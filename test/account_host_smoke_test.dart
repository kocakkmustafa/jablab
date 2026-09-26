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
    expect(
      find.textContaining('Browse lessons without signing in'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Live camera sessions and subscription sales are closed',
      ),
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
    testWidgets('settings explains course and closed sales in $locale', (
      tester,
    ) async {
      tester.platformDispatcher.localeTestValue = Locale(locale);
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            onOpenWhyNot: () {},
            excludedCount: 1,
            accountPageBuilder: (_) =>
                const Scaffold(body: Text('Account route')),
          ),
        ),
      );
      expect(
        find.textContaining(
          locale == 'tr'
              ? 'Solo boks kursunu hesap veya kamera olmadan'
              : 'Practise the solo boxing course without an account or camera',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          locale == 'tr'
              ? 'canlı kamera seansları ve abonelik satışı kapalıdır'
              : 'Live camera sessions and subscription sales are closed',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          locale == 'tr'
              ? 'Kurs için satın alma gerekmez'
              : 'No purchase is needed for the course',
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
