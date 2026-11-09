import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../i18n.dart';
import '../icons.dart';
import '../state.dart';
import '../summary.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/sheets.dart';

enum _Span { view, previous, months3, months6, year, all }

enum _Topic { moments, categories, biggest, small, habits, noSpend, accounts, savings }

const _topicIcons = {
  _Topic.moments: 'clock',
  _Topic.categories: 'chart-pie',
  _Topic.biggest: 'flame',
  _Topic.small: 'coins',
  _Topic.habits: 'repeat',
  _Topic.noSpend: 'smile',
  _Topic.accounts: 'wallet',
  _Topic.savings: 'piggy-bank',
};

/// The "Résumé intelligent" block of the Statistics tab: a plain Column, to be
/// placed in the parent's scrolling list.
class SmartSummaryView extends StatefulWidget {
  const SmartSummaryView({super.key});

  @override
  State<SmartSummaryView> createState() => _SmartSummaryViewState();
}

class _SmartSummaryViewState extends State<SmartSummaryView> {
  _Span span = _Span.view;
  _Topic topic = _Topic.moments;

  SmartSummary _summary(AppState s) {
    SmartSummary rolling(int months) {
      final p = lastMonthsRange(months);
      return SmartSummary(s, p, previous: rangeBefore(p));
    }

    switch (span) {
      case _Span.view:
        return SmartSummary(s, s.view, previous: s.previousPeriod(s.view));
      case _Span.previous:
        final p = s.previousPeriod(s.view);
        return SmartSummary(s, p, previous: s.previousPeriod(p));
      case _Span.months3:
        return rolling(3);
      case _Span.months6:
        return rolling(6);
      case _Span.year:
        return rolling(12);
      case _Span.all:
        return SmartSummary(s, allTimeRange(s));
    }
  }

  String _spanLabel(_Span x) {
    final l = context.l;
    return switch (x) {
      _Span.view => l.sumRangeCurrent,
      _Span.previous => l.sumRangePrevious,
      _Span.months3 => l.sumRange3Months,
      _Span.months6 => l.sumRange6Months,
      _Span.year => l.sumRangeYear,
      _Span.all => l.sumRangeAll,
    };
  }

  String _topicLabel(_Topic x) {
    final l = context.l;
    return switch (x) {
      _Topic.moments => l.sumTopicMoments,
      _Topic.categories => l.sumTopicCategories,
      _Topic.biggest => l.sumTopicBiggest,
      _Topic.small => l.sumTopicSmall,
      _Topic.habits => l.sumTopicHabits,
      _Topic.noSpend => l.sumTopicNoSpend,
      _Topic.accounts => l.sumTopicAccounts,
      _Topic.savings => l.sumTopicSavings,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sum = _summary(s);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final x in _Span.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(label: Text(_spanLabel(x)), selected: span == x, onSelected: (_) => setState(() => span = x)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!sum.hasData)
          Panel(
            child: EmptyState(icon: 'sparkles', text: context.l.sumEmpty),
          )
        else ...[
          FadeIn(child: _Essentials(sum: sum)),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final x in _Topic.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(appIcon(_topicIcons[x]!), size: 16, color: context.c.accent),
                      label: Text(_topicLabel(x)),
                      selected: topic == x,
                      onSelected: (_) => setState(() => topic = x),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FadeIn(key: ValueKey(topic), child: _analysis(sum)),
        ],
      ],
    );
  }

  Widget _analysis(SmartSummary sum) {
    if (topic != _Topic.savings && sum.spending.isEmpty) {
      return Panel(
        child: EmptyState(icon: _topicIcons[topic]!, text: context.l.sumNoSpending),
      );
    }
    return switch (topic) {
      _Topic.moments => _Moments(sum: sum),
      _Topic.categories => _Categories(sum: sum),
      _Topic.biggest => _Biggest(sum: sum),
      _Topic.small => _Small(sum: sum),
      _Topic.habits => _Habits(sum: sum),
      _Topic.noSpend => _NoSpend(sum: sum),
      _Topic.accounts => _Accounts(sum: sum),
      _Topic.savings => _Savings(sum: sum),
    };
  }
}

class _Essentials extends StatelessWidget {
  final SmartSummary sum;
  const _Essentials({required this.sum});

