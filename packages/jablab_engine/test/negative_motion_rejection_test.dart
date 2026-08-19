import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// JAB-P0-003 Step 1 — HELD-OUT NEGATİF FİXTURE'LAR (jab/cross OLMAYAN
/// hareketler yumruk SAYILMAMALI).
///
/// ## Kapsam — hangi soruyu sınıyor, hangisini SINAMIYOR
///
/// Bu dosya DEDEKTÖR MANTIĞINI (faz-durum-makinesi eşikleri) sentetik
/// iskeletlerle sınıyor — GERÇEK bir insanın gerçek kamerada MediaPipe'ı
/// KANDIRIP KANDIRAMAYACAĞINI DEĞİL. O soru roadmap'in 3.000-etiketli
/// holdout'una ait (EXTERNAL_GATE — `docs/evidence/production-line/
/// model-gate.json`) ve `engine_test.dart`'ın kendi sözleşmesiyle AYNI
/// sınırı taşır (`poseModelVariant: 'synthetic'`). İki soru KARIŞTIRILMAZ:
/// biri "algoritma mantıksal olarak doğru mu", öbürü "gerçek dünyada
/// güvenilir mi".
///
/// ## Fixture'lar NASIL kalibre edildi — tahmin DEĞİL, ÖLÇÜLDÜ
///
/// `assets/rulesets/boxing@1.0.0.json`in kendi `$fixtureRule`i (M-C-06)
/// "fixture eşiğin ~1.3 katı genlik taşımalı" diyor — ama bu ancak TEK bir
/// eşiği geçen fixture'lar için doğrudan uygulanabilir. Feint'inki gibi İKİ
/// eşik ARASINDA (minPeakExtension 0.70 – PEAK 0.85) KALMASI gereken bir
/// fixture'da 1,3× hiç sığmaz (0,70×1,3=0,91, PEAK'in kendisini aşar) — bu
/// yüzden feint'in genliği KURALIN RUHUNA göre (minPeakExtension'ı net
/// aşıp PEAK'ten net uzak durarak) seçildi, harfine göre değil; sebep
/// aşağıda adıyla yazılı. Tüm pozisyonlar gerçek `StrikingEngine`ye karşı
/// TEK-kareli `extensionRatio` ölçümüyle VE tam-dizi koşumuyla önceden
/// kalibre edildi (bu turun kendi ölçümü) — `midPose`nin (helpers.dart)
/// kendisi bile ÖLÇÜLMEDEN "yarı yol" sanılsaydı 0,84-0,89 (PEAK'e
/// bitişik) çıktığı için YANLIŞ bir feint fixture'ı üretirdi.
void main() {
  final RuleSet rules = loadBoxingRuleSet();

  StrikingEngine engine() => StrikingEngine(
        ruleSet: rules,
        calibrationMapped: true,
        provenance: const <String, String>{
          'poseModelVariant': 'synthetic',
          'calibrationProfileId': 'test',
        },
      );

  /// [frames]i motora sürer, tamamlanan denemeleri VE görülen tüm
  /// `DetectedIssue` kodlarını (birleşik küme) döner — negatif fixture'lar
  /// için "tamamlanmadı" tek başına yetmez, HANGİ mekanizmanın durdurduğu
  /// da (ya da hiç durdurmadığı, GUARD_READY'den hiç çıkmadıysa) adıyla
  /// ölçülmeli.
  ({List<AttemptDigest> digests, Set<String> issueCodes}) drive(
      List<PoseFrame> frames) {
    final StrikingEngine e = engine();
    final List<AttemptDigest> digests = <AttemptDigest>[];
    final Set<String> codes = <String>{};
    for (final PoseFrame f in frames) {
      final EngineOutput out = e.process(f);
      final AttemptDigest? d = out.completedAttempt;
      if (d != null) digests.add(d);
      codes.addAll(out.issues.map((DetectedIssue i) => i.code));
    }
    return (digests: digests, issueCodes: codes);
  }

  test('POZİTİF KONTROL — kurulum gerçekten bir yumruğu tamamlıyor '
      '(negatif fixture\'ların "sıfır" bulgusu anlamlı olsun diye)', () {
    final List<PoseFrame> jab = sequence(<SyntheticKeyframe>[
      SyntheticKeyframe(0, guardPose),
      SyntheticKeyframe(200000, guardPose),
      SyntheticKeyframe(320000, extendedPose),
      SyntheticKeyframe(520000, guardPose),
      SyntheticKeyframe(750000, guardPose),
    ]);
    final result = drive(jab);
    expect(result.digests, isNotEmpty,
        reason: 'VAKUM MUHAFIZI: aynı kalibrasyon zinciriyle kurulan '
            'gerçek bir yumruk bile tamamlanmıyorsa, aşağıdaki negatif '
            'fixture\'ların "tamamlanmadı" sonucu hiçbir şey KANITLAMAZ — '
            'motor zaten hiçbir şeyi tamamlatmıyor olabilir');
  });

  group('GARD / SLİP — kol EXTENSION eşiğine (0,68) hiç YAKLAŞMIYOR', () {
    test('slip: gövde/gard sabit kalırken YALNIZ gövde açısı değişiyor '
        '(kol hiç uzanmıyor)', () {
      // Ölçüldü: guardPose'un kendi extensionRatio'su ~0,15-0,18 —
      // EXTENSION eşiğinin (0,68) ÇOK altında, M-C-06'nın "1,3× genlik"
      // kuralını (0,68/1,3≈0,52 altı) rahatça karşılıyor. Slip'in gerçek
      // biyomekaniği (baş/gövdeyi menzil dışına eğmek) kol geometrisini
      // DEĞİŞTİRMEZ — bu yüzden asıl sınanan şey "gövde hareketi kol
      // eşiğini YANLIŞLIKLA tetiklemiyor" iddiasıdır.
      final List<PoseFrame> slip = sequence(<SyntheticKeyframe>[
        SyntheticKeyframe(0, guardPose),
        SyntheticKeyframe(150000,
            guardPose.copyWith(trunkAngle: -0.4)), // sola eğ
        SyntheticKeyframe(400000,
            guardPose.copyWith(trunkAngle: -0.4)), // tut
        SyntheticKeyframe(650000,
            guardPose.copyWith(trunkAngle: 0.3)), // sağa eğ (asimetrik)
        SyntheticKeyframe(900000, guardPose),
      ]);
      final result = drive(slip);
      expect(result.digests, isEmpty,
          reason: 'slip bir yumruk olarak TAMAMLANDI — kol hiç uzanmadan '
              'bir teknik tamamlanamaz, bu VAROLMAMASI gereken bir hata');
      expect(result.issueCodes, isNot(contains('ATTEMPT_ABORTED')),
          reason: 'ATTEMPT_ABORTED görüldü — bu, kolun EXTENSION eşiğine '
              'GİRDİĞİ anlamına gelir (abortOnRetreat yalnız EXTENSION\'a '
              'girmiş bir denemede tetiklenir). Slip\'te kol hiç uzanmamalı, '
              'yani makine GUARD_READY\'den HİÇ ÇIKMAMALI — bir "abort" '
              'bile fazla, "hiçbir şey olmadı" beklenir');
    });

    test('gard resetleme: eller gard İÇİNDE küçük asimetrik ayar yapıyor '
        '(EXTENSION\'a girmiyor)', () {
      final SyntheticPose slightlyRaised = SyntheticPose(
        leftUpperArm: guardPose.leftUpperArm - 0.15,
        leftForearm: guardPose.leftForearm + 0.10,
        rightUpperArm: guardPose.rightUpperArm,
        rightForearm: guardPose.rightForearm - 0.10,
      );
      final List<PoseFrame> reset = sequence(<SyntheticKeyframe>[
        SyntheticKeyframe(0, guardPose),
        SyntheticKeyframe(200000, slightlyRaised),
        SyntheticKeyframe(500000, guardPose),
        SyntheticKeyframe(750000, slightlyRaised),
        SyntheticKeyframe(1000000, guardPose),
      ]);
      final result = drive(reset);
      expect(result.digests, isEmpty,
          reason: 'gard-içi küçük ayar bir yumruk olarak TAMAMLANDI');
      expect(result.issueCodes, isNot(contains('ATTEMPT_ABORTED')),
          reason: 'gard-içi ayar EXTENSION eşiğini tetiklememeli — bir '
              'abort bile fazla');
    });
  });

  group('FEİNT — EXTENSION\'a girip PEAK\'e (0,85) ULAŞMADAN geri çekiliyor',
      () {
    /// `guardPose.lerp(SyntheticPose.neutral, t)`nin ÖLÇÜLEN extensionRatio
    /// eğrisi (bu turun kalibrasyonu, doğrusal DEĞİL): t=0,5→~0,77 ·
    /// t=0,55→~0,81 · t=0,6→~0,85 (PEAK sınırı) · t=0,65→~0,88 (PEAK'i
    /// AŞAR, artık feint değil gerçek-hızlı-yumruk sayılır).
    const double feintT = 0.5;

    List<PoseFrame> feintSequence(double t) => sequence(<SyntheticKeyframe>[
          SyntheticKeyframe(0, guardPose),
          SyntheticKeyframe(100000, guardPose),
          SyntheticKeyframe(250000, guardPose.lerp(SyntheticPose.neutral, t)),
          SyntheticKeyframe(320000, guardPose.lerp(SyntheticPose.neutral, t)),
          SyntheticKeyframe(450000, guardPose),
          SyntheticKeyframe(650000, guardPose),
        ]);

    test('t=$feintT (minPeakExtension 0,70\'i net aşar, PEAK 0,85\'e net '
        'uzak durur) → ATTEMPT_ABORTED, TAMAMLANMAZ', () {
      final result = drive(feintSequence(feintT));
      expect(result.digests, isEmpty,
          reason: 'feint bir yumruk olarak TAMAMLANDI — abortOnRetreat '
              'çalışmıyor olabilir');
      expect(result.issueCodes, contains('ATTEMPT_ABORTED'),
          reason: 'feint hiçbir İZ bırakmadan sessizce kayboldu — '
              'abortOnRetreat mekanizması hiç TETİKLENMEDİ mi, yoksa '
              'motor bu hareketi hiç ADAY bile saymadı mı belirsiz. '
              'ATTEMPT_ABORTED beklenir: kol GERÇEKTEN EXTENSION\'a '
              'girdi ve GERÇEKTEN geri çekildi, mekanizma bunu GÖRDÜ');
    });

    test('SINIR KONTROLÜ — t=0,65 (PEAK\'i aşar) AYNI şekil/zamanlamayla '
        'GERÇEKTEN tamamlanıyor (fixture\'ın sınırın DOĞRU tarafında '
        'olduğunun kanıtı)', () {
      // Bu, feint fixture'ının "her şeyi reddeden gevşek bir eşik" değil,
      // PEAK sınırının TAM KENDİSİNE yakın, bilinçli seçilmiş bir nokta
      // olduğunu kanıtlar — aynı zamanlama/şekille yalnız GENLİK
      // değiştiğinde sonuç TERSİNE dönüyor.
      final result = drive(feintSequence(0.65));
      expect(result.digests, isNotEmpty,
          reason: 't=0,65 PEAK eşiğini (0,85) aşıyor — bu artık kısa ama '
              'GERÇEK bir yumruk, feint DEĞİL; tamamlanmaması feint '
              'fixture\'ının aslında hiçbir şeyi doğru sınamadığının '
              'işareti olurdu (her genlik reddediliyor demektir)');
    });
  });

  group('YÜRÜYÜŞ/RASTGELE KOL SALLAMA — hız FARKI mantıksal sınırı '
      'oluşturuyor (M-F-436: kusur iddiada değil KORUMASIZLIĞINDA)', () {
    /// Guard'tan `SyntheticPose.neutral`e (ÖLÇÜLDÜ: elde-sarkık bir kolun
    /// extensionRatio'su 1,0 — TAM UZANMIŞ bir yumrukla AYNI, çünkü
    /// extensionRatio yalnız DÜZLÜĞÜ ölçer, YÖNÜ ÖLÇMEZ) yükselen bir
    /// salınım, tek değişken YÜKSELİŞ SÜRESİ.
    List<PoseFrame> swing(int riseUs) => sequence(<SyntheticKeyframe>[
          SyntheticKeyframe(0, guardPose),
          SyntheticKeyframe(100000, guardPose),
          SyntheticKeyframe(100000 + riseUs, SyntheticPose.neutral),
          SyntheticKeyframe(100000 + riseUs + riseUs, guardPose),
          SyntheticKeyframe(100000 + riseUs + riseUs + 200000, guardPose),
        ]);

    test('✅ yavaş (500 ms) yürüyüş-temposu salınım DOĞRU reddediliyor '
        '(EXTENSION timeout 400 ms\'i aşıyor)', () {
      final result = drive(swing(500000));
      expect(result.digests, isEmpty,
          reason: '500 ms\'lik yavaş bir yükseliş EXTENSION\'ın 400 ms\'lik '
              'timeout\'unu aşmalı ve zaman-aşımıyla reddedilmeli — '
              'reddedilmediyse timeout mekanizması bu hız sınıfını '
              'KORUMUYOR demektir');
    });

    test(
        '⚠️ BİLİNEN AÇIK, ÖRTÜLMEDİ — tempolu (250 ms) kol sallama BUGÜN '
        'GERÇEK bir jab olarak SAYILIYOR (yön ayrımı YOK)', () {
      // Bu test BAŞARILI bir korumayı KANITLAMIYOR — TAM TERSİNE, bugünkü
      // motorun GERÇEK bir sınırını ADIYLA KAYIT ALTINA ALIYOR (M-F-436:
      // "kusur iddiada değil korumasızlığındadır" — burada iddia zaten
      // yok, motor hiçbir yerde "yön de ölçerim" demiyor, ama bu sınır da
      // hiçbir yerde YAZILI değildi; artık BURADA, ölçülü ve kalıcı).
      //
      // Kök sebep: `extensionRatio` yalnız |bilek-omuz| / (üstkol+önkol)
      // oranını ölçer — kolun İLERİ mi (yumruk) yoksa AŞAĞI/YANA mı
      // (yürürken sarkan/sallanan kol) uzandığını AYIRT ETMEZ. Tempolu bir
      // kol sallama (koşarken, telefonla konuşurken el kaldırma, vb.)
      // guard'tan (~0,15) sarkık-düz (~1,0) konuma 250 ms'de geçerse,
      // EXTENSION (400ms timeout) ve PEAK (150ms timeout) pencerelerinin
      // İKİSİNE de sığar ve `jab` olarak TAMAMLANIR.
      //
      // Bunu DÜZELTMEK bu turun kapsamı DIŞINDA bırakıldı, kaçırılmadı:
      // gerçek düzeltme (yön/vektör kısıtı ya da bir minimum "kameraya
      // doğru" bileşeni eklemek) StrikingEngine'in çekirdek eşleşme
      // mantığını değiştiren, `motion-cv-engineer` danışman gözden
      // geçirmesi hak eden bir tasarım kararı (CLAUDE.md) — bir fixture
      // dosyasında tek taraflı icat edilmez. Kayıt: DEFTER J-294 +
      // `docs/evidence/production-line/model-gate.json`.
      final result = drive(swing(250000));
      expect(result.digests, isNotEmpty,
          reason: 'BEKLENEN (bugünkü, İSTENMEYEN) davranış artık '
              'DEĞİŞTİYSE — yani kol sallama artık DOĞRU reddediliyorsa — '
              'bu SEVİNDİRİCİ bir kırmızı: yön-ayrımı düzeltmesi gelmiş '
              'demektir, bu testi ve yukarıdaki DEFTER/model-gate '
              'kayıtlarını GÜNCELLE (açık artık kapandı)');
      expect(result.digests.first.techniqueId, 'jab',
          reason: 'YALNIZCA hangi teknik olarak yanlış sınıflandığını '
              'belgelemek için — asıl bulgu digest\'in VAR OLMASI');
    });
  });

  group('RULESET VERSİYON BAĞLAMA (JAB-P0-003 Step 3) — var olan, '
      'ADANMIŞ bir testle korunuyor', () {
    test('her tamamlanan denemenin provenance\'ı ship edilen ruleset\'in '
        'rulesetId@version\'ını taşır', () {
      final List<PoseFrame> jab = sequence(<SyntheticKeyframe>[
        SyntheticKeyframe(0, guardPose),
        SyntheticKeyframe(200000, guardPose),
        SyntheticKeyframe(320000, extendedPose),
        SyntheticKeyframe(520000, guardPose),
        SyntheticKeyframe(750000, guardPose),
      ]);
      final result = drive(jab);
      expect(result.digests, isNotEmpty);
      expect(result.digests.first.provenance['ruleSetVersion'],
          '${rules.rulesetId}@${rules.version}',
          reason: 'StrikingEngine._buildDigest artık farklı bir alan '
              'yazıyor olabilir — bu binding zaten VARDI (engine_test.dart '
              'içinde TEK bir assertion\'a gömülüydü), burada KENDİ '
              'adanmış testi var ki gelecekte sessizce kırılmasın');
      // Adaylık DEĞİL — bilerek YAZILMAYAN alan: `calibratedForModel`.
      // boxing@1.0.0.json'ın kendi `$unreadFields` notu (provenance.
      // calibratedForModel) bunu J-048'den beri ADIYLA bekliyor: gerçek
      // kamera köprüsü (ADR-002) kurulmadan doldurulacak GERÇEK bir değer
      // yok — bu, unutulmuş bir görev DEĞİL, donanıma bağlı BEKLEYEN bir
      // karar. Burada `isNull` ile SESSİZCE doğrulanmıyor (bir null-check
      // "bekliyoruz" ile "unuttuk"u ayırt edemez) — yalnız adıyla, bu
      // yorumla kayıtlı.
    });
  });
}
