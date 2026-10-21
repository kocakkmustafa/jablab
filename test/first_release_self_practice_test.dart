import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/karate_course.dart';
import 'package:jablab/app/karate_course_page.dart';
import 'package:jablab/app/self_guided_practice.dart';
import 'package:jablab/app/self_guided_practice_panel.dart';
import 'package:jablab/app/taikyoku_shodan_course.dart';
import 'package:jablab/app/taikyoku_shodan_course_page.dart';

import 'localization_fixture.dart';

// Report-only definition. Run only after the exact asset/model/panel afterimages
// are applied and accepted by the shared SDK coordinator. No test was run here.
Map<String, dynamic> _asset(String name) =>
    (jsonDecode(File('assets/content/$name').readAsStringSync()) as Map)
        .cast<String, dynamic>();

void main() {
  test(
    'all 26 tasks bind to the existing lesson without awarding progress',
    () {
      final karate = KarateCourse.fromJsonString(
        jsonEncode(_asset('karate_a.v1.json')),
      );
      final taikyoku = TaikyokuCourse.fromJsonString(
        jsonEncode(_asset('taikyoku_shodan_jl.v1.json')),
      );
      expect(karate.lessons, hasLength(16));
      expect(taikyoku.lessons, hasLength(10));
      expect(karate.physicalTechniqueValidated, isFalse);
      expect(taikyoku.physicalTechniqueValidated, isFalse);
      expect(karate.physicalPracticeAvailable, isFalse);
      expect(taikyoku.physicalPracticeAvailable, isFalse);
      for (final lesson in karate.lessons) {
        expect(lesson.selfPractice.lessonId, lesson.id);
        expect(
          lesson.selfPractice.sourceIds.every(lesson.sourceIds.contains),
          isTrue,
        );
      }
      for (final lesson in taikyoku.lessons) {
        expect(lesson.selfPractice.lessonId, lesson.id);
        expect(
          lesson.selfPractice.sourceIds.every(
            taikyoku.sources.map((source) => source.id).contains,
          ),
          isTrue,
        );
      }
      for (final practice in [
        ...karate.lessons.map((lesson) => lesson.selfPractice),
        ...taikyoku.lessons.map((lesson) => lesson.selfPractice),
      ]) {
        expect(practice.progressEffect, 0);
        expect(practice.verifiedTechnique, isFalse);
        for (final copy in [
          practice.task,
          practice.observe,
          practice.safety,
          practice.adaptation,
        ]) {
          expect(copy.en.trim(), isNotEmpty);
          expect(copy.tr.trim(), isNotEmpty);
        }
      }
    },
  );

  test('Karate rejects a task borrowed from another lesson or source', () {
    for (final key in ['lessonId', 'sourceIds']) {
      final json = _asset('karate_a.v1.json');
      final practice = json['lessons'][3]['selfPractice'] as Map;
      practice[key] = key == 'lessonId' ? 'ka-06' : ['not-a-course-source'];
      expect(
        () => KarateCourse.fromJsonString(jsonEncode(json)),
        throwsFormatException,
      );
    }
  });

  test('Taikyoku rejects a task borrowed from another lesson or recording', () {
    for (final key in ['lessonId', 'sourceIds']) {
      final json = _asset('taikyoku_shodan_jl.v1.json');
      final practice = json['content']['lessons'][3]['selfPractice'] as Map;
      practice[key] = key == 'lessonId' ? 'ts-09' : ['not-recording-A-or-B'];
      expect(
        () => TaikyokuCourse.fromJsonString(jsonEncode(json)),
        throwsFormatException,
      );
    }
  });

  test(
    'tasks cannot award progress or claim video review without a receipt',
    () {
      for (final courseName in [
        'karate_a.v1.json',
        'taikyoku_shodan_jl.v1.json',
      ]) {
        for (final invalid in ['progress', 'receipt', 'extra', 'missing']) {
          final json = _asset(courseName);
          final lessons = courseName.startsWith('karate')
              ? json['lessons']
              : json['content']['lessons'];
          final practice = lessons[3]['selfPractice'] as Map;
          if (invalid == 'progress') {
            practice['progressEffect'] = 1;
          } else if (invalid == 'receipt') {
            practice['sourceReview'] = 'video_review';
            practice['sourceReviewReceiptId'] = null;
          } else if (invalid == 'extra') {
            practice['masteryScore'] = 100;
          } else {
            practice.remove('safety');
          }
          expect(
            () => courseName.startsWith('karate')
                ? KarateCourse.fromJsonString(jsonEncode(json))
                : TaikyokuCourse.fromJsonString(jsonEncode(json)),
            throwsFormatException,
            reason: '$courseName/$invalid',
          );
        }
      }
    },
  );

  testWidgets(
    'a Karate written-report callback cannot survive Stop into a new comparison',
    (tester) async {
      var reports = 0;
      final course = KarateCourse.fromJsonString(
        jsonEncode(_asset('karate_a.v1.json')),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: testSupportedLocales,
          localizationsDelegates: testLocalizationDelegates,
          localeListResolutionCallback: resolveTestLocales,
          home: KarateLessonPage(
            lesson: course.lessons.first,
            course: course,
            admitted: () => true,
            priorWritten: () => true,
            onWritten: () => reports++,
            onInvalidate: () {},
            onReset: () {},
          ),
        ),
      );
      await settleTestLocalizations(tester, expectedLocale: const Locale('en'));
      await tester.pumpAndSettle();
      Future<Finder> reveal(String key) async {
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pump();
        final finder = find.byKey(Key(key));
        await tester.scrollUntilVisible(
          finder,
          300,
          maxScrolls: 60,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
        await tester.pumpAndSettle();
        return finder;
      }

      Future<void> compare() async {
        await tester.enterText(
          await reveal('karate-own-answer'),
          'KA-P1 is original preparation, not a belt or defensive qualification.',
        );
        tester.testTextInput.hide();
        await tester.pump();
        await tester.tap((await reveal('karate-reveal-answer')).hitTestable());
        await tester.pump();
        await tester.enterText(
          await reveal('karate-own-correction'),
          'Keep the original written sequence and physical uncertainty separate.',
        );
        tester.testTextInput.hide();
        await tester.pump();
        await tester.tap((await reveal('karate-compared')).hitTestable());
        await tester.pump();
      }

      await compare();
      final report = await reveal('karate-report-written');
      final armedReport = tester.widget<TextButton>(report).onPressed;
      expect(armedReport, isNotNull);
      final staleReport = armedReport!;
      await tester.tap(find.byKey(const Key('karate-stop-top')));
      await tester.pump();
      staleReport();
      await tester.pump();
      expect(reports, 0);
      // Even when a new valid comparison exists, only its new closure may report.
      await compare();
      staleReport();
      await tester.pump();
      expect(reports, 0);
      final current = await reveal('karate-report-written');
      expect(tester.widget<TextButton>(current).onPressed, isNotNull);
      await tester.tap(current.hitTestable());
      await tester.pump();
      expect(reports, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final karateCase in [true, false]) {
    testWidgets(
      '${karateCase ? 'Karate' : 'Taikyoku'} practice is unsaved and stale callbacks cannot undo Stop',
      (tester) async {
        var writtenReports = 0;
        var writtenInvalidations = 0;
        var resets = 0;
        var admitted = true;
        final Widget page;
        if (karateCase) {
          final course = KarateCourse.fromJsonString(
            jsonEncode(_asset('karate_a.v1.json')),
          );
          page = KarateLessonPage(
            lesson: course.lessons.singleWhere(
              (lesson) => lesson.id == 'ka-12',
            ),
            course: course,
            admitted: () => admitted,
            priorWritten: () => true,
            onWritten: () => writtenReports++,
            onInvalidate: () => writtenInvalidations++,
            onReset: () => resets++,
          );
        } else {
          final course = TaikyokuCourse.fromJsonString(
            jsonEncode(_asset('taikyoku_shodan_jl.v1.json')),
          );
          page = TaikyokuLessonPage(
            lesson: course.lessons.singleWhere(
              (lesson) => lesson.id == 'ts-04',
            ),
            course: course,
            admitted: () => admitted,
            priorWritten: () => true,
            onWritten: () => writtenReports++,
            onInvalidate: () => writtenInvalidations++,
            onReset: () => resets++,
          );
        }
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            supportedLocales: testSupportedLocales,
            localizationsDelegates: testLocalizationDelegates,
            localeListResolutionCallback: resolveTestLocales,
            home: page,
          ),
        );
        await settleTestLocalizations(
          tester,
          expectedLocale: const Locale('en'),
        );
        await tester.pumpAndSettle();
        final panelFinder = find.byType(SelfGuidedPracticePanel);
        await tester.scrollUntilVisible(
          panelFinder,
          300,
          maxScrolls: 50,
          scrollable: find.byType(Scrollable).first,
        );
        final beforeHide = tester.widget<SelfGuidedPracticePanel>(panelFinder);
        final readingToggle = find.byKey(
          Key(karateCase ? 'karate-toggle-reading' : 'taikyoku-toggle-reading'),
        );
        await tester.scrollUntilVisible(
          readingToggle,
          -300,
          maxScrolls: 50,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readingToggle.hitTestable());
        await tester.pump();
        expect(panelFinder, findsNothing);
        beforeHide.onChanged(PracticeAttempt.uncertain);
        await tester.pump();
        await tester.scrollUntilVisible(
          readingToggle,
          -300,
          maxScrolls: 50,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readingToggle.hitTestable());
        await tester.pump();
        await tester.scrollUntilVisible(
          panelFinder,
          300,
          maxScrolls: 50,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester.widget<SelfGuidedPracticePanel>(panelFinder).attempt,
          PracticeAttempt.unrecorded,
        );
        final writtenInvalidationsAfterReading = writtenInvalidations;
        final choice = find.byKey(const Key('self-guided-attempt-uncertain'));
        await tester.scrollUntilVisible(
          choice,
          200,
          maxScrolls: 30,
          scrollable: find.byType(Scrollable).first,
        );
        final beforeTerminal = tester.widget<SelfGuidedPracticePanel>(
          panelFinder,
        );
        await tester.tap(choice.hitTestable());
        await tester.pump();
        final oldPanel = tester.widget<SelfGuidedPracticePanel>(panelFinder);
        expect(oldPanel.attempt, PracticeAttempt.uncertain);
        expect(oldPanel.admitted(), isFalse);
        beforeTerminal.onChanged(PracticeAttempt.attempted);
        oldPanel.onChanged(PracticeAttempt.unrecorded);
        await tester.pump();
        expect(
          tester.widget<SelfGuidedPracticePanel>(panelFinder).attempt,
          PracticeAttempt.uncertain,
        );
        expect(writtenReports, 0);
        expect(writtenInvalidations, writtenInvalidationsAfterReading);
        await tester.tap(
          find.byKey(Key(karateCase ? 'karate-stop-top' : 'taikyoku-stop-top')),
        );
        await tester.pump();
        expect(
          tester.widget<SelfGuidedPracticePanel>(panelFinder).attempt,
          PracticeAttempt.unrecorded,
        );
        final resetCount = resets;
        expect(resetCount, greaterThanOrEqualTo(1));
        // Simulate a delayed event from the widget that existed before Stop.
        oldPanel.onChanged(PracticeAttempt.uncertain);
        await tester.pump();
        expect(
          tester.widget<SelfGuidedPracticePanel>(panelFinder).attempt,
          PracticeAttempt.unrecorded,
        );
        final activePanel = tester.widget<SelfGuidedPracticePanel>(panelFinder);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        activePanel.onChanged(PracticeAttempt.uncertain);
        final inactivePanel = tester.widget<SelfGuidedPracticePanel>(
          panelFinder,
        );
        expect(inactivePanel.admitted(), isFalse);
        inactivePanel.onChanged(PracticeAttempt.attempted);
        await tester.pump();
        expect(
          tester.widget<SelfGuidedPracticePanel>(panelFinder).attempt,
          PracticeAttempt.unrecorded,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        inactivePanel.onChanged(PracticeAttempt.uncertain);
        await tester.pump();
        expect(
          tester.widget<SelfGuidedPracticePanel>(panelFinder).attempt,
          PracticeAttempt.unrecorded,
        );
        final resumedPanel = tester.widget<SelfGuidedPracticePanel>(
          panelFinder,
        );
        admitted = false;
        resumedPanel.onChanged(PracticeAttempt.uncertain);
        await tester.pump();
        expect(
          tester.widget<SelfGuidedPracticePanel>(panelFinder).attempt,
          PracticeAttempt.unrecorded,
        );
        final resetsAfterEvents = resets;
        await tester.pumpWidget(const SizedBox.shrink());
        resumedPanel.onChanged(PracticeAttempt.uncertain);
        await tester.pump();
        expect(writtenReports, 0);
        expect(writtenInvalidations, writtenInvalidationsAfterReading);
        expect(resets, resetsAfterEvents);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test(
    'reviewed original preparations retain legacy false and concept-only boundaries',
    () {
      final karate = KarateCourse.fromJsonString(
        jsonEncode(_asset('karate_a.v1.json')),
      );
      final taikyoku = TaikyokuCourse.fromJsonString(
        jsonEncode(_asset('taikyoku_shodan_jl.v1.json')),
      );
      for (final p in [
        ...karate.lessons.map((l) => l.selfPractice),
        ...taikyoku.lessons.map((l) => l.selfPractice),
      ]) {
        expect(p.sourceReviewReceiptId, isNotNull);
        expect(p.sourceReview, isNot(PracticeSourceReview.pending));
        expect(p.offersMovement, p.mode != SelfGuidedPracticeMode.conceptOnly);
        expect(p.verifiedTechnique, isFalse);
        expect(p.progressEffect, 0);
      }
      expect(karate.physicalTechniqueValidated, isFalse);
      expect(taikyoku.physicalTechniqueValidated, isFalse);
      for (final name in ['karate_a.v1.json', 'taikyoku_shodan_jl.v1.json']) {
        final value = _asset(name);
        final lessons = name.startsWith('karate')
            ? value['lessons']
            : value['content']['lessons'];
        final p = lessons[3]['selfPractice'] as Map;
        p['sourceReview'] = 'pending';
        p['sourceReviewReceiptId'] = null;
        final decoded = name.startsWith('karate')
            ? KarateCourse.fromJsonString(
                jsonEncode(value),
              ).lessons[3].selfPractice
            : TaikyokuCourse.fromJsonString(
                jsonEncode(value),
              ).lessons[3].selfPractice;
        expect(decoded.offersMovement, isFalse);
        p['sourceReviewReceiptId'] = 'fake-receipt-while-pending';
        expect(
          () => name.startsWith('karate')
              ? KarateCourse.fromJsonString(jsonEncode(value))
              : TaikyokuCourse.fromJsonString(jsonEncode(value)),
          throwsFormatException,
        );
      }
    },
  );
}
