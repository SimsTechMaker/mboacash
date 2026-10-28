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
      version: 1,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE kv (k TEXT PRIMARY KEY, v TEXT NOT NULL)');
        await db.execute('''CREATE TABLE txs (
          id TEXT PRIMARY KEY, type TEXT NOT NULL, amount REAL NOT NULL, cat TEXT, account TEXT, to_acc TEXT,
          dir INTEGER, goal TEXT, debt TEXT, init INTEGER, date TEXT NOT NULL, note TEXT, sample INTEGER, created INTEGER)''');
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
  });

  /// Swaps every table for the given data in one transaction (backup restore).
  Future<void> replaceAll(Settings s, List<Tx> txs, List<Goal> goals, List<Debt> debts) => _db.transaction((t) async {
    await t.delete('txs');
    await t.delete('goals');
    await t.delete('debts');
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
