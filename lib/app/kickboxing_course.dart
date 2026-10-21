import 'dart:convert';

import 'self_guided_practice.dart';

final class KickboxingCopy {
  const KickboxingCopy({required this.tr, required this.en});
  final String tr, en;
  factory KickboxingCopy.decode(dynamic value) {
    final m = _object(value);
    _keys(m, {'tr', 'en'});
    return KickboxingCopy(tr: _text(m['tr']), en: _text(m['en']));
  }
}

final class KickboxingSource {
  KickboxingSource(Map<String, dynamic> m)
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

final class KickboxingLesson {
  KickboxingLesson(Map<String, dynamic> m)
    : number = _integer(m['number']),
      id = _text(m['id']),
      title = KickboxingCopy.decode(m['title']),
      instructions = KickboxingCopy.decode(m['instructions']),
      question = KickboxingCopy.decode(m['question']),
      correction = KickboxingCopy.decode(m['correction']),
      answer = KickboxingCopy.decode(m['answer']),
      sourceNote = m['sourceNote'] == null
          ? null
          : KickboxingCopy.decode(m['sourceNote']),
      rows = List.unmodifiable(_array(m['rows']).map(KickboxingCopy.decode)),
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
      'instructions',
      'question',
      'correction',
      'answer',
      'rows',
      'prerequisiteIds',
      'physicalPrerequisiteIds',
      'sourceIds',
      if (m.containsKey('selfGuidedPractice')) 'selfGuidedPractice',
      'sourceNote',
    });
    selfGuidedPractice?.requireBinding(id, sourceIds);
    if (sourceIds.isEmpty) {
      throw const FormatException('Missing source binding');
    }
  }
  final SelfGuidedPractice? selfGuidedPractice;
  final int number;
  final String id;
  final KickboxingCopy title, instructions, question, correction, answer;
  final KickboxingCopy? sourceNote;
  final List<KickboxingCopy> rows;
  final List<String> prerequisiteIds, physicalPrerequisiteIds, sourceIds;
}

/// Written progress and optional self-guided trials are separate.
/// No instructor or individual physical acceptance is inferred.
final class KickboxingCourse {
  KickboxingCourse._(Map<String, dynamic> m)
    : title = KickboxingCopy.decode(m['title']),
      common = KickboxingCopy.decode(m['common']),
      safety = KickboxingCopy.decode(m['safety']),
      writtenAlternative = KickboxingCopy.decode(m['writtenAlternative']),
      conventions = KickboxingCopy.decode(m['conventions']),
      conventionRows = List.unmodifiable(
        _array(m['conventionRows']).map(KickboxingCopy.decode),
      ),
      review = KickboxingCopy.decode(m['review']),
      sources = List.unmodifiable(
        _array(m['sources']).map((s) => KickboxingSource(_object(s))),
      ),
      lessons = List.unmodifiable(
        _array(m['lessons']).map((l) => KickboxingLesson(_object(l))),
      ) {
    _keys(m, {
      'schemaVersion',
      'id',
      'practiceKind',
      'title',
      'common',
      'safety',
      'writtenAlternative',
      'conventions',
      'conventionRows',
      'review',
      'releaseReadiness',
      'manuscriptSha256',
      'sources',
      'lessons',
    });
    if (_integer(m['schemaVersion']) != 1 ||
        m['id'] != 'jablab.kickboxing_a' ||
        m['practiceKind'] != 'written_solo_foundations' ||
        m['manuscriptSha256'] !=
            '477ea5401b315028a8d92459cacb803ce35ef1d93b72c0d298bd5969949b75a7' ||
        lessons.length != 16 ||
        conventionRows.length != 8) {
      throw const FormatException('Unsupported Kickboxing A manuscript');
    }
    final readiness = _object(m['releaseReadiness']);
    _keys(readiness, {
      'instructorReview',
      'demonstrations',
      'individualFeedback',
    });
    if (readiness.values.any((v) => v is! bool || v != false)) {
      throw const FormatException('Unaccepted physical readiness claim');
    }
    final sourceIds = sources.map((s) => s.id).toSet();
    if (sources.length != 15 ||
        sourceIds.length != 15 ||
        !List.generate(15, (i) => 'S${i + 1}').every(sourceIds.contains)) {
      throw const FormatException('Invalid teaching source inventory');
    }
    const observedPrimaryUrls = <String, String>{
      'S11': 'https://www.youtube.com/watch?v=CmpqqsmiP70',
      'S12': 'https://www.youtube.com/watch?v=IJIBBBQVIMw',
      'S13': 'https://www.youtube.com/watch?v=ZE6IVZ-MQUA',
      'S14': 'https://www.youtube.com/watch?v=bEVIlec93Ps',
      'S15': 'https://www.youtube.com/watch?v=aP-4Kjgc4Q8',
    };
    if (sources.any(
      (source) =>
          observedPrimaryUrls.containsKey(source.id) &&
          source.url.toString() != observedPrimaryUrls[source.id],
    )) {
      throw const FormatException('Wrong actual primary source binding');
    }
    for (var i = 0; i < lessons.length; i++) {
      final l = lessons[i];
      final expected = 'kb-${(i + 1).toString().padLeft(2, '0')}';
      final prior = i == 0
          ? <String>[]
          : ['kb-${i.toString().padLeft(2, '0')}'];
      final physical = [7, 8].contains(i + 1)
          ? ['individual-turn-feedback']
          : [10, 11, 12, 13].contains(i + 1)
          ? ['individual-kick-feedback']
          : [15, 16].contains(i + 1)
          ? ['individual-turn-feedback', 'individual-kick-feedback']
          : <String>[];
      if (l.number != i + 1 ||
          l.id != expected ||
          !_same(l.prerequisiteIds, prior) ||
          !_same(l.physicalPrerequisiteIds, physical) ||
          !l.sourceIds.every(sourceIds.contains) ||
          (l.sourceNote != null) != [11, 12].contains(l.number) ||
          l.rows.length != ([4, 12].contains(l.number) ? 4 : 0)) {
        throw const FormatException('Invalid lesson or prerequisite binding');
      }
    }
  }
  factory KickboxingCourse.fromJsonString(String source) {
    try {
      return KickboxingCourse._(_object(jsonDecode(source)));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed Kickboxing A course');
    }
  }
  // Repository verifies this exact transcribed asset after the Core integrity gate.
  static const String reviewedAssetSha256 =
      '33a908eadfac286345ca0cba189ff786afc31d018980956d19fcdb02fb238047';
  final KickboxingCopy title,
      common,
      safety,
      writtenAlternative,
      conventions,
      review;
  final List<KickboxingCopy> conventionRows;
  final List<KickboxingSource> sources;
  final List<KickboxingLesson> lessons;
  bool get verifiedPhysicalPracticeAvailable => false;
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
