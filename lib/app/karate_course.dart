import 'dart:convert';

import 'self_guided_practice.dart';

final class KarateCopy {
  const KarateCopy({required this.tr, required this.en});
  final String tr, en;
  factory KarateCopy.decode(dynamic value) {
    final m = _object(value);
    _keys(m, {'tr', 'en'});
    return KarateCopy(tr: _text(m['tr']), en: _text(m['en']));
  }
}

final class KarateSource {
  KarateSource(Map<String, dynamic> m)
    : id = _text(m['id']),
      title = _text(m['title']),
      url = Uri.parse(_text(m['url'])),
      support = _text(m['support']),
      limit = _text(m['limit']) {
    _keys(m, {'id', 'title', 'url', 'support', 'limit'});
    if (url.scheme != 'https' || url.host.isEmpty || url.userInfo.isNotEmpty) {
      throw const FormatException('Invalid teaching source URL');
    }
  }
  final String id, title, support, limit;
  final Uri url;
}

final class KarateLesson {
  KarateLesson(Map<String, dynamic> m)
    : number = _integer(m['number']),
      id = _text(m['id']),
      title = KarateCopy.decode(m['title']),
      teaching = KarateCopy.decode(m['teaching']),
      physicalTask = KarateCopy.decode(m['physical_task']),
      selfPractice = SelfGuidedPractice.decode(m['selfPractice']),
      writtenTask = KarateCopy.decode(m['written_task']),
      question = KarateCopy.decode(m['question']),
      answer = KarateCopy.decode(m['answer_key']),
      correction = KarateCopy.decode(m['correction']),
      retest = KarateCopy.decode(m['retest']),
      prerequisiteIds = _strings(m['prerequisiteIds']),
      physicalPrerequisiteIds = _strings(m['physicalPrerequisiteIds']),
      sourceIds = _strings(m['sourceIds']) {
    _keys(m, {
      'number',
      'id',
      'title',
      'teaching',
      'physical_task',
      'selfPractice',
      'written_task',
      'question',
      'answer_key',
      'correction',
      'retest',
      'prerequisiteIds',
      'physicalPrerequisiteIds',
      'sourceIds',
    });
    selfPractice.requireBinding(id, sourceIds);
    if (sourceIds.isEmpty) {
      throw const FormatException('Missing source binding');
    }
  }
  final SelfGuidedPractice selfPractice;
  final int number;
  final String id;
  final KarateCopy title,
      teaching,
      physicalTask,
      writtenTask,
      question,
      answer,
      correction,
      retest;
  final List<String> prerequisiteIds, physicalPrerequisiteIds, sourceIds;
}

