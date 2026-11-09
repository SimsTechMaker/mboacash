import 'package:carnet237/db.dart';
import 'package:carnet237/export.dart';
import 'package:carnet237/models.dart';
import 'package:carnet237/state.dart';
import 'package:flutter_test/flutter_test.dart';

// The checks an accountant would make: every franc that moves is accounted
// for, and every total agrees with the others however it is computed.

const p = Period('2026-11-01', '2026-11-30');

AppState _state(List<Tx> txs) {
  final s = AppState(Store());
  s.settings
    ..periodStart = p.start
    ..periodEnd = p.end;
  s.view = p;
  s.txs = txs;
  s.ready = true;
  return s;
}

var _n = 0;
Tx _tx(
  TxType type,
  double amount,
  String date, {
  String account = 'cash',
  String to = '',
  int dir = 1,
  String goal = '',
  String debt = '',
  bool init = false,
}) => Tx(
  id: 'x${_n++}',
  type: type,
  amount: amount,
  cat: switch (type) {
    TxType.income => 'salaire',
    TxType.expense => 'alim',
    _ => typeCode(type),
  },
  account: account,
  to: to,
  dir: dir,
  goal: goal,
  debt: debt,
  init: init,
  date: date,
);

/// Carried over + income − expenses + adjustments = available at the end.
void reconciles(AppState s, Period q) {
  final sum = s.sums(s.periodTxs(q));
  expect(
    s.carriedInto(q) + sum.income - sum.expense + s.otherMoves(q),
    closeTo(s.spendableAt(q.end), 0.001),
    reason: 'report + entrées − sorties + ajustements ≠ disponible',
  );
  final c = s.summarize(q);
  expect(c.closing - c.opening - c.income + c.expense, closeTo(s.otherMoves(q), 0.001), reason: 'the stored summary leaves something out');
}

