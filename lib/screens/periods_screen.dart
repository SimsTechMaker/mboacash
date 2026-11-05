import 'dart:convert';

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

String periodKindName(AppLocalizations l, String kind) => switch (kind) {
  '2weeks' => l.periodKind2weeks,
  'quarter' => l.periodKindQuarter,
  'semester' => l.periodKindSemester,
  'custom' => l.periodKindCustom,
  _ => l.periodKindMonth,
};

/// The rhythm of the budget, the open period and the history of closed ones.
class PeriodsScreen extends StatelessWidget {
  const PeriodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final l = context.l;
    final open = s.openPeriod;
    final history = s.closed.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.periodsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroLabel(l.periodOpenLabel),
                const SizedBox(height: 4),
                Text(
                  periodLabel(open),
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text('${periodKindName(l, s.settings.periodKind)} · ${l.periodDays(open.days)}', style: const TextStyle(color: heroSoft, fontSize: 12.5)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: HeroStat(label: l.periodCarried, icon: 'history', value: s.carriedInto(open)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: HeroStat(label: l.periodAvailable, icon: 'wallet', value: s.spendableAt(open.end)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: Icon(appIcon('sliders-horizontal'), size: 18),
                  label: Text(l.periodChange),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClosePeriodScreen())),
                  icon: Icon(appIcon('calendar-check'), size: 18),
                  label: Text(l.periodClose),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionTitle(icon: 'history', text: l.periodHistory),
          if (history.isEmpty)
            Panel(
              child: EmptyState(icon: 'history', text: l.periodHistoryEmpty),
            ),
          for (var i = 0; i < history.length; i++) ...[
            FadeIn(
              index: i,
              child: SoftCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClosedPeriodScreen(id: history[i].id))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(periodLabel(history[i].period), style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            l.periodHistorySub(f.money(history[i].income), f.money(history[i].expense)),
                            style: TextStyle(color: context.c.muted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(f.money(history[i].closing), style: numStyle.copyWith(fontWeight: FontWeight.w600)),
                        Text(l.periodLeft, style: TextStyle(color: context.c.muted, fontSize: 11.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

Future<void> _openEditor(BuildContext context) {
  final s = context.read<AppState>();
  return showFormSheet(
    context,
    title: context.l.periodChange,
    builder: (_) => _PeriodForm(state: s),
  );
}

class _PeriodForm extends StatefulWidget {
  final AppState state;
  const _PeriodForm({required this.state});
  @override
  State<_PeriodForm> createState() => _PeriodFormState();
}

class _PeriodFormState extends State<_PeriodForm> {
  late String kind = widget.state.settings.periodKind;
  late String start = widget.state.openPeriod.start;
  late String end = widget.state.openPeriod.end;

  /// The open period cannot overlap one already closed.
  String? get _firstDay => widget.state.closed.isEmpty ? null : shiftDays(widget.state.closed.last.end, 1);

  void _setKind(String k) => setState(() {
    kind = k;
    if (k != 'custom') end = Period.from(start, k, anchor: parseIso(start).day).end;
  });

  void _setStart(String d) => setState(() {
    start = d;
    if (kind != 'custom') {
      end = Period.from(d, kind, anchor: parseIso(d).day).end;
    } else if (end.compareTo(d) < 0) {
      end = d;
    }
  });

  Future<void> save() async {
    final l = context.l;
    final first = _firstDay;
    if (first != null && start.compareTo(first) < 0) return toast(context, l.periodStartTooEarly(longDate(first)));
    if (end.compareTo(start) < 0) return toast(context, l.periodEndBeforeStart);
    await widget.state.setPeriod(kind, start, end);
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, l.periodSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final k in periodKinds) ChoiceChip(label: Text(periodKindName(l, k)), selected: kind == k, onSelected: (_) => _setKind(k))],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DateField(label: l.periodStart, value: start, onChanged: _setStart),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: kind == 'custom'
                  ? DateField(label: l.periodEnd, value: end, onChanged: (d) => setState(() => end = d))
                  : InputDecorator(
                      decoration: InputDecoration(labelText: l.periodEnd),
                      child: Text(longDate(end)),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(l.periodFormHelp, style: TextStyle(color: context.c.muted, fontSize: 13)),
        const SizedBox(height: 16),
        FilledButton(onPressed: save, child: Text(l.save)),
      ],
    );
  }
}

/// One line of a period's summary.
Widget _line(BuildContext context, String label, double value, {bool signed = false, bool strong = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    children: [
      Expanded(
        child: Text(label, style: TextStyle(fontWeight: strong ? FontWeight.w600 : FontWeight.w400)),
      ),
      Text(
        fmtOf(context).money(value, signed: signed),
        style: numStyle.copyWith(fontWeight: strong ? FontWeight.w600 : FontWeight.w500),
      ),
    ],
  ),
);

/// Opening, movements and closing of a period, then its biggest expenses.
class _Summary extends StatelessWidget {
  final ClosedPeriod c;
  const _Summary({required this.c});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final f = fmtOf(context);
    final top = (jsonDecode(c.top) as List).cast<List>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            children: [
              _line(context, l.periodCarried, c.opening),
              _line(context, l.totalsIncome, c.income, signed: true),
              _line(context, l.totalsExpenses, -c.expense, signed: true),
              const Divider(),
              _line(context, l.periodLeft, c.closing, strong: true),
              if (c.saved != 0) _line(context, l.periodSaved2, c.saved),
              if (c.budget > 0) _line(context, l.periodBudgetSpent(f.money(c.budget)), c.spent),
            ],
          ),
        ),
        if (top.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionTitle(icon: 'chart-pie', text: l.periodTop),
          Panel(child: Column(children: [for (final t in top) _line(context, '${t[0]}', (t[1] as num).toDouble())])),
        ],
        const SizedBox(height: 8),
        Text(
          l.periodCount(c.count),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.c.muted, fontSize: 12.5),
        ),
      ],
    );
  }
}

