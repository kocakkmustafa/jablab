import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/course_access.dart';
import 'package:jablab/app/kickboxing_course.dart';
import 'package:jablab/app/kickboxing_course_page.dart';

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
      await t.tap(find.byKey(const Key('paywall-not-now')));
      await t.pumpAndSettle();
      expect(unlockCalls, 0);
      expect(find.byType(KickboxingLessonPage), findsNothing);

      // Subscribe/restore → verified membership → the lesson opens and the
      // remaining locks clear.
      await t.tap(find.byKey(const Key('kickboxing-lesson-6')));
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
