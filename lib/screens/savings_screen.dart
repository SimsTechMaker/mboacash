import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final target = s.goals.fold<double>(0, (a, g) => a + g.target);

    return Scaffold(
      appBar: AppBar(title: const Text('Épargne')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openGoalSheet(context),
        icon: Icon(appIcon('plus')),
        label: const Text('Nouvel objectif'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Label('Total mis de côté'),
                const SizedBox(height: 4),
                FittedBox(child: Money(s.totalSaved, size: 28)),
                if (target > 0) Text("sur ${f.money(target)} d'objectifs", style: TextStyle(color: context.c.muted)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (s.goals.isEmpty)
            const Panel(
              child: EmptyState(
                icon: 'piggy-bank',
                text: "Crée un objectif (fonds d'urgence, voyage, voiture…) puis mets de l'argent de côté depuis tes comptes. L'argent épargné quitte le compte et s'ajoute à l'objectif.",
              ),
            ),
          for (final g in s.goals) ...[_GoalCard(goal: g), const SizedBox(height: 10)],
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
    var plan = '';
    if (g.target > 0 && !done && g.deadline.isNotEmpty) {
      final now = DateTime.now(), end = parseIso(g.deadline);
      final months = ((end.year - now.year) * 12 + end.month - now.month).clamp(1, 1000);
      plan = ' · ${f.money((g.target - saved) / months)} par mois pour y arriver';
    }
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: g.icon, color: slot(g.color)),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    if (g.sample) ...[
                      const SizedBox(width: 6),
                      Text(
                        'EXEMPLE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.c.warn),
                      ),
                    ],
                  ],
                ),
              ),
              Money(saved, size: 15),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${g.target > 0 ? 'Objectif ${f.money(g.target)}' : 'Sans montant cible'}${g.deadline.isNotEmpty ? ' · avant le ${longDate(g.deadline)}' : ''}$plan',
                  style: TextStyle(color: context.c.muted, fontSize: 13),
                ),
              ),
              if (done) Pill('Atteint', color: context.c.income) else if (g.target > 0) Pill('${(pct * 100).round()} %', color: context.c.muted),
            ],
          ),
          if (g.target > 0) ...[const SizedBox(height: 8), Gauge(value: pct, color: done ? context.c.income : slot(g.color))],
          const SizedBox(height: 6),
          const Divider(),
          Wrap(
            children: [
              TextButton.icon(icon: Icon(appIcon('plus'), size: 18), label: const Text('Mettre de côté'), onPressed: () => openGoalMoveSheet(context, g, -1)),
              TextButton.icon(icon: Icon(appIcon('minus'), size: 18), label: const Text('Retirer'), onPressed: () => openGoalMoveSheet(context, g, 1)),
              TextButton.icon(
                icon: Icon(appIcon('pencil'), size: 18),
                label: const Text('Modifier'),
                onPressed: () => openGoalSheet(context, goal: g),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
