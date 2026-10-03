import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

/// Protocol fixture only: the production controller and private lease still
/// perform every decode, ownership filter, closure and EventChannel operation.
class NativeCaptureState {
  String? ownerId;
  Object? ownerTag;
  int generation = 0;
  int closeSequence = 0;
  String phase = 'closed';
  static int clock = 0;
}

class OwnedNativeFixture {
  OwnedNativeFixture({
    NativeCaptureState? state,
    this.holdNativeStart = false,
    this.holdBusyReply = false,
    this.completeBusyOnStop = true,
    this.realEventChannel = false,
    this.startError,
    this.closeDelay = Duration.zero,
    this.libraryTag = 'owned-test',
    this.controlTimeout = const Duration(seconds: 15),
    this.closeFault,
    this.closeGate,
    this.cancelGate,
    this.listenGate,
    this.ownedProtocolAvailable = true,
  }) : state = state ?? NativeCaptureState(),
       id = ++_nextId {
    TestWidgetsFlutterBinding.ensureInitialized();
    control = MethodChannel('jablab/test/owned_control/$id');
    frameControl = MethodChannel('jablab/test/owned_frames/$id');
    frames = realEventChannel
        ? EventChannel(frameControl.name)
        : _FixtureFrames(this);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(control, handleControl);
    messenger.setMockMethodCallHandler(frameControl, handleFrameControl);
    addTearDown(close);
  }

  static int _nextId = 0;
  final int id;
  final NativeCaptureState state;
  final bool holdNativeStart;
  final bool holdBusyReply;
  final bool completeBusyOnStop;
  final bool realEventChannel;
  final Object? startError;
  final Duration closeDelay;
  final String libraryTag;
  final Duration controlTimeout;
  String? closeFault;
  final Completer<void>? closeGate;
  final Completer<void>? cancelGate;
  final Completer<void>? listenGate;
  final bool ownedProtocolAvailable;
  late final MethodChannel control;
  late final MethodChannel frameControl;
  late final EventChannel frames;
  final calls = <MethodCall>[];
  final streamCalls = <MethodCall>[];
  final nativeStartEntered = Completer<void>();
  final busyEntered = Completer<void>();
  final stopEntered = Completer<void>();
  final nativeCloseAcknowledged = Completer<void>();
  final Map<String, Completer<Object?>> _pendingStarts = {};
  final Map<String, Completer<Object?>> _busyReplies = {};
  Object? tag;
  String? listenerOwner;
  int startCalls = 0;
  int stopCalls = 0;
  int stopRequests = 0;
  int globalStopCalls = 0;
  int framesCalls = 0;
  int convenienceReceiveCalls = 0;
  final listenEntered = Completer<void>();
  final cancelEntered = Completer<void>();
  int listenCalls = 0;
  int cancelCalls = 0;
  int activeListeners = 0;
  int interruptedStarts = 0;
  int? startedAt;
  int? stopFinishedAt;
  bool awaitedClosingBeforeStart = false;
  bool _closedFixture = false;

  MotionCameraController createController() => MotionCameraController(
    control: control,
    frames: frames,
    controlTimeout: controlTimeout,
  );

  Map<String, Object> running(String owner, {bool owned = true}) => {
    if (owned) 'protocol': 1,
    if (owned) 'ownerId': owner,
    if (owned) 'generation': state.generation,
    'w': 480,
    'h': 640,
    'clock': 'monotonic',
    'library': libraryTag,
  };

  Map<String, Object> observation(String owner, {int nonce = 0}) {
    final current = state.ownerId == owner;
    final phase = current ? state.phase : 'closed';
    return {
      'protocol': 1,
      'ownerId': owner,
      'generation': current ? state.generation : 0,
      'state': phase,
      'captureClosed': phase == 'closed',
      'modelsClosed': phase == 'closed',
      'closeSequence': state.closeSequence,
      'nonce': nonce,
    };
  }

