import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/account_bridge.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:jablab/app/solo_boxing_progress.dart';

// These tests use the real store and owned temporary filesystem paths. They
// do not prove OS-kill, power-loss, full-disk or physical-device durability.
const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

enum _Writer { viewed, practised, completed }

Future<SoloCourseProgress> _write(
  _Writer writer,
  SoloCourseProgressStore store,
  SoloBoxingCourse course,
) => switch (writer) {
  _Writer.viewed => store.markViewed(course, course.lessons.first),
  _Writer.practised => store.markPractised(course, course.lessons.first),
  _Writer.completed => store.markCompleted(
    course,
    course.lessons.first,
    selfChecksConfirmed: true,
  ),
};

enum _NodeKind { regularFile, directory, link, danglingLink }

/// An independently captured witness, including link targets and directory
/// contents. Testing only the final file would miss a followed temp symlink.
final class _PathWitness {
  _PathWitness({
    required this.path,
    required this.type,
    this.bytes,
    this.targetPath,
    this.targetBytes,
    this.childPath,
    this.childBytes,
  });

  final String path;
  final FileSystemEntityType type;
  final List<int>? bytes;
  final String? targetPath;
  final List<int>? targetBytes;
  final String? childPath;
  final List<int>? childBytes;

  Future<void> expectUnchanged() async {
    expect(await FileSystemEntity.type(path, followLinks: false), type);
    if (bytes != null) {
      expect(await File(path).readAsBytes(), bytes);
    }
    if (targetPath case final target?) {
      expect(await Link(path).target(), target);
      if (targetBytes case final original?) {
        expect(await File(target).readAsBytes(), original);
      } else {
        expect(
          await FileSystemEntity.type(target, followLinks: false),
          FileSystemEntityType.notFound,
        );
      }
    }
    if (childPath case final child?) {
      expect(await File(child).readAsBytes(), childBytes);
    }
  }
}

Future<_PathWitness> _seedNode(
  String path,
  _NodeKind kind, {
  required String contents,
}) async {
  switch (kind) {
    case _NodeKind.regularFile:
      await File(path).writeAsString(contents, flush: true);
      return _PathWitness(
        path: path,
        type: FileSystemEntityType.file,
        bytes: utf8.encode(contents),
      );
    case _NodeKind.directory:
      await Directory(path).create();
      final child = File('$path/owned-sentinel.txt');
      const sentinel = 'SYNTHETIC directory child — korunmalı';
      await child.writeAsString(sentinel, flush: true);
      return _PathWitness(
        path: path,
        type: FileSystemEntityType.directory,
        childPath: child.path,
        childBytes: utf8.encode(sentinel),
      );
    case _NodeKind.link:
      final target = File('$path-owned-target');
      await target.writeAsString(contents, flush: true);
      await Link(path).create(target.path);
      return _PathWitness(
        path: path,
        type: FileSystemEntityType.link,
        targetPath: target.path,
        targetBytes: utf8.encode(contents),
      );
    case _NodeKind.danglingLink:
      final target = '$path-owned-missing-target';
      await Link(path).create(target);
      return _PathWitness(
        path: path,
        type: FileSystemEntityType.link,
        targetPath: target,
      );
  }
}

