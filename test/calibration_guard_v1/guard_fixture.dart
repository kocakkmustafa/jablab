// Synthetic calibration-admission protocol using actual engine and owned camera wire; no physical or production camera admission.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/live_honesty.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/live_session_failure.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/shell_candidate/live_surface.dart' show LiveState;
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import '../support/owned_native_fixture.dart';

const calibrationReason =
    'Technique feedback is unavailable while this setup is awaiting calibration. '
    'The count records detected attempts; it is not a judgement of technique.';
const calibrationReasonTr =
    'Bu kurulumun kalibrasyonu beklenirken teknik geri bildirimi kullanılamaz. '
    'Sayı algılanan denemeleri kaydeder; teknik doğruluğu göstermez.';
const readyMarker = 'fixture-ready';
const correctedMarker = 'fixture-corrected';

// Geometry and sample schedule copied from the existing report controller
// fixture / live_jab_path_test, not an operating FPS or physical threshold.
const fixtureStepUs = 33333;
const fixtureGuardUs = 200000;
const guardPose = SyntheticPose(
  leftUpperArm: 1.35,
  leftForearm: -1.45,
  rightUpperArm: 1.75,
  rightForearm: -1.65,
);
const extendedPose = SyntheticPose(
  leftUpperArm: 0,
  leftForearm: 0,
  rightUpperArm: 0,
  rightForearm: 0,
);

Future<Map<String, dynamic>> loadRulesJson() async =>
    (jsonDecode(
              await rootBundle.loadString(ContentRepository.boxingRuleSetAsset),
            )
            as Map)
        .cast<String, dynamic>();

// Only metadata labels may vary. This does not modify rules, errors, smoothing,
// thresholds or the asset, and a calibrated string is not verified calibration.
RuleSet rulesVariant(
  Map<String, dynamic> source, {
  bool? pending,
  String? status,
  bool omitMetadata = false,
}) {
  final copy = Map<String, dynamic>.from(source);
  if (omitMetadata) {
    copy.remove('calibrationPending');
    copy.remove('thresholdStatus');
  } else {
    if (pending != null) {
      copy['calibrationPending'] = pending;
    }
    if (status != null) {
      copy['thresholdStatus'] = status;
    }
  }
  return RuleSet.fromJson(copy);
}

List<PoseFrame> jabFrames({
  int offsetUs = 0,
  int guardUs = fixtureGuardUs,
  bool raiseRearGuard = false,
}) {
  final start = raiseRearGuard
      ? guardPose.copyWith(rightUpperArm: -2.4, rightForearm: -0.75)
      : guardPose;
  final peak = raiseRearGuard
      ? extendedPose.copyWith(rightUpperArm: -2.4, rightForearm: -0.75)
      : extendedPose;
  final sequence = SyntheticSequence([
    SyntheticKeyframe(0, start),
    if (guardUs > 0) SyntheticKeyframe(guardUs, start),
    SyntheticKeyframe(guardUs + 120000, peak),
    SyntheticKeyframe(guardUs + 320000, start),
    SyntheticKeyframe(guardUs + 550000, start),
  ]);
  return [
    for (int t = sequence.startUs; t <= sequence.endUs; t += fixtureStepUs)
      const SyntheticPoseBuilder().build(sequence.poseAt(t), tUs: offsetUs + t),
  ];
}

List<PoseFrame> steadyFrames({int offsetUs = 0, int count = 8}) => [
  for (var i = 0; i < count; i++)
    const SyntheticPoseBuilder().build(
      guardPose,
      tUs: offsetUs + i * fixtureStepUs,
    ),
];

PoseFrame hideLandmark(PoseFrame frame, int index, double visibility) =>
    frame.copyWith(
      landmarks: [
        for (var i = 0; i < frame.landmarks.length; i++)
          i == index
              ? frame.landmarks[i].copyWith(visibility: visibility)
              : frame.landmarks[i],
      ],
    );

CameraFrameEnvelope envelope(PoseFrame? frame, {int? tUs}) =>
    CameraFrameEnvelope(
      tUs: tUs ?? frame?.tUs ?? 0,
      size: const FrameSize(480, 640),
      modelVersion: frame?.modelVersion ?? 'synthetic-no-person',
      clockDomain: ClockDomain.monotonic,
      inferenceUs: 1000,
      dropped: 0,
      passes: {BodyOrientation.upright: frame},
    );

class RecordingCues extends CueBook {
  RecordingCues()
    : super(
        const {},
        byKey: {
          for (final entry in jabLabIssueCueMapping.entries)
            entry.value: [
              jabLabVisibilityIssueCodes.contains(entry.key)
                  ? 'visibility:${entry.key}'
                  : 'technical:${entry.key}',
            ],
          jabLabReadyCueKey: [readyMarker],
          jabLabCorrectedCueKey: [correctedMarker],
          'cue.structural': ['fixture-structural'],
        },
      );
  final keyCalls = <String>[];
  @override
  String? sayKey(String key) {
    keyCalls.add(key);
    return super.sayKey(key);
  }

