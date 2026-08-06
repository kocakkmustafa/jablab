import 'package:flutter/material.dart';

import 'camera_harness_screen.dart';
import 'design_tokens.dart';

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
/// Fiyat yuvası tasarımın kendi "Tier 2-d — bilmiyorum" (kesikli kenar)
/// diliyle çiziliyor: `{price}` çalışma-zamanı yuvası henüz bağlı değil,
/// bu da tam olarak o katmanın rezerve ettiği anlam ("ölçülmedi/bilinmiyor"),
/// süs değil.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onOpenWhyNot});

  final VoidCallback onOpenWhyNot;

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
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text('Settings',
                        style: JText.pageTitle.copyWith(fontSize: 30, letterSpacing: -.9)),
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
                          Text('SUBSCRIPTION', style: JText.label.copyWith(color: JColors.ember)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: JColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('FREE PLAN',
                                style: JText.label.copyWith(color: JColors.ink3, letterSpacing: 1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Full corner',
                          style: JText.pageTitle.copyWith(fontSize: 28, letterSpacing: -1)),
                      const SizedBox(height: 8),
                      Text(
                        'The first assessment and the first course are free — you '
                        'see what the coaching is actually like before anything is '
                        'asked of you.',
                        style: JText.body.copyWith(fontSize: 14, color: JColors.ink2),
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
                                  Text('PRICE', style: JText.label.copyWith(fontSize: 9)),
                                  const SizedBox(height: 5),
                                  Text('Pricing is not set yet.',
                                      key: const Key('pricing-not-set'),
                                      style: JText.mono.copyWith(color: JColors.ink, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: JColors.ember,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Center(
                            child: Text('Continue',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF180A05))),
                          ),
                        ),
                      ),
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
                              Text("What we don't do, and why",
                                  style: JText.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Seven things left out on purpose, each with its reason.',
                                  style: JText.body.copyWith(fontSize: 12.5, color: JColors.ink2)),
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
                          style: TextStyle(color: JColors.ink3)),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (_) => const CameraHarnessScreen()),
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
