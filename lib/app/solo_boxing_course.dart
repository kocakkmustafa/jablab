import 'dart:convert';

/// The first complete JabLab product: a self-paced, non-contact boxing path.
/// No field in this schema authorizes a camera score or a medical verdict.
final class SoloBoxingCourse {
  const SoloBoxingCourse({
    required this.id,
    required this.version,
    required this.title,
    required this.goal,
    required this.healthNotice,
    required this.sources,
    required this.modules,
  });

  factory SoloBoxingCourse.fromJsonString(String source) {
    final Map<String, dynamic> json = (jsonDecode(source) as Map)
        .cast<String, dynamic>();
    final SoloBoxingCourse course = SoloBoxingCourse(
      id: json['courseId'] as String,
      version: json['version'] as int,
      title: CourseCopy.fromJson(json['title']),
      goal: CourseCopy.fromJson(json['goal']),
      healthNotice: CourseCopy.fromJson(json['healthNotice']),
      sources: (json['sources'] as List)
          .map((dynamic value) => CourseSource.fromJson(value))
          .toList(growable: false),
      modules: (json['modules'] as List)
          .map((dynamic value) => SoloModule.fromJson(value))
          .toList(growable: false),
    );
    course.validate();
    return course;
  }

  final String id;
  final int version;
  final CourseCopy title;
  final CourseCopy goal;
  final CourseCopy healthNotice;
  final List<CourseSource> sources;
  final List<SoloModule> modules;

  List<SoloLesson> get lessons => [
    for (final SoloModule module in modules) ...module.lessons,
  ];

  void validate() {
    if (id != 'jablab.solo_boxing' || version != 1 || modules.length != 8) {
      throw const FormatException('Unsupported solo boxing course identity');
    }
    _requireCopy(title, 'title');
    _requireCopy(goal, 'goal');
    _requireCopy(healthNotice, 'healthNotice');
    if (lessons.length != 39) {
      throw FormatException(
        'Solo boxing needs 39 lessons; got ${lessons.length}',
      );
    }
    final Set<String> sourceIds = <String>{};
    for (final CourseSource source in sources) {
      if (!sourceIds.add(source.id) ||
          source.title.trim().isEmpty ||
          source.publisher.trim().isEmpty ||
          source.url.scheme != 'https' ||
          (source.supports == null) != (source.doesNotSupport == null)) {
        throw FormatException('Invalid or duplicate source ${source.id}');
      }
      if (source.supports case final support?) {
        _requireCopy(support, '${source.id}.supports');
      }
      if (source.doesNotSupport case final limit?) {
        _requireCopy(limit, '${source.id}.doesNotSupport');
      }
    }
    final Set<String> moduleIds = <String>{};
    final Set<String> seenLessons = <String>{};
    for (final SoloModule module in modules) {
      if (!moduleIds.add(module.id) || module.lessons.isEmpty) {
        throw FormatException('Invalid or duplicate module ${module.id}');
      }
      _requireCopy(module.title, '${module.id}.title');
      _requireCopy(module.intro, '${module.id}.intro');
      for (final SoloLesson lesson in module.lessons) {
        if (!seenLessons.add(lesson.id) ||
            !lesson.id.startsWith('${module.id}.') ||
            lesson.minutes < 4 ||
            lesson.evidenceMode != 'self_report') {
          throw FormatException('Invalid lesson ${lesson.id}');
        }
        for (final String prerequisite in lesson.prerequisites) {
          if (!seenLessons.contains(prerequisite) ||
              prerequisite == lesson.id) {
            throw FormatException(
              '${lesson.id}: invalid prerequisite $prerequisite',
            );
          }
        }
        if (lesson.sourceIds.isEmpty ||
            lesson.sourceIds.any(
              (String source) => !sourceIds.contains(source),
            )) {
          throw FormatException('${lesson.id}: missing source binding');
        }
        _requireCopy(lesson.title, '${lesson.id}.title');
        _requireCopy(lesson.objective, '${lesson.id}.objective');
        _requireCopy(lesson.practice, '${lesson.id}.practice');
        _requireCopy(lesson.adaptation, '${lesson.id}.adaptation');
        _requireCopy(lesson.stopSignal, '${lesson.id}.stopSignal');
        _requireCopy(lesson.mediaBrief, '${lesson.id}.mediaBrief');
        if (lesson.steps.length < 2 || lesson.selfChecks.length < 2) {
          throw FormatException('${lesson.id}: teaching or self-check is thin');
        }
        for (final CourseCopy step in lesson.steps) {
          _requireCopy(step, '${lesson.id}.step');
        }
        for (final CourseCopy check in lesson.selfChecks) {
          _requireCopy(check, '${lesson.id}.selfCheck');
        }
      }
    }
    if (lessons.last.id != 'boxing.integration.independent_round') {
      throw const FormatException('Solo boxing capstone must be last');
    }
  }

