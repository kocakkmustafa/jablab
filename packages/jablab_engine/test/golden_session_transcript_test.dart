import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// GERÇEK HASAT VERİSİ MOTORDAN GEÇİYOR MU — VE EKSİK OLAN FIXTURE SINIFI
/// (J-184).
///
/// ## Neden yazıldı
///
/// Kurucunun ölçütü: *"bir insan telefonuna indirse, çalışır mı, ve baştan
/// sona bir seans yapabilir mi?"* Cihaz turu kurucuda. **Cihazsız
/// yapılabilecek en yakın şeyi denedim:** gerçek videodan hasat edilmiş
/// landmark'ları motora verip ne çıktığını okumak.
///
/// ## Ölçüm ve BENİM HATAM
///
/// İlk yazışımda bu testin *"tamamlanan deneme > 0"* beklemesi vardı ve
/// **iki fixture de 0 üretti.** Bunu bir kusur sanıp raporlamaya
/// hazırlandım. Doğrulayınca kusurun **bende** olduğu çıktı:
///
/// * Uzanma profili düzgün bir yumruk eğrisi değil, **kare kare zıplayan
///   gürültü** — yapısal doğrulayıcının `boneLengthInstability` demesiyle
///   birebir tutarlı;
/// * İkinci fixture'ın adı zaten **"Kenny Weldon *stance*"** — duruş
///   verisi, yumruk değil;
/// * İkisi de **ölçü çapraz-kontrol** fixture'ı: `harvest_cross_check_test`
///   Python↔Dart aritmetiğini **kare kare** karşılaştırsın diye var. Temiz
///   bir yumruk döngüsü içermeleri **hiç amaçlanmamış.**
///
/// > **Bir fixture'ı, yapılmadığı soruyu sormak için kullanmak ölçüm
/// > değildir.** Sonuç sayısal olarak doğru çıkar ve **yanlış şeyi**
/// > söyler.
///
/// ## Asıl bulgu: ORTADA OLMAYAN FIXTURE SINIFI
///
/// Depoda iki tür var ve **üçüncüsü yok**:
///
/// | tür | ne kanıtlar | nerede |
/// |---|---|---|
/// | sentetik keyframe | faz makinesi **ideal** girdide çalışıyor | `engine_test` |
/// | gerçek hasat (ölçü) | Dart aritmetiği Python ile **aynı sayıyı** verir | `harvest_cross_check_test` |
/// | **gerçek hasat (seans)** | **gerçek veriden bir seans ÇIKAR** | **YOK** |
///
/// Bu boşluk, cihaz turunun neden bir **engel** olduğunun teknik hâli:
/// bugün elimizde *"gerçek veriden yumruk sayılıyor"* diyen **hiçbir
/// artefakt yok** — ne cihazda, ne fixture'da. Sentetik girdi faz
/// makinesini kanıtlar, gürültüye dayanıklılığı kanıtlamaz.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Cihazda çalıştığını — burada kamera, ışık, kare düşmesi, izin akışı
///   **yok**. Bu kapı yeşilken bile *"telefonda çalışıyor"* denemez.
/// * Hükümlerin **doğru** olduğunu; yalnız üretildiklerini ve
///   çevrilebildiklerini. Eşikler kalibre değil
///   (`thresholdStatus: raw-signal-pending-revision`).
void main() {
  final RuleSet rules = loadBoxingRuleSet();

  /// Kural setinin BEYAN ETTİĞİ tüm geri bildirim anahtarları.
  ///
  /// ⚠️ İlk yazışımda burada yalnız `rules.errors` vardı ve küme **tam bir
  /// anahtar kadar dardı**: `cue.strike_not_extended` `errors[]` altında
  /// değil, tekniklerin faz-iptal yapılandırmasında duruyor. Yani kapı,
  /// motorun **doğru** ürettiği bir anahtarı "tanımsız" diye bildirdi.
  /// Ham JSON'dan taranıyor, çünkü soru *"kural seti bunu beyan ediyor
  /// mu"*, *"`RuleSet` sınıfı bunu hangi alana koydu"* değil.
  Set<String> declaredKeys() {
    final Object? doc =
        jsonDecode(File('../../assets/rulesets/boxing@1.0.0.json')
            .readAsStringSync());
    final Set<String> out = <String>{};
    void walk(Object? n) {
      if (n is Map) {
        for (final MapEntry<Object?, Object?> e in n.entries) {
          if (e.key == 'feedbackKey' && e.value is String) {
            out.add(e.value! as String);
          }
          walk(e.value);
        }
      } else if (n is List) {
        for (final Object? v in n) {
          walk(v);
        }
      }
    }

    walk(doc);
    return out;
  }

  ({
    int frames,
    int judgeable,
    int attempts,
    List<String> keys,
    Set<String> suppressions,
  }) run(String fixture) {
    final Map<String, dynamic> g =
        (jsonDecode(File('test/golden/$fixture').readAsStringSync()) as Map)
            .cast<String, dynamic>();
    final StrikingEngine e = StrikingEngine(
      ruleSet: rules,
      calibrationMapped: true,
      provenance: const <String, String>{
        'poseModelVariant': 'harvest-v2',
        'calibrationProfileId': 'golden',
      },
    );
    int frames = 0, judgeable = 0, attempts = 0;
    final List<String> keys = <String>[];
    final Set<String> supp = <String>{};
    for (final dynamic raw in g['frames'] as List<dynamic>) {
      final Map<String, dynamic> f = (raw as Map).cast<String, dynamic>();
      final List<dynamic> lm = f['lm'] as List<dynamic>;
      final EngineOutput o = e.process(PoseFrame(
        tUs: ((f['t'] as num) * 1000).round(),
        modelVersion: 'harvest-v2',
        landmarks: List<PoseLandmark>.generate(lm.length, (int i) {
          final List<dynamic> p = lm[i] as List<dynamic>;
          return PoseLandmark((p[0] as num).toDouble(), (p[1] as num).toDouble(),
              (p[2] as num).toDouble(), (p[3] as num).toDouble());
        }, growable: false),
      ));
      frames++;
      if (o.judgeable) judgeable++;
      if (o.suppressionReason != null) supp.add('${o.suppressionReason}');
      if (o.completedAttempt != null) attempts++;
      for (final DetectedIssue i in o.issues) {
        keys.add(i.feedbackKey);
      }
    }
    return (
      frames: frames,
      judgeable: judgeable,
      attempts: attempts,
      keys: keys,
      suppressions: supp,
    );
  }

  const List<String> fixtures = <String>[
    'harvest_cross_check.json',
    'harvest_cross_check_2.json',
  ];

  for (final String fixture in fixtures) {
    test('[$fixture] gerçek veri motordan geçiyor ve hüküm verilebilir kare '
        'üretiyor', () {
      final ({
        int frames,
        int judgeable,
        int attempts,
        List<String> keys,
        Set<String> suppressions,
      }) r = run(fixture);

      // VAKUM MUHAFIZI — eşik GEREKÇELİ: iki fixture 59 ve 55 kare. İlk
      // yazışımda buraya gerekçesiz `> 100` koymuştum ve kapı, sağlıklı
      // bir fixture'ı "yüklenemedi" diye reddetti. Eşik ölçülen büyüklüğe
      // bağlanmazsa kapının kendisi bir yanlış-pozitif üreticisidir.
      expect(r.frames, greaterThan(40),
          reason: 'yalnız ${r.frames} kare okundu — fixture yüklenemedi, '
              'bu testin hiçbir sonucu anlamlı değil');

      expect(r.judgeable, greaterThan(0),
          reason: 'gerçek veride HİÇBİR kare hüküm verilebilir değil '
              '(${r.frames} kare; bastırma: ${r.suppressions.join(", ")}). '
              'Ölçüler Python ile uyuşsa bile bu veriden hiçbir şey '
              'çıkmıyor demektir.');
    });

    test('[$fixture] motorun ÜRETTİĞİ her anahtar kural setinde BEYANLI', () {
      final ({
        int frames,
        int judgeable,
        int attempts,
        List<String> keys,
        Set<String> suppressions,
      }) r = run(fixture);

      // Bu, statik "her feedbackKey bir cue'ya varıyor" kapısından FARKLI
      // bir soru: orada kural setinin İÇİNDEKİ anahtarlar tarandı, burada
      // motorun ÇALIŞIRKEN ürettikleri. Aradaki fark, bu gecenin tekrar
      // eden dersi: beyanın varlığı, o yoldan geçildiğinin kanıtı değil.
      final Set<String> declared = declaredKeys();
      expect(declared.length, greaterThanOrEqualTo(14),
          reason: 'kural setinden yalnız ${declared.length} anahtar '
              'okundu — tarayıcı bozuk, "tanımsız anahtar yok" sonucu '
              'ANLAMSIZ');

      final List<String> unknown =
          r.keys.where((String k) => !declared.contains(k)).toSet().toList();
      expect(unknown, isEmpty,
          reason: 'motor kural setinde BEYAN EDİLMEYEN anahtar üretti: '
              '$unknown — bu bir cümleye çevrilemez ve ham kod olarak '
              'yüzeye sızma riski taşır (J-099)');
    });
  }

  test('EKSİK FIXTURE SINIFI ADIYLA DURUYOR — seans-sınıfı fixture YOK', () {
    // Bu test bir kusur aramıyor; bir BOŞLUĞU kaydediyor ve boşluk
    // kapandığında ÖTÜYOR, böylece belge kendiliğinden bayatlamaz.
    //
    // Bugünkü iki fixture ÖLÇÜ çapraz-kontrolü için hasat edildi. Gerçek
    // veriden bir SEANS çıktığını gösteren üçüncü sınıf YOK — ve o
    // boşluk, cihaz turunun neden bir ENGEL olduğunun teknik hâli.
    final List<String> golden = Directory('test/golden')
        .listSync()
        .whereType<File>()
        .map((File f) => f.uri.pathSegments.last)
        .where((String n) => n.endsWith('.json'))
        .toList()
      ..sort();

    expect(golden, fixtures,
        reason: 'golden dizini değişti: $golden\n\n'
            'SEANS-SINIFI bir fixture eklendiyse (tam bir yumruk döngüsü '
            'içeren, gürültüye dayanıklılığı sınayan gerçek veri): bu '
            'testi güncelle, "tamamlanan deneme > 0" ölçen gerçek bir '
            'kapı yaz ve `docs/design/KAPI-ENVANTERI.md`ye işle. O kapı '
            'bugün YAZILAMIYOR çünkü sınayacağı veri yok.');
  });

  test('ÖLÇÜM DÖKÜMÜ — gerçek veri ne üretiyor (bilgi, kapı değil)', () {
    final StringBuffer b = StringBuffer();
    for (final String f in fixtures) {
      final ({
        int frames,
        int judgeable,
        int attempts,
        List<String> keys,
        Set<String> suppressions,
      }) r = run(f);
      final Map<String, int> tally = <String, int>{};
      for (final String k in r.keys) {
        tally[k] = (tally[k] ?? 0) + 1;
      }
      b
        ..writeln('  $f')
        ..writeln('    kare ${r.frames} · hüküm verilebilir ${r.judgeable} '
            '(%${(100 * r.judgeable / r.frames).toStringAsFixed(1)})')
        ..writeln('    tamamlanan deneme ${r.attempts}  ← ÖLÇÜ fixture\'ı, '
            'yumruk döngüsü içermesi amaçlanmadı')
        ..writeln('    bastırma: ${r.suppressions.join(", ")}')
        ..writeln('    anahtarlar: $tally');
    }
    // ignore: avoid_print
    print('\n=== GERÇEK HASAT VERİSİ · MOTOR DÖKÜMÜ ===\n$b');
    expect(true, isTrue);
  });
}
