import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jablab/app/ui_language.dart';

// Isolated routes use the production locale resolver and real packaged copy.
const testSupportedLocales = AppLocalizations.supportedLocales;
const testLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
Locale resolveTestLocales(List<Locale>? preferred, Iterable<Locale> supported) =>
    AppLocalizations.resolve(preferred, supported);
