import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Offline logic regression only. These hand-built skeletons are not people,
/// camera recordings, independently labelled data, or a model validation set.
void main() {
  final RuleSet rules = loadBoxingRuleSet();

  ({List<String> events, Set<String> issues}) detected(List<PoseFrame> frames) {
    final StrikingEngine engine = StrikingEngine(
      ruleSet: rules,
      calibrationMapped: true,
      provenance: const <String, String>{'poseModelVariant': 'synthetic'},
    );
    final List<String> events = <String>[];
    final Set<String> issues = <String>{};
    for (final PoseFrame frame in frames) {
      final EngineOutput output = engine.process(frame);
      final AttemptDigest? attempt = output.completedAttempt;
      if (attempt != null) events.add(attempt.techniqueId);
      issues.addAll(output.issues.map((DetectedIssue issue) => issue.code));
    }
    return (events: events, issues: issues);
  }

  List<PoseFrame> swing(int riseUs) => sequence(<SyntheticKeyframe>[
    SyntheticKeyframe(0, guardPose),
    SyntheticKeyframe(100000, guardPose),
    SyntheticKeyframe(100000 + riseUs, SyntheticPose.neutral),
    SyntheticKeyframe(100000 + 2 * riseUs, guardPose),
    SyntheticKeyframe(300000 + 2 * riseUs, guardPose),
  ]);

  final SyntheticPose leadStraight = extendedPose.copyWith(
    rightUpperArm: guardPose.rightUpperArm,
    rightForearm: guardPose.rightForearm,
  );

  List<PoseFrame> straight(int riseUs) => sequence(<SyntheticKeyframe>[
    SyntheticKeyframe(0, guardPose),
    SyntheticKeyframe(200000, guardPose),
    SyntheticKeyframe(200000 + riseUs, leadStraight),
    SyntheticKeyframe(400000 + riseUs, guardPose),
    SyntheticKeyframe(650000 + riseUs, guardPose),
  ]);

  test(
    'named synthetic negative controls and positive controls gate events',
    () {
      final List<({String name, bool jabExpected, List<PoseFrame> frames})>
      controls = [
        (
          name: 'guard',
          jabExpected: false,
          frames: straight(120000).take(6).toList(),
        ),
        (
          name: 'downward_swing_250ms',
          jabExpected: false,
          frames: swing(250000),
        ),
        (
          name: 'downward_swing_300ms',
          jabExpected: false,
          frames: swing(300000),
        ),
        (
          name: 'downward_swing_500ms',
          jabExpected: false,
          frames: swing(500000),
        ),
        (
          name: 'straight_jab_120ms',
          jabExpected: true,
          frames: straight(120000),
        ),
        (
          name: 'straight_jab_180ms',
          jabExpected: true,
          frames: straight(180000),
        ),
        (
          name: 'straight_jab_250ms',
          jabExpected: true,
          frames: straight(250000),
        ),
      ];

      final List<String> falsePositives = <String>[];
      final List<String> falseNegatives = <String>[];
      for (final control in controls) {
        final result = detected(control.frames);
        final List<String> events = result.events;
        // This test's replay receipt includes each negative control result.
        // ignore: avoid_print
        print(
          '${control.name}: expected=${control.jabExpected ? "jab" : "none"} '
          'observed=${events.isEmpty ? "none" : events.join(",")} '
          'issues=${result.issues.join(",")}',
        );
        if (control.jabExpected) {
          if (events.length != 1 || events.single != 'jab') {
            falseNegatives.add('${control.name}=${events.join(",")}');
          }
        } else if (events.isNotEmpty) {
          falsePositives.add('${control.name}=${events.join(",")}');
        }
      }

      // ignore: avoid_print
      print(
        'synthetic_gate: cases=${controls.length} '
        'false_positives=${falsePositives.length} '
        'missed_or_extra_positive_events=${falseNegatives.length}',
      );

      expect(
        falsePositives,
        isEmpty,
        reason: 'Sentetik negatif harekete olay atandı: $falsePositives',
      );
      expect(
        falseNegatives,
        isEmpty,
        reason: 'Sentetik düz yumruk kayboldu: $falseNegatives',
      );
    },
  );
}
