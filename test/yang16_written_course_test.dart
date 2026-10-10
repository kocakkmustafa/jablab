import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/yang16_written_course.dart';
import 'package:motion_content/motion_content.dart';

import 'yang16_test_support.dart';

Map<String, dynamic> _json(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
Object? _at(Object? value, String pointer) {
  for (final token in pointer.substring(1).split('/')) {
    value = value is List ? value[int.parse(token)] : (value as Map)[token];
  }
  return value;
}

void main() {
  test('actual v2 bytes and all1450 accepted translated fields match independent pins', () {
    final fixture = _json('test/fixtures/yang16_reviewed_text.v2.json');
    final content = _json(ContentRepository.yang16CourseAsset);
    final mapping = _json(ContentRepository.yang16MappingAsset);
    expect(computeSha256Hex(File(ContentRepository.yang16CourseAsset).readAsBytesSync()),
      Yang16WrittenCourse.reviewedAssetSha256);
    expect(computeSha256Hex(File(ContentRepository.yang16MappingAsset).readAsBytesSync()),
      Yang16WrittenCourse.reviewedMappingSha256);
    expect(fixture['curriculumSha256'], Yang16WrittenCourse.reviewedAssetSha256);
    expect(fixture['mappingSha256'], Yang16WrittenCourse.reviewedMappingSha256);
    expect(fixture['manuscriptSha256'], Yang16WrittenCourse.manuscriptSha256);
    final fields = fixture['translatedFields'] as List;
    expect(fields, hasLength(1450));
    expect(fields.map((v) => v['pointer']).toSet(), hasLength(1450));
    expect(mapping['translatedFields'], fields);
    for (final field in fields) {
      final value = _at(content, field['pointer'] as String) as String;
      expect(computeSha256Hex(Uint8List.fromList(utf8.encode(value))), field['sha256'],
        reason: field['pointer'] as String);
    }
  });

  test('18 sections,17 actual adjacency links and6 final checks preserve original full targets', () {
    final content = _json(ContentRepository.yang16CourseAsset);
    final fixture = _json('test/fixtures/yang16_reviewed_text.v2.json');
    final course = yangCourse();
    expect(course.targets, hasLength(24));
    expect(course.targets.where((t) => !t.isFinal), hasLength(18));
    expect(course.targets.where((t) => t.isFinal), hasLength(6));
    expect(course.boundaries, hasLength(17));
    expect(course.targets.map((t) => t.id).toList(), [
      'prepare', for (var i = 1; i <= 16; i++) 'm${i.toString().padLeft(2, "0")}', 'return',
      'full-order','boundary-count','observed-repetitions','cut-and-contact',
      'reference-not-load','honest-return-and-endpoint',
    ]);
    for (var i = 0; i < 24; i++) {
      final target = course.targets[i];
      final original = i < 18 ? content['lessons'][i]['recall']['prompt']
        : content['finalWrittenChecks'][i - 18]['prompt'];
      final retest = i < 18 ? content['lessons'][i]['retest']['prompt']
        : content['finalWrittenChecks'][i - 18]['retest'];
      final answer = (i < 18 ? fixture['nodeAnswers'][i] : fixture['finalAnswers'][i - 18]) as Map;
      expect(original, retest, reason: 'Original target ${target.id} must recur unchanged');
      expect(target.prompt.en, original['en']); expect(target.prompt.tr, original['tr']);
      expect(target.answer.en, answer['en']); expect(target.answer.tr, answer['tr']);
      expect(target.index, i); expect(target.facts, isNotEmpty);
      if (i < 18) { expect(target.options.map((o) => o.id), ['a','b']); }
    }
    for (var i = 0; i < 17; i++) {
      final boundary = course.boundaries[i];
      expect(boundary.id, 'E${i.toString().padLeft(2, "0")}');
      expect(boundary.from, course.targets[i].id); expect(boundary.to, course.targets[i + 1].id);
      expect(boundary.limit.en, isNotEmpty); expect(boundary.limit.tr, isNotEmpty);
    }
    expect(course.physicalPracticeAvailable, isFalse);
    expect(course.reviewReadiness.values, everyElement(isFalse));
  });

  test('direct decoder rejects all changed bytes, weak retests, metadata and physical claims', () {
    final original = File(ContentRepository.yang16CourseAsset).readAsStringSync();
    final mapping = File(ContentRepository.yang16MappingAsset).readAsStringSync();
    void reject(void Function(Map<String,dynamic>) mutate) {
      final value = jsonDecode(original) as Map<String,dynamic>; mutate(value);
      expect(() => Yang16WrittenCourse.fromVerifiedStrings(jsonEncode(value), mapping), throwsFormatException);
    }
    for (final key in (jsonDecode(original)['reviewReadiness'] as Map).keys) {
      reject((v) => v['reviewReadiness'][key] = true);
      reject((v) => v['reviewReadiness'].remove(key));
    }
    for (var i = 0; i < 18; i++) {
      reject((v) => v['lessons'][i]['retest']['prompt']['en'] = 'Different question');
      reject((v) => v['lessons'][i]['retest']['requiredFacts'].removeLast());
      reject((v) => v['lessons'][i]['retest']['partialAnswerPasses'] = true);
      reject((v) => v['lessons'][i]['recall']['answerId'] = 'unknown');
      reject((v) => v['lessons'][i]['physicalActionAvailable'] = true);
      reject((v) => v['lessons'][i]['physicalPrerequisites'][0]['establishedByThisManuscript'] = true);
      reject((v) => v['lessons'][i]['supplementaryCheck']['requiredForCompletion'] = true);
    }
    for (var i = 0; i < 6; i++) {
      reject((v) => v['finalWrittenChecks'][i]['retest']['tr'] = 'Başka soru');
      reject((v) => v['finalWrittenChecks'][i]['retestAnswer']['en'] = 'Partial answer');
      reject((v) => v['finalWrittenChecks'][i]['sameTargetRetestContract']['partialAnswerPasses'] = true);
    }
    reject((v) => v['lessons'].removeLast());
    reject((v) => v['boundaries'][7]['to'] = 'm16');
    reject((v) => v['reviewManuscriptVersion'] = 2.0);
    reject((v) => v['title'].remove('tr'));
    reject((v) => v['unknownSchemaKey'] = true);
    for (final bad in ['', '{}', '$original ', '{"id":"duplicate",${original.substring(1)}']) {
      expect(() => Yang16WrittenCourse.fromVerifiedStrings(bad, mapping), throwsFormatException);
    }
    final changedMapping = jsonDecode(mapping) as Map<String,dynamic>;
    changedMapping['translatedFields'][0]['sha256'] = List.filled(64, '0').join();
    expect(() => Yang16WrittenCourse.fromVerifiedStrings(original, jsonEncode(changedMapping)), throwsFormatException);
    expect(() => Yang16WrittenCourse.fromVerifiedStrings(original, '$mapping '), throwsFormatException);
  });

  test('decoded target, fact, boundary and readiness collections cannot be mutated', () {
    final course = yangCourse();
    expect(() => course.targets.clear(), throwsUnsupportedError);
    expect(() => course.boundaries.clear(), throwsUnsupportedError);
    expect(() => course.reading.clear(), throwsUnsupportedError);
    expect(() => course.targets.first.options.clear(), throwsUnsupportedError);
    expect(() => course.targets.first.facts.clear(), throwsUnsupportedError);
    expect(() => course.targets.first.reading.clear(), throwsUnsupportedError);
    expect(() => course.reviewReadiness['physicalMasteryAccepted'] = true, throwsUnsupportedError);
  });
}
