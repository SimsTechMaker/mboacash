import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../backup.dart';
import '../i18n.dart';
import '../icons.dart';
import '../models.dart';
import '../security.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// A complete backup in one password-protected file (everything, proof photos
/// included), saved or sent wherever the user likes. No Google account and no
/// network: the share sheet decides where the file goes.
class FileBackupScreen extends StatefulWidget {
  const FileBackupScreen({super.key});
  @override
  State<FileBackupScreen> createState() => _FileBackupScreenState();
}

class _FileBackupScreenState extends State<FileBackupScreen> {
  bool busy = false;

  Future<void> _busy(Future<void> Function() body) async {
    setState(() => busy = true);
    try {
      await body();
    } on BackupException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (e) {
      debugPrint('file backup: $e');
      if (mounted) toast(context, context.l.fileBackupFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> export() async {
    final password = await _askPassword(context, confirm: true);
    if (password == null || !mounted) return;
    final s = context.read<AppState>();
    final lock = context.read<LockService>();
    await _busy(() async {
      final bytes = await DriveBackup.sealWithPassword(utf8.encode(jsonEncode(await s.fullSnapshot())), password);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/my-nkap-${todayIso()}.nkap');
      await file.writeAsBytes(bytes, flush: true);
      await lock.withoutLock(
        () => SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/octet-stream')],
            subject: tr.fileBackupSubject,
          ),
        ),
      );
    });
  }

  Future<void> import() async {
    final s = context.read<AppState>();
    final lock = context.read<LockService>();
    final files = await lock.withoutLock(() => FilePicker.pickFiles(type: FileType.any));
    if (files.isEmpty || !mounted) return;
    final password = await _askPassword(context, confirm: false);
    if (password == null || !mounted) return;
    await _busy(() async {
      final bytes = await files.first.readAsBytes();
      final plain = await DriveBackup.openWithPassword(bytes, password);
      final data = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.l.fileBackupReplaceTitle),
          content: Text(ctx.l.fileBackupReplaceText),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l.fileBackupReplace)),
          ],
        ),
      );
      if (ok != true) return;
      try {
        await s.restore(data);
      } catch (_) {
        // restore() parses everything before writing: local data is untouched.
        throw BackupException(tr.backupUnreadable);
      }
      if (mounted) toast(context, context.l.fileBackupRestored);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    Widget point(String icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(appIcon(icon), size: 18, color: context.c.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.fileBackupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [point('database', l.fileBackupPointAll), point('file-lock', l.fileBackupPointPassword), point('cloud-off', l.fileBackupPointOffline)],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: busy ? null : export, icon: Icon(appIcon('hard-drive-download')), label: Text(l.fileBackupExport)),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: busy ? null : import, icon: Icon(appIcon('hard-drive-upload')), label: Text(l.fileBackupImport)),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
          Text(l.fileBackupWarning, style: TextStyle(color: context.c.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Asks for the file password; with [confirm], twice and at least 6 characters.
Future<String?> _askPassword(BuildContext context, {required bool confirm}) {
  final a = TextEditingController();
  final b = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final l = ctx.l;
        void submit() {
          if (confirm && a.text.length < 6) return setState(() => error = l.fileBackupPasswordShort);
          if (confirm && a.text != b.text) return setState(() => error = l.fileBackupPasswordMismatch);
          if (a.text.isEmpty) return;
          Navigator.pop(ctx, a.text);
        }

        return AlertDialog(
          title: Text(confirm ? l.fileBackupPasswordNew : l.fileBackupPasswordEnter),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (confirm) ...[Text(l.fileBackupPasswordHelp, style: TextStyle(color: ctx.c.muted, fontSize: 13)), const SizedBox(height: 16)],
              TextField(
                controller: a,
                obscureText: true,
                autofocus: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(labelText: l.fileBackupPassword),
                onSubmitted: (_) => confirm ? null : submit(),
              ),
              if (confirm) const SizedBox(height: 12),
              if (confirm)
                TextField(
                  controller: b,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l.fileBackupPasswordAgain),
                  onSubmitted: (_) => submit(),
                ),
              if (error != null) ...[const SizedBox(height: 8), Text(error!, style: TextStyle(color: ctx.c.expense, fontSize: 13))],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            FilledButton(onPressed: submit, child: Text(l.ok)),
          ],
        );
      },
    ),
  );
}
