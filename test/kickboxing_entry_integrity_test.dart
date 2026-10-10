import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/kickboxing_course_page.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/kickboxing_course.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Kickboxing authenticated bundle loads and boxing remains intact',
    () async {
      const repository = ContentRepository();
      final kickboxing = await repository.loadKickboxingCourse();
      expect(kickboxing.lessons, hasLength(16));
      expect(
        computeSha256Hex(
          File(ContentRepository.kickboxingCourseAsset).readAsBytesSync(),
        ),
        KickboxingCourse.reviewedAssetSha256,
      );
      final taiChi = await repository.loadTaiChiCourse();
      expect(taiChi.lessons, hasLength(14));
      final boxing = await repository.loadSoloBoxingCourse();
      expect(boxing.lessons, hasLength(39));
      expect(
        computeSha256Hex(
          File(ContentRepository.soloBoxingCourseAsset).readAsBytesSync(),
        ),
        '0909b6c991fb631faeb357026475f787ae226562e261a479e0eb315095de069f',
      );
    },
  );

  test(
    'same-length Kickboxing tampering is rejected by Core integrity gate',
    () async {
      final bytes = File(ContentRepository.kickboxingCourseAsset)
          .readAsBytesSync();
      final changed = Uint8List.fromList(bytes);
      changed[changed.length - 1] = bytes.last == 10 ? 32 : 10;
      final repository = ContentRepository(
        contentBundleOverride: _Overlay({
          ContentRepository.kickboxingCourseAsset: changed,
        }),
      );
      await expectLater(
        repository.loadKickboxingCourse(),
        throwsA(isA<ContentException>()),
      );
    },
  );

  test(
    'a rebuilt manifest cannot replace the fixed reviewed Kickboxing asset',
    () async {
      final json = jsonDecode(
        File(ContentRepository.kickboxingCourseAsset).readAsStringSync(),
      ) as Map<String, dynamic>;
      // Structurally valid text replacement plus matching integrity metadata
      // must still fail the reviewed-content binding.
      json['safety']['en'] = 'Changed safety guidance';
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));
      final manifest = jsonDecode(
        File(ContentRepository.kickboxingIntegrityManifestAsset)
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final asset = (manifest['assets'] as List).single as Map<String, dynamic>;
      asset['byteLength'] = bytes.length;
      asset['sha256'] = computeSha256Hex(bytes);
      manifest['catalogDigest'] = computeCatalogDigest(manifest);
      final repository = ContentRepository(
        contentBundleOverride: _Overlay({
          ContentRepository.kickboxingCourseAsset: bytes,
          ContentRepository.kickboxingIntegrityManifestAsset:
              Uint8List.fromList(utf8.encode(jsonEncode(manifest))),
        }),
      );
      await expectLater(
        repository.loadKickboxingCourse(),
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
        'real root $interruption retires Kickboxing ${lessonOpen ? "lesson" : "overview"}',
        (tester) async {
          final directory = Directory.systemTemp.createTempSync(
            'kickboxing-root-interrupt-',
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
          final entry = find.byKey(const Key('open-kickboxing-course'));
          await settleUntil(tester, entry);
          await Scrollable.ensureVisible(tester.element(entry));
          await tester.pumpAndSettle();
          await tester.tap(entry.hitTestable());
          await settleUntil(
            tester,
            find.byKey(const Key('kickboxing-course-list')),
          );
          if (lessonOpen) {
            final lesson = find.byKey(const Key('kickboxing-lesson-1'));
            await tester.scrollUntilVisible(
              lesson,
              250,
              scrollable: find
                  .descendant(
                    of: find.byKey(const Key('kickboxing-course-list')),
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
              find.byKey(const Key('kickboxing-course-list')),
              findsNothing,
            );
            final answer = find.byKey(const Key('kickboxing-own-answer'));
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
            final reveal = find.byKey(const Key('kickboxing-reveal-answer'));
            await Scrollable.ensureVisible(tester.element(reveal));
            await tester.pumpAndSettle();
            await tester.tap(reveal.hitTestable());
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.byKey(const Key('kickboxing-answer')),
              300,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.byKey(const Key('kickboxing-answer')), findsOneWidget);
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
                ? find.byKey(const Key('open-kickboxing-course'))
                : find.text('Account recovery is required.'),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(KickboxingCoursePage, skipOffstage: false),
            findsNothing,
          );
          expect(
            find.byKey(
              const Key('kickboxing-reveal-answer'),
              skipOffstage: false,
            ),
            findsNothing,
          );
          expect(
            find.byKey(const Key('kickboxing-own-answer'), skipOffstage: false),
            findsNothing,
          );
          expect(
            find.byKey(const Key('kickboxing-answer'), skipOffstage: false),
            findsNothing,
          );
          if (interruption == 'recovery') {
            expect(find.text('Account recovery is required.'), findsOneWidget);
          } else {
            await settleUntil(
              tester,
              find.byKey(const Key('open-kickboxing-course')),
            );
            expect(
              find.byKey(const Key('open-kickboxing-course')),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final language in ['en', 'tr']) {
    for (final hasCurrentBoxing in [false, true]) {
      testWidgets(
        'real ${hasCurrentBoxing ? "current boxing" : "first-run"} entry opens Kickboxing and returns $language',
        (tester) async {
          tester.binding.platformDispatcher.localeTestValue = Locale(language);
          addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
          final directory = Directory.systemTemp.createTempSync(
            'kickboxing-entry-',
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
          final entry = find.byKey(const Key('open-kickboxing-course'));
          await settleUntil(tester, entry);
          await Scrollable.ensureVisible(tester.element(entry));
          await tester.pumpAndSettle();
          await tester.tap(entry);
          await settleUntil(
            tester,
            find.byKey(const Key('kickboxing-course-list')),
          );
          expect(
            find.byKey(const Key('kickboxing-course-list')),
            findsOneWidget,
          );
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('open-solo-boxing-course')),
            findsOneWidget,
          );
          expect(
            store.all.length,
            hasCurrentBoxing ? 1 : 0,
            reason: 'Opening/reading Kickboxing must not write boxing history',
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
