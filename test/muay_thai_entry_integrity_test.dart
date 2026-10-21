import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/muay_thai_course_page.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/muay_thai_course.dart';
import 'package:motion_content/motion_content.dart';

import 'app_pump.dart';

class _Overlay extends CachingAssetBundle {
  _Overlay(this.overrides);
  final Map<String, Uint8List> overrides;
  @override
  Future<ByteData> load(String key) async {
    final bytes = overrides[key];
    return bytes == null ? rootBundle.load(key) : ByteData.sublistView(bytes);
  }
}

// Reach the real lazy list control before using its element or tapping it.
Future<void> showRootEntry(WidgetTester tester) async {
  final scroll = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scroll).position.jumpTo(0);
  await tester.pump();
  final entry = find.byKey(const Key('open-muay-thai-course'));
  await tester.scrollUntilVisible(
    entry,
    300,
    scrollable: scroll,
    maxScrolls: 100,
  );
  await Scrollable.ensureVisible(tester.element(entry), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'MuayThai authenticated bundle loads and boxing remains intact',
    () async {
      const repository = ContentRepository();
      final muayThai = await repository.loadMuayThaiCourse();
      expect(muayThai.lessons, hasLength(16));
      expect(
        computeSha256Hex(
          File(ContentRepository.muayThaiCourseAsset).readAsBytesSync(),
        ),
        MuayThaiCourse.reviewedAssetSha256,
      );
      final karate = await repository.loadKarateCourse();
      expect(karate.lessons, hasLength(16));
      expect(
        computeSha256Hex(
          File(ContentRepository.karateCourseAsset).readAsBytesSync(),
        ),
        '8d1a488fad8c6b5039ffc9842698800b13a3446a7a1235742b97b2184cf913db',
      );
      final kickboxing = await repository.loadKickboxingCourse();
      expect(kickboxing.lessons, hasLength(16));
      expect(
        computeSha256Hex(
          File(ContentRepository.kickboxingCourseAsset).readAsBytesSync(),
        ),
        '33a908eadfac286345ca0cba189ff786afc31d018980956d19fcdb02fb238047',
      );
      final taiChi = await repository.loadTaiChiCourse();
      expect(taiChi.lessons, hasLength(14));
      final boxing = await repository.loadSoloBoxingCourse();
      expect(boxing.lessons, hasLength(39));
      expect(
        computeSha256Hex(
          File(ContentRepository.soloBoxingCourseAsset).readAsBytesSync(),
        ),
        '56773912d8917e3403fb1b2fe3755cf564b10e57e4ed35f24c1df6640b2594dd',
      );
    },
  );

  test(
    'same-length MuayThai tampering is rejected by Core integrity gate',
    () async {
      final bytes = File(
        ContentRepository.muayThaiCourseAsset,
      ).readAsBytesSync();
      final changed = Uint8List.fromList(bytes);
      changed[changed.length - 1] = bytes.last == 10 ? 32 : 10;
      final repository = ContentRepository(
        contentBundleOverride: _Overlay({
          ContentRepository.muayThaiCourseAsset: changed,
        }),
      );
      await expectLater(
        repository.loadMuayThaiCourse(),
        throwsA(isA<ContentException>()),
      );
    },
  );

  test(
    'a rebuilt manifest cannot replace the fixed reviewed MuayThai asset',
    () async {
      final json =
          jsonDecode(
                File(ContentRepository.muayThaiCourseAsset).readAsStringSync(),
              )
              as Map<String, dynamic>;
      // Structurally valid text replacement plus matching integrity metadata
      // must still fail the reviewed-content binding.
      json['shared']['stop']['en'] = 'Changed safety guidance';
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));
      final manifest =
          jsonDecode(
                File(
                  ContentRepository.muayThaiIntegrityManifestAsset,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final asset = (manifest['assets'] as List).single as Map<String, dynamic>;
      asset['byteLength'] = bytes.length;
      asset['sha256'] = computeSha256Hex(bytes);
      manifest['catalogDigest'] = computeCatalogDigest(manifest);
      final repository = ContentRepository(
        contentBundleOverride: _Overlay({
          ContentRepository.muayThaiCourseAsset: bytes,
          ContentRepository.muayThaiIntegrityManifestAsset: Uint8List.fromList(
            utf8.encode(jsonEncode(manifest)),
          ),
        }),
      );
      await expectLater(
        repository.loadMuayThaiCourse(),
        throwsA(
          isA<ContentException>().having(
            (e) => e.error.code,
            'fixed reviewed content binding',
            ContentErrorCode.hashMismatch,
          ),
        ),
      );
    },
  );

  for (final interruption in ['owner', 'recovery']) {
    for (final lessonOpen in [false, true]) {
      testWidgets(
        'real root $interruption retires MuayThai ${lessonOpen ? "lesson" : "overview"}',
        (tester) async {
          final directory = Directory.systemTemp.createTempSync(
            'muay-thai-root-interrupt-',
          );
          addTearDown(() => directory.deleteSync(recursive: true));
          final owner = ValueNotifier<String?>(
            '11111111-1111-4111-8111-111111111111',
          );
          final recovery = ValueNotifier<bool>(false);
          addTearDown(owner.dispose);
          addTearDown(recovery.dispose);
          await tester.runAsync(
            () => tester.pumpWidget(
              JabLabApp(
                repository: ContentRepository(
                  historyDirectoryOverride: directory,
                  ownerRegistry: OwnerResourceRegistry(),
                ),
                onboarding: const OnboardingStore(seenOverride: true),
                accountUserId: owner,
                accountRecovery: recovery,
              ),
            ),
          );
          await settleAppLoad(tester);
          final entry = find.byKey(const Key('open-muay-thai-course'));
          await showRootEntry(tester);
          await Scrollable.ensureVisible(tester.element(entry));
          await tester.pumpAndSettle();
          await tester.tap(entry.hitTestable());
          await settleUntil(
            tester,
            find.byKey(const Key('muay-thai-course-list')),
          );
          if (lessonOpen) {
            final lesson = find.byKey(const Key('muay-thai-lesson-1'));
            await tester.scrollUntilVisible(
              lesson,
              250,
              scrollable: find
                  .descendant(
                    of: find.byKey(const Key('muay-thai-course-list')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await Scrollable.ensureVisible(
              tester.element(lesson),
              alignment: 0.5,
            );
            await tester.pumpAndSettle();
            await tester.tap(lesson.hitTestable());
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('muay-thai-course-list')),
              findsNothing,
            );
            final answer = find.byKey(const Key('muay-thai-own-answer'));
            await tester.scrollUntilVisible(
              answer,
              500,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 100,
            );
            await tester.enterText(
              answer,
              'Unsaved owner-specific written account',
            );
            tester.testTextInput.hide();
            await tester.pumpAndSettle();
            final reveal = find.byKey(const Key('muay-thai-reveal-answer'));
            await Scrollable.ensureVisible(tester.element(reveal));
            await tester.pumpAndSettle();
            await tester.tap(reveal.hitTestable());
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.byKey(const Key('muay-thai-answer')),
              300,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.byKey(const Key('muay-thai-answer')), findsOneWidget);
          }
          if (interruption == 'owner') {
            owner.value = '22222222-2222-4222-8222-222222222222';
          } else {
            recovery.value = true;
          }
          await tester.pump();
          await settleUntil(
            tester,
            interruption == 'owner'
                ? find.byType(SelectPage)
                : find.text('Account recovery is required.'),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(MuayThaiCoursePage, skipOffstage: false),
            findsNothing,
          );
          expect(
            find.byKey(
              const Key('muay-thai-reveal-answer'),
              skipOffstage: false,
            ),
            findsNothing,
          );
          expect(
            find.byKey(const Key('muay-thai-own-answer'), skipOffstage: false),
            findsNothing,
          );
          expect(
            find.byKey(const Key('muay-thai-answer'), skipOffstage: false),
            findsNothing,
          );
          if (interruption == 'recovery') {
            expect(find.text('Account recovery is required.'), findsOneWidget);
          } else {
            await showRootEntry(tester);
            expect(
              find.byKey(const Key('open-muay-thai-course')),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final interruption in ['owner', 'recovery']) {
    testWidgets(
      'root admission retires a queued Muay Thai route before its builder ($interruption)',
      (tester) async {
        final directory = Directory.systemTemp.createTempSync(
          'muay-thai-queued-root-',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final owner = ValueNotifier<String?>(
          '11111111-1111-4111-8111-111111111111',
        );
        final recovery = ValueNotifier<bool>(false);
        addTearDown(owner.dispose);
        addTearDown(recovery.dispose);
        await tester.runAsync(
          () => tester.pumpWidget(
            JabLabApp(
              repository: ContentRepository(
                historyDirectoryOverride: directory,
                ownerRegistry: OwnerResourceRegistry(),
              ),
              onboarding: const OnboardingStore(seenOverride: true),
              accountUserId: owner,
              accountRecovery: recovery,
            ),
          ),
        );
        await settleAppLoad(tester);
        await showRootEntry(tester);
        // Dispatch the actual root handler and interrupt before the next frame.
        // This covers root admission before route construction, separately from
        // the lesson didPush and after-transition retirement cases.
        tester
            .widget<SelectPage>(find.byType(SelectPage))
            .onOpenMuayThaiCourse!();
        if (interruption == 'owner') {
          owner.value = '22222222-2222-4222-8222-222222222222';
        } else {
          recovery.value = true;
        }
        await tester.pump();
        await settleUntil(
          tester,
          interruption == 'owner'
              ? find.byType(SelectPage)
              : find.text('Account recovery is required.'),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(MuayThaiCoursePage, skipOffstage: false),
          findsNothing,
        );
        expect(
          find.byKey(const Key('muay-thai-course-list'), skipOffstage: false),
          findsNothing,
        );
        expect(
          find.byKey(const Key('muay-thai-own-answer'), skipOffstage: false),
          findsNothing,
        );
        if (interruption == 'owner') {
          await showRootEntry(tester);
          expect(
            find.byKey(const Key('open-muay-thai-course')).hitTestable(),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final language in ['en', 'tr']) {
    for (final hasCurrentBoxing in [false, true]) {
      testWidgets(
        'real ${hasCurrentBoxing ? "current boxing" : "first-run"} entry opens MuayThai and returns $language',
        (tester) async {
          tester.binding.platformDispatcher.localeTestValue = Locale(language);
          addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
          final directory = Directory.systemTemp.createTempSync(
            'muay-thai-entry-',
          );
          addTearDown(() => directory.deleteSync(recursive: true));
          final store = _History(
            hasCurrentBoxing
                ? [
                    SessionRecord(
                      lessonId: 'boxing.foundations.jab',
                      completedAt: DateTime.utc(2026, 8, 1),
                      workedSeconds: 30,
                      unitsCompleted: 1,
                      plannedUnits: 2,
                      unitLabel: 'round',
                      lessonClass: 'unscored',
                    ),
                  ]
                : [],
          );
          final historyBefore = jsonEncode([
            for (final record in store.all) record.toJson(),
          ]);
          final originalRecords = List<SessionRecord>.of(store.all);
          await tester.runAsync(
            () => tester.pumpWidget(
              JabLabApp(
                repository: ContentRepository(
                  historyDirectoryOverride: directory,
                  ownerRegistry: OwnerResourceRegistry(),
                  storeOverride: store,
                ),
                onboarding: const OnboardingStore(seenOverride: true),
              ),
            ),
          );
          await settleAppLoad(tester);
          expect(
            hasCurrentBoxing
                ? find.byType(CoursePage)
                : find.byType(SelectPage),
            findsOneWidget,
          );
          final entry = find.byKey(const Key('open-muay-thai-course'));
          await showRootEntry(tester);
          await Scrollable.ensureVisible(tester.element(entry));
          await tester.pumpAndSettle();
          await tester.tap(entry);
          await settleUntil(
            tester,
            find.byKey(const Key('muay-thai-course-list')),
          );
          expect(
            find.byKey(const Key('muay-thai-course-list')),
            findsOneWidget,
          );
          await tester.pageBack();
          await tester.pumpAndSettle();
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('open-solo-boxing-course')),
            findsOneWidget,
          );
          expect(
            store.all.length,
            hasCurrentBoxing ? 1 : 0,
            reason: 'Opening/reading MuayThai must not write boxing history',
          );
          expect(store.all, orderedEquals(originalRecords));
          expect(
            jsonEncode([for (final record in store.all) record.toJson()]),
            historyBefore,
            reason:
                'Every serialized field of supplied boxing history remains exact',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _History implements SessionStore {
  _History(this.all);
  final List<SessionRecord> all;
  @override
  Future<void> append(SessionRecord record) async => all.add(record);
  @override
  Future<List<SessionRecord>> recent({int? limit}) async => all;
  @override
  Future<int> unreadableRecords() async => 0;
  @override
  Future<int> workedSecondsFor(String lessonId) async => all
      .where((r) => r.lessonId == lessonId)
      .fold<int>(0, (sum, r) => sum + r.workedSeconds);
}
