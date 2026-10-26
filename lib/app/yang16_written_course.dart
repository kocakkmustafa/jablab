import 'dart:convert';
import 'dart:typed_data';

import 'package:motion_content/motion_content.dart' show computeSha256Hex;

final class Yang16Copy {
  const Yang16Copy({required this.tr, required this.en});
  factory Yang16Copy.decode(Object? value) {
    final m = _object(value);
    _keys(m, {'tr', 'en'});
    return Yang16Copy(tr: _text(m['tr']), en: _text(m['en']));
  }
  final String tr, en;
}

final class Yang16Option {
  Yang16Option(Map<String, dynamic> m)
    : id = _text(m['id']),
      text = Yang16Copy.decode(m['text']) {
    _keys(m, {'id', 'text'});
  }
  final String id;
  final Yang16Copy text;
}

final class Yang16Boundary {
  Yang16Boundary(Map<String, dynamic> m)
    : id = _text(m['id']),
      from = _text(m['from']),
      to = _text(m['to']),
      link = Yang16Copy.decode(m['writtenLink']),
      limit = Yang16Copy.decode(m['localUncertainty']) {
    _keys(m, {
      'id',
      'from',
      'to',
      'writtenLink',
      'localUncertainty',
      'observationGrounding',
      'physicalActionAvailable',
      'physicalInstruction',
    });
    _require(
      m['physicalActionAvailable'] == false && m['physicalInstruction'] == null,
      'Physical boundary must remain unavailable',
    );
  }
  final String id, from, to;
  final Yang16Copy link, limit;
}

final class Yang16Target {
  Yang16Target._({
    required this.id,
    required this.index,
    required this.title,
    required this.reading,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.facts,
    required this.correction,
    required this.completion,
    required this.supplementPrompt,
    required this.supplementAnswer,
    required this.supplementOptions,
    required this.initialExplanation,
    required this.retestExplanation,
    required this.responseRequirement,
    required this.supplementExplanation,
  });

  factory Yang16Target.node(Map<String, dynamic> m, int index) {
    _require(
      m['writtenSequenceIndex'] == index &&
          m['physicalActionAvailable'] == false &&
          m['physicalInstruction'] == null,
      'Invalid written node',
    );
    final original = _object(m['recall']);
    final retest = _object(m['retest']);
    _require(
      _equal(original['prompt'], retest['prompt']) &&
          _equal(original['options'], retest['options']) &&
          original['answerId'] == retest['answerId'] &&
          retest['originalTargetCheckId'] == original['id'],
      'Retest changed original target',
    );
    _retestContract(retest);
    final options = _options(original['options']);
    final answerId = _text(original['answerId']);
    _require(
      options.map((o) => o.id).join(',') == 'a,b' &&
          options.any((o) => o.id == answerId),
      'Invalid original key',
    );
    final answerRaw = _array(
      original['options'],
    ).map(_object).firstWhere((o) => o['id'] == answerId)['text'];
    _require(
      _equal(answerRaw, retest['expectedReconstruction']),
      'Retest weakened full answer',
    );
    final supplemental = _object(m['supplementaryCheck']);
    _supplementContract(supplemental);
    final legacy = _object(supplemental['legacyQuestion']);
    final legacyOptions = _options(legacy['options']);
    final legacyAnswer = legacyOptions
        .firstWhere((o) => o.id == legacy['answerId'])
        .text;
    final reading = <Yang16Copy>[
      Yang16Copy.decode(m['goal']),
      Yang16Copy.decode(m['observationTeaching']),
      Yang16Copy.decode(m['localUncertainty']),
      for (final raw in _array(m['physicalPrerequisites']))
        Yang16Copy.decode(_physicalRequirement(raw)['requirement']),
      Yang16Copy.decode(m['progressMeaning']),
    ];
    return Yang16Target._(
      id: _text(m['id']),
      index: index,
      title: Yang16Copy.decode(m['title']),
      reading: List.unmodifiable(reading),
      prompt: Yang16Copy.decode(original['prompt']),
      options: options,
      answer: Yang16Copy.decode(answerRaw),
      facts: _copies(retest['requiredFacts']),
      correction: Yang16Copy.decode(m['correction']),
      completion: Yang16Copy.decode(m['targetCompletionCriterion']),
      supplementPrompt: Yang16Copy.decode(legacy['prompt']),
      supplementAnswer: legacyAnswer,
      supplementOptions: legacyOptions,
      initialExplanation: Yang16Copy.decode(original['explanation']),
      retestExplanation: Yang16Copy.decode(retest['explanation']),
      responseRequirement: Yang16Copy.decode(retest['responseRequirement']),
      supplementExplanation: Yang16Copy.decode(legacy['explanation']),
    );
  }

