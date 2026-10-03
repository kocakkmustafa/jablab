import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/account_bridge.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:jablab/app/solo_boxing_progress.dart';

const String _alice = '11111111-1111-4111-8111-111111111111';
const String _bob = '22222222-2222-4222-8222-222222222222';

SessionRecord _record(String lesson) => SessionRecord(
  lessonId: lesson,
  completedAt: DateTime.utc(2026, 10, 2),
  workedSeconds: 10,
  unitsCompleted: 1,
  plannedUnits: 1,
  unitLabel: 'round',
  lessonClass: 'unscored',
);

final class _Gate {
  final Completer<void> entered = Completer<void>();
  final Completer<void> release = Completer<void>();

  Future<void> wait() async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
  }
}

final class _GatedFile implements File {
  _GatedFile(this.file, {this.existsGate, this.readGate, this.parentGate});

  final File file;
  final _Gate? existsGate;
  final _Gate? readGate;
  final _Gate? parentGate;

  @override
  String get path => file.path;
  @override
  File get absolute => file.absolute;
  @override
  Directory get parent => parentGate == null
      ? file.parent
      : _GatedDirectory(file.parent, parentGate!);

  @override
  Future<bool> exists() async {
    await existsGate?.wait();
    return file.exists();
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    await readGate?.wait();
    return file.readAsString(encoding: encoding);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected gated File method $invocation');
}

final class _GatedDirectory implements Directory {
  _GatedDirectory(this.directory, this.gate);
  final Directory directory;
  final _Gate gate;

  @override
  Future<Directory> create({bool recursive = false}) async {
    await gate.wait();
    return directory.create(recursive: recursive);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected gated Directory method $invocation');
}

Future<void> _eventTurn() => Future<void>.delayed(Duration.zero);

void main() {
  late Directory directory;
  late OwnerResourceRegistry owners;
  late SoloBoxingCourse course;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('jablab-owner-lifetime-');
    owners = OwnerResourceRegistry();
    owners.activate(_alice);
    owners.activate(_bob);
    course = SoloBoxingCourse.fromJsonString(
      File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
    );
  });
  tearDown(() async {
    await owners.retireAll();
    await directory.delete(recursive: true);
  });

  ContentRepository repository({
    File Function(Directory, String?)? sessionFile,
    File Function(Directory, String?)? courseFile,
  }) => ContentRepository(
    historyDirectoryOverride: directory,
    ownerRegistry: owners,
    sessionFileOverride: sessionFile,
    courseFileOverride: courseFile,
  );

  test(
    'all repository handles share one owner lease and retired reads fail closed',
    () async {
      final JsonlSessionStore first =
          await repository().openStore(accountUserId: _alice)
              as JsonlSessionStore;
      final JsonlSessionStore second =
          await repository().openStore(accountUserId: _alice)
              as JsonlSessionStore;
      final JsonlSessionStore attempts =
          await repository(
                sessionFile: (root, _) =>
                    File('${root.path}/alice-attempts.jsonl'),
              ).openStore(accountUserId: _alice)
              as JsonlSessionStore;
      final OwnerResourceLifetime lifetime = owners.capture(_alice);
      expect(identical(first.writeLease, second.writeLease), isTrue);
      expect(identical(first.writeLease, attempts.writeLease), isTrue);
      await first.append(_record('existing'));
      await attempts.append(_record('attempt'));
      bool notifiedAfterClosure = false;
      lifetime.active.addListener(() {
        notifiedAfterClosure = !lifetime.journalWrites.isActive;
        expect(() => owners.capture(_alice), throwsStateError);
      });

      final Future<void> drained = owners.retire(_alice);
      expect(lifetime.isActive, isFalse);
      expect(notifiedAfterClosure, isTrue);
      for (final SessionStore handle in <SessionStore>[
        first,
        second,
        attempts,
      ]) {
        await expectLater(
          handle.append(_record('late')),
          throwsA(isA<SessionStoreRetiredException>()),
        );
        await expectLater(
          handle.recent(),
          throwsA(isA<SessionStoreRetiredException>()),
        );
        await expectLater(
          handle.workedSecondsFor('existing'),
          throwsA(isA<SessionStoreRetiredException>()),
        );
        await expectLater(
          handle.unreadableRecords(),
          throwsA(isA<SessionStoreRetiredException>()),
        );
      }
      await drained;
      expect(await sessionFileFor(directory, _alice).exists(), isTrue);
      expect(
        await File('${directory.path}/alice-attempts.jsonl').exists(),
        isTrue,
      );
    },
  );

