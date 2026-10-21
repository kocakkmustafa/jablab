// Report-only acceptance supplement. All definitions are UNRUN.
// Uses production pages/models and actual packaged copy; no physical AT claim.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/karate_course.dart';
import 'package:jablab/app/karate_course_page.dart';
import 'package:jablab/app/self_guided_practice.dart';
import 'package:jablab/app/self_guided_practice_panel.dart';
import 'package:jablab/app/ui_language.dart';

import 'localization_fixture.dart';

KarateCourse _course() => KarateCourse.fromJsonString(
  File('assets/content/karate_a.v1.json').readAsStringSync(),
);

String _arabicMessage(String en, String tr) {
  final catalog =
      jsonDecode(File('assets/i18n/ar.json').readAsStringSync())
          as Map<String, dynamic>;
  final messages = catalog['messages'] as Map<String, dynamic>;
  final translated = messages[AppLocalizations.sourceKey(en, tr)];
  expect(catalog['locale'], 'ar');
  expect(catalog['complete'], isTrue);
  expect(
    translated,
    isA<String>(),
    reason: 'Actual packaged Arabic is required',
  );
  final result = translated as String;
  expect(result.trim(), isNotEmpty);
  expect(RegExp(r'[\u0600-\u06ff]').hasMatch(result), isTrue);
  expect(
    result,
    isNot(en),
    reason: 'A source fallback is not an Arabic render',
  );
  return result;
}

Future<Finder> _showKey(WidgetTester tester, String key) async {
  final scrollable = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  final target = find.byKey(Key(key));
  await tester.scrollUntilVisible(
    target,
    300,
    maxScrolls: 100,
    scrollable: scrollable,
  );
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  expect(
    tester.takeException(),
    isNull,
    reason: 'No overflow or layout exception',
  );
  return target;
}

