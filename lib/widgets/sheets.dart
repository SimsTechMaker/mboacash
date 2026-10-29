import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../i18n.dart';
import '../icons.dart';
import '../insights.dart';
import '../models.dart';
import '../proofs.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';
import 'proof.dart';

// ---------------------------------------------------------------------------
// Income / expense / transfer
// ---------------------------------------------------------------------------

Future<void> openTxSheet(BuildContext context, {Tx? tx, Recurring? from}) {
  final s = context.read<AppState>();
  if (tx != null && !{TxType.income, TxType.expense, TxType.transfer}.contains(tx.type)) {
    return openMovementDetails(context, tx);
  }
  return showFormSheet(
    context,
    title: tx == null ? context.l.newOperation : context.l.sheetsTxEditTitle,
    builder: (_) => _TxForm(tx: tx, from: from, state: s),
  );
}

class _TxForm extends StatefulWidget {
  final Tx? tx;
  final Recurring? from; // prefill from a recurring movement
  final AppState state;
  const _TxForm({this.tx, this.from, required this.state});
  @override
  State<_TxForm> createState() => _TxFormState();
}

class _TxFormState extends State<_TxForm> {
  late TxType type;
  late String cat, account, to, date;
  final amount = TextEditingController();
  final note = TextEditingController();
  bool catChosen = false; // the user picked a category: stop suggesting
  bool suggested = false;
  // Proof photo: the saved file name, and a new photo written only on save.
  late String proof = widget.tx?.proof ?? '';
  Uint8List? newProof;

  @override
  void initState() {
    super.initState();
    final s = widget.state;
    final t = widget.tx;
    final r = widget.from;
    type = t?.type ?? (r != null && r.income ? TxType.income : TxType.expense);
    account = t != null ? s.accountOf(t) : (r != null && s.accById(r.account) != null ? r.account : (s.accFilter ?? s.settings.defaultAccount));
    final other = s.activeAccounts.where((a) => a.id != account).firstOrNull;
    to = t?.to.isNotEmpty == true ? t!.to : (other?.id ?? account);
    cat = t?.cat ?? r?.cat ?? s.activeCats(false).first.id;
    final today = todayIso();
    date = t?.date ?? (r != null || today.startsWith(s.month) ? today : '${s.month}-01');
    if (t != null || r != null) {
      amount.text = Fmt(s.settings.currency).number(t?.amount ?? r!.amount);
      note.text = t?.note ?? r!.note;
      catChosen = true;
    }
    note.addListener(_suggest);
  }

  @override
  void dispose() {
    note.removeListener(_suggest);
    super.dispose();
  }

  /// Picks the category from the note as the user types, until they choose one.
  void _suggest() {
    if (catChosen || type == TxType.transfer) return;
    final id = Insights.of(widget.state).suggestCategory(note.text, income: type == TxType.income);
    if (id != null && id != cat) {
      setState(() {
        cat = id;
        suggested = true;
      });
    }
  }

  void setType(TxType t) {
    setState(() {
      type = t;
      if (t != TxType.transfer) {
        final income = t == TxType.income;
        final c = widget.state.catById(cat);
        if (c == null || c.income != income || c.archived) cat = widget.state.activeCats(income).first.id;
      }
    });
  }