  test(
    'delayed history and course directory opens retain the captured closed epoch',
    () async {
      final Completer<Directory> support = Completer<Directory>();
      final ContentRepository delayed = ContentRepository(
        ownerRegistry: owners,
        historyDirectoryProvider: () => support.future,
      );
      final Future<void> historyRejected = expectLater(
        delayed.openStore(accountUserId: _alice),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      final Future<void> courseRejected = expectLater(
        delayed.openSoloProgressStore(accountUserId: _alice),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      await owners.retire(_alice);
      final OwnerResourceLifetime successor = owners.activate(_alice);
      support.complete(directory);
      await Future.wait<void>(<Future<void>>[historyRejected, courseRejected]);
      expect(owners.capture(_alice), same(successor));
      expect(await sessionFileFor(directory, _alice).exists(), isFalse);
      expect(await courseFileFor(directory, _alice).exists(), isFalse);
    },
  );

  test(
    'confirmed erasure waits for both held journal write and course read',
    () async {
      final ContentRepository plain = repository();
      final SessionStore history = await plain.openStore(accountUserId: _alice);
      await history.append(_record('before'));
      final SoloCourseProgressStore progress = await plain
          .openSoloProgressStore(accountUserId: _alice);
      await progress.markViewed(course, course.lessons.first);
      final File journal = sessionFileFor(directory, _alice);
      final File courseFile = courseFileFor(directory, _alice);
      await File('${journal.path}.tmp').writeAsString('history residue');
      await File('${courseFile.path}.tmp').writeAsString('course residue');
      final _Gate writeGate = _Gate();
      final _Gate readGate = _Gate();
      final SessionStore heldHistory = await repository(
        sessionFile: (_, _) => _GatedFile(journal, existsGate: writeGate),
      ).openStore(accountUserId: _alice);
      final SoloCourseProgressStore heldProgress = await repository(
        courseFile: (_, _) => _GatedFile(courseFile, readGate: readGate),
      ).openSoloProgressStore(accountUserId: _alice);
      final Future<void> writeRejected = expectLater(
        heldHistory.append(_record('late')),
        throwsA(isA<SessionStoreRetiredException>()),
      );
      final Future<void> readRejected = expectLater(
        heldProgress.load(),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      await Future.wait<void>(<Future<void>>[
        writeGate.entered.future,
        readGate.entered.future,
      ]);
      bool erased = false;
      final Future<void> cleanup = clearLocalHistoryFor(
        _alice,
        supportDirectory: directory,
        ownerRegistry: owners,
      );
      final Future<void> observed = cleanup.then((_) => erased = true);
      final Future<void> duplicate = clearLocalHistoryFor(
        _alice,
        supportDirectory: directory,
        ownerRegistry: owners,
      );
      expect(identical(cleanup, duplicate), isTrue);
      expect(() => owners.capture(_alice), throwsStateError);
      expect(() => owners.activate(_alice), throwsStateError);
      await _eventTurn();
      expect(erased, isFalse);
      expect(await journal.exists(), isTrue);
      expect(await courseFile.exists(), isTrue);
      expect(await File('${journal.path}.tmp').exists(), isTrue);
      writeGate.release.complete();
      await writeRejected;
      await _eventTurn();
      expect(
        erased,
        isFalse,
        reason: 'the independent course read is still admitted IO',
      );
      expect(await journal.exists(), isTrue);
      readGate.release.complete();
      await readRejected;
      await observed;
      for (final File file in <File>[
        journal,
        File('${journal.path}.tmp'),
        courseFile,
        File('${courseFile.path}.tmp'),
      ]) {
        expect(await file.exists(), isFalse);
      }
      await expectLater(
        history.append(_record('resurrect')),
        throwsA(isA<SessionStoreRetiredException>()),
      );
      await expectLater(
        progress.load(),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      await expectLater(
        plain.openStore(accountUserId: _alice),
        throwsStateError,
      );
    },
  );

  test(
    'admitted course write and its queued successor drain before any erasure',
    () async {
      final SessionStore history = await repository().openStore(
        accountUserId: _alice,
      );
      await history.append(_record('keep-until-drain'));
      final SoloCourseProgressStore progress = await repository()
          .openSoloProgressStore(accountUserId: _alice);
      await progress.markViewed(course, course.lessons.first);
      final _Gate parentGate = _Gate();
      final SoloCourseProgressStore held = await repository(
        courseFile: (root, owner) =>
            _GatedFile(courseFileFor(root, owner), parentGate: parentGate),
      ).openSoloProgressStore(accountUserId: _alice);
      final Future<void> firstRejected = expectLater(
        held.markPractised(course, course.lessons.first),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      await parentGate.entered.future;
      final Future<void> queuedRejected = expectLater(
        progress.markPractised(course, course.lessons.first),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      bool erased = false;
      final Future<void> cleanup = clearLocalHistoryFor(
        _alice,
        supportDirectory: directory,
        ownerRegistry: owners,
      ).then((_) => erased = true);
      await _eventTurn();
      expect(erased, isFalse);
      expect(await sessionFileFor(directory, _alice).exists(), isTrue);
      expect(await courseFileFor(directory, _alice).exists(), isTrue);
      parentGate.release.complete();
      await Future.wait<void>(<Future<void>>[
        firstRejected,
        queuedRejected,
        cleanup,
      ]);
      expect(await sessionFileFor(directory, _alice).exists(), isFalse);
      expect(await courseFileFor(directory, _alice).exists(), isFalse);
      expect(
        await File('${courseFileFor(directory, _alice).path}.tmp').exists(),
        isFalse,
      );
    },
  );

  for (final bool present in <bool>[false, true]) {
    test(
      'held course read ${present ? 'with records' : 'of a missing file'} rejects after retirement',
      () async {
        if (present) {
          await (await repository().openSoloProgressStore(
            accountUserId: _alice,
          )).markViewed(course, course.lessons.first);
        }
        final _Gate gate = _Gate();
        final SoloCourseProgressStore held = await repository(
          courseFile: (root, owner) =>
              _GatedFile(courseFileFor(root, owner), existsGate: gate),
        ).openSoloProgressStore(accountUserId: _alice);
        final Future<void> rejected = expectLater(
          held.load(),
          throwsA(isA<OwnerResourceRetiredException>()),
        );
        await gate.entered.future;
        bool drained = false;
        final Future<void> retirement = owners
            .retire(_alice)
            .then((_) => drained = true);
        await _eventTurn();
        expect(drained, isFalse);
        gate.release.complete();
        await rejected;
        await retirement;
        expect(await courseFileFor(directory, _alice).exists(), present);
      },
    );
  }

  test(
    'A cleanup preserves B live writes, B tmp and guest byte-for-byte',
    () async {
      final ContentRepository plain = repository();
      final SessionStore alice = await plain.openStore(accountUserId: _alice);
      final SessionStore bob = await plain.openStore(accountUserId: _bob);
      final SessionStore guest = await plain.openStore();
      await alice.append(_record('alice'));
      await bob.append(_record('bob-before'));
      await guest.append(_record('guest'));
      final SoloCourseProgressStore bobProgress = await plain
          .openSoloProgressStore(accountUserId: _bob);
      final SoloCourseProgressStore guestProgress = await plain
          .openSoloProgressStore();
      await bobProgress.markViewed(course, course.lessons.first);
      await guestProgress.markViewed(course, course.lessons.first);
      final File bobTmp = File('${sessionFileFor(directory, _bob).path}.tmp');
      final File bobCourseTmp = File(
        '${courseFileFor(directory, _bob).path}.tmp',
      );
      await bobTmp.writeAsString('B crash residue');
      await bobCourseTmp.writeAsString('B course residue');
      final String guestBytes = await sessionFileFor(
        directory,
        null,
      ).readAsString();
      final String guestCourseBytes = await courseFileFor(
        directory,
        null,
      ).readAsString();
      final _Gate gate = _Gate();
      final SessionStore held = await repository(
        sessionFile: (root, owner) =>
            _GatedFile(sessionFileFor(root, owner), existsGate: gate),
      ).openStore(accountUserId: _alice);
      final Future<void> rejected = expectLater(
        held.append(_record('old-A')),
        throwsA(isA<SessionStoreRetiredException>()),
      );
      await gate.entered.future;
      final Future<void> cleanup = clearLocalHistoryFor(
        _alice,
        supportDirectory: directory,
        ownerRegistry: owners,
      );
      await bob.append(_record('bob-after'));
      await bobProgress.markPractised(course, course.lessons.first);
      // Successful B atomic writes consume their own tmp; restore independent
      // crash residue, then verify A erasure never targets it.
      await bobTmp.writeAsString('B crash residue');
      await bobCourseTmp.writeAsString('B course residue');
      final String bobBytes = await sessionFileFor(
        directory,
        _bob,
      ).readAsString();
      final String bobCourseBytes = await courseFileFor(
        directory,
        _bob,
      ).readAsString();
      gate.release.complete();
      await rejected;
      await cleanup;
      expect(owners.capture(_bob).isActive, isTrue);
      expect(
        (await bob.recent()).map((r) => r.lessonId),
        containsAll(<String>['bob-before', 'bob-after']),
      );
      expect(await sessionFileFor(directory, _bob).readAsString(), bobBytes);
      expect(
        await courseFileFor(directory, _bob).readAsString(),
        bobCourseBytes,
      );
      expect(await bobTmp.readAsString(), 'B crash residue');
      expect(await bobCourseTmp.readAsString(), 'B course residue');
      expect(await sessionFileFor(directory, null).readAsString(), guestBytes);
      expect(
        await courseFileFor(directory, null).readAsString(),
        guestCourseBytes,
      );
      expect(await sessionFileFor(directory, _alice).exists(), isFalse);
    },
  );

  test(
    'logout or recovery retirement preserves persisted data until explicit fresh admission',
    () async {
      final ContentRepository plain = repository();
      final SessionStore oldHistory = await plain.openStore(
        accountUserId: _alice,
      );
      final SoloCourseProgressStore oldProgress = await plain
          .openSoloProgressStore(accountUserId: _alice);
      await oldHistory.append(_record('persisted'));
      await oldProgress.markPractised(course, course.lessons.first);
      final String historyBytes = await sessionFileFor(
        directory,
        _alice,
      ).readAsString();
      final String courseBytes = await courseFileFor(
        directory,
        _alice,
      ).readAsString();
      final OwnerResourceLifetime old = owners.capture(_alice);
      await old.retireAndDrain();
      await expectLater(
        plain.openStore(accountUserId: _alice),
        throwsStateError,
      );
      expect(
        await sessionFileFor(directory, _alice).readAsString(),
        historyBytes,
      );
      expect(
        await courseFileFor(directory, _alice).readAsString(),
        courseBytes,
      );
      final OwnerResourceLifetime fresh = owners.activate(_alice);
      expect(fresh.epoch, greaterThan(old.epoch));
      expect(fresh.journalWrites, isNot(same(old.journalWrites)));
      expect(
        (await (await plain.openStore(
          accountUserId: _alice,
        )).recent()).single.lessonId,
        'persisted',
      );
      expect(
        (await (await plain.openSoloProgressStore(
              accountUserId: _alice,
            )).load())
            .forLesson(course.lessons.first, course.version)
            ?.practiceCount,
        1,
      );
      await expectLater(
        oldHistory.append(_record('late')),
        throwsA(isA<SessionStoreRetiredException>()),
      );
      await expectLater(
        oldProgress.load(),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
    },
  );

  test(
    'confirmed UUID validation and retirement precede support directory await',
    () async {
      final Completer<Directory> support = Completer<Directory>();
      int directoryCalls = 0;
      Future<Directory> provider() {
        directoryCalls++;
        return support.future;
      }

      expect(
        () => clearLocalHistoryFor(
          '../guest',
          ownerRegistry: owners,
          supportDirectoryProvider: provider,
        ),
        throwsArgumentError,
      );
      expect(directoryCalls, 0);
      final OwnerResourceLifetime alice = owners.capture(_alice);
      final Future<void> cleanup = clearLocalHistoryFor(
        _alice.toUpperCase(),
        ownerRegistry: owners,
        supportDirectoryProvider: provider,
      );
      expect(alice.isActive, isFalse);
      expect(alice.journalWrites.isActive, isFalse);
      expect(() => owners.activate(_alice), throwsStateError);
      await _eventTurn();
      expect(directoryCalls, 1);
      support.complete(directory);
      await cleanup;
      expect(owners.capture(_bob).isActive, isTrue);
    },
  );

  test(
    'reentrant host IO retirement registers the operation before callback code',
    () async {
      final OwnerResourceLifetime lifetime = owners.capture(_alice);
      final Completer<void> release = Completer<void>();
      bool drained = false;
      late Future<void> retirement;
      final Future<void> operation = lifetime.runCourseIo<void>(() async {
        retirement = lifetime.retireAndDrain().then((_) => drained = true);
        await release.future;
      });
      final Future<void> rejected = expectLater(
        operation,
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      await _eventTurn();
      expect(drained, isFalse);
      expect(() => owners.activate(_alice), throwsStateError);
      release.complete();
      await rejected;
      await retirement;
      expect(owners.activate(_alice).isActive, isTrue);
    },
  );

  test(
    'independent storage namespaces do not retire the same UUID elsewhere',
    () async {
      final Directory otherRoot = Directory('${directory.path}/other');
      await otherRoot.create();
      final OwnerResourceRegistry otherOwners = OwnerResourceRegistry()
        ..activate(_alice);
      final SessionStore other = await ContentRepository(
        historyDirectoryOverride: otherRoot,
        ownerRegistry: otherOwners,
      ).openStore(accountUserId: _alice);
      await other.append(_record('other namespace'));
      await clearLocalHistoryFor(
        _alice,
        supportDirectory: directory,
        ownerRegistry: owners,
      );
      expect(otherOwners.capture(_alice).isActive, isTrue);
      expect((await other.recent()).single.lessonId, 'other namespace');
      await otherOwners.retireAll();
    },
  );

  test(
    'stale UI A epoch1 cleanup cannot retire or erase fresh A epoch2',
    () async {
      final ContentRepository plain = repository();
      final OwnerResourceLifetime openingA = owners.capture(_alice);
      Future<void> stalePageCleanup(String id) => clearLocalHistoryFor(
        id,
        supportDirectory: directory,
        ownerRegistry: owners,
        expectedLifetime: openingA,
      );
      await (await plain.openStore(
        accountUserId: _alice,
      )).append(_record('A epoch1'));
      await openingA.retireAndDrain();
      await (await plain.openStore(accountUserId: _bob)).append(_record('B'));
      final OwnerResourceLifetime freshA = owners.activate(_alice);
      await (await plain.openStore(
        accountUserId: _alice,
      )).append(_record('A epoch2'));
      await (await plain.openSoloProgressStore(
        accountUserId: _alice,
      )).markPractised(course, course.lessons.first);
      await (await plain.openStore()).append(_record('guest'));
      final List<File> preserved = <File>[
        sessionFileFor(directory, _alice),
        courseFileFor(directory, _alice),
        sessionFileFor(directory, _bob),
        sessionFileFor(directory, null),
      ];
      for (final File file in preserved.toList()) {
        final File tmp = File('${file.path}.tmp');
        await tmp.writeAsString('preserved crash residue');
        preserved.add(tmp);
      }
      final List<String> before = <String>[
        for (final File file in preserved) await file.readAsString(),
      ];
      bool retired = false;
      freshA.active.addListener(() => retired = true);
      expect(owners.isCurrent(openingA), isFalse);
      expect(owners.isCurrent(freshA), isTrue);
      expect(
        () => stalePageCleanup(_alice),
        throwsA(isA<OwnerResourceStaleCleanupException>()),
      );
      await _eventTurn();
      expect(retired, isFalse);
      expect(owners.capture(_alice), same(freshA));
      expect(owners.capture(_bob).isActive, isTrue);
      expect(owners.capture(null).isActive, isTrue);
      for (int i = 0; i < preserved.length; i++) {
        expect(await preserved[i].readAsString(), before[i]);
      }
    },
  );

  test(
    'current initiating lifetime guard erases exactly its four regular files',
    () async {
      final OwnerResourceLifetime initiating = owners.capture(_alice);
      final File history = sessionFileFor(directory, _alice);
      final File progress = courseFileFor(directory, _alice);
      final List<File> files = <File>[
        history,
        File('${history.path}.tmp'),
        progress,
        File('${progress.path}.tmp'),
      ];
      for (final File file in files) {
        await file.writeAsString('erase');
      }
      final Future<void> cleanup = clearLocalHistoryFor(
        _alice,
        supportDirectory: directory,
        ownerRegistry: owners,
        expectedLifetime: initiating,
      );
      expect(initiating.isActive, isFalse);
      await cleanup;
      for (final File file in files) {
        expect(await file.exists(), isFalse);
      }
      expect(owners.capture(_bob).isActive, isTrue);
    },
  );

  test(
    'UI lifetime mismatch rejects before provider while receipt UUID policy stays separate',
    () async {
      int providerCalls = 0;
      Future<Directory> provider() async {
        providerCalls++;
        return directory;
      }

      final OwnerResourceLifetime alice = owners.capture(_alice);
      expect(
        () => clearLocalHistoryFor(
          _bob,
          ownerRegistry: owners,
          expectedLifetime: alice,
          supportDirectoryProvider: provider,
        ),
        throwsA(isA<OwnerResourceStaleCleanupException>()),
      );
      final OwnerResourceRegistry foreign = OwnerResourceRegistry()
        ..activate(_alice);
      expect(
        () => clearLocalHistoryFor(
          _alice,
          ownerRegistry: owners,
          expectedLifetime: foreign.capture(_alice),
          supportDirectoryProvider: provider,
        ),
        throwsA(isA<OwnerResourceStaleCleanupException>()),
      );
      await owners.retire(_alice);
      expect(owners.isCurrent(alice), isTrue);
      expect(
        () => clearLocalHistoryFor(
          _alice,
          ownerRegistry: owners,
          expectedLifetime: alice,
          supportDirectoryProvider: provider,
        ),
        throwsA(isA<OwnerResourceStaleCleanupException>()),
      );
      expect(providerCalls, 0);
      // Independently authenticated receipt reconciliation is explicitly UUID
      // scoped and does not reuse the stale UI initiating-ticket policy.
      await clearLocalHistoryFor(
        _alice,
        ownerRegistry: owners,
        supportDirectoryProvider: provider,
      );
      expect(providerCalls, 1);
      await foreign.retireAll();
    },
  );

  test(
    'cleanup failure retains closed admission and later receipt cleanup can retry',
    () async {
      await (await repository().openStore(
        accountUserId: _alice,
      )).append(_record('persist-until-retry'));
      await expectLater(
        clearLocalHistoryFor(
          _alice,
          ownerRegistry: owners,
          supportDirectoryProvider: () async =>
              throw StateError('directory unavailable'),
        ),
        throwsStateError,
      );
      expect(() => owners.capture(_alice), throwsStateError);
      expect(await sessionFileFor(directory, _alice).exists(), isTrue);
      await clearLocalHistoryFor(
        _alice,
        supportDirectory: directory,
        ownerRegistry: owners,
      );
      expect(await sessionFileFor(directory, _alice).exists(), isFalse);
      expect(() => owners.capture(_alice), throwsStateError);
    },
  );

  test(
    'injected history store keeps its filesystem-free override behavior',
    () async {
      final SessionStore injected = JsonlSessionStore(
        File('${directory.path}/injected.jsonl'),
      );
      await owners.retireAll();
      final ContentRepository override = ContentRepository(
        ownerRegistry: owners,
        storeOverride: injected,
        historyDirectoryProvider: () async =>
            throw StateError('must not resolve storage'),
      );
      expect(await override.openStore(accountUserId: _alice), same(injected));
      await injected.append(_record('override'));
      expect((await injected.recent()).single.lessonId, 'override');
    },
  );
}
