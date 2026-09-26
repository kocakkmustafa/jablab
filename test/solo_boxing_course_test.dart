import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/solo_boxing_course.dart';

void main() {
  final String asset = File(
    'assets/content/solo_boxing_course.v1.json',
  ).readAsStringSync();

  test(
    '39 ordered bilingual lessons have full teaching and source bindings',
    () {
      final SoloBoxingCourse course = SoloBoxingCourse.fromJsonString(asset);
      expect(
        course.modules.map((SoloModule module) => module.lessons.length),
        <int>[5, 5, 6, 5, 5, 5, 5, 3],
      );
      expect(course.lessons.length, 39);
      expect(course.lessons.first.prerequisites, isEmpty);
      for (int i = 1; i < course.lessons.length; i++) {
        expect(course.lessons[i].prerequisites, <String>[
          course.lessons[i - 1].id,
        ]);
      }
      expect(course.lessons.last.id, 'boxing.integration.independent_round');
      expect(
        course.lessons.every(
          (SoloLesson lesson) =>
              lesson.evidenceMode == 'self_report' &&
              lesson.steps.length >= 2 &&
              lesson.selfChecks.length >= 2,
        ),
        isTrue,
      );
      expect(asset, isNot(contains('videoUrl')));
      expect(asset, isNot(contains('cameraScore')));
    },
  );

  test('missing translation, source or lesson fails closed', () {
    Map<String, dynamic> parsed() =>
        (jsonDecode(asset) as Map).cast<String, dynamic>();

    final Map<String, dynamic> missingTr = parsed();
    final Map<String, dynamic> firstModule =
        ((missingTr['modules'] as List).first as Map).cast<String, dynamic>();
    final Map<String, dynamic> firstLesson =
        ((firstModule['lessons'] as List).first as Map).cast<String, dynamic>();
    ((firstLesson['practice'] as Map).cast<String, dynamic>())['tr'] = '';
    expect(
      () => SoloBoxingCourse.fromJsonString(jsonEncode(missingTr)),
      throwsFormatException,
    );

    final Map<String, dynamic> missingSource = parsed();
    final Map<String, dynamic> module =
        ((missingSource['modules'] as List).first as Map)
            .cast<String, dynamic>();
    final Map<String, dynamic> lesson =
        ((module['lessons'] as List).first as Map).cast<String, dynamic>();
    lesson['sourceIds'] = <String>['unknown'];
    expect(
      () => SoloBoxingCourse.fromJsonString(jsonEncode(missingSource)),
      throwsFormatException,
    );

    final Map<String, dynamic> shortCourse = parsed();
    ((shortCourse['modules'] as List).last as Map)['lessons'].removeLast();
    expect(
      () => SoloBoxingCourse.fromJsonString(jsonEncode(shortCourse)),
      throwsFormatException,
    );
  });
}
