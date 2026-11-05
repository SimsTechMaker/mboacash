import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// SQLite storage on the phone. Settings (categories, accounts, preferences)
/// live as one JSON value in `kv`; movements, goals and debts get tables.
class Store {
  late final Database _db;

  Future<void> open() async {
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'carnet237.db'),
      version: 3,
      // v2: proof photo file name on movements. v3: agenda and closed periods.
      onUpgrade: (db, from, _) async {
        if (from < 2) await db.execute('ALTER TABLE txs ADD COLUMN proof TEXT');
        if (from < 3) await _createPlanning(db);
      },
      onCreate: (db, _) async {
        await _createPlanning(db);
        await db.execute('CREATE TABLE kv (k TEXT PRIMARY KEY, v TEXT NOT NULL)');
        await db.execute('''CREATE TABLE txs (
          id TEXT PRIMARY KEY, type TEXT NOT NULL, amount REAL NOT NULL, cat TEXT, account TEXT, to_acc TEXT,
          dir INTEGER, goal TEXT, debt TEXT, init INTEGER, date TEXT NOT NULL, note TEXT, proof TEXT, sample INTEGER, created INTEGER)''');
        await db.execute('CREATE INDEX txs_date ON txs(date)');
        await db.execute('''CREATE TABLE goals (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, icon TEXT, color TEXT, target REAL, initial REAL,
          deadline TEXT, sample INTEGER, created INTEGER)''');
        await db.execute('''CREATE TABLE debts (
          id TEXT PRIMARY KEY, kind TEXT NOT NULL, person TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL,
          due TEXT, note TEXT, sample INTEGER, created INTEGER)''');
      },
    );
  }

  static Future<void> _createPlanning(Database db) async {
    await db.execute('''CREATE TABLE scheduled (
      id TEXT PRIMARY KEY, type TEXT NOT NULL, amount REAL NOT NULL, cat TEXT, account TEXT, to_acc TEXT,
      note TEXT, next TEXT NOT NULL, repeat TEXT, day INTEGER, created INTEGER)''');
    await db.execute('''CREATE TABLE periods (
      id TEXT PRIMARY KEY, start TEXT NOT NULL, end_date TEXT NOT NULL, kind TEXT, opening REAL, income REAL,
      expense REAL, saved REAL, closing REAL, budget REAL, spent REAL, count INTEGER, top TEXT, closed_at INTEGER)''');
  }

  Future<Settings> loadSettings() async {
    final rows = await _db.query('kv', where: 'k = ?', whereArgs: ['settings']);
    if (rows.isEmpty) return Settings.defaults();
    try {
      return Settings.fromJson(jsonDecode(rows.first['v'] as String) as Map<String, dynamic>);
    } catch (_) {
      return Settings.defaults();
    }
  }

  Future<void> saveSettings(Settings s) => _db.insert('kv', {'k': 'settings', 'v': jsonEncode(s.toJson())}, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Tx>> loadTxs() async => (await _db.query('txs')).map(Tx.fromRow).toList();
  Future<List<Goal>> loadGoals() async => (await _db.query('goals', orderBy: 'created')).map(Goal.fromRow).toList();
  Future<List<Debt>> loadDebts() async => (await _db.query('debts', orderBy: 'created')).map(Debt.fromRow).toList();

  Future<List<Scheduled>> loadScheduled() async => (await _db.query('scheduled', orderBy: 'next')).map(Scheduled.fromRow).toList();
  Future<List<ClosedPeriod>> loadPeriods() async => (await _db.query('periods', orderBy: 'start')).map(ClosedPeriod.fromRow).toList();
  Future<void> saveScheduled(Scheduled x) => _db.insert('scheduled', x.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> deleteScheduled(String id) => _db.delete('scheduled', where: 'id = ?', whereArgs: [id]);
  Future<void> savePeriod(ClosedPeriod p) => _db.insert('periods', p.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> deletePeriod(String id) => _db.delete('periods', where: 'id = ?', whereArgs: [id]);

  Future<void> saveTx(Tx t) => _db.insert('txs', t.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> saveGoal(Goal g) => _db.insert('goals', g.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> saveDebt(Debt d) => _db.insert('debts', d.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteTx(String id) => _db.delete('txs', where: 'id = ?', whereArgs: [id]);
  Future<void> deleteGoal(String id) => _db.transaction((t) async {
    await t.delete('txs', where: "type = 'save' AND goal = ?", whereArgs: [id]);
    await t.delete('goals', where: 'id = ?', whereArgs: [id]);
  });
  Future<void> deleteDebt(String id) => _db.transaction((t) async {
    await t.delete('txs', where: "type = 'debt' AND debt = ?", whereArgs: [id]);
    await t.delete('debts', where: 'id = ?', whereArgs: [id]);
  });

  Future<void> saveMany(List<Tx> txs) => _db.transaction((t) async {
    for (final x in txs) {
      await t.insert('txs', x.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  });

  Future<void> clearSamples() => _db.transaction((t) async {
    await t.delete('txs', where: 'sample = 1');
    await t.delete('goals', where: 'sample = 1');
    await t.delete('debts', where: 'sample = 1');
  });

  Future<void> wipe() => _db.transaction((t) async {
    await t.delete('txs');
    await t.delete('goals');
    await t.delete('debts');
    await t.delete('scheduled');
    await t.delete('periods');
  });

  /// Adds imported data in one transaction: all of it or nothing.
  Future<void> importAll(Settings s, List<Tx> txs, List<Goal> goals, List<Debt> debts) => _db.transaction((t) async {
    await t.insert('kv', {'k': 'settings', 'v': jsonEncode(s.toJson())}, conflictAlgorithm: ConflictAlgorithm.replace);
    for (final g in goals) {
      await t.insert('goals', g.toRow());
    }
    for (final d in debts) {
      await t.insert('debts', d.toRow());
    }
    for (final x in txs) {
      await t.insert('txs', x.toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  });

  /// Swaps every table for the given data in one transaction (backup restore).
  Future<void> replaceAll(Settings s, List<Tx> txs, List<Goal> goals, List<Debt> debts, List<Scheduled> scheduled, List<ClosedPeriod> periods) =>
      _db.transaction((t) async {
        await t.delete('txs');
        await t.delete('goals');
        await t.delete('debts');
        await t.delete('scheduled');
        await t.delete('periods');
        for (final x in scheduled) {
          await t.insert('scheduled', x.toRow());
        }
        for (final x in periods) {
          await t.insert('periods', x.toRow());
        }
        await t.insert('kv', {'k': 'settings', 'v': jsonEncode(s.toJson())}, conflictAlgorithm: ConflictAlgorithm.replace);
        for (final x in txs) {
          await t.insert('txs', x.toRow());
        }
        for (final g in goals) {
          await t.insert('goals', g.toRow());
        }
        for (final d in debts) {
          await t.insert('debts', d.toRow());
        }
      });
}
