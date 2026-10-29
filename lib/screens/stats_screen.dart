import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../i18n.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/sheets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final l = context.l;
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

    final prev = s.sums(s.monthTxs(shiftMonth(s.month, -1))).expense;
    final delta = prev > 0 ? (sum.expense - prev) / prev : null;

    Widget tile(String icon, String label, String value, {Color? color}) => Expanded(
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(appIcon(icon), size: 18, color: color ?? context.c.accent),
            const SizedBox(height: 8),
            FittedBox(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: numStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? context.c.ink),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, maxLines: 2, style: TextStyle(color: context.c.muted, fontSize: 11.5)),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        const Center(child: MonthNav()),
        const SizedBox(height: 14),
        GradientCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroStat(label: l.totalsIncome, icon: 'arrow-down-left', value: sum.income),
                    const SizedBox(height: 12),
                    HeroStat(label: l.totalsExpenses, icon: 'arrow-up-right', value: sum.expense),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  RingProgress(
                    value: rate == null ? 0 : rate.clamp(0, 1).toDouble(),
                    color: const Color(0xFF9BE3C6),
                    size: 84,
                    stroke: 9,
                    child: Text(
                      rate == null ? '—' : l.statsPercent('${(rate * 100).round()}'),
                      style: numStyle.copyWith(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(l.statsSavingsRate, style: const TextStyle(color: heroSoft, fontSize: 11.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            tile('calendar', l.statsDailySpend, f.money(ordinary / days)),
            const SizedBox(width: 10),
            tile('receipt', l.statsOpsThisMonth, '${list.length}'),
            const SizedBox(width: 10),
            tile(
              delta != null && delta > 0 ? 'trending-up' : 'trending-down',
              l.statsVsPrevMonth,
              delta == null ? '—' : l.statsPercent('${delta > 0 ? '+' : ''}${(delta * 100).round()}'),
              color: delta == null
                  ? null
                  : delta > 0
                  ? context.c.expense
                  : context.c.income,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionTitle(icon: 'chart-pie', text: l.statsWhereMoneyGoes),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rows.isEmpty)
                Text(l.statsWhereEmpty, style: TextStyle(color: context.c.muted))
              else ...[
                Center(
                  child: Donut(
                    slices: [for (final r in rows) DonutSlice(r.value, slot(s.group(r.key).color))],
                    centerTop: l.totalsExpenses,
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
                                            text: '  ${l.statsPercent('${(r.value / sum.expense * 100).round()}')}',
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
        const SizedBox(height: 18),
        SectionTitle(
          icon: 'chart-column',
          text: l.statsSixMonths,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Key(color: context.c.income, label: l.totalsIncome),
              const SizedBox(width: 10),
              _Key(color: context.c.expense, label: l.totalsExpenses),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bars.every((b) => b.a == 0 && b.b == 0))
                Text(l.statsNothingToCompare, style: TextStyle(color: context.c.muted))
              else
                PairBars(data: bars, axis: f.compact),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionTitle(icon: 'flame', text: l.statsTopExpenses),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (top.isEmpty) Text(l.statsNoExpenses, style: TextStyle(color: context.c.muted)),
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
