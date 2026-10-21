import 'dart:convert';

import 'self_guided_practice.dart';

final class TaikyokuCopy {
  const TaikyokuCopy({required this.tr, required this.en});
  factory TaikyokuCopy.decode(Object? value) {
    final m = _object(value);
    _keys(m, {'tr', 'en'});
    return TaikyokuCopy(tr: _text(m['tr']), en: _text(m['en']));
  }
  final String tr, en;
}

final class TaikyokuRequirement {
  TaikyokuRequirement(Map<String, dynamic> m)
    : id = _text(m['id']),
      title = TaikyokuCopy.decode(m['title']),
      detail = TaikyokuCopy.decode(m['detail']) {
    _keys(m, {'id', 'title', 'detail', 'accepted'});
    _require(m['accepted'] == false, 'Unaccepted physical requirement');
  }
  final String id;
  final TaikyokuCopy title, detail;
  bool get accepted => false;
}

final class TaikyokuSource {
  TaikyokuSource(Map<String, dynamic> m)
    : id = _text(m['id']),
      url = Uri.parse(_text(m['url'])),
      title = _text(m['reported_title']),
      duration = _text(m['reported_duration']),
      scope = _text(m['binding_scope']) {
    _keys(m, {
      'id',
      'url',
      'reported_title',
      'reported_duration',
      'binding_scope',
    });
    _require(
      url.scheme == 'https' &&
          url.host == 'www.youtube.com' &&
          url.userInfo.isEmpty &&
          url.fragment.isEmpty,
      'Invalid source URL',
    );
  }
  final String id, title, duration, scope;
  final Uri url;
}

final class TaikyokuChoice {
  TaikyokuChoice(Map<String, dynamic> m)
    : id = _text(m['id']),
      text = TaikyokuCopy.decode(m['text']) {
    _keys(m, {'id', 'text'});
  }
  final String id;
  final TaikyokuCopy text;
}

final class TaikyokuRecall {
  TaikyokuRecall(Map<String, dynamic> m)
    : id = _text(m['id']),
      prompt = TaikyokuCopy.decode(m['prompt']),
      choices = List.unmodifiable(
        _array(m['choices']).map((v) => TaikyokuChoice(_object(v))),
      ),
      correctChoiceId = _text(m['correct_choice_id']),
      explanation = TaikyokuCopy.decode(m['explanation']) {
    _keys(m, {
      'id',
      'prompt',
      'choices',
      'correct_choice_id',
      'explanation',
      'progress_kind',
    });
    _require(
      m['progress_kind'] == 'written_recall_only' &&
          _same(choices.map((c) => c.id).toList(), ['a', 'b', 'c']) &&
          choices.any((c) => c.id == correctChoiceId),
      'Invalid recall contract',
    );
  }
  final String id, correctChoiceId;
  final TaikyokuCopy prompt, explanation;
  final List<TaikyokuChoice> choices;
  TaikyokuChoice get correctChoice =>
      choices.firstWhere((c) => c.id == correctChoiceId);
}

final class TaikyokuEvidence {
  TaikyokuEvidence(Map<String, dynamic> m)
    : sample = _text(m['endpoint_sample']),
      countPointer = _text(m['source_mapping_pointer']),
      turnPointer = _nullableText(m['turn_entry_pointer']),
      stepPointer = _nullableText(m['stepping_entry_pointer']),
      fineStepSampled = m['fine_stepping_entry_sampled'] {
    _keys(m, {
      'recording',
      'endpoint_sample',
      'source_mapping_pointer',
      'turn_entry_pointer',
      'report_sha256',
      'stepping_entry_pointer',
      'fine_stepping_entry_sampled',
    });
    _require(
      m['recording'] == 'B' &&
          m['report_sha256'] == TaikyokuCourse.reportSha256 &&
          (fineStepSampled == null || fineStepSampled is bool),
      'Invalid movement evidence',
    );
  }
  final String sample, countPointer;
  final String? turnPointer, stepPointer;
  final Object? fineStepSampled;
}

