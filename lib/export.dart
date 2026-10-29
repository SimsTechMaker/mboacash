import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'format.dart';
import 'i18n.dart';
import 'models.dart';
import 'security.dart';
import 'state.dart';
import 'widgets/common.dart';

// ---------------------------------------------------------------------------
// CSV
// ---------------------------------------------------------------------------

Future<void> exportCsv(BuildContext context) async {
  final s = context.read<AppState>();
  final lock = context.read<LockService>();
  final f = Fmt(s.settings.currency);
  const types = {
    TxType.income: 'revenu',
    TxType.expense: 'depense',
    TxType.transfer: 'transfert',
    TxType.adjust: 'ajustement',
    TxType.save: 'epargne',
    TxType.debt: 'dette',
  };
  // The first 8 columns are the original layout; the rest make the file
  // re-importable without guessing (see csv_import.dart, which reads both).
  final rows = [
    ['date', 'type', 'libelle', 'compte', 'vers_compte', 'montant', 'devise', 'note', 'categorie', 'objectif', 'personne', 'sens', 'role', 'id'],
  ];
  final txs = [...s.txs]..sort((a, b) => a.date.compareTo(b.date));
  for (final t in txs) {
    final v = txView(s, t);
    final signed = t.type == TxType.expense
        ? -t.amount
        : (t.type == TxType.income || t.type == TxType.transfer)
        ? t.amount
        : t.dir * t.amount;
    final acc = s.accountOf(t);
    final d = t.type == TxType.debt ? s.debtById(t.debt) : null;
    rows.add([
      t.date,
      types[t.type]!,
      v.title,
      acc.isEmpty ? '' : s.accById(acc)?.name ?? '',
      t.type == TxType.transfer ? s.accById(t.to)?.name ?? '' : '',
      // No grouping, so the cell stays a number in Excel ("12500", "12500,5" / "12500.5").
      f.number(signed).replaceAll(lang == 'en' ? ',' : ' ', ''),
      s.settings.currency,
      t.note,
      t.type == TxType.income || t.type == TxType.expense ? s.catById(t.cat)?.name ?? '' : '',
      t.type == TxType.save ? s.goalById(t.goal)?.name ?? '' : '',
      d?.person ?? '',
      d == null ? '' : (d.owe ? 'je_dois' : 'on_me_doit'),
      t.type == TxType.debt ? (t.init ? 'pret_initial' : 'remboursement') : '',
      t.id,
    ]);
  }
  String cell(String v) => RegExp(r'[";\n]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;
  final csv = '﻿${rows.map((r) => r.map(cell).join(';')).join('\n')}';
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/my-nkap-${todayIso()}.csv');
  await file.writeAsString(csv, encoding: utf8);
  await lock.withoutLock(
    () => SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: tr.exportCsvSubject,
      ),
    ),
  );
}

/// Exports and shared PDFs are written in plain text to the app's cache so the
/// share sheet can read them. Remove the old ones at each start so financial
/// data does not linger there.
Future<void> cleanExportFiles() async {
  try {
    final dir = await getTemporaryDirectory();
    final limit = DateTime.now().subtract(const Duration(minutes: 10));
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is File && (e.path.endsWith('.csv') || e.path.endsWith('.pdf') || e.path.endsWith('.nkap')) && (await e.lastModified()).isBefore(limit)) {
        await e.delete();
      }
    }
  } catch (_) {
    // Best effort only.
  }
}

// ---------------------------------------------------------------------------
// PDF statement
// ---------------------------------------------------------------------------

class StatementOptions {
  final String from, to;
  final String account; // '' = all accounts
  final bool categories, plans;
  const StatementOptions({required this.from, required this.to, this.account = '', this.categories = true, this.plans = true});
}

