import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'db.dart';
import 'i18n.dart';
import 'models.dart';
import 'proofs.dart';

class Effect {
  final String account;
  final double delta;
  const Effect(this.account, this.delta);
}

/// All app data in memory, written through to SQLite. Data sets stay small
/// (a few thousand rows), so every screen computes from these lists directly.
class AppState extends ChangeNotifier {
  final Store store;
  AppState(this.store);

  Settings settings = Settings.defaults();
  List<Tx> txs = [];
  List<Goal> goals = [];
  List<Debt> debts = [];
  List<Scheduled> scheduled = [];
  List<ClosedPeriod> closed = []; // oldest first
  late Period view = settings.openPeriod; // the period on screen
  bool ready = false;

  // Journal filters, shared between tabs (e.g. "Opérations" on an account card).
  String? catFilter;
  String? accFilter;

  /// Bumped on every data change. All five tabs rebuild on each change (they
  /// stay alive in an IndexedStack), so lookups and per-month lists are cached
  /// per revision instead of being recomputed by every screen.
  int rev = 0;
  Map<String, Category>? _catIdx;
  Map<String, Account>? _accIdx;
  final _monthCache = <String, List<Tx>>{};
  final _periodCache = <String, List<Tx>>{};
  Map<String, double>? _balances;

  void _changed() {
    rev++;
    _catIdx = null;
    _accIdx = null;
    _monthCache.clear();
    _periodCache.clear();
    _balances = null;
    notifyListeners();
  }

  Future<void> load() async {
    await store.open();
    settings = await store.loadSettings();
    _applyLang(settings);
    // Also pins the open period of data saved before periods existed: without
    // it, the period would silently follow the calendar and never need closing.
    await store.saveSettings(settings);
    txs = await store.loadTxs();
    goals = await store.loadGoals();
    debts = await store.loadDebts();
    scheduled = await store.loadScheduled();
    closed = await store.loadPeriods();
    view = openPeriod;
    ready = true;
    _changed();
  }

  // ---------- lookups ----------
  Category? catById(String id) => (_catIdx ??= {for (final c in settings.cats) c.id: c})[id];
  Account? accById(String id) => (_accIdx ??= {for (final a in settings.accounts) a.id: a})[id];

  List<Category> activeCats(bool income) => settings.cats.where((c) => c.income == income && !c.archived).toList();
  List<Account> get activeAccounts => settings.accounts.where((a) => !a.archived).toList();
  Goal? goalById(String id) => goals.where((g) => g.id == id).firstOrNull;
  Debt? debtById(String id) => debts.where((d) => d.id == id).firstOrNull;

  /// The account a movement belongs to; falls back to the default account if
  /// it was removed. Debts recorded "outside my accounts" have none.
  String accountOf(Tx t) {
    if (t.type == TxType.debt && t.account.isEmpty) return '';
    return accById(t.account) != null ? t.account : settings.defaultAccount;
  }

  // ---------- computations ----------
  List<Tx> monthTxs(String key) => _monthCache[key] ??= List.unmodifiable(txs.where((t) => t.date.startsWith(key)));

  List<Tx> periodTxs(Period p) => _periodCache[p.key] ??= List.unmodifiable(txs.where((t) => p.contains(t.date)));

  /// What a movement adds to the period's income (> 0) or expenses (< 0).
  /// Savings and debts count by direction when real money moves: putting
  /// aside or lending is an expense, taking back, borrowing or being repaid is
  /// income. Transfers, adjustments and debts kept "outside my accounts" don't.
  double flow(Tx t) => switch (t.type) {
    TxType.income => t.amount,
    TxType.expense => -t.amount,
    TxType.save => t.dir * t.amount,
    TxType.debt => accountOf(t).isEmpty ? 0 : t.dir * t.amount,
    _ => 0,
  };

  /// Grouping key for per-category totals: the category id, or 'save'/'debt'.
  String flowKey(Tx t) => t.type == TxType.income || t.type == TxType.expense ? t.cat : typeCode(t.type);

  ({double income, double expense}) sums(Iterable<Tx> list) {
    double i = 0, o = 0;
    for (final t in list) {
      final f = flow(t);
      if (f > 0) i += f;
      if (f < 0) o -= f;
    }
    return (income: i, expense: o);
  }

