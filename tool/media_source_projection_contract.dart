import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:jablab/app/media_source_projection_pin.dart';
import 'package:jablab/app/solo_boxing_course.dart';

const _maxJsonBytes = 2 * 1024 * 1024;
final _shaPattern = RegExp(r'^[0-9a-f]{64}$');

String sourceProjectionSha256(List<int> bytes) =>
    sha256.convert(bytes).toString();

/// The exporter uses sorted JSON keys, UTF-8 and no trailing newline.
Uint8List canonicalSourceJsonBytes(Object? value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(_sorted(value))));

Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return SplayTreeMap<String, Object?>.from({
      for (final key in keys) key: _sorted(value[key]),
    });
  }
  if (value is List) return value.map(_sorted).toList(growable: false);
  return value;
}

Map<String, dynamic> _jsonMap(
  Uint8List bytes,
  String label, {
  bool canonical = false,
}) {
  if (bytes.isEmpty || bytes.length > _maxJsonBytes) {
    throw FormatException('$label byte size is outside 1..$_maxJsonBytes');
  }
  final text = utf8.decode(bytes, allowMalformed: false);
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('$label must be a JSON object');
  }
  if (canonical && !_sameBytes(bytes, canonicalSourceJsonBytes(decoded))) {
    throw FormatException('$label is not canonical JSON');
  }
  return decoded;
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void _keys(Map<String, dynamic> value, Set<String> expected, String label) {
  if (value.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(value.keys.toSet()).isNotEmpty) {
    throw FormatException('$label field set changed');
  }
}

void _equal(Object? actual, Object? expected, String label) {
  if (actual != expected) throw FormatException('$label changed');
}

String _sha(Object? value, String label) {
  if (value is! String || !_shaPattern.hasMatch(value)) {
    throw FormatException('$label is not a SHA-256 hex digest');
  }
  return value;
}

List<Map<String, dynamic>> _objects(Object? value, String label) {
  if (value is! List) throw FormatException('$label is not an array');
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('$label contains a non-object');
        }
        return item;
      })
      .toList(growable: false);
}

List<Map<String, dynamic>> _liveLessons(Map<String, dynamic> course) {
  final lessons = <Map<String, dynamic>>[];
  for (final module in _objects(course['modules'], 'course.modules')) {
    lessons.addAll(_objects(module['lessons'], 'course.module.lessons'));
  }
  return lessons;
}

