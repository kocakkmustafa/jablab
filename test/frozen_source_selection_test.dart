// Portable snapshots only. The separate live historical obligation is required
// by tool/frozen_source_release_gate.py before aggregate release acceptance.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'support/frozen_source_fixture.dart';

void main() {
  final fixture = Directory('test/fixtures/frozen_source');
  test(
    'sealed historical archive, locks, receipt and both actual VM graphs',
    () async {
      await verifyFrozenFixture(fixture);
    },
  );
  test('historical fixture rejects wrong paths and identities', () {
    verifyFrozenNegatives(fixture);
  });
}
