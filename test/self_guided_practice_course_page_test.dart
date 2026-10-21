import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/kickboxing_course.dart';
import 'package:jablab/app/kickboxing_course_page.dart';
import 'package:jablab/app/muay_thai_course.dart';
import 'package:jablab/app/muay_thai_course_page.dart';
import 'package:jablab/app/self_guided_practice.dart';
import 'package:jablab/app/self_guided_practice_panel.dart';

import 'localization_fixture.dart';
import 'self_guided_practice_test.dart' show practiceFixture;

Object courseFixture(String name, {bool pending = false}) {
  final map =
      jsonDecode(File('assets/content/${name}_a.v1.json').readAsStringSync())
          as Map<String, dynamic>;
  for (final dynamic lesson in (map['lessons'] as List<dynamic>).take(2)) {
    lesson['selfGuidedPractice'] = practiceFixture(
      lessonId: lesson['id'] as String,
      sourceIds: (lesson['sourceIds'] as List<dynamic>).cast<String>(),
      mode: 'small_range_non_contact',
      review: pending ? 'pending' : 'video_review',
      receipt: pending ? null : 'SYNTHETIC_WIDGET_ONLY_NOT_RELEASE_EVIDENCE',
    );
  }
  return name == 'kickboxing'
      ? KickboxingCourse.fromJsonString(jsonEncode(map))
      : MuayThaiCourse.fromJsonString(jsonEncode(map));
}

Widget lessonPage(
  String name,
  Object source,
  int index, {
  required bool Function() admitted,
  required VoidCallback onWritten,
  required VoidCallback onReset,
}) {
  if (name == 'kickboxing') {
    final course = source as KickboxingCourse;
    return KickboxingLessonPage(
      key: const ValueKey('same-lesson-state'),
      lesson: course.lessons[index],
      course: course,
      admitted: admitted,
      priorWritten: () => true,
      onWritten: onWritten,
      onInvalidate: () {},
      onReset: onReset,
    );
  }
  final course = source as MuayThaiCourse;
  return MuayThaiLessonPage(
    key: const ValueKey('same-lesson-state'),
    lesson: course.lessons[index],
    course: course,
    admitted: admitted,
    priorWritten: () => true,
    onWritten: onWritten,
    onInvalidate: () {},
    onReset: onReset,
  );
}

Widget app(Widget child, String language) => MaterialApp(
  locale: Locale(language),
  supportedLocales: testSupportedLocales,
  localizationsDelegates: testLocalizationDelegates,
  localeListResolutionCallback: resolveTestLocales,
  home: child,
);

Future<void> show(WidgetTester t, String key) async {
  final target = find.byKey(Key(key));
  t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
  await t.pump();
  await t.scrollUntilVisible(
    target,
    400,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 100,
  );
  await t.ensureVisible(target);
  await t.pumpAndSettle();
}

Future<void> tap(WidgetTester t, String key) async {
  await show(t, key);
  await t.tap(find.byKey(Key(key)).hitTestable());
  await t.pumpAndSettle();
}

Future<void> prepareWritten(WidgetTester t, String slug) async {
  await show(t, '$slug-own-answer');
  await t.enterText(
    find.byKey(Key('$slug-own-answer')),
    'My independent answer with uncertainty.',
  );
  t.testTextInput.hide();
  await t.pumpAndSettle();
  await tap(t, '$slug-reveal-answer');
  await show(t, '$slug-own-correction');
  await t.enterText(
    find.byKey(Key('$slug-own-correction')),
    'My one correction; technique remains unverified.',
  );
  t.testTextInput.hide();
  await t.pumpAndSettle();
  await tap(t, '$slug-compared');
}

Future<void> reportWritten(WidgetTester t, String slug) async {
  await prepareWritten(t, slug);
  await tap(t, '$slug-report-written');
}

