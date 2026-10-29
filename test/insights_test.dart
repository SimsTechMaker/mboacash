import 'package:carnet237/csv_import.dart';
import 'package:carnet237/db.dart';
import 'package:carnet237/models.dart';
import 'package:carnet237/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// AppState without a database: these tests only use the in-memory lists.
AppState _state(List<Tx> txs) {
  final s = AppState(Store());
  s.txs = txs;
  s.ready = true;
  return s;
}

Tx _tx(TxType type, double amount, String date, {String cat = '', int dir = 1, String account = 'cash', String note = ''}) =>
    Tx(id: newId(), type: type, amount: amount, cat: cat.isEmpty ? typeCode(type) : cat, account: account, dir: dir, date: date, note: note);

void main() {
  test('savings and debts count as income or expense, outside the budget', () {
    final s = _state([
      _tx(TxType.income, 100000, '2026-10-01', cat: 'salaire'),
      _tx(TxType.expense, 20000, '2026-10-02', cat: 'alim'),
      _tx(TxType.save, 30000, '2026-10-03', dir: -1), // put aside
      _tx(TxType.save, 5000, '2026-10-04', dir: 1), // taken back
      _tx(TxType.debt, 10000, '2026-10-05', dir: -1), // repaid by me
      _tx(TxType.debt, 7000, '2026-10-06', dir: 1, account: ''), // outside my accounts: ignored
      _tx(TxType.transfer, 50000, '2026-10-07'),
    ]);
    final sum = s.sums(s.txs);
    expect(sum.income, 105000);
    expect(sum.expense, 60000);
    expect(s.budgetSpent(s.txs), 20000);
  });

  test('CSV round trip: parse quotes and both separators', () {
    expect(parseCsv('a;"b;c";"d ""e"""\n1;2;3'), [
      ['a', 'b;c', 'd "e"'],
      ['1', '2', '3'],
    ]);
    expect(parseCsv('﻿x,y\r\n1,2\r\n'), [
      ['x', 'y'],
      ['1', '2'],
    ]);
  });

  test('import creates missing items and skips duplicates', () {
    final s = _state([_tx(TxType.expense, 3500, '2026-10-04', cat: 'transport', note: 'Moto-taxi')]);
    const csv =
        'date;type;libelle;compte;vers_compte;montant;devise;note\n'
        '2026-10-04;depense;Transport;Espèces;;-3500;XAF;Moto-taxi\n' // already there
        '05/10/2026;depense;Coiffure;Espèces;;-2500;XAF;Salon\n' // new category
        '2026-10-06;dette;Prêt à Awa;Mobile Money;;-15000;XAF;\n'
        '2026-10-08;dette;Remboursement de Awa;Mobile Money;;15000;XAF;\n'
        '2026-10-09;epargne;Épargne : Voyage;Banque;;-20000;XAF;\n'
        'pas une date;depense;X;;;-1;XAF;\n';
    final p = planImport(s, csv);
    expect(p.duplicates, 1);
    expect(p.errors.length, 1);
    expect(p.txs.length, 4);
    expect(p.newCats.map((c) => c.name), ['Coiffure']);
    expect(p.newGoals.single.name, 'Voyage');
    final d = p.newDebts.single;
    expect((d.person, d.owe, d.amount), ('Awa', false, 15000));
    final loan = p.txs.firstWhere((t) => t.type == TxType.debt && t.init);
    expect(loan.dir, -1);
  });
}
