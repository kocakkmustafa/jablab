import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:motion_core/motion_core.dart';

import 'pose_model.dart';
import 'technique_task.dart';

/// Actual loaded-byte digests. Candidate declarations cannot create this
/// receipt. The acceptance digest must come from separate app-owned review;
/// this metadata is not a signature verifier or an accuracy attestation.
final class TechniqueProviderArtifacts {
  TechniqueProviderArtifacts.fromLoadedBytes({
    required Uint8List modelBytes,
    Uint8List? calibrationBytes,
    required this.reviewedAcceptanceSha256,
  }) : actualModelSha256 = sha256.convert(modelBytes).toString(),
       actualCalibrationSha256 = calibrationBytes == null
           ? null
           : sha256.convert(calibrationBytes).toString() {
    if (modelBytes.isEmpty ||
        calibrationBytes?.isEmpty == true ||
        (reviewedAcceptanceSha256 != null &&
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(reviewedAcceptanceSha256!))) {
      throw const FormatException('Invalid loaded provider artifacts');
    }
  }

  final String actualModelSha256;
  final String? actualCalibrationSha256, reviewedAcceptanceSha256;
}

/// App-owned task/model binding around Core's admission and explicit rollback.
/// It does not duplicate the common readiness/selection algorithm or perform
/// inference. The shipping declaration is permanently non-ready in this release.
final class TechniqueProviderAdapter {
  TechniqueProviderAdapter.forTask(this.task);
  TechniqueProviderAdapter.forLesson(String courseId, String lessonId)
    : task = TechniqueTasks.forLesson(courseId, lessonId);

  static const runtimeAbi = 'jablab.technique-phase/1.0.0';
  final TechniqueTaskSpec? task;
  final _selection = MotionProviderSelection();

  /// Includes the reviewed course/model/phase/view identity via the task digest.
  /// Same title or technique ID with different source is a different capability.
  String? get capabilityKey {
    final spec = task;
    return spec == null
        ? null
        : '${spec.id}@${spec.version}#${spec.sha256Digest}';
  }

  MotionProviderManifest get shippingManifest => MotionProviderManifest(
    providerId: 'jablab.technique-phase',
    providerVersion: '1.0.0',
    mode: MotionProviderMode.production,
    runtimeAbi: runtimeAbi,
    inputSchema: TechniqueTaskSpec.inputSchema,
    coordinateSpace: TechniqueTaskSpec.coordinateSpace,
    modelSha256: PoseModelPin.sha256, // A declaration, not loaded-byte proof.
    capabilities: {
      if (capabilityKey case final key?)
        key: const MotionCapability(
          state: MotionCapabilityState.calibrationRequired,
        ),
    },
  );

  MotionReadiness get shippingReadiness => inspect(shippingManifest);
  MotionProviderManifest? get active => _selection.active;
  MotionProviderManifest? get previous => _selection.previous;

  MotionProviderRequirement _requirement(
    TechniqueProviderArtifacts? artifacts,
  ) => MotionProviderRequirement(
    capability: capabilityKey!,
    runtimeAbi: runtimeAbi,
    inputSchema: TechniqueTaskSpec.inputSchema,
    coordinateSpace: TechniqueTaskSpec.coordinateSpace,
    // The task pins a model. Matching arbitrary candidate/loaded bytes
    // must not substitute a different model into this reviewed task.
    actualModelSha256: artifacts?.actualModelSha256 == task!.modelSha256
        ? artifacts?.actualModelSha256
        : null,
    actualCalibrationSha256: artifacts?.actualCalibrationSha256,
    reviewedAcceptanceSha256: artifacts?.reviewedAcceptanceSha256,
    // Fixed production requirement; no mode preference or replay fallback.
  );

  MotionReadiness inspect(
    MotionProviderManifest candidate, {
    TechniqueProviderArtifacts? artifacts,
  }) => task == null
      ? MotionReadiness.unsupported
      : _requirement(artifacts).inspect(candidate);

  /// No shipping caller supplies a trained provider or acceptance receipt yet.
  /// Future owners must retire observation/camera and open a fresh session on
  /// an admitted model/calibration/account/lifecycle identity change.
  MotionReadiness select(
    MotionProviderManifest candidate, {
    TechniqueProviderArtifacts? artifacts,
  }) => task == null
      ? MotionReadiness.unsupported
      : _selection.select(candidate, _requirement(artifacts));

  MotionReadiness rollback({TechniqueProviderArtifacts? artifacts}) =>
      task == null
      ? MotionReadiness.unsupported
      : _selection.rollback(_requirement(artifacts));

  void clear() => _selection.clear();
}
