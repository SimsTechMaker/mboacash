import 'package:intl/intl.dart';

import 'format.dart';
import 'i18n.dart';
import 'models.dart';
import 'state.dart';

/// The "Résumé intelligent": plain arithmetic over the movements of a range,
/// on the phone. Sentences are only offered when enough data backs them.

const _minPattern = 8; // expenses needed before a spending pattern means anything
const _minPeakShare = 1.3; // a "peak" is at least 1.3 times an even share
const _minWeekDays = 14; // two of each weekday
const _minMonthDays = 28; // long enough to hold a start, a middle and an end of month
const _minSmallSample = 5; // expenses needed to work out what "small" means
const _minSmallCount = 3;
const _minHabit = 3;
const _minPaceDays = 14; // one deposit in a few days says nothing about a pace
const _maxWaitDays = 36500; // beyond a century, no date is worth showing
const _topCount = 5;
const _highlights = 5;

String _pct(double ratio) => '${(ratio * 100).round().abs()}';

/// Name of a weekday in the app's language, Monday being 0.
String weekdayName(int i) => DateFormat('EEEE', intlLocale).format(DateTime(2024, 1, 1 + i)); // 1 January 2024 was a Monday

/// The earliest movement ever recorded: the day the user's history begins.
String? firstTxDate(AppState s) {
  String? first;
  for (final t in s.txs) {
    if (first == null || t.date.compareTo(first) < 0) first = t.date;
  }
  return first;
}

/// From the first movement to today.
Period allTimeRange(AppState s, {String? today}) {
  final end = today ?? todayIso();
  final first = firstTxDate(s);
  return Period(first == null || first.compareTo(end) > 0 ? end : first, end);
}

/// The last [months] months, ending today.
Period lastMonthsRange(int months, {String? today}) {
  final end = today ?? todayIso();
  final d = parseIso(end);
  return Period(shiftDays(isoDate(addMonths(d, -months, d.day)), 1), end);
}

/// The range of the same length just before [p].
Period rangeBefore(Period p) => Period(shiftDays(p.start, -p.days), shiftDays(p.start, -1));

class SumCategory {
  final String key, name, icon, color;
  final double total;

  /// Total of the range compared with, or null when there is nothing to compare.
  final double? before;
  const SumCategory({required this.key, required this.name, required this.icon, required this.color, required this.total, this.before});

  /// Change as a ratio (0.25 is +25 %); null without a base to measure from.
  double? get change => before == null || before! <= 0 ? null : (total - before!) / before!;

  /// Nothing was spent here in the range compared with.
  bool get isNew => before == 0 && total > 0;
}

class SumHabit {
  final String note;
  final int count;
  final double total;
  const SumHabit(this.note, this.count, this.total);
  double get average => total / count;
}

class SumAccount {
  final String id, name, icon;
  final int count;
  final double total;
  const SumAccount({required this.id, required this.name, required this.icon, required this.count, required this.total});
}

class SumGoal {
  final Goal goal;
  final double saved;

  /// What the range put aside for this goal, per month; null without a pace.
  final double? perMonth;

  /// When the target is reached at that pace, or null if it never is.
  final String? eta;
  const SumGoal({required this.goal, required this.saved, this.perMonth, this.eta});

  /// At this pace, the deadline will be missed.
  bool get behind => goal.deadline.isNotEmpty && eta != null && eta!.compareTo(goal.deadline) > 0;
}

/// What stands out in [range], compared with [previous] when given. [today]
/// can be set for tests.
class SmartSummary {
  final AppState s;
  final Period range;
  final Period? previous;
  final String today;
  SmartSummary(this.s, this.range, {this.previous, String? today}) : today = today ?? todayIso();

  late final List<Tx> txs = s.periodTxs(range);

  /// Anything that moved money in or out, savings included.
  bool get hasData => txs.any((t) => s.flow(t) != 0);

  // Moving money to savings is not consumption: it stays out of every
  // analysis of spending. Debts still count, as in [AppState.summarize].
  bool _spends(Tx t) => s.flow(t) < 0 && t.type != TxType.save;

  late final List<Tx> spending = txs.where(_spends).toList();
  late final double spent = spending.fold(0.0, (a, t) => a + t.amount);

  /// The part of the range that can be judged: nothing in the future, nothing
  /// before the first movement ever recorded (the user was not counting yet,
  /// so those days say nothing). Null if no such day exists.
  late final Period? elapsed = () {
    final first = firstTxDate(s);
    if (first == null) return null;
    final from = range.start.compareTo(first) > 0 ? range.start : first;
    final to = range.end.compareTo(today) < 0 ? range.end : today;
    return from.compareTo(to) <= 0 ? Period(from, to) : null;
  }();

  int get elapsedDays => elapsed?.days ?? 0;