  /// Spending measured against the monthly budget: ordinary expenses only,
  /// savings and debt repayments stay outside it.
  double budgetSpent(Iterable<Tx> list) => list.where((t) => t.type == TxType.expense).fold(0.0, (s, t) => s + t.amount);

  /// Name, icon and palette slot of a [flowKey] group.
  ({String name, String icon, String color}) group(String key) => switch (key) {
    'save' => (name: tr.typeSave, icon: 'piggy-bank', color: 'c2'),
    'debt' => (name: tr.debtsTitle, icon: 'handshake', color: 'c9'),
    'transfer' => (name: tr.stateGroupTransfer, icon: 'arrow-left-right', color: 'c10'),
    'adjust' => (name: tr.typeAdjust, icon: 'sliders-horizontal', color: 'c10'),
    _ => (name: catById(key)?.name ?? tr.stateNoCategory, icon: catById(key)?.icon ?? 'package', color: catById(key)?.color ?? 'c10'),
  };

  List<Effect> effects(Tx t) {
    final a = accountOf(t);
    switch (t.type) {
      case TxType.income:
        return [Effect(a, t.amount)];
      case TxType.expense:
        return [Effect(a, -t.amount)];
      case TxType.transfer:
        return [Effect(a, -t.amount), Effect(t.to, t.amount)];
      default:
        return a.isEmpty ? [] : [Effect(a, t.dir * t.amount)];
    }
  }

  Map<String, double> balances() {
    if (_balances != null) return _balances!;
    final b = {for (final a in settings.accounts) a.id: a.initial};
    for (final t in txs) {
      for (final e in effects(t)) {
        if (b.containsKey(e.account)) b[e.account] = b[e.account]! + e.delta;
      }
    }
    return _balances = Map.unmodifiable(b);
  }

  double goalSaved(Goal g) => g.initial + txs.where((t) => t.type == TxType.save && t.goal == g.id).fold(0.0, (s, t) => s - t.dir * t.amount);
  double debtPaid(Debt d) => txs.where((t) => t.type == TxType.debt && t.debt == d.id && !t.init).fold(0.0, (s, t) => s + t.amount);
  double debtLeft(Debt d) => (d.amount - debtPaid(d)).clamp(0, double.infinity).toDouble();

  /// Money that can really be spent: every account, savings excluded.
  /// Archived accounts count too: money never leaves the totals unseen.
  double get spendable => settings.accounts.fold(0.0, (a, x) => a + (balances()[x.id] ?? 0));

  /// [spendable] as it stood at the end of [iso].
  double spendableAt(String iso) {
    final ids = {for (final a in settings.accounts) a.id};
    var total = settings.accounts.fold(0.0, (a, x) => a + x.initial);
    for (final t in txs) {
      if (t.date.compareTo(iso) > 0) continue;
      for (final e in effects(t)) {
        if (ids.contains(e.account)) total += e.delta;
      }
    }
    return total;
  }

  /// The money a period starts with: what the previous one left.
  double carriedInto(Period p) => spendableAt(shiftDays(p.start, -1));

  /// Balance corrections in [p]: neither income nor expense, but they move
  /// the money available, so they get their own line wherever totals add up.
  double otherMoves(Period p) => periodTxs(p).where((t) => t.type == TxType.adjust).fold(0.0, (a, t) => a + effects(t).fold(0.0, (b, e) => b + e.delta));

  /// What [acc] would hold after a change of [delta], [replacing] an existing
  /// movement when it is being edited.
  double balanceWith(String acc, double delta, {Tx? replacing}) {
    var b = balances()[acc] ?? 0;
    for (final e in replacing == null ? const <Effect>[] : effects(replacing)) {
      if (e.account == acc) b -= e.delta;
    }
    return b + delta;
  }

  /// [date] falls in a period already closed.
  bool isClosedDate(String date) => closed.any((c) => c.period.contains(date));

  /// Accounts below zero: before closing, each balance should match reality.
  List<Account> get negativeAccounts => settings.accounts.where((a) => (balances()[a.id] ?? 0) < -0.004).toList();