  Iterable<String> get technicalCalls => keyCalls.where(
    (key) => jabLabIssueCueMapping.entries.any(
      (entry) =>
          !jabLabVisibilityIssueCodes.contains(entry.key) && entry.value == key,
    ),
  );
}

class RawSample {
  RawSample(this.tUs, this.output, this.state, this.completedCount);
  final int tUs;
  final EngineOutput? output;
  final LiveJabRunning state;
  final int completedCount;
}

// A SECOND actual engine consumes the exact accepted skeleton exposed by the
// controller (after actual owned-wire Float32 decoding and orientation choice).
// It neither fabricates issues nor observes the guard's admission expression.
class RawProbe {
  RawProbe(this.rules);
  final RuleSet rules;
  StrikingEngine? engine;
  int count = 0;
  final samples = <RawSample>[];
  void resetSession() {
    engine = null;
    count = 0;
    samples.clear();
  }

  void accept(
    CameraFrameEnvelope input,
    LiveJabRunning state, {
    bool rearm = false,
  }) {
    final skeleton = state.skeleton;
    if (skeleton == null) {
      engine = null;
      samples.add(RawSample(input.tUs, null, state, count));
      return;
    }
    final current = engine ??= StrikingEngine(
      ruleSet: rules,
      frameSize: input.size,
      allowedTechniqueIds: const {'jab'},
      calibrationMapped: false,
      provenance: const {'modelId': 'guard-test-synthetic'},
    );
    if (rearm) {
      current.startRound();
    }
    final output = current.process(
      PoseFrame(
        tUs: input.tUs,
        landmarks: skeleton,
        modelVersion: input.modelVersion,
      ),
    );
    if (output.completedAttempt?.completed ?? false) {
      count++;
    }
    samples.add(RawSample(input.tUs, output, state, count));
    // Existing controller retires partial observations on unreliable frames.
    // This reset mirrors that pre-existing lifecycle, not the guard predicate.
    if (!output.judgeable) {
      engine = null;
    }
  }

  Iterable<DetectedIssue> get firstIssues => samples
      .map((sample) => sample.output)
      .whereType<EngineOutput>()
      .where((output) => output.issues.isNotEmpty)
      .map((output) => output.issues.first);
}

class GuardFixture {
  GuardFixture(
    this.rules, {
    Future<bool> Function()? permission,
    Future<String> Function()? modelPath,
    Object? cameraStartError,
  }) : camera = OwnedTestCamera(
         startError: cameraStartError,
         libraryTag: 'guard-v1-owned-synthetic',
       ),
       raw = RawProbe(rules) {
    controller = LiveJabController(
      ruleSet: rules,
      cues: cues,
      allowedTechniqueIds: const {'jab'},
      modelPath: modelPath ?? () async => '/dev/null/guard-test-synthetic.task',
      modelId: 'guard-test-synthetic',
      camera: camera,
      requestPermission: permission ?? () async => true,
      permissionPermanentlyDenied: () async => false,
      engineFactory: (size) {
        final engine = StrikingEngine(
          ruleSet: rules,
          frameSize: size,
          allowedTechniqueIds: const {'jab'},
          calibrationMapped: false,
          provenance: const {'modelId': 'guard-test-synthetic'},
        );
        engines.add(engine);
        return engine;
      },
    );
    subscription = controller.states.listen(seen.add);
  }
  final RuleSet rules;
  final OwnedTestCamera camera;
  final RawProbe raw;
  final cues = RecordingCues();
  final engines = <StrikingEngine>[];
  final seen = <LiveJabState>[];
  late final LiveJabController controller;
  late final StreamSubscription<LiveJabState> subscription;
  bool _closed = false;
  List<LiveJabRunning> get runs => seen.whereType<LiveJabRunning>().toList();

  Future<LiveSessionFailure?> start() async {
    raw.resetSession();
    return controller.start();
  }

  Future<LiveJabRunning?> emit(
    PoseFrame? frame, {
    int? tUs,
    bool rearm = false,
  }) async {
    if (rearm && engines.isNotEmpty) {
      engines.last.startRound();
    }
    final input = envelope(frame, tUs: tUs);
    final before = runs.length;
    await camera.native.emitNative(input);
    await Future<void>.delayed(Duration.zero);
    final after = runs;
    expect(after.length - before, inInclusiveRange(0, 1));
    if (after.length == before) {
      return null;
    }
    final state = after.last;
    raw.accept(input, state, rearm: rearm);
    return state;
  }

