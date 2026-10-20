import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_preferences.dart';

/// Writes through this store instance are serialized. A new immutable
/// generation is committed by renaming a flushed prepared file to an unused
/// name in the same directory.
/// The previous good file is never the rename target and stays intact if
/// preparation/commit fails. No atomic-overwrite promise is needed.
///
/// Successful commits retain the latest two valid generations. Cleanup is
/// best effort and cannot turn a committed preference into a reported failure.
/// This is not a power-loss/fsync-directory guarantee or a multi-process lock.
class FileAppPreferencesStore implements AppPreferencesStore {
  FileAppPreferencesStore({
    required this.codec,
    Future<Directory> Function()? supportDirectory,
    Future<void> Function(File prepared, File committed)? commitPrepared,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _commitPrepared = commitPrepared ?? _renamePrepared;

  final AppPreferencesCodec codec;
  final Future<Directory> Function() _supportDirectory;

  /// Fault-injection seam. Production uses rename to an unused sibling path.
  final Future<void> Function(File prepared, File committed) _commitPrepared;
  Future<void> _tail = Future<void>.value();
  static const directoryName = 'app_preferences';
  static const _maxDirectoryEntries = 32;
  static const _maxGeneration = 9007199254740990;
  static final _name = RegExp(r'^prefs-v1-(\d{16})\.json$');

  @override
  bool get persistent => true;

  Future<Directory> _directory() async {
    final support = await _supportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}$directoryName');
  }

  static Future<void> _renamePrepared(File prepared, File committed) async {
    await prepared.rename(committed.path);
  }

  Future<List<_Generation>> _scan(
    Directory directory, {
    bool reserveWriteSlot = false,
  }) async {
    if (!await directory.exists()) return <_Generation>[];
    final result = <_Generation>[];
    // A pending file becomes the committed file by rename: one extra raw
    // entry is enough. Reads and post-commit pruning keep the full limit.
    final entryLimit = _maxDirectoryEntries - (reserveWriteSlot ? 1 : 0);
    var count = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (++count > entryLimit) {
        throw const FormatException(
          'Preferences directory exceeds entry limit',
        );
      }
      if (entity is! File) continue;
      final baseName = entity.uri.pathSegments.last;
      final match = _name.firstMatch(baseName);
      if (match == null) continue;
      final generation = int.tryParse(match[1]!);
      if (generation == null || generation < 1 || generation > _maxGeneration) {
        throw const FormatException('Invalid preferences generation');
      }
      result.add(_Generation(entity, generation));
    }
    result.sort((a, b) => b.number.compareTo(a.number));
    return result;
  }

  Future<List<int>> _boundedBytes(File file) async {
    final handle = await file.open(mode: FileMode.read);
    try {
      // Decode rejects the extra byte; a corrupt huge file is not read whole.
      final result = <int>[];
      while (result.length <= AppPreferencesCodec.maxBytes) {
        final chunk = await handle.read(
          AppPreferencesCodec.maxBytes + 1 - result.length,
        );
        if (chunk.isEmpty) break;
        result.addAll(chunk);
      }
      return result;
    } finally {
      await handle.close();
    }
  }

  @override
  Future<PreferencesReadResult> read() async {
    try {
      final generations = await _scan(await _directory());
      if (generations.isEmpty) {
        return const PreferencesReadResult(PreferencesReadKind.missing);
      }
      var skipped = false;
      for (final generation in generations) {
        try {
          final value = codec.decode(await _boundedBytes(generation.file));
          return PreferencesReadResult(
            skipped
                ? PreferencesReadKind.recovered
                : PreferencesReadKind.loaded,
            value,
          );
        } on Object {
          skipped = true;
        }
      }
      return const PreferencesReadResult(PreferencesReadKind.invalid);
    } on FormatException {
      return const PreferencesReadResult(PreferencesReadKind.invalid);
    } on Object {
      return const PreferencesReadResult(PreferencesReadKind.unavailable);
    }
  }

  @override
  Future<PreferencesWriteResult> write(AppPreferences value) {
    final result = Completer<PreferencesWriteResult>();
    // Every direct store caller is serialized, not just the UI controller.
    // Each branch completes normally so a failed attempt cannot poison the tail.
    _tail = _tail.then((_) async {
      try {
        result.complete(await _writeOne(value));
      } on Object {
        result.complete(
          const PreferencesWriteResult(PreferencesWriteKind.failed),
        );
      }
    });
    return result.future;
  }

  Future<PreferencesWriteResult> _writeOne(AppPreferences value) async {
    File? prepared;
    File? committed;
    List<int>? encoded;
    try {
      encoded = codec.encode(value); // Validate before touching the directory.
      final directory = await _directory();
      await directory.create(recursive: true);
      // Reject full directories before assigning a destination or creating
      // a pending file. Count every entity, including unknown/orphan entries.
      final generations = await _scan(directory, reserveWriteSlot: true);
      final last = generations.isEmpty ? 0 : generations.first.number;
      if (last >= _maxGeneration) {
        return const PreferencesWriteResult(PreferencesWriteKind.failed);
      }
      final number = last + 1;
      final prefix = '${directory.path}${Platform.pathSeparator}';
      committed = File(
        '${prefix}prefs-v1-${number.toString().padLeft(16, '0')}.json',
      );
      if (await committed.exists()) {
        return const PreferencesWriteResult(PreferencesWriteKind.failed);
      }
      prepared = File(
        '${prefix}pending-$number-${DateTime.now().microsecondsSinceEpoch}',
      );
      // Single store writer owns this new path. No existing committed file is
      // opened for writing. The same-directory rename is the commit point.
      await prepared.writeAsBytes(encoded, flush: true);
      await _commitPrepared(prepared, committed);
      if (!_sameBytes(await _boundedBytes(committed), encoded)) {
        return const PreferencesWriteResult(PreferencesWriteKind.uncertain);
      }
      await _pruneValidGenerations(directory);
      return const PreferencesWriteResult(PreferencesWriteKind.committed);
    } on Object {
      // If the platform/fault seam threw after commit, read back the exact
      // immutable destination. Do not report a known committed write as failed.
      if (committed != null && encoded != null) {
        try {
          if (await committed.exists()) {
            final actual = await _boundedBytes(committed);
            if (_sameBytes(actual, encoded)) {
              // Reuse the resolved immutable destination's directory. Do not
              // call the support-directory provider again after a known commit.
              await _pruneValidGenerations(committed.parent);
              return const PreferencesWriteResult(
                PreferencesWriteKind.committed,
              );
            }
            return const PreferencesWriteResult(PreferencesWriteKind.uncertain);
          }
        } on Object {
          return const PreferencesWriteResult(PreferencesWriteKind.uncertain);
        }
      }
      return const PreferencesWriteResult(PreferencesWriteKind.failed);
    } finally {
      // Only this attempt's uncommitted prepared file may be removed here.
      if (prepared != null) {
        try {
          if (await prepared.exists()) await prepared.delete();
        } on Object {
          // A leftover prepared file is never selected by read().
        }
      }
    }
  }

  Future<void> _pruneValidGenerations(Directory directory) async {
    try {
      var validRetained = 0;
      for (final generation in await _scan(directory)) {
        try {
          codec.decode(await _boundedBytes(generation.file));
          if (++validRetained > 2) await generation.file.delete();
        } on Object {
          // Unknown/corrupt records are not silently destroyed. Directory entry
          // limits bound future work and produce a visible failure if exceeded.
        }
      }
    } on Object {
      // Commit is already complete. Cleanup cannot revoke it.
    }
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _Generation {
  const _Generation(this.file, this.number);
  final File file;
  final int number;
}
