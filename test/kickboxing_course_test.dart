import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/kickboxing_course.dart';

void main() {
  Map<String, dynamic> fixture() =>
      jsonDecode(File('assets/content/kickboxing_a.v1.json').readAsStringSync())
          as Map<String, dynamic>;
  void rejects(void Function(Map<String, dynamic>) change) {
    final m = fixture();
    change(m);
    expect(
      () => KickboxingCourse.fromJsonString(jsonEncode(m)),
      throwsFormatException,
    );
  }

  test('actual lesson 12 asset has the correct headers in each locale', () {
    final c = KickboxingCourse.fromJsonString(jsonEncode(fixture()));
    for (final row in c.lessons[11].rows) {
      expect(row.tr.split('\n').map((line) => line.split(':').first).toList(), [
        'İşaret',
        'Eylem',
        'Yön ve destek',
      ]);
      expect(row.en.split('\n').map((line) => line.split(':').first).toList(), [
        'Cue',
        'Action',
        'Direction/support',
      ]);
      expect(row.tr, isNot(contains('Action:')));
      expect(row.en, isNot(contains('Eylem:')));
    }
  });

  test(
    'strict schema retains prerequisite and unaccepted readiness boundaries',
    () {
      rejects((m) => m['schemaVersion'] = 1.0);
      rejects((m) => m['schemaVersion'] = 2);
      rejects((m) => m['lessons'][0]['number'] = 1.0);
      rejects((m) => m['safety']['tr'] = '');
      rejects((m) => m.remove('safety'));
      rejects((m) => m['writtenAlternative']['en'] = '');
      rejects((m) => m['conventionRows'].removeLast());
      rejects((m) => m['id'] = 'jablab.kickboxing_mastery');
      rejects((m) => m['releaseReadiness']['instructorReview'] = true);
      rejects((m) => m['releaseReadiness']['demonstrations'] = 'false');
      rejects((m) => m['releaseReadiness'].remove('individualFeedback'));
      rejects((m) => m['lessons'][6]['physicalPrerequisiteIds'] = []);
      rejects((m) => m['lessons'][11]['physicalPrerequisiteIds'] = []);
      rejects((m) => m['lessons'][1]['prerequisiteIds'] = ['kb-16']);
      rejects((m) => m['lessons'][1]['id'] = 'kb-01');
      rejects((m) => m['lessons'][0]['sourceIds'] = ['missing']);
      rejects((m) => m['lessons'][0]['sourceIds'] = ['S7', 'S7']);
      rejects((m) => m['sources'][1]['id'] = 'S1');
      rejects((m) => m['lessons'][11]['rows'].clear());
      rejects((m) => m['lessons'][10]['sourceNote'] = null);
      rejects((m) => m['lessons'][6]['answer']['tr'] = '');
      rejects((m) => m['lessons'][0]['unexpectedScore'] = 100);
      rejects((m) => m['sources'][0]['url'] = 'http://example.org');
      rejects((m) => m['sources'][0]['url'] = 'https://user:pass@example.org');
    },
  );
  test(
    'immutable source has sixteen lessons and explicit lesson 7 branches',
    () {
      final c = KickboxingCourse.fromJsonString(jsonEncode(fixture()));
      expect(c.lessons, hasLength(16));
      expect(c.verifiedPhysicalPracticeAvailable, isFalse);
      expect(c.conventionRows, hasLength(8));
      expect(
        c.conventionRows[2].en,
        'Southpaw: Right foot/hand lead, left foot/hand rear.',
      );
      expect(c.lessons[3].rows[1].en, contains('Orthodox: right then left'));
      expect(
        c.lessons[11].rows[2].en,
        contains('foot returns to small preparation while lifted'),
      );
      expect(c.safety.tr, contains('aynı oturumda zor görevi yeniden deneme'));
      expect(c.writtenAlternative.en, contains('defer the next physical task'));
      expect(c.lessons[6].answer.en, contains('If only the lead-hand guard'));
      expect(
        c.lessons[6].answer.tr,
        contains('Gözlenmeyen bileşen belirsizdir'),
      );
      expect(() => c.lessons.clear(), throwsUnsupportedError);
      expect(
        () => c.lessons[6].physicalPrerequisiteIds.clear(),
        throwsUnsupportedError,
      );
      expect(() => c.conventionRows.clear(), throwsUnsupportedError);
    },
  );
  test('actual primary IDs retain exact URLs and reject swapped providers', () {
    const expected = <String, String>{
      'S11': 'https://www.youtube.com/watch?v=CmpqqsmiP70',
      'S12': 'https://www.youtube.com/watch?v=IJIBBBQVIMw',
      'S13': 'https://www.youtube.com/watch?v=ZE6IVZ-MQUA',
      'S14': 'https://www.youtube.com/watch?v=bEVIlec93Ps',
      'S15': 'https://www.youtube.com/watch?v=aP-4Kjgc4Q8',
    };
    final c = KickboxingCourse.fromJsonString(jsonEncode(fixture()));
    for (final entry in expected.entries) {
      expect(c.sources.singleWhere((s) => s.id == entry.key).url.toString(), entry.value);
      rejects((m) {
        final source = (m['sources'] as List).singleWhere((s) => s['id'] == entry.key);
        source['url'] = 'https://example.org/wrong-provider';
      });
      rejects((m) => (m['sources'] as List).removeWhere((s) => s['id'] == entry.key));
    }
    rejects((m) => m['sources'].add({...m['sources'].last, 'id': 'UNLISTED-PRIMARY'}));
  });

}
