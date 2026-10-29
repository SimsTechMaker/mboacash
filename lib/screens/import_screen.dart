import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../csv_import.dart';
import '../format.dart';
import '../icons.dart';
import '../security.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Re-imports a CSV exported by carnet237: pick, preview, confirm.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  ImportPlan? plan;
  String? fileName;
  bool busy = false;

  Future<void> pick() async {
    final s = context.read<AppState>();
    final lock = context.read<LockService>();
    setState(() => busy = true);
    try {
      final files = await lock.withoutLock(() => FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'txt']));
      if (files.isEmpty) return;
      final bytes = await files.first.readAsBytes();
      if (bytes.length > 20 * 1024 * 1024) {
        if (mounted) toast(context, 'Fichier trop volumineux (plus de 20 Mo).');
        return;
      }
      final p = planImport(s, decodeCsvBytes(bytes));
      setState(() {
        plan = p;
        fileName = files.first.name;
      });
    } catch (_) {
      if (mounted) toast(context, 'Impossible de lire ce fichier.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> run() async {
    final p = plan!;
    setState(() => busy = true);
    try {
      await context.read<AppState>().importData(txs: p.txs, cats: p.newCats, accounts: p.newAccounts, goals: p.newGoals, debts: p.newDebts);
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, '${plural(p.txs.length, 'opération')} importée${p.txs.length > 1 ? 's' : ''}');
    } catch (_) {
      if (mounted) toast(context, "L'import a échoué ; rien n'a été modifié.");
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = plan;
    Widget fact(String icon, Color color, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(appIcon(icon), size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Importer un CSV')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Choisis un fichier exporté par carnet237 (Plus › Exporter en CSV), même modifié dans Excel. Les opérations déjà présentes sont ignorées, et les catégories, comptes, objectifs et dettes manquants sont créés.",
            style: TextStyle(color: context.c.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: Icon(appIcon('file-up')),
            label: Text(p == null ? 'Choisir un fichier' : 'Choisir un autre fichier'),
            onPressed: busy ? null : pick,
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (p != null && !busy) ...[
            const SizedBox(height: 16),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(fileName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  fact('circle-check', context.c.income, '${plural(p.txs.length, 'opération')} à importer'),
                  if (p.duplicates > 0)
                    fact('copy', context.c.muted, '${plural(p.duplicates, 'doublon')} ignoré${p.duplicates > 1 ? 's' : ''} (déjà dans l\'app)'),
                  if (p.errors.isNotEmpty)
                    fact('triangle-alert', context.c.warn, '${plural(p.errors.length, 'ligne')} illisible${p.errors.length > 1 ? 's' : ''}'),
                  if (p.newCats.isNotEmpty) fact('tags', context.c.accent, 'Catégories créées : ${p.newCats.map((c) => c.name).join(', ')}'),
                  if (p.newAccounts.isNotEmpty) fact('wallet', context.c.accent, 'Comptes créés : ${p.newAccounts.map((a) => a.name).join(', ')}'),
                  if (p.newGoals.isNotEmpty) fact('piggy-bank', context.c.accent, 'Objectifs créés : ${p.newGoals.map((g) => g.name).join(', ')}'),
                  if (p.newDebts.isNotEmpty) fact('handshake', context.c.accent, 'Dettes créées : ${p.newDebts.map((d) => d.person).join(', ')}'),
                  if (p.currency != null)
                    fact(
                      'coins',
                      context.c.warn,
                      'Le fichier est en ${p.currency}, l\'app en ${context.read<AppState>().settings.currency} : les montants sont importés tels quels, sans conversion.',
                    ),
                  if (p.errors.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    for (final e in p.errors.take(5)) Text('• $e', style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                    if (p.errors.length > 5) Text('• … et ${p.errors.length - 5} autres', style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(onPressed: p.isEmpty ? null : run, child: Text(p.isEmpty ? 'Rien à importer' : 'Importer ${plural(p.txs.length, 'opération')}')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
