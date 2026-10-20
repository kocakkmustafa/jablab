// Authored locale identities, script-preserving resolution and authored cardinal contracts; glyph/device acceptance is separate.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/ui_language.dart';

// Fourteen-locale contract; the complete source package is a prerequisite.
void main() {
  test('fourteen authored locale tags retain script and regional identity', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.toLanguageTag()),
      <String>[
        'tr',
        'en',
        'es-419',
        'pt-BR',
        'de',
        'fr',
        'ja',
        'ar',
        'it',
        'ko',
        'id',
        'pl',
        'hi',
        'zh-Hans',
      ],
    );
    final chinese = AppLocalizations.supportedLocales.last;
    expect(chinese.languageCode, 'zh');
    expect(chinese.scriptCode, 'Hans');
    expect(chinese.countryCode, isNull);
  });

  test('Chinese script policy preserves the next preferred language', () {
    const hans = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    const hant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
    final supported = AppLocalizations.supportedLocales;
    for (final preferred in <Locale>[
      const Locale('zh'),
      const Locale('zh', 'CN'),
      const Locale('zh', 'SG'),
      hans,
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'TW',
      ),
    ]) {
      expect(AppLocalizations.resolve([preferred], supported), hans);
    }
    for (final preferred in <Locale>[
      hant,
      const Locale('zh', 'TW'),
      const Locale('zh', 'HK'),
      const Locale('zh', 'MO'),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'CN',
      ),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Latn'),
    ]) {
      expect(
        AppLocalizations.resolve([
          preferred,
          const Locale('fr', 'CA'),
        ], supported),
        const Locale('fr'),
      );
      expect(
        AppLocalizations.resolve([preferred], supported),
        const Locale('en'),
      );
    }
    for (final language in ['it', 'ko', 'id', 'pl', 'hi']) {
      expect(
        AppLocalizations.resolve([Locale(language, 'ZZ')], supported),
        Locale(language),
      );
    }
  });

  test('authored cardinal rules choose all new categories', () {
    const sourceEn = '{count} items';
    const sourceTr = '{count} öğe';
    final key = AppLocalizations.sourceKey(sourceEn, sourceTr);
    final forms = <String, String>{
      for (final category in ['zero', 'one', 'two', 'few', 'many', 'other'])
        category: '{count} $category',
    };
    final vectors = <Locale, Map<num, String>>{
      const Locale('it'): {0: 'other', 1: 'one', 2: 'other', 1000000: 'many'},
      const Locale('pl'): {
        0: 'many',
        1: 'one',
        2: 'few',
        4: 'few',
        5: 'many',
        12: 'many',
        14: 'many',
        21: 'many',
        22: 'few',
        24: 'few',
        101: 'many',
        102: 'few',
        1.5: 'other',
      },
      const Locale('hi'): {
        0: 'one',
        0.5: 'one',
        1: 'one',
        1.1: 'other',
        2: 'other',
      },
      const Locale('ko'): {0: 'other', 1: 'other', 2: 'other', 1.5: 'other'},
      const Locale('id'): {0: 'other', 1: 'other', 2: 'other', 1.5: 'other'},
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'): {
        0: 'other',
        1: 'other',
        2: 'other',
        1.5: 'other',
      },
    };
    for (final vector in vectors.entries) {
      final translations = AppLocalizations(vector.key, {key: forms});
      for (final count in vector.value.entries) {
        expect(
          translations.lookup(
            sourceEn,
            sourceTr,
            args: {'count': count.key},
            pluralArg: 'count',
          ),
          endsWith(' ${count.value}'),
          reason: '${vector.key.toLanguageTag()}: ${count.key}',
        );
      }
    }
  });

  test('Hindi cardinal boundaries use integer digits, not rounding', () {
    const en = 'items';
    const tr = 'öğe';
    final key = AppLocalizations.sourceKey(en, tr);
    final translations = AppLocalizations(const Locale('hi'), {
      key: {'one': 'one', 'other': 'other'},
    });
    // Fixed CLDR one: i = 0 or n = 1; n is absolute and i never rounds.
    const vectors = <(num, String)>[
      (0, 'one'),
      (0.0, 'one'),
      (0.1, 'one'),
      (0.49, 'one'),
      (0.5, 'one'),
      (0.9, 'one'),
      (0.999, 'one'),
      (1, 'one'),
      (1.0, 'one'),
      (1.001, 'other'),
      (1.1, 'other'),
      (1.5, 'other'),
      (2, 'other'),
      (10, 'other'),
      (-0.1, 'one'),
      (-0.5, 'one'),
      (-0.999, 'one'),
      (-1, 'one'),
      (-1.0, 'one'),
      (-1.001, 'other'),
      (-1.5, 'other'),
      (-2, 'other'),
      (-9223372036854775808, 'other'),
      (9223372036854775807, 'other'),
    ];
    for (final (count, category) in vectors) {
      expect(
        translations.lookup(en, tr, args: {'count': count}, pluralArg: 'count'),
        category,
        reason: 'hi cardinal: $count',
      );
    }
  });

  test('Hindi decimal text and plural fallback keep the amount', () {
    const en = '{count} items';
    const tr = '{count} öğe';
    final key = AppLocalizations.sourceKey(en, tr);
    final translations = AppLocalizations(const Locale('hi'), {
      key: {'one': '{count} one', 'other': '{count} other'},
    });
    // decimalPattern has no forced trailing zeros and keeps these <=3 decimals.
    const vectors = <(num, String)>[
      (0, '0 one'),
      (0.0, '0 one'),
      (0.1, '0.1 one'),
      (0.49, '0.49 one'),
      (0.5, '0.5 one'),
      (0.9, '0.9 one'),
      (0.999, '0.999 one'),
      (1, '1 one'),
      (1.0, '1 one'),
      (1.001, '1.001 other'),
      (1.5, '1.5 other'),
      (2, '2 other'),
      (10, '10 other'),
      (-0.5, '-0.5 one'),
      (-1, '-1 one'),
      (-1.001, '-1.001 other'),
      (-1.5, '-1.5 other'),
      (-2, '-2 other'),
    ];
    for (final (count, expected) in vectors) {
      expect(
        translations.lookup(en, tr, args: {'count': count}, pluralArg: 'count'),
        expected,
        reason: 'hi formatted: $count',
      );
    }
    final otherOnly = AppLocalizations(const Locale('hi'), {
      key: {'other': '{count} other'},
    });
    for (final (count, expected) in <(num, String)>[
      (0.5, '0.5 other'),
      (-0.5, '-0.5 other'),
    ]) {
      expect(
        otherOnly.lookup(en, tr, args: {'count': count}, pluralArg: 'count'),
        expected,
        reason: 'hi missing one form: $count',
      );
    }
  });
}