  Future<void> emitAll(Iterable<PoseFrame> frames, {bool rearm = false}) async {
    for (final frame in frames) {
      await emit(frame, rearm: rearm);
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await subscription.cancel();
    await controller.dispose();
    expectSync(camera.native.globalStopCalls, 0);
    expectSync(camera.native.state.phase, 'closed');
    expectSync(camera.activeListeners, 0);
    await camera.close();
  }
}

void expectBlocked(GuardFixture fixture) {
  expect(fixture.runs, isNotEmpty);
  expect(fixture.cues.technicalCalls, isEmpty);
  expect(
    fixture.cues.keyCalls.where((key) => key == jabLabCorrectedCueKey),
    isEmpty,
  );
  expect(fixture.runs.every((state) => state.cue == null), isTrue);
  expect(
    fixture.runs.every((state) => state.surface == LiveState.noVerdict),
    isTrue,
  );
  final valid = fixture.raw.samples
      .where((sample) => sample.output?.judgeable ?? false)
      .toList();
  expect(
    valid,
    isNotEmpty,
    reason: 'A no-frame/no-person path cannot satisfy this witness',
  );
  for (final sample in valid) {
    expect(sample.state.noVerdictReason, calibrationReason);
    expect(sample.state.bucket, LiveHonestyBucket.ours);
    expect(sample.state.phase, sample.output!.activePhase);
    expect(sample.state.completedCount, sample.completedCount);
    expect(sample.state.skeleton, hasLength(Lm.count));
  }
}

void expectFirstIssue(GuardFixture fixture, String code, String band) {
  expect(
    fixture.raw.firstIssues.any(
      (issue) => issue.code == code && issue.band == band,
    ),
    isTrue,
    reason:
        'Must witness an actually FIRST raw issue, not a union or an empty stream',
  );
}

// Fault-fixture preparation ONLY. It aligns an existing synthetic completion
// with the engine's existing 2,000,000 us STANCE_SAMPLE interval, and re-arms
// existing per-round cooldown through the actual startRound() API. This does
// not change a threshold/FPS/rule, establish accepted gap timing, or model an
// ordinary production round. Candidate search must FAIL if no real raw witness.
List<PoseFrame> correctedOpportunityFrames(RuleSet rules) {
  List<EngineOutput> trace(List<PoseFrame> frames) {
    final engine = StrikingEngine(
      ruleSet: rules,
      frameSize: const FrameSize(480, 640),
      allowedTechniqueIds: const {'jab'},
      calibrationMapped: false,
    );
    final outputs = <EngineOutput>[];
    for (final frame in frames) {
      engine.startRound();
      // Match the actual native fixture's Float32 wire representation.
      final values = Float32List.fromList([
        for (final p in frame.landmarks) ...[p.x, p.y, p.z, p.visibility],
      ]);
      outputs.add(
        engine.process(
          frame.copyWith(
            landmarks: [
              for (var i = 0; i < values.length; i += 4)
                PoseLandmark(
                  values[i],
                  values[i + 1],
                  values[i + 2],
                  values[i + 3],
                ),
            ],
          ),
        ),
      );
    }
    return outputs;
  }

  final baseline = trace(jabFrames());
  final completed = baseline
      .where((out) => out.completedAttempt?.completed ?? false)
      .toList();
  expect(
    completed,
    isNotEmpty,
    reason: 'Baseline synthetic movement must really complete',
  );
  // Constant comes from striking_engine.dart STANCE_SAMPLE scheduling, not a
  // new admissible FPS/gap/physical threshold.
  const sampleIntervalUs = 2000000;
  final targetUs = (sampleIntervalUs ~/ fixtureStepUs + 1) * fixtureStepUs;
  final alignedGuardUs = fixtureGuardUs + targetUs - completed.first.tUs;
  for (final delta in [-2, -1, 0, 1, 2]) {
    final first = jabFrames(guardUs: alignedGuardUs + delta * fixtureStepUs);
    final second = jabFrames(offsetUs: first.last.tUs + fixtureStepUs);
    final frames = [...first, ...second];
    final attempts = trace(
      frames,
    ).where((out) => out.completedAttempt?.completed ?? false).toList();
    for (var i = 1; i < attempts.length; i++) {
      final before = attempts[i - 1].issues.isEmpty
          ? null
          : attempts[i - 1].issues.first.code;
      final current = attempts[i].issues.isEmpty
          ? null
          : attempts[i].issues.first.code;
      if (before != null &&
          current != before &&
          !jabLabVisibilityIssueCodes.contains(before)) {
        return frames;
      }
    }
  }
  throw StateError(
    'No non-vacuous raw completion-code-change fixture; do not skip or claim corrected coverage',
  );
}

void expectRawCorrectedOpportunity(GuardFixture fixture) {
  final completed = fixture.raw.samples
      .map((sample) => sample.output)
      .whereType<EngineOutput>()
      .where((out) => out.completedAttempt?.completed ?? false)
      .toList();
  expect(completed.length, greaterThanOrEqualTo(2));
  var opportunities = 0;
  for (var i = 1; i < completed.length; i++) {
    final before = completed[i - 1].issues.isEmpty
        ? null
        : completed[i - 1].issues.first.code;
    final current = completed[i].issues.isEmpty
        ? null
        : completed[i].issues.first.code;
    if (before != null &&
        current != before &&
        !jabLabVisibilityIssueCodes.contains(before)) {
      opportunities++;
    }
  }
  expect(
    opportunities,
    greaterThan(0),
    reason: 'No corrected suppression claim from an unarmed event',
  );
}
