import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../icons.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import 'settings_screen.dart';

class AccountsScreen extends StatelessWidget {
  final VoidCallback onShowOps;
  const AccountsScreen({super.key, required this.onShowOps});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final b = s.balances();
    final list = s.activeAccounts;
    final onAccounts = list.fold<double>(0, (a, x) => a + (b[x.id] ?? 0));
    final net = onAccounts + s.totalSaved + s.totalLent - s.totalOwed;

    Widget row(String l, String v, [Color? c]) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(l)),
          Text(v, style: numStyle.copyWith(color: c ?? context.c.ink)),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Label('Patrimoine net'),
              const SizedBox(height: 4),
              FittedBox(child: Money(net, size: 28, color: net < 0 ? context.c.expense : null)),
              const SizedBox(height: 10),
              row('Sur mes comptes', f.money(onAccounts)),
              row('Épargne mise de côté', f.money(s.totalSaved)),
              row('On me doit', f.money(s.totalLent, signed: true), context.c.income),
              row('Je dois', f.money(-s.totalOwed, signed: true), context.c.expense),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text('Mes comptes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(initialTab: 2))),
              child: const Text('Gérer les comptes'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final a in list) ...[
          Panel(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconBadge(icon: a.icon, color: context.c.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${plural(s.txs.where((t) => s.accountOf(t) == a.id || t.to == a.id).length, 'opération')}${a.id == s.settings.defaultAccount ? ' · par défaut' : ''}',
                            style: TextStyle(color: context.c.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Money(b[a.id] ?? 0, size: 16, color: (b[a.id] ?? 0) < 0 ? context.c.expense : null),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(),
                Row(
                  children: [
                    TextButton.icon(
                      icon: Icon(appIcon('list'), size: 18),
                      label: const Text('Opérations'),
                      onPressed: () {
                        s.setFilters(cat: null, acc: a.id);
                        onShowOps();
                      },
                    ),
                    TextButton.icon(
                      icon: Icon(appIcon('sliders-horizontal'), size: 18),
                      label: const Text('Ajuster le solde'),
                      onPressed: () => openAdjustSheet(context, a.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
