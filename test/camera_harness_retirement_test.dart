import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/camera_harness_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import 'support/owned_native_fixture.dart';

/// Debug harness ownership only. Permission, model and camera are injected;
/// no platform permission, real model file or native/device acceptance runs.
void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1200, 2600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('disposed harness ignores a late granted permission', (
    tester,
  ) async {
    final permission = Completer<PermissionStatus>();
    final camera = _HarnessCamera();
    final navigator = GlobalKey<NavigatorState>();
    final screenKey = GlobalKey();
    var permissionCalls = 0;
    var modelCalls = 0;
    addTearDown(() => _cleanup(tester, camera, releasePending: () {
      if (!permission.isCompleted) permission.complete(PermissionStatus.granted);
    }));

    await _openHarness(
      tester,
      navigator,
      CameraHarnessScreen(
        key: screenKey,
        controller: camera,
        requestPermission: () {
          permissionCalls++;
          return permission.future;
        },
        modelPath: () async {
          modelCalls++;
          return '/test/pose.task';
        },
      ),
    );
    final state = screenKey.currentState!;
    await tester.tap(find.byKey(const Key('harness-start')));
    await tester.pump();
    expect(permissionCalls, 1, reason: 'the injected permission must be pending');
    expect(modelCalls, 0);
    expect(camera.startCalls, 0);

    await _popHarness(tester, navigator);
    expect(state.mounted, isFalse);
    permission.complete(PermissionStatus.granted);
    await tester.pumpAndSettle();

    expect(modelCalls, 0, reason: 'a retired permission must not open a model');
    expect(camera.startCalls, 0);
    expect(camera.framesCalls, 0);
    expect(camera.listenCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed harness ignores a late model path', (tester) async {
    final model = Completer<String>();
    final camera = _HarnessCamera();
    final navigator = GlobalKey<NavigatorState>();
    final screenKey = GlobalKey();
    var modelCalls = 0;
    addTearDown(() => _cleanup(tester, camera, releasePending: () {
      if (!model.isCompleted) model.complete('/test/pose.task');
    }));

    await _openHarness(
      tester,
      navigator,
      CameraHarnessScreen(
        key: screenKey,
        controller: camera,
        requestPermission: () async => PermissionStatus.granted,
        modelPath: () {
          modelCalls++;
          return model.future;
        },
      ),
    );
    final state = screenKey.currentState!;
    await tester.tap(find.byKey(const Key('harness-start')));
    await tester.pump();
    expect(modelCalls, 1, reason: 'the model lookup must really be pending');
    expect(camera.startCalls, 0);

    await _popHarness(tester, navigator);
    expect(state.mounted, isFalse);
    model.complete('/test/pose.task');
    await tester.pumpAndSettle();

    expect(camera.startCalls, 0);
    expect(camera.framesCalls, 0);
    expect(camera.listenCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing pending native start stops it before subscribing', (
    tester,
  ) async {
    final camera = _HarnessCamera(holdNativeStart: true);
    final navigator = GlobalKey<NavigatorState>();
    final screenKey = GlobalKey();
    addTearDown(() => _cleanup(tester, camera));

    await _openHarness(
      tester,
      navigator,
      CameraHarnessScreen(
        key: screenKey,
        controller: camera,
        requestPermission: () async => PermissionStatus.granted,
        modelPath: () async => '/test/pose.task',
      ),
    );
    final state = screenKey.currentState!;
    await tester.tap(find.byKey(const Key('harness-start')));
    await tester.pump();
    expect(camera.startCalls, 1,
        reason: 'this case must reach a pending native camera start');
    expect(camera.framesCalls, 0);

    await _popHarness(tester, navigator);
    expect(state.mounted, isFalse);
    expect(camera.stopCalls, greaterThanOrEqualTo(1));
    expect(camera.interruptedStarts, 1);
    expect(camera.framesCalls, 0);
    expect(camera.listenCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal harness start and route disposal own and release frames', (
    tester,
  ) async {
    final camera = _HarnessCamera();
    final navigator = GlobalKey<NavigatorState>();
    final screenKey = GlobalKey();
    addTearDown(() => _cleanup(tester, camera));

    await _openHarness(
      tester,
      navigator,
      CameraHarnessScreen(
        key: screenKey,
        controller: camera,
        requestPermission: () async => PermissionStatus.granted,
        modelPath: () async => '/test/pose.task',
      ),
    );
    final state = screenKey.currentState!;
    await tester.tap(find.byKey(const Key('harness-start')));
    await tester.pumpAndSettle();

    expect(camera.startCalls, 1);
    expect(camera.framesCalls, 1);
    expect(camera.listenCalls, 1);
    expect(camera.cancelCalls, 0);
    expect(
      tester.widget<Text>(find.byKey(const Key('metric-session'))).data,
      'running',
    );

    await _popHarness(tester, navigator);
    expect(state.mounted, isFalse);
    expect(camera.stopCalls, greaterThanOrEqualTo(1));
    expect(camera.cancelCalls, 1);
    expect(camera.interruptedStarts, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openHarness(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigator,
  CameraHarnessScreen screen,
) async {
  await tester.pumpWidget(MaterialApp(
    navigatorKey: navigator,
    home: const Scaffold(body: Text('Harness parent route')),
  ));
  unawaited(navigator.currentState!.push<void>(
    MaterialPageRoute<void>(builder: (_) => screen),
  ));
  await tester.pumpAndSettle();
}

Future<void> _popHarness(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigator,
) async {
  navigator.currentState!.pop();
  await tester.pumpAndSettle();
}

Future<void> _cleanup(
  WidgetTester tester,
  _HarnessCamera camera, {
  void Function()? releasePending,
}) async {
  // Also cleans a deliberately failing old implementation's late subscription.
  await tester.pumpWidget(const SizedBox.shrink());
  releasePending?.call();
  await tester.pump();
  await camera.stop();
  await tester.pump();
  await camera.close();
}

class _HarnessCamera extends OwnedTestCamera {
  _HarnessCamera({super.holdNativeStart = false})
    : super(
        libraryTag: 'harness-retirement-fixture',
      );
}
