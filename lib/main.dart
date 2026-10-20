import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:motion_account/motion_account.dart';

import 'app/app_preferences.dart';
import 'app/app_preferences_controller.dart';
import 'app/app_preferences_store.dart';
import 'app/design_tokens.dart';
import 'app/account_bridge.dart';
import 'app/jablab_app.dart';
import 'app/identity_appearance_gate.dart';
import 'app/owner_resource_lifetime.dart';
import 'app/owner_bound_account_page.dart';
import 'app/ui_language.dart';

/// PORTRE KİLİDİ (J-109, koordinatör hükmü 2026-08-07).
///
/// ## Gerekçe — ve gerekçe OLMAYAN şey
///
/// Kilit **"yatayda bozulur" diye konmadı**: o bir hipotezdi ve ölçülmedi.
/// Cihaz döndürüldüğünde landmark'ların cihaz yönüne göre normalize edilip
/// edilmediği bilinmiyor — `motion_camera` dokümanı *"capture size after
/// sensor-rotation normalization"* diyor ama o SENSÖR montajı, cihaz yönü
/// değil; native taraf okunmadı. Doğru olsa bile ölçülmemiş bir gerekçeyle
/// alınan karar, yanlış gerekçeyle alınmış karardır.
///
/// **Gerçek gerekçe:** yatay yüzey hiç tasarlanmadı ve hiç ölçülmedi. 375pt
/// taşma kapısı YALNIZ portre ölçüyor (375×812); yatayda (812×375) canlı
/// yüzeyin `Expanded(preview) + sabit metin bloğu` düzeni hiçbir testten
/// geçmedi. Ölçülmemiş bir yüzeyi kullanıcıya açmak M-F-277'nin tersidir.
/// Kilit ucuz ve geri alınabilir; yatayı açık bırakmak değil.
///
/// ## Neden ÜÇ yerde birden
///
/// Flutter çağrısı tek başına yeterli değil: platform manifest'i hâlâ üç
/// yönü ilan ediyorsa iOS açılışta kısa bir yatay kare çizebiliyor ve
/// Android yapılandırma değişikliğini uygulamaya taşıyor. Beyanın üçünde de
/// aynı olması, "kilit var" cümlesinin her katmanda doğru olması demek.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await launchJabLab();
}

/// A missing or invalid account build cannot silently enter the guest shell.
Future<void> launchJabLab({
  AppPreferencesController? preferencesOverride,
  String url = const String.fromEnvironment('MOTION_SUPABASE_URL'),
  String publishableKey = const String.fromEnvironment(
    'MOTION_SUPABASE_PUBLISHABLE_KEY',
  ),
}) async {
  final codec = AppPreferencesCodec(
    supportedLocaleTags: AppLocalizations.supportedLocales.map(
      (l) => l.toLanguageTag(),
    ),
  );
  final preferences =
      preferencesOverride ??
      AppPreferencesController(
        store: FileAppPreferencesStore(codec: codec),
        codec: codec,
      );
  // Outside the identity gate. Bounded read settles before any Flutter root;
  // The same controller supplies appearance to the shell and Core blocker.
  await preferences.load();
  try {
    final MotionAccountRuntime runtime = await MotionAccountRuntime.initialize(
      url: url,
      publishableKey: publishableKey,
      app: MotionApp.jablab,
      emailRedirectTo: 'com.yulalab.jablab://auth/callback',
      onDeletedAccount: clearLocalHistoryFor,
      localAccountIds: localHistoryAccountIds,
    );
    Widget accountPage(BuildContext _) {
      OwnerResourceLifetime? deletionLifetime;
      try {
        deletionLifetime = defaultOwnerResourceRegistry.capture(
          runtime.userId.value,
        );
      } on OwnerResourceRetiredException {
        // Recovery/unverified identity has no admitted local deletion epoch.
      }
      final OwnerResourceLifetime? captured = deletionLifetime;
      return OwnerBoundAccountPage(
        account: runtime.account,
        canInitiate: () =>
            runtime.isCurrentSessionVerified && !runtime.isPasswordRecovery,
        lifetime: captured,
        onRetryIdentity: runtime.refreshIdentity,
        initialPasswordRecovery: runtime.isPasswordRecovery,
        clearLocalData: captured?.accountUserId == null
            ? null
            // Core validates the initiating UUID before this callback. Its
            // account-wide deletion fence also drains later data epochs.
            : clearLocalHistoryFor,
      );
    }

    runApp(
      JabLabIdentityAppearanceGate(
        runtime: runtime,
        preferences: preferences,
        child: JabLabApp(
          preferences: preferences,
          accountUserId: runtime.userId,
          accountRecovery: runtime.passwordRecovery,
          accountPageBuilder: accountPage,
          beforeLessonStart: (lessonContext) => requireMotionPaidAccess(
            lessonContext,
            account: runtime.account,
            accountPageBuilder: accountPage,
          ),
        ),
      ),
    );
  } on Object {
    runApp(JabLabAccountStartupFailure(preferences: preferences));
  }
}

class JabLabAccountStartupFailure extends StatelessWidget {
  const JabLabAccountStartupFailure({super.key, this.preferences});
  final AppPreferencesController? preferences;

  @override
  Widget build(BuildContext context) {
    final controller = preferences;
    if (controller == null) return _material(const AppPreferences());
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _material(controller.value),
    );
  }

  Widget _material(AppPreferences value) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'JabLab',
    locale: value.localeTag == null
        ? null
        : AppLocalizations.supportedLocales.firstWhere(
            (locale) => locale.toLanguageTag() == value.localeTag,
          ),
    supportedLocales: AppLocalizations.supportedLocales,
    localeListResolutionCallback: AppLocalizations.resolve,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      MotionAccountLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: jablabTheme(Brightness.light),
    darkTheme: jablabTheme(Brightness.dark),
    themeMode: switch (value.theme) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    },
    themeAnimationDuration: Duration.zero,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Builder(
            builder: (context) => Text(
              UiLanguage.text(
                context,
                en:
                    'JabLab account service could not start in this build. '
                    'Try reopening the app; if the problem continues, '
                    'install an updated version.',
                tr:
                    'JabLab hesap hizmeti bu sürümde başlatılamadı. '
                    'Uygulamayı yeniden açmayı dene; sorun sürerse '
                    'güncel sürümü yükle.',
              ),
              key: const Key('jablab.accountStartupFailure'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );
}
