// Synthetic calibration-admission protocol using actual engine and owned camera wire; no physical or production camera admission.
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/live_honesty.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/live_session_failure.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/shell_candidate/live_surface.dart' show LiveState;
import 'package:motion_core/motion_core.dart';

import 'guard_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(LiveJabController.debugResetCameraLock);
  late Map<String, dynamic> source;
  setUpAll(() async { source = await loadRulesJson(); });

  GuardFixture fixture({bool? pending, String? status, bool omitMetadata = false}) {
    final value = GuardFixture(rulesVariant(
      source, pending: pending, status: status, omitMetadata: omitMetadata,
    ));
    addTearDown(value.close);
    return value;
  }

  // Positive control uses the SAME frame list through the real owned wire,
  // controller and second actual engine, then fully closes before loss replay.
  // No test-owned capture overlaps and no physical/FPS acceptance is implied.
  Future<void> expectUninterruptedTrajectoryCompletes(List<PoseFrame> frames) async {
    final control = fixture();
    try {
      expect(await control.start(), isNull);
      await control.emitAll(frames);
      final completed = control.raw.samples.where((sample) =>
          sample.output?.completedAttempt?.completed ?? false).toList();
      expect(completed, hasLength(1),
          reason: 'The same uninterrupted trajectory must actually complete');
      expect(control.raw.count, 1);
      expect(control.runs.last.completedCount, 1);
      expectBlocked(control);
    } finally {
      await control.close();
    }
  }

  // GUARD_READY alone is not an interrupted movement. Require an actual
  // nonterminal movement phase from the existing jab asset before injecting loss.
  void expectPartialMovementBeforeLoss(GuardFixture value, PoseFrame lossFrame) {
    expect(value.raw.samples, isNotEmpty,
        reason: 'Loss requires an actual accepted pre-loss raw sample');
    final beforeLoss = value.raw.samples.last;
    expect(beforeLoss.tUs, lessThan(lossFrame.tUs));
    expect(beforeLoss.output, isNotNull);
    final output = beforeLoss.output!;
    expect(output.judgeable, isTrue);
    expect(output.activePhase,
        isIn(const ['EXTENSION', 'PEAK', 'RETRACTION']),
        reason: 'A waiting GUARD_READY or absent phase cannot witness partial loss');
    expect(output.completedAttempt?.completed ?? false, isFalse);
    expect(beforeLoss.completedCount, 0);
    expect(beforeLoss.state.completedCount, 0);
    expect(beforeLoss.state.phase, output.activePhase);
  }

  test('CG-01 pending raw A first issue is suppressed with an actual raw witness', () async {
    final f = fixture();
    expect(f.rules.calibrationPending, isTrue);
    expect(await f.start(), isNull);
    await f.emitAll(steadyFrames());
    expectFirstIssue(f, 'STANCE_TOO_NARROW', 'A');
    expectBlocked(f);
    expect(f.runs.last.completedCount, 0);
  });

  test('CG-02 pending raw B first issue is suppressed while a jab still completes', () async {
    final f = fixture();
    expect(await f.start(), isNull);
    await f.emitAll(jabFrames());
    expectFirstIssue(f, 'REAR_HAND_LOW', 'B');
    expectBlocked(f);
    expect(f.runs.last.completedCount, 1);
    expect(f.raw.count, 1);
  });

  test('CG-03 pending raw B-kal first issue is suppressed rather than hidden behind a B union', () async {
    final f = fixture();
    expect(await f.start(), isNull);
    await f.emitAll(jabFrames(raiseRearGuard: true));
    expectFirstIssue(f, 'ELBOW_FLARED', 'B-kal');
    expectBlocked(f);
    expect(f.runs.last.completedCount, 1);
  });

  test('CG-04 pending false with raw threshold status still cannot emit technique or clean', () async {
    final f = fixture(pending: false, status: 'raw-signal-pending-revision');
    expect(f.rules.publishBlockers(), contains('thresholdStatus=raw-signal-pending-revision'));
    expect(await f.start(), isNull);
    await f.emitAll(jabFrames(raiseRearGuard: true));
    expectFirstIssue(f, 'ELBOW_FLARED', 'B-kal');
    expectBlocked(f);
    expect(f.runs.last.completedCount, 1);
  });

  test('CG-05 a calibrated label with pending true is contradictory metadata and stays blocked', () async {
    final f = fixture(pending: true, status: 'calibrated');
    expect(f.rules.publishBlockers(), contains('calibrationPending'));
    expect(await f.start(), isNull);
    await f.emitAll(jabFrames());
    expectFirstIssue(f, 'REAR_HAND_LOW', 'B');
    expectBlocked(f);
    expect(f.runs.last.completedCount, 1);
  });

  test('CG-06 missing calibration metadata uses real RuleSet fail-closed defaults', () async {
    final f = fixture(omitMetadata: true);
    expect(f.rules.calibrationPending, isTrue);
    expect(f.rules.thresholdStatus, 'unknown');
    expect(await f.start(), isNull);
    await f.emitAll(jabFrames());
    expectFirstIssue(f, 'REAR_HAND_LOW', 'B');
    expectBlocked(f);
  });

  test('CG-07 judgeable empty raw issues are calibration no-call rather than a clean verdict', () async {
    final f = fixture();
    expect(await f.start(), isNull);
    await f.emitAll(steadyFrames());
    final empty = f.raw.samples.where((sample) =>
        sample.output != null && sample.output!.judgeable && sample.output!.issues.isEmpty).toList();
    expect(empty, isNotEmpty, reason: 'A positive empty-issue frame must actually occur');
    for (final sample in empty) {
      expect(sample.state.surface, LiveState.noVerdict);
      expect(sample.state.noVerdictReason, calibrationReason);
      expect(sample.state.cue, isNull);
    }
    expectBlocked(f);
  });

  test('CG-08 two completed counts phase and skeleton survive while ready appears once', () async {
    final f = fixture();
    expect(await f.start(), isNull);
    await f.emitAll(jabFrames());
    expect(f.runs.last.completedCount, 1);
    await f.emitAll(jabFrames(offsetUs: 1000000));
    expect(f.runs.last.completedCount, 2);
    expect(f.raw.count, 2);
    expect(f.raw.samples.any((sample) => sample.output?.activePhase != null), isTrue);
    expect(f.cues.keyCalls.where((key) => key == jabLabReadyCueKey), hasLength(1));
    expect(f.runs.first.narration, readyMarker);
    expect(f.runs.where((state) => state.narration == readyMarker), hasLength(1));
    expectBlocked(f); // Includes frame-for-frame raw count/phase equality.
  });

  test('CG-09 an armed raw completion-code-change cannot emit corrected under pending calibration', () async {
    final f = fixture();
    final frames = correctedOpportunityFrames(f.rules);
    expect(await f.start(), isNull);
    // Explicit test-only cooldown re-arm; not an ordinary production round.
    await f.emitAll(frames, rearm: true);
    expectRawCorrectedOpportunity(f); // Fails, never skips, if event was unarmed.
    expectBlocked(f);
    expect(f.runs.last.completedCount, greaterThanOrEqualTo(2));
    expect(f.cues.keyCalls.where((key) => key == jabLabCorrectedCueKey), isEmpty);
  });

  test('CG-10 denied setup never starts native capture or creates calibration observations', () async {
    final f = GuardFixture(rulesVariant(source), permission: () async => false);
    addTearDown(f.close);
    expect(await f.start(), isA<LivePermissionDenied>());
    expect(f.camera.startCalls, 0);
    expect(f.engines, isEmpty);
    expect(f.runs, isEmpty);
    expect(f.cues.keyCalls, isEmpty);
  });

  test('CG-11 model preparation error is a setup failure with no manufactured count or ready', () async {
    final f = GuardFixture(rulesVariant(source), modelPath: () async {
      throw StateError('owned synthetic model preparation failure');
    });
    addTearDown(f.close);
    expect(await f.start(), isA<LiveSetupFailed>());
    expect(f.camera.startCalls, 0);
    expect(f.engines, isEmpty);
    expect(f.runs, isEmpty);
    expect(f.cues.keyCalls, isEmpty);
  });

  test('CG-12 wrist visibility no-call replaces calibration reason and keeps completed history', () async {
    final f = fixture();
    final frames = jabFrames();
    expect(await f.start(), isNull);
    await f.emitAll(frames);
    expect(f.runs.last.completedCount, 1);
    final low = hideLandmark(
      frames.last.copyWith(tUs: frames.last.tUs + fixtureStepUs), Lm.leftWrist, 0.2,
    );
    final state = (await f.emit(low))!;
    expect(state.surface, LiveState.noVerdict);
    expect(state.noVerdictReason, 'visibility:LOW_TRACKING_CONFIDENCE');
    expect(state.noVerdictReason, isNot(calibrationReason));
    expect(state.bucket, LiveHonestyBucket.yours);
    expect(state.completedCount, 1);
    expect(state.phase, isNull);
    expect(state.skeleton, hasLength(Lm.count));
    expect(f.raw.samples.last.output!.judgeable, isFalse);
    expect(f.cues.keyCalls, contains('cue.low_confidence'));
    expect(f.cues.technicalCalls, isEmpty);
  });

  test('CG-13 unreliable torso retains its distinct no-call sentence instead of calibration blame', () async {
    final f = fixture();
    expect(await f.start(), isNull);
    final low = hideLandmark(steadyFrames().first, Lm.leftShoulder, 0.3);
    await f.emit(low);
    final state = f.runs.last;
    expect(state.surface, LiveState.noVerdict);
    expect(state.noVerdictReason,
        "I can't get a steady read on your torso — square up so your shoulders and hips are both visible.");
    expect(state.noVerdictReason, isNot(calibrationReason));
    expect(state.bucket, LiveHonestyBucket.yours);
    expect(state.completedCount, 0);
    expect(state.phase, isNull);
    expect(f.raw.samples.last.output!.judgeable, isFalse);
  });

  test('CG-14 no-person loss cannot bridge a partial attempt and a fresh attempt still counts', () async {
    final frames = jabFrames();
    await expectUninterruptedTrajectoryCompletes(frames);
    final f = fixture();
    expect(await f.start(), isNull);
    var lossSeen = false;
    for (final frame in frames) {
      if (frame.tUs == 366663) {
        expectPartialMovementBeforeLoss(f, frame);
        lossSeen = true;
        final state = (await f.emit(null, tUs: frame.tUs))!;
        expect(state.skeleton, isNull);
        expect(state.phase, isNull);
        expect(state.noVerdictReason, isNot(calibrationReason));
        expect(state.bucket, LiveHonestyBucket.yours);
      } else { await f.emit(frame); }
    }
    expect(lossSeen, isTrue);
    expect(f.runs.last.completedCount, 0);
    expect(f.engines.length, greaterThan(1));
    await f.emitAll(jabFrames(offsetUs: 1000000));
    expect(f.runs.last.completedCount, 1);
    expect(f.raw.count, 1);
    expect(f.cues.keyCalls.where((key) => key == jabLabReadyCueKey), hasLength(1));
    expectBlocked(f);
  });

  test('CG-15 low-confidence loss cannot bridge a partial attempt or create a corrected event', () async {
    final frames = jabFrames();
    await expectUninterruptedTrajectoryCompletes(frames);
    final f = fixture();
    expect(await f.start(), isNull);
    var lossSeen = false;
    for (final frame in frames) {
      if (frame.tUs == 366663) {
        expectPartialMovementBeforeLoss(f, frame);
        lossSeen = true;
        final state = (await f.emit(hideLandmark(frame, Lm.leftWrist, 0.2)))!;
        expect(state.phase, isNull);
        expect(state.noVerdictReason, 'visibility:LOW_TRACKING_CONFIDENCE');
      } else { await f.emit(frame); }
    }
    expect(lossSeen, isTrue);
    expect(f.runs.last.completedCount, 0);
    expect(f.engines.length, greaterThan(1));
    await f.emitAll(jabFrames(offsetUs: 1000000));
    expect(f.runs.last.completedCount, 1);
    expectBlocked(f);
  });

  test('CG-16 same controller restart clears count phase observation and ready history', () async {
    final f = fixture();
    expect(await f.start(), isNull);
    await f.emitAll(jabFrames());
    expect(f.runs.last.completedCount, 1);
    await f.controller.stop();
    final stoppedStates = f.seen.length;
    await f.emit(jabFrames(offsetUs: 1000000).first);
    expect(f.seen.length, stoppedStates);
    expect(await f.start(), isNull);
    expect(f.controller.dominantTempoBand, isNull);
    final first = (await f.emit(jabFrames(offsetUs: 2000000).first))!;
    expect(first.completedCount, 0);
    expect(first.narration, readyMarker);
    expect(first.noVerdictReason, calibrationReason);
    await f.emitAll(jabFrames(offsetUs: 2000000).skip(1));
    expect(f.runs.last.completedCount, 1);
    expect(f.raw.count, 1);
    expect(f.cues.keyCalls.where((key) => key == jabLabReadyCueKey), hasLength(2));
    expect(f.camera.startCalls, 2);
    expectBlocked(f);
  });

  test('CG-17 disposed controller ignores retired frames and cannot reopen the retired session', () async {
    final f = fixture();
    expect(await f.start(), isNull);
    await f.emitAll(jabFrames());
    expect(f.runs.last.completedCount, 1);
    await f.controller.dispose();
    final before = f.seen.length;
    final builds = f.engines.length;
    await f.emit(jabFrames(offsetUs: 1000000).first);
    expect(f.seen.length, before);
    expect(f.engines.length, builds);
    expect(await f.controller.start(), isA<LiveCameraUnavailable>());
    expect(f.camera.startCalls, 1);
    expect(f.camera.activeListeners, 0);
    expect(f.controller.hasNativeSession, isFalse);
  });

  test('CG-18 absent or structurally unusable setup cannot invent ready skeleton phase or technique', () async {
    final f = fixture();
    expect(await f.start(), isNull);
    final absent = (await f.emit(null, tUs: 0))!;
    expect(absent.skeleton, isNull);
    expect(absent.phase, isNull);
    expect(absent.completedCount, 0);
    expect(f.cues.keyCalls, isNot(contains(jabLabReadyCueKey)));
    const swapped = SyntheticBody(
      upperArmLength: 0.12, forearmLength: 0.11,
      thighLength: 0.08, shinLength: 0.07,
    );
    final invalid = const SyntheticPoseBuilder(body: swapped)
        .build(guardPose, tUs: fixtureStepUs);
    final unusable = (await f.emit(invalid))!;
    expect(unusable.surface, LiveState.noVerdict);
    expect(unusable.noVerdictReason, 'fixture-structural');
    expect(unusable.bucket, LiveHonestyBucket.ours);
    expect(unusable.skeleton, isNull);
    expect(unusable.phase, isNull);
    expect(unusable.completedCount, 0);
    expect(f.engines, isEmpty);
    expect(f.cues.keyCalls, isNot(contains(jabLabReadyCueKey)));
    expect(f.cues.technicalCalls, isEmpty);
    expect(f.cues.keyCalls, isNot(contains(jabLabCorrectedCueKey)));
  });

  test('CG-19 out-of-frame no-call is not replaced by the calibration reason', () async {
    final f = fixture();
    expect(await f.start(), isNull);
    // Outside the existing normalized image bounds; not a new calibration or
    // frame-rate threshold. Start outside to avoid a temporal-jump confound.
    final outside = const SyntheticPoseBuilder().build(
      guardPose.copyWith(rootX: 1.1), tUs: 0,
    );
    final state = (await f.emit(outside))!;
    expect(f.raw.samples.last.output, isNotNull,
        reason: 'Must reach the actual engine quality gate, not an early no-person return');
    expect(f.raw.samples.last.output!.judgeable, isFalse);
    expect(f.raw.samples.last.output!.suppressionReason, startsWith('quality:'));
    expect(state.surface, LiveState.noVerdict);
    expect(state.noVerdictReason, 'visibility:OUT_OF_FRAME');
    expect(state.noVerdictReason, isNot(calibrationReason));
    expect(state.bucket, LiveHonestyBucket.yours);
    expect(state.completedCount, 0);
    expect(state.phase, isNull);
    expect(state.skeleton, hasLength(Lm.count));
    expect(f.cues.keyCalls, contains('cue.out_of_frame'));
    expect(f.cues.technicalCalls, isEmpty);
  });

}
