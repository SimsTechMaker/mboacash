import 'package:intl/intl.dart';

import 'i18n.dart';
import 'models.dart';

const _symbols = {'XAF': 'FCFA', 'XOF': 'FCFA', 'EUR': '€', 'USD': r'$', 'NGN': '₦', 'GHS': 'GH₵', 'MAD': 'MAD', 'GNF': 'GNF'};
const _zeroDecimals = {'XAF', 'XOF', 'GNF'};

class Fmt {
  final String currency;
  final NumberFormat _n;
  Fmt(this.currency) : _n = NumberFormat.decimalPatternDigits(locale: intlLocale, decimalDigits: _zeroDecimals.contains(currency) ? 0 : 2);

  String get symbol => _symbols[currency] ?? currency;

  /// "12 500 FCFA", "−3 000 FCFA", or with [signed] "+12 500 FCFA".
  String money(double v, {bool signed = false}) {
    final s = '${_n.format(v.abs())} $symbol';
    if (v < 0) return '−$s';
    return signed && v > 0 ? '+$s' : s; // no "+0"
  }

  /// Same but with plain spaces and ASCII minus, for PDF and CSV.
  String plain(double v, {bool signed = false}) => money(v, signed: signed).replaceAll(' ', ' ').replaceAll(' ', ' ').replaceAll('−', '-');

  String number(double v) => NumberFormat.decimalPatternDigits(
    locale: intlLocale,
    decimalDigits: _zeroDecimals.contains(currency) ? 0 : 2,
  ).format(v).replaceAll(' ', ' ').replaceAll(' ', ' ');

  String compact(double v) => NumberFormat.compact(locale: intlLocale).format(v);
}

/// Accepts "12 500", "12500,50", "12.5", and in English "12,500.50".
double? parseAmount(String s) {
  var t = s.replaceAll(RegExp(r'[\s  ]'), '');
  // With both separators, the last one is the decimal point.
  if (t.contains(',') && t.contains('.')) {
    t = t.lastIndexOf(',') > t.lastIndexOf('.') ? t.replaceAll('.', '') : t.replaceAll(',', '');
  } else if (lang == 'en' && RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(t)) {
    t = t.replaceAll(',', ''); // "12,500" groups thousands in English
  }
  t = t.replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String monthLabel(String key, {bool year = true}) => _cap((year ? DateFormat.yMMMM(intlLocale) : DateFormat.MMMM(intlLocale)).format(parseIso('$key-01')));

String shortMonth(String key) => DateFormat.MMM(intlLocale).format(parseIso('$key-01'));
String longDate(String iso) => DateFormat.yMMMMd(intlLocale).format(parseIso(iso));
String dayLabel(String iso) => _cap(DateFormat.MMMMEEEEd(intlLocale).format(parseIso(iso)));

String slashDate(String iso) => DateFormat('dd/MM/yyyy').format(parseIso(iso));
