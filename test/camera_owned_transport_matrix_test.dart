import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/live_session_failure.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import 'support/owned_native_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(LiveJabController.debugResetCameraLock);

  test(
    'replacement joins pending listen ACK before cancel and readback',
    () async {
      final listen = Completer<void>();
      final native = OwnedNativeFixture(listenGate: listen);
      final a = _Consumer(native, 'A');
      final b = _Consumer(native, 'B');
      addTearDown(a.close);
      addTearDown(b.close);
      addTearDown(() {
        if (!listen.isCompleted) listen.complete();
      });
      expect(await a.controller.start(), isNull);
      await native.listenEntered.future;
      final closing = a.controller.stop();
      final opening = b.controller.start();
      await native.nativeCloseAcknowledged.future;
      await _flush();
      expect(native.cancelCalls, 0, reason: 'listen RPC is still held');
      expect(native.calls.where((call) => call.method == 'readback'), isEmpty);
      expect(native.startCalls, 1);
      listen.complete();
      await closing;
      expect(await opening, isNull);
      expect(native.streamCalls.map((call) => call.method), [
        'listen',
        'cancel',
        'listen',
      ]);
      expect(native.calls.map((call) => call.method), [
        'startOwned',
        'stopOwned',
        'readback',
        'startOwned',
      ]);
      await _flush();
      await native.emitNative(_frame(1000000));
      await _flush();
      expect(b.states.last, isA<LiveJabRunning>());
      expect(native.convenienceReceiveCalls, 0);
      expect(native.globalStopCalls, 0);
    },
  );

  for (final fault in [
    'cancel-error',
    'cancel-timeout',
    'listen-error',
    'listen-timeout',
  ]) {
    test(
      '$fault quarantines replacement after actual transport failure',
      () async {
        final listen = fault == 'listen-timeout' ? Completer<void>() : null;
        final cancel = fault == 'cancel-timeout' ? Completer<void>() : null;
        final native = OwnedNativeFixture(
          listenGate: listen,
          cancelGate: cancel,
          closeFault: fault.endsWith('-error') ? fault : null,
          controlTimeout: const Duration(milliseconds: 40),
        );
        final a = _Consumer(native, 'A');
        final b = _Consumer(native, 'B');
        addTearDown(a.close);
        addTearDown(b.close);
        addTearDown(() {
          if (listen != null && !listen.isCompleted) listen.complete();
          if (cancel != null && !cancel.isCompleted) cancel.complete();
        });
        await a.controller.start();
        await native.listenEntered.future;
        if (fault.startsWith('listen')) {
          await native.cancelEntered.future;
        }
        await expectLater(a.controller.stop(), throwsA(_uncertain));
        expect(await b.controller.start(), _blocked);
        expect(native.startCalls, 1);
        expect(
          native.calls.where((call) => call.method == 'readback'),
          isEmpty,
        );
        native.closeFault = null;
        if (listen != null && !listen.isCompleted) listen.complete();
        if (cancel != null && !cancel.isCompleted) cancel.complete();
        await _flush();
        await _flush();
        expect(
          await b.controller.start(),
          _blocked,
          reason: 'late RPC settlement cannot clear quarantine',
        );
        expect(native.startCalls, 1);
        expect(native.convenienceReceiveCalls, 0);
        expect(native.globalStopCalls, 0);
      },
    );
  }

  for (final kind in ['end-of-stream', 'error-envelope', 'malformed-frame']) {
    test(
      '$kind closes actual consumer and keeps replacement quarantined',
      () async {
        final native = OwnedNativeFixture();
        final a = _Consumer(native, 'A');
        final b = _Consumer(native, 'B');
        addTearDown(a.close);
        addTearDown(b.close);
        expect(await a.controller.start(), isNull);
        await _flush();
        await native.emitNative(_frame(1000000));
        await _flush();
        expect(a.states.last, isA<LiveJabRunning>());
        final envelope = switch (kind) {
          'end-of-stream' => null,
          'error-envelope' => const StandardMethodCodec().encodeErrorEnvelope(
            code: 'frame-source-error',
          ),
          _ => const StandardMethodCodec().encodeSuccessEnvelope('not-a-frame'),
        };
        await native.sendEnvelope(envelope);
        await native.cancelEntered.future;
        await _flush();
        expect(
          a.states.last,
          isA<LiveJabFailed>().having(
            (state) => state.failure,
            'failure',
            _blocked,
          ),
        );
        expect(await b.controller.start(), _blocked);
        expect(native.startCalls, 1);
        expect(
          native.calls.where((call) => call.method == 'readback'),
          isEmpty,
        );
        expect(native.convenienceReceiveCalls, 0);
        expect(native.globalStopCalls, 0);
      },
    );
  }

  test('late paused A app cancellation preserves encoded B frames', () async {
    final native = OwnedNativeFixture();
    final cameraA = _TrackingCamera(native);
    final a = _Consumer(native, 'A', camera: cameraA);
    final b = _Consumer(native, 'B');
    addTearDown(a.close);
    addTearDown(b.close);
    expect(await a.controller.start(), isNull);
    await _flush();
    final oldFrames = <CameraFrameEnvelope>[];
    final oldApp = cameraA.lastLease.frames().listen(
      oldFrames.add,
      onError: (Object _, StackTrace __) {},
    );
    addTearDown(oldApp.cancel);
    oldApp.pause();
    await native.emitNative(_frame(1000000));
    await _flush();
    await a.controller.stop().timeout(const Duration(seconds: 1));
    expect(await b.controller.start(), isNull);
    await _flush();
    final nativeCalls = native.calls.length;
    final rawCalls = native.streamCalls.length;
    await oldApp.cancel();
    expect(native.calls.length, nativeCalls);
    expect(native.streamCalls.length, rawCalls);
    final before = b.states.length;
    await native.emitNative(_frame(2000000));
    await _flush();
    expect(b.states.length, greaterThan(before));
    expect(b.states.last, isA<LiveJabRunning>());
    expect(oldFrames, isEmpty);
    expect(native.activeListeners, 1);
    expect(native.convenienceReceiveCalls, 0);
    expect(native.globalStopCalls, 0);
  });
}

