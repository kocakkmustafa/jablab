// Explicit live-history lane; absent evidence must fail, never skip.
// Source-preview identity guard. This does not accept a released Git pin.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import '../test/support/frozen_source_fixture.dart' show frozenDartExecutable;

const _historicalBase = 'bc10c21e57c85a468c380a79d9fed288554100ca';
const _authorizedDocsHead = '3c9429fc95b65caf72e30847e709bd53606ac940';

void _expectAuthorizedDocsTransition(
  String head,
  String parent,
  Set<String> files,
) {
  expect(head, _authorizedDocsHead);
  expect(parent, _historicalBase);
  expect(
    files,
    {'AGENTS.md', 'CLAUDE.md'},
    reason:
        'Only the separately authorized documentation transition is accepted; product blobs stay identical',
  );
}

final _workspace =
    Platform.environment['JABLAB_HISTORY_WORKSPACE'] ??
    (throw StateError(
      'Historical evidence unavailable: set JABLAB_HISTORY_WORKSPACE',
    ));
final _lane = '$_workspace/scratch/2026-10-01-release-week-dispatch/lanes';
final _preview = '$_lane/jablab/core-adoption-v4';
final _canonical = '$_workspace/ventures/jablab/app';
const _versions = <String, String>{
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

String _hash(String path) =>
    sha256.convert(File(path).readAsBytesSync()).toString();

void main() {
  test(
    'documentation transition rejects changed product blobs and unknown head',
    () {
      _expectAuthorizedDocsTransition(_authorizedDocsHead, _historicalBase, {
        'AGENTS.md',
        'CLAUDE.md',
      });
      expect(
        () => _expectAuthorizedDocsTransition(
          _authorizedDocsHead,
          _historicalBase,
          {'AGENTS.md', 'CLAUDE.md', 'lib/main.dart'},
        ),
        throwsA(isA<TestFailure>()),
      );
      expect(
        () => _expectAuthorizedDocsTransition('1' * 40, _historicalBase, {
          'AGENTS.md',
          'CLAUDE.md',
        }),
        throwsA(isA<TestFailure>()),
      );
    },
  );

  test(
    'exact frozen archive and all329 consumed source bytes match external seals',
    () {
      final manifestPath =
          '$_lane/motion_core/MOTION-CORE-FINAL-v4-source.manifest.json';
      expect(
        _hash(manifestPath),
        '1408182ae6ee4c274a20d7af77aee174e1c47d2e38829580212bdd077a52a416',
      );
      expect(
        _hash('$_lane/motion_core/MOTION-CORE-FINAL-v4.patch'),
        'ccdddad09a66e3be4d3dd11796add90f9c1f4c86977fa5cc2579de3e09472e0b',
      );
      expect(
        _hash('$_lane/motion_core/MOTION-CORE-FINAL-v4-source.tar.gz'),
        'ff314571318d7e6026455b310c45ef10ccc3df3ae828434505f5043e8dcb02b5',
      );
      final manifest =
          jsonDecode(File(manifestPath).readAsStringSync())
              as Map<String, dynamic>;
      expect(manifest['releaseSha'], isNull);
      expect(manifest['sourceFileCount'], 329);
      final members = Directory(
        '$_preview/core',
      ).listSync(recursive: true, followLinks: false);
      expect(members.whereType<Link>(), isEmpty);
      expect(
        members.whereType<File>().map(
          (file) => file.path.substring('$_preview/core/'.length),
        ),
        unorderedEquals(
          (manifest['allFiles'] as List).map((row) => row['path']),
        ),
      );

      for (final row
          in (manifest['allFiles'] as List).cast<Map<String, dynamic>>()) {
        final file = File('$_preview/core/${row['path']}');
        expect(file.lengthSync(), row['bytes'], reason: row['path'] as String);
        expect(_hash(file.path), row['sha256'], reason: row['path'] as String);
      }
    },
  );

  test(
    'actual Dart VM resolves all Motion libraries from both selected configs',
    () async {
      expect(
        _hash('$_preview/package-uri-probe.dart'),
        '98d1de89607433baabd68c9728058e0f5b0f276babf1264a18ce94e736afe528',
        reason: 'Actual Dart VM probe bytes must match the external plan seal',
      );
      for (final root in <String>[
        '$_preview/app',
        '$_preview/app/packages/jablab_engine',
      ]) {
        final result = await Process.run(frozenDartExecutable(), <String>[
          '--packages=$root/.dart_tool/package_config.json',
          '$_preview/package-uri-probe.dart',
        ]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        final resolved =
            jsonDecode(result.stdout as String) as Map<String, dynamic>;
        expect(resolved.keys, unorderedEquals(_versions.keys));
        for (final name in _versions.keys) {
          expect(
            File.fromUri(Uri.parse(resolved[name] as String)).absolute.path,
            '$_preview/core/packages/$name/lib/$name.dart',
          );
        }
      }
    },
  );

  test(
    'app and standalone engine path graphs contain no old or mixed Git root',
    () {
      for (final root in <String>[
        '$_preview/app',
        '$_preview/app/packages/jablab_engine',
      ]) {
        final configFile = File('$root/.dart_tool/package_config.json');
        final config =
            jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        final motion = (config['packages'] as List)
            .cast<Map<String, dynamic>>()
            .where((row) => (row['name'] as String).startsWith('motion_'))
            .toList();
        expect(motion, hasLength(10));
        expect(
          motion.map((row) => row['name']),
          unorderedEquals(_versions.keys),
        );
        final lock =
            loadYaml(File('$root/pubspec.lock').readAsStringSync()) as YamlMap;
        final packages = lock['packages'] as YamlMap;
        for (final row in motion) {
          final name = row['name'] as String;
          final uri = configFile.uri.resolve(row['rootUri'] as String);
          expect(
            Directory.fromUri(
              uri,
            ).absolute.path.replaceFirst(RegExp(r'/$'), ''),
            '$_preview/core/packages/$name',
          );
          final package = packages[name] as YamlMap;
          expect(package['source'], 'path');
          expect(package['version'], _versions[name]);
          final description = package['description'] as YamlMap;
          expect(description['path'], '$_preview/core/packages/$name');
          expect(description.containsKey('resolved-ref'), isFalse);
        }
      }
    },
  );

  test(
    'canonical Git pins and copied production guards retain original byte identity',
    () {
      expect(
        _hash('$_preview/SELECTION-RECEIPT.json'),
        '9b346343e939bab2d45037b8103a575e91565d8866198826e8b52b088b7e4af9',
      );
      final selection =
          jsonDecode(
                File('$_preview/SELECTION-RECEIPT.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final pinned = selection['canonicalPinnedFiles'] as Map<String, dynamic>;
      for (final entry in pinned.entries) {
        expect(_hash('$_canonical/${entry.key}'), entry.value);
      }
      final baseline = selection['appFiles'] as Map<String, dynamic>;
      for (final path in <String>[
        'test/core_adoption_contract_test.dart',
        'test/dependency_pin_test.dart',
      ]) {
        expect(
          _hash('$_preview/app/$path'),
          (baseline[path] as Map<String, dynamic>)['sha256'],
        );
      }
    },
  );
  test(
    'canonical Git index and local ignored model retain source-only boundaries',
    () async {
      const model = 'assets/models/pose_landmarker_full.v1.task';
      final head = await Process.run('git', [
        '-C',
        _canonical,
        'rev-parse',
        'HEAD',
      ]);
      expect(head.exitCode, 0);
      final currentHead = (head.stdout as String).trim();
      if (currentHead == _authorizedDocsHead) {
        final parent = await Process.run('git', [
          '-C',
          _canonical,
          'rev-parse',
          'HEAD^',
        ]);
        final delta = await Process.run('git', [
          '-C',
          _canonical,
          'diff',
          '--name-only',
          _historicalBase,
          currentHead,
        ]);
        expect(parent.exitCode, 0);
        expect(delta.exitCode, 0);
        _expectAuthorizedDocsTransition(
          currentHead,
          (parent.stdout as String).trim(),
          (delta.stdout as String).trim().split('\n').toSet(),
        );
      } else {
        expect(currentHead, _historicalBase);
      }
      final ignored = await Process.run('git', [
        '-C',
        _canonical,
        'check-ignore',
        '--quiet',
        model,
      ]);
      expect(
        ignored.exitCode,
        0,
        reason: 'model remains ignored in canonical repository',
      );
      final tracked = await Process.run('git', [
        '-C',
        _canonical,
        'ls-files',
        '--error-unmatch',
        model,
      ]);
      expect(
        tracked.exitCode,
        1,
        reason:
            'model must be absent from canonical Git index, rather than Git inspection failing',
      );
      expect(File('$_preview/app/$model').lengthSync(), 9398198);
      expect(
        _hash('$_preview/app/$model'),
        '5134a3aad27a58b93da0088d431f366da362b44e3ccfbe3462b3827a839011b1',
      );
    },
  );
}