/// The review before closing: what happened, and what moves on.
class ClosePeriodScreen extends StatelessWidget {
  const ClosePeriodScreen({super.key});

  Future<void> _close(BuildContext context, double left) async {
    final s = context.read<AppState>();
    final l = context.l;
    final next = s.openPeriod.next(s.settings.periodKind, s.settings.periodAnchor);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l.periodCloseConfirmTitle),
        content: Text(ctx.l.periodCloseConfirmText(periodLabel(next), fmtOf(context).money(left))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l.periodClose)),
        ],
      ),
    );
    if (ok != true) return;
    await s.closePeriod();
    if (!context.mounted) return;
    Navigator.pop(context);
    toast(context, l.periodClosed);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final l = context.l;
    final p = s.openPeriod;
    final c = s.summarize(p);
    final due = s.dueScheduled.where((x) => p.contains(x.next)).length;

    return Scaffold(
      appBar: AppBar(title: Text(l.periodReview)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroLabel(periodLabel(p)),
                const SizedBox(height: 4),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: AnimatedMoney(c.closing, size: 30, color: Colors.white, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(l.periodLeftHelp, style: const TextStyle(color: heroSoft, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (due > 0) ...[
            SoftCard(
              child: Row(
                children: [
                  IconBadge(icon: 'calendar-clock', color: context.c.warn),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.periodDueWarning(due))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _Summary(c: c),
          if (c.closing > 0 && s.goals.isNotEmpty) ...[
            const SizedBox(height: 18),
            SectionTitle(icon: 'piggy-bank', text: l.periodPutAside(f.money(c.closing))),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final g in s.goals) ActionChipButton(icon: g.icon, label: g.name, onPressed: () => openGoalMoveSheet(context, g, -1))],
            ),
          ],
          const SizedBox(height: 22),
          if (s.periodEnded)
            FilledButton.icon(onPressed: () => _close(context, c.closing), icon: Icon(appIcon('calendar-check')), label: Text(l.periodClose))
          else
            Text(
              l.periodNotEnded(longDate(p.end)),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.muted),
            ),
        ],
      ),
    );
  }
}

/// A stored summary from the history.
class ClosedPeriodScreen extends StatelessWidget {
  final String id;
  const ClosedPeriodScreen({super.key, required this.id});

  Future<void> _reopen(BuildContext context) async {
    final s = context.read<AppState>();
    final l = context.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l.periodReopenTitle),
        content: Text(ctx.l.periodReopenText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l.periodReopen)),
        ],
      ),
    );
    if (ok != true) return;
    await s.reopenLast();
    if (!context.mounted) return;
    Navigator.pop(context);
    toast(context, l.periodReopened);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = context.l;
    final c = s.closed.where((x) => x.id == id).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(c == null ? l.periodsTitle : periodLabel(c.period))),
      body: c == null
          ? const SizedBox()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _Summary(c: c),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    s.setView(c.period);
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                  icon: Icon(appIcon('list'), size: 18),
                  label: Text(l.periodSeeOps),
                ),
                if (s.closed.last.id == id) ...[const SizedBox(height: 8), TextButton(onPressed: () => _reopen(context), child: Text(l.periodReopen))],
              ],
            ),
    );
  }
}