Future<void> _arabicSafetyStop(
  WidgetTester tester,
  Brightness brightness,
) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final semantics = tester.ensureSemantics();
  addTearDown(semantics.dispose);
  final course = _course();
  final lesson = course.lessons.singleWhere((lesson) => lesson.id == 'ka-12');
  final practice = lesson.selfPractice;
  var writtenReports = 0;
  var invalidations = 0;
  var visitResets = 0;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: testSupportedLocales,
      localizationsDelegates: testLocalizationDelegates,
      localeListResolutionCallback: resolveTestLocales,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(2.2)),
        child: child!,
      ),
      home: KarateLessonPage(
        lesson: lesson,
        course: course,
        admitted: () => true,
        priorWritten: () => true,
        onWritten: () => writtenReports++,
        onInvalidate: () => invalidations++,
        onReset: () => visitResets++,
      ),
    ),
  );
  await settleTestLocalizations(tester, expectedLocale: const Locale('ar'));
  await tester.pumpAndSettle();
  final panel = find.byType(SelfGuidedPracticePanel);
  await _showKey(tester, 'self-guided-task');
  expect(
    tester.widget<SelfGuidedPracticePanel>(panel).practice,
    same(practice),
  );
  final context = tester.element(panel);
  expect(Localizations.localeOf(context), const Locale('ar'));
  expect(Directionality.of(context), TextDirection.rtl);
  expect(Theme.of(context).brightness, brightness);
  expect(MediaQuery.textScalerOf(context).scale(10), closeTo(22, 0.001));

  for (final item in [
    (key: 'self-guided-safety', copy: practice.safety),
    (key: 'self-guided-adaptation', copy: practice.adaptation),
  ]) {
    final expected = _arabicMessage(item.copy.en, item.copy.tr);
    final control = await _showKey(tester, item.key);
    expect(tester.widget<Text>(control).data, expected);
    expect(
      tester.getSemantics(control).getSemanticsData().label,
      contains(expected),
    );
  }

  final stopped = await _showKey(tester, 'self-guided-attempt-stopped');
  final stopLabel = _arabicMessage(
    'I stopped; no harder retry this session',
    'Durdum; bu oturumda zor görevi yeniden denemiyorum',
  );
  final stopSemantics = tester.getSemantics(stopped).getSemanticsData();
  expect(stopSemantics.label, contains(stopLabel));
  expect(stopSemantics.hasAction(SemanticsAction.tap), isTrue);
  expect(
    tester.widget<RadioListTile<PracticeAttempt>>(stopped).enabled,
    isTrue,
  );
  await tester.tap(stopped.hitTestable());
  await tester.pumpAndSettle();
  expect(
    tester.widget<SelfGuidedPracticePanel>(panel).attempt,
    PracticeAttempt.stopped,
  );
  await _showKey(tester, 'self-guided-ended');
  await _showKey(tester, 'self-guided-attempt-attempted');
  expect(
    tester
        .widget<RadioListTile<PracticeAttempt>>(
          find.byKey(const Key('self-guided-attempt-attempted')),
        )
        .enabled,
    isFalse,
  );

  // The independent visit-clear control remains reachable without scrolling.
  final topStop = find.byKey(const Key('karate-stop-top')).hitTestable();
  expect(topStop, findsOneWidget);
  final tooltip = _arabicMessage(
    'Stop and clear this visit',
    'Dur ve bu ziyareti temizle',
  );
  expect(tester.widget<IconButton>(topStop).tooltip, tooltip);
  final topStopNode = tester.getSemantics(topStop);
  final topSemantics = topStopNode.getSemanticsData();
  // Flutter exposes Tooltip copy through its dedicated semantics tooltip field.
  expect(topSemantics.tooltip, tooltip);
  expect(topSemantics.textDirection, TextDirection.rtl);
  expect(topSemantics.flagsCollection.isButton, isTrue);
  expect(topSemantics.hasAction(SemanticsAction.tap), isTrue);
  final topRect = tester.getRect(topStop);
  expect(topRect.left, greaterThanOrEqualTo(0));
  expect(topRect.right, lessThanOrEqualTo(360));
  expect(writtenReports, 0);
  expect(invalidations, 0);
  expect(visitResets, 0);
  expect(practice.progressEffect, 0);
  expect(practice.verifiedTechnique, isFalse);
  tester.semantics.tap(
    find.semantics.byPredicate((node) => identical(node, topStopNode)),
  );
  await tester.pumpAndSettle();
  expect(visitResets, 1);
  expect(
    tester.widget<SelfGuidedPracticePanel>(panel).attempt,
    PracticeAttempt.unrecorded,
  );
  expect(find.byKey(const Key('self-guided-ended')), findsNothing);
  expect(writtenReports, 0);
  expect(invalidations, 0);
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
    'Arabic RTL light scale2.2 exposes real safety and terminal stop semantics',
    (tester) async => _arabicSafetyStop(tester, Brightness.light),
  );

  testWidgets(
    'Arabic RTL dark scale2.2 exposes real safety and terminal stop semantics',
    (tester) async => _arabicSafetyStop(tester, Brightness.dark),
  );

  testWidgets(
    'real course first-next-last binds all three mode families without progress',
    (tester) async {
      final course = _course();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: testSupportedLocales,
          localizationsDelegates: testLocalizationDelegates,
          localeListResolutionCallback: resolveTestLocales,
          home: KarateCoursePage(loader: () async => course),
        ),
      );
      await settleTestLocalizations(tester, expectedLocale: const Locale('en'));
      await tester.pumpAndSettle();
      const visits = [
        (number: 1, id: 'ka-01', mode: SelfGuidedPracticeMode.conceptOnly),
        (number: 2, id: 'ka-02', mode: SelfGuidedPracticeMode.preparation),
        (
          number: 3,
          id: 'ka-03',
          mode: SelfGuidedPracticeMode.smallRangeNonContact,
        ),
        (number: 16, id: 'ka-16', mode: SelfGuidedPracticeMode.conceptOnly),
      ];
      for (final visit in visits) {
        final lesson = course.lessons.singleWhere(
          (lesson) => lesson.id == visit.id,
        );
        final entry = await _showKey(tester, 'karate-lesson-${visit.number}');
        await tester.tap(entry.hitTestable());
        await tester.pumpAndSettle();
        expect(find.byType(KarateLessonPage), findsOneWidget);
        if (visit.number == 16) {
          expect(find.byType(SelfGuidedPracticePanel), findsNothing);
          await tester.tap(
            (await _showKey(tester, 'karate-toggle-reading')).hitTestable(),
          );
          await tester.pumpAndSettle();
        }
        final task = await _showKey(tester, 'self-guided-task');
        final panelFinder = find.byType(SelfGuidedPracticePanel);
        final panel = tester.widget<SelfGuidedPracticePanel>(panelFinder);
        expect(panel.practice, same(lesson.selfPractice));
        expect(panel.practice.lessonId, visit.id);
        expect(panel.practice.mode, visit.mode);
        expect(tester.widget<Text>(task).data, lesson.selfPractice.task.en);
        expect(panel.attempt, PracticeAttempt.unrecorded);
        final attempt = await _showKey(tester, 'self-guided-attempt-attempted');
        expect(
          tester.widget<RadioListTile<PracticeAttempt>>(attempt).enabled,
          panel.practice.offersMovement,
        );
        final selected = panel.practice.offersMovement
            ? PracticeAttempt.attempted
            : PracticeAttempt.skipped;
        final report = await _showKey(
          tester,
          'self-guided-attempt-${selected.name}',
        );
        await tester.tap(report.hitTestable());
        await tester.pumpAndSettle();
        expect(
          tester.widget<SelfGuidedPracticePanel>(panelFinder).attempt,
          selected,
        );
        expect(panel.practice.progressEffect, 0);
        expect(panel.practice.verifiedTechnique, isFalse);
        await tapTestMaterialBack(tester);
        expect(find.byKey(const Key('karate-course-list')), findsOneWidget);
        final progress = await _showKey(tester, 'karate-written-progress');
        expect(tester.widget<Text>(progress).data, startsWith('0/16'));
        expect(
          find.byKey(const Key('karate-written-completion')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