  factory Yang16Target.finalCheck(Map<String, dynamic> m, int index) {
    final contract = _object(m['sameTargetRetestContract']);
    _retestContract(contract);
    _require(
      _equal(m['prompt'], m['retest']) &&
          _equal(m['answer'], m['retestAnswer']),
      'Final retest changed original target',
    );
    final supplemental = _object(m['supplementaryCheck']);
    _supplementContract(supplemental);
    return Yang16Target._(
      id: _text(m['id']),
      index: index,
      title: Yang16Copy.decode(m['prompt']),
      reading: const [],
      prompt: Yang16Copy.decode(m['prompt']),
      options: const [],
      answer: Yang16Copy.decode(m['answer']),
      facts: _copies(contract['requiredFacts']),
      correction: Yang16Copy.decode(m['correction']),
      completion: Yang16Copy.decode(m['onCorrect']),
      supplementPrompt: Yang16Copy.decode(supplemental['prompt']),
      supplementAnswer: Yang16Copy.decode(supplemental['answer']),
      supplementOptions: const [],
      initialExplanation: null,
      retestExplanation: null,
      responseRequirement: null,
      supplementExplanation: null,
    );
  }

  final String id;
  final int index;
  final Yang16Copy title, prompt, answer, correction, completion;
  final Yang16Copy supplementPrompt, supplementAnswer;
  final Yang16Copy? initialExplanation,
      retestExplanation,
      responseRequirement,
      supplementExplanation;
  final List<Yang16Copy> reading, facts;
  final List<Yang16Option> options, supplementOptions;
  bool get isFinal => index >= 18;
}

/// Exact reviewed written-order content. No mutable decoded map is exposed.
final class Yang16WrittenCourse {
  Yang16WrittenCourse._(Map<String, dynamic> c, Map<String, dynamic> mapping)
    : title = Yang16Copy.decode(c['title']),
      reading = List.unmodifiable([
        for (final key in [
          'scope',
          'endpoint',
          'writtenPrerequisites',
          'physicalPrerequisitePolicy',
          'howToStudy',
          'identityNotes',
          'writtenCompletion',
          'progressPolicy',
        ])
          Yang16Copy.decode(c[key]),
      ]),
      conditions = Yang16Copy.decode(
        _object(c['sameTargetRetestPolicy'])['sameStartingConditions'],
      ),
      passCriteria = Yang16Copy.decode(
        _object(c['sameTargetRetestPolicy'])['passCriteria'],
      ),
      targets = List.unmodifiable([
        for (var i = 0; i < _array(c['lessons']).length; i++)
          Yang16Target.node(_object(_array(c['lessons'])[i]), i),
        for (var i = 0; i < _array(c['finalWrittenChecks']).length; i++)
          Yang16Target.finalCheck(
            _object(_array(c['finalWrittenChecks'])[i]),
            i + 18,
          ),
      ]),
      boundaries = List.unmodifiable(
        _array(c['boundaries']).map((v) => Yang16Boundary(_object(v))),
      ) {
    _keys(c, {
      'reviewManuscriptVersion',
      'id',
      'presentationVariantId',
      'title',
      'scope',
      'endpoint',
      'writtenPrerequisites',
      'physicalPrerequisitePolicy',
      'howToStudy',
      'identityNotes',
      'counts',
      'lessons',
      'boundaries',
      'finalWrittenChecks',
      'writtenCompletion',
      'progressPolicy',
      'reviewReadiness',
      'sourceBindings',
      'sameTargetRetestPolicy',
      'writtenCompletionCriteria',
    });
    _require(
      c['reviewManuscriptVersion'] is int &&
          c['reviewManuscriptVersion'] == 2 &&
          c['id'] == 'yang16-angela-written-v2' &&
          c['presentationVariantId'] ==
              'yang-family-16-angela-plarre-2q4M75cCR6A-observed-2026-10-06-v1',
      'Wrong written presentation',
    );
    final readiness = _object(c['reviewReadiness']);
    _keys(readiness, {
      'concreteManuscriptReviewComplete',
      'physicalPrerequisitesEstablished',
      'completeMechanicalTeaching',
      'physicalMasteryAccepted',
      'appIntegrationApproved',
    });
    _require(
      readiness.values.every((v) => v == false),
      'Physical flags must remain false',
    );
    final policy = _object(c['sameTargetRetestPolicy']);
    _require(
      policy['allRequiredFactsMustBeCorrect'] == true &&
          policy['partialAnswerPasses'] == false &&
          policy['letterOnlyPasses'] == false &&
          policy['inventedMechanicsPass'] == false &&
          policy['supplementaryAnswerCanResolveOriginalError'] == false &&
          policy['sourceObservationSha256'] == observationSha256,
      'Weakened correction loop',
    );
    final completion = _object(c['writtenCompletionCriteria']);
    _require(
      completion['requiredTargets'] == 24 &&
          completion['allTargetsRequired'] == true &&
          completion['wrongOrIncompleteAnswerKeepsTargetUnresolved'] == true &&
          completion['supplementaryAnswerCanSatisfyTarget'] == false &&
          completion['physicalAcceptanceGranted'] == false,
      'Invalid written endpoint',
    );
    final ids = targets.map((t) => t.id).toList();
    _require(
      ids.length == 24 &&
          ids.join(',') == _targetIds.join(',') &&
          boundaries.length == 17,
      'Incomplete written inventory',
    );
    _require(
      _array(completion['requiredTargetIds']).join(',') ==
          [
            for (var i = 0; i < 18; i++) '${_targetIds[i]}-recall',
            ..._targetIds.skip(18),
          ].join(','),
      'Wrong completion targets',
    );
    for (var i = 0; i < 17; i++) {
      final b = boundaries[i];
      _require(
        b.id == 'E${i.toString().padLeft(2, '0')}' &&
            b.from == _targetIds[i] &&
            b.to == _targetIds[i + 1],
        'Wrong ordered boundary',
      );
    }
    _validateMapping(c, mapping);
  }

