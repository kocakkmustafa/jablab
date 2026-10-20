// Host presentation protocol: actual Core runtime/gate, controlled HTTP only.
// Synthetic Auth proof is not a provider, device, IAP or physical acceptance.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jablab/app/app_preferences.dart';
import 'package:jablab/app/app_preferences_controller.dart';
import 'package:jablab/app/identity_appearance_gate.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/owner_bound_account_page.dart';
import 'package:jablab/app/settings_page.dart';
import 'package:jablab/app/ui_language.dart';
import 'package:motion_account/motion_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_pump.dart';

const _owner = '00000000-0000-4000-8000-000000000014';
const _checking = <String, String>{
  'en': 'Checking account…',
  'tr': 'Hesap doğrulanıyor…',
  'fr': 'Vérification du compte…',
  'ar': 'جارٍ التحقّق من الحساب…',
  'ja': 'アカウントを確認中…',
  'zh-Hans': '正在检查账户…',
};
const _failureEn =
    'Could not verify your account. Check your connection and retry.';

http.Response _userResponse() => http.Response(
  jsonEncode({
    'id': _owner,
    'aud': 'authenticated',
    'created_at': '2026-10-20T00:00:00Z',
    'app_metadata': <String, dynamic>{},
  }),
  200,
  headers: {'content-type': 'application/json'},
);

class _DeviceStore implements AppPreferencesStore {
  _DeviceStore(this.value);
  AppPreferences value;
  int reads = 0;
  final writes = <AppPreferences>[];

  @override
  bool get persistent => false;

  @override
  Future<PreferencesReadResult> read() async {
    reads++;
    return PreferencesReadResult(PreferencesReadKind.loaded, value);
  }

  @override
  Future<PreferencesWriteResult> write(AppPreferences next) async {
    writes.add(next);
    value = next;
    return const PreferencesWriteResult(PreferencesWriteKind.committed);
  }
}

class _ProbeLedger {
  int initialized = 0;
  int disposed = 0;
}

class _AdmittedProbe extends StatefulWidget {
  const _AdmittedProbe({required super.key, required this.ledger, required this.child});
  final _ProbeLedger ledger;
  final Widget child;

  @override
  State<_AdmittedProbe> createState() => _AdmittedProbeState();
}

class _AdmittedProbeState extends State<_AdmittedProbe> {
  @override
  void initState() {
    super.initState();
    widget.ledger.initialized++;
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    widget.ledger.disposed++;
    super.dispose();
  }
}

class _Harness {
  _Harness(AppPreferences value) : store = _DeviceStore(value);
  final _DeviceStore store;
  final ledger = _ProbeLedger();
  final probeKey = GlobalKey<_AdmittedProbeState>();
  late final SupabaseClient client;
  late final MockClient transport;
  late final MotionAccountRuntime runtime;
  late final AppPreferencesController preferences;
  late final Widget child;
  Completer<http.Response> _response = Completer<http.Response>();
  Future<void>? _proof;
  int userRequests = 0;
  int unexpectedRequests = 0;
  int deletionCallbacks = 0;
  int profileReads = 0;
  int directoryReads = 0;
  final owners = OwnerResourceRegistry();
  late final Directory support;
  late final File marker;
  late final JabLabApp app;
  bool _closed = false;

