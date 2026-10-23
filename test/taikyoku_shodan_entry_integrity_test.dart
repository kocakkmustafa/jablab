import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/karate_course_page.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/taikyoku_shodan_course.dart';
import 'package:jablab/app/taikyoku_shodan_course_page.dart';
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

Uint8List _tampered() {
  final bytes = File(ContentRepository.taikyokuCourseAsset).readAsBytesSync();
  final changed = Uint8List.fromList(bytes);
  changed[changed.length - 1] = bytes.last == 10 ? 32 : 10;
  return changed;
}

Future<void> _tap(WidgetTester t, String key) async {
  final target = find.byKey(Key(key));
  if (target.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      target,
      500,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 100,
    );
  }
  await Scrollable.ensureVisible(t.element(target), alignment: 0.5);
  await t.pumpAndSettle();
  await t.tap(target.hitTestable());
  await t.pump();
}

Future<void> _root(
  WidgetTester t,
  _History history, {
  ValueNotifier<String?>? owner,
  ValueNotifier<bool>? recovery,
  AssetBundle? bundle,
}) async {
  final directory = Directory.systemTemp.createTempSync('taikyoku-real-root-');
  addTearDown(() => directory.deleteSync(recursive: true));
  await t.runAsync(
    () => t.pumpWidget(
      JabLabApp(
        repository: ContentRepository(
          historyDirectoryOverride: directory,
          storeOverride: history,
          ownerRegistry: OwnerResourceRegistry(),
          contentBundleOverride: bundle,
        ),
        onboarding: const OnboardingStore(seenOverride: true),
        accountUserId: owner,
        accountRecovery: recovery,
      ),
    ),
  );
  await settleAppLoad(t);
}

Future<void> _karate(WidgetTester t) async {
  await _tap(t, 'open-karate-course');
  await settleUntil(t, find.byKey(const Key('karate-course-list')));
  expect(find.byKey(const Key('karate-course-list')), findsOneWidget);
}

