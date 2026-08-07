import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/design_tokens.dart';
import 'package:jablab/app/live_honesty.dart';
import 'package:jablab/app/skeleton_overlay.dart';
import 'package:jablab/shell_candidate/live_surface.dart'
    show LiveCoachSurface, LiveState;

/// SORUMLULUK EKSENİ EKRANA ULAŞIYOR MU (J-110).
///
/// ## Neden metin testi YETMEZ
///
/// J-103 *"sen kadrajda değilsin"* ile *"benim okumam bozuk"* farkını
/// METİNDE ayırdı ve testi de metni ölçtü — geçti. Ama telefon 2-3 m uzakta
/// ve kullanıcının okuduğu **ilk şey renk, ikinci şey ikon, cümle üçüncü**.
/// Düzeltme doğruydu ve kullanıcıya ULAŞMIYORDU. Bu dosya o boşluğu ölçer:
/// ayrımın GÖRSEL tarafı gerçekten farklı mı çiziliyor.
void main() {
  test('üç kovanın rengi de BİRBİRİNDEN farklı', () {
    // Ayrım "var" ama iki kova aynı renkteyse ayrım YOK demektir — ve bunu
    // gözle fark etmek zor, testle kolay.
    final Set<Color> colors =
        LiveHonestyBucket.values.map((LiveHonestyBucket b) => b.accent).toSet();
    expect(colors.length, LiveHonestyBucket.values.length,
        reason: 'iki kova aynı rengi paylaşıyor — uzaktan ayırt edilemez');
  });

  test('üç kovanın ikonu da BİRBİRİNDEN farklı', () {
    final Set<IconData> icons =
        LiveHonestyBucket.values.map((LiveHonestyBucket b) => b.icon).toSet();
    expect(icons.length, LiveHonestyBucket.values.length);
  });

  test('ÜÇ KOVA DA ZEMİNDE GÖRÜNÜR — WCAG 2.2 SC 1.4.11 (metin-dışı 3:1)', () {
    // ## Neden bu kapı, "üç renk farklı" testinin YANINA eklendi
    //
    // O test `Color` KİMLİĞİNİ ölçüyordu ve GEÇİYORDU — ama ölçüm başka
    // şey söyledi: `none` kovası `ink4` iken zemine karşı **1,80:1**
    // veriyordu, eşiğin (3,0) altında. Yani "analiz hiç yok" ikonu
    // pratikte görünmüyordu ve test bunu göremiyordu: üç renk gerçekten
    // farklıydı, biri sadece görünmüyordu. **Beyanın varlığı doğruluğu
    // değildir** — bu gecenin dersi, kendi işime uygulandı.
    //
    // Eşik İCAT DEĞİL: WCAG 2.2 SC 1.4.11, kullanıcı arayüzü bileşenleri
    // ve grafik nesneler için 3:1. Dış standart, bizim seçimimiz değil.
    for (final LiveHonestyBucket b in LiveHonestyBucket.values) {
      final double r = _contrast(_over(b.accent, JColors.ground), JColors.ground);
      expect(r, greaterThanOrEqualTo(3.0),
          reason: '$b zemine karşı ${r.toStringAsFixed(2)}:1 — eşik 3,0. '
              'Görünmeyen bir dürüst hâl, susmakla aynı şeydir.');
    }
  });

  test('KULLANICI METNİ TOKENLARI OKUNUR — WCAG 2.2 AA (J-116)', () {
    // ## Neden bu, kova testinin YANINA geldi
    //
    // J-114'te `none` kovasının ikonunu `ink4`ten çıkardım — **ve örüntüyü
    // değil ÖRNEĞİ düzeltmişim.** Aynı `ink4` bir dosya ötede kamera
    // yer-tutucusunun ALTYAZISINDA duruyordu (1,80:1) ve `JText.mono`
    // tokenının kendi varsayılanı (`ink3`, 3,51:1) da eşiğin altındaydı.
    // Aile dersi #8: **tuzak dosyaya değil DESENE yazılır** — bu kapı o
    // dersin bu gecedeki bedelinin karşılığı.
    //
    // Eşikler WCAG 2.2 SC 1.4.3: normal metin 4,5 · BÜYÜK metin 3,0
    // (≥24px, ya da ≥18,66px + kalın). İcat yok, sınıflandırma standardın.
    // ⚠️ Tokenlar derleme-zamanı sabit DEĞİL (`GoogleFonts` çalışma
    // zamanında çözülüyor), o yüzden liste değil tek tek çağrı. Yeni bir
    // token eklendiğinde buraya yazılmazsa kapı onu görmez — bu kapının
    // beyan edilmiş sınırı ve `$producers`taki `liveKeys` ile aynı sınıf:
    // elle tutulan bir liste, otomatik bir kapsam değil.
    void check(String name, TextStyle style) {
      final double size = style.fontSize ?? 14;
      final bool bold =
          (style.fontWeight?.value ?? 400) >= FontWeight.w700.value;
      final bool large = size >= 24 || (bold && size >= 18.66);
      final double threshold = large ? 3.0 : 4.5;
      final Color c = style.color!;
      final double r = _contrast(_over(c, JColors.ground), JColors.ground);
      expect(r, greaterThanOrEqualTo(threshold),
          reason: '$name ${size.toStringAsFixed(0)}px → '
              '${r.toStringAsFixed(2)}:1, eşik $threshold. Okunamayan bir '
              'cümle, yazılmamış bir cümledir.');
    }

    check('JText.body', JText.body);
    check('JText.bodyMuted', JText.bodyMuted);
    check('JText.label', JText.label);
    check('JText.mono', JText.mono);
    check('JText.correction', JText.correction);
    check('JText.pageTitle', JText.pageTitle);
    check('JText.clock', JText.clock);
  });

  test('SÖNÜK ama OKUNUR — hiyerarşi kaybolmadı', () {
    // Kontrastı yükseltmenin ucuz yolu her şeyi `ink` yapmaktır ve bu,
    // görsel hiyerarşiyi öldürürdü. Ölçü: birincil metin ile sönük metin
    // arasında hâlâ belirgin bir fark VAR (ikisi de eşiği geçerken).
    final double primary =
        _contrast(_over(JText.body.color!, JColors.ground), JColors.ground);
    final double muted =
        _contrast(_over(JText.mono.color!, JColors.ground), JColors.ground);
    expect(primary, greaterThan(muted * 2),
        reason: 'sönük ile birincil metin ayrışmıyor — okunurluk uğruna '
            'hiyerarşi feda edilmiş');
  });

  test('HİÇBİR kova HÜKÜM (ember) tonunu kullanmıyor', () {
    // Ember tasarımda Tier 3'e — HÜKÜM katmanına — rezerve. "Göremiyorum"
    // bir hüküm değil; ember'a kaymak, susan bir katmanı konuşuyormuş gibi
    // göstermek olurdu.
    for (final LiveHonestyBucket b in LiveHonestyBucket.values) {
      expect(b.accent, isNot(JColors.ember),
          reason: '$b hüküm tonunu kullanıyor');
    }
  });

  testWidgets('DONMUŞ yüzeyin "göremiyorum" ikonu ARTIK KIRMIZI DEĞİL',
      (WidgetTester t) async {
    // Kusurun kendisi buydu: `LiveCoachSurface` ikonu `colorScheme.error`
    // ile çiziyor ve bu HER dürüst hâle basılıyordu. "Kimse yok" bir hata
    // değildir — kırmızı, kullanıcıya yanlış bir şey yaptığını söyler.
    // Widget DONMUŞ; renk `Theme` sarmalıyla dışarıdan geliyor.
    for (final LiveHonestyBucket bucket in LiveHonestyBucket.values) {
      await t.pumpWidget(MaterialApp(
        home: Theme(
          data: bucket.themeFor(jablabSessionTheme),
          child: Scaffold(
            body: LiveCoachSurface(
              state: LiveState.noVerdict,
              eventCount: null,
              noVerdictReason: 'test',
              preview: SkeletonPreview(
                  state: LiveState.noVerdict, bucket: bucket),
            ),
          ),
        ),
      ));

      final Iterable<Icon> icons = t.widgetList<Icon>(find.byType(Icon));
      expect(icons, isNotEmpty);
      final Icon judgementIcon = icons.firstWhere(
          (Icon i) => i.icon == Icons.visibility_off_outlined,
          orElse: () => throw StateError('donmuş yüzeyin ikonu bulunamadı — '
              'kabuk değişmiş olabilir, bu test onu ölçüyor'));
      expect(judgementIcon.color, bucket.accent,
          reason: '$bucket kovası donmuş yüzeye ULAŞMIYOR — Theme sarmalı '
              'kopmuş ve ikon varsayılan hata rengine dönmüş');
      expect(judgementIcon.color, isNot(const ColorScheme.dark().error),
          reason: 'hata kırmızısı geri gelmiş');
    }
  });

  testWidgets('kova ikonu ÖNİZLEME yuvasında görünüyor', (WidgetTester t) async {
    // İkon ekseni donmuş yüzeyden değil app'in KENDİ yuvasından geliyor
    // (`LiveCoachSurface`in ikonu sabit ve değiştirilemiyor). Bu test o
    // taşımanın gerçekten çalıştığını ölçüyor — yoksa üç kova aynı ikonla
    // çizilir ve renk tek başına kalır.
    for (final LiveHonestyBucket bucket in LiveHonestyBucket.values) {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SkeletonPreview(state: LiveState.noVerdict, bucket: bucket),
        ),
      ));
      expect(find.byIcon(bucket.icon), findsOneWidget,
          reason: '$bucket ikonu önizlemede çizilmiyor');
    }
  });
}

/// Alfa taşıyan bir rengi zemine BİNDİRİR. Kontrast, ekranda gerçekten
/// oluşan renkten hesaplanmalı: `ink` yarı saydamken `ink`in kendi
/// parlaklığını ölçmek, ölçmediğimiz bir pikseli ölçmek olurdu.
Color _over(Color fg, Color bg) {
  double c(double f, double b) => f * fg.a + b * (1 - fg.a);
  return Color.from(
      alpha: 1, red: c(fg.r, bg.r), green: c(fg.g, bg.g), blue: c(fg.b, bg.b));
}

/// WCAG 2.x bağıl parlaklık ve kontrast oranı — formül standardın kendisi
/// (sRGB doğrusallaştırma + 0.2126/0.7152/0.0722 ağırlıkları), burada
/// uydurulmuş hiçbir katsayı yok.
double _luminance(Color c) {
  double lin(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

double _contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}
