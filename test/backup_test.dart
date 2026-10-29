import 'dart:convert';
import 'dart:typed_data';

import 'package:carnet237/backup.dart';
import 'package:carnet237/proofs.dart';
import 'package:carnet237/security.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

// The backup file format is checked end to end in the app; here we only make
// sure the key derivation is deterministic and that AES-GCM rejects a key
// derived from the wrong code, which is what restore relies on.
void main() {
  test('same code and salt give the same key', () async {
    final salt = randomBytes(16);
    expect(await deriveKey('1234', salt, 1000), await deriveKey('1234', salt, 1000));
    expect(await deriveKey('1234', salt, 1000), isNot(await deriveKey('1235', salt, 1000)));
  });

  test('a key from the wrong code cannot decrypt', () async {
    final salt = randomBytes(16);
    final aes = AesGcm.with256bits();
    final box = await aes.encrypt(utf8.encode('{"app":"carnet237"}'), secretKey: SecretKey(await deriveKey('2468', salt, 1000)));
    final ok = await aes.decrypt(box, secretKey: SecretKey(await deriveKey('2468', salt, 1000)));
    expect(utf8.decode(ok), contains('carnet237'));
    expect(() => aes.decrypt(box, secretKey: SecretKey(deriveKeySync())), throwsA(isA<SecretBoxAuthenticationError>()));
  });

  test('a backup file opens only with its password', () async {
    final plain = utf8.encode('{"app":"carnet237","proofs":{"a-1.jpg":"AA=="}}');
    final file = await DriveBackup.sealWithPassword(plain, 'mot2passe');
    expect(utf8.decode(await DriveBackup.openWithPassword(file, 'mot2passe')), utf8.decode(plain));
    expect(() => DriveBackup.openWithPassword(file, 'autre-mot'), throwsA(isA<BackupException>()));
    expect(() => DriveBackup.openWithPassword(Uint8List.fromList([1, 2, 3]), 'mot2passe'), throwsA(isA<BackupException>()));
  });

  test('proof names from a backup cannot leave the proofs folder', () {
    expect(Proofs.isValidName('t-abc123-lz4.jpg'), isTrue);
    for (final bad in ['../db.jpg', 'a/b.jpg', 'x.png', '', '..jpg/']) {
      expect(Proofs.isValidName(bad), isFalse, reason: bad);
    }
  });
}

List<int> deriveKeySync() => List<int>.filled(32, 7);
