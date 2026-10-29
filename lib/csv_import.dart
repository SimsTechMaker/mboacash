import 'dart:convert';

import 'format.dart';
import 'i18n.dart';
import 'models.dart';
import 'state.dart';

/// Reads a CSV exported by carnet237 (current or older column layout, `;` or
/// `,` separated, as saved by Excel or LibreOffice) and turns it into new
/// movements. Unknown categories, accounts, savings goals and debts are
/// created; rows already in the app are skipped.
class ImportPlan {
  final List<Tx> txs = [];
  final List<Category> newCats = [];
  final List<Account> newAccounts = [];
  final List<Goal> newGoals = [];
  final List<Debt> newDebts = [];
  final List<String> errors = []; // "ligne 12 : …" / "line 12: …"
  int duplicates = 0;
  String? currency; // from the file, when it differs from the app's
  bool get isEmpty => txs.isEmpty;
}

String _key(String s) {
  const from = 'àâäáçéèêëíìîïóòôöúùûüÿ';
  const to = 'aaaaceeeeiiiioooouuuuy';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().trim().runes) {
    final c = String.fromCharCode(ch);
    final i = from.indexOf(c);
    b.write(i >= 0 ? to[i] : c);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// Splits CSV text into rows, honouring quotes and doubled quotes.
List<List<String>> parseCsv(String text) {
  if (text.startsWith('﻿')) text = text.substring(1);
  final firstLine = text.split('\n').first;
  final sep = ';'.allMatches(firstLine).length >= ','.allMatches(firstLine).length ? ';' : ',';
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == sep) {
      row.add(cell.toString());
      cell.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      if (row.any((x) => x.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      cell.write(c);
    }
  }
  row.add(cell.toString());
  if (row.any((x) => x.trim().isNotEmpty)) rows.add(row);
  return rows;
}

String decodeCsvBytes(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes); // older Excel "CSV (séparateur : point-virgule)"
  }
}

String? _date(String v) {
  v = v.trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return v;
  final m = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$').firstMatch(v);
  if (m == null) return null;
  return isoDate(DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!)));
}

/// Type words: the French codes carnet237 writes, plus English aliases.
const _types = {
  'revenu': TxType.income,
  'depense': TxType.expense,
  'transfert': TxType.transfer,
  'ajustement': TxType.adjust,
  'epargne': TxType.save,
  'dette': TxType.debt,
  'income': TxType.income,
  'expense': TxType.expense,
  'transfer': TxType.transfer,
  'adjustment': TxType.adjust,
  'adjust': TxType.adjust,
  'savings': TxType.save,
  'saving': TxType.save,
  'save': TxType.save,
  'debt': TxType.debt,
};

/// Column names: the French headers carnet237 writes, plus English aliases.
const _headers = {
  'date': ['date'],
  'type': ['type'],
  'libelle': ['libelle', 'label', 'description'],
  'categorie': ['categorie', 'category'],
  'compte': ['compte', 'account'],
  'vers_compte': ['vers_compte', 'to_account'],
  'montant': ['montant', 'amount'],
  'devise': ['devise', 'currency'],
  'note': ['note'],
  'objectif': ['objectif', 'goal'],
  'personne': ['personne', 'person'],
  'sens': ['sens', 'direction'],
  'role': ['role'],
  'id': ['id'],
};

