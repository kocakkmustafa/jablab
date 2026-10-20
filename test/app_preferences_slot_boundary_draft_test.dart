// Preference directory slot-boundary and known-commit recovery contracts; no multi-process or power-loss guarantee.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/app_preferences.dart';
import 'package:jablab/app/app_preferences_store.dart';

AppPreferencesCodec _codec() => AppPreferencesCodec(
  supportedLocaleTags: const [
    'tr',
    'en',
    'es-419',
    'pt-BR',
    'de',
    'fr',
    'ja',
    'ar',
  ],
);

const _previous = AppPreferences(
  theme: AppThemePreference.dark,
  localeTag: 'tr',
);
const _desired = AppPreferences(
  theme: AppThemePreference.light,
  localeTag: 'ar',
);
const _subsequent = AppPreferences(
  theme: AppThemePreference.system,
  localeTag: 'ja',
);

Directory _preferencesDirectory(Directory support) => Directory(
  '${support.path}${Platform.pathSeparator}'
  '${FileAppPreferencesStore.directoryName}',
);

File _generation(Directory directory, int number) => File(
  '${directory.path}${Platform.pathSeparator}'
  'prefs-v1-${number.toString().padLeft(16, '0')}.json',
);

Future<void> _seedValid(Directory directory, int count) async {
  await directory.create(recursive: true);
  for (var number = 1; number <= count; number++) {
    await _generation(
      directory,
      number,
    ).writeAsBytes(_codec().encode(_previous), flush: true);
  }
}

Future<Map<String, List<int>>> _seedOrphans(
  Directory directory,
  int count,
) async {
  final saved = <String, List<int>>{};
  for (var i = 0; i < count; i++) {
    // Both interrupted pending names and unrelated names count as raw entries.
    final name = i.isEven ? 'pending-orphan-$i' : 'unknown-$i.txt';
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    await file.writeAsString('preserve-orphan-byte-payload-$i', flush: true);
    saved[name] = await file.readAsBytes();
  }
  return saved;
}

Future<int> _rawEntryCount(Directory directory) async =>
    (await directory.list(followLinks: false).toList()).length;

Future<Map<String, List<int>>> _fileBytes(Directory directory) async {
  final snapshot = <String, List<int>>{};
  await for (final entity in directory.list(followLinks: false)) {
    // These fixtures deliberately contain files only. A later fixture edit
    // must not quietly stop participating in the byte-preservation witness.
    expect(entity, isA<File>());
    if (entity is File) {
      snapshot[entity.uri.pathSegments.last] = await entity.readAsBytes();
    }
  }
  return snapshot;
}

void _expectSnapshotEqual(
  Map<String, List<int>> actual,
  Map<String, List<int>> expected,
) {
  expect(actual.keys, unorderedEquals(expected.keys));
  for (final entry in expected.entries) {
    expect(actual[entry.key], orderedEquals(entry.value), reason: entry.key);
  }
}

Future<void> _expectOrphansUnchanged(
  Directory directory,
  Map<String, List<int>> expected,
) async {
  for (final entry in expected.entries) {
    final file = File('${directory.path}${Platform.pathSeparator}${entry.key}');
    expect(await file.exists(), isTrue, reason: entry.key);
    expect(
      await file.readAsBytes(),
      orderedEquals(entry.value),
      reason: entry.key,
    );
  }
}

FileAppPreferencesStore _reopen(Directory support) => FileAppPreferencesStore(
  codec: _codec(),
  supportDirectory: () async => support,
);

