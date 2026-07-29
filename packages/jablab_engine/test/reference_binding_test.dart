import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// `stance` referansının ürüne bağlanması — değişmezler.
///
/// **Kanonik sözleşme:** motion-core `docs/50-REFERANS-TUKETIM-SOZLESMESI.md`
/// (M-F-46). Aşağıdaki testler o dokümanın numaralı kurallarını taşır;
/// kural metni değişirse burası da değişmeli.
///
/// Referans ürüne bağlandığı an, "hangi eklem skorlanır" kararı bir doküman
/// cümlesi olmaktan çıkıp **kullanıcının aldığı puanı** belirler. Bu yüzden
/// ayrımın ölçümle tutarlı kaldığı burada zorlanır: bir sonraki içerik
/// turunda "şunu da skorlayalım" demek, testi kırmadan mümkün olmamalı.
void main() {
  final Map<String, dynamic> cfg = (jsonDecode(
              File('../../assets/rulesets/boxing@1.0.0.json').readAsStringSync())
          as Map)
      .cast<String, dynamic>();
  final Map<String, dynamic> ref =
      ((cfg['references'] as Map)['stance'] as Map).cast<String, dynamic>();
  final Map<String, dynamic> scored =
      (ref['scoredJoints'] as Map).cast<String, dynamic>();
  final Map<String, dynamic> coached =
      (ref['coachedOnlyJoints'] as Map).cast<String, dynamic>();

  test('M-C-04: referans ≥3 bağımsız eğitmenden üretildi', () {
    expect(ref['contributingTakes'], greaterThanOrEqualTo(3));
    expect((ref['sources'] as List).toSet().length, greaterThanOrEqualTo(3),
        reason: 'aynı eğitmenin iki take\'i TEK kaynak sayılır');
  });

  test('[kural 6] tolerans provisional işaretli (n=3 yetersiz örneklem)', () {
    expect(ref['toleranceStatus'], 'provisional');
    expect(ref['contributingTakes'], lessThan(5),
        reason: 'n≥5 olduğunda status güncellenmeli — bu test o günü hatırlatır');
  });

  test('[kural 1] AYRIM ÖLÇÜMDEN TÜRETİLİR: skorlanan her eklem tabanda, koçlanan üstünde',
      () {
    const double floorDeg = 14.0;
    for (final MapEntry<String, dynamic> e in scored.entries) {
      final double d =
          ((e.value as Map)['measuredDispersionDeg'] as num).toDouble();
      expect(d, lessThanOrEqualTo(floorDeg),
          reason: '${e.key} skorlanıyor ama dispersiyonu $d° > $floorDeg° — '
              'eğitmenlerin anlaşmadığı bir eklemi skorlamak haksız puan üretir');
    }
    for (final MapEntry<String, dynamic> e in coached.entries) {
      final Map<String, dynamic> j = (e.value as Map).cast<String, dynamic>();
      final double d = (j['measuredDispersionDeg'] as num).toDouble();
      if (d <= floorDeg) {
        // J-035: sd tabanın altında olduğu hâlde koçlanan tek meşru yol,
        // take AÇIKLIĞIYLA düşürülmüş olmaktır. sd n=3'te dayanıklı değil;
        // {-1,9 · -3,8 · -28,4} sd 12,0° verir ama uzlaşı değil bölünmedir.
        // Gerekçenin niteliği curriculum_binding_test'te ayrıca zorlanıyor.
        expect(j['demotedBy'], 'takeSpread',
            reason: '${e.key} koçlanan listesinde ama dispersiyonu tabanda — '
                'gerekçesiz düşürülmüş, kapsam sessizce daralıyor');
        continue;
      }
      expect(d, greaterThan(floorDeg));
    }
  });

  test('[kural 2] tolerans serbest bandı asla ölçülen dispersiyonun altına inmez', () {
    for (final MapEntry<String, dynamic> e in scored.entries) {
      final Map<String, dynamic> j = (e.value as Map).cast<String, dynamic>();
      expect((j['freeDeg'] as num).toDouble(),
          greaterThanOrEqualTo((j['measuredDispersionDeg'] as num).toDouble()),
          reason: '${e.key}: serbest bant ölçülen ayrışmadan dar — '
              'eğitmenlerin kendi arasındaki farkı kullanıcının hatası sayar');
    }
  });

  test('[kural 3] gard/kol hükümleri SKORA girmez (D2 + referans çifte mührü)', () {
    // İki bağımsız ölçüm aynı sınırı gösterdi: D2'de blur/kapanma, referansta
    // eğitmen ayrışması. Skorlanan listede kol eklemi belirirse ikisi de
    // çiğnenmiş olur.
    const List<String> armJoints = <String>[
      'lead_elbow', 'rear_elbow', 'lead_upper_arm', 'rear_upper_arm',
      'lead_forearm', 'rear_forearm',
    ];
    for (final String a in armJoints) {
      expect(scored.containsKey(a), isFalse,
          reason: '$a skorlanan listesinde — gard/kol dar toleransla '
              'skorlanamaz (J-033)');
    }
  });

  test('"kollar vs bacaklar" basitleştirmesi config\'te YOK', () {
    // Ölçüm bu sanıyı çürüttü: bir taraf kalça/uyluk ~27° ayrışıyor, karşı
    // omuz 13,3°'de uyuşuyor. Ayrım anatomik değil, ölçülmüş.
    expect(coached.containsKey('rear_hip'), isTrue);
    expect(coached.containsKey('rear_thigh'), isTrue);
    expect(scored.containsKey('lead_shoulder'), isTrue);
  });

  test('[J-034] eklem adları LEAD/REAR — mutlak taraf adı YASAK', () {
    // Referansın "sol"u, hangi take'lerin aynalandığına bağlıdır; builder'ın
    // ayna ataması değişince mutlak ad sessizce yanlış tarafa işaret eder.
    // M-F-06'nın referans katmanındaki karşılığı.
    expect(ref['jointNaming'], 'lead_rear');
    for (final String k in <String>[...scored.keys, ...coached.keys]) {
      expect(k.startsWith('left_') || k.startsWith('right_'), isFalse,
          reason: '$k mutlak taraf adı taşıyor — ayna ataması değişince kayar');
    }
  });

  test('[M-F-51] take-kapısı KABA soru, skorlama yetkisi eklem-bazlı', () {
    // Ara hüküm: take-kapısı "aynı hareket mi" diye sorar; "hangi eklem
    // skorlanır" sorusunu SORMAZ. stance take'leri aynı hareketi yapıyor,
    // yalnız gard stilleri farklı → 35° kaba soruyu geçirir, ince ayrımı
    // eklem tablosu yapar.
    expect(ref['bindingStatus'], 'active');
    expect(ref['clusterToleranceDeg'], 35);
    // Kanıt: 35° ve 60° eşikleriyle üretilen eklem tabloları birebir aynı —
    // küme eşiği ayrımı etkilemiyor, doğru yerde duruyor.
    expect(scored.length + coached.length, 17,
        reason: 'eklem tablosu küme eşiğinden bağımsız olmalı');
  });

  test('[kural 4] kalibre edilmemiş metrik SKORLANMAZ — PEAK checkpoint', () {
    // Sözleşme kural 4: "Geniş bant koyup skorlamak yetmez: o fazda
    // eğitmenler uyuşmuyor / 'doğru' diye bir şey ölçülmedi."
    // PEAK'te skorlanabilecek tek hüküm elbowFlareAngle'dı; J-007 o eşiği
    // kalibre edilemez bıraktı → faz checkpoint (skorlanmaz, koçlanır).
    final Map<String, dynamic> v3 = (jsonDecode(
                File('../../assets/rulesets/boxing.v3.json').readAsStringSync())
            as Map)
        .cast<String, dynamic>();
    for (final dynamic t in v3['techniques'] as List<dynamic>) {
      for (final dynamic p in (t as Map)['phases'] as List<dynamic>) {
        final Map<String, dynamic> ph = (p as Map).cast<String, dynamic>();
        if (ph['id'] != 'PEAK') continue;
        expect(ph['checkpoint'], isTrue,
            reason: '${t['id']}/PEAK skorlanıyor ama eşiği kalibre değil');
        expect(ph.containsKey('quality'), isFalse,
            reason: 'checkpoint fazında quality bloğu çelişkidir');
      }
    }
  });
}
