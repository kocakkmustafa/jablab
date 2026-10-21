// Four source-binding/media-closed witnesses. UNRUN until exact source acceptance.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/lesson_media_catalog.dart';
import 'package:jablab/app/media_source_projection_pin.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:motion_content/motion_content.dart';

import '../tool/media_source_projection_contract.dart';

class _RejectAnyMediaRead extends CachingAssetBundle {
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    reads++;
    throw StateError('Shipping closed source QA must not read media bytes');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List bytes(String path) => File(path).readAsBytesSync();
  Map<String, dynamic> object(Uint8List raw) =>
      jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;


  Uint8List oneByteChange(Uint8List original, String needle, String replacement) {
    final expected = utf8.encode(needle);
    final changed = utf8.encode(replacement);
    if (expected.length != changed.length || expected.isEmpty) {
      throw StateError('One-byte mutation must preserve byte length');
    }
    final offsets = <int>[];
    for (var start = 0; start + expected.length <= original.length; start++) {
      var equal = true;
      for (var offset = 0; offset < expected.length; offset++) {
        if (original[start + offset] != expected[offset]) equal = false;
      }
      if (equal) offsets.add(start);
    }
    if (offsets.isEmpty) throw StateError('Mutation anchor was not found');
    final copy = Uint8List.fromList(original);
    var differences = 0;
    for (var offset = 0; offset < expected.length; offset++) {
      if (expected[offset] != changed[offset]) differences++;
      copy[offsets.first + offset] = changed[offset];
    }
    if (differences != 1) throw StateError('Mutation must change exactly one byte');
    return copy;
  }

  void checkActualEditorialInputs({Uint8List? delta, Uint8List? baseline}) {
    checkPinnedJabLabEditorialSourceInputs(
      proofBytes: bytes('tool/boxing_editorial_source/source_proof.v1.json'),
      deltaBytes: delta ?? bytes('tool/boxing_editorial_source/editorial_delta.v1.json'),
      baselineSubsetBytes: baseline ?? bytes('tool/boxing_editorial_source/baseline_v2k_jablab.v1.json'),
      referenceBindingsBytes: bytes('tool/boxing_editorial_source/reference_bindings.v1.json'),
      historicalProofBytes: bytes('tool/boxing_editorial_source/historical_source_proof.v1.json'),
      historicalFixtureBytes: bytes('test/fixtures/jablab_v2k_source_pins_v1.json'),
      producerBytes: bytes('tool/build_boxing_editorial_closed_qa.py'),
      courseBytes: bytes(JabLabSourceProjectionPin.coursePath),
    );
  }

  test('editorial owner proof binds six original text deltas and grants no acceptance', () {
    checkActualEditorialInputs();
    final proofBytes = bytes('tool/boxing_editorial_source/source_proof.v1.json');
    final proof = object(proofBytes);
    expect(proof['kind'], 'JABLAB_ORIGINAL_EDITORIAL_SOURCE_PROOF_V1');
    expect(proof['state'], 'SOURCE_TEXT_DELTA_ONLY_NOT_MEDIA_OR_PHYSICAL_ACCEPTANCE');
    expect(proof['historicalProofSha256'], 'dec615e14881b86b7676e1157f63b8bf6269026d856e59f2ee3a65d7f97e512a');
    expect(computeSha256Hex(proofBytes), isNot(proof['historicalProofSha256']));
    expect(computeSha256Hex(proofBytes), JabLabSourceProjectionPin.sourceProofSha256);
    expect(proof['afterCourseSha256'], computeSha256Hex(bytes(JabLabSourceProjectionPin.coursePath)));
    final deltaBytes = bytes('tool/boxing_editorial_source/editorial_delta.v1.json');
    final delta = object(deltaBytes);
    expect(proof['deltaSha256'], computeSha256Hex(deltaBytes));
    final baselineBytes = bytes('tool/boxing_editorial_source/baseline_v2k_jablab.v1.json');
    expect(proof['baselineSubsetSha256'], computeSha256Hex(baselineBytes));
    final baseline = object(baselineBytes);
    expect(baseline['sourceProofSHA256'], proof['historicalProofSha256']);
    expect((baseline['lessonRecords'] as List).length, 39);
    expect((delta['changes'] as List).length, 6);
    expect(proof['deltaPairCount'], 6);
    expect((proof['changedLessonIds'] as List).toSet(), {
      'boxing.footwork.diagonal',
      'boxing.combinations.angle_exit',
      'boxing.rounds.personal_plan',
    });
    expect(proof['referenceBindingsSha256'], computeSha256Hex(bytes('tool/boxing_editorial_source/reference_bindings.v1.json')));
    for (final name in [
      'releaseEligible', 'visible', 'mediaBytesAccepted',
      'nativePlaybackAccepted', 'rightsAccepted',
      'physicalTechniqueAccepted', 'approvedProductionTrustRoot',
    ]) {
      expect(proof[name], isFalse, reason: name);
    }
    expect(proof['generatedMedia'], 0);
    expect(proof['qualifiedMedia'], 0);
    expect(proof['progressEffect'], 0);
  });

