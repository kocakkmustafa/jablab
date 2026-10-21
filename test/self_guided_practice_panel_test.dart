import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/self_guided_practice.dart';
import 'package:jablab/app/self_guided_practice_panel.dart';

import 'localization_fixture.dart';
import 'self_guided_practice_test.dart' show practiceFixture;

void main() {
  for (final language in ['tr', 'en']) {
    testWidgets('pending source keeps safety/adaptation visible, movement hidden ($language)', (t) async {
      final practice = SelfGuidedPractice.decode(practiceFixture(mode: 'small_range_non_contact'));
      var changes = 0;
      await t.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        localeListResolutionCallback: resolveTestLocales,
        home: Scaffold(body: ListView(children: [SelfGuidedPracticePanel(
          practice: practice, attempt: PracticeAttempt.unrecorded,
          admitted: () => true, onChanged: (_) { changes++; },
        )])),
      ));
      await settleTestLocalizations(t);
      expect(find.byKey(const Key('self-guided-task')), findsNothing);
      expect(find.byKey(const Key('self-guided-safety')), findsOneWidget);
      expect(find.byKey(const Key('self-guided-adaptation')), findsOneWidget);
      final attempted = t.widget<RadioListTile<PracticeAttempt>>(
        find.byKey(const Key('self-guided-attempt-attempted')),
      );
      expect(attempted.enabled, isFalse);
      expect(changes, 0);
    });

    testWidgets('real interaction records distinct session reports and late admission is rejected ($language)', (t) async {
      var attempt = PracticeAttempt.unrecorded;
      var admitted = true;
      var changes = 0;
      final practice = SelfGuidedPractice.decode(practiceFixture(
        review: 'video_review', receipt: 'synthetic-widget-fixture-only',
        mode: 'small_range_non_contact',
      ));
      await t.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        localeListResolutionCallback: resolveTestLocales,
        home: Scaffold(body: StatefulBuilder(builder: (context, update) => ListView(
          children: [SelfGuidedPracticePanel(
            practice: practice, attempt: attempt, admitted: () => admitted,
            onChanged: (value) { update(() { attempt = value; changes++; }); },
          )],
        ))),
      ));
      await settleTestLocalizations(t);
      for (final value in [PracticeAttempt.attempted, PracticeAttempt.skipped]) {
        final control = find.byKey(Key('self-guided-attempt-${value.name}'));
        await t.ensureVisible(control);
        await t.tap(control);
        await t.pumpAndSettle();
        expect(attempt, value);
      }
      expect(changes, 2);
      final oldGroup = t.widget<RadioGroup<PracticeAttempt>>(find.byType(RadioGroup<PracticeAttempt>));
      admitted = false;
      oldGroup.onChanged(PracticeAttempt.attempted);
      await t.pump();
      expect(changes, 2);
      expect(attempt, PracticeAttempt.skipped);
      admitted = true;
      final uncertain = find.byKey(const Key('self-guided-attempt-uncertain'));
      await t.ensureVisible(uncertain);
      await t.tap(uncertain);
      await t.pumpAndSettle();
      expect(changes, 3);
      expect(attempt, PracticeAttempt.uncertain);
      final endedGroup = t.widget<RadioGroup<PracticeAttempt>>(find.byType(RadioGroup<PracticeAttempt>));
      endedGroup.onChanged(PracticeAttempt.attempted);
      await t.pump();
      expect(changes, 3);
      expect(t.widget<RadioListTile<PracticeAttempt>>(
        find.byKey(const Key('self-guided-attempt-attempted')),
      ).enabled, isFalse);
      expect(practice.progressEffect, 0);
      expect(practice.verifiedTechnique, isFalse);
    });
  }
}
