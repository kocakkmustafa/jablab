import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

Future<void> settleTestLocalizations(WidgetTester tester) async {
  final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
  final expected = app.locale ?? AppLocalizations.resolve(
    tester.binding.platformDispatcher.locales, testSupportedLocales);
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump();
    for (final element in [...find.byType(Scaffold).evaluate(), ...find.byType(Text).evaluate()]) {
      final resources = Localizations.of<AppLocalizations>(element, AppLocalizations);
      if (resources?.locale == expected) return;
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  }
  throw TestFailure('Packaged localization did not load for $expected');
}
