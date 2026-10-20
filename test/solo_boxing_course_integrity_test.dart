import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_failure.dart';
import 'package:jablab/app/content_failure_screen.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/solo_boxing_course_page.dart';
import 'package:motion_content/motion_content.dart';

import 'app_pump.dart';

const String _manifestPath = ContentRepository.soloBoxingIntegrityManifestAsset;
const String _coursePath = ContentRepository.soloBoxingCourseAsset;

final class _CourseAssetOverlayBundle extends CachingAssetBundle {
  _CourseAssetOverlayBundle({
    this.courseBytes,
    this.manifestBytes,
    this.missingManifest = false,
    this.missingCourse = false,
  });

  final Uint8List? courseBytes;
  final Uint8List? manifestBytes;
  final bool missingManifest;
  final bool missingCourse;
  final List<String> requestedPaths = <String>[];

  @override
  Future<ByteData> load(String key) {
    requestedPaths.add(key);
    if ((key == _manifestPath && missingManifest) ||
        (key == _coursePath && missingCourse)) {
      throw StateError('asset unavailable: $key');
    }
    if (key == _manifestPath && manifestBytes != null) {
      final Uint8List bytes = manifestBytes!;
      return Future<ByteData>.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      );
    }
    if (key == _coursePath && courseBytes != null) {
      final Uint8List bytes = courseBytes!;
      return Future<ByteData>.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      );
    }
    return rootBundle.load(key);
  }
}

Future<_CourseAssetOverlayBundle> _schemaInvalidButHashMatchedBundle({
  bool wrongFieldType = false,
}) async {
  final ByteData courseData = await rootBundle.load(_coursePath);
  final Map<String, dynamic> invalid =
      (jsonDecode(utf8.decode(Uint8List.sublistView(courseData))) as Map)
          .cast<String, dynamic>();
  if (wrongFieldType) {
    final Map<String, dynamic> firstModule =
        ((invalid['modules'] as List).first as Map).cast<String, dynamic>();
    final Map<String, dynamic> firstLesson =
        ((firstModule['lessons'] as List).first as Map).cast<String, dynamic>();
    firstLesson['minutes'] = 'ten';
  } else {
    final Map<String, dynamic> lastModule =
        ((invalid['modules'] as List).last as Map).cast<String, dynamic>();
    (lastModule['lessons'] as List).removeLast();
  }
  final Uint8List invalidBytes = Uint8List.fromList(
    utf8.encode(jsonEncode(invalid)),
  );

  final ByteData manifestData = await rootBundle.load(_manifestPath);
  final Map<String, dynamic> manifest =
      (jsonDecode(utf8.decode(Uint8List.sublistView(manifestData))) as Map)
          .cast<String, dynamic>();
  final Map<String, dynamic> asset =
      ((manifest['assets'] as List).single as Map).cast<String, dynamic>();
  asset['byteLength'] = invalidBytes.length;
  asset['sha256'] = computeSha256Hex(invalidBytes);
  manifest['catalogDigest'] = computeCatalogDigest(manifest);
  return _CourseAssetOverlayBundle(
    courseBytes: invalidBytes,
    manifestBytes: Uint8List.fromList(utf8.encode(jsonEncode(manifest))),
  );
}

Future<ContentException> _rejection(_CourseAssetOverlayBundle bundle) async {
  try {
    await ContentRepository(
      contentBundleOverride: bundle,
    ).loadSoloBoxingCourse();
  } on ContentException catch (error) {
    return error;
  }
  throw StateError('Expected the course integrity gate to reject the bundle');
}

// Each test owns a storage namespace; replacements inside it share this registry.
late OwnerResourceRegistry _owners;

