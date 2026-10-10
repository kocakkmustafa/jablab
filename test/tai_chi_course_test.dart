import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/tai_chi_course.dart';

void main() {
  Map<String, dynamic> fixture() =>
      jsonDecode(
            File('assets/content/tai_chi_course.v1.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  void rejects(void Function(Map<String, dynamic>) mutate) {
    final map = fixture();
    mutate(map);
    expect(
      () => TaiChiCourse.fromJsonString(jsonEncode(map)),
      throwsFormatException,
    );
  }

  test(
    'strict lessons reject missing direction/support/correction, duplicate IDs and source bindings',
    () {
      rejects(
        (map) => map['lessons'][0]['practiceRows'][0]['direction']['en'] = '',
      );
      rejects(
        (map) => map['lessons'][0]['practiceRows'][0]['support']['tr'] = '',
      );
      rejects((map) => map['lessons'][0]['correction']['en'] = '');
      rejects((map) => map['lessons'][1]['id'] = map['lessons'][0]['id']);
      rejects((map) => map['lessons'][0]['sourceIds'] = ['unbound']);
      rejects((map) => map['lessons'][0]['sourceIds'] = []);
      rejects((map) => map['practiceKind'] = 'yang_24_form');
      rejects((map) => map['schemaVersion'] = 1.0);
      rejects((map) => map['sources'][0]['url'] = 'http://example.org');
    },
  );
  test('decoded course and lesson collections cannot mutate in UI', () {
    final course = TaiChiCourse.fromJsonString(jsonEncode(fixture()));
    expect(() => course.lessons.clear(), throwsUnsupportedError);
    expect(
      () => course.lessons.first.sourceIds.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => course.lessons.first.practiceRows.clear(),
      throwsUnsupportedError,
    );
  });
}
