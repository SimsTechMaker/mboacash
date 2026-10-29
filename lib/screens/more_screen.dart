import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../backup.dart';
import '../export.dart';
import '../i18n.dart';
import '../icons.dart';
import '../security.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import 'backup_screen.dart';
import 'file_backup_screen.dart';
import 'budget_assistant_screen.dart';
import 'debts_screen.dart';
import 'import_screen.dart';
import 'notifications_screen.dart';
import 'savings_screen.dart';
import 'security_screen.dart';
import 'settings_screen.dart';
import 'statement_screen.dart';

typedef _Item = (String icon, String color, String title, String sub, VoidCallback onTap);

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lock = context.watch<LockService>();
    final backup = context.watch<DriveBackup>();
    final f = fmtOf(context);
    final l = context.l;
    final openDebts = s.debts.where((d) => s.debtLeft(d) > 0).toList();
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    final money = <_Item>[
      (
        'piggy-bank',
        'c2',
        l.moreSavings,
        s.goals.isEmpty ? l.moreSavingsEmpty : l.moreSavingsSub(s.goals.length, f.money(s.totalSaved)),
        () => go(const SavingsScreen()),
      ),
      (
        'handshake',
        'c1',
        l.moreDebts,
        openDebts.isEmpty ? l.moreDebtsEmpty : l.moreDebtsSub(f.money(s.totalOwed), f.money(s.totalLent)),
        () => go(const DebtsScreen()),
      ),
      ('wand-sparkles', 'c7', l.moreAssistant, l.moreAssistantSub, () => go(const BudgetAssistantScreen())),
    ];
    final data = <_Item>[
      ('file-text', 'c3', l.moreStatement, l.moreStatementSub, () => go(const StatementScreen())),
      ('download', 'c8', l.moreExportCsv, l.moreExportCsvSub, () => exportCsv(context)),
      ('file-up', 'c8', l.moreImportCsv, l.moreImportCsvSub, () => go(const ImportScreen())),
      ('file-lock', 'c4', l.fileBackupTitle, l.fileBackupMoreSub, () => go(const FileBackupScreen())),
      ('cloud', 'c5', l.moreDrive, backup.connected ? backup.email! : l.moreDriveSub, () => go(const BackupScreen())),
    ];
    final app = <_Item>[
      (
        lock.hasPin ? 'lock' : 'lock-open',
        'c4',
        l.moreSecurity,
        lock.hasPin ? (lock.biometric ? l.moreSecurityOnBio : l.moreSecurityOn) : l.moreSecurityOff,
        () => go(const SecurityScreen()),
      ),
      ('bell', 'c6', l.moreNotifications, l.moreNotificationsSub, () => go(const NotificationsScreen())),
      ('settings', 'c10', l.moreSettings, l.moreSettingsSub, () => go(const SettingsScreen())),
    ];

    Widget group(String icon, String title, List<_Item> items, int offset) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(icon: icon, text: title),
        FadeIn(
          index: offset,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(indent: 68),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: IconBadge(icon: items[i].$1, color: slot(items[i].$2)),
                    title: Text(items[i].$3, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      items[i].$4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.c.muted, fontSize: 12.5),
                    ),
                    trailing: Icon(appIcon('chevron-right'), color: context.c.muted, size: 20),
                    onTap: items[i].$5,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        GradientCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(15)),
                child: Icon(appIcon('notebook-pen'), color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.appTitle,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(l.moreHeroSub(s.txs.length), style: const TextStyle(color: heroSoft, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Badge(icon: lock.hasPin ? 'shield-check' : 'shield', text: lock.hasPin ? l.moreBadgeLocked : l.moreBadgeNoCode),
                        _Badge(icon: backup.connected ? 'cloud' : 'cloud-off', text: backup.connected ? l.moreBadgeDrive : l.moreBadgeOffline),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        group('coins', l.moreGroupMoney, money, 0),
        group('database', l.moreGroupData, data, 1),
        group('settings', l.moreGroupApp, app, 2),
        Center(
          child: Text(l.moreFooter, style: TextStyle(color: context.c.muted, fontSize: 12)),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String icon, text;
  const _Badge({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(appIcon(icon), size: 13, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
