import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Translations match both authoritative source strings. Stored content,
/// anatomical directions and progress IDs keep their original values.
class AppLocalizations {
  const AppLocalizations(this.locale, this.messages, {this.loadFailed = false, this.complete = true});

  final Locale locale;
  final Map<String, Object?> messages;
  final bool loadFailed;
  final bool complete;

  static const supportedLocales = <Locale>[
    Locale('tr'), Locale('en'), Locale('es', '419'), Locale('pt', 'BR'),
    Locale('de'), Locale('fr'), Locale('ja'), Locale('ar'),
  ];
  static const delegate = _AppLocalizationsDelegate();
  static const _unavailable = (en: 'Text unavailable', tr: 'Metin kullanılamıyor');
  static final Map<String, String> _keys = <String, String>{};

  static String sourceKey(String en, String tr) {
    final source = '$en\u0000$tr';
    if (_keys.length > 4096) _keys.clear();
    return _keys.putIfAbsent(
      source, () => 's_${sha256.convert(utf8.encode(source))}',
    );
  }

  static Locale resolve(List<Locale>? preferred, Iterable<Locale> supported) {
    for (final locale in preferred ?? const <Locale>[]) {
      for (final candidate in supported) {
        if (candidate.toLanguageTag().toLowerCase() ==
            locale.toLanguageTag().toLowerCase()) return candidate;
      }
      for (final candidate in supported) {
        if (candidate.languageCode == locale.languageCode) return candidate;
      }
    }
    return const Locale('en');
  }

  String lookup(String en, String tr, {Map<String, Object> args = const {},
      String? pluralArg}) {
    final Object? entry = messages[sourceKey(en, tr)];
    String? translated;
    if (entry is String) translated = entry;
    if (entry is Map && pluralArg != null && args[pluralArg] is num) {
      final count = args[pluralArg]! as num;
      final category = Intl.pluralLogic<String>(count,
        zero: 'zero', one: 'one', two: 'two', few: 'few', many: 'many',
        other: 'other', locale: locale.toLanguageTag(),
        useExplicitNumberCases: false);
      final value = entry[category] ?? entry['other'];
      if (value is String) translated = value;
    }
    final fallback = locale.languageCode == 'tr' ? tr : en;
    final template = translated ?? fallback;
    final expected = _placeholders(en);
    if (!expected.every(args.containsKey)) {
      return lookup(_unavailable.en, _unavailable.tr);
    }
    final valid = setEquals(expected, _placeholders(template));
    final selected = valid ? template : fallback;
    return selected.replaceAllMapped(RegExp(r'\{(\w+)\}'), (match) {
      final value = args[match[1]];
      if (value == null) return match[0]!;
      if (value is num) {
        return NumberFormat.decimalPattern(locale.toLanguageTag()).format(value);
      }
      return value.toString();
    });
  }

  static Set<String> _placeholders(String value) => RegExp(r'\{(\w+)\}')
      .allMatches(value).map((match) => match[1]!).toSet();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((supported) => supported == locale);
  @override
  Future<AppLocalizations> load(Locale locale) async {
    try {
      final raw = jsonDecode(await rootBundle.loadString(
        'assets/i18n/${locale.toLanguageTag()}.json', cache: false));
      if (raw is! Map || raw['schemaVersion'] != 1 ||
          raw['locale'] != locale.toLanguageTag() || raw['messages'] is! Map) {
        throw const FormatException('Invalid localization bundle');
      }
      return AppLocalizations(locale,
        Map<String, Object?>.from(raw['messages'] as Map),
        complete: raw['complete'] == true);
    } on Object {
      return AppLocalizations(locale, const {}, loadFailed: true);
    }
  }
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Session-only choice. No account, system-language or store-currency mutation.
class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({required this.selected, required this.select,
    required super.child, super.key});
  final Locale? selected;
  final ValueChanged<Locale?> select;
  static AppLanguageScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) =>
      selected != oldWidget.selected;
}

abstract final class UiLanguage {
  static Locale locale(BuildContext context) =>
      Localizations.maybeLocaleOf(context) ??
      AppLocalizations.resolve(
        View.of(context).platformDispatcher.locales,
        AppLocalizations.supportedLocales,
      );
  static String tag(BuildContext context) => locale(context).toLanguageTag();
  static String choose(String languageCode, {required String en,
    required String tr}) => languageCode.toLowerCase() == 'tr' ? tr : en;
  static String text(BuildContext context, {required String en,
    required String tr}) => format(context, en: en, tr: tr);
  static String format(BuildContext context, {required String en,
    required String tr, Map<String, Object> args = const {}, String? pluralArg}) {
    final translations = Localizations.of<AppLocalizations>(
      context, AppLocalizations);
    return (translations ?? AppLocalizations(locale(context), const {}))
        .lookup(en, tr, args: args, pluralArg: pluralArg);
  }
  static bool isTurkish(BuildContext context) =>
      locale(context).languageCode == 'tr';
  static String number(BuildContext context, num value) =>
      NumberFormat.decimalPattern(tag(context)).format(value);
  static String duration(BuildContext context, int seconds) {
    if (seconds <= 0) return text(context,
      en: 'no time recorded', tr: 'süre kaydedilmedi');
    if (seconds < 60) return text(context,
      en: 'under a minute', tr: 'bir dakikadan az');
    final minutes = seconds ~/ 60;
    if (minutes < 60) return format(context,
      en: '{minutes} min', tr: '{minutes} dk', args: {'minutes': minutes});
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0
      ? format(context, en: '{hours}h', tr: '{hours} sa', args: {'hours': hours})
      : format(context, en: '{hours}h {minutes}m', tr: '{hours} sa {minutes} dk',
          args: {'hours': hours, 'minutes': remaining});
  }
  static String date(BuildContext context, DateTime value) =>
      DateFormat.yMMMd(tag(context)).format(value.toLocal());
}
