import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../backup.dart';
import '../export.dart';
import '../format.dart';
import '../icons.dart';
import '../security.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'backup_screen.dart';
import 'debts_screen.dart';
import 'notifications_screen.dart';
import 'savings_screen.dart';
import 'security_screen.dart';
import 'settings_screen.dart';
import 'statement_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lock = context.watch<LockService>();
    final backup = context.watch<DriveBackup>();
    final f = fmtOf(context);
    final openDebts = s.debts.where((d) => s.debtLeft(d) > 0).toList();
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    final items = [
      (
        'piggy-bank',
        'c2',
        'Épargne',
        s.goals.isEmpty ? "Crée un objectif et mets de l'argent de côté" : '${plural(s.goals.length, 'objectif')} · ${f.money(s.totalSaved)} mis de côté',
        () => go(const SavingsScreen()),
      ),
      (
        'handshake',
        'c1',
        'Dettes',
        openDebts.isEmpty ? "Suis ce que tu dois et ce qu'on te doit" : 'Je dois ${f.money(s.totalOwed)} · On me doit ${f.money(s.totalLent)}',
        () => go(const DebtsScreen()),
      ),
      ('file-text', 'c3', 'Relevé PDF', 'Un relevé imprimable par mois, par période ou par compte', () => go(const StatementScreen())),
      ('download', 'c8', 'Exporter en CSV', 'Toutes tes opérations dans un fichier pour Excel', () => exportCsv(context)),
      (
        'cloud',
        'c5',
        'Synchronisation Google Drive',
        backup.connected ? backup.email! : 'Copie chiffrée dans ton Drive, à restaurer sur un autre téléphone',
        () => go(const BackupScreen()),
      ),
      ('bell', 'c6', 'Notifications', 'Rappels, budget, échéances, synchronisation', () => go(const NotificationsScreen())),
      (
        lock.hasPin ? 'lock' : 'lock-open',
        'c4',
        'Sécurité',
        lock.hasPin ? 'Code activé${lock.biometric ? ' · biométrie' : ''}' : 'Protège l\'app par un code et ton empreinte',
        () => go(const SecurityScreen()),
      ),
      ('settings', 'c10', 'Paramètres', 'Thème, devise, budget, catégories, comptes', () => go(const SettingsScreen())),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: IconBadge(icon: items[i].$1, color: slot(items[i].$2)),
                  title: Text(items[i].$3, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(items[i].$4, style: TextStyle(color: context.c.muted)),
                  trailing: Icon(appIcon('chevron-right'), color: context.c.muted),
                  onTap: items[i].$5,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('carnet237 · données enregistrées sur ce téléphone', style: TextStyle(color: context.c.muted, fontSize: 12.5)),
        ),
      ],
    );
  }
}
