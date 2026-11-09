import 'insights.dart';
import 'models.dart';
import 'state.dart';

/// Understanding a movement typed as one short phrase, such as "taxi 1500 momo"
/// or "+ salaire 350k banque", and remembering how the user usually fills
/// the same note. All of it from the user's own history, on the phone.

String _norm(String s) {
  const from = 'àâäáãçéèêëíìîïñóòôöõúùûüÿ';
  const to = 'aaaaaceeeeiiiinooooouuuuy';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().runes) {
    final c = String.fromCharCode(ch);
    final i = from.indexOf(c);
    b.write(i >= 0 ? to[i] : c);
  }
  return b.toString().replaceAll(RegExp(r' +'), ' ').trim();
}

/// What the user usually does with a note.
class NoteHabit {
  final String note, cat, account;
  final TxType type;
  final double amount; // the most recent one
  final int count;
  const NoteHabit({required this.note, required this.cat, required this.account, required this.type, required this.amount, required this.count});
}

/// The notes already used, most frequent first, whose words start with
/// [prefix]. Only income and expenses: they are what people type. The note
/// typed in full is left out unless [exact], since there is nothing to complete.
List<NoteHabit> noteHabits(AppState s, String prefix, {int limit = 4, bool exact = false}) {
  final q = _norm(prefix);
  final groups = <String, List<Tx>>{};
  for (final t in s.txs) {
    if ((t.type != TxType.income && t.type != TxType.expense) || t.note.trim().isEmpty) continue;
    final key = _norm(t.note);
    if (q.isNotEmpty && !key.startsWith(q) && !key.split(' ').any((w) => w.startsWith(q))) continue;
    groups.putIfAbsent(key, () => []).add(t);
  }
  final out = [
    for (final g in groups.values)
      () {
        final last = (g..sort((a, b) => b.date.compareTo(a.date) != 0 ? b.date.compareTo(a.date) : b.created.compareTo(a.created))).first;
        return NoteHabit(note: last.note.trim(), cat: last.cat, account: s.accountOf(last), type: last.type, amount: last.amount, count: g.length);
      }(),
  ]..sort((a, b) => b.count.compareTo(a.count));
  // An exact match is already typed in full: nothing to complete.
  return out.where((h) => exact || q.isEmpty || _norm(h.note) != q).take(limit).toList();
}

/// What a quick phrase means.
class QuickGuess {
  final TxType type;
  final double? amount;
  final String note;
  final String? cat;
  final String account;
  const QuickGuess({required this.type, required this.amount, required this.note, required this.cat, required this.account});
  bool get ready => amount != null && amount! > 0;
}

const _incomeWords = {'salaire', 'paie', 'recu', 'gagne', 'vente', 'vendu', 'prime', 'bonus', 'salary', 'received', 'income'};
const _cashWords = {'cash', 'espece', 'especes', 'liquide', 'poche'};
const _bankWords = {'banque', 'bank', 'carte', 'virement'};
const _mobileWords = {'momo', 'om', 'orange', 'mtn', 'mobile', 'wave', 'flooz'};

/// Reads [text]: an amount ("1500", "1 500", "2k", "1,5k", "25mille", "3000f"),
/// maybe an account ("momo", "banque", "cash" or the name of an account), and
/// the rest as the note. A leading "+" or an income word makes it income.
/// What the phrase leaves out comes from the habit for the same note, then
/// from the category suggestions.
QuickGuess parseQuick(AppState s, String text) {
  var rest = text.trim();
  var income = false;
  if (rest.startsWith('+')) {
    income = true;
    rest = rest.substring(1);
  } else if (rest.startsWith('-')) {
    rest = rest.substring(1);
  }

  // The amount: the first number, with its thousands spaces and suffix.
  double? amount;
  final m = RegExp(r'(\d[\d  ]*(?:[.,]\d+)?)\s*(k|mil|mille|f|fcfa|frs|fr|xaf)?\b', caseSensitive: false).firstMatch(rest);
  if (m != null) {
    final digits = m[1]!.replaceAll(RegExp(r'[  ]'), '').replaceAll(',', '.');
    final v = double.tryParse(digits);
    if (v != null) {
      final suffix = (m[2] ?? '').toLowerCase();
      amount = suffix == 'k' || suffix.startsWith('mil') ? v * 1000 : v;
      rest = rest.replaceRange(m.start, m.end, ' ');
    }
  }

  // The account: a known word or one of the user's account names.
  String? account;
  final accounts = s.activeAccounts;
  String? byName(bool Function(String) test) => accounts.where((a) => test(_norm(a.name))).firstOrNull?.id;
  final kept = <String>[];
  for (final word in rest.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
    final w = _norm(word);
    String? found;
    if (account == null) {
      if (_cashWords.contains(w)) {
        found = accounts.any((a) => a.id == 'cash') ? 'cash' : byName((n) => n.startsWith('esp') || n.contains('cash'));
      } else if (_bankWords.contains(w)) {
        found = accounts.any((a) => a.id == 'bank') ? 'bank' : byName((n) => n.contains('banq') || n.contains('bank'));
      } else if (_mobileWords.contains(w)) {
        found =
            byName((n) => n.split(' ').contains(w)) ??
            (accounts.any((a) => a.id == 'momo') ? 'momo' : byName((n) => n.contains('mobile') || n.contains('momo')));
      } else {
        found = byName((n) => n == w);
      }
    }
    if (found != null) {
      account = found;
    } else {
      kept.add(word);
    }
  }
  var note = kept.join(' ').trim();
  if (note.isNotEmpty) note = note[0].toUpperCase() + note.substring(1);
  if (!income && kept.isNotEmpty && _incomeWords.contains(_norm(kept.first))) income = true;

  // What the user did last time with the same note fills the gaps.
  final habit = note.isEmpty ? null : noteHabits(s, note, limit: 50, exact: true).where((h) => _norm(h.note) == _norm(note)).firstOrNull;
  final type = habit?.type ?? (income ? TxType.income : TxType.expense);
  final cat = habit?.cat ?? (note.isEmpty ? null : Insights.of(s).suggestCategory(note, income: type == TxType.income));
  return QuickGuess(
    type: income ? TxType.income : type,
    amount: amount ?? habit?.amount,
    note: habit?.note ?? note,
    cat: cat ?? s.activeCats(type == TxType.income).first.id,
    account: account ?? habit?.account ?? s.settings.defaultAccount,
  );
}

/// A movement that looks like one already recorded: same kind, amount,
/// account and category, within a day. Usually typed twice by mistake.
Tx? similarTx(AppState s, Tx t) {
  final d = parseIso(t.date);
  return s.txs.where((x) {
    if (x.id == t.id || x.type != t.type || (x.amount - t.amount).abs() > 0.004 || x.account != t.account || x.cat != t.cat) return false;
    return parseIso(x.date).difference(d).inDays.abs() <= 1;
  }).firstOrNull;
}