void main() {
  // Four real-filesystem definitions: 31 valid or 29 orphan + 2 valid,
  // each under a normal rename and a rename that throws after committing.
  for (final orphanCount in [0, 29]) {
    for (final throwAfterCommit in [false, true]) {
      test(
        '31 raw entries, $orphanCount orphans, after-commit throw '
        '$throwAfterCommit: exact reopen and subsequent save remain readable',
        () async {
          final support = await Directory.systemTemp.createTemp(
            'prefs-slot-v2-',
          );
          addTearDown(() => support.delete(recursive: true));
          final directory = _preferencesDirectory(support);
          final validCount = 31 - orphanCount;
          await _seedValid(directory, validCount);
          final orphans = await _seedOrphans(directory, orphanCount);
          final previousFile = _generation(directory, validCount);
          final previousBytes = await previousFile.readAsBytes();
          expect(await _rawEntryCount(directory), 31);

          var commits = 0;
          final preparedCounts = <int>[];
          final renamedCounts = <int>[];
          final preparedWasPresent = <bool>[];
          final destinationWasAbsent = <bool>[];
          final committedPayloads = <List<int>>[];
          final store = FileAppPreferencesStore(
            codec: _codec(),
            supportDirectory: () async => support,
            commitPrepared: (prepared, committed) async {
              commits++;
              preparedWasPresent.add(await prepared.exists());
              destinationWasAbsent.add(!await committed.exists());
              preparedCounts.add(await _rawEntryCount(directory));
              await prepared.rename(committed.path);
              renamedCounts.add(await _rawEntryCount(directory));
              committedPayloads.add(await committed.readAsBytes());
              if (throwAfterCommit) {
                throw const FileSystemException('injected after real rename');
              }
            },
          );

          expect(
            (await store.write(_desired)).kind,
            PreferencesWriteKind.committed,
          );
          expect(commits, 1);
          expect(preparedCounts, [32]);
          expect(renamedCounts, [32]);
          expect(preparedWasPresent, [true]);
          expect(destinationWasAbsent, [true]);
          expect(
            committedPayloads.single,
            orderedEquals(_codec().encode(_desired)),
          );
          expect(
            await previousFile.readAsBytes(),
            orderedEquals(previousBytes),
          );
          await _expectOrphansUnchanged(directory, orphans);
          // GC keeps the latest two valid generations, not unknown/orphan files.
          expect(await _rawEntryCount(directory), orphanCount + 2);
          final reopenedFirst = await _reopen(support).read();
          expect(reopenedFirst.kind, PreferencesReadKind.loaded);
          expect(reopenedFirst.value, _desired);

          final desiredFile = _generation(directory, validCount + 1);
          final desiredBytes = await desiredFile.readAsBytes();
          // Use the same queue after the normal/throwing completion. An omitted
          // known-commit GC leaves 32 valid files and makes this save fail.
          expect(
            (await store.write(_subsequent)).kind,
            PreferencesWriteKind.committed,
          );
          expect(commits, 2);
          expect(preparedCounts, [32, orphanCount + 3]);
          expect(renamedCounts, [32, orphanCount + 3]);
          expect(preparedWasPresent, [true, true]);
          expect(destinationWasAbsent, [true, true]);
          expect(
            committedPayloads.last,
            orderedEquals(_codec().encode(_subsequent)),
          );
          // The immediately preceding good value remains as rollback bytes.
          expect(await desiredFile.readAsBytes(), orderedEquals(desiredBytes));
          await _expectOrphansUnchanged(directory, orphans);
          expect(await _rawEntryCount(directory), orphanCount + 2);
          final reopenedSecond = await _reopen(support).read();
          expect(reopenedSecond.kind, PreferencesReadKind.loaded);
          expect(reopenedSecond.value, _subsequent);
        },
      );
    }
  }

  // Two rejection definitions. The mixed case specifically defeats an
  // incorrect reservation based on generations.length instead of raw entries.
  for (final orphanCount in [0, 30]) {
    test(
      '32 raw entries, $orphanCount orphans: fail before commit and preserve every old byte',
      () async {
        final support = await Directory.systemTemp.createTemp('prefs-full-v2-');
        addTearDown(() => support.delete(recursive: true));
        final directory = _preferencesDirectory(support);
        await _seedValid(directory, 32 - orphanCount);
        await _seedOrphans(directory, orphanCount);
        expect(await _rawEntryCount(directory), 32);
        final before = await _fileBytes(directory);
        final beforeRead = await _reopen(support).read();
        expect(beforeRead.kind, PreferencesReadKind.loaded);
        expect(beforeRead.value, _previous);

        var commits = 0;
        final store = FileAppPreferencesStore(
          codec: _codec(),
          supportDirectory: () async => support,
          commitPrepared: (prepared, committed) async {
            commits++;
            await prepared.rename(committed.path);
          },
        );
        expect((await store.write(_desired)).kind, PreferencesWriteKind.failed);
        expect(
          commits,
          0,
          reason: 'Full-directory rejection precedes the commit seam',
        );
        expect(await _rawEntryCount(directory), 32);
        _expectSnapshotEqual(await _fileBytes(directory), before);
        final reopened = await _reopen(support).read();
        expect(reopened.kind, PreferencesReadKind.loaded);
        expect(reopened.value, _previous);
      },
    );
  }

  test(
    'known committed catch reuses the resolved path, not the support provider',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'prefs-provider-v2-',
      );
      addTearDown(() => support.delete(recursive: true));
      final directory = _preferencesDirectory(support);
      await _seedValid(directory, 31);
      var providerCalls = 0;
      var commits = 0;
      final store = FileAppPreferencesStore(
        codec: _codec(),
        supportDirectory: () async {
          providerCalls++;
          if (providerCalls > 1) {
            throw const FileSystemException(
              'provider must not resolve again after commit',
            );
          }
          return support;
        },
        commitPrepared: (prepared, committed) async {
          commits++;
          await prepared.rename(committed.path);
          throw const FileSystemException('injected after real rename');
        },
      );
      expect(
        (await store.write(_desired)).kind,
        PreferencesWriteKind.committed,
      );
      expect(providerCalls, 1);
      expect(commits, 1);
      expect(await _rawEntryCount(directory), 2);
      final reopened = await _reopen(support).read();
      expect(reopened.kind, PreferencesReadKind.loaded);
      expect(reopened.value, _desired);
    },
  );

  // A deterministic cleanup-scan fault, without a new production test seam.
  // The seam deliberately adds its OWN marker after rename, taking 32 to 33.
  // This is not the ordinary single-writer path. No automatic orphan cleanup
  // is expected; only this test removes its injected marker to inspect recovery.
  for (final throwAfterCommit in [false, true]) {
    test(
      'cleanup scan fault after rename, throw $throwAfterCommit: known commit survives',
      () async {
        final support = await Directory.systemTemp.createTemp(
          'prefs-gc-fault-v2-',
        );
        addTearDown(() => support.delete(recursive: true));
        final directory = _preferencesDirectory(support);
        await _seedValid(directory, 31);
        final before = await _fileBytes(directory);
        final marker = File(
          '${directory.path}${Platform.pathSeparator}unknown-owned-gc-fault.txt',
        );
        var commits = 0;
        final store = FileAppPreferencesStore(
          codec: _codec(),
          supportDirectory: () async => support,
          commitPrepared: (prepared, committed) async {
            commits++;
            await prepared.rename(committed.path);
            await marker.writeAsString('owned-by-this-fault-test', flush: true);
            if (throwAfterCommit) {
              throw const FileSystemException(
                'injected after rename plus GC fault',
              );
            }
          },
        );
        expect(
          (await store.write(_desired)).kind,
          PreferencesWriteKind.committed,
        );
        expect(commits, 1);
        expect(await _rawEntryCount(directory), 33);
        final after = await _fileBytes(directory);
        expect(after.length, before.length + 2); // New commit and owned marker.
        for (final entry in before.entries) {
          expect(
            after[entry.key],
            orderedEquals(entry.value),
            reason: entry.key,
          );
        }
        expect(await marker.readAsString(), 'owned-by-this-fault-test');
        expect(
          await _generation(directory, 32).readAsBytes(),
          orderedEquals(_codec().encode(_desired)),
        );
        expect(
          (await _reopen(support).read()).kind,
          PreferencesReadKind.invalid,
        );

        // Explicit fixture recovery only; production does not erase this file.
        await marker.delete();
        expect(await _rawEntryCount(directory), 32);
        final recovered = await _reopen(support).read();
        expect(recovered.kind, PreferencesReadKind.loaded);
        expect(recovered.value, _desired);
      },
    );
  }
}
