// Appearance palette and widget contracts; native render and platform accessibility require separate acceptance.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/app_preferences.dart';
import 'package:jablab/app/app_preferences_controller.dart';
import 'package:jablab/app/design_tokens.dart';
import 'package:jablab/app/live_honesty.dart';
import 'package:jablab/app/settings_page.dart';
import 'package:jablab/main.dart';

import 'localization_fixture.dart';

void main() {
  test(
    'canonical preference mapping retains Hans script rather than a country',
    () {
      const actuallyShipped = <Locale>[
        Locale('en'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ];
      final c = AppPreferencesCodec(
        supportedLocaleTags: actuallyShipped.map(
          (locale) => locale.toLanguageTag(),
        ),
      );
      final value = c.decode(
        c.encode(const AppPreferences(localeTag: 'zh-Hans')),
      );
      final selected = actuallyShipped.firstWhere(
        (locale) => locale.toLanguageTag() == value.localeTag,
      );
      expect(selected.scriptCode, 'Hans');
      expect(selected.countryCode, isNull);
      expect(
        () => c.encode(const AppPreferences(localeTag: 'zh-Hant')),
        throwsFormatException,
      );
    },
  );

  test(
    'subtree factories preserve each current brightness and immutable extension',
    () {
      for (final brightness in Brightness.values) {
        final base = jablabTheme(brightness);
        final palette = base.extension<JPalette>()!;
        for (final adapted in [
          jablabSessionThemeFor(base),
          jablabHonestyThemeFor(base),
          jablabIntervalTone(base),
        ]) {
          expect(adapted.brightness, brightness);
          expect(adapted.extension<JPalette>(), same(palette));
          expect(base.extension<JPalette>(), same(palette));
        }
        expect(
          jablabSessionThemeFor(base).textTheme.titleLarge!.color,
          palette.ink,
        );
        expect(
          jablabHonestyThemeFor(base).cardTheme.color,
          palette.glassResting,
        );
        expect(
          jablabIntervalTone(base).textTheme.titleLarge!.color,
          palette.observation,
        );
        expect(
          LiveHonestyBucket.yours.themeFor(base).colorScheme.error,
          palette.observation,
        );
        expect(
          LiveHonestyBucket.ours.themeFor(base).colorScheme.error,
          palette.inkMuted,
        );
        expect(
          LiveHonestyBucket.none.themeFor(base).colorScheme.error,
          palette.inkSubtle,
        );
        expect(LiveHonestyBucket.none.icon, Icons.videocam_off_outlined);
      }
    },
  );

  test(
    'typography resolves current palette without modifying dark compatibility styles',
    () {
      final legacy = JText.pageTitle;
      final light = JTypography(JPalette.light);
      final dark = JTypography(JPalette.dark);
      expect(light.pageTitle.color, JPalette.light.ink);
      expect(dark.pageTitle.color, JPalette.dark.ink);
      expect(light.pageTitle.fontFamily, legacy.fontFamily);
      expect(light.pageTitle.fontSize, legacy.fontSize);
      expect(light.clock.fontFeatures, JText.clock.fontFeatures);
      expect(light.label.color, JPalette.light.observation);
      expect(JText.pageTitle, same(legacy));
      expect(JPalette.dark.ink, isNot(JPalette.light.ink));
    },
  );

  test(
    'proposed required text roles meet local4.5 target on uniform composed panels',
    () {
      for (final p in [JPalette.dark, JPalette.light]) {
        for (final fill in [
          const Color(0x00000000),
          p.glassResting,
          p.glassObservation,
          p.glassJudgement,
        ]) {
          final background = Color.alphaBlend(fill, p.ground);
          for (final foreground in [p.ink, p.inkMuted, p.observation]) {
            expect(
              _contrast(Color.alphaBlend(foreground, background), background),
              greaterThanOrEqualTo(4.5),
            );
          }
        }
        expect(_contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(p.onJudgement, p.judgement),
          greaterThanOrEqualTo(4.5),
        );
      }
      // Does not measure blur, gradient all pixels, camera, glyph raster or device.
    },
  );

  testWidgets(
    'loaded preference is the startup failure root first-frame input',
    (tester) async {
      final c = AppPreferencesCodec(supportedLocaleTags: ['tr', 'en', 'ar']);
      final controller = AppPreferencesController(
        codec: c,
        store: _ImmediateStore(
          const AppPreferences(theme: AppThemePreference.dark, localeTag: 'ar'),
        ),
      );
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pumpWidget(
        JabLabAccountStartupFailure(preferences: controller),
      );
      final root = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(root.themeMode, ThemeMode.dark);
      expect(root.locale, const Locale('ar'));
      await settleTestLocalizations(tester, expectedLocale: const Locale('ar'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
      expect(
        Theme.of(
          tester.element(find.byKey(const Key('jablab.accountStartupFailure'))),
        ).brightness,
        Brightness.dark,
      );
      controller.selectTheme(AppThemePreference.light);
      await tester.pump();
      final changed = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(changed.themeMode, ThemeMode.light);
      expect(changed.locale, const Locale('ar'));
    },
  );

  testWidgets(
    'settings uses context colors and exposes failure without losing chosen mode',
    (tester) async {
      final store = _FailThenSaveStore();
      final controller = AppPreferencesController(
        codec: AppPreferencesCodec(supportedLocaleTags: ['en', 'tr']),
        store: store,
      );
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pumpWidget(
        AppPreferencesScope(
          controller: controller,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => MaterialApp(
              theme: jablabTheme(Brightness.light),
              darkTheme: jablabTheme(Brightness.dark),
              themeMode: controller.value.theme == AppThemePreference.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              themeAnimationDuration: Duration.zero,
              home: SettingsPage(onOpenWhyNot: () {}, excludedCount: 12),
            ),
          ),
        ),
      );
      controller.selectTheme(AppThemePreference.dark);
      await tester.pump();
      await tester.pump();
      expect(controller.value.theme, AppThemePreference.dark);
      expect(controller.savePhase, PreferencesSavePhase.failed);
      expect(
        find.byKey(const Key('settings.preferences.status')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings.preferences.retry')),
        findsOneWidget,
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        JPalette.dark.ground,
      );
      await tester.ensureVisible(
        find.byKey(const Key('settings.preferences.retry')),
      );
      await tester.tap(find.byKey(const Key('settings.preferences.retry')));
      await tester.pump();
      expect(store.writes.last.theme, AppThemePreference.dark);
      expect(controller.savePhase, PreferencesSavePhase.saved);
    },
  );
}

double _contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
}

class _ImmediateStore implements AppPreferencesStore {
  _ImmediateStore(this.value);
  AppPreferences value;
  @override
  bool get persistent => true;
  @override
  Future<PreferencesReadResult> read() async =>
      PreferencesReadResult(PreferencesReadKind.loaded, value);
  @override
  Future<PreferencesWriteResult> write(AppPreferences next) async {
    value = next;
    return const PreferencesWriteResult(PreferencesWriteKind.committed);
  }
}

class _FailThenSaveStore implements AppPreferencesStore {
  final writes = <AppPreferences>[];
  @override
  bool get persistent => true;
  @override
  Future<PreferencesReadResult> read() async =>
      const PreferencesReadResult(PreferencesReadKind.missing);
  @override
  Future<PreferencesWriteResult> write(AppPreferences value) async {
    writes.add(value);
    return PreferencesWriteResult(
      writes.length == 1
          ? PreferencesWriteKind.failed
          : PreferencesWriteKind.committed,
    );
  }
}