/// Rebuilds the source-only projection using only app-owned files. This
/// deliberately does not accept or construct a playable media catalogue.
Uint8List rebuildJabLabSourceProjection({
  required Uint8List sliceBytes,
  required Uint8List courseBytes,
  required Uint8List qaFixtureBytes,
}) {
  final slice = _jsonMap(sliceBytes, 'source slice', canonical: true);
  final fixture = _jsonMap(qaFixtureBytes, 'closed QA fixture');
  final course = _jsonMap(courseBytes, 'live course');
  SoloBoxingCourse.fromJsonString(utf8.decode(courseBytes));
  final courseHash = sourceProjectionSha256(courseBytes);
  _equal(courseHash, JabLabSourceProjectionPin.courseSha256, 'live course SHA');

  _keys(slice, {
    'appId',
    'courseSourceSHA256',
    'holds',
    'kind',
    'lessons',
    'schemaVersion',
    'sourceCatalogSHA256',
    'sourceManifestSHA256',
    'sourceProofSHA256',
  }, 'source slice');
  _equal(slice['kind'], 'MOTION_V2L_APP_SOURCE_SLICE_V1', 'slice kind');
  _equal(slice['schemaVersion'], 1, 'slice schema');
  _equal(slice['appId'], JabLabSourceProjectionPin.appId, 'slice app');
  _equal(slice['courseSourceSHA256'], courseHash, 'slice course SHA');
  _equal(
    slice['sourceCatalogSHA256'],
    JabLabSourceProjectionPin.sourceCatalogSha256,
    'slice catalog SHA',
  );
  _equal(
    slice['sourceManifestSHA256'],
    JabLabSourceProjectionPin.sourceManifestSha256,
    'slice manifest SHA',
  );
  _equal(
    slice['sourceProofSHA256'],
    JabLabSourceProjectionPin.sourceProofSha256,
    'slice proof SHA',
  );
  if (slice['holds'] is! List || (slice['holds'] as List).isNotEmpty) {
    throw const FormatException('JabLab source HOLD set must be empty');
  }

  _equal(
    fixture['kind'],
    'JABLAB_V2K_CLOSED_QA_SOURCE_PINS_V1',
    'QA fixture kind',
  );
  _equal(fixture['app'], JabLabSourceProjectionPin.appId, 'QA fixture app');
  _equal(fixture['courseSourceSHA256'], courseHash, 'QA fixture course SHA');
  _equal(
    fixture['sourceCatalogSHA256'],
    slice['sourceCatalogSHA256'],
    'QA fixture catalog SHA',
  );
  _equal(
    fixture['manifestSHA256'],
    slice['sourceManifestSHA256'],
    'QA fixture manifest SHA',
  );
  _equal(
    fixture['sourceProofSHA256'],
    slice['sourceProofSHA256'],
    'QA fixture proof SHA',
  );
  for (final field in [
    'visible',
    'releaseEligible',
    'mediaBytesAccepted',
    'nativePlaybackAccepted',
  ]) {
    _equal(fixture[field], false, 'QA fixture $field');
  }
  _equal(fixture['progressEffect'], 0, 'QA fixture progress effect');
  final sliceLessons = _objects(slice['lessons'], 'slice.lessons');
  final fixtureLessons = _objects(fixture['lessons'], 'fixture.lessons');
  if (!_sameBytes(
    canonicalSourceJsonBytes(sliceLessons),
    canonicalSourceJsonBytes(fixtureLessons),
  )) {
    throw const FormatException(
      'source slice differs from closed QA identities',
    );
  }
  final liveLessons = _liveLessons(course);
  if (sliceLessons.length != JabLabSourceProjectionPin.lessonCount ||
      liveLessons.length != JabLabSourceProjectionPin.lessonCount) {
    throw const FormatException('JabLab lesson count changed');
  }

  final lessonIds = <String>{};
  final assetIds = <String>{};
  final sceneIds = <String>{};
  final stems = <String>{};
  final pins = <String>{};
  final rows = <List<Object?>>[];
  for (var lessonIndex = 0; lessonIndex < sliceLessons.length; lessonIndex++) {
    final lesson = sliceLessons[lessonIndex];
    final live = liveLessons[lessonIndex];
    _keys(lesson, {
      'app',
      'assetId',
      'courseSourceSHA256',
      'lessonCanonicalSHA256',
      'lessonId',
      'membershipStatus',
      'scenes',
    }, 'slice lesson');
    final lessonId = lesson['lessonId'];
    final assetId = lesson['assetId'];
    if (lessonId is! String ||
        lessonId.isEmpty ||
        !lessonIds.add(lessonId) ||
        assetId is! String ||
        !assetId.startsWith('jablab.') ||
        !assetIds.add(assetId)) {
      throw const FormatException('duplicate or invalid lesson/asset identity');
    }
    _equal(lesson['app'], JabLabSourceProjectionPin.appId, 'lesson app');
    _equal(
      lesson['membershipStatus'],
      'SOURCE_PINNED_TEST_ONLY',
      'lesson membership status',
    );
    _equal(lesson['courseSourceSHA256'], courseHash, 'lesson course SHA');
    _equal(lessonId, live['id'], 'live lesson order/identity');
    final lessonHash = sourceProjectionSha256(canonicalSourceJsonBytes(live));
    _equal(
      _sha(lesson['lessonCanonicalSHA256'], 'lesson canonical SHA'),
      lessonHash,
      'live lesson canonical SHA',
    );

    final scenes = _objects(lesson['scenes'], 'lesson.scenes');
    if (scenes.isEmpty) throw const FormatException('lesson has no scenes');
    for (var sceneOrder = 0; sceneOrder < scenes.length; sceneOrder++) {
      final scene = scenes[sceneOrder];
      _keys(scene, {
        'idempotencyKey',
        'productionSpecSHA256',
        'productionState',
        'sceneId',
        'sourceCueSHA256',
        'variants',
      }, 'slice scene');
      final sceneId = scene['sceneId'];
      if (sceneId is! String ||
          !sceneId.startsWith('jablab:$lessonId:') ||
          !sceneIds.add(sceneId)) {
        throw const FormatException('duplicate or invalid scene identity');
      }
      final spec = _sha(scene['productionSpecSHA256'], 'production spec SHA');
      final cue = _sha(scene['sourceCueSHA256'], 'source cue SHA');
      final idempotency = 'motion-media-v1:$spec';
      _equal(scene['idempotencyKey'], idempotency, 'idempotency key');
      _equal(
        scene['productionState'],
        'PREPRODUCTION_UNGENERATED',
        'scene production state',
      );
      final variants = _objects(scene['variants'], 'scene.variants');
      if (variants.isEmpty) {
        throw const FormatException('scene has no variants');
      }
      for (final variant in variants) {
        _keys(variant, {'sourcePinSHA256', 'stem'}, 'source variant');
        final stem = variant['stem'];
        if (stem is! String ||
            !stem.startsWith('jablab/') ||
            !stem.endsWith('--master-format-pending') ||
            !stems.add(stem)) {
          throw const FormatException('duplicate or invalid variant stem');
        }
        final identity = <String, Object?>{
          'manifestSHA256': slice['sourceManifestSHA256'],
          'app': JabLabSourceProjectionPin.appId,
          'courseSourceSHA256': courseHash,
          'lessonId': lessonId,
          'lessonCanonicalSHA256': lessonHash,
          'assetId': assetId,
          'sceneId': sceneId,
          'variantStem': stem,
          'productionSpecSHA256': spec,
          'sourceCueSHA256': cue,
          'idempotencyKey': idempotency,
          'productionState': 'PREPRODUCTION_UNGENERATED',
        };
        final sourcePin = sourceProjectionSha256(
          canonicalSourceJsonBytes(identity),
        );
        _equal(
          _sha(variant['sourcePinSHA256'], 'source pin SHA'),
          sourcePin,
          'source pin identity',
        );
        if (!pins.add(sourcePin)) {
          throw const FormatException('duplicate source pin');
        }
        rows.add(<Object?>[
          sourcePin,
          lessonId,
          assetId,
          sceneId,
          sceneOrder,
          stem,
          lessonHash,
          spec,
          cue,
          idempotency,
          false,
        ]);
      }
    }
  }
  if (sceneIds.length != JabLabSourceProjectionPin.sceneCount ||
      rows.length != JabLabSourceProjectionPin.variantCount ||
      JabLabSourceProjectionPin.heldCount != 0) {
    throw const FormatException('JabLab scene/variant/HOLD count changed');
  }
  rows.sort((a, b) => (a.first as String).compareTo(b.first as String));
  return canonicalSourceJsonBytes(<String, Object?>{
    'appId': JabLabSourceProjectionPin.appId,
    'courseSourceSHA256': courseHash,
    'kind': 'MOTION_V2L_APP_SOURCE_PROJECTION_V1',
    'rows': rows,
    'schemaVersion': 1,
    'sourceCatalogSHA256': slice['sourceCatalogSHA256'],
    'sourceManifestSHA256': slice['sourceManifestSHA256'],
  });
}