  test('one changed byte in a six-element delta or39lesson baseline is rejected', () {
    final delta = bytes('tool/boxing_editorial_source/editorial_delta.v1.json');
    final editedDelta = oneByteChange(delta, 'Stop the practice immediately', 'Ttop the practice immediately');
    expect(editedDelta.length, delta.length);
    expect((object(editedDelta)['changes'] as List).length, 6);
    expect(() => checkActualEditorialInputs(delta: editedDelta), throwsFormatException);
    final baseline = bytes('tool/boxing_editorial_source/baseline_v2k_jablab.v1.json');
    final editedBaseline = oneByteChange(baseline, 'PENDING_VIEWED_ASSET_REVIEW', 'QENDING_VIEWED_ASSET_REVIEW');
    final records = object(editedBaseline)['lessonRecords'] as List;
    expect(editedBaseline.length, baseline.length);
    expect(records.length, 39);
    expect(records.fold<int>(0, (total, row) => total + ((row as Map)['scenes'] as List).length), 292);
    expect(() => checkActualEditorialInputs(baseline: editedBaseline), throwsFormatException);
  });

  test('an editorial proof cannot be substituted for a source slice or closed QA fixture', () {
    final proof = bytes('tool/boxing_editorial_source/source_proof.v1.json');
    final course = bytes(JabLabSourceProjectionPin.coursePath);
    final slice = bytes(JabLabSourceProjectionPin.slicePath);
    final fixture = bytes(JabLabSourceProjectionPin.qaFixturePath);
    expect(
      () => rebuildJabLabSourceProjection(sliceBytes: proof, courseBytes: course, qaFixtureBytes: fixture),
      throwsFormatException,
    );
    expect(
      () => rebuildJabLabSourceProjection(sliceBytes: slice, courseBytes: course, qaFixtureBytes: proof),
      throwsFormatException,
    );
  });

  test('current editorial source membership leaves shipping media empty and performs no media read', () async {
    final course = SoloBoxingCourse.fromJsonString(
      utf8.decode(bytes(JabLabSourceProjectionPin.coursePath)),
    );
    final fixture = object(bytes(JabLabSourceProjectionPin.qaFixturePath));
    final member = (fixture['lessons'] as List).first as Map<String, dynamic>;
    final scene = (member['scenes'] as List).first as Map<String, dynamic>;
    final variant = (scene['variants'] as List).first as Map<String, dynamic>;
    final lesson = course.lessons.singleWhere((value) => value.id == member['lessonId']);
    final bundle = _RejectAnyMediaRead();
    const catalog = LessonMediaCatalog.empty();
    expect(catalog.isEmpty, isTrue);
    expect(catalog.releaseEligible, isFalse);
    expect(fixture['visible'], isFalse);
    expect(fixture['mediaBytesAccepted'], isFalse);
    expect(fixture['nativePlaybackAccepted'], isFalse);
    expect(fixture['progressEffect'], 0);
    final inspected = await catalog.inspect(
      bundle: bundle, course: course, lesson: lesson,
      sceneId: scene['sceneId'] as String,
      variantStem: variant['stem'] as String,
    );
    expect(inspected, isNull);
    expect(bundle.reads, 0);
  });
}
