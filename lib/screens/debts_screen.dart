import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  bool owe = true;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.debts.where((d) => d.owe == owe).toList()
      ..sort((a, b) {
        final open = (s.debtLeft(b) > 0 ? 1 : 0) - (s.debtLeft(a) > 0 ? 1 : 0);
        if (open != 0) return open;
        return (a.due.isEmpty ? '9' : a.due).compareTo(b.due.isEmpty ? '9' : b.due);
      });

    Widget kpi(String l, double v, Color c) => Expanded(
      child: Panel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Label(l),
            const SizedBox(height: 4),
            FittedBox(child: Money(v, size: 18, color: c)),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Dettes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDebtSheet(context, owe: owe),
        icon: Icon(appIcon('plus')),
        label: Text(owe ? 'Ajouter une dette' : 'Ajouter un prêt'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Row(children: [kpi('Je dois', s.totalOwed, context.c.expense), const SizedBox(width: 10), kpi('On me doit', s.totalLent, context.c.income)]),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Je dois')),
              ButtonSegment(value: false, label: Text('On me doit')),
            ],
            selected: {owe},
            onSelectionChanged: (v) => setState(() => owe = v.first),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            Panel(
              child: EmptyState(
                icon: 'handshake',
                text: owe ? "Note l'argent que tu as emprunté et suis tes remboursements." : "Note l'argent que tu as prêté et suis ce qu'on te rembourse.",
              ),
            ),
          for (final d in list) ...[_DebtCard(debt: d), const SizedBox(height: 10)],
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final d = debt;
    final left = s.debtLeft(d), paid = d.amount - left;
    final settled = left <= 0;
    final late = !settled && d.due.isNotEmpty && d.due.compareTo(todayIso()) < 0;
    return Opacity(
      opacity: settled ? 0.7 : 1,
      child: Panel(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconBadge(icon: d.owe ? 'arrow-down-left' : 'arrow-up-right', color: slot(d.owe ? 'c4' : 'c8')),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(d.person, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (d.sample) ...[
                        const SizedBox(width: 6),
                        Text(
                          'EXEMPLE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.c.warn),
                        ),
                      ],
                    ],
                  ),
                ),
                Money(left, size: 15, color: settled ? null : (d.owe ? context.c.expense : context.c.income)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${f.money(paid)} remboursés sur ${f.money(d.amount)} · depuis le ${longDate(d.date)}${d.note.isNotEmpty ? ' · ${d.note}' : ''}',
              style: TextStyle(color: context.c.muted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Gauge(value: d.amount > 0 ? paid / d.amount : 0, color: context.c.income, height: 6),
                ),
                const SizedBox(width: 10),
                if (settled)
                  Pill('Soldée', color: context.c.income)
                else if (late)
                  Pill('En retard', color: context.c.expense)
                else if (d.due.isNotEmpty)
                  Pill('Échéance ${longDate(d.due)}', color: context.c.muted),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(),
            Wrap(
              children: [
                if (!settled)
                  TextButton.icon(
                    icon: Icon(appIcon('check'), size: 18),
                    label: Text(d.owe ? 'Je rembourse' : 'On me rembourse'),
                    onPressed: () => openDebtPaySheet(context, d),
                  ),
                TextButton.icon(
                  icon: Icon(appIcon('pencil'), size: 18),
                  label: const Text('Modifier'),
                  onPressed: () => openDebtSheet(context, debt: d),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
