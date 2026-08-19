import 'package:flutter/services.dart';

/// Cihazın termal durumu — dört kademeli, aile-çapında ORTAK VOKABÜLER.
///
/// İsimlendirme iOS'un kendi `ProcessInfo.ThermalState`inden alındı
/// (icat edilmedi); Android'in yedi kademesi buna İNDİRGENİR — ham değer
/// atılmaz, bkz. [ThermalReading.raw].
enum ThermalTier { nominal, fair, serious, critical }

/// Bir termal okumanın tamamı — normalize edilmiş [tier] + ham platform
/// değeri. Ham değer saklanır: Android indirgemesi (bkz. [_androidTier])
/// yeniden ayarlanması gerekirse veri kaybı olmadan yapılabilsin.
final class ThermalReading {
  const ThermalReading({
    required this.tier,
    required this.platform,
    required this.raw,
  });

  final ThermalTier tier;

  /// 'ios' | 'android'.
  final String platform;

  /// ios: ham kademe adı (`String`). android: `PowerManager` ham kodu
  /// (`int`), ya da API<29'da `null`.
  final Object? raw;

  factory ThermalReading.fromChannelMap(Map<Object?, Object?> m) {
    final String platform = m['platform'] as String;
    final Object? raw = m['raw'];
    final ThermalTier tier = switch (platform) {
      'ios' => _iosTier(raw as String),
      'android' => _androidTier(raw as int?),
      _ => throw StateError('bilinmeyen termal kanal platformu: $platform'),
    };
    return ThermalReading(tier: tier, platform: platform, raw: raw);
  }

  static ThermalTier _iosTier(String raw) => switch (raw) {
        'nominal' => ThermalTier.nominal,
        'fair' => ThermalTier.fair,
        'serious' => ThermalTier.serious,
        'critical' => ThermalTier.critical,
        // Apple'ın gelecekte eklediği bilinmeyen bir kademe — İYİMSER
        // tahmin etmek yerine en katı tarafa yuvarla (H-31 sınıfı).
        _ => ThermalTier.critical,
      };

  /// Android `PowerManager.THERMAL_STATUS_*` (0-6, API 29+) yedi
  /// kademesini iOS'un dördüne indirger. Eşleme Android'in KENDİ eşik
  /// tanımlarına göre (icat değil):
  ///   NONE(0)              → nominal — throttling yok.
  ///   LIGHT(1)/MODERATE(2) → fair — kullanıcı etkisi başlar ama Android
  ///                          dokümantasyonunun "genel deneyim beklenenden
  ///                          kötü" eşiği (SEVERE) değil.
  ///   SEVERE(3)            → serious.
  ///   CRITICAL(4)/EMERGENCY(5)/SHUTDOWN(6) → critical — üçü de
  ///                          roadmap'in "critical" eşiğini aşar,
  ///                          kapatma dahil daha iyimser sayılamaz.
  ///   null (API<29)        → critical'a yuvarlanır ([measured] bunu
  ///                          "gerçekten critical ölçüldü" ile KARIŞTIRMAZ.
  static ThermalTier _androidTier(int? raw) {
    if (raw == null) return ThermalTier.critical;
    return switch (raw) {
      0 => ThermalTier.nominal,
      1 || 2 => ThermalTier.fair,
      3 => ThermalTier.serious,
      _ => ThermalTier.critical,
    };
  }

  /// API<29 Android'de gerçek okuma YOK — [tier] güvenlik tarafına
  /// (critical) yuvarlanmıştır; bu PASS/FAIL kararı için doğru yön ama
  /// "gerçekten critical ölçüldü" değildir. Çağıran taraf bu ayrımı
  /// [measured] ile yapar (H-68: yokluk sessizce en kötü/en iyi sayılmaz,
  /// adıyla taşınır).
  bool get measured => !(platform == 'android' && raw == null);
}

/// Termal durumu OKUYAN köprü — `com.yulalab.jablab/thermal` (app-özel,
/// `motion_core`/`motion_camera` PİNLİ paketlerinden BAĞIMSIZ: kamera
/// zarfı ham piksel taşımıyor, bkz. `docs/evidence/production-line/
/// baseline.json` blur-bucket bulgusu — termal onun aksine kameradan
/// TAMAMEN bağımsız bir OS sorgusu, bu yüzden app katmanında çözülebildi).
/// Yalnız OKUR — hiçbir şeyi değiştirmez, izin istemez.
final class ThermalChannel {
  const ThermalChannel();

  static const MethodChannel _channel =
      MethodChannel('com.yulalab.jablab/thermal');

  /// Bir okuma döndürür, ya da kanal yoksa/desteklenmiyorsa `null`
  /// (web/masaüstü/koşulmayan platform — beklenen, hata değil).
  Future<ThermalReading?> read() async {
    try {
      final Object? raw =
          await _channel.invokeMethod<Object?>('getThermalState');
      if (raw is! Map) return null;
      return ThermalReading.fromChannelMap(raw.cast<Object?, Object?>());
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
