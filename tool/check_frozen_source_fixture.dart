// Same portable assertions used by the default Flutter suite, runnable in Dart.
import 'dart:convert';
import 'dart:io';
import '../test/support/frozen_source_fixture.dart';

Future<void> main(List<String> arguments) async {
  requireFrozen(
    arguments.length <= 1,
    'Expected at most one candidate identity',
  );
  final identity = arguments.isEmpty ? null : arguments.single;
  requireFrozen(
    identity == null || RegExp(r'^[0-9a-f]{64}$').hasMatch(identity),
    'Invalid candidate identity',
  );
  final fixture = Directory('test/fixtures/frozen_source');
  await verifyFrozenFixture(fixture);
  verifyFrozenNegatives(fixture);
  // Emitted only after every fixture, VM and negative assertion completed.
  stdout.writeln(
    jsonEncode({
      'schema': 1,
      'checker': 'jablab-frozen-source-v1',
      'candidate_identity': identity,
      'status': 'PASS',
      'fixture_files': 7,
      'source_files': 329,
      'vm_graphs': ['app', 'engine'],
      'negative_cases': 4,
    }),
  );
}
