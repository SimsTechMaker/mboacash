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

    final balance = s.totalLent - s.totalOwed;
    final open = s.debts.where((d) => s.debtLeft(d) > 0).length;

    return Scaffold(
      appBar: AppBar(title: Text(context.l.debtsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDebtSheet(context, owe: owe),
        icon: Icon(appIcon('plus')),
        label: Text(owe ? context.l.debtsAddDebt : context.l.debtsAddLoan),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          GradientCard(
            tone: HeroTone.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroLabel(context.l.debtsBalance),
                const SizedBox(height: 4),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: AnimatedMoney(balance, signed: true, size: 28, color: Colors.white, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(open == 0 ? context.l.debtsNoneOpen : context.l.debtsOpenCount(open), style: const TextStyle(color: heroSoft, fontSize: 12.5)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: HeroStat(label: context.l.debtsIOwe, icon: 'arrow-down-left', value: s.totalOwed),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: HeroStat(label: context.l.debtsOwedToMe, icon: 'arrow-up-right', value: s.totalLent),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, label: Text(context.l.debtsIOwe)),
              ButtonSegment(value: false, label: Text(context.l.debtsOwedToMe)),
            ],
            selected: {owe},
            onSelectionChanged: (v) => setState(() => owe = v.first),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            Panel(
              child: EmptyState(icon: 'handshake', text: owe ? context.l.debtsEmptyOwe : context.l.debtsEmptyLent),
            ),
          for (var i = 0; i < list.length; i++) ...[
            FadeIn(
              index: i,
              child: _DebtCard(debt: list[i]),
            ),
            const SizedBox(height: 10),
          ],
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
    final pct = d.amount > 0 ? paid / d.amount : 0.0;
    final tone = settled
        ? context.c.income
        : d.owe
        ? context.c.expense
        : context.c.income;
    return AnimatedOpacity(
      opacity: settled ? 0.72 : 1,
      duration: const Duration(milliseconds: 300),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RingProgress(
                  value: pct,
                  color: context.c.income,
                  size: 54,
                  child: Icon(appIcon(settled ? 'check' : (d.owe ? 'arrow-down-left' : 'arrow-up-right')), size: 20, color: slot(d.owe ? 'c4' : 'c8')),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(d.person, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
                          ),
                          if (d.sample) ...[
                            const SizedBox(width: 6),
                            Text(
                              context.l.savingsSampleTag,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.c.warn),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(context.l.debtsRepaidOf(f.money(paid), f.money(d.amount)), style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                      Text(
                        '${context.l.debtsSince(longDate(d.date))}${d.note.isNotEmpty ? ' · ${d.note}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.c.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedMoney(left, size: 16, weight: FontWeight.w600, color: tone),
                    const SizedBox(height: 4),
                    if (settled)
                      Pill(context.l.debtsSettled, color: context.c.income)
                    else if (late)
                      Pill(context.l.debtsLate, color: context.c.expense)
                    else if (d.due.isNotEmpty)
                      Pill(longDate(d.due), color: context.c.muted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!settled)
                  ActionChipButton(
                    icon: 'check',
                    label: d.owe ? context.l.debtsIRepay : context.l.debtsTheyRepay,
                    primary: true,
                    onPressed: () => openDebtPaySheet(context, d),
                  ),
                ActionChipButton(
                  icon: 'pencil',
                  label: context.l.edit,
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
