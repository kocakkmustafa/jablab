import 'localization_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/shell_candidate/live_surface.dart';
import 'package:jablab/shell_candidate/session_flow.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localesTestValue = <Locale>[const Locale('tr')];
  });
  tearDown(() => TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .clearLocalesTestValue());

  testWidgets('session steps and advance control use Turkish',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
      home: SessionFlowScaffold(
        title: 'Test',
        stage: SessionStage.teach,
        onAdvance: () {},
        child: const SizedBox(),
      ),
    ));
    await settleTestLocalizations(tester);
    expect(find.text('Öğren'), findsOneWidget);
    expect(find.text('Dene'), findsOneWidget);
    expect(find.text('Canlı'), findsOneWidget);
    expect(find.text('Özet'), findsOneWidget);
    expect(find.text('Devam et'), findsOneWidget);
  });

  testWidgets('unknown camera measurement stays unknown in Turkish',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
      home: Scaffold(
        body: LiveCoachSurface(
          state: LiveState.noVerdict,
          eventCount: null,
        ),
      ),
    ));
    await settleTestLocalizations(tester);
    expect(find.text('Değerlendirmek için sizi yeterince iyi göremiyorum'),
        findsOneWidget);
    expect(find.byKey(const Key('event-count')), findsNothing);
  });
}
