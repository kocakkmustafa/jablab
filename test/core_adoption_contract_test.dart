import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _approvedSha = 'f2ea161c7e974d57b114ba7773836c72be17a381';
const _historicalSha = 'f13bdc93b2eae2f741bfcdb4c9270a88e5d75e5d';

void main() {
  group('CORE-ADOPT-001 motion dependency contract', () {
    test('every present descriptor ref is the approved Core SHA', () {
      expect(
        _descriptorRefs(File('pubspec.yaml').readAsStringSync()),
        {
          'motion_core': _approvedSha,
          'motion_camera': _approvedSha,
        },
      );
      expect(
        _descriptorRefs(
          File('packages/jablab_engine/pubspec.yaml').readAsStringSync(),
        ),
        {'motion_core': _approvedSha},
      );
    });

    test('every tracked lock ref and resolved-ref is the approved Core SHA',
        () {
      expect(
        _lockRefs(File('pubspec.lock').readAsStringSync()),
        {
          'motion_core': _LockRef(_approvedSha, _approvedSha),
          'motion_camera': _LockRef(_approvedSha, _approvedSha),
        },
      );
      expect(
        _lockRefs(
          File('packages/jablab_engine/pubspec.lock').readAsStringSync(),
        ),
        {'motion_core': _LockRef(_approvedSha, _approvedSha)},
      );
    });

    test('a historical f13 descriptor pin fails the approved-SHA contract', () {
      expect(
        _matchesApprovedDescriptor({'motion_core': _historicalSha}),
        isFalse,
      );
    });

    test('mixed lock ref and resolved-ref fails even when one value is approved',
        () {
      expect(
        _matchesApprovedLock(
          _LockRef(_approvedSha, _historicalSha),
        ),
        isFalse,
      );
    });
  });
}

Map<String, String> _descriptorRefs(String yaml) {
  final refs = <String, String>{};
  for (final package in ['motion_core', 'motion_camera']) {
    final match = RegExp(
      '^  $package:\\n(?:^    .+\\n)*?^      ref: (\\S+)',
      multiLine: true,
    ).firstMatch(yaml);
    if (match != null) refs[package] = _yamlScalar(match.group(1)!);
  }
  return refs;
}

Map<String, _LockRef> _lockRefs(String yaml) {
  final refs = <String, _LockRef>{};
  for (final package in ['motion_core', 'motion_camera']) {
    final block = RegExp(
      '^  $package:\\n(?:(?!^  \\S).)*',
      multiLine: true,
      dotAll: true,
    ).firstMatch(yaml)?.group(0);
    if (block == null) continue;
    final ref = RegExp(r'^      ref: (\S+)', multiLine: true)
        .firstMatch(block)
        ?.group(1);
    final resolvedRef = RegExp(r'^      resolved-ref: (\S+)', multiLine: true)
        .firstMatch(block)
        ?.group(1);
    if (ref == null || resolvedRef == null) {
      throw StateError('$package lock bloğunda ref/resolved-ref eksik');
    }
    refs[package] = _LockRef(_yamlScalar(ref), _yamlScalar(resolvedRef));
  }
  return refs;
}

bool _matchesApprovedDescriptor(Map<String, String> refs) =>
    refs.values.every((ref) => ref == _approvedSha);

bool _matchesApprovedLock(_LockRef ref) =>
    ref.ref == _approvedSha && ref.resolvedRef == _approvedSha;

String _yamlScalar(String value) => value.replaceAll(RegExp(r'^"|"$'), '');

class _LockRef {
  const _LockRef(this.ref, this.resolvedRef);

  final String ref;
  final String resolvedRef;

  @override
  bool operator ==(Object other) =>
      other is _LockRef &&
      other.ref == ref &&
      other.resolvedRef == resolvedRef;

  @override
  int get hashCode => Object.hash(ref, resolvedRef);

  @override
  String toString() => 'LockRef(ref: $ref, resolvedRef: $resolvedRef)';
}
