/// CANLI SEANS KURULUM HATALARININ TİPLİ MODELİ (J-096).
///
/// `ContentFailure` (J-079) emsalinin kamera karşılığı. Aynı gerekçe:
/// ekranın davranışı hata SINIFINA göre değişmek zorunda ve bunu hata
/// METNİNDEN çıkarmak sessiz-kırılma sınıfıdır — metin bir gün değişir,
/// sınıflandırma sessizce yanlışa döner, hiçbir test görmez.
///
/// ## ⚠️ BURADA OLMAYAN HÂL: "kişi görünmüyor"
///
/// Koordinatör paketinde üç dürüst hâl birlikte anıldı (izin-reddi /
/// kamera-açılamadı / kişi-yok) ama **üçüncüsü bir HATA DEĞİL** ve buraya
/// koymak onu yanlış katmana yerleştirirdi:
///
/// * izin-reddi ve kamera-açılamadı **KURULUM** hâlleridir: seans hiç
///   başlamaz, ekran bir kez konuşur, kullanıcının yapacağı bir şey vardır
///   (ya da yoktur ve bu söylenir).
/// * "kişi görünmüyor" **CANLI** bir hâldir: seans KOŞUYOR, kamera akıyor,
///   model çalışıyor — yalnız o anda hüküm verilemiyor. Kare kare değişir ve
///   kendi kendine düzelir.
///
/// İkisini tek tipe yıkmak, geçici bir kadraj sorununu kurulum hatası gibi
/// göstermek olurdu: kullanıcı seansı yeniden başlatmaya çalışırdı. Canlı hâl
/// motorun kendi çıktısında yaşıyor (`EngineOutput.judgeable` +
/// `suppressionReason`) ve yüzeyde `LiveState.noVerdict`e çevriliyor —
/// kabuğun zaten "göremiyorum ayrı bir durumdur" diye kurduğu yuva.
library;

import 'package:motion_camera/motion_camera.dart' show CameraFailure;

/// Canlı seans BAŞLATILAMADI. Bloklayıcı — ama YALNIZ kamera dersini.
///
/// Fitness turları (saat + ses) kamerasız TAM çalışıyor ve kanıtlı
/// (`docs/gates/FITNESS-SHIP-KANITI.txt`), o yüzden bu hâl uygulamayı
/// kilitlemez. "Yine de devam et" düğmesi de YOK: kamera dersinin vaadi
/// analizdir, analizsiz aynı dersi sunmak vaadi boşaltmak olur.
sealed class LiveSessionFailure {
  const LiveSessionFailure();

  /// Geliştirici ayrıntısı — kullanıcıya BİRİNCİL metin olarak gösterilmez
  /// ve yüzeye ham hâlde SIZMAZ (doc-75/5 ile aynı kural, kamera tarafı).
  String get detail;
}

/// Kamera izni verilmedi.
///
/// **İzni APP ister, plugin istemez** (sözleşme §1 katman sınırı): plugin
/// `camera-permission-denied` diye isimli bir retle döner ve UX'i app'e
/// bırakır. Bu ayrım emülatör smoke'unda ölçüldü — izin adımı yokken köprü
/// tam o retle düştü.
final class LivePermissionDenied extends LiveSessionFailure {
  const LivePermissionDenied({required this.permanentlyDenied});

  /// Kullanıcı "bir daha sorma" dediyse (ya da politika engelliyorsa) true.
  ///
  /// Ayrı tutulmasının sebebi SUNULAN EYLEM: geçici rette tekrar sormak
  /// çalışır, kalıcı rette çalışmaz ve "tekrar dene" düğmesi kullanıcıyı
  /// hiçbir yere götürmez — çalışmayan bir düğme, düğme olmamasından
  /// kötüdür (J-079 dersi). Kalıcı retde ayarlara yönlendirilir.
  final bool permanentlyDenied;

  @override
  String get detail => 'camera permission denied '
      '(permanentlyDenied: $permanentlyDenied)';
}

/// Kamera oturumu açılamadı — izin DIŞI bir sebeple.
///
/// [failure] plugin'in isimli reddi (model yüklenemedi, o mercekte kamera
/// yok, zaten çalışan oturum var…). Kod sınıfı taşıdığı için ekran doğru
/// cümleyi kurabiliyor; metinden çıkarmaya çalışsaydık plugin bir gün
/// mesajını değiştirdiğinde sessizce yanlış cümleye düşerdik.
final class LiveCameraUnavailable extends LiveSessionFailure {
  const LiveCameraUnavailable({required this.failure, this.nativeDetail});

  final CameraFailure failure;
  final String? nativeDetail;

  @override
  String get detail =>
      'camera unavailable: ${failure.code}'
      '${nativeDetail == null ? '' : ' — $nativeDetail'}';
}

/// Beklenmeyen bir kurulum hatası (model dosyası çıkarılamadı, I/O…).
///
/// Bilinmeyen bir hata BURAYA düşer, [LiveCameraUnavailable]'a değil:
/// tanımadığımız bir hatayı isimli bir plugin reddi gibi sunmak, kullanıcıya
/// bizim adımıza teşhis koymak olurdu (`ContentFailure.from`un aynı tercihi).
final class LiveSetupFailed extends LiveSessionFailure {
  const LiveSetupFailed(this.error);

  final Object error;

  @override
  String get detail => error.toString();
}
