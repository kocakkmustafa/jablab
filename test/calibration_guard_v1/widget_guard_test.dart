// Synthetic calibration-admission protocol using actual engine and owned camera wire; no physical or production camera admission.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/rehearse_material.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/skeleton_overlay.dart';
import 'package:jablab/app/teach_material.dart';
import 'package:jablab/app/ui_language.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';

import '../localization_fixture.dart';
import 'guard_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(LiveJabController.debugResetCameraLock);
  late Map<String, dynamic> source;
  setUpAll(() async {
    source = await loadRulesJson();
  });

  testWidgets(
    'WG-01 pending B-kal stays invisible in actual SessionScreen while count ready and skeleton render',
    (tester) async {
      final f = await openLive(tester, rulesVariant(source));
      expect(find.byKey(const Key('event-count')), findsNothing);
      await emitWidgetFrames(
        tester,
        f,
        jabFrames(raiseRearGuard: true),
        requireFirstFrameReady: true,
      );
      expectFirstIssue(f, 'ELBOW_FLARED', 'B-kal');
      expectBlocked(f);
      expect(find.text(calibrationReason), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('event-count'))).data,
        '1',
      );
      expect(find.byKey(const Key('skeleton-overlay')), findsOneWidget);
      final preview = tester.widget<SkeletonPreview>(
        find.byType(SkeletonPreview),
      );
      expect(preview.analysisRunning, isTrue);
      expect(preview.skeleton, hasLength(Lm.count));
      expect(
        f.runs.where((state) => state.narration == readyMarker),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'WG-02 Turkish guard reason uses the exact new source pair in the live no-call slot',
    (tester) async {
      final f = await openLive(
        tester,
        rulesVariant(source),
        locale: const Locale('tr'),
      );
      await emitWidgetFrames(tester, f, jabFrames());
      expectFirstIssue(f, 'REAR_HAND_LOW', 'B');
      expect(find.byKey(const Key('live-no-verdict')), findsOneWidget);
      expect(find.text(calibrationReasonTr), findsOneWidget);
      expect(find.text(calibrationReason), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('event-count'))).data,
        '1',
      );
      expect(find.byKey(const Key('live-clean')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'WG-03 an actually empty judgeable raw issue frame never becomes Keep going in the UI',
    (tester) async {
      final f = await openLive(tester, rulesVariant(source));
      await emitWidgetFrames(tester, f, steadyFrames());
      expect(
        f.raw.samples.any(
          (sample) =>
              sample.output != null &&
              sample.output!.judgeable &&
              sample.output!.issues.isEmpty,
        ),
        isTrue,
      );
      expect(find.text(calibrationReason), findsOneWidget);
      expect(find.byKey(const Key('live-clean')), findsNothing);
      expect(find.byKey(const Key('live-cue')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('event-count'))).data,
        '0',
      );
      expect(find.byKey(const Key('skeleton-overlay')), findsOneWidget);
    },
  );

  testWidgets(
    'WG-04 an armed raw completion-code-change never paints corrected under the pending guard',
    (tester) async {
      final rules = rulesVariant(source);
      final frames = correctedOpportunityFrames(rules);
      final f = await openLive(tester, rules);
      await emitWidgetFrames(tester, f, frames, rearm: true);
      expectRawCorrectedOpportunity(f);
      expectBlocked(f);
      expect(find.text(correctedMarker), findsNothing);
      expect(find.text(calibrationReason), findsOneWidget);
      expect(f.runs.last.completedCount, greaterThanOrEqualTo(2));
    },
  );

  testWidgets(
    'WG-05 visibility no-call replaces the calibration sentence without losing completed count',
    (tester) async {
      final f = await openLive(tester, rulesVariant(source));
      final frames = jabFrames();
      await emitWidgetFrames(tester, f, frames);
      expect(find.text(calibrationReason), findsOneWidget);
      final low = hideLandmark(
        frames.last.copyWith(tUs: frames.last.tUs + fixtureStepUs),
        Lm.leftWrist,
        0.2,
      );
      await tester.runAsync(() => f.emit(low));
      await tester.pump();
      expect(find.text(calibrationReason), findsNothing);
      expect(find.text('visibility:LOW_TRACKING_CONFIDENCE'), findsOneWidget);
      expect(find.byKey(const Key('live-no-verdict')), findsOneWidget);
      expect(find.byKey(const Key('live-clean')), findsNothing);
      expect(find.byKey(const Key('live-cue')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('event-count'))).data,
        '1',
      );
      expect(f.runs.last.phase, isNull);
    },
  );

  testWidgets(
    'WG-06 denied setup shows its actual failure without zero count calibration reason or skeleton',
    (tester) async {
      final f = await openLive(
        tester,
        rulesVariant(source),
        permission: () async => false,
        expectCapture: false,
      );
      expect(f.camera.startCalls, 0);
      expect(f.runs, isEmpty);
      expect(find.byKey(const Key('event-count')), findsNothing);
      expect(find.byKey(const Key('skeleton-overlay')), findsNothing);
      expect(find.text(calibrationReason), findsNothing);
      expect(
        find.text(
          'We need the camera to watch your jab. Nothing is analysed without it — the round clock still runs.',
        ),
        findsOneWidget,
      );
      expect(f.cues.keyCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'WG-07 lifecycle retirement removes the stale guard state ignores old frames and does not restart',
    (tester) async {
      final f = await openLive(tester, rulesVariant(source));
      await emitWidgetFrames(tester, f, jabFrames());
      expect(find.text(calibrationReason), findsOneWidget);
      expect(f.runs.last.completedCount, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      for (var turn = 0; turn < 12; turn++) {
        await tester.pump();
        await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
      }
      expect(f.camera.stopCalls, 1);
      expect(f.camera.activeListeners, 0);
      expect(f.controller.hasNativeSession, isFalse);
      expect(find.byKey(const Key('event-count')), findsNothing);
      expect(find.text(calibrationReason), findsNothing);
      expect(find.byKey(const Key('skeleton-overlay')), findsNothing);
      final statesAtRetirement = f.seen.length;
      await tester.runAsync(() => f.emit(jabFrames(offsetUs: 1000000).first));
      await tester.pump();
      expect(f.seen.length, statesAtRetirement);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(f.camera.startCalls, 1);
      expect(find.text(correctedMarker), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'WG-08 guard keeps the observed event count through the real summary handoff',
    (tester) async {
      final f = await openLive(tester, rulesVariant(source));
      await emitWidgetFrames(tester, f, jabFrames());
      expect(f.runs.last.completedCount, 1);
      expect(find.text(calibrationReason), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('advance-button')));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await _settleWidgetRoute(tester);
      expect(find.byKey(const Key('summary-count')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('summary-count'))).data,
        '1',
      );
      expect(find.byKey(const Key('live-cue')), findsNothing);
      expect(find.text(correctedMarker), findsNothing);
      expect(tester.takeException(), isNull);
      // Existing tempo summary is deliberately outside this guard's contract.
    },
  );
}

Future<GuardFixture> openLive(
  WidgetTester tester,
  RuleSet rules, {
  Locale locale = const Locale('en'),
  Future<bool> Function()? permission,
  bool expectCapture = true,
}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  tester.binding.platformDispatcher.localesTestValue = [locale];
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.binding.platformDispatcher.clearLocalesTestValue();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  final fixture = GuardFixture(rules, permission: permission);
  addTearDown(() => closeWidgetFixture(tester, fixture));
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('tr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SessionScreen(
        lesson: const ShellLesson(
          id: 'guard.synthetic.jab',
          title: 'Synthetic guard fixture',
          minutes: 3,
        ),
        cues: fixture.cues,
        coachedNotScored: const [],
        bands: const {'Stance': '—'},
        plan: null,
        teachMaterial: const TeachMaterialText(body: 'Synthetic fixture only.'),
        rehearseMaterial: const RehearseMaterialNone(
          reason: 'Synthetic fixture only.',
        ),
        liveJab: fixture.controller,
      ),
    ),
  );
  await settleTestLocalizations(tester, expectedLocale: locale);
  await _settleWidgetRoute(tester);
  for (var stage = 0; stage < 2; stage++) {
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('advance-button')));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
  }
  if (expectCapture) {
    for (
      var turn = 0;
      turn < 20 && fixture.camera.activeListeners == 0;
      turn++
    ) {
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(fixture.camera.startCalls, 1);
    expect(fixture.camera.activeListeners, 1);
  }
  return fixture;
}

