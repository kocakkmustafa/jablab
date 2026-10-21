import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/karate_course.dart';

void main() {
  Map<String, dynamic> fixture() =>
      jsonDecode(File('assets/content/karate_a.v1.json').readAsStringSync())
          as Map<String, dynamic>;
  void rejects(void Function(Map<String, dynamic>) change) {
    final m = fixture();
    change(m);
    expect(
      () => KarateCourse.fromJsonString(jsonEncode(m)),
      throwsFormatException,
    );
  }

  test(
    'hand-recovery and exit content keeps written truth separate from optional tasks',
    () {
      final c = KarateCourse.fromJsonString(jsonEncode(fixture()));
      expect(c.lessons, hasLength(16));
      expect(c.sequenceRows, hasLength(6));
      expect(c.physicalPracticeAvailable, isFalse);
      expect(c.lessons[10].answer.en, contains('short up-and-back path'));
      expect(c.lessons[10].answer.en, contains('right hikite stays'));
      expect(c.lessons[10].answer.tr, contains('sağ hikite yerinde kalır'));
      expect(c.lessons[7].answer.en, contains('right rear foot advances'));
      expect(c.lessons[7].answer.en, contains('without passing it'));
      expect(c.lessons[11].answer.en, contains('left-right-left-right'));
      expect(c.lessons[14].answer.en, contains('E→S→W'));
      expect(c.lessons[14].answer.en, contains('S→W→N'));
      expect(c.sequenceRows[5].en, contains('not a seventh unit'));
      expect(c.shared['limits']!.en, contains('not Heian Shodan'));
      expect(
        c.shared['physical_gate']!.en,
        contains('Optional small non-contact self-practice'),
      );
      expect(() => c.lessons.clear(), throwsUnsupportedError);
      expect(() => c.sequenceRows.clear(), throwsUnsupportedError);
      expect(() => c.shared.clear(), throwsUnsupportedError);
      expect(
        () => c.lessons[10].physicalPrerequisiteIds.clear(),
        throwsUnsupportedError,
      );
    },
  );
  test(
    'strict decoder rejects weakened physical prerequisites, readiness and source bindings',
    () {
      rejects((m) => m['schemaVersion'] = 1.0);
      rejects((m) => m['schemaVersion'] = 1);
      rejects((m) => m['schemaVersion'] = 3);
      rejects((m) => m['manuscriptSha256'] = 'unreviewed');
      rejects((m) => m['id'] = 'jablab.karate_mastery');
      rejects((m) => m['shared'].remove('physical_gate'));
      rejects((m) => m['shared']['stop']['en'] = '');
      rejects((m) => m['shared']['extra'] = {'tr': 'x', 'en': 'x'});
      rejects((m) => m['releaseReadiness']['instructorReview'] = true);
      rejects((m) => m['releaseReadiness']['demonstrations'] = 'false');
      rejects((m) => m['physicalRequirements']['P5'] = true);
      rejects((m) => m['physicalRequirements'].remove('P6'));
      rejects((m) => m['lessons'][10]['physicalPrerequisiteIds'].remove('P5'));
      rejects((m) => m['lessons'][14]['physicalPrerequisiteIds'].remove('P6'));
      rejects((m) => m['lessons'][1]['prerequisiteIds'] = ['ka-16']);
      rejects((m) => m['lessons'][0]['number'] = 1.0);
      rejects((m) => m['lessons'][1]['id'] = 'ka-01');
      rejects((m) => m['lessons'][10]['answer_key']['tr'] = '');
      rejects((m) => m['lessons'][0].remove('written_task'));
      rejects((m) => m['lessons'][0].remove('retest'));
      rejects((m) => m['sequenceRows'].removeLast());
      rejects((m) => m['lessons'][0]['sourceIds'] = ['unknown']);
      rejects((m) => m['lessons'][0]['sourceIds'] = ['K1', 'K1']);
      rejects((m) => m['sources'][1]['id'] = 'K1');
      rejects((m) => m['sources'][0]['url'] = 'https://user:pass@example.org');
      rejects((m) => m['sources'][0]['url'] = 'http://example.org');
      rejects((m) => m['lessons'][0]['masteryScore'] = 100);
    },
  );

  test(
    'all sixteen physical protocol sets match the independent accepted inventory',
    () {
      const expected = <List<String>>[
        [],
        ['P0'],
        ['P0', 'P1'],
        ['P0', 'P1'],
        ['P0', 'P1', 'P2'],
        ['P0', 'P1', 'P2'],
        ['P0', 'P1', 'P2'],
        ['P0', 'P1', 'P3'],
        ['P0', 'P1', 'P3'],
        ['P0', 'P1', 'P2', 'P3', 'P4'],
        ['P0', 'P1', 'P2', 'P3', 'P5'],
        ['P0', 'P1', 'P3', 'P6'],
        ['P0', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6'],
        ['P0', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6'],
        ['P0', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6'],
        ['P0', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6'],
      ];
      final m = fixture();
      final c = KarateCourse.fromJsonString(jsonEncode(m));
      for (var i = 0; i < expected.length; i++) {
        expect(
          m['lessons'][i]['physicalPrerequisiteIds'],
          expected[i],
          reason: 'asset lesson ${i + 1}',
        );
        expect(
          c.lessons[i].physicalPrerequisiteIds,
          expected[i],
          reason: 'decoded lesson ${i + 1}',
        );
      }
      expect(c.physicalPracticeAvailable, isFalse);
    },
  );
  test(
    'all sixteen protocol sets reject omission, extras, duplicates and reordering',
    () {
      final original = fixture();
      for (var i = 0; i < 16; i++) {
        final required = List<String>.from(
          original['lessons'][i]['physicalPrerequisiteIds'],
        );
        rejects(
          (m) =>
              m['lessons'][i]['physicalPrerequisiteIds'] = [...required, 'P99'],
        );
        if (required.isEmpty) {
          rejects((m) => m['lessons'][i]['physicalPrerequisiteIds'] = ['P0']);
        } else {
          for (final id in required) {
            rejects(
              (m) => m['lessons'][i]['physicalPrerequisiteIds'] = required
                  .where((x) => x != id)
                  .toList(),
            );
          }
          rejects(
            (m) => m['lessons'][i]['physicalPrerequisiteIds'] = [
              ...required,
              required.first,
            ],
          );
          if (required.length > 1) {
            rejects(
              (m) => m['lessons'][i]['physicalPrerequisiteIds'] = required
                  .reversed
                  .toList(),
            );
          }
        }
      }
    },
  );
  test(
    'every physical and release flag rejects claims, invalid types and missing keys',
    () {
      for (final id in ['P0', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6']) {
        for (final invalid in <Object?>[true, 'false', 0, null]) {
          rejects((m) => m['physicalRequirements'][id] = invalid);
        }
        rejects((m) => m['physicalRequirements'].remove(id));
      }
      rejects((m) => m['physicalRequirements']['P7'] = false);
      for (final id in [
        'instructorReview',
        'demonstrations',
        'individualFeedback',
      ]) {
        for (final invalid in <Object?>[true, 'false', 0, null]) {
          rejects((m) => m['releaseReadiness'][id] = invalid);
        }
        rejects((m) => m['releaseReadiness'].remove(id));
      }
      rejects((m) => m['releaseReadiness']['physicalMastery'] = false);
    },
  );
  test('actual primary IDs retain exact URLs and reject swapped providers', () {
    const expected = <String, String>{
      'K11': 'https://www.youtube.com/watch?v=jH6bv4GDpp0',
      'K12': 'https://www.youtube.com/watch?v=kta8JS_pXFs',
      'K13': 'https://www.youtube.com/watch?v=1uKTYj00QLM',
    };
    final c = KarateCourse.fromJsonString(jsonEncode(fixture()));
    for (final entry in expected.entries) {
      expect(
        c.sources.singleWhere((s) => s.id == entry.key).url.toString(),
        entry.value,
      );
      rejects((m) {
        final source = (m['sources'] as List).singleWhere(
          (s) => s['id'] == entry.key,
        );
        source['url'] = 'https://example.org/wrong-provider';
      });
      rejects(
        (m) => (m['sources'] as List).removeWhere((s) => s['id'] == entry.key),
      );
    }
    rejects(
      (m) => m['sources'].add({...m['sources'].last, 'id': 'UNLISTED-PRIMARY'}),
    );
  });
}
