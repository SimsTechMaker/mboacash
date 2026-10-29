import 'dart:convert';
import 'dart:io';

import 'package:carnet237/csv_import.dart';
import 'package:carnet237/db.dart';
import 'package:carnet237/format.dart';
import 'package:carnet237/i18n.dart';
import 'package:carnet237/models.dart';
import 'package:carnet237/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  tearDown(() => useLang('fr'));

  test('both string tables have the same keys and placeholders', () {
    Map<String, dynamic> arb(String l) => jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync());
    final fr = arb('fr')..remove('@@locale');
    final en = arb('en')..remove('@@locale');
    final keys = fr.keys.where((k) => !k.startsWith('@')).toSet();
    expect(en.keys.toSet(), keys);
    final holder = RegExp(r'\{(\w+)[,}]');
    for (final k in keys) {
      Set<String> names(String s) => holder.allMatches(s).map((m) => m[1]!).toSet();
      expect(names(en[k]), names(fr[k]), reason: k);
    }
  });

  test('built-in names follow the language, renamed ones are kept', () {
    useLang('fr');
    final s = Settings.defaults();
    s.cats.firstWhere((c) => c.id == 'resto').name = 'Maquis';
    s.relabel('en');
    expect(s.cats.firstWhere((c) => c.id == 'alim').name, 'Groceries');
    expect(s.cats.firstWhere((c) => c.id == 'resto').name, 'Maquis');
    expect(s.accounts.firstWhere((a) => a.id == 'cash').name, 'Cash');
    expect(s.labelsLang, 'en');
    s.relabel('fr');
    expect(s.cats.firstWhere((c) => c.id == 'alim').name, 'Alimentation');
  });

  test('amounts typed the English or French way', () {
    useLang('en');
    expect(parseAmount('12,500'), 12500);
    expect(parseAmount('12,500.50'), 12500.5);
    expect(Fmt('XAF').money(12500), '12,500 FCFA');
    expect(monthLabel('2026-10'), 'October 2026');
    useLang('fr');
    expect(parseAmount('12 500,50'), 12500.5);
    expect(parseAmount('12,5'), 12.5);
  });

  test('a CSV with English headers imports', () {
    useLang('en');
    final s = AppState(Store())..ready = true;
    const csv =
        'date,type,label,account,to_account,amount,currency,note,category\n'
        '2026-10-04,expense,Taxi,Cash,,-3500,XAF,,Transport\n'
        '2026-10-05,income,Salary,Bank,,250000,XAF,,Salary\n';
    final p = planImport(s, csv);
    expect(p.errors, isEmpty);
    expect(p.txs.map((t) => t.type), [TxType.expense, TxType.income]);
  });
}
