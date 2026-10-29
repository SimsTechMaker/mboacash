import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../i18n.dart';
import '../icons.dart';
import '../insights.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'savings_screen.dart';

/// Proposes a budget from the user's income and goals, then applies it.
class BudgetAssistantScreen extends StatefulWidget {
  const BudgetAssistantScreen({super.key});
  @override
  State<BudgetAssistantScreen> createState() => _BudgetAssistantScreenState();
}

class _BudgetAssistantScreenState extends State<BudgetAssistantScreen> {
  final income = TextEditingController();
  Rule rule = Rule.r503020;

  static Map<Rule, (String, String)> rules(AppLocalizations l) => {
    Rule.r503020: ('50 / 30 / 20', l.assistantRule503020Desc),
    Rule.r702010: ('70 / 20 / 10', l.assistantRule702010Desc),
    Rule.history: (l.assistantRuleHistory, l.assistantRuleHistoryDesc),
  };

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final month = monthKey(DateTime.now());
    var v = Insights.of(s).avgIncome(month);
    if (v <= 0) v = s.sums(s.monthTxs(month)).income;
    if (v > 0) income.text = Fmt(s.settings.currency).number((v / 1000).round() * 1000.0);
    income.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    income.dispose();
    super.dispose();
  }

  Future<void> apply(Preset p) async {
    final s = context.read<AppState>();
    final next = s.settings.copy();
    next.budget = p.budget;
    for (final c in next.cats) {
      if (!c.income) c.cap = p.caps[c.id] ?? 0;
    }
    await s.saveSettings(next);
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, context.l.assistantApplied);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final value = parseAmount(income.text) ?? 0;
    final p = value > 0 ? Insights.of(s).preset(rule, value) : null;
    final needIds = Insights.needs;
    final l = context.l;

    Widget line(String icon, Color color, String label, double v, {String? sub}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (sub != null) Text(sub, style: TextStyle(color: context.c.muted, fontSize: 12)),
              ],
            ),
          ),
          Text(f.money(v), style: numStyle.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.assistantTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.assistantIntro, style: TextStyle(color: context.c.muted)),
          const SizedBox(height: 14),
          AmountField(controller: income, label: l.assistantIncomeLabel),
          if (Insights.of(s).avgIncome(monthKey(DateTime.now())) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(l.assistantPrefilled, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
            ),
          const SizedBox(height: 16),
          Label(l.assistantMethod),
          const SizedBox(height: 8),
          for (final e in rules(l).entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: rule == e.key ? context.c.accent : context.c.line, width: rule == e.key ? 2 : 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => rule = e.key),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(e.value.$2, style: TextStyle(color: context.c.muted, fontSize: 13)),
                            ],
                          ),
                        ),
                        AnimatedScale(
                          scale: rule == e.key ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(appIcon('check'), color: context.c.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (p != null) ...[
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Panel(
                key: ValueKey('${p.rule}-${p.income}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.assistantProposal, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    line('wallet', context.c.accent, l.assistantMonthlyBudget, p.budget),
                    line(
                      'house',
                      slot('c3'),
                      l.assistantNeeds,
                      p.caps.entries.where((e) => needIds.contains(e.key)).fold(0.0, (a, e) => a + e.value),
                      sub: l.assistantNeedsSub,
                    ),
                    line(
                      'party-popper',
                      slot('c6'),
                      l.assistantWants,
                      p.caps.entries.where((e) => !needIds.contains(e.key)).fold(0.0, (a, e) => a + e.value),
                      sub: l.assistantWantsSub,
                    ),
                    line('piggy-bank', slot('c2'), l.typeSave, p.saving),
                    const Divider(height: 24),
                    Label(l.assistantCapPerCat),
                    const SizedBox(height: 6),
                    for (final e in p.caps.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(appIcon(s.group(e.key).icon), size: 18, color: slot(s.group(e.key).color)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(s.group(e.key).name)),
                            Text(f.money(e.value), style: numStyle),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Label(l.assistantGoals),
                    const SizedBox(height: 6),
                    if (s.goals.isEmpty) ...[
                      Text(l.assistantNoGoals(f.money(p.budget * 3)), style: TextStyle(color: context.c.muted)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsScreen())),
                          child: Text(l.assistantCreateGoal),
                        ),
                      ),
                    ],
                    for (final g in s.goals.where((g) => p.goals.containsKey(g.id)))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(appIcon(g.icon), size: 18, color: slot(g.color)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(g.name)),
                            Text(l.assistantPerMonth(f.money(p.goals[g.id]!)), style: numStyle),
                          ],
                        ),
                      ),
                    if (s.goals.isNotEmpty && p.goals.isEmpty) Text(l.assistantGoalsReached, style: TextStyle(color: context.c.muted)),
                    const SizedBox(height: 16),
                    FilledButton.icon(icon: Icon(appIcon('check')), label: Text(l.assistantApply), onPressed: () => apply(p)),
                    const SizedBox(height: 6),
                    Text(l.assistantApplyNote, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
