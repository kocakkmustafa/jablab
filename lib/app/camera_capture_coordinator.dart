import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:motion_camera/motion_camera.dart';

/// Process camera admission shared by lesson controllers and the dev harness.
/// A failed close is retained even after its route/controller has gone away.
abstract final class CameraCaptureCoordinator {
  static final _closing = <Future<void>>{};
  static final _uncertainty = ValueNotifier<CameraException?>(null);
  static int _testEpoch = 0;

  static ValueListenable<CameraException?> get uncertainty => _uncertainty;
  static CameraException? get failure => _uncertainty.value;
  static bool get isBlocked => failure != null;

  static Future<void> waitForClosure() async {
    if (failure case final error?) throw error;
    while (_closing.isNotEmpty) {
      try {
        await Future.wait<void>(List<Future<void>>.of(_closing));
      } catch (error) {
        throw recordUncertainty(error);
      }
      if (failure case final error?) throw error;
    }
  }

  /// Retirement and registration are synchronous, ahead of any app cancel.
  static Future<void> close(CameraCaptureLease lease) {
    lease.retire();
    final closing = lease.close();
    final epoch = _testEpoch;
    if (_closing.add(closing)) {
      unawaited(
        closing.then<void>(
          (_) {
            _closing.remove(closing);
          },
          onError: (Object error, StackTrace stack) {
            _closing.remove(closing);
            if (epoch == _testEpoch) recordUncertainty(error);
          },
        ),
      );
    }
    return closing;
  }

  static CameraException recordUncertainty(Object error) {
    return _uncertainty.value ??= CameraException(
      CameraFailure.closeUncertain,
      error is CameraException
          ? error.detail
          : 'camera closure could not be confirmed',
    );
  }

  /// Test isolation only. Production has no timeout/reset/replacement bypass.
  @visibleForTesting
  static void debugResetForTests() {
    _testEpoch++;
    _closing.clear();
    _uncertainty.value = null;
  }
}
