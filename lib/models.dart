import 'dart:math';

/// Generates short unique ids (time + random), like the web prototype.
String newId([String prefix = '']) {
  final r = Random();
  final rand = List.generate(6, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[r.nextInt(36)]).join();
  return '$prefix${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}$rand';
}

String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String monthKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
DateTime parseIso(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p.length > 2 ? p[2] : 1);
}

String shiftMonth(String key, int delta) {
  final d = parseIso('$key-01');
  return monthKey(DateTime(d.year, d.month + delta, 1));
}

String todayIso() => isoDate(DateTime.now());

/// Palette slots shared by categories and savings goals (see theme.dart).
const palette = ['c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10'];

enum TxType { income, expense, transfer, adjust, save, debt }

const _typeCodes = {TxType.income: 'in', TxType.expense: 'out', TxType.transfer: 'transfer', TxType.adjust: 'adjust', TxType.save: 'save', TxType.debt: 'debt'};
String typeCode(TxType t) => _typeCodes[t]!;
TxType typeFromCode(String? c) => _typeCodes.entries.firstWhere((e) => e.value == c, orElse: () => const MapEntry(TxType.expense, 'out')).key;

class Category {
  String id;
  String name;
  String icon;
  bool income;
  String color;
  double cap;
  bool archived;

  Category({required this.id, required this.name, required this.icon, required this.income, required this.color, this.cap = 0, this.archived = false});

  Category copy() => Category(id: id, name: name, icon: icon, income: income, color: color, cap: cap, archived: archived);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon, 'type': income ? 'in' : 'out', 'color': color, 'cap': cap, 'archived': archived};
  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: '${j['id']}',
    name: '${j['name']}',
    icon: '${j['icon'] ?? 'tag'}',
    income: j['type'] == 'in',
    color: palette.contains(j['color']) ? j['color'] : 'c10',
    cap: (j['cap'] as num?)?.toDouble() ?? 0,
    archived: j['archived'] == true,
  );
}

class Account {
  String id;
  String name;
  String icon;
  double initial;
  bool archived;

  Account({required this.id, required this.name, required this.icon, this.initial = 0, this.archived = false});

  Account copy() => Account(id: id, name: name, icon: icon, initial: initial, archived: archived);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon, 'initial': initial, 'archived': archived};
  factory Account.fromJson(Map<String, dynamic> j) => Account(
    id: '${j['id']}',
    name: '${j['name']}',
    icon: '${j['icon'] ?? 'credit-card'}',
    initial: (j['initial'] as num?)?.toDouble() ?? 0,
    archived: j['archived'] == true,
  );
}

List<Category> defaultCategories() => [
  ['alim', 'Alimentation', 'shopping-cart', false, 'c1'],
  ['resto', 'Restaurant', 'utensils', false, 'c6'],
  ['transport', 'Transport', 'car', false, 'c2'],
  ['logement', 'Logement', 'house', false, 'c3'],
  ['factures', 'Factures', 'lightbulb', false, 'c4'],
  ['telephone', 'Téléphone et internet', 'wifi', false, 'c5'],
  ['sante', 'Santé', 'pill', false, 'c5'],
  ['loisirs', 'Loisirs', 'film', false, 'c6'],
  ['shopping', 'Shopping', 'shopping-bag', false, 'c7'],
  ['education', 'Éducation', 'graduation-cap', false, 'c8'],
  ['famille', 'Famille', 'users', false, 'c9'],
  ['autre', 'Autre', 'package', false, 'c10'],
  ['salaire', 'Salaire', 'briefcase', true, 'c8'],
  ['activite', 'Activité', 'hand-coins', true, 'c2'],
  ['cadeau', 'Cadeau', 'gift', true, 'c6'],
  ['autre_in', 'Autre revenu', 'coins', true, 'c10'],
].map((c) => Category(id: c[0] as String, name: c[1] as String, icon: c[2] as String, income: c[3] as bool, color: c[4] as String)).toList();