void main() {
  setUp(() => _owners = OwnerResourceRegistry());
  TestWidgetsFlutterBinding.ensureInitialized();

  test('packaged manifest verifies the exact 39-lesson course', () async {
    final _CourseAssetOverlayBundle bundle = _CourseAssetOverlayBundle();
    final ContentRepository repository = ContentRepository(
      contentBundleOverride: bundle,
    );
    final course = await repository.loadSoloBoxingCourse();
    expect(course.modules, hasLength(8));
    expect(course.lessons, hasLength(39));
    expect(bundle.requestedPaths, contains(_manifestPath));
    expect(
      bundle.requestedPaths.where((String path) => path == _coursePath),
      hasLength(2),
    );

    final ByteData data = await rootBundle.load(_manifestPath);
    final Map<String, dynamic> manifest =
        (jsonDecode(utf8.decode(Uint8List.sublistView(data))) as Map)
            .cast<String, dynamic>();
    expect(manifest['courses'], isEmpty);
    expect(manifest['lessons'], isEmpty);
    expect(manifest['models'], isEmpty);
    final Map<String, dynamic> asset =
        ((manifest['assets'] as List).single as Map).cast<String, dynamic>();
    expect(asset['path'], _coursePath);
    expect(asset['byteLength'], 201068);
    expect(
      asset['sha256'],
      '0909b6c991fb631faeb357026475f787ae226562e261a479e0eb315095de069f',
    );
  });

  test(
    'same-length parseable tamper blocks before the course is exposed',
    () async {
      final ByteData originalData = await rootBundle.load(_coursePath);
      final Uint8List original = Uint8List.sublistView(originalData);
      final Uint8List changed = Uint8List.fromList(original);
      changed[changed.length - 1] = original.last == 10 ? 32 : 10;
      expect(changed.length, original.length);
      expect(() => jsonDecode(utf8.decode(changed)), returnsNormally);
      final _CourseAssetOverlayBundle bundle = _CourseAssetOverlayBundle(
        courseBytes: changed,
      );

      final ContentException error = await _rejection(bundle);
      expect(error.error.code, ContentErrorCode.hashMismatch);
      expect(ContentFailure.from(error).kind, ContentFailureKind.integrity);
      expect(bundle.requestedPaths, contains(_coursePath));
    },
  );

  test(
    'missing packaged manifest is a non-retryable integrity failure',
    () async {
      final _CourseAssetOverlayBundle bundle = _CourseAssetOverlayBundle(
        missingManifest: true,
      );
      final ContentException error = await _rejection(bundle);
      expect(error.error.code, ContentErrorCode.missingAsset);
      expect(ContentFailure.from(error).kind, ContentFailureKind.integrity);
      expect(bundle.requestedPaths, contains(_manifestPath));
      expect(bundle.requestedPaths, isNot(contains(_coursePath)));
    },
  );

  test(
    'missing packaged course is a non-retryable integrity failure',
    () async {
      final _CourseAssetOverlayBundle bundle = _CourseAssetOverlayBundle(
        missingCourse: true,
      );
      final ContentException error = await _rejection(bundle);
      expect(error.error.code, ContentErrorCode.missingAsset);
      expect(ContentFailure.from(error).kind, ContentFailureKind.integrity);
      expect(bundle.requestedPaths, contains(_coursePath));
    },
  );

  test(
    'hash-matched but invalid course schema is an integrity failure',
    () async {
      final _CourseAssetOverlayBundle bundle =
          await _schemaInvalidButHashMatchedBundle();
      final ContentException error = await _rejection(bundle);
      expect(error.error.code, ContentErrorCode.schema);
      expect(ContentFailure.from(error).kind, ContentFailureKind.integrity);
      expect(bundle.requestedPaths, contains(_coursePath));
    },
  );

  test(
    'hash-matched wrong JSON field type is a schema integrity failure',
    () async {
      final _CourseAssetOverlayBundle bundle =
          await _schemaInvalidButHashMatchedBundle(wrongFieldType: true);
      final ContentException error = await _rejection(bundle);
      expect(error.error.code, ContentErrorCode.schema);
      expect(ContentFailure.from(error).kind, ContentFailureKind.integrity);
    },
  );

  testWidgets('tampered course blocks home before the boxing entry is shown', (
    WidgetTester tester,
  ) async {
    final ByteData originalData = (await tester.runAsync(
      () => rootBundle.load(_coursePath),
    ))!;
    final Uint8List changed = Uint8List.fromList(
      Uint8List.sublistView(originalData),
    );
    changed[changed.length - 1] = changed.last == 10 ? 32 : 10;
    final _CourseAssetOverlayBundle bundle = _CourseAssetOverlayBundle(
      courseBytes: changed,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        JabLabApp(
          repository: ContentRepository(
            contentBundleOverride: bundle,
            ownerRegistry: _owners,
          ),
          onboarding: const OnboardingStore(seenOverride: true),
        ),
      );
    });
    await settleAppLoad(tester);
    await settleUntil(tester, find.byType(ContentFailureScreen));
    await tester.pumpAndSettle();

    expect(find.byType(ContentFailureScreen), findsOneWidget);
    expect(find.byKey(const Key('failure-retry')), findsNothing);
    expect(find.byType(SelectPage), findsNothing);
    expect(find.byKey(const Key('item-boxing')), findsNothing);
  });

  testWidgets('hash-matched invalid course blocks boot without retry', (
    WidgetTester tester,
  ) async {
    final _CourseAssetOverlayBundle bundle = (await tester.runAsync(
      _schemaInvalidButHashMatchedBundle,
    ))!;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        JabLabApp(
          repository: ContentRepository(
            contentBundleOverride: bundle,
            ownerRegistry: _owners,
          ),
          onboarding: const OnboardingStore(seenOverride: true),
        ),
      );
    });
    await settleAppLoad(tester);
    await settleUntil(tester, find.byType(ContentFailureScreen));
    await tester.pumpAndSettle();
    expect(find.byType(ContentFailureScreen), findsOneWidget);
    expect(find.byKey(const Key('failure-retry')), findsNothing);
    expect(find.byKey(const Key('failure-exit-course')), findsNothing);
    expect(find.byType(SelectPage), findsNothing);
  });

  for (final bool missingManifest in <bool>[true, false]) {
    testWidgets(
      'missing packaged ${missingManifest ? 'manifest' : 'course'} blocks boot without retry',
      (WidgetTester tester) async {
        final _CourseAssetOverlayBundle bundle = _CourseAssetOverlayBundle(
          missingManifest: missingManifest,
          missingCourse: !missingManifest,
        );
        await tester.runAsync(() async {
          await tester.pumpWidget(
            JabLabApp(
              repository: ContentRepository(
                contentBundleOverride: bundle,
                ownerRegistry: _owners,
              ),
              onboarding: const OnboardingStore(seenOverride: true),
            ),
          );
        });
        await settleAppLoad(tester);
        await settleUntil(tester, find.byType(ContentFailureScreen));
        await tester.pumpAndSettle();
        expect(find.byType(ContentFailureScreen), findsOneWidget);
        expect(find.byKey(const Key('failure-retry')), findsNothing);
        expect(find.byKey(const Key('failure-exit-course')), findsNothing);
        expect(find.byType(SelectPage), findsNothing);
      },
    );
  }

  testWidgets('direct course route shows no retry for a hash mismatch', (
    WidgetTester tester,
  ) async {
    final ByteData originalData = (await tester.runAsync(
      () => rootBundle.load(_coursePath),
    ))!;
    final Uint8List changed = Uint8List.fromList(
      Uint8List.sublistView(originalData),
    );
    changed[changed.length - 1] = changed.last == 10 ? 32 : 10;
    final _CourseAssetOverlayBundle bundle = _CourseAssetOverlayBundle(
      courseBytes: changed,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: SoloBoxingCoursePage(
            repository: ContentRepository(
              contentBundleOverride: bundle,
              ownerRegistry: _owners,
            ),
          ),
        ),
      );
    });
    for (var attempt = 0; attempt < 40; attempt++) {
      if (find.byType(ContentFailureScreen).evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.byType(ContentFailureScreen), findsOneWidget);
    expect(find.byKey(const Key('failure-retry')), findsNothing);
    expect(find.byKey(const Key('solo-course-progress')), findsNothing);
  });

  testWidgets('direct route classifies hash-matched bad schema as integrity', (
    WidgetTester tester,
  ) async {
    final _CourseAssetOverlayBundle bundle = (await tester.runAsync(
      _schemaInvalidButHashMatchedBundle,
    ))!;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: SoloBoxingCoursePage(
            repository: ContentRepository(
              contentBundleOverride: bundle,
              ownerRegistry: _owners,
            ),
          ),
        ),
      );
    });
    for (var attempt = 0; attempt < 40; attempt++) {
      if (find.byType(ContentFailureScreen).evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.byType(ContentFailureScreen), findsOneWidget);
    expect(find.byKey(const Key('failure-retry')), findsNothing);
    expect(find.byKey(const Key('solo-course-progress')), findsNothing);
  });

  testWidgets('pushed hash failure has visible back to the parent route', (
    WidgetTester tester,
  ) async {
    final ByteData originalData = (await tester.runAsync(
      () => rootBundle.load(_coursePath),
    ))!;
    final Uint8List changed = Uint8List.fromList(
      Uint8List.sublistView(originalData),
    );
    changed[changed.length - 1] = changed.last == 10 ? 32 : 10;
    final _CourseAssetOverlayBundle bundle = _CourseAssetOverlayBundle(
      courseBytes: changed,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-course-route'),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => SoloBoxingCoursePage(
                        repository: ContentRepository(
                          ownerRegistry: _owners,
                          contentBundleOverride: bundle,
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open course route'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-course-route')));
    await tester.pump();
    for (var attempt = 0; attempt < 40; attempt++) {
      if (find.byType(ContentFailureScreen).evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.byType(ContentFailureScreen), findsOneWidget);
    expect(find.byKey(const Key('failure-retry')), findsNothing);
    expect(find.byKey(const Key('failure-exit-course')), findsOneWidget);
    expect(find.byKey(const Key('solo-course-progress')), findsNothing);

    await tester.tap(find.byKey(const Key('failure-exit-course')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-course-route')), findsOneWidget);
    expect(find.byType(ContentFailureScreen), findsNothing);
  });
}
