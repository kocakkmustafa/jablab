import 'localization_fixture.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/kickboxing_course.dart';
import 'package:jablab/app/kickboxing_course_page.dart';
import 'package:jablab/app/technique_capability_panel.dart';

void main() {
  for (final language in ['tr', 'en']) {
    testWidgets(
      'kb-12 $language has calibration/phase state with no measurement or completion',
      (t) async {
        t.platformDispatcher.localesTestValue = <Locale>[Locale(language)];
        addTearDown(t.platformDispatcher.clearLocalesTestValue);
        await t.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final course = KickboxingCourse.fromJsonString(
          File('assets/content/kickboxing_a.v1.json').readAsStringSync(),
        );
        var reports = 0;
        await t.pumpWidget(
          MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
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
    await settleTestLocalizations(t);
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.byKey(const Key('technique-capability-panel')),
          200,
          maxScrolls: 30,
        );
        await t.pumpAndSettle();
        expect(
          find.byKey(const Key('technique-capability-panel')),
          findsOneWidget,
        );
        expect(
          find.text(
            language == 'tr' ? 'Kalibrasyon gerekli' : 'Calibration required',
          ),
          findsOneWidget,
        );
        final phases = t
            .widget<Text>(find.byKey(const Key('technique-task-phases')))
            .data!;
        expect(
          phases,
          contains(language == 'tr' ? 'Geri toplama' : 'Retraction'),
        );
        expect(
          find.textContaining(
            language == 'tr'
                ? 'Burada hareket ölçülmedi.'
                : 'No movement has been measured here.',
          ),
          findsOneWidget,
        );
        expect(reports, 0);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('unknown lesson panel is unsupported and cannot enable capture', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
        home: Scaffold(
          body: TechniqueCapabilityPanel(
            courseId: 'jablab.karate_a',
            lessonId: 'kb-12',
          ),
        ),
      ),
    );
    await settleTestLocalizations(t);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('technique-task-phases')), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.textContaining('not supported'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