  static void _requireCopy(CourseCopy copy, String path) {
    if (copy.en.trim().isEmpty || copy.tr.trim().isEmpty) {
      throw FormatException('$path: both languages are required');
    }
  }
}

final class CourseCopy {
  const CourseCopy(this.en, this.tr);

  factory CourseCopy.fromJson(dynamic value) {
    final Map<String, dynamic> json = (value as Map).cast<String, dynamic>();
    return CourseCopy(json['en'] as String, json['tr'] as String);
  }

  final String en;
  final String tr;

  String inLanguage({required bool turkish}) => turkish ? tr : en;
}

final class CourseSource {
  const CourseSource(
    this.id,
    this.publisher,
    this.title,
    this.url,
    this.supports,
    this.doesNotSupport,
  );

  factory CourseSource.fromJson(dynamic value) {
    final Map<String, dynamic> json = (value as Map).cast<String, dynamic>();
    return CourseSource(
      json['id'] as String,
      json['publisher'] as String,
      json['title'] as String,
      Uri.parse(json['url'] as String),
      json['supports'] == null ? null : CourseCopy.fromJson(json['supports']),
      json['doesNotSupport'] == null
          ? null
          : CourseCopy.fromJson(json['doesNotSupport']),
    );
  }

  final String id;
  final String publisher;
  final String title;
  final Uri url;
  final CourseCopy? supports, doesNotSupport;
}

final class SoloModule {
  const SoloModule(this.id, this.title, this.intro, this.lessons);

  factory SoloModule.fromJson(dynamic value) {
    final Map<String, dynamic> json = (value as Map).cast<String, dynamic>();
    return SoloModule(
      json['id'] as String,
      CourseCopy.fromJson(json['title']),
      CourseCopy.fromJson(json['intro']),
      (json['lessons'] as List)
          .map((dynamic item) => SoloLesson.fromJson(item))
          .toList(growable: false),
    );
  }

  final String id;
  final CourseCopy title;
  final CourseCopy intro;
  final List<SoloLesson> lessons;
}

final class SoloLesson {
  const SoloLesson({
    required this.id,
    required this.title,
    required this.objective,
    required this.steps,
    required this.practice,
    required this.selfChecks,
    required this.adaptation,
    required this.stopSignal,
    required this.mediaBrief,
    required this.prerequisites,
    required this.sourceIds,
    required this.minutes,
    required this.evidenceMode,
  });

  factory SoloLesson.fromJson(dynamic value) {
    final Map<String, dynamic> json = (value as Map).cast<String, dynamic>();
    return SoloLesson(
      id: json['id'] as String,
      title: CourseCopy.fromJson(json['title']),
      objective: CourseCopy.fromJson(json['objective']),
      steps: (json['steps'] as List)
          .map((dynamic item) => CourseCopy.fromJson(item))
          .toList(growable: false),
      practice: CourseCopy.fromJson(json['practice']),
      selfChecks: (json['selfChecks'] as List)
          .map((dynamic item) => CourseCopy.fromJson(item))
          .toList(growable: false),
      adaptation: CourseCopy.fromJson(json['adaptation']),
      stopSignal: CourseCopy.fromJson(json['stopSignal']),
      mediaBrief: CourseCopy.fromJson(json['mediaBrief']),
      prerequisites: (json['prerequisites'] as List).cast<String>(),
      sourceIds: (json['sourceIds'] as List).cast<String>(),
      minutes: json['minutes'] as int,
      evidenceMode: json['evidenceMode'] as String,
    );
  }

  final String id;
  final CourseCopy title;
  final CourseCopy objective;
  final List<CourseCopy> steps;
  final CourseCopy practice;
  final List<CourseCopy> selfChecks;
  final CourseCopy adaptation;
  final CourseCopy stopSignal;
  final CourseCopy mediaBrief;
  final List<String> prerequisites;
  final List<String> sourceIds;
  final int minutes;
  final String evidenceMode;
}
