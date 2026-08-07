import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// İDDİANIN ÖZNESİ, İDDİANIN SINIFINI BELİRLER (J-186, koordinatör hükmü C).
///
/// ## Ayırıcı ölçüt: ÖZNE — sözcük değil
///
/// İçerikte 8 göreli-vurgu iddiası ölçüldü. Hepsini yasaklamak **gürültü**
/// olurdu; hiçbirini yasaklamamak **yanlış** olurdu. Ayıran şey **özne**:
///
/// | özne | sınıf | dayanağı | adet |
/// |---|---|---|---|
/// | *"çoğu insan / koçlar"* | **alan** iddiası | referans/literatür | 6 → **dokunulmaz** |
/// | *"**biz** izleriz"* | **ürün** iddiası | **kural seti** | 1 → düzeltildi |
/// | *"**biz** en sık sayarız"* | **popülasyon** iddiası | **YOK, olamaz** | 1 → düzeltildi |
///
/// Bu, sözcük → cümle → çerçeve → **özne** merdiveninin dördüncü basamağı:
/// aynı sözcük (*"most"*) üç ayrı sınıfta üç ayrı şey yapıyor.
///
/// ## İki katman, iki ayrı hüküm
///
/// **① ÜRÜN öznesi + göreli vurgu** — *"the thing we watch most"*.
/// Kural setinde **ölçülebilir bir dayanak aranır**; yoktu (5 kod eşit
/// `high`, ve en çok fazda değerlendirilen rear hand değil). Bu **koşullu**
/// bir yasak: **dayanak gelirse iddia geri konabilir.**
///
/// **② ÜRÜN öznesi + KULLANICILAR ARASI karşılaştırma** — *"the single
/// fault we count most often"*. Bunun dayanağı **imkânsız**: telemetri yok,
/// ham video cihazda kalır, oturumlar yereldir — ürün **hangi hatayı en sık
/// saydığını kullanıcılar arasında bilemez**, ve ilk açılışta **hiçbir şey
/// saymamıştır.** Bu, *"analiz başlamamışken çıplak 0 yok"* kuralının cümle
/// hâli ve **kalıcı** bir sınır.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * `$`-önekli iç notlar **taranmaz** — onlar kullanıcı yüzeyi değil,
///   ve içlerinde kusurun kendisi **alıntı** olarak yaşıyor.
/// * İddianın **doğru** olduğunu; yalnız **sınıfına uygun** olduğunu.
/// * Yeni bir özne sınıfı çıkarsa (*"koçunuz"*, *"uygulama"*) bu kapı onu
///   **görmez** ve bunu bilerek yazıyorum.
void main() {
  /// Kullanıcıya giden metinler — `$` iç notlar hariç.
  List<({String path, String text})> surfaces() {
    final List<({String path, String text})> out =
        <({String path, String text})>[];
    for (final String p in <String>[
      'assets/content/library.json',
      'assets/content/cues.en.json',
    ]) {
      void walk(Object? n, String path) {
        if (n is Map) {
          for (final MapEntry<Object?, Object?> e in n.entries) {
            final String k = '${e.key}';
            if (k.startsWith(r'$')) continue; // iç not = yüzey değil
            walk(e.value, '$path.$k');
          }
        } else if (n is List) {
          for (int i = 0; i < n.length; i++) {
            walk(n[i], '$path[$i]');
          }
        } else if (n is String && n.length > 20) {
          out.add((path: path, text: n));
        }
      }

      walk(jsonDecode(File(p).readAsStringSync()), p.split('/').last);
    }
    return out;
  }

  /// ② POPÜLASYON: ürün öznesi + kullanıcılar arası sıklık.
  final RegExp population = RegExp(
      r'\b(we|our)\b[^.]{0,60}\b(count|see|measure|track|record)\w*\b'
      r'[^.]{0,40}\b(most often|most frequently|across (users|sessions|people)'
      r'|of all (our )?(users|sessions))\b',
      caseSensitive: false);

  /// ① VURGU: ürün öznesi + göreli/üstün derece.
  final RegExp emphasis = RegExp(
      r'\b(we|our)\b[^.]{0,60}\b(watch|see|read|grade|measure|track|look'
      r'|check)\w*\b[^.]{0,40}\b(most|more than|primarily|especially'
      r'|above all)\b',
      caseSensitive: false);

  test('② POPÜLASYON iddiası YOK — dayanağı İMKÂNSIZ, kalıcı sınır', () {
    final List<({String path, String text})> s = surfaces();
    expect(s.length, greaterThan(60),
        reason: 'yalnız ${s.length} metin tarandı — gezinme bozuk');

    final List<String> bad = s
        .where((({String path, String text}) x) => population.hasMatch(x.text))
        .map((({String path, String text}) x) => x.path)
        .toList();
    expect(bad, isEmpty,
        reason: 'kullanıcılar arası sıklık iddiası: $bad\n\n'
            'BU DÜZELTİLEMEZ, KALDIRILIR. Ürünün telemetrisi yok (ham video '
            'cihazda, oturumlar yerel) → hangi hatayı en sık saydığını '
            'kullanıcılar arasında BİLEMEZ, ve ilk açılışta hiçbir şey '
            'saymamıştır. "Analiz başlamamışken çıplak 0 yok" kuralının '
            'cümle hâli.');
  });

  test('① VURGU iddiası, kural-setinde DAYANAĞI olmadan geçemez', () {
    final List<String> bad = surfaces()
        .where((({String path, String text}) x) =>
            emphasis.hasMatch(x.text) && !population.hasMatch(x.text))
        .map((({String path, String text}) x) => x.path)
        .toList();
    expect(bad, isEmpty,
        reason: 'ürün öznesiyle göreli vurgu iddiası: $bad\n\n'
            'BU KOŞULLU BİR YASAK. İddia doğruysa DAYANAĞINI GÖSTER: '
            'kural setinde ölçülebilir bir ağırlık (tek başına en yüksek '
            'severity, ya da en çok fazda değerlendirilen kod) varsa iddia '
            'MEŞRUDUR ve bu testin izin listesine gerekçesiyle eklenmelidir. '
            'Bugün dayanak YOK: 5 kod eşit "high" ve en çok fazda '
            'değerlendirilen BALANCE_LOSS (3), rear hand değil (2).');
  });

  test('POZİTİF KONTROL — desenler GERÇEK kusur cümlelerini yakalıyor', () {
    // Kapının kendisi ölçülüyor: yukarıdaki iki "temiz" sonuç, desenlerin
    // hiçbir şey yakalayamamasından da doğabilirdi.
    expect(
        emphasis.hasMatch(
            'the rear hand is the thing we watch most.'),
        isTrue);
    expect(
        population.hasMatch(
            'that is the single fault we count most often.'),
        isTrue);
  });

  test('NEGATİF İKİZ — ALAN iddialarına DOKUNULMUYOR', () {
    // M-F-354: sınırı geniş yazmak, dar yazmak kadar pahalıdır. Bu kapı
    // "most" sözcüğünü yasaklasaydı, ölçülmüş ve meşru 6 alan iddiasını
    // da öldürürdü — ve onlar bu ürünün en iyi yazısı.
    final RegExp domain = RegExp(
        r'\b(most people|coaches disagree|the most common)\b',
        caseSensitive: false);
    final int kept =
        surfaces().where((({String path, String text}) x) => domain.hasMatch(x.text)).length;
    expect(kept, greaterThanOrEqualTo(4),
        reason: 'alan iddiaları $kept\'e düştü — kapı fazla geniş yazılmış '
            've ürünün MEŞRU pedagoji cümlelerini kesiyor olabilir. '
            'Ayırıcı ölçüt ÖZNE: "çoğu insan" bir alan iddiasıdır ve '
            'referansla desteklenir, kural setiyle değil.');

    for (final String ok in <String>[
      'Most people find it about two thirds of what they started with.',
      'the arm is simply where coaches disagree most',
      'The most common fault in the first week is folding forward',
    ]) {
      expect(emphasis.hasMatch(ok), isFalse, reason: 'yanlış yakalama: $ok');
      expect(population.hasMatch(ok), isFalse, reason: 'yanlış yakalama: $ok');
    }
  });

  test('TERS İKİZ — cümleler SİLİNEREK geçilemez, DÜZELTİLEREK geçilir', () {
    // Kapıyı geçmenin yanlış yolu: iki cümleyi tamamen silmek. O zaman
    // ihlal kalmaz ama ÖĞRETİM DEĞERİ de gider. Düzeltilmiş hâllerin
    // varlığı çiviliyor — ikisi de kural setiyle DESTEKLİ iddialar
    // (her iki kod `high` ve gerçekten seslendiriliyor).
    final String lib = File('assets/content/library.json').readAsStringSync();
    expect(lib, contains('When it drops, you will hear about it.'),
        reason: 'stance dersinin düzeltilmiş cümlesi kaybolmuş — sınıfı '
            'DESTEKSİZ idi, yani ölçüm gelirse iddia geri konabilir; '
            'ama cümlenin kendisi silinmemeli');
    expect(lib, contains('It is one of the faults we call out by name.'),
        reason: 'jab dersinin düzeltilmiş cümlesi kaybolmuş — sınıfı '
            'DESTEKLENEMEZ idi (telemetri yok), yani bu KALICI bir sınır '
            've yerine konan cümle onun taşıyıcısı');
  });
}
