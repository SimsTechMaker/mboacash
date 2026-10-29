import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final list = s.monthTxs(s.month);
    final sum = s.sums(list);
    final first = parseIso('${s.month}-01');
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final days = s.month == monthKey(DateTime.now()) ? DateTime.now().day : daysInMonth;
    // Money put into savings counts as an expense in the totals, but it is
    // still saved: add it back for the savings rate.
    final savedNet = list.where((t) => t.type == TxType.save).fold<double>(0, (a, t) => a - t.dir * t.amount);
    final rate = sum.income > 0 ? (sum.income - sum.expense + savedNet) / sum.income : null;

    final out = list.where((t) => s.flow(t) < 0).toList();
    final by = <String, double>{};
    for (final t in out) {
      by[s.flowKey(t)] = (by[s.flowKey(t)] ?? 0) - s.flow(t);
    }
    final rows = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = [...out]..sort((a, b) => b.amount.compareTo(a.amount));
    final ordinary = s.budgetSpent(list);

    final months = [for (var k = 5; k >= 0; k--) shiftMonth(s.month, -k)];
    final bars = months.map((m) {
      final x = s.sums(s.monthTxs(m));
      return BarPair(shortMonth(m), x.income, x.expense, m == s.month);
    }).toList();

    Widget kpi(String l, String v, [Color? c]) => Expanded(
      child: Panel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Label(l),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(v, style: numStyle.copyWith(fontSize: 16, color: c ?? context.c.ink)),
            ),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        const Center(child: MonthNav()),
        const SizedBox(height: 14),
        Row(
          children: [
            kpi('Revenus', f.money(sum.income), context.c.income),
            const SizedBox(width: 10),
            kpi('Dépenses', f.money(sum.expense), context.c.expense),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            kpi("Taux d'épargne", rate == null ? '—' : '${(rate * 100).round()} %', rate != null && rate < 0 ? context.c.expense : null),
            const SizedBox(width: 10),
            kpi('Dépense courante par jour', f.money(ordinary / days)),
          ],
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Où part l'argent", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Text('Les dépenses du mois apparaîtront ici, réparties par catégorie.', style: TextStyle(color: context.c.muted))
              else ...[
                Center(
                  child: Donut(
                    slices: [for (final r in rows) DonutSlice(r.value, slot(s.group(r.key).color))],
                    centerTop: 'Dépenses',
                    centerValue: f.compact(sum.expense),
                  ),
                ),
                const SizedBox(height: 16),
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(appIcon(s.group(r.key).icon), size: 18, color: slot(s.group(r.key).color)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: s.group(r.key).name),
                                          TextSpan(
                                            text: '  ${(r.value / sum.expense * 100).round()} %',
                                            style: TextStyle(color: context.c.muted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Money(r.value, size: 13.5),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Gauge(value: r.value / rows.first.value, color: slot(s.group(r.key).color), height: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Six derniers mois', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  _Key(color: context.c.income, label: 'Revenus'),
                  const SizedBox(width: 10),
                  _Key(color: context.c.expense, label: 'Dépenses'),
                ],
              ),
              const SizedBox(height: 12),
              if (bars.every((b) => b.a == 0 && b.b == 0))
                Text("Rien à comparer pour l'instant.", style: TextStyle(color: context.c.muted))
              else
                PairBars(data: bars, axis: f.compact),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Plus grosses dépenses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              if (top.isEmpty) Text('Aucune dépense ce mois-ci.', style: TextStyle(color: context.c.muted)),
              for (final t in top.take(5))
                TxTile(
                  tx: t,
                  onTap: () => openTxSheet(context, tx: t),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final Color color;
  final String label;
  const _Key({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, color: context.c.muted)),
    ],
  );
}
