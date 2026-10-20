import 'localization_fixture.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/kickboxing_course.dart';
import 'package:jablab/app/kickboxing_course_page.dart';

KickboxingCourse course() => KickboxingCourse.fromJsonString(
  File('assets/content/kickboxing_a.v1.json').readAsStringSync(),
);

Future<void> open(
  WidgetTester t, {
  ValueNotifier<String?>? owner,
  ValueNotifier<bool>? admission,
  NavigatorObserver? observer,
  Future<KickboxingCourse> Function()? loader,
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
                builder: (_) => KickboxingCoursePage(
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
  await show(t, const Key('kickboxing-own-answer'));
  await t.enterText(
    find.byKey(const Key('kickboxing-own-answer')),
    'My independent account; physical tasks unattempted.',
  );
  t.testTextInput.hide();
  await t.pumpAndSettle();
  await tap(t, const Key('kickboxing-reveal-answer'));
  await show(t, const Key('kickboxing-own-correction'));
  await t.enterText(
    find.byKey(const Key('kickboxing-own-correction')),
    'I must retain the supporting hand and all individual prerequisites.',
  );
  t.testTextInput.hide();
  await t.pumpAndSettle();
  await tap(t, const Key('kickboxing-compared'));
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
            await tap(t, Key('kickboxing-lesson-${l.number}'));
            final answer = language == 'tr' ? l.answer.tr : l.answer.en;
            expect(
              find.text(language == 'tr' ? l.title.tr : l.title.en),
              findsOneWidget,
            );
            expect(find.byKey(const Key('kickboxing-answer')), findsNothing);
            expect(
              find.byKey(const Key('kickboxing-correction-guidance')),
              findsNothing,
            );
            expect(
              find.bySemanticsLabel(RegExp(RegExp.escape(answer))),
              findsNothing,
            );
            if (l.number == 12) {
              for (final row in l.rows) {
                final copy = language == 'tr' ? row.tr : row.en;
                final card = find.text(copy);
                await t.scrollUntilVisible(
                  card,
                  300,
                  scrollable: find.byType(Scrollable).first,
                  maxScrolls: 200,
                );
                await Scrollable.ensureVisible(t.element(card), alignment: 0.5);
                await t.pumpAndSettle();
                // Read the actual rendered card; expected headers are independent of the fixture.
                final rendered = t.widget<Text>(card).data!;
                expect(
                  rendered
                      .split('\n')
                      .map((line) => line.split(':').first)
                      .toList(),
                  language == 'tr'
                      ? ['İşaret', 'Eylem', 'Yön ve destek']
                      : ['Cue', 'Action', 'Direction/support'],
                );
                expect(
                  rendered,
                  isNot(contains(language == 'tr' ? 'Action:' : 'Eylem:')),
                );
              }
            }
            await show(t, const Key('kickboxing-reveal-answer'));
            expect(
              t
                  .widget<TextButton>(
                    find.byKey(const Key('kickboxing-reveal-answer')),
                  )
                  .onPressed,
              isNull,
            );
            await show(t, const Key('kickboxing-own-answer'));
            await t.enterText(
              find.byKey(const Key('kickboxing-own-answer')),
              'My independent account; physical tasks unattempted.',
            );
            t.testTextInput.hide();
            await t.pumpAndSettle();
            await tap(t, const Key('kickboxing-reveal-answer'));
            await show(t, const Key('kickboxing-answer'));
            expect(find.text(answer), findsOneWidget);
            expect(
              find.bySemanticsLabel(RegExp(RegExp.escape(answer))),
              findsOneWidget,
            );
            await show(t, const Key('kickboxing-own-correction'));
            await t.enterText(
              find.byKey(const Key('kickboxing-own-correction')),
              'I record a specific correction; no physical component was attempted.',
            );
            t.testTextInput.hide();
            await t.pumpAndSettle();
            await tap(t, const Key('kickboxing-compared'));
            await tap(t, const Key('kickboxing-report-written'));
            expect(course().physicalPracticeAvailable, isFalse);
            expect(t.takeException(), isNull);
            await t.pageBack();
            await t.pumpAndSettle();
          }
          await show(t, const Key('kickboxing-written-progress'));
          expect(find.textContaining('16/16'), findsOneWidget);
          await show(t, const Key('kickboxing-written-completion'));
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
      await tap(t, const Key('kickboxing-lesson-1'));
      await writeAndCompare(t);
      await tap(t, const Key('kickboxing-report-written'));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('kickboxing-answer')), findsNothing);
      await show(t, const Key('kickboxing-own-answer'));
      expect(
        t
            .widget<TextField>(find.byKey(const Key('kickboxing-own-answer')))
            .controller!
            .text,
        isEmpty,
      );
      await t.pageBack();
      await t.pumpAndSettle();
      await show(t, const Key('kickboxing-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
    },
  );
  testWidgets('stale load cannot restore course after owner retirement', (
    t,
  ) async {
    final owner = ValueNotifier<String?>('first');
    addTearDown(owner.dispose);
    final pending = Completer<KickboxingCourse>();
    await t.pumpWidget(
      MaterialApp(
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        localeListResolutionCallback: resolveTestLocales,
        home: KickboxingCoursePage(
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
    expect(find.byKey(const Key('kickboxing-course-list')), findsNothing);
  });
  testWidgets(
    'uncertainty and missing correction cannot report a written review',
    (t) async {
      await open(t);
      await tap(t, const Key('kickboxing-lesson-1'));
      await show(t, const Key('kickboxing-own-answer'));
      await t.enterText(
        find.byKey(const Key('kickboxing-own-answer')),
        'Independent answer',
      );
      t.testTextInput.hide();
      await t.pumpAndSettle();
      await tap(t, const Key('kickboxing-reveal-answer'));
      await tap(t, const Key('kickboxing-compared'));
      await show(t, const Key('kickboxing-report-written'));
      expect(
        t
            .widget<TextButton>(
              find.byKey(const Key('kickboxing-report-written')),
            )
            .onPressed,
        isNull,
      );
      await show(t, const Key('kickboxing-own-correction'));
      await t.enterText(
        find.byKey(const Key('kickboxing-own-correction')),
        'My unresolved question',
      );
      t.testTextInput.hide();
      await t.pumpAndSettle();
      await tap(t, const Key('kickboxing-observation-uncertain'));
      await show(t, const Key('kickboxing-report-written'));
      expect(
        t
            .widget<TextButton>(
              find.byKey(const Key('kickboxing-report-written')),
            )
            .onPressed,
        isNull,
      );
      await t.pageBack();
      await t.pumpAndSettle();
      await show(t, const Key('kickboxing-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
    },
  );
  testWidgets(
    'prior written review is required; editing invalidates later reports',
    (t) async {
      await open(t);
      await tap(t, const Key('kickboxing-lesson-2'));
      await writeAndCompare(t);
      await show(t, const Key('kickboxing-report-written'));
      expect(
        t
            .widget<TextButton>(
              find.byKey(const Key('kickboxing-report-written')),
            )
            .onPressed,
        isNull,
      );
      await t.pageBack();
      await t.pumpAndSettle();
      for (final n in [1, 2]) {
        await tap(t, Key('kickboxing-lesson-$n'));
        await writeAndCompare(t);
        await tap(t, const Key('kickboxing-report-written'));
        await t.pageBack();
        await t.pumpAndSettle();
      }
      await show(t, const Key('kickboxing-written-progress'));
      expect(find.textContaining('2/16'), findsOneWidget);
      await tap(t, const Key('kickboxing-lesson-1'));
      await show(t, const Key('kickboxing-own-answer'));
      await t.enterText(
        find.byKey(const Key('kickboxing-own-answer')),
        'Changed account; I am uncertain.',
      );
      t.testTextInput.hide();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('kickboxing-answer')), findsNothing);
      await t.pageBack();
      await t.pumpAndSettle();
      await show(t, const Key('kickboxing-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
    },
  );
  testWidgets(
    'stop clears the visit and reopening starts without saved progress',
    (t) async {
      await open(t);
      await tap(t, const Key('kickboxing-lesson-1'));
      await writeAndCompare(t);
      await tap(t, const Key('kickboxing-report-written'));
      await t.tap(find.byKey(const Key('kickboxing-stop-top')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('kickboxing-answer')), findsNothing);
      await t.pageBack();
      await t.pumpAndSettle();
      await show(t, const Key('kickboxing-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      await show(t, const Key('kickboxing-written-progress'));
      expect(find.textContaining('0/16'), findsOneWidget);
    },
  );
  testWidgets('withdrawn admission removes the active lesson and overview', (
    t,
  ) async {
    final admission = ValueNotifier<bool>(true);
    addTearDown(admission.dispose);
    await open(t, admission: admission);
    await tap(t, const Key('kickboxing-lesson-1'));
    await writeAndCompare(t);
    admission.value = false;
    await t.pumpAndSettle();
    expect(
      find.byType(KickboxingCoursePage, skipOffstage: false),
      findsNothing,
    );
    expect(
      find.byType(KickboxingLessonPage, skipOffstage: false),
      findsNothing,
    );
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
    await tap(t, const Key('kickboxing-lesson-1'));
    expect(
      find.byType(KickboxingCoursePage, skipOffstage: false),
      findsNothing,
    );
    expect(
      find.byType(KickboxingLessonPage, skipOffstage: false),
      findsNothing,
    );
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
      await t.tap(find.byKey(const Key('kickboxing-retry')));
      await t.pumpAndSettle();
      expect(loads, 2);
      await show(t, const Key('kickboxing-written-progress'));
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
