import 'dart:io';
import 'support/local_core_intake.dart';

import 'package:flutter_test/flutter_test.dart';

const _approvedSha = 'f43d71a375431e96c689a7a4a04fb53ff01af693';
const _historicalSha = 'f13bdc93b2eae2f741bfcdb4c9270a88e5d75e5d';

void main() {
  test('header-only override is not local Core mode', () {
    expect(hasLocalMotionOverrides('dependency_overrides:\n'), isFalse);
    expect(
      hasLocalMotionOverrides(
        'dependency_overrides:\n  motion_core:\n    path: ../motion-core\n',
      ),
      isTrue,
    );
  });
  test(
    'published graph rejects wrong resolved SHA, URI, and malformed lock',
    () {
      const root = '/fixture/git/motion-core-$currentMotionSha';
      final config = <String, dynamic>{
        'packages': [
          {'name': 'motion_core', 'rootUri': '$root/packages/motion_core'},
        ],
      };
      const lock =
          '  motion_core:\n    description:\n'
          '      path: "packages/motion_core"\n'
          '      ref: "$currentMotionSha"\n'
          '      resolved-ref: "$currentMotionSha"\n'
          '      url: "https://github.com/kocakkmustafa/motion-core.git"\n'
          '    source: git\n    version: "0.13.0"\n';
      final uri = Uri.file('/fixture/.dart_tool/package_config.json');
      verifyPublishedMotionGraph(
        config,
        uri,
        lock,
        root,
        actualCommit: currentMotionSha,
      );
      const alternateRoot = '/other/custom/cache/repository-checkout';
      final alternate = <String, dynamic>{
        'packages': [
          {
            'name': 'motion_core',
            'rootUri': '$alternateRoot/packages/motion_core',
          },
        ],
      };
      verifyPublishedMotionGraph(
        alternate,
        uri,
        lock,
        alternateRoot,
        actualCommit: currentMotionSha,
      );
      expect(
        () => verifyPublishedMotionGraph(
          config,
          uri,
          lock,
          root,
          actualCommit: '1' * 40,
        ),
        throwsA(isA<TestFailure>()),
      );

      for (final bad in [
        lock.replaceFirst(
          'resolved-ref: "$currentMotionSha"',
          'resolved-ref: "${'1' * 40}"',
        ),
        'packages:\n',
      ]) {
        expect(
          () => verifyPublishedMotionGraph(
            config,
            uri,
            bad,
            root,
            actualCommit: currentMotionSha,
          ),
          throwsA(isA<TestFailure>()),
        );
      }
      final wrong = <String, dynamic>{
        'packages': [
          {'name': 'motion_core', 'rootUri': '/fixture/local/motion_core'},
        ],
      };
      expect(
        () => verifyPublishedMotionGraph(
          wrong,
          uri,
          lock,
          root,
          actualCommit: currentMotionSha,
        ),
        throwsA(isA<TestFailure>()),
      );
    },
  );
  group('CORE-ADOPT-001 motion dependency contract', () {
    test('account and content packages cannot bypass the descriptor audit', () {
      final refs = _descriptorRefs(File('pubspec.yaml').readAsStringSync());
      expect(refs['motion_account'], _approvedSha);
      expect(refs['motion_content'], _approvedSha);
    });

    test('account and content packages cannot bypass the lock audit', () {
      final refs = _lockRefs(lockForAudit('pubspec.lock'));
      expect(refs['motion_account'], _LockRef(_approvedSha, _approvedSha));
      expect(refs['motion_content'], _LockRef(_approvedSha, _approvedSha));
    });

    test('every present descriptor ref is the approved Core SHA', () {
      expect(_descriptorRefs(File('pubspec.yaml').readAsStringSync()), {
        'motion_account': _approvedSha,
        'motion_content': _approvedSha,
        'motion_core': _approvedSha,
        'motion_camera': _approvedSha,
        'motion_entitlements': _approvedSha,
      });
      expect(
        _descriptorRefs(
          File('packages/jablab_engine/pubspec.yaml').readAsStringSync(),
        ),
        {'motion_core': _approvedSha},
      );
    });

    test(
      'every tracked lock ref and resolved-ref is the approved Core SHA',
      () {
        expect(_lockRefs(lockForAudit('pubspec.lock')), {
          'motion_account': _LockRef(_approvedSha, _approvedSha),
          'motion_content': _LockRef(_approvedSha, _approvedSha),
          'motion_core': _LockRef(_approvedSha, _approvedSha),
          'motion_camera': _LockRef(_approvedSha, _approvedSha),
          'motion_entitlements': _LockRef(_approvedSha, _approvedSha),
          // R3: native age-signal/app-transaction plugin, same Core SHA.
          'motion_platform_signals': _LockRef(_approvedSha, _approvedSha),
        });
        expect(_lockRefs(lockForAudit('packages/jablab_engine/pubspec.lock')), {
          'motion_core': _LockRef(_approvedSha, _approvedSha),
        });
      },
    );

    test('a historical f13 descriptor pin fails the approved-SHA contract', () {
      expect(
        _matchesApprovedDescriptor({'motion_core': _historicalSha}),
        isFalse,
      );
    });

    test(
      'mixed lock ref and resolved-ref fails even when one value is approved',
      () {
        expect(
          _matchesApprovedLock(_LockRef(_approvedSha, _historicalSha)),
          isFalse,
        );
      },
    );
  });
}

Map<String, String> _descriptorRefs(String yaml) {
  final refs = <String, String>{};
  for (final package in _motionPackages) {
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
  for (final package in _motionPackages) {
    final block = RegExp(
      '^  $package:\\n(?:(?!^  \\S).)*',
      multiLine: true,
      dotAll: true,
    ).firstMatch(yaml)?.group(0);
    if (block == null) continue;
    final ref = RegExp(
      r'^      ref: (\S+)',
      multiLine: true,
    ).firstMatch(block)?.group(1);
    final resolvedRef = RegExp(
      r'^      resolved-ref: (\S+)',
      multiLine: true,
    ).firstMatch(block)?.group(1);
    if (ref == null || resolvedRef == null) {
      throw StateError('$package lock bloğunda ref/resolved-ref eksik');
    }
    refs[package] = _LockRef(_yamlScalar(ref), _yamlScalar(resolvedRef));
  }
  return refs;
}

const _motionPackages = [
  'motion_account',
  'motion_camera',
  'motion_content',
  'motion_core',
  'motion_entitlements',
  'motion_platform_signals',
];

bool _matchesApprovedDescriptor(Map<String, String> refs) =>
    refs.isNotEmpty && refs.values.every((ref) => ref == _approvedSha);

bool _matchesApprovedLock(_LockRef ref) =>
    ref.ref == _approvedSha && ref.resolvedRef == _approvedSha;

String _yamlScalar(String value) => value.replaceAll(RegExp(r'^"|"$'), '');

class _LockRef {
  const _LockRef(this.ref, this.resolvedRef);

  final String ref;
  final String resolvedRef;

  @override
  bool operator ==(Object other) =>
      other is _LockRef && other.ref == ref && other.resolvedRef == resolvedRef;

  @override
  int get hashCode => Object.hash(ref, resolvedRef);

  @override
  String toString() => 'LockRef(ref: $ref, resolvedRef: $resolvedRef)';
}
