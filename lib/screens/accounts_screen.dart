import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/sheets.dart';
import 'settings_screen.dart';

class AccountsScreen extends StatelessWidget {
  final VoidCallback onShowOps;
  const AccountsScreen({super.key, required this.onShowOps});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final b = s.balances();
    final list = s.activeAccounts;
    final onAccounts = list.fold<double>(0, (a, x) => a + (b[x.id] ?? 0));
    final net = onAccounts + s.totalSaved + s.totalLent - s.totalOwed;
    final positive = list.fold<double>(0, (a, x) => a + ((b[x.id] ?? 0) > 0 ? b[x.id]! : 0));
    final l = context.l;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        GradientCard(
          tone: HeroTone.blue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeroLabel(l.accountsNetWorth),
              const SizedBox(height: 4),
              FittedBox(
                alignment: Alignment.centerLeft,
                child: AnimatedMoney(net, size: 30, color: Colors.white, weight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: HeroStat(label: l.accountsOnAccounts, icon: 'wallet', value: onAccounts),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HeroStat(label: l.typeSave, icon: 'piggy-bank', value: s.totalSaved),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: HeroStat(label: l.accountsOwedToMe, icon: 'arrow-up-right', value: s.totalLent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HeroStat(label: l.accountsIOwe, icon: 'arrow-down-left', value: -s.totalOwed),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionTitle(
          icon: 'wallet',
          text: l.accountsMine,
          trailing: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(initialTab: 2))),
            child: Text(l.catsManage),
          ),
        ),
        for (var i = 0; i < list.length; i++) ...[
          FadeIn(
            index: i,
            child: _AccountCard(id: list[i].id, share: positive > 0 ? ((b[list[i].id] ?? 0) / positive).clamp(0.0, 1.0) : 0, onShowOps: onShowOps),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String id;
  final double share;
  final VoidCallback onShowOps;
  const _AccountCard({required this.id, required this.share, required this.onShowOps});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = s.accById(id)!;
    final bal = s.balances()[id] ?? 0;
    final count = s.txs.where((t) => s.accountOf(t) == id || t.to == id).length;
    final l = context.l;
    return SoftCard(
      onTap: () {
        s.setFilters(cat: null, acc: id);
        onShowOps();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: a.icon, color: context.c.accent, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
                        ),
                        if (id == s.settings.defaultAccount) ...[const SizedBox(width: 6), Pill(l.accountsDefault, color: context.c.accent)],
                      ],
                    ),
                    Text(l.opsCount(count), style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                  ],
                ),
              ),
              AnimatedMoney(bal, size: 17, weight: FontWeight.w600, color: bal < 0 ? context.c.expense : null),
            ],
          ),
          // The share only means something for accounts that hold money.
          if (bal > 0 && share > 0) ...[
            const SizedBox(height: 12),
            Gauge(value: share, color: context.c.accent, height: 5),
            const SizedBox(height: 4),
            Text(l.accountsShare((share * 100).round()), style: TextStyle(color: context.c.muted, fontSize: 11.5)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChipButton(
                icon: 'list',
                label: l.accountsOps,
                onPressed: () {
                  s.setFilters(cat: null, acc: id);
                  onShowOps();
                },
              ),
              ActionChipButton(icon: 'sliders-horizontal', label: l.accountsAdjust, onPressed: () => openAdjustSheet(context, id)),
            ],
          ),
        ],
      ),
    );
  }
}
