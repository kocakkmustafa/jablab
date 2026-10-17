import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kReleaseMode, visibleForTesting;
import 'package:motion_core/motion_core.dart';

import 'technique_task.dart';
import 'technique_provider_adapter.dart';

enum TechniqueObservationKind {
  unsupported,
  calibrationRequired,
  uncertain,
  unobservable,
  phaseCandidate,
}

enum TechniqueObservationReason {
  unsupportedTask,
  calibrationMissing,
  sideUnmapped,
  unsupportedView,
  missingPose,
  lowConfidence,
  outOfFrame,
  invalidGeometry,
  wrongModel,
  clockDiscontinuity,
  contextChanged,
  wrongTask,
  wrongSide,
  wrongPhaseOrder,
  providerFailure,
  providerBusy,
  retired,
}

/// These are capture/calibration inputs, not achieved physical tolerances.
/// Production has no accepted profile in this release; tests supply their own.
final class TechniqueCaptureProfile {
  TechniqueCaptureProfile({
    required this.minimumVisibility,
    required this.maximumGapUs,
  }) {
    if (!minimumVisibility.isFinite ||
        minimumVisibility <= 0 ||
        minimumVisibility > 1 ||
        maximumGapUs <= 0) {
      throw const FormatException('Invalid capture profile');
    }
  }
  final double minimumVisibility;
  final int maximumGapUs;
}

final class TechniquePoseSample {
  const TechniquePoseSample({
    required this.frame,
    required this.size,
    required this.context,
    this.monotonicClock = true,
  });
  final PoseFrame? frame;
  final FrameSize size;
  final TechniqueCaptureContext context;
  final bool monotonicClock;
}

final class TechniqueFeatures {
  TechniqueFeatures({
    required this.tUs,
    required this.actualSide,
    required Map<String, double> values,
  }) : values = Map.unmodifiable(values);
  final int tUs;
  final TechniqueSide actualSide;
  final Map<String, double> values;
}

final class TechniqueFeatureRead {
  const TechniqueFeatureRead._(this.features, this.reason);
  final TechniqueFeatures? features;
  final TechniqueObservationReason? reason;
}

/// Visible, aspect-corrected 2D geometry only. It does not classify a kick or
/// infer support/load/contact, nor choose physical acceptance thresholds.
abstract final class LowerLimbFeatureExtractor {
  static TechniqueFeatureRead read(
    TechniqueTaskSpec task,
    TechniqueCaptureProfile profile,
    TechniquePoseSample sample,
  ) {
    TechniqueFeatureRead reject(TechniqueObservationReason r) =>
        TechniqueFeatureRead._(null, r);
    final frame = sample.frame;
    final context = sample.context;
    if (context.actualSide == null ||
        context.leadSide == null ||
        context.sideMapping == LandmarkSideMapping.unknown) {
      return reject(TechniqueObservationReason.sideUnmapped);
    }
    if (!task.views.contains(context.view)) {
      return reject(TechniqueObservationReason.unsupportedView);
    }
    if (frame == null) return reject(TechniqueObservationReason.missingPose);
    if (frame.modelVersion != task.modelId) {
      return reject(TechniqueObservationReason.wrongModel);
    }
    if (!sample.monotonicClock || frame.tUs < 0) {
      return reject(TechniqueObservationReason.clockDiscontinuity);
    }
    if (frame.landmarks.length != Lm.count ||
        sample.size.width <= 0 ||
        sample.size.height <= 0) {
      return reject(TechniqueObservationReason.invalidGeometry);
    }
    for (final index in TechniqueTaskSpec.requiredLandmarks) {
      final p = frame[index];
      if (![p.x, p.y, p.z, p.visibility].every((v) => v.isFinite) ||
          p.visibility > 1) {
        return reject(TechniqueObservationReason.invalidGeometry);
      }
      if (p.visibility < profile.minimumVisibility) {
        return reject(TechniqueObservationReason.lowConfidence);
      }
      if (p.x < 0 || p.x > 1 || p.y < 0 || p.y > 1) {
        return reject(TechniqueObservationReason.outOfFrame);
      }
    }
    // Native input is normalized image coordinates. z is deliberately excluded
    // from the projected angle; normalized depth is not a world-space measure.
    final isotropic = frame.toIsotropic(sample.size);
    bool left = context.actualSide == TechniqueSide.left;
    if (context.sideMapping == LandmarkSideMapping.swapped) left = !left;
    Vec3 point(int i) {
      final p = isotropic[i];
      return Vec3(p.x, p.y, 0);
    }

    final shoulder = point(left ? Lm.leftShoulder : Lm.rightShoulder);
    final hip = point(left ? Lm.leftHip : Lm.rightHip);
    final knee = point(left ? Lm.leftKnee : Lm.rightKnee);
    final ankle = point(left ? Lm.leftAnkle : Lm.rightAnkle);
    final torso = (shoulder - hip).length;
    final kneeAngle = jointAngle(hip, knee, ankle) * 180 / math.pi;
    final hipAngle = jointAngle(shoulder, hip, knee) * 180 / math.pi;
    if (!torso.isFinite ||
        torso <= 1e-9 ||
        !kneeAngle.isFinite ||
        !hipAngle.isFinite) {
      return reject(TechniqueObservationReason.invalidGeometry);
    }
    return TechniqueFeatureRead._(
      TechniqueFeatures(
        tUs: frame.tUs,
        actualSide: context.actualSide!,
        values: {
          'kneeAngle.image2d.deg': kneeAngle,
          'hipAngle.image2d.deg': hipAngle,
          'ankleHorizontalFromHip.torso': (ankle.x - hip.x).abs() / torso,
          'ankleVerticalFromHip.torso': (ankle.y - hip.y) / torso,
        },
      ),
      null,
    );
  }
}

