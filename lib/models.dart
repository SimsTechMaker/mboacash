import 'dart:math';
import 'dart:ui' show Locale;

import 'i18n.dart';

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

String shiftDays(String iso, int days) {
  final d = parseIso(iso);
  return isoDate(DateTime(d.year, d.month, d.day + days));
}

/// [d] moved by [months], on [day] of the month or its last day if shorter.
DateTime addMonths(DateTime d, int months, int day) {
  final last = DateTime(d.year, d.month + months + 1, 0).day;
  return DateTime(d.year, d.month + months, day < last ? day : last);
}

const periodKinds = ['2weeks', 'month', 'quarter', 'semester', 'custom'];
const _kindMonths = {'month': 1, 'quarter': 3, 'semester': 6};

/// A budget period, both ends included. The user chooses when it starts and
/// how long it lasts: it need not follow calendar months.
class Period {
  final String start, end;
  const Period(this.start, this.end);

  bool contains(String iso) => iso.compareTo(start) >= 0 && iso.compareTo(end) <= 0;
  int get days {
    final a = parseIso(start), b = parseIso(end);
    // In UTC, so a daylight saving change cannot lose a day.
    return DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays + 1;
  }

  String get key => '$start/$end';

  @override
  bool operator ==(Object other) => other is Period && other.start == start && other.end == end;
  @override
  int get hashCode => key.hashCode;

  /// The calendar month around [d].
  factory Period.calendarMonth(DateTime d) => Period(isoDate(DateTime(d.year, d.month, 1)), isoDate(DateTime(d.year, d.month + 1, 0)));

  /// The period of [kind] starting on [start]. [anchor] is the day of the
  /// month periods start on; [days] is the length of a custom period.
  factory Period.from(String start, String kind, {required int anchor, int days = 30}) {
    final months = _kindMonths[kind];
    if (months != null) return Period(start, shiftDays(isoDate(addMonths(parseIso(start), months, anchor)), -1));
    return Period(start, shiftDays(start, (kind == '2weeks' ? 14 : days) - 1));
  }

  Period next(String kind, int anchor) => Period.from(shiftDays(end, 1), kind, anchor: anchor, days: days);

  Period previous(String kind, int anchor) {
    final months = _kindMonths[kind];
    if (months != null) return Period(isoDate(addMonths(parseIso(start), -months, anchor)), shiftDays(start, -1));
    final n = kind == '2weeks' ? 14 : days;
    return Period(shiftDays(start, -n), shiftDays(start, -1));
  }
}

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

const _defaultCats = [
  ('alim', 'shopping-cart', false, 'c1'),
  ('resto', 'utensils', false, 'c6'),
  ('transport', 'car', false, 'c2'),
  ('logement', 'house', false, 'c3'),
  ('factures', 'lightbulb', false, 'c4'),
  ('telephone', 'wifi', false, 'c5'),
  ('sante', 'pill', false, 'c5'),
  ('loisirs', 'film', false, 'c6'),
  ('shopping', 'shopping-bag', false, 'c7'),
  ('education', 'graduation-cap', false, 'c8'),
  ('famille', 'users', false, 'c9'),
  ('autre', 'package', false, 'c10'),
  ('salaire', 'briefcase', true, 'c8'),
  ('activite', 'hand-coins', true, 'c2'),
  ('cadeau', 'gift', true, 'c6'),
  ('autre_in', 'coins', true, 'c10'),
];

/// Names of the built-in categories and accounts, by id, in language [l].
Map<String, String> defaultLabels(AppLocalizations l) => {
  'alim': l.defCatAlim,
  'resto': l.defCatResto,
  'transport': l.defCatTransport,
  'logement': l.defCatLogement,
  'factures': l.defCatFactures,
  'telephone': l.defCatTelephone,
  'sante': l.defCatSante,
  'loisirs': l.defCatLoisirs,
  'shopping': l.defCatShopping,
  'education': l.defCatEducation,
  'famille': l.defCatFamille,
  'autre': l.defCatAutre,
  'salaire': l.defCatSalaire,
  'activite': l.defCatActivite,
  'cadeau': l.defCatCadeau,
  'autre_in': l.defCatAutreIn,
  'cash': l.defAccCash,
  'bank': l.defAccBank,
  'momo': l.defAccMomo,
};

List<Category> defaultCategories() {
  final names = defaultLabels(tr);
  return [for (final c in _defaultCats) Category(id: c.$1, name: names[c.$1]!, icon: c.$2, income: c.$3, color: c.$4)];
}

List<Account> defaultAccounts() => [
  Account(id: 'cash', name: tr.defAccCash, icon: 'wallet'),
  Account(id: 'bank', name: tr.defAccBank, icon: 'landmark'),
  Account(id: 'momo', name: tr.defAccMomo, icon: 'smartphone'),
];

