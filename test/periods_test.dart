import 'package:carnet237/db.dart';
import 'package:carnet237/models.dart';
import 'package:carnet237/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// AppState without a database: these tests only use the in-memory lists.
AppState _state(List<Tx> txs) {
  final s = AppState(Store());
  s.settings
    ..periodKind = 'month'
    ..periodStart = '2026-10-25'
    ..periodEnd = '2026-11-24'
    ..periodAnchor = 25;
  s.view = s.openPeriod;
  s.txs = txs;
  s.ready = true;
  return s;
}

Tx _tx(TxType type, double amount, String date, {String cat = 'alim', int dir = 1, String goal = ''}) =>
    Tx(id: newId(), type: type, amount: amount, cat: cat, account: 'cash', dir: dir, goal: goal, date: date);

void main() {
  test('periods follow the day the user chose, not the calendar', () {
    const p = Period('2026-10-25', '2026-11-24');
    expect(p.days, 31);
    expect(p.next('month', 25), const Period('2026-11-25', '2026-12-24'));
    expect(p.previous('month', 25), const Period('2026-09-25', '2026-10-24'));
    expect(Period.from('2026-11-01', '2weeks', anchor: 1), const Period('2026-11-01', '2026-11-14'));
    expect(Period.from('2026-01-01', 'quarter', anchor: 1), const Period('2026-01-01', '2026-03-31'));
    expect(Period.from('2026-01-01', 'semester', anchor: 1), const Period('2026-01-01', '2026-06-30'));
    expect(const Period('2026-03-01', '2026-03-10').next('custom', 1), const Period('2026-03-11', '2026-03-20'));
  });

  test('a start on the 31st survives short months', () {
    final feb = Period.from('2026-01-31', 'month', anchor: 31).next('month', 31);
    expect(feb, const Period('2026-02-28', '2026-03-30'));
    expect(feb.next('month', 31).start, '2026-03-31');
  });

  test('what a period leaves is what the next one starts with', () {
    final s = _state([
      _tx(TxType.income, 100000, '2026-10-01', cat: 'salaire'),
      _tx(TxType.expense, 85000, '2026-10-20'),
      _tx(TxType.expense, 2000, '2026-10-26'),
    ]);
    expect(s.carriedInto(s.view), 15000);
    expect(s.spendableAt(s.view.end), 13000);
    final next = s.nextPeriod(s.view);
    expect(s.carriedInto(next), s.spendableAt(s.view.end));
  });

  test('savings leave the money you can use without being an expense', () {
    final s = _state([_tx(TxType.income, 100000, '2026-10-26', cat: 'salaire'), _tx(TxType.save, 30000, '2026-10-27', dir: -1, goal: 'g1')]);
    s.goals = [Goal(id: 'g1', name: 'Urgence')];
    expect(s.spendable, 70000);
    expect(s.goalSaved(s.goals.first), 30000);
    expect(s.sums(s.txs).expense, 0);
    expect(s.movesIn(const Period('2026-10-27', '2026-10-27')).savings, -30000);
    s.txs = [...s.txs, _tx(TxType.save, 10000, '2026-10-28', dir: 1, goal: 'g1')];
    expect(s.spendableAt('2026-10-28'), 80000);
    expect(s.movesIn(const Period('2026-10-28', '2026-10-28')).savings, 10000);
  });

  test('the summary of a period holds its figures', () {
    final s = _state([
      _tx(TxType.income, 50000, '2026-10-01', cat: 'salaire'),
      _tx(TxType.income, 80000, '2026-11-01', cat: 'salaire'),
      _tx(TxType.expense, 20000, '2026-11-02'),
      _tx(TxType.save, 10000, '2026-11-03', dir: -1, goal: 'g'),
    ]);
    final c = s.summarize(s.openPeriod);
    expect((c.opening, c.income, c.expense, c.saved, c.closing, c.count), (50000.0, 80000.0, 20000.0, 10000.0, 100000.0, 3));
    expect(c.top, contains('20000'));
  });

  test('navigation goes through closed periods, even of another rhythm', () {
    final s = _state([]);
    s.closed = [
      ClosedPeriod(
        id: 'a',
        start: '2026-10-11',
        end: '2026-10-24',
        kind: '2weeks',
        opening: 0,
        income: 0,
        expense: 0,
        saved: 0,
        closing: 0,
        budget: 0,
        spent: 0,
        count: 0,
        top: '[]',
      ),
    ];
    final prev = s.previousPeriod(s.openPeriod);
    expect(prev, const Period('2026-10-11', '2026-10-24'));
    expect(s.nextPeriod(prev), s.openPeriod);
    expect(s.periodOf('2026-10-12'), prev);
  });

  test('a planned movement repeats on its day', () {
    final x = Scheduled(id: 's', type: TxType.expense, amount: 5000, account: 'cash', next: '2026-01-31', repeat: 'month');
    expect(x.occurrences('2026-01-01', '2026-04-30'), ['2026-01-31', '2026-02-28', '2026-03-31', '2026-04-30']);
    final once = Scheduled(id: 'o', type: TxType.expense, amount: 5000, account: 'cash', next: '2026-01-31');
    expect(once.after(once.next), isNull);
    expect(once.occurrences('2026-02-01', '2026-12-31'), isEmpty);
    final week = Scheduled(id: 'w', type: TxType.income, amount: 1, account: 'cash', next: '2026-03-01', repeat: '2weeks');
    expect(week.after('2026-03-01'), '2026-03-15');
  });
}
