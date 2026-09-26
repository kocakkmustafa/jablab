import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jablab/app/account_bridge.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native solo course saves, reopens and isolates account progress', (
    tester,
  ) async {
    const alice = '11111111-1111-4111-8111-111111111111';
    const bob = '22222222-2222-4222-8222-222222222222';
    final support = await getApplicationSupportDirectory();
    final directory = await Directory(
      '${support.path}/solo-course-test-${DateTime.now().microsecondsSinceEpoch}',
    ).create();
    final owner = ValueNotifier<String?>(alice);
    addTearDown(() async {
      owner.dispose();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final repository = ContentRepository(historyDirectoryOverride: directory);
    final course = await repository.loadSoloBoxingCourse();
    expect(course.lessons.length, 39);

    Widget app() => JabLabApp(
      repository: repository,
      accountUserId: owner,
      onboarding: const OnboardingStore(seenOverride: true),
    );
    Future<void> capture(String name) async {
      if (const bool.fromEnvironment('COURSE_SCREENSHOTS') && Platform.isIOS) {
        await binding.takeScreenshot(name);
      }
    }

    Future<void> waitFor(bool Function() ready) async {
      for (var i = 0; i < 80 && !ready(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(ready(), isTrue, reason: 'Native file/UI action did not complete');
    }

    Finder pageScroll() {
      final lesson = find.byKey(const Key('solo-lesson-list'));
      final list = lesson.evaluate().isNotEmpty
          ? lesson
          : find.byType(ListView).first;
      // Selectable source text has its own tiny inner scrollable.
      return find.descendant(of: list, matching: find.byType(Scrollable)).first;
    }

    Future<void> tap(Key key, {double delta = 600}) async {
      final target = find.byKey(key);
      if (target.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          target,
          delta,
          maxScrolls: 20,
          scrollable: pageScroll(),
        );
      } else {
        await tester.ensureVisible(target);
      }
      await tester.pumpAndSettle();
      await waitFor(() {
        final widget = tester.widget(target);
        return widget is! ButtonStyleButton || widget.onPressed != null;
      });
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tap(const Key('open-solo-boxing-course'));
    await waitFor(() => find.textContaining('0 / 39').evaluate().isNotEmpty);
    expect(find.textContaining('0 / 39'), findsOneWidget);
    await capture('jablab-course');
    await tap(const Key('solo-next-lesson'));
    await capture('jablab-lesson');
    await tap(const Key('solo-mark-practised'));
    for (var i = 0; i < 2; i++) {
      await tap(Key('solo-check-boxing.start.space-$i'), delta: -600);
    }
    await tap(const Key('solo-mark-complete'));
    await waitFor(() {
      final storeText = tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('solo-mark-complete')),
              matching: find.byType(Text),
            ),
          )
          .data!;
      return storeText.startsWith('Self-reported complete') ||
          storeText.startsWith('Öz beyanla tamamlandı');
    });
    // The retained simulator uses Turkish; pageBack() assumes "Back".
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('solo-course-progress')),
      -500,
      maxScrolls: 20,
      scrollable: pageScroll(),
    );
    await waitFor(() => find.textContaining('1 / 39').evaluate().isNotEmpty);
    expect(find.textContaining('1 / 39'), findsOneWidget);
    await capture('jablab-progress');
    final reopened = await repository.openSoloProgressStore(
      accountUserId: alice,
    );
    expect((await reopened.load()).completedCount(course), 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tap(const Key('open-solo-boxing-course'));
    await waitFor(() => find.textContaining('1 / 39').evaluate().isNotEmpty);
    expect(find.textContaining('1 / 39'), findsOneWidget);
    owner.value = bob;
    await tester.pumpAndSettle();
    await waitFor(() => find.textContaining('0 / 39').evaluate().isNotEmpty);
    expect(find.textContaining('0 / 39'), findsOneWidget);
    await clearLocalHistoryFor(alice, supportDirectory: directory);
    expect(await courseFileFor(directory, alice).exists(), isFalse);
    await expectLater(reopened.load(), throwsStateError);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
