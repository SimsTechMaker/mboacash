import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../i18n.dart';
import '../icons.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import 'debts_screen.dart';
import 'savings_screen.dart';
import 'settings_screen.dart';

/// Everything the user owns or owes, in three lists: the accounts whose money
/// can be spent, the savings accounts, and loans and debts.
class AccountsScreen extends StatelessWidget {
  final VoidCallback onShowOps;
  const AccountsScreen({super.key, required this.onShowOps});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final l = context.l;
    final b = s.balances();
    final net = s.spendable + s.totalSaved + s.totalLent - s.totalOwed;
    final openDebts = s.debts.where((d) => s.debtLeft(d) > 0).toList()..sort((a, c) => (a.due.isEmpty ? '9' : a.due).compareTo(c.due.isEmpty ? '9' : c.due));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(l.accountsWorth, style: TextStyle(color: context.c.muted, fontSize: 13)),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: AnimatedMoney(net, size: 32, weight: FontWeight.w700),
        ),
        Text(l.accountsWorthHelp, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
        const SizedBox(height: 18),
        _Section(
          title: l.accountsSpendableSection(f.money(s.spendable)),
          action: l.catsManage,
          onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(initialTab: 2))),
          children: [
            for (final a in s.activeAccounts)
              _Row(
                icon: a.icon,
                color: context.c.accent,
                title: a.name,
                subtitle: [
                  l.opsCount(s.txs.where((t) => s.accountOf(t) == a.id || t.to == a.id).length),
                  if (a.id == s.settings.defaultAccount) l.accountsDefault,
                ].join(' · '),
                amount: b[a.id] ?? 0,
                onTap: () => _actions(context, a.name, [
                  (
                    'list',
                    l.accountsOps,
                    () {
                      s.setFilters(cat: null, acc: a.id);
                      onShowOps();
                    },
                  ),
                  ('sliders-horizontal', l.accountsAdjust, () => openAdjustSheet(context, a.id)),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _Section(
          title: l.accountsSavingsSection(f.money(s.totalSaved)),
          action: s.goals.isEmpty ? l.add : l.catsManage,
          onAction: () => s.goals.isEmpty ? openGoalSheet(context) : Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsScreen())),
          empty: s.goals.isEmpty ? l.savingsEmpty : null,
          children: [
            for (final g in s.goals)
              _Row(
                icon: g.icon,
                color: slot(g.color),
                title: g.name,
                subtitle: g.target > 0 ? l.savingsOfTarget(f.money(g.target)) : null,
                amount: s.goalSaved(g),
                progress: g.target > 0 ? (s.goalSaved(g) / g.target).clamp(0.0, 1.0) : null,
                onTap: () => _actions(context, g.name, [
                  ('plus', l.savingsPutAside, () => openGoalMoveSheet(context, g, -1)),
                  ('arrow-left-right', l.accountsSavingsBack, () => openGoalMoveSheet(context, g, 1)),
                  ('pencil', l.edit, () => openGoalSheet(context, goal: g)),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _Section(
          title: l.accountsDebtsSection,
          action: s.debts.isEmpty ? l.add : l.homeSeeAll,
          onAction: () => s.debts.isEmpty ? openDebtSheet(context) : Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen())),
          empty: openDebts.isEmpty ? l.debtsNoneOpen : null,
          children: [
            for (final d in openDebts)
              _Row(
                icon: d.owe ? 'arrow-down-left' : 'arrow-up-right',
                color: slot(d.owe ? 'c4' : 'c8'),
                title: d.owe ? l.debtIOweTo(d.person) : l.debtOwesMe(d.person),
                subtitle: d.due.isEmpty ? null : l.debtDueOn(longDate(d.due)),
                amount: d.owe ? -s.debtLeft(d) : s.debtLeft(d),
                signed: true,
                onTap: () => _actions(context, d.person, [
                  (d.owe ? 'arrow-up-right' : 'arrow-down-left', d.owe ? l.debtsIRepay : l.debtsTheyRepay, () => openDebtPaySheet(context, d)),
                  ('pencil', l.edit, () => openDebtSheet(context, debt: d)),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}

/// A titled list in a card, with one action on the right of the title.
class _Section extends StatelessWidget {
  final String title, action;
  final VoidCallback onAction;
  final List<Widget> children;
  final String? empty;
  const _Section({required this.title, required this.action, required this.onAction, required this.children, this.empty});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: empty != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(empty!, style: TextStyle(color: context.c.muted)),
                )
              : Column(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(indent: 64), children[i]],
                  ],
                ),
        ),
      ],
    );
  }
}

/// One account, savings account or debt: icon, name, detail and amount.
class _Row extends StatelessWidget {
  final String icon, title;
  final String? subtitle;
  final Color color;
  final double amount;
  final double? progress;
  final bool signed;
  final VoidCallback onTap;
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.amount,
    this.progress,
    this.signed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.c.muted, fontSize: 12.5),
                    ),
                  if (progress != null) ...[const SizedBox(height: 6), Gauge(value: progress!, color: color, height: 5)],
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedMoney(
              amount,
              signed: signed,
              size: 15.5,
              weight: FontWeight.w600,
              color: amount < 0
                  ? context.c.expense
                  : signed && amount > 0
                  ? context.c.income
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// What can be done with an account, a savings account or a debt.
void _actions(BuildContext context, String title, List<(String, String, VoidCallback)> items) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        for (final (icon, label, onTap) in items)
          ListTile(
            leading: Icon(appIcon(icon)),
            title: Text(label),
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
