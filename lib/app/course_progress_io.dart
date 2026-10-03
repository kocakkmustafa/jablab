import 'dart:io';

import 'owner_resource_lifetime.dart';

final class _CourseFileQueue {
  Future<void> tail = Future<void>.value();
  int generation = 0;

  Future<T> enqueue<T>(Future<T> Function() operation) {
    final Future<T> result = tail.then((_) => operation());
    tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

final Map<String, _CourseFileQueue> _courseFiles = <String, _CourseFileQueue>{};

_CourseFileQueue _queueFor(File file) => _courseFiles.putIfAbsent(
  Uri.file(file.absolute.path).normalizePath().toFilePath(),
  _CourseFileQueue.new,
);

/// Serializes app-local course writes. Account deletion invalidates leases
/// before waiting for active writes, so an old page cannot resurrect its file.
final class CourseProgressIoLease {
  factory CourseProgressIoLease(
    File file, {
    OwnerResourceLifetime? ownerLifetime,
  }) {
    final _CourseFileQueue queue = _queueFor(file);
    final OwnerResourceLifetime lifetime =
        ownerLifetime ?? defaultOwnerResourceRegistry.capture(null);
    lifetime.checkActive();
    return CourseProgressIoLease._(queue, queue.generation, lifetime);
  }

  const CourseProgressIoLease._(
    this._queue,
    this._generation,
    this._ownerLifetime,
  );

  final _CourseFileQueue _queue;
  final int _generation;
  final OwnerResourceLifetime _ownerLifetime;

  void checkCurrent() {
    _ownerLifetime.checkActive();
    if (_generation != _queue.generation) {
      throw StateError('Course progress store was invalidated by deletion');
    }
  }

  Future<T> read<T>(Future<T> Function() operation) =>
      _ownerLifetime.runCourseIo(() async {
        checkCurrent();
        final T value = await operation();
        checkCurrent();
        return value;
      });

  Future<T> mutate<T>(Future<T> Function() operation) =>
      _ownerLifetime.runCourseIo(
        () => _queue.enqueue(() async {
          checkCurrent();
          final T value = await operation();
          checkCurrent();
          return value;
        }),
      );
}

Future<void> deleteCourseProgressFile(File file) {
  final _CourseFileQueue queue = _queueFor(file);
  queue.generation++;
  return queue.enqueue(() async {
    for (final File target in <File>[file, File('${file.path}.tmp')]) {
      if (await FileSystemEntity.type(target.path, followLinks: false) ==
          FileSystemEntityType.file) {
        await target.delete();
      }
    }
  });
}
