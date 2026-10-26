import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/rehearse_material.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/skeleton_overlay.dart';
import 'package:jablab/app/teach_material.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import 'support/owned_native_fixture.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _openSessionKey = Key('owner-lifecycle-open');
const _sessionKey = Key('owner-lifecycle-session');
const _unrelatedRouteKey = Key('owner-lifecycle-unrelated-route');

/// Widget ownership and foreground gates use a mocked platform-channel protocol;
/// no real native/provider/device, content asset, model file or permission prompt.
/// A null upright pass is enough
/// to prove that the live analysis path is connected; no form claim is made.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(LiveJabController.debugResetCameraLock);

  for (final nextOwner in <String?>[null, _bob]) {
    testWidgets(
      'owner change to ${nextOwner == null ? 'guest' : 'Bob'} retires the live '
      'route without saving Alice history',
      (tester) async {
        final harness = _Harness();
        await _pushLive(tester, harness);
        expect(harness.camera.startCalls, 1);
        await tester.pump(const Duration(seconds: 2));

        harness.account.value = nextOwner;
        await _flush(tester);

        expect(harness.camera.stopCalls, greaterThan(0));
        expect(find.byType(SessionScreen, skipOffstage: false), findsNothing);
        expect(
          harness.store.written,
          isEmpty,
          reason: 'owner invalidation must not save into the old journal',
        );
        expect(harness.camera.startCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'owner change removes a covered session and retains the unrelated top route',
    (tester) async {
      final harness = _Harness();
      await _pushLive(tester, harness);
      expect(harness.camera.startCalls, 1);
      await tester.pump(const Duration(seconds: 2));
      unawaited(
        harness.navigator.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Unrelated route', key: _unrelatedRouteKey),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_unrelatedRouteKey), findsOneWidget);
      expect(
        find.byType(SessionScreen, skipOffstage: false),
        findsOneWidget,
        reason: 'the old session must actually be underneath another route',
      );

      harness.account.value = _bob;
      await _flush(tester);

      expect(
        find.byKey(_unrelatedRouteKey),
        findsOneWidget,
        reason: 'invalidating a covered session must not pop the top route',
      );
      expect(find.byType(SessionScreen, skipOffstage: false), findsNothing);
      expect(harness.camera.stopCalls, greaterThan(0));
      expect(harness.store.written, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inactive and paused stop analysis, ignore old frames and do not restart on resume',
    (tester) async {
      final harness = _Harness();
      await _pushLive(tester, harness);
      expect(harness.camera.startCalls, 1);
      harness.camera.emit(_frame(1000000));
      await _flush(tester);
      expect(
        _analysisRunning(tester),
        isTrue,
        reason: 'the positive control must reach a real running frame',
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await _flush(tester);
      expect(harness.camera.stopCalls, greaterThan(0));
      expect(_analysisRunning(tester), isFalse);
      final stoppedStateCount = harness.states.length;
      harness.camera.emit(_frame(2000000));
      await _flush(tester);
      expect(_analysisRunning(tester), isFalse);
      expect(
        harness.states.length,
        stoppedStateCount,
        reason: 'the retired camera stream must not produce new live states',
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await _flush(tester);
      expect(_analysisRunning(tester), isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(
        harness.camera.startCalls,
        1,
        reason: 'a completed stop must not automatically restart native work',
      );
      expect(_analysisRunning(tester), isFalse);
      harness.camera.emit(_frame(3000000));
      await _flush(tester);
      expect(harness.states.length, stoppedStateCount);
      expect(_analysisRunning(tester), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'permission granted while still inactive waits for resumed before native start',
    (tester) async {
      final permission = Completer<bool>();
      var permissionCalls = 0;
      final harness = _Harness(
        requestPermission: () {
          permissionCalls++;
          return permission.future;
        },
      );
      await _pushLive(tester, harness);
      expect(
        permissionCalls,
        1,
        reason: 'the live screen must have entered the pending permission call',
      );
      expect(harness.camera.startCalls, 0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await _flush(tester);
      permission.complete(true);
      await _flush(tester);
      expect(
        harness.camera.startCalls,
        0,
        reason: 'granting permission does not make an inactive app foreground',
      );
      expect(_analysisRunning(tester), isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(
        permissionCalls,
        1,
        reason: 'resuming should finish the pending start, not ask again',
      );
      expect(harness.camera.startCalls, 1);
      expect(harness.camera.framesCalls, 1);
      harness.camera.emit(_frame(1000000));
      await _flush(tester);
      expect(_analysisRunning(tester), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'replacing the owner notifier retires the old session even for the same UUID',
    (tester) async {
      final harness = _Harness();
      await _pushLive(tester, harness);
      expect(harness.camera.startCalls, 1);
      await tester.pump(const Duration(seconds: 2));
      final replacement = ValueNotifier<String?>(_alice);
      harness.extraAccounts.add(replacement);

      harness.owner.value = replacement;
      await _flush(tester);

      expect(find.byType(SessionScreen, skipOffstage: false), findsNothing);
      expect(harness.camera.stopCalls, greaterThan(0));
      expect(harness.store.written, isEmpty);
      harness.account.value = _bob;
      await _flush(tester);
      expect(
        harness.camera.startCalls,
        1,
        reason: 'the old notifier must not revive a retired session',
      );
      expect(harness.store.written, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('inactive while native start is pending retires that start', (
    tester,
  ) async {
    final harness = _Harness(holdNativeStart: true);
    await _pushLive(tester, harness);
    expect(harness.camera.startCalls, 1);
    expect(harness.camera.framesCalls, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await _flush(tester);
    expect(harness.camera.stopCalls, 1);
    expect(harness.camera.framesCalls, 0);
    expect(_analysisRunning(tester), isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush(tester);
    expect(harness.camera.startCalls, 1);
    expect(harness.camera.framesCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary timed exit still records the opening owner history', (
    tester,
  ) async {
    final harness = _Harness();
    await _pushLive(tester, harness);
    expect(harness.camera.startCalls, 1);
    await tester.pump(const Duration(seconds: 2));

    harness.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await _flush(tester);

    expect(
      harness.store.written,
      hasLength(1),
      reason: 'zero saves after invalidation must not mean all saves broke',
    );
    expect(harness.store.written.single.workedSeconds, greaterThan(0));
    expect(harness.store.written.single.isComplete, isFalse);
    expect(harness.camera.stopCalls, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pushLive(WidgetTester tester, _Harness harness) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await _flush(tester);
    // Completed stream futures can belong to the root zone, while controller
    // retirement completers belong to FakeAsync. Drain both without waiting
    // on one queue while freezing the other; preserve actual close completion.
    final closing = harness.close();
    var closed = false;
    closing.then((_) => closed = true);
    for (var turn = 0; turn < 12 && !closed; turn++) {
      await tester.pump();
      await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    }
    expect(closed, isTrue, reason: 'all owned streams must finish retirement');
    await closing;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.binding.setSurfaceSize(null);
  });
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: harness.navigator,
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            key: _openSessionKey,
            onPressed: () => unawaited(
              harness.navigator.currentState!.push<void>(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ValueListenableBuilder<ValueListenable<String?>>(
                        valueListenable: harness.owner,
                        builder: (_, account, __) => SessionScreen(
                          key: _sessionKey,
                          accountUserId: account,
                          lesson: const ShellLesson(
                            id: 'owner-lifecycle-fixture',
                            title: 'Owner lifecycle fixture',
                            minutes: 2,
                          ),
                          cues: harness.cues,
                          coachedNotScored: const <String>[],
                          bands: const <String, String>{},
                          plan: const RoundPlan(
                            rounds: 2,
                            roundSeconds: 60,
                            restSeconds: 5,
                            planProvenance: 'owner-lifecycle-test',
                          ),
                          store: harness.store,
                          liveJab: harness.live,
                          teachMaterial: const TeachMaterialText(
                            body: 'Fixture lesson.',
                          ),
                          rehearseMaterial: const RehearseMaterialNone(
                            reason: 'fixture: no drill named',
                          ),
                        ),
                      ),
                ),
              ),
            ),
            child: const Text('Open fixture session'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_openSessionKey));
  await tester.pumpAndSettle();
  expect(find.byKey(_sessionKey), findsOneWidget);
  expect(harness.camera.startCalls, 0);
  expect(find.byKey(const Key('teach-no-analysis')), findsOneWidget);
  await tester.tap(find.byKey(const Key('advance-button')));
  await tester.pumpAndSettle();
  expect(harness.camera.startCalls, 0);
  await tester.tap(find.byKey(const Key('advance-button')));
  await _flush(tester);
  expect(find.byType(SkeletonPreview), findsOneWidget);
}

Future<void> _flush(WidgetTester tester) async {
  // Broadcast subscription cancellation can return Dart's cached root-zone
  // future. Pumping only FakeAsync leaves the awaited native stop pending.
  // Drain one real event turn without calling stop ourselves, then complete
  // route transitions and the fake-native futures in the widget clock.
  await tester.pump();
  await tester.runAsync(() async {
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

bool _analysisRunning(WidgetTester tester) => tester
    .widget<SkeletonPreview>(find.byType(SkeletonPreview))
    .analysisRunning;

CameraFrameEnvelope _frame(int tUs) => CameraFrameEnvelope(
  tUs: tUs,
  size: const FrameSize(480, 640),
  modelVersion: 'owner-lifecycle-test',
  clockDomain: ClockDomain.monotonic,
  inferenceUs: 1000,
  dropped: 0,
  passes: const <BodyOrientation, PoseFrame?>{BodyOrientation.upright: null},
);

class _Harness {
  _Harness({
    Future<bool> Function()? requestPermission,
    bool holdNativeStart = false,
  }) {
    camera = _RecordingCamera(holdNativeStart: holdNativeStart);
    owner = ValueNotifier<ValueListenable<String?>>(account);
    live = LiveJabController(
      ruleSet: RuleSet.fromJson(<String, dynamic>{
        'schemaVersion': 1,
        'rulesetId': 'boxing',
        'version': 'owner-lifecycle-test',
        'techniques': <dynamic>[],
        'combinations': <dynamic>[],
        'errors': <dynamic>[],
        'trackedComponents': <dynamic>[],
        'calibrationPending': true,
        'display': <String, dynamic>{'numericScoresUnlocked': false},
      }),
      cues: cues,
      camera: camera,
      modelPath: () async => '/fixture/pose.task',
      modelId: 'owner-lifecycle-test',
      requestPermission: requestPermission ?? () async => true,
    );
    subscription = live.states.listen(states.add);
  }

  final navigator = GlobalKey<NavigatorState>();
  final account = ValueNotifier<String?>(_alice);
  final extraAccounts = <ValueNotifier<String?>>[];
  late final ValueNotifier<ValueListenable<String?>> owner;
  late final _RecordingCamera camera;
  final store = _RecordingStore();
  final cues = CueBook(const <NarrationEvent, List<String>>{});
  late final LiveJabController live;
  late final StreamSubscription<LiveJabState> subscription;
  final states = <LiveJabState>[];

  Future<void> close() async {
    await subscription.cancel();
    await live.dispose();
    await camera.close();
    owner.dispose();
    account.dispose();
    for (final extra in extraAccounts) {
      extra.dispose();
    }
  }
}

class _RecordingCamera extends OwnedTestCamera {
  _RecordingCamera({super.holdNativeStart = false})
    : super(libraryTag: 'owner-lifecycle-fixture');
}

class _RecordingStore implements SessionStore {
  final written = <SessionRecord>[];

  @override
  Future<void> append(SessionRecord record) async => written.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => written;

  @override
  Future<int> unreadableRecords() async => 0;

  @override
  Future<int> workedSecondsFor(String lessonId) async => written
      .where((record) => record.lessonId == lessonId)
      .fold<int>(0, (total, record) => total + record.workedSeconds);
}