Future<Uint8List> buildStatement(AppState s, StatementOptions o) async {
  final f = Fmt(s.settings.currency);
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSans-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSans-SemiBold.ttf'));
  String m(double v, {bool signed = false}) => f.plain(v, signed: signed);

  final scope = o.account.isNotEmpty ? {o.account} : s.settings.accounts.map((a) => a.id).toSet();
  double effectOn(Tx t) => s.effects(t).where((e) => scope.contains(e.account)).fold(0.0, (a, e) => a + e.delta);
  final txs = [...s.txs]..sort((a, b) => a.date.compareTo(b.date) != 0 ? a.date.compareTo(b.date) : a.created.compareTo(b.created));

  var opening = scope.fold<double>(0, (a, id) => a + (s.accById(id)?.initial ?? 0));
  for (final t in txs) {
    if (t.date.compareTo(o.from) < 0) opening += effectOn(t);
  }
  var run = opening, debit = 0.0, credit = 0.0;
  final rows = <List<String>>[];
  for (final t in txs) {
    if (t.date.compareTo(o.from) < 0 || t.date.compareTo(o.to) > 0) continue;
    if (!s.effects(t).any((e) => scope.contains(e.account))) continue;
    final e = effectOn(t);
    run += e;
    if (e < 0) {
      debit -= e;
    } else {
      credit += e;
    }
    final v = txView(s, t);
    final acc = s.accountOf(t);
    final accName = t.type == TxType.transfer ? '${s.accById(acc)?.name} -> ${s.accById(t.to)?.name}' : (acc.isEmpty ? '' : s.accById(acc)?.name ?? '');
    final label = switch (t.type) {
      TxType.transfer => '${e == 0 ? tr.exportTransferInternal : tr.exportTransfer}${t.note.isNotEmpty ? ' - ${t.note}' : ''}',
      TxType.income || TxType.expense => t.note.isNotEmpty ? t.note : v.title,
      _ => '${v.title}${t.note.isNotEmpty ? ' - ${t.note}' : ''}',
    };
    final catName = (t.type == TxType.income || t.type == TxType.expense) ? (s.catById(t.cat)?.name ?? '') : v.title.split(RegExp(r'\s?:')).first.trim();
    rows.add([slashDate(t.date), label, catName, accName, e < 0 ? m(-e) : '', e > 0 ? m(e) : '', m(run)]);
  }
  final period = txs.where((t) => t.date.compareTo(o.from) >= 0 && t.date.compareTo(o.to) <= 0 && s.flow(t) != 0 && scope.contains(s.accountOf(t)));
  final sums = s.sums(period);

  const accent = PdfColor.fromInt(0xFF1D6A56);
  const ink = PdfColor.fromInt(0xFF14201B);
  const muted = PdfColor.fromInt(0xFF5A6963);
  const line = PdfColor.fromInt(0xFFD2DBD7);
  const zebra = PdfColor.fromInt(0xFFF7F9F8);
  const foot = PdfColor.fromInt(0xFFE2E8E5);
  const red = PdfColor.fromInt(0xFFB23F28);
  const green = PdfColor.fromInt(0xFF2C7A4C);

  final theme = pw.ThemeData.withFont(base: regular, bold: bold);
  final doc = pw.Document(title: tr.exportPdfDocTitle, author: 'my-nkap');
  final accTitle = o.account.isNotEmpty ? s.accById(o.account)?.name ?? '' : tr.exportAllAccounts;

  pw.Widget table(
    List<String> head,
    List<List<String>> body, {
    List<String>? footer,
    Map<int, pw.TableColumnWidth>? widths,
    Set<int> right = const {},
    Map<int, PdfColor> colors = const {},
  }) {
    return pw.TableHelper.fromTextArray(
      headers: head,
      data: [...body, ?footer],
      border: pw.TableBorder.all(color: line, width: 0.5),
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: accent),
      cellStyle: const pw.TextStyle(fontSize: 8, color: ink),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      oddRowDecoration: const pw.BoxDecoration(color: zebra),
      columnWidths: widths,
      cellAlignments: {for (final i in right) i: pw.Alignment.centerRight},
      headerAlignments: {for (final i in right) i: pw.Alignment.centerRight},
      // Rows are counted with the header as row 0, so the totals row is body.length + 1.
      textStyleBuilder: (col, data, row) {
        final isFoot = footer != null && row == body.length + 1;
        return pw.TextStyle(fontSize: 8, color: isFoot ? ink : colors[col] ?? ink, fontWeight: isFoot ? pw.FontWeight.bold : pw.FontWeight.normal);
      },
      cellDecoration: (col, data, row) => footer != null && row == body.length + 1 ? const pw.BoxDecoration(color: foot) : const pw.BoxDecoration(),
    );
  }

  pw.Widget box(String l, String v, bool hi) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 3),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: hi ? const PdfColor.fromInt(0xFFE6F2ED) : zebra,
        border: pw.Border.all(color: line),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l.toUpperCase(),
            style: pw.TextStyle(fontSize: 7, color: muted, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(v, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ),
  );

  pw.Widget section(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
    child: pw.Text(t, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
  );

  final byCat = <String, double>{};
  for (final t in period.where((t) => s.flow(t) < 0)) {
    byCat[s.flowKey(t)] = (byCat[s.flowKey(t)] ?? 0) - s.flow(t);
  }
  final catRows = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 36),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(14),
              color: accent,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          tr.exportTitle,
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(tr.exportPeriod(longDate(o.from), longDate(o.to)), style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                        pw.Text(accTitle, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        tr.appTitle,
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(tr.exportIssued(longDate(todayIso())), style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                      pw.Text(tr.exportCurrency(s.settings.currency), style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            )
          : pw.SizedBox(),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: line, width: 0.5)),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(tr.exportFooter(longDate(o.from), longDate(o.to)), style: const pw.TextStyle(fontSize: 7, color: muted)),
            ),
            pw.Text(tr.exportPage('${ctx.pageNumber}', '${ctx.pagesCount}'), style: const pw.TextStyle(fontSize: 7, color: muted)),
          ],
        ),
      ),
      build: (ctx) => [
        pw.Row(
          children: [
            box(tr.exportOpening, m(opening), false),
            box(tr.exportCredits, m(credit), false),
            box(tr.exportDebits, m(debit), false),
            box(tr.exportClosing, m(run), true),
          ],
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Text(
            tr.exportPeriodSummary(m(sums.income), m(sums.expense), tr.opsCount(rows.length)),
            style: const pw.TextStyle(fontSize: 8.5, color: muted),
          ),
        ),
        if (rows.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Center(
              child: pw.Text(tr.exportEmpty, style: const pw.TextStyle(color: muted)),
            ),
          )
        else
          table(
            [tr.exportColDate, tr.exportColLabel, tr.exportColCategory, tr.exportColAccount, tr.exportColDebit, tr.exportColCredit, tr.exportColBalance],
            rows,
            footer: ['', tr.exportTotals, '', '', m(debit), m(credit), m(run)],
            widths: {
              0: const pw.FixedColumnWidth(48),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1.6),
              3: const pw.FlexColumnWidth(1.7),
              4: const pw.FixedColumnWidth(64),
              5: const pw.FixedColumnWidth(64),
              6: const pw.FixedColumnWidth(68),
            },
            right: {4, 5, 6},
            colors: {4: red, 5: green},
          ),
        if (o.categories && catRows.isNotEmpty) ...[
          section(tr.exportByCategory),
          table(
            [tr.exportColCategory, tr.exportColAmount, tr.exportColShare, tr.exportColCap],
            [
              for (final r in catRows)
                [
                  s.group(r.key).name,
                  m(r.value),
                  tr.exportPercent('${(r.value / sums.expense * 100).round()}'),
                  (s.catById(r.key)?.cap ?? 0) > 0 ? m(s.catById(r.key)!.cap) : '-',
                ],
            ],
            footer: [tr.exportTotal, m(sums.expense), tr.exportPercent('100'), ''],
            right: {1, 2, 3},
          ),
        ],
        if (o.plans && o.account.isEmpty && s.goals.isNotEmpty) ...[
          section(tr.typeSave),
          table(
            [tr.exportColGoal, tr.exportColSaved, tr.exportColTarget, tr.exportColProgress, tr.exportColTargetDate],
            [
              for (final g in s.goals)
                [
                  g.name,
                  m(s.goalSaved(g)),
                  g.target > 0 ? m(g.target) : '-',
                  g.target > 0 ? tr.exportPercent('${(s.goalSaved(g) / g.target * 100).clamp(0, 100).round()}') : '-',
                  g.deadline.isEmpty ? '-' : longDate(g.deadline),
                ],
            ],
            right: {1, 2, 3},
          ),
        ],
        if (o.plans && o.account.isEmpty && s.debts.isNotEmpty) ...[
          section(tr.exportDebtsLoans),
          table(
            [tr.exportColPerson, tr.exportColDirection, tr.exportColAmount, tr.exportColRepaid, tr.exportColLeft, tr.exportColDue],
            [
              for (final d in s.debts)
                [
                  d.person,
                  d.owe ? tr.exportIOwe : tr.exportOwedToMe,
                  m(d.amount),
                  m(d.amount - s.debtLeft(d)),
                  s.debtLeft(d) > 0 ? m(s.debtLeft(d)) : tr.exportSettled,
                  d.due.isEmpty ? '-' : longDate(d.due),
                ],
            ],
            right: {2, 3, 4},
          ),
        ],
      ],
    ),
  );
  return doc.save();
}

String statementFileName(AppState s, StatementOptions o) {
  var name = tr.exportFileName(o.from, o.to);
  if (o.account.isNotEmpty) {
    final a = (s.accById(o.account)?.name ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    name += '-$a';
  }
  return '$name.pdf';
}
