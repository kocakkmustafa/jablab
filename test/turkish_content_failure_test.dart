import 'localization_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_failure.dart';
import 'package:jablab/app/content_failure_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localeTestValue = const Locale('tr');
  });
  tearDown(() => TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .clearLocaleTestValue());

  testWidgets('integrity failure explains responsibility without retry',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
      home: ContentFailureScreen(
        failure: ContentFailure(
          kind: ContentFailureKind.integrity,
          detail: 'bad lesson',
        ),
      ),
    ));
    expect(find.text('İçeriği durdurduk'), findsOneWidget);
    expect(find.textContaining('Sorun cihazınızda değil'), findsOneWidget);
    expect(find.byKey(const Key('failure-retry')), findsNothing);
  });

  testWidgets('unreadable content offers Turkish retry',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
      home: ContentFailureScreen(
        failure: const ContentFailure(
          kind: ContentFailureKind.unreadable,
          detail: 'asset missing',
        ),
        onRetry: () async {},
      ),
    ));
    expect(find.text('Uygulama içeriği okunamadı'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.text('Teknik ayrıntı'), findsOneWidget);
  });
}