final class TechniquePhaseEvent {
  const TechniquePhaseEvent({
    required this.taskId,
    required this.taskSha256,
    required this.providerIdentity,
    required this.actualSide,
    required this.tUs,
    required this.phase,
  });
  final String taskId, taskSha256, providerIdentity;
  final TechniqueSide actualSide;
  final int tUs;
  final TechniquePhase phase;
}

/// Domain port for a future admitted provider. Core owns manifest admission,
/// mode/ABI/artifact/acceptance compatibility and explicit rollback. No copy of
/// that contract is implemented here. Fake/replay implementations live in tests.
abstract interface class TechniquePhaseProvider {
  String get identity;
  Future<TechniquePhaseEvent?> observe(TechniqueFeatures features);
  void reset();
  Future<void> close();
}

final class TechniqueObservation {
  const TechniqueObservation({
    required this.kind,
    required this.isReplay,
    this.reason,
    this.phase,
    this.startUs,
    this.endUs,
    this.sequenceCandidateComplete = false,
  });
  final TechniqueObservationKind kind;
  final TechniqueObservationReason? reason;
  final TechniquePhase? phase;
  final int? startUs, endUs;
  final bool isReplay, sequenceCandidateComplete;
  // Phase/sequence observations cannot write or authorize lesson progress.
  int get progressEffect => 0;
}

final class TechniqueObservationSession {
  TechniqueObservationSession.productionForLesson(
    String courseId,
    String lessonId,
  ) : task = TechniqueTasks.forLesson(courseId, lessonId),
      _productionBinding = TechniqueProviderAdapter.forLesson(
        courseId,
        lessonId,
      ),
      _provider = null,
      _profile = null,
      _expectedProviderIdentity = null;

  /// Test seam only, guarded in release. No production constructor takes a
  /// provider/mode toggle or falls back to a replay provider.
  @visibleForTesting
  TechniqueObservationSession.replayForTesting({
    required TechniqueTaskSpec this.task,
    required TechniquePhaseProvider provider,
    required TechniqueCaptureProfile profile,
  }) : _provider = provider,
       _productionBinding = null,
       _profile = profile,
       _expectedProviderIdentity = provider.identity {
    if (kReleaseMode) {
      throw StateError('Replay observation is unavailable in release');
    }
  }

  final TechniqueTaskSpec? task;
  final TechniqueProviderAdapter? _productionBinding;
  final TechniquePhaseProvider? _provider;
  final TechniqueCaptureProfile? _profile;
  final String? _expectedProviderIdentity;
  int _epoch = 0, _phaseIndex = -1;
  int? _lastUs, _startUs;
  String? _context;
  bool _busy = false, _retired = false, _needsReset = false;
  Future<void>? _closing;
  bool get isReplay => _provider != null;
  MotionReadiness get providerReadiness =>
      _productionBinding?.shippingReadiness ?? MotionReadiness.replayOnly;

  TechniqueObservation _result(
    TechniqueObservationKind kind,
    TechniqueObservationReason reason,
  ) => TechniqueObservation(kind: kind, reason: reason, isReplay: isReplay);

  TechniqueObservation get availability =>
      providerReadiness == MotionReadiness.unsupported || task == null
      ? _result(
          TechniqueObservationKind.unsupported,
          TechniqueObservationReason.unsupportedTask,
        )
      : _result(
          TechniqueObservationKind.calibrationRequired,
          TechniqueObservationReason.calibrationMissing,
        );

