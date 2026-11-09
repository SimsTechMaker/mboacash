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
import '../widgets/design.dart';
import '../widgets/sheets.dart';
import 'agenda_screen.dart';
import 'budget_assistant_screen.dart';
import 'periods_screen.dart';

/// Home: month summary, forecast, advice, upcoming recurring movements, journal.
class OpsScreen extends StatelessWidget {
  const OpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final month = s.periodTxs(s.view);
    final current = s.view.contains(todayIso());
    final ins = Insights.of(s);
    final l = context.l;

    final scoped = month.where((t) => s.accFilter == null || s.accountOf(t) == s.accFilter || t.to == s.accFilter).toList();
    final usedKeys = scoped.map(s.flowKey).toSet().toList();
    final catFilter = usedKeys.contains(s.catFilter) ? s.catFilter : null;
    final list = scoped.where((t) => catFilter == null || s.flowKey(t) == catFilter).toList()
      ..sort((a, b) => b.date.compareTo(a.date) != 0 ? b.date.compareTo(a.date) : b.created.compareTo(a.created));
    final byDay = <String, List<Tx>>{};
    for (final t in list) {
      byDay.putIfAbsent(t.date, () => []).add(t);
    }
    final advice = s.txs.isEmpty ? <Insight>[] : ins.advice(s.view, (v) => f.money(v));
    final due = current ? ins.dueThisMonth : <Recurring>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        const Center(child: MonthNav()),
        const SizedBox(height: 14),
        if (s.periodEnded) ...[const _PeriodEndedCard(), const SizedBox(height: 12)],
        if (s.dueScheduled.isNotEmpty) ...[const _DueScheduledCard(), const SizedBox(height: 12)],
        _Hero(month: month),
        if (s.viewingOpen && !s.periodEnded && s.txs.isNotEmpty) ...[const SizedBox(height: 12), _ForecastCard(forecast: ins.forecast())],
        if (advice.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionTitle(icon: 'sparkles', text: l.opsAdvice),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: advice.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _AdviceCard(insight: advice[i]),
            ),
          ),
        ],
        if (due.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionTitle(icon: 'repeat', text: l.opsDueTitle),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < due.length && i < 5; i++) ...[if (i > 0) const Divider(), _RecurringTile(r: due[i])],
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(l.opsJournal, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (list.isNotEmpty) Label(l.opsCount(list.length)),
                ],
              ),
              if (s.accFilter != null || usedKeys.length > 1) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (s.accFilter != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            avatar: Icon(appIcon(s.accById(s.accFilter!)?.icon ?? 'wallet'), size: 16),
                            label: Text(s.accById(s.accFilter!)?.name ?? ''),
                            onDeleted: () => s.setFilters(cat: s.catFilter, acc: null),
                          ),
                        ),
                      if (usedKeys.length > 1) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(l.opsFilterAll),
                            selected: catFilter == null,
                            onSelected: (_) => s.setFilters(cat: null, acc: s.accFilter),
                          ),
                        ),
                        for (final id in usedKeys)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              avatar: Icon(appIcon(s.group(id).icon), size: 16, color: slot(s.group(id).color)),
                              label: Text(s.group(id).name),
                              selected: catFilter == id,
                              onSelected: (_) => s.setFilters(cat: id, acc: s.accFilter),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
              if (list.isEmpty)
                EmptyState(
                  icon: 'receipt',
                  text: s.txs.isEmpty
                      ? l.opsEmptyFirst
                      : s.accFilter != null
                      ? l.opsEmptyMonthAccount(periodLabel(s.view))
                      : l.opsEmptyMonth(periodLabel(s.view)),
                  action: s.txs.isEmpty
                      ? OutlinedButton(
                          onPressed: () async {
                            await s.loadSamples();
                            if (context.mounted) toast(context, context.l.opsSamplesLoaded);
                          },
                          child: Text(l.opsLoadSamples),
                        )
                      : null,
                ),
              for (final e in byDay.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Row(
                    children: [
                      Text(dayLabel(e.key), style: TextStyle(color: context.c.muted, fontSize: 13)),
                      const Spacer(),
                      Builder(
                        builder: (_) {
                          // What the day did to the money available, every kind of movement included.
                          final net = e.value.fold<double>(0, (a, t) => a + s.effects(t).fold(0.0, (b, x) => b + x.delta));
                          return net == 0
                              ? const SizedBox()
                              : FitNumber(
                                  child: Text(f.money(net, signed: true), style: numStyle.copyWith(color: context.c.muted, fontSize: 13)),
                                );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                for (final t in e.value)
                  TxTile(
                    tx: t,
                    onTap: () => openTxSheet(context, tx: t),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Carried over, income, expenses and money moved: the lines that take the
/// period's start to the money available. Moves only show when there are some.
class _CashLines extends StatelessWidget {
  final double carried, income, expense;
  final ({double savings, double debts, double adjust}) moves;
  final Color color, soft;
  const _CashLines({required this.carried, required this.income, required this.expense, required this.moves, required this.color, required this.soft});

  @override
  Widget build(BuildContext context) {
    final f = fmtOf(context);
    final l = context.l;
    Widget line(String icon, String label, double v, {bool signed = true}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(appIcon(icon), size: 15, color: soft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(color: soft, fontSize: 13)),
          ),
          FitNumber(
            child: Text(
              f.money(v, signed: signed),
              style: numStyle.copyWith(color: color, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        line('history', l.cashCarried, carried, signed: false),
        line('arrow-down-left', l.totalsIncome, income),
        line('arrow-up-right', l.totalsExpenses, -expense),
        if (moves.savings != 0) line('piggy-bank', moves.savings < 0 ? l.cashSaved : l.cashFromSavings, moves.savings),
        if (moves.debts != 0) line('handshake', l.cashDebts, moves.debts),
        if (moves.adjust != 0) line('sliders-horizontal', l.periodAdjust, moves.adjust),
      ],
    );
  }
}

/// The open period has reached its end date: invite the user to close it.
class _PeriodEndedCard extends StatelessWidget {
  const _PeriodEndedCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = context.l;
    return SoftCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClosePeriodScreen())),
      child: Row(
        children: [
          IconBadge(icon: 'calendar-check', color: context.c.warn),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.periodEndedTitle(periodLabel(s.openPeriod)), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(l.periodEndedText, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
              ],
            ),
          ),
          Icon(appIcon('chevron-right'), color: context.c.muted),
        ],
      ),
    );
  }
}

/// Planned movements whose date has come, waiting for a yes.
class _DueScheduledCard extends StatelessWidget {
  const _DueScheduledCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = context.l;
    final due = s.dueScheduled;
    return SoftCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgendaScreen())),
      child: Row(
        children: [
          IconBadge(icon: 'calendar-clock', color: context.c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.agendaDueCount(due.length), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(l.agendaDueText, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
              ],
            ),
          ),
          Icon(appIcon('chevron-right'), color: context.c.muted),
        ],
      ),
    );
  }
}