  Future<Object?> handleControl(MethodCall call) async {
    calls.add(call);
    final args = (call.arguments as Map<Object?, Object?>?) ?? const {};
    if (!ownedProtocolAvailable &&
        const {
          'startOwned',
          'stopOwned',
          'readback',
          'setPassPlanOwned',
        }.contains(call.method)) {
      throw MissingPluginException(call.method);
    }
    switch (call.method) {
      case 'start':
      case 'startOwned':
        startCalls++;
        if (!nativeStartEntered.isCompleted) nativeStartEntered.complete();
        final owned = call.method == 'startOwned';
        final owner = owned
            ? args['ownerId']! as String
            : 'legacy-${args['modelId']}-$startCalls';
        final error = startError;
        if (error is CameraException) {
          throw PlatformException(
            code: error.failure.code,
            message: error.detail,
          );
        }
        if (error != null) throw error;
        if (state.phase != 'closed') {
          awaitedClosingBeforeStart = state.phase == 'closing';
          if (holdBusyReply) {
            final pending = Completer<Object?>();
            _busyReplies[owner] = pending;
            if (!busyEntered.isCompleted) busyEntered.complete();
            return pending.future;
          }
          throw PlatformException(
            code: state.phase == 'closing' || state.phase == 'uncertain'
                ? 'close-uncertain'
                : 'already-running',
          );
        }
        state.ownerId = owner;
        state.ownerTag = tag;
        state.generation++;
        state.phase = holdNativeStart ? 'opening' : 'running';
        startedAt = ++NativeCaptureState.clock;
        if (holdNativeStart) {
          final pending = Completer<Object?>();
          _pendingStarts[owner] = pending;
          return pending.future;
        }
        return running(owner, owned: owned);
      case 'stop':
      case 'stopOwned':
        stopRequests++;
        if (!stopEntered.isCompleted) stopEntered.complete();
        final owned = call.method == 'stopOwned';
        if (!owned) globalStopCalls++;
        final owner = owned ? args['ownerId']! as String : state.ownerId;
        if (owned && state.ownerId != owner) {
          if (completeBusyOnStop) releaseBusy(owner!);
          return observation(owner!);
        }
        if (state.phase != 'closed') {
          stopCalls++;
          state.phase = 'closing';
        }
        final pending = _pendingStarts.remove(owner);
        if (pending != null && !pending.isCompleted) {
          interruptedStarts++;
          pending.completeError(PlatformException(code: 'session-interrupted'));
        }
        if (!owned) {
          for (final busy in _busyReplies.values) {
            if (!busy.isCompleted) {
              busy.completeError(
                PlatformException(code: 'session-interrupted'),
              );
            }
          }
          _busyReplies.clear();
        }
        if (closeDelay != Duration.zero) await Future<void>.delayed(closeDelay);
        await closeGate?.future;
        if (closeFault == 'rpc-error') {
          state.phase = 'uncertain';
          throw PlatformException(code: 'close-uncertain');
        }
        state.phase = 'closed';
        state.ownerTag = null;
        state.closeSequence++;
        stopFinishedAt = ++NativeCaptureState.clock;
        if (!nativeCloseAcknowledged.isCompleted) {
          nativeCloseAcknowledged.complete();
        }
        if (!owned) return null;
        final ack = observation(owner!);
        if (closeFault == 'ack-owner') ack['ownerId'] = 'wrong-owner';
        return ack;
      case 'readback':
        final owner = args['ownerId']! as String;
        final reply = observation(owner, nonce: args['nonce']! as int);
        switch (closeFault) {
          case 'readback-owner':
            reply['ownerId'] = 'wrong-owner';
          case 'readback-generation':
            reply['generation'] = state.generation + 1;
          case 'readback-nonce':
            reply['nonce'] = 0;
          case 'readback-sequence':
            reply['closeSequence'] = 0;
          case 'readback-model':
            reply['modelsClosed'] = false;
          case 'readback-state':
            reply['state'] = 'closing';
        }
        return reply;
      case 'setPassPlanOwned':
        return observation(args['ownerId']! as String);
      case 'setPassPlan':
        return null;
      default:
        throw MissingPluginException(call.method);
    }
  }

  void releaseBusy(String owner) {
    final pending = _busyReplies.remove(owner);
    if (pending != null && !pending.isCompleted) {
      pending.completeError(PlatformException(code: 'already-running'));
    }
  }

  Future<Object?> handleFrameControl(MethodCall call) async {
    streamCalls.add(call);
    final args = call.arguments as Map<Object?, Object?>?;
    if (call.method == 'listen') {
      framesCalls++;
      listenCalls++;
      activeListeners++;
      listenerOwner = args?['ownerId'] as String? ?? state.ownerId;
      if (!listenEntered.isCompleted) listenEntered.complete();
      await listenGate?.future;
      if (closeFault == 'listen-error') {
        throw PlatformException(code: 'listen-error');
      }
    } else if (call.method == 'cancel') {
      cancelCalls++;
      if (!cancelEntered.isCompleted) cancelEntered.complete();
      await cancelGate?.future;
      if (closeFault == 'cancel-error') {
        throw PlatformException(code: 'cancel-error');
      }
      if (args?['ownerId'] == listenerOwner || args == null) {
        listenerOwner = null;
        activeListeners--;
      }
    } else {
      throw MissingPluginException(call.method);
    }
    return null;
  }

