import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import 'settings_screen.dart';

class OpsScreen extends StatelessWidget {
  const OpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final month = s.monthTxs(s.month);
    final sum = s.sums(month);
    final bal = sum.income - sum.expense;

    final scoped = month.where((t) => s.accFilter == null || s.accountOf(t) == s.accFilter || t.to == s.accFilter).toList();
    final usedCats = scoped.map((t) => t.cat).toSet().toList();
    final catFilter = usedCats.contains(s.catFilter) ? s.catFilter : null;
    final list = scoped.where((t) => catFilter == null || t.cat == catFilter).toList()
      ..sort((a, b) => b.date.compareTo(a.date) != 0 ? b.date.compareTo(a.date) : b.created.compareTo(a.created));
    final byDay = <String, List<Tx>>{};
    for (final t in list) {
      byDay.putIfAbsent(t.date, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        Center(child: const MonthNav()),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Label('Solde du mois'),
                          const SizedBox(height: 4),
                          FittedBox(
                            child: Money(
                              bal,
                              signed: true,
                              size: 26,
                              color: bal < 0
                                  ? context.c.expense
                                  : bal > 0
                                  ? context.c.income
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _Total(label: 'Revenus', value: sum.income, color: context.c.income),
                    ),
                    VerticalDivider(width: 1, color: context.c.line),
                    Expanded(
                      child: _Total(label: 'Dépenses', value: sum.expense, color: context.c.expense),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _Budget(spent: sum.expense),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Journal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (list.isNotEmpty) Label(plural(list.length, 'opération')),
                ],
              ),
              if (s.accFilter != null || usedCats.length > 1) ...[
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
                      if (usedCats.length > 1) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: const Text('Tout'),
                            selected: catFilter == null,
                            onSelected: (_) => s.setFilters(cat: null, acc: s.accFilter),
                          ),
                        ),
                        for (final id in usedCats)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              avatar: Icon(appIcon(_catIcon(s, id)), size: 16, color: slot(s.catById(id)?.color ?? 'c10')),
                              label: Text(_catName(s, id)),
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
                      ? 'Ton carnet est vide. Ajoute ta première dépense avec le bouton +, ou charge quelques exemples pour voir le carnet rempli.'
                      : 'Aucune opération en ${monthLabel(s.month)}${s.accFilter != null ? ' sur ce compte' : ''}.',
                  action: s.txs.isEmpty
                      ? OutlinedButton(
                          onPressed: () async {
                            await s.loadSamples();
                            if (context.mounted) toast(context, 'Exemples chargés. Tu pourras les retirer dans Paramètres › Données.');
                          },
                          child: const Text('Charger des exemples'),
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
                          final net = e.value.fold<double>(
                            0,
                            (a, t) =>
                                a +
                                (t.type == TxType.income
                                    ? t.amount
                                    : t.type == TxType.expense
                                    ? -t.amount
                                    : 0),
                          );
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

  static String _catName(AppState s, String id) =>
      const {'transfer': 'Transfert', 'adjust': 'Ajustement', 'save': 'Épargne', 'debt': 'Dettes'}[id] ?? s.catById(id)?.name ?? 'Sans catégorie';
  static String _catIcon(AppState s, String id) =>
      const {'transfer': 'arrow-left-right', 'adjust': 'sliders-horizontal', 'save': 'piggy-bank', 'debt': 'handshake'}[id] ?? s.catById(id)?.icon ?? 'package';
}

class _Total extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _Total({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(label),
        const SizedBox(height: 4),
        FittedBox(child: Money(value, size: 18, color: color)),
      ],
    ),
  );
}

class _Budget extends StatelessWidget {
  final double spent;
  const _Budget({required this.spent});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = fmtOf(context);
    final b = s.settings.budget;
    if (b <= 0) {
      return ListTile(
        dense: true,
        title: const Label('Budget'),
        trailing: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(initialTab: 3))),
          child: const Text('Fixer un budget mensuel'),
        ),
      );
    }
    final pct = spent / b;
    final color = pct > 1
        ? context.c.expense
        : pct >= 0.8
        ? context.c.warn
        : context.c.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Label('Budget'),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${f.money(spent)} / ${f.money(b)}', style: numStyle.copyWith(fontSize: 13), overflow: TextOverflow.ellipsis),
              ),
              Pill(pct > 1 ? 'Dépassé de ${f.money(spent - b)}' : 'Reste ${f.money(b - spent)}', color: color),
            ],
          ),
          const SizedBox(height: 8),
          Gauge(value: pct, color: color),
        ],
      ),
    );
  }
}
