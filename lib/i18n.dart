import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';

export 'l10n/app_localizations.dart';

/// Languages the app ships (lib/l10n/app_*.arb). French is the template.
const supportedLangs = ['fr', 'en'];

/// Strings for code that has no BuildContext (services, PDF, CSV,
/// notifications). Widgets use `context.l` so they rebuild on a change.
AppLocalizations tr = lookupAppLocalizations(const Locale('fr'));

/// The active language code: 'fr' or 'en'.
String get lang => tr.localeName;

/// The intl locale for dates and numbers (British English: day before month).
String get intlLocale => lang == 'fr' ? 'fr_FR' : 'en_GB';

extension L10nContext on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
}

/// 'auto' follows the phone: French when it is in French, English otherwise.
String resolveLang(String setting) {
  if (supportedLangs.contains(setting)) return setting;
  final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return sys == 'fr' ? 'fr' : 'en';
}

void useLang(String code) {
  tr = lookupAppLocalizations(Locale(code));
  Intl.defaultLocale = intlLocale;
}
