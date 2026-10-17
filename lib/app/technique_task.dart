import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:motion_core/motion_core.dart' show Lm;

import 'pose_model.dart';
import 'kickboxing_course.dart';

enum TechniqueSide { left, right }

enum TechniqueView { leftProfile, rightProfile, frontOblique, unknown }

enum LandmarkSideMapping { anatomical, swapped, unknown }

enum TechniquePhase { preparation, extension, retraction, returnToStart }

/// App-owned lesson intent. It never guesses a technique from a lesson title.
/// Provider admission/readiness belongs to the shared Core contract; this
/// specification only binds the task that an admitted provider must observe.
final class TechniqueTaskSpec {
  TechniqueTaskSpec({
    required this.id,
    required this.version,
    required this.courseId,
    required this.lessonId,
    required this.techniqueId,
    required this.variant,
    required this.courseSha256,
    required this.modelId,
    required this.modelSha256,
    required List<TechniqueView> views,
    required List<TechniquePhase> phases,
  }) : views = List.unmodifiable(views),
       phases = List.unmodifiable(phases) {
    if ([
          id,
          courseId,
          lessonId,
          techniqueId,
          variant,
          modelId,
        ].any((s) => s.trim().isEmpty) ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(courseSha256) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(modelSha256) ||
        views.isEmpty ||
        views.contains(TechniqueView.unknown) ||
        views.toSet().length != views.length ||
        phases.length < 2 ||
        phases.toSet().length != phases.length) {
      throw const FormatException('Invalid technique task specification');
    }
  }

  static const schemaVersion = 1;
  static const inputSchema = 'body33.image.v1';
  static const coordinateSpace = 'image2d.aspectCorrected';
  final String id, version, courseId, lessonId, techniqueId, variant;
  final String courseSha256, modelId, modelSha256;
  final List<TechniqueView> views;
  final List<TechniquePhase> phases;

  // Both limbs must be visible; body-pose data cannot measure support force,
  // contact, pain, toe articulation, impact or suitability for the learner.
  static const requiredLandmarks = [
    Lm.leftShoulder,
    Lm.rightShoulder,
    Lm.leftHip,
    Lm.rightHip,
    Lm.leftKnee,
    Lm.rightKnee,
    Lm.leftAnkle,
    Lm.rightAnkle,
  ];

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'version': version,
    'courseId': courseId,
    'lessonId': lessonId,
    'techniqueId': techniqueId,
    'variant': variant,
    'courseSha256': courseSha256,
    'modelId': modelId,
    'modelSha256': modelSha256,
    'inputSchema': inputSchema,
    'coordinateSpace': coordinateSpace,
    'views': views.map((v) => v.name).toList(),
    'phases': phases.map((v) => v.name).toList(),
    'requiredLandmarks': requiredLandmarks,
  };

  String get sha256Digest =>
      sha256.convert(utf8.encode(jsonEncode(toJson()))).toString();
  bool belongsTo(String course, String lesson) =>
      courseId == course && lessonId == lesson;
}

abstract final class TechniqueTasks {
  static final lowFrontKick = TechniqueTaskSpec(
    id: 'jablab.kickboxing.low-front-kick',
    version: '1.0.0',
    courseId: 'jablab.kickboxing_a',
    lessonId: 'kb-12',
    techniqueId: 'low_front_kick',
    variant: 'supported_non_contact',
    courseSha256: KickboxingCourse.reviewedAssetSha256,
    modelId: PoseModelPin.modelId,
    modelSha256: PoseModelPin.sha256,
    views: [TechniqueView.leftProfile, TechniqueView.rightProfile],
    phases: [
      TechniquePhase.preparation,
      TechniquePhase.extension,
      TechniquePhase.retraction,
      TechniquePhase.returnToStart,
    ],
  );

  static TechniqueTaskSpec? forLesson(String courseId, String lessonId) =>
      lowFrontKick.belongsTo(courseId, lessonId) ? lowFrontKick : null;
}

/// Actual anatomical side and display mirroring are separate inputs. Neither
/// a screen-left point nor a selected stance proves actual left/right mapping.
final class TechniqueCaptureContext {
  const TechniqueCaptureContext({
    required this.actualSide,
    required this.leadSide,
    required this.view,
    required this.sideMapping,
    this.displayMirrored = false,
  });
  final TechniqueSide? actualSide, leadSide;
  final TechniqueView view;
  final LandmarkSideMapping sideMapping;
  final bool displayMirrored;
  bool? get isLead =>
      actualSide == null || leadSide == null ? null : actualSide == leadSide;
  String get identity =>
      '${actualSide?.name}/${leadSide?.name}/${view.name}/${sideMapping.name}/$displayMirrored';
}