List<Account> defaultAccounts() => [
  Account(id: 'cash', name: 'Espèces', icon: 'wallet'),
  Account(id: 'bank', name: 'Banque', icon: 'landmark'),
  Account(id: 'momo', name: 'Mobile Money', icon: 'smartphone'),
];

const currencies = {
  'XAF': 'Franc CFA (XAF)',
  'XOF': 'Franc CFA (XOF)',
  'EUR': 'Euro (EUR)',
  'USD': 'Dollar US (USD)',
  'NGN': 'Naira (NGN)',
  'GHS': 'Cedi (GHS)',
  'MAD': 'Dirham marocain (MAD)',
  'GNF': 'Franc guinéen (GNF)',
};

class Settings {
  String currency;
  double budget;
  String theme; // auto | light | dark
  List<Category> cats;
  List<Account> accounts;
  String defaultAccount;

  Settings({required this.currency, required this.budget, required this.theme, required this.cats, required this.accounts, required this.defaultAccount});

  factory Settings.defaults() =>
      Settings(currency: 'XAF', budget: 0, theme: 'auto', cats: defaultCategories(), accounts: defaultAccounts(), defaultAccount: 'cash');

  Settings copy() => Settings(
    currency: currency,
    budget: budget,
    theme: theme,
    cats: cats.map((c) => c.copy()).toList(),
    accounts: accounts.map((a) => a.copy()).toList(),
    defaultAccount: defaultAccount,
  );

  /// Repairs anything a bad edit could leave behind: at least one active
  /// category of each kind and one active account, and a valid default account.
  void normalize() {
    for (final income in [false, true]) {
      if (!cats.any((c) => c.income == income && !c.archived)) {
        // Bring the built-in categories back, reviving any that were hidden.
        for (final d in defaultCategories().where((d) => d.income == income)) {
          final existing = cats.where((c) => c.id == d.id).firstOrNull;
          if (existing != null) {
            existing.archived = false;
          } else {
            cats.add(d);
          }
        }
      }
    }
    if (!accounts.any((a) => !a.archived)) accounts.add(Account(id: newId('a-'), name: 'Espèces', icon: 'wallet'));
    if (!accounts.any((a) => a.id == defaultAccount && !a.archived)) defaultAccount = accounts.firstWhere((a) => !a.archived).id;
    for (final c in cats) {
      if (c.name.trim().isEmpty) c.name = 'Sans nom';
    }
    for (final a in accounts) {
      if (a.name.trim().isEmpty) a.name = 'Compte';
    }
  }

  Map<String, dynamic> toJson() => {
    'currency': currency,
    'budget': budget,
    'theme': theme,
    'cats': cats.map((c) => c.toJson()).toList(),
    'accounts': accounts.map((a) => a.toJson()).toList(),
    'defaultAccount': defaultAccount,
  };
  factory Settings.fromJson(Map<String, dynamic> j) {
    final s = Settings(
      currency: currencies.containsKey(j['currency']) ? j['currency'] : 'XAF',
      budget: (j['budget'] as num?)?.toDouble() ?? 0,
      theme: ['auto', 'light', 'dark'].contains(j['theme']) ? j['theme'] : 'auto',
      cats: (j['cats'] as List?)?.map((e) => Category.fromJson(Map<String, dynamic>.from(e))).toList() ?? defaultCategories(),
      accounts: (j['accounts'] as List?)?.map((e) => Account.fromJson(Map<String, dynamic>.from(e))).toList() ?? defaultAccounts(),
      defaultAccount: '${j['defaultAccount'] ?? 'cash'}',
    );
    s.normalize();
    return s;
  }
}

/// One movement of money. Like the web version, a single table holds every
/// kind: income/expense/transfer plus adjustments, savings moves and debts.
/// For adjust/save/debt, [dir] is the sign of the effect on [account].
class Tx {
  final String id;
  TxType type;
  double amount;
  String cat;
  String account;
  String to;
  int dir;
  String goal;
  String debt;
  bool init; // debt: the original loan rather than a repayment
  String date;
  String note;
  bool sample;
  int created;

