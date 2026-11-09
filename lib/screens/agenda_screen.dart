import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

String repeatName(AppLocalizations l, String r) => switch (r) {
  'week' => l.agendaRepeatWeek,
  '2weeks' => l.agendaRepeat2weeks,
  'month' => l.agendaRepeatMonth,
  'quarter' => l.agendaRepeatQuarter,
  'year' => l.agendaRepeatYear,
  _ => l.agendaRepeatOnce,
};

({String title, String icon, String color}) _look(AppState s, Scheduled x) {
  final g = s.group(x.type == TxType.transfer ? 'transfer' : x.cat);
  return (title: x.note.isNotEmpty ? x.note : g.name, icon: g.icon, color: g.color);
}

/// Calendar of what is planned and what happened, with the planned movements
/// waiting for confirmation on top.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  String month = monthKey(DateTime.now());
  String selected = todayIso();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = context.l;
    final f = fmtOf(context);
    final due = s.dueScheduled;
    final first = '$month-01';
    final last = isoDate(DateTime(parseIso(first).year, parseIso(first).month + 1, 0));

    // Days of the month holding a planned movement or a recorded one.
    final planned = <String, List<Scheduled>>{};
    for (final x in s.scheduled) {
      for (final d in x.occurrences(first, last)) {
        planned.putIfAbsent(d, () => []).add(x);
      }
    }
    final done = <String>{
      for (final t in s.txs)
        if (t.date.startsWith(month)) t.date,
    };
    final dayTxs = s.txs.where((t) => t.date == selected).toList();
    final dayPlanned = planned[selected] ?? const <Scheduled>[];

    return Scaffold(
      appBar: AppBar(title: Text(l.agendaTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openScheduledSheet(context, date: selected.compareTo(todayIso()) < 0 ? todayIso() : selected),
        icon: Icon(appIcon('plus')),
        label: Text(l.agendaNew),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          if (due.isNotEmpty) ...[
            SectionTitle(icon: 'calendar-clock', text: l.agendaToConfirm),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < due.length; i++) ...[if (i > 0) const Divider(), _ScheduledTile(x: due[i], date: due[i].next, due: true)],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: l.commonPrevPeriod,
                      icon: Icon(appIcon('chevron-left'), size: 20),
                      onPressed: () => setState(() => month = shiftMonth(month, -1)),
                    ),
                    Expanded(
                      child: Text(
                        monthLabel(month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: l.commonNextPeriod,
                      icon: Icon(appIcon('chevron-right'), size: 20),
                      onPressed: () => setState(() => month = shiftMonth(month, 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _MonthGrid(month: month, selected: selected, planned: planned.keys.toSet(), done: done, onSelect: (d) => setState(() => selected = d)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(icon: 'calendar', text: dayLabel(selected)),
          if (dayTxs.isEmpty && dayPlanned.isEmpty)
            Panel(
              child: EmptyState(icon: 'calendar', text: l.agendaDayEmpty),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final x in dayPlanned) _ScheduledTile(x: x, date: selected, due: false),
                  for (final t in dayTxs)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TxTile(
                        tx: t,
                        onTap: () => openTxSheet(context, tx: t),
                      ),
                    ),
                ],
              ),
            ),
          if (s.scheduled.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionTitle(icon: 'repeat', text: l.agendaAll),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < s.scheduled.length; i++) ...[
                    if (i > 0) const Divider(),
                    ListTile(
                      leading: IconBadge(icon: _look(s, s.scheduled[i]).icon, color: slot(_look(s, s.scheduled[i]).color)),
                      title: Text(_look(s, s.scheduled[i]).title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${repeatName(l, s.scheduled[i].repeat)} · ${longDate(s.scheduled[i].next)}'),
                      trailing: FitNumber(share: 0.36, child: Text(f.money(s.scheduled[i].amount), style: numStyle)),
                      onTap: () => openScheduledSheet(context, x: s.scheduled[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final String month, selected;
  final Set<String> planned, done;
  final ValueChanged<String> onSelect;
  const _MonthGrid({required this.month, required this.selected, required this.planned, required this.done, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final first = parseIso('$month-01');
    final count = DateTime(first.year, first.month + 1, 0).day;
    final blank = first.weekday - 1; // weeks start on Monday
    final today = todayIso();
    final names = DateFormat.E(intlLocale);
    final rows = ((blank + count) / 7).ceil();

    Widget cell(int index) {
      final day = index - blank + 1;
      if (day < 1 || day > count) return const Expanded(child: SizedBox(height: 44));
      final iso = isoDate(DateTime(first.year, first.month, day));
      final isSel = iso == selected;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelect(iso),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isSel ? context.c.accent.withValues(alpha: 0.16) : null,
              border: iso == today ? Border.all(color: context.c.accent) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day', style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, fontSize: 13.5)),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (planned.contains(iso)) _Dot(color: context.c.warn),
                    if (planned.contains(iso) && done.contains(iso)) const SizedBox(width: 3),
                    if (done.contains(iso)) _Dot(color: context.c.accent),
                    if (!planned.contains(iso) && !done.contains(iso)) const SizedBox(height: 5),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                // 5 January 2026 was a Monday.
                child: Text(
                  names.format(DateTime(2026, 1, 5 + i)),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.c.muted, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++) Row(children: [for (var c = 0; c < 7; c++) cell(r * 7 + c)]),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _ScheduledTile extends StatelessWidget {
  final Scheduled x;
  final String date;
  final bool due;
  const _ScheduledTile({required this.x, required this.date, required this.due});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final l = context.l;
    final look = _look(s, x);
    final sign = x.type == TxType.income ? x.amount : (x.type == TxType.expense ? -x.amount : x.amount);
    return ListTile(
      leading: IconBadge(icon: look.icon, color: slot(look.color)),
      title: Text(look.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(due ? longDate(date) : l.agendaPlanned),
      trailing: FitNumber(
        share: 0.36,
        child: Text(fmtOf(context).money(sign, signed: x.type != TxType.transfer), style: numStyle),
      ),
      // Only the next occurrence can be confirmed: later ones wait their turn.
      onTap: () => date == x.next && date.compareTo(todayIso()) <= 0 ? openConfirmSheet(context, x) : openScheduledSheet(context, x: x),
    );
  }
}

/// Confirm, with a last chance to correct the amount or the date, or skip.
Future<void> openConfirmSheet(BuildContext context, Scheduled x) {
  final s = context.read<AppState>();
  final look = _look(s, x);
  final amount = TextEditingController(text: Fmt(s.settings.currency).number(x.amount));
  var date = x.next;
  return showFormSheet(
    context,
    title: look.title,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ctx.l.agendaConfirmHelp, style: TextStyle(color: ctx.c.muted, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AmountField(controller: amount, label: ctx.l.sheetsAmount),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DateField(label: ctx.l.sheetsDate, value: date, onChanged: (d) => setState(() => date = d)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              OutlinedButton(
                onPressed: () async {
                  await s.skipScheduled(x);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(ctx.l.agendaSkip),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final v = parseAmount(amount.text);
                    if (v == null || v <= 0) return toast(ctx, ctx.l.sheetsAmountPositive);
                    await s.confirmScheduled(x, amount: v, date: date);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    toast(ctx, ctx.l.agendaConfirmed);
                  },
                  child: Text(ctx.l.confirm),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Creates or edits a planned movement.
Future<void> openScheduledSheet(BuildContext context, {Scheduled? x, String? date}) {
  final s = context.read<AppState>();
  return showFormSheet(
    context,
    title: x == null ? context.l.agendaNew : context.l.agendaEdit,
    builder: (_) => _ScheduledForm(x: x, date: date ?? todayIso(), state: s),
  );
}

class _ScheduledForm extends StatefulWidget {
  final Scheduled? x;
  final String date;
  final AppState state;
  const _ScheduledForm({this.x, required this.date, required this.state});
  @override
  State<_ScheduledForm> createState() => _ScheduledFormState();
}

class _ScheduledFormState extends State<_ScheduledForm> {
  late TxType type = widget.x?.type ?? TxType.expense;
  late String date = widget.x?.next ?? widget.date;
  late String repeat = widget.x?.repeat ?? 'once';
  late String account = widget.x?.account ?? widget.state.settings.defaultAccount;
  late String to = widget.x?.to.isNotEmpty == true ? widget.x!.to : (widget.state.activeAccounts.where((a) => a.id != account).firstOrNull?.id ?? account);
  late String cat = widget.x?.cat.isNotEmpty == true ? widget.x!.cat : widget.state.activeCats(false).first.id;
  late final amount = TextEditingController(text: widget.x == null ? '' : Fmt(widget.state.settings.currency).number(widget.x!.amount));
  late final note = TextEditingController(text: widget.x?.note ?? '');

  void setType(TxType t) => setState(() {
    type = t;
    if (t != TxType.transfer && widget.state.catById(cat)?.income != (t == TxType.income)) cat = widget.state.activeCats(t == TxType.income).first.id;
  });

  Future<void> save() async {
    final l = context.l;
    final v = parseAmount(amount.text);
    if (v == null || v <= 0) return toast(context, l.sheetsAmountPositive);
    if (type == TxType.transfer && to == account) return toast(context, l.sheetsTransferSameAccount);
    final old = widget.x;
    await widget.state.saveScheduled(
      Scheduled(
        id: old?.id ?? newId('s-'),
        type: type,
        amount: v,
        cat: type == TxType.transfer ? '' : cat,
        account: account,
        to: type == TxType.transfer ? to : '',
        note: note.text.trim(),
        next: date,
        repeat: repeat,
        created: old?.created,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, l.agendaSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = widget.state;
    final isT = type == TxType.transfer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<TxType>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: TxType.expense, label: Text(l.typeExpense)),
            ButtonSegment(value: TxType.income, label: Text(l.typeIncome)),
            ButtonSegment(value: TxType.transfer, label: Text(l.commonTransfer)),
          ],
          selected: {type},
          onSelectionChanged: (v) => setType(v.first),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AmountField(controller: amount, label: l.sheetsAmount, autofocus: widget.x == null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DateField(label: l.sheetsDate, value: date, onChanged: (d) => setState(() => date = d)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: repeat,
          decoration: InputDecoration(labelText: l.agendaRepeat),
          items: [for (final r in repeats) DropdownMenuItem(value: r, child: Text(repeatName(l, r)))],
          onChanged: (v) => setState(() => repeat = v ?? 'once'),
        ),
        const SizedBox(height: 12),
        accountDropdown(
          context,
          label: isT ? l.sheetsFromAccount : l.sheetsAccount,
          value: account,
          extra: [account],
          onChanged: (v) => setState(() => account = v),
        ),
        if (isT) ...[
          const SizedBox(height: 12),
          accountDropdown(context, label: l.sheetsToAccount, value: to, extra: [to], onChanged: (v) => setState(() => to = v)),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.sheetsNote, hintText: l.agendaNoteHint, counterText: ''),
        ),
        if (!isT) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in s.activeCats(type == TxType.income))
                ChoiceChip(
                  selected: c.id == cat,
                  onSelected: (_) => setState(() => cat = c.id),
                  avatar: Icon(appIcon(c.icon), size: 17, color: slot(c.color)),
                  label: Text(c.name),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            if (widget.x != null) ...[
              ConfirmDeleteButton(
                label: l.delete,
                onConfirm: () async {
                  await s.deleteScheduled(widget.x!.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(onPressed: save, child: Text(l.save)),
            ),
          ],
        ),
      ],
    );
  }
}
