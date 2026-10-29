import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'config.dart';
import 'i18n.dart';
import 'security.dart';
import 'state.dart';

class BackupFile {
  final String id, name;
  final DateTime created;
  final int size;
  const BackupFile(this.id, this.name, this.created, this.size);
}

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
  @override
  String toString() => message;
}

/// Encrypted backups in the app's private Drive folder ("appDataFolder"):
/// only carnet237 can see these files, they don't show in the user's Drive.
///
/// The app is offline by design: nothing here touches the network until the
/// user presses a button on the backup screen. At startup only local
/// preferences are read (last backup date, connected e-mail).
///
/// File layout: "C237" | version (1) | iterations (4, big-endian) | salt (16)
/// | nonce (12) | AES-256-GCM ciphertext | tag (16). The key is PBKDF2 of the
/// app lock code with that salt, so a backup restores on another phone with
/// the code that was set when it was made.
class DriveBackup extends ChangeNotifier {
  static const scopes = [drive.DriveApi.driveAppdataScope];
  static const keep = 10;
  static const _magic = [0x43, 0x32, 0x33, 0x37]; // C237
  static const _maxIterations = 1000000; // refuse files that would take minutes to open

  final AppState state;
  final LockService lock;
  DriveBackup(this.state, this.lock);

  bool get configured => googleServerClientId.isNotEmpty;
  String? email; // remembered locally once connected; no network needed to show it
  bool get connected => email != null;
  bool busy = false;
  DateTime? lastBackup;
  List<BackupFile>? files; // null until the user asks to see them
  String? lastError;

  /// Called after each successful backup (the sync reminder is rescheduled).
  void Function(DateTime when)? onBackup;

  final _signIn = GoogleSignIn.instance;
  GoogleSignInAccount? _user;
  bool _signInReady = false;

  /// Local only: reads what was saved on this phone.
  Future<void> init() async {
    final last = int.tryParse(await lock.readPref('last_backup') ?? '');
    lastBackup = last == null ? null : DateTime.fromMillisecondsSinceEpoch(last);
    email = await lock.readPref('drive_email');
    notifyListeners();
  }

  // ---------- account (network, on user action only) ----------

  Future<GoogleSignInAccount> _account() async {
    if (!configured) throw BackupException(tr.backupNotConfigured);
    if (!_signInReady) {
      await _signIn.initialize(serverClientId: googleServerClientId);
      _signInReady = true;
    }
    final GoogleSignInAccount u =
        _user ??
        await (_signIn.attemptLightweightAuthentication() ?? Future<GoogleSignInAccount?>.value()) ??
        await lock.withoutLock<GoogleSignInAccount>(() => _signIn.authenticate(scopeHint: scopes));
    _user = u;
    if (email != u.email) {
      email = u.email;
      await lock.writePref('drive_email', u.email);
    }
    return u;
  }

  Future<drive.DriveApi> _api() async {
    final u = await _account();
    final GoogleSignInClientAuthorization auth =
        await u.authorizationClient.authorizationForScopes(scopes) ?? await lock.withoutLock(() => u.authorizationClient.authorizeScopes(scopes));
    return drive.DriveApi(auth.authClient(scopes: scopes));
  }

  Future<void> connect() => _run(() async {
    files = await _list(await _api());
  });

  Future<void> disconnect() => _run(() async {
    try {
      if (!_signInReady) {
        await _signIn.initialize(serverClientId: googleServerClientId);
        _signInReady = true;
      }
      await _signIn.disconnect();
    } catch (_) {
      // Offline or already revoked: forgetting the account locally is enough.
    }
    _user = null;
    email = null;
    files = null;
    await lock.writePref('drive_email', null);
  });

  // ---------- operations ----------

  Future<void> refresh() => _run(() async {
    files = await _list(await _api());
  });

