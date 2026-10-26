import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/store_subscription_link.dart';

void main() {
  test('each store opens its own subscription page for JabLab', () {
    expect(
      storeSubscriptionManagementUri(TargetPlatform.iOS).toString(),
      'https://apps.apple.com/account/subscriptions',
    );
    expect(
      storeSubscriptionManagementUri(TargetPlatform.android).toString(),
      'https://play.google.com/store/account/subscriptions'
      '?package=com.yulalab.jablab',
    );
  });

  test(
    'opening launches exactly the platform page and absorbs failure',
    () async {
      final List<Uri> opened = <Uri>[];
      await openStoreSubscriptionManagement(
        platform: TargetPlatform.android,
        launch: (Uri uri) async {
          opened.add(uri);
          return true;
        },
      );
      await openStoreSubscriptionManagement(
        platform: TargetPlatform.iOS,
        launch: (Uri uri) async {
          opened.add(uri);
          throw StateError('no handler');
        },
      );
      expect(opened, <Uri>[
        storeSubscriptionManagementUri(TargetPlatform.android),
        storeSubscriptionManagementUri(TargetPlatform.iOS),
      ]);
    },
  );

  test('production wires the store link into the account page', () {
    final String main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('onManageSubscription: () =>'));
    expect(main, contains('openStoreSubscriptionManagement()'));
  });
}
