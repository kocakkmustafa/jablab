import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/account_bridge.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:jablab/app/solo_boxing_course_page.dart';
import 'package:jablab/app/solo_boxing_progress.dart';

import 'app_pump.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1200,
      3000,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });
  tearDown(() {
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('solo late builder rejects an owner retired inside didPush', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('jablab-solo-route-'),
    ))!;
    final registry = OwnerResourceRegistry()..activate(_alice);
    final account = ValueNotifier<String?>(_alice);
    final admission = ValueNotifier<bool>(true);
    final observer = _Push();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await _io(tester, registry.retireAll);
      await tester.runAsync(() => directory.delete(recursive: true));
      account.dispose();
      admission.dispose();
    });
    await tester.runAsync(
      () => tester.pumpWidget(
        MaterialApp(
          navigatorObservers: <NavigatorObserver>[observer],
          home: SoloBoxingCoursePage(
            repository: ContentRepository(
              historyDirectoryOverride: directory,
              ownerRegistry: registry,
            ),
            accountUserId: account,
            resourceAdmission: admission,
          ),
        ),
      ),
    );
    await settleUntil(
      tester,
      find.byKey(const Key('solo-lesson-boxing.start.space')),
    );
    final pushed = Completer<Route<dynamic>>();
    observer.next = (route) {
      admission.value = false;
      account.value = _bob;
      unawaited(registry.retire(_alice));
      pushed.complete(route);
    };
    await tester.tap(find.byKey(const Key('solo-lesson-boxing.start.space')));
    final route = await _io(tester, () => pushed.future);
    await tester.pumpAndSettle();
    expect(route.isActive, isFalse);
    expect(
      find.byType(SoloBoxingLessonPage, skipOffstage: false),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing the same UUID notifier retires the old solo lesson', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('jablab-solo-replace-'),
    ))!;
    final registry = OwnerResourceRegistry()..activate(_alice);
    final first = ValueNotifier<String?>(_alice);
    final replacement = ValueNotifier<String?>(_alice);
    final course = SoloBoxingCourse.fromJsonString(
      File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
    );
    final lesson = course.lessons.first;
    final store = soloProgressStoreFor(
      directory,
      _alice,
      ownerRegistry: registry,
    );
    Widget page(ValueNotifier<String?> owner) => MaterialApp(
      home: SoloBoxingLessonPage(
        key: const Key('same-solo-state'),
        course: course,
        lesson: lesson,
        store: store,
        initialProgress: null,
        accountAtOpen: _alice,
        accountUserId: owner,
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await _io(tester, registry.retireAll);
      await tester.runAsync(() => directory.delete(recursive: true));
      first.dispose();
      replacement.dispose();
    });
    await tester.pumpWidget(page(first));
    expect(find.byKey(const Key('solo-lesson-list')), findsOneWidget);
    await tester.pumpWidget(page(replacement));
    expect(
      find.byKey(const Key('solo-lesson-list')),
      findsNothing,
      reason:
          'same UUID notifier replacement retires the original lesson immediately',
    );
    replacement.value = _bob;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('solo-lesson-list')), findsNothing);
    expect(
      await tester.runAsync(() => courseFileFor(directory, _alice).exists()),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}

class _Push extends NavigatorObserver {
  void Function(Route<dynamic>)? next;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final callback = next;
    next = null;
    callback?.call(route);
  }
}

Future<T> _io<T>(WidgetTester tester, Future<T> Function() action) async {
  bool settled = false;
  T? value;
  Object? error;
  StackTrace? stack;
  action().then(
    (result) {
      value = result;
      settled = true;
    },
    onError: (Object failure, StackTrace trace) {
      error = failure;
      stack = trace;
      settled = true;
    },
  );
  for (int i = 0; i < 80 && !settled; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  expectSync(
    settled,
    isTrue,
    reason: 'admitted course IO must settle within 80 pumps',
  );
  if (error != null) Error.throwWithStackTrace(error!, stack!);
  return value as T;
}