  /// The movement recording the money lent or borrowed when [d] was created.
  Tx? loanFor(Debt d) => txs.where((t) => t.type == TxType.debt && t.debt == d.id && t.init).firstOrNull;

  /// A debt cannot be smaller than what was already repaid.
  double minDebtAmount(Debt d) => debtPaid(d);

  /// A debt can be deleted when nothing is left to settle, or when it never
  /// moved money on the accounts.
  bool canDeleteDebt(Debt d) => debtLeft(d) <= 0 || !txs.any((t) => t.type == TxType.debt && t.debt == d.id && t.account.isNotEmpty);

  double get totalSaved => goals.fold(0.0, (s, g) => s + goalSaved(g));
  double get totalOwed => debts.where((d) => d.owe).fold(0.0, (s, d) => s + debtLeft(d));
  double get totalLent => debts.where((d) => !d.owe).fold(0.0, (s, d) => s + debtLeft(d));

  // ---------- navigation helpers ----------
  Period get openPeriod => settings.openPeriod;
  bool get viewingOpen => view == openPeriod;

  /// The open period's end date has passed: it is waiting to be closed.
  bool get periodEnded => todayIso().compareTo(openPeriod.end) > 0;

  void setView(Period p) {
    view = p;
    catFilter = null;
    notifyListeners();
  }

  /// The period just before [p]: a closed one if there is one, otherwise
  /// worked out from the current rhythm.
  Period previousPeriod(Period p) {
    for (final c in closed.reversed) {
      if (c.end.compareTo(p.start) < 0) return c.end == shiftDays(p.start, -1) ? c.period : Period(shiftDays(c.end, 1), shiftDays(p.start, -1));
    }
    return p.previous(settings.periodKind, settings.periodAnchor);
  }

  Period nextPeriod(Period p) {
    final open = openPeriod;
    if (p.end.compareTo(open.start) >= 0) return p.next(settings.periodKind, settings.periodAnchor);
    for (final c in closed) {
      if (c.start.compareTo(p.end) > 0) return c.period;
    }
    return open;
  }

  /// The period holding [date], for jumping to a movement just saved.
  Period periodOf(String date) {
    var p = view;
    for (var i = 0; i < 600 && !p.contains(date); i++) {
      p = date.compareTo(p.start) < 0 ? previousPeriod(p) : nextPeriod(p);
    }
    return p;
  }

  void setFilters({String? cat, String? acc}) {
    catFilter = cat;
    accFilter = acc;
    notifyListeners();
  }

  // ---------- writes ----------
  Future<void> saveTx(Tx t) async {
    await store.saveTx(t);
    final i = txs.indexWhere((x) => x.id == t.id);
    final from = i >= 0 && txs[i].date.compareTo(t.date) < 0 ? txs[i].date : t.date;
    if (i >= 0) {
      // The proof photo was replaced or removed: drop the old file.
      if (txs[i].proof.isNotEmpty && txs[i].proof != t.proof) await Proofs.delete(txs[i].proof);
      txs[i] = t;
    } else {
      txs.add(t);
    }
    await _refreshClosed(from);
    _changed();
  }

  Future<void> deleteTx(String id) async {
    await store.deleteTx(id);
    final old = txs.where((t) => t.id == id).firstOrNull;
    final proof = old?.proof ?? '';
    if (proof.isNotEmpty) await Proofs.delete(proof);
    txs.removeWhere((t) => t.id == id);
    if (old != null) await _refreshClosed(old.date);
    _changed();
  }

  /// Switches the app to the language [s] asks for and renames the built-in
  /// categories and accounts to match (custom names are left alone).
  void _applyLang(Settings s) {
    final code = resolveLang(s.language);
    useLang(code);
    s.relabel(code);
  }

  Future<void> saveSettings(Settings s) async {
    _applyLang(s);
    s.normalize();
    await store.saveSettings(s);
    settings = s;
    // An account's starting balance may have changed: it moves every total.
    await _refreshClosed('');
    _changed();
  }

  // ---------- budget periods ----------

