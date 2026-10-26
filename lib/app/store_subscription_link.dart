import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store-side subscription management (Apple 3.1.2 / Play: cancel and change
/// plans where the subscription was bought). JabLab never cancels itself.
///
/// The Play link names the package only: the account page does not know
/// which product (individual or Motion+) the member holds, and Play lists
/// every subscription of the app on that page.
Uri storeSubscriptionManagementUri(TargetPlatform platform) =>
    platform == TargetPlatform.android
    ? Uri.parse(
        'https://play.google.com/store/account/subscriptions'
        '?package=com.yulalab.jablab',
      )
    : Uri.parse('https://apps.apple.com/account/subscriptions');

/// Opens the store page outside the app; false when it could not be opened
/// (the account page then says so with Core's own message).
Future<bool> openStoreSubscriptionManagement({
  TargetPlatform? platform,
  Future<bool> Function(Uri uri)? launch,
}) async {
  final Uri uri = storeSubscriptionManagementUri(
    platform ?? defaultTargetPlatform,
  );
  try {
    return await (launch ??
        (Uri target) =>
            launchUrl(target, mode: LaunchMode.externalApplication))(uri);
  } on Object {
    // The store app or a browser may be unavailable on this device.
    return false;
  }
}
