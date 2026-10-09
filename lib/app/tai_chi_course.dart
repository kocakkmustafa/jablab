import 'dart:convert';

/// Original written foundations: never a certification of a traditional form.
final class TaiChiCopy {
  const TaiChiCopy({required this.tr, required this.en});
  final String tr;
  final String en;
  factory TaiChiCopy.decode(dynamic value) {
    final map = _map(value);
    return TaiChiCopy(tr: _string(map['tr']), en: _string(map['en']));
  }
}

final class TaiChiSource {
  TaiChiSource(Map<String, dynamic> map)
    : id = _string(map['id']),
      title = _string(map['title']),
      url = Uri.parse(_string(map['url'])) {
    if (url.scheme != 'https' || url.host.isEmpty) {
      throw const FormatException('Tai Chi source must use HTTPS');
    }
  }
  final String id;
  final String title;
  final Uri url;
}

final class TaiChiPracticeRow {
  TaiChiPracticeRow(Map<String, dynamic> map)
    : count = TaiChiCopy.decode(map['count']),
      direction = TaiChiCopy.decode(map['direction']),
      support = TaiChiCopy.decode(map['support']),
      instruction = TaiChiCopy.decode(map['instruction']);
  final TaiChiCopy count, direction, support, instruction;
}

final class TaiChiLesson {
  TaiChiLesson(Map<String, dynamic> map)
    : number = _integer(map['number']),
      id = _string(map['id']),
      title = TaiChiCopy.decode(map['title']),
      objective = TaiChiCopy.decode(map['objective']),
      preparation = TaiChiCopy.decode(map['preparation']),
      instructions = TaiChiCopy.decode(map['instructions']),
      selfCheck = TaiChiCopy.decode(map['selfCheck']),
      correction = TaiChiCopy.decode(map['correction']),
      retest = TaiChiCopy.decode(map['retest']),
      question = TaiChiCopy.decode(_map(map['knowledgeCheck'])['question']),
      answer = TaiChiCopy.decode(_map(map['knowledgeCheck'])['answer']),
      practiceRows = List.unmodifiable(
        _list(
          map['practiceRows'],
        ).map((dynamic row) => TaiChiPracticeRow(_map(row))),
      ),
      sourceIds = List.unmodifiable(_list(map['sourceIds']).map(_string)) {
    if (practiceRows.isEmpty ||
        sourceIds.isEmpty ||
        sourceIds.toSet().length != sourceIds.length) {
      throw const FormatException(
        'Tai Chi lesson needs practice and unique source bindings',
      );
    }
  }
  final int number;
  final String id;
  final TaiChiCopy title,
      objective,
      preparation,
      instructions,
      selfCheck,
      correction,
      retest,
      question,
      answer;
  final List<TaiChiPracticeRow> practiceRows;
  final List<String> sourceIds;
}

final class TaiChiCourse {
  TaiChiCourse._(Map<String, dynamic> map)
    : id = _string(map['id']),
      title = TaiChiCopy.decode(map['title']),
      scope = TaiChiCopy.decode(map['scope']),
      endpoint = TaiChiCopy.decode(map['endpoint']),
      safety = TaiChiCopy.decode(map['safety']),
      sources = List.unmodifiable(
        _list(
          map['sources'],
        ).map((dynamic source) => TaiChiSource(_map(source))),
      ),
      lessons = List.unmodifiable(
        _list(
          map['lessons'],
        ).map((dynamic lesson) => TaiChiLesson(_map(lesson))),
      ) {
    if (map['schemaVersion'] is! int ||
        map['schemaVersion'] != 1 ||
        id != 'jablab.tai_chi_foundations' ||
        map['practiceKind'] != 'original_foundations' ||
        lessons.length != 14) {
      throw const FormatException(
        'Unsupported Tai Chi written foundations course',
      );
    }
    final sourceIds = sources.map((source) => source.id).toSet();
    if (sourceIds.isEmpty || sourceIds.length != sources.length) {
      throw const FormatException('Missing or duplicate Tai Chi source');
    }
    final lessonIds = <String>{};
    for (var i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      if (lesson.number != i + 1 ||
          !lessonIds.add(lesson.id) ||
          !lesson.sourceIds.every(sourceIds.contains)) {
        throw const FormatException(
          'Invalid Tai Chi lesson order or source binding',
        );
      }
    }
  }
  factory TaiChiCourse.fromJsonString(String source) {
    try {
      return TaiChiCourse._(_map(jsonDecode(source)));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed Tai Chi course');
    }
  }
  final String id;
  final TaiChiCopy title, scope, endpoint, safety;
  final List<TaiChiSource> sources;
  final List<TaiChiLesson> lessons;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

List<dynamic> _list(dynamic value) {
  if (value is! List) throw const FormatException('Expected list');
  return value;
}

String _string(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Expected nonempty string');
  }
  return value;
}

int _integer(dynamic value) {
  if (value is! int) throw const FormatException('Expected integer');
  return value;
}
