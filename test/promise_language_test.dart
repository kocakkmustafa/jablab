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
/// * `lib/shell_candidate/` — DONDURULMUŞ (M-F-25). Orada 6 eşleşme var ve
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

  test('DONDURULMUŞ kabuğun borcu SESSİZ DEĞİL — sayı ölçülü', () {
    // Bu kapının kör noktası ÖLÇÜLÜYOR. `shell_candidate/`ı taramamak bir
    // karar; o kararı "orada bir şey yok" sanmakla karıştırmamak için sayı
    // burada duruyor. Kabuk terfi turunda bu test ya sıfıra iner ya da
    // kapının kapsamı genişler — ikisi de bilinçli bir hamle olur.
    int frozen = 0;
    for (final FileSystemEntity f
        in Directory('lib/shell_candidate').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      frozen += dartStrings(f.readAsStringSync())
          .where(promise.hasMatch)
          .length;
    }
    // ⚠️ ÖLÇÜLEN SAYI **6**, koordinatörün bildirdiği 4 DEĞİL — ve fark
    // tahminle değil sayarak kapandı. Sebep yöntemde: o tarama yalnız `yet`
    // arıyordu, bu kapı aynı sınıfın diğer üyelerini (`soon`…) de sayıyor.
    // Altısı, adıyla:
    //   honesty_box    'Nothing yet — this section is not open.'
    //   library_pages  'Soon' · 'Soon · <wave>' · 'Not open yet…' ×2
    //   shell_scaffold 'Pricing is not set yet.'
    // Beşinin CANLI ikizi bu turda düzeltildi (`select_page`,
    // `settings_page`); donmuş kopyalar duruyor ve kabuk terfi turunun
    // borcu. `'Soon'` rozeti ayrıca bu kapının kendi bulgusu: `yet`-only
    // tarama onu göremiyordu, canlı ikizi (`SOON` rozeti, Sayfa A) bu tur
    // `NOT OPEN` oldu.
    expect(frozen, lessThanOrEqualTo(6),
        reason: 'dondurulmuş kabukta vaat dili ARTTI ($frozen) — donmuş bir '
            'ağaca yeni ihlal eklenmiş olamaz, biri dosyayı değiştirdi');
  });
}