/// Gradient summary card: period balance, money carried over, income and
/// expenses, budget.
class _Hero extends StatelessWidget {
  final List<Tx> month;
  const _Hero({required this.month});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final sum = s.sums(month);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = dark ? const Color(0xFF1F5E4D) : const Color(0xFF1D6A56);
    final bottom = dark ? const Color(0xFF123B30) : const Color(0xFF124A3C);
    const white = Colors.white;
    final soft = Colors.white.withValues(alpha: 0.72);
    final b = s.settings.budget;
    final spent = s.budgetSpent(month);
    final pct = b > 0 ? spent / b : 0.0;
    final l = context.l;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [top, bottom]),
        boxShadow: [
          BoxShadow(
            color: top.withValues(alpha: dark ? 0.0 : 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Like a cash-flow statement: one figure, and how it came about.
          Text(
            l.periodAvailable.toUpperCase(),
            style: TextStyle(color: soft, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(s.spendableAt(s.view.end), size: 30, color: white, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _CashLines(carried: s.carriedInto(s.view), income: sum.income, expense: sum.expense, moves: s.movesIn(s.view), color: white, soft: soft),
          const SizedBox(height: 16),
          if (b > 0) ...[
            Row(
              children: [
                Text(l.opsBudget, style: TextStyle(color: soft, fontSize: 12.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('${f.money(spent)} / ${f.money(b)}', style: numStyle.copyWith(color: white, fontSize: 12.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pct > 1 ? l.opsBudgetOver(f.money(spent - b)) : l.opsBudgetLeft(f.money(b - spent)),
                  style: TextStyle(color: pct > 1 ? const Color(0xFFFFC2B3) : white, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct.clamp(0, 1).toDouble()),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation(
                    pct > 1
                        ? const Color(0xFFFF8A70)
                        : pct >= 0.8
                        ? const Color(0xFFF5C451)
                        : const Color(0xFF9BE3C6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(l.opsBudgetNote, style: TextStyle(color: soft, fontSize: 11.5)),
          ] else
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetAssistantScreen())),
              child: Row(
                children: [
                  Icon(appIcon('wand-sparkles'), size: 16, color: white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.opsBudgetAssistant,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(appIcon('chevron-right'), size: 16, color: white),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final Forecast forecast;
  const _ForecastCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final f = fmtOf(context);
    final fc = forecast;
    final b = s.settings.budget;
    final over = b > 0 && fc.budgetProjected > b;
    // The money available at the end of the period: today's figure, plus the
    // income still expected, minus the spending still expected.
    final bal = s.spendableAt(s.openPeriod.end) + (fc.projectedIncome - fc.income) - (fc.projectedExpense - fc.spent);
    final l = context.l;
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBadge(icon: 'telescope', color: over ? context.c.warn : context.c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.opsForecastTitle, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l.opsForecastExpenses),
                      TextSpan(
                        text: f.money(fc.projectedExpense),
                        style: numStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: l.opsForecastBalance),
                      TextSpan(
                        text: f.money(bal),
                        style: numStyle.copyWith(fontWeight: FontWeight.w600, color: bal < 0 ? context.c.expense : context.c.income),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                if (over)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(l.opsForecastOver(f.money(fc.budgetProjected - b)), style: TextStyle(color: context.c.warn, fontSize: 12.5)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(l.opsForecastDay(fc.day, fc.days), style: TextStyle(color: context.c.muted, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final Insight insight;
  const _AdviceCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final color = switch (insight.tone) {
      Tone.good => context.c.income,
      Tone.warn => context.c.warn,
      Tone.info => context.c.accent,
    };
    return SizedBox(
      width: 250,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: insight.cat == null ? null : () => s.setFilters(cat: insight.cat, acc: null),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(icon: insight.icon, color: color, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insight.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    insight.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.c.muted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final Recurring r;
  const _RecurringTile({required this.r});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final f = fmtOf(context);
    final g = s.group(r.cat);
    final late = r.nextDate.compareTo(todayIso()) < 0;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
      leading: IconBadge(icon: g.icon, color: slot(g.color), size: 38),
      title: Text(
        r.note,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${r.income ? '+' : '−'}${f.money(r.amount)} · ${late ? context.l.opsRecurringUsual(parseIso(r.nextDate).day) : context.l.opsRecurringPlanned(longDate(r.nextDate))}',
        style: TextStyle(color: context.c.muted, fontSize: 12.5),
      ),
      trailing: TextButton(
        onPressed: () => openTxSheet(context, from: r),
        child: Text(context.l.add),
      ),
    );
  }
}