final class TaikyokuMovement {
  TaikyokuMovement(Map<String, dynamic> m)
    : id = _text(m['id']),
      count = _integer(m['count']),
      title = TaikyokuCopy.decode(m['title']),
      start = TaikyokuCopy.decode(m['start']),
      feet = TaikyokuCopy.decode(m['feet']),
      hands = TaikyokuCopy.decode(m['hands']),
      finish = TaikyokuCopy.decode(m['finish']),
      next = TaikyokuCopy.decode(m['next']),
      limit = TaikyokuCopy.decode(m['limit']),
      evidence = TaikyokuEvidence(_object(m['evidence'])) {
    _keys(m, {
      'id',
      'count',
      'title',
      'start',
      'feet',
      'hands',
      'finish',
      'next',
      'limit',
      'evidence',
    });
  }
  final String id;
  final int count;
  final TaikyokuCopy title, start, feet, hands, finish, next, limit;
  final TaikyokuEvidence evidence;
}

final class TaikyokuCountContract {
  TaikyokuCountContract(Map<String, dynamic> m)
    : id = _text(m['id']),
      count = _integer(m['count']),
      heading = _text(m['heading']),
      frontFoot = _text(m['frontFoot']),
      activeHand = _text(m['activeHand']),
      technique = _text(m['technique']),
      entry = _text(m['entry']),
      sample = _text(m['endpointSample']) {
    _keys(m, {
      'id',
      'count',
      'heading',
      'frontFoot',
      'activeHand',
      'technique',
      'entry',
      'sourceRecording',
      'endpointSample',
      'footContact',
      'wristRotation',
      'loading',
    });
    _require(
      m['sourceRecording'] == 'B' &&
          m['footContact'] == null &&
          m['wristRotation'] == null &&
          m['loading'] == null,
      'Unobserved movement mechanics must remain unknown',
    );
  }
  final String id, heading, frontFoot, activeHand, technique, entry, sample;
  final int count;
}

final class TaikyokuLesson {
  TaikyokuLesson(Map<String, dynamic> m)
    : id = _text(m['id']),
      title = TaikyokuCopy.decode(m['title']),
      objective = TaikyokuCopy.decode(m['objective']),
      teaching = List.unmodifiable(
        _array(m['teaching']).map(TaikyokuCopy.decode),
      ),
      movementIds = _strings(m['movement_ids']),
      recall = List.unmodifiable(
        _array(m['recall']).map((v) => TaikyokuRecall(_object(v))),
      ),
      completionMeaning = TaikyokuCopy.decode(m['completion_meaning']),
      selfPractice = SelfGuidedPractice.decode(m['selfPractice']) {
    _keys(m, {
      'id',
      'title',
      'objective',
      'teaching',
      'movement_ids',
      'recall',
      'completion_meaning',
      'selfPractice',
    });
  }
  final String id;
  final TaikyokuCopy title, objective, completionMeaning;
  final List<TaikyokuCopy> teaching;
  final List<String> movementIds;
  final List<TaikyokuRecall> recall;
  final SelfGuidedPractice selfPractice;
  int get number => int.parse(id.substring(3));
  String? get previousLessonId => number == 1 ? null : _id('ts-', number - 1);
}

/// Written recall and optional source-bound practice do not validate technique.
/// Manuscript/curriculum/source-map hashes retain historical source provenance;
/// reviewedAssetSha256 pins every byte of the current authored asset.
final class TaikyokuCourse {
  TaikyokuCourse._(Map<String, dynamic> envelope)
    : this._content(envelope, _object(envelope['content']));

