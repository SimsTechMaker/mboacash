import 'dart:math';

import 'models.dart';
import 'state.dart';

/// On-device "intelligence": everything here is plain arithmetic over the
/// user's own history. No network, no model, results cached per data revision.

String _norm(String s) {
  const from = 'àâäáãçéèêëíìîïñóòôöõúùûüÿ';
  const to = 'aaaaaceeeeiiiinooooouuuuy';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().runes) {
    final c = String.fromCharCode(ch);
    final i = from.indexOf(c);
    b.write(i >= 0 ? to[i] : c);
  }
  return b.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').replaceAll(RegExp(r' +'), ' ').trim();
}

List<String> _words(String note) => _norm(note).split(' ').where((w) => w.length >= 3 && !_stop.contains(w)).toList();
const _stop = {'les', 'des', 'pour', 'avec', 'une', 'aux', 'chez', 'mon', 'mes', 'son', 'ses', 'sur', 'par', 'the', 'and'};

/// Common words → built-in category ids, used before there is enough history.
const _keywords = <String, String>{
  'taxi': 'transport',
  'moto': 'transport',
  'bus': 'transport',
  'carburant': 'transport',
  'essence': 'transport',
  'gasoil': 'transport',
  'clando': 'transport',
  'parking': 'transport',
  'peage': 'transport',
  'billet': 'transport',
  'yango': 'transport',
  'marche': 'alim',
  'supermarche': 'alim',
  'courses': 'alim',
  'pain': 'alim',
  'boulangerie': 'alim',
  'riz': 'alim',
  'poisson': 'alim',
  'viande': 'alim',
  'legumes': 'alim',
  'mahima': 'alim',
  'santa': 'alim',
  'carrefour': 'alim',
  'dovv': 'alim',
  'casino': 'alim',
  'restaurant': 'resto',
  'resto': 'resto',
  'maquis': 'resto',
  'tourne': 'resto',
  'dejeuner': 'resto',
  'diner': 'resto',
  'snack': 'resto',
  'loyer': 'logement',
  'bail': 'logement',
  'caution': 'logement',
  'eneo': 'factures',
  'electricite': 'factures',
  'camwater': 'factures',
  'eau': 'factures',
  'canal': 'factures',
  'abonnement': 'factures',
  'mtn': 'telephone',
  'orange': 'telephone',
  'nexttel': 'telephone',
  'camtel': 'telephone',
  'forfait': 'telephone',
  'credit': 'telephone',
  'internet': 'telephone',
  'data': 'telephone',
  'recharge': 'telephone',
  'pharmacie': 'sante',
  'medicament': 'sante',
  'hopital': 'sante',
  'consultation': 'sante',
  'clinique': 'sante',
  'analyse': 'sante',
  'cinema': 'loisirs',
  'sortie': 'loisirs',
  'concert': 'loisirs',
  'match': 'loisirs',
  'weekend': 'loisirs',
  'bar': 'loisirs',
  'vetement': 'shopping',
  'chaussures': 'shopping',
  'habit': 'shopping',
  'pagne': 'shopping',
  'telephone': 'shopping',
  'ecole': 'education',
  'scolarite': 'education',
  'cours': 'education',
  'livre': 'education',
  'fournitures': 'education',
  'formation': 'education',
  'parents': 'famille',
  'famille': 'famille',
  'enfant': 'famille',
  'bebe': 'famille',
  'cotisation': 'famille',
  'deuil': 'famille',
  'mariage': 'famille',
  'salaire': 'salaire',
  'paie': 'salaire',
  'prime': 'salaire',
  'mission': 'activite',
  'client': 'activite',
  'vente': 'activite',
  'freelance': 'activite',
  'commission': 'activite',
  'cadeau': 'cadeau',
  'don': 'cadeau',
};

class Recurring {
  final String note, cat, account;
  final bool income;
  final double amount;
  final int months;
  final String lastDate, nextDate;
  final bool paidThisMonth;
  Recurring(this.note, this.cat, this.account, this.income, this.amount, this.months, this.lastDate, this.nextDate, this.paidThisMonth);
}

enum Tone { good, warn, info }

class Insight {
  final Tone tone;
  final String icon, title, text;
  final String? cat; // tapping opens the journal filtered on it
  final double weight;
  Insight(this.tone, this.icon, this.title, this.text, {this.cat, this.weight = 0});
}

class Forecast {
  final double spent, income, projectedExpense, projectedIncome, budgetSpent, budgetProjected;
  final int day, days;
  Forecast(this.spent, this.income, this.projectedExpense, this.projectedIncome, this.budgetSpent, this.budgetProjected, this.day, this.days);
  double get projectedBalance => projectedIncome - projectedExpense;
}

