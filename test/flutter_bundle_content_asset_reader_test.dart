import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/flutter_bundle_content_asset_reader.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:motion_content/motion_content.dart';

const String _manifestPath = 'assets/motion_content/manifest.json';
const String _coursePath = ContentRepository.soloBoxingCourseAsset;
// Pin for the existing JabLab course asset at this bridge test's review.
const int _courseByteLength = 201068;
const String _courseSha256 =
    '0909b6c991fb631faeb357026475f787ae226562e261a479e0eb315095de069f';

final class _ManifestOverlayBundle extends CachingAssetBundle {
  _ManifestOverlayBundle(this.manifestBytes);

  final Uint8List manifestBytes;
  final List<String> requestedPaths = <String>[];

  @override
  Future<ByteData> load(String key) {
    requestedPaths.add(key);
    if (key == _manifestPath) {
      return Future<ByteData>.value(
        ByteData.view(
          manifestBytes.buffer,
          manifestBytes.offsetInBytes,
          manifestBytes.lengthInBytes,
        ),
      );
    }
    return rootBundle.load(key);
  }
}

Uint8List _manifestBytes({String? assetPath, String? assetSha256}) {
  final Map<String, Object?> manifest = <String, Object?>{
    'schemaVersion': 1,
    'contentVersion': '1.0.0',
    'appId': 'com.yulalab.jablab',
    'minimumCoreContract': '1.0.0',
    'locales': <String>['tr', 'en'],
    'courses': <Object?>[
      <String, Object?>{
        'id': 'solo-boxing-bridge-test',
        'order': 0,
        'visibility': 'free',
        'title': <String, String>{'tr': 'Boks', 'en': 'Boxing'},
        'description': <String, String>{
          'tr': 'Paket doğrulama testi',
          'en': 'Bundle verification test',
        },
        'lessonIds': <String>['solo-boxing-asset-test'],
      },
    ],
    'lessons': <Object?>[
      <String, Object?>{
        'id': 'solo-boxing-asset-test',
        'type': 'practice',
        'title': <String, String>{'tr': 'Ders', 'en': 'Lesson'},
        'description': <String, String>{'tr': 'Test', 'en': 'Test'},
        'instruction': <String, String>{'tr': 'Oku', 'en': 'Read'},
        'accessibilityLabel': <String, String>{
          'tr': 'Dersi aç',
          'en': 'Open lesson',
        },
        'modelIds': <String>[],
        'assetIds': <String>['solo-boxing-asset'],
      },
    ],
    'models': <Object?>[],
    'assets': <Object?>[
      <String, Object?>{
        'id': 'solo-boxing-asset',
        'path': assetPath ?? _coursePath,
        'byteLength': _courseByteLength,
        'sha256': assetSha256 ?? _courseSha256,
      },
    ],
  };
  manifest['catalogDigest'] = computeCatalogDigest(manifest);
  return Uint8List.fromList(utf8.encode(jsonEncode(manifest)));
}

ContentBundleLoader _loader(_ManifestOverlayBundle bundle) =>
    ContentBundleLoader(
      reader: FlutterBundleContentAssetReader(bundle: bundle),
      expectedAppId: 'com.yulalab.jablab',
      currentCoreContract: SemanticVersion.parse('1.0.0'),
      manifestPath: _manifestPath,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reads the pinned existing course bytes through Flutter bundle',
    () async {
      final _ManifestOverlayBundle bundle = _ManifestOverlayBundle(
        _manifestBytes(),
      );
      final ContentLoadResult result = await _loader(bundle).load();

      expect(result, isA<ContentReady>());
      final ContentReady ready = result as ContentReady;
      expect(ready.catalog.manifest.assets.single.path, _coursePath);
      expect(bundle.requestedPaths, <String>[_manifestPath, _coursePath]);

      final Uint8List bytes = await ready.assets.read(_coursePath);
      expect(bytes.length, _courseByteLength);
      expect(computeSha256Hex(bytes), _courseSha256);
      final SoloBoxingCourse course = SoloBoxingCourse.fromJsonString(
        utf8.decode(bytes),
      );
      expect(course.id, 'jablab.solo_boxing');
      expect(course.modules, hasLength(8));
      expect(course.lessons, hasLength(39));
      expect(bundle.requestedPaths.last, _coursePath);
    },
  );

  test('a wrong pinned hash blocks the course before it is exposed', () async {
    final _ManifestOverlayBundle bundle = _ManifestOverlayBundle(
      _manifestBytes(assetSha256: List<String>.filled(64, '0').join()),
    );
    final ContentLoadResult result = await _loader(bundle).load();

    expect(result, isA<ContentBlocked>());
    expect(
      (result as ContentBlocked).error.code,
      ContentErrorCode.hashMismatch,
    );
  });

  test('previous course SHA cannot expose the new course bytes', () async {
    final _ManifestOverlayBundle bundle = _ManifestOverlayBundle(
      _manifestBytes(
        assetSha256:
            '09b060840beeaa6e527a1768241850a57eb0363a29839c517cafb3bfc0bd5335',
      ),
    );
    final ContentLoadResult result = await _loader(bundle).load();

    expect(result, isA<ContentBlocked>());
    expect(
      (result as ContentBlocked).error.code,
      ContentErrorCode.hashMismatch,
    );
  });

  test('unsafe manifest path is blocked without a bundle read', () async {
    final _ManifestOverlayBundle bundle = _ManifestOverlayBundle(
      _manifestBytes(assetPath: 'assets/content/../private.json'),
    );
    final ContentLoadResult result = await _loader(bundle).load();

    expect(result, isA<ContentBlocked>());
    expect((result as ContentBlocked).error.code, ContentErrorCode.unsafePath);
    expect(bundle.requestedPaths, <String>[_manifestPath]);
  });

  test(
    'direct reader also rejects unsafe paths before Flutter sees them',
    () async {
      final _ManifestOverlayBundle bundle = _ManifestOverlayBundle(
        _manifestBytes(),
      );
      final FlutterBundleContentAssetReader reader =
          FlutterBundleContentAssetReader(bundle: bundle);

      await expectLater(
        reader.read('../private.json'),
        throwsA(
          isA<ContentException>().having(
            (ContentException error) => error.error.code,
            'code',
            ContentErrorCode.unsafePath,
          ),
        ),
      );
      expect(bundle.requestedPaths, isEmpty);
    },
  );
}
