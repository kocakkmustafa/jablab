import 'localization_fixture.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/taikyoku_shodan_course.dart';
import 'package:jablab/app/taikyoku_shodan_course_page.dart';
import 'package:motion_content/motion_content.dart';

TaikyokuCourse _course() => TaikyokuCourse.fromJsonString(
  File('assets/content/taikyoku_shodan_jl.v1.json').readAsStringSync());

Future<void> _open(WidgetTester t, {ValueNotifier<String?>? owner,
  ValueNotifier<bool>? admission, NavigatorObserver? observer,
  Future<TaikyokuCourse> Function()? loader}) async {
  await t.pumpWidget(MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
    navigatorObservers: observer == null ? [] : [observer],
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context)
      .copyWith(textScaler: const TextScaler.linear(2)), child: child!),
    home: Builder(builder: (context) => Scaffold(body: TextButton(
      child: const Text('Open'), onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TaikyokuCoursePage(
          loader: loader ?? () async => _course(), accountUserId: owner,
          resourceAdmission: admission)),
      ),
    ))),
  ));
    await settleTestLocalizations(t);
  await t.tap(find.text('Open'));
  if (loader == null) { await t.pumpAndSettle(); } else { await t.pump(); }
}

Future<void> _show(WidgetTester t, String key, {bool fromTop = false}) async {
  final root = find.byKey(Key(find.byKey(const Key('taikyoku-lesson-body')).evaluate().isNotEmpty
    ? 'taikyoku-lesson-body' : 'taikyoku-course-list'));
  final scrollable = find.descendant(of: root, matching: find.byType(Scrollable)).first;
  if (fromTop) { t.state<ScrollableState>(scrollable).position.jumpTo(0); await t.pump(); }
  final target = find.byKey(Key(key));
  if (target.evaluate().isEmpty) {
    // Small steps keep short controls reachable between large lazy text blocks.
    await t.scrollUntilVisible(target, 200, scrollable: scrollable, maxScrolls: 300);
  }
  await Scrollable.ensureVisible(t.element(target), alignment: 0.1);
  await t.pumpAndSettle();
}
Future<void> _tap(WidgetTester t, String key) async {
  await _show(t, key, fromTop: true);
  await t.tap(find.byKey(Key(key)).hitTestable());
  await t.pumpAndSettle();
}
Future<void> _write(WidgetTester t, String key, String value) async {
  await _show(t, key, fromTop: true);
  await t.enterText(find.byKey(Key(key)), value);
  t.testTextInput.hide();
  await t.pumpAndSettle();
}
Future<void> _exact(WidgetTester t, String key, TaikyokuCopy copy, String language) async {
  await _show(t, key);
  expect(t.widget<Text>(find.byKey(Key(key))).data, language == 'tr' ? copy.tr : copy.en);
  expect(t.takeException(), isNull, reason: 'Large-text rendering at $key');
}
Future<void> _prepareReport(WidgetTester t, TaikyokuLesson lesson) async {
  await _tap(t, 'taikyoku-toggle-reading');
  for (final q in lesson.recall) { await _write(t, 'taikyoku-own-${q.id}', 'Independent written answer for ${q.id}.'); }
  await _tap(t, 'taikyoku-reveal-answer');
  await _write(t, 'taikyoku-own-correction', 'I correct my written turn/arm account; hidden details remain unknown.');
  await _tap(t, 'taikyoku-start-retest');
  for (final q in lesson.recall) { await _write(t, 'taikyoku-retest-${q.id}', 'Same prompt retest for ${q.id}; no physical acceptance.'); }
  await _tap(t, 'taikyoku-compare-retest');
  await _show(t, 'taikyoku-report-written');
  expect(t.widget<TextButton>(find.byKey(const Key('taikyoku-report-written'))).onPressed, isNull,
    reason: 'Comparison must be explicitly reported before written progress can change');
  await _tap(t, 'taikyoku-compared');
}