  // ---------- comparison ----------

  /// The range is still running, so it is compared with the same number of
  /// days of [previous]: ten days against a whole month would always "drop".
  bool get _running => range.contains(today) && today != range.end;

  /// What [range] is measured against. None if [previous] starts before the
  /// history does: it would look cheaper than it really was.
  late final Period? baseline = () {
    final p = previous, first = firstTxDate(s);
    if (p == null || first == null || first.compareTo(p.start) > 0 || today.compareTo(range.start) < 0) return null;
    if (!_running) return p;
    final cut = shiftDays(p.start, Period(range.start, today).days - 1);
    return cut.compareTo(p.end) < 0 ? Period(p.start, cut) : p;
  }();

  /// The comparison only covers the start of the previous range.
  bool get comparedSoFar => baseline != null && baseline != previous;

  late final List<Tx> _spendingBefore = baseline == null ? const [] : s.periodTxs(baseline!).where(_spends).toList();

  /// Spending of the range compared with, or null without one.
  double? get spentBefore => baseline == null ? null : _spendingBefore.fold<double>(0, (a, t) => a + t.amount);

  double? get spentChange {
    final b = spentBefore;
    return b == null || b <= 0 ? null : (spent - b) / b;
  }

  // ---------- moments ----------

  List<double> _buckets(int n, Iterable<Tx> list, int Function(Tx) index) {
    final out = List.filled(n, 0.0);
    for (final t in list) {
      out[index(t)] += t.amount;
    }
    return out;
  }

  /// Monday first.
  late final List<double> byWeekday = _buckets(7, spending, (t) => parseIso(t.date).weekday - 1);

  /// Days 1-10, 11-20, then 21 to the end of the month.
  late final List<double> byMonthPart = _buckets(3, spending, (t) => (parseIso(t.date).day - 1).clamp(0, 20) ~/ 10);

  /// Expenses whose hour can be trusted: only one entered on its own date was
  /// created at the time it happened.
  late final List<Tx> _timed = spending.where((t) => isoDate(DateTime.fromMillisecondsSinceEpoch(t.created)) == t.date).toList();

  /// Size of the sample behind [byTimeOfDay].
  int get timedCount => _timed.length;

  /// Morning (5-12h), afternoon (12-18h), evening (18-22h), night (22-5h).
  late final List<double> byTimeOfDay = _buckets(4, _timed, (t) {
    final h = DateTime.fromMillisecondsSinceEpoch(t.created).hour;
    return h < 5 || h >= 22
        ? 3
        : h < 12
        ? 0
        : h < 18
        ? 1
        : 2;
  });

  /// The index that clearly leads [v], if any.
  int? _peak(List<double> v) {
    final total = v.fold(0.0, (a, x) => a + x);
    var top = 0;
    for (var i = 1; i < v.length; i++) {
      if (v[i] > v[top]) top = i;
    }
    return total > 0 && v[top] / total >= _minPeakShare / v.length ? top : null;
  }

  bool get _weekReadable => spending.length >= _minPattern && elapsedDays >= _minWeekDays;
  bool get _monthReadable => spending.length >= _minPattern && elapsedDays >= _minMonthDays;
  bool get _dayReadable => timedCount >= _minPattern;

  /// The weekday spending leans to. It must show on two dates at least, or it
  /// is one big purchase rather than a pattern.
  int? get peakWeekday {
    final i = _weekReadable ? _peak(byWeekday) : null;
    if (i == null) return null;
    return spending.where((t) => parseIso(t.date).weekday - 1 == i).map((t) => t.date).toSet().length >= 2 ? i : null;
  }

  int? get peakMonthPart => _monthReadable ? _peak(byMonthPart) : null;
  int? get peakTimeOfDay => _dayReadable ? _peak(byTimeOfDay) : null;

  String? get weekdayInsight {
    if (!_weekReadable) return null;
    final i = peakWeekday;
    return i == null ? tr.sumWeekEven : tr.sumPeakWeekday(weekdayName(i), _pct(byWeekday[i] / spent));
  }

  String? get monthPartInsight {
    if (!_monthReadable) return null;
    final i = peakMonthPart;
    return i == null ? tr.sumMonthEven : tr.sumPeakMoment([tr.sumWhenStart, tr.sumWhenMiddle, tr.sumWhenEnd][i], _pct(byMonthPart[i] / spent));
  }

  String? get timeOfDayInsight {
    if (!_dayReadable) return null;
    final i = peakTimeOfDay;
    if (i == null) return tr.sumDayEven;
    final total = byTimeOfDay.fold(0.0, (a, x) => a + x);
    return tr.sumPeakMoment([tr.sumWhenMorning, tr.sumWhenAfternoon, tr.sumWhenEvening, tr.sumWhenNight][i], _pct(byTimeOfDay[i] / total));
  }

