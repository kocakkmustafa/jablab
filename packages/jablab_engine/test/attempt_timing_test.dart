import 'package:jablab_engine/jablab_engine.dart';
import 'package:jablab_engine/src/attempt_timing.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

AttemptRun run(
  List<(String, int)> entries, {
  AttemptOutcome outcome = AttemptOutcome.completed,
}) => AttemptRun(
  techniqueId: 'timing-fixture',
  outcome: outcome,
  startedAtUs: entries.isEmpty ? 0 : entries.first.$2,
  endedAtUs: entries.isEmpty ? 0 : entries.last.$2,
  transitions: <PhaseTransition>[
    for (int i = 0; i < entries.length; i++)
      PhaseTransition(
        fromPhase: i == 0 ? null : entries[i - 1].$1,
        toPhase: entries[i].$1,
        tUs: entries[i].$2,
        phaseIndex: i,
      ),
  ],
);

void main() {
  test('legacy constructor remains valid without the optional timing field', () {
    const digest = AttemptDigest(
      techniqueId: 'legacy',
      limb: Side.lead,
      outcome: AttemptOutcome.completed,
      transitions: <String, int>{},
      snapshots: <String, MeasureSet>{},
      extensionMs: 1120,
      tempoBand: 'controlled',
      provenance: <String, String>{},
    );
    expect(digest.extensionMs, 1120);
    expect(digest.extensionToPeakMs, isNull);
  });

  test('named interval excludes guard, shoulder rotation and recovery', () {
    final result = extensionToPeakDurationMs(run(<(String, int)>[
      ('GUARD_READY', 0),
      ('REAR_SHOULDER_ROTATION', 500000),
      ('EXTENSION', 1000000),
      ('PEAK', 1120000),
      ('RETRACTION', 1200000),
      ('GUARD_RECOVERED', 1300000),
    ]));
    expect(result, 120);
  });

  test('microseconds retain fractional milliseconds', () {
    expect(extensionToPeakDurationMs(run(<(String, int)>[
      ('EXTENSION', 1000001), ('PEAK', 1123457),
    ])), closeTo(123.456, .000001));
  });

  test('zero is a valid timestamp, but zero duration is not', () {
    expect(extensionToPeakDurationMs(run(<(String, int)>[
      ('EXTENSION', 0), ('PEAK', 120000),
    ])), 120);
  });

  final invalid = <String, List<(String, int)>>{
    'empty': <(String, int)>[],
    'missing extension': [('GUARD_READY', 0), ('PEAK', 120000)],
    'missing peak': [('GUARD_READY', 0), ('EXTENSION', 100000)],
    'fallback has neither boundary': [
      ('GUARD_READY', 0), ('STRIKE_WINDOW', 100000),
      ('GUARD_RECOVERED', 300000),
    ],
    'duplicate extension': [
      ('EXTENSION', 100000), ('EXTENSION', 110000), ('PEAK', 220000),
    ],
    'duplicate peak': [
      ('EXTENSION', 100000), ('PEAK', 200000), ('PEAK', 220000),
    ],
    'peak before extension': [('PEAK', 100000), ('EXTENSION', 220000)],
    'equal boundary timestamps': [('EXTENSION', 100000), ('PEAK', 100000)],
    'backward boundary timestamp': [('EXTENSION', 200000), ('PEAK', 100000)],
    'backward timestamp before interval': [
      ('GUARD_READY', 200000), ('EXTENSION', 100000), ('PEAK', 220000),
    ],
    'backward timestamp after interval': [
      ('EXTENSION', 100000), ('PEAK', 220000), ('GUARD_RECOVERED', 210000),
    ],
  };
  for (final entry in invalid.entries) {
    test('invalid timing is unavailable: ${entry.key}', () {
      expect(extensionToPeakDurationMs(run(entry.value)), isNull);
    });
  }
  for (final outcome in <AttemptOutcome>[
    AttemptOutcome.timedOut, AttemptOutcome.aborted, AttemptOutcome.lostTracking,
  ]) {
    test('incomplete outcome has no tempo interval: ${outcome.name}', () {
      expect(extensionToPeakDurationMs(run(<(String, int)>[
        ('EXTENSION', 100000), ('PEAK', 220000),
      ], outcome: outcome)), isNull);
    });
  }
}
