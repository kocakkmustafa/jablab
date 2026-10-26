import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/course_access.dart';
import 'package:jablab/app/kickboxing_course.dart';
import 'package:jablab/app/kickboxing_course_page.dart';
import 'package:motion_entitlements/motion_entitlements.dart'
    show isLessonUnlocked;

import 'localization_fixture.dart';

KickboxingCourse _course() => KickboxingCourse.fromJsonString(
  File('assets/content/kickboxing_a.v1.json').readAsStringSync(),
);

void main() {
  group('option A free boundary', () {
    test('about the first third (boxing: first two modules) is free', () {
      expect(freeLessonCount, <GatedCourse, int>{
        GatedCourse.boxing: 10,
        GatedCourse.kickboxing: 5,
        GatedCourse.muayThai: 5,
        GatedCourse.karate: 5,
        GatedCourse.taikyoku: 3,
        GatedCourse.taiChi: 5,
        GatedCourse.yang16: 6,
      });
    });

    test('lesson totals match the bundled course content', () {
      Map<String, dynamic> json(String name) =>
          jsonDecode(File('assets/content/$name').readAsStringSync())
              as Map<String, dynamic>;
      int lessons(Map<String, dynamic> m) => (m['lessons'] as List).length;
      expect(courseLessonCount, <GatedCourse, int>{
        GatedCourse.boxing: (json('solo_boxing_course.v1.json')['modules']
                as List)
            .fold<int>(0, (n, m) => n + lessons(m as Map<String, dynamic>)),
        GatedCourse.kickboxing: lessons(json('kickboxing_a.v1.json')),
        GatedCourse.muayThai: lessons(json('muay_thai_a.v1.json')),
        GatedCourse.karate: lessons(json('karate_a.v1.json')),
        GatedCourse.taikyoku: lessons(
          json('taikyoku_shodan_jl.v1.json')['content']
              as Map<String, dynamic>,
        ),
        GatedCourse.taiChi: lessons(json('tai_chi_course.v1.json')),
        GatedCourse.yang16: lessons(json('yang16_angela_written.v2.json')),
      });
    });

    test('Y4-1: every boundary is Core isLessonUnlocked with the app count', () {
      final access = CourseAccess(salesOpen: true, unlock: (_) async => false);
      for (final course in GatedCourse.values) {
        final int total = courseLessonCount[course]!;
        for (var i = 0; i < total; i++) {
          final bool core = isLessonUnlocked(
            lessonIndex: i,
            totalLessons: total,
            firstModuleLessonCount: 0,
            entitled: false,
            freeLessonLimit: freeLessonCount[course],
          );
          expect(access.allows(course, i), core, reason: '${course.name} $i');
          expect(core, i < freeLessonCount[course]!);
        }
        expect(access.allows(course, -1), isFalse);
        expect(access.allows(course, total), isFalse);
      }
      // Core's own default would free more (boxing 13, kickboxing 6): the
      // founder kept JabLab's counts, so lesson 11 of boxing stays paid.
      expect(
        isLessonUnlocked(
          lessonIndex: 10,
          totalLessons: 39,
          firstModuleLessonCount: 0,
          entitled: false,
        ),
        isTrue,
      );
      expect(access.allows(GatedCourse.boxing, 10), isFalse);
    });

    test('closed sales never lock a lesson', () {
      final access = CourseAccess.open();
      for (final course in GatedCourse.values) {
        expect(access.allows(course, 999), isTrue, reason: course.name);
      }
    });

    test('open sales lock only past the boundary until entitled', () {
      final access = CourseAccess(salesOpen: true, unlock: (_) async => false);
      expect(access.allows(GatedCourse.kickboxing, 4), isTrue);
      expect(access.allows(GatedCourse.kickboxing, 5), isFalse);
      expect(access.allows(GatedCourse.boxing, 9), isTrue);
      expect(access.allows(GatedCourse.boxing, 10), isFalse);
      access.entitled.value = true;
      expect(access.allows(GatedCourse.kickboxing, 15), isTrue);
    });
  });

  group('kickboxing paywall', () {
    Future<void> pump(WidgetTester t, CourseAccess access) async {
      await t.pumpWidget(
        MaterialApp(
          supportedLocales: testSupportedLocales,
          localizationsDelegates: testLocalizationDelegates,
          localeListResolutionCallback: resolveTestLocales,
          home: KickboxingCoursePage(
            loader: () async => _course(),
            access: access,
          ),
        ),
      );
      await settleTestLocalizations(t);
      await t.pumpAndSettle();
    }

    Future<void> reveal(WidgetTester t, Key key) async {
      await t.scrollUntilVisible(
        find.byKey(key),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 200,
      );
      await t.pumpAndSettle();
    }

    Finder lockOn(int number) => find.descendant(
      of: find.byKey(Key('kickboxing-lesson-$number')),
      matching: find.byType(LessonLockBadge),
    );

    testWidgets('free lesson opens; locked lesson shows the paywall', (
      WidgetTester t,
    ) async {
      var unlockCalls = 0;
      final access = CourseAccess(
        salesOpen: true,
        unlock: (_) async {
          unlockCalls++;
          return true;
        },
      );
      await pump(t, access);

      await reveal(t, const Key('kickboxing-lesson-5'));
      expect(lockOn(5), findsNothing);
      await reveal(t, const Key('kickboxing-lesson-6'));
      expect(lockOn(6), findsOneWidget);

      // "Not now" keeps the lesson closed and buys nothing.
      await t.tap(find.byKey(const Key('kickboxing-lesson-6')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('paywall-sheet')), findsOneWidget);
      expect(find.byKey(const Key('paywall-trial-terms')), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('paywall-not-now')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('paywall-not-now')));
      await t.pumpAndSettle();
      expect(unlockCalls, 0);
      expect(find.byType(KickboxingLessonPage), findsNothing);

      // Subscribe/restore → verified membership → the lesson opens and the
      // remaining locks clear.
      await t.tap(find.byKey(const Key('kickboxing-lesson-6')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('paywall-subscribe')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('paywall-subscribe')));
      await t.pumpAndSettle();
      expect(unlockCalls, 1);
      expect(access.entitled.value, isTrue);
      expect(find.byType(KickboxingLessonPage), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      await reveal(t, const Key('kickboxing-lesson-16'));
      expect(lockOn(16), findsNothing);
    });

    testWidgets('an unverified purchase keeps the lesson locked', (
      WidgetTester t,
    ) async {
      final access = CourseAccess(salesOpen: true, unlock: (_) async => false);
      await pump(t, access);
      await reveal(t, const Key('kickboxing-lesson-6'));
      await t.tap(find.byKey(const Key('kickboxing-lesson-6')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('paywall-subscribe')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('paywall-subscribe')));
      await t.pumpAndSettle();
      expect(access.entitled.value, isFalse);
      expect(find.byType(KickboxingLessonPage), findsNothing);
      expect(lockOn(6), findsOneWidget);
    });

    testWidgets('closed sales show no locks and open every lesson', (
      WidgetTester t,
    ) async {
      await pump(t, CourseAccess.open());
      await reveal(t, const Key('kickboxing-lesson-16'));
      expect(find.byType(LessonLockBadge), findsNothing);
      await t.tap(find.byKey(const Key('kickboxing-lesson-16')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('paywall-sheet')), findsNothing);
      expect(find.byType(KickboxingLessonPage), findsOneWidget);
    });
  });
}