  @override
  Widget build(BuildContext context) {
    final list = sum.highlights(fmtOf(context).money);
    return GradientCard(
      tone: HeroTone.plum,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(appIcon('sparkles'), size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: HeroLabel(context.l.sumEssential)),
              Text(periodLabel(sum.range), style: const TextStyle(color: heroSoft, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty) Text(context.l.sumEssentialEmpty, style: const TextStyle(color: heroSoft, fontSize: 13.5, height: 1.35)),
          for (final h in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 7, right: 9),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  Expanded(child: Text(h, style: const TextStyle(fontSize: 14, height: 1.35))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The one sentence that says what an analysis means.
class _Insight extends StatelessWidget {
  final String text;
  const _Insight(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.35)),
  );
}

/// An interpretation standing alone, under tiles.
class _InsightPanel extends StatelessWidget {
  final String text;
  const _InsightPanel(this.text);

  @override
  Widget build(BuildContext context) => Panel(padding: const EdgeInsets.fromLTRB(16, 16, 16, 6), child: _Insight(text));
}

/// A label with its amount above a bar scaled against [max].
class _Bar extends StatelessWidget {
  final String label;
  final double value, max;
  final Color color;
  final String? icon, note;
  final Widget? badge;
  const _Bar({required this.label, required this.value, required this.max, required this.color, this.icon, this.note, this.badge});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        if (icon != null) ...[Icon(appIcon(icon!), size: 18, color: color), const SizedBox(width: 10)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (badge != null) ...[const SizedBox(width: 6), badge!],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Money(value, size: 13.5),
                ],
              ),
              if (note != null) Text(note!, style: TextStyle(color: context.c.muted, fontSize: 12)),
              const SizedBox(height: 4),
              Gauge(value: max > 0 ? value / max : 0, color: color, height: 4),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A figure with its label, for a row of [Expanded] tiles.
class _Tile extends StatelessWidget {
  final String icon, label, value;
  final Color? color;
  const _Tile({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Expanded(
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
          Text(label, maxLines: 2, style: TextStyle(color: context.c.muted, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _Moments extends StatelessWidget {
  final SmartSummary sum;
  const _Moments({required this.sum});

  Widget _block(BuildContext context, String icon, String title, String? insight, List<String> labels, List<double> values, int? peak, {String? foot}) {
    final top = values.reduce((a, b) => a > b ? a : b);
    final accent = context.c.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(icon: icon, text: title),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Insight(insight ?? context.l.sumNotEnough),
              for (var i = 0; i < labels.length; i++)
                _Bar(label: labels[i], value: values[i], max: top, color: i == peak ? accent : accent.withValues(alpha: 0.45)),
              if (foot != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(foot, style: TextStyle(color: context.c.muted, fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    String cap(String x) => x[0].toUpperCase() + x.substring(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _block(context, 'calendar', l.sumWeekTitle, sum.weekdayInsight, [for (var i = 0; i < 7; i++) cap(weekdayName(i))], sum.byWeekday, sum.peakWeekday),
        const SizedBox(height: 12),
        _block(
          context,
          'chart-column',
          l.sumMonthTitle,
          sum.monthPartInsight,
          [l.sumPartStart, l.sumPartMiddle, l.sumPartEnd],
          sum.byMonthPart,
          sum.peakMonthPart,
        ),
        const SizedBox(height: 12),
        _block(
          context,
          'clock',
          l.sumDayTitle,
          sum.timeOfDayInsight,
          [l.sumTimeMorning, l.sumTimeAfternoon, l.sumTimeEvening, l.sumTimeNight],
          sum.byTimeOfDay,
          sum.peakTimeOfDay,
          foot: l.sumTimedSample(sum.timedCount),
        ),
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  final SmartSummary sum;
  const _Categories({required this.sum});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final f = fmtOf(context);
    final top = sum.categories.first.total;
    final jump = sum.categoryJumpInsight(f.money);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Insight(sum.categoryInsight(f.money) ?? l.sumNotEnough),
          if (jump != null) _Insight(jump),
          for (final c in sum.categories)
            _Bar(
              label: c.name,
              icon: c.icon,
              value: c.total,
              max: top,
              color: slot(c.color),
              badge: c.isNew
                  ? Pill(l.sumNew, color: context.c.warn)
                  : c.change == null || (c.change! * 100).round() == 0
                  ? null
                  : Pill(
                      l.statsPercent('${c.change! > 0 ? '+' : ''}${(c.change! * 100).round()}'),
                      color: c.change! > 0 ? context.c.expense : context.c.income,
                    ),
            ),
          if (sum.baseline != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                sum.comparedSoFar ? l.sumComparedSoFar(periodLabel(sum.baseline!)) : l.sumCompared(periodLabel(sum.baseline!)),
                style: TextStyle(color: context.c.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _Biggest extends StatelessWidget {
  final SmartSummary sum;
  const _Biggest({required this.sum});

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sum.biggestInsight != null) _Insight(sum.biggestInsight!),
        for (final t in sum.biggest)
          TxTile(
            tx: t,
            onTap: () => openTxSheet(context, tx: t),
          ),
      ],
    ),
  );
}

class _Small extends StatelessWidget {
  final SmartSummary sum;
  const _Small({required this.sum});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final f = fmtOf(context);
    final insight = sum.smallInsight(f.money);
    if (insight == null) {
      return Panel(
        child: EmptyState(icon: 'coins', text: l.sumSmallNone),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Tile(icon: 'receipt', label: l.sumSmallCount, value: '${sum.smallCount}'),
            const SizedBox(width: 10),
            _Tile(icon: 'coins', label: l.sumSmallTotal, value: f.money(sum.smallTotal)),
            const SizedBox(width: 10),
            _Tile(icon: 'chart-pie', label: l.sumSmallShare, value: l.statsPercent('${(sum.smallTotal / sum.spent * 100).round()}')),
          ],
        ),
        const SizedBox(height: 10),
        _InsightPanel(insight),
      ],
    );
  }
}

class _Habits extends StatelessWidget {
  final SmartSummary sum;
  const _Habits({required this.sum});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final f = fmtOf(context);
    final insight = sum.habitInsight(f.money);
    if (insight == null) {
      return Panel(
        child: EmptyState(icon: 'repeat', text: l.sumHabitsNone),
      );
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Insight(insight),
          for (final h in sum.habits)
            _Bar(label: h.note, note: l.sumHabitRow(h.count, f.money(h.average)), value: h.total, max: sum.habits.first.total, color: context.c.accent),
        ],
      ),
    );
  }
}

class _NoSpend extends StatelessWidget {
  final SmartSummary sum;
  const _NoSpend({required this.sum});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Tile(icon: 'smile', label: l.sumNoSpendTile, value: '${sum.noSpendDays}'),
            const SizedBox(width: 10),
            _Tile(icon: 'trophy', label: l.sumStreakTile, value: '${sum.longestStreak}'),
            const SizedBox(width: 10),
            _Tile(icon: 'calendar', label: l.sumElapsedTile, value: '${sum.elapsedDays}'),
          ],
        ),
        const SizedBox(height: 10),
        _InsightPanel(sum.noSpendInsight ?? l.sumNotEnough),
      ],
    );
  }
}

class _Accounts extends StatelessWidget {
  final SmartSummary sum;
  const _Accounts({required this.sum});

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sum.accountInsight != null) _Insight(sum.accountInsight!),
        for (final a in sum.accounts)
          _Bar(label: a.name, icon: a.icon, note: context.l.sumAccountRow(a.count), value: a.total, max: sum.accounts.first.total, color: context.c.accent),
      ],
    ),
  );
}

