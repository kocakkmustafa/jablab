import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// `stance` referansının ürüne bağlanması — değişmezler.
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

  test('M-F-38: tolerans provisional işaretli (n=3 yetersiz örneklem)', () {
    expect(ref['toleranceStatus'], 'provisional');
    expect(ref['contributingTakes'], lessThan(5),
        reason: 'n≥5 olduğunda status güncellenmeli — bu test o günü hatırlatır');
  });

  test('AYRIM ÖLÇÜMDEN TÜRETİLİR: skorlanan her eklem tabanda, koçlanan üstünde',
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
      final double d =
          ((e.value as Map)['measuredDispersionDeg'] as num).toDouble();
      expect(d, greaterThan(floorDeg),
          reason: '${e.key} koçlanan listesinde ama dispersiyonu tabanda — '
              'skorlanabilirken skorlanmıyor, kapsam gereksiz daralıyor');
    }
  });

  test('tolerans serbest bandı asla ölçülen dispersiyonun altına inmez', () {
    for (final MapEntry<String, dynamic> e in scored.entries) {
      final Map<String, dynamic> j = (e.value as Map).cast<String, dynamic>();
      expect((j['freeDeg'] as num).toDouble(),
          greaterThanOrEqualTo((j['measuredDispersionDeg'] as num).toDouble()),
          reason: '${e.key}: serbest bant ölçülen ayrışmadan dar — '
              'eğitmenlerin kendi arasındaki farkı kullanıcının hatası sayar');
    }
  });

  test('gard/kol hükümleri SKORA girmez (D2 + referans çifte mührü)', () {
    // İki bağımsız ölçüm aynı sınırı gösterdi: D2'de blur/kapanma, referansta
    // eğitmen ayrışması. Skorlanan listede kol eklemi belirirse ikisi de
    // çiğnenmiş olur.
    const List<String> armJoints = <String>[
      'left_elbow', 'right_elbow', 'left_upper_arm', 'right_upper_arm',
      'left_forearm', 'right_forearm',
    ];
    for (final String a in armJoints) {
      expect(scored.containsKey(a), isFalse,
          reason: '$a skorlanan listesinde — gard/kol dar toleransla '
              'skorlanamaz (J-033)');
    }
  });

  test('"kollar vs bacaklar" basitleştirmesi config\'te YOK', () {
    // Ölçüm bu sanıyı çürüttü: öne çıkan (lead) tarafın kalça ve uyluğu da
    // ~27° ayrışıyor, arka omuz 13,3°'de uyuşuyor. Ayrım anatomik değil.
    expect(coached.containsKey('left_hip'), isTrue);
    expect(coached.containsKey('left_thigh'), isTrue);
    expect(scored.containsKey('right_shoulder'), isTrue);
  });
}
