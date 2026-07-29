import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:test/test.dart';

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

  test('M-C-04: referans ≥3 BAĞIMSIZ eğitmenden üretildi', () {
    expect(ref['contributingTakes'], greaterThanOrEqualTo(3));
    expect((ref['sources'] as List).toSet().length, greaterThanOrEqualTo(3),
        reason: "aynı eğitmenin iki take'i TEK kaynak sayılır");
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

  test('[kural 7+8] artefakt BAĞLANMADI ve sebebi isimli', () {
    final Map<String, dynamic> sa =
        (ref['sourceArtifact'] as Map).cast<String, dynamic>();
    expect(sa['boundTo'], isNull,
        reason: 'ayna güveni ve kaynak beyanı olmadan artefakttan '
            'taraf-bağımlı hüküm türetilemez');
    expect(sa['mirrorConfident'], isFalse);
    expect(sa['mirrorSearchDecisive'], isFalse);
    expect(sa[r'$whyNotBound'], isNotEmpty);
    expect(sa[r'$whyNotBound'], contains('KURAL 7'));
    expect(sa[r'$whyNotBound'], contains('KURAL 8'));
  });

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
    expect(ref['toleranceStatus'], 'provisional');
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
