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
  final rows = <_Row>[];
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
    rows.add(_Row(t.date, label, [if (catName != label) catName, accName].where((x) => x.isNotEmpty).join(' · '), e, run));
  }
  final period = txs.where((t) => t.date.compareTo(o.from) >= 0 && t.date.compareTo(o.to) <= 0 && s.flow(t) != 0 && scope.contains(s.accountOf(t)));
  final sums = s.sums(period);

  const accent = PdfColor.fromInt(0xFF1D6A56);
  const accentDark = PdfColor.fromInt(0xFF124A3C);
  const ink = PdfColor.fromInt(0xFF14201B);
  const muted = PdfColor.fromInt(0xFF66756F);
  const line = PdfColor.fromInt(0xFFE3E9E6);
  const soft = PdfColor.fromInt(0xFFF3F6F4);
  const track = PdfColor.fromInt(0xFFE6ECE9);
  const red = PdfColor.fromInt(0xFFC0492F);
  const green = PdfColor.fromInt(0xFF23805A);
  const gold = PdfColor.fromInt(0xFFE8A33D);
  const heroSoft = PdfColor.fromInt(0xFFCFE3DB);

  final theme = pw.ThemeData.withFont(base: regular, bold: bold);
  final doc = pw.Document(title: tr.exportPdfDocTitle, author: tr.appTitle);
  final accTitle = o.account.isNotEmpty ? s.accById(o.account)?.name ?? '' : tr.exportAllAccounts;
  final logo = pw.MemoryImage((await rootBundle.load('assets/icon/logo-512.png')).buffer.asUint8List());

  /// A number on one line: it keeps its size and only shrinks if it would not
  /// fit, so a very large amount never wraps or gets cut.
  pw.Widget number(String text, pw.TextStyle style, {pw.Alignment align = pw.Alignment.centerRight}) => pw.Align(
    alignment: align,
    child: pw.FittedBox(
      fit: pw.BoxFit.scaleDown,
      alignment: align,
      child: pw.Text(text, style: style),
    ),
  );

  /// Column width that holds the longest of [values], within reason.
  double widthFor(Iterable<String> values, double size) {
    final longest = values.fold<int>(0, (a, v) => v.length > a ? v.length : a);
    return (longest * size * 0.58 + 6).clamp(52.0, 132.0);
  }

  pw.Widget bar(double share, PdfColor color, {double height = 5}) {
    final filled = (share.clamp(0.0, 1.0) * 1000).round();
    return pw.ClipRRect(
      horizontalRadius: height / 2,
      verticalRadius: height / 2,
      child: pw.Container(
        height: height,
        color: track,
        child: pw.Row(
          children: [
            if (filled > 0)
              pw.Expanded(
                flex: filled,
                child: pw.Container(color: color),
              ),
            if (filled < 1000) pw.Expanded(flex: 1000 - filled, child: pw.SizedBox()),
          ],
        ),
      ),
    );
  }

  pw.Widget section(String t, {String? side}) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Row(
      children: [
        pw.Container(
          width: 3,
          height: 12,
          decoration: pw.BoxDecoration(color: gold, borderRadius: pw.BorderRadius.circular(2)),
        ),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: pw.Text(
            t,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ink),
          ),
        ),
        if (side != null) pw.Text(side, style: const pw.TextStyle(fontSize: 8.5, color: muted)),
      ],
    ),
  );

  pw.Widget kpi(String label, String value, PdfColor color) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 4),
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: pw.BoxDecoration(color: soft, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: muted)),
          pw.SizedBox(height: 4),
          number(
            value,
            pw.TextStyle(fontSize: 13.5, fontWeight: pw.FontWeight.bold, color: color),
            align: pw.Alignment.centerLeft,
          ),
        ],
      ),
    ),
  );

  final byCat = <String, double>{};
  for (final t in period.where((t) => s.flow(t) < 0)) {
    byCat[s.flowKey(t)] = (byCat[s.flowKey(t)] ?? 0) - s.flow(t);
  }
  final catRows = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final catMax = catRows.isEmpty ? 1.0 : catRows.first.value;
  final catAmountW = widthFor(catRows.map((r) => m(r.value)), 9.5);

  pw.Widget category(MapEntry<String, double> r) {
    final g = s.group(r.key);
    final cap = s.catById(r.key)?.cap ?? 0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 128,
            child: pw.Text(g.name, maxLines: 1, style: const pw.TextStyle(fontSize: 9.5, color: ink)),
          ),
          pw.Expanded(child: bar(r.value / catMax, cap > 0 && r.value > cap ? red : accent, height: 7)),
          pw.SizedBox(
            width: 38,
            child: pw.Text(
              tr.exportPercent('${(r.value / sums.expense * 100).round()}'),
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8.5, color: muted),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.SizedBox(
            width: catAmountW,
            child: number(m(r.value), pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: ink)),
          ),
        ],
      ),
    );
  }

  pw.Widget goal(Goal g) {
    final saved = s.goalSaved(g);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: soft, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  g.name,
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: ink),
                ),
              ),
              pw.SizedBox(
                width: 170,
                child: number(
                  g.target > 0 ? '${m(saved)} / ${m(g.target)}' : m(saved),
                  pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: ink),
                ),
              ),
            ],
          ),
          if (g.target > 0) ...[pw.SizedBox(height: 6), bar(saved / g.target, accent)],
          if (g.deadline.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('${tr.exportColTargetDate} : ${longDate(g.deadline)}', style: const pw.TextStyle(fontSize: 8, color: muted)),
          ],
        ],
      ),
    );
  }

  pw.Widget debt(Debt d) {
    final left = s.debtLeft(d);
    final facts = [
      d.owe ? tr.exportIOwe : tr.exportOwedToMe,
      '${tr.exportColAmount} ${m(d.amount)}',
      if (d.due.isNotEmpty) '${tr.exportColDue} ${longDate(d.due)}',
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: line, width: 0.6)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  d.person,
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: ink),
                ),
                pw.Text(facts.join(' · '), style: const pw.TextStyle(fontSize: 8, color: muted)),
              ],
            ),
          ),
          pw.SizedBox(
            width: 120,
            child: number(
              left > 0 ? m(left) : tr.exportSettled,
              pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: left <= 0 ? green : (d.owe ? red : ink)),
            ),
          ),
        ],
      ),
    );
  }

  // The journal reads like the app: days, then movements, with the amount and
  // the running balance sized to the largest figures of this statement.
  final amountW = widthFor(rows.map((r) => m(r.effect, signed: true)), 9.5);
  final balanceW = widthFor(rows.map((r) => m(r.balance)), 8.5);

  pw.Widget movement(_Row r) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 4.5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: line, width: 0.5)),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(r.label, style: const pw.TextStyle(fontSize: 9.5, color: ink)),
              if (r.detail.isNotEmpty) pw.Text(r.detail, style: const pw.TextStyle(fontSize: 7.5, color: muted)),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.SizedBox(
          width: amountW,
          child: number(
            r.effect == 0 ? '-' : m(r.effect, signed: true),
            pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: r.effect < 0 ? red : (r.effect > 0 ? green : muted)),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.SizedBox(
          width: balanceW,
          child: number(m(r.balance), const pw.TextStyle(fontSize: 8.5, color: muted)),
        ),
      ],
    ),
  );

  pw.Widget dayHeader(String date) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 9, bottom: 2),
    child: pw.Text(
      dayLabel(date),
      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: accent),
    ),
  );

  final journal = <pw.Widget>[];
  for (var i = 0; i < rows.length; i++) {
    final newDay = i == 0 || rows[i].date != rows[i - 1].date;
    // A day's title never stays alone at the bottom of a page.
    journal.add(
      newDay
          ? pw.Inseparable(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [dayHeader(rows[i].date), movement(rows[i])]),
            )
          : movement(rows[i]),
    );
  }

  final moved = credit + debit;

  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 38),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.only(bottom: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: line, width: 0.6)),
              ),
              child: pw.Row(
                children: [
                  pw.Image(logo, width: 14, height: 14),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    tr.appTitle,
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: ink),
                  ),
                  pw.Spacer(),
                  pw.Text('$accTitle · ${tr.exportPeriod(longDate(o.from), longDate(o.to))}', style: const pw.TextStyle(fontSize: 8, color: muted)),
                ],
              ),
            ),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
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
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(14),
            gradient: const pw.LinearGradient(begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight, colors: [accent, accentDark]),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                children: [
                  // A white edge: the logo's tile is the same green as this card.
                  pw.Container(
                    padding: const pw.EdgeInsets.all(1.5),
                    decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Image(logo, width: 26, height: 26),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    tr.appTitle,
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Spacer(),
                  pw.Text(tr.exportIssued(longDate(todayIso())), style: const pw.TextStyle(color: heroSoft, fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          tr.exportTitle,
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(tr.exportPeriod(longDate(o.from), longDate(o.to)), style: const pw.TextStyle(color: heroSoft, fontSize: 9)),
                        pw.Text('$accTitle · ${tr.exportCurrency(s.settings.currency)}', style: const pw.TextStyle(color: heroSoft, fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(tr.exportClosing, style: const pw.TextStyle(color: heroSoft, fontSize: 8.5)),
                        pw.SizedBox(height: 2),
                        number(m(run), pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: -4),
          child: pw.Row(
            children: [
              kpi(tr.exportOpening, m(opening), ink),
              kpi(tr.exportCredits, m(credit, signed: true), green),
              kpi(tr.exportDebits, m(-debit, signed: true), red),
            ],
          ),
        ),
        if (moved > 0) ...[
          pw.SizedBox(height: 10),
          pw.ClipRRect(
            horizontalRadius: 3,
            verticalRadius: 3,
            child: pw.Row(
              children: [
                if (credit > 0)
                  pw.Expanded(
                    flex: (credit / moved * 1000).round().clamp(1, 1000),
                    child: pw.Container(height: 6, color: green),
                  ),
                if (debit > 0)
                  pw.Expanded(
                    flex: (debit / moved * 1000).round().clamp(1, 1000),
                    child: pw.Container(height: 6, color: red),
                  ),
              ],
            ),
          ),
        ],
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Text(
            tr.exportPeriodSummary(m(sums.income), m(sums.expense), tr.opsCount(rows.length)),
            style: const pw.TextStyle(fontSize: 8, color: muted),
          ),
        ),
        if (o.categories && catRows.isNotEmpty) ...[section(tr.exportByCategory, side: m(sums.expense)), ...catRows.map(category)],
        if (o.plans && o.account.isEmpty && s.goals.isNotEmpty) ...[section(tr.typeSave, side: m(s.totalSaved)), ...s.goals.map(goal)],
        if (o.plans && o.account.isEmpty && s.debts.isNotEmpty) ...[section(tr.exportDebtsLoans), ...s.debts.map(debt)],
        section(tr.exportJournal, side: tr.opsCount(rows.length)),
        if (rows.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Center(
              child: pw.Text(tr.exportEmpty, style: const pw.TextStyle(color: muted)),
            ),
          )
        else ...[
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(tr.exportColLabel, style: const pw.TextStyle(fontSize: 7.5, color: muted)),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: amountW,
                child: pw.Text(
                  tr.exportColAmount,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 7.5, color: muted),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.SizedBox(
                width: balanceW,
                child: pw.Text(
                  tr.exportColBalance,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 7.5, color: muted),
                ),
              ),
            ],
          ),
          ...journal,
        ],
      ],
    ),
  );
  return doc.save();
}

/// One line of the statement's journal.
class _Row {
  final String date, label, detail;
  final double effect, balance;
  const _Row(this.date, this.label, this.detail, this.effect, this.balance);
}

String statementFileName(AppState s, StatementOptions o) {
  var name = tr.exportFileName(o.from, o.to);
  if (o.account.isNotEmpty) {
    final a = (s.accById(o.account)?.name ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    name += '-$a';
  }
  return '$name.pdf';
}