  /// The figures of [p] as they stand, for the closing screen and the history.
  ClosedPeriod summarize(Period p, {String? id, int? closedAt, String? kind, double? budget}) {
    final list = periodTxs(p);
    final sum = sums(list);
    final by = <String, double>{};
    for (final t in list) {
      if (flow(t) < 0 && t.type != TxType.save) by[flowKey(t)] = (by[flowKey(t)] ?? 0) - flow(t);
    }
    final top = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ClosedPeriod(
      id: id ?? newId('p-'),
      start: p.start,
      end: p.end,
      kind: kind ?? settings.periodKind,
      opening: carriedInto(p),
      income: sum.income,
      expense: sum.expense,
      saved: list.where((t) => t.type == TxType.save).fold(0.0, (a, t) => a - t.dir * t.amount),
      closing: spendableAt(p.end),
      budget: budget ?? settings.budget,
      spent: budgetSpent(list),
      count: list.length,
      top: jsonEncode([
        for (final e in top.take(5)) [group(e.key).name, e.value],
      ]),
      closedAt: closedAt,
    );
  }

  /// Keeps the stored summaries true when a movement dated in a closed period
  /// is added, changed or removed. Everything after it moves too: what one
  /// period leaves is what the next one starts with.
  /// An empty [date] refreshes them all.
  Future<void> _refreshClosed(String date) async {
    if (closed.isEmpty || date.compareTo(closed.last.end) > 0) return;
    _balances = null;
    _periodCache.clear();
    for (var i = 0; i < closed.length; i++) {
      final c = closed[i];
      if (c.end.compareTo(date) < 0) continue;
      closed[i] = summarize(c.period, id: c.id, closedAt: c.closedAt, kind: c.kind, budget: c.budget);
      await store.savePeriod(closed[i]);
    }
  }

  /// Stores the open period's summary and opens the next one.
  Future<void> closePeriod() async {
    final c = summarize(openPeriod);
    await store.savePeriod(c);
    closed = [...closed, c];
    final next = openPeriod.next(settings.periodKind, settings.periodAnchor);
    final s = settings.copy()
      ..periodStart = next.start
      ..periodEnd = next.end;
    await store.saveSettings(s);
    settings = s;
    view = next;
    _changed();
  }

  /// Undoes the last closing: its summary goes and it is the open period again.
  Future<void> reopenLast() async {
    final c = closed.last;
    await store.deletePeriod(c.id);
    closed = closed.sublist(0, closed.length - 1);
    final s = settings.copy()
      ..periodStart = c.start
      ..periodEnd = c.end;
    await store.saveSettings(s);
    settings = s;
    view = c.period;
    _changed();
  }

  /// Sets the rhythm from now on, on the open period. Closed periods stay as
  /// they are, so the open one cannot start before the last one ended.
  Future<void> setPeriod(String kind, String start, String end) async {
    final s = settings.copy()
      ..periodKind = kind
      ..periodStart = start
      ..periodEnd = end
      ..periodAnchor = parseIso(start).day;
    await store.saveSettings(s);
    settings = s;
    view = s.openPeriod;
    _changed();
  }

  // ---------- agenda ----------

  /// Planned movements whose date has come, waiting for confirmation.
  List<Scheduled> get dueScheduled {
    final today = todayIso();
    return scheduled.where((x) => x.next.compareTo(today) <= 0).toList()..sort((a, b) => a.next.compareTo(b.next));
  }

  Future<void> saveScheduled(Scheduled x) async {
    await store.saveScheduled(x);
    scheduled = [...scheduled.where((y) => y.id != x.id), x]..sort((a, b) => a.next.compareTo(b.next));
    _changed();
  }

  Future<void> deleteScheduled(String id) async {
    await store.deleteScheduled(id);
    scheduled = scheduled.where((x) => x.id != id).toList();
    _changed();
  }

  /// Moves past this occurrence; a one-off is finished.
  Future<void> skipScheduled(Scheduled x) async {
    final next = x.after(x.next);
    if (next == null) return deleteScheduled(x.id);
    x.next = next;
    await saveScheduled(x);
  }

