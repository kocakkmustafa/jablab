import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/main.dart';

void main() {
  testWidgets('missing account configuration shows a bounded first frame', (
    WidgetTester tester,
  ) async {
    await launchJabLab(url: '', publishableKey: '');
    await tester.pump();

    expect(find.byType(JabLabAccountStartupFailure), findsOneWidget);
    expect(
      find.byKey(const Key('jablab.accountStartupFailure')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Invalid Motion account configuration'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final String language in <String>['en', 'tr']) {
    testWidgets('invalid account configuration stays readable in $language', (
      WidgetTester tester,
    ) async {
      tester.binding.platformDispatcher.localeTestValue = Locale(language);
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

      await launchJabLab(url: 'invalid', publishableKey: 'test-key');
      await tester.pump();

      expect(find.byType(JabLabAccountStartupFailure), findsOneWidget);
      expect(
        find.textContaining(
          language == 'tr'
              ? 'hesap hizmeti bu sürümde başlatılamadı'
              : 'account service could not start in this build',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
