import 'package:flutter/widgets.dart';

/// Selects the app's own Turkish/English copy from the device language.
/// Kept local until the shared Motion account and localization contracts land.
abstract final class UiLanguage {
  static String choose(
    String languageCode, {
    required String en,
    required String tr,
  }) => languageCode.toLowerCase() == 'tr' ? tr : en;

  static String text(
    BuildContext context, {
    required String en,
    required String tr,
  }) => choose(
    View.of(context).platformDispatcher.locale.languageCode,
    en: en,
    tr: tr,
  );

  static bool isTurkish(BuildContext context) =>
      View.of(context).platformDispatcher.locale.languageCode.toLowerCase() ==
      'tr';
}