void assertJabLabProjectionMatches(Uint8List actual, Uint8List rebuilt) {
  final projection = _jsonMap(actual, 'source projection', canonical: true);
  _keys(projection, {
    'appId',
    'courseSourceSHA256',
    'kind',
    'rows',
    'schemaVersion',
    'sourceCatalogSHA256',
    'sourceManifestSHA256',
  }, 'source projection');
  _equal(
    projection['appId'],
    JabLabSourceProjectionPin.appId,
    'projection app',
  );
  _equal(
    projection['kind'],
    'MOTION_V2L_APP_SOURCE_PROJECTION_V1',
    'projection kind',
  );
  _equal(projection['schemaVersion'], 1, 'projection schema');
  final rows = projection['rows'];
  if (rows is! List || rows.length != JabLabSourceProjectionPin.variantCount) {
    throw const FormatException('projection row count changed');
  }
  if (!_sameBytes(actual, rebuilt)) {
    throw const FormatException('projection differs from live source rebuild');
  }
}

void checkPinnedJabLabSourceProjection({
  required Uint8List sliceBytes,
  required Uint8List projectionBytes,
  required Uint8List courseBytes,
  required Uint8List qaFixtureBytes,
}) {
  final expected = <(String, Uint8List, String)>[
    ('source slice', sliceBytes, JabLabSourceProjectionPin.sliceSha256),
    (
      'source projection',
      projectionBytes,
      JabLabSourceProjectionPin.projectionSha256,
    ),
    ('live course', courseBytes, JabLabSourceProjectionPin.courseSha256),
    (
      'closed QA fixture',
      qaFixtureBytes,
      JabLabSourceProjectionPin.qaFixtureSha256,
    ),
  ];
  for (final (label, bytes, digest) in expected) {
    if (bytes.isEmpty ||
        bytes.length > _maxJsonBytes ||
        sourceProjectionSha256(bytes) != digest) {
      throw FormatException('$label byte pin changed');
    }
  }
  final rebuilt = rebuildJabLabSourceProjection(
    sliceBytes: sliceBytes,
    courseBytes: courseBytes,
    qaFixtureBytes: qaFixtureBytes,
  );
  assertJabLabProjectionMatches(projectionBytes, rebuilt);
}
