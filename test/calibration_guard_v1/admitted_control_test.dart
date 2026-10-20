// Synthetic protocol controls for the admitted presentation branch. The actual
// controller, owned native wire and second actual engine are used; changing
// metadata labels does not establish physical calibration or camera admission.
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/shell_candidate/live_surface.dart' show LiveState;

import 'guard_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(LiveJabController.debugResetCameraLock);
  late Map<String, dynamic> source;
  setUpAll(() async {
    source = await loadRulesJson();
  });

  GuardFixture admittedFixture() {
    final fixture = GuardFixture(
      rulesVariant(source, pending: false, status: 'calibrated'),
    );
    addTearDown(fixture.close);
    expect(fixture.rules.calibrationPending, isFalse);
    expect(fixture.rules.thresholdStatus, 'calibrated');
    return fixture;
  }

  test(
    'AC-01 synthetic admitted metadata preserves a real technical cue',
    () async {
      final f = admittedFixture();
      expect(await f.start(), isNull);
      await f.emitAll(steadyFrames());
      expectFirstIssue(f, 'STANCE_TOO_NARROW', 'A');
      final technical = f.raw.samples.where((sample) {
        final output = sample.output;
        return output != null &&
            output.judgeable &&
            output.issues.isNotEmpty &&
            !jabLabVisibilityIssueCodes.contains(output.issues.first.code);
      }).toList();
      expect(
        technical,
        isNotEmpty,
        reason: 'An actually first raw technical issue must reach presentation',
      );
      for (final sample in technical) {
        final code = sample.output!.issues.first.code;
        final key = jabLabIssueCueMapping[code];
        expect(key, isNotNull);
        expect(sample.state.surface, LiveState.correcting);
        expect(sample.state.cue, 'technical:$code');
        expect(sample.state.noVerdictReason, isNull);
        expect(sample.state.completedCount, sample.completedCount);
        expect(sample.state.phase, sample.output!.activePhase);
        expect(f.cues.keyCalls, contains(key));
      }
      expect(f.cues.technicalCalls, isNotEmpty);
    },
  );

  test(
    'AC-02 synthetic admitted metadata preserves a real empty-issue clean state',
    () async {
      final f = admittedFixture();
      expect(await f.start(), isNull);
      await f.emitAll(steadyFrames());
      final empty = f.raw.samples.where((sample) {
        final output = sample.output;
        return output != null && output.judgeable && output.issues.isEmpty;
      }).toList();
      expect(
        empty,
        isNotEmpty,
        reason:
            'No clean-branch claim from an absent or unjudgeable raw output',
      );
      for (final sample in empty) {
        expect(sample.state.surface, LiveState.clean);
        expect(sample.state.cue, isNull);
        expect(sample.state.noVerdictReason, isNull);
        expect(sample.state.completedCount, sample.completedCount);
        expect(sample.state.phase, sample.output!.activePhase);
      }
    },
  );

  test(
    'AC-03 synthetic admitted metadata preserves actual completion-code-change narration',
    () async {
      final f = admittedFixture();
      final frames = correctedOpportunityFrames(f.rules);
      expect(await f.start(), isNull);
      // Test-only cooldown re-arm matches the raw witness helper. This is not an
      // ordinary production round or a new admissible FPS/physical threshold.
      await f.emitAll(frames, rearm: true);
      expectRawCorrectedOpportunity(f);
      final completed = f.raw.samples
          .where(
            (sample) => sample.output?.completedAttempt?.completed ?? false,
          )
          .toList();
      expect(completed.length, greaterThanOrEqualTo(2));
      final first = completed.first;
      expect(first.completedCount, 1);
      expect(first.state.narration, isNot(correctedMarker));
      final prefix = f.raw.samples
          .takeWhile((sample) => sample.tUs <= first.tUs)
          .toList();
      expect(prefix, isNotEmpty);
      expect(prefix.last.tUs, first.tUs);
      expect(
        prefix.every((sample) => sample.state.narration != correctedMarker),
        isTrue,
        reason: 'No corrected narration before or at the first completion',
      );

      String? previous;
      var completionCount = 0;
      var opportunities = 0;
      for (final sample in f.raw.samples) {
        final output = sample.output;
        if (output == null) {
          previous = null;
          expect(sample.state.narration, isNot(correctedMarker));
          continue;
        }
        var opportunity = false;
        if (output.completedAttempt?.completed ?? false) {
          completionCount += 1;
          final current = output.issues.isEmpty
              ? null
              : output.issues.first.code;
          opportunity =
              previous != null &&
              current != previous &&
              !jabLabVisibilityIssueCodes.contains(previous);
          previous = current;
        }
        expect(sample.state.completedCount, completionCount);
        expect(sample.completedCount, completionCount);
        if (opportunity) {
          opportunities += 1;
          expect(
            sample.state.narration,
            correctedMarker,
            reason:
                'The actual completion-code-change state must carry narration',
          );
        } else {
          expect(sample.state.narration, isNot(correctedMarker));
        }
        // Match the existing controller ordering: completion bookkeeping happens
        // before unreliable observations retire the partial comparison history.
        if (!output.judgeable) {
          previous = null;
        }
      }
      expect(
        opportunities,
        greaterThan(0),
        reason:
            'The admitted corrected path needs a real, non-vacuous opportunity',
      );
      expect(completionCount, completed.length);
      expect(f.raw.count, completionCount);
      expect(f.runs.last.completedCount, completionCount);
      expect(
        f.cues.keyCalls.where((key) => key == jabLabCorrectedCueKey),
        hasLength(opportunities),
      );
      expect(
        f.runs.where((state) => state.narration == correctedMarker),
        hasLength(opportunities),
      );
    },
  );
}
