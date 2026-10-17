import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/technique_observation.dart';
import 'package:jablab/app/technique_task.dart';
import 'package:motion_core/motion_core.dart';

final task = TechniqueTasks.lowFrontKick;
TechniqueCaptureContext context({
  TechniqueSide? side = TechniqueSide.left,
  TechniqueSide? lead = TechniqueSide.left,
  LandmarkSideMapping mapping = LandmarkSideMapping.anatomical,
  TechniqueView view = TechniqueView.leftProfile,
  bool mirrored = false,
}) => TechniqueCaptureContext(
  actualSide: side,
  leadSide: lead,
  view: view,
  sideMapping: mapping,
  displayMirrored: mirrored,
);

PoseFrame pose(int tUs) {
  final points = List.generate(
    Lm.count,
    (_) => const PoseLandmark(.5, .5, 0, 1),
  );
  points[Lm.leftShoulder] = const PoseLandmark(.4, .2, 0, 1);
  points[Lm.rightShoulder] = const PoseLandmark(.55, .2, 0, 1);
  points[Lm.leftHip] = const PoseLandmark(.4, .5, 0, 1);
  points[Lm.rightHip] = const PoseLandmark(.55, .5, 0, 1);
  points[Lm.leftKnee] = const PoseLandmark(.5, .65, 0, 1);
  points[Lm.rightKnee] = const PoseLandmark(.55, .65, 0, 1);
  points[Lm.leftAnkle] = const PoseLandmark(.7, .65, 0, 1);
  points[Lm.rightAnkle] = const PoseLandmark(.55, .85, 0, 1);
  return PoseFrame(tUs: tUs, landmarks: points, modelVersion: task.modelId);
}

TechniquePoseSample sample(
  int t, {
  PoseFrame? frame,
  TechniqueCaptureContext? captureContext,
  bool noPose = false,
  bool monotonic = true,
}) => TechniquePoseSample(
  frame: noPose ? null : frame ?? pose(t),
  size: const FrameSize(480, 640),
  context: captureContext ?? context(),
  monotonicClock: monotonic,
);
TechniqueCaptureProfile profile() =>
    TechniqueCaptureProfile(minimumVisibility: .5, maximumGapUs: 1000);
TechniqueObservationSession _session(_Provider p) =>
    TechniqueObservationSession.replayForTesting(
      task: task,
      provider: p,
      profile: profile(),
    );

