import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jablab/app/account_bridge.dart';
import 'package:jablab/app/owner_bound_account_page.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:motion_account/motion_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'actual runtime held refresh denies fresh delete until exact proof succeeds',
    (tester) async {
      final fixture = await _fixture(tester);
      late MotionAccountRuntime runtime;
      late Completer<void> hold;
      Future<Object?>? verification;
      await tester.runAsync(() async {
        hold = Completer<void>();
        runtime = MotionAccountRuntime.forTesting(
          client: fixture.client,
          app: MotionApp.jablab,
          onDeletedAccount: (_) async {},
        );
        await runtime.refreshIdentity();
        await _eventTurn();
      });
      try {
        expect(runtime.isCurrentSessionVerified, isTrue);
        final owner = fixture.owners.capture(_alice);
        await _page(
          tester,
          fixture,
          lifetime: owner,
          account: runtime.account,
          canInitiate: () =>
              runtime.isCurrentSessionVerified && !runtime.isPasswordRecovery,
        );
        final bound = tester
            .widget<MotionAccountPage>(find.byType(MotionAccountPage))
            .account;
        await tester.runAsync(() async {
          fixture.userReadHold = hold;
          fixture.userReadStarted = Completer<void>();
          await fixture.refreshToken('alice-proof-pending');
          verification = runtime.refreshIdentity().then<Object?>(
            (_) => null,
            onError: (Object error, StackTrace _) => error,
          );
          await fixture.userReadStarted!.future.timeout(
            const Duration(seconds: 5),
          );
        });
        expect(runtime.isCurrentSessionVerified, isFalse);
        expect(fixture.owners.capture(_alice), same(owner));
        expect(owner.isActive, isTrue);
        await tester.runAsync(() async {
          await expectLater(
            bound.deleteCommonAccount(),
            throwsA(isA<OwnerResourceRetiredException>()),
          );
        });
        expect(fixture.deleteRequests, 0);
        expect(fixture.cleanupCalls, 0);
        hold.complete();
        fixture.userReadHold = null;
        await tester.runAsync(() async {
          expect(await verification, isNull);
          await runtime.refreshIdentity();
        });
        expect(runtime.isCurrentSessionVerified, isTrue);
        expect(fixture.owners.capture(_alice), same(owner));
        await tester.runAsync(() => bound.deleteCommonAccount());
        expect(fixture.deleteRequests, 1);
      } finally {
        if (!hold.isCompleted) hold.complete();
        fixture.userReadHold = null;
        await _unmount(tester);
        await tester.runAsync(() async {
          if (verification != null) await verification;
          runtime.dispose();
        });
      }
    },
  );

  testWidgets('actual deletion dialog cannot dispatch after A1-B-A2', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    final a1 = fixture.owners.capture(_alice);
    await _page(tester, fixture, lifetime: a1);
    await _openDeletion(tester);
    await tester.runAsync(() async {
      await fixture.owners.retire(_alice);
      await fixture.signIn(_bob, 'bob-session');
    });
    await tester.pump();
    await tester.runAsync(() async {
      fixture.owners.activate(_alice);
      await fixture.signIn(_alice, 'alice-fresh-session');
    });
    await tester.pump();
    final before = fixture.snapshot();
    await _confirm(tester);
    expect(fixture.deleteRequests, 0);
    expect(fixture.cleanupCalls, 0);
    expect(fixture.snapshot(), before);
    expect(fixture.owners.capture(_alice).isActive, isTrue);
    expect(
      fixture.client.auth.currentSession?.accessToken,
      'alice-fresh-session',
    );
    await _unmount(tester);
  });

  for (final newTicket in [false, true]) {
    testWidgets(
      'verified receipt erases A after fresh same-UUID auth (new ticket $newTicket)',
      (tester) async {
        final fixture = await _fixture(tester, holdRemote: true);
        final initiating = fixture.owners.capture(_alice);
        await _page(tester, fixture, lifetime: initiating);
        await _openDeletion(tester);
        await _confirm(tester, settle: false);
        await _signal(tester, fixture.deleteEntered);
        expect(fixture.deleteRequests, 1);
        expect(fixture.authorization, 'Bearer alice-session');
        expect(fixture.deleteBody?['expectedUserId'], _alice);
        await tester.runAsync(() async {
          if (newTicket) {
            await fixture.owners.retire(_alice);
            fixture.owners.activate(_alice);
          }
          await fixture.signIn(_alice, 'alice-fresh-session');
        });
        await tester.pump();
        final preserved = fixture.snapshot(exclude: _alice);
        final successor = fixture.owners.capture(_alice);
        await tester.runAsync(() async {
          fixture.releaseRemote();
          await _eventTurn();
        });
        await _finished(tester);
        expect(fixture.cleanupCalls, 1);
        expect(fixture.accountFiles(_alice), hasLength(4));
        expect(
          fixture.accountFiles(_alice).where((file) => file.existsSync()),
          isEmpty,
        );
        expect(fixture.snapshot(exclude: _alice), preserved);
        expect(initiating.isActive, isFalse);
        expect(successor.isActive, isFalse);
        expect(fixture.logoutRequests, 0);
        expect(
          fixture.client.auth.currentSession?.accessToken,
          'alice-fresh-session',
        );
        expect(
          find.textContaining('Local history could not be cleared now'),
          findsNothing,
        );
        await _unmount(tester);
      },
    );
  }

  testWidgets('held confirmed cleanup blocks a successor owner activation', (
    tester,
  ) async {
    final fixture = await _fixture(tester, holdCleanup: true);
    final initiating = fixture.owners.capture(_alice);
    final preserved = fixture.snapshot(exclude: _alice);
    await _page(tester, fixture, lifetime: initiating);
    await _openDeletion(tester);
    await _confirm(tester, settle: false);
    await _signal(tester, fixture.cleanupEntered);
    expect(fixture.cleanupCalls, 1);
    expect(initiating.isActive, isFalse);
    expect(
      () => fixture.owners.activate(_alice),
      throwsA(isA<OwnerResourceRetiredException>()),
    );
    expect(fixture.snapshot(exclude: _alice), preserved);
    await tester.runAsync(() async {
      fixture.releaseCleanup();
      await _eventTurn();
    });
    await _signal(tester, fixture.cleanupFinished);
    await _finished(tester);
    expect(
      fixture.accountFiles(_alice).where((file) => file.existsSync()),
      isEmpty,
    );
    expect(fixture.snapshot(exclude: _alice), preserved);
    expect(fixture.logoutRequests, 1);
    await _unmount(tester);
  });

  group('store subscription management (JAB-14)', () {
    testWidgets('signed-in member page offers the store link while selling', (
      tester,
    ) async {
      final fixture = await _fixture(tester);
      var opened = 0;
      await _page(
        tester,
        fixture,
        lifetime: fixture.owners.capture(_alice),
        membershipAvailable: true,
        onManageSubscription: () async {
          opened++;
          return true;
        },
      );
      await tester.runAsync(_eventTurn);
      await tester.pumpAndSettle();
      final link = find.text('Manage store subscription');
      await tester.scrollUntilVisible(
        link,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(link);
      await tester.pump();
      expect(opened, 1);
      expect(
        find.text('Could not open the store subscription page.'),
        findsNothing,
      );
      expect(fixture.membershipChecks, greaterThanOrEqualTo(1));
      await _unmount(tester);
    });

    testWidgets('a store page that cannot open says so with Core text', (
      tester,
    ) async {
      final fixture = await _fixture(tester);
      await _page(
        tester,
        fixture,
        lifetime: fixture.owners.capture(_alice),
        membershipAvailable: true,
        onManageSubscription: () async => false,
      );
      await tester.runAsync(_eventTurn);
      await tester.pumpAndSettle();
      final link = find.text('Manage store subscription');
      await tester.scrollUntilVisible(
        link,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(link);
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Could not open the store subscription page.'),
        findsOneWidget,
      );
      await _unmount(tester);
    });

    testWidgets('closed sales hide the store link even when wired', (
      tester,
    ) async {
      final fixture = await _fixture(tester);
      await _page(
        tester,
        fixture,
        lifetime: fixture.owners.capture(_alice),
        onManageSubscription: () async => true,
      );
      expect(
        tester
            .widget<MotionAccountPage>(find.byType(MotionAccountPage))
            .onManageSubscription,
        isNull,
      );
      expect(find.text('Manage store subscription'), findsNothing);
      expect(fixture.membershipChecks, 0);
      await _unmount(tester);
    });

    testWidgets('a guest never sees the store link', (tester) async {
      final fixture = await _fixture(tester);
      await tester.runAsync(() async {
        await fixture.client.auth.signOut();
        await _eventTurn();
      });
      await _page(
        tester,
        fixture,
        membershipAvailable: true,
        onManageSubscription: () async => true,
      );
      expect(fixture.client.auth.currentUser, isNull);
      expect(find.text('Manage store subscription'), findsNothing);
      await _unmount(tester);
    });
  });

  testWidgets('normal current owner deletes exactly its four files', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    final initiating = fixture.owners.capture(_alice);
    final preserved = fixture.snapshot(exclude: _alice);
    expect(fixture.accountFiles(_alice), hasLength(4));
    await _page(tester, fixture, lifetime: initiating);
    await _openDeletion(tester);
    await _confirm(tester);
    expect(fixture.deleteRequests, 1);
    expect(fixture.cleanupCalls, 1);
    expect(
      fixture.accountFiles(_alice).where((file) => file.existsSync()),
      isEmpty,
    );
    expect(fixture.snapshot(exclude: _alice), preserved);
    expect(fixture.client.auth.currentUser, isNull);
    expect(fixture.logoutRequests, 1);
    await _unmount(tester);
  });

  testWidgets('replayed historical sign-ins do not retire a new current page', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await tester.runAsync(() async {
      await fixture.signIn(_bob, 'bob-historical-session');
      await fixture.signIn(_alice, 'alice-current-session');
    });
    await _page(tester, fixture, lifetime: fixture.owners.capture(_alice));
    await _openDeletion(tester);
    await _confirm(tester);
    expect(fixture.deleteRequests, 1);
    expect(fixture.authorization, 'Bearer alice-current-session');
    expect(fixture.cleanupCalls, 1);
    await _unmount(tester);
  });

  testWidgets('recovery without an active account ticket has no deletion', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await tester.runAsync(() => fixture.owners.retire(_alice));
    await _page(tester, fixture, recovery: true);
    final shared = tester.widget<MotionAccountPage>(
      find.byType(MotionAccountPage),
    );
    expect(shared.account, isNot(same(fixture.account)));
    expect(shared.account.supabase, same(fixture.client));
    expect(shared.clearLocalData, isNull);
    expect(find.text('Save password'), findsOneWidget);
    expect(find.text('Delete Motion account'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'New password'),
      'test-password-only',
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Save password'));
      await _eventTurn();
    });
    await _finished(tester);
    expect(fixture.passwordUpdates, 1);
    expect(fixture.deleteRequests, 0);
    expect(find.text('Save profile'), findsOneWidget);
    expect(find.text('Delete Motion account'), findsNothing);
    await _unmount(tester);
  });

  testWidgets(
    'HOST signedIn stream event retires authorization with unchanged Session',
    (tester) async {
      final fixture = await _fixture(tester);
      final host = await _hostAuth(tester, fixture);
      final lifetime = fixture.owners.capture(_alice);
      await _page(tester, fixture, lifetime: lifetime, account: host);
      await _openDeletion(tester);
      final session = fixture.client.auth.currentSession;
      final before = fixture.snapshot();
      // A controlled public account-stream seam changes host policy only;
      // GoTrue Session/token ownership remains unchanged.
      host.emitSignedIn();
      await tester.pump();
      expect(fixture.client.auth.currentSession, same(session));
      await _confirm(tester);
      expect(fixture.deleteRequests, 0);
      expect(fixture.cleanupCalls, 0);
      expect(fixture.snapshot(), before);
      expect(fixture.owners.capture(_alice), same(lifetime));
      expect(lifetime.isActive, isTrue);
      await _unmount(tester);
    },
  );

  for (final replayed in [false, true]) {
    testWidgets(
      'HOST auth stream error stays observed and fails closed (replayed $replayed)',
      (tester) async {
        final fixture = await _fixture(tester);
        final host = await _hostAuth(tester, fixture);
        final lifetime = fixture.owners.capture(_alice);
        if (replayed) host.emitError(StateError('test offline auth'));
        await _page(tester, fixture, lifetime: lifetime, account: host);
        await _openDeletion(tester);
        if (!replayed) {
          host.emitError(StateError('test offline auth'));
          await tester.pump();
        }
        final before = fixture.snapshot();
        await _confirm(tester);
        expect(tester.takeException(), isNull);
        expect(fixture.deleteRequests, 0);
        expect(fixture.cleanupCalls, 0);
        expect(fixture.snapshot(), before);
        expect(lifetime.isActive, isTrue);
        await _unmount(tester);
      },
    );
  }

  testWidgets('same-owner token refresh before dispatch preserves the ticket', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    final lifetime = fixture.owners.capture(_alice);
    await _page(tester, fixture, lifetime: lifetime);
    await tester.runAsync(
      () => fixture.refreshToken('alice-refreshed-session'),
    );
    await tester.pump();
    expect(fixture.owners.capture(_alice), same(lifetime));
    expect(lifetime.isActive, isTrue);
    await _openDeletion(tester);
    await _confirm(tester);
    expect(fixture.deleteRequests, 1);
    expect(fixture.authorization, 'Bearer alice-refreshed-session');
    expect(fixture.cleanupCalls, 1);
    expect(
      fixture.accountFiles(_alice).where((file) => file.existsSync()),
      isEmpty,
    );
    await _unmount(tester);
  });

  testWidgets(
    'token refresh preserves captured cleanup epoch and drains its owner write',
    (tester) async {
      final fixture = await _fixture(tester, holdRemote: true);
      final lifetime = fixture.owners.capture(_alice);
      final before = fixture.snapshot();
      final preserved = fixture.snapshot(exclude: _alice);
      final releaseWrite = Completer<void>();
      final writeEntered = Completer<void>();
      final writeDone = Completer<void>();
      final capturedRetired = Completer<void>();
      Object? writeFailure;
      void onRetired() {
        if (!lifetime.isActive && !capturedRetired.isCompleted) {
          capturedRetired.complete();
        }
      }

      lifetime.active.addListener(onRetired);
      addTearDown(() => lifetime.active.removeListener(onRetired));
      addTearDown(() {
        if (!releaseWrite.isCompleted) releaseWrite.complete();
      });
      await tester.runAsync(() async {
        unawaited(
          lifetime
              .runCourseIo<void>(() async {
                writeEntered.complete();
                await releaseWrite.future;
                await fixture
                    .accountFiles(_alice)
                    .first
                    .writeAsString('admitted owner write before retirement');
              })
              .then<void>(
                (_) => writeDone.complete(),
                onError: (Object failure, StackTrace _) {
                  writeFailure = failure;
                  writeDone.complete();
                },
              ),
        );
      });
      await _signal(tester, writeEntered);
      await _page(tester, fixture, lifetime: lifetime);
      await _openDeletion(tester);
      await _confirm(tester, settle: false);
      await _signal(tester, fixture.deleteEntered);
      await tester.runAsync(
        () => fixture.refreshToken('alice-refreshed-session'),
      );
      await tester.pump();
      expect(fixture.owners.capture(_alice), same(lifetime));
      expect(lifetime.isActive, isTrue);
      await tester.runAsync(() async {
        fixture.releaseRemote();
        await _eventTurn();
      });
      await _signal(tester, capturedRetired);
      await _signal(tester, fixture.cleanupAdmitted);
      // Both captured retirement and authoritative namespace fence start before
      // waiting on the old admitted write. Erasure remains behind that drain.
      expect(fixture.cleanupCalls, 1);
      expect(fixture.cleanupAdmitted.isCompleted, isTrue);
      expect(lifetime.isActive, isFalse);
      expect(fixture.cleanupEntered.isCompleted, isFalse);
      expect(fixture.snapshot(), before);
      expect(
        () => fixture.owners.activate(_alice),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      expect(
        () => fixture.owners.capture(_alice),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      await tester.runAsync(() async {
        releaseWrite.complete();
        await _eventTurn();
      });
      await _signal(tester, writeDone);
      await _signal(tester, fixture.cleanupFinished);
      await _finished(tester);
      expect(fixture.deleteRequests, 1);
      expect(fixture.authorization, 'Bearer alice-session');
      expect(writeFailure, isA<OwnerResourceRetiredException>());
      expect(fixture.cleanupCalls, 1);
      expect(fixture.accountFiles(_alice), hasLength(4));
      expect(
        fixture.accountFiles(_alice).where((file) => file.existsSync()),
        isEmpty,
      );
      expect(fixture.snapshot(exclude: _alice), preserved);
      expect(fixture.logoutRequests, 0);
      expect(fixture.client.auth.currentUser?.id, _alice);
      expect(
        fixture.client.auth.currentSession?.accessToken,
        'alice-refreshed-session',
      );
      await _unmount(tester);
    },
  );

  testWidgets(
    'opening Session replacement cannot cross a held initial replay',
    (tester) async {
      final fixture = await _fixture(tester);
      final lifetime = fixture.owners.capture(_alice);
      final openingSession = fixture.client.auth.currentSession;
      final gated = _ReplayGateAccount(fixture.client);
      addTearDown(gated.close);
      await _page(tester, fixture, lifetime: lifetime, account: gated);
      await _openDeletion(tester);
      await tester.runAsync(
        () => fixture.refreshToken('alice-replacement-session'),
      );
      gated.releaseReplay(
        AuthState(AuthChangeEvent.initialSession, openingSession),
      );
      await tester.pump();
      final before = fixture.snapshot();
      await _confirm(tester);
      expect(fixture.deleteRequests, 0);
      expect(fixture.cleanupCalls, 0);
      expect(fixture.snapshot(), before);
      expect(lifetime.isActive, isTrue);
      await _unmount(tester);
      expect(gated.activeListeners, 0);
    },
  );

  testWidgets(
    'dialog locale rebuild uses its own context for current deletion',
    (tester) async {
      final fixture = await _fixture(tester);
      final lifetime = fixture.owners.capture(_alice);
      final preserved = fixture.snapshot(exclude: _alice);
      await _page(tester, fixture, lifetime: lifetime);
      await _openDeletion(tester);
      final pageState = tester.state(find.byType(MotionAccountPage));
      await _rebuildDialogLocale(tester, fixture);
      expect(pageState.mounted, isTrue);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Hesabı sil'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _confirm(tester, label: 'Hesabı sil');
      expect(fixture.deleteRequests, 1);
      expect(fixture.cleanupCalls, 1);
      expect(fixture.logoutRequests, 1);
      expect(
        fixture.accountFiles(_alice).where((file) => file.existsSync()),
        isEmpty,
      );
      expect(fixture.snapshot(exclude: _alice), preserved);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets(
    'disposed parent dialog survives locale rebuild without dispatch',
    (tester) async {
      final fixture = await _fixture(tester);
      final lifetime = fixture.owners.capture(_alice);
      await _page(tester, fixture, lifetime: lifetime);
      await _openDeletion(tester);
      final pageState = tester.state(find.byType(MotionAccountPage));
      final openingSession = fixture.client.auth.currentSession;
      final before = fixture.snapshot();
      fixture.page.value = const SizedBox.shrink();
      await tester.pump();
      expect(pageState.mounted, isFalse);
      expect(find.byType(AlertDialog), findsOneWidget);
      await _rebuildDialogLocale(tester, fixture);
      expect(find.text('Hesabı sil'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _confirm(tester, label: 'Hesabı sil');
      expect(fixture.deleteRequests, 0);
      expect(fixture.cleanupCalls, 0);
      expect(fixture.logoutRequests, 0);
      expect(fixture.client.auth.currentSession, same(openingSession));
      expect(fixture.snapshot(), before);
      expect(lifetime.isActive, isTrue);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets('account client replacement retires the old dialog page', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    final replacement = await _fixture(tester);
    final lifetime = fixture.owners.capture(_alice);
    await _page(tester, fixture, lifetime: lifetime);
    await _openDeletion(tester);
    final oldState = tester.state(find.byType(MotionAccountPage));
    final oldAccount = tester
        .widget<MotionAccountPage>(find.byType(MotionAccountPage))
        .account;
    final before = fixture.snapshot();
    await _page(
      tester,
      fixture,
      lifetime: lifetime,
      account: replacement.account,
    );
    expect(oldState.mounted, isFalse);
    expect(find.byType(AlertDialog), findsOneWidget);
    await _confirm(tester);
    await tester.runAsync(
      () => expectLater(
        oldAccount.deleteCommonAccount(),
        throwsA(isA<OwnerResourceRetiredException>()),
      ),
    );
    expect(fixture.deleteRequests, 0);
    expect(replacement.deleteRequests, 0);
    expect(fixture.cleanupCalls, 0);
    expect(fixture.snapshot(), before);
    expect(lifetime.isActive, isTrue);
    await _unmount(tester);
  });

  testWidgets('host ticket replacement retires the old dialog page', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await _page(tester, fixture, lifetime: fixture.owners.capture(_alice));
    await _openDeletion(tester);
    final oldState = tester.state(find.byType(MotionAccountPage));
    final oldAccount = tester
        .widget<MotionAccountPage>(find.byType(MotionAccountPage))
        .account;
    final before = fixture.snapshot();
    await tester.runAsync(() async {
      await fixture.owners.retire(_alice);
      fixture.owners.activate(_alice);
    });
    await _page(tester, fixture, lifetime: fixture.owners.capture(_alice));
    expect(oldState.mounted, isFalse);
    expect(find.byType(AlertDialog), findsOneWidget);
    await _confirm(tester);
    await tester.runAsync(
      () => expectLater(
        oldAccount.deleteCommonAccount(),
        throwsA(isA<OwnerResourceRetiredException>()),
      ),
    );
    expect(fixture.deleteRequests, 0);
    expect(fixture.cleanupCalls, 0);
    expect(fixture.snapshot(), before);
    expect(fixture.owners.capture(_alice).isActive, isTrue);
    await _unmount(tester);
  });
  testWidgets(
    'queued HOST signedIn stream event prevents immediate client dispatch',
    (tester) async {
      final fixture = await _fixture(tester);
      final host = await _hostAuth(tester, fixture);
      final lifetime = fixture.owners.capture(_alice);
      await _page(tester, fixture, lifetime: lifetime, account: host);
      final bound = tester
          .widget<MotionAccountPage>(find.byType(MotionAccountPage))
          .account;
      final session = fixture.client.auth.currentSession;
      final before = fixture.snapshot();
      await tester.runAsync(() async {
        host.emitSignedIn();
        // No pump or event turn separates the controlled host event and call.
        final deletion = bound.deleteCommonAccount(
          afterRemoteDelete: (id) => fixture.clear(id),
        );
        await expectLater(
          deletion,
          throwsA(isA<OwnerResourceRetiredException>()),
        );
      });
      expect(fixture.client.auth.currentSession, same(session));
      expect(fixture.deleteRequests, 0);
      expect(fixture.cleanupCalls, 0);
      expect(fixture.snapshot(), before);
      expect(lifetime.isActive, isTrue);
    },
  );

  testWidgets('later same-owner initialSession cannot authorize old dialog', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    final lifetime = fixture.owners.capture(_alice);
    await _page(tester, fixture, lifetime: lifetime);
    await _openDeletion(tester);
    await tester.runAsync(
      () => fixture.client.auth.setInitialSession(
        jsonEncode(_session(_alice, 'alice-restored-session')),
      ),
    );
    await tester.pump();
    final before = fixture.snapshot();
    await _confirm(tester);
    expect(fixture.deleteRequests, 0);
    expect(fixture.cleanupCalls, 0);
    expect(fixture.snapshot(), before);
    expect(lifetime.isActive, isTrue);
  });

  testWidgets(
    'unobserved restored Session prevents immediate client dispatch',
    (tester) async {
      final fixture = await _fixture(tester);
      final lifetime = fixture.owners.capture(_alice);
      await _page(tester, fixture, lifetime: lifetime);
      final bound = tester
          .widget<MotionAccountPage>(find.byType(MotionAccountPage))
          .account;
      final before = fixture.snapshot();
      await tester.runAsync(() async {
        final replacement = fixture.client.auth.setInitialSession(
          jsonEncode(_session(_alice, 'alice-restored-session')),
        );
        final deletion = bound.deleteCommonAccount(
          afterRemoteDelete: (id) => fixture.clear(id),
        );
        await replacement;
        await expectLater(
          deletion,
          throwsA(isA<OwnerResourceRetiredException>()),
        );
      });
      expect(fixture.deleteRequests, 0);
      expect(fixture.cleanupCalls, 0);
      expect(fixture.snapshot(), before);
      expect(lifetime.isActive, isTrue);
    },
  );

  testWidgets(
    'queued HOST signedIn policy permits UUID erase and unchanged-Session signout',
    (tester) async {
      final fixture = await _fixture(tester, holdRemote: true);
      final host = await _hostAuth(tester, fixture);
      final lifetime = fixture.owners.capture(_alice);
      await _page(tester, fixture, lifetime: lifetime, account: host);
      await _openDeletion(tester);
      await _confirm(tester, settle: false);
      await _signal(tester, fixture.deleteEntered);
      final session = fixture.client.auth.currentSession;
      final preserved = fixture.snapshot(exclude: _alice);
      await tester.runAsync(() async {
        fixture.releaseRemote();
        host.emitSignedIn();
        await _eventTurn();
      });
      await _finished(tester);
      expect(fixture.deleteRequests, 1);
      expect(fixture.authorization, 'Bearer ${session!.accessToken}');
      expect(fixture.cleanupCalls, 1);
      expect(
        fixture.accountFiles(_alice).where((file) => file.existsSync()),
        isEmpty,
      );
      expect(fixture.snapshot(exclude: _alice), preserved);
      expect(lifetime.isActive, isFalse);
      // This synthetic policy event never changes the actual GoTrue Session.
      // Core's captured-token final sign-out is legitimate for that session.
      expect(fixture.client.auth.currentSession, isNull);
      expect(fixture.logoutRequests, 1);
    },
  );

  testWidgets(
    'identity retry preserves retired page until explicit route reopen',
    (tester) async {
      final fixture = await _fixture(tester);
      final host = await _hostAuth(tester, fixture);
      final lifetime = fixture.owners.capture(_alice);
      var retries = 0;
      host.emitError(StateError('cached auth failure'));
      await _page(
        tester,
        fixture,
        lifetime: lifetime,
        account: host,
        onRetry: () async {
          retries++;
          await fixture.signIn(_alice, 'verified-retry-session');
        },
      );
      final oldAccount = tester
          .widget<MotionAccountPage>(find.byType(MotionAccountPage))
          .account;
      await _openDeletion(tester);
      await _confirm(tester);
      expect(fixture.deleteRequests, 0);
      await tester.runAsync(() async {
        await tester.tap(find.text('Refresh account'));
        await _eventTurn();
      });
      await _finished(tester);
      expect(retries, 1);
      final retiredAccount = tester
          .widget<MotionAccountPage>(find.byType(MotionAccountPage))
          .account;
      expect(retiredAccount, same(oldAccount));
      expect(lifetime.isActive, isTrue);
      await _openDeletion(tester);
      await _confirm(tester);
      expect(fixture.deleteRequests, 0);
      await _unmount(tester);
      await _page(tester, fixture, lifetime: lifetime);
      final newAccount = tester
          .widget<MotionAccountPage>(find.byType(MotionAccountPage))
          .account;
      expect(newAccount, isNot(same(oldAccount)));
      await _openDeletion(tester);
      await _confirm(tester);
      expect(fixture.deleteRequests, 1);
      expect(fixture.authorization, 'Bearer verified-retry-session');
      expect(fixture.cleanupCalls, 1);
    },
  );
  testWidgets(
    'verified A receipt preserves replacement Bob Auth and namespace',
    (tester) async {
      final fixture = await _fixture(tester, holdRemote: true);
      final initiating = fixture.owners.capture(_alice);
      final bob = fixture.owners.capture(_bob);
      final preserved = fixture.snapshot(exclude: _alice);
      await _page(tester, fixture, lifetime: initiating);
      await _openDeletion(tester);
      await _confirm(tester, settle: false);
      await _signal(tester, fixture.deleteEntered);
      await tester.runAsync(
        () => fixture.signIn(_bob, 'bob-successor-session'),
      );
      await tester.pump();
      await tester.runAsync(() async {
        fixture.releaseRemote();
        await _eventTurn();
      });
      await _finished(tester);
      expect(fixture.deleteRequests, 1);
      expect(fixture.deleteBody?['expectedUserId'], _alice);
      expect(fixture.cleanupCalls, 1);
      expect(
        fixture.accountFiles(_alice).where((file) => file.existsSync()),
        isEmpty,
      );
      expect(fixture.snapshot(exclude: _alice), preserved);
      expect(initiating.isActive, isFalse);
      expect(bob.isActive, isTrue);
      expect(fixture.owners.capture(_bob), same(bob));
      expect(fixture.client.auth.currentUser?.id, _bob);
      expect(
        fixture.client.auth.currentSession?.accessToken,
        'bob-successor-session',
      );
      expect(fixture.logoutRequests, 0);
    },
  );

  testWidgets('same-token restored successor Auth survives verified A receipt', (
    tester,
  ) async {
    final fixture = await _fixture(tester, holdRemote: true);
    final initiating = fixture.owners.capture(_alice);
    final preserved = fixture.snapshot(exclude: _alice);
    await _page(tester, fixture, lifetime: initiating);
    await _openDeletion(tester);
    await _confirm(tester, settle: false);
    await _signal(tester, fixture.deleteEntered);
    final initiatingSession = fixture.client.auth.currentSession;
    await tester.runAsync(() async {
      await fixture.owners.retire(_alice);
      fixture.owners.activate(_alice);
      await fixture.client.auth.setInitialSession(
        jsonEncode(_session(_alice, 'alice-session')),
      );
      await _eventTurn();
    });
    await tester.pump();
    final successor = fixture.owners.capture(_alice);
    final successorSession = fixture.client.auth.currentSession;
    expect(successor, isNot(same(initiating)));
    expect(successorSession, isNot(same(initiatingSession)));
    expect(successorSession?.accessToken, initiatingSession?.accessToken);
    await tester.runAsync(() async {
      fixture.releaseRemote();
      await _eventTurn();
    });
    await _finished(tester);
    expect(fixture.cleanupCalls, 1);
    expect(
      fixture.accountFiles(_alice).where((file) => file.existsSync()),
      isEmpty,
    );
    expect(fixture.snapshot(exclude: _alice), preserved);
    expect(initiating.isActive, isFalse);
    expect(successor.isActive, isFalse);
    // This checks Core's final sign-out ownership. Host cleanup never selects
    // or changes mutable Auth; a Core failure must stay visible as behavioral RED.
    expect(fixture.client.auth.currentSession, same(successorSession));
    expect(fixture.logoutRequests, 0);
  });

  testWidgets(
    'verified A receipt fences and drains a busy replacement A epoch',
    (tester) async {
      final fixture = await _fixture(tester, holdRemote: true);
      final initiating = fixture.owners.capture(_alice);
      final preserved = fixture.snapshot(exclude: _alice);
      await _page(tester, fixture, lifetime: initiating);
      await _openDeletion(tester);
      await _confirm(tester, settle: false);
      await _signal(tester, fixture.deleteEntered);
      await tester.runAsync(() async {
        await fixture.owners.retire(_alice);
        fixture.owners.activate(_alice);
        await fixture.signIn(_alice, 'alice-E2-session');
      });
      await tester.pump();
      final successor = fixture.owners.capture(_alice);
      expect(successor, isNot(same(initiating)));
      expect(initiating.isActive, isFalse);
      final releaseWrite = Completer<void>();
      final writeEntered = Completer<void>();
      final writeDone = Completer<void>();
      Object? writeFailure;
      addTearDown(() {
        if (!releaseWrite.isCompleted) releaseWrite.complete();
      });
      await tester.runAsync(() async {
        unawaited(
          successor
              .runCourseIo<void>(() async {
                writeEntered.complete();
                await releaseWrite.future;
                await fixture
                    .accountFiles(_alice)[2]
                    .writeAsString('E2 admitted course bytes');
              })
              .then<void>(
                (_) => writeDone.complete(),
                onError: (Object failure, StackTrace _) {
                  writeFailure = failure;
                  writeDone.complete();
                },
              ),
        );
      });
      await _signal(tester, writeEntered);
      final beforeReceipt = fixture.snapshot();
      await tester.runAsync(() async {
        fixture.releaseRemote();
        await _eventTurn();
      });
      await _signal(tester, fixture.cleanupAdmitted);
      expect(fixture.cleanupCalls, 1);
      expect(successor.isActive, isFalse);
      expect(fixture.cleanupEntered.isCompleted, isFalse);
      expect(fixture.snapshot(), beforeReceipt);
      expect(
        () => fixture.owners.capture(_alice),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      expect(
        () => fixture.owners.activate(_alice),
        throwsA(isA<OwnerResourceRetiredException>()),
      );
      var newWriteEntered = false;
      await tester.runAsync(
        () => expectLater(
          successor.runCourseIo<void>(() async {
            newWriteEntered = true;
          }),
          throwsA(isA<OwnerResourceRetiredException>()),
        ),
      );
      expect(newWriteEntered, isFalse);
      await tester.runAsync(() async {
        releaseWrite.complete();
        await _eventTurn();
      });
      await _signal(tester, writeDone);
      await _signal(tester, fixture.cleanupFinished);
      await _finished(tester);
      expect(writeFailure, isA<OwnerResourceRetiredException>());
      expect(
        fixture.accountFiles(_alice).where((file) => file.existsSync()),
        isEmpty,
      );
      expect(fixture.snapshot(exclude: _alice), preserved);
      expect(
        fixture.client.auth.currentSession?.accessToken,
        'alice-E2-session',
      );
      expect(fixture.logoutRequests, 0);
    },
  );

  testWidgets('synchronous host cleanup failure still awaits captured drain', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    final lifetime = fixture.owners.capture(_alice);
    final releaseWrite = Completer<void>();
    final writeEntered = Completer<void>();
    final writeDone = Completer<void>();
    final callbackCalled = Completer<void>();
    final deletionDone = Completer<void>();
    Object? deletionFailure;
    Object? writeFailure;
    addTearDown(() {
      if (!releaseWrite.isCompleted) releaseWrite.complete();
    });
    await tester.runAsync(() async {
      unawaited(
        lifetime
            .runCourseIo<void>(() async {
              writeEntered.complete();
              await releaseWrite.future;
              await fixture
                  .accountFiles(_alice)
                  .first
                  .writeAsString('settled after cleanup failure');
            })
            .then<void>(
              (_) => writeDone.complete(),
              onError: (Object failure, StackTrace _) {
                writeFailure = failure;
                writeDone.complete();
              },
            ),
      );
    });
    await _signal(tester, writeEntered);
    await _page(tester, fixture, lifetime: lifetime);
    final bound = tester
        .widget<MotionAccountPage>(find.byType(MotionAccountPage))
        .account;
    await tester.runAsync(() async {
      unawaited(
        bound
            .deleteCommonAccount(
              afterRemoteDelete: (id) {
                expect(id, _alice);
                callbackCalled.complete();
                throw StateError('synchronous test cleanup failure');
              },
            )
            .then<void>(
              (_) => deletionDone.complete(),
              onError: (Object failure, StackTrace _) {
                deletionFailure = failure;
                deletionDone.complete();
              },
            ),
      );
    });
    await _signal(tester, callbackCalled);
    expect(lifetime.isActive, isFalse);
    expect(deletionDone.isCompleted, isFalse);
    expect(fixture.client.auth.currentUser?.id, _alice);
    await tester.runAsync(() async {
      releaseWrite.complete();
      await _eventTurn();
    });
    await _signal(tester, writeDone);
    await _signal(tester, deletionDone);
    expect(writeFailure, isA<OwnerResourceRetiredException>());
    expect(deletionFailure, isA<MotionLocalCleanupPending>());
    expect(fixture.deleteRequests, 1);
    expect(fixture.cleanupCalls, 0);
    expect(
      fixture.accountFiles(_alice).where((file) => file.existsSync()),
      hasLength(4),
    );
    expect(
      fixture.accountFiles(_alice).first.readAsStringSync(),
      'settled after cleanup failure',
    );
    expect(tester.takeException(), isNull);
  });

  for (final binding in ['missing', 'guest', 'retired', 'recovery']) {
    for (final replayed in [false, true]) {
      testWidgets(
        '$binding binding filters HOST auth errors without deletion (replayed $replayed)',
        (tester) async {
          final fixture = await _fixture(tester);
          OwnerResourceLifetime? lifetime;
          if (binding == 'guest') {
            lifetime = fixture.owners.capture(null);
            await tester.runAsync(() async {
              await fixture.account.signOut();
              await _eventTurn();
            });
          } else if (binding == 'retired') {
            lifetime = fixture.owners.capture(_alice);
            await tester.runAsync(() => fixture.owners.retire(_alice));
          }
          final before = fixture.snapshot();
          final host = await _hostAuth(tester, fixture);
          if (replayed) {
            host.emitError(StateError('cached unbound auth'));
          }
          await _page(
            tester,
            fixture,
            lifetime: lifetime,
            recovery: binding == 'recovery',
            account: host,
          );
          if (!replayed) {
            host.emitError(StateError('live unbound auth'));
            await tester.pump();
          }
          final shared = tester.widget<MotionAccountPage>(
            find.byType(MotionAccountPage),
          );
          expect(shared.account, isNot(same(fixture.account)));
          expect(shared.account.supabase, same(fixture.client));
          expect(shared.clearLocalData, isNull);
          expect(find.text('Delete Motion account'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.runAsync(
            () => expectLater(
              shared.account.deleteCommonAccount(
                afterRemoteDelete: (id) => fixture.clear(id),
              ),
              throwsA(isA<OwnerResourceRetiredException>()),
            ),
          );
          if (binding == 'recovery') {
            // Stream errors close only deletion authorization. The actual Core
            // password recovery flow remains usable on the same Supabase client.
            await tester.enterText(
              find.widgetWithText(TextField, 'New password'),
              'test-password-only',
            );
            await tester.runAsync(() async {
              await tester.tap(find.text('Save password'));
              await _eventTurn();
            });
            await _finished(tester);
            expect(fixture.passwordUpdates, 1);
            expect(find.text('Save profile'), findsOneWidget);
          } else if (binding == 'guest') {
            await tester.enterText(
              find.widgetWithText(TextField, 'Email'),
              'member@example.invalid',
            );
            await tester.enterText(
              find.widgetWithText(TextField, 'Password'),
              'test-only',
            );
            await tester.runAsync(() async {
              await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
              await _eventTurn();
            });
            await _finished(tester);
            expect(fixture.client.auth.currentUser?.id, _alice);
            expect(find.text('Save profile'), findsOneWidget);
            expect(lifetime!.isActive, isTrue);
          }
          expect(find.text('Delete Motion account'), findsNothing);
          expect(tester.takeException(), isNull);
          expect(fixture.deleteRequests, 0);
          expect(fixture.cleanupCalls, 0);
          expect(fixture.snapshot(), before);
          if (binding == 'retired') {
            expect(lifetime!.isActive, isFalse);
          } else {
            expect(fixture.owners.capture(_alice).isActive, isTrue);
          }
          await _unmount(tester);
        },
      );
    }
  }
}

Future<void> _eventTurn() => Future<void>.delayed(Duration.zero);

Future<_HostAuthAccount> _hostAuth(
  WidgetTester tester,
  _AccountFixture fixture,
) async {
  late _HostAuthAccount host;
  await tester.runAsync(() async {
    host = _HostAuthAccount(fixture.client);
    await _eventTurn();
  });
  addTearDown(() async {
    await _unmount(tester);
    await _io(tester, host.close);
  });
  return host;
}

Future<_AccountFixture> _fixture(
  WidgetTester tester, {
  bool holdRemote = false,
  bool holdCleanup = false,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  late _AccountFixture fixture;
  await tester.runAsync(() async {
    fixture = _AccountFixture(holdRemote: holdRemote, holdCleanup: holdCleanup);
    await fixture.prepare();
  });
  addTearDown(() async {
    await _unmount(tester);
    await _io(tester, fixture.close);
  });
  return fixture;
}

Future<void> _page(
  WidgetTester tester,
  _AccountFixture fixture, {
  OwnerResourceLifetime? lifetime,
  bool recovery = false,
  MotionAccountClient? account,
  Future<void> Function()? onRetry,
  bool Function()? canInitiate,
  bool membershipAvailable = false,
  Future<bool> Function()? onManageSubscription,
}) async {
  final page = OwnerBoundAccountPage(
    account: account ?? fixture.account,
    canInitiate: canInitiate,
    lifetime: lifetime,
    ownerRegistry: fixture.owners,
    initialPasswordRecovery: recovery,
    onRetryIdentity: onRetry,
    clearLocalData: (id) => fixture.clear(id),
    // Identity/deletion harness: the membership row (Core R1+ default) is
    // covered by identity_appearance_gate_test and Core's own suite; only
    // the store-subscription tests turn it on.
    membershipAvailable: membershipAvailable,
    onManageSubscription: onManageSubscription,
  );
  if (find.byKey(ObjectKey(fixture.page)).evaluate().isEmpty) {
    fixture.page.value = page;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('tr')],
        localizationsDelegates: _dialogDelegates,
        home: ValueListenableBuilder<Widget>(
          key: ObjectKey(fixture.page),
          valueListenable: fixture.page,
          builder: (context, child, _) => child,
        ),
      ),
    );
  } else {
    // Keep the real Navigator/Localizations stable while replacing only the
    // host child. Core's independent DialogRoute stays available to confirm.
    fixture.page.value = page;
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

const _dialogDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Future<void> _rebuildDialogLocale(
  WidgetTester tester,
  _AccountFixture fixture,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: const [Locale('en'), Locale('tr')],
      localizationsDelegates: _dialogDelegates,
      home: ValueListenableBuilder<Widget>(
        key: ObjectKey(fixture.page),
        valueListenable: fixture.page,
        builder: (context, child, _) => child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDeletion(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Delete Motion account'));
  await tester.tap(find.text('Delete Motion account'));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
}

Future<void> _confirm(
  WidgetTester tester, {
  bool settle = true,
  String label = 'Delete account',
}) async {
  await tester.runAsync(() async {
    await tester.tap(find.text(label));
    await _eventTurn();
  });
  await tester.pump();
  if (settle) await _finished(tester);
}

/// Retired futures may have been created in the widget's fake zone. Their
/// completion needs fake microtasks and real filesystem work to advance together.
Future<void> _io(WidgetTester tester, Future<void> Function() operation) async {
  var settled = false;
  Object? failure;
  StackTrace? stack;
  await tester.runAsync(() async {
    unawaited(
      operation().then<void>(
        (_) => settled = true,
        onError: (Object error, StackTrace trace) {
          failure = error;
          stack = trace;
          settled = true;
        },
      ),
    );
  });
  for (var turn = 0; turn < 80 && !settled; turn++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  expect(settled, isTrue, reason: 'Fixture IO did not settle');
  if (failure != null) Error.throwWithStackTrace(failure!, stack!);
}

Future<void> _signal(WidgetTester tester, Completer<void> signal) async {
  // Gates behind real fixture file IO need real time to complete; an
  // `_eventTurn` (Duration.zero) gave them almost none, so a loaded machine
  // could miss the gate (seen once on caf83b9, same file 35/35 on rerun).
  // Same shape as `_finished`: each turn yields real time, then pumps.
  for (var turn = 0; turn < 30 && !signal.isCompleted; turn++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(
    signal.isCompleted,
    isTrue,
    reason: 'Mock action did not reach its gate',
  );
}

Future<void> _finished(WidgetTester tester) async {
  // Filesystem retirement/erase runs in the real zone. Fake 20ms pumps
  // advance animation time but do not give concurrent disk work 20ms of CPU.
  // Wait on the observable busy indicator with a real, bounded IO budget.
  final deadline = Stopwatch()..start();
  while (deadline.elapsed < const Duration(seconds: 5)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (find.byType(LinearProgressIndicator).evaluate().isEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Account action did not settle');
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.runAsync(_eventTurn);
}

/// Real Supabase/Auth/Functions clients on a MockClient; no provider traffic.
/// Session setup follows frozen Core account_lifecycle_race_test.dart.
class _AccountFixture {
  _AccountFixture({this.holdRemote = false, this.holdCleanup = false}) {
    client = SupabaseClient(
      'https://motion.example.invalid',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(_request),
    );
    account = MotionAccountClient(
      supabase: client,
      app: MotionApp.jablab,
      emailRedirectTo: 'com.yulalab.jablab://auth/callback',
    );
  }

  final bool holdRemote;
  final bool holdCleanup;
  final owners = OwnerResourceRegistry()
    ..activate(_alice)
    ..activate(_bob);
  final directory = Directory.systemTemp.createTempSync('jablab-account-page-');
  final deleteEntered = Completer<void>();
  final cleanupEntered = Completer<void>();
  final cleanupAdmitted = Completer<void>();
  final cleanupFinished = Completer<void>();
  final _remote = Completer<http.Response>();
  final _cleanup = Completer<void>();
  late final SupabaseClient client;
  late final MotionAccountClient account;
  final page = ValueNotifier<Widget>(const SizedBox.shrink());
  String _nextUser = _alice;
  String _nextToken = 'alice-session';
  Completer<void>? userReadHold;
  Completer<void>? userReadStarted;
  int deleteRequests = 0;
  int membershipChecks = 0;
  int logoutRequests = 0;
  int passwordUpdates = 0;
  int cleanupCalls = 0;
  String? authorization;
  Map<String, dynamic>? deleteBody;

  Future<void> prepare() async {
    for (final owner in [_alice, _bob, null]) {
      for (final file in accountFiles(owner)) {
        await file.writeAsString('preserve:${file.uri.pathSegments.last}');
      }
    }
    await client.auth.setInitialSession(
      jsonEncode(_session(_alice, 'alice-session')),
    );
    await _eventTurn();
  }

  Future<void> signIn(String owner, String token) async {
    _nextUser = owner;
    _nextToken = token;
    await account.signIn(
      email: 'member@example.invalid',
      password: 'test-only',
    );
    await _eventTurn();
  }

  Future<void> refreshToken(String token) async {
    _nextUser = _alice;
    _nextToken = token;
    await client.auth.refreshSession('fixture-refresh-token');
    await _eventTurn();
  }

  Future<http.Response> _request(http.Request request) async {
    if (request.url.path.endsWith('/motion-delete-account')) {
      deleteRequests++;
      authorization = request.headers['Authorization'];
      deleteBody = jsonDecode(request.body) as Map<String, dynamic>;
      if (!deleteEntered.isCompleted) deleteEntered.complete();
      return holdRemote
          ? _remote.future
          : _json({'deleted': true, 'userId': _alice});
    }
    if (request.url.path.endsWith('/token')) {
      return _json(_session(_nextUser, _nextToken));
    }
    if (request.url.path.endsWith('/logout')) {
      logoutRequests++;
      return _json({});
    }
    if (request.url.path.endsWith('/user')) {
      if (request.method == 'PUT') passwordUpdates++;
      if (request.method == 'GET' && userReadHold != null) {
        if (userReadStarted?.isCompleted == false) userReadStarted!.complete();
        await userReadHold!.future;
      }
      return _json(_user(client.auth.currentUser?.id ?? _alice));
    }
    if (request.url.path.endsWith('/motion_profiles')) {
      return _json({'display_name': 'Test member'});
    }
    if (request.url.path.endsWith('/motion-check-membership')) {
      membershipChecks++;
      return _json({'active': false, 'anyActive': false});
    }
    throw StateError(
      'Unexpected mocked request ${request.method} ${request.url.path}',
    );
  }

  Future<void> clear(String id) async {
    cleanupCalls++;
    final cleanup = clearLocalHistoryFor(
      id,
      ownerRegistry: owners,
      supportDirectoryProvider: () async {
        if (!cleanupEntered.isCompleted) cleanupEntered.complete();
        if (holdCleanup) await _cleanup.future;
        return directory;
      },
    );
    if (!cleanupAdmitted.isCompleted) cleanupAdmitted.complete();
    await cleanup;
    if (!cleanupFinished.isCompleted) cleanupFinished.complete();
  }

  void releaseRemote() {
    if (!_remote.isCompleted) {
      _remote.complete(_json({'deleted': true, 'userId': _alice}));
    }
  }

  void releaseCleanup() {
    if (!_cleanup.isCompleted) _cleanup.complete();
  }

  List<File> accountFiles(String? id) {
    final history = sessionFileFor(directory, id);
    final course = courseFileFor(directory, id);
    return [
      history,
      File('${history.path}.tmp'),
      course,
      File('${course.path}.tmp'),
    ];
  }

  Map<String, String> snapshot({String? exclude}) => {
    for (final owner in [_alice, _bob, null])
      if (exclude == null || owner != exclude)
        for (final file in accountFiles(owner))
          if (file.existsSync())
            file.uri.pathSegments.last: file.readAsStringSync(),
  };

  Future<void> close() async {
    releaseRemote();
    releaseCleanup();
    await owners.retireAll();
    await client.dispose();
    await directory.delete(recursive: true);
    page.dispose();
  }
}

/// Test-only public MotionAccountClient.authChanges seam. Real public GoTrue
/// signIn/refresh/recovery states are relayed unchanged; policy/error injections
/// never call SDK @internal notify methods or replace its current Session.
/// The controlled seam replays one latest value/error to exercise host filtering.
class _HostAuthAccount extends MotionAccountClient {
  _HostAuthAccount(SupabaseClient client)
    : super(
        supabase: client,
        app: MotionApp.jablab,
        emailRedirectTo: 'com.yulalab.jablab://auth/callback',
      ) {
    _latestState = AuthState(
      AuthChangeEvent.initialSession,
      client.auth.currentSession,
    );
    _source = client.auth.onAuthStateChange.listen(
      _emit,
      onError: (Object error, StackTrace _) => emitError(error),
    );
  }

  final _events = StreamController<AuthState>.broadcast();
  late final StreamSubscription<AuthState> _source;
  AuthState? _latestState;
  Object? _latestError;

  @override
  Stream<AuthState> get authChanges => Stream<AuthState>.multi((out) {
    if (_latestError != null) {
      out.addError(_latestError!);
    } else if (_latestState != null) {
      out.add(_latestState!);
    }
    final listener = _events.stream.listen(
      out.addSync,
      onError: out.addErrorSync,
      onDone: out.closeSync,
    );
    out.onCancel = listener.cancel;
  }, isBroadcast: true);

  void _emit(AuthState state) {
    _latestState = state;
    _latestError = null;
    _events.add(state);
  }

  void emitSignedIn() =>
      _emit(AuthState(AuthChangeEvent.signedIn, supabase.auth.currentSession));

  void emitError(Object error) {
    _latestState = null;
    _latestError = error;
    _events.addError(error);
  }

  Future<void> close() async {
    await _source.cancel();
    await _events.close();
  }
}

/// Holds only the initial auth replay. Core deletion still uses the actual
/// Supabase/Functions client, so the opening session boundary is independent.
class _ReplayGateAccount extends MotionAccountClient {
  _ReplayGateAccount(SupabaseClient client)
    : super(
        supabase: client,
        app: MotionApp.jablab,
        emailRedirectTo: 'com.yulalab.jablab://auth/callback',
      );
  int activeListeners = 0;
  late final _events = StreamController<AuthState>.broadcast(
    sync: true,
    onListen: () => activeListeners++,
    onCancel: () => activeListeners--,
  );
  @override
  Stream<AuthState> get authChanges => _events.stream;
  void releaseReplay(AuthState state) => _events.add(state);
  Future<void> close() => _events.close();
}

Map<String, Object> _user(String id) => {
  'id': id,
  'aud': 'authenticated',
  'email': 'member@example.invalid',
  'created_at': '2026-09-24T00:00:00Z',
  'app_metadata': <String, Object>{},
};
Map<String, Object> _session(String id, String token) => {
  'access_token': token,
  'token_type': 'bearer',
  'refresh_token': 'fixture-refresh-token',
  'user': _user(id),
};
http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);