  Future<List<BackupFile>> _list(drive.DriveApi api) async {
    final res = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains 'carnet237-'",
      orderBy: 'createdTime desc',
      pageSize: 100,
      $fields: 'files(id,name,createdTime,size)',
    );
    return [
      for (final f in res.files ?? <drive.File>[]) BackupFile(f.id!, f.name ?? '', f.createdTime?.toLocal() ?? DateTime.now(), int.tryParse(f.size ?? '') ?? 0),
    ];
  }

  /// "Synchroniser": encrypts everything and uploads it as a new backup.
  Future<void> backupNow() => _run(() async {
    final k = await lock.backupKey();
    if (k == null) throw BackupException(tr.backupNeedPin);
    final api = await _api();
    final bytes = await _encrypt(utf8.encode(jsonEncode(await state.fullSnapshot())), k.key, k.salt);
    final now = DateTime.now();
    final name = 'carnet237-${now.toIso8601String().substring(0, 19).replaceAll(':', '-')}.c237';
    await api.files.create(
      drive.File()
        ..name = name
        ..parents = ['appDataFolder']
        ..mimeType = 'application/octet-stream',
      uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
    );
    var list = await _list(api);
    for (final old in list.skip(keep)) {
      await api.files.delete(old.id);
    }
    if (list.length > keep) list = list.take(keep).toList();
    files = list;
    lastBackup = now;
    await lock.writePref('last_backup', '${now.millisecondsSinceEpoch}');
    onBackup?.call(now);
  });

  /// Replaces all local data with the backup. [code] is the lock code that was
  /// set when the backup was made.
  Future<void> restore(BackupFile f, String code) => _run(() async {
    final api = await _api();
    final media = await api.files.get(f.id, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final bytes = BytesBuilder(copy: false);
    await for (final c in media.stream) {
      bytes.add(c);
    }
    final plain = await _decrypt(bytes.toBytes(), code);
    final data = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    try {
      await state.restore(data);
    } catch (_) {
      // restore() parses everything before writing, so local data is untouched.
      throw BackupException(tr.backupUnreadable);
    }
  });

  Future<void> delete(BackupFile f) => _run(() async {
    final api = await _api();
    await api.files.delete(f.id);
    files?.removeWhere((x) => x.id == f.id);
  });

  Future<void> _run(Future<void> Function() body) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      await body();
    } on BackupException catch (e) {
      lastError = e.message;
      rethrow;
    } on GoogleSignInException catch (e) {
      // Full details go to the log (adb logcat / flutter run) for diagnosis;
      // the short Google description is shown to the user.
      debugPrint('carnet237 GoogleSignInException: $e');
      // Closing Google's consent screen comes back as unknownError "[16] Cancelled by user".
      final cancelled = e.code == GoogleSignInExceptionCode.canceled || (e.description ?? '').contains('[16]');
      lastError = cancelled
          ? tr.backupSignInCancelled
          : (e.description == null ? tr.backupSignInFailed(e.code.name) : tr.backupSignInFailedDetail(e.code.name, e.description!));
      throw BackupException(lastError!);
    } on drive.DetailedApiRequestError catch (e) {
      debugPrint('carnet237 Drive error: ${e.status} ${e.message}');
      lastError = e.message == null ? tr.backupDriveRefused('${e.status}') : tr.backupDriveRefusedDetail('${e.status}', e.message!);
      throw BackupException(lastError!);
    } catch (e, st) {
      debugPrint('carnet237 backup error: $e\n$st');
      lastError = tr.backupNetworkError;
      throw BackupException(lastError!);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---------- encryption ----------

  /// A complete backup protected by [password], for a file the user keeps
  /// themself (same format as the Drive backups, with its own salt).
  static Future<Uint8List> sealWithPassword(List<int> plain, String password) async {
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    return _encrypt(plain, await deriveKey(password, salt, LockService.backupIterations), salt);
  }

  /// Opens a backup file made by [sealWithPassword] or by a Drive backup.
  static Future<List<int>> openWithPassword(Uint8List data, String password) => _decrypt(data, password);

  static Future<Uint8List> _encrypt(List<int> plain, List<int> key, List<int> salt) async {
    final aes = AesGcm.with256bits();
    final box = await aes.encrypt(plain, secretKey: SecretKey(key), nonce: aes.newNonce());
    final out = BytesBuilder()
      ..add(_magic)
      ..addByte(1)
      ..add((ByteData(4)..setUint32(0, LockService.backupIterations)).buffer.asUint8List())
      ..add(salt)
      ..add(box.nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return out.toBytes();
  }

  static Future<List<int>> _decrypt(Uint8List data, String code) async {
    const head = 4 + 1 + 4 + 16 + 12;
    if (data.length < head + 16 || !List.generate(4, (i) => data[i] == _magic[i]).every((x) => x) || data[4] != 1) {
      throw BackupException(tr.backupInvalidFile);
    }
    final iterations = ByteData.sublistView(data, 5, 9).getUint32(0);
    if (iterations < 1000 || iterations > _maxIterations) throw BackupException(tr.backupInvalidFile);
    final salt = data.sublist(9, 25);
    final nonce = data.sublist(25, 37);
    final cipher = data.sublist(37, data.length - 16);
    final mac = data.sublist(data.length - 16);
    final key = await deriveKey(code, salt, iterations);
    try {
      return await AesGcm.with256bits().decrypt(
        SecretBox(cipher, nonce: nonce, mac: Mac(mac)),
        secretKey: SecretKey(key),
      );
    } on SecretBoxAuthenticationError {
      throw BackupException(tr.backupWrongCode);
    }
  }
}