void main() {
  test(
    'exact reviewed course/lesson binding; no cross-discipline fallback',
    () {
      expect(
        sha256
            .convert(
              File('assets/content/kickboxing_a.v1.json').readAsBytesSync(),
            )
            .toString(),
        task.courseSha256,
      );
      expect(
        TechniqueTasks.forLesson('jablab.kickboxing_a', 'kb-12'),
        same(task),
      );
      for (final key in [
        ('jablab.karate_a', 'kb-12'),
        ('jablab.kickboxing_a', 'kb-11'),
        ('boxing', 'jab'),
      ]) {
        expect(TechniqueTasks.forLesson(key.$1, key.$2), isNull);
      }
      expect(task.toJson()['schemaVersion'], 1);
      expect(task.toJson()['coordinateSpace'], 'image2d.aspectCorrected');
      expect(task.sha256Digest, matches(r'^[0-9a-f]{64}$'));
      expect(() => task.phases.clear(), throwsUnsupportedError);
      expect(() => task.views.clear(), throwsUnsupportedError);
    },
  );

  test(
    'production kb-12 abstains even with a complete visible sample',
    () async {
      final s = TechniqueObservationSession.productionForLesson(
        'jablab.kickboxing_a',
        'kb-12',
      );
      final result = await s.observe(sample(1));
      expect(result.kind, TechniqueObservationKind.calibrationRequired);
      expect(result.isReplay, isFalse);
      expect(result.sequenceCandidateComplete, isFalse);
      expect(result.progressEffect, 0);
      await s.close();
    },
  );

  test('production unknown lesson is unsupported', () async {
    final s = TechniqueObservationSession.productionForLesson(
      'jablab.muay_thai_a',
      'mt-12',
    );
    expect(
      (await s.observe(sample(1))).kind,
      TechniqueObservationKind.unsupported,
    );
    await s.close();
  });

  test(
    'aspect corrected 2D geometry measures a projection, not a technique',
    () {
      final read = LowerLimbFeatureExtractor.read(task, profile(), sample(1));
      expect(read.reason, isNull);
      expect(
        read.features!.values['kneeAngle.image2d.deg'],
        closeTo(116.565051, .00001),
      );
      expect(read.features!.values.keys, isNot(contains('force')));
      expect(() => read.features!.values.clear(), throwsUnsupportedError);
    },
  );

  test('display mirroring does not change actual limb or geometry', () {
    final plain = LowerLimbFeatureExtractor.read(
      task,
      profile(),
      sample(1),
    ).features!;
    final mirrored = LowerLimbFeatureExtractor.read(
      task,
      profile(),
      sample(1, captureContext: context(mirrored: true)),
    ).features!;
    expect(mirrored.actualSide, TechniqueSide.left);
    expect(mirrored.values, plain.values);
    expect(
      context(side: TechniqueSide.right, lead: TechniqueSide.left).isLead,
      isFalse,
    );
    expect(
      context(side: TechniqueSide.left, lead: TechniqueSide.left).isLead,
      isTrue,
    );
    expect(context(lead: null).isLead, isNull);
  });

  test(
    'explicit swapped landmark mapping preserves actual-left measurement',
    () {
      final f = pose(1);
      final mirrored = f.copyWith(
        landmarks: [
          for (var i = 0; i < Lm.count; i++)
            f[LmMirror.of(i)].copyWith(x: 1 - f[LmMirror.of(i)].x),
        ],
      );
      final plain = LowerLimbFeatureExtractor.read(
        task,
        profile(),
        sample(1),
      ).features!;
      final swapped = LowerLimbFeatureExtractor.read(
        task,
        profile(),
        sample(
          1,
          frame: mirrored,
          captureContext: context(mapping: LandmarkSideMapping.swapped),
        ),
      ).features!;
      expect(swapped.actualSide, TechniqueSide.left);
      for (final key in plain.values.keys) {
        expect(swapped.values[key], closeTo(plain.values[key]!, 1e-9));
      }
    },
  );

  for (final failure in [
    'side',
    'mapping',
    'view',
    'missing',
    'confidence',
    'offFrame',
    'nan',
    'model',
    'clock',
    'collapsed',
  ]) {
    test(
      '$failure data cannot reach provider or produce a phase candidate',
      () async {
        final p = _Provider([TechniquePhase.preparation]);
        final s = _session(p);
        addTearDown(s.close);
        var f = pose(1);
        var c = context();
        if (failure == 'side') c = context(side: null);
        if (failure == 'mapping') {
          c = context(mapping: LandmarkSideMapping.unknown);
        }
        if (failure == 'view') c = context(view: TechniqueView.frontOblique);
        if (failure == 'model') f = f.copyWith(modelVersion: 'other');
        if (['confidence', 'offFrame', 'nan', 'collapsed'].contains(failure)) {
          final points = List<PoseLandmark>.of(f.landmarks);
          points[Lm.leftKnee] = switch (failure) {
            'confidence' => points[Lm.leftKnee].copyWith(visibility: .1),
            'offFrame' => points[Lm.leftKnee].copyWith(x: 1.1),
            'nan' => points[Lm.leftKnee].copyWith(y: double.nan),
            _ => points[Lm.leftHip],
          };
          f = f.copyWith(landmarks: points);
        }
        final result = await s.observe(
          sample(
            1,
            frame: f,
            captureContext: c,
            noPose: failure == 'missing',
            monotonic: failure != 'clock',
          ),
        );
        expect(result.kind, TechniqueObservationKind.unobservable);
        expect(result.sequenceCandidateComplete, isFalse);
        expect(result.progressEffect, 0);
        expect(p.calls, 0);
      },
    );
  }

  test(
    'synthetic phase sequence completes only in exact order, with no progress effect',
    () async {
      final p = _Provider(task.phases);
      final s = _session(p);
      addTearDown(s.close);
      for (var i = 0; i < task.phases.length; i++) {
        final result = await s.observe(sample(i + 1));
        expect(result.kind, TechniqueObservationKind.phaseCandidate);
        expect(result.isReplay, isTrue);
        expect(result.sequenceCandidateComplete, i == task.phases.length - 1);
        expect(result.startUs, 1);
        expect(result.progressEffect, 0);
      }
    },
  );

  test(
    'extension alone, wrong order and another technique cannot complete kb-12',
    () async {
      final p = _Provider([
        TechniquePhase.extension,
        TechniquePhase.preparation,
        TechniquePhase.retraction,
        TechniquePhase.returnToStart,
      ]);
      final s = _session(p);
      addTearDown(s.close);
      for (var i = 1; i <= 4; i++) {
        expect((await s.observe(sample(i))).sequenceCandidateComplete, isFalse);
      }
      p.handler = (f) async => p.event(f, taskId: 'jablab.boxing.jab');
      expect(
        (await s.observe(sample(5))).reason,
        TechniqueObservationReason.wrongTask,
      );
    },
  );

  for (final mismatch in ['taskHash', 'provider', 'side', 'timestamp']) {
    test('event $mismatch mismatch is refused', () async {
      final p = _Provider([]);
      p.handler = (f) async => p.event(
        f,
        taskHash: mismatch == 'taskHash' ? 'a' * 64 : null,
        providerIdentity: mismatch == 'provider' ? 'another.provider' : null,
        side: mismatch == 'side' ? TechniqueSide.right : null,
        timestamp: mismatch == 'timestamp' ? f.tUs + 1 : null,
      );
      final s = _session(p);
      addTearDown(s.close);
      final result = await s.observe(sample(1));
      expect(result.kind, isNot(TechniqueObservationKind.phaseCandidate));
      expect(result.sequenceCandidateComplete, isFalse);
    });
  }

  for (final interruption in [
    'missing',
    'gap',
    'reversedClock',
    'sideChange',
    'displayMirror',
    'lifecycle',
  ]) {
    test('$interruption cannot bridge a partial sequence', () async {
      final p = _Provider([
        TechniquePhase.preparation,
        TechniquePhase.extension,
        TechniquePhase.retraction,
        TechniquePhase.returnToStart,
      ]);
      final s = _session(p);
      addTearDown(s.close);
      await s.observe(sample(1));
      await s.observe(sample(2));
      switch (interruption) {
        case 'missing':
          await s.observe(sample(3, noPose: true));
        case 'gap':
          await s.observe(sample(2000));
        case 'reversedClock':
          await s.observe(sample(1));
        case 'sideChange':
          await s.observe(
            sample(3, captureContext: context(side: TechniqueSide.right)),
          );
        case 'displayMirror':
          await s.observe(sample(3, captureContext: context(mirrored: true)));
        case 'lifecycle':
          s.interrupt();
      }
      final start = interruption == 'gap' ? 2001 : 4;
      expect(
        (await s.observe(sample(start))).sequenceCandidateComplete,
        isFalse,
      );
      expect(
        (await s.observe(sample(start + 1))).sequenceCandidateComplete,
        isFalse,
      );
      expect(p.resets, greaterThan(0));
    });
  }

  test(
    'closing session discards a late provider reply and closes once',
    () async {
      final entered = Completer<TechniqueFeatures>();
      final pending = Completer<TechniquePhaseEvent?>();
      final p = _Provider([])
        ..handler = (f) {
          entered.complete(f);
          return pending.future;
        };
      final s = _session(p);
      final observation = s.observe(sample(1));
      final features = await entered.future;
      await s.close();
      await s.close();
      pending.complete(p.event(features));
      expect((await observation).reason, TechniqueObservationReason.retired);
      expect(p.closes, 1);
      expect(
        (await s.observe(sample(2))).reason,
        TechniqueObservationReason.retired,
      );
    },
  );

  test(
    'overlapping provider call invalidates the pending observation',
    () async {
      final pending = Completer<TechniquePhaseEvent?>();
      late TechniqueFeatures captured;
      final p = _Provider([])
        ..handler = (f) {
          captured = f;
          return pending.future;
        };
      final s = _session(p);
      addTearDown(s.close);
      final first = s.observe(sample(1));
      expect(
        (await s.observe(sample(2))).reason,
        TechniqueObservationReason.providerBusy,
      );
      pending.complete(p.event(captured));
      expect(
        (await first).kind,
        isNot(TechniqueObservationKind.phaseCandidate),
      );
    },
  );

  test(
    'provider identity change requires a fresh session and closes old provider',
    () async {
      final p = _Provider(task.phases);
      final s = _session(p);
      addTearDown(s.close);
      await s.observe(sample(1));
      p.identityValue = 'different.provider/2.0.0';
      final result = await s.observe(sample(2));
      expect(result.kind, isNot(TechniqueObservationKind.phaseCandidate));
      expect(result.sequenceCandidateComplete, isFalse);
      expect(p.closes, 1);
      expect(
        (await s.observe(sample(3))).reason,
        TechniqueObservationReason.retired,
      );
    },
  );

  test(
    'provider exception abstains and allows a fresh complete sequence',
    () async {
      final p = _Provider([])
        ..handler = (_) async => throw StateError('synthetic failure');
      final s = _session(p);
      addTearDown(s.close);
      expect(
        (await s.observe(sample(1))).reason,
        TechniqueObservationReason.providerFailure,
      );
      p.handler = null;
      p.phases.addAll(task.phases);
      for (var i = 0; i < 4; i++) {
        expect(
          (await s.observe(sample(i + 2))).sequenceCandidateComplete,
          i == 3,
        );
      }
    },
  );

  test('phase not listed by the task is unsupported', () async {
    final short = TechniqueTaskSpec(
      id: task.id,
      version: task.version,
      courseId: task.courseId,
      lessonId: task.lessonId,
      techniqueId: task.techniqueId,
      variant: task.variant,
      courseSha256: task.courseSha256,
      modelId: task.modelId,
      modelSha256: task.modelSha256,
      views: task.views,
      phases: [TechniquePhase.preparation, TechniquePhase.extension],
    );
    final p = _Provider([])
      ..handler = (f) async => TechniquePhaseEvent(
        taskId: short.id,
        taskSha256: short.sha256Digest,
        providerIdentity: 'synthetic.kb12.provider/1.0.0',
        actualSide: f.actualSide,
        tUs: f.tUs,
        phase: TechniquePhase.retraction,
      );
    final s = TechniqueObservationSession.replayForTesting(
      task: short,
      provider: p,
      profile: profile(),
    );
    addTearDown(s.close);
    expect(
      (await s.observe(sample(1))).reason,
      TechniqueObservationReason.wrongPhaseOrder,
    );
  });

  test('provider change while awaiting response retires the session', () async {
    final pending = Completer<TechniquePhaseEvent?>();
    late TechniqueFeatures features;
    final p = _Provider([])
      ..handler = (f) {
        features = f;
        return pending.future;
      };
    final s = _session(p);
    addTearDown(s.close);
    final result = s.observe(sample(1));
    p.identityValue = 'replacement.provider/2.0.0';
    pending.complete(p.event(features));
    expect((await result).kind, isNot(TechniqueObservationKind.phaseCandidate));
    expect(p.closes, 1);
  });
}

