import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../export.dart';
import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../security.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum _Period { current, previous, year, custom }

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});
  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  _Period period = _Period.current;
  late String from, to;
  String account = '';
  bool categories = true, plans = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final m = context.read<AppState>().month;
    from = '$m-01';
    to = _lastDay(m);
  }

  String _lastDay(String m) {
    final d = parseIso('$m-01');
    return isoDate(DateTime(d.year, d.month + 1, 0));
  }

  StatementOptions? _options(AppState s) {
    String a, b;
    switch (period) {
      case _Period.current:
        a = '${s.month}-01';
        b = _lastDay(s.month);
      case _Period.previous:
        final p = shiftMonth(s.month, -1);
        a = '$p-01';
        b = _lastDay(p);
      case _Period.year:
        final y = s.month.substring(0, 4);
        a = '$y-01-01';
        b = '$y-12-31';
      case _Period.custom:
        a = from;
        b = to;
    }
    if (a.compareTo(b) > 0) return null;
    return StatementOptions(from: a, to: b, account: account, categories: categories, plans: plans);
  }

  Future<void> run({required bool print}) async {
    final s = context.read<AppState>();
    final lock = context.read<LockService>();
    final o = _options(s);
    if (o == null) return toast(context, 'Choisis une période valide.');
    setState(() => busy = true);
    try {
      final bytes = await buildStatement(s, o);
      final name = statementFileName(s, o);
      await lock.withoutLock(() async {
        if (print) {
          await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
        } else {
          await Printing.sharePdf(bytes: bytes, filename: name);
        }
      });
    } catch (e) {
      if (mounted) toast(context, 'La création du PDF a échoué.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final prev = shiftMonth(s.month, -1);
    return Scaffold(
      appBar: AppBar(title: const Text('Relevé PDF')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Un document A4 prêt à imprimer : soldes d'ouverture et de clôture, toutes les opérations de la période avec le solde après chaque ligne, puis les dépenses par catégorie.",
            style: TextStyle(color: context.c.muted),
          ),
          const SizedBox(height: 16),
          const Label('Période'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in _Period.values)
                ChoiceChip(
                  selected: period == p,
                  onSelected: (_) => setState(() => period = p),
                  label: Text(switch (p) {
                    _Period.current => monthLabel(s.month),
                    _Period.previous => monthLabel(prev),
                    _Period.year => 'Année ${s.month.substring(0, 4)}',
                    _Period.custom => 'Dates au choix',
                  }),
                ),
            ],
          ),
          if (period == _Period.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DateField(label: 'Du', value: from, onChanged: (d) => setState(() => from = d)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateField(label: 'Au', value: to, onChanged: (d) => setState(() => to = d)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: account,
            decoration: const InputDecoration(labelText: 'Comptes'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Tous les comptes')),
              for (final a in s.activeAccounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => account = v ?? ''),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: categories,
            onChanged: (v) => setState(() => categories = v),
            title: const Text('Inclure les dépenses par catégorie'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: plans,
            onChanged: account.isEmpty ? (v) => setState(() => plans = v) : null,
            title: const Text("Inclure l'épargne et les dettes"),
            subtitle: account.isEmpty ? null : const Text('Seulement pour le relevé de tous les comptes'),
          ),
          const SizedBox(height: 20),
          if (busy)
            const Center(
              child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
            ),
          if (!busy) ...[
            FilledButton.icon(icon: Icon(appIcon('printer')), label: const Text('Aperçu et impression'), onPressed: () => run(print: true)),
            const SizedBox(height: 10),
            OutlinedButton.icon(icon: Icon(appIcon('share-2')), label: const Text('Partager le PDF'), onPressed: () => run(print: false)),
          ],
          const SizedBox(height: 16),
          Text(
            "« Aperçu et impression » ouvre l'impression Android, qui permet aussi d'enregistrer en PDF. « Partager » l'envoie par WhatsApp, e-mail ou vers tes fichiers.",
            style: TextStyle(color: context.c.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
