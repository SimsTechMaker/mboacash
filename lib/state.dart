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
  String month = monthKey(DateTime.now());
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
  Map<String, double>? _balances;

  void _changed() {
    rev++;
    _catIdx = null;
    _accIdx = null;
    _monthCache.clear();
    _balances = null;
    notifyListeners();
  }

  Future<void> load() async {
    await store.open();
    settings = await store.loadSettings();
    final labels = settings.labelsLang;
    _applyLang(settings);
    if (settings.labelsLang != labels) await store.saveSettings(settings);
    txs = await store.loadTxs();
    goals = await store.loadGoals();
    debts = await store.loadDebts();
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

  /// What a movement adds to the month's income (> 0) or expenses (< 0).
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

  double get totalSaved => goals.fold(0.0, (s, g) => s + goalSaved(g));
  double get totalOwed => debts.where((d) => d.owe).fold(0.0, (s, d) => s + debtLeft(d));
  double get totalLent => debts.where((d) => !d.owe).fold(0.0, (s, d) => s + debtLeft(d));

  // ---------- navigation helpers ----------
  void setMonth(String m) {
    month = m;
    catFilter = null;
    notifyListeners();
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
    if (i >= 0) {
      // The proof photo was replaced or removed: drop the old file.
      if (txs[i].proof.isNotEmpty && txs[i].proof != t.proof) await Proofs.delete(txs[i].proof);
      txs[i] = t;
    } else {
      txs.add(t);
    }
    _changed();
  }

  Future<void> deleteTx(String id) async {
    await store.deleteTx(id);
    final proof = txs.where((t) => t.id == id).firstOrNull?.proof ?? '';
    if (proof.isNotEmpty) await Proofs.delete(proof);
    txs.removeWhere((t) => t.id == id);
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
    _changed();
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

  Future<void> deleteGoal(String id) async {
    await store.deleteGoal(id);
    goals.removeWhere((g) => g.id == id);
    txs.removeWhere((t) => t.type == TxType.save && t.goal == id);
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

  Future<void> deleteDebt(String id) async {
    await store.deleteDebt(id);
    debts.removeWhere((d) => d.id == id);
    txs.removeWhere((t) => t.type == TxType.debt && t.debt == id);
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
    _changed();
  }

  Future<void> wipeAll() async {
    await store.wipe();
    txs.clear();
    goals.clear();
    debts.clear();
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
    for (final x in t) {
      if (x.proof.isNotEmpty && !Proofs.isValidName(x.proof)) x.proof = '';
    }
    final proofs = data['proofs'] is Map ? Map<String, dynamic>.from(data['proofs'] as Map) : const <String, dynamic>{};
    _applyLang(s);
    await store.replaceAll(s, t, g, d);
    await Proofs.import(proofs);
    await Proofs.prune({for (final x in t) x.proof});
    settings = s;
    txs = t;
    goals = g;
    debts = d;
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
    month = monthKey(now);
    _changed();
  }
}
