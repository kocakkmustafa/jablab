import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/settings_page.dart';

void main() {
  testWidgets('Turkish device locale shows account status without a dead action',
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());

    await tester.pumpWidget(MaterialApp(
      home: SettingsPage(onOpenWhyNot: () {}, excludedCount: 1),
    ));

    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.textContaining('Hesap girişi bağlı değil'), findsOneWidget);
    expect(find.text('Giriş yap'), findsNothing);
  });
}
