import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';

SyntheticPoseBuilder builder() => const SyntheticPoseBuilder();

/// Gard: her iki kol da dirsekten katlı, eller çene hizasında.
const SyntheticPose guardPose = SyntheticPose(
  leftUpperArm: 1.35,
  leftForearm: -1.45,
  rightUpperArm: 1.75,
  rightForearm: -1.65,
);

/// Tam uzanma: iki kol da düz ileri (aynı açı = kol tamamen açık).
const SyntheticPose extendedPose = SyntheticPose(
  leftUpperArm: 0.0,
  leftForearm: 0.0,
  rightUpperArm: 0.0,
  rightForearm: 0.0,
);

/// Yarı yol — faz geçişlerinin arasını doldurur.
const SyntheticPose midPose = SyntheticPose(
  leftUpperArm: 0.65,
  leftForearm: -0.30,
  rightUpperArm: 0.75,
  rightForearm: -0.40,
);

/// Kareyi bir noktaya göre ölçekler (kamera mesafesi değişimi vekili).
PoseFrame scaleFrame(PoseFrame f, double k) => PoseFrame(
      tUs: f.tUs,
      modelVersion: f.modelVersion,
      landmarks: f.landmarks
          .map((PoseLandmark l) =>
              PoseLandmark(l.x * k, l.y * k, l.z * k, l.visibility))
          .toList(growable: false),
    );

/// Bir landmark'ı elle taşır — anatomik imkânsızlık üretmek için.
PoseFrame moveLandmark(PoseFrame f, int index, double dx, double dy) {
  final List<PoseLandmark> lms = List<PoseLandmark>.from(f.landmarks);
  final PoseLandmark l = lms[index];
  lms[index] = PoseLandmark(l.x + dx, l.y + dy, l.z, l.visibility);
  return PoseFrame(tUs: f.tUs, landmarks: lms, modelVersion: f.modelVersion);
}

/// Gerçek `boxing@1.0.0` config'ini yükler — testler kopya config kullanmaz,
/// çünkü ship edilen dosyanın kendisi sınanmalı.
RuleSet loadBoxingRuleSet() {
  final File f = File('../../assets/rulesets/boxing@1.0.0.json');
  final Map<String, dynamic> json =
      (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>();
  return RuleSet.fromJson(json);
}

/// Anahtar karelerden kare dizisi üretir.
List<PoseFrame> sequence(List<SyntheticKeyframe> keys, {int fps = 30}) {
  final SyntheticSequence seq = SyntheticSequence(keys);
  final int stepUs = (1000000 / fps).round();
  final List<PoseFrame> out = <PoseFrame>[];
  for (int t = seq.startUs; t <= seq.endUs; t += stepUs) {
    out.add(builder().build(seq.poseAt(t), tUs: t));
  }
  return out;
}