  TaikyokuCourse._content(Map<String, dynamic> envelope, Map<String, dynamic> m)
    : title = TaikyokuCopy.decode(m['title']),
      commonLimits = TaikyokuCopy.decode(m['common_limits']),
      opening = TaikyokuCopy.decode(m['opening']),
      closing = TaikyokuCopy.decode(m['closing']),
      requirements = List.unmodifiable(
        _array(
          m['physicalRequirements'],
        ).map((v) => TaikyokuRequirement(_object(v))),
      ),
      movements = List.unmodifiable(
        _array(m['movements']).map((v) => TaikyokuMovement(_object(v))),
      ),
      lessons = List.unmodifiable(
        _array(m['lessons']).map((v) => TaikyokuLesson(_object(v))),
      ),
      sources = List.unmodifiable(
        _array(m['sources']).map((v) => TaikyokuSource(_object(v))),
      ),
      countContracts = List.unmodifiable(
        _array(
          envelope['orderedMovementContracts'],
        ).map((v) => TaikyokuCountContract(_object(v))),
      ) {
    _keys(envelope, {
      'schemaVersion',
      'id',
      'practiceKind',
      'manuscriptSha256',
      'curriculumSha256',
      'sourceMapSha256',
      'sourceBindings',
      'content',
      'orderedMovementContracts',
    });
    _require(
      _integer(envelope['schemaVersion']) == 2 &&
          envelope['id'] == 'jablab.taikyoku_shodan_jl' &&
          envelope['practiceKind'] == 'written_kata_instruction_and_recall' &&
          envelope['manuscriptSha256'] == manuscriptSha256 &&
          envelope['curriculumSha256'] == curriculumSha256 &&
          envelope['sourceMapSha256'] == sourceMapSha256,
      'Unsupported kata manuscript',
    );
    final bindings = _object(envelope['sourceBindings']);
    _keys(bindings, {
      'opening',
      'movementEndpoints',
      'observedTransitions',
      'closing',
      'BClosingInwardFootOrder',
      'referenceReportSha256',
    });
    _require(
      bindings['opening'] == 'A' &&
          bindings['closing'] == 'A' &&
          bindings['movementEndpoints'] == 'B' &&
          bindings['observedTransitions'] == 'B' &&
          bindings['BClosingInwardFootOrder'] == null &&
          bindings['referenceReportSha256'] == reportSha256,
      'Invalid A/B source distinction',
    );
    _keys(m, {
      'version',
      'status',
      'id',
      'working_reference_label',
      'title',
      'authorship',
      'approved_reference_report_sha256',
      'reference_approval_scope',
      'releaseReadiness',
      'physicalRequirements',
      'common_limits',
      'opening',
      'closing',
      'movements',
      'lessons',
      'sources',
      'source_mapping_input_sha256',
      'protected_base',
      'scope_limits',
    });
    _require(
      m['version'] == 'taikyoku-shodan-jason-leung-manuscript-v1' &&
          m['id'] == 'taikyoku-shodan-jason-leung-a' &&
          m['working_reference_label'] == 'TS20-JL-working-20261006' &&
          m['approved_reference_report_sha256'] == reportSha256 &&
          m['source_mapping_input_sha256'] == sourceMapSha256,
      'Wrong instructor reference',
    );
    for (final key in ['status', 'authorship', 'reference_approval_scope']) {
      _text(
        m[key],
      ); // Preserved authored-snapshot metadata, not a runtime release claim.
    }
    _strings(m['scope_limits']);
    final readiness = _object(m['releaseReadiness']);
    _keys(readiness, {
      'instructorReview',
      'demonstrations',
      'individualFeedback',
    });
    _require(
      readiness.values.every((v) => v == false),
      'Unaccepted physical readiness',
    );
    _require(
      requirements.length == 6 &&
          _same(requirements.map((p) => p.id).toList(), [
            for (var i = 0; i < 6; i++) 'TS-P$i',
          ]),
      'Invalid physical prerequisite inventory',
    );
    final base = _object(m['protected_base']);
    _keys(base, {'tree', 'source_files', 'existing_lessons', 'unchanged'});
    _require(
      base['tree'] == 'dcb466024b2da49e068fc33499260c7cddf879cf' &&
          _integer(base['source_files']) == 445 &&
          _integer(base['existing_lessons']) == 101 &&
          base['unchanged'] == true,
      'Invalid protected source reference',
    );
    _require(
      sources.length == 2 &&
          sources[0].id == 'A' &&
          sources[1].id == 'B' &&
          sources[0].url.toString() ==
              'https://www.youtube.com/watch?v=jH6bv4GDpp0' &&
          sources[1].url.toString() ==
              'https://www.youtube.com/watch?v=kta8JS_pXFs',
      'Wrong source recording',
    );
    _require(
      movements.length == 20 &&
          countContracts.length == 20 &&
          lessons.length == 10,
      'Incomplete kata inventory',
    );
    for (var i = 0; i < 20; i++) {
      final movement = movements[i];
      final contract = countContracts[i];
      final evidence = movement.evidence;
      final turnIndex = _turnCounts.indexOf(i + 1);
      final stepIndex = _stepCounts.indexOf(i + 1);
      _require(
        movement.count == i + 1 &&
            movement.id == _id('ts-m', i + 1) &&
            contract.count == movement.count &&
            contract.id == movement.id &&
            contract.heading == _headings[i] &&
            contract.frontFoot == _sides[i] &&
            contract.activeHand == _sides[i] &&
            contract.technique == _techniques[i] &&
            contract.entry == _entries[i] &&
            contract.sample == _samples[i] &&
            evidence.sample == _samples[i] &&
            evidence.countPointer == '/counts/$i' &&
            evidence.turnPointer ==
                (turnIndex < 0 ? null : '/requested_turn_entries/$turnIndex') &&
            evidence.stepPointer ==
                (stepIndex < 0 ? null : '/stepping_boundaries/$stepIndex') &&
            evidence.fineStepSampled == (stepIndex < 0 ? null : stepIndex < 5),
        'Invalid ordered movement or evidence binding',
      );
    }
    const teachingLengths = [4, 2, 2, 2, 2, 2, 2, 2, 2, 2];
    const groups = <List<int>>[
      [],
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 11, 12],
      [13, 14, 15, 16],
      [17, 18, 19, 20],
      [],
      [],
      [],
      [],
    ];
    const answers = [
      'a',
      'c',
      'b',
      'b',
      'a',
      'c',
      'c',
      'a',
      'b',
      'c',
      'b',
      'a',
      'b',
      'c',
      'a',
      'c',
      'a',
      'b',
      'c',
      'b',
    ];
    for (var i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      lesson.selfPractice.requireBinding(
        lesson.id,
        sources.map((source) => source.id).toList(),
      );
      _require(
        lesson.id == _id('ts-', i + 1) &&
            lesson.teaching.length == teachingLengths[i] &&
            _same(lesson.movementIds, [
              for (final n in groups[i]) _id('ts-m', n),
            ]) &&
            lesson.recall.length == 2,
        'Invalid ordered lesson contract',
      );
      for (var j = 0; j < 2; j++) {
        final q = lesson.recall[j];
        _require(
          q.id == _id('ts-q', i * 2 + j + 1) &&
              q.correctChoiceId == answers[i * 2 + j],
          'Invalid ordered recall key',
        );
      }
    }
  }

  factory TaikyokuCourse.fromJsonString(String source) {
    try {
      return TaikyokuCourse._(_object(jsonDecode(source)));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed Taikyoku Shodan course');
    }
  }

  static const reviewedAssetSha256 =
      '7c498b8d582e3c9cce14f81b8cde4e81e0021b0668015e03f1d0f30c604aaacc';
  static const manuscriptSha256 =
      'f748648bffca221f6752a4ceedea8418df389e06a0e488d039d8177e64e27d3a';
  static const curriculumSha256 =
      '6c6a0608c2bd5b63d6d00157b5a0d6be17e8d29b0fc3fa154441119750dbee9c';
  static const sourceMapSha256 =
      '942e3c3804bf64a81470bda1fa256c9389dd0eae42f71b40cb2973e9d7b6d4c6';
  static const reportSha256 =
      '13f7bdaa3dd4f33682595128f00a12884aa9563e61206c84fc4158cf3f4e6aff';
  final TaikyokuCopy title, commonLimits, opening, closing;
  final List<TaikyokuRequirement> requirements;
  final List<TaikyokuSource> sources;
  final List<TaikyokuMovement> movements;
  final List<TaikyokuCountContract> countContracts;
  final List<TaikyokuLesson> lessons;
  bool get selfPracticeAvailable =>
      lessons.any((lesson) => lesson.selfPractice.offersMovement);
  bool get physicalTechniqueValidated => false;
  // Compatibility value: validated physical availability remains false.
  bool get physicalPracticeAvailable => false;
  Map<String, bool> get releaseReadiness => const {
    'instructorReview': false,
    'demonstrations': false,
    'individualFeedback': false,
  };
  List<TaikyokuMovement> movementsFor(TaikyokuLesson lesson) =>
      List.unmodifiable(
        lesson.movementIds.map((id) => movements.firstWhere((m) => m.id == id)),
      );
}

