import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final rules = loadBoxingRuleSet();
  const rearExtended = SyntheticPose(
    leftUpperArm: 1.35,
    leftForearm: -1.45,
    rightUpperArm: 0,
    rightForearm: 0,
  );
  final frames =
      sequence([
        const SyntheticKeyframe(0, guardPose),
        const SyntheticKeyframe(100000, guardPose),
        const SyntheticKeyframe(220000, rearExtended),
        const SyntheticKeyframe(420000, guardPose),
        const SyntheticKeyframe(650000, guardPose),
      ]).map((frame) {
        final points = List<PoseLandmark>.of(frame.landmarks);
        for (final i in [
          Lm.leftShoulder,
          Lm.leftElbow,
          Lm.leftWrist,
          Lm.leftPinky,
          Lm.leftIndex,
          Lm.leftThumb,
        ]) {
          points[i] = points[i].copyWith(y: points[i].y - .025);
        }
        for (final i in [
          Lm.rightShoulder,
          Lm.rightElbow,
          Lm.rightWrist,
          Lm.rightPinky,
          Lm.rightIndex,
          Lm.rightThumb,
        ]) {
          points[i] = points[i].copyWith(y: points[i].y + .025);
        }
        return frame.copyWith(landmarks: points);
      }).toList();
  List<AttemptDigest> completed(Set<String>? ids) {
    final engine = StrikingEngine(ruleSet: rules, allowedTechniqueIds: ids);
    return [
      for (final frame in frames)
        if (engine.process(frame).completedAttempt case final attempt?) attempt,
    ];
  }

  test(
    'synthetic rear-only sequence with shoulder projection is a positive cross control',
    () {
      expect(completed({'cross'}).map((a) => a.techniqueId), ['cross']);
    },
  );
  test('cross cannot complete or fall back in a jab-only lesson', () {
    expect(completed({'jab'}), isEmpty);
  });
  test('setup/stance camera task does not count an unrelated punch', () {
    expect(completed({}), isEmpty);
  });
  test('unknown technique IDs fail closed', () {
    expect(
      () => StrikingEngine(
        ruleSet: rules,
        allowedTechniqueIds: {'low_front_kick'},
      ),
      throwsArgumentError,
    );
  });
  test('caller mutation cannot change a running engine selection', () {
    final ids = <String>{'jab'};
    final engine = StrikingEngine(ruleSet: rules, allowedTechniqueIds: ids);
    ids.add('cross');
    final attempts = [
      for (final f in frames)
        if (engine.process(f).completedAttempt case final attempt?) attempt,
    ];
    expect(attempts, isEmpty);
  });
}