/// Currency codes with their name in the current language.
Map<String, String> get currencies => {
  'XAF': tr.curXAF,
  'XOF': tr.curXOF,
  'EUR': tr.curEUR,
  'USD': tr.curUSD,
  'NGN': tr.curNGN,
  'GHS': tr.curGHS,
  'MAD': tr.curMAD,
  'GNF': tr.curGNF,
};

class Settings {
  String currency;
  double budget;
  String theme; // auto | light | dark
  String language; // auto | fr | en
  /// Language the built-in category and account names are written in, so
  /// they can be renamed when the language changes ('' for older data: fr).
  String labelsLang;
  // The open budget period (see [Period]); closing it opens the next one.
  String periodKind;
  String periodStart, periodEnd;
  int periodAnchor; // day of the month periods start on
  List<Category> cats;
  List<Account> accounts;
  String defaultAccount;

  Settings({
    required this.currency,
    required this.budget,
    required this.theme,
    this.language = 'auto',
    this.labelsLang = '',
    this.periodKind = 'month',
    this.periodStart = '',
    this.periodEnd = '',
    this.periodAnchor = 1,
    required this.cats,
    required this.accounts,
    required this.defaultAccount,
  });

  factory Settings.defaults() =>
      Settings(currency: 'XAF', budget: 0, theme: 'auto', labelsLang: lang, cats: defaultCategories(), accounts: defaultAccounts(), defaultAccount: 'cash')
        ..normalize();

  Settings copy() => Settings(
    currency: currency,
    budget: budget,
    theme: theme,
    language: language,
    labelsLang: labelsLang,
    periodKind: periodKind,
    periodStart: periodStart,
    periodEnd: periodEnd,
    periodAnchor: periodAnchor,
    cats: cats.map((c) => c.copy()).toList(),
    accounts: accounts.map((a) => a.copy()).toList(),
    defaultAccount: defaultAccount,
  );

  Period get openPeriod => Period(periodStart, periodEnd);

  /// Renames built-in categories and accounts still bearing their default
  /// name from the [labelsLang] language into [to]. Renamed ones are kept.
  void relabel(String to) {
    final from = labelsLang.isEmpty ? 'fr' : labelsLang;
    if (from == to) return;
    final before = defaultLabels(lookupAppLocalizations(Locale(from)));
    final after = defaultLabels(lookupAppLocalizations(Locale(to)));
    for (final c in cats) {
      if (before[c.id] != null && c.name == before[c.id]) c.name = after[c.id]!;
    }
    for (final a in accounts) {
      if (before[a.id] != null && a.name == before[a.id]) a.name = after[a.id]!;
    }
    labelsLang = to;
  }

  /// Repairs anything a bad edit could leave behind: at least one active
  /// category of each kind and one active account, and a valid default account.
  void normalize() {
    if (periodStart.isEmpty || periodEnd.compareTo(periodStart) < 0) {
      final p = Period.calendarMonth(DateTime.now());
      periodStart = p.start;
      periodEnd = p.end;
    }
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
    if (!accounts.any((a) => !a.archived)) accounts.add(Account(id: newId('a-'), name: tr.defAccCash, icon: 'wallet'));
    if (!accounts.any((a) => a.id == defaultAccount && !a.archived)) defaultAccount = accounts.firstWhere((a) => !a.archived).id;
    for (final c in cats) {
      if (c.name.trim().isEmpty) c.name = tr.unnamedCategory;
    }
    for (final a in accounts) {
      if (a.name.trim().isEmpty) a.name = tr.unnamedAccount;
    }
  }