enum Rule { r503020, r702010, history }

class Preset {
  final Rule rule;
  final double income, budget, saving;
  final Map<String, double> caps; // category id -> monthly cap
  final Map<String, double> goals; // goal id -> monthly amount to put aside
  Preset(this.rule, this.income, this.budget, this.saving, this.caps, this.goals);
}

class Insights {
  final AppState s;
  Insights._(this.s);

  static Insights? _cache;
  static int _rev = -1;

  /// Shared instance for the current data revision.
  static Insights of(AppState s) {
    if (_cache == null || _rev != s.rev || !identical(_cache!.s, s)) {
      _cache = Insights._(s);
      _rev = s.rev;
    }
    return _cache!;
  }

  // ---------------------------------------------------------------------------
  // Category suggestion
  // ---------------------------------------------------------------------------

  Map<String, Map<String, int>>? _wordIdx;

  /// Best category for a note: what this user chose before for the same words,
  /// otherwise the built-in keyword list. Null when there is no clue.
  String? suggestCategory(String note, {required bool income}) {
    final words = _words(note);
    if (words.isEmpty) return null;
    final active = {for (final c in s.activeCats(income)) c.id};
    _wordIdx ??= _buildWordIndex();
    final score = <String, double>{};
    for (var i = 0; i < words.length; i++) {
      final hits = _wordIdx!['${income ? 'i' : 'o'}:${words[i]}'];
      if (hits == null) continue;
      for (final e in hits.entries) {
        if (!active.contains(e.key)) continue;
        score[e.key] = (score[e.key] ?? 0) + e.value * (i == 0 ? 2 : 1); // first word weighs more
      }
    }
    if (score.isNotEmpty) return (score.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    for (final w in words) {
      for (final e in _keywords.entries) {
        if ((w == e.key || (w.length >= 5 && w.startsWith(e.key))) && active.contains(e.value)) return e.value;
      }
    }
    return null;
  }

  Map<String, Map<String, int>> _buildWordIndex() {
    final idx = <String, Map<String, int>>{};
    for (final t in s.txs) {
      if ((t.type != TxType.income && t.type != TxType.expense) || t.note.isEmpty) continue;
      final p = t.type == TxType.income ? 'i' : 'o';
      for (final w in _words(t.note).toSet()) {
        final m = idx.putIfAbsent('$p:$w', () => {});
        m[t.cat] = (m[t.cat] ?? 0) + 1;
      }
    }
    return idx;
  }

  // ---------------------------------------------------------------------------
  // Recurring movements
  // ---------------------------------------------------------------------------

  List<Recurring>? _recurring;

  /// Same note and a similar amount in at least 3 of the last 6 months, or in
  /// each of the last 2 months.
  List<Recurring> get recurring => _recurring ??= _findRecurring();

  List<Recurring> _findRecurring() {
    final now = DateTime.now();
    final thisMonth = monthKey(now);
    final from = shiftMonth(thisMonth, -6);
    final groups = <String, List<Tx>>{};
    for (final t in s.txs) {
      if ((t.type != TxType.income && t.type != TxType.expense) || t.note.trim().isEmpty || t.date.compareTo('$from-01') < 0) continue;
      groups.putIfAbsent('${t.type == TxType.income ? 'i' : 'o'}:${_norm(t.note)}', () => []).add(t);
    }
    final out = <Recurring>[];
    for (final g in groups.values) {
      final byMonth = <String, Tx>{};
      for (final t in g..sort((a, b) => a.date.compareTo(b.date))) {
        byMonth[t.date.substring(0, 7)] = t; // last of each month
      }
      final months = byMonth.keys.toList()..sort();
      final pastMonths = months.where((m) => m != thisMonth).toList();
      final last2 = pastMonths.contains(shiftMonth(thisMonth, -1)) && pastMonths.contains(shiftMonth(thisMonth, -2));
      if (pastMonths.length < 3 && !last2) continue;
      final amounts = byMonth.values.map((t) => t.amount).toList()..sort();
      final median = amounts[amounts.length ~/ 2];
      if (amounts.any((a) => (a - median).abs() > median * 0.15)) continue;
      final last = byMonth[months.last]!;
      final days = byMonth.values.map((t) => parseIso(t.date).day).toList()..sort();
      final day = days[days.length ~/ 2];
      final paid = byMonth.containsKey(thisMonth);
      final target = paid ? parseIso('${shiftMonth(thisMonth, 1)}-01') : now;
      final next = DateTime(target.year, target.month, min(day, DateTime(target.year, target.month + 1, 0).day));
      out.add(Recurring(last.note, last.cat, s.accountOf(last), last.type == TxType.income, median, months.length, last.date, isoDate(next), paid));
    }
    out.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return out;
  }

  /// Recurring movements of the current month that have not been entered yet.
  List<Recurring> get dueThisMonth => recurring.where((r) => !r.paidThisMonth).toList();

  // ---------------------------------------------------------------------------
  // Month-end forecast
  // ---------------------------------------------------------------------------

  Forecast forecast() {
    final now = DateTime.now();
    final month = monthKey(now);
    final days = DateTime(now.year, now.month + 1, 0).day;
    final day = now.day;
    final list = s.monthTxs(month);
    final sum = s.sums(list);
    final budgetSpent = s.budgetSpent(list);

    // Daily pace of ordinary spending: this month blended with the last three
    // months, so the first days of a month don't swing the forecast wildly.
    double histDaily = 0;
    var histMonths = 0;
    for (var k = 1; k <= 3; k++) {
      final m = shiftMonth(month, -k);
      final l = s.monthTxs(m);
      if (l.isEmpty) continue;
      final d = parseIso('$m-01');
      histDaily += _variable(l) / DateTime(d.year, d.month + 1, 0).day;
      histMonths++;
    }
    histDaily = histMonths == 0 ? 0 : histDaily / histMonths;
    final thisDaily = _variable(list) / day;
    final pace = histMonths == 0 ? thisDaily : (thisDaily * day + histDaily * 7) / (day + 7);
    final remaining = days - day;

    final due = dueThisMonth;
    final dueOut = due.where((r) => !r.income).fold(0.0, (a, r) => a + r.amount);
    final dueIn = due.where((r) => r.income).fold(0.0, (a, r) => a + r.amount);
    final variableAhead = pace * remaining;
    return Forecast(
      sum.expense,
      sum.income,
      sum.expense + variableAhead + dueOut,
      sum.income + dueIn,
      budgetSpent,
      budgetSpent + variableAhead + dueOut,
      day,
      days,
    );
  }

  /// Ordinary expenses that are not part of a recurring series.
  double _variable(List<Tx> l) {
    final rec = {for (final r in recurring.where((r) => !r.income)) _norm(r.note)};
    return l.where((t) => t.type == TxType.expense && !rec.contains(_norm(t.note))).fold(0.0, (a, t) => a + t.amount);
  }

  // ---------------------------------------------------------------------------
  // Advice
  // ---------------------------------------------------------------------------

  /// Average monthly totals per [AppState.flowKey] over the 3 months before [month].
  Map<String, double> _avgByGroup(String month, {required bool expenses}) {
    final tot = <String, double>{};
    var n = 0;
    for (var k = 1; k <= 3; k++) {
      final l = s.monthTxs(shiftMonth(month, -k));
      if (l.isEmpty) continue;
      n++;
      for (final t in l) {
        final f = s.flow(t);
        if (expenses ? f < 0 : f > 0) tot[s.flowKey(t)] = (tot[s.flowKey(t)] ?? 0) + f.abs();
      }
    }
    return n == 0 ? {} : tot.map((k, v) => MapEntry(k, v / n));
  }

  double avgIncome(String month) => _avgByGroup(month, expenses: false).values.fold(0.0, (a, b) => a + b);

  List<Insight> advice(String month, String Function(double) money) {
    final out = <Insight>[];
    final now = DateTime.now();
    final current = month == monthKey(now);
    final first = parseIso('$month-01');
    final days = DateTime(first.year, first.month + 1, 0).day;
    final elapsed = current ? now.day : days;
    if (current && elapsed < 5) return out; // too early to say anything useful
    final scale = days / elapsed; // project the current month to a full month

    final avg = _avgByGroup(month, expenses: true);
    if (avg.isEmpty) return out;
    final cur = <String, double>{};
    for (final t in s.monthTxs(month)) {
      final f = s.flow(t);
      if (f < 0) cur[s.flowKey(t)] = (cur[s.flowKey(t)] ?? 0) + -f;
    }
    final income = max(avgIncome(month), 1.0);
    for (final key in {...avg.keys, ...cur.keys}) {
      if (key == 'save' || key == 'debt') continue;
      final a = avg[key] ?? 0, c = (cur[key] ?? 0) * scale;
      final diff = c - a;
      if (a <= 0 || diff.abs() < max(2000, income * 0.03)) continue;
      final pct = (diff / a * 100).round();
      final g = s.group(key);
      final verb = current ? 'à ce rythme, tu finirais le mois à' : 'soit';
      if (pct >= 20) {
        out.add(
          Insight(
            Tone.warn,
            g.icon,
            '+$pct % en ${g.name}',
            '${money(cur[key] ?? 0)} dépensés, $verb ${money(c)} contre ${money(a)} en moyenne.',
            cat: key,
            weight: diff,
          ),
        );
      } else if (pct <= -20) {
        out.add(
          Insight(
            Tone.good,
            g.icon,
            '$pct % en ${g.name}',
            'Bien joué : ${money(a - c)} de moins que ta moyenne${current ? ' si tu gardes ce rythme' : ''}.',
            cat: key,
            weight: -diff * 0.8,
          ),
        );
      }
    }
    // Savings habit.
    final saved = s.monthTxs(month).where((t) => t.type == TxType.save).fold(0.0, (a, t) => a - t.dir * t.amount);
    final avgSaved = avg['save'] ?? 0;
    if (s.goals.isNotEmpty && saved <= 0 && avgSaved > 0 && current && now.day >= 10) {
      out.add(
        Insight(
          Tone.info,
          'piggy-bank',
          'Pas encore d\'épargne ce mois-ci',
          "D'habitude tu mets ${money(avgSaved)} de côté par mois.",
          cat: 'save',
          weight: avgSaved,
        ),
      );
    }
    out.sort((a, b) => b.weight.compareTo(a.weight));
    return out.take(4).toList();
  }

  // ---------------------------------------------------------------------------
  // Budget presets
  // ---------------------------------------------------------------------------

  static const needs = {'logement', 'factures', 'alim', 'transport', 'sante', 'telephone', 'education', 'famille'};

  /// Proposes a monthly budget, per-category caps and monthly savings per goal
  /// for an [income], following a rule or the user's own past spending.
  Preset preset(Rule rule, double income) {
    final month = monthKey(DateTime.now());
    final avg = _avgByGroup(month, expenses: true)..removeWhere((k, _) => k == 'save' || k == 'debt' || s.catById(k) == null);
    final cats = s.activeCats(false);
    final needIds = cats.where((c) => needs.contains(c.id)).map((c) => c.id).toList();
    final wantIds = cats.where((c) => !needs.contains(c.id)).map((c) => c.id).toList();

    double needPart, wantPart, savePart;
    switch (rule) {
      case Rule.r503020:
        (needPart, wantPart, savePart) = (0.5, 0.3, 0.2);
      case Rule.r702010:
        (needPart, wantPart, savePart) = (0.7, 0.2, 0.1);
      case Rule.history:
        final spent = avg.values.fold(0.0, (a, b) => a + b);
        final sp = income > 0 ? (spent / income).clamp(0.0, 0.95) : 0.8;
        final n = needIds.fold(0.0, (a, id) => a + (avg[id] ?? 0));
        final share = spent > 0 ? n / spent : 0.65;
        (needPart, wantPart, savePart) = (sp * share, sp * (1 - share), 1 - sp);
    }

    // Split each envelope across its categories in proportion to past
    // spending, or evenly without history; round to 500 for readable caps.
    Map<String, double> split(List<String> ids, double envelope) {
      final hist = ids.fold(0.0, (a, id) => a + (avg[id] ?? 0));
      return {for (final id in ids) id: _round(hist > 0 ? envelope * (avg[id] ?? 0) / hist : envelope / max(ids.length, 1))}..removeWhere((_, v) => v <= 0);
    }

    final caps = {...split(needIds, income * needPart), ...split(wantIds, income * wantPart)};
    final budget = caps.values.fold(0.0, (a, b) => a + b);
    final saving = _round(income * savePart);

    // Goals: what each needs per month to arrive on time, scaled to the
    // savings envelope; goals without a deadline share what is left.
    final goals = <String, double>{};
    final now = DateTime.now();
    final open = s.goals.where((g) => g.target <= 0 || s.goalSaved(g) < g.target).toList();
    double need(Goal g) {
      if (g.target <= 0 || g.deadline.isEmpty) return 0;
      final d = parseIso(g.deadline);
      final m = max(1, (d.year - now.year) * 12 + d.month - now.month);
      return max(0, g.target - s.goalSaved(g)) / m;
    }

    final dated = open.where((g) => need(g) > 0).toList();
    final totalNeed = dated.fold(0.0, (a, g) => a + need(g));
    final f = totalNeed > saving && totalNeed > 0 ? saving / totalNeed : 1.0;
    for (final g in dated) {
      goals[g.id] = _round(need(g) * f);
    }
    final rest = saving - goals.values.fold(0.0, (a, b) => a + b);
    final free = open.where((g) => !goals.containsKey(g.id)).toList();
    if (rest > 0 && free.isNotEmpty) {
      for (final g in free) {
        goals[g.id] = _round(rest / free.length);
      }
    }
    return Preset(rule, income, budget, saving, caps, goals);
  }

  static double _round(double v) => (v / 500).round() * 500.0;
}
