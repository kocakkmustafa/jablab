import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:motion_account/motion_account.dart';
import 'package:jablab/app/ui_language.dart';

// Isolated routes use the production locale resolver and real packaged copy.
const testSupportedLocales = AppLocalizations.supportedLocales;
const testLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  MotionAccountLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
Locale resolveTestLocales(
  List<Locale>? preferred,
  Iterable<Locale> supported,
) => AppLocalizations.resolve(preferred, supported);

Future<void> settleTestLocalizations(
  WidgetTester tester, {
  Locale? expectedLocale,
}) async {
  final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
  final expected =
      expectedLocale ??
      app.locale ??
      AppLocalizations.resolve(
        tester.binding.platformDispatcher.locales,
        testSupportedLocales,
      );
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(() => tester.pump());
    for (final element in [
      ...find.byType(Scaffold).evaluate(),
      ...find.byType(Text).evaluate(),
      ...find.byType(Builder).evaluate(),
    ]) {
      final resources = Localizations.of<AppLocalizations>(
        element,
        AppLocalizations,
      );
      if (resources != null && resources.locale == expected) {
        expect(Localizations.localeOf(element), expected);
        expect(resources.loadFailed, isFalse);
        expect(resources.complete, isTrue);
        return;
      }
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
  }
  throw TestFailure('Packaged localization did not load for $expected');
}

// WidgetTester.pageBack searches the English Back tooltip. Tap the real
// Material back control so translated tooltips do not change the UI action.
Future<void> tapTestMaterialBack(WidgetTester tester) async {
  final back = find.byType(BackButton).hitTestable();
  expect(back, findsOneWidget, reason: 'One reachable Material back control');
  await tester.tap(back);
  await tester.pumpAndSettle();
}