void main() {
  for (final name in ['kickboxing', 'muay_thai']) {
    final slug = name.replaceAll('_', '-');
    for (final language in ['tr', 'en']) {
      testWidgets(
        'practice reports cannot bypass real written flow ($name/$language)',
        (t) async {
          final source = courseFixture(name);
          var written = 0;
          await t.pumpWidget(
            app(
              lessonPage(
                name,
                source,
                0,
                admitted: () => true,
                onWritten: () {
                  written++;
                },
                onReset: () {},
              ),
              language,
            ),
          );
          await settleTestLocalizations(t);
          await tap(t, 'self-guided-attempt-attempted');
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.attempted,
          );
          await show(t, '$slug-report-written');
          expect(
            t
                .widget<TextButton>(find.byKey(Key('$slug-report-written')))
                .onPressed,
            isNull,
          );
          expect(written, 0);
          await reportWritten(t, slug);
          expect(written, 1);
          await show(t, 'self-guided-practice-panel');
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.attempted,
          );
        },
      );

      testWidgets(
        'reset, admission retirement and disposal reject the actual old panel callback ($name/$language)',
        (t) async {
          final source = courseFixture(name);
          var admitted = true;
          var resets = 0;
          await t.pumpWidget(
            app(
              lessonPage(
                name,
                source,
                0,
                admitted: () => admitted,
                onWritten: () {},
                onReset: () {
                  resets++;
                },
              ),
              language,
            ),
          );
          await settleTestLocalizations(t);
          await tap(t, 'self-guided-attempt-attempted');
          final old = t.widget<SelfGuidedPracticePanel>(
            find.byType(SelfGuidedPracticePanel),
          );
          await t.tap(find.byKey(Key('$slug-stop-top')));
          await t.pumpAndSettle();
          expect(resets, 1);
          old.onChanged(PracticeAttempt.attempted);
          await t.pump();
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.unrecorded,
          );
          final afterReset = t.widget<SelfGuidedPracticePanel>(
            find.byType(SelfGuidedPracticePanel),
          );
          admitted = false;
          afterReset.onChanged(PracticeAttempt.uncertain);
          await t.pump();
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.unrecorded,
          );
          admitted =
              true; // Ensure disposal is guarded even when admission stays true.
          await t.pumpWidget(const SizedBox.shrink());
          old.onChanged(PracticeAttempt.attempted);
          afterReset.onChanged(PracticeAttempt.attempted);
          expect(t.takeException(), isNull);
        },
      );

      testWidgets(
        'same State lesson replacement clears written draft and rejects old practice callback ($name/$language)',
        (t) async {
          final source = courseFixture(name);
          var written = 0;
          Widget build(int index) => app(
            lessonPage(
              name,
              source,
              index,
              admitted: () => true,
              onWritten: () {
                written++;
              },
              onReset: () {},
            ),
            language,
          );
          await t.pumpWidget(build(0));
          await settleTestLocalizations(t);
          await reportWritten(t, slug);
          expect(written, 1);
          await show(t, 'self-guided-practice-panel');
          final old = t.widget<SelfGuidedPracticePanel>(
            find.byType(SelfGuidedPracticePanel),
          );
          await t.pumpWidget(build(1));
          await t.pumpAndSettle();
          old.onChanged(PracticeAttempt.attempted);
          await t.pump();
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.unrecorded,
          );
          await show(t, '$slug-own-answer');
          expect(
            t
                .widget<TextField>(find.byKey(Key('$slug-own-answer')))
                .controller!
                .text,
            isEmpty,
          );
          expect(find.byKey(Key('$slug-answer')), findsNothing);
          await show(t, '$slug-report-written');
          expect(
            t
                .widget<TextButton>(find.byKey(Key('$slug-report-written')))
                .onPressed,
            isNull,
          );
          expect(written, 1);
        },
      );

      testWidgets(
        'stopped and uncertain end this visit and reject pre-stop practice callbacks ($name/$language)',
        (t) async {
          for (final terminal in [
            PracticeAttempt.stopped,
            PracticeAttempt.uncertain,
          ]) {
            await t.pumpWidget(const SizedBox.shrink());
            final source = courseFixture(name);
            var written = 0;
            await t.pumpWidget(
              app(
                lessonPage(
                  name,
                  source,
                  0,
                  admitted: () => true,
                  onWritten: () {
                    written++;
                  },
                  onReset: () {},
                ),
                language,
              ),
            );
            await settleTestLocalizations(t);
            await show(t, 'self-guided-practice-panel');
            final old = t.widget<SelfGuidedPracticePanel>(
              find.byType(SelfGuidedPracticePanel),
            );
            await tap(t, 'self-guided-attempt-${terminal.name}');
            old.onChanged(PracticeAttempt.attempted);
            await t.pump();
            expect(
              t
                  .widget<SelfGuidedPracticePanel>(
                    find.byType(SelfGuidedPracticePanel),
                  )
                  .attempt,
              terminal,
            );
            expect(find.byKey(const Key('self-guided-ended')), findsOneWidget);
            expect(
              t
                  .widget<RadioListTile<PracticeAttempt>>(
                    find.byKey(const Key('self-guided-attempt-attempted')),
                  )
                  .enabled,
              isFalse,
            );
            expect(written, 0);
          }
        },
      );

      testWidgets(
        'hiding and reopening reading rejects the old practice callback ($name/$language)',
        (t) async {
          final source = courseFixture(name);
          var written = 0;
          await t.pumpWidget(
            app(
              lessonPage(
                name,
                source,
                0,
                admitted: () => true,
                onWritten: () {
                  written++;
                },
                onReset: () {},
              ),
              language,
            ),
          );
          await settleTestLocalizations(t);
          await show(t, 'self-guided-practice-panel');
          final old = t.widget<SelfGuidedPracticePanel>(
            find.byType(SelfGuidedPracticePanel),
          );
          await tap(t, '$slug-toggle-reading');
          old.onChanged(PracticeAttempt.attempted);
          await t.pump();
          expect(find.byType(SelfGuidedPracticePanel), findsNothing);
          await tap(t, '$slug-toggle-reading');
          await show(t, 'self-guided-practice-panel');
          old.onChanged(PracticeAttempt.attempted);
          await t.pump();
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.unrecorded,
          );
          final fresh = t.widget<SelfGuidedPracticePanel>(
            find.byType(SelfGuidedPracticePanel),
          );
          fresh.onChanged(PracticeAttempt.attempted);
          await t.pump();
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.attempted,
          );
          expect(written, 0);
        },
      );

      testWidgets(
        'pause rejects old practice and enabled written callbacks, including fresh inactive builds ($name/$language)',
        (t) async {
          addTearDown(() {
            t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          });
          final source = courseFixture(name);
          var written = 0;
          await t.pumpWidget(
            app(
              lessonPage(
                name,
                source,
                0,
                admitted: () => true,
                onWritten: () {
                  written++;
                },
                onReset: () {},
              ),
              language,
            ),
          );
          await settleTestLocalizations(t);
          await prepareWritten(t, slug);
          await show(t, '$slug-report-written');
          final oldWritten = t
              .widget<TextButton>(find.byKey(Key('$slug-report-written')))
              .onPressed!;
          await show(t, 'self-guided-practice-panel');
          final oldPractice = t.widget<SelfGuidedPracticePanel>(
            find.byType(SelfGuidedPracticePanel),
          );
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
          await t.pump();
          oldWritten();
          oldPractice.onChanged(PracticeAttempt.attempted);
          final whileInactive = t.widget<SelfGuidedPracticePanel>(
            find.byType(SelfGuidedPracticePanel),
          );
          whileInactive.onChanged(PracticeAttempt.attempted);
          await t.pump();
          expect(written, 0);
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.unrecorded,
          );
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          await t.pump();
          whileInactive.onChanged(PracticeAttempt.attempted);
          oldWritten();
          await t.pump();
          expect(written, 0);
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.unrecorded,
          );
          final fresh = t.widget<SelfGuidedPracticePanel>(
            find.byType(SelfGuidedPracticePanel),
          );
          fresh.onChanged(PracticeAttempt.attempted);
          await t.pump();
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.attempted,
          );
          expect(written, 0);
        },
      );

      testWidgets(
        'actual pending panel parent callback cannot report an attempt ($name/$language)',
        (t) async {
          final source = courseFixture(name, pending: true);
          var written = 0;
          await t.pumpWidget(
            app(
              lessonPage(
                name,
                source,
                0,
                admitted: () => true,
                onWritten: () {
                  written++;
                },
                onReset: () {},
              ),
              language,
            ),
          );
          await settleTestLocalizations(t);
          await show(t, 'self-guided-practice-panel');
          final pending = t.widget<SelfGuidedPracticePanel>(
            find.byType(SelfGuidedPracticePanel),
          );
          pending.onChanged(PracticeAttempt.attempted);
          await t.pump();
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.unrecorded,
          );
          pending.onChanged(PracticeAttempt.skipped);
          await t.pump();
          expect(
            t
                .widget<SelfGuidedPracticePanel>(
                  find.byType(SelfGuidedPracticePanel),
                )
                .attempt,
            PracticeAttempt.skipped,
          );
          expect(written, 0);
        },
      );
    }
  }
}
