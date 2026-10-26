import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/session_narrator.dart';

/// MOTOR KODU → KULLANICI CÜMLESİ eşlemesinin eksiksizliği (J-096).
///
/// Sınanan dürüstlük değişmezi: **ham teşhis dizesi kullanıcıya gösterilemez.**
/// `REAR_HAND_LOW` bir kod adıdır; ekranda görünmesi doc-75/5 sınıfının
/// kamera tarafıdır.
///
/// ## Neden İKİ YÖN
///
/// Tek yön yeterli değil ve bu ölçüldü. Mekanik `cue.${code.toLowerCase()}`
/// kısayolu **14 kodun 7'sinde** tutmuyor (`TEMPO_TOO_FAST_FOR_FORM` →
/// `cue.slow_down` gibi). Bu yüzden:
///   * her kural-seti kodu eşlemede OLMALI (yoksa o hata ham kodla ya da
///     genel cümleyle geçer — düzeltme kaybolur);
///   * eşlemedeki her anahtar içerikte OLMALI (sarkan atıf; `CueBook`un
///     olay tarafında zaten fırlattığı kural).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Kural setindeki TÜM hata kodları — elle liste YAZILMIYOR, dosyadan
  /// süpürülüyor: yeni bir kod eklenince test onu kendiliğinden kapsar ve
  /// unutulamaz (`fitness_ship_audit`in içerikten-sürme deseni).
  Set<String> ruleSetCodes() {
    final Object doc = jsonDecode(
      File('assets/rulesets/boxing@1.0.0.json').readAsStringSync(),
    );
    final Set<String> codes = <String>{};
    void walk(Object? o) {
      if (o is Map) {
        final Object? c = o['code'];
        if (c is String) codes.add(c);
        o.values.forEach(walk);
      } else if (o is List) {
        o.forEach(walk);
      }
    }

    walk(doc);
    return codes;
  }

  Set<String> cueKeys() {
    final Map<String, dynamic> doc =
        (jsonDecode(File('assets/content/cues.en.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();
    final Set<String> keys = <String>{};
    for (final MapEntry<String, dynamic> g in doc.entries) {
      if (g.key.startsWith(r'$') || g.value is! Map) continue;
      for (final String k in (g.value as Map).keys.cast<String>()) {
        if (!k.startsWith(r'$')) keys.add(k);
      }
    }
    return keys;
  }

  test('ÖLÜ REPLİK YOK — her anahtarın bir çağrı yolu var (J-104 kapısı)', () {
    // ## Neden bu kapı var
    //
    // 2026-08-06 taraması `cues.en.json`in 62 anahtarından **32'sinin**
    // hiçbir kod yolundan çağrılmadığını ölçtü (%52). Sevk edilen bir
    // varlıkta duran her replik, uygulamanın o cümleyi söyleyebildiğini
    // İDDİA EDER — söyleyemiyorsa beyan yanlıştır (M-F-186'nın veri tarafı).
    // J-104 turunda 30'u temizlendi; bu kapı 31.'nin sessizce eklenmesini
    // engelliyor: yeni bir replik yazan kişi ya tetiğini yazar, ya
    // `docs/design/ICERIK-ONCU-REPLIKLER.md`ye taşır — kararı İSİMLE verir.
    //
    // ## Neden yalnız DİZE SABİTLERİ taranıyor
    //
    // Ham `cue.` geçişini aramak bir yanlış-negatif üretirdi: bu depoda
    // replik anahtarları YORUMLARDA sıkça anılıyor (bu yorumun kendisi
    // dahil). Bir anahtarın bir açıklamada geçmesi, onu ateşleyen kodun var
    // olduğunu KANITLAMAZ — aile dersi #6'nın tam kendisi. Bu yüzden yalnız
    // tırnak içindeki hâli sayılıyor: Dart `'cue.x'` ve JSON `"cue.x"`.
    //
    // ## Bu kapının GÖREMEDİĞİ şey — beyan ediyorum
    //
    // "Bir eşleme tablosunda duruyor" ile "kullanıcı duyuyor" AYRI şeyler.
    // `jabLabCueMapping`e yazılmış bir anahtar bu kapıdan geçer ama onu
    // ateşleyen olay hiç üretilmiyor olabilir (`cue.corrected`/`streak`/
    // `settled` bugün tam olarak bu durumda — `cues.en.json`in
    // `$producers` bloğunda `awaiting-wiring` diye İSİMLE beyan edildi).
    // Bu kapı statik erişilebilirliği ölçer, çalışma-zamanı ulaşılabilirliği
    // DEĞİL; ikincisi ancak `session_rounds_test`in kilometre-taşı testi
    // gibi gerçek bir yüzey testiyle ölçülür.
    final Set<String> referenced = <String>{};
    final RegExp literal = RegExp(r'''['"](cue\.[a-z_.]+)['"]''');
    // ⚠️ KAPSAM DÜZELTİLDİ (J-145). Bu kapı önce `lib` · `assets/rulesets` ·
    // `packages` tarıyordu ve **`assets/content` YOKTU** — yani atıflar tam
    // da taranmayan dizindeydi. Sonucu: J-104 `drill` grubunun 10 repliğini
    // *"ölü"* sayıp sildi, oysa `curriculum.json`daki 10 drill'in 10'u
    // `introCue` ile onlara atıf yapıyordu. **Kapı, kusura yol açan dar
    // tanımı kodlamıştı.**
    //
    // `cues.en.json` BİLEREK dışarıda: kendi anahtarlarını içerdiği için
    // her repliği kendi kendine "atıflı" yapar ve kapı vakum-doğru olurdu.
    for (final String dir in <String>[
      'lib',
      'assets/rulesets',
      'assets/content',
      'packages',
    ]) {
      for (final FileSystemEntity f in Directory(
        dir,
      ).listSync(recursive: true)) {
        if (f is! File) continue;
        if (f.path.endsWith('cues.en.json')) continue;
        if (!f.path.endsWith('.dart') && !f.path.endsWith('.json')) continue;
        for (final RegExpMatch m in literal.allMatches(f.readAsStringSync())) {
          referenced.add(m.group(1)!);
        }
      }
    }

    final List<String> dead = (cueKeys().difference(referenced)).toList()
      ..sort();
    expect(
      dead,
      isEmpty,
      reason:
          'ÖLÜ REPLİK: $dead — bu anahtar(lar) `cues.en.json`da '
          'duruyor ama hiçbir kod yolu çağırmıyor. Üç seçenekten birini '
          'İSİMLE seç: (a) tetiğini yaz · (b) sil (yetenek yok ya da '
          'canlı bir yol aynı şeyi zaten söylüyor) · (c) sil ve metni '
          '`docs/design/ICERIK-ONCU-REPLIKLER.md`ye taşı (yüzeyi yok).',
    );
  });

  test('kural setindeki HER kod eşlemede var', () {
    final Set<String> missing = ruleSetCodes().difference(
      jabLabIssueCueMapping.keys.toSet(),
    );
    expect(
      missing,
      isEmpty,
      reason:
          'eşlenmemiş kod(lar) $missing — bu hatalar kullanıcıya '
          'genel cümleyle geçer, gerçek düzeltme KAYBOLUR',
    );
  });

  test('eşlemedeki HER anahtar içerikte var (sarkan atıf yok)', () {
    final Set<String> dangling = jabLabIssueCueMapping.values
        .toSet()
        .difference(cueKeys());
    expect(
      dangling,
      isEmpty,
      reason: 'içerikte olmayan replik anahtar(lar)ı: $dangling',
    );
  });

  test('MEKANİK eşleme YETMİYOR — kısayolun neden reddedildiği ölçülü', () {
    // Bu test bir davranışı değil bir KARARI pinliyor: biri "şu haritayı
    // silip toLowerCase() yazalım" derse, kaç kodun sessizce düşeceğini
    // sayıyla görsün.
    final Set<String> keys = cueKeys();
    final List<String> wouldBreak =
        ruleSetCodes()
            .where((String c) => !keys.contains('cue.${c.toLowerCase()}'))
            .toList()
          ..sort();
    expect(
      wouldBreak.length,
      greaterThanOrEqualTo(7),
      reason:
          'mekanik kısayol artık tutuyorsa bu kararı yeniden gözden '
          'geçir — ama ÖLÇEREK',
    );
    for (final String c in wouldBreak) {
      expect(
        jabLabIssueCueMapping.containsKey(c),
        isTrue,
        reason: '$c mekanik eşlemede düşerdi ve elle de eşlenmemiş',
      );
    }
  });

  test('GÖRÜNÜRLÜK kodları düzeltme sayılmıyor', () {
    // Kullanıcı yanlış bir şey yapmıyor, biz göremiyoruz. Düzeltme yuvasına
    // koymak olmayan bir hatayı düzelttirmek olurdu.
    for (final String c in jabLabVisibilityIssueCodes) {
      expect(
        jabLabIssueCueMapping.containsKey(c),
        isTrue,
        reason: '$c görünürlük kodu ama eşlemesi yok',
      );
    }
    expect(
      jabLabVisibilityIssueCodes.contains('REAR_HAND_LOW'),
      isFalse,
      reason:
          'teknik kusuru görünürlük sınıfına düşerse kullanıcıya '
          '"göremiyorum" denir ve gerçek düzeltme hiç verilmez',
    );
  });

  test('replik kitabı anahtarla CÜMLE döndürüyor, kodu değil', () async {
    final CueBook book = await const ContentRepository().loadCues();
    for (final MapEntry<String, String> e in jabLabIssueCueMapping.entries) {
      final String? line = book.sayKey(e.value);
      expect(line, isNotNull, reason: '${e.value} için cümle yok');
      expect(
        line,
        isNot(contains(e.key)),
        reason: 'cümle ham kodu (${e.key}) taşıyor',
      );
      expect(
        line,
        isNot(matches(RegExp(r'^[A-Z_]+$'))),
        reason: 'cümle bir kod adı gibi görünüyor: "$line"',
      );
    }
  });

  test('replikte doldurulmamış yer tutucu YOK', () async {
    // Sesli okunduğunda "Round {n} of {total}" diye duyulur.
    final CueBook book = await const ContentRepository().loadCues();
    for (final String key in jabLabIssueCueMapping.values) {
      final String line = book.sayKey(key)!;
      expect(
        CueBook.unfilledPlaceholder.hasMatch(line),
        isFalse,
        reason: '"$line" doldurulmamış yer tutucu taşıyor',
      );
    }
  });
}
