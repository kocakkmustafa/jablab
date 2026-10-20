import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/main.dart';

import 'localization_fixture.dart';

void main() {
  testWidgets(
    'missing account configuration mounts a failure root before localization',
    (WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await launchJabLab(url: '', publishableKey: '');
      await tester.pump();

      // The failure root must mount on the first pump, before asset readiness.
      expect(find.byType(JabLabAccountStartupFailure), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleTestLocalizations(tester, expectedLocale: const Locale('en'));
      expect(
        find.byKey(const Key('jablab.accountStartupFailure')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Invalid Motion account configuration'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final String language in <String>['en', 'tr']) {
    testWidgets(
      'invalid account configuration renders translated failure message in $language',
      (WidgetTester tester) async {
        tester.platformDispatcher.localesTestValue = [Locale(language)];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await launchJabLab(url: 'invalid', publishableKey: 'test-key');
        await tester.pump();

        expect(find.byType(JabLabAccountStartupFailure), findsOneWidget);
        expect(tester.takeException(), isNull);
        await settleTestLocalizations(tester, expectedLocale: Locale(language));
        expect(
          find.textContaining(
            language == 'tr'
                ? 'hesap hizmeti bu sürümde başlatılamadı'
                : 'account service could not start in this build',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
