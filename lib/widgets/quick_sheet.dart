import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../icons.dart';
import '../insights.dart';
import '../models.dart';
import '../quick_entry.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';
import 'sheets.dart';

/// Quick entry: one phrase, such as "taxi 1500 momo", and the movement is
/// recorded. The home screen, the app shortcut and the widget open it.
Future<void> openQuickEntry(BuildContext context) => showFormSheet(context, title: context.l.quickTitle, builder: (_) => const _QuickForm());

class _QuickForm extends StatefulWidget {
  const _QuickForm();
  @override
  State<_QuickForm> createState() => _QuickFormState();
}

class _QuickFormState extends State<_QuickForm> {
  final text = TextEditingController();

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> save(QuickGuess g) async {
    final s = context.read<AppState>();
    final l = context.l;
    final f = fmtOf(context);
    final tx = Tx(id: newId(), type: g.type, amount: g.amount!, cat: g.cat!, account: g.account, date: todayIso(), note: g.note);
    if (!await confirmDuplicate(context, s, tx)) return;
    if (!mounted) return;
    if (g.type == TxType.expense && !await confirmOverdraft(context, s, g.account, s.balanceWith(g.account, -g.amount!))) return;
    if (!mounted) return;
    await s.saveTx(tx);
    if (!s.view.contains(tx.date)) s.setView(s.periodOf(tx.date));
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, l.quickSaved(f.money(g.type == TxType.income ? g.amount! : -g.amount!, signed: true), g.note.isEmpty ? s.group(g.cat!).name : g.note));
  }

  /// The full form, filled with what was understood.
  void details(QuickGuess g) {
    final s = context.read<AppState>();
    Navigator.pop(context);
    openTxSheet(
      context,
      from: Recurring(g.note, g.cat ?? s.activeCats(false).first.id, g.account, g.type == TxType.income, g.amount ?? 0, 0, todayIso(), todayIso(), false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = context.l;
    final f = fmtOf(context);
    final typed = text.text.trim().isNotEmpty;
    final g = parseQuick(s, text.text);
    final habits = noteHabits(s, text.text.replaceAll(RegExp(r'[\d.,  ]+.*$'), ''));
    final group = s.group(g.cat ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: text,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => g.ready ? save(g) : null,
          decoration: InputDecoration(hintText: l.quickHint, prefixIcon: Icon(appIcon('zap'), size: 20)),
        ),
        const SizedBox(height: 8),
        Text(l.quickHelp, style: TextStyle(color: context.c.muted, fontSize: 12.5)),
        if (habits.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final h in habits)
                ActionChip(
                  avatar: Icon(appIcon(s.group(h.cat).icon), size: 16, color: slot(s.group(h.cat).color)),
                  label: Text('${h.note} · ${f.money(h.amount)}'),
                  onPressed: () => setState(() => text.text = h.note),
                ),
            ],
          ),
        ],
        if (typed) ...[
          const SizedBox(height: 14),
          // What was understood, before anything is saved.
          Panel(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconBadge(icon: group.icon, color: slot(group.color)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.note.isEmpty ? group.name : g.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${group.name} · ${s.accById(g.account)?.name ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.c.muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                g.ready
                    ? FitNumber(
                        child: Text(
                          f.money(g.type == TxType.income ? g.amount! : -g.amount!, signed: true),
                          style: numStyle.copyWith(fontWeight: FontWeight.w600, color: g.type == TxType.income ? context.c.income : context.c.expense),
                        ),
                      )
                    : Text(l.quickNoAmount, style: TextStyle(color: context.c.warn, fontSize: 12.5)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(onPressed: () => details(g), child: Text(l.quickMore)),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(onPressed: g.ready ? () => save(g) : null, child: Text(l.add)),
            ),
          ],
        ),
      ],
    );
  }
}
