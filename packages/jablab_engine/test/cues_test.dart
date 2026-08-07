import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Sesli koç replikleri — mekanik değişmezler.
///
/// Replikler ürünün AĞZI. Bir hata kodu üretilip karşılığında söylenecek bir
/// şey olmaması, kullanıcı için "sistem sustu" demektir; fazla uzun bir replik
/// ise telefon uzaktayken duyulmaz. İkisi de sessizce olur, o yüzden testle
/// zorlanır.
void main() {
  final Map<String, dynamic> cues = (jsonDecode(
          File('../../assets/content/cues.en.json').readAsStringSync()) as Map)
      .cast<String, dynamic>();
  final RuleSet rules = loadBoxingRuleSet();

  Map<String, dynamic> group(String g) =>
      (cues[g] as Map).cast<String, dynamic>();

  Iterable<String> allLines() sync* {
    // `summary` J-104'te SİLİNDİ (üreticisi yoktu) — J-145'te ölçüldü:
    // beş summary repliğinin hiçbirine `cues.en.json` DIŞINDA atıf yok.
    // Listede bırakmak testi çökertiyordu, çökerten şey de content değil
    // BU LİSTEYDİ.
    for (final String g in <String>[
      'technique', 'noVerdict', 'counting', 'encouragement', 'session'
    ]) {
      for (final dynamic v in group(g).values) {
        yield* (v as List<dynamic>).cast<String>();
      }
    }
  }

  test('config\'teki HER hata kodunun repliği var', () {
    final Set<String> haveCues = <String>{
      ...group('technique').keys,
      ...group('noVerdict').keys,
    };
    for (final ErrorConfig e in rules.errors) {
      expect(haveCues, contains(e.feedbackKey),
          reason: '${e.code} üretiliyor ama söylenecek bir şey yok — '
              'kullanıcı için sistem susmuş olur');
    }
  });

  test('uzunluk sınırı NE ZAMAN söylendiğine bağlı (plan §13)', () {
    // "Kombinasyon ortasında uzun anlatım yok · tur sonunda ayrıntı."
    // Düz bir sınır bu kuralı yanlış temsil ederdi: tur ortasında 8 kelime
    // bile fazla, tur sonunda 13 kelime gayet normal.
    const Map<String, int> limits = <String, int>{
      'technique': 5,      // tur ortasında, kullanıcı hareket hâlinde
      'noVerdict': 10,     // durur ve dinler; sebep açıklanmalı
      'counting': 3,
      'encouragement': 5,
      'session': 6,
      'interval': 5,       // HIIT: yalnız ritim ve sayım
      'drill': 8,          // drill BAŞLAMADAN, kullanıcı dururken
      // `summary` ve `setup` J-104'te silindi (üreticisi yoktu, J-145'te
      // çapraz-dosya atıfları da ölçüldü: yok). `drill` DURUYOR çünkü
      // `curriculum.json`daki 10 drill'in 10'u `introCue` ile ona atıf
      // yapıyor — J-104 onu da silmişti ve bu YANLIŞTI.
    };

    // Yeni bir grup eklendiğinde bu haritaya yazılmazsa uzunluk kuralından
    // SESSİZCE kaçardı — ve tam olarak öyle bir grupta kural en çok gerekir
    // (yeni grup = henüz kimsenin sesli dinlemediği replikler).
    final Set<String> covered = limits.keys.toSet();
    for (final MapEntry<String, dynamic> g in cues.entries) {
      if (g.key.startsWith(r'$') || g.value is! Map) continue;
      expect(covered, contains(g.key),
          reason: '"${g.key}" grubu uzunluk sınırı tanımlamamış — sınırdan kaçıyor');
    }
    for (final MapEntry<String, int> lim in limits.entries) {
      for (final MapEntry<String, dynamic> e in group(lim.key).entries) {
        if (e.key.startsWith(r'$')) continue; // grup içi belge notu
        for (final String line in (e.value as List<dynamic>).cast<String>()) {
          final int words = line.split(RegExp(r'\s+')).length;
          expect(words, lessThanOrEqualTo(lim.value),
              reason: '${lim.key}/${e.key}: "$line" ($words kelime, '
                  'sınır ${lim.value})');
        }
      }
    }
  });

  test('teknik replikleri ≤5 kelime — tur içinde söylenecekler en kısası', () {
    for (final MapEntry<String, dynamic> e in group('technique').entries) {
      for (final String line in (e.value as List<dynamic>).cast<String>()) {
        expect(line.split(RegExp(r'\s+')).length, lessThanOrEqualTo(5),
            reason: '${e.key}: "$line" tur ortasında söylenemeyecek kadar uzun');
      }
    }
  });

  test('"göremiyorum" replikleri VAR — sessizlik alternatifi', () {
    // plan §12: susmak "her şey yolunda" der. Bu grup boşsa, hüküm
    // verilemeyen anlarda ürün sessizce yalan söyler.
    expect(group('noVerdict'), isNotEmpty);
    expect(group('noVerdict').keys, contains('cue.low_confidence'));
  });

  test('hiçbir replik ölçmediğimiz şeyi iddia etmiyor', () {
    // "power", "force", "speed: 42" gibi ifadeler ürünün ölçemediği şeyler.
    final RegExp forbidden = RegExp(r'\b(power|force|kph|mph|newton)\b',
        caseSensitive: false);
    for (final String line in allLines()) {
      if (line.contains("don't measure")) continue; // dürüstlük cümlesi
      expect(forbidden.hasMatch(line), isFalse,
          reason: 'ölçemediğimiz bir şeyi iddia eden replik: "$line"');
    }
  });

  test('her anahtarın en az bir varyantı var (tekrar körlüğüne karşı)', () {
    for (final String g in <String>['technique', 'session']) {
      for (final MapEntry<String, dynamic> e in group(g).entries) {
        expect((e.value as List<dynamic>), isNotEmpty, reason: e.key);
      }
    }
  });

  test('[J-039] her replik grubunun ÜRETİCİSİ beyan edilmiş', () {
    // Üreticisi olmayan replik ölü içeriktir. Satır hedefini ölü içerikle
    // tutturmak metriği oynamaktır; bu yüzden her grup ya bugün bir şey
    // tarafından söylenebilir olmalı ya da neden söylenemediğini yazmalı.
    final Map<String, dynamic> producers =
        (cues[r'$producers'] as Map).cast<String, dynamic>();
    for (final MapEntry<String, dynamic> g in cues.entries) {
      if (g.key.startsWith(r'$') || g.value is! Map) continue;
      final Map<String, dynamic>? pr =
          (producers[g.key] as Map?)?.cast<String, dynamic>();
      expect(pr, isNotNull,
          reason: '"${g.key}" grubunun üreticisi beyan edilmemiş — '
              'kimsenin söyleyemediği replikler sessizce birikir');
      expect(
          <String>['bound', 'awaiting-wiring', 'awaiting-surface']
              .contains(pr!['status']),
          isTrue,
          reason: '${g.key}: tanınmayan durum "${pr['status']}"');
    }
  });

  test('[J-039] SARKAN ATIF yok — beyan edilen yüzey gerçekten var', () {
    // "awaiting-wiring" iddiası, yüzeyin VAR olduğunu söyler. Yüzey silinmiş
    // veya adı değişmişse iddia sessizce yalana döner ve grup sonsuza kadar
    // "bir sonraki tur bağlanacak" durumunda asılı kalır.
    final Map<String, dynamic> producers =
        (cues[r'$producers'] as Map).cast<String, dynamic>();
    for (final MapEntry<String, dynamic> e in producers.entries) {
      if (e.key.startsWith(r'$')) continue;
      final Map<String, dynamic> pr = (e.value as Map).cast<String, dynamic>();
      final String? surface = pr['surface'] as String?;
      if (pr['status'] == 'awaiting-wiring') {
        expect(surface, isNotNull,
            reason: '${e.key}: yüzey var deniyor ama yolu yazılmamış');
        expect(File('../../$surface').existsSync(), isTrue,
            reason: '${e.key}: beyan edilen yüzey $surface YOK — sarkan atıf');
      }
      if (pr['status'] == 'awaiting-surface') {
        expect(surface, isNull,
            reason: '${e.key}: yüzey yok deniyor ama bir yol gösteriyor');
      }
    }
  });

  test('[J-039] drill giriş replikleri GERÇEKTEN bağlı', () {
    // "bound" en güçlü iddia: bugün bir şey bunu söyleyebilir. İddiayı
    // taşıyan tek grup drill; bağ çift yönlü zorlanıyor.
    final Map<String, dynamic> cur = (jsonDecode(
                File('../../assets/content/curriculum.json').readAsStringSync())
            as Map)
        .cast<String, dynamic>();
    final Map<String, dynamic> drills =
        (cur['drills'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> drillCues = group('drill');
    for (final MapEntry<String, dynamic> d in drills.entries) {
      final String? intro = (d.value as Map)['introCue'] as String?;
      expect(intro, isNotNull, reason: '${d.key}: giriş repliği yok');
      expect(drillCues.containsKey(intro), isTrue,
          reason: '${d.key} → $intro: böyle bir replik yok (sarkan atıf)');
    }
    for (final String k in drillCues.keys) {
      if (k.startsWith(r'$')) continue;
      final bool used = drills.values.any(
          (dynamic d) => (d as Map)['introCue'] == k);
      expect(used, isTrue,
          reason: '$k hiçbir drill tarafından kullanılmıyor — ölü replik');
    }
  });
}