Future<void> emitWidgetFrames(
  WidgetTester tester,
  GuardFixture fixture,
  Iterable<PoseFrame> frames, {
  bool rearm = false,
  bool requireFirstFrameReady = false,
}) async {
  var inspected = 0;
  var readyRenderedFrames = 0;
  for (final frame in frames) {
    final accepted = await tester.runAsync(
      () => fixture.emit(frame, rearm: rearm),
    );
    await tester.pump();
    if (requireFirstFrameReady) {
      expect(
        accepted,
        isNotNull,
        reason: 'Ready rendering requires an actual accepted frame',
      );
      if (inspected == 0) {
        expect(accepted!.narration, readyMarker);
        final slot = find.byKey(const Key('live-narration'));
        expect(slot, findsOneWidget);
        expect(tester.widget<Text>(slot).data, readyMarker);
        expect(find.text(readyMarker), findsOneWidget);
        readyRenderedFrames++;
      } else {
        expect(accepted!.narration, isNot(readyMarker));
        expect(
          find.text(readyMarker),
          findsNothing,
          reason: 'Ready must not replay on later frames',
        );
      }
    }
    inspected++;
    // Inspect EVERY frame's actual widget; final-frame absence alone can miss
    // a technical/corrected cue briefly drawn earlier in the same attempt.
    expect(find.byKey(const Key('live-cue')), findsNothing);
    expect(find.byKey(const Key('live-clean')), findsNothing);
    expect(find.text(correctedMarker), findsNothing);
    expect(tester.takeException(), isNull);
  }
  expect(inspected, greaterThan(0));
  if (requireFirstFrameReady) {
    expect(readyRenderedFrames, 1);
  }
}

// Bounded owned-close drain copied from the existing second-pass widget
// fixture. These waits synchronize synthetic messenger queues, not physical
// observation, FPS, maximum gap or training-safety thresholds.
Future<void> closeWidgetFixture(
  WidgetTester tester,
  GuardFixture fixture,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  var settled = false;
  Object? error;
  StackTrace? stack;
  fixture
      .close()
      .then<void>(
        (_) => settled = true,
        onError: (Object e, StackTrace s) {
          error = e;
          stack = s;
          settled = true;
        },
      )
      .ignore();
  for (var i = 0; i < 80 && !settled; i++) {
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  expect(
    settled,
    isTrue,
    reason: 'Owned synthetic capture must finish closing',
  );
  if (error != null) {
    Error.throwWithStackTrace(error!, stack!);
  }
}

// Positional SDK arguments; bounded route synchronization, not physical timing.
Future<void> _settleWidgetRoute(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}
