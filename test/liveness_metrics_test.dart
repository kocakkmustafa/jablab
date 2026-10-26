import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/thermal_channel.dart';

import '../integration_test/liveness_metrics.dart';

/// JAB-P0-002 — `integration_test/liveness_metrics.dart`in saf-Dart
/// mantığının birim testleri. Gerçek cihaz/kamera/kanal GEREKTİRMEZ:
/// `PeriodicSampler`e senkron sahte okuma fonksiyonları veriliyor,
/// `worstTier`/`percentileToJson`/`ThermalReading.fromChannelMap` saf
/// fonksiyonlar. Cihaz-günü koşumunun kendisi (gerçek FPS/termal
/// sinyali) EXTERNAL_GATE — burada sınanan yalnız HESAP mantığı.
void main() {
  group('PeriodicSampler — tick() doğrudan çağrılabilir (deterministik)', () {
    test('null-olmayan okumaları biriktirir', () async {
      final List<double?> queue = <double?>[1.0, 2.0, 3.0];
      final PeriodicSampler<double> s = PeriodicSampler<double>(
        interval: const Duration(seconds: 1),
        read: () async => queue.removeAt(0),
      );
      await s.tick();
      await s.tick();
      await s.tick();
      expect(s.samples, <double>[1.0, 2.0, 3.0]);
    });

    test('null okumaları ATLAR — biriktirilen listeye girmez', () async {
      final List<double?> queue = <double?>[1.0, null, 2.0, null];
      final PeriodicSampler<double> s = PeriodicSampler<double>(
        interval: const Duration(seconds: 1),
        read: () async => queue.removeAt(0),
      );
      for (int i = 0; i < 4; i++) {
        await s.tick();
      }
      expect(
        s.samples,
        <double>[1.0, 2.0],
        reason:
            'null okuma "0" ya da "ölçülmedi" olarak SESSİZCE '
            'birikmemeli — hiç birikmemeli',
      );
    });

    test('SABOTAJ — üst üste binen okuma GERÇEKTEN engellenir', () async {
      // Bir okuma yavaşken (Completer ile elle kontrol edilir) ikinci
      // tick() çağrısı YENİ bir okuma BAŞLATMAMALI — aksi hâlde termal
      // kanalın round-trip'i tick aralığından uzun sürdüğünde okumalar
      // sıraya dizilip birikirdi (dosyanın kendi gerekçesi).
      int startedReads = 0;
      final Completer<double?> firstRead = Completer<double?>();
      final PeriodicSampler<double> s = PeriodicSampler<double>(
        interval: const Duration(seconds: 1),
        read: () {
          startedReads++;
          return startedReads == 1
              ? firstRead.future
              : Future<double?>.value(9.0);
        },
      );
      final Future<void> firstTick = s.tick();
      // İlk okuma henüz BİTMEDİ (Completer tamamlanmadı) — bu sırada
      // ikinci bir tick() gelirse no-op olmalı.
      await s.tick();
      expect(
        startedReads,
        1,
        reason:
            'ikinci tick() ilk okuma sürerken YENİ bir okuma '
            'başlattı — üst-üste-binme koruması ÇALIŞMIYOR',
      );
      firstRead.complete(1.0);
      await firstTick;
      expect(s.samples, <double>[1.0]);

      // Koruma KALICI değil — ilk okuma bitince üçüncü tick() yeni bir
      // okuma başlatabilmeli (negatif ikiz: koruma sonsuza kadar
      // kilitlenmiş OLMAMALI).
      await s.tick();
      expect(
        startedReads,
        2,
        reason:
            'ilk okuma bittikten SONRA bile yeni okuma başlamıyor — '
            'koruma kalıcı kilide dönüşmüş',
      );
      expect(s.samples, <double>[1.0, 9.0]);
    });

    test(
      'start()/stop() GERÇEK bir Timer.periodic kurar ve iptal eder',
      () async {
        int reads = 0;
        final PeriodicSampler<double> s = PeriodicSampler<double>(
          interval: const Duration(milliseconds: 15),
          read: () async => (reads++).toDouble(),
        );
        s.start();
        await Future<void>.delayed(const Duration(milliseconds: 70));
        s.stop();
        final int countAtStop = s.samples.length;
        expect(
          countAtStop,
          greaterThanOrEqualTo(2),
          reason:
              'zamanlayıcı 70ms içinde en az birkaç kez ateşlemedi — '
              'start() gerçek bir Timer.periodic KURMUYOR olabilir',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          s.samples.length,
          countAtStop,
          reason:
              'stop() sonrası yeni örnek eklendi — zamanlayıcı '
              'GERÇEKTEN iptal edilmemiş',
        );
      },
    );
  });

  group('worstTier — en şiddetli kademe, sıraya bakmadan', () {
    test('boş liste → null (VAKUM, sessizce nominal SAYILMAZ)', () {
      expect(worstTier(const <ThermalReading>[]), isNull);
    });

    test('tek okuma → o okumanın kademesi', () {
      final ThermalReading r = ThermalReading(
        tier: ThermalTier.fair,
        platform: 'ios',
        raw: 'fair',
      );
      expect(worstTier(<ThermalReading>[r]), ThermalTier.fair);
    });

    test('karışık sıradaki en kötü kademeyi bulur (giriş sırasından '
        'BAĞIMSIZ)', () {
      ThermalReading mk(ThermalTier t) =>
          ThermalReading(tier: t, platform: 'ios', raw: t.name);
      expect(
        worstTier(<ThermalReading>[
          mk(ThermalTier.nominal),
          mk(ThermalTier.critical),
          mk(ThermalTier.fair),
        ]),
        ThermalTier.critical,
        reason: 'en kötü ORTADA gelse bile en kötü seçilmeli',
      );
      expect(
        worstTier(<ThermalReading>[
          mk(ThermalTier.serious),
          mk(ThermalTier.nominal),
        ]),
        ThermalTier.serious,
      );
    });
  });

  group('percentileToJson — Measured/Unmeasured ikisi de kapsanır', () {
    test('Measured → {measured: değer}', () {
      final PeriodicSampler<double> s = PeriodicSampler<double>(
        interval: const Duration(seconds: 1),
        read: () async => null,
      );
      s.samples.addAll(List<double>.generate(10, (int i) => i.toDouble()));
      final Map<String, dynamic> json = percentileToJson(
        s.percentile(0.5, minSources: 5),
      );
      expect(json['measured'], isNotNull);
      expect(
        json.containsKey('reason'),
        isFalse,
        reason: 'Measured sonucunda "reason" alanı bulunmamalı',
      );
    });

    test('Unmeasured → measured:null + reason/n/minSources TAŞINIR '
        '(sessizce 0/null\'a düşmez)', () {
      final PeriodicSampler<double> s = PeriodicSampler<double>(
        interval: const Duration(seconds: 1),
        read: () async => null,
      );
      s.samples.addAll(<double>[1.0, 2.0]); // 2 < minSources 5
      final Map<String, dynamic> json = percentileToJson(
        s.percentile(0.5, minSources: 5),
      );
      expect(json['measured'], isNull);
      expect(json['reason'], isA<String>());
      expect(json['n'], 2);
      expect(json['minSources'], 5);
    });
  });

  group('ThermalReading.fromChannelMap — iOS dört kademe + bilinmeyen', () {
    for (final String tier in <String>[
      'nominal',
      'fair',
      'serious',
      'critical',
    ]) {
      test('ios "$tier" → ThermalTier.$tier', () {
        final ThermalReading r = ThermalReading.fromChannelMap(
          <Object?, Object?>{'platform': 'ios', 'raw': tier},
        );
        expect(r.tier.name, tier);
        expect(r.measured, isTrue);
      });
    }

    test('ios bilinmeyen kademe adı → critical\'e yuvarlanır (İYİMSER '
        'TAHMİN YOK)', () {
      final ThermalReading r = ThermalReading.fromChannelMap(<Object?, Object?>{
        'platform': 'ios',
        'raw': 'somethingNewApple2027AddedX',
      });
      expect(r.tier, ThermalTier.critical);
    });
  });

  group('ThermalReading.fromChannelMap — Android yedi kademe → dörde '
      'İNDİRGENİR (dokümante eşleme)', () {
    final Map<int, ThermalTier> expected = <int, ThermalTier>{
      0: ThermalTier.nominal, // NONE
      1: ThermalTier.fair, // LIGHT
      2: ThermalTier.fair, // MODERATE
      3: ThermalTier.serious, // SEVERE
      4: ThermalTier.critical, // CRITICAL
      5: ThermalTier.critical, // EMERGENCY
      6: ThermalTier.critical, // SHUTDOWN
    };
    expected.forEach((int raw, ThermalTier tier) {
      test('android raw=$raw → ThermalTier.${tier.name}', () {
        final ThermalReading r = ThermalReading.fromChannelMap(
          <Object?, Object?>{'platform': 'android', 'raw': raw},
        );
        expect(r.tier, tier);
        expect(r.measured, isTrue);
        expect(r.raw, raw, reason: 'ham değer KAYBOLMAMALI');
      });
    });

    test('android raw=99 (öngörülemeyen üst değer) → critical (güvenlik '
        'tarafına yuvarlanır)', () {
      final ThermalReading r = ThermalReading.fromChannelMap(<Object?, Object?>{
        'platform': 'android',
        'raw': 99,
      });
      expect(r.tier, ThermalTier.critical);
    });

    test('android raw=null (API<29) → critical AMA measured=false — '
        'ikisi KARIŞTIRILMAZ', () {
      final ThermalReading r = ThermalReading.fromChannelMap(<Object?, Object?>{
        'platform': 'android',
        'raw': null,
      });
      expect(
        r.tier,
        ThermalTier.critical,
        reason: 'PASS/FAIL kararı için güvenli yön',
      );
      expect(
        r.measured,
        isFalse,
        reason:
            '"gerçekten critical ölçüldü" ile "ölçülemedi" farklı '
            'iddialar — measured bu ayrımı taşımalı',
      );
    });
  });

  test('fromChannelMap bilinmeyen platform adında PATLAR (sessizce '
      'yutmaz)', () {
    expect(
      () => ThermalReading.fromChannelMap(<Object?, Object?>{
        'platform': 'windows-phone',
        'raw': 0,
      }),
      throwsStateError,
    );
  });
}
