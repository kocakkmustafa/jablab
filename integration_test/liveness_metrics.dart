/// JAB-P0-002 — cihaz-günü canlılık probunun p10/p50/p95 FPS ve termal
/// zaman-serisi yardımcıları. `test/` altındaki saf-Dart birim testinden
/// de import edilebilsin diye `integration_test/`ten AYRI, `flutter_test`e
/// bağımlı DEĞİL (yalnız `dart:async` + `jablab_engine`).
///
/// Yüzdelik hesaplarken `reliablePercentile` (`packages/jablab_engine`,
/// J-283) İCAT EDİLMEDİ — küçük-örneklem koruması burada da geçerli: kısa
/// bir dev-check koşumundan (örn. 10 sn) p95 basmak, F4'ün "3 kaynaktan
/// p90" hatasının FPS karşılığı olurdu (H-62).
library;

import 'dart:async';

import 'package:jablab/app/thermal_channel.dart';
import 'package:jablab_engine/jablab_engine.dart'
    show Measured, PercentileResult, Unmeasured, reliablePercentile;

/// [interval] aralığıyla [read]i çağırıp `null`-olmayan sonuçları biriktiren
/// yardımcı. Tek tip: FPS (senkron `double?` okuma, `async` sarmalanır) ve
/// termal (gerçekten `async`, platform-kanalı gidiş-dönüşü) AYNI mekanizmayı
/// kullanır — ikinci bir sınıf icat edilmedi.
final class PeriodicSampler<T> {
  PeriodicSampler({required this.interval, required this.read});

  final Duration interval;
  final Future<T?> Function() read;
  final List<T> samples = <T>[];
  Timer? _timer;
  bool _reading = false;

  void start() {
    _timer = Timer.periodic(interval, (_) {
      unawaited(tick());
    });
  }

  /// Bir okuma denemesi — `Timer.periodic` tarafından çağrılır, ama testler
  /// de GERÇEK zamanlayıcıyı beklemeden DOĞRUDAN çağırabilir (deterministik,
  /// hızlı — bir zamanlayıcının GERÇEKTEN kurulduğunu sınamak ayrı, küçük
  /// bir teste bırakılır).
  Future<void> tick() async {
    // Önceki okuma bitmeden ikincisini BAŞLATMA — termal kanalın
    // gidiş-dönüşü tick aralığından uzun sürerse okumalar birikip
    // sırayla patlardı; en son değeri kaçırmak, çakışan okumalardan
    // daha güvenli.
    if (_reading) return;
    _reading = true;
    try {
      final T? v = await read();
      if (v != null) samples.add(v);
    } finally {
      _reading = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// FPS örnekleyicisine yalnız `double` için anlamlı olan yüzdelik hesabını
/// ekler — `PeriodicSampler<T>` genel kalır (termal için de kullanılıyor,
/// `ThermalReading` için "yüzdelik" bir kavram DEĞİL), tip-özel davranış
/// extension ile ayrıştırılır, sınıf içine gömülmez.
extension PeriodicSamplerFpsX on PeriodicSampler<double> {
  /// [p] yüzdeliği ([0,1]) — `reliablePercentile`in aynı küçük-örneklem
  /// korumasıyla ([minSources]'tan az örnek varsa [Unmeasured]).
  PercentileResult percentile(double p, {int minSources = 5}) =>
      reliablePercentile(
        samples,
        p,
        contributingSources: samples.length,
        minSources: minSources,
      );
}

/// [readings] içindeki en KÖTÜ (en yüksek şiddetli) termal kademe, ya da
/// hiç okuma yoksa `null`. `ThermalTier` enum sırası şiddet sırasıdır
/// (nominal < fair < serious < critical) — `.index` karşılaştırması bu
/// yüzden geçerli.
ThermalTier? worstTier(List<ThermalReading> readings) {
  if (readings.isEmpty) return null;
  return readings
      .map((ThermalReading r) => r.tier)
      .reduce((ThermalTier a, ThermalTier b) => a.index > b.index ? a : b);
}

/// [PercentileResult]i artefakt JSON'ına yazılabilir bir haritaya çevirir.
/// `measured:null` + `reason` sözleşmesi bu deponun "bilmiyorum ≠ sıfır"
/// ilkesiyle tutarlı (K8/doc-75 ailesi) — `Unmeasured`i sessizce `0`/`null`a
/// düşürmek, "ölçmedim" ile "ölçtüm, sıfır çıktı"yı aynı sayı gibi gösterirdi.
Map<String, dynamic> percentileToJson(PercentileResult r) => switch (r) {
  Measured m => <String, dynamic>{'measured': m.value},
  Unmeasured u => <String, dynamic>{
    'measured': null,
    'reason': u.reason,
    'n': u.n,
    'minSources': u.minSources,
  },
};

/// Records both cleanup attempts; a failed cancel must not skip camera stop.
/// Method completion is not an owned-capture idle readback attestation.
final class ProbeCleanupResult {
  const ProbeCleanupResult({this.cancelError, this.stopError});

  final String? cancelError;
  final String? stopError;
  bool get succeeded => cancelError == null && stopError == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'methodCallsSucceeded': succeeded,
    'cancelError': cancelError,
    'stopError': stopError,
    'nativeIdleReadbackVerified': false,
  };
}

Future<ProbeCleanupResult> cleanupProbeCapture({
  required Future<void> Function() cancelFrames,
  required Future<void> Function() stopCamera,
}) async {
  String? cancelError;
  String? stopError;
  try {
    await cancelFrames();
  } on Object catch (error) {
    cancelError = error.toString();
  }
  try {
    await stopCamera();
  } on Object catch (error) {
    stopError = error.toString();
  }
  return ProbeCleanupResult(cancelError: cancelError, stopError: stopError);
}
