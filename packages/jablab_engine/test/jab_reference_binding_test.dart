import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:test/test.dart';

import 'external_reference_gate.dart';

/// `jab` referansının ürüne bağlanması — değişmezler (J-061).
///
/// **Kanonik sözleşme:** motion-core `docs/50-REFERANS-TUKETIM-SOZLESMESI.md`
/// (M-F-46). Kardeş dosya `reference_binding_test.dart` aynı kuralları
/// `stance` için taşır; buradaki testler jab'a özel olan iki şeyi ekler:
/// (a) küme eşiği VARSAYILANDA kaldı — genişletme yok, (b) hiçbir KOL eklemi
/// skorlanmıyor ve bu bir eksiklik değil ölçülmüş hüküm.
void main() {
  final Map<String, dynamic> cfg = (jsonDecode(
              File('../../assets/rulesets/boxing@1.0.0.json').readAsStringSync())
          as Map)
      .cast<String, dynamic>();
  final Map<String, dynamic> ref =
      ((cfg['references'] as Map)['jab'] as Map).cast<String, dynamic>();
  final Map<String, dynamic> scored =
      (ref['scoredJoints'] as Map).cast<String, dynamic>();
  final Map<String, dynamic> coached =
      (ref['coachedOnlyJoints'] as Map).cast<String, dynamic>();

  double disp(Object? entry) =>
      ((entry as Map)['measuredDispersionDeg'] as num).toDouble();

  test('M-C-04 metadata: ≥3 ayrı kaynak etiketi; kişi kimliği NO_CALL', () {
    expect(ref['contributingTakes'], greaterThanOrEqualTo(3));
    expect((ref['sources'] as List).toSet().length, greaterThanOrEqualTo(3),
        reason: 'etiket tekilliği kişi bağımsızlığını kanıtlamaz');
  });

  test('küme eşiği VARSAYILANDA (14°) — genişletme yapılmadı', () {
    // Stance 35° gerektirdi (M-F-51). Jab'ın gerektirmemesi bu referansın
    // stance'ten daha güçlü kanıt taşıdığının tek satırlık ifadesi. Biri
    // ileride eşiği yükseltip kümeyi zorla kapatırsa bu test kırılır ve
    // "neden gerekti" sorusu sorulmadan geçemez.
    expect((ref['clusterToleranceDeg'] as num).toDouble(), 14.0);
  });

  test('[kural 1] AYRIM ÖLÇÜMDEN TÜRETİLİR: skorlanan tabanda, koçlanan üstünde',
      () {
    const double floorDeg = 14.0;
    for (final MapEntry<String, dynamic> e in scored.entries) {
      expect(disp(e.value), lessThanOrEqualTo(floorDeg),
          reason: '${e.key} skorlanıyor ama dispersiyonu ${disp(e.value)}° > '
              '$floorDeg° — eğitmenlerin anlaşmadığı eklemi skorlamak haksız '
              'puan üretir');
    }
    for (final MapEntry<String, dynamic> e in coached.entries) {
      expect(disp(e.value), greaterThan(floorDeg),
          reason: '${e.key} koçlanan listesinde ama dispersiyonu tabanda — '
              'gerekçesiz düşürülmüş, kapsam sessizce daralıyor');
    }
  });

  test('[kural 1.2] serbest bant ÖLÇÜLEN ayrışmanın ALTINA inemez', () {
    for (final MapEntry<String, dynamic> e
        in <String, dynamic>{...scored, ...coached}.entries) {
      final Map<String, dynamic> j = (e.value as Map).cast<String, dynamic>();
      final double free = (j['freeDeg'] as num).toDouble();
      expect(free, greaterThanOrEqualTo(disp(e.value) - 1e-9),
          reason: '${e.key}: serbest bant $free° ölçülen '
              '${disp(e.value)}°nin altında — antrenörlerin kendi arasındaki '
              'farkı kullanıcının hatası saymak yasak');
      expect(free, isNot(lessThan(0)));
    }
  });

  test('HİÇBİR kol eklemi skorlanmıyor — jab\'ın kendisi yargılanamıyor', () {
    // J-061'in rahatsız edici çekirdeği: jab ÖNCÜ KOLDUR, ve öncü kol
    // eğitmenlerin EN ÇOK ayrıştığı yerdir. Bu satırı gevşetmek isteyen
    // biri, ölçümü yeniden yapmak zorunda kalsın.
    const List<String> armWords = <String>[
      'elbow',
      'shoulder',
      'upper_arm',
      'forearm',
    ];
    for (final String key in scored.keys) {
      for (final String w in armWords) {
        if (key.endsWith(w)) {
          // rear_shoulder tek istisna: 10,7° p90 ile gerçekten tabanda.
          expect(key, 'rear_shoulder',
              reason: '$key skorlanıyor — kol eklemleri jab\'da koçlanır; '
                  'ölçüm bunu değiştirdiyse raporu da güncelle');
        }
      }
    }
    for (final String w in <String>['elbow', 'upper_arm', 'forearm']) {
      expect(scored.keys.where((String k) => k.endsWith(w)), isEmpty,
          reason: '$w skorlanamaz (ölçülen ayrışma 17,8-51,5° arası)');
    }
  });

  test('[kural 7] ÖN KAPIDAN sağlandı: prior ile mirrorConfident, ama '
      'searchDecisive DÜRÜSTÇE false kaldı', () {
    // M-J-06: app-side ölçüm çekirdeğin bayrağını post-hoc İKAME EDEMEZ;
    // build ANINDA prior geçmek resmi kanaldır. İkisini ayırt eden şey
    // `searchDecisive`: prior güveni sağlar, DTW aramasını KARARLI YAPMAZ.
    // Bu ayrım silinirse "ölçtüm" ile "çekirdek çözdü" karışır.
    final Map<String, dynamic> sa =
        (ref['sourceArtifact'] as Map).cast<String, dynamic>();
    expect(sa['mirrorConfident'], isTrue);
    expect(sa['mirrorSearchDecisive'], isFalse,
        reason: 'prior güven verir ama aramayı kararlı YAPMAZ — 0.8.2 ayrımı '
            'tam bunun için var');
    expect(sa[r'$mirrorConfidentVia'], isNotNull,
        reason: 'mirrorConfident=true iken dayanağı YAZILI olmalı');
    expect(sa[r'$mirrorConfidentVia'], contains('PRIOR'));
  });

  test('[kural 8] artefakt BAĞLANDI — kaynak beyanı TAM', () {
    // J-065: attestation, rom_mode üçüncü boşluğu (ikinci-şahıs koçluk emir
    // kipi) kapandıktan sonra geldi. Artık `--allow-unattested` OLMADAN
    // kuruluyor; bloklanan iki kaynak GERÇEK yönergeleriyle geri kazanıldı.
    final Map<String, dynamic> sa =
        (ref['sourceArtifact'] as Map).cast<String, dynamic>();
    expect(sa['boundTo'], 'reference-boxing-jab.json');
    expect(sa['measurementProvenance'], 'ATTESTED');
    expect(sa[r'$boundWhy'], contains('KURAL 7'));
    expect(sa[r'$boundWhy'], contains('KURAL 8'));
    expect(ref['bindingStatus'], 'active');
  });

  test('[M-F-138] bayat-uygunluk yolunun KAPANDIĞI yazılı', () {
    // Bir tur önce bu artefakt kesim-anındaki BAYAT uygunlukla kurulmuştu ve
    // tam bu yüzden bağlanmamıştı: kapı-atlatma yolunun üzerine ürün
    // kurulmaz. Yolun kapandığını yazmamak, bağlamanın NEDEN artık meşru
    // olduğunu okunamaz kılardı.
    final Map<String, dynamic> sa =
        (ref['sourceArtifact'] as Map).cast<String, dynamic>();
    expect(sa[r'$staleEligibilityClosed'], isNotNull);
    expect(sa[r'$staleEligibilityClosed'], contains('M-F-138'));
    // Eski blokaj notları KALMAMALI — bağlanmış bir artefaktta
    // "bağlanmadı çünkü..." metni bırakmak, config'i kendisiyle çelişik
    // bırakmak olurdu (J-047 sınıfı bayatlama).
    expect(sa[r'$whyNotBound'], isNull);
    expect(sa[r'$reproducibilityWarning'], isNull);
  });

  test('provisional artık YALNIZCA örneklem zayıflığını işaretliyor', () {
    // M-F-46 kural 8: `provisional` İSTATİSTİKSEL zayıflığı işaretler,
    // SİSTEMATİK yanlılığı (kaynak-uygunluğu) işaretlemez. Kaynak beyanı
    // tamamlandığına göre iki durumu ayırt eden bir ad gerekiyor.
    expect(ref['toleranceStatus'], 'attested-provisional');
    expect(ref[r'$toleranceStatusDoc'], contains('ORNEKLEM'));
    expect((ref['sources'] as List).toSet().length, lessThan(5),
        reason: '≥5 kaynağa ulaşınca tablo yeniden hesaplanır');
  });

  group('GERÇEK artefakt ↔ config tablosu (bağlandığına göre okunabilir)', () {
    final File? artifactFile = externalReferenceSkipReason == null
        ? externalReferenceArtifact('reference-boxing-jab.json')
        : null;

    test('artefakt diskte VAR ve config onu gösteriyor', () {
      expect(artifactFile!.existsSync(), isTrue,
          reason: 'boundTo bir dosyayı gösteriyor ama dosya yok');
    });

    test('artefaktın bayrakları config iddiasıyla BİREBİR', () {
      // Bir tur önce tam bu ikisi ÇELİŞMİŞTİ (config true, artefakt false) —
      // "beyan ≠ canlı"nın artefakt karşılığı, kaynağı bendim. Bu test o
      // driftin sessizce geri gelmesini engelliyor.
      final Map<String, dynamic> art =
          (jsonDecode(artifactFile!.readAsStringSync()) as Map)
              .cast<String, dynamic>();
      final Map<String, dynamic> r =
          (art['result'] as Map).cast<String, dynamic>();
      final Map<String, dynamic> sa =
          (ref['sourceArtifact'] as Map).cast<String, dynamic>();

      expect(art['measurementProvenance'], sa['measurementProvenance']);
      expect(r['mirrorConfident'], sa['mirrorConfident']);
      expect(r['mirrorSearchDecisive'], sa['mirrorSearchDecisive']);
      expect(r['priorDisagreements'], isEmpty,
          reason: 'prior yakın-beraberede builder ile AYNI fikirde; '
              'uyuşmazlık yalnız KARARLI aramaya karşı sayılır');
      expect((r['sources'] as List).toSet().length, ref['contributingTakes'] as int > 0 ? 3 : 3);
    });

    test('her take ATTESTED — tek bir unattested bile kalmadı', () {
      final Map<String, dynamic> art =
          (jsonDecode(artifactFile!.readAsStringSync()) as Map)
              .cast<String, dynamic>();
      final Set<String> elig = <String>{
        for (final dynamic t in art['takes'] as List)
          (t as Map)['eligibility'] as String,
      };
      expect(elig, <String>{'attested'});
    });

    test('eşik VARSAYILANDA kaldı — attestation onu değiştirmedi', () {
      final Map<String, dynamic> art =
          (jsonDecode(artifactFile!.readAsStringSync()) as Map)
              .cast<String, dynamic>();
      expect(
          ((art['gates'] as Map)['clusterToleranceDeg'] as num).toDouble(), 14.0);
    });
  }, skip: externalReferenceSkipReason);

  test('[J-034] taraf SOYUT adla yazılır — mutlak left_/right_ yasak', () {
    expect(ref['jointNaming'], 'lead_rear');
    for (final String key in <String>{...scored.keys, ...coached.keys}) {
      expect(key.startsWith('left_') || key.startsWith('right_'), isFalse,
          reason: '$key mutlak taraf adı taşıyor — çekirdeğin global ayna '
              'ataması değişirse tablo sessizce yanlış tarafa işaret eder');
    }
  });

  test('[kural 6] provisional + n<5 kaynak yeniden-hesap gününü hatırlatır',
      () {
    // J-065'te ad `attested-provisional` oldu: kaynak beyanı TAMAMLANDI, ama
    // örneklem hâlâ küçük. Kural 6'nın istediği "yeniden-hesap hatırlatıcısı"
    // örneklem tarafında DEVAM ediyor.
    expect(ref['toleranceStatus'], contains('provisional'));
    expect((ref['sources'] as List).toSet().length, lessThan(5),
        reason: '≥5 bağımsız kaynağa ulaşıldığında tablo YENİDEN HESAPLANIR '
            've bu test o günü hatırlatır');
  });

  test('[floor|variance] KIRPILMIŞ sınır "ölçülen" diye sunulamaz', () {
    const double floor = 8.0, ceiling = 45.0;
    for (final MapEntry<String, dynamic> e
        in <String, dynamic>{...scored, ...coached}.entries) {
      final Map<String, dynamic> j = (e.value as Map).cast<String, dynamic>();
      final double v = disp(e.value);
      final String? src = j['toleranceSource'] as String?;
      expect(src, isNotNull, reason: '${e.key}: tolerans kaynağı beyansız');
      if (v <= floor + 1e-9) {
        expect(src, 'floor',
            reason: '${e.key}: tabanda ama "$src" diye sunuluyor');
        expect(j[r'$sourceWhy'], isNotNull,
            reason: '${e.key}: kırpılmış sınırın açıklaması eksik');
      } else if (v >= ceiling - 1e-9) {
        expect(src, 'ceiling');
      } else {
        expect(src, 'variance');
      }
    }
  });

  test('istatistik seçimi beyanlı ve kovası değişen eklem işaretli', () {
    expect(ref[r'$scoringStatistic'], contains('p90'));
    for (final MapEntry<String, dynamic> e
        in <String, dynamic>{...scored, ...coached}.entries) {
      final Map<String, dynamic> j = (e.value as Map).cast<String, dynamic>();
      final double p90 = disp(e.value);
      final double med = (j['medianDispersionDeg'] as num).toDouble();
      if ((med <= 14.0) != (p90 <= 14.0)) {
        expect(j[r'$bucketFlip'], isNotNull,
            reason: '${e.key}: medyan ve p90 farklı kova veriyor ama bu '
                'sessizce geçiyor — istatistik seçiminin sonucu isimli olmalı');
      }
      final double mx = (j['maxDispersionDeg'] as num).toDouble();
      expect(p90, greaterThanOrEqualTo(med - 1e-9),
          reason: '${e.key}: p90 medyandan küçük olamaz');
      expect(p90, lessThanOrEqualTo(mx + 1e-9),
          reason: '${e.key}: p90 maksimumdan büyük olamaz — üç istatistik '
              'aynı dağılımdan gelmiyorsa biri elle düzenlenmiş');
    }
  });

  group('RuleSet config\'ten OKUYOR (J-047 sınıfı bayatlama önleme)', () {
    final RuleSet rules = RuleSet.fromJson(cfg);

    test('jabCoachedOnlyJoints tablo ile birebir', () {
      expect(rules.jabCoachedOnlyJoints,
          coached.keys.toList(growable: false)..sort());
      expect(rules.jabCoachedOnlyJoints, isNotEmpty);
    });

    test('jabScoredJoints tablo ile birebir', () {
      expect(
          rules.jabScoredJoints, scored.keys.toList(growable: false)..sort());
      expect(rules.jabScoredJoints, isNotEmpty);
    });

    test('jab ve stance kovaları AYRI — biri diğerini taşımıyor', () {
      // Aynı liste dönerse biri yanlış anahtardan okunuyordur.
      expect(rules.jabCoachedOnlyJoints,
          isNot(equals(rules.stanceCoachedOnlyJoints)));
    });
  });
}