  factory Yang16WrittenCourse.fromVerifiedStrings(
    String source,
    String mappingSource,
  ) {
    try {
      _require(_hash(source) == reviewedAssetSha256, 'Unreviewed course bytes');
      _require(
        _hash(mappingSource) == reviewedMappingSha256,
        'Unreviewed mapping bytes',
      );
      return Yang16WrittenCourse._(
        _object(jsonDecode(source)),
        _object(jsonDecode(mappingSource)),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed Yang16 written-order course');
    }
  }

  static const reviewedAssetSha256 =
      'd6f8488084fd1bc54005ee1bd952038408e7b41e7bd02ad4f98bb85a72a44f94';
  static const reviewedMappingSha256 =
      'fcace5b2ce5d0544eae3acf92b5160fc2983c0e106ce0248259df00889bf143e';
  static const manuscriptSha256 =
      '39cb8c9162769caf61fee9fe19732cc667efe4f30de013d46af012bc2935841f';
  static const observationSha256 =
      '0fed7b2ac593b5906cc2448bb186d24e1a9299facfa0d2954cd9a7eb23ac1c66';
  static const sourceMapSha256 =
      '08293151065df8d38cba87c4e46076e03543c137f84c330c6063ca78f2ec1f11';
  final Yang16Copy title, conditions, passCriteria;
  final List<Yang16Copy> reading;
  final List<Yang16Target> targets;
  final List<Yang16Boundary> boundaries;
  bool get physicalPracticeAvailable => false;
  Map<String, bool> get reviewReadiness => const {
    'concreteManuscriptReviewComplete': false,
    'physicalPrerequisitesEstablished': false,
    'completeMechanicalTeaching': false,
    'physicalMasteryAccepted': false,
    'appIntegrationApproved': false,
  };
  List<Yang16Boundary> boundariesFor(Yang16Target target) => List.unmodifiable(
    boundaries.where((b) => b.from == target.id || b.to == target.id),
  );
}

const _targetIds = [
  'prepare',
  'm01',
  'm02',
  'm03',
  'm04',
  'm05',
  'm06',
  'm07',
  'm08',
  'm09',
  'm10',
  'm11',
  'm12',
  'm13',
  'm14',
  'm15',
  'm16',
  'return',
  'full-order',
  'boundary-count',
  'observed-repetitions',
  'cut-and-contact',
  'reference-not-load',
  'honest-return-and-endpoint',
];

void _validateMapping(
  Map<String, dynamic> content,
  Map<String, dynamic> mapping,
) {
  _keys(mapping, {
    'schemaVersion',
    'appId',
    'courseId',
    'curriculumSha256',
    'manuscriptSha256',
    'observationSha256',
    'sourceMapSha256',
    'manuscriptPayloadTree',
    'orderedNodeIds',
    'orderedBoundaryIds',
    'orderedTargetIds',
    'translatedFields',
    'sameTargetContracts',
  });
  _require(
    mapping['schemaVersion'] is int &&
        mapping['schemaVersion'] == 1 &&
        mapping['appId'] == 'com.yulalab.jablab' &&
        mapping['courseId'] == content['id'] &&
        mapping['curriculumSha256'] ==
            Yang16WrittenCourse.reviewedAssetSha256 &&
        mapping['manuscriptSha256'] == Yang16WrittenCourse.manuscriptSha256 &&
        mapping['observationSha256'] == Yang16WrittenCourse.observationSha256 &&
        mapping['sourceMapSha256'] == Yang16WrittenCourse.sourceMapSha256 &&
        mapping['manuscriptPayloadTree'] ==
            'af9208ed3cbefb06ddab87eafc772f8c3de098b7',
    'Wrong reviewed source mapping',
  );
  _require(
    _array(mapping['orderedNodeIds']).join(',') ==
            _targetIds.take(18).join(',') &&
        _array(mapping['orderedTargetIds']).join(',') == _targetIds.join(',') &&
        _array(mapping['orderedBoundaryIds']).join(',') ==
            [
              for (var i = 0; i < 17; i++) 'E${i.toString().padLeft(2, '0')}',
            ].join(','),
    'Wrong mapping order',
  );
  final fields = _array(mapping['translatedFields']);
  _require(fields.length == 1450, 'Incomplete translated mapping');
  final pointers = <String>{};
  for (final raw in fields) {
    final m = _object(raw);
    _keys(m, {'pointer', 'sha256'});
    final pointer = _text(m['pointer']);
    _require(
      pointers.add(pointer) &&
          _hash(_text(_at(content, pointer))) == m['sha256'],
      'Translated text mapping mismatch',
    );
  }
  final contracts = _array(mapping['sameTargetContracts']);
  _require(contracts.length == 24, 'Incomplete retest mapping');
  for (var i = 0; i < contracts.length; i++) {
    final m = _object(contracts[i]);
    _keys(m, {
      'targetId',
      'requiredPromptPointer',
      'originalPromptPointer',
      'requiredFactsPointer',
    });
    _require(
      m['targetId'] == _targetIds[i] &&
          _equal(
            _at(content, _text(m['requiredPromptPointer'])),
            _at(content, _text(m['originalPromptPointer'])),
          ) &&
          _array(_at(content, _text(m['requiredFactsPointer']))).isNotEmpty,
      'Retest mapping changed original target',
    );
  }
}

void _retestContract(Map<String, dynamic> m) {
  _require(
    m['allRequiredFactsMustBeCorrect'] == true &&
        m['partialAnswerPasses'] == false &&
        m['supplementaryAnswerCanSubstitute'] == false &&
        m['sameStartingConditionsPolicy'] ==
            '/sameTargetRetestPolicy/sameStartingConditions' &&
        m['passCriteriaPolicy'] == '/sameTargetRetestPolicy/passCriteria' &&
        _array(m['requiredFacts']).isNotEmpty,
    'Weakened same-target retest',
  );
}

void _supplementContract(Map<String, dynamic> m) {
  _require(
    m['requiredForCompletion'] == false &&
        m['canResolveOriginalTarget'] == false,
    'Supplement cannot substitute for original target',
  );
}

Map<String, dynamic> _physicalRequirement(Object? v) {
  final m = _object(v);
  _keys(m, {'id', 'requirement', 'establishedByThisManuscript'});
  _require(
    m['establishedByThisManuscript'] == false,
    'Physical prerequisite remains open',
  );
  return m;
}

List<Yang16Option> _options(Object? v) =>
    List.unmodifiable(_array(v).map((v) => Yang16Option(_object(v))));
List<Yang16Copy> _copies(Object? v) =>
    List.unmodifiable(_array(v).map(Yang16Copy.decode));
String _hash(String v) => computeSha256Hex(Uint8List.fromList(utf8.encode(v)));
bool _equal(Object? a, Object? b) => jsonEncode(a) == jsonEncode(b);
Object? _at(Object? value, String pointer) {
  _require(pointer.startsWith('/'), 'Invalid mapping pointer');
  for (final token in pointer.substring(1).split('/')) {
    value = value is List ? value[int.parse(token)] : _object(value)[token];
  }
  return value;
}

void _require(bool condition, String message) {
  if (!condition) throw FormatException(message);
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>)
    throw const FormatException('Expected object');
  return value;
}

List<dynamic> _array(Object? value) {
  if (value is! List) throw const FormatException('Expected array');
  return value;
}

String _text(Object? value) {
  if (value is! String || value.trim().isEmpty)
    throw const FormatException('Expected text');
  return value;
}

void _keys(Map<String, dynamic> m, Set<String> expected) => _require(
  m.length == expected.length && expected.every(m.containsKey),
  'Unexpected or missing schema key',
);
