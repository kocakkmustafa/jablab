import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/yang16_written_course_page.dart';

import 'yang16_test_support.dart';

void main() {
  for (final language in ['tr','en']) {
    for (final scale in [1.0,2.2]) {
      testWidgets('all24 original $language targets preserve hidden keys and same-target correction at scale$scale', (t) async {
        t.platformDispatcher.localeTestValue = Locale(language);
        addTearDown(t.platformDispatcher.clearLocaleTestValue);
        await t.binding.setSurfaceSize(const Size(360,800));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final semantics = t.ensureSemantics();
        final course = yangCourse();
        try {
          for (final target in course.targets) {
            var reports = 0, invalidations = 0;
            await t.pumpWidget(MaterialApp(key: ValueKey('${target.id}-$scale'),
              builder: (context, child) => MediaQuery(data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)), child: child!),
              home: Yang16WrittenTargetPage(course: course, target: target,
                admitted: () => true, priorWritten: () => true,
                onWritten: () { reports++; }, onInvalidate: () { invalidations++; }, onReset: () {})));
            await t.pumpAndSettle();
            await yangExact(t, 'yang16-target-title', target.title, language);
            for (var i = 0; i < target.reading.length; i++) {
              await yangExact(t, 'yang16-reading-$i', target.reading[i], language);
            }
            if (target.isFinal) {
              for (var i = 0; i < course.reading.length; i++) {
                await yangExact(t, 'yang16-final-reading-$i', course.reading[i], language);
              }
            }
            for (final boundary in course.boundariesFor(target)) {
              await yangExact(t, 'yang16-${boundary.id}-link', boundary.link, language);
              await yangExact(t, 'yang16-${boundary.id}-limit', boundary.limit, language);
            }
            await yangExact(t, 'yang16-original-prompt', target.prompt, language);
            for (final option in target.options) {
              await yangShow(t, 'yang16-original-option-${option.id}');
              expect(t.widget<Text>(find.byKey(Key('yang16-original-option-${option.id}'))).data,
                '${option.id}: ${yangText(option.text, language)}');
            }
            expect(yangHasChildKey(t, 'yang16-full-answer-key'), isFalse);
            expect(yangHasChildKey(t, 'yang16-answer-explanation'), isFalse);
            expect(yangHasChildKey(t, 'yang16-target-completion-rule'), isFalse);
            expect(yangHasChildKey(t, 'yang16-authored-correction'), isFalse);
            expect(yangHasChildKey(t, 'yang16-fact-0'), isFalse);
            expect(yangHasChildKey(t, 'yang16-open-supplement'), isFalse);
            await yangDisabled(t, 'yang16-compare-answer');
            await yangTap(t, 'yang16-toggle-reading');
            for (final letter in ['a','B','a)','B.','   ']) {
              await yangWrite(t, 'yang16-own-answer', letter);
              await yangDisabled(t, 'yang16-compare-answer');
            }
            await yangWrite(t, 'yang16-own-answer', 'My own incomplete reconstruction.');
            await yangTap(t, 'yang16-compare-answer');
            await yangExact(t, 'yang16-full-answer-key', target.answer, language);
            if (target.initialExplanation != null) {
              await yangExact(t, 'yang16-answer-explanation', target.initialExplanation!, language);
            }
            await yangDisabled(t, 'yang16-report-written');
            await yangTap(t, 'yang16-needs-correction');
            await yangExact(t, 'yang16-authored-correction', target.correction, language);
            await yangDisabled(t, 'yang16-start-retest');
            await yangWrite(t, 'yang16-own-correction', yangText(target.correction, language));
            await yangTap(t, 'yang16-start-retest');
            for (final key in ['yang16-full-answer-key','yang16-authored-correction',
              'yang16-fact-0','yang16-open-supplement','yang16-answer-explanation',
              'yang16-target-completion-rule']) {
              expect(yangHasChildKey(t, key), isFalse, reason: 'Independent retest hides $key');
              expect(find.byKey(Key(key), skipOffstage:false), findsNothing);
            }
            expect(yangHasChildKey(t, 'yang16-reading-0'), isFalse);
            expect(yangHasChildKey(t, 'yang16-final-reading-0'), isFalse);
            await yangExact(t, 'yang16-original-prompt', target.prompt, language);
            if (target.responseRequirement != null) {
              await yangExact(t, 'yang16-retest-response-requirement', target.responseRequirement!, language);
            }
            await yangExact(t, 'yang16-same-conditions', course.conditions, language);
            for (final option in target.options) {
              await yangShow(t, 'yang16-original-option-${option.id}');
              expect(t.widget<Text>(find.byKey(Key('yang16-original-option-${option.id}'))).data,
                '${option.id}: ${yangText(option.text, language)}');
            }
            await yangDisabled(t, 'yang16-compare-answer');
            await yangWrite(t, 'yang16-retest-answer', yangText(target.answer, language));
            await yangTap(t, 'yang16-compare-answer');
            await yangExact(t, 'yang16-full-answer-key', target.answer, language);
            if (target.retestExplanation != null) {
              await yangExact(t, 'yang16-answer-explanation', target.retestExplanation!, language);
            }
            for (var i = 0; i < target.facts.length; i++) {
              await yangShow(t, 'yang16-fact-$i');
              expect((t.widget<CheckboxListTile>(find.byKey(Key('yang16-fact-$i'))).title as Text).data,
                yangText(target.facts[i], language));
              await yangDisabled(t, 'yang16-report-written');
              await yangTap(t, 'yang16-fact-$i');
            }
            expect(reports, 0, reason: 'Showing/checking every fact is not a report');
            await yangTap(t, 'yang16-report-written');
            expect(reports, 1);
            await yangExact(t, 'yang16-target-completion-rule', target.completion, language);
            await yangTap(t, 'yang16-open-supplement');
            await yangExact(t, 'yang16-supplement-prompt', target.supplementPrompt, language);
            expect(yangHasChildKey(t, 'yang16-supplement-key'), isFalse);
            await yangDisabled(t, 'yang16-compare-supplement');
            await yangWrite(t, 'yang16-supplement-answer', yangText(target.supplementAnswer, language));
            await yangTap(t, 'yang16-compare-supplement');
            await yangExact(t, 'yang16-supplement-key', target.supplementAnswer, language);
            if (target.supplementExplanation != null) {
              await yangExact(t, 'yang16-supplement-explanation', target.supplementExplanation!, language);
            }
            expect(reports, 1, reason: 'Optional answer cannot replace or add a target');
            await yangWrite(t, 'yang16-retest-answer', 'Changed: an unresolved original fact.');
            expect(yangHasChildKey(t, 'yang16-full-answer-key'), isFalse);
            expect(yangHasChildKey(t, 'yang16-open-supplement'), isFalse);
            await yangDisabled(t, 'yang16-report-written');
            expect(invalidations, greaterThan(0));
            expect(course.physicalPracticeAvailable, isFalse);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox.shrink()); await t.pump();
          }
        } finally { semantics.dispose(); }
      });
    }
  }

  testWidgets('unchecking a fact, re-comparing and retrying cannot reuse an earlier full comparison', (t) async {
    await yangOpen(t); final target = yangCourse().targets.first;
    await yangTap(t, 'yang16-target-${target.id}');
    await yangPrepare(t, target, correction:true);
    await yangTap(t, 'yang16-fact-0');
    await yangDisabled(t, 'yang16-report-written');
    await yangTap(t, 'yang16-fact-0');
    await yangTap(t, 'yang16-compare-answer');
    await yangDisabled(t, 'yang16-report-written');
    await yangTap(t, 'yang16-start-retest');
    expect(yangHasChildKey(t, 'yang16-full-answer-key'), isFalse);
    await yangShow(t, 'yang16-retest-answer');
    expect(t.widget<TextField>(find.byKey(const Key('yang16-retest-answer'))).controller!.text, isEmpty);
    await yangDisabled(t, 'yang16-compare-answer');
    await t.pageBack(); await t.pumpAndSettle();
    await yangProgress(t, 0);
  });
}
