import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:jablab/app/solo_boxing_course_page.dart';

import 'app_pump.dart';

void main() {
  late Directory directory;
  setUp(
    () => directory = Directory.systemTemp.createTempSync('jablab-solo-ui-'),
  );
  tearDown(() => directory.deleteSync(recursive: true));

  testWidgets('first-run catalogue opens the full solo course', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        JabLabApp(
          repository: ContentRepository(historyDirectoryOverride: directory),
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

  testWidgets('self-report flow saves and reloads one completed lesson', (
    WidgetTester tester,
  ) async {
    final ContentRepository repository = ContentRepository(
      historyDirectoryOverride: directory,
      loadStringOverride: (String path) => File(path).readAsString(),
    );
    await tester.pumpWidget(
      MaterialApp(home: SoloBoxingCoursePage(repository: repository)),
    );
    await settleUntil(tester, find.byKey(const Key('solo-course-progress')));
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
    await settleUntil(tester, find.text('LEARN'));
    final Finder lessonScroll = find
        .descendant(
          of: find.byKey(const Key('solo-lesson-list')),
          matching: find.byType(Scrollable),
        )
        .first;

    final Finder practised = find.byKey(const Key('solo-mark-practised'));
    await tester.scrollUntilVisible(
      practised,
      800,
      maxScrolls: 12,
      scrollable: lessonScroll,
    );
    await tester.tap(practised);
    await settleUntil(tester, find.textContaining('Practise again'));

    for (int i = 0; i < 2; i++) {
      final Finder check = find.byKey(Key('solo-check-boxing.start.space-$i'));
      await tester.scrollUntilVisible(
        check,
        -800,
        maxScrolls: 12,
        scrollable: lessonScroll,
      );
      await tester.tap(check);
      await tester.pump();
    }
    final Finder complete = find.byKey(const Key('solo-mark-complete'));
    await tester.scrollUntilVisible(
      complete,
      800,
      maxScrolls: 12,
      scrollable: lessonScroll,
    );
    await tester.tap(complete);
    await settleUntil(tester, find.textContaining('Self-reported complete'));
    await tester.pageBack();
    await settleUntil(tester, find.text('1 / 39 self-reported complete'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(home: SoloBoxingCoursePage(repository: repository)),
    );
    await settleUntil(tester, find.text('1 / 39 self-reported complete'));
  });

  testWidgets('account change clears the previous solo progress', (
    WidgetTester tester,
  ) async {
    const String alice = '11111111-1111-4111-8111-111111111111';
    const String bob = '22222222-2222-4222-8222-222222222222';
    final ValueNotifier<String?> account = ValueNotifier<String?>(alice);
    final ContentRepository repository = ContentRepository(
      historyDirectoryOverride: directory,
      loadStringOverride: (String path) => File(path).readAsString(),
    );
    await tester.runAsync(() async {
      final SoloBoxingCourse course = await repository.loadSoloBoxingCourse();
      final store = await repository.openSoloProgressStore(
        accountUserId: alice,
      );
      await store.markPractised(course, course.lessons.first);
      await store.markCompleted(
        course,
        course.lessons.first,
        selfChecksConfirmed: true,
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SoloBoxingCoursePage(
          repository: repository,
          accountUserId: account,
        ),
      ),
    );
    await settleUntil(tester, find.text('1 / 39 self-reported complete'));
    expect(find.text('1 / 39 self-reported complete'), findsOneWidget);
    account.value = bob;
    await tester.pump();
    expect(find.text('1 / 39 self-reported complete'), findsNothing);
    await settleUntil(tester, find.text('0 / 39 self-reported complete'));
    expect(find.text('0 / 39 self-reported complete'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    account.dispose();
  });
}