Future<void> _kata(WidgetTester t) async {
  await _karate(t);
  await _tap(t, 'open-taikyoku-course');
  await settleUntil(t, find.byKey(const Key('taikyoku-course-list')));
  expect(find.byKey(const Key('taikyoku-course-list')), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'real bundled kata authenticates while original101 lessons and all five course pins remain exact',
    () async {
      const repository = ContentRepository();
      final kata = await repository.loadTaikyokuCourse();
      expect(kata.lessons, hasLength(10));
      expect(kata.movements, hasLength(20));
      expect(kata.physicalPracticeAvailable, isFalse);
      expect(
        computeSha256Hex(
          File(ContentRepository.taikyokuCourseAsset).readAsBytesSync(),
        ),
        TaikyokuCourse.reviewedAssetSha256,
      );
      final boxing = await repository.loadSoloBoxingCourse();
      final tai = await repository.loadTaiChiCourse();
      final kick = await repository.loadKickboxingCourse();
      final karate = await repository.loadKarateCourse();
      final muay = await repository.loadMuayThaiCourse();
      expect(
        [
          boxing.lessons.length,
          tai.lessons.length,
          kick.lessons.length,
          karate.lessons.length,
          muay.lessons.length,
        ],
        [39, 14, 16, 16, 16],
      );
      final pins = {
        ContentRepository.soloBoxingCourseAsset:
            '56773912d8917e3403fb1b2fe3755cf564b10e57e4ed35f24c1df6640b2594dd',
        ContentRepository.taiChiCourseAsset:
            '7aeac315bb2c6f4dc0ad6b6c21c43f04658dc3b45b263c1ce66767acec9309b8',
        ContentRepository.kickboxingCourseAsset:
            '4a4b69256a4c85b08e02d145b67475cb9c10405d8a827a25a50f678bf531bc3c',
        ContentRepository.karateCourseAsset:
            '8d1a488fad8c6b5039ffc9842698800b13a3446a7a1235742b97b2184cf913db',
        ContentRepository.muayThaiCourseAsset:
            'd17e9a6fe37d12ea20fda70da3dc02aa8b0fee74c0b357207f15eb2664c6cebc',
      };
      for (final entry in pins.entries) {
        expect(
          computeSha256Hex(File(entry.key).readAsBytesSync()),
          entry.value,
        );
      }
      expect(karate.physicalPracticeAvailable, isFalse);
      expect(karate.sequenceRows, hasLength(6));
    },
  );

  test('same-length tampering is rejected by the Core bundle gate', () async {
    final repository = ContentRepository(
      contentBundleOverride: _Overlay({
        ContentRepository.taikyokuCourseAsset: _tampered(),
      }),
    );
    await expectLater(
      repository.loadTaikyokuCourse(),
      throwsA(isA<ContentException>()),
    );
  });
  test(
    'rebuilt integrity metadata cannot replace reviewed kata teaching or readiness',
    () async {
      final asset =
          jsonDecode(
                File(ContentRepository.taikyokuCourseAsset).readAsStringSync(),
              )
              as Map<String, dynamic>;
      asset['content']['common_limits']['en'] =
          'Unreviewed replacement guidance';
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(asset)));
      final manifest =
          jsonDecode(
                File(
                  ContentRepository.taikyokuIntegrityManifestAsset,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final row = (manifest['assets'] as List).single as Map<String, dynamic>;
      row['byteLength'] = bytes.length;
      row['sha256'] = computeSha256Hex(bytes);
      manifest['catalogDigest'] = computeCatalogDigest(manifest);
      final repository = ContentRepository(
        contentBundleOverride: _Overlay({
          ContentRepository.taikyokuCourseAsset: bytes,
          ContentRepository.taikyokuIntegrityManifestAsset: Uint8List.fromList(
            utf8.encode(jsonEncode(manifest)),
          ),
        }),
      );
      await expectLater(
        repository.loadTaikyokuCourse(),
        throwsA(
          isA<ContentException>().having(
            (e) => e.error.code,
            'fixed reviewed asset pin',
            ContentErrorCode.hashMismatch,
          ),
        ),
      );
    },
  );

  for (final language in ['tr', 'en']) {
    for (final current in [false, true]) {
      testWidgets(
        'real ${current ? "current boxing" : "first-run"} Karate→named kata→back navigation $language preserves history',
        (t) async {
          t.platformDispatcher.localeTestValue = Locale(language);
          addTearDown(t.platformDispatcher.clearLocaleTestValue);
          final history = _History(current ? [_boxingRecord()] : []);
          await _root(t, history);
          expect(
            current ? find.byType(CoursePage) : find.byType(SelectPage),
            findsOneWidget,
          );
          await _kata(t);
          await _tap(t, 'taikyoku-lesson-1');
          await t.pumpAndSettle();
          expect(find.byType(TaikyokuLessonPage), findsOneWidget);
          expect(
            find.byKey(const Key('taikyoku-physical-blocked')),
            findsOneWidget,
          );
          await t.pageBack();
          await t.pumpAndSettle();
          expect(find.byKey(const Key('taikyoku-course-list')), findsOneWidget);
          await t.pageBack();
          await t.pumpAndSettle();
          expect(find.byKey(const Key('karate-course-list')), findsOneWidget);
          await t.pageBack();
          await t.pumpAndSettle();
          expect(
            current ? find.byType(CoursePage) : find.byType(SelectPage),
            findsOneWidget,
          );
          expect(history.records, hasLength(current ? 1 : 0));
          expect(history.appends, 0);
          expect(t.takeException(), isNull);
        },
      );
    }
  }

  for (final interruption in ['owner', 'recovery']) {
    for (final lessonOpen in [false, true]) {
      testWidgets(
        'real root $interruption retires named kata ${lessonOpen ? "lesson" : "overview"} and Karate parent',
        (t) async {
          final owner = ValueNotifier<String?>(
            '11111111-1111-4111-8111-111111111111',
          );
          final recovery = ValueNotifier<bool>(false);
          addTearDown(owner.dispose);
          addTearDown(recovery.dispose);
          final history = _History([]);
          await _root(t, history, owner: owner, recovery: recovery);
          await _kata(t);
          if (lessonOpen) {
            await _tap(t, 'taikyoku-lesson-1');
            await t.pumpAndSettle();
          }
          if (interruption == 'owner') {
            owner.value = '22222222-2222-4222-8222-222222222222';
          } else {
            recovery.value = true;
          }
          await t.pump();
          await settleUntil(
            t,
            interruption == 'owner'
                ? find.byKey(const Key('open-karate-course'))
                : find.text('Account recovery is required.'),
          );
          await t.pumpAndSettle();
          expect(
            find.byType(TaikyokuCoursePage, skipOffstage: false),
            findsNothing,
          );
          expect(
            find.byType(TaikyokuLessonPage, skipOffstage: false),
            findsNothing,
          );
          expect(
            find.byType(KarateCoursePage, skipOffstage: false),
            findsNothing,
          );
          expect(history.appends, 0);
          expect(t.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'retained real Karate entry callback cannot open the kata after owner handoff',
    (t) async {
      final owner = ValueNotifier<String?>(
        '11111111-1111-4111-8111-111111111111',
      );
      addTearDown(owner.dispose);
      await _root(t, _History([]), owner: owner);
      await _karate(t);
      final stale = t
          .widget<TaikyokuCourseEntryCard>(find.byType(TaikyokuCourseEntryCard))
          .onOpen;
      owner.value = '22222222-2222-4222-8222-222222222222';
      stale();
      await t.pump();
      await settleUntil(t, find.byKey(const Key('open-karate-course')));
      stale();
      await t.pumpAndSettle();
      expect(
        find.byType(TaikyokuCoursePage, skipOffstage: false),
        findsNothing,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed actual asset blocks kata entry content while Karate and original history remain usable',
    (t) async {
      final history = _History([]);
      await _root(
        t,
        history,
        bundle: _Overlay({ContentRepository.taikyokuCourseAsset: _tampered()}),
      );
      await _karate(t);
      await _tap(t, 'open-taikyoku-course');
      await settleUntil(t, find.byKey(const Key('taikyoku-load-failure')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('taikyoku-course-list')), findsNothing);
      expect(find.byKey(const Key('taikyoku-written-progress')), findsNothing);
      expect(find.byKey(const Key('taikyoku-retry')), findsNothing);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('karate-course-list')), findsOneWidget);
      expect(history.appends, 0);
      expect(t.takeException(), isNull);
    },
  );
}

SessionRecord _boxingRecord() => SessionRecord(
  lessonId: 'boxing.foundations.jab',
  completedAt: DateTime.utc(2026, 8, 1),
  workedSeconds: 30,
  unitsCompleted: 1,
  plannedUnits: 2,
  unitLabel: 'round',
  lessonClass: 'unscored',
);

class _History implements SessionStore {
  _History(this.records);
  final List<SessionRecord> records;
  int appends = 0;
  @override
  Future<void> append(SessionRecord record) async {
    appends++;
    records.add(record);
  }

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => records;
  @override
  Future<int> unreadableRecords() async => 0;
  @override
  Future<int> workedSecondsFor(String lessonId) async => records
      .where((r) => r.lessonId == lessonId)
      .fold<int>(0, (sum, r) => sum + r.workedSeconds);
}