  /// Records the occurrence as a real movement, then moves past it.
  Future<void> confirmScheduled(Scheduled x, {required double amount, required String date}) async {
    await saveTx(
      Tx(
        id: newId(),
        type: x.type,
        amount: amount,
        cat: x.type == TxType.transfer ? 'transfer' : x.cat,
        account: x.account,
        to: x.type == TxType.transfer ? x.to : '',
        date: date,
        note: x.note,
      ),
    );
    await skipScheduled(x);
  }

  Future<void> saveGoal(Goal g) async {
    await store.saveGoal(g);
    final i = goals.indexWhere((x) => x.id == g.id);
    if (i >= 0) {
      goals[i] = g;
    } else {
      goals.add(g);
    }
    _changed();
  }

  /// Only an empty savings account can go (see [goalSaved]); its past
  /// movements stay, so earlier periods keep their figures.
  Future<void> deleteGoal(String id) async {
    final g = goalById(id);
    if (g != null && goalSaved(g).abs() > 0.004) throw StateError('savings account not empty');
    await store.deleteGoal(id);
    goals.removeWhere((g) => g.id == id);
    _changed();
  }

  Future<void> saveDebt(Debt d) async {
    await store.saveDebt(d);
    final i = debts.indexWhere((x) => x.id == d.id);
    if (i >= 0) {
      debts[i] = d;
    } else {
      debts.add(d);
    }
    _changed();
  }

  /// See [canDeleteDebt]. Movements that touched the accounts stay in the
  /// history; a debt kept outside the accounts goes with its records.
  Future<void> deleteDebt(String id) async {
    final d = debtById(id);
    if (d == null) return;
    if (!canDeleteDebt(d)) throw StateError('debt not settled');
    final keep = txs.any((t) => t.type == TxType.debt && t.debt == id && t.account.isNotEmpty);
    await store.deleteDebt(id, keepTxs: keep);
    debts.removeWhere((d) => d.id == id);
    if (!keep) txs.removeWhere((t) => t.type == TxType.debt && t.debt == id);
    _changed();
  }

  /// Adjust an account to its real balance with one "adjust" movement.
  Future<double> adjustAccount(String accId, double real, String date, String note) async {
    final cur = balances()[accId] ?? 0;
    final diff = ((real - cur) * 100).roundToDouble() / 100;
    if (diff == 0) return 0;
    await saveTx(Tx(id: newId(), type: TxType.adjust, amount: diff.abs(), cat: 'adjust', account: accId, dir: diff > 0 ? 1 : -1, date: date, note: note));
    return diff;
  }

  bool get hasSamples => txs.any((t) => t.sample) || goals.any((g) => g.sample) || debts.any((d) => d.sample);

  Future<void> clearSamples() async {
    await store.clearSamples();
    txs.removeWhere((t) => t.sample);
    goals.removeWhere((g) => g.sample);
    debts.removeWhere((d) => d.sample);
    await _refreshClosed('');
    _changed();
  }

  Future<void> wipeAll() async {
    await store.wipe();
    txs.clear();
    goals.clear();
    debts.clear();
    scheduled = [];
    closed = [];
    await Proofs.prune({});
    _changed();
  }

  /// Adds the result of a CSV import, with the categories, accounts, goals
  /// and debts it had to create.
  Future<void> importData({
    required List<Tx> txs,
    List<Category> cats = const [],
    List<Account> accounts = const [],
    List<Goal> goals = const [],
    List<Debt> debts = const [],
  }) async {
    final s = settings.copy()
      ..cats.addAll(cats)
      ..accounts.addAll(accounts);
    s.normalize();
    await store.importAll(s, txs, goals, debts);
    settings = s;
    this.txs = [...this.txs, ...txs];
    this.goals = [...this.goals, ...goals];
    this.debts = [...this.debts, ...debts];
    await _refreshClosed('');
    _changed();
  }

  /// Everything the app stores, as plain JSON (what a backup contains).
  Map<String, dynamic> snapshot() => {
    'app': 'carnet237', // format tag from the app's first name: kept so every backup opens
    'format': 1,
    'created': DateTime.now().toIso8601String(),
    'settings': settings.toJson(),
    'txs': txs.map((t) => t.toRow()).toList(),
    'goals': goals.map((g) => g.toRow()).toList(),
    'debts': debts.map((d) => d.toRow()).toList(),
    'scheduled': scheduled.map((x) => x.toRow()).toList(),
    'periods': closed.map((x) => x.toRow()).toList(),
  };

