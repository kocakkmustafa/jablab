import 'localization_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/settings_page.dart';

void main() {
  testWidgets('Turkish device locale shows account status without a dead action',
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.localesTestValue = <Locale>[const Locale('tr')];
    addTearDown(() => tester.binding.platformDispatcher.clearLocalesTestValue());

    await tester.pumpWidget(MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
      home: SettingsPage(onOpenWhyNot: () {}, excludedCount: 1),
    ));
    await settleTestLocalizations(tester);

    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.textContaining('Hesap girişi bağlı değil'), findsOneWidget);
    expect(find.text('Giriş yap'), findsNothing);
  });
}