Matcher get _uncertain => isA<CameraException>().having(
  (error) => error.failure,
  'failure',
  CameraFailure.closeUncertain,
);
Matcher get _blocked => isA<LiveCameraUnavailable>().having(
  (state) => state.failure.code,
  'failure',
  'close-uncertain',
);
Future<void> _flush() => Future<void>.delayed(Duration.zero);
CameraFrameEnvelope _frame(int tUs) => CameraFrameEnvelope(
  tUs: tUs,
  size: const FrameSize(480, 640),
  modelVersion: 'test',
  clockDomain: ClockDomain.monotonic,
  inferenceUs: 1000,
  dropped: 0,
  passes: const {BodyOrientation.upright: null},
);

class _TrackingCamera extends MotionCameraController {
  _TrackingCamera(OwnedNativeFixture native)
    : super(
        control: native.control,
        frames: native.frames,
        controlTimeout: native.controlTimeout,
      );
  late CameraCaptureLease lastLease;
  @override
  CameraCaptureLease createCaptureLease() =>
      lastLease = super.createCaptureLease();
}

class _Consumer {
  _Consumer(
    OwnedNativeFixture native,
    String id, {
    MotionCameraController? camera,
  }) {
    controller = LiveJabController(
      ruleSet: RuleSet.fromJson({
        'schemaVersion': 1,
        'rulesetId': 'boxing',
        'version': 'owned-matrix-test',
        'techniques': [],
        'combinations': [],
        'errors': [],
        'trackedComponents': [],
        'calibrationPending': true,
        'display': {'numericScoresUnlocked': false},
      }),
      cues: CueBook(const <NarrationEvent, List<String>>{}),
      camera: camera ?? native.createController(),
      modelPath: () async => '/test/model.task',
      modelId: id,
      requestPermission: () async => true,
    );
    subscription = controller.states.listen(states.add);
  }
  late final LiveJabController controller;
  late final StreamSubscription<LiveJabState> subscription;
  final states = <LiveJabState>[];
  Future<void> close() async {
    await subscription.cancel();
    try {
      await controller.dispose();
    } on CameraException catch (_) {}
  }
}