  /// [snapshot] plus the proof photos, base64-encoded: a complete backup.
  Future<Map<String, dynamic>> fullSnapshot() async => {...snapshot(), 'proofs': await Proofs.export(txs.map((t) => t.proof).where((p) => p.isNotEmpty))};

  /// Replaces all data with a [snapshot] (with or without proof photos). Parsing happens first, so a bad
  /// file leaves the current data untouched.
  Future<void> restore(Map<String, dynamic> data) async {
    if (data['app'] != 'carnet237') throw const FormatException('not a carnet237 backup');
    List<Map<String, Object?>> rows(String k) => [for (final r in (data[k] as List? ?? const [])) Map<String, Object?>.from(r as Map)];
    final s = Settings.fromJson(Map<String, dynamic>.from(data['settings'] as Map));
    final t = rows('txs').map(Tx.fromRow).toList();
    final g = rows('goals').map(Goal.fromRow).toList();
    final d = rows('debts').map(Debt.fromRow).toList();
    // Older backups have neither of these.
    final sc = rows('scheduled').map(Scheduled.fromRow).toList();
    final cp = rows('periods').map(ClosedPeriod.fromRow).toList()..sort((a, b) => a.start.compareTo(b.start));
    for (final x in t) {
      if (x.proof.isNotEmpty && !Proofs.isValidName(x.proof)) x.proof = '';
    }
    final proofs = data['proofs'] is Map ? Map<String, dynamic>.from(data['proofs'] as Map) : const <String, dynamic>{};
    _applyLang(s);
    await store.replaceAll(s, t, g, d, sc, cp);
    await Proofs.import(proofs);
    await Proofs.prune({for (final x in t) x.proof});
    settings = s;
    txs = t;
    goals = g;
    debts = d;
    scheduled = sc;
    closed = cp;
    view = s.openPeriod;
    catFilter = null;
    accFilter = null;
    _changed();
  }

