import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/liveness_metrics.dart';

void main() {
  test(
    'successful cleanup only reports method completion, not native idle',
    () async {
      final calls = <String>[];
      final result = await cleanupProbeCapture(
        cancelFrames: () async => calls.add('cancel'),
        stopCamera: () async => calls.add('stop'),
      );
      expect(calls, ['cancel', 'stop']);
      expect(result.succeeded, isTrue);
      expect(result.toJson()['nativeIdleReadbackVerified'], isFalse);
    },
  );

  test(
    'camera stop failure cannot become successful liveness cleanup',
    () async {
      final result = await cleanupProbeCapture(
        cancelFrames: () async {},
        stopCamera: () async => throw StateError('native stop failed'),
      );
      expect(result.succeeded, isFalse);
      expect(result.cancelError, isNull);
      expect(result.stopError, contains('native stop failed'));
      expect(result.toJson()['methodCallsSucceeded'], isFalse);
    },
  );

  test(
    'failed frame cancellation still attempts stop and remains failed',
    () async {
      var stops = 0;
      final result = await cleanupProbeCapture(
        cancelFrames: () async => throw StateError('cancel failed'),
        stopCamera: () async {
          stops++;
        },
      );
      expect(stops, 1);
      expect(result.succeeded, isFalse);
      expect(result.cancelError, contains('cancel failed'));
      expect(result.stopError, isNull);
    },
  );

  test('simultaneous cancel and stop faults retain both causes', () async {
    final result = await cleanupProbeCapture(
      cancelFrames: () async => throw StateError('cancel failed'),
      stopCamera: () async => throw StateError('stop failed'),
    );
    expect(result.cancelError, contains('cancel failed'));
    expect(result.stopError, contains('stop failed'));
    expect(result.succeeded, isFalse);
  });

  test(
    'held cancellation cannot report completion or start stop early',
    () async {
      final gate = Completer<void>();
      var stopped = false;
      var completed = false;
      final cleanup =
          cleanupProbeCapture(
            cancelFrames: () => gate.future,
            stopCamera: () async {
              stopped = true;
            },
          ).then((value) {
            completed = true;
            return value;
          });
      await Future<void>.delayed(Duration.zero);
      expect(stopped, isFalse);
      expect(completed, isFalse);
      gate.complete();
      expect((await cleanup).succeeded, isTrue);
      expect(stopped, isTrue);
    },
  );
}
