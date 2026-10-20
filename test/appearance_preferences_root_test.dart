// Real JabLabApp, local preference IO and Settings contracts; first mounted Flutter input is not native first-raster timing.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/app_preferences.dart';
import 'package:jablab/app/app_preferences_controller.dart';
import 'package:jablab/app/app_preferences_store.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/settings_page.dart';
import 'package:jablab/app/solo_boxing_course_page.dart';
import 'package:jablab/app/ui_language.dart';

import 'app_pump.dart';
import 'localization_fixture.dart';

const _statusKey = Key('settings.preferences.status');
const _saveRetryKey = Key('settings.preferences.retry');

AppPreferencesCodec _codec() => AppPreferencesCodec(
  supportedLocaleTags: AppLocalizations.supportedLocales.map(
    (locale) => locale.toLanguageTag(),
  ),
);

// Starts IO in the fake zone, then advances both real IO and fake continuations.
// Neither runAsync/pumpWidget nor another guarded pump belongs inside action.
Future<T> _io<T>(
  WidgetTester tester,
  String stage,
  Future<T> Function() action,
) async {
  debugPrintSynchronously('JABLAB_APPEARANCE_ROOT $stage/begin');
  bool settled = false;
  T? value;
  Object? error;
  StackTrace? stack;
  action().then((result) {
    value = result;
    settled = true;
  }, onError: (Object failure, StackTrace trace) {
    error = failure;
    stack = trace;
    settled = true;
  });
  for (int i = 0; i < 80 && !settled; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  expect(settled, isTrue, reason: '$stage: bounded dual-clock IO did not settle');
  if (error != null) {
    Error.throwWithStackTrace(error!, stack!);
  }
  debugPrintSynchronously('JABLAB_APPEARANCE_ROOT $stage/done');
  return value as T;
}

Future<void> _settle(WidgetTester tester) =>
    tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (int i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  expect(finder, findsOneWidget, reason: 'Positive route/resource readiness');
}

Future<void> _choose<T>(
  WidgetTester tester,
  Key key,
  T value,
) async {
  final control = find.byKey(key);
  expect(control, findsOneWidget);
  await tester.ensureVisible(control);
  await tester.tap(control);
  await _settle(tester);
  final choice = find.byWidgetPredicate(
    (widget) => widget is DropdownMenuItem<T> && widget.value == value,
  ).last;
  expect(choice, findsOneWidget);
  await tester.ensureVisible(choice);
  await tester.tap(choice);
  await _settle(tester);
}

void _expectLoaded(WidgetTester tester, Finder target, Locale expected) {
  expect(target, findsOneWidget);
  final context = tester.element(target);
  final resources = Localizations.of<AppLocalizations>(
    context,
    AppLocalizations,
  );
  expect(resources, isNotNull, reason: 'Real delegate, not lookup fallback');
  expect(resources!.locale, expected);
  expect(resources.complete, isTrue);
  expect(resources.loadFailed, isFalse);
  expect(Localizations.localeOf(context), expected);
  expect(Directionality.of(context), expected.languageCode == 'ar'
      ? TextDirection.rtl : TextDirection.ltr);
}

// Faults affect preference IO only. Content, courses, assets, owner lifetimes
// and the app/navigator remain real. Non-committed injected results never write.
class _RootStore implements AppPreferencesStore {
  _RootStore(this.disk);
  final FileAppPreferencesStore disk;
  Future<PreferencesReadResult> Function()? nextRead;
  Future<PreferencesWriteResult> Function(AppPreferences)? nextWrite;
  final payloads = <AppPreferences>[];
  final _pending = <Future<void>>[];
  int reads = 0;

  @override
  bool get persistent => true;

  @override
  Future<PreferencesReadResult> read() {
    reads++;
    final action = nextRead;
    nextRead = null;
    return action == null ? disk.read() : action();
  }

  @override
  Future<PreferencesWriteResult> write(AppPreferences value) {
    payloads.add(value);
    final action = nextWrite;
    nextWrite = null;
    final result = action == null ? disk.write(value) : action(value);
    _pending.add(result.then<void>((_) {}));
    return result;
  }

  Future<void> drain() => Future.wait<void>(_pending.toList()).then((_) {});
}

class _RootHarness {
  _RootHarness(this.tester, this.support, this.history, this.marker) {
    _resources();
  }

  final WidgetTester tester;
  final Directory support;
  final Directory history;
  final File marker;
  final owner = ValueNotifier<String?>(null);
  final controllers = <AppPreferencesController>[];
  final stores = <_RootStore>[];
  late OwnerResourceRegistry owners;
  late ContentRepository repository;
  late JabLabApp root;
  int directoryReads = 0;
  bool _retired = false;
  bool _markerReady = false;

  static Future<_RootHarness> create(WidgetTester tester) async {
    final support = await _io<Directory>(tester, 'temp.create',
      () => Directory.systemTemp.createTemp('jablab-appearance-root-'));
    // Register owned cleanup before the remaining filesystem setup can fail.
    final history = Directory('${support.path}/history');
    final marker = File('${history.path}/unrelated-owned-marker.txt');
    final result = _RootHarness(tester, support, history, marker);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(result.close);
    await tester.binding.setSurfaceSize(const Size(375, 900));
    await _io<Directory>(tester, 'history.create', history.create);
    await _io<File>(tester, 'marker.write',
      () => marker.writeAsString('owned-marker-keep'));
    result._markerReady = true;
    return result;
  }

  void _resources() {
    owners = OwnerResourceRegistry();
    repository = ContentRepository(
      ownerRegistry: owners,
      historyDirectoryProvider: () async {
        directoryReads++;
        return history;
      },
    );
    _retired = false;
  }

  FileAppPreferencesStore disk() => FileAppPreferencesStore(
    codec: _codec(),
    supportDirectory: () async => support,
  );

  _RootStore store() {
    final result = _RootStore(disk());
    stores.add(result);
    return result;
  }

  AppPreferencesController controller(_RootStore store) {
    final result = AppPreferencesController(store: store, codec: _codec());
    controllers.add(result);
    return result;
  }

  Future<void> load(AppPreferencesController preferences) =>
      _io<void>(tester, 'preferences.load', preferences.load);

  Future<void> mount(AppPreferencesController preferences) async {
    if (_retired) {
      _resources();
    }
    root = JabLabApp(
      repository: repository,
      onboarding: const OnboardingStore(seenOverride: true),
      accountUserId: owner,
      preferences: preferences,
    );
    // Keep the established real-root mount recipe; no nested guarded pumping.
    await tester.runAsync(() => tester.pumpWidget(root));
  }

  Future<void> ready() async {
    await settleAppLoad(tester);
    await _settle(tester);
    expect(directoryReads, greaterThan(0));
    expect(owners.capture(null).isActive, isTrue);
    expect(owners.capture(null).journalWrites.isActive, isTrue);
    expect(tester.takeException(), isNull);
  }

  Future<void> settings() async {
    final open = find.byKey(const Key('settings-button'));
    expect(open, findsOneWidget);
    await tester.tap(open);
    await _settle(tester);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byKey(const Key('settings.appearance')), findsOneWidget);
  }

  Future<void> drain() async {
    for (final store in stores) {
      await _io<void>(tester, 'preferences.drain', store.drain);
    }
    await tester.pump();
  }

  Future<void> unmount() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await drain();
    await _io<void>(tester, 'owners.retire', owners.retireAll);
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
    stores.clear();
    _retired = true;
  }

  Future<void> close() async {
    // No deletion if write/owner drain failed or remained pending.
    await unmount();
    if (_markerReady) {
      expect(await _io<String>(tester, 'marker.read', marker.readAsString),
        'owned-marker-keep');
    }
    await _io<FileSystemEntity>(tester, 'temp.delete',
      () => support.delete(recursive: true));
    owner.dispose();
  }
}