  Future<void> loadSamples() async {
    final now = DateTime.now();
    String a(String id) => accById(id) != null && !accById(id)!.archived ? id : settings.defaultAccount;
    String c(String id, bool income) => catById(id) != null && !catById(id)!.archived ? id : activeCats(income).first.id;
    String d(int mBack, int day) => isoDate(DateTime(now.year, now.month - mBack, day));

    final goal = Goal(
      id: newId('g-'),
      name: tr.stateSampleGoalEmergency,
      icon: 'shield',
      color: 'c2',
      target: 600000,
      deadline: isoDate(DateTime(now.year, now.month + 8, 1)),
      sample: true,
    );
    final lent = Debt(
      id: newId('d-'),
      owe: false,
      person: 'Moussa',
      amount: 50000,
      date: d(1, 10),
      due: isoDate(DateTime(now.year, now.month, 1)),
      note: tr.stateSampleNoteRentAdvance,
      sample: true,
    );
    final owe = Debt(
      id: newId('d-'),
      owe: true,
      person: tr.stateSampleDebtTontine,
      amount: 120000,
      date: d(2, 5),
      due: isoDate(DateTime(now.year, now.month + 3, 1)),
      sample: true,
    );
    for (final g in [goal]) {
      await store.saveGoal(g);
    }
    for (final x in [lent, owe]) {
      await store.saveDebt(x);
    }
    goals.add(goal);
    debts.addAll([lent, owe]);

    final list = <Tx>[];
    var n = 0;
    void add(
      int mBack,
      int day,
      TxType type,
      double amount, {
      String cat = '',
      String acc = 'cash',
      String to = '',
      String note = '',
      Debt? debt,
      bool init = false,
    }) {
      if (mBack == 0 && day > now.day) return;
      final account = a(acc);
      final toAcc = type == TxType.transfer ? a(to) : '';
      if (type == TxType.transfer && toAcc == account) return;
      int dir = 1;
      if (type == TxType.save) dir = -1;
      if (type == TxType.debt) dir = debt!.owe == init ? 1 : -1;
      list.add(
        Tx(
          id: newId(),
          type: type,
          amount: amount,
          cat: type == TxType.income || type == TxType.expense ? c(cat, type == TxType.income) : typeCode(type),
          account: account,
          to: toAcc,
          dir: dir,
          goal: type == TxType.save ? goal.id : '',
          debt: debt?.id ?? '',
          init: init,
          date: d(mBack, day),
          note: note,
          sample: true,
          created: now.millisecondsSinceEpoch + n++,
        ),
      );
    }

    const inc = TxType.income, exp = TxType.expense, xfer = TxType.transfer;
    for (final m in [0, 1, 2]) {
      add(m, 1, inc, 450000, cat: 'salaire', acc: 'bank', note: tr.stateSampleNoteSalary);
      add(m, 2, exp, 150000, cat: 'logement', acc: 'bank', note: tr.stateSampleNoteRent);
      add(m, 3, xfer, m == 0 ? 60000 : 120000, acc: 'bank', to: 'cash', note: tr.stateSampleNoteWithdrawal);
    }
    add(0, 3, exp, 18500, cat: 'alim', note: tr.stateSampleNoteWeeklyMarket);
    add(0, 4, exp, 3500, cat: 'transport', note: tr.stateSampleNoteMotoTaxi);
    add(0, 5, xfer, 30000, acc: 'bank', to: 'momo', note: tr.stateSampleNoteTopUp);
    add(0, 5, TxType.save, 50000, acc: 'bank');
    add(0, 6, exp, 22000, cat: 'factures', acc: 'momo', note: tr.stateSampleNoteEneo);
    add(0, 8, exp, 9200, cat: 'alim', note: tr.stateSampleNoteSupermarket);
    add(0, 9, exp, 6500, cat: 'resto', note: tr.stateSampleNoteLunch);
    add(0, 10, TxType.debt, 20000, acc: 'momo', debt: owe);
    add(0, 12, exp, 12000, cat: 'loisirs', note: tr.stateSampleNoteCinema);
    add(0, 13, exp, 7500, cat: 'sante', note: tr.stateSampleNotePharmacy);
    add(0, 14, inc, 85000, cat: 'activite', acc: 'momo', note: tr.stateSampleNoteFreelance);
    add(0, 15, exp, 25000, cat: 'famille', acc: 'momo', note: tr.stateSampleNoteParents);
    add(0, 16, TxType.debt, 20000, debt: lent);
    add(0, 18, exp, 15000, cat: 'transport', note: tr.stateSampleNoteFuel);
    add(0, 20, exp, 19900, cat: 'shopping', acc: 'bank', note: tr.stateSampleNoteShoes);
    add(0, 22, exp, 10000, cat: 'telephone', acc: 'momo', note: tr.stateSampleNoteInternet);
    add(0, 24, exp, 30000, cat: 'education', acc: 'bank', note: tr.stateSampleNoteLessons);
    add(1, 5, TxType.save, 75000, acc: 'bank');
    add(1, 6, exp, 61000, cat: 'alim', note: tr.stateSampleNoteGroceries);
    add(1, 10, TxType.debt, 50000, debt: lent, init: true);
    add(1, 12, exp, 31000, cat: 'factures', acc: 'momo', note: tr.stateSampleNoteUtilities);
    add(1, 19, exp, 28000, cat: 'transport', note: tr.stateSampleNoteFuel);
    add(1, 25, exp, 22000, cat: 'loisirs', acc: 'bank', note: tr.stateSampleNoteWeekend);
    add(2, 5, TxType.debt, 120000, acc: 'bank', debt: owe, init: true);
    add(2, 9, exp, 72000, cat: 'alim', note: tr.stateSampleNoteGroceries);
    add(2, 16, exp, 40000, cat: 'sante', acc: 'bank', note: tr.stateSampleNoteDoctor);
    add(2, 22, exp, 55000, cat: 'shopping', acc: 'bank', note: tr.stateSampleNotePhone);

    await store.saveMany(list);
    txs.addAll(list);
    view = periodOf(todayIso());
    _changed();
  }
}
