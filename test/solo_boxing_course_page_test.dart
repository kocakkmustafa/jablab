import 'localization_fixture.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:jablab/app/solo_boxing_course_page.dart';
import 'package:jablab/app/solo_boxing_progress.dart';

import 'app_pump.dart';

// Each test owns a storage namespace; replacements inside it share this registry.
late OwnerResourceRegistry _owners;

void main() {
  setUp(() => _owners = OwnerResourceRegistry());
  late Directory directory;
  setUp(
    () => directory = Directory.systemTemp.createTempSync('jablab-solo-ui-'),
  );
  tearDown(() => directory.deleteSync(recursive: true));

  Future<void> tapCentered(WidgetTester tester, Finder finder) async {
    expect(finder, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
    await tester.pumpAndSettle();
    expect(finder.hitTestable(), findsOneWidget);
    await tester.tap(finder.hitTestable());
    await tester.pumpAndSettle();
  }

  testWidgets('first-run catalogue opens the full solo course', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        JabLabApp(
          repository: ContentRepository(
            historyDirectoryOverride: directory,
            ownerRegistry: _owners,
          ),
          onboarding: const OnboardingStore(seenOverride: true),
        ),
      );
    });
    await settleAppLoad(tester);
    await settleUntil(tester, find.byKey(const Key('open-solo-boxing-course')));
    await tester.tap(find.byKey(const Key('open-solo-boxing-course')));
    await settleUntil(tester, find.byKey(const Key('solo-course-progress')));
    expect(find.text('0 / 39 self-reported complete'), findsOneWidget);
    expect(find.byKey(const Key('solo-next-lesson')), findsOneWidget);
  });

  for (final bool turkish in <bool>[false, true]) {
    testWidgets(
      'one-round ${turkish ? 'TR' : 'EN'} option can be reported without a second-round claim',
      (WidgetTester tester) async {
        tester.binding.platformDispatcher.localesTestValue = <Locale>[
          Locale(turkish ? 'tr' : 'en'),
        ];
        addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
        final course = SoloBoxingCourse.fromJsonString(
          File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
        );
        final lesson = course.lessons.singleWhere(
          (item) => item.id == 'boxing.integration.two_round_rehearsal',
        );
        final store = SoloCourseProgressStore(
          File('${directory.path}/one-round-${turkish ? 'tr' : 'en'}.json'),
          ownerLifetime: _owners.capture(null),
        );
        final checkText = lesson.selfChecks
            .map((check) => turkish ? check.tr : check.en)
            .join(' ')
            .toLowerCase();
        expect(checkText, contains(turkish ? 'tek raunt' : 'one round'));
        expect(
          checkText,
          isNot(contains(turkish ? 'iki rauntta da' : 'both rounds')),
        );
        await tester.pumpWidget(
          MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
            home: SoloBoxingLessonPage(
              course: course,
              lesson: lesson,
              store: store,
              initialProgress: null,
              accountAtOpen: null,
            ),
          ),
        );
    await settleTestLocalizations(tester, expectedLocale: Locale(turkish ? 'tr' : 'en'));
        final lessonScroll = find
            .descendant(
              of: find.byKey(const Key('solo-lesson-list')),
              matching: find.byType(Scrollable),
            )
            .first;
        final complete = find.byKey(const Key('solo-mark-complete'));
        await tester.scrollUntilVisible(
          complete,
          600,
          maxScrolls: 20,
          scrollable: lessonScroll,
        );
        expect(tester.widget<OutlinedButton>(complete).onPressed, isNull);
        final prepared = find.byKey(const Key('solo-session-prepared'));
        await tester.scrollUntilVisible(
          prepared,
          -600,
          maxScrolls: 20,
          scrollable: lessonScroll,
        );
        expect(tester.widget<CheckboxListTile>(prepared).value, isFalse);
        await tapCentered(tester, prepared);
        final practised = find.byKey(const Key('solo-mark-practised'));
        await tester.scrollUntilVisible(
          practised,
          600,
          maxScrolls: 20,
          scrollable: lessonScroll,
        );
        await tapCentered(tester, practised);
        await settleUntil(
          tester,
          find.textContaining(turkish ? 'Yeniden çalış' : 'Practise again'),
        );
        await tester.scrollUntilVisible(
          complete,
          600,
          maxScrolls: 20,
          scrollable: lessonScroll,
        );
        expect(tester.widget<OutlinedButton>(complete).onPressed, isNull);
        for (int i = 0; i < lesson.selfChecks.length; i++) {
          final check = find.byKey(Key('solo-check-${lesson.id}-$i'));
          await tester.scrollUntilVisible(
            check,
            -600,
            maxScrolls: 20,
            scrollable: lessonScroll,
          );
          final tile = tester.widget<CheckboxListTile>(check);
          expect(
            (tile.title! as Text).data,
            turkish ? lesson.selfChecks[i].tr : lesson.selfChecks[i].en,
          );
          await tapCentered(tester, check);
        }
        await tester.scrollUntilVisible(
          complete,
          600,
          maxScrolls: 20,
          scrollable: lessonScroll,
        );
        await tapCentered(tester, complete);
        await settleUntil(
          tester,
          find.textContaining(
            turkish ? 'Öz beyanla tamamlandı' : 'Self-reported complete',
          ),
        );
        final saved = (await tester.runAsync(store.load))!;
        final progress = saved.forLesson(lesson, course.version)!;
        expect(progress.state, SoloLessonState.selfReportedComplete);
        expect(progress.practiceCount, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('standalone lead hook requires fresh-session preparation', (
    WidgetTester tester,
  ) async {
    final course = SoloBoxingCourse.fromJsonString(
      File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
    );
    final lesson = course.lessons.singleWhere(
      (item) => item.id == 'boxing.curves.lead_hook',
    );
    final store = SoloCourseProgressStore(
      File('${directory.path}/hook.json'),
      ownerLifetime: _owners.capture(null),
    );
    await tester.pumpWidget(
      MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
        home: SoloBoxingLessonPage(
          course: course,
          lesson: lesson,
          store: store,
          initialProgress: null,
          accountAtOpen: null,
        ),
      ),
    );
    await settleTestLocalizations(tester);
    final lessonScroll = find
        .descendant(
          of: find.byKey(const Key('solo-lesson-list')),
          matching: find.byType(Scrollable),
        )
        .first;
    final prepared = find.byKey(const Key('solo-session-prepared'));
    await tester.scrollUntilVisible(
      prepared,
      300,
      maxScrolls: 20,
      scrollable: lessonScroll,
    );
    expect(find.text('PREPARE THIS SESSION'), findsOneWidget);
    expect(find.textContaining('small, slow arc'), findsOneWidget);
    final practised = find.byKey(const Key('solo-mark-practised'));
    await tester.scrollUntilVisible(
      practised,
      600,
      maxScrolls: 20,
      scrollable: lessonScroll,
    );
    expect(tester.widget<FilledButton>(practised).onPressed, isNull);
    await tester.scrollUntilVisible(
      prepared,
      -600,
      maxScrolls: 20,
      scrollable: lessonScroll,
    );
    await tapCentered(tester, prepared);
    await tester.scrollUntilVisible(
      practised,
      600,
      maxScrolls: 20,
      scrollable: lessonScroll,
    );
    expect(tester.widget<FilledButton>(practised).onPressed, isNotNull);
    await tapCentered(tester, practised);
    await settleUntil(tester, find.textContaining('Practise again'));
    final saved = (await tester.runAsync(store.load))!;
    expect(saved.forLesson(lesson, course.version)!.practiceCount, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('fresh physical session', () {
    late SoloBoxingCourse course;
    late SoloLesson lesson;
    late SoloCourseProgressStore store;
    late DateTime now;

    setUp(() {
      course = SoloBoxingCourse.fromJsonString(
        File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
      );
      lesson = course.lessons.singleWhere(
        (item) => item.id == 'boxing.curves.lead_hook',
      );
      store = SoloCourseProgressStore(
        File('${directory.path}/fresh.json'),
        ownerLifetime: _owners.capture(null),
      );
      now = DateTime(2026, 9, 28, 12);
    });

    Future<Finder> reveal(WidgetTester tester, String key) async {
      final scrollable = find
          .descendant(
            of: find.byKey(const Key('solo-lesson-list')),
            matching: find.byType(Scrollable),
          )
          .first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pump();
      final target = find.byKey(Key(key));
      await tester.scrollUntilVisible(
        target,
        350,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      return target;
    }

    Future<void> open(WidgetTester tester, {bool priorPractice = false, Locale? expectedLocale}) async {
      SoloLessonProgress? prior;
      if (priorPractice) {
        final saved = (await tester.runAsync(
          () => store.markPractised(course, lesson),
        ))!;
        prior = saved.forLesson(lesson, course.version);
      }
      await tester.pumpWidget(
        MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
          home: SoloBoxingLessonPage(
            course: course,
            lesson: lesson,
            store: store,
            initialProgress: prior,
            accountAtOpen: null,
            preparationClock: () => now,
          ),
        ),
      );
    await settleTestLocalizations(tester, expectedLocale: expectedLocale);
    }

    Future<void> acknowledge(WidgetTester tester) async {
      await tapCentered(tester, await reveal(tester, 'solo-session-prepared'));
    }

    void leaveForeground(WidgetTester tester, AppLifecycleState state) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      if (state == AppLifecycleState.paused) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      }
    }

    void resume(WidgetTester tester, AppLifecycleState state) {
      if (state == AppLifecycleState.paused) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }

    Future<void> expectBlocked(
      WidgetTester tester, {
      bool turkish = false,
    }) async {
      await reveal(tester, 'solo-preparation-required');
      expect(
        find.text(turkish ? lesson.practice.tr : lesson.practice.en),
        findsNothing,
      );
      expect(
        tester
            .widget<FilledButton>(await reveal(tester, 'solo-mark-practised'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(await reveal(tester, 'solo-mark-complete'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              await reveal(tester, 'solo-session-prepared'),
            )
            .value,
        isFalse,
      );
    }

    for (final turkish in [false, true]) {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
      ]) {
        testWidgets(
          '${turkish ? 'TR' : 'EN'} ${state.name} invalidates prior practice and preparation',
          (tester) async {
            tester.binding.platformDispatcher.localesTestValue = <Locale>[
              Locale(turkish ? 'tr' : 'en'),
            ];
            addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
            await open(tester, priorPractice: true, expectedLocale: Locale(turkish ? 'tr' : 'en'));
            await expectBlocked(tester, turkish: turkish);
            await acknowledge(tester);
            final check = await reveal(tester, 'solo-check-${lesson.id}-0');
            expect(
              find.text(turkish ? lesson.practice.tr : lesson.practice.en),
              findsOneWidget,
            );
            expect(tester.widget<CheckboxListTile>(check).onChanged, isNotNull);
            for (var i = 0; i < lesson.selfChecks.length; i++) {
              await tapCentered(
                tester,
                await reveal(tester, 'solo-check-${lesson.id}-$i'),
              );
            }
            // Yesterday's saved practice is not this session's physical attempt.
            expect(
              tester
                  .widget<OutlinedButton>(
                    await reveal(tester, 'solo-mark-complete'),
                  )
                  .onPressed,
              isNull,
            );
            leaveForeground(tester, state);
            await tester.pump();
            resume(tester, state);
            await tester.pump();
            await expectBlocked(tester, turkish: turkish);
            final saved = (await tester.runAsync(store.load))!;
            expect(saved.forLesson(lesson, course.version)!.practiceCount, 1);
            expect(
              saved.forLesson(lesson, course.version)!.state,
              SoloLessonState.practised,
            );
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }

    testWidgets('manual break closes copy and both physical record actions', (
      tester,
    ) async {
      await open(tester, priorPractice: true);
      await acknowledge(tester);
      await tapCentered(tester, await reveal(tester, 'solo-session-break'));
      await expectBlocked(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'overnight expiry and stale callback cannot carry readiness into tomorrow',
      (tester) async {
        now = DateTime(2026, 9, 28, 23, 59, 50);
        await open(tester, priorPractice: true);
        await acknowledge(tester);
        final staleSave = tester
            .widget<FilledButton>(await reveal(tester, 'solo-mark-practised'))
            .onPressed!;
        now = DateTime(2026, 9, 29);
        staleSave();
        await tester.pump(const Duration(seconds: 11));
        await expectBlocked(tester);
        final saved = (await tester.runAsync(store.load))!;
        expect(saved.forLesson(lesson, course.version)!.practiceCount, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'late pre-break save cannot count as practice in a new session',
      (tester) async {
        await open(tester);
        await acknowledge(tester);
        tester
            .widget<FilledButton>(await reveal(tester, 'solo-mark-practised'))
            .onPressed!();
        leaveForeground(tester, AppLifecycleState.paused);
        await tester.pump();
        resume(tester, AppLifecycleState.paused);
        await settleUntil(tester, find.textContaining('Practise again'));
        await acknowledge(tester);
        for (var i = 0; i < lesson.selfChecks.length; i++) {
          await tapCentered(
            tester,
            await reveal(tester, 'solo-check-${lesson.id}-$i'),
          );
        }
        expect(
          tester
              .widget<OutlinedButton>(
                await reveal(tester, 'solo-mark-complete'),
              )
              .onPressed,
          isNull,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'spoken space and breath lessons need no physical preparation',
      (tester) async {
        for (final id in ['boxing.start.space', 'boxing.start.breath']) {
          lesson = course.lessons.singleWhere((item) => item.id == id);
          await open(tester);
          expect(find.byKey(const Key('solo-session-prepared')), findsNothing);
          expect(
            tester
                .widget<FilledButton>(
                  await reveal(tester, 'solo-mark-practised'),
                )
                .onPressed,
            isNotNull,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  });

  for (final bool turkish in <bool>[false, true]) {
    testWidgets(
      'self-report ${turkish ? 'TR' : 'EN'} flow survives real back and reopen',
      (WidgetTester tester) async {
        tester.binding.platformDispatcher.localesTestValue = <Locale>[
          Locale(turkish ? 'tr' : 'en'),
        ];
        addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
        final ContentRepository repository = ContentRepository(
          ownerRegistry: _owners,
          historyDirectoryOverride: directory,
          loadStringOverride: (String path) => File(path).readAsString(),
        );
        await tester.pumpWidget(
          MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales, home: SoloBoxingCoursePage(repository: repository)),
        );
    await settleTestLocalizations(tester, expectedLocale: Locale(turkish ? 'tr' : 'en'));
        await settleUntil(
          tester,
          find.byKey(const Key('solo-course-progress')),
        );
        // Diagnostic on failure: preserve the visible error instead of an absent-key message.
        expect(
          find.byKey(const Key('solo-course-progress')),
          findsOneWidget,
          reason: tester
              .widgetList<Text>(find.byType(Text))
              .map((Text text) => text.data)
              .join(' | '),
        );
        await tester.tap(find.byKey(const Key('solo-next-lesson')));
        await settleUntil(tester, find.text(turkish ? 'ÖĞREN' : 'LEARN'));
        final SoloBoxingCourse course = SoloBoxingCourse.fromJsonString(
          File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
        );
        final SoloLesson first = course.lessons.first;
        final Finder lessonScroll = find
            .descendant(
              of: find.byKey(const Key('solo-lesson-list')),
              matching: find.byType(Scrollable),
            )
            .first;

        final Finder practiceText = find.text(
          turkish ? first.practice.tr : first.practice.en,
        );
        await tester.scrollUntilVisible(
          practiceText,
          600,
          maxScrolls: 20,
          scrollable: lessonScroll,
        );
        expect(practiceText, findsOneWidget);
        final Finder practised = find.byKey(const Key('solo-mark-practised'));
        await tester.scrollUntilVisible(
          practised,
          800,
          maxScrolls: 12,
          scrollable: lessonScroll,
        );
        await tapCentered(tester, practised);
        await settleUntil(
          tester,
          find.textContaining(turkish ? 'Yeniden çalış' : 'Practise again'),
        );

        for (int i = 0; i < first.selfChecks.length; i++) {
          final Finder check = find.byKey(
            Key('solo-check-boxing.start.space-$i'),
          );
          await tester.scrollUntilVisible(
            check,
            -800,
            maxScrolls: 12,
            scrollable: lessonScroll,
          );
          await tapCentered(tester, check);
          await tester.pump();
        }
        final Finder complete = find.byKey(const Key('solo-mark-complete'));
        await tester.scrollUntilVisible(
          complete,
          800,
          maxScrolls: 12,
          scrollable: lessonScroll,
        );
        await tapCentered(tester, complete);
        await settleUntil(
          tester,
          find.textContaining(
            turkish ? 'Öz beyanla tamamlandı' : 'Self-reported complete',
          ),
        );
        await tester.tap(find.byType(BackButton));
        final String total = turkish
            ? '1 / 39 öz beyanla tamamlandı'
            : '1 / 39 self-reported complete';
        await settleUntil(tester, find.text(total));
        expect(find.text(total), findsOneWidget);
        final store = (await tester.runAsync(
          () => repository.openSoloProgressStore(),
        ))!;
        final saved = await tester.runAsync(store.load);
        expect(saved!.forLesson(first, course.version)!.practiceCount, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales, home: SoloBoxingCoursePage(repository: repository)),
        );
    await settleTestLocalizations(tester, expectedLocale: Locale(turkish ? 'tr' : 'en'));
        await settleUntil(tester, find.text(total));
        expect(find.text(total), findsOneWidget);
        final Finder firstRow = find.byKey(
          const Key('solo-lesson-boxing.start.space'),
        );
        await tester.scrollUntilVisible(
          firstRow,
          500,
          maxScrolls: 20,
          scrollable: find.byType(Scrollable).last,
        );
        await tapCentered(tester, firstRow);
        await settleUntil(tester, find.text(turkish ? 'ÖĞREN' : 'LEARN'));
        final Finder savedPractice = find.byKey(
          const Key('solo-mark-practised'),
        );
        await tester.scrollUntilVisible(
          savedPractice,
          800,
          maxScrolls: 20,
          scrollable: lessonScroll,
        );
        expect(
          find.text(
            turkish ? 'Yeniden çalış · 1 kayıt' : 'Practise again · 1 recorded',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('old v1 completion is retained with the new self-check text', (
    tester,
  ) async {
    final repository = ContentRepository(
      ownerRegistry: _owners,
      historyDirectoryOverride: directory,
      loadStringOverride: (String path) => File(path).readAsString(),
    );
    final store = (await tester.runAsync(
      () => repository.openSoloProgressStore(),
    ))!;
    final old = jsonEncode({
      'schemaVersion': 1,
      'courseId': 'jablab.solo_boxing',
      'lessons': {
        'boxing.start.space': {
          'contentVersion': 1,
          'state': 'selfReportedComplete',
          'viewedAt': '2026-09-26T12:00:00Z',
          'lastPractisedAt': '2026-09-26T12:01:00Z',
          'completedAt': '2026-09-26T12:02:00Z',
          'practiceCount': 2,
        },
      },
    });
    store.file.writeAsStringSync(old);
    await tester.pumpWidget(
      MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales, home: SoloBoxingCoursePage(repository: repository)),
    );
    await settleTestLocalizations(tester);
    await settleUntil(tester, find.text('1 / 39 self-reported complete'));
    expect(find.text('1 / 39 self-reported complete'), findsOneWidget);
    expect(store.file.readAsStringSync(), old);
    final saved = await tester.runAsync(store.load);
    expect(saved!.records['boxing.start.space']!.practiceCount, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'account change closes the old lesson and loads persisted Bob progress',
    (WidgetTester tester) async {
      const String alice = '11111111-1111-4111-8111-111111111111';
      const String bob = '22222222-2222-4222-8222-222222222222';
      _owners.activate(alice);
      _owners.activate(bob);
      final ValueNotifier<String?> account = ValueNotifier<String?>(alice);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        account.dispose();
      });
      final ContentRepository repository = ContentRepository(
        ownerRegistry: _owners,
        historyDirectoryOverride: directory,
        loadStringOverride: (String path) => File(path).readAsString(),
      );
      late SoloBoxingCourse course;
      late SoloCourseProgressStore aliceStore;
      late SoloCourseProgressStore bobStore;
      await tester.runAsync(() async {
        course = await repository.loadSoloBoxingCourse();
        aliceStore = await repository.openSoloProgressStore(
          accountUserId: alice,
        );
        await aliceStore.markPractised(course, course.lessons.first);
        await aliceStore.markCompleted(
          course,
          course.lessons.first,
          selfChecksConfirmed: true,
        );
        bobStore = await repository.openSoloProgressStore(accountUserId: bob);
        await bobStore.markPractised(course, course.lessons.last);
      });
      final bobBytes = bobStore.file.readAsStringSync();
      await tester.pumpWidget(
        MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales,
          home: SoloBoxingCoursePage(
            repository: repository,
            accountUserId: account,
          ),
        ),
      );
    await settleTestLocalizations(tester);
      await settleUntil(tester, find.text('1 / 39 self-reported complete'));
      expect(find.text('1 / 39 self-reported complete'), findsOneWidget);
      await tester.tap(find.byKey(const Key('solo-next-lesson')));
      await settleUntil(tester, find.byType(SoloBoxingLessonPage));
      expect(find.byType(SoloBoxingLessonPage), findsOneWidget);
      final oldRoute = ModalRoute.of(
        tester.element(find.byType(SoloBoxingLessonPage)),
      )!;
      expect(oldRoute.isFirst, isFalse);
      final aliceBytes = aliceStore.file.readAsStringSync();

      account.value = bob;
      await tester.pump();
      expect(
        find.text('1 / 39 self-reported complete', skipOffstage: false),
        findsNothing,
      );
      await settleUntil(tester, find.text('0 / 39 self-reported complete'));
      expect(find.text('0 / 39 self-reported complete'), findsOneWidget);
      expect(oldRoute.isActive, isFalse);
      expect(
        find.byType(SoloBoxingLessonPage, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byType(SoloBoxingCoursePage),
        findsOneWidget,
        reason:
            'the standalone course reloads Bob after its Alice lesson retires',
      );
      final freshBob = (await tester.runAsync(
        () => repository.openSoloProgressStore(accountUserId: bob),
      ))!;
      final persistedBob = (await tester.runAsync(freshBob.load))!;
      expect(
        persistedBob
            .forLesson(course.lessons.last, course.version)!
            .practiceCount,
        1,
      );
      expect(
        persistedBob.forLesson(course.lessons.first, course.version),
        isNull,
      );
      expect(freshBob.file.path, bobStore.file.path);
      expect(freshBob.file.readAsStringSync(), bobBytes);
      expect(aliceStore.file.readAsStringSync(), aliceBytes);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