  static Future<_Harness> create(
    WidgetTester tester, {
    AppPreferences value = const AppPreferences(),
  }) async {
    final h = _Harness(value);
    h.client = SupabaseClient(
      'https://motion.example.invalid',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: h.transport = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/user')) {
          h.userRequests++;
          return h._response.future;
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/rest/v1/motion_profiles')) {
          h.profileReads++;
          return http.Response(jsonEncode({
            'user_id': _owner, 'display_name': 'Synthetic profile baseline',
            'created_at': '2026-10-20T00:00:00Z',
            'updated_at': '2026-10-20T00:00:00Z',
          }), 200, headers: {'content-type': 'application/json'});
        }
        h.unexpectedRequests++;
        return http.Response('{"message":"unexpected synthetic request"}', 400);
      }),
    );
    h.preferences = AppPreferencesController(
      store: h.store,
      codec: AppPreferencesCodec(
        supportedLocaleTags: AppLocalizations.supportedLocales.map(
          (locale) => locale.toLanguageTag(),
        ),
      ),
    );
    await tester.runAsync(() async {
      await h.client.auth.setInitialSession(jsonEncode({
        'access_token': 'ap14-synthetic-token',
        'token_type': 'bearer',
        'user': {
          'id': _owner,
          'aud': 'authenticated',
          'created_at': '2026-10-20T00:00:00Z',
          'app_metadata': <String, dynamic>{},
        },
      }));
      // Future listeners still receive Auth replay. Initial/replayed and
      // explicit verification share the same held response, never an orphan.
      await Future<void>.delayed(Duration.zero);
      h.runtime = MotionAccountRuntime.forTesting(
        client: h.client,
        app: MotionApp.jablab,
        onDeletedAccount: (_) async {
          h.deletionCallbacks++;
        },
      );
      await h.preferences.load();
      h.beginProof();
      await Future<void>.delayed(Duration.zero);
    });
    h.support = await _io<Directory>(tester, 'temp.create',
      () => Directory.systemTemp.createTemp('jablab-identity-host-'));
    h.marker = File('${h.support.path}/owned-marker.txt');
    addTearDown(() => h.close(tester));
    await _io<File>(tester, 'marker.write',
      () => h.marker.writeAsString('preserve-owned-marker'));
    h.app = JabLabApp(
      preferences: h.preferences,
      repository: ContentRepository(
        ownerRegistry: h.owners,
        historyDirectoryProvider: () async {
          h.directoryReads++;
          return h.support;
        },
      ),
      onboarding: const OnboardingStore(seenOverride: true),
      accountUserId: h.runtime.userId,
      accountRecovery: h.runtime.passwordRecovery,
      accountPageBuilder: (_) => OwnerBoundAccountPage(
        account: h.runtime.account,
        ownerRegistry: h.owners,
        lifetime: h.owners.capture(h.runtime.userId.value),
        canInitiate: () => h.runtime.isCurrentSessionVerified &&
            !h.runtime.isPasswordRecovery,
        onRetryIdentity: h.runtime.refreshIdentity,
      ),
    );
    h.child = _AdmittedProbe(key: h.probeKey, ledger: h.ledger, child: h.app);
    expect(h.preferences.readPhase, PreferencesReadPhase.loaded);
    expect(h.store.reads, 1);
    expect(h.store.writes, isEmpty);
    expect(h.userRequests, greaterThan(0));
    expect(h.runtime.phase.value, MotionIdentityPhase.verifying);
    expect(h.runtime.isCurrentSessionVerified, isFalse);
    return h;
  }

  void beginProof() {
    if (_proof != null) {
      expect(_response.isCompleted, isTrue,
        reason: 'A proof is never replaced while its transport is pending');
      _response = Completer<http.Response>();
    }
    _proof = runtime.refreshIdentity().then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
  }

  Future<void> finishProof(WidgetTester tester, {bool success = true}) async {
    await tester.runAsync(() async {
      _response.complete(success
          ? _userResponse()
          : http.Response(
              '{"message":"synthetic verification failure",'
              '"code":"synthetic_auth_failure"}',
              400,
              headers: {'content-type': 'application/json'},
            ));
      await _proof;
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    await tester.pump();
    expect(runtime.phase.value, success
        ? MotionIdentityPhase.verified : MotionIdentityPhase.unavailable);
    expect(runtime.isCurrentSessionVerified, success);
  }

  Widget adapter() => JabLabIdentityAppearanceGate(
    runtime: runtime,
    preferences: preferences,
    child: child,
  );

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(adapter());
    expect(
      Localizations.maybeLocaleOf(
        tester.element(find.byType(JabLabIdentityAppearanceGate)),
      ),
      isNull,
      reason: 'OS observer must be exercised at the actual top-level boundary',
    );
  }

  void expectClosed() {
    expect(ledger.initialized, 0);
    expect(probeKey.currentState, isNull);
    expect(runtime.isCurrentSessionVerified, isFalse);
    expect(runtime.userId.value, isNull);
    expect(runtime.isDisposed, isFalse);
    expect(unexpectedRequests, 0);
    expect(deletionCallbacks, 0);
  }

  Future<void> close(WidgetTester tester) async {
    if (_closed) {
      return;
    }
    _closed = true;
    await tester.pumpWidget(const SizedBox.shrink());
    // Unmount must not own or dispose either caller-owned dependency.
    expect(runtime.isDisposed, isFalse);
    if (!_response.isCompleted) {
      await finishProof(tester);
    }
    await tester.runAsync(() async {
      await _proof;
      await Future<void>.delayed(Duration.zero);
    });
    await _io<void>(tester, 'owners.retire', owners.retireAll);
    expect(await _io<String>(tester, 'marker.read', marker.readAsString),
      'preserve-owned-marker');
    await _io<FileSystemEntity>(tester, 'temp.delete',
      () => support.delete(recursive: true));
    runtime.dispose();
    await _io<void>(tester, 'client.dispose', client.dispose);
    transport.close();
    preferences.dispose();
    expect(ledger.disposed, ledger.initialized);
    expect(unexpectedRequests, 0);
    expect(deletionCallbacks, 0);
    expect(tester.takeException(), isNull);
  }
}

