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
  const SettingsPage({
    super.key,
    required this.onOpenWhyNot,
    required this.excludedCount,
  });

  final VoidCallback onOpenWhyNot;

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
                          // J-152 (koordinatör hükmü 10:23): başlık
                          // `SUBSCRIPTION` idi ve rozet `FREE PLAN` — ikisi
                          // birlikte bir **plan hiyerarşisi** iddia ediyordu
                          // (*"free olan varsa başkası da vardır"*). Ölçüm:
                          // **ne IAP var ne ikinci plan.** J-124'ün sınıfı —
                          // üretici yok ama beyan onu anlatıyor.
                          //
                          // Ve ikisi birlikte altındaki DÜRÜST cümleyi de
                          // zehirliyordu: *"Pricing is not set"* tek başına
                          // dürüsttü; plan hiyerarşisiyle okununca
                          // *"fiyatlandırma geliyor"* oluyordu.
                          //
                          // ⚖️ Bu bir DÜRÜSTLÜK kararı, iş modeli kararı
                          // DEĞİL: abonelik gelirse başlık O ZAMAN doğru
                          // olur; bugün değil.
                          Text('ACCESS', style: JText.label.copyWith(color: JColors.ember)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: JColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('NO PAYWALL',
                                // `ink3` idi: 10 puntoda 3,51:1, eşik 4,5
                                // (J-126). Sayfa A'nın `NOT OPEN` rozetiyle
                                // AYNI kalıptan yapılmıştı (J-102'de öyle
                                // kaydedilmiş) — kalıp paylaşılınca kusur da
                                // paylaşılmış. Kapı ikizi buldu, ben birini.
                                style: JText.label.copyWith(color: JColors.ink2, letterSpacing: 1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // J-155: başlık `Full corner` idi — bir **KADEME ADI**
                      // ("tam" olan varsa eksik olan da vardır). J-152'de
                      // hiyerarşi SÖZCÜKLERİNİ kaldırdım (`SUBSCRIPTION` /
                      // `FREE PLAN`) ama **kademenin ADINI bıraktım**; aynı
                      // iddia, bir satır yukarıda hayatta kaldı.
                      //
                      // Ve `Full corner` **başka hiçbir yerde geçmiyor** —
                      // J-124'ün sınıfı: ürün bir kavramı adlandırıyor,
                      // karşılığı yok. (*"Corner"* ürünün koçluk metaforu ve
                      // meşru: *"Your corner calls out guard…"*; sorun
                      // *"Full"*.)
                      //
                      // Yeni başlık bugünün olgusunu söylüyor — rozetle ve
                      // altındaki cümleyle aynı şeyi, üç kez değil bir kez.
                      Text('Everything is open',
                          style: JText.pageTitle.copyWith(fontSize: 28, letterSpacing: -1)),
                      const SizedBox(height: 8),
                      Text(
                        // J-151: eski metin *"The first **assessment** and the
                        // first course are free — … before anything is **asked
                        // of you**"* diyordu. İKİ kusur: ① `assessment`
                        // sözcüğü TÜM DEPODA yalnız bu cümlede geçiyordu —
                        // öyle bir aşama YOK (J-124'ün sınıfı) ② *"before
                        // anything is asked"* gelecekte bir istek İMÂ ediyor,
                        // yani vaat — ve kapının kelime listesinde yok
                        // (`yet`/`soon`/`will` değil). Yeni metin yalnız
                        // BUGÜNÜ söylüyor: ödeme duvarı yok, kilitli dersler
                        // ödeme yüzünden değil ÖLÇÜM yüzünden kapalı ve her
                        // biri sebebini yazıyor.
                        'Nothing here is behind a payment. A few lessons are '
                        'locked, and not because of money — each one names the '
                        'measurement it is missing.',
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
                                  Text('Pricing is not set.',
                                      key: const Key('pricing-not-set'),
                                      style: JText.mono.copyWith(color: JColors.ink, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ⛔ BURADA ÖLÜ BİR "Continue" DÜĞMESİ VARDI — KALDIRILDI
                      // (J-254). Ekranın görsel olarak EN BASKIN öğesiydi:
                      // tam genişlik, ember dolgu, `PRICE / Pricing is not
                      // set.` satırının hemen altında. Ve **hiçbir şey
                      // yapmıyordu**: dosyadaki üç `onTap` geri (61) ·
                      // why-not (189) · kamera köprüsü (228); bu blokta
                      // `InkWell`/`GestureDetector` YOKTU (ölçüldü).
                      //
                      // İki ayrı kusur taşıyordu:
                      //  1. **Ölü affordance** — J-094'ün sınıfı: ekran,
                      //     kullanıcıya yapamayacağı bir eylemi sunuyordu.
                      //  2. **Var olmayan bir akışı İMÂ ediyordu** — aynı
                      //     panel `NO PAYWALL` · `Everything is open` ·
                      //     `Pricing is not set.` diyor. Bir satın alma
                      //     CTA'sı, olmayan bir ödeme adımını vaat eder;
                      //     J-151'de *"before anything is asked of you"*
                      //     cümlesi tam bu sebeple silinmişti — **cümleyi
                      //     silip DÜĞMEYİ bırakmışız.**
                      //
                      // ⚠️ Fiyat GELDİĞİNDE geri gelecek olan şey bir düğme
                      // değil bir AKIŞTIR; o gün buraya işleyicisiyle birlikte
                      // konur. Boş kabuğu şimdiden bırakmak, J-044'ün 17 ölü
                      // alanının yüzey karşılığı olurdu.
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
                              Text(
                                  '$excludedCount things left out on purpose, '
                                  'each with its reason.',
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
