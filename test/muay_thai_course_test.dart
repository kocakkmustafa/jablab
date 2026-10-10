import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/muay_thai_course.dart';

void main() {
  Map<String,dynamic> fixture() => jsonDecode(File('assets/content/muay_thai_a.v1.json').readAsStringSync()) as Map<String,dynamic>;
  void rejects(void Function(Map<String,dynamic>) change) {
    final m=fixture();change(m);
    expect(() => MuayThaiCourse.fromJsonString(jsonEncode(m)),throwsFormatException);
  }
  test('actual accepted v2 fist, support, toes and nine pauses remain written only', () {
    final c=MuayThaiCourse.fromJsonString(jsonEncode(fixture()));
    expect(c.lessons,hasLength(16)); expect(c.sequenceRows,hasLength(9));
    expect(c.sources,hasLength(14)); expect(c.physicalPracticeAvailable,isFalse);
    expect(c.lessons[3].answer.en,contains('keeping the thumb outside'));
    expect(c.lessons[3].answer.en,contains('release the thumb before opening the four fingers'));
    expect(c.lessons[3].answer.tr,contains('başparmak işaret/orta parmağın dışına yatırılır'));
    expect(c.lessons[9].answer.en,contains('right takes the load and left unloads'));
    expect(c.lessons[10].answer.en,contains('toes drawn back/up toward the shin'));
    expect(c.lessons[10].answer.en,contains('re-bend first'));
    expect(c.lessons[10].answer.en,contains('Ground it before sharing load'));
    expect(c.lessons[11].answer.en,contains('left takes the load and right unloads'));
    expect(c.lessons[11].answer.en,contains('Only after grounding share load'));
    expect(c.lessons[14].answer.en,contains('backward right R1→R0 then left F1→F0'));
    expect(c.sequenceRows[8].en,contains('release the external thumb'));
    expect(c.shared['limits']!.en,contains('Wai Kru'));
    expect(c.sources[10].role,contains('cross-style'));
    expect(c.sources[12].limit,contains('stationary rear-knee'));
    expect(() => c.lessons.clear(),throwsUnsupportedError);
    expect(() => c.sequenceRows.clear(),throwsUnsupportedError);
    expect(() => c.shared.clear(),throwsUnsupportedError);
    expect(() => c.sources.clear(),throwsUnsupportedError);
    expect(() => c.lessons[14].physicalPrerequisiteIds.clear(),throwsUnsupportedError);
    expect(() => c.lessons[14].sourceIds.clear(),throwsUnsupportedError);
  });
  test('strict decoder rejects schema, course, language, inventory and prerequisite corruption', () {
    rejects((m) => m['schemaVersion']=1.0);
    rejects((m) => m['schemaVersion']=2);
    rejects((m) => m['manuscriptSha256']='unreviewed');
    rejects((m) => m['id']='jablab.muay_thai_mastery');
    rejects((m) => m['practiceKind']='physical_muay_thai');
    rejects((m) => m['shared'].remove('physical_gate'));
    rejects((m) => m['shared']['stop']['en']='');
    rejects((m) => m['shared']['stop']['fr']='extra');
    rejects((m) => m['shared']['extra']={'tr':'x','en':'x'});
    rejects((m) => m['lessons'][1]['prerequisiteIds']=['mt-16']);
    rejects((m) => m['lessons'][0]['number']=1.0);
    rejects((m) => m['lessons'][1]['id']='mt-01');
    rejects((m) => m['lessons'][10]['answer_key']['tr']='');
    rejects((m) => m['lessons'][0].remove('written_task'));
    rejects((m) => m['lessons'][0].remove('retest'));
    rejects((m) => m['sequenceRows'].removeLast());
    rejects((m) => m['sources'].removeLast());
    rejects((m) => m['sources'][1]['id']='M1');
    rejects((m) => m['sources']=List.from(m['sources'].reversed));
    rejects((m) => m['sources'][0].remove('role'));
    rejects((m) => m['sources'][0]['url']='https://user:pass@example.org');
    rejects((m) => m['sources'][0]['url']='http://example.org');
    rejects((m) => m['lessons'][0]['masteryScore']=100);
  });
  test('all sixteen physical sets match independent accepted literal IDs', () {
    const expected=<List<String>>[
      [], ['P0'], ['P0','P1'], ['P0','P1'],
      ['P0','P1','P2'], ['P0','P1','P2'],
      ['P0','P1','P3'], ['P0','P1','P3'], ['P0','P1','P3'],
      ['P0','P1','P4'], ['P0','P1','P4'], ['P0','P1','P5'],
      ['P0','P1','P3','P6'], [],
      ['P0','P1','P2','P3','P4','P5','P6','P7'], [],
    ];
    final m=fixture();final c=MuayThaiCourse.fromJsonString(jsonEncode(m));
    for(var i=0;i<16;i++) {
      expect(m['lessons'][i]['physicalPrerequisiteIds'],expected[i]);
      expect(c.lessons[i].physicalPrerequisiteIds,expected[i]);
      expect(c.lessons[i].id,'mt-${(i+1).toString().padLeft(2,'0')}');
      expect(c.lessons[i].prerequisiteIds,i==0 ? <String>[] : ['mt-${i.toString().padLeft(2,'0')}']);
    }
  });
  test('every physical set rejects missing, injected, duplicate and reordered IDs', () {
    final original=fixture();
    for(var i=0;i<16;i++) {
      final ids=List<String>.from(original['lessons'][i]['physicalPrerequisiteIds']);
      rejects((m) => m['lessons'][i]['physicalPrerequisiteIds']=[...ids,'P99']);
      if(ids.isEmpty) { rejects((m) => m['lessons'][i]['physicalPrerequisiteIds']=['P0']); }
      else {
        for(final id in ids) { rejects((m) => m['lessons'][i]['physicalPrerequisiteIds']=ids.where((x) => x!=id).toList()); }
        rejects((m) => m['lessons'][i]['physicalPrerequisiteIds']=[...ids,ids.first]);
        if(ids.length>1) { rejects((m) => m['lessons'][i]['physicalPrerequisiteIds']=ids.reversed.toList()); }
      }
    }
  });
  test('all eight physical and three readiness flags remain false and exact', () {
    for(final id in ['P0','P1','P2','P3','P4','P5','P6','P7']) {
      for(final invalid in <Object?>[true,'false',0,null]) { rejects((m) => m['physicalRequirements'][id]=invalid); }
      rejects((m) => m['physicalRequirements'].remove(id));
    }
    rejects((m) => m['physicalRequirements']['P8']=false);
    for(final id in ['instructorReview','demonstrations','individualFeedback']) {
      for(final invalid in <Object?>[true,'false',0,null]) { rejects((m) => m['releaseReadiness'][id]=invalid); }
      rejects((m) => m['releaseReadiness'].remove(id));
    }
    rejects((m) => m['releaseReadiness']['mastery']=false);
  });
  test('all sixteen ordered contextual source sets match their independent inventory', () {
    const expected=<List<String>>[
      ['M1','M2'], ['M10'], ['M3','M9'], ['M3','M9','M11','M12'],
      ['M4'], ['M3','M9'], ['M5','M10'], ['M5','M6'], ['M5','M10'],
      ['M7','M3','M13'], ['M7','M3','M13','M14'], ['M6','M3','M13'],
      ['M8'], ['M1','M4','M6'],
      ['M4','M5','M7','M8','M10','M3','M11','M12','M13','M14'], ['M1','M10'],
    ];
    final c=MuayThaiCourse.fromJsonString(jsonEncode(fixture()));
    for(var i=0;i<16;i++) {
      expect(c.lessons[i].sourceIds,expected[i]);
      rejects((m) => m['lessons'][i]['sourceIds']=[]);
      rejects((m) => m['lessons'][i]['sourceIds']=['unknown']);
      rejects((m) => m['lessons'][i]['sourceIds']=[...expected[i],expected[i].first]);
      final extra=List.generate(14,(n) => 'M${n+1}').firstWhere((x) => !expected[i].contains(x));
      rejects((m) => m['lessons'][i]['sourceIds']=[...expected[i],extra]);
      for(final id in expected[i]) { rejects((m) => m['lessons'][i]['sourceIds']=expected[i].where((x) => x!=id).toList()); }
      if(expected[i].length>1) { rejects((m) => m['lessons'][i]['sourceIds']=expected[i].reversed.toList()); }
    }
  });
}
