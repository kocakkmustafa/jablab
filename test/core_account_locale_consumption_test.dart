// Consumer locale contract for published Core d69; device and provider acceptance is separate.
import 'dart:io';
import 'app_pump.dart';
import 'localization_fixture.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/settings_page.dart';
import 'package:motion_account/motion_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SignedOutLocaleAccount implements MotionAccountClient {
  @override
  User? get currentUser => null;
  @override
  Stream<AuthState> get authChanges => const Stream<AuthState>.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Copied in shape from account_resource_shell_test.dart:_io (51-PASS suite).
// Only filesystem/drain callbacks belong here; never wrap runAsync/pumpWidget.
void _rootStage(String stage) {
  debugPrintSynchronously('JABLAB_ROOT_LOCALE_STAGE $stage');
}

Future<T> _rootIo<T>(
  WidgetTester tester,
  String stage,
  Future<T> Function() action,
) async {
  _rootStage('$stage/begin');
  bool settled = false;
  T? value;
  Object? error;
  StackTrace? stack;
  action().then(
    (result) {
      value = result;
      settled = true;
    },
    onError: (Object failure, StackTrace trace) {
      error = failure;
      stack = trace;
      settled = true;
    },
  );
  for (int i = 0; i < 80 && !settled; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  if (!settled) {
    _rootStage('$stage/bounded-failure');
  }
  expectSync(
    settled,
    isTrue,
    reason: '$stage: real IO and UI continuations must settle within 80 pumps',
  );
  if (error != null) {
    _rootStage('$stage/error');
    Error.throwWithStackTrace(error!, stack!);
  }
  _rootStage('$stage/done');
  return value as T;
}

Future<void> _rootRouteSettled(WidgetTester tester, String stage) async {
  _rootStage('$stage/begin');
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
  _rootStage('$stage/done');
}

void main() {
  // Literal values from published Core, independent of the renderer's lookup.
  final variants = <Locale, List<String>>{
    const Locale('tr'): [
      "Giriş yap",
      "Hesap oluştur",
      "Yeni hesap oluştur",
      "E-posta",
    ],
    const Locale('en'): [
      "Sign in",
      "Create account",
      "Create a new account",
      "Email",
    ],
    const Locale('es', '419'): [
      "Iniciar sesión",
      "Crear cuenta",
      "Crear una cuenta nueva",
      "Correo electrónico",
    ],
    const Locale('pt', 'BR'): [
      "Entrar",
      "Criar conta",
      "Criar uma nova conta",
      "E-mail",
    ],
    const Locale('de'): [
      "Anmelden",
      "Konto erstellen",
      "Neues Konto erstellen",
      "E-Mail",
    ],
    const Locale('fr'): [
      "Se connecter",
      "Créer un compte",
      "Créer un nouveau compte",
      "E-mail",
    ],
    const Locale('ja'): ["ログイン", "アカウントを作成", "新しいアカウントを作成", "メールアドレス"],
    const Locale('ar'): [
      "تسجيل الدخول",
      "إنشاء حساب",
      "إنشاء حساب جديد",
      "البريد الإلكتروني",
    ],
    const Locale('it'): [
      "Accedi",
      "Crea account",
      "Crea un nuovo account",
      "Email",
    ],
    const Locale('ko'): ["로그인", "계정 만들기", "새 계정 만들기", "이메일"],
    const Locale('id'): ["Masuk", "Buat akun", "Buat akun baru", "Email"],
    const Locale('pl'): [
      "Zaloguj się",
      "Utwórz konto",
      "Utwórz nowe konto",
      "E-mail",
    ],
    const Locale('hi'): [
      "साइन इन करें",
      "खाता बनाएँ",
      "नया खाता बनाएँ",
      "ईमेल",
    ],
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'): [
      "登录",
      "创建账户",
      "创建新账户",
      "电子邮箱",
    ],
  };
  for (final entry in variants.entries) {
    testWidgets(
      'settings account route inherits ${entry.key.toLanguageTag()} into Core sign-in and registration',
      (tester) async {
        tester.platformDispatcher.localesTestValue = [entry.key];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            locale: entry.key,
            supportedLocales: testSupportedLocales,
            localizationsDelegates: testLocalizationDelegates,
            localeListResolutionCallback: resolveTestLocales,
            home: SettingsPage(
              onOpenWhyNot: () {},
              excludedCount: 1,
              accountPageBuilder: (_) =>
                  MotionAccountPage(account: _SignedOutLocaleAccount()),
            ),
          ),
        );
        await settleTestLocalizations(tester, expectedLocale: entry.key);
        await tester.ensureVisible(find.byKey(SettingsPage.accountEntryKey));
        await tester.tap(find.byKey(SettingsPage.accountEntryKey));
        await tester.pumpAndSettle();
        final account = find.byType(MotionAccountPage);
        expect(account, findsOneWidget);
        final context = tester.element(account);
        expect(Localizations.localeOf(context), entry.key);
        final loaded = Localizations.of<MotionAccountLocalizations>(
          context,
          MotionAccountLocalizations,
        );
        expect(
          loaded,
          isNotNull,
          reason:
              'The actual Core delegate must be loaded; of() fallback is insufficient',
        );
        expect(loaded!.locale, entry.key);
        expect(
          Directionality.of(context),
          entry.key.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
        );
        expect(
          find.widgetWithText(FilledButton, entry.value[0]),
          findsOneWidget,
        );
        expect(find.text(entry.value[3]), findsWidgets);
        if (entry.key.languageCode != 'en') {
          expect(find.text('Sign in'), findsNothing);
        }
        await tester.ensureVisible(find.text(entry.value[2]));
        await tester.tap(find.text(entry.value[2]));
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(FilledButton, entry.value[1]),
          findsOneWidget,
        );
        final email = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == entry.value[3],
        );
        expect(email, findsOneWidget);
        final fieldContext = tester.element(email);
        expect(Localizations.localeOf(fieldContext), entry.key);
        expect(
          Directionality.of(fieldContext),
          entry.key.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
        );
        expect(find.text(entry.value[3]), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
  // Real production root: this fails if JabLabApp omits the Core delegate even
  // when the standalone fixture above includes it. No external account call.
  for (final locale in [const Locale('tr'), const Locale('ar')]) {
    testWidgets(
      'production JabLabApp supplies Core delegate through settings in ${locale.toLanguageTag()}',
      (tester) async {
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        final trace = locale.toLanguageTag();
        final directory = await _rootIo<Directory>(
          tester,
          '$trace/temp.create',
          () => Directory.systemTemp.createTemp('jablab-core-locale-'),
        );
        final owners = OwnerResourceRegistry();
        addTearDown(() async {
          _rootStage('$trace/teardown.unmount/begin');
          await tester.pumpWidget(const SizedBox.shrink());
          _rootStage('$trace/teardown.unmount/done');
          await _rootIo<void>(
            tester,
            '$trace/teardown.retire',
            owners.retireAll,
          );
          await _rootIo<FileSystemEntity>(
            tester,
            '$trace/teardown.delete',
            () => directory.delete(recursive: true),
          );
        });
        _rootStage('$trace/root.mount/begin');
        await tester.runAsync(
          () => tester.pumpWidget(
            JabLabApp(
              repository: ContentRepository(
                historyDirectoryOverride: directory,
                ownerRegistry: owners,
              ),
              onboarding: const OnboardingStore(seenOverride: true),
              accountPageBuilder: (_) =>
                  MotionAccountPage(account: _SignedOutLocaleAccount()),
            ),
          ),
        );
        _rootStage('$trace/root.mount/done');
        _rootStage('$trace/root.load/begin');
        await settleAppLoad(tester);
        _rootStage('$trace/root.load/done');
        await _rootRouteSettled(tester, '$trace/root.settle');
        final rootMaterial = tester.widget<MaterialApp>(
          find.byType(MaterialApp).first,
        );
        expect(
          rootMaterial.localizationsDelegates,
          contains(MotionAccountLocalizations.delegate),
        );
        _rootStage('$trace/settings.tap/begin');
        await tester.tap(find.byKey(const Key('settings-button')));
        _rootStage('$trace/settings.tap/done');
        await _rootRouteSettled(tester, '$trace/settings.settle');
        expect(find.byType(SettingsPage), findsOneWidget);
        _rootStage('$trace/account.ensureVisible/begin');
        await tester.ensureVisible(find.byKey(SettingsPage.accountEntryKey));
        _rootStage('$trace/account.ensureVisible/done');
        _rootStage('$trace/account.tap/begin');
        await tester.tap(find.byKey(SettingsPage.accountEntryKey));
        _rootStage('$trace/account.tap/done');
        await _rootRouteSettled(tester, '$trace/account.settle');
        final context = tester.element(find.byType(MotionAccountPage));
        final loaded = Localizations.of<MotionAccountLocalizations>(
          context,
          MotionAccountLocalizations,
        );
        expect(loaded, isNotNull);
        expect(loaded!.locale, locale);
        expect(Localizations.localeOf(context), locale);
        expect(
          Directionality.of(context),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(
          find.widgetWithText(
            FilledButton,
            locale.languageCode == 'tr' ? 'Giriş yap' : 'تسجيل الدخول',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        _rootStage('$trace/assertions/done');
      },
    );
  }
}
