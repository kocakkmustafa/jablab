import 'dart:io';
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

  test('SCRIM ÜSTÜNDEKİ ALTYAZI, İSKELET EN PARLAKKEN BİLE OKUNUR (J-117)',
      () {
    // ## Hükmün ayrılmaz parçası — kapsam, scrim'le BİRLİKTE genişledi
    //
    // J-116'da kontrastı ZEMİNE karşı ölçtüm ve iskeletin örttüğü durumu
    // "kapsam dışı" diye dürüstçe beyan ettim. Scrim gelince o beyan
    // BAYATLADI: artık efektif zemin scrim'li zemin. Ölçmeye devam
    // etmemek, J-114'te kendi koyduğum kuralın (*"`ink` yarı saydamken
    // `ink`in kendi parlaklığını ölçmek, ölçmediğimiz bir pikseli ölçmek
    // olurdu"*) aynı ihlalini bir katman yukarıda tekrarlamak olurdu.
    //
    // ## En kötü hâl UYDURULMADI, painter'dan türetildi
    //
    // `_SkeletonPainter` eklemleri `JColors.cool` ile, alfa
    // `_alpha(i) * sceneAlpha` çiziyor. Tavan: `_alpha` en fazla
    // `0.15 + 0.85*1.0 = 1.0`, `sceneAlpha` temiz hâlde `0.85` →
    // **cool @ 0.85**. Altyazının arkasına düşebilecek en parlak piksel bu.
    const double maxJointAlpha = 0.85;

    // Gradyanın ÜST ucu (en açık zemin): deep @ .55 over ground.
    final Color gradientTop = _blend(JColors.deep, 0.55, JColors.ground);
    final Color brightestJoint =
        _blend(JColors.cool, maxJointAlpha, gradientTop);
    final Color scrimmed =
        _blend(JColors.ground, 0.81, brightestJoint);
    final Color caption = _blend(JColors.ink2, 1.0, scrimmed);

    final double r = _contrast(caption, scrimmed);
    expect(r, greaterThanOrEqualTo(4.5),
        reason: 'iskelet altyazının üstünden geçerken metin '
            '${r.toStringAsFixed(2)}:1 — scrim yetmiyor. Örtüşmede '
            'okunmayan bir açıklama, hiç yazılmamış bir açıklamadır.');

    // NEGATİF İKİZ: scrim OLMASAYDI kırılırdı. Bu satır olmadan test,
    // scrim silindiğinde de yeşil kalabilecek bir şey ölçüyor olabilirdi.
    final Color noScrim = _blend(JColors.ink2, 1.0, brightestJoint);
    expect(_contrast(noScrim, brightestJoint), lessThan(4.5),
        reason: 'scrim olmadan da geçiyorsa bu test scrim\'i ÖLÇMÜYOR — '
            'vakum-doğru bir kapı (aile dersi #4)');
  });

  test('YERİNDE GEÇİLEN metin renkleri de OKUNUR (J-126)', () {
    // ## Kapı envanterinin ürettiği bulgu
    //
    // Yukarıdaki token testi `JText.*` VARSAYILANLARINI ölçüyor. Ama
    // yüzeyler rengi çoğu zaman **yerinde** geçiyor:
    // `JText.label.copyWith(color: JColors.ink3)`. O yol kapının DIŞINDAYDI
    // — ve içinde gerçek bir ihlal vardı: kapalı disiplin rozeti
    // (`NOT OPEN`) 10 puntoda **3,51:1**, eşik 4,5.
    //
    // İkinci kez aynı ders: **J-116'da örüntüyü değil örneği düzeltmiştim**;
    // burada kapının KAPSAMI örüntünün yalnız bir yarısını tutuyordu.
    // Kapsamı ölçmeden "kapattım" demek, J-122'nin (kapsam ≠ alan) test
    // tarafı.
    //
    // ⚠️ BU KAPININ GÖREMEDİĞİ, beyan: rengi bir DEĞİŞKENDEN alan yerler
    // (`color: fg`) çözülemiyor — statik metinde değer yok. Onlar hâlâ
    // kapının dışında ve bunu bilerek yazıyorum; "hepsini tarıyor" demek
    // yanlış olurdu.
    TextStyle? base(String name) => switch (name) {
          'body' => JText.body,
          'bodyMuted' => JText.bodyMuted,
          'label' => JText.label,
          'mono' => JText.mono,
          'correction' => JText.correction,
          'pageTitle' => JText.pageTitle,
          'clock' => JText.clock,
          _ => null,
        };
    Color? tone(String name) => switch (name) {
          'ink' => JColors.ink,
          'ink2' => JColors.ink2,
          'ink3' => JColors.ink3,
          'ink4' => JColors.ink4,
          'cool' => JColors.cool,
          'cool2' => JColors.cool2,
          'cool3' => JColors.cool3,
          _ => null,
        };

    final RegExp override = RegExp(
        r'JText\.(\w+)\s*\n?\s*\.?copyWith\(([^)]*)\)', dotAll: true);
    final RegExp colorRef = RegExp(r'JColors\.(\w+)');
    final RegExp sizeRef = RegExp(r'fontSize:\s*([\d.]+)');

    /// YEREL RENK DEĞİŞKENLERİNİ ÇÖZER (J-127). Kapının kör noktası
    /// buydu ve **boş değildi**: `final Color fg = locked ? ink3 : ink;`
    /// satırı kilitli ders ADINI 3,51:1'de tutuyordu. Kapsam sınıfı
    /// *"ölçüm yöntemi"* idi — yani kapatılabilirdi, ve kapatıldı.
    ///
    /// Yalnız `JColors.*`tan kurulan yerel sabitler çözülüyor; çalışma
    /// zamanından gelen bir renk hâlâ dışarıda ve o **gerçekten** statikle
    /// çözülemez.
    Map<String, String> localColors(String src) {
      final Map<String, String> out = <String, String>{};
      for (final RegExpMatch m in RegExp(
              r'final\s+Color\s+(\w+)\s*=\s*([^;]+);')
          .allMatches(src)) {
        out[m.group(1)!] = m.group(2)!;
      }
      return out;
    }

    final List<String> hits = <String>[];
    for (final FileSystemEntity f
        in Directory('lib/app').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String src = f.readAsStringSync();
      final Map<String, String> locals = localColors(src);
      for (final RegExpMatch m in override.allMatches(src)) {
        final TextStyle? b = base(m.group(1)!);
        if (b == null) continue;
        final String args = m.group(2)!;
        if (!args.contains('color:')) continue;
        final double size =
            double.tryParse(sizeRef.firstMatch(args)?.group(1) ?? '') ??
                b.fontSize ??
                14;
        final bool bold = (b.fontWeight?.value ?? 400) >= FontWeight.w700.value;
        final double threshold =
            (size >= 24 || (bold && size >= 18.66)) ? 3.0 : 4.5;
        // ⚠️ YALNIZ `color:` BAĞI — ilk yazışımda argümanların TAMAMINDAKİ
        // `JColors.*` referanslarını alıyordum ve kapı kendi fazla
        // genişliğini gösterdi: karşılamadaki bağlantının `decorationColor`
        // (alt çizgi) rengini METİN rengi sanıp 2,10:1 diye bildirdi.
        // Alt çizgi bir metin değil; onu metin eşiğiyle ölçmek, standardı
        // ölçmediği şey için kullanmak olurdu (J-114'ün aynı dersi).
        //
        // TERNARY korunuyor: `color: locked ? ink2 : cool2` — `color:`
        // bağının İÇİNDEKİ her dal ölçülüyor, çünkü koşulun bir yarısını
        // kör bırakmak ihlali yarı yarıya gizler.
        String colorArg = _colorBinding(args);
        // Değişken adı geçiyorsa yerel tanımıyla DEĞİŞTİR — böylece
        // `color: fg` de ölçülür.
        for (final MapEntry<String, String> v in locals.entries) {
          colorArg = colorArg.replaceAll(RegExp('\\b${v.key}\\b'), v.value);
        }
        for (final RegExpMatch c in colorRef.allMatches(colorArg)) {
          final Color? col = tone(c.group(1)!);
          if (col == null) continue;
          final double r =
              _contrast(_over(col, JColors.ground), JColors.ground);
          if (r < threshold) {
            hits.add('${f.uri.pathSegments.last} JText.${m.group(1)} + '
                '${c.group(1)} @${size.toStringAsFixed(0)}px → '
                '${r.toStringAsFixed(2)}:1 (eşik $threshold)');
          }
        }
      }
    }
    expect(hits, isEmpty,
        reason: 'yerinde geçilen metin rengi okunmuyor: ${hits.join(" · ")}');
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
                  state: LiveState.noVerdict,
                  bucket: bucket,
                  analysisRunning: false),
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
          body: SkeletonPreview(
              state: LiveState.noVerdict,
              bucket: bucket,
              analysisRunning: false),
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

/// [fg]i [alpha] ile [bg] üstüne bindirir. `_over`den farkı: alfayı
/// rengin kendisinden değil AÇIKÇA alması — scrim gibi katmanları
/// modellerken alfa bir kompozisyon parametresidir, rengin özelliği değil.
Color _blend(Color fg, double alpha, Color bg) {
  final double a = alpha * fg.a;
  double c(double f, double b) => f * a + b * (1 - a);
  return Color.from(
      alpha: 1, red: c(fg.r, bg.r), green: c(fg.g, bg.g), blue: c(fg.b, bg.b));
}

/// `copyWith` argümanlarından YALNIZ `color:` bağının değerini çıkarır.
/// Sonraki üst-düzey virgüle kadar okur, yani ternary (`a ? X : Y`) tek
/// parça olarak gelir; `decorationColor:`/`backgroundColor:` gibi başka
/// renk parametreleri DIŞARIDA kalır.
String _colorBinding(String args) {
  final int i = RegExp(r'(^|,)\s*color:').firstMatch(args)?.end ?? -1;
  if (i < 0) return '';
  int depth = 0;
  for (int j = i; j < args.length; j++) {
    final String ch = args[j];
    if (ch == '(' || ch == '[') depth++;
    if (ch == ')' || ch == ']') depth--;
    if (ch == ',' && depth == 0) return args.substring(i, j);
  }
  return args.substring(i);
}
