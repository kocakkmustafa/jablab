import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BAĞIMLILIK DÜRÜSTLÜĞÜ — "ağa çıkmıyoruz" iddiasını KAPIYA bağlar (J-217).
///
/// ## Neden var — ve neden bugün BİR YALAN buldu
///
/// *"Ürün ağ isteği yapmıyor"* iddiası **ölçülmüştü ve ölçüm doğruydu**:
/// üretim Dart'ında `HttpClient`/`package:http` **0** (sabotaj-doğrulamalı).
/// Ama o ölçüm **kendi kodumu** kapsıyordu, ***ürünü değil.***
///
/// `google_fonts` **doğrudan bağımlılık**, `design_tokens.dart`ta üretimde
/// kullanılıyor, `allowRuntimeFetching` **hiç kapatılmamış** (varsayılan
/// açık) ve depoda **paketlenmiş font YOK** → uygulama font yüzlerini
/// **çalışma anında Google'ın sunucularından indiriyor.**
///
/// > ***Kendi kodunda ağ olmaması, ürününde ağ olmaması demek değildir.***
///
/// Bu, tam olarak bu hattın bütün gün düzelttiği sınıf — bu kez KAPSAM
/// hatası bende: doğru ölçüm, fazla geniş cümle.
///
/// ## Ölçütün ŞEKLİ — BÖLME (tamlık-zorlayan), liste değil
///
/// Desen Lissom'dan **adapte edildi, icat edilmedi** (koordinatör hükmü).
/// Ostinato'nun ölçtüğü kusur önlendi: *tam-eşleşmeli küçük bir "ağ paketi"
/// listesi*, `http_parser` gibi önek paylaşan adları **görmez bile** ve
/// paketlerin çoğu hiçbir kapıdan geçmez (onda 65 paketin 63'ü).
///
/// Burada bunun yerine **BÖLME** var: `pubspec.lock`taki **her paket**
/// aşağıdaki kümelerden **tam birine** düşmek zorunda. Yeni bir paket
/// eklendiğinde sınıflandırılmamış olur ve kapı **öter** — yani "ağ" sorusu
/// **sorulmadan** bağımlılık eklenemez.
void main() {
  /// Ağ yapabilen paketler — ADIYLA ve GEREKÇESİYLE.
  ///
  /// Bu küme büyürse kapı öter: bir ağ bağımlılığı **sessizce** giremez.
  const Map<String, String> networkCapable = <String, String>{
    'google_fonts':
        'ÜRETİMDE AĞA ÇIKIYOR. design_tokens.dart GoogleFonts.familjenGrotesk/'
            'ibmPlexMono kullanıyor; allowRuntimeFetching kapatılmamış ve '
            'paketlenmiş font yok → font yüzleri çalışma anında indiriliyor. '
            'Kullanıcı verisi GÖNDERİLMİYOR (istek font dosyası için) ama '
            '"ürün ağa çıkmıyor" cümlesi bu paket yüzünden YANLIŞTIR.',
    'http':
        'google_fonts ve test altyapısının transitif bağımlılığı; üretim '
            'kodumuz onu import ETMİYOR (ölçüldü, sabotaj-doğrulamalı).',
    'sync_http':
        'flutter_driver/webdriver zincirinin transitif bağımlılığı — yalnız '
            'test/sürücü yolunda, sevk edilen uygulamaya girmiyor.',
    'webdriver':
        'integration_test sürücüsü; WebDriver protokolü HTTP üzerinden '
            'konuşur ama yalnız geliştirme makinesinde, sevk edilen '
            'uygulamada değil.',
    'fuchsia_remote_debug_protocol':
        'flutter_driver zincirinin transitif bağımlılığı — uzak hata '
            'ayıklama protokolü, yalnız test/sürücü yolunda.',
    'vm_service':
        'Dart VM servis protokolü (soket) — geliştirme/test aracı; sürüm '
            'derlemesinde kullanıcıya ulaşan bir yol değil.',
  };

  /// Ağ yapmayan her şey. Bölmenin öteki yarısı.
  const Set<String> noNetwork = <String>{
    'args', 'async', 'boolean_selector', 'characters', 'clock', 'code_assets',
    'collection', 'crypto', 'fake_async', 'ffi', 'file', 'flutter',
    'flutter_driver', 'flutter_lints', 'flutter_test', 'flutter_web_plugins',
    'hooks', 'http_parser', 'integration_test', 'jablab_engine', 'jni',
    'jni_flutter', 'jni_util', 'leak_tracker', 'leak_tracker_flutter_testing',
    'leak_tracker_testing', 'lints', 'logging', 'matcher',
    'material_color_utilities', 'meta', 'motion_camera', 'motion_core',
    'objective_c', 'package_config', 'path', 'path_provider',
    'path_provider_android', 'path_provider_foundation', 'path_provider_linux',
    'path_provider_platform_interface', 'path_provider_windows', 'platform',
    'permission_handler', 'permission_handler_android',
    'permission_handler_apple', 'permission_handler_html',
    'permission_handler_platform_interface', 'permission_handler_windows',
    'plugin_platform_interface', 'process', 'pub_semver', 'record_use',
    'sky_engine', 'source_span', 'stack_trace', 'stream_channel',
    'string_scanner', 'term_glyph', 'test_api', 'typed_data', 'vector_math',
    'web', 'xdg_directories', 'yaml',
  };

  List<String> lockPackages() {
    final List<String> out = <String>[];
    bool inPackages = false;
    for (final String line in File('pubspec.lock').readAsLinesSync()) {
      if (line.startsWith('packages:')) {
        inPackages = true;
        continue;
      }
      if (inPackages && line.isNotEmpty && !line.startsWith(' ')) break;
      final RegExpMatch? m =
          RegExp(r'^  ([a-z0-9_]+):$').firstMatch(line);
      if (inPackages && m != null) out.add(m.group(1)!);
    }
    return out;
  }

  test('POZİTİF KONTROL — lock okunuyor ve bilinen paketler bulunuyor', () {
    final List<String> pkgs = lockPackages();
    // Vakum muhafızı: boş liste, aşağıdaki bölme testini sessizce geçirirdi.
    expect(pkgs.length, greaterThan(50),
        reason: 'yalnız ${pkgs.length} paket okundu — ayrıştırma bozuk, '
            'bölme testinin sonucu ANLAMSIZ olurdu');
    // Ostinato'nun kusurunun ikizi: önek paylaşan ad GÖRÜNÜYOR mu?
    expect(pkgs, contains('http'), reason: 'ayrıştırıcı `http`yi görmüyor');
    expect(pkgs, contains('http_parser'),
        reason: 'önek paylaşan ad görünmüyor — Ostinato\'nun bulduğu kusur '
            'burada da olurdu');
  });

  test('🔒 BÖLME TAM — her paket sınıflandırılmış, yeni paket kapıdan geçer',
      () {
    final List<String> pkgs = lockPackages();
    final Set<String> classified = <String>{
      ...networkCapable.keys,
      ...noNetwork,
    };

    final List<String> unclassified =
        pkgs.where((String p) => !classified.contains(p)).toList()..sort();
    expect(unclassified, isEmpty,
        reason: 'SINIFLANDIRILMAMIŞ paket(ler): $unclassified\n'
            'Bir bağımlılık eklendi ve "ağa çıkıyor mu" sorusu SORULMADI. '
            'Kararı ver ve listeye yaz: ağ yapabiliyorsa `networkCapable`a '
            'GEREKÇESİYLE, yapmıyorsa `noNetwork`a. Ürünün gizlilik '
            'beyanları (Info.plist, PrivacyInfo.xcprivacy, mağaza metni) '
            'bu ayrıma dayanıyor.');

    // Ters yön: listede olup lock'ta OLMAYAN bir ad, bölmeyi bayatlatır.
    final List<String> stale =
        classified.where((String p) => !pkgs.contains(p)).toList()..sort();
    expect(stale, isEmpty,
        reason: 'lock\'ta olmayan sınıflandırma: $stale — bağımlılık '
            'kaldırılmış, bölme bayatlamış');
  });

  test('🔴 AĞ YAPABİLEN PAKETLERİN HEPSİ GEREKÇELİ — ve küme sabit', () {
    for (final MapEntry<String, String> e in networkCapable.entries) {
      expect(e.value.length, greaterThan(40),
          reason: '${e.key} gerekçesiz ya da çok kısa — bir ağ bağımlılığı '
              'adıyla ve SEBEBİYLE durur');
    }
    // Küme değişirse öt: yeni bir ağ bağımlılığı, ürünün gizlilik
    // cümlelerini yeniden yazmayı gerektirebilir.
    expect(networkCapable.keys.toSet(), <String>{
      'google_fonts', 'http', 'sync_http', 'webdriver',
      'fuchsia_remote_debug_protocol', 'vm_service',
    });
  });

  test('⛔ "ürün ağa çıkmıyor" DENEMEZ — google_fonts üretimde ağa çıkıyor',
      () {
    // Bu testin varlık sebebi: bugün PrivacyInfo.xcprivacy'de tam o cümle
    // vardı ve YANLIŞTI. Cümle geri gelirse burası öter.
    final String manifest =
        File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
    expect(manifest.contains('ağ isteği YAPMIYOR'), isFalse,
        reason: 'gizlilik manifesti "ürün ağ isteği yapmıyor" diyor ama '
            'google_fonts üretimde font indiriyor — kapsamı KAMERA/kullanıcı '
            'verisiyle sınırla, ürünün tamamı hakkında konuşma');
    // POZİTİF KONTROL: dosya gerçekten okunuyor.
    expect(manifest, contains('NSPrivacyTracking'),
        reason: 'manifest okunamadı — yukarıdaki "yok" sonucu anlamsız');
  });
}
