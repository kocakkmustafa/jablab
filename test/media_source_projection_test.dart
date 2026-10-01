import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/media_source_projection_pin.dart';

import '../tool/media_source_projection_contract.dart';

Uint8List _file(String path) => File(path).readAsBytesSync();

Map<String, dynamic> _editable(Uint8List bytes) =>
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List slice;
  late Uint8List projection;
  late Uint8List course;
  late Uint8List fixture;

  setUpAll(() {
    slice = _file(JabLabSourceProjectionPin.slicePath);
    projection = _file(JabLabSourceProjectionPin.projectionPath);
    course = _file(JabLabSourceProjectionPin.coursePath);
    fixture = _file(JabLabSourceProjectionPin.qaFixturePath);
  });

  Uint8List rebuild({
    Uint8List? sourceSlice,
    Uint8List? liveCourse,
    Uint8List? qaFixture,
  }) => rebuildJabLabSourceProjection(
    sliceBytes: sourceSlice ?? slice,
    courseBytes: liveCourse ?? course,
    qaFixtureBytes: qaFixture ?? fixture,
  );

  test(
    'app-owned pins rebuild all 292 rows from live lesson and scene order',
    () {
      checkPinnedJabLabSourceProjection(
        sliceBytes: slice,
        projectionBytes: projection,
        courseBytes: course,
        qaFixtureBytes: fixture,
      );
      final expected = rebuild();
      expect(
        sourceProjectionSha256(expected),
        JabLabSourceProjectionPin.projectionSha256,
      );
      expect(expected, orderedEquals(projection));
      final decoded = _editable(expected);
      final rows = decoded['rows'] as List;
      expect(rows, hasLength(292));
      expect(rows.every((row) => (row as List).length == 11), isTrue);
      expect(rows.every((row) => (row as List).last == false), isTrue);
      expect(rows.map((row) => (row as List).first).toSet(), hasLength(292));
    },
  );

  test(
    'both exact source assets are loadable from the Flutter bundle',
    () async {
      for (final (path, expectedSha) in <(String, String)>[
        (
          JabLabSourceProjectionPin.slicePath,
          JabLabSourceProjectionPin.sliceSha256,
        ),
        (
          JabLabSourceProjectionPin.projectionPath,
          JabLabSourceProjectionPin.projectionSha256,
        ),
      ]) {
        final data = await rootBundle.load(path);
        final bytes = Uint8List.sublistView(data);
        expect(sourceProjectionSha256(bytes), expectedSha);
      }
    },
  );

  test('a missing scene cannot keep the 292-row source projection', () {
    final changed = _editable(slice);
    final lessons = changed['lessons'] as List;
    final first = lessons.first as Map<String, dynamic>;
    (first['scenes'] as List).removeLast();
    expect(
      () => rebuild(sourceSlice: canonicalSourceJsonBytes(changed)),
      throwsFormatException,
    );
  });

  test('duplicate source scene is rejected before projection output', () {
    final changed = _editable(slice);
    final first = (changed['lessons'] as List).first as Map<String, dynamic>;
    final scenes = first['scenes'] as List;
    scenes[1] = scenes[0];
    expect(
      () => rebuild(sourceSlice: canonicalSourceJsonBytes(changed)),
      throwsFormatException,
    );
  });

  test(
    'source pin is recomputed rather than trusted from two matching copies',
    () {
      final changedSlice = _editable(slice);
      final changedFixture = _editable(fixture);
      for (final source in [changedSlice, changedFixture]) {
        final first = (source['lessons'] as List).first as Map<String, dynamic>;
        final scene = (first['scenes'] as List).first as Map<String, dynamic>;
        scene['sourceCueSHA256'] = List<String>.filled(64, '0').join();
      }
      expect(
        () => rebuild(
          sourceSlice: canonicalSourceJsonBytes(changedSlice),
          qaFixture: canonicalSourceJsonBytes(changedFixture),
        ),
        throwsFormatException,
      );
    },
  );

  test('old or edited live course cannot validate current slice', () {
    final changed = _editable(course);
    final module = (changed['modules'] as List).first as Map<String, dynamic>;
    final lesson = (module['lessons'] as List).first as Map<String, dynamic>;
    final objective = lesson['objective'] as Map<String, dynamic>;
    objective['en'] = '${objective['en']} ';
    expect(
      () => rebuild(
        liveCourse: Uint8List.fromList(utf8.encode(jsonEncode(changed))),
      ),
      throwsFormatException,
    );
  });

  test('duplicate, missing and reordered projection rows are rejected', () {
    final expected = rebuild();
    final changed = _editable(projection);
    final rows = changed['rows'] as List;
    rows[1] = rows[0];
    expect(
      () => assertJabLabProjectionMatches(
        canonicalSourceJsonBytes(changed),
        expected,
      ),
      throwsFormatException,
    );
    rows.removeLast();
    expect(
      () => assertJabLabProjectionMatches(
        canonicalSourceJsonBytes(changed),
        expected,
      ),
      throwsFormatException,
    );
    final reordered = _editable(projection);
    final reorderedRows = reordered['rows'] as List;
    final first = reorderedRows.first as List;
    first[4] = (first[4] as int) + 1;
    expect(
      () => assertJabLabProjectionMatches(
        canonicalSourceJsonBytes(reordered),
        expected,
      ),
      throwsFormatException,
    );
  });

  test('same-length package tamper fails the immutable binary pin', () {
    final changed = Uint8List.fromList(projection);
    changed[changed.length - 1] ^= 1;
    expect(
      () => checkPinnedJabLabSourceProjection(
        sliceBytes: slice,
        projectionBytes: changed,
        courseBytes: course,
        qaFixtureBytes: fixture,
      ),
      throwsFormatException,
    );
  });
}