  void _clearPartial() {
    _phaseIndex = -1;
    _startUs = null;
    _needsReset = true;
  }

  /// Account, provider, camera or lifecycle changes invalidate pending results.
  /// Owners create a new production session when a new provider is admitted.
  void interrupt() {
    _productionBinding?.clear();
    _epoch++;
    _clearPartial();
    _lastUs = null;
    _context = null;
  }

  Future<TechniqueObservation> observe(TechniquePoseSample sample) async {
    if (_retired) {
      return _result(
        TechniqueObservationKind.unobservable,
        TechniqueObservationReason.retired,
      );
    }
    final provider = _provider, spec = task, profile = _profile;
    // No new calibration/acceptance artifact exists. Production never asks the
    // camera or a provider to infer a supposedly supported kb-12 observation.
    if (provider == null || spec == null || profile == null) {
      return availability;
    }
    if (_busy) {
      _epoch++;
      _clearPartial();
      return _result(
        TechniqueObservationKind.uncertain,
        TechniqueObservationReason.providerBusy,
      );
    }
    if (provider.identity != _expectedProviderIdentity) {
      await close();
      return _result(
        TechniqueObservationKind.unobservable,
        TechniqueObservationReason.contextChanged,
      );
    }
    final read = LowerLimbFeatureExtractor.read(spec, profile, sample);
    final features = read.features;
    if (features == null) {
      _clearPartial();
      return _result(TechniqueObservationKind.unobservable, read.reason!);
    }
    final context = sample.context.identity;
    if (_context != null && _context != context) {
      interrupt();
      _context = context;
      return _result(
        TechniqueObservationKind.uncertain,
        TechniqueObservationReason.contextChanged,
      );
    }
    _context = context;
    final last = _lastUs;
    if (last != null &&
        (features.tUs <= last || features.tUs - last > profile.maximumGapUs)) {
      _clearPartial();
      if (features.tUs > last) _lastUs = features.tUs;
      return _result(
        TechniqueObservationKind.uncertain,
        TechniqueObservationReason.clockDiscontinuity,
      );
    }
    _lastUs = features.tUs;
    final epoch = _epoch;
    _busy = true;
    try {
      if (_needsReset) {
        provider.reset();
        _needsReset = false;
      }
      final event = await provider.observe(features);
      if (provider.identity != _expectedProviderIdentity) {
        await close();
        return _result(
          TechniqueObservationKind.unobservable,
          TechniqueObservationReason.contextChanged,
        );
      }
      if (_retired || epoch != _epoch) {
        return _result(
          TechniqueObservationKind.unobservable,
          TechniqueObservationReason.retired,
        );
      }
      if (event == null) {
        _clearPartial();
        return _result(
          TechniqueObservationKind.uncertain,
          TechniqueObservationReason.providerFailure,
        );
      }
      if (event.taskId != spec.id ||
          event.taskSha256 != spec.sha256Digest ||
          event.providerIdentity != _expectedProviderIdentity ||
          event.tUs != features.tUs) {
        _clearPartial();
        return _result(
          TechniqueObservationKind.unsupported,
          TechniqueObservationReason.wrongTask,
        );
      }
      if (event.actualSide != features.actualSide) {
        _clearPartial();
        return _result(
          TechniqueObservationKind.uncertain,
          TechniqueObservationReason.wrongSide,
        );
      }
      final index = spec.phases.indexOf(event.phase);
      if (index < 0) {
        _clearPartial();
        return _result(
          TechniqueObservationKind.unsupported,
          TechniqueObservationReason.wrongPhaseOrder,
        );
      }
      if (index == 0 && _phaseIndex > 0) _clearPartial();
      if (index != _phaseIndex && index != _phaseIndex + 1) {
        _clearPartial();
        return _result(
          TechniqueObservationKind.uncertain,
          TechniqueObservationReason.wrongPhaseOrder,
        );
      }
      if (_phaseIndex == -1) _startUs = features.tUs;
      _phaseIndex = index;
      final complete = index == spec.phases.length - 1;
      final result = TechniqueObservation(
        kind: TechniqueObservationKind.phaseCandidate,
        phase: event.phase,
        startUs: _startUs,
        endUs: features.tUs,
        sequenceCandidateComplete: complete,
        isReplay: true,
      );
      if (complete) _clearPartial();
      return result;
    } catch (_) {
      _clearPartial();
      return _result(
        TechniqueObservationKind.unobservable,
        TechniqueObservationReason.providerFailure,
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> close() {
    _retired = true;
    interrupt();
    return _closing ??= Future<void>.sync(() async {
      final provider = _provider;
      if (provider != null) await provider.close();
    });
  }
}
