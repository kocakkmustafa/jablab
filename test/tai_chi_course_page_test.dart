import 'localization_fixture.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/tai_chi_course.dart';
import 'package:jablab/app/tai_chi_course_page.dart';

TaiChiCourse course() => TaiChiCourse.fromJsonString(
  File('assets/content/tai_chi_course.v1.json').readAsStringSync(),
);
Future<void> open(
  WidgetTester tester, {
  ValueNotifier<String?>? owner,
  ValueNotifier<bool>? admission,
  Future<TaiChiCourse> Function()? loader,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      supportedLocales: testSupportedLocales,
      localizationsDelegates: testLocalizationDelegates,
      localeListResolutionCallback: resolveTestLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TaiChiCoursePage(
                  loader: loader ?? () async => course(),
                  accountUserId: owner,
                  resourceAdmission: admission,
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await settleTestLocalizations(tester);
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> lesson(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('tai-chi-lesson-1')),
    250,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('tai-chi-lesson-1')).hitTestable());
  await tester.pumpAndSettle();
}

Future<void> visibleTap(
  WidgetTester tester,
  Key key, {
  double delta = 250,
}) async {
  await tester.scrollUntilVisible(find.byKey(key), delta);
  await tester.tap(find.byKey(key).hitTestable());
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['tr', 'en']) {
    testWidgets('all 14 $language lessons remain usable at large text scale', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = <Locale>[Locale(language)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final semantics = tester.ensureSemantics();
      try {
        await open(tester, textScale: 2);
        for (final current in course().lessons) {
          final entry = find.byKey(Key('tai-chi-lesson-${current.number}'));
          await tester.scrollUntilVisible(
            entry,
            300,
            scrollable: find
                .descendant(
                  of: find.byKey(const Key('tai-chi-course-list')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await Scrollable.ensureVisible(tester.element(entry), alignment: 0.5);
          await tester.pumpAndSettle();
          final title = find
              .descendant(of: entry, matching: find.byType(Text))
              .first;
          await Scrollable.ensureVisible(tester.element(title), alignment: 0.5);
          await tester.pumpAndSettle();
          await tester.tap(title.hitTestable());
          await tester.pumpAndSettle();
          final answer = language == 'tr'
              ? current.answer.tr
              : current.answer.en;
          expect(find.byKey(const Key('tai-chi-answer')), findsNothing);
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(answer))),
            findsNothing,
          );
          final retest = language == 'tr'
              ? current.retest.tr
              : current.retest.en;
          await tester.scrollUntilVisible(find.text(retest), 300);
          expect(find.text(retest), findsOneWidget);
          await visibleTap(
            tester,
            const Key('tai-chi-reveal-answer'),
            delta: 300,
          );
          await tester.scrollUntilVisible(
            find.byKey(const Key('tai-chi-answer')),
            300,
          );
          expect(find.text(answer), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(answer))),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tapTestMaterialBack(tester);
          await tester.pumpAndSettle();
        }
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('pause and voluntary break reset practice readiness and report', (
    tester,
  ) async {
    await open(tester);
    await lesson(tester);
    await visibleTap(tester, const Key('tai-chi-prepared'));
    await visibleTap(tester, const Key('tai-chi-attempted'));
    await visibleTap(tester, const Key('tai-chi-check-observed'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('tai-chi-check-unattempted')),
      -250,
    );
    expect(
      tester
          .widget<RadioGroup<String>>(
            find.byKey(const Key('tai-chi-self-check-group')),
          )
          .groupValue,
      'unattempted',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('tai-chi-prepared')),
      -250,
    );
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('tai-chi-prepared')))
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('tai-chi-attempted')))
          .value,
      isFalse,
    );
    await visibleTap(tester, const Key('tai-chi-prepared'));
    await visibleTap(tester, const Key('tai-chi-attempted'));
    await visibleTap(tester, const Key('tai-chi-take-break'));
    await tester.scrollUntilVisible(
      find.byKey(const Key('tai-chi-prepared')),
      -250,
    );
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('tai-chi-prepared')))
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('tai-chi-attempted')))
          .onChanged,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('tai-chi-check-unattempted')),
      250,
    );
    expect(
      tester
          .widget<RadioGroup<String>>(
            find.byKey(const Key('tai-chi-self-check-group')),
          )
          .groupValue,
      'unattempted',
    );
  });

  for (final language in ['tr', 'en']) {
    testWidgets('$language lesson renders translated task and hidden answer', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = <Locale>[Locale(language)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await open(tester);
      await lesson(tester);
      final first = course().lessons.first;
      expect(
        find.text(language == 'tr' ? first.title.tr : first.title.en),
        findsOneWidget,
      );
      expect(
        find.text(language == 'tr' ? first.objective.tr : first.objective.en),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tai-chi-answer')), findsNothing);
      await visibleTap(tester, const Key('tai-chi-reveal-answer'));
      expect(
        find.text(language == 'tr' ? first.answer.tr : first.answer.en),
        findsOneWidget,
      );
    });
  }
  testWidgets('answer starts hidden and per-visit practice needs preparation', (
    tester,
  ) async {
    await open(tester);
    await lesson(tester);
    expect(find.byKey(const Key('tai-chi-answer')), findsNothing);
    await visibleTap(tester, const Key('tai-chi-reveal-answer'));
    expect(find.byKey(const Key('tai-chi-answer')), findsOneWidget);
    await visibleTap(tester, const Key('tai-chi-reveal-answer'));
    expect(find.byKey(const Key('tai-chi-answer')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('tai-chi-attempted')),
      -250,
    );
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('tai-chi-attempted')))
          .onChanged,
      isNull,
    );
    await visibleTap(tester, const Key('tai-chi-prepared'), delta: -250);
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('tai-chi-attempted')))
          .onChanged,
      isNotNull,
    );
    await tapTestMaterialBack(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tai-chi-course-list')), findsOneWidget);
    await lesson(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('tai-chi-prepared')),
      250,
    );
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('tai-chi-prepared')))
          .value,
      isFalse,
    );
  });
  for (final interruption in ['owner', 'admission']) {
    testWidgets('$interruption change removes lesson and overview', (
      tester,
    ) async {
      final owner = ValueNotifier<String?>('a');
      final admission = ValueNotifier<bool>(true);
      await open(tester, owner: owner, admission: admission);
      await lesson(tester);
      if (interruption == 'owner') {
        owner.value = 'b';
      } else {
        admission.value = false;
      }
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.byType(TaiChiCoursePage), findsNothing);
      owner.dispose();
      admission.dispose();
    });
  }
  testWidgets('failed load retries and pending stale result cannot reopen', (
    tester,
  ) async {
    var attempts = 0;
    await open(
      tester,
      loader: () async {
        if (++attempts == 1) throw StateError('offline');
        return course();
      },
    );
    await tester.tap(find.byKey(const Key('tai-chi-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tai-chi-course-list')), findsOneWidget);
    await tapTestMaterialBack(tester);
    await tester.pumpAndSettle();
    final pending = Completer<TaiChiCourse>();
    final owner = ValueNotifier<String?>('a');
    // Avoid pumpAndSettle while the deliberate pending loader shows a spinner.
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        localeListResolutionCallback: resolveTestLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TaiChiCoursePage(
                    loader: () => pending.future,
                    accountUserId: owner,
                  ),
                ),
              ),
              child: const Text('Pending'),
            ),
          ),
        ),
      ),
    );
    await settleTestLocalizations(tester);
    await tester.tap(find.text('Pending'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    owner.value = 'b';
    await tester.pumpAndSettle();
    pending.complete(course());
    await tester.pumpAndSettle();
    expect(find.text('Pending'), findsOneWidget);
    expect(find.byType(TaiChiCoursePage), findsNothing);
    owner.dispose();
  });
}
