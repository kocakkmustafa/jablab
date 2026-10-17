import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/pose_model.dart';
import 'package:jablab/app/verified_pose_model.dart';

void main() {
  late Directory directory;
  late Uint8List realBundledBytes;
  setUpAll(() {
    // Verifies the actual local pinned model; no download or inference runs.
    realBundledBytes = File(PoseModelPin.assetPath).readAsBytesSync();
  });
  setUp(
    () async =>
        directory = await Directory.systemTemp.createTemp('jablab-model-test-'),
  );
  tearDown(() async => directory.delete(recursive: true));

  test(
    'legacy filename is preserved and never trusted; hash path is verified',
    () async {
      final legacy = File('${directory.path}/pose_landmarker_full.v1.task');
      await legacy.writeAsString('legacy invalid bytes');
      final bundle = _Bundle(realBundledBytes);
      final path = await VerifiedPoseModel.materialize(
        bundle: bundle,
        directory: directory,
      );
      expect(path, endsWith('jablab-pose-${PoseModelPin.sha256}.task'));
      expect(await File(path).readAsBytes(), realBundledBytes);
      expect(await legacy.readAsString(), 'legacy invalid bytes');
      expect(bundle.reads, 1);
      expect(
        await VerifiedPoseModel.materialize(
          bundle: bundle,
          directory: directory,
        ),
        path,
      );
      expect(bundle.reads, 1, reason: 'verified cache needs no asset read');
      expect(directory.listSync().whereType<Directory>(), isEmpty);
    },
  );

  test(
    'same-length corruption in cache is refused without deletion or fallback',
    () async {
      final bundle = _Bundle(realBundledBytes);
      final path = await VerifiedPoseModel.materialize(
        bundle: bundle,
        directory: directory,
      );
      final corrupt = Uint8List.fromList(realBundledBytes)..[0] ^= 1;
      await File(path).writeAsBytes(corrupt);
      await expectLater(
        VerifiedPoseModel.materialize(bundle: bundle, directory: directory),
        throwsA(isA<PoseModelIntegrityException>()),
      );
      expect(bundle.reads, 1);
      expect(await File(path).readAsBytes(), corrupt);
    },
  );

  test('bad asset never publishes model or staging directory', () async {
    await expectLater(
      VerifiedPoseModel.materialize(
        bundle: _Bundle(Uint8List.fromList([1, 2, 3])),
        directory: directory,
      ),
      throwsA(isA<PoseModelIntegrityException>()),
    );
    expect(await directory.list().toList(), isEmpty);
  });

  test('asset ByteData view respects offset and length', () async {
    final storage = Uint8List(realBundledBytes.length + 8)
      ..setRange(4, 4 + realBundledBytes.length, realBundledBytes);
    final bundle = _Bundle(storage, offset: 4, length: realBundledBytes.length);
    final path = await VerifiedPoseModel.materialize(
      bundle: bundle,
      directory: directory,
    );
    expect(await File(path).length(), PoseModelPin.byteLength);
    expect(await File(path).readAsBytes(), realBundledBytes);
  });

  test(
    'concurrent callers publish verified bytes and clean only own temp dirs',
    () async {
      final paths = await Future.wait([
        for (var i = 0; i < 3; i++)
          VerifiedPoseModel.materialize(
            bundle: _Bundle(realBundledBytes),
            directory: directory,
          ),
      ]);
      expect(paths.toSet(), hasLength(1));
      expect(await File(paths.first).readAsBytes(), realBundledBytes);
      expect(directory.listSync().whereType<Directory>(), isEmpty);
    },
  );
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.bytes, {this.offset = 0, int? length})
    : length = length ?? bytes.length;
  final Uint8List bytes;
  final int offset, length;
  var reads = 0;
  @override
  Future<ByteData> load(String key) async {
    expect(key, PoseModelPin.assetPath);
    reads++;
    return ByteData.view(bytes.buffer, offset, length);
  }
}
