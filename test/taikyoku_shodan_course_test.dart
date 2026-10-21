import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/taikyoku_shodan_course.dart';
import 'package:motion_content/motion_content.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(
          File('assets/content/taikyoku_shodan_jl.v1.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

Object? _at(Object? value, String pointer) {
  for (final token in pointer.substring(1).split('/')) {
    value = value is List ? value[int.parse(token)] : (value as Map)[token];
  }
  return value;
}

void main() {
  void rejects(void Function(Map<String, dynamic>) change, {String? message}) {
    final value = _fixture();
    change(value);
    expect(
      () => TaikyokuCourse.fromJsonString(jsonEncode(value)),
      message == null
          ? throwsFormatException
          : throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'specific schema boundary',
                contains(message),
              ),
            ),
    );
  }

  test(
    'authored text is pinned while unchanged text retains historical hashes',
    () {
      final asset = _fixture();
      final pinned =
          jsonDecode(
                File(
                  'test/fixtures/taikyoku_shodan_authored_text.v2.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(
        pinned['legacy_reviewed_manuscript_sha256'],
        TaikyokuCourse.manuscriptSha256,
      );
      expect(
        pinned['legacy_reviewed_curriculum_sha256'],
        TaikyokuCourse.curriculumSha256,
      );
      final fields = pinned['fields'] as List;
      expect(fields, hasLength(348));
      // These two original teaching pairs intentionally changed under the new
      // first-release scope. Every other historical pair remains byte-hash exact.
      const changedHistoricalPointers = {
        '/content/lessons/0/teaching/3',
        '/content/lessons/9/teaching/0',
      };
      final legacyBytes = File(
        'test/fixtures/taikyoku_shodan_reviewed_text.v1.json',
      ).readAsBytesSync();
      expect(
        computeSha256Hex(Uint8List.fromList(legacyBytes)),
        pinned['baseReviewedFixtureSha256'],
      );
      final legacy =
          jsonDecode(utf8.decode(legacyBytes)) as Map<String, dynamic>;
      var retained = 0;
      for (final field in legacy['fields'] as List) {
        final pointer = field['pointer'] as String;
        if (changedHistoricalPointers.contains(pointer)) continue;
        final pair = _at(asset, pointer) as Map;
        for (final language in ['tr', 'en']) {
          expect(
            computeSha256Hex(
              Uint8List.fromList(utf8.encode(pair[language] as String)),
            ),
            field[language],
            reason: 'unchanged historical $pointer/$language',
          );
        }
        retained++;
      }
      expect(retained, 306);
      for (final field in fields) {
        final pair = _at(asset, field['pointer'] as String) as Map;
        expect(pair.keys.toSet(), {'tr', 'en'});
        for (final language in ['tr', 'en']) {
          expect(
            computeSha256Hex(
              Uint8List.fromList(utf8.encode(pair[language] as String)),
            ),
            field[language],
            reason: '${field["pointer"]}/$language',
          );
        }
      }
    },
  );

  test(
    'full20-count order retains actual sides, headings, source samples and visibility limits',
    () {
      final c = TaikyokuCourse.fromJsonString(jsonEncode(_fixture()));
      expect(c.lessons, hasLength(10));
      expect(c.movements, hasLength(20));
      expect(
        c.countContracts.map((m) => m.heading).join(),
        'WWEENNNNEEWWSSSSWWEE',
      );
      expect(
        c.countContracts.map((m) => m.activeHand).join(),
        'LRRLLRLRLRRLLRLRLRRL',
      );
      expect(
        c.countContracts.map((m) => m.frontFoot).join(),
        'LRRLLRLRLRRLLRLRLRRL',
      );
      expect(c.countContracts.map((m) => m.sample).toList(), [
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
      ]);
      expect(c.lessons.expand((l) => l.movementIds).toList(), [
        for (var i = 1; i <= 20; i++) 'ts-m${i.toString().padLeft(2, "0")}',
      ]);
      expect(c.opening.en, contains('left foot moves outward first'));
      expect(c.opening.en, contains('B starts already ready'));
      expect(c.closing.en, contains('left foot closing inward first'));
      expect(c.closing.en, contains('not assigned to B’s unseen interval'));
      expect(c.movements[8].feet.en, contains('around/behind'));
      expect(c.movements[16].feet.en, isNot(contains('behind')));
      expect(c.movements[8].limit.en, contains('outside the lower frame'));
      expect(c.movements[11].limit.en, contains('obscured by the near leg'));
      expect(c.movements[15].limit.en, contains('overlap partly'));
      expect(c.movements[12].hands.en, contains('partly hidden'));
      for (final n in [10, 12, 14, 15, 16, 18, 20]) {
        expect(c.movements[n - 1].hands.en, contains('not closely sampled'));
        expect(c.movements[n - 1].evidence.fineStepSampled, isFalse);
      }
      expect(c.commonLimits.en, contains('not measured joint angles'));
      expect(c.commonLimits.en, contains('viewed muted'));
      expect(c.physicalPracticeAvailable, isFalse);
      expect(c.requirements.map((p) => p.accepted), everyElement(isFalse));
      expect(c.releaseReadiness.values, everyElement(isFalse));
    },
  );

  test('all20 original keys preserve independent semantic answers', () {
    final c = TaikyokuCourse.fromJsonString(jsonEncode(_fixture()));
    final qs = c.lessons.expand((l) => l.recall).toList();
    expect(qs.map((q) => q.correctChoice.text.en).toList(), [
      'Left, then right',
      'Only the visible location relationship',
      'right / E',
      'From the preceding count’s actual finish',
      'left / N',
      'From the preceding count’s actual finish',
      'left / E',
      'From the preceding count’s actual finish',
      'left / S',
      'From the preceding count’s actual finish',
      'left / W',
      'From the preceding count’s actual finish',
      'Left, then right',
      'Recovery–ready–bow–upright',
      'Long left turn, left block/W',
      'Opening, all 20 actions, every boundary and closing',
      'Record visible and unknown detail separately',
      'Prompt, starting count, side and reference heading',
      'I recalled the 20-count order; physical conditions remain open',
      'No; audio was not separately assessed',
    ]);
    expect(qs.map((q) => q.correctChoiceId).toSet(), {'a', 'b', 'c'});
    expect(c.lessons[8].teaching[0].en, contains('Example 1'));
    expect(c.lessons[8].teaching[1].en, contains('Same-condition retest'));
    expect(
      c.lessons[9].completionMeaning.en,
      contains('not reporting acceptance of a physical kata'),
    );
  });

  test('decoder rejects wrong editions and any weakened A/B distinction', () {
    rejects((m) => m['schemaVersion'] = 1.0);
    rejects((m) => m['schemaVersion'] = 1);
    rejects((m) => m['schemaVersion'] = 3);
    rejects((m) => m['id'] = 'jablab.huckle_kata');
    rejects((m) => m['practiceKind'] = 'physical_mastery');
    for (final key in [
      'manuscriptSha256',
      'curriculumSha256',
      'sourceMapSha256',
    ]) {
      rejects((m) => m[key] = 'unreviewed');
    }
    for (final key in ['opening', 'closing']) {
      rejects((m) => m['sourceBindings'][key] = 'B', message: 'A/B');
    }
    for (final key in ['movementEndpoints', 'observedTransitions']) {
      rejects((m) => m['sourceBindings'][key] = 'A', message: 'A/B');
    }
    rejects(
      (m) => m['sourceBindings']['BClosingInwardFootOrder'] = ['L', 'R'],
      message: 'A/B',
    );
    rejects(
      (m) =>
          m['content']['working_reference_label'] = 'TS20-LH-working-20261006',
    );
    rejects(
      (m) => m['content']['sources'][0]['url'] =
          'https://user:pass@www.youtube.com/watch?v=jH6bv4GDpp0',
    );
    rejects(
      (m) => m['content']['sources'][1]['url'] =
          'https://www.youtube.com/watch?v=another',
    );
    rejects((m) => m['content']['sources'].removeLast());
    rejects((m) => m['content']['sources'][0]['extra'] = true);
  });

  test(
    'every ordered movement and transition binding rejects substitution and omission',
    () {
      for (var i = 0; i < 20; i++) {
        rejects((m) => m['content']['movements'][i]['count'] = i + 1.0);
        rejects((m) => m['content']['movements'][i]['id'] = 'ts-m99');
        rejects(
          (m) => m['content']['movements'][i]['evidence']['recording'] = 'A',
        );
        rejects(
          (m) =>
              m['content']['movements'][i]['evidence']['source_mapping_pointer'] =
                  '/counts/99',
        );
        rejects(
          (m) => m['orderedMovementContracts'][i]['heading'] = 'unknown',
          message: 'ordered movement',
        );
        rejects(
          (m) => m['orderedMovementContracts'][i]['activeHand'] = 'unknown',
        );
        rejects(
          (m) => m['orderedMovementContracts'][i]['frontFoot'] = 'unknown',
        );
        for (final key in ['footContact', 'wristRotation', 'loading']) {
          rejects(
            (m) => m['orderedMovementContracts'][i][key] = 'verified',
            message: 'must remain unknown',
          );
        }
      }
      for (final i in [0, 2, 4, 8, 10, 12, 16, 18]) {
        rejects(
          (m) =>
              m['content']['movements'][i]['evidence']['turn_entry_pointer'] =
                  null,
        );
      }
      for (final i in [1, 3, 5, 6, 7, 9, 11, 13, 14, 15, 17, 19]) {
        rejects(
          (m) =>
              m['content']['movements'][i]['evidence']['stepping_entry_pointer'] =
                  null,
        );
      }
      rejects((m) => m['content']['movements'].removeLast());
      rejects((m) => m['orderedMovementContracts'].removeLast());
      rejects(
        (m) => m['content']['movements'] = (m['content']['movements'] as List)
            .reversed
            .toList(),
      );
      rejects((m) => m['content']['movements'][8]['limit'].remove('tr'));
      rejects((m) => m['content']['movements'][12]['hands']['en'] = '');
    },
  );

  test(
    'all lesson groups, bilingual keys and recall order are strictly required',
    () {
      for (var i = 0; i < 10; i++) {
        rejects((m) => m['content']['lessons'][i]['id'] = 'ts-99');
        rejects((m) => m['content']['lessons'][i]['objective']['tr'] = '');
        rejects(
          (m) => m['content']['lessons'][i]['completion_meaning'].remove('en'),
        );
        rejects((m) => m['content']['lessons'][i]['teaching'].removeLast());
        rejects((m) => m['content']['lessons'][i]['recall'].removeLast());
        rejects(
          (m) => m['content']['lessons'][i]['recall'][0]['id'] = 'ts-q99',
        );
        rejects(
          (m) => m['content']['lessons'][i]['recall'][0]['correct_choice_id'] =
              'missing',
        );
        rejects(
          (m) => m['content']['lessons'][i]['recall'][0]['progress_kind'] =
              'physical',
        );
        rejects(
          (m) =>
              m['content']['lessons'][i]['recall'][0]['choices'][1]['id'] = 'a',
        );
        rejects(
          (m) =>
              m['content']['lessons'][i]['recall'][0]['explanation']['en'] = '',
        );
        rejects((m) => m['content']['lessons'][i]['mastery'] = true);
      }
      rejects(
        (m) => m['content']['lessons'][1]['movement_ids'] = [
          'ts-m01',
          'ts-m02',
          'ts-m03',
          'ts-m03',
        ],
      );
      rejects(
        (m) => m['content']['lessons'][3]['movement_ids'] = [
          'ts-m09',
          'ts-m10',
          'ts-m12',
          'ts-m11',
        ],
      );
      rejects((m) => m['content']['lessons'][0]['movement_ids'] = ['ts-m01']);
      rejects((m) => m['content']['lessons'][0]['title']['fr'] = 'unreviewed');
      rejects(
        (m) =>
            m['content']['lessons'][0]['recall'][0]['correct_choice_id'] = 'b',
        message: 'recall key',
      );
    },
  );

  test('all physical flags remain false, required and immutable', () {
    for (var i = 0; i < 6; i++) {
      for (final invalid in <Object?>[true, 'false', 0, null]) {
        rejects(
          (m) => m['content']['physicalRequirements'][i]['accepted'] = invalid,
        );
      }
      rejects(
        (m) => m['content']['physicalRequirements'][i].remove('accepted'),
      );
      rejects((m) => m['content']['physicalRequirements'][i]['id'] = 'TS-P99');
    }
    for (final key in [
      'instructorReview',
      'demonstrations',
      'individualFeedback',
    ]) {
      for (final invalid in <Object?>[true, 'false', 0, null]) {
        rejects((m) => m['content']['releaseReadiness'][key] = invalid);
      }
      rejects((m) => m['content']['releaseReadiness'].remove(key));
    }
    rejects((m) => m['content']['releaseReadiness']['physicalMastery'] = false);
    final c = TaikyokuCourse.fromJsonString(jsonEncode(_fixture()));
    expect(() => c.movements.clear(), throwsUnsupportedError);
    expect(() => c.countContracts.clear(), throwsUnsupportedError);
    expect(() => c.lessons.clear(), throwsUnsupportedError);
    expect(() => c.lessons[1].movementIds.clear(), throwsUnsupportedError);
    expect(() => c.lessons[0].teaching.clear(), throwsUnsupportedError);
    expect(
      () => c.lessons[0].recall[0].choices.clear(),
      throwsUnsupportedError,
    );
    expect(() => c.requirements.clear(), throwsUnsupportedError);
    expect(
      () => c.releaseReadiness['instructorReview'] = true,
      throwsUnsupportedError,
    );
  });
}
