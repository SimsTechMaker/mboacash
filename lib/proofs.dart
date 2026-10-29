import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Proof photos (receipts) attached to movements. Each is a small JPEG in the
/// app's private documents folder; a movement only stores the file name.
class Proofs {
  static Directory? _dir;

  /// Names the app writes itself; anything else (e.g. "../x" in a backup) is refused.
  static final _valid = RegExp(r'^[A-Za-z0-9_-]{1,80}\.jpg$');
  static bool isValidName(String name) => _valid.hasMatch(name);

  static Future<Directory> dir() async {
    final d = _dir ??= Directory(p.join((await getApplicationDocumentsDirectory()).path, 'proofs'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<File> file(String name) async => File(p.join((await dir()).path, name));

  /// Writes a new proof for movement [txId] and returns its file name.
  static Future<String> save(String txId, Uint8List bytes) async {
    final name = '${txId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '')}-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}.jpg';
    await (await file(name)).writeAsBytes(bytes, flush: true);
    return name;
  }

  static Future<void> delete(String name) async {
    if (!isValidName(name)) return;
    final f = await file(name);
    if (await f.exists()) await f.delete();
  }

  /// Removes files no movement points to any more.
  static Future<void> prune(Set<String> used) async {
    await for (final e in (await dir()).list()) {
      if (e is File && !used.contains(p.basename(e.path))) await e.delete();
    }
  }

  /// The proofs in [names] as base64, for a backup. Missing files are skipped.
  static Future<Map<String, String>> export(Iterable<String> names) async {
    final out = <String, String>{};
    for (final n in names) {
      if (!isValidName(n)) continue;
      final f = await file(n);
      if (await f.exists()) out[n] = base64Encode(await f.readAsBytes());
    }
    return out;
  }

  /// Writes the proofs of a backup. Invalid names are ignored.
  static Future<void> import(Map<String, dynamic> data) async {
    for (final e in data.entries) {
      if (!isValidName(e.key) || e.value is! String) continue;
      await (await file(e.key)).writeAsBytes(base64Decode(e.value as String), flush: true);
    }
  }
}
