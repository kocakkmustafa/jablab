import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/lesson_media_catalog.dart';
import 'package:jablab/app/lesson_media_source_pins_editorial.dart';
import 'package:motion_content/motion_content.dart';

const _fixtureSha256 =
    'db35dc4c8be0ac825c64b2bf8d0b8612e213c09abd14c1a9c5e93e43b295e0c7';
const _courseSha256 =
    '56773912d8917e3403fb1b2fe3755cf564b10e57e4ed35f24c1df6640b2594dd';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 39 current editorial lessons and 292 variants remain closed QA', () {
    final fixtureBytes = File(
      'test/fixtures/jablab_editorial_source_pins.v1.json',
    ).readAsBytesSync();
    expect(computeSha256Hex(fixtureBytes), _fixtureSha256);
    final fixture =
        jsonDecode(utf8.decode(fixtureBytes)) as Map<String, dynamic>;
    expect(fixture.keys.toSet(), {
      'schemaVersion',
      'kind',
      'sourceCatalogSHA256',
      'manifestSHA256',
      'sourceProofSHA256',
      'app',
      'courseSourceSHA256',
      'lessons',
      'visible',
      'releaseEligible',
      'progressEffect',
      'mediaBytesAccepted',
      'nativePlaybackAccepted',
    });
    expect(fixture['schemaVersion'], 1);
    expect(fixture['kind'], 'JABLAB_EDITORIAL_CLOSED_QA_SOURCE_PINS_V1');
    expect(fixture['sourceCatalogSHA256'], jablabEditorialSourcePinCatalogSha256);
    expect(fixture['manifestSHA256'], jablabEditorialSourcePinManifestSha256);
    expect(fixture['sourceProofSHA256'], jablabEditorialSourcePinProofSha256);
    expect(fixture['app'], 'jablab');
    expect(fixture['courseSourceSHA256'], _courseSha256);
    expect(fixture['visible'], false);
    expect(fixture['releaseEligible'], jablabEditorialClosedQaReleaseEligible);
    expect(fixture['progressEffect'], jablabEditorialClosedQaProgressEffect);
    expect(fixture['mediaBytesAccepted'], false);
    expect(fixture['nativePlaybackAccepted'], false);
    expect(const LessonMediaCatalog.empty().isEmpty, true);
    expect(const LessonMediaCatalog.empty().releaseEligible, false);

    final courseBytes = File(
      'assets/content/solo_boxing_course.v1.json',
    ).readAsBytesSync();
    expect(computeSha256Hex(courseBytes), _courseSha256);
    final course = jsonDecode(utf8.decode(courseBytes)) as Map<String, dynamic>;
    final liveLessons = <String, Map<String, dynamic>>{};
    for (final rawModule in course['modules'] as List) {
      final module = rawModule as Map<String, dynamic>;
      for (final rawLesson in module['lessons'] as List) {
        final lesson = rawLesson as Map<String, dynamic>;
        expect(liveLessons.containsKey(lesson['id']), false);
        liveLessons[lesson['id'] as String] = lesson;
      }
    }
    expect(liveLessons.length, 39);

    final fixtureLessons = (fixture['lessons'] as List)
        .cast<Map<String, dynamic>>();
    final lessonIds = <String>{};
    final sceneIds = <String>{};
    final stems = <String>{};
    final pins = <String>{};
    for (final lesson in fixtureLessons) {
      final lessonId = lesson['lessonId'] as String;
      expect(lessonIds.add(lessonId), true);
      expect(lesson['app'], 'jablab');
      expect(lesson['membershipStatus'], 'SOURCE_PINNED_TEST_ONLY');
      expect(lesson['courseSourceSHA256'], _courseSha256);
      final live = liveLessons[lessonId];
      expect(live, isNotNull);
      final liveSha = computeSha256Hex(
        Uint8List.fromList(utf8.encode(canonicalJsonEncode(live))),
      );
      expect(lesson['lessonCanonicalSHA256'], liveSha);
      for (final scene
          in (lesson['scenes'] as List).cast<Map<String, dynamic>>()) {
        expect(sceneIds.add(scene['sceneId'] as String), true);
        expect(scene['productionState'], 'PREPRODUCTION_UNGENERATED');
        for (final variant
            in (scene['variants'] as List).cast<Map<String, dynamic>>()) {
          final stem = variant['stem'] as String;
          expect(stems.add(stem), true);
          final identity = <String, dynamic>{
            'manifestSHA256': fixture['manifestSHA256'],
            'app': lesson['app'],
            'courseSourceSHA256': lesson['courseSourceSHA256'],
            'lessonId': lessonId,
            'lessonCanonicalSHA256': lesson['lessonCanonicalSHA256'],
            'assetId': lesson['assetId'],
            'sceneId': scene['sceneId'],
            'variantStem': stem,
            'productionSpecSHA256': scene['productionSpecSHA256'],
            'sourceCueSHA256': scene['sourceCueSHA256'],
            'idempotencyKey': scene['idempotencyKey'],
            'productionState': scene['productionState'],
          };
          final calculated = computeSha256Hex(
            Uint8List.fromList(utf8.encode(canonicalJsonEncode(identity))),
          );
          expect(variant['sourcePinSHA256'], calculated);
          expect(pins.add(calculated), true);
        }
      }
    }
    expect(lessonIds, liveLessons.keys.toSet());
    expect(
      (lessonIds.length, sceneIds.length, stems.length, pins.length),
      (39, 292, 292, 292),
    );
    expect(pins, jablabEditorialClosedQaSourcePinHashes);
  });
}
