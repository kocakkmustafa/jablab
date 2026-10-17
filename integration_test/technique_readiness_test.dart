import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/kickboxing_course_page.dart';
import 'package:jablab/app/technique_capability_panel.dart';

/// Native Flutter lesson UI only. No camera, account, inference, filesystem
/// progress or physical technique acceptance. Uses actual bundled course bytes.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final language in ['tr', 'en']) {
    testWidgets(
      'native kb-12 $language readiness leaves measurement and progress unavailable',
      (tester) async {
        tester.platformDispatcher.localeTestValue = Locale(language);
        addTearDown(tester.platformDispatcher.clearLocaleTestValue);
        final course = await const ContentRepository().loadKickboxingCourse();
        var reports = 0;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: KickboxingLessonPage(
              course: course,
              lesson: course.lessons[11],
              admitted: () => true,
              priorWritten: () => false,
              onWritten: () {
                reports++;
              },
              onInvalidate: () {},
              onReset: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('technique-capability-panel')),
          250,
          maxScrolls: 30,
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            language == 'tr' ? 'Kalibrasyon gerekli' : 'Calibration required',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('technique-task-phases')), findsOneWidget);
        expect(
          find.textContaining(
            language == 'tr'
                ? 'Burada hareket ölçülmedi.'
                : 'No movement has been measured here.',
          ),
          findsOneWidget,
        );
        expect(reports, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('native unsupported branch cannot expose a measurement control', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TechniqueCapabilityPanel(
            courseId: 'jablab.karate_a',
            lessonId: 'kb-12',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('technique-task-phases')), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
