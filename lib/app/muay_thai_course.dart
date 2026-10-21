import 'dart:convert';

import 'self_guided_practice.dart';

final class MuayThaiCopy {
  const MuayThaiCopy({required this.tr, required this.en});
  final String tr, en;
  factory MuayThaiCopy.decode(dynamic value) {
    final m = _object(value);
    _keys(m, {'tr', 'en'});
    return MuayThaiCopy(tr: _text(m['tr']), en: _text(m['en']));
  }
}

final class MuayThaiSource {
  MuayThaiSource(Map<String, dynamic> m)
    : id = _text(m['id']),
      title = _text(m['title']),
      url = Uri.parse(_text(m['url'])),
      role = _text(m['role']),
      support = _text(m['support']),
      limit = _text(m['limit']) {
    _keys(m, {'id', 'title', 'url', 'role', 'support', 'limit'});
    if (url.scheme != 'https' || url.host.isEmpty || url.userInfo.isNotEmpty) {
      throw const FormatException('Invalid teaching source URL');
    }
  }
  final String id, title, role, support, limit;
  final Uri url;
}

final class MuayThaiLesson {
  MuayThaiLesson(Map<String, dynamic> m)
    : number = _integer(m['number']),
      id = _text(m['id']),
      title = MuayThaiCopy.decode(m['title']),
      teaching = MuayThaiCopy.decode(m['teaching']),
      physicalTask = MuayThaiCopy.decode(m['physical_task']),
      writtenTask = MuayThaiCopy.decode(m['written_task']),
      question = MuayThaiCopy.decode(m['question']),
      answer = MuayThaiCopy.decode(m['answer_key']),
      correction = MuayThaiCopy.decode(m['correction']),
      retest = MuayThaiCopy.decode(m['retest']),
      prerequisiteIds = _strings(m['prerequisiteIds']),
      physicalPrerequisiteIds = _strings(m['physicalPrerequisiteIds']),
      sourceIds = _strings(m['sourceIds']),
      selfGuidedPractice = m.containsKey('selfGuidedPractice')
          ? SelfGuidedPractice.decode(m['selfGuidedPractice'])
          : null {
    _keys(m, {
      'number',
      'id',
      'title',
      'teaching',
      'physical_task',
      'written_task',
      'question',
      'answer_key',
      'correction',
      'retest',
      'prerequisiteIds',
      'physicalPrerequisiteIds',
      'sourceIds',
      if (m.containsKey('selfGuidedPractice')) 'selfGuidedPractice',
    });
    selfGuidedPractice?.requireBinding(id, sourceIds);
    if (sourceIds.isEmpty) {
      throw const FormatException('Missing source binding');
    }
  }
  final SelfGuidedPractice? selfGuidedPractice;
  final int number;
  final String id;
  final MuayThaiCopy title,
      teaching,
      physicalTask,
      writtenTask,
      question,
      answer,
      correction,
      retest;
  final List<String> prerequisiteIds, physicalPrerequisiteIds, sourceIds;
}

