import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/settings_page.dart';

/// AYARLAR YÜZEYİ — ÖLÜ AFFORDANS KAPISI (J-254).
///
/// ## Ölçtüğü kusur
///
/// Ayarlar sayfasında **tam genişlik, ember dolgulu bir `Continue` düğmesi**
/// duruyordu — ekranın görsel olarak EN BASKIN öğesi, `PRICE / Pricing is not
/// set.` satırının hemen altında — ve **hiçbir şey yapmıyordu**: o blokta
/// `InkWell`/`GestureDetector` yoktu.
///
/// İki kusur birden:
///  1. **Ölü affordans** (J-094 sınıfı: yapılamayacak bir eylem sunmak).
///  2. **Var olmayan bir akışı ima etmek** — aynı panel `NO PAYWALL`,
///     `Everything is open`, `Pricing is not set.` diyor.
///
/// ## Neden BU kusur bu kadar yaşadı — kapsam boşluğu
///
/// `SettingsPage` **canlı bir rota** ama `yuzey_yuruyusu_test`in yürüyüşünde
/// YOK; yürüyüş karşılama → seçim → kurs → seans zincirini geziyor. Yani bu
/// yüzeyin ne yazdığını **hiçbir kapı okumuyordu**.
/// > ***BİR YÜZEYİ HİÇBİR KAPI OKUMUYORSA, ORADAKİ HER İDDİA DENETİMSİZDİR.***
void main() {
  Future<void> pumpSettings(WidgetTester t) async {
    await t.pumpWidget(MaterialApp(
      home: SettingsPage(onOpenWhyNot: () {}, excludedCount: 12),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('ÖLÜ "Continue" DÜĞMESİ GERİ GELMEDİ', (WidgetTester t) async {
    await pumpSettings(t);
    expect(find.text('Continue'), findsNothing,
        reason: 'ayarlarda işleyicisiz bir `Continue` CTA\'sı var — ölü '
            'affordans, ve olmayan bir ödeme adımını ima ediyor. Fiyat '
            'geldiğinde geri gelecek olan bir DÜĞME değil bir AKIŞTIR; '
            'düğme o gün İŞLEYİCİSİYLE birlikte konur.');
  });

  testWidgets('DOKUNULABİLİR HER ÖĞENİN BİR EYLEMİ VAR', (WidgetTester t) async {
    // Ağacı ölçer: `InkWell` var ama `onTap` yoksa öter.
    //
    // 🔴 ARTIK RİSK — ADIYLA, ÇÜNKÜ SABOTAJLA ÖLÇÜLDÜ:
    // **Bu kapı, J-254'ün kusurunu YAKALAYAMAZ.** Ölü `Continue` düğmesi geri
    // konduğunda (M1) bu test **YEŞİL kaldı**; kırmızıya dönenler yalnız
    // isimli kapı ile ödeme-çelişkisi kapısı oldu. Sebep: ölü düğme bir
    // `InkWell` DEĞİLDİ — sadece `DecoratedBox` + `Text`, yani hiçbir zaman
    // bu kapının paydasına girmedi.
    // > ***BİR KAPININ ADI "GENEL" OLABİLİR AMA PAYDASI DARDIR:*** burada
    // > ölçülen "dokunulabilir görünen her şey" değil, "kendini dokunulabilir
    // > İLAN EDEN her şey". Düğme GİBİ görünen ama öyle ilan etmeyen bir
    // > kutu, tanım gereği görünmez.
    // ⇒ Bu kapı, isimli kapının YERİNE geçmez; onun YANINDA durur.
    await pumpSettings(t);
    final Iterable<InkWell> inkwells = t.widgetList<InkWell>(find.byType(InkWell));
    expect(inkwells, isNotEmpty,
        reason: 'VAKUM: sayfada hiç `InkWell` yok — bu kapı hiçbir şey '
            'ölçmüyor demektir (ayarlar en az geri/why-not taşımalı)');
    for (final InkWell w in inkwells) {
      expect(w.onTap, isNotNull,
          reason: 'dokunulabilir görünen bir öğe işleyicisiz — kullanıcı '
              'dokunur, hiçbir şey olmaz');
    }
  });

  testWidgets('ÖDEME BEYANLARI ÇELİŞMİYOR', (WidgetTester t) async {
    // J-250'nin dersi: cümleler tek tek değil BİRLİKTE okunur. Bu panel
    // "ödeme yok" diyorsa, aynı yüzeyde bir satın alma adımı DURMAMALI.
    await pumpSettings(t);
    expect(find.text('Everything is open'), findsOneWidget);
    expect(find.byKey(const Key('pricing-not-set')), findsOneWidget);
    for (final String s in <String>['Buy', 'Subscribe', 'Upgrade', 'Continue']) {
      expect(find.text(s), findsNothing,
          reason: '"$s" — ödeme yok diyen bir yüzeyde satın alma adımı '
              'duruyor; iki iddia aynı ekranda çelişiyor');
    }
  });
}
