import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final VoidCallback onShowOps;
  const CategoriesScreen({super.key, required this.onShowOps});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool income = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final type = income ? TxType.income : TxType.expense;
    final list = s.monthTxs(s.month).where((t) => t.type == type);
    final by = <String, double>{}, count = <String, int>{};
    for (final t in list) {
      by[t.cat] = (by[t.cat] ?? 0) + t.amount;
      count[t.cat] = (count[t.cat] ?? 0) + 1;
    }
    final total = by.values.fold<double>(0, (a, b) => a + b);
    final cats = [...s.activeCats(income)];
    for (final id in by.keys) {
      final c = s.catById(id);
      if (c != null && !cats.contains(c)) cats.add(c);
    }
    cats.sort((a, b) => (by[b.id] ?? 0).compareTo(by[a.id] ?? 0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        const Center(child: MonthNav()),
        const SizedBox(height: 14),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: false, label: Text('Dépenses')),
            ButtonSegment(value: true, label: Text('Revenus')),
          ],
          selected: {income},
          onSelectionChanged: (v) => setState(() => income = v.first),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '${income ? 'Reçu' : 'Dépensé'} en ${monthLabel(s.month, year: false).toLowerCase()} : ${f.money(total)}',
                style: TextStyle(color: context.c.muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(initialTab: 1))),
              child: const Text('Gérer'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final c in cats) ...[
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                s.setFilters(cat: c.id, acc: null);
                widget.onShowOps();
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    IconBadge(icon: c.icon, color: slot(c.color)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              Money(by[c.id] ?? 0, size: 14),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (_) {
                              final v = by[c.id] ?? 0;
                              final cap = income ? 0.0 : c.cap;
                              final pct = cap > 0 ? v / cap : (total > 0 ? v / total : 0.0);
                              final color = cap > 0
                                  ? (pct > 1
                                        ? context.c.expense
                                        : pct >= 0.8
                                        ? context.c.warn
                                        : slot(c.color))
                                  : slot(c.color);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${plural(count[c.id] ?? 0, 'opération')}${cap > 0 ? ' · plafond ${f.money(cap)}' : ''}',
                                          style: TextStyle(color: context.c.muted, fontSize: 12.5),
                                        ),
                                      ),
                                      if (cap > 0)
                                        Pill(pct > 1 ? 'Dépassé' : '${(pct * 100).round()} %', color: color)
                                      else
                                        Text('${(pct * 100).round()} %', style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Gauge(value: pct, color: color, height: 6),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
