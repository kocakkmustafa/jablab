import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final RuleSet rules = loadBoxingRuleSet();

  group('boxing@1.0.0 config', () {
    test('ship edilen dosya yüklenir ve beklenen yapıyı taşır', () {
      expect(rules.rulesetId, 'boxing');
      expect(rules.techniques.map((TechniqueConfig t) => t.id),
          containsAll(<String>['jab', 'cross']));
      expect(rules.errors.length, greaterThanOrEqualTo(10),
          reason: 'V1 kriteri: ≥10 güvenilir hata (bant A+B)');
      // Motorun boks bilmediğinin kanıtı: teknik/hata/kombinasyon adlarının
      // hiçbiri kodda sabit değil, hepsi buradan geliyor.
      expect(rules.combinations.map((CombinationConfig c) => c.id),
          contains('1-2'));
    });

    test('K8 (M-F-04): kalibrasyonsuz sayısal skor KİLİTLİ', () {
      expect(rules.numericScoresUnlocked, isFalse);
      expect(rules.publishBlockers(), isNotEmpty,
          reason: 'eşikler kalibre edilmeden A bandı yayınlanamaz');
      expect(rules.thresholdStatus, 'raw-signal-pending-revision');
    });

    test('ADR-001: tempo SAYI değil BANT — sınırlar D2 havuzundan', () {
      expect(rules.tempoBandFor(60), 'fast');
      expect(rules.tempoBandFor(120), 'brisk');
      expect(rules.tempoBandFor(220), 'controlled');
      expect(rules.tempoBandFor(94.999), 'fast');
      expect(rules.tempoBandFor(95), 'brisk');
      expect(rules.tempoBandFor(159.999), 'brisk');
      expect(rules.tempoBandFor(160), 'controlled');
    });
  });

  group('StrikingEngine', () {
    StrikingEngine engine() => StrikingEngine(
          ruleSet: rules,
          calibrationMapped: true,
          provenance: const <String, String>{
            'poseModelVariant': 'synthetic',
            'calibrationProfileId': 'test',
            'tempoTimingRevision': 'caller-must-not-override',
            'tempoWindow': 'first-transition->PEAK',
          },
        );

    test('sentetik yumruk tam faz döngüsünü tamamlar ve tempo bandı üretir', () {
      final List<PoseFrame> frames = sequence(<SyntheticKeyframe>[
        SyntheticKeyframe(0, guardPose),
        SyntheticKeyframe(200000, guardPose),
        SyntheticKeyframe(320000, extendedPose), // ~120 ms uzanma
        SyntheticKeyframe(520000, guardPose),
        SyntheticKeyframe(750000, guardPose),
      ]);

      final StrikingEngine e = engine();
      AttemptDigest? digest;
      for (final PoseFrame f in frames) {
        digest ??= e.process(f).completedAttempt;
      }

      expect(digest, isNotNull, reason: 'yumruk hiç tamamlanmadı');
      expect(digest!.outcome, AttemptOutcome.completed);
      // J-026: yedek teknik değil, SPESİFİK teknik raporlanmalı.
      expect(digest.techniqueId, isNot('unclassified_strike'),
          reason: 'yedek teknik spesifik tekniği gölgeledi — yumruk iki kez '
              'sayılıyor demektir');
      expect(digest.transitions.keys, contains('PEAK'));
      expect(digest.extensionMs, isNotNull);
      expect(digest.tempoBand, isNotNull);
      // ADR-001: hız faz süresinden türetildi, kare-arası pikselden değil.
      expect(digest.extensionMs, greaterThan(0));
      final double namedMs =
          (digest.transitions['PEAK']! - digest.transitions['EXTENSION']!) /
              1000.0;
      expect(digest.extensionToPeakMs, namedMs);
      expect(digest.tempoBand, rules.tempoBandFor(namedMs));
      expect(digest.extensionMs, greaterThan(namedMs));
      expect(digest.provenance['tempoTimingRevision'], 'extension-to-peak@1');
      expect(digest.provenance['tempoWindow'], 'EXTENSION->PEAK');
      expect(digest.provenance['poseModelVariant'], 'synthetic');
      expect(digest.provenance['calibrationProfileId'], 'test');
      expect(digest.provenance['eventLogicRevision'], rules.eventLogicRevision);
      // M-F-07 provenance zorunlu.
      expect(digest.provenance['ruleSetVersion'], 'boxing@1.0.0');
      expect(digest.provenance['thresholdStatus'],
          'raw-signal-pending-revision');
    });

    // Aynı FPS içinde hareket suffix'i ve örnekleme fazı sabittir.
    // 1 sn ortak gard warm-up'ına yalnız ek bekleme kareleri eklenir.
    for (final int fps in <int>[30, 60]) {
      test('MS-1: ${fps}fps gard beklemesi tempo aralığını değiştirmez', () {
        final SyntheticSequence motion = SyntheticSequence(
          <SyntheticKeyframe>[
            SyntheticKeyframe(0, guardPose),
            SyntheticKeyframe(180000, extendedPose),
            SyntheticKeyframe(200000, extendedPose),
            SyntheticKeyframe(380000, guardPose),
            SyntheticKeyframe(600000, guardPose),
          ],
        );
        double? baselineNamedMs;
        double? baselineLegacyMs;
        String? baselineBand;
        for (final int dwellMs in <int>[0, 100, 300, 1100]) {
          final StrikingEngine e = StrikingEngine(
            ruleSet: rules,
            calibrationMapped: true,
            allowedTechniqueIds: <String>{'jab'},
          );
          final int guardFrames = fps + dwellMs * fps ~/ 1000;
          final int movementFrames = (600000 * fps / 1000000).round();
          final List<AttemptDigest> completed = <AttemptDigest>[];
          for (int i = 0; i <= guardFrames + movementFrames; i++) {
            final int tUs = (i * 1000000 / fps).round();
            final int localUs = ((i - guardFrames) * 1000000 / fps).round();
            final SyntheticPose pose = i < guardFrames
                ? guardPose
                : motion.poseAt(localUs);
            final AttemptDigest? d =
                e.process(builder().build(pose, tUs: tUs)).completedAttempt;
            if (d != null) completed.add(d);
          }
          expect(completed, hasLength(1), reason: 'dwellMs=$dwellMs');
          final AttemptDigest d = completed.single;
          expect(d.techniqueId, 'jab');
          expect(d.outcome, AttemptOutcome.completed);
          expect(d.transitions.keys.toList(), <String>[
            'GUARD_READY', 'EXTENSION', 'PEAK',
            'RETRACTION', 'GUARD_RECOVERED',
          ]);
          final double namedMs =
              (d.transitions['PEAK']! - d.transitions['EXTENSION']!) / 1000.0;
          expect(d.extensionToPeakMs, namedMs);
          expect(d.tempoBand, rules.tempoBandFor(namedMs));
          expect(d.extensionMs, greaterThan(namedMs));
          if (dwellMs == 0) {
            baselineNamedMs = namedMs;
            baselineLegacyMs = d.extensionMs!;
            baselineBand = d.tempoBand!;
          } else {
            expect(namedMs, baselineNamedMs);
            expect(d.tempoBand, baselineBand);
            expect(d.extensionMs! - baselineLegacyMs!, closeTo(dwellMs, .002));
          }
        }
      });
    }

    test('J-009 REGRESYON: kolunu uzatıp BEKLEMEK yumruk sayılmaz', () {
      // D2 ölçümünde detektör, torbaya yaslanıp kolu uzatan boksörü
      // "736 ms'lik yumruk" okumuştu. Faz timeout'u olmadan üretim motoru
      // canlı seansta aynı hatayı yapardı.
      final List<PoseFrame> frames = sequence(<SyntheticKeyframe>[
        SyntheticKeyframe(0, guardPose),
        SyntheticKeyframe(200000, guardPose),
        SyntheticKeyframe(320000, extendedPose),
        SyntheticKeyframe(2000000, extendedPose), // 1,7 sn uzanmış BEKLEME
      ]);

      final StrikingEngine e = engine();
      final List<AttemptDigest> completed = <AttemptDigest>[];
      for (final PoseFrame f in frames) {
        final AttemptDigest? d = e.process(f).completedAttempt;
        if (d != null) completed.add(d);
      }

      expect(completed, isEmpty,
          reason: 'uzatıp bekleme TAMAMLANMIŞ yumruk olarak sayıldı — '
              'faz timeout çalışmıyor (J-009)');
    });

    test('J-013 REGRESYON: anatomik imkânsızlıkta HÜKÜM YOK', () {
      // Düz kolda uzanma oranı 1'i geçemez. Geçiyorsa model uzuv etiketi
      // takas etmiş olabilir (M-019) — güven yüksek kalsa bile hüküm verilmez.
      final StrikingEngine e = engine();
      e.process(builder().build(guardPose, tUs: 0));

      final PoseFrame impossible = moveLandmark(
        builder().build(extendedPose, tUs: 33000),
        Lm.leftWrist,
        0.9, // bileği kol boyunun ötesine taşı
        0,
      );
      final EngineOutput out = e.process(impossible);

      expect(out.judgeable, isFalse);
      expect(out.suppressionReason, isNotNull);
      expect(out.completedAttempt, isNull);
    });

    test('hüküm verilemeyen karede teknik hata kodu ÜRETİLMEZ', () {
      // plan §12: "Sağ bileğin bu açıdan güvenilir görünmüyor" denir,
      // "yanlış yaptın" DENMEZ.
      final StrikingEngine e = engine();
      final PoseFrame blind = PoseFrame(
        tUs: 0,
        landmarks: List<PoseLandmark>.generate(
            Lm.count, (int _) => const PoseLandmark.invisible(),
            growable: false),
        modelVersion: 'synthetic-v1',
      );
      final EngineOutput out = e.process(blind);

      expect(out.judgeable, isFalse);
      for (final DetectedIssue i in out.issues) {
        expect(i.band, 'A');
        expect(i.severity, 'blocking',
            reason: 'hüküm verilemezken yalnız bloklayıcı kod çıkabilir, '
                'teknik hata kodu çıkamaz');
      }
    });

    test('taraf etiketi kalibrasyon eşlemesi olmadan raporlanamaz (M-F-06)', () {
      final StrikingEngine noCal = StrikingEngine(ruleSet: rules);
      final EngineOutput out =
          noCal.process(builder().build(guardPose, tUs: 0));
      expect(out.stance.sideLabelsReportable, isFalse,
          reason: 'kalibrasyon eşlemesi yokken "sol/sağ" denemez');

      final EngineOutput calibrated =
          engine().process(builder().build(guardPose, tUs: 0));
      expect(calibrated.stance.sideLabelsReportable, isTrue);
    });
  });

  group('CueGate — koç konuşurken hüküm kapısı', () {
    test('cue sırasında YUMRUK SAYILIR ama HÜKÜM VERİLMEZ', () {
      // JabLab semantiği Ostinato'dan farklı: kamera kirlenmez, ama kullanıcı
      // bir önceki düzeltmeye tepki veriyordur. Tespit sürer, hüküm susar.
      final List<PoseFrame> frames = sequence(<SyntheticKeyframe>[
        SyntheticKeyframe(0, guardPose),
        SyntheticKeyframe(200000, guardPose),
        SyntheticKeyframe(320000, extendedPose),
        SyntheticKeyframe(520000, guardPose),
        SyntheticKeyframe(750000, guardPose),
      ]);

      final StrikingEngine e = StrikingEngine(
        ruleSet: rules,
        calibrationMapped: true,
        cueGate: CueGate(),
      );
      e.cueStarted(0); // koç tüm seans boyunca konuşuyor

      AttemptDigest? digest;
      final List<DetectedIssue> allIssues = <DetectedIssue>[];
      for (final PoseFrame f in frames) {
        final EngineOutput o = e.process(f);
        digest ??= o.completedAttempt;
        allIssues.addAll(o.issues);
      }

      expect(digest, isNotNull,
          reason: 'cue sırasında yumruk SAYILMAYI sürdürmeli — '
              'susan şey hüküm, tespit değil');
      expect(allIssues, isEmpty,
          reason: 'koç konuşurken yeni hata kodu üretilmemeli');
    });

    test('cue bittikten sonra ring-out süresince de hüküm yok', () {
      final StrikingEngine e = StrikingEngine(ruleSet: rules);
      e.cueStarted(0);
      e.cueEnded(100000);
      // Varsayılan ringOut 300 ms: 200 ms'de hâlâ kapalı, 500 ms'de açık.
      expect(e.cueGate.isAnalysisClean(200000), isFalse);
      expect(e.cueGate.isAnalysisClean(500000), isTrue);
    });
  });
}