const _headings = [
  'W',
  'W',
  'E',
  'E',
  'N',
  'N',
  'N',
  'N',
  'E',
  'E',
  'W',
  'W',
  'S',
  'S',
  'S',
  'S',
  'W',
  'W',
  'E',
  'E',
];
const _sides = [
  'L',
  'R',
  'R',
  'L',
  'L',
  'R',
  'L',
  'R',
  'L',
  'R',
  'R',
  'L',
  'L',
  'R',
  'L',
  'R',
  'L',
  'R',
  'R',
  'L',
];
const _turnCounts = [1, 3, 5, 9, 11, 13, 17, 19];
const _stepCounts = [2, 4, 6, 7, 8, 10, 12, 14, 15, 16, 18, 20];
const _samples = [
  '0:09.4',
  '0:14.4',
  '0:19.4',
  '0:22.0',
  '0:25.9',
  '0:28.9',
  '0:32.5',
  '0:35.9',
  '0:39.3',
  '0:42.9',
  '0:47.4',
  '0:50.8',
  '0:55.8',
  '0:58.4',
  '1:01.8',
  '1:05.8',
  '1:09.9',
  '1:13.8',
  '1:18.8',
  '1:22.8',
];
const _entries = [
  'left quarter-turn',
  'forward step',
  'right half-turn',
  'forward step',
  'left quarter-turn',
  'forward step',
  'forward step',
  'forward step',
  'long left turn',
  'forward step',
  'right half-turn',
  'forward step',
  'left quarter-turn',
  'forward step',
  'forward step',
  'forward step',
  'long left turn',
  'forward step',
  'right half-turn',
  'forward step',
];
const _techniques = [
  'low block',
  'middle punch',
  'low block',
  'middle punch',
  'low block',
  'middle punch',
  'middle punch',
  'middle punch',
  'low block',
  'middle punch',
  'low block',
  'middle punch',
  'low block',
  'punch',
  'punch',
  'punch',
  'low block',
  'punch',
  'low block',
  'punch',
];

String _id(String prefix, int number) =>
    '$prefix${number.toString().padLeft(2, '0')}';
void _require(bool valid, String message) {
  if (!valid) throw FormatException(message);
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

List<dynamic> _array(Object? value) {
  if (value is! List) throw const FormatException('Expected array');
  return value;
}

String _text(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Expected nonempty text');
  }
  return value;
}

String? _nullableText(Object? value) => value == null ? null : _text(value);
int _integer(Object? value) {
  if (value is! int) throw const FormatException('Expected integer');
  return value;
}

void _keys(Map<String, dynamic> value, Set<String> expected) => _require(
  value.length == expected.length && expected.every(value.containsKey),
  'Unexpected or missing schema key',
);
List<String> _strings(Object? value) {
  final strings = _array(value).map(_text).toList(growable: false);
  _require(strings.toSet().length == strings.length, 'Duplicate reference');
  return List.unmodifiable(strings);
}

bool _same(List<String> a, List<String> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);
