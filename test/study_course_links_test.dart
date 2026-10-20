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
import 'package:jablab/app/solo_boxing_course_page.dart';
import 'package:jablab/app/tai_chi_course_page.dart';

import 'app_pump.dart';
import 'package:jablab/app/study_review.dart';

/// Host widget flow only: bundled teaching can open without a permission
/// request, a native camera session, or the legacy camera-session access gate.
/// This does not exercise production account startup or a physical camera.
void main() {
  const paths =
      <({String entry, String courseReady, String firstLesson, Type page})>[
        (
          entry: 'open-solo-boxing-course',
          courseReady: 'solo-course-progress',
          firstLesson: 'solo-lesson-boxing.start.space',
          page: SoloBoxingLessonPage,
        ),
        (
          entry: 'open-tai-chi-course',
          courseReady: 'tai-chi-course-list',
          firstLesson: 'tai-chi-lesson-1',
          page: TaiChiLessonPage,
        ),
        (
          entry: 'open-kickboxing-course',
          courseReady: 'kickboxing-course-list',
          firstLesson: 'kickboxing-lesson-1',
          page: KickboxingLessonPage,
        ),
        (
          entry: 'open-karate-course',
          courseReady: 'karate-course-list',
          firstLesson: 'karate-lesson-1',
          page: KarateLessonPage,
        ),
        (
          entry: 'open-muay-thai-course',
          courseReady: 'muay-thai-course-list',
          firstLesson: 'muay-thai-lesson-1',
          page: MuayThaiLessonPage,
        ),
      ];
  const channels = <MethodChannel>[
    MethodChannel('flutter.baseflow.com/permissions/methods'),
    MethodChannel('motion_camera/control'),
    MethodChannel('motion_camera/frames'),
  ];

  for (final language in <String>['tr', 'en']) {
    for (final path in paths) {
      testWidgets(
        '${path.entry} recall link opens its $language lesson with camera off',
        (tester) async {
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
          await open('study-review-entry', find.byType(StudyReviewPage));
          final area = <String, String>{
            'open-solo-boxing-course': 'boxing',
            'open-tai-chi-course': 'taichi',
            'open-kickboxing-course': 'kickboxing',
            'open-karate-course': 'karate',
            'open-muay-thai-course': 'muaythai',
          }[path.entry]!;
          await open('study-course-$area', find.byKey(Key(path.courseReady)));
          await open(path.firstLesson, find.byType(path.page));

          expect(find.byType(path.page), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(nativeCalls, isEmpty);
          expect(legacyAccessCalls, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
