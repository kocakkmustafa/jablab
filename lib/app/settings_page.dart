import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: JColors.ground,
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[const Color(0xFF170809), JColors.ground],
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
                Text(
                  UiLanguage.text(context, en: 'Settings', tr: 'Ayarlar'),
                  style: JText.pageTitle.copyWith(
                    fontSize: 30,
                    letterSpacing: -.9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
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
                        style: JText.label.copyWith(color: JColors.ember),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: JColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          UiLanguage.text(context, en: 'COURSE', tr: 'KURS'),
                          style: JText.label.copyWith(
                            color: JColors.ink2,
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
                    style: JText.pageTitle.copyWith(
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
                    style: JText.body.copyWith(
                      fontSize: 14,
                      color: JColors.ink2,
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
                      style: JText.body.copyWith(
                        fontSize: 13,
                        color: JColors.ink2,
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
                      style: JText.body.copyWith(
                        fontSize: 13,
                        color: JColors.ink2,
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
                                style: JText.label.copyWith(fontSize: 9),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                UiLanguage.text(
                                  context,
                                  en: 'Subscription sales are closed in this release. No purchase is needed for the course.',
                                  tr: 'Bu sürümde abonelik satışı kapalıdır. Kurs için satın alma gerekmez.',
                                ),
                                key: const Key('store-prices-in-account'),
                                style: JText.mono.copyWith(
                                  color: JColors.ink,
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
                            style: JText.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            UiLanguage.isTurkish(context)
                                ? '$excludedCount özellik bilinçli olarak dışarıda; '
                                      'her birinin gerekçesi var.'
                                : '$excludedCount things left out on purpose, '
                                      'each with its reason.',
                            style: JText.body.copyWith(
                              fontSize: 12.5,
                              color: JColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: JColors.ember, size: 18),
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
              Divider(color: JColors.hairline),
              Builder(
                builder: (BuildContext context) => ListTile(
                  key: const Key('open-camera-harness'),
                  iconColor: JColors.ink3,
                  textColor: JColors.ink2,
                  leading: const Icon(Icons.biotech_outlined),
                  title: const Text('Camera bridge — dev harness'),
                  subtitle: Text(
                    'Debug build only. Raw bridge metrics, no preview, no judgement.',
                    style: TextStyle(color: JColors.ink3),
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