class _Savings extends StatelessWidget {
  final SmartSummary sum;
  const _Savings({required this.sum});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final f = fmtOf(context);
    final rate = sum.savingsRate;
    final insight = sum.savingsInsight(f.money);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Tile(icon: 'piggy-bank', label: l.sumNetSaved, value: f.money(sum.netSaved, signed: true)),
            const SizedBox(width: 10),
            _Tile(
              icon: rate != null && rate < 0 ? 'trending-down' : 'trending-up',
              label: l.statsSavingsRate,
              value: rate == null ? '—' : l.statsPercent('${(rate * 100).round()}'),
              color: rate != null && rate < 0 ? context.c.expense : null,
            ),
          ],
        ),
        if (insight != null) ...[const SizedBox(height: 10), _InsightPanel(insight)],
        if (sum.goals.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionTitle(icon: 'target', text: l.sumGoalsTitle),
          for (var i = 0; i < sum.goals.length; i++) ...[
            FadeIn(
              index: i,
              child: _GoalPace(goal: sum.goals[i]),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _GoalPace extends StatelessWidget {
  final SumGoal goal;
  const _GoalPace({required this.goal});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final f = fmtOf(context);
    final g = goal.goal;
    final color = slot(g.color);
    final text = goal.eta != null
        ? l.sumGoalEta(f.money(goal.perMonth!), longDate(goal.eta!))
        : goal.perMonth != null
        ? l.sumGoalFar(f.money(goal.perMonth!))
        : l.sumGoalNoPace;
    return SoftCard(
      child: Row(
        children: [
          IconBadge(icon: g.icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        g.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (goal.behind) Pill(l.sumGoalLate, color: context.c.warn),
                  ],
                ),
                const SizedBox(height: 4),
                Gauge(value: goal.saved / g.target, color: color, height: 4),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                if (g.deadline.isNotEmpty) Text(l.savingsBefore(longDate(g.deadline)), style: TextStyle(color: context.c.muted, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
