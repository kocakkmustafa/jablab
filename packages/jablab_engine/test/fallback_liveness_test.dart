import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

/// FALLBACK CANLILIK KAPISI — aile kuralı M-F-184/1 (J-077).
///
/// Reçete: `ventures/motion-core/workspace/FALLBACK-CANLILIK-RECETESI.md`
///
/// Kural: *bir fallback sınıfının VAR olması, tanımadığı girdinin ORAYA
/// düştüğü anlamına gelmez.* `unclassified_strike` kural setinde duruyor ve
/// yıllarca "kanca sayılıyor ama sınıflandırılmıyor" cümlesinin dayanağı
/// oldu — hiç ölçülmeden. Bu dosya o ölçümü KALICI hâle getiriyor.
///
/// ⚠️ **Buradaki testler mevcut davranışı KARAKTERİZE ediyor, ONAYLAMIYOR.**
/// Reçetenin Adım-4 kapısı ("sözlük-dışı girdi fallback'e DÜŞMELİ") JabLab'da
/// bugün KIRMIZI olurdu: ölçüm gösterdi ki kanca fallback'e düşmüyor, hiç
/// görünmüyor (mekanizma B). O kapı düzeltmenin parçasıdır, bu turun değil —
/// açık boşluk DEFTER J-077'de P1. Aşağıdaki beklentiler, davranış
/// DEĞİŞTİĞİNDE kırmızıya dönsün diye var: fallback bir gün tetiklenmeye
/// başlarsa (ya da tetiklenmesi umulup sessizce tetiklenmemeye devam ederse)
/// bunu bir sonraki oturum sayıdan öğrenir, varsayımdan değil.
void main() {
  final RuleSet rules = RuleSet.fromJson(
    (jsonDecode(File('../../assets/rulesets/boxing@1.0.0.json')
                .readAsStringSync()) as Map)
        .cast<String, dynamic>(),
  );

  test('fallback sınıfı kural setinde GERÇEKTEN tanımlı ve fazları var', () {
    // En eski kilit gerekçesi bu sınıfın varlığına dayanıyordu. Varlık
    // doğru — yanlış olan, varlığından tetiklendiği sonucunu çıkarmaktı.
    final TechniqueConfig fb = rules.techniques
        .firstWhere((TechniqueConfig t) => t.id == 'unclassified_strike');
    expect(fb.phases.map((TechniquePhase p) => p.id),
        containsAll(<String>['GUARD_READY', 'STRIKE_WINDOW']),
        reason: 'fallback fazsızsa hiç tetiklenemez');
  });

  test('SÖZLÜK: modellenmiş teknikler İSİMLE sabit — hook/uppercut YOK', () {
    // Sözlüğün kendisi ölçümün ön koşulu (reçete Adım 1). Buraya bir gün
    // hook eklenirse bu test kırılır ve fallback ölçümü YENİDEN yapılmalıdır.
    expect(rules.techniques.map((TechniqueConfig t) => t.id).toSet(),
        <String>{'jab', 'cross', 'unclassified_strike'},
        reason: 'sözlük değiştiyse fallback canlılığı yeniden ölçülmeli');
  });

  group('sözlük-dışı girdi', () {
    // Gerçek sözlük-dışı girdi (lead-hook dersi, pVvOF2kQuIQ) repoda DEĞİL —
    // `~/motion-harvest/` altında ve git'e girmiyor. O yüzden buradaki girdi
    // sentetik; reçete Adım 2 bunu açıkça ayırıyor: sentetik girdi REGRESYON
    // kapısı için geçerli, ÖLÇÜM iddiası için değil. Gerçek malzemedeki
    // ölçüm: docs/g3/YUMRUK-TIPI-IMZA-OLCUMU.md §1.

    /// Yatay bir kol süpürmesi — kanca kabası. Kasıtlı olarak `EXTENSION`
    /// geometrisini KURMUYOR: bilek gövdenin önünden yatay geçer, ileri
    /// uzanma yok.
    List<PoseFrame> sweep() {
      final List<PoseFrame> out = <PoseFrame>[];
      for (int i = 0; i < 120; i++) {
        final double p = i / 119.0;
        // Sol bilek soldan sağa yatay süpürüyor, omuz hizasında.
        final double wx = 0.30 + 0.40 * p;
        out.add(_frame(tUs: i * 33367, leadWristX: wx, leadWristY: 0.42));
      }
      return out;
    }

    test('KARAKTERİZASYON: yatay süpürme ne fallback ne jab/cross üretiyor',
        () {
      final StrikingEngine engine = StrikingEngine(
        ruleSet: rules,
        calibrationMapped: true,
        frameSize: const FrameSize(1920, 1080),
        provenance: <String, String>{
          'poseModelVariant': 'synthetic',
          'calibrationProfileId': 'fallback_liveness',
        },
      );
      final Map<String, int> completed = <String, int>{};
      int aborted = 0;
      for (final PoseFrame f in sweep()) {
        final AttemptDigest? d = engine.process(f).completedAttempt;
        if (d == null) continue;
        if (d.outcome == AttemptOutcome.completed) {
          completed[d.techniqueId] = (completed[d.techniqueId] ?? 0) + 1;
        } else {
          aborted++;
        }
      }

      // ÜÇ sayaç birlikte (reçete Adım 3). Teşhis tablosunun hangi satırına
      // düştüğümüz bu üçlüden okunur.
      printOnFailure('completed=$completed aborted=$aborted');

      // Bugünün ölçülmüş gerçeği: hiçbir modellenmiş sınıf TAMAMLANMIYOR.
      // Bu iyi haber (mekanizma A yok — yanlış sayım yok)...
      expect(completed['jab'] ?? 0, 0,
          reason: 'yatay süpürme jab olarak TAMAMLANDI → mekanizma A '
              '(yanlış-sınıflama) ortaya çıktı, reçete Adım 5 uygulanmalı');
      expect(completed['cross'] ?? 0, 0,
          reason: 'yatay süpürme cross olarak TAMAMLANDI → mekanizma A');

      // ...ama fallback de tetiklenmiyor: mekanizma B (görünmezlik).
      // Bu beklenti BİLEREK "0" pinliyor ve bu bir HEDEF DEĞİL, bir
      // KARAKTERİZASYON: fallback bir gün canlanırsa test kırılır ve
      // düzeltmeyi FARK EDERİZ. Kırıldığında yapılacak şey testi değiştirmek
      // değil, J-077'yi kapatmak.
      expect(completed['unclassified_strike'] ?? 0, 0,
          reason: 'fallback TETİKLENDİ — J-077 kapanmış olabilir; '
              'docs/g3/YUMRUK-TIPI-IMZA-OLCUMU.md ve library.json '
              'lockedBy=technique-invisible gerekçesi YENİDEN ölçülmeli');
    });
  });
}

