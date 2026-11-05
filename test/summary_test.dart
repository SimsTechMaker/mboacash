import 'package:carnet237/db.dart';
import 'package:carnet237/models.dart';
import 'package:carnet237/state.dart';
import 'package:carnet237/summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// AppState without a database: these tests only use the in-memory lists.
AppState _state(List<Tx> txs, {List<Goal> goals = const []}) {
  final s = AppState(Store());
  s.txs = txs;
  s.goals = [...goals];
  s.ready = true;
  return s;
}

Tx _tx(TxType type, double amount, String date, {String cat = '', int dir = 1, String account = 'cash', String note = '', String goal = '', int? created}) =>
    Tx(
      id: newId(),
      type: type,
      amount: amount,
      cat: cat.isEmpty ? typeCode(type) : cat,
      account: account,
      dir: dir,
      goal: goal,
      date: date,
      note: note,
      created: created ?? 0,
    );

Tx _out(double amount, String date, {String cat = 'alim', String account = 'cash', String note = '', int? created}) =>
    _tx(TxType.expense, amount, date, cat: cat, account: account, note: note, created: created);

int _at(String date, int hour) {
  final d = parseIso(date);
  return DateTime(d.year, d.month, d.day, hour).millisecondsSinceEpoch;
}

String _money(double v) => '${v.round()}';

const _october = Period('2026-10-01', '2026-10-31'); // 1 October 2026 is a Thursday
const _september = Period('2026-09-01', '2026-09-30');
const _after = '2026-11-05'; // October is over

SmartSummary _sum(AppState s, {Period range = _october, Period? previous, String today = _after}) => SmartSummary(s, range, previous: previous, today: today);

