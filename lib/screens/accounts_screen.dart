import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/sheets.dart';
import 'savings_screen.dart';
import 'settings_screen.dart';

class AccountsScreen extends StatelessWidget {
  final VoidCallback onShowOps;
  const AccountsScreen({super.key, required this.onShowOps});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final b = s.balances();
    final list = s.activeAccounts;
    final onAccounts = s.spendable;
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
              HeroLabel(l.accountsSpendable),
              const SizedBox(height: 4),
              FittedBox(
                alignment: Alignment.centerLeft,
                child: AnimatedMoney(onAccounts, size: 30, color: Colors.white, weight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: HeroStat(label: l.accountsNetWorth, icon: 'landmark', value: net),
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
        const SizedBox(height: 8),
        SectionTitle(
          icon: 'piggy-bank',
          text: context.l.accountsSavings,
          trailing: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsScreen())),
            child: Text(context.l.catsManage),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(context.l.accountsSavingsHelp, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
        ),
        if (s.goals.isEmpty)
          Panel(
            child: EmptyState(
              icon: 'piggy-bank',
              text: context.l.savingsEmpty,
              action: OutlinedButton(onPressed: () => openGoalSheet(context), child: Text(context.l.savingsNewGoal)),
            ),
          ),
        for (final g in s.goals) ...[_SavingsCard(goal: g), const SizedBox(height: 10)],
      ],
    );
  }
}

/// A savings account: its money is set apart until moved to a normal account.
class _SavingsCard extends StatelessWidget {
  final Goal goal;
  const _SavingsCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final saved = s.goalSaved(goal);
    final l = context.l;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: goal.icon, color: slot(goal.color), size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
              ),
              AnimatedMoney(saved, size: 17, weight: FontWeight.w600),
            ],
          ),
          if (goal.target > 0) ...[const SizedBox(height: 12), Gauge(value: (saved / goal.target).clamp(0.0, 1.0), color: slot(goal.color), height: 5)],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChipButton(icon: 'plus', label: l.savingsPutAside, primary: true, onPressed: () => openGoalMoveSheet(context, goal, -1)),
              ActionChipButton(icon: 'arrow-left-right', label: l.accountsSavingsBack, onPressed: () => openGoalMoveSheet(context, goal, 1)),
            ],
          ),
        ],
      ),
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
                    Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5),
                    ),
                    const SizedBox(height: 2),
                    // The "default" tag sits on this line: next to the name, a
                    // large balance would squeeze the name onto two lines.
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l.opsCount(count), style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                        if (id == s.settings.defaultAccount) Pill(l.accountsDefault, color: context.c.accent),
                      ],
                    ),
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