/// Minimal iskelet: yalnız duruş+jab kapılarının okuduğu eklemler anlamlı,
/// gerisi sabit ve GÖRÜNÜR (güven kapısı testi bu değil).
PoseFrame _frame({
  required int tUs,
  required double leadWristX,
  required double leadWristY,
}) {
  final List<PoseLandmark> lm = List<PoseLandmark>.generate(
      Lm.count, (int _) => const PoseLandmark(0.5, 0.5, 0, 0.95));
  void put(int i, double x, double y) =>
      lm[i] = PoseLandmark(x, y, 0, 0.95);

  put(11, 0.44, 0.40); // sol omuz
  put(12, 0.56, 0.40); // sağ omuz
  put(13, 0.42, 0.50); // sol dirsek
  put(14, 0.58, 0.50); // sağ dirsek
  put(15, leadWristX, leadWristY); // sol bilek — süpürme burada
  put(16, 0.58, 0.46); // sağ bilek (gard)
  put(23, 0.46, 0.62); // sol kalça
  put(24, 0.54, 0.62); // sağ kalça
  put(25, 0.44, 0.76); // sol diz
  put(26, 0.56, 0.76); // sağ diz
  put(27, 0.42, 0.90); // sol ayak bileği
  put(28, 0.58, 0.90); // sağ ayak bileği

  return PoseFrame(
    tUs: tUs,
    landmarks: lm,
    modelVersion: 'synthetic',
  );
}
