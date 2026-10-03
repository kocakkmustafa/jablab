import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/live_session_failure.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';

import 'support/owned_native_fixture.dart';

/// Başlangıç sürerken kapanış: izin ve model çözümü native çağrıdan ÖNCE
/// bekleyebilir. Native plugin yalnız kendisine gönderilmiş start'ı iptal
/// eder; bu testler app'in henüz gönderilmemiş işi de emekliye ayırmasını
/// ister. Gerçek cihaz/izin/model kabulü değildir.
void main() {
  setUp(LiveJabController.debugResetCameraLock);

  test('stop during permission prevents a late native start', () async {
    final permissionEntered = Completer<void>();
    final permission = Completer<bool>();
    var modelCalls = 0;
    final harness = _Harness(
      requestPermission: () {
        permissionEntered.complete();
        return permission.future;
      },
      modelPath: () async {
        modelCalls++;
        return '/test/pose.task';
      },
    );
    addTearDown(harness.close);

    final starting = harness.controller.start();
    await permissionEntered.future;
    await harness.controller.stop();
    permission.complete(true);
    final failure = await starting;
    await Future<void>.value();

    expect(modelCalls, 0, reason: 'retired permission must not open the model');
    expect(harness.camera.startCalls, 0);
    expect(harness.camera.framesCalls, 0);
    expect(harness.states, isEmpty);
    expect(failure, _interrupted);
  });

  test('stop during model resolution prevents a late native start', () async {
    final modelEntered = Completer<void>();
    final model = Completer<String>();
    final harness = _Harness(
      modelPath: () {
        modelEntered.complete();
        return model.future;
      },
    );
    addTearDown(harness.close);

    final starting = harness.controller.start();
    await modelEntered.future;
    await harness.controller.stop();
    model.complete('/test/pose.task');
    final failure = await starting;
    await Future<void>.value();

    expect(harness.camera.startCalls, 0);
    expect(harness.camera.framesCalls, 0);
    expect(harness.states, isEmpty);
    expect(failure, _interrupted);
  });

  test(
    'dispose during model resolution prevents native and stream setup',
    () async {
      final modelEntered = Completer<void>();
      final model = Completer<String>();
      final harness = _Harness(
        modelPath: () {
          modelEntered.complete();
          return model.future;
        },
      );
      addTearDown(harness.close);

      final starting = harness.controller.start();
      await modelEntered.future;
      await harness.controller.dispose();
      model.complete('/test/pose.task');
      final failure = await starting;
      await Future<void>.value();

      expect(harness.camera.startCalls, 0);
      expect(
        harness.camera.framesCalls,
        0,
        reason: 'a disposed state stream must not gain a camera subscription',
      );
      expect(harness.states, isEmpty);
      expect(failure, _interrupted);
    },
  );

  test(
    'a simultaneous second start is rejected without duplicate native work',
    () async {
      final modelEntered = Completer<void>();
      final model = Completer<String>();
      var modelCalls = 0;
      final harness = _Harness(
        modelPath: () {
          modelCalls++;
          if (!modelEntered.isCompleted) modelEntered.complete();
          return model.future;
        },
      );
      addTearDown(harness.close);

      final first = harness.controller.start();
      await modelEntered.future;
      final second = harness.controller.start();
      model.complete('/test/pose.task');
      final results = await Future.wait<LiveSessionFailure?>([first, second]);
      await Future<void>.value();

      expect(results.first, isNull);
      expect(
        results.last,
        isA<LiveCameraUnavailable>().having(
          (failure) => failure.failure,
          'failure',
          CameraFailure.alreadyRunning,
        ),
      );
      expect(modelCalls, 1);
      expect(harness.camera.startCalls, 1);
      expect(harness.camera.framesCalls, 1);
      expect(harness.camera.listenCalls, 1);
      expect(harness.states, [isA<LiveJabStarting>()]);
    },
  );

  test('normal start registers camera frames and emits starting', () async {
    final harness = _Harness();
    addTearDown(harness.close);

    expect(await harness.controller.start(), isNull);
    await Future<void>.value();

    expect(harness.camera.startCalls, 1);
    expect(harness.camera.framesCalls, 1);
    expect(
      harness.camera.listenCalls,
      1,
      reason: 'the positive control must install the frame listener',
    );
    expect(harness.states, [isA<LiveJabStarting>()]);
  });

  test(
    'a stream decoding failure retires capture and quarantines admission',
    () async {
      final harness = _Harness();
      addTearDown(() => harness.close(closeUncertain: true));
      expect(await harness.controller.start(), isNull);
      harness.camera.emitError(
        const FormatException('malformed native envelope'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(harness.states.last, isA<LiveJabFailed>());
      expect(harness.camera.stopCalls, 1);
      expect(harness.camera.activeListeners, 0);
      await expectLater(harness.controller.dispose(), throwsA(_closeUncertain));
      final next = _Harness();
      addTearDown(next.close);
      expect(
        await next.controller.start(),
        isA<LiveCameraUnavailable>().having(
          (failure) => failure.failure,
          'failure',
          CameraFailure.closeUncertain,
        ),
      );
      expect(
        next.camera.startCalls,
        0,
        reason: 'uncertainty must remain sticky after disposal',
      );
    },
  );

  test(
    'late disposal of a retired controller cannot stop the next owner',
    () async {
      final native = _SharedNativeState();
      final old = _Harness(sharedNative: native);
      final next = _Harness(sharedNative: native);
      addTearDown(old.close);
      addTearDown(next.close);
      expect(await old.controller.start(), isNull);
      await old.controller.stop();
      expect(native.owner, isNull);
      expect(await next.controller.start(), isNull);
      expect(native.owner, same(next.camera));
      await old.controller.dispose();
      expect(native.owner, same(next.camera));
      expect(old.camera.stopCalls, 1);
    },
  );

  test(
    'native start interrupted by stop never registers frames or state',
    () async {
      final harness = _Harness(holdNativeStart: true);
      addTearDown(harness.close);

      final starting = harness.controller.start();
      await harness.camera.nativeStartEntered.future;
      expect(
        harness.camera.startCalls,
        1,
        reason: 'this control must reach an actual pending native call',
      );
      expect(harness.camera.framesCalls, 0);
      expect(harness.states, isEmpty);

      await harness.controller.stop();
      final failure = await starting;
      await Future<void>.value();

      expect(harness.camera.stopCalls, 1);
      expect(harness.camera.startCalls, 1);
      expect(harness.camera.framesCalls, 0);
      expect(harness.camera.listenCalls, 0);
      expect(harness.states, isEmpty);
      expect(failure, _interrupted);
    },
  );

  test(
    'a rejected start never owns another controller native session',
    () async {
      final native = _SharedNativeState();
      final active = _Harness(sharedNative: native);
      final rejected = _Harness(
        sharedNative: native,
        startFailure: CameraFailure.alreadyRunning,
      );
      addTearDown(active.close);
      addTearDown(rejected.close);
      expect(await active.controller.start(), isNull);
      expect(await rejected.controller.start(), isA<LiveCameraUnavailable>());
      expect(native.owner, same(active.camera));
      await rejected.controller.dispose();
      expect(native.owner, same(active.camera));
      expect(rejected.camera.stopCalls, 0);
    },
  );
}

Matcher get _interrupted => isA<LiveCameraUnavailable>().having(
  (failure) => failure.failure,
  'failure',
  CameraFailure.sessionInterrupted,
);

Matcher get _closeUncertain => isA<CameraException>().having(
  (error) => error.failure,
  'failure',
  CameraFailure.closeUncertain,
);

class _Harness {
  _Harness({
    Future<bool> Function()? requestPermission,
    Future<String> Function()? modelPath,
    bool holdNativeStart = false,
    _SharedNativeState? sharedNative,
    CameraFailure? startFailure,
  }) {
    camera = _RecordingCamera(
      holdNativeStart: holdNativeStart,
      sharedNative: sharedNative,
      startFailure: startFailure,
    );
    controller = LiveJabController(
      ruleSet: RuleSet.fromJson(<String, dynamic>{
        'schemaVersion': 1,
        'rulesetId': 'boxing',
        'version': 'start-retirement-test',
        'techniques': <dynamic>[],
        'combinations': <dynamic>[],
        'errors': <dynamic>[],
        'trackedComponents': <dynamic>[],
        'calibrationPending': true,
        'display': <String, dynamic>{'numericScoresUnlocked': false},
      }),
      cues: CueBook(const <NarrationEvent, List<String>>{}),
      camera: camera,
      modelPath: modelPath ?? () async => '/test/pose.task',
      modelId: 'start-retirement-test',
      requestPermission: requestPermission ?? () async => true,
    );
    subscription = controller.states.listen(states.add);
  }

  late final _RecordingCamera camera;
  late final LiveJabController controller;
  late final StreamSubscription<LiveJabState> subscription;
  final List<LiveJabState> states = <LiveJabState>[];

  Future<void> close({bool closeUncertain = false}) async {
    await subscription.cancel();
    try {
      if (closeUncertain) {
        await expectLater(controller.dispose(), throwsA(_closeUncertain));
      } else {
        await controller.dispose();
      }
    } finally {
      await camera.close();
    }
  }
}

/// Counts duplicate calls instead of hiding them behind a fake already-running
/// refusal. Its pending-native-stop behavior mirrors the pinned plugin:
/// stop completes the outstanding start with sessionInterrupted.
class _SharedNativeState extends NativeCaptureState {
  _RecordingCamera? get owner => ownerTag as _RecordingCamera?;
}

/// Uses the real controller and its private lease; the fixture counts native
/// effects and interrupts a pending owned start when that owner is closed.
class _RecordingCamera extends OwnedTestCamera {
  _RecordingCamera({
    required super.holdNativeStart,
    _SharedNativeState? sharedNative,
    CameraFailure? startFailure,
  }) : super(
         state: sharedNative,
         startError: startFailure == null
             ? null
             : CameraException(startFailure, 'native already owned'),
         libraryTag: 'start-retirement-fixture',
       );
}
