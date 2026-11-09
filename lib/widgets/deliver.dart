import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../i18n.dart';
import '../icons.dart';
import '../security.dart';
import 'common.dart';

/// Hands a file the app made (CSV, PDF, backup) to the user: saved on the
/// phone through Android's own "save as" screen, where the user picks the
/// folder, or shared with another app. No storage permission is needed.
Future<void> deliverFile(BuildContext context, {required Uint8List bytes, required String name, required String mime, required String subject}) async {
  final lock = context.read<LockService>();
  final l = context.l;
  final choice = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        ListTile(
          leading: Icon(appIcon('download')),
          title: Text(ctx.l.deliverSave),
          subtitle: Text(ctx.l.deliverSaveSub),
          onTap: () => Navigator.pop(ctx, 'save'),
        ),
        ListTile(
          leading: Icon(appIcon('share-2')),
          title: Text(ctx.l.deliverShare),
          subtitle: Text(ctx.l.deliverShareSub),
          onTap: () => Navigator.pop(ctx, 'share'),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
  if (choice == null) return;
  if (choice == 'save') {
    // The save screen opens outside the app: don't lock it meanwhile.
    final uri = await lock.withoutLock(() => FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: mime, dialogTitle: l.deliverSave));
    if (uri != null && context.mounted) toast(context, l.deliverSaved(name));
    return;
  }
  // The share sheet reads a file: written to the cache, removed at the next
  // start (see cleanExportFiles).
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  await lock.withoutLock(
    () => SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        subject: subject,
      ),
    ),
  );
}
