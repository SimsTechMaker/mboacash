import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'i18n.dart';

/// Random bytes from the platform's secure generator.
List<int> randomBytes(int n) {
  final r = Random.secure();
  return List<int>.generate(n, (_) => r.nextInt(256));
}

/// PBKDF2-HMAC-SHA256, shared by the code check and the backup key.
Future<List<int>> deriveKey(String secret, List<int> salt, int iterations) async {
  final k = await Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256).deriveKeyFromPassword(password: secret, nonce: salt);
  return k.extractBytes();
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// App lock: a 4–6 digit code (stored only as a salted PBKDF2 hash in the
/// Android keystore-backed secure storage), optional biometrics, and a delay
/// after which the app locks again when it goes to the background.
///
/// Setting the code also derives the key used to encrypt Google Drive
/// backups, so that automatic backups can run without asking for the code.
class LockService extends ChangeNotifier {
  static const pinIterations = 20000;
  static const backupIterations = 60000;
  static const maxTries = 5;

  final _store = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  bool loaded = false;
  bool hasPin = false;
  bool biometric = false;
  bool biometricAvailable = false;
  int delaySeconds = 60; // 0 = lock as soon as the app leaves the screen
  bool locked = false;
  int failures = 0;
  DateTime? blockedUntil;

  DateTime? _pausedAt;
  int _bypass = 0;

  Future<void> load() async {
    final all = await _store.readAll();
    hasPin = all['pin_hash'] != null;
    biometric = all['bio'] == '1';
    delaySeconds = int.tryParse(all['lock_delay'] ?? '') ?? 60;
    failures = int.tryParse(all['fails'] ?? '') ?? 0;
    final until = int.tryParse(all['blocked_until'] ?? '');
    blockedUntil = until == null ? null : DateTime.fromMillisecondsSinceEpoch(until);
    try {
      biometricAvailable = await _auth.canCheckBiometrics && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      biometricAvailable = false;
    }
    locked = hasPin;
    loaded = true;
    notifyListeners();
  }

  // ---------- code ----------

  Future<void> setPin(String pin) async {
    final salt = randomBytes(16);
    final hash = await deriveKey(pin, salt, pinIterations);
    final backupSalt = randomBytes(16);
    final backupKey = await deriveKey(pin, backupSalt, backupIterations);
    await _store.write(key: 'pin_salt', value: base64Encode(salt));
    await _store.write(key: 'pin_hash', value: base64Encode(hash));
    await _store.write(key: 'backup_salt', value: base64Encode(backupSalt));
    await _store.write(key: 'backup_key', value: base64Encode(backupKey));
    await _resetFailures();
    hasPin = true;
    locked = false;
    notifyListeners();
  }

  Future<void> removePin() async {
    for (final k in ['pin_salt', 'pin_hash', 'backup_salt', 'backup_key', 'bio']) {
      await _store.delete(key: k);
    }
    hasPin = false;
    biometric = false;
    locked = false;
    notifyListeners();
  }

  /// Checks a code without changing the lock state (used before sensitive
  /// settings changes). Counts towards the attempt limit.
  Future<bool> check(String pin) async {
    if (isBlocked) return false;
    final salt = await _store.read(key: 'pin_salt');
    final hash = await _store.read(key: 'pin_hash');
    if (salt == null || hash == null) return true;
    final ok = _sameBytes(await deriveKey(pin, base64Decode(salt), pinIterations), base64Decode(hash));
    if (ok) {
      await _resetFailures();
    } else {
      failures++;
      await _store.write(key: 'fails', value: '$failures');
      if (failures >= maxTries) {
        // 30 s, then 1, 2, 4 … minutes, capped at one hour.
        final wait = Duration(seconds: min(3600, 30 * pow(2, failures - maxTries).toInt()));
        blockedUntil = DateTime.now().add(wait);
        await _store.write(key: 'blocked_until', value: '${blockedUntil!.millisecondsSinceEpoch}');
      }
      notifyListeners();
    }
    return ok;
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await check(pin);
    if (ok) {
      locked = false;
      notifyListeners();
    }
    return ok;
  }

  bool get isBlocked => blockedUntil != null && DateTime.now().isBefore(blockedUntil!);

  Future<void> _resetFailures() async {
    failures = 0;
    blockedUntil = null;
    await _store.delete(key: 'fails');
    await _store.delete(key: 'blocked_until');
  }

  // ---------- biometrics ----------

  Future<bool> setBiometric(bool on) async {
    if (on) {
      final ok = await _prompt(tr.securityBioEnableReason);
      if (!ok) return false;
    }
    biometric = on;
    await _store.write(key: 'bio', value: on ? '1' : '0');
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithBiometric() async {
    if (!biometric || !biometricAvailable) return false;
    final ok = await _prompt(tr.securityBioUnlockReason);
    if (ok) {
      await _resetFailures();
      locked = false;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> _prompt(String reason) async {
    _bypass++;
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true, persistAcrossBackgrounding: true);
    } catch (_) {
      return false;
    } finally {
      _bypass--;
    }
  }

  // ---------- auto-lock ----------

  Future<void> setDelay(int seconds) async {
    delaySeconds = seconds;
    await _store.write(key: 'lock_delay', value: '$seconds');
    notifyListeners();
  }

  void lockNow() {
    if (!hasPin) return;
    locked = true;
    notifyListeners();
  }

  /// Runs [action] (a share sheet, Google sign-in, the print dialog…) without
  /// the app locking itself when that screen takes the foreground.
  Future<T> withoutLock<T>(Future<T> Function() action) async {
    _bypass++;
    try {
      return await action();
    } finally {
      _pausedAt = null;
      _bypass--;
    }
  }

  void onPaused() {
    if (_bypass == 0 && _pausedAt == null) _pausedAt = DateTime.now();
  }

  void onResumed() {
    final at = _pausedAt;
    _pausedAt = null;
    if (!hasPin || at == null || _bypass > 0) return;
    if (DateTime.now().difference(at).inSeconds >= delaySeconds) lockNow();
  }

  // ---------- backup key ----------

  /// The key derived from the code when it was set, with its salt, or null if
  /// no code is set. Backups are encrypted with it.
  Future<({List<int> key, List<int> salt})?> backupKey() async {
    final k = await _store.read(key: 'backup_key');
    final s = await _store.read(key: 'backup_salt');
    if (k == null || s == null) return null;
    return (key: base64Decode(k), salt: base64Decode(s));
  }

  // ---------- small preferences kept beside the lock settings ----------

  Future<String?> readPref(String k) => _store.read(key: 'pref_$k');
  Future<void> writePref(String k, String? v) => v == null ? _store.delete(key: 'pref_$k') : _store.write(key: 'pref_$k', value: v);
}
