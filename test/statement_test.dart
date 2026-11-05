import 'dart:io';

import 'package:carnet237/db.dart';
import 'package:carnet237/export.dart';
import 'package:carnet237/models.dart';
import 'package:carnet237/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());

  AppState filled(double scale) {
    final s = AppState(Store());
    s.settings.cats.firstWhere((c) => c.id == 'alim').cap = 30000 * scale;
    s.txs = [
      Tx(id: 'a', type: TxType.income, amount: 350000 * scale, cat: 'salaire', account: 'bank', date: '2026-10-01', note: 'Salaire octobre'),
      for (var i = 0; i < 70; i++)
        Tx(
          id: 'e$i',
          type: TxType.expense,
          amount: (1500 + i * 730) * scale,
          cat: ['alim', 'transport', 'factures', 'loisirs', 'sante'][i % 5],
          account: i.isEven ? 'cash' : 'momo',
          date: '2026-10-${(i % 28 + 1).toString().padLeft(2, '0')}',
          note: i % 3 == 0 ? 'Une note assez longue pour voir comment le libellé passe à la ligne dans le relevé' : '',
        ),
      Tx(id: 't', type: TxType.transfer, amount: 20000 * scale, cat: 'transfer', account: 'bank', to: 'cash', date: '2026-10-05'),
      Tx(id: 's', type: TxType.save, amount: 40000 * scale, cat: 'save', account: 'bank', dir: -1, goal: 'g', date: '2026-10-06'),
    ];
    s.goals = [Goal(id: 'g', name: "Fonds d'urgence", target: 600000 * scale, deadline: '2027-06-01'), Goal(id: 'h', name: 'Voyage')];
    s.debts = [Debt(id: 'd', owe: false, person: 'Moussa', amount: 50000 * scale, date: '2026-09-01', due: '2026-12-01')];
    s.ready = true;
    return s;
  }

  // STATEMENT_OUT=<folder> keeps the files, to look at them.
  Future<void> build(AppState s, String name) async {
    final bytes = await buildStatement(s, const StatementOptions(from: '2026-10-01', to: '2026-10-31'));
    expect(bytes.length, greaterThan(1000));
    final out = Platform.environment['STATEMENT_OUT'];
    if (out != null) File('$out/$name.pdf').writeAsBytesSync(bytes);
  }

  test('the statement builds with ordinary amounts', () => build(filled(1), 'normal'));
  test('the statement builds with very large amounts', () => build(filled(25000), 'large'));
  test('the statement builds with no movement', () => build(AppState(Store())..ready = true, 'empty'));
}
