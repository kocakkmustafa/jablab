import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// KULLANICIYA GİDEN METNİN BİÇİMİ (J-115).
///
/// ## Neden bu kapı — ve neden BUGÜN hiçbir şey bulmuyor
///
/// Koordinatörün 2026-08-07 ölçümü: bu gece ekran kanıtının yakaladığı 6
/// kusurun **hiçbiri metin ekseninde değildi**, ve kurduğum üç kapının
/// **üçü de** orada ölçüyor. Kör noktayı asıl kapatan şey göz — ama
/// hepsini değil: Gravita'nın kusuru bir GÖZ bulgusu olarak geldi
/// (kullanıcıya `Parallel_bars` yazıyordu, **79 test yeşilken**) ve o kusur
/// **mekanik olarak yakalanabilir** bir şeydi. Bir metnin tanımlayıcı
/// biçiminde olması ölçülebilir.
///
/// **Bu kapı bugün SIFIR bulgu veriyor ve bu bilinerek böyle.** JabLab'ın
/// içeriği tarandı: kullanıcıya giden alanlarda tek bir kod-biçimli dize
/// yok. Kapı bir düzeltme değil, bir **önleme** — ve önlediği şey uzak
/// değil: `library.json`daki bir `displayName` bir içerik turunda yanlışlıkla
/// `mma_striking` yazılırsa bugün hiçbir şey onu durdurmuyordu.
///
/// ## JabLab'da id-fallback YAPISAL OLARAK yok — ölçüldü
///
/// Gravita'nın mekanizması (ad yoksa id'ye düş) burada imkânsız:
/// `Lesson`/`Course`/`Discipline` hepsinde `displayName` zorunlu ve
/// `j['displayName'] as String` ile okunuyor — `?? id` diye bir yol yok.
/// Yani kalan tek risk İÇERİK tarafı, ve kapı tam oraya bakıyor.
///
/// `errorFocus` (ham hata kodları taşıyor) da tarandı: yalnız
/// `Library.validate` içinde okunuyor, `ShellLesson`a hiç girmiyor, yani
/// ekrana ulaşmıyor. Kod listesi taşıyan bir alanın var olması onu
/// sızıntı yapmaz — **nereye gittiği** yapar.
void main() {
  /// Tam bir tanımlayıcı: `snake_case` · `SCREAMING_CASE` · `camelCase` ·
  /// `noktali.anahtar`. İnsan cümlesi bunların hiçbirine benzemez.
  final RegExp wholeIdentifier = RegExp(
    r'^[a-z0-9]+(?:[_.][a-z0-9]+)+$|^[A-Z][A-Z0-9_]{3,}$|'
    r'^[a-z]+(?:[A-Z][a-z0-9]+)+$',
  );

  /// Cümlenin İÇİNE gömülü kod — `REAR_HAND_LOW` ya da `lead_forearm` gibi.
  /// Backtick içindekiler hariç: dokümantasyon değil, KULLANICI metni
  /// taranıyor ve bu depoda backtick yalnız yorumlarda geçiyor.
  final RegExp inlineIdentifier = RegExp(
    r'(?<![\w`])(?:[A-Z]{2,}_[A-Z_]+|[a-z]+_[a-z_]+)(?![\w`])',
  );

  /// Lissom'un bu geceki kusurunun sınıfı: metin **hem vardı hem doğruydu**,
  /// yalnız okunmuyordu. Çift tire ekranda tek uzun çizgi gibi görünüp
  /// cümleyi kesiyor. `---` (em-dash kaçışı) hariç tutuluyor.
  final RegExp doubleDash = RegExp(r'(?<!-)--(?!-)');

  /// `library.json`da KULLANICIYA giden alanlar. Beyaz liste, kara liste
  /// DEĞİL: yeni bir makine alanı eklendiğinde kapı onu yanlışlıkla
  /// taramaz, ama yeni bir METİN alanı eklendiğinde de görmez — o yüzden
  /// liste burada, görünür yerde duruyor.
  const Set<String> userFacing = <String>{
    'displayName',
    'blurb',
    'goal',
    'reason',
    'lockedReason',
    'intro',
    'productName',
    'measured',
    'notMeasured',
    'title',
  };

  List<(String, String)> scan(Object? node, String path, bool inUser) {
    final List<(String, String)> out = <(String, String)>[];
    if (node is String) {
      if (!inUser) return out;
      final String s = node.trim();
      if (wholeIdentifier.hasMatch(s)) out.add((path, 'TAM KOD: $s'));
      for (final RegExpMatch m in inlineIdentifier.allMatches(s)) {
        out.add((path, 'SATIR-İÇİ KOD: ${m.group(0)}'));
      }
      if (doubleDash.hasMatch(s)) out.add((path, 'ÇİFT TİRE: $s'));
    } else if (node is List) {
      for (int i = 0; i < node.length; i++) {
        out.addAll(scan(node[i], '$path[$i]', inUser));
      }
    } else if (node is Map) {
      node.forEach((Object? k, Object? v) {
        if (k is String && k.startsWith(r'$')) return;
        out.addAll(
          scan(
            v,
            '$path.$k',
            inUser || (k is String && userFacing.contains(k)),
          ),
        );
      });
    }
    return out;
  }

  test('library.json — kullanıcı alanlarında KOD BİÇİMİ yok', () {
    final List<(String, String)> hits = scan(
      jsonDecode(File('assets/content/library.json').readAsStringSync()),
      '',
      false,
    );
    expect(
      hits,
      isEmpty,
      reason:
          'kullanıcıya kod gösteriliyor: '
          '${hits.map(((String, String) h) => "${h.$1} ${h.$2}").join(" · ")}',
    );
  });

  test('cues.en.json — replikler cümle, kod DEĞİL', () {
    // `live_cue_mapping_test` ANAHTARIN içerikte olmasını ölçüyor; bu,
    // içeriğin kendisinin bir CÜMLE olduğunu. İkisi farklı: eşlemesi doğru
    // ama metni `REAR_HAND_LOW` olan bir replik o kapıdan geçerdi.
    final Map<String, dynamic> doc =
        (jsonDecode(File('assets/content/cues.en.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();
    final List<String> hits = <String>[];
    for (final MapEntry<String, dynamic> g in doc.entries) {
      if (g.key.startsWith(r'$') || g.value is! Map) continue;
      (g.value as Map).forEach((Object? k, Object? v) {
        if (k is! String || k.startsWith(r'$') || v is! List) return;
        for (final String line in v.cast<String>()) {
          if (wholeIdentifier.hasMatch(line.trim())) hits.add('$k: "$line"');
          if (inlineIdentifier.hasMatch(line)) hits.add('$k: "$line"');
          if (doubleDash.hasMatch(line)) hits.add('$k (çift tire): "$line"');
        }
      });
    }
    expect(hits, isEmpty, reason: 'replik kod taşıyor: ${hits.join(" · ")}');
  });

  test('BU KAPININ GÖREMEDİĞİ — beyan', () {
    // Kapı bir DİZE biçimi ölçer. Bu gecenin altı ekran-kusurunun ikisi
    // (düğme rengi/konumu, örtüşen yerleşim) bir dize DEĞİL — onları
    // hiçbir metin kapısı göremez ve göz doğrulaması yerine geçmez.
    //
    // Bu test bir davranış sınamıyor; **kapının kendi sınırını kod içinde
    // tutuyor** ki bir sonraki tur "metin kapıları var, ekran taraması
    // gereksiz" diye okumasın. J-114'te aynı şeyi kontrast için yaptım:
    // ölçülebileni ölçüp ölçülemeyeni adıyla bıraktım.
    expect(true, isTrue);
  });
}
