import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'app_preferences_controller.dart';
import 'camera_harness_screen.dart';
import 'design_tokens.dart';
import 'ui_language.dart';

/// Ayarlar köşesi (design: `docs/design/DESIGN-PANEL-PROMPT.md` §2
/// "Köşe — Ayarlar", `JabLab.dc.html` `isSettings` dalı). Ayrı sekme
/// DEĞİL — Sayfa A/B'nin köşe ikonundan açılan bir sayfa.
///
/// Tasarımda profil kartı (isim/stance) ve koçluk-tercihleri listesi
/// (ses seviyesi, düzeltme sıklığı vb.) var — bu turda bunların karşılığı
/// olan GERÇEK bir kullanıcı/ayar sistemi YOK. Sahte veri BASILMAZ (bu
/// app'in tüm kimliği bu ilkeye dayanıyor); bu iki öğe kapanış raporunda
/// DESIGN-AHEAD-OF-CODE olarak kayda geçiyor, burada İCAT EDİLMEDİ.
///
/// Mağaza fiyatı bu ekrana sabit yazılmaz; Motion üyelik ekranı mağazanın
/// kullanıcıya uygun para birimindeki aylık ve yıllık tekliflerini gösterir.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.onOpenWhyNot,
    required this.excludedCount,
    this.accountPageBuilder,
  });

  final VoidCallback onOpenWhyNot;
  final WidgetBuilder? accountPageBuilder;
  static const Key accountEntryKey = Key('settings.accountEntry');

  /// Kapsam-dışı madde sayısı — `library.exclusions`tan TÜREVİ (J-151).
  ///
  /// Elle yazılıydı ve **bayatlamıştı**: ekranda *"Seven things"* diyordu,
  /// gerçek sayı **12**. J-107'de aynı kusur karşılama ekranında bulunup
  /// türetilerek çözülmüştü; **ayarlar köşesi o turda taranmamıştı** —
  /// kapsamın katman değil YÜZEY bazında dolaşılması gerektiğinin bir
  /// örneği daha.
  final int excludedCount;

  @override
  Widget build(BuildContext context) {
    final colors = JColors.of(context);
    final text = JText.of(context);
    final preferences = AppPreferencesScope.maybeOf(context);
    return Scaffold(
      backgroundColor: colors.ground,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[colors.gradientTop, colors.ground],
            stops: const <double>[0, .42],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: <Widget>[
              Row(
                children: <Widget>[
                  GlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    // `tester.pageBack()` `find.byTooltip('Back')` arıyor
                    // (bkz. course_page.dart'ın aynı düzeltmesi) — süs değil.
                    tooltip: UiLanguage.text(context, en: 'Back', tr: 'Geri'),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      UiLanguage.text(context, en: 'Settings', tr: 'Ayarlar'),
                      style: text.pageTitle.copyWith(
                        fontSize: 30,
                        letterSpacing: -.9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              if (Localizations.of<AppLocalizations>(context, AppLocalizations)
                  case final translations?
                  when translations.loadFailed || !translations.complete)
                Text(
                  UiLanguage.text(
                    context,
                    en: 'Some translations are unavailable. Source English text is shown where needed.',
                    tr: 'Bazı çeviriler kullanılamıyor. Gerektiğinde kaynak İngilizce metin gösterilir.',
                  ),
                  key: const Key('settings.language.incomplete'),
                  style: text.bodyMuted,
                ),
              if (AppLanguageScope.maybeOf(context) case final language?)
                GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        UiLanguage.text(
                          context,
                          en: 'App language',
                          tr: 'Uygulama dili',
                        ),
                        style: text.body,
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<Locale>(
                        key: const Key('settings.language'),
                        isExpanded: true,
                        value: language.selected,
                        hint: Text(
                          UiLanguage.text(
                            context,
                            en: 'Follow device languages',
                            tr: 'Cihaz dillerini izle',
                          ),
                        ),
                        items: [
                          for (final locale
                              in AppLocalizations.supportedLocales)
                            DropdownMenuItem(
                              value: locale,
                              child: Text(
                                _languageNames[locale.toLanguageTag()] ??
                                    locale.toLanguageTag(),
                              ),
                            ),
                        ],
                        onChanged: language.select,
                      ),
                      TextButton(
                        key: const Key('settings.language.device'),
                        onPressed: () => language.select(null),
                        child: Text(
                          UiLanguage.text(
                            context,
                            en: 'Use device languages',
                            tr: 'Cihaz dillerini kullan',
                          ),
                        ),
                      ),
                      Text(
                        UiLanguage.text(
                          context,
                          en: 'Language and appearance are device preferences. They do not change your account details or store currency.',
                          tr: 'Dil ve görünüm cihaz tercihleridir. Hesap bilgilerini veya mağaza para birimini değiştirmez.',
                        ),
                        style: text.bodyMuted,
                      ),
                    ],
                  ),
                ),
              if (preferences != null) ...<Widget>[
                const SizedBox(height: 14),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        UiLanguage.text(
                          context,
                          en: 'Appearance',
                          tr: 'Görünüm',
                        ),
                        style: text.body,
                      ),
                      DropdownButton<AppThemePreference>(
                        key: const Key('settings.appearance'),
                        isExpanded: true,
                        value: preferences.value.theme,
                        items: <DropdownMenuItem<AppThemePreference>>[
                          DropdownMenuItem(
                            value: AppThemePreference.system,
                            child: Text(
                              UiLanguage.text(
                                context,
                                en: 'Follow device appearance',
                                tr: 'Cihaz görünümünü izle',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: AppThemePreference.light,
                            child: Text(
                              UiLanguage.text(context, en: 'Light', tr: 'Açık'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: AppThemePreference.dark,
                            child: Text(
                              UiLanguage.text(context, en: 'Dark', tr: 'Koyu'),
                            ),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) preferences.selectTheme(mode);
                        },
                      ),
                      _PreferencesStatus(preferences),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              GlassPanel(
                tier: GlassTier.judgement,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          UiLanguage.text(context, en: 'ACCESS', tr: 'ERİŞİM'),
                          style: text.label.copyWith(color: colors.judgement),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.outline),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            UiLanguage.text(context, en: 'COURSE', tr: 'KURS'),
                            style: text.label.copyWith(
                              color: colors.inkMuted,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      UiLanguage.text(
                        context,
                        en: 'Solo boxing course',
                        tr: 'Solo boks kursu',
                      ),
                      style: text.pageTitle.copyWith(
                        fontSize: 28,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      UiLanguage.text(
                        context,
                        en: 'Practise the solo boxing course without an account or camera. Course progress stays on this device and reflects your own practice record. A Motion account is optional. Live camera sessions and subscription sales are closed in this release.',
                        tr: 'Solo boks kursunu hesap veya kamera olmadan çalışabilirsiniz. Kurs ilerlemesi bu cihazda kalır ve kendi çalışma kaydınızı gösterir. Motion hesabı isteğe bağlıdır. Bu sürümde canlı kamera seansları ve abonelik satışı kapalıdır.',
                      ),
                      style: text.body.copyWith(
                        fontSize: 14,
                        color: colors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (accountPageBuilder == null)
                      Text(
                        UiLanguage.text(
                          context,
                          en: 'Account sign-in is not connected. Session history stays on this device.',
                          tr: 'Hesap girişi bağlı değil. Seans geçmişi bu cihazda kalır.',
                        ),
                        key: const Key('account-not-connected'),
                        style: text.body.copyWith(
                          fontSize: 13,
                          color: colors.inkMuted,
                        ),
                      )
                    else
                      TextButton.icon(
                        key: accountEntryKey,
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: accountPageBuilder!),
                        ),
                        icon: const Icon(Icons.person_outline),
                        label: Text(
                          UiLanguage.text(
                            context,
                            en: 'Motion account',
                            tr: 'Motion hesabı',
                          ),
                        ),
                      ),
                    if (accountPageBuilder != null)
                      Text(
                        UiLanguage.text(
                          context,
                          en: 'Browse lessons without signing in. Existing guest history stays on this device and does not move into an account.',
                          tr: 'Derslere giriş yapmadan göz atabilirsiniz. Mevcut misafir geçmişi bu cihazda kalır ve hesaba aktarılmaz.',
                        ),
                        style: text.body.copyWith(
                          fontSize: 13,
                          color: colors.inkMuted,
                        ),
                      ),
                    const SizedBox(height: 14),
                    UnknownGlassPanel(
                      padding: const EdgeInsets.all(13),
                      borderRadius: 14,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  UiLanguage.text(
                                    context,
                                    en: 'SUBSCRIPTIONS',
                                    tr: 'ABONELİKLER',
                                  ),
                                  style: text.label.copyWith(fontSize: 9),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  UiLanguage.text(
                                    context,
                                    en: 'Subscription sales are closed in this release. No purchase is needed for the course.',
                                    tr: 'Bu sürümde abonelik satışı kapalıdır. Kurs için satın alma gerekmez.',
                                  ),
                                  key: const Key('store-prices-in-account'),
                                  style: text.mono.copyWith(
                                    color: colors.ink,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // The real purchase action lives in Motion account and has
                    // a store handler; this settings panel does not fake a CTA.
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  key: const Key('why-not-link'),
                  onTap: onOpenWhyNot,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              UiLanguage.text(
                                context,
                                en: "What we don't do, and why",
                                tr: 'Yapmadıklarımız ve nedenleri',
                              ),
                              style: text.body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              UiLanguage.format(
                                context,
                                en:
                                    '{value1} things left out on purpose, '
                                    'each with its reason.',
                                tr:
                                    '{value1} özellik bilinçli olarak dışarıda; '
                                    'her birinin gerekçesi var.',
                                args: {'value1': excludedCount},
                              ),
                              style: text.body.copyWith(
                                fontSize: 12.5,
                                color: colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: colors.judgement,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              // DEV HARNESS girişi — YALNIZ debug derlemede (J-072). Bilerek
              // giydirilMEDİ: bir dev-harness'ı ürün diliyle süslemek
              // "kamera var" izlenimini güçlendirirdi (§7.8 ruhu SettingsPage
              // için de geçerli).
              if (CameraHarnessScreen.isAvailable) ...<Widget>[
                const SizedBox(height: 24),
                Divider(color: colors.outline),
                Builder(
                  builder: (BuildContext context) => ListTile(
                    key: const Key('open-camera-harness'),
                    iconColor: colors.inkSubtle,
                    textColor: colors.inkMuted,
                    leading: const Icon(Icons.biotech_outlined),
                    title: const Text('Camera bridge — dev harness'),
                    subtitle: Text(
                      'Debug build only. Raw bridge metrics, no preview, no judgement.',
                      style: TextStyle(color: colors.inkSubtle),
                    ),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const CameraHarnessScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Honest persistence state, shared by locale and appearance changes.
class _PreferencesStatus extends StatelessWidget {
  const _PreferencesStatus(this.controller);
  final AppPreferencesController controller;
  @override
  Widget build(BuildContext context) {
    final save = controller.savePhase;
    final read = controller.readPhase;
    final readProblem =
        read == PreferencesReadPhase.invalid ||
        read == PreferencesReadPhase.unavailable ||
        read == PreferencesReadPhase.timedOut ||
        read == PreferencesReadPhase.recovered;
    final message = switch (save) {
      PreferencesSavePhase.saving => UiLanguage.text(
        context,
        en: 'Saving device preferences…',
        tr: 'Cihaz tercihleri kaydediliyor…',
      ),
      PreferencesSavePhase.failed => UiLanguage.text(
        context,
        en: 'Your choices apply now, but could not be saved. Any previously saved choices are kept.',
        tr: 'Seçimlerin şu anda geçerli ancak kaydedilemedi. Varsa önceki kayıtlı seçimler korunuyor.',
      ),
      PreferencesSavePhase.uncertain => UiLanguage.text(
        context,
        en: 'Your choices apply now. Saving could not be confirmed; retry to save the current choices.',
        tr: 'Seçimlerin şu anda geçerli. Kayıt doğrulanamadı; mevcut seçimleri kaydetmek için yeniden dene.',
      ),
      PreferencesSavePhase.saved =>
        controller.persistent
            ? UiLanguage.text(
                context,
                en: 'Saved on this device.',
                tr: 'Bu cihaza kaydedildi.',
              )
            : UiLanguage.text(
                context,
                en: 'Applied for this session.',
                tr: 'Bu oturum için uygulandı.',
              ),
      PreferencesSavePhase.idle =>
        readProblem
            ? UiLanguage.text(
                context,
                en: 'Saved preferences could not be fully read. Current preferences are shown; nothing was overwritten.',
                tr: 'Kayıtlı tercihler tam okunamadı. Mevcut tercihler gösteriliyor; hiçbir kaydın üzerine yazılmadı.',
              )
            : '',
    };
    if (message.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            key: const Key('settings.preferences.status'),
            style: JText.of(context).bodyMuted,
          ),
        ),
        if (save == PreferencesSavePhase.failed ||
            save == PreferencesSavePhase.uncertain)
          TextButton(
            key: const Key('settings.preferences.retry'),
            onPressed: () async {
              await controller.retrySave();
            },
            child: Text(
              UiLanguage.text(
                context,
                en: 'Retry saving preferences',
                tr: 'Tercihleri kaydetmeyi yeniden dene',
              ),
            ),
          ),
      ],
    );
  }
}

const _languageNames = <String, String>{
  'tr': 'Türkçe',
  'en': 'English',
  'es-419': 'Español (Latinoamérica)',
  'pt-BR': 'Português (Brasil)',
  'de': 'Deutsch',
  'fr': 'Français',
  'ja': '日本語',
  'ar': 'العربية',
  'it': 'Italiano',
  'ko': '한국어',
  'id': 'Bahasa Indonesia',
  'pl': 'Polski',
  'hi': 'हिन्दी',
  'zh-Hans': '简体中文',
};