/// Written recall and optional source-bound self-practice are separate.
/// Historical manuscript provenance is not the checksum of this authored asset.
/// Every individual physical validation record stays unmet.
final class KarateCourse {
  KarateCourse._(Map<String, dynamic> m)
    : title = KarateCopy.decode(m['title']),
      shared = _shared(m['shared']),
      sequenceRows = List.unmodifiable(
        _array(m['sequenceRows']).map(KarateCopy.decode),
      ),
      sources = List.unmodifiable(
        _array(m['sources']).map((s) => KarateSource(_object(s))),
      ),
      lessons = List.unmodifiable(
        _array(m['lessons']).map((l) => KarateLesson(_object(l))),
      ) {
    _keys(m, {
      'schemaVersion',
      'id',
      'practiceKind',
      'manuscriptSha256',
      'title',
      'shared',
      'releaseReadiness',
      'physicalRequirements',
      'sequenceRows',
      'sources',
      'lessons',
    });
    if (_integer(m['schemaVersion']) != 2 ||
        m['id'] != 'jablab.karate_a' ||
        m['practiceKind'] != 'written_kihon_sequence_preparation' ||
        m['manuscriptSha256'] !=
            '93e6eb8f640a5d9e103bda7a3223aceb9dd6ed97a812c6dec8dc7e3bfa4f7bc4' ||
        lessons.length != 16 ||
        sequenceRows.length != 6) {
      throw const FormatException('Unsupported Karate A manuscript');
    }
    final readiness = _object(m['releaseReadiness']);
    _keys(readiness, {
      'instructorReview',
      'demonstrations',
      'individualFeedback',
    });
    final requirements = _object(m['physicalRequirements']);
    _keys(requirements, {for (var i = 0; i < 7; i++) 'P$i'});
    if ([
      ...readiness.values,
      ...requirements.values,
    ].any((v) => v is! bool || v != false)) {
      throw const FormatException('Unaccepted physical readiness claim');
    }
    final sourceIds = sources.map((s) => s.id).toSet();
    if (sources.length != 13 ||
        sourceIds.length != 13 ||
        !List.generate(13, (i) => 'K${i + 1}').every(sourceIds.contains)) {
      throw const FormatException('Invalid teaching source inventory');
    }
    const observedPrimaryUrls = <String, String>{
      'K11': 'https://www.youtube.com/watch?v=jH6bv4GDpp0',
      'K12': 'https://www.youtube.com/watch?v=kta8JS_pXFs',
      'K13': 'https://www.youtube.com/watch?v=1uKTYj00QLM',
    };
    if (sources.any((source) =>
        observedPrimaryUrls.containsKey(source.id) &&
        source.url.toString() != observedPrimaryUrls[source.id])) {
      throw const FormatException('Wrong actual primary source binding');
    }
    const List<List<int>> physical = [
      [],
      [0],
      [0, 1],
      [0, 1],
      [0, 1, 2],
      [0, 1, 2],
      [0, 1, 2],
      [0, 1, 3],
      [0, 1, 3],
      [0, 1, 2, 3, 4],
      [0, 1, 2, 3, 5],
      [0, 1, 3, 6],
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5, 6],
    ];
    for (var i = 0; i < lessons.length; i++) {
      final l = lessons[i];
      final id = 'ka-${(i + 1).toString().padLeft(2, '0')}';
      final prior = i == 0
          ? <String>[]
          : ['ka-${i.toString().padLeft(2, '0')}'];
      if (l.number != i + 1 ||
          l.id != id ||
          !_same(l.prerequisiteIds, prior) ||
          !_same(l.physicalPrerequisiteIds, [
            for (final requirement in physical[i]) 'P$requirement',
          ]) ||
          !l.sourceIds.every(sourceIds.contains)) {
        throw const FormatException('Invalid lesson or prerequisite binding');
      }
    }
  }
  factory KarateCourse.fromJsonString(String source) {
    try {
      return KarateCourse._(_object(jsonDecode(source)));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed Karate A course');
    }
  }
  // Core verification is followed by the fixed pin for this transcription.
  static const String reviewedAssetSha256 =
      '8d1a488fad8c6b5039ffc9842698800b13a3446a7a1235742b97b2184cf913db';
  final KarateCopy title;
  final Map<String, KarateCopy> shared;
  final List<KarateCopy> sequenceRows;
  final List<KarateSource> sources;
  final List<KarateLesson> lessons;
  bool get selfPracticeAvailable =>
      lessons.any((lesson) => lesson.selfPractice.offersMovement);
  bool get physicalTechniqueValidated => false;
  // Retained compatibility value: this means validated physical availability.
  bool get physicalPracticeAvailable => false;
}

Map<String, KarateCopy> _shared(dynamic value) {
  final m = _object(value);
  _keys(m, {
    'status',
    'style',
    'audience',
    'endpoint',
    'limits',
    'physical_gate',
    'equipment',
    'stop',
    'dose',
    'learning_loop',
    'progress',
    'directions',
  });
  return Map.unmodifiable(
    m.map((key, value) => MapEntry(key, KarateCopy.decode(value))),
  );
}

Map<String, dynamic> _object(dynamic v) {
  if (v is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return v;
}

List<dynamic> _array(dynamic v) {
  if (v is! List) throw const FormatException('Expected array');
  return v;
}

String _text(dynamic v) {
  if (v is! String || v.trim().isEmpty) {
    throw const FormatException('Expected nonempty text');
  }
  return v;
}

int _integer(dynamic v) {
  if (v is! int) throw const FormatException('Expected integer');
  return v;
}

void _keys(Map<String, dynamic> m, Set<String> expected) {
  if (m.length != expected.length || !m.keys.every(expected.contains)) {
    throw const FormatException('Unexpected or missing field');
  }
}

List<String> _strings(dynamic v) {
  final result = _array(v).map(_text).toList();
  if (result.toSet().length != result.length) {
    throw const FormatException('Duplicate reference');
  }
  return List.unmodifiable(result);
}

bool _same(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
