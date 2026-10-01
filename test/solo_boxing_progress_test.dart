import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/account_bridge.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:jablab/app/solo_boxing_progress.dart';

void main() {
  const String alice = '11111111-1111-4111-8111-111111111111';
  const String bob = '22222222-2222-4222-8222-222222222222';
  late Directory directory;
  late SoloBoxingCourse course;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('jablab-solo-progress-');
    course = SoloBoxingCourse.fromJsonString(
      File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
    );
  });
  tearDown(() => directory.deleteSync(recursive: true));

  test(
    'view, practice, self-check completion and repeat persist separately',
    () async {
      final SoloCourseProgressStore store = soloProgressStoreFor(
        directory,
        alice,
      );
      final SoloLesson first = course.lessons.first;
      expect((await store.load()).completedCount(course), 0);
      await store.markViewed(course, first);
      expect(
        (await store.load()).forLesson(first, course.version)?.state,
        SoloLessonState.viewed,
      );
      expect(
        () => store.markCompleted(course, first, selfChecksConfirmed: false),
        throwsStateError,
      );
      await store.markPractised(course, first);
      expect(
        (await store.load()).forLesson(first, course.version)?.practiceCount,
        1,
      );
      await store.markCompleted(course, first, selfChecksConfirmed: true);
      await store.markPractised(course, first);
      final SoloCourseProgress readBack = await store.load();
      expect(readBack.completedCount(course), 1);
      expect(readBack.nextLesson(course)?.id, course.lessons[1].id);
      expect(
        readBack.forLesson(first, course.version)?.state,
        SoloLessonState.selfReportedComplete,
      );
      expect(readBack.forLesson(first, course.version)?.practiceCount, 2);
      expect(readBack.forLesson(first, course.version)?.completedAt, isNotNull);
    },
  );

  test(
    'guest and accounts are isolated, account deletion includes course',
    () async {
      final SoloLesson first = course.lessons.first;
      await soloProgressStoreFor(directory, null).markViewed(course, first);
      await soloProgressStoreFor(directory, alice).markViewed(course, first);
      expect(
        (await soloProgressStoreFor(directory, bob).load()).records,
        isEmpty,
      );
      expect(
        await localHistoryAccountIds(supportDirectory: directory),
        <String>[alice],
      );
      await clearLocalHistoryFor(alice, supportDirectory: directory);
      expect(
        (await soloProgressStoreFor(directory, alice).load()).records,
        isEmpty,
      );
      expect(
        (await soloProgressStoreFor(directory, null).load()).records,
        contains(first.id),
      );
      expect(() => courseFileNameFor('../guest'), throwsArgumentError);
    },
  );

  test('corrupt progress is an error, never displayed as zero', () async {
    final File file = courseFileFor(directory, alice);
    await file.writeAsString('{bad json');
    expect(
      soloProgressStoreFor(directory, alice).load(),
      throwsFormatException,
    );
  });

  test(
    'concurrent stores serialize writes and deletion rejects stale saves',
    () async {
      final SoloCourseProgressStore first = soloProgressStoreFor(
        directory,
        alice,
      );
      final SoloCourseProgressStore second = soloProgressStoreFor(
        directory,
        alice,
      );
      final SoloLesson lesson = course.lessons.first;
      await Future.wait(<Future<SoloCourseProgress>>[
        for (int i = 0; i < 8; i++)
          (i.isEven ? first : second).markPractised(course, lesson),
      ]);
      expect(
        (await first.load()).forLesson(lesson, course.version)?.practiceCount,
        8,
      );

      final Future<void> pending = first
          .markPractised(course, lesson)
          .then<void>(
            (_) {},
            onError: (Object error, StackTrace _) {
              expect(error, isA<StateError>());
            },
          );
      await clearLocalHistoryFor(alice, supportDirectory: directory);
      await pending;
      expect(await courseFileFor(directory, alice).exists(), isFalse);
      expect(
        await File('${courseFileFor(directory, alice).path}.tmp').exists(),
        isFalse,
      );
      expect(first.markPractised(course, lesson), throwsStateError);
      expect(
        (await soloProgressStoreFor(directory, alice).load()).records,
        isEmpty,
      );
    },
  );
}
