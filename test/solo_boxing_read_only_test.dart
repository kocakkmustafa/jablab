import 'localization_fixture.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/account_bridge.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:jablab/app/solo_boxing_course_page.dart';

import 'app_pump.dart';

void main() {
  late Directory directory;
  late OwnerResourceRegistry owners;
  late ContentRepository repository;
  late SoloBoxingCourse course;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('jablab-read-only-');
    owners = OwnerResourceRegistry();
    repository = ContentRepository(
      ownerRegistry: owners,
      historyDirectoryOverride: directory,
      loadStringOverride: (path) => File(path).readAsString(),
    );
    course = SoloBoxingCourse.fromJsonString(
      File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
    );
  });
  tearDown(() => directory.deleteSync(recursive: true));

  Finder lessonScroll() => find.descendant(
    of: find.byKey(const Key('solo-lesson-list')),
    matching: find.byType(Scrollable),
  ).first;

  Finder pageScroll() => find.byType(SoloBoxingLessonPage).evaluate().isNotEmpty
      ? lessonScroll()
      : find.descendant(
          of: find.byType(SoloBoxingCoursePage),
          matching: find.byType(Scrollable),
        ).first;

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      maxScrolls: 20,
      scrollable: pageScroll(),
    );
    expect(target, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget);
  }

  Future<void> openFirstLesson(WidgetTester tester) async {
    final target = find.byKey(Key('solo-lesson-${course.lessons.first.id}'));
    await reveal(tester, target);
    await tester.tap(target.hitTestable());
    await settleUntil(tester, find.byType(SoloBoxingLessonPage));
    await tester.pumpAndSettle();
  }

  Future<void> expectReadOnlyLesson(WidgetTester tester) async {
    expect(find.byKey(const Key('solo-progress-unavailable')), findsOneWidget);
    expect(tester.widget<SoloBoxingLessonPage>(find.byType(SoloBoxingLessonPage)).readOnly, isTrue);
    final practised = find.byKey(const Key('solo-mark-practised'));
    final complete = find.byKey(const Key('solo-mark-complete'));
    await reveal(tester, practised);
    expect(tester.widget<FilledButton>(practised).onPressed, isNull);
    await reveal(tester, complete);
    expect(tester.widget<OutlinedButton>(complete).onPressed, isNull);
    expect(tester.takeException(), isNull);
  }

  for (final turkish in [false, true]) {
    for (final wrongType in [false, true]) {
      testWidgets('unreadable ${wrongType ? 'directory' : 'JSON'} ${turkish ? 'TR' : 'EN'} keeps lessons readable without zero totals', (tester) async {
        tester.binding.platformDispatcher.localesTestValue = <Locale>[Locale(turkish ? 'tr' : 'en')];
        addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
        final file = courseFileFor(directory, null);
        const raw = '{preserve this broken progress';
        if (wrongType) {
          Directory(file.path).createSync();
          File('${file.path}/sentinel').writeAsStringSync(raw);
        } else {
          file.writeAsStringSync(raw);
        }
        await tester.pumpWidget(MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales, home: SoloBoxingCoursePage(repository: repository)));
    await settleTestLocalizations(tester, expectedLocale: Locale(turkish ? 'tr' : 'en'));
        await settleUntil(tester, find.byKey(const Key('solo-progress-unavailable')));
        expect(find.byKey(const Key('solo-course-progress')), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.byKey(const Key('solo-next-lesson')), findsNothing);
        expect(find.textContaining('0 /'), findsNothing);
        await openFirstLesson(tester);
        await expectReadOnlyLesson(tester);
        final step = find.text(turkish ? course.lessons.first.steps.first.tr : course.lessons.first.steps.first.en);
        await tester.scrollUntilVisible(step, -300, maxScrolls: 20, scrollable: pageScroll());
        expect(step, findsOneWidget);
        expect(File(wrongType ? '${file.path}/sentinel' : file.path).readAsStringSync(), raw);
        expect(FileSystemEntity.typeSync('${file.path}.tmp', followLinks: false), FileSystemEntityType.notFound);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('viewed write failure opens read-only and preserves both files', (tester) async {
    final store = (await tester.runAsync(() => repository.openSoloProgressStore()))!;
    await tester.runAsync(() => store.markPractised(course, course.lessons.first));
    final original = store.file.readAsBytesSync();
    final pending = File('${store.file.path}.tmp')..writeAsStringSync('pending bytes');
    await tester.pumpWidget(MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales, home: SoloBoxingCoursePage(repository: repository)));
    await settleTestLocalizations(tester);
    await settleUntil(tester, find.byKey(const Key('solo-course-progress')));
    await openFirstLesson(tester);
    await expectReadOnlyLesson(tester);
    expect(store.file.readAsBytesSync(), original);
    expect(pending.readAsStringSync(), 'pending bytes');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('corruption after opening never turns a failed practice into success', (tester) async {
    await tester.pumpWidget(MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales, home: SoloBoxingCoursePage(repository: repository)));
    await settleTestLocalizations(tester);
    await settleUntil(tester, find.byKey(const Key('solo-course-progress')));
    await openFirstLesson(tester);
    final file = courseFileFor(directory, null);
    const raw = '{new damage';
    file.writeAsStringSync(raw);
    final practised = find.byKey(const Key('solo-mark-practised'));
    await reveal(tester, practised);
    expect(tester.widget<FilledButton>(practised).onPressed, isNotNull);
    await tester.tap(practised);
    await settleUntil(tester, find.byType(SnackBar));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.widget<FilledButton>(practised).onPressed, isNull);
    final notice = find.byKey(const Key('solo-progress-unavailable'));
    await tester.scrollUntilVisible(
      notice,
      -300,
      maxScrolls: 20,
      scrollable: pageScroll(),
    );
    expect(notice, findsOneWidget);
    expect(find.textContaining('Practise again'), findsNothing);
    expect(file.readAsStringSync(), raw);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('retry uses a fresh read and never silently resets damaged bytes', (tester) async {
    final file = courseFileFor(directory, null)..writeAsStringSync('{broken');
    await tester.pumpWidget(MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales, home: SoloBoxingCoursePage(repository: repository)));
    await settleTestLocalizations(tester);
    await settleUntil(tester, find.byKey(const Key('solo-progress-unavailable')));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('solo-progress-retry')));
      await settleUntil(tester, find.byKey(const Key('solo-progress-unavailable')));
      expect(file.readAsStringSync(), '{broken');
      expect(find.byKey(const Key('solo-course-progress')), findsNothing);
    }
    // An externally repaired, valid journal is re-read. The app did not repair it.
    const repaired = '{"schemaVersion":1,"courseId":"jablab.solo_boxing","lessons":{}}';
    file.writeAsStringSync(repaired);
    await tester.tap(find.byKey(const Key('solo-progress-retry')));
    await settleUntil(tester, find.byKey(const Key('solo-course-progress')));
    expect(find.text('0 / 39 self-reported complete'), findsOneWidget);
    expect(file.readAsStringSync(), repaired);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('owner change retires a read-only lesson without touching either owner', (tester) async {
    const alice = '11111111-1111-4111-8111-111111111111';
    const bob = '22222222-2222-4222-8222-222222222222';
    owners.activate(alice);
    owners.activate(bob);
    final account = ValueNotifier<String?>(alice);
    final aliceFile = courseFileFor(directory, alice)..writeAsStringSync('{alice damage');
    final bobStore = (await tester.runAsync(() => repository.openSoloProgressStore(accountUserId: bob)))!;
    await tester.runAsync(() => bobStore.markPractised(course, course.lessons.first));
    final bobBytes = bobStore.file.readAsBytesSync();
    await tester.pumpWidget(MaterialApp(supportedLocales: testSupportedLocales, localizationsDelegates: testLocalizationDelegates, localeListResolutionCallback: resolveTestLocales, home: SoloBoxingCoursePage(repository: repository, accountUserId: account)));
    await settleTestLocalizations(tester);
    await settleUntil(tester, find.byKey(const Key('solo-progress-unavailable')));
    await openFirstLesson(tester);
    expect(find.byType(SoloBoxingLessonPage), findsOneWidget);
    account.value = bob;
    await settleUntil(tester, find.byKey(const Key('solo-course-progress')));
    expect(find.byType(SoloBoxingLessonPage), findsNothing);
    expect(aliceFile.readAsStringSync(), '{alice damage');
    expect(bobStore.file.readAsBytesSync(), bobBytes);
    await tester.pumpWidget(const SizedBox.shrink());
    account.dispose();
  });
}
