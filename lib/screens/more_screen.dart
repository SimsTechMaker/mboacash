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
import '../widgets/design.dart';
import 'backup_screen.dart';
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
    final openDebts = s.debts.where((d) => s.debtLeft(d) > 0).toList();
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    final money = <_Item>[
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
      ('wand-sparkles', 'c7', 'Assistant budget', 'Budget et plafonds selon tes revenus et tes objectifs', () => go(const BudgetAssistantScreen())),
    ];
    final data = <_Item>[
      ('file-text', 'c3', 'Relevé PDF', 'Imprimable, par mois, par période ou par compte', () => go(const StatementScreen())),
      ('download', 'c8', 'Exporter en CSV', 'Toutes tes opérations dans un fichier pour Excel', () => exportCsv(context)),
      ('file-up', 'c8', 'Importer un CSV', 'Récupérer un export carnet237, sans doublons', () => go(const ImportScreen())),
      (
        'cloud',
        'c5',
        'Synchronisation Google Drive',
        backup.connected ? backup.email! : 'Copie chiffrée dans ton Drive, à restaurer ailleurs',
        () => go(const BackupScreen()),
      ),
    ];
    final app = <_Item>[
      (
        lock.hasPin ? 'lock' : 'lock-open',
        'c4',
        'Sécurité',
        lock.hasPin ? 'Code activé${lock.biometric ? ' · empreinte' : ''}' : 'Protège l\'app par un code et ton empreinte',
        () => go(const SecurityScreen()),
      ),
      ('bell', 'c6', 'Notifications', 'Rappels, budget, échéances, synchronisation', () => go(const NotificationsScreen())),
      ('settings', 'c10', 'Paramètres', 'Thème, devise, budget, catégories, comptes', () => go(const SettingsScreen())),
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
                    const Text(
                      'carnet237',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text('${plural(s.txs.length, 'opération')} · données sur ce téléphone', style: const TextStyle(color: heroSoft, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Badge(icon: lock.hasPin ? 'shield-check' : 'shield', text: lock.hasPin ? 'Protégée' : 'Sans code'),
                        _Badge(icon: backup.connected ? 'cloud' : 'cloud-off', text: backup.connected ? 'Drive connecté' : 'Hors ligne'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        group('coins', 'Argent', money, 0),
        group('database', 'Données', data, 1),
        group('settings', 'Application', app, 2),
        Center(
          child: Text('carnet237 · fait au Cameroun', style: TextStyle(color: context.c.muted, fontSize: 12)),
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