void main() {
  for (final language in ['tr','en']) {
    testWidgets('all10 $language lessons and20 counts render exact teaching at large text with keys hidden', (t) async {
      t.platformDispatcher.localeTestValue = Locale(language);
      addTearDown(t.platformDispatcher.clearLocaleTestValue);
      await t.binding.setSurfaceSize(const Size(360,800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final semantics = t.ensureSemantics();
      try {
        await _open(t);
        final course = _course();
        await _exact(t, 'taikyoku-course-title', course.title, language);
        await _tap(t, 'taikyoku-prerequisites');
        for (final p in course.requirements) {
          await _exact(t, '${p.id}-title', p.title, language);
          await _exact(t, '${p.id}-detail', p.detail, language);
        }
        await _tap(t, 'taikyoku-source-limits');
        await _exact(t, 'taikyoku-common-limits', course.commonLimits, language);
        for (final lesson in course.lessons) {
          await _tap(t, 'taikyoku-lesson-${lesson.number}');
          await _exact(t, 'taikyoku-lesson-title', lesson.title, language);
          await _exact(t, 'taikyoku-objective', lesson.objective, language);
          for (var i = 0; i < lesson.teaching.length; i++) {
            await _exact(t, 'taikyoku-teaching-$i', lesson.teaching[i], language);
          }
          for (final m in course.movementsFor(lesson)) {
            for (final pair in [ ('title',m.title),('start',m.start),('feet',m.feet),
              ('hands',m.hands),('finish',m.finish),('next',m.next),('limit',m.limit)]) {
              await _exact(t, '${m.id}-${pair.$1}', pair.$2, language);
            }
          }
          for (final q in lesson.recall) {
            await _exact(t, '${q.id}-prompt', q.prompt, language);
            for (final choice in q.choices) { await _exact(t, '${q.id}-choice-${choice.id}', choice.text, language); }
            expect(find.byKey(Key('${q.id}-key'), skipOffstage: false), findsNothing);
            expect(find.byKey(Key('${q.id}-explanation'), skipOffstage: false), findsNothing);
            expect(find.bySemanticsLabel(language == 'tr' ? '${q.id} yanıt anahtarı' : 'Answer key for ${q.id}'), findsNothing);
          }
          await _show(t, 'taikyoku-reveal-answer');
          expect(t.widget<TextButton>(find.byKey(const Key('taikyoku-reveal-answer'))).onPressed, isNull);
          await _prepareReport(t, lesson);
          for (final q in lesson.recall) {
            await _show(t, '${q.id}-key', fromTop: true);
            expect(t.widget<Text>(find.byKey(Key('${q.id}-key'))).data,
              language == 'tr' ? 'Anahtar: ${q.correctChoiceId}' : 'Key: ${q.correctChoiceId}');
            await _exact(t, '${q.id}-correct-answer', q.correctChoice.text, language);
            await _exact(t, '${q.id}-explanation', q.explanation, language);
          }
          await _tap(t, 'taikyoku-report-written');
          await _exact(t, 'taikyoku-completion-meaning', lesson.completionMeaning, language);
          expect(course.physicalPracticeAvailable, isFalse);
          await t.pageBack(); await t.pumpAndSettle();
        }
        await _show(t, 'taikyoku-written-progress', fromTop: true);
        expect(find.textContaining('10/10'), findsOneWidget);
        await _show(t, 'taikyoku-written-completion');
        expect(find.textContaining(language == 'tr' ? 'Fiziksel tamamlanma veya ustalık doğrulanmaz' : 'does not establish physical completion or mastery'), findsOneWidget);
        expect(t.takeException(), isNull);
      } finally { semantics.dispose(); }
    });
  }

  testWidgets('initial writing and comparison cannot bypass correction or a hidden-key retest', (t) async {
    await _open(t); await _tap(t, 'taikyoku-lesson-1');
    final lesson = _course().lessons.first;
    await _tap(t, 'taikyoku-toggle-reading');
    await _write(t, 'taikyoku-own-ts-q01', 'Own first answer');
    await _show(t, 'taikyoku-reveal-answer');
    expect(t.widget<TextButton>(find.byKey(const Key('taikyoku-reveal-answer'))).onPressed, isNull);
    await _write(t, 'taikyoku-own-ts-q02', 'Own second answer');
    await _tap(t, 'taikyoku-reveal-answer');
    await _show(t, 'taikyoku-report-written');
    expect(t.widget<TextButton>(find.byKey(const Key('taikyoku-report-written'))).onPressed, isNull);
    await _show(t, 'taikyoku-start-retest', fromTop: true);
    expect(t.widget<TextButton>(find.byKey(const Key('taikyoku-start-retest'))).onPressed, isNull);
    await _write(t, 'taikyoku-own-correction', 'Unresolved physical detail remains open.');
    await _tap(t, 'taikyoku-start-retest');
    for (final q in lesson.recall) {
      expect(find.byKey(Key('${q.id}-key'), skipOffstage: false), findsNothing);
      expect(find.byKey(Key('${q.id}-explanation'), skipOffstage: false), findsNothing);
      await _show(t, '${q.id}-prompt', fromTop: true);
      expect(t.widget<Text>(find.byKey(Key('${q.id}-prompt'))).data, q.prompt.en);
    }
    await _write(t, 'taikyoku-retest-ts-q01', 'Only one retest');
    await _show(t, 'taikyoku-compare-retest');
    expect(t.widget<TextButton>(find.byKey(const Key('taikyoku-compare-retest'))).onPressed, isNull);
    await t.pageBack(); await t.pumpAndSettle();
    await _show(t, 'taikyoku-written-progress', fromTop: true);
    expect(find.textContaining('0/10'), findsOneWidget);
  });

  testWidgets('prior written review and editing protect the finite sequence', (t) async {
    await _open(t); await _tap(t, 'taikyoku-lesson-2');
    await _prepareReport(t, _course().lessons[1]);
    await _show(t, 'taikyoku-report-written');
    expect(t.widget<TextButton>(find.byKey(const Key('taikyoku-report-written'))).onPressed, isNull);
    await t.pageBack(); await t.pumpAndSettle();
    for (final lesson in _course().lessons.take(2)) {
      await _tap(t, 'taikyoku-lesson-${lesson.number}');
      await _prepareReport(t, lesson); await _tap(t, 'taikyoku-report-written');
      await t.pageBack(); await t.pumpAndSettle();
    }
    await _show(t, 'taikyoku-written-progress', fromTop: true);
    expect(find.textContaining('2/10'), findsOneWidget);
    await _tap(t, 'taikyoku-lesson-1');
    await _write(t, 'taikyoku-own-ts-q01', 'Changed first boundary; uncertain.');
    await t.pageBack(); await t.pumpAndSettle();
    await _show(t, 'taikyoku-written-progress', fromTop: true);
    expect(find.textContaining('0/10'), findsOneWidget);
  });

  for (final stop in ['lifecycle','stop']) {
    testWidgets('$stop clears drafts, keys, retest and progress; retained report callbacks cannot restore them', (t) async {
      await _open(t); await _tap(t, 'taikyoku-lesson-1');
      await _prepareReport(t, _course().lessons.first);
      await _show(t, 'taikyoku-report-written');
      final stale = t.widget<TextButton>(find.byKey(const Key('taikyoku-report-written'))).onPressed!;
      stale(); await t.pumpAndSettle();
      if (stop == 'stop') {
        await t.tap(find.byKey(const Key('taikyoku-stop-top'))); await t.pumpAndSettle();
      } else {
        for (final state in [AppLifecycleState.inactive,AppLifecycleState.hidden,AppLifecycleState.paused]) {
          t.binding.handleAppLifecycleStateChanged(state);
        }
        await t.pump(); stale(); await t.pump();
        for (final state in [AppLifecycleState.hidden,AppLifecycleState.inactive,AppLifecycleState.resumed]) {
          t.binding.handleAppLifecycleStateChanged(state);
        }
        await t.pumpAndSettle();
      }
      stale(); await t.pumpAndSettle();
      for (final q in _course().lessons.first.recall) {
        expect(find.byKey(Key('${q.id}-key'), skipOffstage: false), findsNothing);
        await _show(t, 'taikyoku-own-${q.id}', fromTop: true);
        expect(t.widget<TextField>(find.byKey(Key('taikyoku-own-${q.id}'))).controller!.text, isEmpty);
      }
      await t.pageBack(); await t.pumpAndSettle();
      await _show(t, 'taikyoku-written-progress', fromTop: true);
      expect(find.textContaining('0/10'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  for (final interrupt in ['owner','admission']) {
    testWidgets('$interrupt retires overview/lesson and stale callbacks with no retained written answer', (t) async {
      final owner = ValueNotifier<String?>('first');
      final admission = ValueNotifier<bool>(true);
      addTearDown(owner.dispose); addTearDown(admission.dispose);
      await _open(t, owner: owner, admission: admission);
      await _tap(t, 'taikyoku-lesson-1');
      await _prepareReport(t, _course().lessons.first);
      await _show(t, 'taikyoku-report-written');
      final stale = t.widget<TextButton>(find.byKey(const Key('taikyoku-report-written'))).onPressed!;
      if (interrupt == 'owner') { owner.value = 'second'; } else { admission.value = false; }
      stale(); await t.pumpAndSettle(); stale(); await t.pumpAndSettle();
      expect(find.byType(TaikyokuCoursePage, skipOffstage: false), findsNothing);
      expect(find.byType(TaikyokuLessonPage, skipOffstage: false), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('leaving and reopening the course never restores per-visit written progress', (t) async {
    await _open(t); await _tap(t, 'taikyoku-lesson-1');
    await _prepareReport(t, _course().lessons.first); await _tap(t, 'taikyoku-report-written');
    await t.pageBack(); await t.pumpAndSettle();
    await _show(t, 'taikyoku-written-progress', fromTop: true);
    expect(find.textContaining('1/10'), findsOneWidget);
    await t.pageBack(); await t.pumpAndSettle();
    await t.tap(find.text('Open')); await t.pumpAndSettle();
    await _show(t, 'taikyoku-written-progress', fromTop: true);
    expect(find.textContaining('0/10'), findsOneWidget);
  });

  testWidgets('an interrupted load is discarded and resume admits only a fresh load', (t) async {
    final first = Completer<TaikyokuCourse>();
    final second = Completer<TaikyokuCourse>();
    var calls = 0;
    await _open(t, loader: () => ++calls == 1 ? first.future : second.future);
    for (final state in [AppLifecycleState.inactive,AppLifecycleState.hidden,AppLifecycleState.paused]) {
      t.binding.handleAppLifecycleStateChanged(state);
    }
    first.complete(_course()); await t.pump();
    expect(find.byKey(const Key('taikyoku-course-list')), findsNothing);
    for (final state in [AppLifecycleState.hidden,AppLifecycleState.inactive,AppLifecycleState.resumed]) {
      t.binding.handleAppLifecycleStateChanged(state);
    }
    expect(calls, 2);
    second.complete(_course()); await t.pumpAndSettle();
    expect(find.byKey(const Key('taikyoku-course-list')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('stale pending load cannot restore retired owner content', (t) async {
    final owner = ValueNotifier<String?>('first'); addTearDown(owner.dispose);
    final pending = Completer<TaikyokuCourse>();
    await _open(t, owner: owner, loader: () => pending.future);
    owner.value = 'second'; await t.pump();
    pending.complete(_course()); await t.pumpAndSettle();
    expect(find.byType(TaikyokuCoursePage, skipOffstage: false), findsNothing);
    expect(find.byKey(const Key('taikyoku-course-list')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('owner retirement inside didPush cannot build a stale lesson', (t) async {
    final owner = ValueNotifier<String?>('first'); addTearDown(owner.dispose);
    final observer = _PushObserver();
    await _open(t, owner: owner, observer: observer);
    observer.next = () { owner.value = 'second'; };
    await _tap(t, 'taikyoku-lesson-1');
    expect(find.byType(TaikyokuCoursePage, skipOffstage: false), findsNothing);
    expect(find.byType(TaikyokuLessonPage, skipOffstage: false), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('integrity failure blocks lesson content and progress with no repair-by-retry claim', (t) async {
    await _open(t, loader: () async => throw const ContentException(
      ContentError(code: ContentErrorCode.hashMismatch)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('taikyoku-load-failure')), findsOneWidget);
    expect(find.byKey(const Key('taikyoku-retry')), findsNothing);
    expect(find.byKey(const Key('taikyoku-course-list')), findsNothing);
    expect(find.byKey(const Key('taikyoku-written-progress')), findsNothing);
    expect(t.takeException(), isNull);
  });
}

class _PushObserver extends NavigatorObserver {
  VoidCallback? next;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final action = next; next = null; action?.call();
  }
}