  Future<void> save() async {
    final s = widget.state;
    final v = parseAmount(amount.text);
    if (v == null || v <= 0) return toast(context, context.l.sheetsAmountPositive);
    if (type == TxType.transfer && to == account) return toast(context, context.l.sheetsTransferSameAccount);
    final t = widget.tx;
    final id = t?.id ?? newId();
    if (newProof != null) proof = await Proofs.save(id, newProof!);
    final tx = Tx(
      id: id,
      type: type,
      amount: v,
      cat: type == TxType.transfer ? 'transfer' : cat,
      account: account,
      to: type == TxType.transfer ? to : '',
      date: date,
      note: note.text.trim(),
      proof: proof,
      sample: t?.sample ?? false,
      created: t?.created,
    );
    await s.saveTx(tx);
    if (!date.startsWith(s.month)) s.setMonth(date.substring(0, 7));
    if (!mounted) return;
    Navigator.pop(context);
    final l = context.l;
    toast(context, t != null ? l.sheetsTxUpdated : {TxType.expense: l.sheetsExpenseAdded, TxType.income: l.sheetsIncomeAdded}[type] ?? l.sheetsTransferSaved);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final isT = type == TxType.transfer;
    final cats = isT ? <Category>[] : s.activeCats(type == TxType.income);
    final cur = s.catById(cat);
    if (!isT && cur != null && cur.archived && !cats.contains(cur)) cats.add(cur);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<TxType>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: TxType.expense, label: Text(context.l.typeExpense)),
            ButtonSegment(value: TxType.income, label: Text(context.l.typeIncome)),
            ButtonSegment(value: TxType.transfer, label: Text(context.l.commonTransfer)),
          ],
          selected: {type},
          onSelectionChanged: (v) => setType(v.first),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AmountField(controller: amount, label: context.l.sheetsAmount, autofocus: widget.tx == null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DateField(label: context.l.sheetsDate, value: date, onChanged: (d) => setState(() => date = d)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        accountDropdown(
          context,
          label: isT ? context.l.sheetsFromAccount : context.l.sheetsAccount,
          value: account,
          extra: [account],
          onChanged: (v) => setState(() => account = v),
        ),
        if (isT) ...[
          const SizedBox(height: 12),
          accountDropdown(context, label: context.l.sheetsToAccount, value: to, extra: [to], onChanged: (v) => setState(() => to = v)),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: context.l.sheetsNote, hintText: context.l.sheetsTxNoteHint, counterText: ''),
        ),
        const SizedBox(height: 12),
        ProofField(
          saved: proof,
          pending: newProof,
          onPicked: (b) => setState(() => newProof = b),
          onRemove: () => setState(() {
            newProof = null;
            proof = '';
          }),
        ),
        if (!isT) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text(context.l.sheetsCategory, style: TextStyle(color: context.c.muted, fontSize: 13)),
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: suggested && !catChosen ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Row(
                  children: [
                    Icon(appIcon('sparkles'), size: 14, color: context.c.accent),
                    const SizedBox(width: 4),
                    Text(context.l.sheetsSuggested, style: TextStyle(color: context.c.accent, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in cats)
                ChoiceChip(
                  selected: c.id == cat,
                  onSelected: (_) => setState(() {
                    cat = c.id;
                    catChosen = true;
                  }),
                  avatar: Icon(appIcon(c.icon), size: 17, color: slot(c.color)),
                  label: Text(c.name),
                  side: BorderSide(color: c.id == cat ? context.c.ink : context.c.line),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            if (widget.tx != null) ...[
              ConfirmDeleteButton(
                label: context.l.delete,
                onConfirm: () async {
                  await s.deleteTx(widget.tx!.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    toast(context, context.l.sheetsTxDeleted);
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(onPressed: save, child: Text(widget.tx == null ? context.l.add : context.l.sheetsUpdate)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Adjustments, savings and debt movements are managed from their own
/// screens; tapping one in the journal only shows it and allows deleting.
Future<void> openMovementDetails(BuildContext context, Tx tx) {
  final s = context.read<AppState>();
  final v = txView(s, tx);
  final l = context.l;
  final where = tx.type == TxType.adjust
      ? l.sheetsAdjustExplain
      : tx.type == TxType.save
      ? l.sheetsSaveExplain
      : l.sheetsDebtExplain;
  return showFormSheet(
    context,
    title: v.title,
    builder: (ctx) {
      final f = Fmt(s.settings.currency);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoBox(lines: [ctx.l.sheetsInfoAmount(f.money(tx.amount)), ctx.l.sheetsInfoDate(longDate(tx.date)), ctx.l.sheetsInfoAccount(v.sub)]),
          const SizedBox(height: 12),
          Text('$where ${ctx.l.sheetsDeleteIfMistake}', style: TextStyle(color: ctx.c.muted)),
          const SizedBox(height: 16),
          ConfirmDeleteButton(
            label: ctx.l.sheetsDeleteMovement,
            onConfirm: () async {
              await s.deleteTx(tx.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                toast(ctx, ctx.l.sheetsMovementDeleted);
              }
            },
          ),
        ],
      );
    },
  );
}

class _InfoBox extends StatelessWidget {
  final List<String> lines;
  const _InfoBox({required this.lines});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: context.c.surface2, borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final l in lines) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(l))],
    ),
  );
}

// ---------------------------------------------------------------------------
// Account adjustment
// ---------------------------------------------------------------------------

Future<void> openAdjustSheet(BuildContext context, String accId) {
  final s = context.read<AppState>();
  final a = s.accById(accId)!;
  final cur = s.balances()[accId] ?? 0;
  final real = TextEditingController();
  final note = TextEditingController();
  var date = todayIso();
  return showFormSheet(
    context,
    title: context.l.sheetsAdjustTitle(a.name),
    builder: (ctx) {
      final f = Fmt(s.settings.currency);
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ctx.l.sheetsAdjustIntro, style: TextStyle(color: ctx.c.muted)),
            const SizedBox(height: 12),
            _InfoBox(lines: [ctx.l.sheetsBookBalance(f.money(cur))]),
            const SizedBox(height: 12),
            AmountField(controller: real, label: ctx.l.sheetsRealBalance, autofocus: true),
            const SizedBox(height: 12),
            DateField(label: ctx.l.sheetsDate, value: date, onChanged: (d) => set(() => date = d)),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: ctx.l.sheetsNote, hintText: ctx.l.sheetsAdjustNoteHint),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                final v = parseAmount(real.text);
                if (v == null) return toast(ctx, ctx.l.sheetsRealBalanceMissing);
                final diff = await s.adjustAccount(accId, v, date, note.text.trim());
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                toast(ctx, diff == 0 ? ctx.l.sheetsBalanceAlreadyRight : ctx.l.sheetsBalanceAdjusted(f.money(diff, signed: true)));
              },
              child: Text(ctx.l.sheetsAdjust),
            ),
          ],
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Savings goals
// ---------------------------------------------------------------------------

const goalIcons = ['piggy-bank', 'shield', 'house', 'car', 'plane', 'graduation-cap', 'laptop', 'heart', 'gift', 'tree-palm', 'baby', 'star'];

Future<void> openGoalSheet(BuildContext context, {Goal? goal}) {
  final s = context.read<AppState>();
  final name = TextEditingController(text: goal?.name ?? '');
  final f = Fmt(s.settings.currency);
  final target = TextEditingController(text: goal != null && goal.target > 0 ? f.number(goal.target) : '');
  final initial = TextEditingController();
  var deadline = goal?.deadline ?? '';
  var icon = goal?.icon ?? 'piggy-bank';
  final used = s.goals.map((g) => g.color).toSet();
  final color = goal?.color ?? palette.firstWhere((p) => !used.contains(p), orElse: () => 'c2');
  return showFormSheet(
    context,
    title: goal == null ? context.l.sheetsGoalNewTitle : context.l.sheetsGoalEditTitle,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: name,
              autofocus: goal == null,
              decoration: InputDecoration(labelText: ctx.l.sheetsName, hintText: ctx.l.sheetsGoalNameHint),
            ),
            const SizedBox(height: 12),
            AmountField(controller: target, label: ctx.l.sheetsGoalTarget),
            const SizedBox(height: 12),
            DateField(label: ctx.l.sheetsGoalDeadline, value: deadline, optional: true, onChanged: (d) => set(() => deadline = d)),
            if (goal == null) ...[const SizedBox(height: 12), AmountField(controller: initial, label: ctx.l.sheetsGoalInitial)],
            const SizedBox(height: 14),
            Text(ctx.l.sheetsIcon, style: TextStyle(color: ctx.c.muted, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final n in goalIcons)
                  ChoiceChip(
                    selected: n == icon,
                    onSelected: (_) => set(() => icon = n),
                    label: Icon(appIcon(n), size: 20, color: slot(color)),
                    side: BorderSide(color: n == icon ? ctx.c.ink : ctx.c.line),
                  ),
              ],
            ),
            if (goal != null) ...[const SizedBox(height: 12), Text(ctx.l.sheetsGoalDeleteHint, style: TextStyle(color: ctx.c.muted, fontSize: 13))],
            const SizedBox(height: 18),
            Row(
              children: [
                if (goal != null) ...[
                  ConfirmDeleteButton(
                    label: ctx.l.delete,
                    onConfirm: () async {
                      await s.deleteGoal(goal.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        toast(ctx, ctx.l.sheetsGoalDeleted);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (name.text.trim().isEmpty) return toast(ctx, ctx.l.sheetsGoalNameMissing);
                      final t = parseAmount(target.text) ?? 0;
                      final g =
                          goal ?? Goal(id: newId('g-'), name: '', color: color, initial: (parseAmount(initial.text) ?? 0).clamp(0, double.infinity).toDouble());
                      g
                        ..name = name.text.trim()
                        ..target = t > 0 ? t : 0
                        ..deadline = deadline
                        ..icon = icon;
                      await s.saveGoal(g);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      toast(ctx, goal == null ? ctx.l.sheetsGoalCreated : ctx.l.sheetsGoalUpdated);
                    },
                    child: Text(goal == null ? ctx.l.sheetsGoalCreate : ctx.l.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// [dir] = -1 puts money aside (leaves the account), 1 takes it back.
Future<void> openGoalMoveSheet(BuildContext context, Goal g, int dir) {
  final s = context.read<AppState>();
  final saved = s.goalSaved(g);
  final amount = TextEditingController();
  final note = TextEditingController();
  var account = s.settings.defaultAccount;
  var date = todayIso();
  final f = Fmt(s.settings.currency);
  return showFormSheet(
    context,
    title: dir < 0 ? context.l.sheetsGoalPutAsideTitle(g.name) : context.l.sheetsGoalWithdrawTitle(g.name),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoBox(lines: [g.target > 0 ? ctx.l.sheetsGoalSavedOf(f.money(saved), f.money(g.target)) : ctx.l.sheetsGoalSaved(f.money(saved))]),
            const SizedBox(height: 12),
            AmountField(controller: amount, label: ctx.l.sheetsAmount, autofocus: true),
            const SizedBox(height: 12),
            accountDropdown(ctx, label: dir < 0 ? ctx.l.sheetsFromAccount : ctx.l.sheetsToAccount, value: account, onChanged: (v) => set(() => account = v)),
            const SizedBox(height: 12),
            DateField(label: ctx.l.sheetsDate, value: date, onChanged: (d) => set(() => date = d)),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: ctx.l.sheetsNote),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                final v = parseAmount(amount.text);
                if (v == null || v <= 0) return toast(ctx, ctx.l.sheetsAmountPositive);
                if (dir > 0 && v > saved + 0.001) return toast(ctx, ctx.l.sheetsGoalWithdrawMax(f.money(saved)));
                await s.saveTx(
                  Tx(id: newId(), type: TxType.save, amount: v, cat: 'save', account: account, dir: dir, goal: g.id, date: date, note: note.text.trim()),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                toast(ctx, dir < 0 ? ctx.l.sheetsGoalPutAsideDone(f.money(v)) : ctx.l.sheetsGoalWithdrawDone(f.money(v)));
              },
              child: Text(dir < 0 ? ctx.l.sheetsGoalPutAside : ctx.l.sheetsGoalWithdraw),
            ),
          ],
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Debts
// ---------------------------------------------------------------------------

Future<void> openDebtSheet(BuildContext context, {Debt? debt, bool owe = true}) {
  final s = context.read<AppState>();
  final f = Fmt(s.settings.currency);
  final person = TextEditingController(text: debt?.person ?? '');
  final amount = TextEditingController(text: debt != null ? f.number(debt.amount) : '');
  final note = TextEditingController(text: debt?.note ?? '');
  var kindOwe = debt?.owe ?? owe;
  var date = debt?.date ?? todayIso();
  var due = debt?.due ?? '';
  var account = s.settings.defaultAccount;
  return showFormSheet(
    context,
    title: debt == null ? context.l.sheetsDebtNewTitle : context.l.sheetsDebtEditTitle,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (debt == null) ...[
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: true, label: Text(ctx.l.sheetsDebtIOwe)),
                  ButtonSegment(value: false, label: Text(ctx.l.sheetsDebtOwedToMe)),
                ],
                selected: {kindOwe},
                onSelectionChanged: (v) => set(() => kindOwe = v.first),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: person,
              decoration: InputDecoration(
                labelText: ctx.l.sheetsDebtPerson,
                hintText: kindOwe ? ctx.l.sheetsDebtPersonHintOwe : ctx.l.sheetsDebtPersonHintLent,
              ),
            ),
            const SizedBox(height: 12),
            AmountField(controller: amount, label: ctx.l.sheetsDebtTotal),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DateField(label: ctx.l.sheetsDate, value: date, onChanged: (d) => set(() => date = d)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateField(label: ctx.l.sheetsDebtDue, value: due, optional: true, onChanged: (d) => set(() => due = d)),
                ),
              ],
            ),
            if (debt == null) ...[
              const SizedBox(height: 12),
              accountDropdown(
                ctx,
                label: kindOwe ? ctx.l.sheetsDebtReceivedOn : ctx.l.sheetsDebtPaidOutOf,
                value: account,
                allowNone: true,
                onChanged: (v) => set(() => account = v),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: ctx.l.sheetsNote),
            ),
            const SizedBox(height: 8),
            Text(debt != null ? ctx.l.sheetsDebtDeleteHint : ctx.l.sheetsDebtAccountHint, style: TextStyle(color: ctx.c.muted, fontSize: 13)),
            const SizedBox(height: 18),
            Row(
              children: [
                if (debt != null) ...[
                  ConfirmDeleteButton(
                    label: ctx.l.delete,
                    onConfirm: () async {
                      await s.deleteDebt(debt.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        toast(ctx, ctx.l.sheetsDebtDeleted);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final v = parseAmount(amount.text);
                      if (person.text.trim().isEmpty) return toast(ctx, ctx.l.sheetsDebtPersonMissing);
                      if (v == null || v <= 0) return toast(ctx, ctx.l.sheetsAmountPositive);
                      final d = debt ?? Debt(id: newId('d-'), owe: kindOwe, person: '', amount: 0, date: date);
                      d
                        ..person = person.text.trim()
                        ..amount = v
                        ..date = date
                        ..due = due
                        ..note = note.text.trim();
                      await s.saveDebt(d);
                      if (debt == null && account.isNotEmpty) {
                        await s.saveTx(
                          Tx(
                            id: newId(),
                            type: TxType.debt,
                            amount: v,
                            cat: 'debt',
                            account: account,
                            dir: kindOwe ? 1 : -1,
                            debt: d.id,
                            init: true,
                            date: date,
                          ),
                        );
                      }
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      toast(ctx, debt != null ? ctx.l.sheetsDebtUpdated : (kindOwe ? ctx.l.sheetsDebtAdded : ctx.l.sheetsLoanAdded));
                    },
                    child: Text(debt == null ? ctx.l.add : ctx.l.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> openDebtPaySheet(BuildContext context, Debt d) {
  final s = context.read<AppState>();
  final f = Fmt(s.settings.currency);
  final left = s.debtLeft(d);
  final amount = TextEditingController(text: f.number(left));
  final note = TextEditingController();
  var account = s.settings.defaultAccount;
  var date = todayIso();
  return showFormSheet(
    context,
    title: d.owe ? context.l.sheetsDebtRepayTitle(d.person) : context.l.sheetsDebtRepaymentFromTitle(d.person),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoBox(
              lines: [d.owe ? ctx.l.sheetsDebtLeftToPay(f.money(left), f.money(d.amount)) : ctx.l.sheetsDebtLeftToReceive(f.money(left), f.money(d.amount))],
            ),
            const SizedBox(height: 12),
            AmountField(controller: amount, label: ctx.l.sheetsAmount),
            const SizedBox(height: 12),
            accountDropdown(
              ctx,
              label: d.owe ? ctx.l.sheetsDebtPaidFrom : ctx.l.sheetsDebtReceivedIn,
              value: account,
              allowNone: true,
              onChanged: (v) => set(() => account = v),
            ),
            const SizedBox(height: 12),
            DateField(label: ctx.l.sheetsDate, value: date, onChanged: (x) => set(() => date = x)),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: ctx.l.sheetsNote),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                final v = parseAmount(amount.text);
                if (v == null || v <= 0) return toast(ctx, ctx.l.sheetsAmountPositive);
                if (v > left + 0.001) return toast(ctx, ctx.l.sheetsDebtLeftMax(f.money(left)));
                await s.saveTx(
                  Tx(
                    id: newId(),
                    type: TxType.debt,
                    amount: v,
                    cat: 'debt',
                    account: account,
                    dir: d.owe ? -1 : 1,
                    debt: d.id,
                    date: date,
                    note: note.text.trim(),
                  ),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                toast(ctx, v >= left ? ctx.l.sheetsDebtSettled : ctx.l.sheetsRepaymentSaved);
              },
              child: Text(ctx.l.sheetsSaveRepayment),
            ),
          ],
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Icon picker
// ---------------------------------------------------------------------------

Future<String?> pickIcon(BuildContext context, String current, Color color) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (ctx, scroll) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ctx.l.sheetsPickIcon, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                controller: scroll,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 56, mainAxisSpacing: 4, crossAxisSpacing: 4),
                itemCount: pickerIcons.length,
                itemBuilder: (_, i) {
                  final n = pickerIcons[i];
                  final sel = n == current;
                  return Material(
                    color: sel ? ctx.c.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(ctx, n),
                      child: Icon(appIcon(n), color: sel ? ctx.c.accent : color),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
