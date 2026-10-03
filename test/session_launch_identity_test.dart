import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/session_store.dart';

import 'app_pump.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _unrelatedRouteKey = Key('launch-identity-unrelated-route');
const _seen = OnboardingStore(seenOverride: true);

/// Real application navigation, with a memory journal and no live camera
/// stage. didPush is the synchronous boundary after the membership guard and
/// before the new route has built its first SessionScreen.
// Each test owns a storage namespace; replacements inside it share this registry.
late OwnerResourceRegistry _owners;

void main() {
  setUp(() => _owners = OwnerResourceRegistry());
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1200,
      3000,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });
  tearDown(() {
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets(
    'account changed by didPush retires the launch and preserves other routes',
    (tester) async {
      final account = ValueNotifier<String?>(_alice);
      final store = _MemoryStore();
      final observer = _RouteWitness();
      var guardCalls = 0;
      await _openCourse(
        tester,
        account: account,
        store: store,
        observer: observer,
        beforeLessonStart: (_) async {
          guardCalls++;
          return true;
        },
      );
      final rootRoute = observer.activeRoutes.first;
      final courseRoute = observer.activeRoutes.last;
      Route<dynamic>? launchRoute;
      Route<void>? unrelatedRoute;
      var switches = 0;
      var guardCallsAtPush = 0;
      var screenWasAbsentAtPush = false;
      observer.onNextPush = (route) {
        launchRoute = route;
        guardCallsAtPush = guardCalls;
        screenWasAbsentAtPush = find
            .byType(SessionScreen, skipOffstage: false)
            .evaluate()
            .isEmpty;
        switches++;
        account.value = _bob;
        // Navigator is locked inside didPush. Queue a real unrelated push
        // before any retirement callback scheduled by the route builder.
        binding.addPostFrameCallback((_) {
          final next = MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Unrelated route', key: _unrelatedRouteKey),
              ),
            ),
          );
          unrelatedRoute = next;
          unawaited(observer.navigator!.push<void>(next));
        });
      };

      await tester.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
      await tester.pumpAndSettle();

      expect(guardCallsAtPush, 1);
      expect(screenWasAbsentAtPush, isTrue);
      expect(switches, 1);
      expect(guardCalls, 1);
      expect(account.value, _bob);
      expect(launchRoute, isNotNull);
      expect(unrelatedRoute, isNotNull);
      expect(find.byKey(_unrelatedRouteKey), findsOneWidget);
      expect(
        find.byType(SessionScreen, skipOffstage: false),
        findsNothing,
        reason: 'the Alice launch must not become a Bob session on first build',
      );
      expect(
        launchRoute!.isActive,
        isFalse,
        reason: 'an invalid launch must not leave a persistent empty route',
      );
      expect(rootRoute.isActive, isTrue);
      expect(courseRoute.isActive, isTrue);
      expect(unrelatedRoute!.isCurrent, isTrue);
      expect(
        observer.activeRoutes,
        orderedEquals(<Route<dynamic>>[
          rootRoute,
          courseRoute,
          unrelatedRoute!,
        ]),
        reason:
            'retiring one launch must keep the course and unrelated top route',
      );
      expect(store.written, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the same owner reaches the guarded session normally', (
    tester,
  ) async {
    final account = ValueNotifier<String?>(_alice);
    final store = _MemoryStore();
    final observer = _RouteWitness();
    var guardCalls = 0;
    await _openCourse(
      tester,
      account: account,
      store: store,
      observer: observer,
      beforeLessonStart: (_) async {
        guardCalls++;
        return true;
      },
    );
    final courseRoute = observer.activeRoutes.last;

    await tester.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
    await tester.pumpAndSettle();

    expect(guardCalls, 1);
    expect(account.value, _alice);
    expect(find.byType(SessionScreen), findsOneWidget);
    expect(find.byKey(const Key('stage-teach')), findsOneWidget);
    final screen = tester.widget<SessionScreen>(find.byType(SessionScreen));
    expect(screen.lesson.id, 'boxing.foundations.jab');
    expect(identical(screen.accountUserId, account), isTrue);
    expect(identical(screen.store, store), isTrue);
    expect(courseRoute.isActive, isTrue);
    expect(observer.activeRoutes, hasLength(3));
    expect(observer.activeRoutes.last.isCurrent, isTrue);
    expect(store.written, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account changed while the guard waits never pushes a session', (
    tester,
  ) async {
    final account = ValueNotifier<String?>(_alice);
    final store = _MemoryStore();
    final observer = _RouteWitness();
    final guard = Completer<bool>();
    var guardCalls = 0;
    addTearDown(() {
      if (!guard.isCompleted) guard.complete(false);
    });
    await _openCourse(
      tester,
      account: account,
      store: store,
      observer: observer,
      beforeLessonStart: (_) {
        guardCalls++;
        return guard.future;
      },
    );
    final existingRoutes = List<Route<dynamic>>.of(observer.activeRoutes);

    await tester.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
    await tester.pump();
    expect(guardCalls, 1);
    expect(guard.isCompleted, isFalse);
    expect(observer.activeRoutes, orderedEquals(existingRoutes));
    expect(find.byType(SessionScreen, skipOffstage: false), findsNothing);

    account.value = _bob;
    await tester.pump();
    guard.complete(true);
    await tester.pumpAndSettle();

    expect(guardCalls, 1);
    expect(account.value, _bob);
    expect(find.byType(SessionScreen, skipOffstage: false), findsNothing);
    expect(find.byType(CoursePage), findsOneWidget);
    expect(observer.activeRoutes, orderedEquals(existingRoutes));
    expect(observer.pushedRoutes, hasLength(2));
    expect(existingRoutes.every((route) => route.isActive), isTrue);
    expect(store.written, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openCourse(
  WidgetTester tester, {
  required ValueNotifier<String?> account,
  required _MemoryStore store,
  required _RouteWitness observer,
  required Future<bool> Function(BuildContext) beforeLessonStart,
}) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    account.dispose();
  });
  await tester.runAsync(() async {
    await tester.pumpWidget(
      JabLabApp(
        repository: ContentRepository(
          storeOverride: store,
          ownerRegistry: _owners,
        ),
        onboarding: _seen,
        navigatorObservers: <NavigatorObserver>[observer],
        accountUserId: account,
        beforeLessonStart: beforeLessonStart,
      ),
    );
  });
  await settleAppLoad(tester);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('content-error')), findsNothing);
  await tester.tap(find.byKey(const Key('item-boxing')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('course-boxing.foundations')));
  await tester.pumpAndSettle();
  expect(find.byType(CoursePage), findsOneWidget);
  expect(observer.activeRoutes, hasLength(2));
}

class _RouteWitness extends NavigatorObserver {
  final activeRoutes = <Route<dynamic>>[];
  final pushedRoutes = <Route<dynamic>>[];
  void Function(Route<dynamic>)? onNextPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    activeRoutes.add(route);
    pushedRoutes.add(route);
    final callback = onNextPush;
    onNextPush = null;
    callback?.call(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    activeRoutes.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    activeRoutes.remove(route);
  }
}

class _MemoryStore implements SessionStore {
  final written = <SessionRecord>[];

  @override
  Future<void> append(SessionRecord record) async => written.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async =>
      List<SessionRecord>.of(written);

  @override
  Future<int> unreadableRecords() async => 0;

  @override
  Future<int> workedSecondsFor(String lessonId) async => written
      .where((record) => record.lessonId == lessonId)
      .fold<int>(0, (total, record) => total + record.workedSeconds);
}
