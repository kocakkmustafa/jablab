import 'dart:convert';
import 'dart:isolate';

Future<void> main() async {
  final names = <String>[
    'motion_account',
    'motion_audio',
    'motion_camera',
    'motion_content',
    'motion_core',
    'motion_entitlements',
    'motion_feedback',
    'motion_media',
    'motion_store',
    'motion_telemetry',
  ];
  final paths = <String, String>{};
  for (final name in names) {
    final uri = await Isolate.resolvePackageUri(
      Uri.parse('package:$name/$name.dart'),
    );
    if (uri == null) throw StateError('Unresolved $name');
    paths[name] = uri.toString();
  }
  print(jsonEncode(paths));
}
