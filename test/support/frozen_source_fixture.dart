// Portable immutable evidence checks; live history remains a release obligation.
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

const frozenVersions = <String, String>{
  'motion_account': '0.2.0',
  'motion_audio': '0.1.1',
  'motion_camera': '0.2.0',
  'motion_content': '0.1.0',
  'motion_core': '0.12.0',
  'motion_entitlements': '0.1.1',
  'motion_feedback': '0.1.0',
  'motion_media': '0.1.0',
  'motion_store': '0.3.0',
  'motion_telemetry': '0.4.0',
};
const frozenSeals = <String, String>{
  'MOTION-CORE-FINAL-v4-source.manifest.json':
      '1408182ae6ee4c274a20d7af77aee174e1c47d2e38829580212bdd077a52a416',
  'MOTION-CORE-FINAL-v4.patch':
      'ccdddad09a66e3be4d3dd11796add90f9c1f4c86977fa5cc2579de3e09472e0b',
  'MOTION-CORE-FINAL-v4-source.tar.gz':
      'ff314571318d7e6026455b310c45ef10ccc3df3ae828434505f5043e8dcb02b5',
  'SELECTION-RECEIPT.json':
      '9b346343e939bab2d45037b8103a575e91565d8866198826e8b52b088b7e4af9',
  'package-uri-probe.dart':
      '98d1de89607433baabd68c9728058e0f5b0f276babf1264a18ce94e736afe528',
  'app.pubspec.lock':
      '86ffb6205d421cdc8acb7204ebc8215693337855336345dc218012ff1a949744',
  'engine.pubspec.lock':
      '60488ae4b44e8f817b0c59ea059d5c026b383273d762321fd5e8f06b17d45ca6',
};
void requireFrozen(bool condition, String reason) {
  if (!condition) throw StateError(reason);
}

void verifyFrozenSeal(File file, String expected) {
  requireFrozen(
    sha256.convert(file.readAsBytesSync()).toString() == expected,
    'Wrong historical identity: ${file.path}',
  );
}

void rejectFrozenPath(String path) {
  requireFrozen(
    path.isNotEmpty &&
        !path.startsWith('/') &&
        !path.contains('\\') &&
        !path.split('/').any((p) => p == '..' || p == '.' || p.isEmpty),
    'Unsafe historical member path: $path',
  );
}

