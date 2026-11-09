import 'package:carnet237/db.dart';
import 'package:carnet237/models.dart';
import 'package:carnet237/quick_entry.dart';
import 'package:carnet237/state.dart';
import 'package:flutter_test/flutter_test.dart';

var _n = 0;
Tx _tx(TxType type, double amount, String date, String cat, String account, String note) =>
    Tx(id: 'q${_n++}', type: type, amount: amount, cat: cat, account: account, date: date, note: note);

AppState _state(List<Tx> txs) {
  final s = AppState(Store());
  s.txs = txs;
  s.ready = true;
  return s;
}

void main() {
  test('a phrase gives amount, account and note', () {
    final s = _state([]);
    final g = parseQuick(s, 'taxi 1500 momo');
    expect((g.type, g.amount, g.note, g.account, g.cat), (TxType.expense, 1500.0, 'Taxi', 'momo', 'transport'));
    expect(parseQuick(s, 'marché 2k').amount, 2000);
    expect(parseQuick(s, 'loyer 75 000 banque').amount, 75000);
    expect(parseQuick(s, 'loyer 75 000 banque').account, 'bank');
    expect(parseQuick(s, 'pain 1,5k cash').amount, 1500);
    expect(parseQuick(s, 'riz 25mille').amount, 25000);
    expect(parseQuick(s, 'eau 3000f').amount, 3000);
    expect(parseQuick(s, 'pharmacie').ready, isFalse);
  });

  test('income from a plus sign or an income word', () {
    final s = _state([]);
    expect(parseQuick(s, '+ 350k banque').type, TxType.income);
    final g = parseQuick(s, 'salaire 350000 banque');
    expect((g.type, g.cat, g.account), (TxType.income, 'salaire', 'bank'));
  });

  test('habits fill what the phrase leaves out', () {
    final s = _state([
      _tx(TxType.expense, 14000, '2026-10-02', 'alim', 'cash', 'Marché Mokolo'),
      _tx(TxType.expense, 14500, '2026-10-09', 'alim', 'cash', 'Marché Mokolo'),
      _tx(TxType.expense, 20000, '2026-10-10', 'telephone', 'momo', 'Internet'),
    ]);
    final g = parseQuick(s, 'marché mokolo');
    expect((g.amount, g.cat, g.account, g.note), (14500.0, 'alim', 'cash', 'Marché Mokolo'));
    expect(parseQuick(s, 'marché mokolo 12000 banque').amount, 12000); // what is typed wins
    expect(parseQuick(s, 'marché mokolo 12000 banque').account, 'bank');
    final h = noteHabits(s, 'mar');
    expect(h.single.note, 'Marché Mokolo');
    expect(h.single.count, 2);
    expect(noteHabits(s, '').first.note, 'Marché Mokolo'); // most frequent first
  });

  test('the same movement twice is noticed', () {
    final s = _state([_tx(TxType.expense, 1500, '2026-11-09', 'transport', 'cash', 'Taxi')]);
    expect(similarTx(s, _tx(TxType.expense, 1500, '2026-11-09', 'transport', 'cash', 'Moto')), isNotNull);
    expect(similarTx(s, _tx(TxType.expense, 1500, '2026-11-12', 'transport', 'cash', 'Taxi')), isNull);
    expect(similarTx(s, _tx(TxType.expense, 2000, '2026-11-09', 'transport', 'cash', 'Taxi')), isNull);
  });
}
