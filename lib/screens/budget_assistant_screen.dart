import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
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

  static const rules = {
    Rule.r503020: ('50 / 30 / 20', 'La règle classique : 50 % pour les besoins, 30 % pour les envies, 20 % pour l\'épargne.'),
    Rule.r702010: ('70 / 20 / 10', 'Plus réaliste quand le loyer et la nourriture pèsent lourd : 70 % besoins, 20 % envies, 10 % épargne.'),
    Rule.history: ('Mes habitudes', 'Part de tes dépenses réelles des 3 derniers mois, et garde le reste pour l\'épargne.'),
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
    toast(context, 'Budget et plafonds appliqués');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final value = parseAmount(income.text) ?? 0;
    final p = value > 0 ? Insights.of(s).preset(rule, value) : null;
    final needIds = Insights.needs;

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
      appBar: AppBar(title: const Text('Assistant budget')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Indique ce que tu gagnes par mois : l'assistant propose un budget, un plafond par catégorie et ce qu'il faut mettre de côté pour tes objectifs.",
            style: TextStyle(color: context.c.muted),
          ),
          const SizedBox(height: 14),
          AmountField(controller: income, label: 'Revenus mensuels'),
          if (Insights.of(s).avgIncome(monthKey(DateTime.now())) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Pré-rempli avec ta moyenne des 3 derniers mois.', style: TextStyle(color: context.c.muted, fontSize: 12.5)),
            ),
          const SizedBox(height: 16),
          const Label('Méthode'),
          const SizedBox(height: 8),
          for (final e in rules.entries)
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
                    const Text('Proposition', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    line('wallet', context.c.accent, 'Budget mensuel (dépenses courantes)', p.budget),
                    line(
                      'house',
                      slot('c3'),
                      'Besoins',
                      p.caps.entries.where((e) => needIds.contains(e.key)).fold(0.0, (a, e) => a + e.value),
                      sub: 'Logement, factures, alimentation, transport…',
                    ),
                    line(
                      'party-popper',
                      slot('c6'),
                      'Envies',
                      p.caps.entries.where((e) => !needIds.contains(e.key)).fold(0.0, (a, e) => a + e.value),
                      sub: 'Restaurant, loisirs, shopping…',
                    ),
                    line('piggy-bank', slot('c2'), 'Épargne', p.saving),
                    const Divider(height: 24),
                    const Label('Plafond par catégorie'),
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
                    const Label('Objectifs d\'épargne'),
                    const SizedBox(height: 6),
                    if (s.goals.isEmpty) ...[
                      Text(
                        "Aucun objectif pour l'instant. Commence par un fonds d'urgence d'environ 3 mois de dépenses, soit à peu près ${f.money(p.budget * 3)}.",
                        style: TextStyle(color: context.c.muted),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsScreen())),
                          child: const Text('Créer un objectif'),
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
                            Text('${f.money(p.goals[g.id]!)} / mois', style: numStyle),
                          ],
                        ),
                      ),
                    if (s.goals.isNotEmpty && p.goals.isEmpty) Text('Tous tes objectifs sont atteints.', style: TextStyle(color: context.c.muted)),
                    const SizedBox(height: 16),
                    FilledButton.icon(icon: Icon(appIcon('check')), label: const Text('Appliquer ce budget'), onPressed: () => apply(p)),
                    const SizedBox(height: 6),
                    Text(
                      'Remplace ton budget mensuel et les plafonds de tes catégories de dépenses. Tu pourras les modifier ensuite dans Paramètres.',
                      style: TextStyle(color: context.c.muted, fontSize: 12.5),
                    ),
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