void main() {
  test('every kind of movement reconciles over a period', () {
    final s = _state([
      _tx(TxType.income, 300000, '2026-10-25', account: 'bank'),
      _tx(TxType.income, 350000, '2026-11-02', account: 'bank'),
      _tx(TxType.expense, 42000, '2026-11-03'),
      _tx(TxType.transfer, 100000, '2026-11-03', account: 'bank', to: 'cash'),
      _tx(TxType.save, 50000, '2026-11-04', account: 'bank', dir: -1, goal: 'g'),
      _tx(TxType.save, 10000, '2026-11-20', account: 'cash', dir: 1, goal: 'g'),
      _tx(TxType.debt, 30000, '2026-11-05', dir: -1, debt: 'd', init: true), // lent from cash
      _tx(TxType.debt, 10000, '2026-11-15', dir: 1, debt: 'd'), // partly repaid
      _tx(TxType.debt, 80000, '2026-11-06', account: '', dir: 1, debt: 'e', init: true), // outside my accounts
    ]);
    s.goals = [Goal(id: 'g', name: 'Urgence')];
    s.debts = [
      Debt(id: 'd', owe: false, person: 'Awa', amount: 30000, date: '2026-11-05'),
      Debt(id: 'e', owe: true, person: 'Banque', amount: 80000, date: '2026-11-06'),
    ];
    reconciles(s, p);
    // Net worth: accounts + savings + owed to me − I owe.
    expect(s.spendable + s.totalSaved + s.totalLent - s.totalOwed, 300000 + 350000 - 42000 - 80000);
  });

  test('an adjustment has its own line, so the period still reconciles', () {
    final s = _state([
      _tx(TxType.income, 100000, '2026-11-02'),
      _tx(TxType.adjust, 7500, '2026-11-10', dir: -1), // cash counted short
    ]);
    expect(s.otherMoves(p), -7500);
    reconciles(s, p);
  });

  test('money on an archived account stays in the totals', () {
    final s = _state([_tx(TxType.income, 50000, '2026-11-02', account: 'momo')]);
    s.settings.accounts.firstWhere((a) => a.id == 'momo').archived = true;
    expect(s.spendable, 50000);
    expect(s.spendableAt(p.end), 50000);
    reconciles(s, p);
  });

  test('the PDF statement and the app agree', () {
    final s = _state([
      _tx(TxType.income, 120000, '2026-10-20', account: 'bank'),
      _tx(TxType.income, 30000, '2026-11-02', account: 'momo'),
      _tx(TxType.save, 20000, '2026-11-03', account: 'bank', dir: -1, goal: 'g'),
      _tx(TxType.expense, 5000, '2026-11-04'),
      _tx(TxType.adjust, 1000, '2026-11-05', dir: 1),
    ]);
    s.goals = [Goal(id: 'g', name: 'Urgence')];
    s.settings.accounts.firstWhere((a) => a.id == 'momo').archived = true;
    final b = statementBalances(s, StatementOptions(from: p.start, to: p.end));
    expect(b.opening, s.carriedInto(p));
    expect(b.closing, s.spendableAt(p.end));
  });

  test('a debt follows its loan and cannot drop below what was repaid', () {
    final s = _state([_tx(TxType.debt, 30000, '2026-11-05', dir: -1, debt: 'd', init: true), _tx(TxType.debt, 20000, '2026-11-08', dir: 1, debt: 'd')]);
    final d = Debt(id: 'd', owe: false, person: 'Awa', amount: 30000, date: '2026-11-05');
    s.debts = [d];
    expect(s.loanFor(d)!.amount, 30000);
    expect(s.minDebtAmount(d), 20000);
    // The edit sheet moves the loan with the debt: what left the account and
    // what is owed stay equal, so net worth does not change.
    expect(s.spendable + s.totalLent, 0);
    final edited = _state([_tx(TxType.debt, 45000, '2026-11-05', dir: -1, debt: 'd', init: true), _tx(TxType.debt, 20000, '2026-11-08', dir: 1, debt: 'd')]);
    edited.debts = [Debt(id: 'd', owe: false, person: 'Awa', amount: 45000, date: '2026-11-05')];
    expect(edited.spendable + edited.totalLent, 0);
  });

  test('deleting is only allowed when nothing is left in it', () {
    final s = _state([
      _tx(TxType.debt, 30000, '2026-11-05', dir: -1, debt: 'd', init: true),
      _tx(TxType.debt, 80000, '2026-11-06', account: '', dir: 1, debt: 'e', init: true),
    ]);
    final lent = Debt(id: 'd', owe: false, person: 'Awa', amount: 30000, date: '2026-11-05');
    final outside = Debt(id: 'e', owe: true, person: 'Banque', amount: 80000, date: '2026-11-06');
    s.debts = [lent, outside];
    expect(s.canDeleteDebt(lent), isFalse); // 30 000 still owed, money moved
    expect(s.canDeleteDebt(outside), isTrue); // never touched the accounts
    s.txs = [...s.txs, _tx(TxType.debt, 30000, '2026-11-09', dir: 1, debt: 'd')];
    expect(s.canDeleteDebt(lent), isTrue);
  });

  test('an overdraft is seen before it happens', () {
    final s = _state([_tx(TxType.income, 5000, '2026-11-02')]);
    expect(s.balanceWith('cash', -20000), -15000);
    final t = s.txs.first;
    expect(s.balanceWith('cash', 3000, replacing: t), 3000); // editing the income down
  });

  test('closing looks for what an accountant would check', () {
    final s = _state([_tx(TxType.expense, 8000, '2026-11-03')]);
    expect(s.negativeAccounts.map((a) => a.id), ['cash']);
    s.closed = [s.summarize(const Period('2026-10-01', '2026-10-31'))];
    expect(s.isClosedDate('2026-10-15'), isTrue);
    expect(s.isClosedDate('2026-11-03'), isFalse);
  });
}
