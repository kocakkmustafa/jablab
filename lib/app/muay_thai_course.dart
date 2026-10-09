import 'dart:convert';

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
      sourceIds = _strings(m['sourceIds']) {
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
    });
    if (sourceIds.isEmpty) {
      throw const FormatException('Missing source binding');
    }
  }
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

/// Exact written preparation; every physical requirement stays unmet.
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
    if (!_same(sources.map((s) => s.id).toList(),
        List.generate(14, (i) => 'M${i + 1}'))) {
      throw const FormatException('Invalid teaching source inventory');
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
      [3, 9],
      [3, 9, 11, 12],
      [4],
      [3, 9],
      [5, 10],
      [5, 6],
      [5, 10],
      [7, 3, 13],
      [7, 3, 13, 14],
      [6, 3, 13],
      [8],
      [1, 4, 6],
      [4, 5, 7, 8, 10, 3, 11, 12, 13, 14],
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
      'ee16b7fe958d45c08bdcef399147a2569d33b566110f3fc4675d2971ec403531';
  final MuayThaiCopy title;
  final Map<String, MuayThaiCopy> shared;
  final List<MuayThaiCopy> sequenceRows;
  final List<MuayThaiSource> sources;
  final List<MuayThaiLesson> lessons;
  bool get physicalPracticeAvailable => false;
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
