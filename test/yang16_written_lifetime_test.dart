import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/yang16_written_course.dart';
import 'package:jablab/app/yang16_written_course_page.dart';
import 'package:motion_content/motion_content.dart';

import 'yang16_test_support.dart';

// Read the real overview's supplied children while its target route is current.
// Lazy/offstage mounting must not conceal a stale endpoint or count.
Widget? _overviewChild(WidgetTester t, String key) {
  final overview = t.widget<ListView>(find.byKey(const Key('yang16-course-list'),skipOffstage:false));
  final children = (overview.childrenDelegate as SliverChildListDelegate).children;
  for (final child in children) { if (child.key == Key(key)) return child; }
  return null;
}
void _overviewProgress(WidgetTester t, int count, {required bool complete}) {
  expect((_overviewChild(t,'yang16-written-progress') as Text).data,contains('$count/24'));
  expect(_overviewChild(t,'yang16-written-completion'),complete ? isNotNull : isNull);
}
Future<void> _freshFacts(WidgetTester t, int count) async {
  for (var i = 0; i < count; i++) {
    await yangShow(t,'yang16-fact-$i');
    expect(t.widget<CheckboxListTile>(find.byKey(Key('yang16-fact-$i'))).value,isFalse);
  }
}

void main() {
  for (final correction in [false,true]) {
    testWidgets('post-report ${correction ? "same-target retest" : "initial"} Compare withdraws progress and supplement; fresh facts and report are required', (t) async {
      await yangOpen(t); final target = yangCourse().targets.first;
      await yangTap(t,'yang16-target-${target.id}'); await yangPrepare(t,target,correction:correction);
      await yangShow(t,'yang16-report-written');
      final staleReport = t.widget<TextButton>(find.byKey(const Key('yang16-report-written'))).onPressed!;
      await yangTap(t,'yang16-report-written'); _overviewProgress(t,1,complete:false);
      await yangTap(t,'yang16-open-supplement');
      await yangWrite(t,'yang16-supplement-answer',target.supplementAnswer.en);
      await yangShow(t,'yang16-supplement-answer');
      final oldSupplement = t.widget<TextField>(find.byKey(const Key('yang16-supplement-answer'))).controller!;
      await yangShow(t,'yang16-compare-supplement');
      final staleSupplement = t.widget<TextButton>(find.byKey(const Key('yang16-compare-supplement'))).onPressed!;
      await yangTap(t,'yang16-compare-supplement');
      expect(yangHasChildKey(t,'yang16-supplement-key'),isTrue);
      await yangTap(t,'yang16-compare-answer');
      _overviewProgress(t,0,complete:false); expect(oldSupplement.text,isEmpty);
      staleReport(); staleSupplement(); await t.pumpAndSettle();
      for (final key in ['yang16-target-completion-rule','yang16-open-supplement',
        'yang16-supplement-prompt','yang16-supplement-answer','yang16-supplement-key']) {
        expect(yangHasChildKey(t,key),isFalse);
      }
      await _freshFacts(t,target.facts.length); await yangDisabled(t,'yang16-report-written');
      for (var i = 0; i < target.facts.length; i++) {
        await yangTap(t,'yang16-fact-$i'); _overviewProgress(t,0,complete:false);
        if (i < target.facts.length - 1) { await yangDisabled(t,'yang16-report-written'); }
      }
      expect(yangHasChildKey(t,'yang16-target-completion-rule'),isFalse);
      await yangTap(t,'yang16-report-written'); _overviewProgress(t,1,complete:false);
      expect(yangHasChildKey(t,'yang16-target-completion-rule'),isTrue);
      await t.pageBack(); await t.pumpAndSettle(); await yangProgress(t,1);
      expect(t.takeException(),isNull);
    });
  }

  for (final language in ['tr','en']) {
    testWidgets('post-report 24/24 endpoint $language retracts on Compare and returns only after fresh facts plus a fresh report', (t) async {
      t.platformDispatcher.localeTestValue = Locale(language);
      addTearDown(t.platformDispatcher.clearLocaleTestValue);
      await yangOpen(t,scale:2.2); final course = yangCourse();
      for (final target in course.targets.take(23)) {
        await yangTap(t,'yang16-target-${target.id}'); await yangPrepare(t,target,language:language);
        await yangTap(t,'yang16-report-written'); await t.pageBack(); await t.pumpAndSettle();
      }
      await yangProgress(t,23);
      final last = course.targets.last;
      await yangTap(t,'yang16-target-${last.id}'); await yangPrepare(t,last,language:language,correction:true);
      await yangShow(t,'yang16-report-written');
      final staleReport = t.widget<TextButton>(find.byKey(const Key('yang16-report-written'))).onPressed!;
      await yangTap(t,'yang16-report-written'); _overviewProgress(t,24,complete:true);
      await yangTap(t,'yang16-compare-answer');
      _overviewProgress(t,23,complete:false); staleReport(); await t.pumpAndSettle();
      expect(yangHasChildKey(t,'yang16-target-completion-rule'),isFalse);
      expect(yangHasChildKey(t,'yang16-open-supplement'),isFalse);
      await _freshFacts(t,last.facts.length); await yangDisabled(t,'yang16-report-written');
      for (var i = 0; i < last.facts.length; i++) {
        await yangTap(t,'yang16-fact-$i'); _overviewProgress(t,23,complete:false);
        if (i < last.facts.length - 1) { await yangDisabled(t,'yang16-report-written'); }
      }
      _overviewProgress(t,23,complete:false);
      await yangTap(t,'yang16-report-written'); _overviewProgress(t,24,complete:true);
      await t.pageBack(); await t.pumpAndSettle(); await yangProgress(t,24);
      await yangShow(t,'yang16-written-completion');
      expect(t.widget<Text>(find.byKey(const Key('yang16-written-completion'))).data,
        contains(language == 'tr' ? 'Fiziksel tamamlanma veya ustalık doğrulanmaz'
          : 'does not establish physical completion or mastery'));
      expect(t.takeException(),isNull);
    });
  }

  for (final language in ['tr','en']) {
    testWidgets('all24 $language targets alone reach the honest per-visit written endpoint', (t) async {
      t.platformDispatcher.localeTestValue = Locale(language);
      addTearDown(t.platformDispatcher.clearLocaleTestValue);
      await yangOpen(t, scale:2.2); final course = yangCourse();
      for (var i = 0; i < course.reading.length; i++) {
        await yangExact(t, 'yang16-overview-reading-$i', course.reading[i], language);
      }
      await yangProgress(t, 0);
      for (var i = 0; i < 24; i++) {
        final target = course.targets[i];
        await yangTap(t, 'yang16-target-${target.id}');
        await yangPrepare(t, target, language:language, correction:i.isOdd);
        await yangTap(t, 'yang16-report-written');
        await t.pageBack(); await t.pumpAndSettle();
        await yangProgress(t, i + 1);
        if (i < 23) { expect(find.byKey(const Key('yang16-written-completion')), findsNothing); }
      }
      await yangShow(t, 'yang16-written-completion');
      expect(t.widget<Text>(find.byKey(const Key('yang16-written-completion'))).data,
        contains(language == 'tr' ? 'Fiziksel tamamlanma veya ustalık doğrulanmaz'
          : 'does not establish physical completion or mastery'));
      expect(course.reviewReadiness.values, everyElement(isFalse));
      await t.pageBack(); await t.pumpAndSettle();
      await t.tap(find.text('Open')); await t.pumpAndSettle();
      await yangProgress(t, 0);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('prior target gating and downstream invalidation preserve the complete24-target order', (t) async {
    await yangOpen(t); final course = yangCourse();
    for (final i in [1,18,23]) {
      final target = course.targets[i]; await yangTap(t, 'yang16-target-${target.id}');
      await yangPrepare(t, target);
      await yangDisabled(t, 'yang16-report-written');
      expect(yangHasChildKey(t, 'yang16-open-supplement'), isFalse);
      await t.pageBack(); await t.pumpAndSettle(); await yangProgress(t, 0);
    }
    for (final target in course.targets.take(3)) {
      await yangTap(t, 'yang16-target-${target.id}'); await yangPrepare(t, target);
      await yangTap(t, 'yang16-report-written'); await t.pageBack(); await t.pumpAndSettle();
    }
    await yangProgress(t, 3);
    await yangTap(t, 'yang16-target-m01'); await yangTap(t, 'yang16-toggle-reading');
    await yangWrite(t, 'yang16-own-answer', 'A changed unresolved account.');
    await t.pageBack(); await t.pumpAndSettle(); await yangProgress(t, 1);
    await yangTap(t, 'yang16-target-prepare'); await yangTap(t, 'yang16-toggle-reading');
    await t.pageBack(); await t.pumpAndSettle(); await yangProgress(t, 0);
    expect(t.takeException(), isNull);
  });

  for (final interruption in ['stop','lifecycle']) {
    for (final phase in ['draft','initial-key','correction','retest-draft','retest-key',
      'partial-facts','full-facts','reported','supplement-draft','supplement-key']) {
      testWidgets('$interruption at $phase clears own text, key, facts and all progress; stale actions stay blocked', (t) async {
        await yangOpen(t); final target = yangCourse().targets.first;
        await yangTap(t, 'yang16-target-${target.id}'); await yangTap(t, 'yang16-toggle-reading');
        await yangWrite(t, 'yang16-own-answer', 'Independent but incomplete answer.');
        if (phase != 'draft') { await yangTap(t, 'yang16-compare-answer'); }
        if (!['draft','initial-key'].contains(phase)) {
          await yangTap(t, 'yang16-needs-correction');
          await yangWrite(t, 'yang16-own-correction', target.correction.en);
        }
        if (!['draft','initial-key','correction'].contains(phase)) {
          await yangTap(t, 'yang16-start-retest');
          await yangWrite(t, 'yang16-retest-answer', target.answer.en);
        }
        if (!['draft','initial-key','correction','retest-draft'].contains(phase)) {
          await yangTap(t, 'yang16-compare-answer');
        }
        if (phase == 'partial-facts') { await yangTap(t, 'yang16-fact-0'); }
        if (['full-facts','reported','supplement-draft','supplement-key'].contains(phase)) {
          for (var i = 0; i < target.facts.length; i++) { await yangTap(t, 'yang16-fact-$i'); }
        }
        if (['reported','supplement-draft','supplement-key'].contains(phase)) {
          await yangTap(t, 'yang16-report-written');
        }
        if (phase.startsWith('supplement')) {
          await yangTap(t, 'yang16-open-supplement');
          await yangWrite(t, 'yang16-supplement-answer', target.supplementAnswer.en);
          if (phase == 'supplement-key') { await yangTap(t, 'yang16-compare-supplement'); }
        }
        final stale = <VoidCallback>[];
        for (final key in ['yang16-compare-answer','yang16-start-retest','yang16-report-written',
          'yang16-compare-supplement']) {
          if (yangHasChildKey(t, key)) {
            await yangShow(t, key);
            final action = t.widget<TextButton>(find.byKey(Key(key))).onPressed;
            if (action != null) stale.add(action);
          }
        }
        if (interruption == 'stop') {
          await t.tap(find.byKey(const Key('yang16-stop-top'))); await t.pumpAndSettle();
        } else {
          yangPause(t); await t.pump();
          for (final action in stale) { action(); }
          await t.pump(); yangResume(t); await t.pumpAndSettle();
        }
        for (final action in stale) { action(); }
        await t.pumpAndSettle();
        for (final key in ['yang16-full-answer-key','yang16-answer-explanation',
          'yang16-target-completion-rule','yang16-authored-correction','yang16-fact-0',
          'yang16-retest-answer','yang16-open-supplement','yang16-supplement-key']) {
          expect(yangHasChildKey(t, key), isFalse);
        }
        await yangShow(t, 'yang16-own-answer');
        expect(t.widget<TextField>(find.byKey(const Key('yang16-own-answer'))).controller!.text, isEmpty);
        await yangDisabled(t, 'yang16-compare-answer');
        await yangDisabled(t, 'yang16-report-written');
        await t.pageBack(); await t.pumpAndSettle(); await yangProgress(t, 0);
        expect(t.takeException(), isNull);
      });
    }
  }

  for (final interruption in ['switch-owner','logout','guest-login','admission']) {
    testWidgets('$interruption retires both routes and rejects a retained ready-to-report callback', (t) async {
      final owner = ValueNotifier<String?>(interruption == 'guest-login' ? null : 'first');
      final admission = ValueNotifier<bool>(true);
      addTearDown(owner.dispose); addTearDown(admission.dispose);
      await yangOpen(t, owner:owner, admission:admission);
      await yangTap(t, 'yang16-target-prepare'); await yangPrepare(t, yangCourse().targets.first);
      await yangShow(t, 'yang16-report-written');
      final stale = t.widget<TextButton>(find.byKey(const Key('yang16-report-written'))).onPressed!;
      if (interruption == 'admission') { admission.value = false; }
      else { owner.value = interruption == 'logout' ? null : 'second'; }
      stale(); await t.pumpAndSettle(); stale(); await t.pumpAndSettle();
      expect(find.byType(Yang16WrittenCoursePage, skipOffstage:false), findsNothing);
      expect(find.byType(Yang16WrittenTargetPage, skipOffstage:false), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      if (interruption == 'admission') { admission.value = true; }
      await t.tap(find.text('Open')); await t.pumpAndSettle(); await yangProgress(t, 0);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('background completion is discarded and only a fresh foreground load can arrive', (t) async {
    final old = Completer<Yang16WrittenCourse>(), fresh = Completer<Yang16WrittenCourse>();
    var calls = 0;
    await yangOpen(t, loader:() => ++calls == 1 ? old.future : fresh.future);
    yangPause(t); old.complete(yangCourse()); await t.pump();
    expect(find.byKey(const Key('yang16-course-list')), findsNothing);
    yangResume(t); expect(calls, 2); fresh.complete(yangCourse()); await t.pumpAndSettle();
    await yangProgress(t, 0); expect(t.takeException(), isNull);
  });

  for (final late in ['success','error']) {
    testWidgets('a late $late cannot restore retired owner content or expose a retry', (t) async {
      final owner = ValueNotifier<String?>('first'); addTearDown(owner.dispose);
      final pending = Completer<Yang16WrittenCourse>();
      await yangOpen(t, owner:owner, loader:() => pending.future);
      owner.value = 'second'; await t.pump();
      if (late == 'success') { pending.complete(yangCourse()); }
      else { pending.completeError(StateError('late unavailable asset')); }
      await t.pumpAndSettle();
      expect(find.byType(Yang16WrittenCoursePage, skipOffstage:false), findsNothing);
      expect(find.byKey(const Key('yang16-retry')), findsNothing); expect(t.takeException(), isNull);
    });
  }

  testWidgets('owner retirement inside didPush cannot build the pending target', (t) async {
    final owner = ValueNotifier<String?>('first'); addTearDown(owner.dispose);
    final observer = YangPushObserver(); await yangOpen(t, owner:owner, observer:observer);
    observer.next = () { owner.value = 'second'; };
    await yangTap(t, 'yang16-target-prepare');
    expect(find.byType(Yang16WrittenCoursePage, skipOffstage:false), findsNothing);
    expect(find.byType(Yang16WrittenTargetPage, skipOffstage:false), findsNothing);
    expect(t.takeException(), isNull);
  });

  for (final replacement in ['owner-notifier','admission-notifier','loader']) {
    testWidgets('$replacement identity replacement retires existing routes and written state', (t) async {
      final firstOwner = ValueNotifier<String?>('same-owner');
      final newOwner = ValueNotifier<String?>('same-owner');
      final firstAdmission = ValueNotifier<bool>(true), newAdmission = ValueNotifier<bool>(true);
      for (final notifier in [firstOwner,newOwner]) { addTearDown(notifier.dispose); }
      for (final notifier in [firstAdmission,newAdmission]) { addTearDown(notifier.dispose); }
      Future<Yang16WrittenCourse> firstLoad() async => yangCourse();
      Future<Yang16WrittenCourse> newLoad() async => yangCourse();
      var replace = false;
      late StateSetter change;
      await t.pumpWidget(MaterialApp(home:Builder(builder:(context) => Scaffold(body:TextButton(
        child:const Text('Open'), onPressed:() => Navigator.of(context).push(MaterialPageRoute<void>(
          builder:(_) => StatefulBuilder(builder:(context,setState) {
            change = setState;
            return Yang16WrittenCoursePage(
              loader:replace && replacement == 'loader' ? newLoad : firstLoad,
              accountUserId:replace && replacement == 'owner-notifier' ? newOwner : firstOwner,
              resourceAdmission:replace && replacement == 'admission-notifier' ? newAdmission : firstAdmission);
          })),
        ),
      )))));
      await t.tap(find.text('Open')); await t.pumpAndSettle();
      await yangTap(t, 'yang16-target-prepare'); await yangPrepare(t, yangCourse().targets.first);
      await yangShow(t, 'yang16-report-written');
      final stale = t.widget<TextButton>(find.byKey(const Key('yang16-report-written'))).onPressed!;
      change(() { replace = true; }); await t.pump(); stale(); await t.pumpAndSettle();
      expect(find.byType(Yang16WrittenCoursePage,skipOffstage:false), findsNothing);
      expect(find.byType(Yang16WrittenTargetPage,skipOffstage:false), findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('transient retry is admitted, but integrity failure is terminal and never creates progress', (t) async {
    var calls = 0;
    await yangOpen(t, loader:() async {
      if (++calls == 1) throw const ContentException(ContentError(code:ContentErrorCode.timeout));
      return yangCourse();
    });
    await t.pumpAndSettle();
    expect(find.byKey(const Key('yang16-retry')), findsOneWidget);
    await t.tap(find.byKey(const Key('yang16-retry'))); await t.pumpAndSettle(); await yangProgress(t, 0);
    await t.pumpWidget(const SizedBox.shrink()); await t.pump();
    await yangOpen(t, loader:() async => throw const ContentException(
      ContentError(code:ContentErrorCode.hashMismatch)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('yang16-load-failure')), findsOneWidget);
    expect(find.byKey(const Key('yang16-retry')), findsNothing);
    expect(find.byKey(const Key('yang16-course-list')), findsNothing);
    expect(find.byKey(const Key('yang16-written-progress')), findsNothing);
    expect(t.takeException(), isNull);
  });
}