ImportPlan planImport(AppState s, String text) {
  final plan = ImportPlan();
  final rows = parseCsv(text);
  if (rows.isEmpty) {
    plan.errors.add(tr.importErrEmpty);
    return plan;
  }
  final head = rows.first.map((h) => _key(h).replaceAll(RegExp(r'[ -]'), '_')).toList();
  int col(String n) {
    for (final a in _headers[n]!) {
      final i = head.indexOf(a);
      if (i >= 0) return i;
    }
    return -1;
  }

  final cDate = col('date'), cType = col('type'), cLabel = col('libelle'), cCat = col('categorie'), cAcc = col('compte'), cTo = col('vers_compte');
  final cAmount = col('montant'), cCur = col('devise'), cNote = col('note'), cGoal = col('objectif'), cPerson = col('personne'), cSens = col('sens');
  final cRole = col('role'), cId = col('id');
  if (cDate < 0 || cType < 0 || cAmount < 0) {
    plan.errors.add(tr.importErrNotExport);
    return plan;
  }

  // Lookups over existing data, extended as new items are created.
  final accounts = {for (final a in s.settings.accounts) _key(a.name): a.id};
  final cats = {for (final c in s.settings.cats) '${c.income ? 'i' : 'o'}:${_key(c.name)}': c.id};
  final goals = {for (final g in s.goals) _key(g.name): g};
  final debts = {for (final d in s.debts) '${d.owe ? 'owe' : 'lent'}:${_key(d.person)}': d};
  final ids = {for (final t in s.txs) t.id};
  String finger(String date, TxType type, double amount, String acc, String note) => '$date|${typeCode(type)}|${amount.toStringAsFixed(2)}|$acc|${_key(note)}';
  final seen = {for (final t in s.txs) finger(t.date, t.type, t.amount, s.accountOf(t), t.note)};
  final usedColors = s.settings.cats.map((c) => c.color).toSet();
  final debtInit = <String, double>{}, debtPay = <String, double>{};

  String account(String name) {
    final k = _key(name);
    if (k.isEmpty) return s.settings.defaultAccount;
    return accounts[k] ??= () {
      final a = Account(id: newId('a-'), name: name.trim(), icon: 'credit-card');
      plan.newAccounts.add(a);
      return a.id;
    }();
  }

  String category(String name, bool income) {
    final other = income ? tr.defCatAutreIn : tr.defCatAutre;
    final k = '${income ? 'i' : 'o'}:${_key(name.isEmpty ? other : name)}';
    return cats[k] ??= () {
      final color = palette.firstWhere((p) => !usedColors.contains(p), orElse: () => palette[(s.settings.cats.length + plan.newCats.length) % palette.length]);
      usedColors.add(color);
      final c = Category(id: newId('c-'), name: name.trim().isEmpty ? other : name.trim(), icon: 'tag', income: income, color: color);
      plan.newCats.add(c);
      return c.id;
    }();
  }

  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    String at(int c) => c >= 0 && c < r.length ? r[c].trim() : '';
    final line = '${i + 1}';
    final date = _date(at(cDate));
    final type = _types[_key(at(cType))];
    final raw = parseAmount(at(cAmount).replaceAll(' ', '').replaceAll(' ', ''));
    if (date == null || type == null || raw == null || raw == 0) {
      plan.errors.add(tr.importErrUnreadable(line));
      continue;
    }
    final cur = at(cCur);
    if (cur.isNotEmpty && cur != s.settings.currency) plan.currency = cur;
    final amount = raw.abs();
    final sign = raw < 0 ? -1 : 1;
    final note = at(cNote);
    final label = at(cLabel);
    var accName = at(cAcc);
    var dir = 1, cat = typeCode(type), to = '', goal = '', debt = '';
    var init = false;

    switch (type) {
      case TxType.income:
      case TxType.expense:
        cat = category(cCat >= 0 && at(cCat).isNotEmpty ? at(cCat) : label, type == TxType.income);
      case TxType.transfer:
        to = account(at(cTo));
      case TxType.adjust:
        dir = sign;
      case TxType.save:
        dir = sign;
        var name = at(cGoal);
        if (name.isEmpty) {
          name =
              RegExp(r"^(?:Épargne|Retrait d'épargne|Savings|Savings withdrawal|Withdrawal from savings) ?: (.+)$").firstMatch(label)?[1] ??
              tr.importSavingsGoal;
        }
        goal = (goals[_key(name)] ??= () {
          final g = Goal(id: newId('g-'), name: name);
          plan.newGoals.add(g);
          return g;
        }()).id;
      case TxType.debt:
        var person = at(cPerson);
        bool? owe = switch (_key(at(cSens))) {
          'je_dois' || 'je dois' || 'i_owe' || 'i owe' => true,
          'on_me_doit' || 'on me doit' || 'owed_to_me' || 'owed to me' => false,
          _ => null,
        };
        final role = _key(at(cRole));
        if (role.isNotEmpty) init = role.startsWith('pret') || role.startsWith('init') || role.startsWith('loan');
        // Older exports only have the label: "Emprunt auprès de X", "Prêt à X",
        // "Remboursement à X" (I repay) or "Remboursement de X" (I am repaid).
        for (final (re, o, ini) in [
          (RegExp(r'^Emprunt auprès de (.+)$'), true, true),
          (RegExp(r'^Prêt à (.+)$'), false, true),
          (RegExp(r'^Remboursement à (.+)$'), true, false),
          (RegExp(r'^Remboursement de (.+)$'), false, false),
          // Same labels from an English export.
          (RegExp(r'^Borrowed from (.+)$'), true, true),
          (RegExp(r'^(?:Loan|Lent) to (.+)$'), false, true),
          (RegExp(r'^Repayment to (.+)$'), true, false),
          (RegExp(r'^Repayment from (.+)$'), false, false),
        ]) {
          final m = re.firstMatch(label);
          if (m != null) {
            if (person.isEmpty) person = m[1]!;
            owe ??= o;
            if (role.isEmpty) init = ini;
          }
        }
        if (person.isEmpty || owe == null) {
          plan.errors.add(tr.importErrDebt(line));
          continue;
        }
        final k = '${owe ? 'owe' : 'lent'}:${_key(person)}';
        final d = debts[k] ??= () {
          final d = Debt(id: newId('d-'), owe: owe!, person: person, amount: 0, date: date);
          plan.newDebts.add(d);
          return d;
        }();
        if (plan.newDebts.contains(d) && date.compareTo(d.date) < 0) d.date = date;
        (init ? debtInit : debtPay)[d.id] = ((init ? debtInit : debtPay)[d.id] ?? 0) + amount;
        debt = d.id;
        // Money really moved only when an account is named; otherwise the sign
        // follows the debt's direction.
        dir = accName.isEmpty ? ((owe == init) ? 1 : -1) : sign;
    }
    final acc = type == TxType.debt && accName.isEmpty ? '' : account(accName);

    final id = at(cId);
    if ((id.isNotEmpty && ids.contains(id)) || !seen.add(finger(date, type, amount, acc, note))) {
      plan.duplicates++;
      continue;
    }
    final tx = Tx(
      id: id.isNotEmpty ? id : newId(),
      type: type,
      amount: amount,
      cat: cat,
      account: acc,
      to: to,
      dir: dir,
      goal: goal,
      debt: debt,
      init: init,
      date: date,
      note: note,
    );
    ids.add(tx.id);
    plan.txs.add(tx);
  }

  // Debts created from the file: the loan is the sum of its initial rows,
  // or, when only repayments were exported, what was repaid.
  for (final d in plan.newDebts) {
    d.amount = (debtInit[d.id] ?? 0) > 0 ? debtInit[d.id]! : (debtPay[d.id] ?? 0);
  }
  return plan;
}
