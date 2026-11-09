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
import '../widgets/quick_sheet.dart';
import '../widgets/sheets.dart';
import 'agenda_screen.dart';
import 'budget_assistant_screen.dart';
import 'periods_screen.dart';

/// Home: the money available and where it stands, what needs a look, and
/// the latest movements. Everything else is one tap away.
class HomeScreen extends StatelessWidget {
  final VoidCallback onShowJournal;
  const HomeScreen({super.key, required this.onShowJournal});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final l = context.l;
    final ins = Insights.of(s);
    final open = s.openPeriod;
    final list = s.periodTxs(open);
    final sum = s.sums(list);
    final available = s.spendableAt(open.end);
    final fc = s.txs.isNotEmpty && !s.periodEnded ? ins.forecast() : null;
    final projected = fc == null ? null : available + (fc.projectedIncome - fc.income) - (fc.projectedExpense - fc.spent);
    final due = ins.dueThisMonth.where((r) => open.contains(r.nextDate) || r.nextDate.compareTo(todayIso()) < 0).toList();
    final tip = s.txs.isEmpty ? null : ins.advice(open, (v) => f.money(v)).firstOrNull;
    final today = todayIso();
    final recent = s.txs.where((t) => t.date.compareTo(today) <= 0).toList()
      ..sort((a, b) => b.date.compareTo(a.date) != 0 ? b.date.compareTo(a.date) : b.created.compareTo(a.created));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // The one figure that matters, and where the period is heading.
        Text('${l.periodAvailable} · ${periodLabel(open)}', style: TextStyle(color: context.c.muted, fontSize: 13)),
        const SizedBox(height: 2),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: AnimatedMoney(available, size: 36, weight: FontWeight.w700),
        ),
        if (projected != null)
          Row(
            children: [
              Icon(appIcon(projected >= 0 ? 'trending-up' : 'trending-down'), size: 16, color: projected >= 0 ? context.c.income : context.c.expense),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.homeForecast(f.money(projected)),
                  style: TextStyle(color: projected >= 0 ? context.c.income : context.c.expense, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        // One phrase is enough to record a movement.
        Material(
          color: context.c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: context.c.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => openQuickEntry(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(appIcon('zap'), size: 20, color: context.c.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.quickBar, style: TextStyle(color: context.c.muted)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Panel(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: _CashLines(
            carried: s.carriedInto(open),
            income: sum.income,
            expense: sum.expense,
            moves: s.movesIn(open),
            color: context.c.ink,
            soft: context.c.muted,
          ),
        ),
        const SizedBox(height: 10),
        const _BudgetBox(),
        if (s.periodEnded) ...[const SizedBox(height: 10), const _PeriodEndedCard()],
        if (s.dueScheduled.isNotEmpty) ...[const SizedBox(height: 10), const _DueScheduledCard()],
        if (tip != null) ...[const SizedBox(height: 10), _TipRow(insight: tip, onTap: onShowJournal)],
        if (due.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionTitle(icon: 'repeat', text: l.opsDueTitle),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < due.length && i < 3; i++) ...[if (i > 0) const Divider(), _RecurringTile(r: due[i])],
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        SectionTitle(
          icon: 'list',
          text: l.homeRecent,
          trailing: recent.isEmpty ? null : TextButton(onPressed: onShowJournal, child: Text(l.homeSeeAll)),
        ),
        if (recent.isEmpty)
          Panel(
            child: EmptyState(
              icon: 'receipt',
              text: l.opsEmptyFirst,
              action: OutlinedButton(
                onPressed: () async {
                  await s.loadSamples();
                  if (context.mounted) toast(context, context.l.opsSamplesLoaded);
                },
                child: Text(l.opsLoadSamples),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                children: [
                  for (final t in recent.take(4))
                    TxTile(
                      tx: t,
                      onTap: () => openTxSheet(context, tx: t),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The period's budget: what is left, and what that allows per day.
class _BudgetBox extends StatelessWidget {
  const _BudgetBox();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final l = context.l;
    final b = s.settings.budget;
    if (b <= 0) {
      return SoftCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetAssistantScreen())),
        child: Row(
          children: [
            IconBadge(icon: 'wand-sparkles', color: context.c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l.opsBudgetAssistant, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Icon(appIcon('chevron-right'), color: context.c.muted),
          ],
        ),
      );
    }
    final open = s.openPeriod;
    final spent = s.budgetSpent(s.periodTxs(open));
    final left = b - spent;
    final today = todayIso();
    final daysLeft = open.contains(today) ? Period(today, open.end).days : 0;
    final color = left < 0
        ? context.c.expense
        : spent >= b * 0.8
        ? context.c.warn
        : context.c.income;
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l.opsBudget, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              FitNumber(
                child: Text(
                  left < 0 ? l.opsBudgetOver(f.money(-left)) : l.homeBudgetLeft(f.money(left)),
                  style: numStyle.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Gauge(value: (spent / b).clamp(0.0, 1.0), color: color, height: 7),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(l.homeBudgetSpent(f.money(spent), f.money(b)), style: TextStyle(color: context.c.muted, fontSize: 12.5)),
              ),
              if (left > 0 && daysLeft > 0) Text(l.homePerDay(f.money(left / daysLeft)), style: TextStyle(color: context.c.muted, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The most useful piece of advice, on one line.
class _TipRow extends StatelessWidget {
  final Insight insight;
  final VoidCallback onTap;
  const _TipRow({required this.insight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final color = switch (insight.tone) {
      Tone.good => context.c.income,
      Tone.warn => context.c.warn,
      Tone.info => context.c.accent,
    };
    return SoftCard(
      onTap: insight.cat == null
          ? null
          : () {
              s.setFilters(cat: insight.cat, acc: null);
              onTap();
            },
      child: Row(
        children: [
          IconBadge(icon: insight.icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
                Text(
                  insight.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.c.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Journal: every movement of a period, grouped by day, with search and filters.
class OpsScreen extends StatefulWidget {
  const OpsScreen({super.key});
  @override
  State<OpsScreen> createState() => _OpsScreenState();
}

class _OpsScreenState extends State<OpsScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  /// Lower case without accents, so "eneo" finds "ENEO" and "epargne" "Épargne".
  static String _norm(String s) {
    const from = 'àâäáçéèêëíìîïñóòôöúùûü', to = 'aaaaceeeeiiiinooooouuuu';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final l = context.l;
    final q = _norm(search.text.trim());

    final scoped = s.periodTxs(s.view).where((t) => s.accFilter == null || s.accountOf(t) == s.accFilter || t.to == s.accFilter).toList();
    final usedKeys = scoped.map(s.flowKey).toSet().toList();
    final catFilter = usedKeys.contains(s.catFilter) ? s.catFilter : null;
    bool matches(Tx t) {
      if (q.isEmpty) return true;
      final v = txView(s, t);
      return _norm('${t.note} ${v.title} ${v.sub} ${s.group(s.flowKey(t)).name}').contains(q);
    }

    final list = scoped.where((t) => (catFilter == null || s.flowKey(t) == catFilter) && matches(t)).toList()
      ..sort((a, b) => b.date.compareTo(a.date) != 0 ? b.date.compareTo(a.date) : b.created.compareTo(a.created));
    final byDay = <String, List<Tx>>{};
    for (final t in list) {
      byDay.putIfAbsent(t.date, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        const Center(child: MonthNav()),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l.journalSearch,
            prefixIcon: Icon(appIcon('search'), size: 20),
            suffixIcon: search.text.isEmpty ? null : IconButton(tooltip: l.close, icon: Icon(appIcon('x'), size: 18), onPressed: () => setState(search.clear)),
            isDense: true,
          ),
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
        const SizedBox(height: 6),
        if (list.isEmpty)
          Panel(
            child: EmptyState(
              icon: q.isEmpty ? 'receipt' : 'search',
              text: q.isNotEmpty
                  ? l.journalNoMatch
                  : s.accFilter != null
                  ? l.opsEmptyMonthAccount(periodLabel(s.view))
                  : l.opsEmptyMonth(periodLabel(s.view)),
            ),
          ),
        for (final e in byDay.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Row(
              children: [
                Text(
                  dayLabel(e.key),
                  style: TextStyle(color: context.c.muted, fontSize: 13, fontWeight: FontWeight.w500),
                ),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Column(
                children: [
                  for (final t in e.value)
                    TxTile(
                      tx: t,
                      onTap: () => openTxSheet(context, tx: t),
                    ),
                ],
              ),
            ),
          ),
        ],
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
