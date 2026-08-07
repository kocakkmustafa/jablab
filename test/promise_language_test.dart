import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// VAAT DİLİ KAPISI (M-F-186) — kullanıcının gördüğü hiçbir cümle bir
/// ZAMAN TAAHHÜDÜ vermez.
///
/// ## Hüküm
///
/// Ostinato'nun 2026-08-07 turunun hükmü, aileye taşındı: **"gerekçenin
/// varlığı 'yet'i affetmiyor — 'yet' bir zaman taahhüdüdür."** İyi yazılmış
/// bir gerekçenin yanına konmuş bir *"yet"* gerekçeyi geçersiz kılmıyor;
/// yanına karşılığı olmayan bir söz ekliyor. *"Bu disiplin açık değil"*
/// dürüstlük; *"henüz açık değil"* takvim.
///
/// ## Neden dosya-dosya düzeltmek YETMEZ
///
/// Bu tur 15 kullanıcı-görünür örneği temizledi. Aile dersi #8 (*tuzak
/// dosyaya değil DESENE yazılır*) 16.'sının yarın sessizce eklenmesini
/// engellemeyi istiyor: bir sonraki içerik turunda *"Not open yet"* yazmak
/// hâlâ en doğal cümle ve hiçbir şey onu durdurmuyordu.
///
/// ## Kapsam — ve BEYAN EDİLMİŞ sınırları
///
/// **Taranan:** `lib/` içindeki Dart DİZE SABİTLERİ ve `assets/content/`
/// JSON'larındaki kullanıcıya giden metin alanları.
///
/// **Taranmayan, gerekçesiyle:**
/// * `lib/shell_candidate/` — DONDURULMUŞ (M-F-25). Orada 6 eşleşme var (biri
///   ERİŞİLEBİLİR ve kullanıcıya görünüyor — J-122) ve
///   bu kapı onları görmüyor; dondurulmuş bir ağacı düzeltmek bu turun
///   yetkisinde değil. **Kabuk terfi turunun borcu** olarak buraya yazıldı;
///   sessizce "temiz" demiyoruz.
/// * **Yorumlar ve doküman satırları** — kullanıcı görmez. Üstelik bu
///   dosyanın kendisi ve kuralı anlatan yorumlar "yet" kelimesini taşımak
///   ZORUNDA; onları ihlal saymak kuralı yazılamaz hâle getirirdi.
/// * `docs/` — sevk edilmiyor. (İçerik-öncü replikler dosyası bir istisna
///   olarak elle temizlendi: oradaki metin bir gün BAĞLANACAK, yani
///   bugünkü hâliyle sevk edilmeye aday.)
void main() {
  /// Bir zaman taahhüdü veren ifadeler. `yet` tek başına yeterli değil —
  /// aynı sınıfın diğer üyeleri de burada, çünkü "yet"i yasaklayıp
  /// "coming soon" yazmak kuralı harfiyen tutup ruhunu çiğnemek olurdu.
  final RegExp promise = RegExp(
    r"\b(yet|soon|coming soon|for now|in a future|will be added|"
    r"we'll add|planned for)\b",
    caseSensitive: false,
  );

  /// Dart kaynağından KULLANICI dizelerini çıkarır.
  ///
  /// Yorumlar ATILIYOR: `///` ve `//` satırları ile `/* */` blokları. Bu
  /// kapının kendi gerekçesi de dahil, bu depoda kuralı ANLATAN yorumlar
  /// kaçınılmaz olarak yasak kelimeyi taşıyor.
  ///
  /// WIDGET ANAHTARLARI da atılıyor (`Key('soon-x')`): anahtar kullanıcıya
  /// görünmez, testlerin tutunduğu bir tanımlayıcıdır. `coming-soon-note`
  /// anahtarını ihlal saymak, görünmeyen bir adı değiştirmeye zorlardı —
  /// görünen kusuru düzeltmeden gürültü üretmek.
  List<String> dartStrings(String source) {
    final String noKeys =
        source.replaceAll(RegExp(r"Key\('[^']*'\)"), 'Key(_)');
    final String noBlock =
        noKeys.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    final String noLine = noBlock
        .split('\n')
        .where((String l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    return RegExp(r"'((?:[^'\\\n]|\\.)*)'")
        .allMatches(noLine)
        .map((RegExpMatch m) => m.group(1)!)
        .toList();
  }

  test('lib/ — kullanıcı dizgelerinde vaat dili YOK', () {
    final List<String> hits = <String>[];
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      // DONDURULMUŞ ağaç — sınıf dokümanındaki gerekçe.
      if (f.path.contains('shell_candidate')) continue;
      for (final String s in dartStrings(f.readAsStringSync())) {
        if (promise.hasMatch(s)) hits.add('${f.path}: "$s"');
      }
    }
    expect(hits, isEmpty,
        reason: 'VAAT DİLİ: ${hits.join(" · ")}\n'
            'Gerekçenin varlığı bunu affetmiyor — bir zaman taahhüdü '
            'veriyorsun ve onu tutan hiçbir şey yok. Cümlenin geri kalanı '
            'zaten dürüstse, taahhüdü SİL: "Not open yet" → "Not open".');
  });

  test('assets/content — kullanıcı metinlerinde vaat dili YOK', () {
    final List<String> hits = <String>[];
    for (final FileSystemEntity f
        in Directory('assets/content').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.json')) continue;
      void walk(Object? node, String path) {
        if (node is String) {
          if (promise.hasMatch(node)) hits.add('${f.path} $path: "$node"');
        } else if (node is List) {
          for (int i = 0; i < node.length; i++) {
            walk(node[i], '$path[$i]');
          }
        } else if (node is Map) {
          node.forEach((Object? k, Object? v) {
            // `$` önekli alanlar TÜRETİM/GEREKÇE notudur, kullanıcıya
            // gitmez — `$planBasis` gibi alanlar bu kuralı ANLATIRKEN
            // kelimeyi kullanabilmeli.
            if (k is String && k.startsWith(r'$')) return;
            walk(v, '$path.$k');
          });
        }
      }

      walk(jsonDecode(f.readAsStringSync()), '');
    }
    expect(hits, isEmpty,
        reason: 'VAAT DİLİ (içerik): ${hits.join(" · ")}');
  });

  test('KAPALI disiplinlerde GELECEK-ZAMAN iddiası YOK', () {
    // ## Neden düz bir `will` yasağı YANLIŞ olurdu
    //
    // İki cümle ölçüldü, ikisi de AYNI kelimeyi taşıyor, ama yalnız biri
    // vaat:
    //
    //   r20 dersi   "…it will tell you if it loses you"      → DOĞRU
    //   taekwondo   "…will carry a visible accuracy warning" → VAAT
    //
    // Fark kelimede değil ÖZNEDE: birincisi kullanıcının birazdan koşacağı
    // turun BUGÜNKÜ davranışını tarif ediyor (`noVerdict` yuvası çalışıyor
    // ve gerçekten söylüyor); ikincisi var OLMAYAN bir disiplin hakkında
    // konuşuyor. Düz bir `will` yasağı doğru cümleyi de kırmızıya çevirir
    // ve kapıyı gürültüye boğardı — ders #5: bir sınırı olduğundan GENİŞ
    // yazmak, dar yazmak kadar pahalı. Bu yüzden kural KAPSAMLI: gelecek
    // zaman yalnız `coming_soon` disiplinlerin metninde yasak.
    final List<String> hits = <String>[];
    final RegExp future = RegExp(r'\bwill\b(?!\s+not\b)', caseSensitive: false);
    for (final Map<String, dynamic> d in _comingSoon()) {
      for (final String text in _userText(d)) {
        if (future.hasMatch(text)) hits.add('${d['id']}: "$text"');
      }
    }
    expect(hits, isEmpty,
        reason: 'kapalı bir disiplin hakkında GELECEK ZAMAN: '
            '${hits.join(" · ")}\nKart zaten "not open" diyor; bu metnin '
            'işi NEDEN kapalı olduğunu söylemek, ne geleceğini değil.');
  });

  test('KAPALI disiplinlerin hepsi kapalı olma SEBEBİNİ taşıyor', () {
    // 2026-08-07 ölçümü: 7'nin YALNIZ 1'i (kickboxing) sebebi söylüyordu;
    // kalanı ya içerik listeliyordu ("Siu Nim Tao through Biu Jee") ya da
    // kapsam beyanı yapıyordu. Bir YOL HARİTASI ile bir DÜRÜSTLÜK BEYANI
    // aynı şey değil: birincisi ne geleceğini söyler, ikincisi neden bugün
    // olmadığını. Kart zaten "not open" diyor — NEDEN'i bu metin taşımalı.
    //
    // ⚠️ BEYAN EDİLMİŞ SINIR: bu kapı metnin bir engel sözcüğü TAŞIDIĞINI
    // ölçer, gerekçenin DOĞRU ya da iyi olduğunu değil. Kelime listesi bir
    // kalite ölçüsü değil, "burada bir gerekçe olması gerektiği"nin
    // hatırlatıcısı. Kaliteyi insan okuması doğrular; bu ayrımı silmek
    // testi yalancı yapar.
    final RegExp blocker = RegExp(
        r"\b(not in|not built|missing|reference|cannot|can't|do not|"
        r"does not|we have one|refuses|stays out|is not)\b",
        caseSensitive: false);
    final List<String> silent = <String>[];
    for (final Map<String, dynamic> d in _comingSoon()) {
      final String blurb = (d['blurb'] as String?) ?? '';
      if (!blocker.hasMatch(blurb)) silent.add(d['id'] as String);
    }
    expect(silent, isEmpty,
        reason: 'kapalı ama NEDEN kapalı olduğunu söylemeyen disiplin: '
            '$silent');
  });

  test('DONDURULMUŞ kabuk: ERİŞİLEBİLİR ihlal SAYISI ölçülü (J-122)', () {
    // ## Kapının kör noktası ölçüldü — ve içinde CANLI bir ihlal çıktı
    //
    // Bu kapı `shell_candidate/`ı taramıyor (dondurulmuş, M-F-25) ve o
    // kararı *"orada bir şey yok"* sanmakla karıştırmamak için sayıyı
    // burada tutuyordu: **6**. Ama sayı tek başına yanıltıcıydı — aile
    // dersi J-115: *kod taşıyan bir alanın VAR OLMASI onu sızıntı yapmaz,
    // NEREYE GİTTİĞİ yapar.*
    //
    // Erişilebilirlik ölçüldü (`lib/app/`ın donmuş ağaçtan ne İTHAL
    // ettiğine bakarak):
    //
    //   library_pages `LibraryPage`/`_ItemCard`/`ItemPage`  → 4 ihlal,
    //     app YALNIZ `WhyNotPage`i ithal ediyor → **ERİŞİLEMEZ**
    //   shell_scaffold `PaywallStub`                        → 1 ihlal,
    //     dosya hiç ithal edilmiyor → **ERİŞİLEMEZ**
    //   honesty_box `HonestyBox`                            → 1 ihlal,
    //     `select_page` onu İTHAL EDİYOR → **🔴 CANLI**
    //
    // Canlı olan şu: `measured.isEmpty` iken widget
    // *"Nothing yet — this section is not open."* basıyor ve **7 kapalı
    // disiplinin 7'sinde de `measured` boş.** Yani cümle yedi kartta da
    // kullanıcıya görünüyor — ve J-108'de `library.json`dan SİLDİĞİM
    // cümlenin ("Nothing yet — this discipline is not open") **donmuş
    // ikizi.** İçerik kopyasını düzeltmiştim, widget'ın kendi kopyası
    // duruyordu.
    //
    // Düzeltme app tarafından YAPILAMIYOR: `measured`a bir şey koymak
    // olmayan bir ölçüm iddia etmek olurdu, kutuyu hiç göstermemek de
    // dürüstlüğü en çok gereken yerde kaldırmak. Donmuş widget'a dokunmak
    // kabuk-terfi kararı → koordinatöre taşındı (J-122).
    int frozen = 0;
    for (final FileSystemEntity f
        in Directory('lib/shell_candidate').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      frozen += dartStrings(f.readAsStringSync())
          .where(promise.hasMatch)
          .length;
    }
    expect(frozen, lessThanOrEqualTo(6),
        reason: 'dondurulmuş kabukta vaat dili ARTTI ($frozen) — donmuş bir '
            'ağaca yeni ihlal eklenmiş olamaz, biri dosyayı değiştirdi');

    // ERİŞİLEBİLİR olanın sayısı AYRI tutuluyor: toplam düşerse sevinmek
    // ama canlı olan dururken "azaldı" demek, yanlış yerde rahatlamaktır.
    final int live = dartStrings(
            File('lib/shell_candidate/honesty_box.dart').readAsStringSync())
        .where(promise.hasMatch)
        .length;
    expect(live, lessThanOrEqualTo(1),
        reason: 'CANLI (kullanıcıya görünen) vaat dili arttı: $live. '
            '`HonestyBox` `select_page` tarafından kullanılıyor — bu '
            'dosyadaki her ihlal 7 kapalı disiplin kartında GÖRÜNÜR.');
  });
}

/// `library.json`daki kapalı disiplinler.
List<Map<String, dynamic>> _comingSoon() {
  final Map<String, dynamic> lib =
      (jsonDecode(File('assets/content/library.json').readAsStringSync())
              as Map)
          .cast<String, dynamic>();
  return (lib['disciplines'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .where((Map<String, dynamic> d) => d['status'] == 'coming_soon')
      .toList();
}

/// Bir disiplin düğümünün KULLANICIYA giden metinleri — `$` önekli
/// türetim/gerekçe alanları hariç (onlar kuralı ANLATIRKEN kelimeyi
/// kullanabilmeli).
List<String> _userText(Object? node) {
  final List<String> out = <String>[];
  void walk(Object? n) {
    if (n is String) {
      out.add(n);
    } else if (n is List) {
      n.forEach(walk);
    } else if (n is Map) {
      n.forEach((Object? k, Object? v) {
        if (k is String && k.startsWith(r'$')) return;
        walk(v);
      });
    }
  }

  walk(node);
  return out;
}
