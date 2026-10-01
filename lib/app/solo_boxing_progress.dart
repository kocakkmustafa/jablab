import 'dart:convert';
import 'dart:io';

import 'account_bridge.dart';
import 'course_progress_io.dart';
import 'solo_boxing_course.dart';

enum SoloLessonState { viewed, practised, selfReportedComplete }

final class SoloLessonProgress {
  const SoloLessonProgress({
    required this.contentVersion,
    required this.state,
    required this.viewedAt,
    this.lastPractisedAt,
    this.completedAt,
    this.practiceCount = 0,
  });

  factory SoloLessonProgress.fromJson(Map<String, dynamic> json) {
    final String stateName = json['state'] as String;
    final SoloLessonState state = SoloLessonState.values.singleWhere(
      (SoloLessonState candidate) => candidate.name == stateName,
      orElse: () => throw FormatException('Unknown lesson state $stateName'),
    );
    return SoloLessonProgress(
      contentVersion: json['contentVersion'] as int,
      state: state,
      viewedAt: DateTime.parse(json['viewedAt'] as String).toUtc(),
      lastPractisedAt: json['lastPractisedAt'] == null
          ? null
          : DateTime.parse(json['lastPractisedAt'] as String).toUtc(),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String).toUtc(),
      practiceCount: json['practiceCount'] as int,
    );
  }

  final int contentVersion;
  final SoloLessonState state;
  final DateTime viewedAt;
  final DateTime? lastPractisedAt;
  final DateTime? completedAt;
  final int practiceCount;

  Map<String, Object?> toJson() => <String, Object?>{
    'contentVersion': contentVersion,
    'state': state.name,
    'viewedAt': viewedAt.toIso8601String(),
    'lastPractisedAt': lastPractisedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'practiceCount': practiceCount,
  };
}

final class SoloCourseProgress {
  const SoloCourseProgress(this.records);

  final Map<String, SoloLessonProgress> records;

  SoloLessonProgress? forLesson(SoloLesson lesson, int contentVersion) {
    final SoloLessonProgress? record = records[lesson.id];
    return record?.contentVersion == contentVersion ? record : null;
  }

  int completedCount(SoloBoxingCourse course) => course.lessons
      .where(
        (SoloLesson lesson) =>
            forLesson(lesson, course.version)?.state ==
            SoloLessonState.selfReportedComplete,
      )
      .length;

  SoloLesson? nextLesson(SoloBoxingCourse course) {
    for (final SoloLesson lesson in course.lessons) {
      if (forLesson(lesson, course.version)?.state !=
          SoloLessonState.selfReportedComplete) {
        return lesson;
      }
    }
    return null;
  }
}

/// Local, account-scoped self-report journal. It never imports session counts
/// or promotes a camera observation into course completion.
final class SoloCourseProgressStore {
  SoloCourseProgressStore(this.file) : _lease = CourseProgressIoLease(file);

  final File file;
  final CourseProgressIoLease _lease;

  Future<SoloCourseProgress> load() async {
    _lease.checkCurrent();
    if (!await file.exists()) return const SoloCourseProgress({});
    final Map<String, dynamic> root =
        (jsonDecode(await file.readAsString()) as Map).cast<String, dynamic>();
    if (root['schemaVersion'] != 1 ||
        root['courseId'] != 'jablab.solo_boxing') {
      throw const FormatException('Unsupported solo course progress file');
    }
    final Map<String, dynamic> values = (root['lessons'] as Map)
        .cast<String, dynamic>();
    final Map<String, SoloLessonProgress> records =
        <String, SoloLessonProgress>{};
    for (final MapEntry<String, dynamic> entry in values.entries) {
      final SoloLessonProgress progress = SoloLessonProgress.fromJson(
        (entry.value as Map).cast<String, dynamic>(),
      );
      if (progress.practiceCount < 0 ||
          (progress.state == SoloLessonState.selfReportedComplete &&
              progress.completedAt == null)) {
        throw FormatException('Invalid progress for ${entry.key}');
      }
      records[entry.key] = progress;
    }
    return SoloCourseProgress(
      Map<String, SoloLessonProgress>.unmodifiable(records),
    );
  }

  Future<SoloCourseProgress> markViewed(
    SoloBoxingCourse course,
    SoloLesson lesson,
  ) => _update(course, lesson, SoloLessonState.viewed);

  Future<SoloCourseProgress> markPractised(
    SoloBoxingCourse course,
    SoloLesson lesson,
  ) => _update(course, lesson, SoloLessonState.practised);

  Future<SoloCourseProgress> markCompleted(
    SoloBoxingCourse course,
    SoloLesson lesson, {
    required bool selfChecksConfirmed,
  }) {
    if (!selfChecksConfirmed) {
      throw StateError('Self-check must be confirmed before completion');
    }
    return _update(course, lesson, SoloLessonState.selfReportedComplete);
  }

  Future<SoloCourseProgress> _update(
    SoloBoxingCourse course,
    SoloLesson lesson,
    SoloLessonState requested,
  ) => _lease.mutate(() => _updateUnlocked(course, lesson, requested));

  Future<SoloCourseProgress> _updateUnlocked(
    SoloBoxingCourse course,
    SoloLesson lesson,
    SoloLessonState requested,
  ) async {
    if (course.id != 'jablab.solo_boxing' ||
        !course.lessons.any((SoloLesson item) => item.id == lesson.id)) {
      throw ArgumentError.value(lesson.id, 'lesson', 'Not in this course');
    }
    final SoloCourseProgress current = await load();
    final SoloLessonProgress? old = current.forLesson(lesson, course.version);
    if (requested == SoloLessonState.selfReportedComplete &&
        (old == null || old.state.index < SoloLessonState.practised.index)) {
      throw StateError('Practice must be self-reported before completion');
    }
    final DateTime now = DateTime.now().toUtc();
    final SoloLessonState nextState =
        old != null && old.state.index > requested.index
        ? old.state
        : requested;
    final int practiceCount =
        (old?.practiceCount ?? 0) +
        (requested == SoloLessonState.practised ? 1 : 0);
    final SoloLessonProgress next = SoloLessonProgress(
      contentVersion: course.version,
      state: nextState,
      viewedAt: old?.viewedAt ?? now,
      lastPractisedAt: requested == SoloLessonState.practised
          ? now
          : old?.lastPractisedAt,
      completedAt: requested == SoloLessonState.selfReportedComplete
          ? old?.completedAt ?? now
          : old?.completedAt,
      practiceCount: practiceCount,
    );
    final Map<String, SoloLessonProgress> records =
        Map<String, SoloLessonProgress>.from(current.records);
    records[lesson.id] = next;
    await file.parent.create(recursive: true);
    final File temp = File('${file.path}.tmp');
    await temp.writeAsString(
      jsonEncode(<String, Object>{
        'schemaVersion': 1,
        'courseId': course.id,
        'lessons': <String, Object?>{
          for (final MapEntry<String, SoloLessonProgress> entry
              in records.entries)
            entry.key: entry.value.toJson(),
        },
      }),
      flush: true,
    );
    await temp.rename(file.path);
    return SoloCourseProgress(
      Map<String, SoloLessonProgress>.unmodifiable(records),
    );
  }
}

SoloCourseProgressStore soloProgressStoreFor(
  Directory support,
  String? accountUserId,
) => SoloCourseProgressStore(courseFileFor(support, accountUserId));
