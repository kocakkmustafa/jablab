import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/src/google_fonts_base.dart' show pendingFontFutures;
import 'package:jablab/app/design_tokens.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// TÜM test dosyaları için TEK giriş — Flutter bunu otomatik bulup sarar
/// (`test/` altında `flutter_test_config.dart` adı özel; HER test DOSYASI
/// için AYRI çalışır, yani aşağıdaki ön-ısınma her dosyada bir kez tekrar
/// eder).
///
/// ## Neden burada bir ön-ısınma var
///
/// `google_fonts` (`JText`, design_tokens.dart) her `GoogleFonts.x(...)`
/// çağrısında özel font YÜZÜNÜ (glyph) arka planda ağdan indirip diske
/// kaydediyor — dönen `TextStyle` SENKRON üretiliyor, yükleme bitene kadar
/// sistem varsayılan fontuna DÜŞEREK; yani indirme başarısız olsa BİLE
/// `find.text(...)`/`find.byKey(...)`/taşma denetimleri ETKİLENMİYOR.
///
/// **ÖLÇÜLDÜ (design turu Parça 2, 2026-08-06) — DÖRT aşamalı teşhis,
/// sırayla giderildi:**
/// 1. `flutter test` `TestWidgetsFlutterBinding` aktifken kurulan HER
///    `HttpClient`i 400'e ZORLUYOR (Flutter'ın kasıtlı test-izolasyonu).
///    `google_fonts`un arka plan indirmesi bu yüzden `fitness_ship_audit_
///    test.dart`ta patladı (bu dosya ilk kez `SessionScreen`i CANLI
///    aşamaya kadar pompalıyor; `jablabSessionTheme`in ihtiyaç duyduğu
///    `ibmPlexMono` w500 bu makinede hiç istenmemişti).
/// 2. Ham `dart:io HttpClient`, binding henüz YOKKEN, AYNI URL'de 200
///    dönüyor — genel ağ erişimi sorun değil, kusur binding'in kurduğu
///    `HttpOverrides.global`de.
/// 3. Binding aktifleşmeden ÖNCE ön-ısınmak da OLMUYOR: `google_fonts`
///    önce YEREL asset'i kontrol ediyor ve bu `ServicesBinding.instance`
///    istiyor.
/// 4. Binding kurup `HttpOverrides.global`ı geçici açınca indirme
///    BAŞARILI oluyor ama bu kez `google_fonts`un indirdiğini DİSKE
///    yazma adımı `path_provider`in platform kanalını (`getApplication
///    SupportDirectory`) çağırıyor — `flutter test`in saf Dart-VM ortamında
///    gerçek bir platform kanalı YOK, `MissingPluginException` atıyor.
///
/// **Çözüm — DÖRDÜ BİRDEN:** binding kur (3) → `HttpOverrides.global`ı
/// geçici `null`a al (1-2) → `PathProviderPlatform.instance`ı GERÇEK bir
/// dizine (bu koşunun kendi geçici klasörü) yazan sahte bir uygulamayla
/// değiştir (4) → `JText`in TÜM alanlarını bir kez okuyup yüklemeyi
/// TETİKLE, tamamlanmalarını bekle, İKİSİNİ de GERİ TAK. Böylece asıl
/// testler çalışmaya başladığında ihtiyaç duyulan her ağırlık zaten
/// `google_fonts`un kendi bellek-içi önbelleğinde (`_loadedFonts`) — YENİ
/// bir indirme denemesi hiç tetiklenmiyor.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final HttpOverrides? previousHttpOverrides = HttpOverrides.current;
  final PathProviderPlatform previousPathProvider =
      PathProviderPlatform.instance;
  final Directory fontCacheDir =
      Directory.systemTemp.createTempSync('jablab_test_fonts_');

  HttpOverrides.global = null;
  PathProviderPlatform.instance = _TempPathProvider(fontCacheDir.path);
  try {
    JText.correction;
    JText.clock;
    JText.pageTitle;
    JText.body;
    JText.bodyMuted;
    JText.label;
    JText.mono;
    // `TextStyle` SENKRON döner, yükleme arka planda başlar — sabit bir
    // bekleme yerine paketin KENDİ takip ettiği `pendingFontFutures`i
    // bekliyoruz: her dosya yalnız GERÇEKTEN gerektiği kadar bekliyor
    // (genelde <1sn), sabit bir sayı ne fazla yavaşlatıyor ne de yavaş bir
    // bağlantıda yetersiz kalıyor.
    await Future.wait(pendingFontFutures.toList());
  } finally {
    HttpOverrides.global = previousHttpOverrides;
    PathProviderPlatform.instance = previousPathProvider;
  }
  await testMain();
  try {
    fontCacheDir.deleteSync(recursive: true);
  } on Object {
    // Temizlik başarısız olsa bile TESTLERİN sonucu etkilenmez — geçici
    // klasör zaten sistemin kendi temp dizininde, işletim sistemi süpürür.
  }
}

/// `google_fonts`un indirdiği font baytlarını diske yazabilmesi için — GERÇEK
/// bir platform kanalı yerine bu koşunun kendi geçici klasörünü döndürüyor.
/// `path_provider`in kendi paket testinin izlediği desenin AYNISI
/// (`FakePathProviderPlatform`, `google_fonts` paket kaynağı).
class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this._path) : super();

  final String _path;

  @override
  Future<String?> getApplicationSupportPath() async => _path;

  @override
  Future<String?> getTemporaryPath() async => _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}
