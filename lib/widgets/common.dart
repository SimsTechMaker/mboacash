import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';

Fmt fmtOf(BuildContext context) => Fmt(context.select<AppState, String>((s) => s.settings.currency));

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}

/// Rounded square with a tinted background and a line icon.
class IconBadge extends StatelessWidget {
  final String icon;
  final Color color;
  final double size;
  final bool soft;
  const IconBadge({super.key, required this.icon, required this.color, this.size = 40, this.soft = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Color.alphaBlend(color.withValues(alpha: 0.16), context.c.surface), borderRadius: BorderRadius.circular(size * 0.28)),
      child: Icon(appIcon(icon), color: color, size: size * 0.5),
    );
  }
}

class Gauge extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const Gauge({super.key, required this.value, required this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: height,
        backgroundColor: context.c.surface2,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(99)),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class Label extends StatelessWidget {
  final String text;
  const Label(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(fontSize: 11, letterSpacing: 0.9, fontWeight: FontWeight.w600, color: context.c.muted),
  );
}

class Money extends StatelessWidget {
  final double value;
  final bool signed;
  final double size;
  final Color? color;
  const Money(this.value, {super.key, this.signed = false, this.size = 15, this.color});

  @override
  Widget build(BuildContext context) => Text(
    fmtOf(context).money(value, signed: signed),
    style: numStyle.copyWith(fontSize: size, color: color ?? context.c.ink, fontWeight: FontWeight.w500),
  );
}

/// Amount that counts up or down to its new value (balance, totals).
class AnimatedMoney extends StatelessWidget {
  final double value;
  final bool signed;
  final double size;
  final Color? color;
  final FontWeight weight;
  const AnimatedMoney(this.value, {super.key, this.signed = false, this.size = 15, this.color, this.weight = FontWeight.w500});

  @override
  Widget build(BuildContext context) {
    final f = fmtOf(context);
    return TweenAnimationBuilder<double>(
      // Counts up from 0 on first display, then from the previous value.
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(
        f.money(v, signed: signed),
        style: numStyle.copyWith(fontSize: size, color: color ?? context.c.ink, fontWeight: weight),
      ),
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class EmptyState extends StatelessWidget {
  final String icon;
  final String text;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Icon(appIcon(icon), size: 32, color: context.c.accent),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.c.muted),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// Month selector used by Operations, Categories and Statistics.
class MonthNav extends StatelessWidget {
  const MonthNav({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        border: Border.all(color: context.c.line),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Mois précédent',
            icon: Icon(appIcon('chevron-left'), size: 20),
            onPressed: () => s.setMonth(shiftMonth(s.month, -1)),
          ),
          SizedBox(
            width: 128,
            child: Text(
              monthLabel(s.month),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Mois suivant',
            icon: Icon(appIcon('chevron-right'), size: 20),
            onPressed: () => s.setMonth(shiftMonth(s.month, 1)),
          ),
        ],
      ),
    );
  }
}

/// How a movement is shown in lists: title, subtitle, signed amount, icon.
class TxView {
  final String title, sub, icon;
  final double shown;
  final bool signed;
  final Color color;
  final int tone; // 1 income, -1 expense, 0 neutral
  TxView(this.title, this.sub, this.icon, this.color, this.shown, this.signed, this.tone);
}

TxView txView(AppState s, Tx t) {
  final accId = s.accountOf(t);
  final acc = accId.isEmpty ? null : s.accById(accId);
  final accName = acc?.name ?? 'Hors comptes';
  String withNote(String base) => t.note.isEmpty ? base : '$base · ${t.note}';
  switch (t.type) {
    case TxType.income:
    case TxType.expense:
      final c = s.catById(t.cat);
      final inc = t.type == TxType.income;
      return TxView(
        c?.name ?? 'Sans catégorie',
        t.note.isEmpty ? accName : '${t.note} · $accName',
        c?.icon ?? 'package',
        slot(c?.color ?? 'c10'),
        inc ? t.amount : -t.amount,
        true,
        inc ? 1 : -1,
      );
    case TxType.transfer:
      return TxView('Transfert', withNote('$accName → ${s.accById(t.to)?.name ?? '?'}'), 'arrow-left-right', slot('c10'), t.amount, false, 0);
    case TxType.adjust:
      return TxView('Ajustement', withNote(accName), 'sliders-horizontal', slot('c10'), t.dir * t.amount, true, 0);
    case TxType.save:
      final g = s.goalById(t.goal);
      final name = g?.name ?? 'objectif supprimé';
      return TxView(
        t.dir < 0 ? 'Épargne : $name' : "Retrait d'épargne : $name",
        withNote('${t.dir < 0 ? 'Depuis' : 'Vers'} $accName'),
        g?.icon ?? 'piggy-bank',
        slot(g?.color ?? 'c2'),
        t.dir * t.amount,
        true,
        0,
      );
    case TxType.debt:
      final d = s.debtById(t.debt);
      final who = d?.person ?? 'dette supprimée';
      final owe = d?.owe ?? t.dir > 0;
      final title = t.init ? (owe ? 'Emprunt auprès de $who' : 'Prêt à $who') : (owe ? 'Remboursement à $who' : 'Remboursement de $who');
      return TxView(title, withNote(accName), 'handshake', slot(owe ? 'c4' : 'c8'), acc == null ? t.amount : t.dir * t.amount, acc != null, 0);
  }
}

class TxTile extends StatelessWidget {
  final Tx tx;
  final VoidCallback? onTap;
  const TxTile({super.key, required this.tx, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = txView(s, tx);
    final color = v.tone > 0
        ? context.c.income
        : v.tone < 0
        ? context.c.expense
        : context.c.muted;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            IconBadge(icon: v.icon, color: v.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          v.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (tx.sample) ...[
                        const SizedBox(width: 6),
                        Text(
                          'EXEMPLE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.c.warn),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    v.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.c.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              fmtOf(context).money(v.shown, signed: v.signed),
              style: numStyle.copyWith(color: color, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text field for amounts with a numeric keyboard.
class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  const AmountField({super.key, required this.controller, required this.label, this.autofocus = false});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
    style: numStyle.copyWith(fontSize: 18),
    decoration: InputDecoration(labelText: label, suffixText: fmtOf(context).symbol),
  );
}

/// Date field that opens the French date picker.
class DateField extends StatelessWidget {
  final String label;
  final String value; // ISO or ''
  final ValueChanged<String> onChanged;
  final bool optional;
  const DateField({super.key, required this.label, required this.value, required this.onChanged, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final init = value.isEmpty ? DateTime.now() : parseIso(value);
        final d = await showDatePicker(
          context: context,
          initialDate: init,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          locale: const Locale('fr', 'FR'),
        );
        if (d != null) onChanged(isoDate(d));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: optional && value.isNotEmpty
              ? IconButton(icon: Icon(appIcon('x'), size: 18), onPressed: () => onChanged(''), tooltip: 'Effacer')
              : Icon(appIcon('calendar'), size: 18),
        ),
        child: Text(value.isEmpty ? 'Aucune' : longDate(value), style: TextStyle(color: value.isEmpty ? context.c.muted : context.c.ink)),
      ),
    );
  }
}

DropdownButtonFormField<String> accountDropdown(
  BuildContext context, {
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
  bool allowNone = false,
  List<String> extra = const [],
}) {
  final s = context.read<AppState>();
  final list = [...s.activeAccounts];
  for (final id in extra) {
    final a = s.accById(id);
    if (a != null && !list.contains(a)) list.add(a);
  }
  final items = <DropdownMenuItem<String>>[
    if (allowNone) const DropdownMenuItem(value: '', child: Text('Ne pas toucher à mes comptes')),
    ...list.map(
      (a) => DropdownMenuItem(
        value: a.id,
        child: Row(children: [Icon(appIcon(a.icon), size: 18), const SizedBox(width: 8), Text(a.name)]),
      ),
    ),
  ];
  final v = items.any((i) => i.value == value) ? value : items.first.value!;
  return DropdownButtonFormField<String>(
    initialValue: v,
    decoration: InputDecoration(labelText: label),
    items: items,
    onChanged: (x) => onChanged(x ?? ''),
  );
}

/// Opens a bottom sheet that scrolls and lifts above the keyboard.
Future<T?> showFormSheet<T>(BuildContext context, {required String title, required Widget Function(BuildContext) builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

/// A delete button that asks for confirmation by changing its own label.
class ConfirmDeleteButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onConfirm;
  const ConfirmDeleteButton({super.key, required this.label, required this.onConfirm});
  @override
  State<ConfirmDeleteButton> createState() => _ConfirmDeleteButtonState();
}

class _ConfirmDeleteButtonState extends State<ConfirmDeleteButton> {
  bool armed = false;
  @override
  Widget build(BuildContext context) {
    final red = context.c.expense;
    return armed
        ? FilledButton(
            style: FilledButton.styleFrom(backgroundColor: red, foregroundColor: Colors.white),
            onPressed: widget.onConfirm,
            child: const Text('Confirmer la suppression'),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: red),
            onPressed: () => setState(() => armed = true),
            child: Text(widget.label),
          );
  }
}
