import 'dart:io';

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

_CourseFileQueue _queueFor(File file) =>
    _courseFiles.putIfAbsent(file.absolute.path, _CourseFileQueue.new);

/// Serializes app-local course writes. Account deletion invalidates leases
/// before waiting for active writes, so an old page cannot resurrect its file.
final class CourseProgressIoLease {
  factory CourseProgressIoLease(File file) {
    final _CourseFileQueue queue = _queueFor(file);
    return CourseProgressIoLease._(queue, queue.generation);
  }

  const CourseProgressIoLease._(this._queue, this._generation);

  final _CourseFileQueue _queue;
  final int _generation;

  void checkCurrent() {
    if (_generation != _queue.generation) {
      throw StateError('Course progress store was invalidated by deletion');
    }
  }

  Future<T> mutate<T>(Future<T> Function() operation) => _queue.enqueue(() {
    checkCurrent();
    return operation();
  });
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
