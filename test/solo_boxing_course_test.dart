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

    final Map<String, dynamic> emptyAppendedCheck = parsed();
    final Map<String, dynamic> lastCheck =
        ((emptyAppendedCheck['modules'] as List).first['lessons'] as List)
            .first['selfChecks']
            .last
            .cast<String, dynamic>();
    lastCheck['en'] = '';
    expect(
      () => SoloBoxingCourse.fromJsonString(jsonEncode(emptyAppendedCheck)),
      throwsFormatException,
    );

    final Map<String, dynamic> nonHttpsSource = parsed();
    (nonHttpsSource['sources'] as List).last['url'] = 'http://example.com';
    expect(
      () => SoloBoxingCourse.fromJsonString(jsonEncode(nonHttpsSource)),
      throwsFormatException,
    );
  });

  test('narrow boxing citations stay on four exact solo lessons', () {
    final course = SoloBoxingCourse.fromJsonString(asset);
    const added = <String>{
      'killa_125_sequence',
      'toronto_small_angle_exit',
      'rarebreed_beginner_round_structure',
      'marksman_independent_focus_reflection',
    };
    final bindings = <String, Set<String>>{
      for (final lesson in course.lessons)
        if (lesson.sourceIds.toSet().intersection(added).isNotEmpty)
          lesson.id: lesson.sourceIds.toSet().intersection(added),
    };
    expect(bindings, <String, Set<String>>{
      'boxing.combinations.one_two_uppercut': <String>{'killa_125_sequence'},
      'boxing.combinations.angle_exit': <String>{'toronto_small_angle_exit'},
      'boxing.integration.two_round_rehearsal': <String>{
        'rarebreed_beginner_round_structure',
      },
      'boxing.integration.independent_round': <String>{
        'marksman_independent_focus_reflection',
      },
    });
    for (final source in course.sources.where((s) => added.contains(s.id))) {
      expect(source.supports!.en, isNotEmpty);
      expect(source.supports!.tr, isNotEmpty);
      expect(source.doesNotSupport!.en, isNotEmpty);
      expect(source.doesNotSupport!.tr, isNotEmpty);
    }
    final broken = (jsonDecode(asset) as Map).cast<String, dynamic>();
    ((broken['sources'] as List).last as Map).remove('doesNotSupport');
    expect(
      () => SoloBoxingCourse.fromJsonString(jsonEncode(broken)),
      throwsFormatException,
    );
  });
}