void main() {
  testWidgets('ROOT-PREF-01 disk locale and theme feed first mounted MaterialApp',
    (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final h = await _RootHarness.create(tester);
    const saved = AppPreferences(theme: AppThemePreference.light, localeTag: 'ar');
    expect((await _io<PreferencesWriteResult>(tester, 'seed.write',
      () => h.disk().write(saved))).kind, PreferencesWriteKind.committed);
    final store = h.store();
    final c = h.controller(store);
    await h.load(c);
    expect(c.readPhase, PreferencesReadPhase.loaded);
    expect(c.value, saved);
    await h.mount(c);
    // First mounted Flutter root input; not localized body/native splash SLA.
    final first = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(first.locale, const Locale('ar'));
    expect(first.themeMode, ThemeMode.light);
    expect(first.theme!.brightness, Brightness.light);
    expect(first.darkTheme!.brightness, Brightness.dark);
    expect(store.payloads, isEmpty);
    await h.ready();
    await h.settings();
    _expectLoaded(tester, find.byType(SettingsPage), const Locale('ar'));
    expect(Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.light);
    expect(c.dirty, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ROOT-PREF-02 actual settings pair persists into a fresh root',
    (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = await _RootHarness.create(tester);
    final store = h.store();
    final c = h.controller(store);
    await h.load(c);
    await h.mount(c);
    await h.ready();
    await h.settings();
    await _choose<Locale>(tester, const Key('settings.language'), const Locale('pl'));
    await settleTestLocalizations(tester, expectedLocale: const Locale('pl'));
    await _choose<AppThemePreference>(tester, const Key('settings.appearance'),
      AppThemePreference.dark);
    await h.drain();
    const chosen = AppPreferences(theme: AppThemePreference.dark, localeTag: 'pl');
    expect(c.value, chosen);
    expect(store.payloads, const [
      AppPreferences(localeTag: 'pl'), chosen,
    ]);
    expect(c.savePhase, PreferencesSavePhase.saved);
    expect(c.dirty, isFalse);
    expect(find.byKey(_statusKey), findsOneWidget);
    final oldState = tester.state(find.byType(JabLabApp));
    await h.unmount();
    final reopened = h.store();
    final fresh = h.controller(reopened);
    await h.load(fresh);
    expect(fresh.value, chosen);
    await h.mount(fresh);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('pl'));
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark);
    await h.ready();
    await h.settings();
    expect(identical(oldState, tester.state(find.byType(JabLabApp))), isFalse);
    _expectLoaded(tester, find.byType(SettingsPage), const Locale('pl'));
    expect(tester.widget<DropdownButton<AppThemePreference>>(
      find.byKey(const Key('settings.appearance'))).value, AppThemePreference.dark);
    expect(reopened.payloads, isEmpty, reason: 'Restart must not auto-save');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ROOT-PREF-03 platform order and Hant fallback preserve admitted course',
    (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('xx'), Locale('fr', 'CA')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = await _RootHarness.create(tester);
    final store = h.store();
    final c = h.controller(store);
    await h.load(c);
    await h.mount(c);
    await h.ready();
    final rootState = tester.state(find.byType(JabLabApp));
    final open = find.byKey(const Key('open-solo-boxing-course'));
    expect(open, findsOneWidget);
    await tester.ensureVisible(open);
    await tester.tap(open);
    await _until(tester, find.byKey(const Key('solo-course-progress')));
    await _settle(tester);
    final route = find.byType(SoloBoxingCoursePage);
    _expectLoaded(tester, route, const Locale('fr'));
    final routeState = tester.state(route);
    final navigator = tester.state(find.byType(Navigator).first);
    final admission = tester.widget<SoloBoxingCoursePage>(route).resourceAdmission;
    expect(admission, isNotNull);
    expect(admission!.value, isTrue);
    final lifetime = h.owners.capture(null);
    final reads = h.directoryReads;
    int lifetimeChanges = 0;
    void changed() { lifetimeChanges++; }
    lifetime.active.addListener(changed);
    addTearDown(() => lifetime.active.removeListener(changed));
    final variants = <(List<Locale>, Locale)>[
      ([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'), const Locale('ar')], const Locale('ar')),
      ([const Locale('zh', 'TW'), const Locale('ko')], const Locale('ko')),
      ([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')], const Locale('en')),
      ([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN')], const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')),
      ([const Locale('xx')], const Locale('en')),
    ];
    for (final (preferences, expected) in variants) {
      tester.platformDispatcher.localesTestValue = preferences;
      await settleTestLocalizations(tester, expectedLocale: expected);
      await _settle(tester);
      _expectLoaded(tester, route, expected);
      expect(identical(tester.widget<JabLabApp>(find.byType(JabLabApp)), h.root), isTrue);
      expect(identical(tester.state(find.byType(JabLabApp)), rootState), isTrue);
      expect(identical(tester.state(route), routeState), isTrue);
      expect(identical(tester.state(find.byType(Navigator).first), navigator), isTrue);
      expect(identical(tester.widget<SoloBoxingCoursePage>(route).resourceAdmission,
        admission), isTrue);
      expect(admission.value, isTrue);
      expect(identical(h.owners.capture(null), lifetime), isTrue);
      expect(lifetime.journalWrites.isActive, isTrue);
      expect(lifetimeChanges, 0);
      expect(h.directoryReads, reads, reason: 'Presentation must not reopen owner IO');
      expect(c.value.localeTag, isNull);
      expect(store.payloads, isEmpty);
      expect(tester.takeException(), isNull);
    }
    // This is actual JabLabApp continuity. It does not cover a blocked Core gate.
  });

  testWidgets('ROOT-PREF-04 system brightness updates same settings route',
    (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final h = await _RootHarness.create(tester);
    final store = h.store();
    final c = h.controller(store);
    await h.load(c);
    await h.mount(c);
    await h.ready();
    await h.settings();
    final settingsElement = tester.element(find.byType(SettingsPage));
    final rootState = tester.state(find.byType(JabLabApp));
    final lifetime = h.owners.capture(null);
    final reads = h.directoryReads;
    for (final brightness in [Brightness.dark, Brightness.light, Brightness.dark]) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      await _settle(tester);
      expect(Theme.of(tester.element(find.byType(SettingsPage))).brightness, brightness);
      expect(identical(tester.element(find.byType(SettingsPage)), settingsElement), isTrue);
      expect(identical(tester.state(find.byType(JabLabApp)), rootState), isTrue);
      expect(identical(h.owners.capture(null), lifetime), isTrue);
      expect(h.directoryReads, reads);
    }
    expect(store.payloads, isEmpty, reason: 'System events are not user edits');
    await _choose<AppThemePreference>(tester, const Key('settings.appearance'),
      AppThemePreference.light);
    await h.drain();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await _settle(tester);
    expect(Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.light);
    expect(c.value.theme, AppThemePreference.light);
    expect(store.payloads, const [AppPreferences(theme: AppThemePreference.light)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ROOT-PREF-05 failed read retry keeps edited UI and save retry payload',
    (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = await _RootHarness.create(tester);
    final store = h.store();
    store.nextRead = () async =>
      const PreferencesReadResult(PreferencesReadKind.unavailable);
    final c = h.controller(store);
    await h.load(c);
    await h.mount(c);
    await h.ready();
    await h.settings();
    expect(find.textContaining('Saved preferences could not be fully read.'), findsOneWidget);
    expect(store.payloads, isEmpty);
    final writing = Completer<PreferencesWriteResult>();
    store.nextWrite = (_) => writing.future;
    await _choose<AppThemePreference>(tester, const Key('settings.appearance'),
      AppThemePreference.dark);
    expect(c.dirty, isTrue);
    final late = Completer<PreferencesReadResult>();
    store.nextRead = () => late.future;
    // The current candidate has no read-Retry UI button. Exercise its public
    // load API, while all selected controls and save-Retry remain actual UI.
    final retryRead = c.load();
    late.complete(const PreferencesReadResult(PreferencesReadKind.loaded,
      AppPreferences(theme: AppThemePreference.light, localeTag: 'fr')));
    await _io<void>(tester, 'read.retry', () => retryRead);
    expect(c.readPhase, PreferencesReadPhase.ignoredAfterEdit);
    expect(c.value, const AppPreferences(theme: AppThemePreference.dark));
    expect(tester.widget<DropdownButton<AppThemePreference>>(
      find.byKey(const Key('settings.appearance'))).value, AppThemePreference.dark);
    expect(Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark);
    _expectLoaded(tester, find.byType(SettingsPage), const Locale('en'));
    writing.complete(const PreferencesWriteResult(PreferencesWriteKind.failed));
    await h.drain();
    expect(find.textContaining('could not be saved.'), findsOneWidget);
    expect(find.text('Saved on this device.'), findsNothing);
    final retry = find.byKey(_saveRetryKey);
    expect(retry, findsOneWidget);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await h.drain();
    expect(store.payloads, const [
      AppPreferences(theme: AppThemePreference.dark),
      AppPreferences(theme: AppThemePreference.dark),
    ]);
    expect(c.savePhase, PreferencesSavePhase.saved);
    expect(c.dirty, isFalse);
    expect(find.text('Saved on this device.'), findsOneWidget);
    expect(find.byKey(_saveRetryKey), findsNothing);
    final persisted = await _io<PreferencesReadResult>(tester, 'read.confirm', h.disk().read);
    expect(persisted.value, const AppPreferences(theme: AppThemePreference.dark));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ROOT-PREF-06 failed and uncertain UI never replace known disk state',
    (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = await _RootHarness.create(tester);
    const known = AppPreferences(theme: AppThemePreference.light, localeTag: 'en');
    expect((await _io<PreferencesWriteResult>(tester, 'known.seed',
      () => h.disk().write(known))).kind, PreferencesWriteKind.committed);
    for (final outcome in [PreferencesWriteKind.failed, PreferencesWriteKind.uncertain]) {
      final store = h.store();
      final c = h.controller(store);
      await h.load(c);
      expect(c.value, known);
      await h.mount(c);
      await h.ready();
      await h.settings();
      store.nextWrite = (_) async => PreferencesWriteResult(outcome);
      await _choose<AppThemePreference>(tester, const Key('settings.appearance'),
        AppThemePreference.dark);
      await h.drain();
      expect(c.dirty, isTrue);
      expect(c.value, const AppPreferences(theme: AppThemePreference.dark, localeTag: 'en'));
      expect(c.savePhase, outcome == PreferencesWriteKind.failed
        ? PreferencesSavePhase.failed : PreferencesSavePhase.uncertain);
      expect(find.byKey(_statusKey), findsOneWidget);
      expect(find.textContaining(outcome == PreferencesWriteKind.failed
        ? 'could not be saved.' : 'Saving could not be confirmed;'), findsOneWidget);
      expect(find.text('Saved on this device.'), findsNothing);
      expect(find.byKey(_saveRetryKey), findsOneWidget);
      expect(Theme.of(tester.element(find.byType(SettingsPage))).brightness,
        Brightness.dark);
      final stillKnown = await _io<PreferencesReadResult>(tester, 'known.read', h.disk().read);
      expect(stillKnown.value, known);
      expect(store.payloads, const [
        AppPreferences(theme: AppThemePreference.dark, localeTag: 'en'),
      ]);
      await h.unmount();
      final freshStore = h.store();
      final fresh = h.controller(freshStore);
      await h.load(fresh);
      expect(fresh.value, known);
      await h.mount(fresh);
      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light);
      await h.ready();
      await h.settings();
      expect(Theme.of(tester.element(find.byType(SettingsPage))).brightness,
        Brightness.light);
      expect(freshStore.payloads, isEmpty);
      expect(tester.takeException(), isNull);
      await h.unmount();
    }
    // Injected uncertainty here means no commit; it does not infer the real
    // destination after an actual OS readback failure. File fault tests do that.
  });
}