  // ---------- categories ----------

  /// Biggest first. Categories only present in the range compared with come
  /// last, with a total of 0: a drop to nothing is worth seeing too.
  late final List<SumCategory> categories = () {
    final now = <String, double>{}, was = <String, double>{};
    for (final t in spending) {
      now[s.flowKey(t)] = (now[s.flowKey(t)] ?? 0) + t.amount;
    }
    for (final t in _spendingBefore) {
      was[s.flowKey(t)] = (was[s.flowKey(t)] ?? 0) + t.amount;
    }
    final list = [
      for (final k in {...now.keys, ...was.keys})
        SumCategory(
          key: k,
          name: s.group(k).name,
          icon: s.group(k).icon,
          color: s.group(k).color,
          total: now[k] ?? 0,
          before: baseline == null ? null : was[k] ?? 0,
        ),
    ];
    return list..sort((a, b) => a.total != b.total ? b.total.compareTo(a.total) : (b.before ?? 0).compareTo(a.before ?? 0));
  }();

  /// The category that grew the most, if the growth weighs on the total.
  SumCategory? get categoryJump {
    SumCategory? best;
    for (final c in categories) {
      final grew = c.total - (c.before ?? 0);
      if ((c.change ?? 0) >= 0.25 && grew >= spent * 0.1 && (best == null || grew > best.total - best.before!)) best = c;
    }
    return best;
  }

  String? categoryInsight(String Function(double) money) {
    if (spending.length < 3) return null;
    final c = categories.first;
    return tr.sumTopCategory(c.name, _pct(c.total / spent), money(c.total));
  }

  String? categoryJumpInsight(String Function(double) money) {
    final c = categoryJump;
    return c == null ? null : tr.sumCategoryUp(c.name, _pct(c.change!), money(c.total - c.before!));
  }

  // ---------- biggest expenses ----------

  late final List<Tx> biggest = ([...spending]..sort((a, b) => b.amount.compareTo(a.amount))).take(_topCount).toList();

  String? get biggestInsight {
    if (spending.length <= _topCount) return null;
    return tr.sumBiggestShare(_topCount, _pct(biggest.fold(0.0, (a, t) => a + t.amount) / spent));
  }

  // ---------- small expenses ----------

  /// What counts as small: under a quarter of the upper quartile of the
  /// range's expenses. The quartile ignores the rent and other rare big
  /// amounts, and unlike the median it stays meaningful for someone who notes
  /// lots of tiny expenses, the very case this analysis is for. Expenses of
  /// similar amounts give nothing, as they should. 0 with too few expenses.
  late final double smallThreshold = () {
    if (spending.length < _minSmallSample) return 0.0;
    final a = spending.map((t) => t.amount).toList()..sort();
    return a[((a.length - 1) * 0.75).round()] * 0.25;
  }();

  late final List<Tx> _small = spending.where((t) => t.amount < smallThreshold).toList();
  int get smallCount => _small.length;
  late final double smallTotal = _small.fold(0.0, (a, t) => a + t.amount);

  String? smallInsight(String Function(double) money) {
    if (smallCount < _minSmallCount) return null;
    return tr.sumSmallInsight(smallCount, money(smallThreshold), money(smallTotal));
  }

  // ---------- habits ----------

  /// Notes that keep coming back, the costliest first. The note is shown as
  /// first written.
  late final List<SumHabit> habits = () {
    final by = <String, List<Tx>>{};
    for (final t in spending) {
      final k = t.note.trim().toLowerCase();
      if (k.isNotEmpty) (by[k] ??= []).add(t);
    }
    final list = [
      for (final g in by.values)
        if (g.length >= _minHabit) SumHabit(g.first.note.trim(), g.length, g.fold(0.0, (a, t) => a + t.amount)),
    ];
    return list..sort((a, b) => b.total.compareTo(a.total));
  }();

  String? habitInsight(String Function(double) money) {
    if (habits.isEmpty) return null;
    final h = habits.first;
    return tr.sumHabitInsight(h.note, h.count, money(h.total));
  }

  // ---------- days without spending ----------

  late final ({int days, int streak}) _noSpend = () {
    final p = elapsed;
    if (p == null) return (days: 0, streak: 0);
    final busy = spending.map((t) => t.date).toSet();
    var days = 0, streak = 0, run = 0;
    for (var d = p.start; d.compareTo(p.end) <= 0; d = shiftDays(d, 1)) {
      run = busy.contains(d) ? 0 : run + 1;
      if (run > 0) days++;
      if (run > streak) streak = run;
    }
    return (days: days, streak: streak);
  }();

  /// Out of [elapsedDays].
  int get noSpendDays => _noSpend.days;
  int get longestStreak => _noSpend.streak;

