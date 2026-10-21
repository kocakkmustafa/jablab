import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/kickboxing_course.dart';
import 'package:jablab/app/muay_thai_course.dart';
import 'package:jablab/app/self_guided_practice.dart';

Map<String, dynamic> practiceFixture({
  String lessonId = 'kb-01',
  List<String> sourceIds = const ['S7'],
  String mode = 'preparation',
  String review = 'pending',
  String? receipt,
}) => {
  'lessonId': lessonId,
  'sourceIds': sourceIds,
  'mode': mode,
  'sourceReview': review,
  'sourceReviewReceiptId': receipt,
  'task': {'tr': 'Özgün küçük görev', 'en': 'Original small task'},
  'observe': {'tr': 'Belirsiz kısmı kaydet', 'en': 'Record uncertainty'},
  'safety': {'tr': 'Temas ve zorlamaya geçme', 'en': 'Add no contact or force'},
  'adaptation': {'tr': 'Oturarak sırayı yaz', 'en': 'Write the order seated'},
  'progressEffect': 0,
};

void main() {
  test(
    'pending evidence offers no movement and cannot carry a fake receipt',
    () {
      final pending = SelfGuidedPractice.decode(practiceFixture());
      expect(pending.offersMovement, isFalse);
      expect(pending.progressEffect, 0);
      expect(pending.verifiedTechnique, isFalse);
      expect(
        () => SelfGuidedPractice.decode(
          practiceFixture(receipt: 'synthetic-only-not-an-acceptance'),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'text review permits bounded preparation, not named small-range mechanics',
    () {
      final text = practiceFixture(
        review: 'text_review',
        receipt: 'synthetic-text-fixture-only',
      );
      expect(SelfGuidedPractice.decode(text).offersMovement, isTrue);
      text['mode'] = 'small_range_non_contact';
      expect(SelfGuidedPractice.decode(text).offersMovement, isFalse);
      text['sourceReview'] = 'video_review';
      text['sourceReviewReceiptId'] = 'synthetic-video-family-only';
      expect(SelfGuidedPractice.decode(text).offersMovement, isTrue);
      text['mode'] = 'concept_only';
      expect(SelfGuidedPractice.decode(text).offersMovement, isFalse);
    },
  );

  test(
    'strict fields, bilingual safety, evidence state and zero progress survive tampering',
    () {
      void rejects(void Function(Map<String, dynamic>) change) {
        final map = practiceFixture();
        change(map);
        expect(() => SelfGuidedPractice.decode(map), throwsFormatException);
      }

      rejects((m) => m['progressEffect'] = 1);
      rejects((m) => m['progressEffect'] = 0.0);
      rejects((m) => m['progressEffect'] = false);
      rejects((m) => m['verifiedTechnique'] = true);
      rejects((m) => m['mode'] = 'contact');
      rejects((m) => m['sourceReview'] = 'metadata_is_video');
      rejects((m) => m['sourceReview'] = 'video_review');
      rejects((m) => m['safety']['tr'] = '');
      rejects((m) => m['adaptation'].remove('en'));
      rejects((m) => m['observe']['de'] = 'unexpected');
      rejects((m) => m.remove('task'));
      rejects((m) => m['sourceIds'] = ['S7', 'S7']);
      rejects((m) => m['sourceIds'] = []);
    },
  );

  test(
    'lesson/source binding rejects a reused foreign block, not a shared family receipt',
    () {
      final first = SelfGuidedPractice.decode(
        practiceFixture(
          review: 'video_review',
          receipt: 'synthetic-shared-family-only',
        ),
      );
      first.requireBinding('kb-01', ['S7']);
      expect(
        () => first.requireBinding('kb-02', ['S7']),
        throwsFormatException,
      );
      expect(
        () => first.requireBinding('kb-01', ['S1']),
        throwsFormatException,
      );
      final second = SelfGuidedPractice.decode(
        practiceFixture(
          lessonId: 'kb-02',
          sourceIds: ['S1'],
          review: 'video_review',
          receipt: 'synthetic-shared-family-only',
        ),
      );
      second.requireBinding('kb-02', ['S1']);
      expect(second.sourceReviewReceiptId, first.sourceReviewReceiptId);
      expect(() => second.sourceIds.add('S2'), throwsUnsupportedError);
    },
  );

  test(
    'both real course decoders preserve sixteen IDs, prerequisites and false acceptance',
    () {
      for (final name in ['kickboxing', 'muay_thai']) {
        final map =
            jsonDecode(
                  File('assets/content/${name}_a.v1.json').readAsStringSync(),
                )
                as Map<String, dynamic>;
        final lessons = map['lessons'] as List<dynamic>;
        final beforeIds = [for (final l in lessons) l['id']];
        final beforePrerequisites = jsonEncode([
          for (final l in lessons) l['prerequisiteIds'],
        ]);
        for (final dynamic lesson in lessons) {
          lesson['selfGuidedPractice'] = practiceFixture(
            lessonId: lesson['id'] as String,
            sourceIds: (lesson['sourceIds'] as List<dynamic>).cast<String>(),
          );
        }
        if (name == 'kickboxing') {
          final c = KickboxingCourse.fromJsonString(jsonEncode(map));
          expect(c.lessons.map((l) => l.id), beforeIds);
          expect(
            jsonEncode(c.lessons.map((l) => l.prerequisiteIds).toList()),
            beforePrerequisites,
          );
          expect(c.verifiedPhysicalPracticeAvailable, isFalse);
          expect(c.lessons.every((l) => l.selfGuidedPractice != null), isTrue);
        } else {
          final c = MuayThaiCourse.fromJsonString(jsonEncode(map));
          expect(c.lessons.map((l) => l.id), beforeIds);
          expect(
            jsonEncode(c.lessons.map((l) => l.prerequisiteIds).toList()),
            beforePrerequisites,
          );
          expect(c.verifiedPhysicalPracticeAvailable, isFalse);
          expect(c.lessons.every((l) => l.selfGuidedPractice != null), isTrue);
          expect(
            (map['physicalRequirements'] as Map<String, dynamic>).values,
            everyElement(isFalse),
          );
        }
        expect(
          (map['releaseReadiness'] as Map<String, dynamic>).values,
          everyElement(isFalse),
        );
      }
    },
  );

  test(
    'both course decoders reject cross-lesson block injection and readiness promotion',
    () {
      for (final name in ['kickboxing', 'muay_thai']) {
        Map<String, dynamic> fixture() =>
            jsonDecode(
                  File('assets/content/${name}_a.v1.json').readAsStringSync(),
                )
                as Map<String, dynamic>;
        Object decode(Map<String, dynamic> map) => name == 'kickboxing'
            ? KickboxingCourse.fromJsonString(jsonEncode(map))
            : MuayThaiCourse.fromJsonString(jsonEncode(map));
        final map = fixture();
        final dynamic lesson = map['lessons'][0];
        lesson['selfGuidedPractice'] = practiceFixture(
          lessonId: 'foreign-lesson',
          sourceIds: (lesson['sourceIds'] as List<dynamic>).cast<String>(),
        );
        expect(() => decode(map), throwsFormatException);
        final promoted = fixture();
        promoted['releaseReadiness']['instructorReview'] = true;
        expect(() => decode(promoted), throwsFormatException);
        final absent = fixture();
        absent['lessons'][0]['selfGuidedPractice'] = null;
        expect(() => decode(absent), throwsFormatException);
      }
    },
  );
}