// Dual-clock helper follows the already accepted real-root fixture recipe.
Future<T> _io<T>(WidgetTester tester, String stage, Future<T> Function() action) async {
  bool settled = false;
  T? value;
  Object? error;
  StackTrace? trace;
  action().then((result) {
    value = result;
    settled = true;
  }, onError: (Object failure, StackTrace stack) {
    error = failure;
    trace = stack;
    settled = true;
  });
  for (int turn = 0; turn < 80 && !settled; turn++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  expect(settled, isTrue, reason: '$stage: bounded owned IO did not settle');
  if (error != null) {
    Error.throwWithStackTrace(error!, trace!);
  }
  return value as T;
}

Future<void> _routeSettled(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 3),
);

Future<void> _blocker(
  WidgetTester tester,
  Locale locale, {
  String? text,
  Brightness? brightness,
  Color? background,
  Color? foreground,
}) async {
  final literal = text ?? _checking[locale.toLanguageTag()]!;
  // A pending indicator intentionally animates forever; pumpAndSettle is not
  // an admissible readiness oracle here. Advance bounded frames and real work.
  for (int turn = 0; turn < 40; turn++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
    if (find.text(literal).evaluate().isNotEmpty) {
      break;
    }
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final target = find.text(literal);
  expect(target, findsOneWidget, reason: 'Actual, literal localized blocker');
  final context = tester.element(target);
  final loaded = Localizations.of<MotionAccountLocalizations>(
    context, MotionAccountLocalizations,
  );
  expect(loaded, isNotNull, reason: 'Real Core delegate must be mounted');
  expect(loaded!.locale, locale);
  expect(Localizations.localeOf(context), locale);
  expect(Directionality.of(context), locale.languageCode == 'ar'
      ? TextDirection.rtl : TextDirection.ltr);
  if (brightness != null) {
    expect(Theme.of(context).brightness, brightness);
  }
  if (background != null) {
    final canvas = find.descendant(
      of: find.byType(Scaffold),
      matching: find.byWidgetPredicate(
        (widget) => widget is Material && widget.type == MaterialType.canvas,
      ),
    );
    expect(canvas, findsOneWidget, reason: 'Actual Scaffold canvas required');
    expect(tester.widget<Material>(canvas).color, background);
  }
  if (foreground != null) {
    expect(DefaultTextStyle.of(context).style.color, foreground);
  }
  expect(tester.takeException(), isNull);
}

Element _gate(WidgetTester tester, _Harness h) {
  final finder = find.byType(MotionIdentityGate);
  expect(finder, findsOneWidget);
  final gate = tester.widget<MotionIdentityGate>(finder);
  expect(gate.runtime, same(h.runtime));
  expect(gate.child, same(h.child));
  return tester.element(finder);
}

void _platformReset(WidgetTester tester) {
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

void main() {
  testWidgets('AP14-01 root OS locale event updates the held real blocker',
    (tester) async {
    _platformReset(tester);
    tester.platformDispatcher.localesTestValue = const [Locale('xx'), Locale('fr')];
    final h = await _Harness.create(tester);
    await h.mount(tester);
    await _blocker(tester, const Locale('fr'));
    final gate = _gate(tester, h);
    final session = h.client.auth.currentSession;
    final calls = h.userRequests;
    tester.platformDispatcher.localesTestValue = const [Locale('ar'), Locale('en')];
    await _blocker(tester, const Locale('ar'));
    expect(_gate(tester, h), same(gate));
    expect(h.client.auth.currentSession, same(session));
    expect(h.userRequests, calls);
    expect(h.runtime.phase.value, MotionIdentityPhase.verifying);
    expect(h.store.reads, 1);
    expect(h.store.writes, isEmpty);
    h.expectClosed();
  });

  testWidgets('AP14-02 explicit locale wins until actual follow-device edit',
    (tester) async {
    _platformReset(tester);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    final h = await _Harness.create(tester,
      value: const AppPreferences(localeTag: 'tr'));
    await h.mount(tester);
    await _blocker(tester, const Locale('tr'));
    final gate = _gate(tester, h);
    final calls = h.userRequests;
    tester.platformDispatcher.localesTestValue = const [Locale('ar'), Locale('en')];
    await _blocker(tester, const Locale('tr'));
    expect(h.store.writes, isEmpty);
    h.preferences.selectLocale(null);
    await _blocker(tester, const Locale('ar'));
    expect(h.store.writes, [const AppPreferences()]);
    expect(h.userRequests, calls);
    expect(_gate(tester, h), same(gate));
    h.expectClosed();
  });

  testWidgets('AP14-03 Hant lists continue to French and Hans stays explicit',
    (tester) async {
    _platformReset(tester);
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    final h = await _Harness.create(tester);
    await h.mount(tester);
    await _blocker(tester, const Locale('en'));
    final gate = _gate(tester, h);
    final calls = h.userRequests;
    for (final traditional in const [
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      Locale('zh', 'TW'), Locale('zh', 'HK'), Locale('zh', 'MO'),
    ]) {
      tester.platformDispatcher.localesTestValue = [traditional, const Locale('fr')];
      await _blocker(tester, const Locale('fr'));
      expect(find.text(_checking['zh-Hans']!), findsNothing);
      expect(_gate(tester, h), same(gate));
    }
    const hans = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    tester.platformDispatcher.localesTestValue = const [hans, Locale('en')];
    await _blocker(tester, hans);
    tester.platformDispatcher.localesTestValue = const [];
    await _blocker(tester, const Locale('en'));
    expect(h.userRequests, calls);
    expect(h.store.writes, isEmpty);
    h.expectClosed();
  });

  testWidgets('AP14-04 parent inheritance and explicit adapter preferences differ',
    (tester) async {
    _platformReset(tester);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    final h = await _Harness.create(tester,
      value: const AppPreferences(theme: AppThemePreference.light, localeTag: 'tr'));
    const inheritedGround = Color(0xFF012345);
    await tester.pumpWidget(Localizations(
      locale: const Locale('ar'),
      delegates: MotionAccountLocalizations.delegates,
      child: Theme(
        data: ThemeData.dark().copyWith(scaffoldBackgroundColor: inheritedGround),
        child: MotionIdentityGate(runtime: h.runtime, child: h.child),
      ),
    ));
    await _blocker(tester, const Locale('ar'), brightness: Brightness.dark,
      background: inheritedGround);
    h.expectClosed();
    final calls = h.userRequests;
    // Actual JabLab wrapper supplies an explicit palette/locale preference.
    await tester.pumpWidget(Localizations(
      locale: const Locale('ar'),
      delegates: MotionAccountLocalizations.delegates,
      child: Theme(
        data: ThemeData.dark().copyWith(scaffoldBackgroundColor: inheritedGround),
        child: h.adapter(),
      ),
    ));
    await _blocker(tester, const Locale('tr'), brightness: Brightness.light,
      background: const Color(0xFFFFF8F9), foreground: const Color(0xFF251D22));
    expect(h.userRequests, calls);
    expect(h.store.writes, isEmpty);
    expect(h.runtime.isDisposed, isFalse);
    h.expectClosed();
  });

  testWidgets('AP14-05 explicit modes govern pending and failure canvases',
    (tester) async {
    _platformReset(tester);
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    final h = await _Harness.create(tester,
      value: const AppPreferences(theme: AppThemePreference.light));
    await h.mount(tester);
    await _blocker(tester, const Locale('en'), brightness: Brightness.light,
      background: const Color(0xFFFFF8F9), foreground: const Color(0xFF251D22));
    final gate = _gate(tester, h);
    final calls = h.userRequests;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    h.preferences.selectTheme(AppThemePreference.dark);
    await _blocker(tester, const Locale('en'), brightness: Brightness.dark,
      background: const Color(0xFF0A0608), foreground: const Color(0xFFF7F4F5));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await _blocker(tester, const Locale('en'), brightness: Brightness.dark);
    await h.finishProof(tester, success: false);
    await _blocker(tester, const Locale('en'), text: _failureEn,
      brightness: Brightness.dark, background: const Color(0xFF0A0608));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    h.preferences.selectTheme(AppThemePreference.light);
    await _blocker(tester, const Locale('en'), text: _failureEn,
      brightness: Brightness.light, background: const Color(0xFFFFF8F9));
    expect(_gate(tester, h), same(gate));
    expect(h.userRequests, calls);
    expect(h.store.writes, [
      const AppPreferences(theme: AppThemePreference.dark),
      const AppPreferences(theme: AppThemePreference.light),
    ]);
    h.expectClosed();
  });

  testWidgets('AP14-06 system events and same-session refresh retain real app state',
    (tester) async {
    _platformReset(tester);
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    final h = await _Harness.create(tester);
    await h.mount(tester);
    await _blocker(tester, const Locale('en'), brightness: Brightness.light,
      background: const Color(0xFFFFF8F9));
    final gate = _gate(tester, h);
    final calls = h.userRequests;
    for (final brightness in [Brightness.dark, Brightness.light]) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      await _blocker(tester, const Locale('en'), brightness: brightness,
        background: brightness == Brightness.dark
            ? const Color(0xFF0A0608) : const Color(0xFFFFF8F9));
      expect(_gate(tester, h), same(gate));
    }
    expect(h.store.writes, isEmpty);
    expect(h.userRequests, calls);
    h.expectClosed();
    await h.finishProof(tester);
    await settleAppLoad(tester);
    await _routeSettled(tester);
    expect(find.byType(JabLabApp), findsOneWidget);
    expect(h.ledger.initialized, 1);
    expect(h.directoryReads, greaterThan(0));
    final probeState = h.probeKey.currentState;
    expect(probeState, isNotNull);
    final appState = tester.state(find.byType(JabLabApp));
    final lifetime = h.owners.capture(_owner);
    expect(lifetime.isActive, isTrue);
    expect(lifetime.journalWrites.isActive, isTrue);
    await tester.tap(find.byKey(const Key('settings-button')));
    await _routeSettled(tester);
    expect(find.byType(SettingsPage), findsOneWidget);
    await tester.ensureVisible(find.byKey(SettingsPage.accountEntryKey));
    await tester.tap(find.byKey(SettingsPage.accountEntryKey));
    await _routeSettled(tester);
    final account = find.byType(MotionAccountPage);
    expect(account, findsOneWidget);
    for (int turn = 0; turn < 40 && h.profileReads == 0; turn++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    expect(h.profileReads, 1);
    await _routeSettled(tester);
    final profileField = find.byWidgetPredicate((widget) => widget is TextField &&
      widget.controller?.text == 'Synthetic profile baseline');
    expect(profileField, findsOneWidget,
      reason: 'The actual Core profile read must populate an actual field');
    await tester.ensureVisible(profileField);
    final fieldController = tester.widget<TextField>(profileField).controller!;
    await tester.enterText(profileField, 'retained typed draft');
    final editedField = find.byWidgetPredicate((widget) => widget is TextField &&
      identical(widget.controller, fieldController));
    final accountState = tester.state(account);
    final navigator = Navigator.of(tester.element(account));
    final maybeRoute = ModalRoute.of(tester.element(account));
    expect(maybeRoute, isNotNull);
    final route = maybeRoute!;
    expect(route.isCurrent, isTrue);
    expect(fieldController.text, 'retained typed draft');
    final session = h.client.auth.currentSession;

    Future<void> retained(Locale locale) async {
      // Appearance may reload real packaged app assets. Route animation
      // settlement alone cannot prove that real asynchronous IO completed.
      await settleAppLoad(tester);
      await _routeSettled(tester);
      expect(_gate(tester, h), same(gate));
      expect(h.probeKey.currentState, same(probeState));
      expect(tester.state(find.byType(JabLabApp)), same(appState));
      expect(tester.state(find.byType(MotionAccountPage)), same(accountState));
      expect(Navigator.of(tester.element(account)), same(navigator));
      expect(ModalRoute.of(tester.element(account)), same(route));
      expect(route.isCurrent, isTrue);
      expect(editedField, findsOneWidget);
      expect(fieldController.text, 'retained typed draft');
      final context = tester.element(editedField);
      expect(Localizations.localeOf(context), locale);
      expect(Localizations.of<MotionAccountLocalizations>(
        context, MotionAccountLocalizations)!.locale, locale);
      expect(h.owners.capture(_owner), same(lifetime));
      expect(lifetime.isActive, isTrue);
      expect(lifetime.journalWrites.isActive, isTrue);
      expect(h.client.auth.currentSession, same(session));
      expect(h.runtime.isCurrentSessionVerified, isTrue);
      expect(h.ledger.initialized, 1);
      expect(h.ledger.disposed, 0);
      expect(h.profileReads, 1);
      expect(h.unexpectedRequests, 0);
      expect(tester.takeException(), isNull);
    }

    h.preferences.selectLocale('ar');
    h.preferences.selectTheme(AppThemePreference.dark);
    await retained(const Locale('ar'));
    expect(h.userRequests, calls);
    // Ordinary verification of the unchanged Session preserves current proof.
    // A failed/distinct credential proof has a separate owner-retirement rule.
    await tester.runAsync(() async {
      h.beginProof();
      await Future<void>.delayed(Duration.zero);
    });
    expect(h.userRequests, calls + 1);
    expect(h.runtime.phase.value, MotionIdentityPhase.verified);
    expect(h.runtime.isCurrentSessionVerified, isTrue);
    h.preferences.selectLocale(null);
    h.preferences.selectTheme(AppThemePreference.system);
    tester.platformDispatcher.localesTestValue = const [Locale('xx'), Locale('fr')];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await retained(const Locale('fr'));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(h.userRequests, calls + 1);
    await h.finishProof(tester);
    await retained(const Locale('fr'));
    expect(h.runtime.isDisposed, isFalse);
    expect(h.client.auth.currentUser!.id, _owner);
    await h.close(tester);
    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();
    expect(find.byType(JabLabIdentityAppearanceGate), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