/// Isolated test adapter, never imported by lib/ or a shipping constructor.
class _Provider implements TechniquePhaseProvider {
  _Provider(Iterable<TechniquePhase> phases) : phases = phases.toList();
  final List<TechniquePhase> phases;
  Future<TechniquePhaseEvent?> Function(TechniqueFeatures)? handler;
  int calls = 0, resets = 0, closes = 0;
  String identityValue = 'synthetic.kb12.provider/1.0.0';
  @override
  String get identity => identityValue;
  TechniquePhaseEvent event(
    TechniqueFeatures f, {
    String? taskId,
    String? taskHash,
    String? providerIdentity,
    TechniqueSide? side,
    int? timestamp,
    TechniquePhase? phase,
  }) => TechniquePhaseEvent(
    taskId: taskId ?? task.id,
    taskSha256: taskHash ?? task.sha256Digest,
    providerIdentity: providerIdentity ?? identity,
    actualSide: side ?? f.actualSide,
    tUs: timestamp ?? f.tUs,
    phase: phase ?? TechniquePhase.preparation,
  );
  @override
  Future<TechniquePhaseEvent?> observe(TechniqueFeatures f) async {
    calls++;
    if (handler != null) return handler!(f);
    return phases.isEmpty ? null : event(f, phase: phases.removeAt(0));
  }

  @override
  void reset() {
    resets++;
  }

  @override
  Future<void> close() async {
    closes++;
  }
}
