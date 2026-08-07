import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ÖKSÜZ İÇERİK ANAHTARI KAPISI (J-129).
///
/// ## Neden
///
/// `Lesson.fromJson` tanımadığı bir anahtarı **sessizce düşürür** — JSON'un
/// hoşgörüsü burada bir kusur kanalıdır: içerik yazılır, ALANI yoktur, ve
/// hiçbir şey ötmez. Ölçüldüğünde 10 öksüz anahtar çıktı ve bulunma biçimi
/// silinmelerinden önemliydi:
///
/// * ikisi canlı öğretme metninin **birebir kopyasıydı**,
/// * ikisi kapsanmıştı,
/// * ve **ikisi yanlıştı** — `hiit` *"punch quality is not judged at this
///   pace"* diyordu, ki J-119 tam bu iddiayı ölçüp çürüttü; `fatigue`
///   *"watches whether your error rate climbs"* diyordu, öyle bir trend
///   hesabı yok ve dersin kendi öğretme metni aksini söylüyor.
///
/// Yani: **okunmayan anahtar, çürütülmüş iddiaların hayatta kaldığı yerdir.**
/// Bu gecenin bütün dürüstlük turları YÜZEYLERİ taradı; burası hiçbir
/// yüzeyde değildi, dolayısıyla hiçbiri oraya bakmadı. Vaat dili kapısı bu
/// dosyayı tarıyor ama o **kelimeye** bakar, DOĞRULUĞA değil.
///
/// ## Tasarım kararı — tanımlı anahtarlar PARSER KAYNAĞINDAN türetilir
///
/// Elle bir "bilinen anahtarlar" listesi tutmak, doğruyu iki yere yazmak
/// olurdu; ikisi ayrıştığı gün kapı sessizce yalan söylerdi. Bunun yerine
/// her `fromJson` gövdesindeki `j['...']` / `h['...']` erişimleri okunuyor:
/// parser bir alanı okumayı bırakırsa kapı **kendiliğinden** sıkılaşır.
///
/// ## ⚠️ NE ÖLÇMÜYOR — beyan (kapı envanterinin kendi kuralı)
///
/// * **`curriculum.json`** kapsam DIŞI ve sınıfı *ölçüm yöntemi*: onun
///   tüketicisi uygulama değil testlerdir, şekli de serbest bir sözlük.
///   "Tanımlı anahtar"ı test kodundan türetmek, testi kendi kâhini yapardı.
/// * **`cues.en.json`** kapsam dışı ve sınıfı *kapandı-başka-kapıyla*:
///   `CueBook.fromJson` tanımadığı anahtarda FIRLATIR, sessizce düşürmez —
///   yani bu kusur sınıfı orada zaten imkânsız.
/// * **Ters yön**: parser'ın okuduğu ama içerikte HİÇ geçmeyen alan. Bu ayrı
///   bir kusur (ölü alan, J-044) ve bu kapı onu görmez.
/// * **Doğruluk**: bir anahtar okunuyor diye içeriği doğru değildir.
void main() {
  final String parserSrc =
      File('packages/jablab_engine/lib/src/library.dart').readAsStringSync();

  /// Bir `fromJson` gövdesinden okunan JSON anahtarlarını TÜRET.
  Set<String> parsedKeys(String cls) {
    final int start = parserSrc.indexOf('$cls.fromJson');
    expect(start, greaterThan(-1), reason: '$cls.fromJson kaynakta yok');
    final List<int> after = <String>['factory ', 'final class ', '  static ']
        .map((String t) => parserSrc.indexOf(t, start + 1))
        .where((int i) => i > 0)
        .toList();
    final String body =
        parserSrc.substring(start, after.isEmpty ? parserSrc.length : after.reduce((int a, int b) => a < b ? a : b));
    return RegExp(r"""[jh]\['([^']+)'\]""")
        .allMatches(body)
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();
  }

  /// Kök üstverisi: hiçbir parser okumuyor ve bu KASITLI. Muafiyet
  /// desenle değil ADLA veriliyor — desen muafiyeti, bir sonraki öksüz
  /// anahtarı da sessizce yutardı.
  const Map<String, String> rootMetadata = <String, String>{
    'schemaVersion': 'şema sürümü — insan okuru için, kod sürüm ayrımı yapmıyor',
    'language': 'dosya dili — tek dil var, seçim yapan kod yok',
  };

  test('library.json — parser\'ın okumadığı anahtar YOK', () {
    final Map<String, Set<String>> known = <String, Set<String>>{
      for (final String c in <String>[
        'Library', 'Discipline', 'Course', 'Lesson',
        'RoundPlan', 'IntervalPlan', 'ExcludedItem',
      ])
        c: parsedKeys(c),
    };
    // VAKUM KAPISI: regex kırılırsa her set boşalır ve "bilinmeyen" sayısı
    // patlar (gürültülü, sessiz değil). Asıl risk tersi — bir sınıfın
    // gövdesi yanlış kesilip TEK anahtar bile bulunmazsa maskelenmeyi
    // fark etmemek. O yüzden her set doluluk kanıtı istiyor.
    known.forEach((String c, Set<String> ks) {
      expect(ks, isNotEmpty, reason: '$c için anahtar türetilemedi — '
          'gövde ayrıştırması kırılmış olabilir');
    });

    final Map<String, dynamic> lib = (jsonDecode(
            File('assets/content/library.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();

    final List<String> orphans = <String>[];
    int visited = 0;
    void check(Map<dynamic, dynamic> node, String cls, String path) {
      visited++;
      for (final dynamic k in node.keys) {
        final String key = k as String;
        // `$` önekli notlar dosyanın kendi provenance sözleşmesi — içerik
        // değil, gerekçe. Bunlar kullanıcıya hiç gitmez ve gitmemeli.
        if (key.startsWith(r'$')) continue;
        if (cls == 'Library' && rootMetadata.containsKey(key)) continue;
        if (!known[cls]!.contains(key)) {
          final String v = jsonEncode(node[key]);
          orphans.add('$path → $cls.$key = ${v.length > 90 ? '${v.substring(0, 90)}…' : v}');
        }
      }
    }

    check(lib, 'Library', '/');
    for (final dynamic d in lib['disciplines'] as List<dynamic>) {
      final Map<dynamic, dynamic> disc = d as Map<dynamic, dynamic>;
      final String dp = '/${disc['id']}';
      check(disc, 'Discipline', dp);
      for (final dynamic c in (disc['courses'] as List<dynamic>? ?? const <dynamic>[])) {
        final Map<dynamic, dynamic> course = c as Map<dynamic, dynamic>;
        check(course, 'Course', '$dp/${course['id']}');
        for (final dynamic l in (course['lessons'] as List<dynamic>? ?? const <dynamic>[])) {
          final Map<dynamic, dynamic> lesson = l as Map<dynamic, dynamic>;
          final String lp = '$dp/${lesson['id']}';
          check(lesson, 'Lesson', lp);
          if (lesson['roundPlan'] != null) {
            check(lesson['roundPlan'] as Map<dynamic, dynamic>, 'RoundPlan', '$lp/roundPlan');
          }
          if (lesson['intervalPlan'] != null) {
            check(lesson['intervalPlan'] as Map<dynamic, dynamic>, 'IntervalPlan', '$lp/intervalPlan');
          }
        }
      }
    }
    for (final dynamic x in ((lib['whyNotIncluded'] as Map)['items'] as List<dynamic>)) {
      final Map<dynamic, dynamic> item = x as Map<dynamic, dynamic>;
      check(item, 'ExcludedItem', '/whyNotIncluded/${item['id']}');
    }

    // İKİNCİ VAKUM KAPISI: yürüyüş hiçbir düğüme uğramazsa liste boş kalır
    // ve kapı YEŞİL öter. Aile dersi #4 — yapıyı kaldırmak yokluk iddiasını
    // bedavaya doğru yapar.
    expect(visited, greaterThan(20),
        reason: 'yürüyüş $visited düğüme uğradı — ağaç şekli değişmiş olabilir '
            've kapı hiçbir şeye bakmadan geçiyor olabilir');

    expect(orphans, isEmpty,
        reason: 'İÇERİK YAZILDI, ALANI YOK — parser bu anahtarları sessizce '
            'düşürüyor; yazılan metin hiçbir yüzeye ULAŞMIYOR ve hiçbir '
            'dürüstlük turu oraya BAKMIYOR (J-129):\n  ${orphans.join('\n  ')}');
  });

  test('NEGATİF İKİZ — bilinen bir öksüz anahtar geri gelirse kapı öter', () {
    final Set<String> lessonKeys = parsedKeys('Lesson');
    // Silinen üç anahtar: geri eklenirlerse yukarıdaki test kırmızıya döner.
    // Bunu ölçmek için parser'ın onları GERÇEKTEN tanımadığını doğruluyoruz —
    // yoksa "kapı öter" iddiası kanıtsız kalırdı.
    for (final String dead in <String>['blurb', 'lockedBy']) {
      expect(lessonKeys, isNot(contains(dead)),
          reason: 'Lesson artık `$dead` okuyorsa J-129\'un gerekçesi düştü: '
              'ya alanı bir yüzeye bağla ya bu ikizi güncelle');
    }
    expect(parsedKeys('Discipline'), isNot(contains('comingSoonInThisDiscipline')));
    // Ve pozitif taraf: gerçekten okunan bir alan yanlışlıkla öksüz
    // sayılmamalı — `blurb` DISIPLIN düzeyinde okunuyor ve ekranda.
    expect(parsedKeys('Discipline'), contains('blurb'));
  });
}
