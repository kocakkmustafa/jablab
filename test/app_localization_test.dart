import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/ui_language.dart';
import 'package:jablab/app/settings_page.dart';

import 'localization_fixture.dart';
import 'app_pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preferred list and regional variants resolve to authored locales', () {
    const supported = AppLocalizations.supportedLocales;
    expect(
      AppLocalizations.resolve(const [
        Locale('xx'),
        Locale('fr', 'CA'),
      ], supported),
      const Locale('fr'),
    );
    expect(
      AppLocalizations.resolve(const [Locale('es', 'MX')], supported),
      const Locale('es', '419'),
    );
    expect(
      AppLocalizations.resolve(const [Locale('pt', 'PT')], supported),
      const Locale('pt', 'BR'),
    );
    expect(AppLocalizations.resolve(const [], supported), const Locale('en'));
  });

  test(
    'changed sources and malformed placeholders use authoritative fallback',
    () {
      expect(
        AppLocalizations.sourceKey('Back', 'Geri'),
        's_6481143dce107b9049197eefc57cfa2069bbbe9fd8cfc18413e0854e9d640562',
      );
      final key = AppLocalizations.sourceKey('Read {count}', 'Oku {count}');
      final translations = AppLocalizations(const Locale('fr'), {
        key: 'Lire {count}',
      });
      expect(
        translations.lookup('Read {count}', 'Oku {count}', args: {'count': 7}),
        'Lire 7',
      );
      expect(
        translations.lookup(
          'Read now {count}',
          'Şimdi oku {count}',
          args: {'count': 7},
        ),
        'Read now 7',
      );
      final malformed = AppLocalizations(const Locale('fr'), {
        key: 'Lire {other}',
      });
      expect(
        malformed.lookup('Read {count}', 'Oku {count}', args: {'count': 7}),
        'Read 7',
      );
      expect(
        const AppLocalizations(Locale('tr'), {}).lookup('Read', 'Oku'),
        'Oku',
      );
      expect(
        translations.lookup('Read {count}', 'Oku {count}'),
        'Text unavailable',
      );
    },
  );

  test('CLDR categories include Arabic six forms and French zero', () {
    final key = AppLocalizations.sourceKey('{count} items', '{count} öğe');
    final forms = {
      for (final category in ['zero', 'one', 'two', 'few', 'many', 'other'])
        category: '{count} $category',
    };
    final arabic = AppLocalizations(const Locale('ar'), {key: forms});
    for (final value in {
      0: 'zero',
      1: 'one',
      2: 'two',
      3: 'few',
      11: 'many',
      100: 'other',
    }.entries) {
      expect(
        arabic.lookup(
          '{count} items',
          '{count} öğe',
          args: {'count': value.key},
          pluralArg: 'count',
        ),
        endsWith(value.value),
      );
    }
    final french = AppLocalizations(const Locale('fr'), {key: forms});
    expect(
      french.lookup(
        '{count} items',
        '{count} öğe',
        args: {'count': 0},
        pluralArg: 'count',
      ),
      endsWith('one'),
    );
    final japanese = AppLocalizations(const Locale('ja'), {key: forms});
    expect(
      japanese.lookup(
        '{count} items',
        '{count} öğe',
        args: {'count': 1},
        pluralArg: 'count',
      ),
      endsWith('other'),
    );
  });

  test(
    'all packaged locales match the exact source key set and placeholders',
    () {
      final source =
          jsonDecode(File('l10n/source_catalog.json').readAsStringSync())
              as Map;
      final entries = {
        for (final e in source['entries'] as List) e['id'] as String: e as Map,
      };
      for (final locale in AppLocalizations.supportedLocales) {
        final bundle =
            jsonDecode(
                  File(
                    'assets/i18n/${locale.toLanguageTag()}.json',
                  ).readAsStringSync(),
                )
                as Map;
        final messages = bundle['messages'] as Map;
        expect(bundle['complete'], isTrue, reason: locale.toLanguageTag());
        expect(
          messages.keys.toSet(),
          entries.keys.toSet(),
          reason: locale.toLanguageTag(),
        );
        for (final message in messages.entries) {
          final expected = (entries[message.key]!['placeholders'] as List)
              .toSet();
          final values = message.value is Map
              ? (message.value as Map).values
              : [message.value];
          for (final value in values) {
            expect(
              RegExp(
                r'\{(\w+)\}',
              ).allMatches(value as String).map((m) => m[1]).toSet(),
              expected,
              reason: '${locale.toLanguageTag()} ${message.key}',
            );
          }
        }
      }
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    for (final width in [320.0, 375.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'settings ${locale.toLanguageTag()} $width scale $scale direction and overflow',
          (tester) async {
            tester.view.physicalSize = Size(width, 812);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              AppLanguageScope(
                selected: locale,
                select: (_) {},
                child: MaterialApp(
                  locale: locale,
                  supportedLocales: testSupportedLocales,
                  localizationsDelegates: testLocalizationDelegates,
                  localeListResolutionCallback: resolveTestLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: SettingsPage(onOpenWhyNot: () {}, excludedCount: 12),
                ),
              ),
            );
            await settleUntil(tester, find.byType(SettingsPage));
            await tester.pumpAndSettle();
            final context = tester.element(find.byType(SettingsPage));
            expect(UiLanguage.tag(context), locale.toLanguageTag());
            expect(
              Directionality.of(context),
              locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );
            for (var i = 0; i < 10; i++) {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -350),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  }

  testWidgets(
    'explicit locale overrides device and live change rebuilds route',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = <Locale>[
        const Locale('tr'),
      ];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      expect(tester.binding.platformDispatcher.locales, <Locale>[
        const Locale('tr'),
      ]);
      final locale = ValueNotifier<Locale>(const Locale('fr'));
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (context, value, _) => MaterialApp(
            locale: value,
            supportedLocales: testSupportedLocales,
            localizationsDelegates: testLocalizationDelegates,
            localeListResolutionCallback: resolveTestLocales,
            home: Builder(
              builder: (context) => Text(
                UiLanguage.text(context, en: 'Back', tr: 'Geri'),
                key: const Key('copy'),
              ),
            ),
          ),
        ),
      );
      await settleUntil(tester, find.byKey(const Key('copy')));
      await tester.pumpAndSettle();
      expect(
        UiLanguage.tag(tester.element(find.byKey(const Key('copy')))),
        'fr',
      );
      expect(find.text('Geri'), findsNothing);
      locale.value = const Locale('ar');
      for (var i = 0; i < 40; i++) {
        await tester.pump();
        if (UiLanguage.tag(tester.element(find.byKey(const Key('copy')))) ==
            'ar')
          break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
      }
      await tester.pumpAndSettle();
      expect(
        UiLanguage.tag(tester.element(find.byKey(const Key('copy')))),
        'ar',
      );
      expect(
        Directionality.of(tester.element(find.byKey(const Key('copy')))),
        TextDirection.rtl,
      );
    },
  );
}
