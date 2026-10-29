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
import 'budget_assistant_screen.dart';

/// Home: month summary, forecast, advice, upcoming recurring movements, journal.
class OpsScreen extends StatelessWidget {
  const OpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final month = s.monthTxs(s.month);
    final current = s.month == monthKey(DateTime.now());
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
    final advice = s.txs.isEmpty ? <Insight>[] : ins.advice(s.month, (v) => f.money(v));
    final due = current ? ins.dueThisMonth : <Recurring>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        const Center(child: MonthNav()),
        const SizedBox(height: 14),
        _Hero(month: month),
        if (current && s.txs.isNotEmpty) ...[const SizedBox(height: 12), _ForecastCard(forecast: ins.forecast())],
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
                      ? l.opsEmptyMonthAccount(monthLabel(s.month))
                      : l.opsEmptyMonth(monthLabel(s.month)),
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
                          final net = e.value.fold<double>(0, (a, t) => a + s.flow(t));
                          return net == 0 ? const SizedBox() : Text(f.money(net, signed: true), style: numStyle.copyWith(color: context.c.muted, fontSize: 13));
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

/// Gradient summary card: month balance, income and expenses, budget.
class _Hero extends StatelessWidget {
  final List<Tx> month;
  const _Hero({required this.month});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final sum = s.sums(month);
    final bal = sum.income - sum.expense;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = dark ? const Color(0xFF1F5E4D) : const Color(0xFF1D6A56);
    final bottom = dark ? const Color(0xFF123B30) : const Color(0xFF124A3C);
    const white = Colors.white;
    final soft = Colors.white.withValues(alpha: 0.72);
    final b = s.settings.budget;
    final spent = s.budgetSpent(month);
    final pct = b > 0 ? spent / b : 0.0;
    final l = context.l;

    Widget total(String label, String icon, double v) => Expanded(
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
            child: Icon(appIcon(icon), size: 16, color: white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: soft, fontSize: 12)),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: AnimatedMoney(v, size: 15, color: white),
                ),
              ],
            ),
          ),
        ],
      ),
    );

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
          Text(
            l.opsHeroBalance,
            style: TextStyle(color: soft, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(bal, signed: true, size: 30, color: white, weight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [total(l.totalsIncome, 'arrow-down-left', sum.income), const SizedBox(width: 10), total(l.totalsExpenses, 'arrow-up-right', sum.expense)],
          ),
          const SizedBox(height: 16),
          if (b > 0) ...[
            Row(
              children: [
                Text(l.opsBudget, style: TextStyle(color: soft, fontSize: 12.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${f.money(spent)} / ${f.money(b)}',
                    style: numStyle.copyWith(color: white, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
    final bal = fc.projectedBalance;
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
                        text: f.money(bal, signed: true),
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
