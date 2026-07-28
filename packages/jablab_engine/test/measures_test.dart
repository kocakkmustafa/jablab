import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('MeasureSet', () {
    test('ölçüler kamera mesafesinden bağımsız — aynı poz, iki ölçek', () {
      // Bu, ölçülerin "aynı-kare oranı" olarak tasarlanmasının tek testi:
      // vücut yarıya inse bile HİÇBİR ölçü değişmemeli. Değişirse, bir yerde
      // mutlak piksele bölünmüşüz demektir.
      final PoseFrame big = builder().build(guardPose, tUs: 0);
      final PoseFrame small = scaleFrame(big, 0.5);

      final MeasureSet a =
          const MeasureCalculator().compute(big, Stance.orthodox);
      final MeasureSet b =
          const MeasureCalculator().compute(small, Stance.orthodox);

      for (final String key in a.all.keys) {
        expect(b.all[key], closeTo(a.all[key]!, 1e-6),
            reason: '$key ölçekle değişti — mutlak piksele bağımlılık var');
      }
    });

    test('uzanma oranı: gard düşük, tam uzanmada ~1.0', () {
      final MeasureSet guard = const MeasureCalculator()
          .compute(builder().build(guardPose, tUs: 0), Stance.orthodox);
      final MeasureSet ext = const MeasureCalculator()
          .compute(builder().build(extendedPose, tUs: 0), Stance.orthodox);

      final double eGuard = guard.read('extensionRatio', limb: Side.lead)!;
      final double eExt = ext.read('extensionRatio', limb: Side.lead)!;

      expect(eGuard, lessThan(0.62),
          reason: 'gard, config PHASE_THR eşiğinin altında olmalı');
      expect(eExt, greaterThan(0.85),
          reason: 'tam uzanma, config EXT_PEAK_MIN eşiğini geçmeli');
      expect(eExt, lessThanOrEqualTo(1.001),
          reason: 'düz kolda e>1 geometrik olarak imkânsız (J-013)');
    });

    test('uzanma oranı vücut tipinden bağımsız', () {
      // Uzun-ince ve kısa-geniş aynı açılarda aynı oranı vermeli; yoksa
      // eşikler vücut tipine göre kayar ve kural seti tek beden olur.
      final double tall = const MeasureCalculator()
          .compute(
              const SyntheticPoseBuilder(body: SyntheticBody.tallSlim)
                  .build(extendedPose, tUs: 0),
              Stance.orthodox)
          .read('extensionRatio', limb: Side.lead)!;
      final double broad = const MeasureCalculator()
          .compute(
              const SyntheticPoseBuilder(body: SyntheticBody.shortBroad)
                  .build(extendedPose, tUs: 0),
              Stance.orthodox)
          .read('extensionRatio', limb: Side.lead)!;

      expect(broad, closeTo(tall, 0.02));
    });

    test('gövde eğimi dikeyden sapmayı derece olarak verir', () {
      final MeasureSet upright = const MeasureCalculator()
          .compute(builder().build(guardPose, tUs: 0), Stance.orthodox);
      final MeasureSet leaning = const MeasureCalculator().compute(
          builder().build(guardPose.copyWith(trunkAngle: -1.30), tUs: 0),
          Stance.orthodox);

      expect(upright.read('trunkLeanAngle')!, lessThan(6));
      expect(leaning.read('trunkLeanAngle')!, greaterThan(10));
    });

    test('delta yalnız önceki kare verildiğinde üretilir', () {
      final MeasureCalculator c = const MeasureCalculator();
      final MeasureSet first =
          c.compute(builder().build(guardPose, tUs: 0), Stance.orthodox);
      expect(first.read('lead.extensionRatioDelta'), isNull);

      final MeasureSet second = c.compute(
          builder().build(extendedPose, tUs: 33000), Stance.orthodox,
          previous: first);
      expect(second.read('lead.extensionRatioDelta'), greaterThan(0),
          reason: 'gard→uzanma geçişinde delta pozitif olmalı');
    });
  });
}