void main() {
  late Directory owned;
  late OwnerResourceRegistry owners;
  late SoloBoxingCourse course;
  late File progress;

  SoloCourseProgressStore store([String? owner = _alice]) =>
      soloProgressStoreFor(owned, owner, ownerRegistry: owners);

  // This fixture is specified independently from the store's serializer. Both
  // existing records must survive a rejected mutation, including the unrelated
  // completed lesson. The first record allows completed(true) to reach IO.
  String validSource() => jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'courseId': 'jablab.solo_boxing',
    'lessons': <String, Object?>{
      course.lessons.first.id: <String, Object?>{
        'contentVersion': course.version,
        'state': 'practised',
        'viewedAt': '2026-10-18T10:00:00.000Z',
        'lastPractisedAt': '2026-10-18T10:05:00.000Z',
        'completedAt': null,
        'practiceCount': 2,
      },
      course.lessons[1].id: <String, Object?>{
        'contentVersion': course.version,
        'state': 'selfReportedComplete',
        'viewedAt': '2026-10-18T11:00:00.000Z',
        'lastPractisedAt': '2026-10-18T11:05:00.000Z',
        'completedAt': '2026-10-18T11:10:00.000Z',
        'practiceCount': 1,
      },
    },
  });

  Map<String, dynamic> firstRecord(Map<String, dynamic> root) =>
      ((root['lessons'] as Map)[course.lessons.first.id] as Map)
          .cast<String, dynamic>();

  setUp(() {
    owned = Directory.systemTemp.createTempSync('jablab-progress-preservation-');
    owners = OwnerResourceRegistry();
    owners.activate(_alice);
    owners.activate(_bob);
    course = SoloBoxingCourse.fromJsonString(
      File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
    );
    progress = courseFileFor(owned, _alice);
  });

  tearDown(() async {
    await owners.retireAll();
    await owned.delete(recursive: true);
  });

  final corruptions = <String, String Function(Map<String, dynamic>)>{
    'truncated JSON': (root) {
      final source = jsonEncode(root);
      return source.substring(0, source.length ~/ 2);
    },
    'unsupported schema': (root) => jsonEncode(root..['schemaVersion'] = 999),
    'wrong course': (root) => jsonEncode(root..['courseId'] = 'synthetic.other'),
    'wrong lessons type': (root) => jsonEncode(root..['lessons'] = <Object>[]),
    'unknown state': (root) {
      final record = firstRecord(root)..['state'] = 'mastered';
      (root['lessons'] as Map)[course.lessons.first.id] = record;
      return jsonEncode(root);
    },
    'negative practice count': (root) {
      final record = firstRecord(root)..['practiceCount'] = -1;
      (root['lessons'] as Map)[course.lessons.first.id] = record;
      return jsonEncode(root);
    },
    'completion without timestamp': (root) {
      final record = firstRecord(root)
        ..['state'] = 'selfReportedComplete'
        ..['completedAt'] = null;
      (root['lessons'] as Map)[course.lessons.first.id] = record;
      return jsonEncode(root);
    },
    'bad record alongside intact records': (root) {
      (root['lessons'] as Map)['synthetic.broken'] = <String, Object?>{
        'state': 'viewed',
      };
      return jsonEncode(root);
    },
  };

  for (final corruption in corruptions.entries) {
    for (final writer in _Writer.values) {
      test('${writer.name} preserves ${corruption.key}', () async {
        final source = corruption.value(
          (jsonDecode(validSource()) as Map).cast<String, dynamic>(),
        );
        await progress.writeAsString(source, flush: true);
        final before = await progress.readAsBytes();
        final parserFailure = anyOf(isA<FormatException>(), isA<TypeError>());

        await expectLater(store().load(), throwsA(parserFailure));
        await expectLater(_write(writer, store(), course), throwsA(parserFailure));

        expect(await progress.readAsBytes(), before);
        expect(
          await FileSystemEntity.type('${progress.path}.tmp', followLinks: false),
          FileSystemEntityType.notFound,
        );
      });
    }
  }

  for (final writer in _Writer.values) {
    test('${writer.name} rechecks data corrupted after a successful load', () async {
      await progress.writeAsString(validSource(), flush: true);
      final handle = store();
      expect((await handle.load()).completedCount(course), 1);
      const corrupt = '{SYNTHETIC corruption after load';
      await progress.writeAsString(corrupt, flush: true);

      await expectLater(_write(writer, handle, course), throwsFormatException);

      expect(await progress.readAsString(), corrupt);
      expect(
        await FileSystemEntity.type('${progress.path}.tmp', followLinks: false),
        FileSystemEntityType.notFound,
      );
    });
  }

  for (final kind in <_NodeKind>[
    _NodeKind.directory,
    _NodeKind.link,
    _NodeKind.danglingLink,
  ]) {
    for (final writer in _Writer.values) {
      test('${writer.name} rejects a final ${kind.name} without changing it', () async {
        // The link's valid JSON target must still be rejected as a final path.
        final witness = await _seedNode(
          progress.path,
          kind,
          contents: validSource(),
        );
        await expectLater(store().load(), throwsA(isA<FileSystemException>()));
        await expectLater(
          _write(writer, store(), course),
          throwsA(isA<FileSystemException>()),
        );

        await witness.expectUnchanged();
        expect(
          await FileSystemEntity.type('${progress.path}.tmp', followLinks: false),
          FileSystemEntityType.notFound,
        );
      });
    }
  }

  for (final kind in _NodeKind.values) {
    for (final writer in _Writer.values) {
      test('${writer.name} preserves orphan ${kind.name} temp as unknown', () async {
        final witness = await _seedNode(
          '${progress.path}.tmp',
          kind,
          contents: validSource(),
        );
        // A recoverable-looking temp is not evidence of committed progress.
        await expectLater(store().load(), throwsA(isA<FileSystemException>()));
        await expectLater(
          _write(writer, store(), course),
          throwsA(isA<FileSystemException>()),
        );

        await witness.expectUnchanged();
        expect(
          await FileSystemEntity.type(progress.path, followLinks: false),
          FileSystemEntityType.notFound,
        );
      });
    }
  }

  test('a malformed orphan temp is preserved without a false empty load', () async {
    final witness = await _seedNode(
      '${progress.path}.tmp',
      _NodeKind.regularFile,
      contents: '{SYNTHETIC uncommitted and truncated',
    );
    await expectLater(store().load(), throwsA(isA<FileSystemException>()));
    await expectLater(
      store().markViewed(course, course.lessons.first),
      throwsA(isA<FileSystemException>()),
    );
    await witness.expectUnchanged();
    expect(
      await FileSystemEntity.type(progress.path, followLinks: false),
      FileSystemEntityType.notFound,
    );
  });

  for (final kind in _NodeKind.values) {
    for (final writer in _Writer.values) {
      test('${writer.name} cannot clobber existing ${kind.name} temp', () async {
        final source = validSource();
        await progress.writeAsString(source, flush: true);
        final before = await progress.readAsBytes();
        final witness = await _seedNode(
          '${progress.path}.tmp',
          kind,
          contents: '{SYNTHETIC earlier incomplete write — korunmalı',
        );
        // A valid final remains readable even while a previous temp is kept.
        expect((await store().load()).completedCount(course), 1);

        await expectLater(
          _write(writer, store(), course),
          throwsA(isA<FileSystemException>()),
        );

        expect(await progress.readAsBytes(), before);
        await witness.expectUnchanged();
        expect((await store().load()).completedCount(course), 1);
      });
    }
  }

  test('fresh progress writes and reopens without leaving a temp', () async {
    expect((await store().load()).records, isEmpty);
    await store().markViewed(course, course.lessons.first);
    await store().markPractised(course, course.lessons.first);
    await store().markCompleted(
      course,
      course.lessons.first,
      selfChecksConfirmed: true,
    );
    await store().markPractised(course, course.lessons.first);

    for (var reopen = 0; reopen < 3; reopen++) {
      final loaded = await store().load();
      final first = loaded.forLesson(course.lessons.first, course.version)!;
      expect(loaded.completedCount(course), 1);
      expect(first.state, SoloLessonState.selfReportedComplete);
      expect(first.practiceCount, 2);
      expect(first.completedAt, isNotNull);
    }
    expect(
      await FileSystemEntity.type('${progress.path}.tmp', followLinks: false),
      FileSystemEntityType.notFound,
    );
  });

  test('a rejected temp write does not poison the same path queue', () async {
    await progress.writeAsString(validSource(), flush: true);
    final blocked = File('${progress.path}.tmp');
    await blocked.writeAsString('SYNTHETIC retained residue', flush: true);
    final handle = store();
    await expectLater(
      handle.markPractised(course, course.lessons.first),
      throwsA(isA<FileSystemException>()),
    );
    // This owned-fixture removal represents a separately resolved obstruction;
    // the product under test must not remove it as part of the rejected save.
    expect(await blocked.readAsString(), 'SYNTHETIC retained residue');
    await blocked.delete();

    await handle.markPractised(course, course.lessons.first);

    final loaded = await store().load();
    expect(loaded.forLesson(course.lessons.first, course.version)?.practiceCount, 3);
    expect(loaded.completedCount(course), 1);
    expect(await blocked.exists(), isFalse);
  });

  test('an unreadable account does not alter guest or another account', () async {
    await store(null).markViewed(course, course.lessons.first);
    await store(_bob).markPractised(course, course.lessons.first);
    final guest = courseFileFor(owned, null);
    final bob = courseFileFor(owned, _bob);
    final guestBefore = await guest.readAsBytes();
    final bobBefore = await bob.readAsBytes();
    const corrupt = '{SYNTHETIC Alice-only corruption';
    await progress.writeAsString(corrupt, flush: true);

    for (final writer in _Writer.values) {
      await expectLater(_write(writer, store(), course), throwsFormatException);
    }

    expect(await progress.readAsString(), corrupt);
    expect(await guest.readAsBytes(), guestBefore);
    expect(await bob.readAsBytes(), bobBefore);
    expect((await store(null).load()).records.length, 1);
    expect((await store(_bob).load()).records.length, 1);
  });
}
