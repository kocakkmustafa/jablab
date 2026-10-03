import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/camera_harness_screen.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/live_session_failure.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';
import 'package:permission_handler/permission_handler.dart';

import 'support/owned_native_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(LiveJabController.debugResetCameraLock);

  test(
    'pending busy reply retirement preserves A and its actual consumer frames',
    () async {
      final native = OwnedNativeFixture(
        realEventChannel: true,
        holdBusyReply: true,
      );
      final a = _Consumer(native, 'A');
      final b = _Consumer(native, 'B');
      addTearDown(a.close);
      addTearDown(b.close);
      expect(await a.controller.start(), isNull);
      await _flush();
      final ownerA = native.state.ownerId;
      await native.emitNative(_frame(1000000));
      await _flush();
      expect(a.states.last, isA<LiveJabRunning>());
      final before = a.states.length;

      final pendingB = b.controller.start();
      await native.busyEntered.future;
      expect(native.state.ownerId, ownerA);
      await b.controller.stop();
      expect(await pendingB, _failure('session-interrupted'));
      expect(
        native.state.ownerId,
        ownerA,
        reason: 'B submitted a request but never acquired A capture',
      );
      expect(native.state.phase, 'running');
      expect(native.globalStopCalls, 0);
      expect(b.states, isEmpty);
      expect(
        native.streamCalls.where((call) => call.method == 'listen'),
        hasLength(1),
      );
      await native.emitNative(_frame(2000000));
      await _flush();
      expect(a.states.length, greaterThan(before));
      expect(a.states.last, isA<LiveJabRunning>());
      expect(
        native.calls.where((call) => call.method == 'readback'),
        hasLength(1),
      );
    },
  );

  test(
    'replacement waits for close ACK and fresh readback before native start',
    () async {
      final gate = Completer<void>();
      final native = OwnedNativeFixture(
        realEventChannel: true,
        closeGate: gate,
      );
      final a = _Consumer(native, 'A');
      final b = _Consumer(native, 'B');
      addTearDown(a.close);
      addTearDown(b.close);
      expect(await a.controller.start(), isNull);
      await _flush();
      final closing = a.controller.stop();
      final opening = b.controller.start();
      await native.stopEntered.future;
      await _flush();
      expect(native.startCalls, 1);
      expect(b.states, isEmpty);
      gate.complete();
      await closing;
      expect(await opening, isNull);
      await _flush();
      final methods = native.calls.map((call) => call.method).toList();
      expect(methods, ['startOwned', 'stopOwned', 'readback', 'startOwned']);
      expect(native.streamCalls.map((call) => call.method), [
        'listen',
        'cancel',
        'listen',
      ]);
      await native.emitNative(_frame(2000000));
      await _flush();
      expect(b.states.last, isA<LiveJabRunning>());
      final nativeCalls = native.calls.length;
      final streamCalls = native.streamCalls.length;
      await a.controller.stop();
      await a.close();
      expect(native.calls.length, nativeCalls);
      expect(native.streamCalls.length, streamCalls);
      final before = b.states.length;
      await native.emitNative(_frame(3000000));
      await _flush();
      expect(b.states.length, greaterThan(before));
    },
  );

  test(
    'an absent-owner ACK still waits for pending start settlement',
    () async {
      final native = OwnedNativeFixture(
        realEventChannel: true,
        holdBusyReply: true,
        completeBusyOnStop: false,
      );
      final a = _Consumer(native, 'A');
      final b = _Consumer(native, 'B');
      final c = _Consumer(native, 'C');
      addTearDown(a.close);
      addTearDown(b.close);
      addTearDown(c.close);
      expect(await a.controller.start(), isNull);
      final pendingB = b.controller.start();
      await native.busyEntered.future;
      final ownerB = native.calls.last.arguments as Map<Object?, Object?>;
      final closingB = b.controller.stop();
      final openingC = c.controller.start();
      await _flush();
      expect(native.startCalls, 2);
      expect(
        native.calls.where(
          (call) =>
              call.method == 'readback' &&
              (call.arguments as Map<Object?, Object?>)['ownerId'] ==
                  ownerB['ownerId'],
        ),
        isEmpty,
        reason: 'an ACK cannot replace settlement of the admitted start Future',
      );
      await a.controller.stop();
      await _flush();
      expect(native.state.phase, 'closed');
      expect(
        native.startCalls,
        2,
        reason: 'C still waits for B start settlement',
      );
      native.releaseBusy(ownerB['ownerId']! as String);
      await closingB;
      expect(await pendingB, _failure('session-interrupted'));
      expect(await openingC, isNull);
      expect(native.startCalls, 3);
      expect(native.globalStopCalls, 0);
    },
  );

  test('replacement waits for the actual EventChannel cancel Future', () async {
    final cancelGate = Completer<void>();
    final native = OwnedNativeFixture(
      realEventChannel: true,
      cancelGate: cancelGate,
    );
    final a = _Consumer(native, 'A');
    final b = _Consumer(native, 'B');
    addTearDown(a.close);
    addTearDown(b.close);
    expect(await a.controller.start(), isNull);
    await _flush();
    final closing = a.controller.stop();
    final opening = b.controller.start();
    await native.nativeCloseAcknowledged.future;
    await _flush();
    expect(native.cancelCalls, 1);
    expect(
      native.state.phase,
      'closed',
      reason: 'native ACK already completed',
    );
    expect(native.calls.where((call) => call.method == 'readback'), isEmpty);
    expect(native.startCalls, 1);
    cancelGate.complete();
    await closing;
    expect(await opening, isNull);
    expect(native.calls.map((call) => call.method), [
      'startOwned',
      'stopOwned',
      'readback',
      'startOwned',
    ]);
  });

  test(
    'actual owned frame decode rejects foreign owner and generation',
    () async {
      final native = OwnedNativeFixture(realEventChannel: true);
      final a = _Consumer(native, 'A');
      addTearDown(a.close);
      expect(await a.controller.start(), isNull);
      await _flush();
      final before = a.states.length;
      await native.emitNative(_frame(1000000, ownerId: 'foreign-owner'));
      await native.emitNative(
        _frame(2000000, generation: native.state.generation + 1),
      );
      await _flush();
      expect(a.states, hasLength(before));
      await native.emitNative(_frame(3000000));
      await _flush();
      expect(a.states.length, greaterThan(before));
      expect(a.states.last, isA<LiveJabRunning>());
    },
  );

  test(
    'missing owned protocol fails closed without a global fallback',
    () async {
      final native = OwnedNativeFixture(ownedProtocolAvailable: false);
      final a = _Consumer(native, 'A');
      final b = _Consumer(native, 'B');
      addTearDown(a.close);
      addTearDown(b.close);
      expect(await a.controller.start(), _failure('close-uncertain'));
      final attempts = native.calls.length;
      expect(await b.controller.start(), _failure('close-uncertain'));
      expect(native.calls, hasLength(attempts));
      expect(native.calls.map((call) => call.method), [
        'startOwned',
        'stopOwned',
      ]);
      expect(native.globalStopCalls, 0);
    },
  );

  for (final fault in [
    'rpc-error',
    'ack-owner',
    'readback-owner',
    'readback-generation',
    'readback-nonce',
    'readback-sequence',
    'readback-model',
    'readback-state',
  ]) {
    test(
      '$fault keeps another actual controller blocked after failed close',
      () async {
        final native = OwnedNativeFixture(closeFault: fault);
        final a = _Consumer(native, 'A');
        final b = _Consumer(native, 'B');
        addTearDown(a.close);
        addTearDown(b.close);
        expect(await a.controller.start(), isNull);
        await expectLater(
          a.controller.stop(),
          throwsA(_cameraFailure('close-uncertain')),
        );
        expect(await b.controller.start(), _failure('close-uncertain'));
        expect(native.startCalls, 1);
        native.closeFault = null;
        expect(await b.controller.start(), _failure('close-uncertain'));
        expect(
          native.startCalls,
          1,
          reason: 'late success or a new controller cannot reset uncertainty',
        );
      },
    );
  }

  test(
    'close timeout remains blocked when a late native ACK arrives',
    () async {
      final gate = Completer<void>();
      final native = OwnedNativeFixture(
        closeGate: gate,
        controlTimeout: const Duration(milliseconds: 25),
      );
      final a = _Consumer(native, 'A');
      final b = _Consumer(native, 'B');
      addTearDown(a.close);
      addTearDown(b.close);
      expect(await a.controller.start(), isNull);
      CameraException? failure;
      try {
        await a.controller.stop();
      } on CameraException catch (error) {
        failure = error;
      }
      expect(failure?.failure, CameraFailure.closeUncertain);
      expect(await b.controller.start(), _failure('close-uncertain'));
      gate.complete();
      await _flush();
      expect(await b.controller.start(), _failure('close-uncertain'));
      expect(native.startCalls, 1);
    },
  );

  test(
    'unawaited failed retirement stays observed and dispose closes states',
    () async {
      final native = OwnedNativeFixture(closeFault: 'readback-model');
      final a = _Consumer(native, 'A');
      final b = _Consumer(native, 'B');
      addTearDown(a.close);
      addTearDown(b.close);
      final statesDone = Completer<void>();
      final subscription = a.controller.states.listen(
        (_) {},
        onDone: statesDone.complete,
      );
      addTearDown(subscription.cancel);
      expect(await a.controller.start(), isNull);
      unawaited(a.controller.stop());
      await _flush();
      expect(await b.controller.start(), _failure('close-uncertain'));
      unawaited(a.controller.dispose());
      await statesDone.future;
      expect(await b.controller.start(), _failure('close-uncertain'));
      expect(native.startCalls, 1);
    },
  );

  testWidgets('live close uncertainty also blocks the debug harness', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late OwnedNativeFixture native;
    await tester.runAsync(() async {
      native = OwnedNativeFixture(closeFault: 'readback-model');
      final a = _Consumer(native, 'A');
      expect(await a.controller.start(), isNull);
      CameraException? failure;
      try {
        await a.controller.stop();
      } on CameraException catch (error) {
        failure = error;
      }
      expect(failure?.failure, CameraFailure.closeUncertain);
      await a.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: CameraHarnessScreen(
          controller: native.createController(),
          requestPermission: () async => PermissionStatus.granted,
          modelPath: () async => '/test/model.task',
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('harness-start')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const Key('harness-error')), findsOneWidget);
    expect(native.startCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Matcher _failure(String code) => isA<LiveCameraUnavailable>().having(
  (failure) => failure.failure.code,
  'failure code',
  code,
);
Matcher _cameraFailure(String code) => isA<CameraException>().having(
  (failure) => failure.failure.code,
  'failure code',
  code,
);
Future<void> _flush() => Future<void>.delayed(Duration.zero);
CameraFrameEnvelope _frame(int tUs, {String? ownerId, int? generation}) =>
    CameraFrameEnvelope(
      ownerId: ownerId,
      generation: generation,
      tUs: tUs,
      size: const FrameSize(480, 640),
      modelVersion: 'test',
      clockDomain: ClockDomain.monotonic,
      inferenceUs: 1000,
      dropped: 0,
      passes: const {BodyOrientation.upright: null},
    );

class _Consumer {
  _Consumer(OwnedNativeFixture native, String id) {
    controller = LiveJabController(
      ruleSet: RuleSet.fromJson({
        'schemaVersion': 1,
        'rulesetId': 'boxing',
        'version': 'owned-test',
        'techniques': [],
        'combinations': [],
        'errors': [],
        'trackedComponents': [],
        'calibrationPending': true,
        'display': {'numericScoresUnlocked': false},
      }),
      cues: CueBook(const <NarrationEvent, List<String>>{}),
      camera: native.createController(),
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
