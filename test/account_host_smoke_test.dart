import 'localization_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/account_bridge.dart';
import 'package:jablab/app/settings_page.dart';
import 'package:motion_account/motion_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SignedOutAccount implements MotionAccountClient {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authChanges => const Stream<AuthState>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('host settings opens Core sign-in and registration screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        localeListResolutionCallback: resolveTestLocales,
        home: SettingsPage(
          onOpenWhyNot: () {},
          excludedCount: 1,
          accountPageBuilder: (_) => MotionAccountPage(
            account: _SignedOutAccount(),
            clearLocalData: clearLocalHistoryFor,
          ),
        ),
      ),
    );
    await settleTestLocalizations(tester);
    expect(
      find.textContaining('Browse lessons without signing in'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Live camera sessions are closed'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(SettingsPage.accountEntryKey));
    await tester.pumpAndSettle();
    expect(find.byType(MotionAccountPage), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    await tester.tap(find.text('Create a new account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);
  });

  for (final locale in ['en', 'tr']) {
    testWidgets('settings explains course and free lessons in $locale', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = <Locale>[Locale(locale)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: testSupportedLocales,
          localizationsDelegates: testLocalizationDelegates,
          localeListResolutionCallback: resolveTestLocales,
          home: SettingsPage(
            onOpenWhyNot: () {},
            excludedCount: 1,
            accountPageBuilder: (_) =>
                const Scaffold(body: Text('Account route')),
          ),
        ),
      );
      await settleTestLocalizations(tester);
      expect(
        find.textContaining(
          locale == 'tr'
              ? 'Ücretsiz dersleri hesap veya kamera olmadan'
              : 'Practise the free lessons without an account or camera',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          locale == 'tr'
              ? 'canlı kamera seansları kapalıdır'
              : 'Live camera sessions are closed',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          locale == 'tr'
              ? 'Her kursun ilk dersleri ücretsizdir'
              : 'The first lessons of every course are free',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('requires a Motion account'), findsNothing);
      expect(
        find.textContaining('prices appear in Motion account'),
        findsNothing,
      );
      await tester.ensureVisible(find.byKey(SettingsPage.accountEntryKey));
      await tester.tap(find.byKey(SettingsPage.accountEntryKey));
      await tester.pumpAndSettle();
      expect(find.text('Account route'), findsOneWidget);
    });
  }
}