  String? get noSpendInsight {
    if (elapsedDays < 7) return null;
    if (noSpendDays == 0) return tr.sumNoSpendNone;
    return '${tr.sumNoSpendDays(noSpendDays, elapsedDays)} ${tr.sumNoSpendStreak(longestStreak)}';
  }

  // ---------- accounts ----------

  /// The accounts expenses are paid from, the most used first.
  late final List<SumAccount> accounts = () {
    final by = <String, List<Tx>>{};
    for (final t in spending) {
      (by[s.accountOf(t)] ??= []).add(t);
    }
    final list = [
      for (final e in by.entries)
        SumAccount(
          id: e.key,
          name: s.accById(e.key)?.name ?? tr.commonOffAccounts,
          icon: s.accById(e.key)?.icon ?? 'wallet',
          count: e.value.length,
          total: e.value.fold(0.0, (a, t) => a + t.amount),
        ),
    ];
    return list..sort((a, b) => b.total.compareTo(a.total));
  }();

  String? get accountInsight {
    if (accounts.isEmpty) return null;
    final a = accounts.first;
    return accounts.length == 1 ? tr.sumAccountOnly(a.name) : tr.sumAccountTop(a.name, _pct(a.total / spent));
  }

  // ---------- savings ----------

  /// Money put aside for the goals, minus what was taken back.
  late final double netSaved = txs.where((t) => t.type == TxType.save).fold(0.0, (a, t) => a - t.dir * t.amount);

  /// Income not consumed: kept on the accounts or put aside.
  double get _kept {
    final sum = s.sums(txs);
    return sum.income - sum.expense;
  }

  /// Same figure as on the Statistics screen; null without income.
  double? get savingsRate {
    final income = s.sums(txs).income;
    return income > 0 ? _kept / income : null;
  }

  /// Goals still to reach, with a deadline or a pace to talk about. The pace
  /// is what the range moved to the goal, spread over its elapsed days.
  late final List<SumGoal> goals = [for (final g in s.goals) ?_goal(g)];

  SumGoal? _goal(Goal g) {
    final saved = s.goalSaved(g);
    if (g.target <= 0 || saved >= g.target) return null;
    final moved = txs.where((t) => t.type == TxType.save && t.goal == g.id && t.date.compareTo(today) <= 0).fold(0.0, (a, t) => a - t.dir * t.amount);
    final perDay = elapsedDays >= _minPaceDays && moved > 0 ? moved / elapsedDays : null;
    if (perDay == null) return g.deadline.isEmpty ? null : SumGoal(goal: g, saved: saved);
    final wait = ((g.target - saved) / perDay).ceil();
    return SumGoal(goal: g, saved: saved, perMonth: perDay * 30, eta: wait > _maxWaitDays ? null : shiftDays(today, wait));
  }

  String? savingsInsight(String Function(double) money) {
    final rate = savingsRate;
    if (rate == null) return null;
    return rate < 0 ? tr.sumOverspent(money(-_kept)) : tr.sumKept(_pct(rate));
  }

  // ---------- the essentials ----------

  String? _spentChangeInsight() {
    final c = spentChange;
    if (c == null || c.abs() < 0.1 || spending.length < 3) return null;
    final pct = _pct(c);
    if (comparedSoFar) return c > 0 ? tr.sumSpentUpSoFar(pct) : tr.sumSpentDownSoFar(pct);
    return c > 0 ? tr.sumSpentUp(pct) : tr.sumSpentDown(pct);
  }

  /// Up to five sentences on what stands out, most useful first: money going
  /// out faster than it comes in, then where it goes, then the patterns. There
  /// are fewer of them, or none, when the data backs nothing more.
  List<String> highlights(String Function(double) money) {
    final rate = savingsRate;
    final behind = goals.where((g) => g.behind).firstOrNull;
    final enough = spending.length >= 3;
    return [
      if (rate != null && rate < 0 && enough) tr.sumOverspent(money(-_kept)),
      ?_spentChangeInsight(),
      if (enough && categories.first.total / spent >= 0.25) ?categoryInsight(money),
      ?categoryJumpInsight(money),
      if (behind != null) tr.sumGoalBehind(behind.goal.name, longDate(behind.eta!), longDate(behind.goal.deadline)),
      if (spent > 0 && smallCount >= _minSmallSample && smallTotal / spent >= 0.05) ?smallInsight(money),
      ?habitInsight(money),
      if (peakWeekday != null) ?weekdayInsight,
      if (peakMonthPart != null) ?monthPartInsight,
      if (rate != null && rate >= 0 && enough && elapsedDays >= 7) tr.sumKept(_pct(rate)),
      if (enough && longestStreak >= 3) ?noSpendInsight,
    ].take(_highlights).toList();
  }
}