void main() {
  setUpAll(() => initializeDateFormatting());

  test('savings, transfers and adjustments are not spending', () {
    final s = _state([
      _out(10000, '2026-10-05'),
      _tx(TxType.save, 50000, '2026-10-06', dir: -1, note: 'tontine'),
      _tx(TxType.save, 50000, '2026-10-07', dir: -1, note: 'tontine'),
      _tx(TxType.save, 50000, '2026-10-08', dir: -1, note: 'tontine'),
      _tx(TxType.transfer, 70000, '2026-10-09'),
      _tx(TxType.adjust, 3000, '2026-10-10', dir: -1),
      _tx(TxType.debt, 4000, '2026-10-11', dir: -1),
    ]);
    final x = _sum(s);
    expect(x.spent, 14000);
    expect(x.categories.map((c) => c.key), ['alim', 'debt']);
    expect(x.byWeekday.reduce((a, b) => a + b), 14000);
    expect(x.biggest.map((t) => t.amount), [10000, 4000]);
    expect(x.habits, isEmpty);
  });

  test('no data in the range', () {
    final x = _sum(_state([_out(1000, '2026-09-05')]));
    expect(x.hasData, isFalse);
    expect(x.highlights(_money), isEmpty);
    expect(_sum(_state([])).elapsedDays, 0);
  });

  test('spending by weekday and part of the month', () {
    final x = _sum(
      _state([
        _out(1000, '2026-10-05'), // Monday
        _out(2000, '2026-10-10'), // Saturday, last day of the start
        _out(4000, '2026-10-11'), // Sunday, first day of the middle
        _out(8000, '2026-10-20'), // Tuesday, last day of the middle
        _out(16000, '2026-10-21'), // Wednesday, first day of the end
        _out(32000, '2026-10-31'), // Saturday
      ]),
    );
    expect(x.byWeekday, [1000, 8000, 16000, 0, 0, 34000, 4000]);
    expect(x.byMonthPart, [3000, 12000, 48000]);
  });

  test('the time of day only uses expenses entered on their own date', () {
    final x = _sum(
      _state([
        _out(1000, '2026-10-05', created: _at('2026-10-05', 9)),
        _out(2000, '2026-10-05', created: _at('2026-10-05', 12)),
        _out(4000, '2026-10-05', created: _at('2026-10-05', 19)),
        _out(8000, '2026-10-05', created: _at('2026-10-05', 23)),
        _out(16000, '2026-10-06', created: _at('2026-10-06', 4)),
        _out(32000, '2026-10-05', created: _at('2026-10-07', 9)), // entered two days later
        _out(64000, '2026-10-05', created: 0), // imported: no time at all
      ]),
    );
    expect(x.timedCount, 5);
    expect(x.byTimeOfDay, [1000, 2000, 4000, 24000]);
    expect(x.timeOfDayInsight, isNull); // only five: too few to conclude
  });

  test('a peak needs enough expenses on enough dates', () {
    final saturdays = ['2026-10-03', '2026-10-10', '2026-10-17', '2026-10-24', '2026-10-31'];
    final x = _sum(_state([for (final d in saturdays) _out(9000, d), _out(1000, '2026-10-05'), _out(1000, '2026-10-06'), _out(1000, '2026-10-07')]));
    expect(x.peakWeekday, 5);
    expect(x.weekdayInsight, contains('samedi'));

    final few = _sum(_state([for (final d in saturdays) _out(9000, d)]));
    expect(few.peakWeekday, isNull);
    expect(few.weekdayInsight, isNull);

    // One big purchase is not a habit of that day.
    final once = _sum(
      _state([
        _out(500000, '2026-10-03'),
        for (final d in [5, 6, 7, 8, 9, 11, 12, 13]) _out(1000, '2026-10-${'$d'.padLeft(2, '0')}'),
      ]),
    );
    expect(once.peakWeekday, isNull);
  });

  test('a running range has no month pattern yet', () {
    final x = _sum(_state([for (var d = 1; d < 10; d++) _out(1000, '2026-10-0$d')]), today: '2026-10-09');
    expect(x.peakMonthPart, isNull);
    expect(x.monthPartInsight, isNull);
  });

  test('categories compare with the previous range', () {
    final s = _state([
      _out(10000, '2026-09-01', cat: 'alim'),
      _out(5000, '2026-09-02', cat: 'loisirs'),
      _out(15000, '2026-10-02', cat: 'alim'),
      _out(3000, '2026-10-03', cat: 'transport'),
    ]);
    final by = {for (final c in _sum(s, previous: _september).categories) c.key: c};
    expect(by['alim']!.change, 0.5);
    expect(by['transport']!.change, isNull);
    expect(by['transport']!.isNew, isTrue);
    expect((by['loisirs']!.total, by['loisirs']!.change), (0, -1));
    expect(_sum(s, previous: _september).categories.last.key, 'loisirs');
    expect(_sum(s).categories.first.before, isNull);
  });

  test('a running range is compared with the same number of days', () {
    final s = _state([_out(5000, '2026-09-01'), _out(50000, '2026-09-25'), _out(10000, '2026-10-04')]);
    final x = _sum(s, previous: _september, today: '2026-10-10');
    expect(x.comparedSoFar, isTrue);
    expect(x.spentBefore, 5000);
    expect(x.spentChange, 1);
    expect(_sum(s, previous: _september).comparedSoFar, isFalse);
    expect(_sum(s, previous: _september).spentBefore, 55000);
  });

  test('no comparison with a range the history does not cover', () {
    final s = _state([_out(5000, '2026-09-20'), _out(10000, '2026-10-04')]);
    final x = _sum(s, previous: _september);
    expect(x.baseline, isNull);
    expect(x.spentChange, isNull);
  });

  test('the five biggest expenses', () {
    final x = _sum(
      _state([
        for (final a in [3.0, 9.0, 1.0, 7.0, 5.0, 2.0, 8.0]) _out(a, '2026-10-05'),
      ]),
    );
    expect(x.biggest.map((t) => t.amount), [9, 8, 7, 5, 3]);
    expect(x.biggestInsight, isNotNull);
  });

  test('small expenses are under a quarter of the upper quartile', () {
    final x = _sum(
      _state([
        for (final a in [200.0, 300.0, 400.0, 1000.0, 2000.0, 4000.0, 8000.0, 150000.0]) _out(a, '2026-10-05'),
      ]),
    );
    expect(x.smallThreshold, 1000);
    expect(x.smallCount, 3);
    expect(x.smallTotal, 900);
    expect(x.smallInsight(_money), contains('900'));

    final alike = _sum(_state([for (var i = 0; i < 6; i++) _out(1000, '2026-10-05')]));
    expect(alike.smallCount, 0);
    expect(alike.smallInsight(_money), isNull);

    expect(_sum(_state([_out(100, '2026-10-05'), _out(9000, '2026-10-05')])).smallThreshold, 0);
  });

  test('habits are notes repeated three times, whatever their case', () {
    final x = _sum(
      _state([
        _out(500, '2026-10-05', note: ' Taxi '),
        _out(700, '2026-10-06', note: 'taxi'),
        _out(600, '2026-10-07', note: 'TAXI'),
        _out(300, '2026-10-05', note: 'pain'),
        _out(300, '2026-10-06', note: 'pain'),
        _out(900, '2026-10-05'),
        _out(900, '2026-10-06'),
        _out(900, '2026-10-07'),
      ]),
    );
    final h = x.habits.single;
    expect((h.note, h.count, h.total, h.average), ('Taxi', 3, 1800, 600));
  });

  test('days without spending stop today and start with the history', () {
    final s = _state([
      _out(1000, '2026-10-02'),
      _out(1000, '2026-10-03'),
      _tx(TxType.save, 9000, '2026-10-05', dir: -1), // no consumption: still a day without spending
      _out(1000, '2026-10-06'),
      _out(1000, '2026-10-20'), // in the future
    ]);
    final x = _sum(s, today: '2026-10-11');
    expect(x.elapsedDays, 10); // 1 October is before the first movement
    expect(x.noSpendDays, 7); // 4, 5, 7, 8, 9, 10, 11
    expect(x.longestStreak, 5);
    expect(_sum(s, range: const Period('2026-12-01', '2026-12-31'), today: '2026-11-05').elapsedDays, 0);
  });

  test('accounts are ranked by what they spend', () {
    final x = _sum(_state([_out(1000, '2026-10-05'), _out(1000, '2026-10-06'), _out(5000, '2026-10-07', account: 'momo')]));
    expect(x.accounts.map((a) => (a.id, a.total, a.count)), [('momo', 5000, 1), ('cash', 2000, 2)]);
    expect(x.accountInsight, contains('71'));
  });

  test('net saved and savings rate', () {
    final x = _sum(
      _state([
        _tx(TxType.income, 100000, '2026-10-01', cat: 'salaire'),
        _out(20000, '2026-10-02'),
        _tx(TxType.save, 40000, '2026-10-03', dir: -1),
        _tx(TxType.save, 10000, '2026-10-04', dir: 1),
      ]),
    );
    expect(x.netSaved, 30000);
    expect(x.savingsRate, closeTo(80000 / 110000, 1e-9));
    expect(_sum(_state([_out(1000, '2026-10-02')])).savingsRate, isNull);
  });

  test('goals: estimated date at the pace of the range', () {
    final car = Goal(id: 'car', name: 'Voiture', target: 100000);
    final trip = Goal(id: 'trip', name: 'Voyage', target: 100000, deadline: '2026-12-01');
    final idle = Goal(id: 'idle', name: 'Sans rythme', target: 100000);
    final waiting = Goal(id: 'waiting', name: 'En attente', target: 100000, deadline: '2026-12-01');
    final done = Goal(id: 'done', name: 'Atteint', target: 1000, initial: 2000);
    final open = Goal(id: 'open', name: 'Sans montant');
    final s = _state(
      [
        _tx(TxType.income, 1000, '2026-10-01', cat: 'salaire'),
        _tx(TxType.save, 31000, '2026-10-05', dir: -1, goal: 'car'),
        _tx(TxType.save, 93000, '2026-10-05', dir: -1, goal: 'trip'),
      ],
      goals: [car, trip, idle, waiting, done, open],
    );
    final x = _sum(s);
    expect(x.goals.map((g) => g.goal.id), ['car', 'trip', 'waiting']);
    expect(x.goals[0].eta, shiftDays(_after, 69)); // 69 000 left at 1 000 a day
    expect(x.goals[0].perMonth, 30000);
    expect(x.goals[0].behind, isFalse);
    expect(x.goals[1].eta, shiftDays(_after, 3));
    expect(x.goals[1].behind, isFalse);
    expect((x.goals[2].eta, x.goals[2].behind), (null, false));

    final slow = _state(
      [_tx(TxType.income, 1000, '2026-10-01', cat: 'salaire'), _tx(TxType.save, 3100, '2026-10-05', dir: -1, goal: 'trip')],
      goals: [Goal(id: 'trip', name: 'Voyage', target: 100000, deadline: '2026-12-01')],
    );
    expect(_sum(slow).goals.single.behind, isTrue);
    expect(_sum(slow).highlights(_money).single, contains('Voyage'));

    // A few days are too short to tell a pace.
    expect(_sum(s, today: '2026-10-08').goals.map((g) => (g.goal.id, g.eta)), [('trip', null), ('waiting', null)]);
  });

  test('highlights: most useful first, five at most', () {
    final s = _state([
      _tx(TxType.income, 100000, '2026-09-01', cat: 'salaire'),
      _out(20000, '2026-09-10', cat: 'transport'),
      _tx(TxType.income, 100000, '2026-10-01', cat: 'salaire'),
      _out(150000, '2026-10-02', cat: 'logement'),
      for (final d in ['2026-10-03', '2026-10-10', '2026-10-17', '2026-10-24', '2026-10-31']) _out(300, d, cat: 'transport', note: 'taxi'),
      for (final d in ['2026-10-04', '2026-10-11']) _out(20000, d, cat: 'alim'),
    ]);
    final list = _sum(s, previous: _september).highlights(_money);
    expect(list.length, 5);
    expect(list.first, contains('91500')); // spent more than earned
    expect(list[1], contains('%'));
    expect(list.toSet().length, 5);
  });

  test('highlights stay silent without enough data', () {
    final x = _sum(_state([_out(1000, '2026-10-05'), _out(2000, '2026-10-06')]));
    expect(x.highlights(_money), isEmpty);
  });

  test('ranges built from dates', () {
    expect(lastMonthsRange(3, today: '2026-11-05'), const Period('2026-08-06', '2026-11-05'));
    expect(lastMonthsRange(12, today: '2026-11-05'), const Period('2025-11-06', '2026-11-05'));
    expect(rangeBefore(const Period('2026-10-11', '2026-10-20')), const Period('2026-10-01', '2026-10-10'));
    final s = _state([_out(1000, '2026-10-05'), _out(1000, '2026-03-05')]);
    expect(allTimeRange(s, today: '2026-11-05'), const Period('2026-03-05', '2026-11-05'));
    expect(allTimeRange(_state([]), today: '2026-11-05'), const Period('2026-11-05', '2026-11-05'));
  });

  test('weekday names start on Monday', () {
    expect(weekdayName(0), 'lundi');
    expect(weekdayName(6), 'dimanche');
  });
}