  Map<String, Object?> wire(CameraFrameEnvelope frame) {
    Float32List? pack(PoseFrame? pose) => pose == null
        ? null
        : Float32List.fromList([
            for (final lm in pose.landmarks) ...[
              lm.x,
              lm.y,
              lm.z,
              lm.visibility,
            ],
          ]);
    return {
      'ownerId': frame.ownerId ?? state.ownerId,
      'generation': frame.generation ?? state.generation,
      't': frame.tUs,
      'w': frame.size.width,
      'h': frame.size.height,
      'model': frame.modelVersion,
      'clock': frame.clockDomain.name,
      'infUs': frame.inferenceUs,
      'dropped': frame.dropped,
      if (frame.ran(BodyOrientation.upright))
        'up': pack(frame.pass(BodyOrientation.upright)),
      if (frame.ran(BodyOrientation.inverted))
        'inv': pack(frame.pass(BodyOrientation.inverted)),
    };
  }

  void emit(CameraFrameEnvelope frame) => unawaited(emitNative(frame));
  void emitError(Object error) => unawaited(
    sendEnvelope(
      const StandardMethodCodec().encodeErrorEnvelope(
        code: error is CameraException
            ? error.failure.code
            : 'frame-stream-error',
        message: error.toString(),
      ),
    ),
  );

  Future<void> sendEnvelope(ByteData? envelope) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(frameControl.name, envelope, (_) {});
  }

  Future<void> emitNative(CameraFrameEnvelope frame) async {
    if (state.phase != 'running' || listenerOwner != state.ownerId) return;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          frameControl.name,
          const StandardMethodCodec().encodeSuccessEnvelope(wire(frame)),
          (_) {},
        );
  }

  Future<void> close() async {
    if (_closedFixture) return;
    _closedFixture = true;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(control, null);
    messenger.setMockMethodCallHandler(frameControl, null);
    if (closeGate != null && !closeGate!.isCompleted) closeGate!.complete();
    if (cancelGate != null && !cancelGate!.isCompleted) cancelGate!.complete();
    if (listenGate != null && !listenGate!.isCompleted) listenGate!.complete();
    for (final pending in [..._pendingStarts.values, ..._busyReplies.values]) {
      if (!pending.isCompleted) {
        pending.completeError(PlatformException(code: 'session-interrupted'));
      }
    }
  }
}

class _FixtureFrames extends EventChannel {
  _FixtureFrames(this.fixture) : super(fixture.frameControl.name);
  final OwnedNativeFixture fixture;

  @override
  Stream<Object?> receiveBroadcastStream([Object? arguments]) {
    fixture.convenienceReceiveCalls++;
    throw StateError('Owned fixture must use actual binary messenger RPCs');
  }
}

/// Existing path tests inherit the production controller and actual lease;
/// counters refer to native resource effects, not a foreign owner's scoped ACK.
class OwnedTestCamera extends MotionCameraController {
  OwnedTestCamera({
    NativeCaptureState? state,
    bool holdNativeStart = false,
    Object? startError,
    Duration closeDelay = Duration.zero,
    String libraryTag = 'owned-test',
  }) : this.fixture(
         OwnedNativeFixture(
           state: state,
           holdNativeStart: holdNativeStart,
           startError: startError,
           closeDelay: closeDelay,
           libraryTag: libraryTag,
         ),
       );

  OwnedTestCamera.fixture(this.native)
    : super(
        control: native.control,
        frames: native.frames,
        controlTimeout: native.controlTimeout,
      ) {
    native.tag = this;
  }

  final OwnedNativeFixture native;
  int get startCalls => native.startCalls;
  int get stopCalls => native.stopCalls;
  int get framesCalls => native.framesCalls;
  int get listenCalls => native.listenCalls;
  int get cancelCalls => native.cancelCalls;
  int get activeListeners => native.activeListeners;
  int get interruptedStarts => native.interruptedStarts;
  Completer<void> get nativeStartEntered => native.nativeStartEntered;
  void emit(CameraFrameEnvelope frame) => native.emit(frame);
  void emitError(Object error) => native.emitError(error);
  Future<void> close() => native.close();
}
