import 'package:intl/intl.dart';

import 'models.dart';

const _symbols = {'XAF': 'FCFA', 'XOF': 'FCFA', 'EUR': '€', 'USD': r'$', 'NGN': '₦', 'GHS': 'GH₵', 'MAD': 'MAD', 'GNF': 'GNF'};
const _zeroDecimals = {'XAF', 'XOF', 'GNF'};

class Fmt {
  final String currency;
  final NumberFormat _n;
  Fmt(this.currency) : _n = NumberFormat.decimalPatternDigits(locale: 'fr_FR', decimalDigits: _zeroDecimals.contains(currency) ? 0 : 2);

  String get symbol => _symbols[currency] ?? currency;

  /// "12 500 FCFA", "−3 000 FCFA", or with [signed] "+12 500 FCFA".
  String money(double v, {bool signed = false}) {
    final s = '${_n.format(v.abs())} $symbol';
    if (v < 0) return '−$s';
    return signed ? '+$s' : s;
  }

  /// Same but with plain spaces and ASCII minus, for PDF and CSV.
  String plain(double v, {bool signed = false}) => money(v, signed: signed).replaceAll(' ', ' ').replaceAll(' ', ' ').replaceAll('−', '-');

  String number(double v) => NumberFormat.decimalPatternDigits(
    locale: 'fr_FR',
    decimalDigits: _zeroDecimals.contains(currency) ? 0 : 2,
  ).format(v).replaceAll(' ', ' ').replaceAll(' ', ' ');

  String compact(double v) => NumberFormat.compact(locale: 'fr_FR').format(v);
}

/// Accepts "12 500", "12500,50", "12.5".
double? parseAmount(String s) {
  final t = s.replaceAll(RegExp(r'[\s  ]'), '').replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

String monthLabel(String key, {bool year = true}) {
  final s = DateFormat(year ? 'MMMM yyyy' : 'MMMM', 'fr_FR').format(parseIso('$key-01'));
  return s[0].toUpperCase() + s.substring(1);
}

String shortMonth(String key) => DateFormat('MMM', 'fr_FR').format(parseIso('$key-01'));
String longDate(String iso) => DateFormat('d MMMM yyyy', 'fr_FR').format(parseIso(iso));
String dayLabel(String iso) {
  final s = DateFormat('EEEE d MMMM', 'fr_FR').format(parseIso(iso));
  return s[0].toUpperCase() + s.substring(1);
}

String slashDate(String iso) => DateFormat('dd/MM/yyyy').format(parseIso(iso));
String plural(int n, String w) => '$n $w${n > 1 ? 's' : ''}';
