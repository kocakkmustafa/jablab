import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

RuleSet _rules() => RuleSet.fromJson(
    (jsonDecode(File('../../assets/rulesets/boxing@1.0.0.json')
            .readAsStringSync()) as Map)
        .cast<String, dynamic>());

/// DERİNLİK SÜPÜRMESİ — sayım eşiği ile hata eşiği arasında ulaşılamaz bölge
/// var mı (M-F-57, Gravita'nın 5-harekette bulduğu sınıf).
///
/// Kusurun şekli: sayım eşiği "doğru form" derinliğinde, hata eşiği onun
/// ötesinde duruyorsa, sığ çalışan kullanıcı **hiç sayılmaz ve hiçbir şey
/// duymaz**. Ürün onun için tamamen sessizdir — üstelik sığ çalışan tam da
/// yeni başlayan, yani Foundations'ın hedef kitlesi.
///
/// Kural: **sayım cömert DIŞ sınır, hata onun İÇİNDEKİ kalite çizgisidir.**
void main() {
  /// [t] = 0 gard, 1 tam uzanma. Aradaki her değer sığ bir yumruk.
  SyntheticPose punchAt(double t) => SyntheticPose(
        leftUpperArm: 1.35 * (1 - t),
        leftForearm: -1.45 * (1 - t),
        rightUpperArm: 1.75,
        rightForearm: -1.65,
      );

  ({bool counted, String? technique, Set<String> cues, double peak})
      throwPunch(double t) {
    final List<PoseFrame> frames = sequence(<SyntheticKeyframe>[
      SyntheticKeyframe(0, guardPose),
      SyntheticKeyframe(200000, guardPose),
      SyntheticKeyframe(320000, punchAt(t)),
      SyntheticKeyframe(520000, guardPose),
      // Zaman aşımının dolmasına izin ver: makine EXTENSION'da asılı kalırsa
      // terk kararı ancak timeout ile verilir. Kısa fixture bunu gizler.
      SyntheticKeyframe(1600000, guardPose),
      SyntheticKeyframe(2400000, guardPose),
    ]);
    final StrikingEngine e = StrikingEngine(
      ruleSet: _rules(),
      calibrationMapped: true,
      provenance: const <String, String>{
        'poseModelVariant': 'synthetic',
        'calibrationProfileId': 'test',
      },
    );
    AttemptDigest? digest;
    final Set<String> cues = <String>{};
    double peak = 0;
    for (final PoseFrame f in frames) {
      final EngineOutput out = e.process(f);
      digest ??= out.completedAttempt;
      cues.addAll(out.issues.map((DetectedIssue i) => i.feedbackKey));
      final double? er = out.measures?.all['lead.extensionRatio'] ??
          out.measures?.all['extensionRatio'];
      if (er != null && er > peak) peak = er;
    }
    return (
      counted: digest != null,
      technique: digest?.techniqueId,
      cues: cues,
      peak: peak
    );
  }

  /// Bir derinlikte yumruğun DERİNLİĞİ hakkında bir şey söyleniyor mu.
  /// Duruş/gard replikleri sayılmaz: kullanıcı hiç yumruk atmazken de
  /// çıkıyorlar, dolayısıyla "yumruğun ulaşmadı" bilgisini taşımıyorlar.
  bool speaksAboutDepth(Set<String> cues) =>
      cues.any((String c) => c.contains('extend') || c.contains('reach'));

  test('[J-042] KAPANDIĞINDA geçmesi gereken katı sürüm', () {
    for (int i = 0; i <= 20; i++) {
      final double t = i / 20;
      final ({bool counted, String? technique, Set<String> cues, double peak})
          r = throwPunch(t);
      if (r.peak <= 0.68) continue; // yumruk sayılmayacak kadar sığ
      expect(r.counted || speaksAboutDepth(r.cues), isTrue,
          reason: 'ext ${r.peak.toStringAsFixed(2)}: ne sayıldı ne derinlik '
              'hakkında bir şey söylendi');
    }
  });

  test('[M-F-60] "ulaşmadı" KOÇLANAN katmandan — skora girmez', () {
    // Sözleşme: bu bir teknik hükmü değil, bir GÖZLEM. A/B bandına konursa
    // puanlanabilir hâle gelir ve eğitmenlerin uzlaşmadığı bir şeyi
    // puanlamış oluruz — J-033'ün aynısı, yeni kılıkta.
    final StrikingEngine e = StrikingEngine(
      ruleSet: _rules(),
      calibrationMapped: true,
      provenance: const <String, String>{
        'poseModelVariant': 'synthetic',
        'calibrationProfileId': 'test',
      },
    );
    final List<PoseFrame> frames = sequence(<SyntheticKeyframe>[
      SyntheticKeyframe(0, guardPose),
      SyntheticKeyframe(200000, guardPose),
      SyntheticKeyframe(320000, punchAt(0.6)),
      SyntheticKeyframe(520000, guardPose),
      SyntheticKeyframe(1600000, guardPose),
    ]);
    DetectedIssue? aborted;
    for (final PoseFrame f in frames) {
      for (final DetectedIssue i in e.process(f).issues) {
        if (i.code == 'ATTEMPT_ABORTED') aborted ??= i;
      }
    }
    expect(aborted, isNotNull, reason: 'girişim kapatma hiç ateşlenmedi');
    expect(aborted!.band, 'coached',
        reason: 'A/B bandına konmuş — gözlem, hükme terfi etmiş');
    expect(aborted.evidence, contains('peakExtension'),
        reason: 'sözleşme peakExtension taşımayı şart koşuyor');
  });

  test('[M-F-60] SAYIM DEĞİŞMEDİ — girişim kapatma yalnız SESSİZLİĞİ bozar', () {
    // Sözleşmenin en kolay çiğnenen yarısı bu. "Ulaşmadı" repliğini eklerken
    // yarım hareketi sayıma dahil etmek, sessizliği çözerken sayım
    // dürüstlüğünü bozmak olurdu — üstelik kimse fark etmezdi, çünkü sayı
    // artıyor ve artan sayı iyi görünüyor.
    final List<String> counted = <String>[];
    for (int i = 0; i <= 20; i++) {
      final ({bool counted, String? technique, Set<String> cues, double peak})
          r = throwPunch(i / 20);
      if (r.counted) counted.add('${r.peak.toStringAsFixed(2)}:${r.technique}');
    }
    // Ölçülen dış sınır: yalnız PEAK eşiğini geçen hareketler sayılır ve
    // hepsi SPESİFİK teknik olarak sayılır (yedeğe düşen yok).
    expect(counted.every((String c) => c.endsWith(':jab')), isTrue,
        reason: 'yarım hareket yedek teknik olarak sayılmaya başladı: $counted');
    expect(counted.length, 7,
        reason: 'sayılan hareket adedi değişti — dış sınır kaydı: $counted');
  });
}