  Tx({
    required this.id,
    required this.type,
    required this.amount,
    required this.cat,
    required this.account,
    this.to = '',
    this.dir = 1,
    this.goal = '',
    this.debt = '',
    this.init = false,
    required this.date,
    this.note = '',
    this.sample = false,
    int? created,
  }) : created = created ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> toRow() => {
    'id': id,
    'type': typeCode(type),
    'amount': amount,
    'cat': cat,
    'account': account,
    'to_acc': to,
    'dir': dir,
    'goal': goal,
    'debt': debt,
    'init': init ? 1 : 0,
    'date': date,
    'note': note,
    'sample': sample ? 1 : 0,
    'created': created,
  };
  factory Tx.fromRow(Map<String, Object?> r) => Tx(
    id: r['id'] as String,
    type: typeFromCode(r['type'] as String?),
    amount: (r['amount'] as num).toDouble(),
    cat: (r['cat'] as String?) ?? '',
    account: (r['account'] as String?) ?? '',
    to: (r['to_acc'] as String?) ?? '',
    dir: (r['dir'] as int?) == -1 ? -1 : 1,
    goal: (r['goal'] as String?) ?? '',
    debt: (r['debt'] as String?) ?? '',
    init: (r['init'] as int?) == 1,
    date: r['date'] as String,
    note: (r['note'] as String?) ?? '',
    sample: (r['sample'] as int?) == 1,
    created: (r['created'] as int?) ?? 0,
  );
}

class Goal {
  final String id;
  String name;
  String icon;
  String color;
  double target;
  double initial;
  String deadline;
  bool sample;
  int created;

  Goal({
    required this.id,
    required this.name,
    this.icon = 'piggy-bank',
    this.color = 'c2',
    this.target = 0,
    this.initial = 0,
    this.deadline = '',
    this.sample = false,
    int? created,
  }) : created = created ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'target': target,
    'initial': initial,
    'deadline': deadline,
    'sample': sample ? 1 : 0,
    'created': created,
  };
  factory Goal.fromRow(Map<String, Object?> r) => Goal(
    id: r['id'] as String,
    name: r['name'] as String,
    icon: (r['icon'] as String?) ?? 'piggy-bank',
    color: (r['color'] as String?) ?? 'c2',
    target: (r['target'] as num?)?.toDouble() ?? 0,
    initial: (r['initial'] as num?)?.toDouble() ?? 0,
    deadline: (r['deadline'] as String?) ?? '',
    sample: (r['sample'] as int?) == 1,
    created: (r['created'] as int?) ?? 0,
  );
}

class Debt {
  final String id;
  bool owe; // true: I owe someone; false: someone owes me
  String person;
  double amount;
  String date;
  String due;
  String note;
  bool sample;
  int created;

  Debt({
    required this.id,
    required this.owe,
    required this.person,
    required this.amount,
    required this.date,
    this.due = '',
    this.note = '',
    this.sample = false,
    int? created,
  }) : created = created ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> toRow() => {
    'id': id,
    'kind': owe ? 'owe' : 'lent',
    'person': person,
    'amount': amount,
    'date': date,
    'due': due,
    'note': note,
    'sample': sample ? 1 : 0,
    'created': created,
  };
  factory Debt.fromRow(Map<String, Object?> r) => Debt(
    id: r['id'] as String,
    owe: r['kind'] != 'lent',
    person: r['person'] as String,
    amount: (r['amount'] as num).toDouble(),
    date: r['date'] as String,
    due: (r['due'] as String?) ?? '',
    note: (r['note'] as String?) ?? '',
    sample: (r['sample'] as int?) == 1,
    created: (r['created'] as int?) ?? 0,
  );
}
