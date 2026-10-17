import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show AssetBundle;

import 'pose_model.dart';

/// Bundled assets only. A cache filename is never evidence of model identity.
/// A later app/model revision uses a different hash path; no remote model or
/// automatic calibration promotion is introduced here.
abstract final class VerifiedPoseModel {
  static Future<String> materialize({
    required AssetBundle bundle,
    required Directory directory,
  }) async {
    final output = File(
      '${directory.path}/jablab-pose-${PoseModelPin.sha256}.task',
    );
    if (await output.exists()) {
      await _verify(output);
      return output.path;
    }

    final data = await bundle.load(PoseModelPin.assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    _verifyBytes(bytes);
    await directory.create(recursive: true);
    // A partial write never has the final model filename. Temp ownership is
    // local to this operation and cleanup cannot touch another invocation.
    final staging = await directory.createTemp('.jablab-model-');
    try {
      final pending = File('${staging.path}/verified.task');
      await pending.writeAsBytes(bytes, flush: true);
      await _verify(pending);
      // Concurrent callers may publish only the same verified pinned bytes.
      await pending.rename(output.path);
      await _verify(output);
      return output.path;
    } finally {
      await staging.delete(recursive: true);
    }
  }

  static Future<void> _verify(File file) async {
    if (await file.length() != PoseModelPin.byteLength ||
        (await sha256.bind(file.openRead()).first).toString() !=
            PoseModelPin.sha256) {
      throw const PoseModelIntegrityException();
    }
  }

  static void _verifyBytes(Uint8List bytes) {
    if (bytes.length != PoseModelPin.byteLength ||
        sha256.convert(bytes).toString() != PoseModelPin.sha256) {
      throw const PoseModelIntegrityException();
    }
  }
}

/// A corrupt cache/asset disables camera analysis; written lessons remain open.
/// Existing unknown or corrupt files are preserved, never silently adopted.
final class PoseModelIntegrityException implements Exception {
  const PoseModelIntegrityException();

  @override
  String toString() => 'The bundled pose model could not be verified.';
}
