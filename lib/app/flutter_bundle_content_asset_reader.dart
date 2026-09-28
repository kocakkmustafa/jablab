import 'package:flutter/services.dart';
import 'package:motion_content/motion_content.dart';

/// Reads logical content paths from the Flutter bundle as exact bytes.
///
/// [ContentBundleLoader] owns manifest, length, and SHA validation. The
/// adapter only rejects unsafe paths before handing a key to Flutter.
final class FlutterBundleContentAssetReader implements ContentAssetReader {
  FlutterBundleContentAssetReader({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<Uint8List> read(String logicalPath) async {
    PathPolicy.validate(logicalPath);
    final ByteData data = await _bundle.load(logicalPath);
    return Uint8List.fromList(Uint8List.sublistView(data));
  }
}
