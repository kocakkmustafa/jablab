import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/account_bridge.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/settings_page.dart';

import 'app_pump.dart';

void main() {
  const String alice = '11111111-1111-4111-8111-111111111111';
  const String bob = '22222222-2222-4222-8222-222222222222';
  late Directory tmp;
  late OwnerResourceRegistry owners;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('jablab-account-');
    owners = OwnerResourceRegistry();
    owners.activate(alice);
    owners.activate(bob);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('app id and filenames separate guest and account journals', () {
    expect(motionAppId, 'jablab');
    expect(sessionFileNameFor(null), 'sessions.jsonl');
    expect(sessionFileNameFor(alice), 'sessions-jablab-$alice.jsonl');
    expect(sessionFileNameFor(bob), isNot(sessionFileNameFor(alice)));
    expect(() => sessionFileNameFor('../guest'), throwsArgumentError);
  });

  test('receipt scan returns only canonical app-owned regular files', () async {
    final File aliceFile = sessionFileFor(tmp, alice);
    await aliceFile.writeAsString('record');
    await File('${aliceFile.path}.tmp').writeAsString('unfinished');
    await File('${tmp.path}/sessions.jsonl').writeAsString('guest');
    await File(
      '${tmp.path}/sessions-choreia-$bob.jsonl',
    ).writeAsString('other');
    await File(
      '${tmp.path}/sessions-jablab-invalid.jsonl',
    ).writeAsString('bad');
    await Directory('${tmp.path}/sessions-jablab-$bob.jsonl').create();
    await Link(
      '${tmp.path}/sessions-jablab-33333333-3333-4333-8333-333333333333.jsonl',
    ).create(aliceFile.path);

    expect(await localHistoryAccountIds(supportDirectory: tmp), <String>[
      alice,
    ]);
    expect(
      await localHistoryAccountIds(
        supportDirectory: Directory('${tmp.path}/missing'),
      ),
      isEmpty,
    );
  });

  test(
    'tmp-only crash residue is reconciled without touching other paths',
    () async {
      final File bobTmp = File('${sessionFileFor(tmp, bob).path}.tmp');
      await bobTmp.writeAsString('unfinished');
      final File guestTmp = File('${tmp.path}/sessions.jsonl.tmp');
      await guestTmp.writeAsString('guest');
      final File otherAppTmp = File(
        '${tmp.path}/sessions-choreia-$alice.jsonl.tmp',
      );
      await otherAppTmp.writeAsString('other');
      final File target = File('${tmp.path}/unrelated-data');
      await target.writeAsString('keep');
      final Link symlink = Link('${sessionFileFor(tmp, alice).path}.tmp');
      await symlink.create(target.path);

      expect(await localHistoryAccountIds(supportDirectory: tmp), <String>[
        bob,
      ]);
      await clearLocalHistoryFor(
        bob,
        supportDirectory: tmp,
        ownerRegistry: owners,
      );
      await clearLocalHistoryFor(
        alice,
        supportDirectory: tmp,
        ownerRegistry: owners,
      );
      expect(await bobTmp.exists(), isFalse);
      expect(await guestTmp.readAsString(), 'guest');
      expect(await otherAppTmp.readAsString(), 'other');
      expect(await target.readAsString(), 'keep');
      expect(await symlink.exists(), isTrue);
      expect(await localHistoryAccountIds(supportDirectory: tmp), isEmpty);
    },
  );

  test(
    'sign-in never imports guest history and account deletion is scoped',
    () async {
      final ContentRepository repository = ContentRepository(
        historyDirectoryOverride: tmp,
        ownerRegistry: owners,
      );
      final SessionStore guest = await repository.openStore();
      await guest.append(
        SessionRecord(
          lessonId: 'guest-lesson',
          completedAt: DateTime.utc(2026, 9, 24),
          workedSeconds: 30,
          unitsCompleted: 1,
          plannedUnits: 1,
          unitLabel: 'round',
          lessonClass: 'unscored',
        ),
      );

      final SessionStore signed = await repository.openStore(
        accountUserId: alice,
      );
      expect(await signed.recent(), isEmpty);
      await signed.append(
        SessionRecord(
          lessonId: 'alice-lesson',
          completedAt: DateTime.utc(2026, 9, 24, 1),
          workedSeconds: 40,
          unitsCompleted: 2,
          plannedUnits: 2,
          unitLabel: 'round',
          lessonClass: 'unscored',
        ),
      );
      expect(
        await (await repository.openStore(accountUserId: bob)).recent(),
        isEmpty,
      );
      expect(
        (await (await repository.openStore()).recent()).single.lessonId,
        'guest-lesson',
      );

      final File accountTmp = File('${sessionFileFor(tmp, alice).path}.tmp');
      await accountTmp.writeAsString('interrupted write');
      await clearLocalHistoryFor(
        alice,
        supportDirectory: tmp,
        ownerRegistry: owners,
      );
      await clearLocalHistoryFor(
        alice,
        supportDirectory: tmp,
        ownerRegistry: owners,
      );
      expect(await accountTmp.exists(), isFalse);
      await expectLater(
        repository.openStore(accountUserId: alice),
        throwsStateError,
      );
      // This simulates a new explicit verified admission; open itself cannot
      // silently recreate the erased owner's retired epoch.
      owners.activate(alice);
      expect(
        await (await repository.openStore(accountUserId: alice)).recent(),
        isEmpty,
      );
      expect(
        (await (await repository.openStore()).recent()).single.lessonId,
        'guest-lesson',
      );
    },
  );

  testWidgets('settings opens only an injected account page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          onOpenWhyNot: () {},
          excludedCount: 1,
          accountPageBuilder: (_) =>
              const Scaffold(body: Center(child: Text('Real account page'))),
        ),
      ),
    );
    expect(find.byKey(const Key('account-not-connected')), findsNothing);
    await tester.tap(find.byKey(SettingsPage.accountEntryKey));
    await tester.pumpAndSettle();
    expect(find.text('Real account page'), findsOneWidget);
  });

  testWidgets('account switch hides the previous local course immediately', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<String?> account = ValueNotifier<String?>(null);
    addTearDown(account.dispose);
    final ContentRepository repository = ContentRepository(
      historyDirectoryOverride: tmp,
      ownerRegistry: owners,
    );
    await tester.runAsync(() async {
      await (await repository.openStore()).append(
        SessionRecord(
          lessonId: 'boxing.foundations.jab',
          completedAt: DateTime.utc(2026, 9, 24),
          workedSeconds: 30,
          unitsCompleted: 1,
          plannedUnits: 1,
          unitLabel: 'round',
          lessonClass: 'unscored',
        ),
      );
    });
    await tester.runAsync(() async {
      await tester.pumpWidget(
        JabLabApp(
          repository: repository,
          onboarding: const OnboardingStore(seenOverride: true),
          accountUserId: account,
        ),
      );
    });
    await settleAppLoad(tester);
    await settleUntil(tester, find.byType(CoursePage));
    expect(find.byType(CoursePage), findsOneWidget);

    account.value = alice;
    await tester.pump();
    expect(find.byType(CoursePage), findsNothing);
    await settleUntil(tester, find.byType(SelectPage));
    expect(find.byType(SelectPage), findsOneWidget);

    account.value = null;
    await settleUntil(tester, find.byType(CoursePage));
    expect(find.byType(CoursePage), findsOneWidget);
  });
}