  Map<String, dynamic> toJson() => {
    'currency': currency,
    'budget': budget,
    'theme': theme,
    'language': language,
    'labelsLang': labelsLang,
    'periodKind': periodKind,
    'periodStart': periodStart,
    'periodEnd': periodEnd,
    'periodAnchor': periodAnchor,
    'cats': cats.map((c) => c.toJson()).toList(),
    'accounts': accounts.map((a) => a.toJson()).toList(),
    'defaultAccount': defaultAccount,
  };
  factory Settings.fromJson(Map<String, dynamic> j) {
    final s = Settings(
      currency: currencies.containsKey(j['currency']) ? j['currency'] : 'XAF',
      budget: (j['budget'] as num?)?.toDouble() ?? 0,
      theme: ['auto', 'light', 'dark'].contains(j['theme']) ? j['theme'] : 'auto',
      language: supportedLangs.contains(j['language']) ? j['language'] : 'auto',
      labelsLang: supportedLangs.contains(j['labelsLang']) ? j['labelsLang'] : '',
      periodKind: periodKinds.contains(j['periodKind']) ? j['periodKind'] : 'month',
      periodStart: '${j['periodStart'] ?? ''}',
      periodEnd: '${j['periodEnd'] ?? ''}',
      periodAnchor: (j['periodAnchor'] as num?)?.toInt() ?? 1,
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
  String proof; // file name of the proof photo (see proofs.dart), or ''
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
    this.proof = '',
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
    'proof': proof,
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
    proof: (r['proof'] as String?) ?? '',
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

const repeats = ['once', 'week', '2weeks', 'month', 'quarter', 'year'];

/// A movement planned for later. It only becomes a real [Tx] when the user
/// confirms it, so balances never count money that has not moved.
class Scheduled {
  final String id;
  TxType type; // income, expense or transfer
  double amount;
  String cat;
  String account;
  String to;
  String note;
  String next; // date of the next occurrence
  String repeat;
  int day; // day of the month for monthly repeats, kept across short months
  int created;

  Scheduled({
    required this.id,
    required this.type,
    required this.amount,
    this.cat = '',
    required this.account,
    this.to = '',
    this.note = '',
    required this.next,
    this.repeat = 'once',
    int? day,
    int? created,
  }) : day = day ?? parseIso(next).day,
       created = created ?? DateTime.now().millisecondsSinceEpoch;

  /// The occurrence after [date], or null for a one-off.
  String? after(String date) {
    final d = parseIso(date);
    return switch (repeat) {
      'week' => shiftDays(date, 7),
      '2weeks' => shiftDays(date, 14),
      'month' => isoDate(addMonths(d, 1, day)),
      'quarter' => isoDate(addMonths(d, 3, day)),
      'year' => isoDate(addMonths(d, 12, day)),
      _ => null,
    };
  }

  /// Dates of the occurrences between [from] and [to], both included.
  List<String> occurrences(String from, String to) {
    final out = <String>[];
    String? d = next;
    while (d != null && d.compareTo(to) <= 0 && out.length < 400) {
      if (d.compareTo(from) >= 0) out.add(d);
      d = after(d);
    }
    return out;
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'type': typeCode(type),
    'amount': amount,
    'cat': cat,
    'account': account,
    'to_acc': to,
    'note': note,
    'next': next,
    'repeat': repeat,
    'day': day,
    'created': created,
  };
  factory Scheduled.fromRow(Map<String, Object?> r) => Scheduled(
    id: r['id'] as String,
    type: typeFromCode(r['type'] as String?),
    amount: (r['amount'] as num).toDouble(),
    cat: (r['cat'] as String?) ?? '',
    account: (r['account'] as String?) ?? '',
    to: (r['to_acc'] as String?) ?? '',
    note: (r['note'] as String?) ?? '',
    next: r['next'] as String,
    repeat: repeats.contains(r['repeat']) ? r['repeat'] as String : 'once',
    day: r['day'] as int?,
    created: (r['created'] as int?) ?? 0,
  );
}

/// The summary kept when a budget period is closed, so it can be found later.
class ClosedPeriod {
  final String id;
  final String start, end, kind;
  double opening, income, expense, saved, closing, budget, spent;
  int count;
  String top; // JSON list of [name, amount], biggest expenses first
  int closedAt;

  ClosedPeriod({
    required this.id,
    required this.start,
    required this.end,
    required this.kind,
    required this.opening,
    required this.income,
    required this.expense,
    required this.saved,
    required this.closing,
    required this.budget,
    required this.spent,
    required this.count,
    required this.top,
    int? closedAt,
  }) : closedAt = closedAt ?? DateTime.now().millisecondsSinceEpoch;

  Period get period => Period(start, end);

  Map<String, Object?> toRow() => {
    'id': id,
    'start': start,
    'end_date': end,
    'kind': kind,
    'opening': opening,
    'income': income,
    'expense': expense,
    'saved': saved,
    'closing': closing,
    'budget': budget,
    'spent': spent,
    'count': count,
    'top': top,
    'closed_at': closedAt,
  };
  factory ClosedPeriod.fromRow(Map<String, Object?> r) {
    double n(String k) => (r[k] as num?)?.toDouble() ?? 0;
    return ClosedPeriod(
      id: r['id'] as String,
      start: r['start'] as String,
      end: r['end_date'] as String,
      kind: (r['kind'] as String?) ?? 'month',
      opening: n('opening'),
      income: n('income'),
      expense: n('expense'),
      saved: n('saved'),
      closing: n('closing'),
      budget: n('budget'),
      spent: n('spent'),
      count: (r['count'] as int?) ?? 0,
      top: (r['top'] as String?) ?? '[]',
      closedAt: (r['closed_at'] as int?) ?? 0,
    );
  }
}
