// Authored locale identities, script-preserving resolution and Intl cardinal contracts; glyph/device acceptance is separate.
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

  test('resolved intl rules choose all new cardinal categories', () {
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
}
