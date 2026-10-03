import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/expect.dart' as matcher_expect;
import 'package:jablab/app/account_bridge.dart';
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
const _recovery = Key('test-account-recovery');
const _unrelated = Key('test-resource-unrelated');

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

  testWidgets('same UUID recovery retires journal and covered training route', (
    tester,
  ) async {
    final fixture = await _open(tester);
    final old = fixture.registry.capture(_alice);
    final store = (await _io(
      tester,
      () => fixture.repository.openStore(accountUserId: _alice),
    ));
    await _io(tester, () => store.append(_record()));
    await _openLesson(tester);
    final training = fixture.observer.routes.last;
    unawaited(
      fixture.observer.navigator!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: Text('Unrelated', key: _unrelated)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    fixture.recovery.value = true;
    expectSync(
      fixture.account.value,
      _alice,
      reason: 'recovery does not change the UUID',
    );
    expectSync(
      old.isActive,
      isFalse,
      reason: 'retirement precedes any frame or filesystem await',
    );
    await _io(tester, old.retireAndDrain);
    await tester.pumpAndSettle();

    expectSync(training.isActive, isFalse);
    expectSync(find.byType(SessionScreen, skipOffstage: false), findsNothing);
    expectSync(find.byKey(_unrelated), findsOneWidget);
    expectSync(find.byKey(_recovery, skipOffstage: false), findsOneWidget);
    await _io(tester, () async {
      await matcher_expect.expectLater(
        store.append(_record()),
        throwsA(isA<SessionStoreRetiredException>()),
      );
      await matcher_expect.expectLater(
        store.recent(),
        throwsA(isA<SessionStoreRetiredException>()),
      );
      expectSync(
        await sessionFileFor(fixture.directory, _alice).exists(),
        isTrue,
      );
    });
    expectSync(tester.takeException(), isNull);
  });

  testWidgets(
    'recovery completion admits a fresh epoch and preserves prior history',
    (tester) async {
      final fixture = await _open(tester);
      final old = fixture.registry.capture(_alice);
      final oldStore = (await _io(
        tester,
        () => fixture.repository.openStore(accountUserId: _alice),
      ));
      await _io(tester, () => oldStore.append(_record()));
      fixture.recovery.value = true;
      await _io(tester, old.retireAndDrain);
      await tester.pumpAndSettle();
      fixture.recovery.value = false;
      await settleAppLoad(tester);
      await tester.pumpAndSettle();
      final fresh = fixture.registry.capture(_alice);
      expectSync(fresh.epoch, greaterThan(old.epoch));
      expectSync(old.isActive, isFalse);
      expectSync(fresh.isActive, isTrue);
      await _io(tester, () async {
        final next = await fixture.repository.openStore(accountUserId: _alice);
        expectSync(await next.recent(), hasLength(1));
        await next.append(_record());
        expectSync(await next.recent(), hasLength(2));
        await matcher_expect.expectLater(
          oldStore.append(_record()),
          throwsA(isA<SessionStoreRetiredException>()),
        );
      });
      await _openLesson(tester);
      expectSync(find.byType(SessionScreen), findsOneWidget);
      expectSync(tester.takeException(), isNull);
    },
  );

  testWidgets('confirmed Alice cleanup keeps Bob route and guest files', (
    tester,
  ) async {
    final fixture = await _open(tester);
    await _io(tester, () async {
      final alice = await fixture.repository.openStore(accountUserId: _alice);
      await alice.append(_record());
      await sessionFileFor(fixture.directory, null).writeAsString('guest');
    });
    fixture.account.value = _bob;
    await settleAppLoad(tester);
    await tester.pumpAndSettle();
    await _ownerReady(tester, fixture.registry, _bob);
    final bob = fixture.registry.capture(_bob);
    await _io(tester, () async {
      final store = await fixture.repository.openStore(accountUserId: _bob);
      await store.append(_record());
    });
    await _openLesson(tester);
    final training = fixture.observer.routes.last;
    await _io(
      tester,
      () => clearLocalHistoryFor(
        _alice,
        supportDirectory: fixture.directory,
        ownerRegistry: fixture.registry,
      ),
    );
    await tester.pumpAndSettle();
    expectSync(bob.isActive, isTrue);
    expectSync(training.isCurrent, isTrue);
    expectSync(find.byType(SessionScreen), findsOneWidget);
    await _io(tester, () async {
      expectSync(
        await sessionFileFor(fixture.directory, _alice).exists(),
        isFalse,
      );
      expectSync(
        await sessionFileFor(fixture.directory, _bob).exists(),
        isTrue,
      );
      expectSync(
        await sessionFileFor(fixture.directory, null).readAsString(),
        'guest',
      );
    });
    expectSync(tester.takeException(), isNull);
  });

  for (final solo in <bool>[false, true]) {
    testWidgets(
      'unmount retires active ${solo ? 'solo' : 'live'} route without ancestor lookup',
      (tester) async {
        final fixture = await _open(tester);
        final lifetime = fixture.registry.capture(_alice);
        if (solo) {
          await tester.tap(
            find.byKey(const Key('open-solo-boxing-course')).first,
          );
          await settleUntil(
            tester,
            find.byKey(const Key('solo-lesson-boxing.start.space')),
          );
        } else {
          await _openLesson(tester);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        expectSync(lifetime.isActive, isFalse);
        await _io(tester, lifetime.retireAndDrain);
        await tester.pumpAndSettle();
        expectSync(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('fresh root waits for the old same-owner filesystem drain', (
    tester,
  ) async {
    final fixture = await _open(tester);
    final old = fixture.registry.capture(_alice);
    final gate = Completer<void>();
    final held = old.runCourseIo(() async {
      await gate.future;
      await courseFileFor(fixture.directory, _alice).writeAsString('admitted');
    });
    final observed = held.then<void>(
      (_) => fail('retired admitted course operation must reject its result'),
      onError: (Object error) {
        expectSync(error, isA<OwnerResourceRetiredException>());
      },
    );
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.pumpWidget(const SizedBox.shrink());
    expectSync(old.isActive, isFalse);
    await tester.runAsync(
      () => tester.pumpWidget(
        JabLabApp(
          repository: fixture.repository,
          onboarding: const OnboardingStore(seenOverride: true),
          accountUserId: fixture.account,
          accountRecovery: fixture.recovery,
        ),
      ),
    );
    await tester.pump();
    expectSync(
      () => fixture.registry.capture(_alice),
      throwsA(isA<OwnerResourceRetiredException>()),
      reason: 'fresh root must not admit while the old file writer is pending',
    );
    gate.complete();
    await _io(tester, () => observed);
    await _ownerReady(tester, fixture.registry, _alice);
    final fresh = fixture.registry.capture(_alice);
    expectSync(fresh.epoch, greaterThan(old.epoch));
    expectSync(fresh.isActive, isTrue);
    expectSync(
      await tester.runAsync(
        () => courseFileFor(fixture.directory, _alice).readAsString(),
      ),
      'admitted',
    );
    expectSync(tester.takeException(), isNull);
  });

  testWidgets('same UUID recovery cancels a pending lesson guard before push', (
    tester,
  ) async {
    final guard = Completer<bool>();
    final fixture = await _open(tester, guard: (_) => guard.future);
    final existing = List<Route<dynamic>>.of(fixture.observer.routes);
    await tester.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
    await tester.pump();
    fixture.recovery.value = true;
    guard.complete(true);
    await tester.pumpAndSettle();
    expectSync(fixture.observer.routes, orderedEquals(existing));
    expectSync(find.byType(SessionScreen, skipOffstage: false), findsNothing);
    expectSync(
      () => fixture.registry.capture(_alice),
      throwsA(isA<OwnerResourceRetiredException>()),
    );
    expectSync(tester.takeException(), isNull);
  });
}

SessionRecord _record() => SessionRecord(
  lessonId: 'boxing.foundations.jab',
  completedAt: DateTime.utc(2026, 10, 2),
  workedSeconds: 1,
  unitsCompleted: 1,
  plannedUnits: 1,
  unitLabel: 'round',
  lessonClass: 'unscored',
);

Future<_Fixture> _open(
  WidgetTester tester, {
  Future<bool> Function(BuildContext)? guard,
}) async {
  final directory = (await _io(
    tester,
    () => Directory.systemTemp.createTemp('jablab-shell-resource-'),
  ));
  final registry = OwnerResourceRegistry();
  final repository = ContentRepository(
    historyDirectoryOverride: directory,
    ownerRegistry: registry,
  );
  final account = ValueNotifier<String?>(_alice);
  final recovery = ValueNotifier<bool>(false);
  final observer = _Routes();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await _io(tester, () async {
      await registry.retireAll();
      await directory.delete(recursive: true);
    });
    account.dispose();
    recovery.dispose();
  });
  await tester.runAsync(
    () => tester.pumpWidget(
      JabLabApp(
        repository: repository,
        onboarding: const OnboardingStore(seenOverride: true),
        accountUserId: account,
        accountRecovery: recovery,
        navigatorObservers: <NavigatorObserver>[observer],
        accountPageBuilder: (_) =>
            const Scaffold(body: Text('Recovery', key: _recovery)),
        beforeLessonStart: guard ?? (_) async => true,
      ),
    ),
  );
  await settleAppLoad(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('item-boxing')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('course-boxing.foundations')));
  await tester.pumpAndSettle();
  expectSync(find.byType(CoursePage), findsOneWidget);
  return _Fixture(directory, registry, repository, account, recovery, observer);
}

Future<void> _openLesson(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
  await tester.pumpAndSettle();
  expectSync(find.byType(SessionScreen), findsOneWidget);
}

class _Fixture {
  const _Fixture(
    this.directory,
    this.registry,
    this.repository,
    this.account,
    this.recovery,
    this.observer,
  );
  final Directory directory;
  final OwnerResourceRegistry registry;
  final ContentRepository repository;
  final ValueNotifier<String?> account;
  final ValueNotifier<bool> recovery;
  final _Routes observer;
}

class _Routes extends NavigatorObserver {
  final routes = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.remove(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.remove(route);
}

/// Real file events and Flutter fake-zone continuations must both advance.
/// Awaiting a drain only inside runAsync starves continuations admitted by UI.
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
    reason: 'real IO and admitted UI continuations must settle within 80 pumps',
  );
  if (error != null) Error.throwWithStackTrace(error!, stack!);
  return value as T;
}

Future<void> _ownerReady(
  WidgetTester tester,
  OwnerResourceRegistry registry,
  String id,
) async {
  for (int i = 0; i < 80; i++) {
    try {
      registry.capture(id);
      return;
    } on OwnerResourceRetiredException {
      /* awaiting previous epoch drain */
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  fail('new owner was not admitted after the previous IO drained');
}