/// Exact written progress; individual physical acceptance stays unmet.
/// An optional self-guided block is not a P0–P7 acceptance record.
final class MuayThaiCourse {
  MuayThaiCourse._(Map<String, dynamic> m)
    : title = MuayThaiCopy.decode(m['title']),
      shared = _shared(m['shared']),
      sequenceRows = List.unmodifiable(
        _array(m['sequenceRows']).map(MuayThaiCopy.decode),
      ),
      sources = List.unmodifiable(
        _array(m['sources']).map((s) => MuayThaiSource(_object(s))),
      ),
      lessons = List.unmodifiable(
        _array(m['lessons']).map((l) => MuayThaiLesson(_object(l))),
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
    if (_integer(m['schemaVersion']) != 1 ||
        m['id'] != 'jablab.muay_thai_a' ||
        m['practiceKind'] != 'written_muay_thai_preparation' ||
        m['manuscriptSha256'] !=
            '64d15e5054ae06e8b2be80506bcd17f1d0b53e8958252e064a1183b354b2b229' ||
        lessons.length != 16 ||
        sequenceRows.length != 9) {
      throw const FormatException('Unsupported Muay Thai A manuscript');
    }
    final readiness = _object(m['releaseReadiness']);
    _keys(readiness, {
      'instructorReview',
      'demonstrations',
      'individualFeedback',
    });
    final requirements = _object(m['physicalRequirements']);
    _keys(requirements, {for (var i = 0; i < 8; i++) 'P$i'});
    if ([
      ...readiness.values,
      ...requirements.values,
    ].any((v) => v is! bool || v != false)) {
      throw const FormatException('Unaccepted physical readiness claim');
    }
    if (!_same(
      sources.map((s) => s.id).toList(),
      List.generate(22, (i) => 'M${i + 1}'),
    )) {
      throw const FormatException('Invalid teaching source inventory');
    }
    const observedPrimaryUrls = <String, String>{
      'M15': 'https://www.youtube.com/watch?v=CmpqqsmiP70',
      'M16': 'https://www.youtube.com/watch?v=IJIBBBQVIMw',
      'M17': 'https://www.youtube.com/watch?v=ZE6IVZ-MQUA',
      'M18': 'https://www.youtube.com/watch?v=bEVIlec93Ps',
      'M19': 'https://www.youtube.com/watch?v=aP-4Kjgc4Q8',
      'M20': 'https://www.youtube.com/watch?v=f_2BzU6eFFI',
      'M21': 'https://www.youtube.com/watch?v=9aHd7OtU9vA',
      'M22': 'https://www.youtube.com/watch?v=1uKTYj00QLM',
    };
    if (sources.any(
      (source) =>
          observedPrimaryUrls.containsKey(source.id) &&
          source.url.toString() != observedPrimaryUrls[source.id],
    )) {
      throw const FormatException('Wrong actual primary source binding');
    }
    // Exact ordered protocol indices from the accepted source map.
    const List<List<int>> physical = [
      [],
      [0],
      [0, 1],
      [0, 1],
      [0, 1, 2],
      [0, 1, 2],
      [0, 1, 3],
      [0, 1, 3],
      [0, 1, 3],
      [0, 1, 4],
      [0, 1, 4],
      [0, 1, 5],
      [0, 1, 3, 6],
      [],
      [0, 1, 2, 3, 4, 5, 6, 7],
      [],
    ];
    const List<List<int>> contexts = [
      [1, 2],
      [10],
      [3, 9, 17],
      [3, 9, 11, 12, 22, 15],
      [4, 17],
      [3, 9, 18],
      [5, 10, 15],
      [5, 6, 16],
      [5, 10, 15, 16],
      [7, 3, 13, 19],
      [7, 3, 13, 14, 19],
      [6, 3, 13, 20],
      [8, 21],
      [1, 4, 6],
      [4, 5, 7, 8, 10, 3, 11, 12, 13, 14, 17, 15, 16, 19, 20, 21],
      [1, 10],
    ];
    for (var i = 0; i < lessons.length; i++) {
      final l = lessons[i];
      final id = 'mt-${(i + 1).toString().padLeft(2, '0')}';
      final prior = i == 0
          ? <String>[]
          : ['mt-${i.toString().padLeft(2, '0')}'];
      if (l.number != i + 1 ||
          l.id != id ||
          !_same(l.prerequisiteIds, prior) ||
          !_same(l.physicalPrerequisiteIds, [
            for (final requirement in physical[i]) 'P$requirement',
          ]) ||
          !_same(l.sourceIds, [
            for (final context in contexts[i]) 'M$context',
          ])) {
        throw const FormatException('Invalid lesson or prerequisite binding');
      }
    }
  }
  factory MuayThaiCourse.fromJsonString(String source) {
    try {
      return MuayThaiCourse._(_object(jsonDecode(source)));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed Muay Thai A course');
    }
  }
  // Core verification is followed by the fixed pin for this transcription.
  static const String reviewedAssetSha256 =
      'd17e9a6fe37d12ea20fda70da3dc02aa8b0fee74c0b357207f15eb2664c6cebc';
  final MuayThaiCopy title;
  final Map<String, MuayThaiCopy> shared;
  final List<MuayThaiCopy> sequenceRows;
  final List<MuayThaiSource> sources;
  final List<MuayThaiLesson> lessons;
  bool get verifiedPhysicalPracticeAvailable => false;
}

Map<String, MuayThaiCopy> _shared(dynamic value) {
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
    m.map((key, value) => MapEntry(key, MuayThaiCopy.decode(value))),
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
