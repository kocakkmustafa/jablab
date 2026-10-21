/// Draft afterimage only. Does not attest that a source video was inspected.
final class PracticeCopy {
  const PracticeCopy({required this.tr, required this.en});

  factory PracticeCopy.decode(dynamic value) {
    final map = _object(value);
    _keys(map, {'tr', 'en'});
    return PracticeCopy(tr: _text(map['tr']), en: _text(map['en']));
  }

  final String tr, en;
}

enum SelfGuidedPracticeMode { preparation, smallRangeNonContact, conceptOnly }

/// Text review is enough for bounded grounded/written preparation.
/// A named movement family uses actual visual review; neither is certification.
enum PracticeSourceReview { pending, writtenSource, videoSegments }

/// A user's unsaved account, not a grade, permission or observed movement.
enum PracticeAttempt { unrecorded, attempted, skipped, stopped, uncertain }

final class SelfGuidedPractice {
  SelfGuidedPractice.decode(dynamic value) : this._(_object(value));

  SelfGuidedPractice._(Map<String, dynamic> map)
    : lessonId = _text(map['lessonId']),
      mode = switch (_text(map['mode'])) {
        'preparation' => SelfGuidedPracticeMode.preparation,
        'small_range_non_contact' =>
          SelfGuidedPracticeMode.smallRangeNonContact,
        'concept_only' => SelfGuidedPracticeMode.conceptOnly,
        _ => throw const FormatException('Unknown self-guided practice mode'),
      },
      sourceReview = switch (_text(map['sourceReview'])) {
        'pending' => PracticeSourceReview.pending,
        'text_review' => PracticeSourceReview.writtenSource,
        'video_review' => PracticeSourceReview.videoSegments,
        _ => throw const FormatException('Unknown practice source review'),
      },
      sourceReviewReceiptId = map['sourceReviewReceiptId'] == null
          ? null
          : _text(map['sourceReviewReceiptId']),
      sourceIds = _strings(map['sourceIds']),
      task = PracticeCopy.decode(map['task']),
      observe = PracticeCopy.decode(map['observe']),
      safety = PracticeCopy.decode(map['safety']),
      adaptation = PracticeCopy.decode(map['adaptation']) {
    _keys(map, {
      'lessonId',
      'mode',
      'sourceReview',
      'sourceReviewReceiptId',
      'sourceIds',
      'task',
      'observe',
      'safety',
      'adaptation',
      'progressEffect',
    });
    if (map['progressEffect'] is! int || map['progressEffect'] != 0) {
      throw const FormatException('Practice must not award progress');
    }
    if (sourceIds.isEmpty ||
        (sourceReview != PracticeSourceReview.pending) !=
            (sourceReviewReceiptId != null)) {
      throw const FormatException('Missing or inconsistent source review');
    }
  }

  final String lessonId;
  final SelfGuidedPracticeMode mode;
  final PracticeSourceReview sourceReview;
  final String? sourceReviewReceiptId;
  final List<String> sourceIds;
  final PracticeCopy task, observe, safety, adaptation;

  int get progressEffect => 0;
  bool get verifiedTechnique => false;
  bool get offersMovement =>
      sourceReview != PracticeSourceReview.pending &&
      mode != SelfGuidedPracticeMode.conceptOnly &&
      (mode == SelfGuidedPracticeMode.preparation ||
          sourceReview == PracticeSourceReview.videoSegments);

  void requireBinding(String expectedLessonId, List<String> lessonSourceIds) {
    if (lessonId != expectedLessonId ||
        !sourceIds.every(lessonSourceIds.contains)) {
      throw const FormatException('Practice belongs to another lesson/source');
    }
  }
}

Map<String, dynamic> _object(dynamic value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected practice object');
  }
  return value;
}

void _keys(Map<String, dynamic> map, Set<String> expected) {
  if (map.length != expected.length || !map.keys.every(expected.contains)) {
    throw const FormatException('Unexpected or missing practice field');
  }
}

String _text(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Expected nonempty practice text');
  }
  return value;
}

List<String> _strings(dynamic value) {
  if (value is! List) throw const FormatException('Expected practice sources');
  final strings = value.map(_text).toList();
  if (strings.toSet().length != strings.length) {
    throw const FormatException('Duplicate practice source');
  }
  return List.unmodifiable(strings);
}
