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
    // Savings and debts appear as two extra groups on whichever side their
    // money went this month.
    final by = <String, double>{}, count = <String, int>{};
    for (final t in s.monthTxs(s.month)) {
      final v = s.flow(t);
      if (income ? v <= 0 : v >= 0) continue;
      final k = s.flowKey(t);
      by[k] = (by[k] ?? 0) + v.abs();
      count[k] = (count[k] ?? 0) + 1;
    }
    final total = by.values.fold<double>(0, (a, b) => a + b);
    final cats = [...s.activeCats(income)];
    for (final id in by.keys) {
      final c = s.catById(id);
      if (c != null && !cats.contains(c)) cats.add(c);
      if (c == null) {
        final g = s.group(id);
        cats.add(Category(id: id, name: g.name, icon: g.icon, income: income, color: g.color));
      }
    }
    cats.sort((a, b) => (by[b.id] ?? 0).compareTo(by[a.id] ?? 0));
    final used = cats.where((c) => (by[c.id] ?? 0) > 0).toList();
    final unused = cats.where((c) => (by[c.id] ?? 0) == 0).toList();
    final overCaps = income ? 0 : used.where((c) => c.cap > 0 && (by[c.id] ?? 0) > c.cap).length;
    final l = context.l;
    final monthName = monthLabel(s.month, year: false);
    final monthLower = lang == 'fr' ? monthName.toLowerCase() : monthName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        const Center(child: MonthNav()),
        const SizedBox(height: 14),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(l.totalsExpenses)),
            ButtonSegment(value: true, label: Text(l.totalsIncome)),
          ],
          selected: {income},
          onSelectionChanged: (v) => setState(() => income = v.first),
        ),
        const SizedBox(height: 14),
        GradientCard(
          tone: income ? HeroTone.green : HeroTone.plum,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroLabel(income ? l.catsReceivedIn(monthLower) : l.catsSpentIn(monthLower)),
                    const SizedBox(height: 4),
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      child: AnimatedMoney(total, size: 28, color: Colors.white, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      used.isEmpty
                          ? l.catsNoOps
                          : '${l.catsCount(used.length)} · ${l.catsTop(used.first.name)}'
                                '${overCaps > 0 ? ' · ${l.catsOverCaps(overCaps)}' : ''}',
                      style: const TextStyle(color: heroSoft, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (used.isNotEmpty) ...[
                const SizedBox(width: 12),
                _MiniDonut(values: [for (final c in used) (by[c.id]!, slot(c.color))]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionTitle(
          icon: 'tags',
          text: l.catsByCategory,
          trailing: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(initialTab: 1))),
            child: Text(l.catsManage),
          ),
        ),
        for (var i = 0; i < used.length; i++) ...[
          FadeIn(
            index: i,
            child: _CatCard(cat: used[i], value: by[used[i].id]!, count: count[used[i].id] ?? 0, total: total, income: income, onShowOps: widget.onShowOps),
          ),
          const SizedBox(height: 8),
        ],
        if (unused.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l.catsUnused, style: TextStyle(color: context.c.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in unused)
                Chip(
                  avatar: Icon(appIcon(c.icon), size: 16, color: slot(c.color)),
                  label: Text(c.cap > 0 && !income ? '${c.name} · ${f.money(c.cap)}' : c.name),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CatCard extends StatelessWidget {
  final Category cat;
  final double value, total;
  final int count;
  final bool income;
  final VoidCallback onShowOps;
  const _CatCard({required this.cat, required this.value, required this.count, required this.total, required this.income, required this.onShowOps});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final f = fmtOf(context);
    final l = context.l;
    final cap = income ? 0.0 : cat.cap;
    final pct = cap > 0 ? value / cap : (total > 0 ? value / total : 0.0);
    final color = cap > 0
        ? (pct > 1
              ? context.c.expense
              : pct >= 0.8
              ? context.c.warn
              : slot(cat.color))
        : slot(cat.color);
    return SoftCard(
      onTap: () {
        s.setFilters(cat: cat.id, acc: null);
        onShowOps();
      },
      child: Row(
        children: [
          RingProgress(
            value: pct,
            color: color,
            size: 50,
            child: Icon(appIcon(cat.icon), size: 20, color: slot(cat.color)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  cap > 0 ? '${l.opsCount(count)} · ${l.catsCap(f.money(cap))}' : '${l.opsCount(count)} · ${l.catsShareOfTotal((pct * 100).round())}',
                  style: TextStyle(color: context.c.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedMoney(value, size: 15, weight: FontWeight.w600),
              if (cap > 0) ...[const SizedBox(height: 4), Pill(pct > 1 ? l.catsOver : l.statsPercent('${(pct * 100).round()}'), color: color)],
            ],
          ),
        ],
      ),
    );
  }
}

/// Small ring of the month's split, inside the header card.
class _MiniDonut extends StatelessWidget {
  final List<(double, Color)> values;
  const _MiniDonut({required this.values});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 74,
    height: 74,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, t, _) => CustomPaint(painter: _DonutPainter(values, t)),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> values;
  final double t;
  _DonutPainter(this.values, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 6.2832, false, p..color = Colors.white.withValues(alpha: 0.15));
    final total = values.fold<double>(0, (a, v) => a + v.$1);
    if (total <= 0) return;
    var start = -1.5708;
    for (final (v, c) in values) {
      final sweep = v / total * 6.2832 * t;
      canvas.drawArc(rect, start, sweep > 0.05 ? sweep - 0.03 : sweep, false, p..color = Color.lerp(c, Colors.white, 0.15)!);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.t != t || old.values != values;
}
