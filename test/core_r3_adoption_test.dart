import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/main.dart' show jablabCameraCoachingAvailable;
import 'package:motion_account/motion_account.dart';

/// Core R3 (`f43d71a`) adoption: the split sales/camera flags, the camera-only
/// lesson-start gate and the Declared Age Range entitlement that lets the
/// store age signal reach Core.
void main() {
  String source(String path) => File(path)
      .readAsStringSync()
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  test('sales follow Core while camera coaching stays closed', () {
    expect(motionSubscriptionSalesAvailable, isTrue);
    expect(motionCameraCoachingAvailable, isFalse);
    expect(jablabCameraCoachingAvailable, motionCameraCoachingAvailable);
  });

  test('main binds camera to the camera flag and paid lessons to sales', () {
    final main = source('lib/main.dart');
    expect(main, contains('salesOpen: motionSubscriptionSalesAvailable'));
    expect(main, contains('salesAvailable: motionSubscriptionSalesAvailable'));
    expect(
      main,
      contains(
        'beforeLessonStart: (lessonContext) => '
        'requireMotionCameraAccess(',
      ),
    );
    expect(
      'requireMotionPaidAccess('.allMatches(main),
      hasLength(1),
      reason: 'only the locked-lesson gate may ask for a membership',
    );
  });

  // Core R4 (`0d29d1b`) + K-2 (2026-10-27): all five apps leave teen
  // purchases to the store's family controls. Every membership entry names
  // the policy, so a missing argument cannot fall back to Core's default.
  test('R4/K-2: every membership entry uses store family controls', () {
    const String policy =
        'teenPurchasePolicy: MotionTeenPurchasePolicy.storeFamilyControls';
    final Map<String, int> expected = <String, int>{
      // requireMotionPaidAccess, its MotionMembershipPage builder and
      // requireMotionCameraAccess.
      'lib/main.dart': 3,
      // MotionAccountPage.
      'lib/app/owner_bound_account_page.dart': 1,
    };
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = source(entity.path);
      expect(
        'teenPurchasePolicy:'.allMatches(text).length,
        expected[entity.path] ?? 0,
        reason: entity.path,
      );
      expect(
        policy.allMatches(text).length,
        expected[entity.path] ?? 0,
        reason: entity.path,
      );
      expect(text, isNot(contains('parentalConsentRequired')));
    }
  });

  test('no deprecated Core flag or parameter is left in the app', () {
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = source(entity.path);
      expect(
        text,
        isNot(contains('motionPaidFeaturesAvailable')),
        reason: entity.path,
      );
      expect(
        text,
        isNot(contains('paidFeaturesAvailable:')),
        reason: entity.path,
      );
    }
  });

  test('Runner carries the Declared Age Range entitlement in every config', () {
    final entitlements = File(
      'ios/Runner/Runner.entitlements',
    ).readAsStringSync();
    expect(
      entitlements,
      matches(
        RegExp(
          r'<key>com\.apple\.developer\.declared-age-range</key>'
          r'\s*<true/>',
        ),
      ),
    );
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(
      'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'.allMatches(
        project,
      ),
      hasLength(3),
    );
  });
}
