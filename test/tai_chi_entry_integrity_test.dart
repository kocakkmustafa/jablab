import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/tai_chi_course_page.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
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
    'Tai Chi authenticated bundle loads and boxing remains intact',
    () async {
      const repository = ContentRepository();
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
    'same-length Tai Chi tampering is rejected by Core integrity gate',
    () async {
      final bytes = File(ContentRepository.taiChiCourseAsset).readAsBytesSync();
      final changed = Uint8List.fromList(bytes);
      changed[changed.length - 1] = bytes.last == 10 ? 32 : 10;
      final repository = ContentRepository(
        contentBundleOverride: _Overlay({
          ContentRepository.taiChiCourseAsset: changed,
        }),
      );
      await expectLater(
        repository.loadTaiChiCourse(),
        throwsA(isA<ContentException>()),
      );
    },
  );

  test(
    'hash-matched unsupported Tai Chi identity is rejected by decoder',
    () async {
      final json =
          jsonDecode(
                File(ContentRepository.taiChiCourseAsset).readAsStringSync(),
              )
              as Map<String, dynamic>;
      json['id'] = 'untrusted';
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));
      final manifest =
          jsonDecode(
                File(
                  ContentRepository.taiChiIntegrityManifestAsset,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final asset = (manifest['assets'] as List).single as Map<String, dynamic>;
      asset['byteLength'] = bytes.length;
      asset['sha256'] = computeSha256Hex(bytes);
      manifest['catalogDigest'] = computeCatalogDigest(manifest);
      final repository = ContentRepository(
        contentBundleOverride: _Overlay({
          ContentRepository.taiChiCourseAsset: bytes,
          ContentRepository.taiChiIntegrityManifestAsset: Uint8List.fromList(
            utf8.encode(jsonEncode(manifest)),
          ),
        }),
      );
      await expectLater(
        repository.loadTaiChiCourse(),
        throwsA(isA<ContentException>()),
      );
    },
  );

  for (final interruption in ['owner', 'recovery']) {
    for (final lessonOpen in [false, true]) {
      testWidgets(
        'real root $interruption retires Tai Chi ${lessonOpen ? "lesson" : "overview"}',
        (tester) async {
          final directory = Directory.systemTemp.createTempSync(
            'tai-chi-root-interrupt-',
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
          final entry = find.byKey(const Key('open-tai-chi-course'));
          await settleUntil(tester, entry);
          await Scrollable.ensureVisible(tester.element(entry));
          await tester.pumpAndSettle();
          await tester.tap(entry.hitTestable());
          await settleUntil(
            tester,
            find.byKey(const Key('tai-chi-course-list')),
          );
          if (lessonOpen) {
            final lesson = find.byKey(const Key('tai-chi-lesson-1'));
            await tester.scrollUntilVisible(
              lesson,
              250,
              scrollable: find
                  .descendant(
                    of: find.byKey(const Key('tai-chi-course-list')),
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
            expect(find.byKey(const Key('tai-chi-course-list')), findsNothing);
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
                ? find.byKey(const Key('open-tai-chi-course'))
                : find.text('Account recovery is required.'),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(TaiChiCoursePage, skipOffstage: false),
            findsNothing,
          );
          expect(
            find.byKey(const Key('tai-chi-reveal-answer'), skipOffstage: false),
            findsNothing,
          );
          if (interruption == 'recovery') {
            expect(find.text('Account recovery is required.'), findsOneWidget);
          } else {
            await settleUntil(
              tester,
              find.byKey(const Key('open-tai-chi-course')),
            );
            expect(
              find.byKey(const Key('open-tai-chi-course')),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final language in ['en', 'tr']) {
    testWidgets(
      'real learning entry opens Tai Chi and returns to boxing $language',
      (tester) async {
        tester.binding.platformDispatcher.localeTestValue = Locale(language);
        addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
        final directory = Directory.systemTemp.createTempSync('tai-chi-entry-');
        addTearDown(() => directory.deleteSync(recursive: true));
        await tester.runAsync(
          () => tester.pumpWidget(
            JabLabApp(
              repository: ContentRepository(
                historyDirectoryOverride: directory,
                ownerRegistry: OwnerResourceRegistry(),
              ),
              onboarding: const OnboardingStore(seenOverride: true),
            ),
          ),
        );
        await settleAppLoad(tester);
        final entry = find.byKey(const Key('open-tai-chi-course'));
        await settleUntil(tester, entry);
        await Scrollable.ensureVisible(tester.element(entry));
        await tester.pumpAndSettle();
        await tester.tap(entry);
        await settleUntil(tester, find.byKey(const Key('tai-chi-course-list')));
        expect(find.byKey(const Key('tai-chi-course-list')), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('open-solo-boxing-course')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
