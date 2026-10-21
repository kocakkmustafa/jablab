// UNRUN report-only afterimage. Synthetic review receipt below is test data.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/self_guided_practice.dart';
import 'package:jablab/app/self_guided_practice_panel.dart';
import 'package:jablab/app/yang16_preparation_course.dart';
import 'package:jablab/app/yang16_written_course_page.dart';
import 'yang16_test_support.dart';

Map<String,dynamic> bankJson() => jsonDecode(File(
  'assets/content/yang16_preparation.v1.json').readAsStringSync()) as Map<String,dynamic>;
Yang16PreparationCourse bank(Map<String,dynamic> value) =>
  Yang16PreparationCourse.fromJsonString(jsonEncode(value));
SelfGuidedPractice reviewedPrepare() {
  final value = bankJson();
  final first = (value['practices'] as List).first as Map;
  first['sourceReview'] = 'video_review';
  first['sourceReviewReceiptId'] = 'SYNTHETIC TEST ONLY: NOT A REAL WATCH RECEIPT';
  return bank(value).forTarget('prepare')!;
}
RadioGroup<PracticeAttempt> attemptGroup(WidgetTester t) =>
  t.widget<RadioGroup<PracticeAttempt>>(find.descendant(
    of: find.byType(SelfGuidedPracticePanel),
    matching: find.byType(RadioGroup<PracticeAttempt>)));
Future<void> mountPractice(WidgetTester t, {required SelfGuidedPractice practice,
  bool Function()? admitted, VoidCallback? written, VoidCallback? invalidate}) async {
  final course = yangCourse();
  await t.pumpWidget(MaterialApp(home: Yang16WrittenTargetPage(
    course: course, target: course.targets.first, practice: practice,
    admitted: admitted ?? () => true, priorWritten: () => true,
    onWritten: written ?? () {}, onInvalidate: invalidate ?? () {}, onReset: () {})));
  await t.pumpAndSettle();
  await yangShow(t, 'self-guided-attempt-attempted');
}
void main() {
  test('separate18 bank preserves original24 written targets and exact node identities', () {
    final course = bank(bankJson());
    expect(course.practices, hasLength(18));
    expect(course.practices.keys.toList(), ['prepare', for(var i=1;i<=16;i++) 'm${i.toString().padLeft(2,'0')}', 'return']);
    expect(course.forTarget('full-order'), isNull);
    expect(yangCourse().targets, hasLength(24));
    expect(() => course.practices.clear(), throwsUnsupportedError);
  });
  test('pending shared practice cannot offer movement or award written progress', () {
    final value = bankJson();
    for(final item in value['practices'] as List) {
      item['sourceReview']='pending'; item['sourceReviewReceiptId']=null;
    }
    for(final practice in bank(value).practices.values) {
      expect(practice.offersMovement, isFalse);
      expect(practice.verifiedTechnique, isFalse);
      expect(practice.progressEffect,0);
    }
  });
  test('cross-node/source, nonzero progress and unreceipted review are rejected', () {
    final wrongNode=bankJson(); (wrongNode['practices'] as List)[1]['lessonId']='prepare';
    expect(() => bank(wrongNode),throwsFormatException);
    final wrongSource=bankJson(); (wrongSource['practices'] as List)[0]['sourceIds']=['unbound'];
    expect(() => bank(wrongSource),throwsFormatException);
    final progress=bankJson(); (progress['practices'] as List)[0]['progressEffect']=1;
    expect(() => bank(progress),throwsFormatException);
    final noReceipt=bankJson(); (noReceipt['practices'] as List)[0]['sourceReview']='video_review';
    (noReceipt['practices'] as List)[0]['sourceReviewReceiptId']=null;
    expect(() => bank(noReceipt),throwsFormatException);
  });
  testWidgets('practice attempt is local and cannot call written or invalidate callbacks',(t) async {
    var written=0,invalidated=0;
    await mountPractice(t,practice:reviewedPrepare(),written:()=>written++,invalidate:()=>invalidated++);
    await yangTap(t,'self-guided-attempt-attempted');
    expect(attemptGroup(t).groupValue,PracticeAttempt.attempted);
    expect(written,0);expect(invalidated,0);
  });
  testWidgets('stop invalidates retained callback and blocks harder retry in this visit',(t) async {
    await mountPractice(t,practice:reviewedPrepare());
    final retained=attemptGroup(t).onChanged;
    await yangTap(t,'self-guided-attempt-stopped');
    retained(PracticeAttempt.attempted);await t.pump();
    expect(attemptGroup(t).groupValue,PracticeAttempt.stopped);
    expect(t.widget<RadioListTile<PracticeAttempt>>(
      find.byKey(const Key('self-guided-attempt-attempted'))).enabled,isFalse);
    expect(attemptGroup(t).groupValue,PracticeAttempt.stopped);
  });
  testWidgets('interruption invalidates prior practice callback',(t) async {
    await mountPractice(t,practice:reviewedPrepare());
    final retained=attemptGroup(t).onChanged;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);await t.pump();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);await t.pump();
    retained(PracticeAttempt.attempted);await t.pump();
    await yangShow(t,'self-guided-attempt-attempted');
    expect(attemptGroup(t).groupValue,PracticeAttempt.unrecorded);
  });
  testWidgets('dynamic admission revocation rejects retained practice callback',(t) async {
    var allowed=true;
    await mountPractice(t,practice:reviewedPrepare(),admitted:()=>allowed);
    final retained=attemptGroup(t).onChanged;allowed=false;
    retained(PracticeAttempt.attempted);await t.pump();
    expect(attemptGroup(t).groupValue,PracticeAttempt.unrecorded);
  });
  testWidgets('disposed target rejects retained callback without setState-after-dispose',(t) async {
    await mountPractice(t,practice:reviewedPrepare());
    final retained=attemptGroup(t).onChanged;
    await t.pumpWidget(const MaterialApp(home:SizedBox()));await t.pump();
    retained(PracticeAttempt.attempted);await t.pump();
    expect(t.takeException(),isNull);
  });
  test('actual preparation bank has bounded reviewed movement without legacy mastery', () {
    for (final practice in bank(bankJson()).practices.values) {
      expect(practice.sourceReview, PracticeSourceReview.videoSegments);
      expect(practice.sourceReviewReceiptId, isNotNull);
      expect(practice.offersMovement, isTrue);
      expect(practice.verifiedTechnique, isFalse);
      expect(practice.progressEffect, 0);
    }
  });

}
