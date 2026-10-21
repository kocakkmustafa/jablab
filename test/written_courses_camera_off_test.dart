// Report-only supplement: five existing root paths plus two nested routes.
// Source definitions only; host camera/permissions remain mocked; UNRUN.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/karate_course_page.dart';
import 'package:jablab/app/kickboxing_course_page.dart';
import 'package:jablab/app/muay_thai_course_page.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/self_guided_practice_panel.dart';
import 'package:jablab/app/solo_boxing_course_page.dart';
import 'package:jablab/app/tai_chi_course_page.dart';
import 'package:jablab/app/taikyoku_shodan_course_page.dart';
import 'package:jablab/app/yang16_written_course_page.dart';

import 'app_pump.dart';

/// Host widget flow only: bundled teaching can open without a permission
/// request, a native camera session, or the legacy camera-session access gate.
/// This does not exercise production account startup or a physical camera.
void main() {
  const paths =
      <({String entry, String courseReady, String firstLesson, Type page, String? subEntry, String? subReady})>[
        (
          entry: 'open-solo-boxing-course',
          courseReady: 'solo-course-progress',
          firstLesson: 'solo-lesson-boxing.start.space',
          page: SoloBoxingLessonPage,
          subEntry: null,
          subReady: null,
        ),
        (
          entry: 'open-tai-chi-course',
          courseReady: 'tai-chi-course-list',
          firstLesson: 'tai-chi-lesson-1',
          page: TaiChiLessonPage,
          subEntry: null,
          subReady: null,
        ),
        (
          entry: 'open-kickboxing-course',
          courseReady: 'kickboxing-course-list',
          firstLesson: 'kickboxing-lesson-1',
          page: KickboxingLessonPage,
          subEntry: null,
          subReady: null,
        ),
        (
          entry: 'open-karate-course',
          courseReady: 'karate-course-list',
          firstLesson: 'karate-lesson-1',
          page: KarateLessonPage,
          subEntry: null,
          subReady: null,
        ),
        (
          entry: 'open-muay-thai-course',
          courseReady: 'muay-thai-course-list',
          firstLesson: 'muay-thai-lesson-1',
          page: MuayThaiLessonPage,
          subEntry: null,
          subReady: null,
        ),
        (
          entry: 'open-karate-course',
          courseReady: 'karate-course-list',
          firstLesson: 'taikyoku-lesson-1',
          page: TaikyokuLessonPage,
          subEntry: 'open-taikyoku-course',
          subReady: 'taikyoku-course-list',
        ),
        (
          entry: 'open-tai-chi-course',
          courseReady: 'tai-chi-course-list',
          firstLesson: 'yang16-target-prepare',
          page: Yang16WrittenTargetPage,
          subEntry: 'open-yang16-written-course',
          subReady: 'yang16-course-list',
        ),
      ];
  const channels = <MethodChannel>[
    MethodChannel('flutter.baseflow.com/permissions/methods'),
    MethodChannel('motion_camera/control'),
    MethodChannel('motion_camera/frames'),
  ];

  for (final language in <String>['tr', 'en']) {
    for (final path in paths) {
      testWidgets('${path.subEntry ?? path.entry} opens its $language lesson with camera off', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = <Locale>[Locale(language)];
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        final owners = OwnerResourceRegistry();
        final directory = Directory.systemTemp.createTempSync(
          'jablab-no-camera-',
        );
        final nativeCalls = <String>[];
        var legacyAccessCalls = 0;
        final messenger = tester.binding.defaultBinaryMessenger;
        for (final channel in channels) {
          messenger.setMockMethodCallHandler(channel, (call) async {
            nativeCalls.add('${channel.name}/${call.method}');
            throw PlatformException(code: 'camera-disabled-for-test');
          });
        }
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          // Root disposal owns retirement; flush its widget-test microtasks.
          await tester.pumpAndSettle();
          directory.deleteSync(recursive: true);
          for (final channel in channels) {
            messenger.setMockMethodCallHandler(channel, null);
          }
          tester.platformDispatcher.clearLocalesTestValue();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        Future<void> open(String key, Finder ready) async {
          final target = find.byKey(Key(key));
          await tester.scrollUntilVisible(
            target,
            400,
            maxScrolls: 30,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.tap(target.hitTestable());
          await tester.pump();
          await settleUntil(tester, ready);
          expect(ready, findsOneWidget);
          await tester.pumpAndSettle();
        }

        await tester.runAsync(
          () => tester.pumpWidget(
            JabLabApp(
              repository: ContentRepository(
                historyDirectoryOverride: directory,
                ownerRegistry: owners,
              ),
              onboarding: const OnboardingStore(seenOverride: true),
              beforeLessonStart: (_) async {
                legacyAccessCalls++;
                return false;
              },
            ),
          ),
        );
        await settleAppLoad(tester);
        await open(path.entry, find.byKey(Key(path.courseReady)));
        if (path.subEntry != null) {
          await open(path.subEntry!, find.byKey(Key(path.subReady!)));
        }
        await open(path.firstLesson, find.byType(path.page));

        if (path.page == Yang16WrittenTargetPage) {
          // The written target can open before its unawaited preparation load.
          // Await the real loaded argument before revealing its lazy panel;
          // pumpAndSettle alone does not finish real bundle/Core reads.
          final preparedTarget = find.byWidgetPredicate(
            (widget) => widget is Yang16WrittenTargetPage &&
                widget.target.id == 'prepare' &&
                widget.practice?.lessonId == 'prepare',
          );
          await settleUntil(tester, preparedTarget);
          expect(preparedTarget, findsOneWidget);
          final target = tester.widget<Yang16WrittenTargetPage>(preparedTarget);
          final panel = find.byType(SelfGuidedPracticePanel);
          await tester.scrollUntilVisible(
            panel,
            400,
            maxScrolls: 30,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(panel, findsOneWidget);
          expect(tester.widget<SelfGuidedPracticePanel>(panel).practice,
              same(target.practice));
        }

        expect(find.byType(path.page), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(nativeCalls, isEmpty);
        expect(legacyAccessCalls, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
