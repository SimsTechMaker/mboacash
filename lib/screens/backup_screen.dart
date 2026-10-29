import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../backup.dart';
import '../i18n.dart';
import '../icons.dart';
import '../security.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lock_screen.dart';
import 'security_screen.dart';

/// Every button here is the only way the app goes online; opening the screen
/// itself makes no network request.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  static String when(BuildContext context, DateTime d) => context.l.backupWhen(DateFormat.yMMMd(intlLocale).format(d), DateFormat.Hm(intlLocale).format(d));

  @override
  Widget build(BuildContext context) {
    final b = context.watch<DriveBackup>();
    final l = context.watch<LockService>();
    final t = context.l;

    Future<void> guard(Future<void> Function() f, [String? done]) async {
      try {
        await f();
        if (done != null && context.mounted) toast(context, done);
      } on BackupException catch (e) {
        if (context.mounted) toast(context, e.message);
      }
    }

    final children = <Widget>[];
    if (!b.configured) {
      children.add(
        Panel(
          child: EmptyState(icon: 'cloud-off', text: t.backupNotConfigured),
        ),
      );
    } else if (!b.connected) {
      children.add(
        Panel(
          child: EmptyState(
            icon: 'cloud',
            text: t.backupConnectIntro,
            action: FilledButton.icon(
              icon: Icon(appIcon('log-in')),
              label: Text(t.backupSignIn),
              onPressed: b.busy ? null : () => guard(b.connect, t.backupConnected),
            ),
          ),
        ),
      );
    } else {
      children.addAll([
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconBadge(icon: 'cloud', color: context.c.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.email!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          b.lastBackup == null ? t.backupNever : t.backupLast(when(context, b.lastBackup!)),
                          style: TextStyle(color: context.c.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!l.hasPin) ...[
                Text(t.backupNeedPin, style: TextStyle(color: context.c.warn)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
                  child: Text(t.backupEnablePin),
                ),
              ] else
                FilledButton.icon(
                  icon: Icon(appIcon('cloud-upload')),
                  label: Text(t.backupSyncNow),
                  onPressed: b.busy ? null : () => guard(b.backupNow, t.backupSent),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(t.backupListTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              icon: Icon(appIcon('refresh-cw'), size: 18),
              label: Text(b.files == null ? t.backupShow : t.backupRefresh),
              onPressed: b.busy ? null : () => guard(b.refresh),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (b.files == null)
          Text(t.backupShowHint, style: TextStyle(color: context.c.muted))
        else if (b.files!.isEmpty)
          Text(t.backupNone, style: TextStyle(color: context.c.muted))
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < b.files!.length; i++) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    leading: Icon(appIcon('archive'), color: context.c.accent),
                    title: Text(when(context, b.files![i].created)),
                    subtitle: Text(_size(context, b.files![i].size, latest: i == 0)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => v == 'restore' ? _restore(context, b, b.files![i]) : guard(() => b.delete(b.files![i]), t.backupDeleted),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'restore', child: Text(t.backupRestore)),
                        PopupMenuItem(value: 'delete', child: Text(t.delete)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        Text(t.backupInfo(DriveBackup.keep), style: TextStyle(color: context.c.muted, fontSize: 13)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: b.busy ? null : () => guard(b.disconnect, t.backupDisconnected), child: Text(t.backupDisconnect)),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.backupTitle)),
      body: Stack(
        children: [
          ListView(padding: const EdgeInsets.all(16), children: children),
          if (b.busy) const Positioned(left: 0, right: 0, top: 0, child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  static String _size(BuildContext context, int bytes, {required bool latest}) {
    final size = NumberFormat('0.0', intlLocale).format(bytes / 1024);
    return latest ? context.l.backupSizeLatest(size) : context.l.backupSize(size);
  }

  Future<void> _restore(BuildContext context, DriveBackup b, BackupFile f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l.backupRestoreTitle),
        content: Text(ctx.l.backupRestoreText(when(ctx, f.created))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l.backupRestore)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final code = await askPin(context, title: context.l.backupCodeTitle, subtitle: context.l.backupCodeSubtitle, check: false);
    if (code == null || !context.mounted) return;
    try {
      await b.restore(f, code);
      if (context.mounted) toast(context, context.l.backupRestored);
    } on BackupException catch (e) {
      if (context.mounted) toast(context, e.message);
    }
  }
}
