import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

// ---------------------------------------------------------------------------
// Income / expense / transfer
// ---------------------------------------------------------------------------

Future<void> openTxSheet(BuildContext context, {Tx? tx}) {
  final s = context.read<AppState>();
  if (tx != null && !{TxType.income, TxType.expense, TxType.transfer}.contains(tx.type)) {
    return openMovementDetails(context, tx);
  }
  return showFormSheet(
    context,
    title: tx == null ? 'Nouvelle opération' : "Modifier l'opération",
    builder: (_) => _TxForm(tx: tx, state: s),
  );
}

class _TxForm extends StatefulWidget {
  final Tx? tx;
  final AppState state;
  const _TxForm({this.tx, required this.state});
  @override
  State<_TxForm> createState() => _TxFormState();
}

class _TxFormState extends State<_TxForm> {
  late TxType type;
  late String cat, account, to, date;
  final amount = TextEditingController();
  final note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.state;
    final t = widget.tx;
    type = t?.type ?? TxType.expense;
    account = t != null ? s.accountOf(t) : (s.accFilter ?? s.settings.defaultAccount);
    final other = s.activeAccounts.where((a) => a.id != account).firstOrNull;
    to = t?.to.isNotEmpty == true ? t!.to : (other?.id ?? account);
    cat = t?.cat ?? s.activeCats(false).first.id;
    final today = todayIso();
    date = t?.date ?? (today.startsWith(s.month) ? today : '${s.month}-01');
    if (t != null) {
      amount.text = Fmt(s.settings.currency).number(t.amount);
      note.text = t.note;
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
    if (v == null || v <= 0) return toast(context, 'Indique un montant supérieur à zéro.');
    if (type == TxType.transfer && to == account) return toast(context, 'Choisis deux comptes différents pour un transfert.');
    final t = widget.tx;
    final tx = Tx(
      id: t?.id ?? newId(),
      type: type,
      amount: v,
      cat: type == TxType.transfer ? 'transfer' : cat,
      account: account,
      to: type == TxType.transfer ? to : '',
      date: date,
      note: note.text.trim(),
      sample: t?.sample ?? false,
      created: t?.created,
    );
    await s.saveTx(tx);
    if (!date.startsWith(s.month)) s.setMonth(date.substring(0, 7));
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, t != null ? 'Opération mise à jour' : {TxType.expense: 'Dépense ajoutée', TxType.income: 'Revenu ajouté'}[type] ?? 'Transfert enregistré');
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
          segments: const [
            ButtonSegment(value: TxType.expense, label: Text('Dépense')),
            ButtonSegment(value: TxType.income, label: Text('Revenu')),
            ButtonSegment(value: TxType.transfer, label: Text('Transfert')),
          ],
          selected: {type},
          onSelectionChanged: (v) => setType(v.first),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AmountField(controller: amount, label: 'Montant', autofocus: widget.tx == null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DateField(label: 'Date', value: date, onChanged: (d) => setState(() => date = d)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        accountDropdown(context, label: isT ? 'Depuis le compte' : 'Compte', value: account, extra: [account], onChanged: (v) => setState(() => account = v)),
        if (isT) ...[
          const SizedBox(height: 12),
          accountDropdown(context, label: 'Vers le compte', value: to, extra: [to], onChanged: (v) => setState(() => to = v)),
        ],
        if (!isT) ...[
          const SizedBox(height: 14),
          Text('Catégorie', style: TextStyle(color: context.c.muted, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in cats)
                ChoiceChip(
                  selected: c.id == cat,
                  onSelected: (_) => setState(() => cat = c.id),
                  avatar: Icon(appIcon(c.icon), size: 17, color: slot(c.color)),
                  label: Text(c.name),
                  side: BorderSide(color: c.id == cat ? context.c.ink : context.c.line),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Note', hintText: 'Marché, taxi, facture ENEO…', counterText: ''),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            if (widget.tx != null) ...[
              ConfirmDeleteButton(
                label: 'Supprimer',
                onConfirm: () async {
                  await s.deleteTx(widget.tx!.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    toast(context, 'Opération supprimée');
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(onPressed: save, child: Text(widget.tx == null ? 'Ajouter' : 'Mettre à jour')),
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
  final where = tx.type == TxType.adjust
      ? "Un ajustement corrige le solde d'un compte sans compter comme revenu ou dépense."
      : tx.type == TxType.save
      ? 'Ce mouvement se gère depuis Plus › Épargne.'
      : 'Ce mouvement se gère depuis Plus › Dettes.';
  return showFormSheet(
    context,
    title: v.title,
    builder: (ctx) {
      final f = Fmt(s.settings.currency);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoBox(lines: ['Montant : ${f.money(tx.amount)}', 'Date : ${longDate(tx.date)}', 'Compte : ${v.sub}']),
          const SizedBox(height: 12),
          Text('$where Tu peux le supprimer ici si c\'était une erreur.', style: TextStyle(color: ctx.c.muted)),
          const SizedBox(height: 16),
          ConfirmDeleteButton(
            label: 'Supprimer ce mouvement',
            onConfirm: () async {
              await s.deleteTx(tx.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                toast(ctx, 'Mouvement supprimé');
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
    title: 'Ajuster : ${a.name}',
    builder: (ctx) {
      final f = Fmt(s.settings.currency);
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Indique ce qu'il y a vraiment sur le compte. La différence est enregistrée comme un ajustement, qui ne compte ni comme revenu ni comme dépense.",
              style: TextStyle(color: ctx.c.muted),
            ),
            const SizedBox(height: 12),
            _InfoBox(lines: ['Solde dans le carnet : ${f.money(cur)}']),
            const SizedBox(height: 12),
            AmountField(controller: real, label: 'Solde réel', autofocus: true),
            const SizedBox(height: 12),
            DateField(label: 'Date', value: date, onChanged: (d) => set(() => date = d)),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note', hintText: 'Frais bancaires, oubli…'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                final v = parseAmount(real.text);
                if (v == null) return toast(ctx, 'Indique le solde réel du compte.');
                final diff = await s.adjustAccount(accId, v, date, note.text.trim());
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                toast(ctx, diff == 0 ? 'Le solde est déjà juste.' : 'Solde ajusté (${f.money(diff, signed: true)})');
              },
              child: const Text('Ajuster'),
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
    title: goal == null ? "Nouvel objectif d'épargne" : "Modifier l'objectif",
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: name,
              autofocus: goal == null,
              decoration: const InputDecoration(labelText: 'Nom', hintText: "Fonds d'urgence, voyage, voiture…"),
            ),
            const SizedBox(height: 12),
            AmountField(controller: target, label: 'Montant visé'),
            const SizedBox(height: 12),
            DateField(label: 'Date visée (facultatif)', value: deadline, optional: true, onChanged: (d) => set(() => deadline = d)),
            if (goal == null) ...[const SizedBox(height: 12), AmountField(controller: initial, label: 'Déjà mis de côté (facultatif)')],
            const SizedBox(height: 14),
            Text('Icône', style: TextStyle(color: ctx.c.muted, fontSize: 13)),
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
            if (goal != null) ...[
              const SizedBox(height: 12),
              Text(
                "Supprimer l'objectif efface aussi ses mouvements : l'argent revient sur les comptes d'origine.",
                style: TextStyle(color: ctx.c.muted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                if (goal != null) ...[
                  ConfirmDeleteButton(
                    label: 'Supprimer',
                    onConfirm: () async {
                      await s.deleteGoal(goal.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        toast(ctx, 'Objectif supprimé');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (name.text.trim().isEmpty) return toast(ctx, "Donne un nom à l'objectif.");
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
                      toast(ctx, goal == null ? 'Objectif créé' : 'Objectif mis à jour');
                    },
                    child: Text(goal == null ? "Créer l'objectif" : 'Enregistrer'),
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
    title: dir < 0 ? 'Mettre de côté : ${g.name}' : 'Retirer de : ${g.name}',
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoBox(lines: ['Déjà épargné : ${f.money(saved)}${g.target > 0 ? ' sur ${f.money(g.target)}' : ''}']),
            const SizedBox(height: 12),
            AmountField(controller: amount, label: 'Montant', autofocus: true),
            const SizedBox(height: 12),
            accountDropdown(ctx, label: dir < 0 ? 'Depuis le compte' : 'Vers le compte', value: account, onChanged: (v) => set(() => account = v)),
            const SizedBox(height: 12),
            DateField(label: 'Date', value: date, onChanged: (d) => set(() => date = d)),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                final v = parseAmount(amount.text);
                if (v == null || v <= 0) return toast(ctx, 'Indique un montant supérieur à zéro.');
                if (dir > 0 && v > saved + 0.001) return toast(ctx, 'Tu ne peux pas retirer plus que ${f.money(saved)}.');
                await s.saveTx(
                  Tx(id: newId(), type: TxType.save, amount: v, cat: 'save', account: account, dir: dir, goal: g.id, date: date, note: note.text.trim()),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                toast(ctx, dir < 0 ? '${f.money(v)} mis de côté' : "${f.money(v)} retirés de l'épargne");
              },
              child: Text(dir < 0 ? 'Mettre de côté' : 'Retirer'),
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
    title: debt == null ? 'Nouvelle dette' : 'Modifier la dette',
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (debt == null) ...[
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Je dois')),
                  ButtonSegment(value: false, label: Text('On me doit')),
                ],
                selected: {kindOwe},
                onSelectionChanged: (v) => set(() => kindOwe = v.first),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: person,
              decoration: InputDecoration(labelText: 'Personne ou organisme', hintText: kindOwe ? "Qui t'a prêté l'argent ?" : 'À qui as-tu prêté ?'),
            ),
            const SizedBox(height: 12),
            AmountField(controller: amount, label: 'Montant total'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DateField(label: 'Date', value: date, onChanged: (d) => set(() => date = d)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateField(label: 'Échéance', value: due, optional: true, onChanged: (d) => set(() => due = d)),
                ),
              ],
            ),
            if (debt == null) ...[
              const SizedBox(height: 12),
              accountDropdown(
                ctx,
                label: kindOwe ? "J'ai reçu l'argent sur" : "L'argent est sorti de",
                value: account,
                allowNone: true,
                onChanged: (v) => set(() => account = v),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 8),
            Text(
              debt != null
                  ? 'Supprimer la dette efface aussi ses remboursements enregistrés.'
                  : "Choisis un compte pour que l'argent reçu ou prêté apparaisse dans son solde, ou « Ne pas toucher à mes comptes » pour une dette ancienne.",
              style: TextStyle(color: ctx.c.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (debt != null) ...[
                  ConfirmDeleteButton(
                    label: 'Supprimer',
                    onConfirm: () async {
                      await s.deleteDebt(debt.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        toast(ctx, 'Dette supprimée');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final v = parseAmount(amount.text);
                      if (person.text.trim().isEmpty) return toast(ctx, 'Indique la personne ou l\'organisme.');
                      if (v == null || v <= 0) return toast(ctx, 'Indique un montant supérieur à zéro.');
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
                      toast(ctx, debt != null ? 'Dette mise à jour' : (kindOwe ? 'Dette ajoutée' : 'Prêt ajouté'));
                    },
                    child: Text(debt == null ? 'Ajouter' : 'Enregistrer'),
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
    title: d.owe ? 'Rembourser ${d.person}' : 'Remboursement de ${d.person}',
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoBox(lines: ['Reste à ${d.owe ? 'payer' : 'recevoir'} : ${f.money(left)} sur ${f.money(d.amount)}']),
            const SizedBox(height: 12),
            AmountField(controller: amount, label: 'Montant'),
            const SizedBox(height: 12),
            accountDropdown(ctx, label: d.owe ? 'Payé depuis' : 'Reçu sur', value: account, allowNone: true, onChanged: (v) => set(() => account = v)),
            const SizedBox(height: 12),
            DateField(label: 'Date', value: date, onChanged: (x) => set(() => date = x)),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                final v = parseAmount(amount.text);
                if (v == null || v <= 0) return toast(ctx, 'Indique un montant supérieur à zéro.');
                if (v > left + 0.001) return toast(ctx, 'Le reste dû est de ${f.money(left)}.');
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
                toast(ctx, v >= left ? 'Dette soldée' : 'Remboursement enregistré');
              },
              child: const Text('Enregistrer le remboursement'),
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
            const Text('Choisir une icône', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
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
