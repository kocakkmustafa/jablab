import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const currentMotionSha = 'f43d71a375431e96c689a7a4a04fb53ff01af693';

bool hasLocalMotionOverrides([String? source]) {
  final file = File('pubspec_overrides.yaml');
  source ??= file.existsSync() ? file.readAsStringSync() : '';
  return RegExp(r'^  motion_[a-z_]+:', multiLine: true).hasMatch(source);
}

void verifyResolvedPublishedMotionGraph(
  Map<String, dynamic> config,
  Uri configUri,
  String lock,
) {
  final rows = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .where((row) => (row['name'] as String).startsWith('motion_'))
      .toList();
  expect(rows, isNotEmpty);
  final first = Directory.fromUri(
    configUri.resolve(rows.first['rootUri'] as String),
  );
  final root = first.parent.parent.resolveSymbolicLinksSync();
  final head = Process.runSync('git', ['-C', root, 'rev-parse', 'HEAD']);
  expect(
    head.exitCode,
    0,
    reason: 'Selected Core must be an actual Git checkout',
  );
  final clean = Process.runSync('git', [
    '-C',
    root,
    'diff',
    '--quiet',
    'HEAD',
    '--',
    'packages',
  ]);
  expect(
    clean.exitCode,
    0,
    reason: 'Selected Core source must equal its commit',
  );
  verifyPublishedMotionGraph(
    config,
    configUri,
    lock,
    root,
    actualCommit: (head.stdout as String).trim(),
  );
  for (final row in rows) {
    final name = row['name'] as String;
    final spec = File('$root/packages/$name/pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: ([0-9.]+)$',
      multiLine: true,
    ).firstMatch(spec)?.group(1);
    expect(version, isNotNull);
    final block = RegExp(
      '^  ${RegExp.escape(name)}:\\n(?:(?!^  \\S).)*',
      multiLine: true,
      dotAll: true,
    ).firstMatch(lock)!.group(0)!;
    expect(block, contains('    version: "$version"'));
  }
}

void verifyPublishedMotionGraph(
  Map<String, dynamic> config,
  Uri configUri,
  String lock,
  String expectedRoot, {
  required String actualCommit,
}) {
  expect(
    actualCommit,
    currentMotionSha,
    reason: 'Actual checkout HEAD must equal the approved Core commit',
  );
  final rows = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .where((row) => (row['name'] as String).startsWith('motion_'))
      .toList();
  expect(rows, isNotEmpty);
  for (final row in rows) {
    final name = row['name'] as String;
    final actual = Directory.fromUri(
      configUri.resolve(row['rootUri'] as String),
    ).absolute.path;
    final selected = Directory(actual);
    final canonical = selected.existsSync()
        ? selected.resolveSymbolicLinksSync()
        : actual;
    expect(canonical, '$expectedRoot/packages/$name');
    final block = RegExp(
      '^  ${RegExp.escape(name)}:\\n(?:(?!^  \\S).)*',
      multiLine: true,
      dotAll: true,
    ).firstMatch(lock)?.group(0);
    expect(block, isNotNull, reason: '$name must have an actual lock entry');
    expect(block, contains('    source: git'));
    for (final field in ['ref', 'resolved-ref']) {
      expect(
        RegExp(
          """^      $field: (?:$currentMotionSha|"$currentMotionSha"|'$currentMotionSha')\$""",
          multiLine: true,
        ).allMatches(block!),
        hasLength(1),
      );
    }
    expect(block, contains('      path: "packages/$name"'));
    expect(
      block,
      contains('      url: "https://github.com/kocakkmustafa/motion-core.git"'),
    );
  }
}

const receiptDigest =
    '8c38cd963b4db730d72c5a3c3ff42c5df3064d84527e59b98a686771ecd02be9';
const intakeRoot = 'test/fixtures/indexed-intake';

Map<String, dynamic> verifyIntake() {
  final bytes = File('$intakeRoot/receipt.json').readAsBytesSync();
  expect(sha256.convert(bytes).toString(), receiptDigest);
  final receipt = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  for (final row in (receipt['locks'] as List).cast<Map<String, dynamic>>()) {
    expect(
      sha256
          .convert(File('$intakeRoot/${row['fixture']}').readAsBytesSync())
          .toString(),
      row['sha256'],
    );
  }
  return receipt;
}

void verifyCurrentLocalCore() {
  verifyIntake();
  final expected = Directory(
    '../motion-core',
  ).absolute.resolveSymbolicLinksSync();
  for (final configPath in [
    '.dart_tool/package_config.json',
    'packages/jablab_engine/.dart_tool/package_config.json',
  ]) {
    final file = File(configPath).absolute;
    final graph = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final rows = (graph['packages'] as List)
        .cast<Map<String, dynamic>>()
        .where((row) => (row['name'] as String).startsWith('motion_'))
        .toList();
    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(
        Directory.fromUri(
          file.uri.resolve(row['rootUri'] as String),
        ).resolveSymbolicLinksSync(),
        '$expected/packages/${row['name']}',
      );
    }
  }
}

String lockForAudit(String path) {
  if (!hasLocalMotionOverrides()) {
    for (final configPath in [
      '.dart_tool/package_config.json',
      'packages/jablab_engine/.dart_tool/package_config.json',
    ]) {
      final config = File(configPath).absolute;
      final graph =
          jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
      final lockPath = configPath.startsWith('packages/')
          ? 'packages/jablab_engine/pubspec.lock'
          : 'pubspec.lock';

      verifyResolvedPublishedMotionGraph(
        graph,
        config.uri,
        File(lockPath).readAsStringSync(),
      );
    }
    return File(path).readAsStringSync();
  }
  verifyCurrentLocalCore();
  return File('$intakeRoot/${path.replaceAll('/', '__')}').readAsStringSync();
}
