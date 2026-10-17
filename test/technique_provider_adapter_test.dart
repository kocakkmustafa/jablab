import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/technique_observation.dart';
import 'package:jablab/app/technique_provider_adapter.dart';
import 'package:jablab/app/technique_task.dart';
import 'package:motion_core/motion_core.dart';

// Isolated synthetic bytes prove consumer contract logic, not model accuracy.
final modelBytes = Uint8List.fromList([1, 2, 3]);
final calibrationBytes = Uint8List.fromList([4, 5, 6]);
final acceptance = sha256.convert([7, 8, 9]).toString();
TechniqueTaskSpec task({String version = '1.0.0'}) => TechniqueTaskSpec(
  id: 'synthetic.jablab.task',
  version: version,
  courseId: 'synthetic.course',
  lessonId: 'synthetic.lesson',
  techniqueId: 'synthetic.technique',
  variant: 'synthetic.variant',
  courseSha256: sha256.convert([10]).toString(),
  modelId: 'synthetic.pose',
  modelSha256: sha256.convert(modelBytes).toString(),
  views: [TechniqueView.leftProfile],
  phases: [TechniquePhase.preparation, TechniquePhase.extension],
);
TechniqueProviderArtifacts artifacts({
  Uint8List? model,
  Uint8List? calibration,
  String? reviewed,
}) => TechniqueProviderArtifacts.fromLoadedBytes(
  modelBytes: model ?? modelBytes,
  calibrationBytes: calibration ?? calibrationBytes,
  reviewedAcceptanceSha256: reviewed ?? acceptance,
);
MotionProviderManifest manifest(
  TechniqueProviderAdapter adapter, {
  String version = '1.0.0',
  MotionProviderMode mode = MotionProviderMode.production,
  MotionCapabilityState state = MotionCapabilityState.validated,
  String? capability,
  String? model,
  String? abi,
  String? input,
  String? space,
}) => MotionProviderManifest(
  providerId: 'synthetic.jablab.provider',
  providerVersion: version,
  mode: mode,
  runtimeAbi: abi ?? TechniqueProviderAdapter.runtimeAbi,
  inputSchema: input ?? TechniqueTaskSpec.inputSchema,
  coordinateSpace: space ?? TechniqueTaskSpec.coordinateSpace,
  modelSha256: model ?? sha256.convert(modelBytes).toString(),
  capabilities: {
    capability ?? adapter.capabilityKey ?? 'unknown': MotionCapability(
      state: state,
      calibrationSha256: sha256.convert(calibrationBytes).toString(),
      acceptanceSha256: acceptance,
    ),
  },
);

