import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader, ByteData;
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;

/// TÜM test dosyaları için TEK giriş (Flutter bunu otomatik bulup sarar).
///
/// ## Neden var — D1 sonrası (F2, 2026-08-16)
///
/// D1 `google_fonts`u kaldırdı (fonts.gstatic.com'dan çalışma-anında
/// çekme, J-264/J-217) ve `.ttf`leri `pubspec.yaml`'ın `fonts:` bildirimiyle
/// PAKETLEDİ. Ama `flutter test` bildirilen fontları OTOMATİK yüklemez —
/// widget testleri varsayılan bir yer-tutucu fontla ölçer, gerçek glyph
/// genişlikleriyle DEĞİL. Ölçüldü: bu dosya silinip yerine hiçbir şey
/// konmadan koşulunca `narrow_viewport_overflow_test.dart` YENİ bir taşma
/// buldu — gerçek fontun ürettiği satır sarması, yer-tutucunkinden farklı.
///
/// Eski sürüm (`google_fonts` ön-ısınması) çok daha karmaşıktı çünkü
/// ASENKRON bir ağ indirmesini + disk yazmasını test ortamında taklit
/// etmesi gerekiyordu (4 aşamalı teşhis, HttpOverrides + PathProvider
/// sahteleri). Artık dosyalar YEREL asset — `FontLoader` doğrudan bayt
/// okuyup kaydediyor, ağ/disk taklidi YOK.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // ⚠️ İLK SATIR — eski sürümün de ilk satırıydı, ve bu sürümde YANLIŞLIKLA
  // düşmüştü: `ContentRepository.load()` gerçek asset bundle'ı okuyor
  // (`rootBundle`), o da `ServicesBinding.instance` istiyor — binding
  // kurulmadan HERHANGİ bir asset okuyan `setUpAll` "Binding has not yet
  // been initialized" ile düşer. Font yüklemenin kendisiyle ilgisi yok;
  // bütün widget-test altyapısının ön-koşulu.
  TestWidgetsFlutterBinding.ensureInitialized();

  await _loadFont('Familjen Grotesk', <String>[
    'assets/fonts/FamiljenGrotesk/FamiljenGrotesk-Regular.ttf',
    'assets/fonts/FamiljenGrotesk/FamiljenGrotesk-Bold.ttf',
  ]);
  await _loadFont('IBM Plex Mono', <String>[
    'assets/fonts/IBMPlexMono/IBMPlexMono-Regular.ttf',
    'assets/fonts/IBMPlexMono/IBMPlexMono-Medium.ttf',
    'assets/fonts/IBMPlexMono/IBMPlexMono-SemiBold.ttf',
  ]);

  // D1 REGRESYON KAPISI (Gravita `G-227` emsali, üç katmandan #2 — test-
  // zamanı sayım). `TestWidgetsFlutterBinding` zaten kurduğu bir
  // `HttpOverrides` ile gerçek istekleri 400'e ZORLUYOR (eski dosyanın
  // ölçtüğü olgu) — ama bu SESSİZ bir varsayılan, GÖRÜNÜR bir iddia
  // değil. Burada override EDİLEREK her `HttpClient` kurma denemesi
  // ANINDA ve ADIYLA (hangi dosyanın hangi satırı) düşürülüyor — google_
  // fonts sessizce geri gelirse ("bir bağımlılık yükseltmesi transitif
  // olarak http'yi geri getirdi" gibi) 361 testin İLK ağa çıkanı BURADA
  // yakalar, "0 bulundu" diye sessizce geçmez.
  HttpOverrides.global = _NoNetworkOverrides();

  await testMain();
}

class _NoNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError(
      'D1 REGRESYONU: bir test GERÇEK bir HttpClient kurmaya çalıştı. '
      'JabLab çalışma-anında ağa çıkmaz (google_fonts kaldırıldı, D1) — '
      'bu ya bir bağımlılığın sessizce ağ-yapabilir hâle döndüğünü ya da '
      'yeni bir ağ bağımlılığının test/network_deps_test.dart\'a hiç '
      'sorulmadan eklendiğini gösterir. Stack trace HANGİ testin '
      'tetiklediğini gösterir.',
    );
  }
}

/// Bir aileye AİT birden fazla ağırlık dosyasını TEK `FontLoader`a
/// ekliyoruz — Flutter'ın kendi deseni: aynı `family` adına yüklenen her
/// dosya, o ailenin İÇİNDEKİ bir varyant olarak kaydolur (gerçek uygulamada
/// `pubspec.yaml`ın `fonts:` listesinin AYNISI).
Future<void> _loadFont(String family, List<String> assetPaths) async {
  final FontLoader loader = FontLoader(family);
  for (final String path in assetPaths) {
    loader.addFont(_readAsset(path));
  }
  await loader.load();
}

/// `rootBundle.load` KULLANILMAZ: bu, `testMain()` çağrılmadan ÖNCE
/// koşuyor ve `TestWidgetsFlutterBinding` henüz KURULMAMIŞ olabilir —
/// asset bundle'ın platform kanalına ihtiyacı var. Doğrudan dosya sistemi
/// okuması bağımsız: `flutter test` çalışma dizini zaten paket köküdür.
Future<ByteData> _readAsset(String relativePath) async {
  final List<int> bytes = await File(relativePath).readAsBytes();
  return ByteData.view(Uint8List.fromList(bytes).buffer);
}
