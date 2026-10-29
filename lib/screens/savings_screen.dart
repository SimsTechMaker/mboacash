import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../i18n.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/sheets.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final target = s.goals.fold<double>(0, (a, g) => a + g.target);
    final reached = s.goals.where((g) => g.target > 0 && s.goalSaved(g) >= g.target).length;

    return Scaffold(
      appBar: AppBar(title: Text(context.l.typeSave)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openGoalSheet(context),
        icon: Icon(appIcon('plus')),
        label: Text(context.l.savingsNewGoal),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          GradientCard(
            tone: HeroTone.blue,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeroLabel(context.l.savingsTotalLabel),
                      const SizedBox(height: 4),
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        child: AnimatedMoney(s.totalSaved, size: 30, color: Colors.white, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        target > 0
                            ? [context.l.savingsOfTargets(f.money(target)), if (reached > 0) context.l.savingsReachedCount(reached)].join(' · ')
                            : context.l.savingsNoTarget,
                        style: const TextStyle(color: heroSoft, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                if (target > 0) ...[
                  const SizedBox(width: 12),
                  RingProgress(
                    value: s.totalSaved / target,
                    color: Colors.white,
                    size: 72,
                    stroke: 8,
                    child: Text(
                      context.l.savingsPercent('${(s.totalSaved / target * 100).clamp(0, 999).round()}'),
                      style: numStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (s.goals.isEmpty)
            Panel(
              child: EmptyState(icon: 'piggy-bank', text: context.l.savingsEmpty),
            )
          else
            SectionTitle(icon: 'target', text: context.l.savingsMyGoals),
          for (var i = 0; i < s.goals.length; i++) ...[
            FadeIn(
              index: i,
              child: _GoalCard(goal: s.goals[i]),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final g = goal;
    final saved = s.goalSaved(g);
    final pct = g.target > 0 ? (saved / g.target).clamp(0, 1).toDouble() : 0.0;
    final done = g.target > 0 && saved >= g.target;
    String? plan;
    if (g.target > 0 && !done && g.deadline.isNotEmpty) {
      final now = DateTime.now(), end = parseIso(g.deadline);
      final months = ((end.year - now.year) * 12 + end.month - now.month).clamp(1, 1000);
      plan = context.l.savingsPerMonth(f.money((g.target - saved) / months));
    }
    final color = done ? context.c.income : slot(g.color);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RingProgress(
                value: pct,
                color: color,
                size: 58,
                child: Icon(appIcon(done ? 'check' : g.icon), size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
                        ),
                        if (g.sample) ...[
                          const SizedBox(width: 6),
                          Text(
                            context.l.savingsSampleTag,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.c.warn),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: f.money(saved),
                            style: numStyle.copyWith(fontWeight: FontWeight.w600, color: context.c.ink),
                          ),
                          if (g.target > 0) TextSpan(text: '  ${context.l.savingsOfTarget(f.money(g.target))}'),
                        ],
                      ),
                      style: TextStyle(color: context.c.muted, fontSize: 13),
                    ),
                    if (g.deadline.isNotEmpty || plan != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          [if (g.deadline.isNotEmpty) context.l.savingsBefore(longDate(g.deadline)), ?plan].join(' · '),
                          style: TextStyle(color: context.c.muted, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              if (done)
                Pill(context.l.savingsReached, color: context.c.income)
              else if (g.target > 0)
                Pill(context.l.savingsPercent('${(pct * 100).round()}'), color: color),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChipButton(icon: 'plus', label: context.l.savingsPutAside, primary: true, onPressed: () => openGoalMoveSheet(context, g, -1)),
              ActionChipButton(icon: 'minus', label: context.l.savingsWithdraw, onPressed: () => openGoalMoveSheet(context, g, 1)),
              ActionChipButton(
                icon: 'pencil',
                label: context.l.edit,
                onPressed: () => openGoalSheet(context, goal: g),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
