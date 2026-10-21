// UNRUN source-bound metadata definitions; not physical or viewing validation.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/self_guided_practice.dart';

void main() {
  const expected = <String, Map<String, Object?>>{
    'kickboxing:kb-01': <String, Object?>{'review': 'text_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-RECEIPT-BINDING-DRAFT.v3.json#/textReviewRecords/kickboxing:kb-01', 'sources': <String>['S7']},
    'kickboxing:kb-02': <String, Object?>{'review': 'text_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-RECEIPT-BINDING-DRAFT.v3.json#/textReviewRecords/kickboxing:kb-02', 'sources': <String>['S7']},
    'kickboxing:kb-03': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-JAB.json', 'sources': <String>['S2','S11']},
    'kickboxing:kb-04': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-FORWARD-BACKWARD.json', 'sources': <String>['S3','S13']},
    'kickboxing:kb-05': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-SIDE-STEP.json', 'sources': <String>['S3','S14']},
    'kickboxing:kb-06': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-JAB.json', 'sources': <String>['S4','S10','S11']},
    'kickboxing:kb-07': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-REAR-CROSS.json', 'sources': <String>['S4','S12']},
    'kickboxing:kb-08': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/7', 'sources': <String>['S7','S11','S12']},
    'kickboxing:kb-09': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-FORWARD-BACKWARD.json', 'sources': <String>['S7','S13']},
    'kickboxing:kb-10': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/EVOLVE-PUSH-KICK.json', 'sources': <String>['S7','S15']},
    'kickboxing:kb-11': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/EVOLVE-PUSH-KICK.json', 'sources': <String>['S5','S15']},
    'kickboxing:kb-12': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/EVOLVE-PUSH-KICK.json', 'sources': <String>['S5','S15']},
    'kickboxing:kb-13': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/12', 'sources': <String>['S7','S11','S15']},
    'kickboxing:kb-14': <String, Object?>{'review': 'text_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-RECEIPT-BINDING-DRAFT.v3.json#/textReviewRecords/kickboxing:kb-14', 'sources': <String>['S6']},
    'kickboxing:kb-15': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/14', 'sources': <String>['S7','S13','S11','S15']},
    'kickboxing:kb-16': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/15', 'sources': <String>['S7','S13','S11','S15']},
    'muay_thai:mt-01': <String, Object?>{'review': 'text_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-RECEIPT-BINDING-DRAFT.v3.json#/textReviewRecords/muay_thai:mt-01', 'sources': <String>['M1','M2']},
    'muay_thai:mt-02': <String, Object?>{'review': 'text_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-RECEIPT-BINDING-DRAFT.v3.json#/textReviewRecords/muay_thai:mt-02', 'sources': <String>['M10']},
    'muay_thai:mt-03': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-FORWARD-BACKWARD.json', 'sources': <String>['M3','M9','M17']},
    'muay_thai:mt-04': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/19', 'sources': <String>['M3','M9','M11','M12','M22','M15']},
    'muay_thai:mt-05': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-FORWARD-BACKWARD.json', 'sources': <String>['M4','M17']},
    'muay_thai:mt-06': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-SIDE-STEP.json', 'sources': <String>['M3','M9','M18']},
    'muay_thai:mt-07': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-JAB.json', 'sources': <String>['M5','M10','M15']},
    'muay_thai:mt-08': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/MYBOXINGCOACH-REAR-CROSS.json', 'sources': <String>['M5','M6','M16']},
    'muay_thai:mt-09': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/24', 'sources': <String>['M5','M10','M15','M16']},
    'muay_thai:mt-10': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/EVOLVE-PUSH-KICK.json', 'sources': <String>['M7','M3','M13','M19']},
    'muay_thai:mt-11': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/EVOLVE-PUSH-KICK.json', 'sources': <String>['M7','M3','M13','M14','M19']},
    'muay_thai:mt-12': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/EVOLVE-KNEE.json', 'sources': <String>['M6','M3','M13','M20']},
    'muay_thai:mt-13': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/EVOLVE-REAR-ELBOW.json', 'sources': <String>['M8','M21']},
    'muay_thai:mt-14': <String, Object?>{'review': 'text_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-RECEIPT-BINDING-DRAFT.v3.json#/textReviewRecords/muay_thai:mt-14', 'sources': <String>['M1','M4','M6']},
    'muay_thai:mt-15': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/30', 'sources': <String>['M4','M5','M7','M8','M10','M3','M11','M12','M13','M14','M17','M15','M16','M19','M20','M21']},
    'muay_thai:mt-16': <String, Object?>{'review': 'text_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-RECEIPT-BINDING-DRAFT.v3.json#/textReviewRecords/muay_thai:mt-16', 'sources': <String>['M1','M10']},
    'karate:ka-01': <String, Object?>{'review': 'text_review', 'receipt': 'jablab-karate-written-scope-20261020', 'sources': <String>['K1','K2','K3']},
    'karate:ka-02': <String, Object?>{'review': 'text_review', 'receipt': 'jablab-karate-written-setup-20261020', 'sources': <String>['K3']},
    'karate:ka-03': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/34', 'sources': <String>['K4','K7','K11','K12']},
    'karate:ka-04': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/KARATE-SHRIMP-FIST.json', 'sources': <String>['K5','K13']},
    'karate:ka-05': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/36', 'sources': <String>['K6','K11','K12']},
    'karate:ka-06': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/37', 'sources': <String>['K5','K6','K7','K11','K12','K13']},
    'karate:ka-07': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/38', 'sources': <String>['K3','K7','K11','K12']},
    'karate:ka-08': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/ULTIMATE-KARATE-TAIKYOKU-B.json', 'sources': <String>['K4','K9','K12']},
    'karate:ka-09': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/ULTIMATE-KARATE-TAIKYOKU-B.json', 'sources': <String>['K4','K6','K12']},
    'karate:ka-10': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/41', 'sources': <String>['K5','K6','K10','K11','K12','K13']},
    'karate:ka-11': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/42', 'sources': <String>['K5','K8','K6','K10','K11','K12']},
    'karate:ka-12': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/ULTIMATE-KARATE-TAIKYOKU-B.json', 'sources': <String>['K1','K4','K9','K12']},
    'karate:ka-13': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/ULTIMATE-KARATE-TAIKYOKU-B.json', 'sources': <String>['K1','K2','K4','K9','K12']},
    'karate:ka-14': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/45', 'sources': <String>['K6','K8','K10','K11','K12']},
    'karate:ka-15': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/46', 'sources': <String>['K1','K2','K6','K8','K4','K9','K10','K11','K12']},
    'karate:ka-16': <String, Object?>{'review': 'text_review', 'receipt': 'jablab-karate-written-scope-20261020', 'sources': <String>['K1','K2','K3']},
    'taikyoku:ts-01': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/ULTIMATE-KARATE-A-OPEN-CLOSE-ORDER.json', 'sources': <String>['A','B']},
    'taikyoku:ts-02': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/49', 'sources': <String>['A','B']},
    'taikyoku:ts-03': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/50', 'sources': <String>['A','B']},
    'taikyoku:ts-04': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/51', 'sources': <String>['A','B']},
    'taikyoku:ts-05': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/52', 'sources': <String>['A','B']},
    'taikyoku:ts-06': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/53', 'sources': <String>['A','B']},
    'taikyoku:ts-07': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/ULTIMATE-KARATE-A-OPEN-CLOSE-ORDER.json', 'sources': <String>['A','B']},
    'taikyoku:ts-08': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/55', 'sources': <String>['A','B']},
    'taikyoku:ts-09': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/ULTIMATE-KARATE-TAIKYOKU-B.json', 'sources': <String>['A','B']},
    'taikyoku:ts-10': <String, Object?>{'review': 'text_review', 'receipt': 'jablab-taikyoku-written-outcome-20261020', 'sources': <String>['A','B']},
    'yang16:prepare': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/58', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m01': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/59', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m02': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/60', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m03': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/61', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m04': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/62', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m05': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/63', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m06': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/64', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m07': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/65', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m08': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/66', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m09': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/67', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m10': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/68', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m11': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/69', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m12': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/70', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m13': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/71', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m14': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/72', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m15': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/73', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:m16': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/74', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
    'yang16:return': <String, Object?>{'review': 'video_review', 'receipt': 'curriculum-first-release-2026-10-20/video-review/FAMILY-COVERAGE-REVIEW.v3.json#/rows/75', 'sources': <String>['TC-ANGELA16','TC-PAULLAM-FIRST']},
  };
  test('all76fixed receipt/source literals preserve mode, progress and review contracts', () {
    const assets = <String, String>{
      'kickboxing': 'kickboxing_a.v1.json', 'muay_thai': 'muay_thai_a.v1.json',
      'karate': 'karate_a.v1.json', 'taikyoku': 'taikyoku_shodan_jl.v1.json',
      'yang16': 'yang16_preparation.v1.json',
    };
    var count = 0;
    for (final entry in assets.entries) {
      final data = jsonDecode(File('assets/content/${entry.value}').readAsStringSync()) as Map;
      final List records = entry.key == 'yang16' ? data['practices'] as List
          : (entry.key == 'taikyoku' ? data['content']['lessons'] : data['lessons']) as List;
      for (final record in records) {
        final Map raw = entry.key == 'yang16' ? record as Map
            : record[entry.key == 'kickboxing' || entry.key == 'muay_thai' ? 'selfGuidedPractice' : 'selfPractice'] as Map;
        final p = SelfGuidedPractice.decode(Map<String, dynamic>.from(raw));
        final fixed = expected['${entry.key}:${p.lessonId}']!;
        expect(raw['sourceReview'], fixed['review']);
        expect(p.sourceReviewReceiptId, fixed['receipt']);
        expect(p.sourceIds, fixed['sources']);
        expect(p.verifiedTechnique, isFalse);
        expect(p.progressEffect, 0);
        expect(p.offersMovement, p.mode != SelfGuidedPracticeMode.conceptOnly);
        final noReceipt = Map<String, dynamic>.from(raw)..['sourceReviewReceiptId'] = null;
        expect(() => SelfGuidedPractice.decode(noReceipt), throwsFormatException);
        final pending = Map<String, dynamic>.from(raw);
        pending['sourceReview'] = 'pending';
        pending['sourceReviewReceiptId'] = null;
        expect(SelfGuidedPractice.decode(pending).offersMovement, isFalse);
        pending['sourceReviewReceiptId'] = 'fake-while-pending';
        expect(() => SelfGuidedPractice.decode(pending), throwsFormatException);
        count++;
      }
    }
    expect(count, 76);
    expect(expected, hasLength(76));
  });
}