void main() {
  test(
    'shipping kb-12 uses Core calibration-required, never selects provider',
    () async {
      expect(MotionProviderManifest.contractVersion, '1.0.0');
      final adapter = TechniqueProviderAdapter.forLesson(
        'jablab.kickboxing_a',
        'kb-12',
      );
      expect(adapter.shippingManifest.mode, MotionProviderMode.production);
      expect(
        adapter.capabilityKey,
        contains(TechniqueTasks.lowFrontKick.sha256Digest),
      );
      expect(adapter.shippingReadiness, MotionReadiness.calibrationRequired);
      expect(
        adapter.select(adapter.shippingManifest),
        MotionReadiness.calibrationRequired,
      );
      expect(adapter.active, isNull);
      final session = TechniqueObservationSession.productionForLesson(
        'jablab.kickboxing_a',
        'kb-12',
      );
      expect(session.providerReadiness, MotionReadiness.calibrationRequired);
      expect(
        session.availability.kind,
        TechniqueObservationKind.calibrationRequired,
      );
      expect(session.availability.isReplay, isFalse);
      expect(session.availability.progressEffect, 0);
      session.interrupt();
      expect(session.providerReadiness, MotionReadiness.calibrationRequired);
      await session.close();
    },
  );

  test(
    'unknown branch/lesson cannot acquire a capability even with matching test bytes',
    () async {
      final adapter = TechniqueProviderAdapter.forLesson(
        'jablab.karate_a',
        'kb-12',
      );
      expect(adapter.capabilityKey, isNull);
      expect(adapter.shippingReadiness, MotionReadiness.unsupported);
      expect(
        adapter.select(manifest(adapter), artifacts: artifacts()),
        MotionReadiness.unsupported,
      );
      expect(adapter.active, isNull);
      final session = TechniqueObservationSession.productionForLesson(
        'jablab.karate_a',
        'kb-12',
      );
      expect(session.providerReadiness, MotionReadiness.unsupported);
      await session.close();
    },
  );

  test(
    'receipt hashes actual view bytes, not candidate values, and snapshots them',
    () {
      final backing = Uint8List.fromList([99, 1, 2, 3, 99]);
      final view = Uint8List.sublistView(backing, 1, 4);
      final receipt = artifacts(model: view);
      expect(receipt.actualModelSha256, sha256.convert(modelBytes).toString());
      expect(
        receipt.actualCalibrationSha256,
        sha256.convert(calibrationBytes).toString(),
      );
      backing[1] = 50;
      expect(receipt.actualModelSha256, sha256.convert(modelBytes).toString());
      expect(
        receipt.actualModelSha256,
        isNot(artifacts(model: view).actualModelSha256),
      );
    },
  );

  test('declarations alone cannot create loaded-byte or reviewed receipts', () {
    final adapter = TechniqueProviderAdapter.forTask(task());
    final candidate = manifest(adapter);
    expect(adapter.select(candidate), MotionReadiness.artifactMismatch);
    final missingCalibration = TechniqueProviderArtifacts.fromLoadedBytes(
      modelBytes: modelBytes,
      reviewedAcceptanceSha256: acceptance,
    );
    expect(
      adapter.select(candidate, artifacts: missingCalibration),
      MotionReadiness.artifactMismatch,
    );
    final missingReview = TechniqueProviderArtifacts.fromLoadedBytes(
      modelBytes: modelBytes,
      calibrationBytes: calibrationBytes,
      reviewedAcceptanceSha256: null,
    );
    expect(
      adapter.select(candidate, artifacts: missingReview),
      MotionReadiness.acceptanceRequired,
    );
    expect(adapter.active, isNull);
  });

  test(
    'matching synthetic bytes and separately supplied synthetic review satisfy contract only',
    () {
      final adapter = TechniqueProviderAdapter.forTask(task());
      final candidate = manifest(adapter);
      expect(
        adapter.inspect(candidate, artifacts: artifacts()),
        MotionReadiness.ready,
      );
      expect(adapter.active, isNull, reason: 'Inspect must not select');
      expect(
        adapter.select(candidate, artifacts: artifacts()),
        MotionReadiness.ready,
      );
      expect(adapter.active, same(candidate));
      expect(adapter.previous, isNull);
    },
  );

  test('same task name with changed task version/hash is unsupported', () {
    final adapter = TechniqueProviderAdapter.forTask(task());
    final other = TechniqueProviderAdapter.forTask(task(version: '1.1.0'));
    expect(
      adapter.select(
        manifest(adapter, capability: other.capabilityKey),
        artifacts: artifacts(),
      ),
      MotionReadiness.unsupported,
    );
    expect(adapter.active, isNull);
  });

  test(
    'matching candidate and loaded different model cannot bypass task pin',
    () {
      final adapter = TechniqueProviderAdapter.forTask(task());
      final other = Uint8List.fromList([44, 55]);
      final candidate = manifest(
        adapter,
        model: sha256.convert(other).toString(),
      );
      expect(
        adapter.select(candidate, artifacts: artifacts(model: other)),
        MotionReadiness.artifactMismatch,
      );
      expect(adapter.active, isNull);
    },
  );

  test(
    'production requirement rejects replay even when all synthetic hashes match',
    () {
      final adapter = TechniqueProviderAdapter.forTask(task());
      expect(
        adapter.select(
          manifest(adapter, mode: MotionProviderMode.replay),
          artifacts: artifacts(),
        ),
        MotionReadiness.replayOnly,
      );
      expect(adapter.active, isNull);
    },
  );

  for (final field in ['abi', 'input', 'space']) {
    test('consumer $field cannot silently adapt a candidate', () {
      final adapter = TechniqueProviderAdapter.forTask(task());
      expect(
        adapter.select(
          manifest(
            adapter,
            abi: field == 'abi' ? 'other' : null,
            input: field == 'input' ? 'other' : null,
            space: field == 'space' ? 'other' : null,
          ),
          artifacts: artifacts(),
        ),
        MotionReadiness.incompatible,
      );
      expect(adapter.active, isNull);
    });
  }

  for (final state in [
    MotionCapabilityState.unsupported,
    MotionCapabilityState.calibrationRequired,
  ]) {
    test('non-ready $state stays closed with matching synthetic receipts', () {
      final adapter = TechniqueProviderAdapter.forTask(task());
      expect(
        adapter.select(manifest(adapter, state: state), artifacts: artifacts()),
        state == MotionCapabilityState.unsupported
            ? MotionReadiness.unsupported
            : MotionReadiness.calibrationRequired,
      );
      expect(adapter.active, isNull);
    });
  }

  test(
    'rejected candidate preserves active/previous; explicit rollback rehashes current bytes',
    () {
      final adapter = TechniqueProviderAdapter.forTask(task());
      final first = manifest(adapter),
          second = manifest(adapter, version: '1.1.0');
      expect(
        adapter.rollback(artifacts: artifacts()),
        MotionReadiness.unsupported,
      );
      expect(
        adapter.select(first, artifacts: artifacts()),
        MotionReadiness.ready,
      );
      expect(
        adapter.select(second, artifacts: artifacts()),
        MotionReadiness.ready,
      );
      expect(
        adapter.select(
          manifest(adapter, space: 'other'),
          artifacts: artifacts(),
        ),
        MotionReadiness.incompatible,
      );
      expect(adapter.active, same(second));
      expect(adapter.previous, same(first));
      expect(
        adapter.rollback(
          artifacts: artifacts(calibration: Uint8List.fromList([99])),
        ),
        MotionReadiness.artifactMismatch,
      );
      expect(adapter.active, same(second));
      expect(adapter.previous, same(first));
      expect(
        adapter.rollback(artifacts: artifacts(reviewed: '0' * 64)),
        MotionReadiness.acceptanceRequired,
      );
      expect(adapter.active, same(second));
      expect(adapter.rollback(artifacts: artifacts()), MotionReadiness.ready);
      expect(adapter.active, same(first));
      expect(adapter.previous, same(second));
    },
  );

  test(
    'clear retires active and rollback identity on resource owner change',
    () {
      final adapter = TechniqueProviderAdapter.forTask(task());
      adapter.select(manifest(adapter), artifacts: artifacts());
      adapter.select(
        manifest(adapter, version: '1.1.0'),
        artifacts: artifacts(),
      );
      adapter.clear();
      expect(adapter.active, isNull);
      expect(adapter.previous, isNull);
      expect(
        adapter.rollback(artifacts: artifacts()),
        MotionReadiness.unsupported,
      );
    },
  );

  test('empty artifact or malformed review digest cannot create a receipt', () {
    expect(() => artifacts(model: Uint8List(0)), throwsFormatException);
    expect(() => artifacts(calibration: Uint8List(0)), throwsFormatException);
    expect(() => artifacts(reviewed: 'invalid'), throwsFormatException);
  });
}
