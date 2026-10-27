import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/onboarding_page.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/main.dart' as production;

/// JAB-11 store screenshots: the seven fixed scenes, driven through the
/// production `main` (guest, build defines) on a freshly installed app.
///
/// The app does not capture anything itself. At each scene it prints
/// `JABLAB_SHOT <name>` and holds the frame while the host script takes the
/// simulator screenshot, so the image carries the real status bar and the
/// device's exact store resolution. Device language and light appearance
/// are set on the simulator by the host before the run.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshot scenes', (tester) async {
    Future<void> frames([int count = 20]) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // File and network work runs outside the fake clock, as in the boot test.
    Future<void> waitFor(bool Function() ready, String stage) async {
      for (var i = 0; i < 300 && !ready(); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(ready(), isTrue, reason: 'scene stage did not appear: $stage');
    }

    bool shown(Key key) => find.byKey(key).evaluate().isNotEmpty;

    Finder pageScroll() => find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;

    Future<void> reveal(Finder target) async {
      for (final double delta in <double>[400, -400]) {
        if (target.evaluate().isNotEmpty) break;
        try {
          await tester.scrollUntilVisible(
            target,
            delta,
            maxScrolls: 40,
            scrollable: pageScroll(),
          );
        } on StateError {
          // Not below the fold; try above.
        }
      }
      await tester.ensureVisible(target);
      await frames();
    }

    Future<void> tap(Key key) async {
      final target = find.byKey(key);
      await reveal(target);
      await waitFor(() {
        final widget = tester.widget(target);
        return widget is! ButtonStyleButton || widget.onPressed != null;
      }, '$key enabled');
      await tester.tap(target);
      await frames();
    }

    Future<void> home() async {
      for (var i = 0; i < 6; i++) {
        final navigators = find
            .byType(Navigator)
            .evaluate()
            .map((e) => (e as StatefulElement).state as NavigatorState)
            .where((n) => n.canPop())
            .toList();
        if (navigators.isEmpty) break;
        navigators.last.pop();
        await frames();
      }
      await frames();
    }

    Future<void> shot(String name) async {
      // Let tap indicators and route transitions fade out first.
      await frames(40);
      expect(tester.takeException(), isNull, reason: name);
      debugPrint('JABLAB_SHOT $name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 4)),
      );
    }

    await production.main();
    await waitFor(
      () =>
          find.byType(OnboardingPage).evaluate().isNotEmpty ||
          find.byType(SelectPage).evaluate().isNotEmpty ||
          find.byType(CoursePage).evaluate().isNotEmpty,
      'boot',
    );
    for (
      var i = 0;
      i < 3 && find.byType(OnboardingPage).evaluate().isNotEmpty;
      i++
    ) {
      await tap(const Key('onboarding-next'));
    }
    if (find.byType(SelectPage).evaluate().isEmpty) {
      await tap(const Key('open-select'));
    }
    await waitFor(
      () => find.byType(SelectPage).evaluate().isNotEmpty,
      'select page',
    );

    // 1. Page A: the five areas.
    await shot('01-areas');

    // 2. Boxing course.
    await tap(const Key('open-solo-boxing-course'));
    await waitFor(() => shown(const Key('solo-course-progress')), 'boxing');
    await shot('02-boxing-course');
    await home();

    // 3. A kickboxing lesson with its self-guided practice panel.
    await tap(const Key('open-kickboxing-course'));
    await waitFor(() => shown(const Key('kickboxing-course-list')), 'kb');
    await tap(const Key('kickboxing-lesson-1'));
    await reveal(find.byKey(const Key('self-guided-practice-panel')));
    await shot('03-kickboxing-practice');
    await home();

    // 4. Karate: Taikyoku Shodan.
    await tap(const Key('open-karate-course'));
    await tap(const Key('open-taikyoku-course'));
    await waitFor(() => shown(const Key('taikyoku-course-list')), 'taikyoku');
    await shot('04-taikyoku');
    await home();

    // 5. Tai Chi foundation lesson.
    await tap(const Key('open-tai-chi-course'));
    await waitFor(() => shown(const Key('tai-chi-course-list')), 'tai chi');
    await tap(const Key('tai-chi-lesson-1'));
    await frames();
    await shot('05-tai-chi-lesson');
    await home();

    // 6. Progress: the first boxing lesson recorded as practised.
    await tap(const Key('open-solo-boxing-course'));
    await waitFor(() => shown(const Key('solo-course-progress')), 'boxing');
    await tap(const Key('solo-next-lesson'));
    await tap(const Key('solo-mark-practised'));
    final course = (await tester.runAsync(
      () => ContentRepository().loadSoloBoxingCourse(),
    ))!;
    final first = course.lessons.first;
    for (var i = 0; i < first.selfChecks.length; i++) {
      await tap(Key('solo-check-${first.id}-$i'));
    }
    await tap(const Key('solo-mark-complete'));
    // pageBack() looks for the English "Back" tooltip; TR says "Geri".
    await tester.tap(find.byType(BackButton));
    await frames();
    await reveal(find.byKey(const Key('solo-course-progress')));
    await waitFor(
      () => find.textContaining('1 / 39').evaluate().isNotEmpty,
      'progress 1 / 39',
    );
    await shot('06-progress');
    await home();

    // 7. Settings: language, appearance, camera coaching closed.
    await tap(const Key('settings-button'));
    await shot('07-settings');

    debugPrint('JABLAB_SHOTS_DONE');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
