import 'localization_fixture.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/karate_course.dart';
import 'package:jablab/app/karate_course_page.dart';

KarateCourse course() => KarateCourse.fromJsonString(
  File('assets/content/karate_a.v1.json').readAsStringSync(),
);

Future<void> open(
  WidgetTester t, {
  ValueNotifier<String?>? owner,
  ValueNotifier<bool>? admission,
  NavigatorObserver? observer,
  Future<KarateCourse> Function()? loader,
}) async {
  await t.pumpWidget(
    MaterialApp(
      supportedLocales: testSupportedLocales,
      localizationsDelegates: testLocalizationDelegates,
      localeListResolutionCallback: resolveTestLocales,
      navigatorObservers: observer == null ? [] : [observer],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => KarateCoursePage(
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
  await settleTestLocalizations(t);
  await t.tap(find.text('Open'));
  await t.pumpAndSettle();
}

Future<void> show(WidgetTester t, Key key) async {
  final scrollable = find.byType(Scrollable).first;
  t.state<ScrollableState>(scrollable).position.jumpTo(0);
  await t.pump();
  await t.scrollUntilVisible(
    find.byKey(key),
    400,
    scrollable: scrollable,
    maxScrolls: 200,
  );
  await Scrollable.ensureVisible(t.element(find.byKey(key)), alignment: 0.5);
  await t.pumpAndSettle();
}

Future<void> tap(WidgetTester t, Key key) async {
  await show(t, key);
  await t.tap(find.byKey(key).hitTestable());
  await t.pumpAndSettle();
}

Future<void> writeAndCompare(WidgetTester t) async {
  await show(t, const Key('karate-own-answer'));
  await t.enterText(
    find.byKey(const Key('karate-own-answer')),
    'My independent account; physical tasks unattempted.',
  );
  t.testTextInput.hide();
  await t.pumpAndSettle();
  await tap(t, const Key('karate-reveal-answer'));
  await show(t, const Key('karate-own-correction'));
  await t.enterText(
    find.byKey(const Key('karate-own-correction')),
    'I must retain the supporting hand and all individual prerequisites.',
  );
  t.testTextInput.hide();
  await t.pumpAndSettle();
  await tap(t, const Key('karate-compared'));
}

void main() {
  for (final language in ['tr', 'en']) {
    testWidgets(
      'all sixteen $language lessons: large text, hidden answers, written-only report',
      (t) async {
        t.platformDispatcher.localesTestValue = <Locale>[Locale(language)];
        addTearDown(t.platformDispatcher.clearLocalesTestValue);
        await t.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final semantics = t.ensureSemantics();
        try {
          await open(t);
          for (final l in course().lessons) {
            await tap(t, Key('karate-lesson-${l.number}'));
            final answer = language == 'tr' ? l.answer.tr : l.answer.en;
            expect(
              find.text(language == 'tr' ? l.title.tr : l.title.en),
              findsOneWidget,
            );
            expect(find.byKey(const Key('karate-answer')), findsNothing);
            expect(
              find.byKey(const Key('karate-correction-guidance')),
              findsNothing,
            );
            expect(
              find.bySemanticsLabel(RegExp(RegExp.escape(answer))),
              findsNothing,
            );
            if (l.number == 16) {
              expect(find.byKey(const Key('karate-teaching')), findsNothing);
              await tap(t, const Key('karate-toggle-reading'));
            }
            await show(t, const Key('karate-teaching'));
            expect(
              t.widget<Text>(find.byKey(const Key('karate-teaching'))).data,
              language == 'tr' ? l.teaching.tr : l.teaching.en,
            );
            await show(t, const Key('karate-conditional-task'));
            expect(
              t
                  .widget<Text>(
                    find.byKey(const Key('karate-conditional-task')),
                  )
                  .data,
              language == 'tr' ? l.physicalTask.tr : l.physicalTask.en,
            );
            await show(t, const Key('karate-written-task'));
            expect(
              t.widget<Text>(find.byKey(const Key('karate-written-task'))).data,
              language == 'tr' ? l.writtenTask.tr : l.writtenTask.en,
            );
            if (l.number == 15) {
              t
                  .state<ScrollableState>(find.byType(Scrollable).first)
                  .position
                  .jumpTo(0);
              await t.pump();
              for (var i = 0; i < course().sequenceRows.length; i++) {
                final row = course().sequenceRows[i];
                final card = find.text(language == 'tr' ? row.tr : row.en);
                await t.scrollUntilVisible(
                  card,
                  300,
                  scrollable: find.byType(Scrollable).first,
                  maxScrolls: 200,
                );
                await Scrollable.ensureVisible(t.element(card), alignment: 0.5);
                await t.pumpAndSettle();
                final rendered = t.widget<Text>(card).data!;
                // Independent location/direction sequence from accepted KA-P1 review.
                expect(
                  rendered,
                  startsWith(
                    [
                      '1 · A · N',
                      '2 · B · N',
                      '3 · C · N',
                      '4 · C · E',
                      '5 · D · E',
                      '6 · D · E',
                    ][i],
                  ),
                );
                expect(t.takeException(), isNull);
              }
            }
            await tap(t, const Key('karate-toggle-reading'));
            expect(find.byKey(const Key('karate-teaching')), findsNothing);
            expect(
              find.byKey(const Key('karate-conditional-task')),
              findsNothing,
            );
            await show(t, const Key('karate-reveal-answer'));
            expect(
              t
                  .widget<TextButton>(
                    find.byKey(const Key('karate-reveal-answer')),
                  )
                  .onPressed,
              isNull,
            );
            await show(t, const Key('karate-own-answer'));
            await t.enterText(
              find.byKey(const Key('karate-own-answer')),
              'My independent account; physical tasks unattempted.',
            );
            t.testTextInput.hide();
            await t.pumpAndSettle();
            await tap(t, const Key('karate-reveal-answer'));
            await show(t, const Key('karate-answer'));
            expect(find.text(answer), findsOneWidget);
            expect(
              find.bySemanticsLabel(RegExp(RegExp.escape(answer))),
              findsOneWidget,
            );
            await show(t, const Key('karate-retest-guidance'));
            expect(
              t
                  .widget<Text>(find.byKey(const Key('karate-retest-guidance')))
                  .data,
              language == 'tr' ? l.retest.tr : l.retest.en,
            );
            await show(t, const Key('karate-own-correction'));
            await t.enterText(
              find.byKey(const Key('karate-own-correction')),
              'I record a specific correction; no physical component was attempted.',
            );
            t.testTextInput.hide();
            await t.pumpAndSettle();
            await tap(t, const Key('karate-compared'));
            await tap(t, const Key('karate-report-written'));
            expect(course().physicalPracticeAvailable, isFalse);
            expect(t.takeException(), isNull);
            await t.pageBack();
            await t.pumpAndSettle();
          }
          await show(t, const Key('karate-written-progress'));
          expect(find.textContaining('16/16'), findsOneWidget);
          await show(t, const Key('karate-written-completion'));
          expect(
            find.textContaining(
              language == 'en'
                  ? 'remain physically unattempted and unverified'
                  : 'fiziksel olarak denenmedi ve doğrulanmadı',
            ),
            findsOneWidget,
          );
          expect(course().physicalPracticeAvailable, isFalse);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
  testWidgets(
    'pause clears own answer, reveal and this visit written progress',
    (t) async {
      await open(t);
      await tap(t, const Key('karate-lesson-1'));
      await writeAndCompare(t);
      await tap(t, const Key('karate-report-written'));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('karate-answer')), findsNothing);
      await show(t, const Key('karate-own-answer'));
      expect(
        t
            .widget<TextField>(find.byKey(const Key('karate-own-answer')))
            .controller!
            .text,
        isEmpty,
      );
      await t.pageBack();
      await t.pumpAndSettle();
      await show(t, const Key('karate-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
    },
  );
  testWidgets('stale load cannot restore course after owner retirement', (
    t,
  ) async {
    final owner = ValueNotifier<String?>('first');
    addTearDown(owner.dispose);
    final pending = Completer<KarateCourse>();
    await t.pumpWidget(
      MaterialApp(
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        localeListResolutionCallback: resolveTestLocales,
        home: KarateCoursePage(
          loader: () => pending.future,
          accountUserId: owner,
        ),
      ),
    );
    await settleTestLocalizations(t);
    await t.pump();
    owner.value = 'second';
    await t.pump();
    pending.complete(course());
    await t.pumpAndSettle();
    expect(find.byKey(const Key('karate-course-list')), findsNothing);
  });
  testWidgets(
    'uncertainty and missing correction cannot report a written review',
    (t) async {
      await open(t);
      await tap(t, const Key('karate-lesson-1'));
      await show(t, const Key('karate-own-answer'));
      await t.enterText(
        find.byKey(const Key('karate-own-answer')),
        'Independent answer',
      );
      t.testTextInput.hide();
      await t.pumpAndSettle();
      await tap(t, const Key('karate-reveal-answer'));
      await tap(t, const Key('karate-compared'));
      await show(t, const Key('karate-report-written'));
      expect(
        t
            .widget<TextButton>(find.byKey(const Key('karate-report-written')))
            .onPressed,
        isNull,
      );
      await show(t, const Key('karate-own-correction'));
      await t.enterText(
        find.byKey(const Key('karate-own-correction')),
        'My unresolved question',
      );
      t.testTextInput.hide();
      await t.pumpAndSettle();
      await tap(t, const Key('karate-observation-uncertain'));
      await show(t, const Key('karate-report-written'));
      expect(
        t
            .widget<TextButton>(find.byKey(const Key('karate-report-written')))
            .onPressed,
        isNull,
      );
      await t.pageBack();
      await t.pumpAndSettle();
      await show(t, const Key('karate-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
    },
  );
  testWidgets(
    'prior written review is required; editing invalidates later reports',
    (t) async {
      await open(t);
      await tap(t, const Key('karate-lesson-2'));
      await writeAndCompare(t);
      await show(t, const Key('karate-report-written'));
      expect(
        t
            .widget<TextButton>(find.byKey(const Key('karate-report-written')))
            .onPressed,
        isNull,
      );
      await t.pageBack();
      await t.pumpAndSettle();
      for (final n in [1, 2]) {
        await tap(t, Key('karate-lesson-$n'));
        await writeAndCompare(t);
        await tap(t, const Key('karate-report-written'));
        await t.pageBack();
        await t.pumpAndSettle();
      }
      await show(t, const Key('karate-written-progress'));
      expect(find.textContaining('2/16'), findsOneWidget);
      await tap(t, const Key('karate-lesson-1'));
      await show(t, const Key('karate-own-answer'));
      await t.enterText(
        find.byKey(const Key('karate-own-answer')),
        'Changed account; I am uncertain.',
      );
      t.testTextInput.hide();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('karate-answer')), findsNothing);
      await t.pageBack();
      await t.pumpAndSettle();
      await show(t, const Key('karate-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
    },
  );
  testWidgets(
    'stop clears the visit and reopening starts without saved progress',
    (t) async {
      await open(t);
      await tap(t, const Key('karate-lesson-1'));
      await writeAndCompare(t);
      await tap(t, const Key('karate-report-written'));
      await t.tap(find.byKey(const Key('karate-stop-top')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('karate-answer')), findsNothing);
      await t.pageBack();
      await t.pumpAndSettle();
      await show(t, const Key('karate-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      await show(t, const Key('karate-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
    },
  );
  testWidgets('withdrawn admission removes the active lesson and overview', (
    t,
  ) async {
    final admission = ValueNotifier<bool>(true);
    addTearDown(admission.dispose);
    await open(t, admission: admission);
    await tap(t, const Key('karate-lesson-1'));
    await writeAndCompare(t);
    admission.value = false;
    await t.pumpAndSettle();
    expect(find.byType(KarateCoursePage, skipOffstage: false), findsNothing);
    expect(find.byType(KarateLessonPage, skipOffstage: false), findsNothing);
    expect(find.text('Open'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('retirement inside didPush cannot build a stale lesson', (
    t,
  ) async {
    final owner = ValueNotifier<String?>('first');
    addTearDown(owner.dispose);
    final observer = _PushObserver();
    await open(t, owner: owner, observer: observer);
    observer.next = () {
      owner.value = 'second';
    };
    await tap(t, const Key('karate-lesson-1'));
    expect(find.byType(KarateCoursePage, skipOffstage: false), findsNothing);
    expect(find.byType(KarateLessonPage, skipOffstage: false), findsNothing);
    expect(find.text('Open'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'load failure offers a working retry without fabricating progress',
    (t) async {
      var loads = 0;
      await open(
        t,
        loader: () async {
          if (++loads == 1) throw const FormatException('Invalid content');
          return course();
        },
      );
      await t.tap(find.byKey(const Key('karate-retry')));
      await t.pumpAndSettle();
      expect(loads, 2);
      await show(t, const Key('karate-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
    },
  );
}

class _PushObserver extends NavigatorObserver {
  VoidCallback? next;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final callback = next;
    next = null;
    callback?.call();
  }
}
