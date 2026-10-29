import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../csv_import.dart';
import '../i18n.dart';
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
        if (mounted) toast(context, context.l.importTooBig);
        return;
      }
      final p = planImport(s, decodeCsvBytes(bytes));
      setState(() {
        plan = p;
        fileName = files.first.name;
      });
    } catch (_) {
      if (mounted) toast(context, context.l.importCantRead);
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
      toast(context, context.l.importDone(p.txs.length));
    } catch (_) {
      if (mounted) toast(context, context.l.importFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final l = context.l;
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
      appBar: AppBar(title: Text(l.importTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.importIntro, style: TextStyle(color: context.c.muted)),
          const SizedBox(height: 16),
          OutlinedButton.icon(icon: Icon(appIcon('file-up')), label: Text(p == null ? l.importPick : l.importPickOther), onPressed: busy ? null : pick),
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
                  fact('circle-check', context.c.income, l.importToImport(p.txs.length)),
                  if (p.duplicates > 0) fact('copy', context.c.muted, l.importDuplicates(p.duplicates)),
                  if (p.errors.isNotEmpty) fact('triangle-alert', context.c.warn, l.importBadLines(p.errors.length)),
                  if (p.newCats.isNotEmpty) fact('tags', context.c.accent, l.importNewCats(p.newCats.map((c) => c.name).join(', '))),
                  if (p.newAccounts.isNotEmpty) fact('wallet', context.c.accent, l.importNewAccounts(p.newAccounts.map((a) => a.name).join(', '))),
                  if (p.newGoals.isNotEmpty) fact('piggy-bank', context.c.accent, l.importNewGoals(p.newGoals.map((g) => g.name).join(', '))),
                  if (p.newDebts.isNotEmpty) fact('handshake', context.c.accent, l.importNewDebts(p.newDebts.map((d) => d.person).join(', '))),
                  if (p.currency != null) fact('coins', context.c.warn, l.importCurrencyWarn(p.currency!, context.read<AppState>().settings.currency)),
                  if (p.errors.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    for (final e in p.errors.take(5)) Text('• $e', style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                    if (p.errors.length > 5) Text('• ${l.importMoreErrors(p.errors.length - 5)}', style: TextStyle(color: context.c.muted, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(onPressed: p.isEmpty ? null : run, child: Text(p.isEmpty ? l.importNothing : l.importButton(p.txs.length))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