// dart runs directly; flutter_tester locates dart in its active SDK cache.
String frozenDartExecutable() {
  final executable = File(Platform.resolvedExecutable);
  if (executable.uri.pathSegments.last == 'dart' ||
      executable.uri.pathSegments.last == 'dart.exe') {
    return executable.path;
  }
  var directory = executable.parent;
  while (true) {
    final candidate = File(
      '${directory.path}/dart-sdk/bin/dart${Platform.isWindows ? '.exe' : ''}',
    );
    if (candidate.existsSync()) return candidate.path;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  return 'dart';
}

void verifyFrozenResolution(Map<String, dynamic> resolved, Directory core) {
  requireFrozen(
    resolved.length == frozenVersions.length &&
        resolved.keys.toSet().containsAll(frozenVersions.keys),
    'Incomplete Motion VM resolution',
  );
  for (final name in frozenVersions.keys) {
    requireFrozen(
      resolved[name] is String &&
          Uri.parse(resolved[name] as String) ==
              File('${core.path}/packages/$name/lib/$name.dart').absolute.uri,
      'Wrong selected Motion library: $name',
    );
  }
}

Future<void> verifyFrozenFixture(Directory fixture) async {
  for (final entry in frozenSeals.entries) {
    verifyFrozenSeal(File('${fixture.path}/${entry.key}'), entry.value);
  }
  final manifest =
      jsonDecode(
            File(
              '${fixture.path}/MOTION-CORE-FINAL-v4-source.manifest.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final receipt =
      jsonDecode(
            File('${fixture.path}/SELECTION-RECEIPT.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  requireFrozen(
    manifest['releaseSha'] == null && manifest['sourceFileCount'] == 329,
    'Wrong historical source boundary',
  );
  requireFrozen(
    receipt['sourceFiles'] == 329 && receipt['releaseSha'] == null,
    'Wrong original selection receipt',
  );
  requireFrozen(
    receipt['sourceManifestSha256'] ==
            frozenSeals['MOTION-CORE-FINAL-v4-source.manifest.json'] &&
        receipt['sourcePatchSha256'] ==
            frozenSeals['MOTION-CORE-FINAL-v4.patch'] &&
        receipt['archiveSha256'] ==
            frozenSeals['MOTION-CORE-FINAL-v4-source.tar.gz'],
    'Receipt source seals mismatch',
  );
  final rows = (manifest['allFiles'] as List).cast<Map<String, dynamic>>();
  final paths = rows.map((row) => row['path'] as String).toSet();
  requireFrozen(
    rows.length == 329 && paths.length == 329,
    'Duplicate/missing source member',
  );
  for (final path in paths) {
    rejectFrozenPath(path);
  }
  // The exact immutable archive seal is verified before extraction. Its 329
  // members are regular files; reject links and extras again after extraction.
  final temporary = Directory.systemTemp.createTempSync('jablab-frozen-');
  try {
    final core = Directory('${temporary.path}/core')..createSync();
    final extracted = await Process.run('tar', [
      '-xzf',
      File('${fixture.path}/MOTION-CORE-FINAL-v4-source.tar.gz').absolute.path,
      '-C',
      core.path,
    ]);
    requireFrozen(
      extracted.exitCode == 0,
      'Archive extraction failed: ${extracted.stderr}',
    );
    final members = core.listSync(recursive: true, followLinks: false);
    requireFrozen(
      !members.any((member) => member is Link),
      'Archive contains links',
    );
    final actual = members
        .whereType<File>()
        .map((f) => f.path.substring(core.path.length + 1))
        .toSet();
    requireFrozen(
      actual.length == paths.length && actual.containsAll(paths),
      'Archive inventory mismatch',
    );
    for (final row in rows) {
      final file = File('${core.path}/${row['path']}');
      requireFrozen(
        file.lengthSync() == row['bytes'],
        'Wrong bytes: ${row['path']}',
      );
      verifyFrozenSeal(file, row['sha256'] as String);
    }
    // Check original lock paths as one consistent historical root. Rebase only
    // generated configs, preserving every byte of both locks and the receipt.
    String? historicalCore;
    for (final lane in ['app', 'engine']) {
      final lock =
          loadYaml(
                File('${fixture.path}/$lane.pubspec.lock').readAsStringSync(),
              )
              as YamlMap;
      final packages = lock['packages'] as YamlMap;
      final configPackages = <Map<String, dynamic>>[];
      for (final entry in frozenVersions.entries) {
        final package = packages[entry.key] as YamlMap;
        final description = package['description'] as YamlMap;
        final path = description['path'] as String;
        final suffix = '/packages/${entry.key}';
        requireFrozen(
          path.endsWith(suffix),
          'Wrong historical lock path: ${entry.key}',
        );
        historicalCore ??= path.substring(0, path.length - suffix.length);
        requireFrozen(
          path == '$historicalCore$suffix',
          'Mixed historical lock roots',
        );
        requireFrozen(
          package['source'] == 'path' &&
              package['version'] == entry.value &&
              !description.containsKey('resolved-ref'),
          'Wrong historical graph: ${entry.key}',
        );
        configPackages.add({
          'name': entry.key,
          'rootUri': '../../core/packages/${entry.key}/',
          'packageUri': 'lib/',
          'languageVersion': '3.11',
        });
      }
      final config = File(
        '${temporary.path}/$lane/.dart_tool/package_config.json',
      );
      config.parent.createSync(recursive: true);
      config.writeAsStringSync(
        jsonEncode({'configVersion': 2, 'packages': configPackages}),
      );
      final result = await Process.run(frozenDartExecutable(), [
        '--packages=${config.path}',
        File('${fixture.path}/package-uri-probe.dart').absolute.path,
      ]);
      requireFrozen(result.exitCode == 0, 'VM probe failed: ${result.stderr}');
      verifyFrozenResolution(
        jsonDecode(result.stdout as String) as Map<String, dynamic>,
        core,
      );
    }
  } finally {
    temporary.deleteSync(recursive: true); // Only this invocation's owned temp.
  }
}

void verifyFrozenNegatives(Directory fixture) {
  var rejected = 0;
  for (final operation in <void Function()>[
    () => rejectFrozenPath('../outside.dart'),
    () => rejectFrozenPath('/absolute.dart'),
    () => verifyFrozenSeal(
      File('${fixture.path}/SELECTION-RECEIPT.json'),
      '0' * 64,
    ),
    () => verifyFrozenResolution({
      for (final name in frozenVersions.keys) name: 'file:///wrong/$name.dart',
    }, Directory('/selected/core')),
  ]) {
    try {
      operation();
    } on StateError {
      rejected++;
    }
  }
  requireFrozen(
    rejected == 4,
    'Wrong-path/identity negative unexpectedly passed',
  );
}
