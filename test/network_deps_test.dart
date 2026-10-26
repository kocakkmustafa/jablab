import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BAĞIMLILIK DÜRÜSTLÜĞÜ — "ağa çıkmıyoruz" iddiasını KAPIYA bağlar (J-217).
///
/// 2026-09-24 güncel durum: Motion hesabı için Auth/profil/üyelik ağı VAR.
/// Aşağıdaki D1 açıklaması font CDN'inin kaldırıldığı tarihsel evreyi anlatır;
/// `networkCapable` artık gerçek hesap taşıyıcılarını da sınıflandırır.
///
/// ## D1 (2026-08-16, F2) — google_fonts KALDIRILDI, bölme YENİDEN ÖLÇÜLDÜ
///
/// `google_fonts` çalışma-anında fonts.gstatic.com'dan font çekiyordu
/// (J-264/J-217) — D1 paketleyip kaldırdı. `flutter pub get` bunu bağımsız
/// doğruladı: "no longer being depended on: google_fonts, http, http_parser"
/// (`http`/`http_parser` yalnız google_fonts'un transitifiydi, kendi
/// başlarına HİÇBİR ŞEY onları gerektirmiyordu — `sync_http`/`webdriver`/
/// `fuchsia_remote_debug_protocol`/`vm_service` hâlâ burada çünkü onlar
/// `flutter_driver`/`integration_test`in transitifi, google_fonts'un DEĞİL).
///
/// ⚠️ ESKİ POZİTİF KONTROL (`http`/`http_parser` önek-paylaşımı) artık
/// ÇALIŞAMAZ — ikisi de lock'ta yok. `path_provider` ailesi AYNI özelliği
/// taşıyor (`path_provider_android`/`_foundation`/`_platform_interface`/...)
/// ve hâlâ gerçek bir bağımlılık — onunla değiştirildi.
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
    // Motion hesabı e-posta, isteğe bağlı görünen ad, hesap ID'si ve
    // satın alma doğrulamasını Supabase'e gönderir. Kamera/seans geçmişi gitmez.
    'motion_account':
        'Ortak hesabın Auth ve üyelik istemcisi; hesap ve satın alma '
        'alanları ağda kullanılır, gizlilik manifestinde beyan edilir.',
    'motion_entitlements':
        'Mağaza satın alma kanıtını Motion doğrulama işlevine gönderir; '
        'işlem referansı hesapla bağlı satın alma geçmişidir.',
    'motion_platform_signals':
        'Core R3 yerel eklentisi: StoreKit AppTransaction ve Play Age '
        'Signals API\'sini çağırır; ağ trafiği işletim sisteminin mağaza '
        'hizmetindedir, eklenti kendisi HTTP açmaz. Deneme kimliği '
        'motion_entitlements üzerinden Motion sunucusuna gider.',
    'in_app_purchase':
        'Apple/Google mağaza satın alma istemcisi; ürün sorgusu ve '
        'işlem akışı cihaz mağazası ağına dayanır.',
    'in_app_purchase_android':
        'Google Play Billing köprüsü; ürün ve satın alma durumunu '
        'Play hizmetiyle doğrular.',
    'in_app_purchase_storekit':
        'Apple StoreKit köprüsü; ürün ve satın alma durumunu '
        'App Store hizmetiyle doğrular.',
    'in_app_purchase_platform_interface':
        'Mağaza köprülerinin ortak satın alma API arayüzü; ağ akışını '
        'taşıyan eklenti ailesiyle birlikte sınıflandırılır.',
    'supabase':
        'Motion hesap istemcisinin Auth/veri API kökü; e-posta, '
        'görünen ad, hesap ID ve satın alma aktarımı beyan edildi.',
    'supabase_common':
        'Supabase istemcisinin ortak altyapısı; hesap '
        'ağına ait, kamera ve seans geçmişi yüklemesi değildir.',
    'supabase_flutter':
        'Supabase oturum ve derin bağlantı köprüsü; '
        'Motion hesabı için gerçek ağ akışı sağlar.',
    'gotrue':
        'Supabase Auth katmanı; giriş/kayıt/kurtarma e-postasını '
        'Motion hesabı sunucusuna iletir.',
    'postgrest':
        'Profil ve uygulamaya özel üyelik sorgusu için '
        'Supabase veri API taşıyıcısıdır.',
    'functions_client':
        'Ortak hesap silme ve satın alma doğrulama Edge Function '
        'çağrılarını taşır; sunucu yanıtı doğrulanır.',
    'realtime_client':
        'Supabase transitif ağ paketi; uygulama '
        'doğrudan gerçek zamanlı abonelik kullanmıyor.',
    'storage_client':
        'Supabase transitif depolama istemcisi; '
        'uygulamada kamera/seans yükleme yolu yok.',
    'http':
        'Supabase istemcisinin HTTP taşıyıcısı; yalnız '
        'hesap/üyelik istekleri için kullanılabilir.',
    'web_socket':
        'Supabase transitif soket taşıyıcısı; '
        'uygulamada doğrudan bağlantı açılmıyor.',
    'web_socket_channel':
        'Supabase transitif soket kanalı; '
        'uygulamada doğrudan bağlantı açılmıyor.',
    'url_launcher':
        'Paket harici URL açabilir; Motion hesabı '
        'bağımlılığıdır, seans verisi göndermez.',
    'url_launcher_android':
        'Android harici URL açıcı; Motion hesabı '
        'transitifi, kamera verisi taşımaz.',
    'url_launcher_ios':
        'iOS harici URL açıcı; Motion hesabı '
        'transitifi, kamera verisi taşımaz.',
    'url_launcher_linux':
        'Linux harici URL açıcı; Motion hesabı '
        'transitifi, mobil sürümde etkin değil.',
    'url_launcher_macos':
        'macOS harici URL açıcı; Motion hesabı '
        'transitifi, mobil sürümde etkin değil.',
    'url_launcher_platform_interface':
        'Harici URL açıcı arayüzü; '
        'hesap bağımlılığının transitif katmanı.',
    'url_launcher_web':
        'Web harici URL açıcı; Motion hesabı '
        'transitifi, mobil sürümde etkin değil.',
    'url_launcher_windows':
        'Windows harici URL açıcı; Motion hesabı '
        'transitifi, mobil sürümde etkin değil.',
    'video_player':
        'Eklenti ağ URL kaynaklarını da açabilir; JabLab medya yüzeyi yalnız '
        'SHA denetimli paketli asset yolunu kullanır, uzak medya URLsi vermez.',
    'video_player_android':
        'Android oynatıcı ağ medyasını destekler; mevcut uygulama yolu yalnız '
        'paketli asset açar ve görüntü yüklemesi yapmaz.',
    'video_player_avfoundation':
        'Apple AVFoundation oynatıcı ağ medyasını destekler; mevcut uygulama '
        'yolu yalnız paketli asset açar.',
    'video_player_platform_interface':
        'Ağ kaynağı kabul edebilen video_player ailesinin ortak arayüzü; '
        'JabLab kodu bu seçeneği kullanmaz.',
    'video_player_web':
        'Web video oynatıcı ağ kaynağı açabilir; mobil kurs yolu yalnız '
        'paketli asset kullanır.',
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
    'app_links', 'app_links_linux', 'app_links_platform_interface',
    'app_links_web', 'convert', 'csslib', 'dart_jsonwebtoken',
    'flutter_localizations', 'gtk', 'html', 'http_parser', 'intl',
    'json_annotation', 'mime', 'passkeys_platform_interface',
    'pointycastle', 'shared_preferences', 'shared_preferences_android',
    'shared_preferences_foundation', 'shared_preferences_linux',
    'shared_preferences_platform_interface', 'shared_preferences_web',
    'shared_preferences_windows', 'yet_another_json_isolate',
    'args', 'async', 'boolean_selector', 'characters', 'clock', 'code_assets',
    'collection', 'crypto', 'fake_async', 'ffi', 'file', 'flutter',
    'flutter_driver', 'flutter_lints', 'flutter_test', 'flutter_web_plugins',
    'hooks', 'integration_test', 'jablab_engine', 'jni',
    'jni_flutter', 'jni_util', 'leak_tracker', 'leak_tracker_flutter_testing',
    'leak_tracker_testing', 'lints', 'logging', 'matcher',
    'material_color_utilities', 'meta', 'motion_camera',
    // The pinned package only validates bundled course bytes using crypto.
    'motion_content',
    'motion_core',
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
    // JAB-P0-002 (2026-08-19): `device_info_plus` eklendi (yalnız
    // `integration_test/` — `isPhysicalDevice`, dev-dependency, release
    // binary'ye girmez). Kendisi + platform arayüzü yerel OS sorgusu
    // yapar, ağa çıkmaz. `win32`/`win32_registry`/`ffi_leak_tracker`
    // TRANSİTİF: `device_info_plus`ın desteklediği Windows platformunun
    // kayıt-defteri/FFI bağlayıcıları (bu proje Windows'a DERLENMİYOR ama
    // `pub` yine de çözüyor) — üçü de yerel sistem çağrısı, HTTP/soket
    // içermez.
    'device_info_plus', 'device_info_plus_platform_interface',
    'ffi_leak_tracker', 'win32', 'win32_registry',
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
      final RegExpMatch? m = RegExp(r'^  ([a-z0-9_]+):$').firstMatch(line);
      if (inPackages && m != null) out.add(m.group(1)!);
    }
    return out;
  }

  test('POZİTİF KONTROL — lock okunuyor ve bilinen paketler bulunuyor', () {
    final List<String> pkgs = lockPackages();
    // Vakum muhafızı: boş liste, aşağıdaki bölme testini sessizce geçirirdi.
    expect(
      pkgs.length,
      greaterThan(50),
      reason:
          'yalnız ${pkgs.length} paket okundu — ayrıştırma bozuk, '
          'bölme testinin sonucu ANLAMSIZ olurdu',
    );
    // Önek-paylaşan ad GÖRÜNÜYOR mu? (Ostinato'nun kusurunun ikizi.)
    // `http`/`http_parser` D1'le lock'tan çıktı — `path_provider` ailesi
    // AYNI özelliği taşıyor ve hâlâ gerçek bir bağımlılık.
    expect(
      pkgs,
      contains('path_provider'),
      reason: 'ayrıştırıcı `path_provider`ı görmüyor',
    );
    expect(
      pkgs,
      contains('path_provider_platform_interface'),
      reason:
          'önek paylaşan ad görünmüyor — Ostinato\'nun bulduğu kusur '
          'burada da olurdu',
    );
  });

  test(
    '🔒 BÖLME TAM — her paket sınıflandırılmış, yeni paket kapıdan geçer',
    () {
      final List<String> pkgs = lockPackages();
      final Set<String> classified = <String>{
        ...networkCapable.keys,
        ...noNetwork,
      };

      final List<String> unclassified =
          pkgs.where((String p) => !classified.contains(p)).toList()..sort();
      expect(
        unclassified,
        isEmpty,
        reason:
            'SINIFLANDIRILMAMIŞ paket(ler): $unclassified\n'
            'Bir bağımlılık eklendi ve "ağa çıkıyor mu" sorusu SORULMADI. '
            'Kararı ver ve listeye yaz: ağ yapabiliyorsa `networkCapable`a '
            'GEREKÇESİYLE, yapmıyorsa `noNetwork`a. Ürünün gizlilik '
            'beyanları (Info.plist, PrivacyInfo.xcprivacy, mağaza metni) '
            'bu ayrıma dayanıyor.',
      );

      // Ters yön: listede olup lock'ta OLMAYAN bir ad, bölmeyi bayatlatır.
      final List<String> stale =
          classified.where((String p) => !pkgs.contains(p)).toList()..sort();
      expect(
        stale,
        isEmpty,
        reason:
            'lock\'ta olmayan sınıflandırma: $stale — bağımlılık '
            'kaldırılmış, bölme bayatlamış',
      );
    },
  );

  test('🔴 AĞ YAPABİLEN PAKETLERİN HEPSİ GEREKÇELİ — ve küme sabit', () {
    for (final MapEntry<String, String> e in networkCapable.entries) {
      expect(
        e.value.length,
        greaterThan(40),
        reason:
            '${e.key} gerekçesiz ya da çok kısa — bir ağ bağımlılığı '
            'adıyla ve SEBEBİYLE durur',
      );
    }
    // Küme değişirse öt: yeni bir ağ bağımlılığı, ürünün gizlilik
    // cümlelerini yeniden yazmayı gerektirebilir.
    expect(networkCapable.keys.toSet(), <String>{
      'sync_http',
      'webdriver',
      'fuchsia_remote_debug_protocol',
      'vm_service',
      'motion_account',
      'motion_entitlements',
      'motion_platform_signals',
      'in_app_purchase',
      'in_app_purchase_android',
      'in_app_purchase_storekit',
      'in_app_purchase_platform_interface',
      'supabase',
      'supabase_common',
      'supabase_flutter',
      'gotrue',
      'postgrest',
      'functions_client',
      'realtime_client',
      'storage_client',
      'http',
      'web_socket',
      'web_socket_channel',
      'url_launcher',
      'url_launcher_android',
      'url_launcher_ios',
      'url_launcher_linux',
      'url_launcher_macos',
      'url_launcher_platform_interface',
      'url_launcher_web',
      'url_launcher_windows',
      'video_player',
      'video_player_android',
      'video_player_avfoundation',
      'video_player_platform_interface',
      'video_player_web',
    });
  });

  test('Motion hesap alanları ve satın alma geçmişi beyanlı; font CDN yok', () {
    // NEGATİF İKİZİN TERSİ (H-40): D1'den ÖNCE bu test "ürün ağa çıkmıyor
    // DENEMEZ" derdi (google_fonts gerçekten çıkıyordu). D1 sonrası olgu
    // TERSİNE DÖNDÜ — artık manifestte kalan herhangi bir "font CDN'i
    // istisnası" cümlesi BAYATTIR ve buradaki eski (ters yönlü) test onu
    // yakalayamazdı. Kapının sabotaj yönü de tersine döndü (H-40 dersi):
    // eskiden "yanlış iddia geri gelirse öt" derdi, şimdi "eski istisna
    // cümlesi hâlâ DURUYORSA öt" diyor.
    final String manifest = File(
      'ios/Runner/PrivacyInfo.xcprivacy',
    ).readAsStringSync();
    // ⚠️ "font" kelimesinin kendisi ARANMAZ — TARİHÎ not (J-217) bilerek
    // korunuyor (M-F-634 ⑤: geçmiş silinmez, üstüne tarih atılır) ve o
    // not "font" kelimesini meşru biçimde taşıyor. Aranan şey GÜNCEL bir
    // İSTİSNA iddiası — eski cümlenin TAM KALIBI.
    expect(
      manifest.contains('Giden tek ağ isteği font'),
      isFalse,
      reason:
          'manifest hâlâ GÜNCEL bir font-CDN istisnası iddia ediyor '
          'ama google_fonts KALDIRILDI (D1) — bayat bir istisna, H-40 '
          'gereği güncellenmeliydi (tarihî not KALABİLİR, güncel iddia '
          'kalamaz)',
    );
    for (final String type in <String>[
      'NSPrivacyCollectedDataTypeEmailAddress',
      'NSPrivacyCollectedDataTypeName',
      'NSPrivacyCollectedDataTypeUserID',
    ]) {
      expect(
        manifest,
        contains(type),
        reason: 'Motion hesabı alanı gizlilik manifestinde eksik: $type',
      );
    }
    expect(
      manifest,
      contains('NSPrivacyCollectedDataTypePurchaseHistory'),
      reason:
          'Satış ilk sürümde açık (Core R3): satın alma kanıtı Motion '
          'sunucusunda hesaba bağlı tutuluyor',
    );
    // POZİTİF KONTROL: dosya gerçekten okunuyor.
    expect(
      manifest,
      contains('NSPrivacyTracking'),
      reason: 'manifest okunamadı — yukarıdaki "yok" sonucu anlamsız',
    );
  });

  test(
    '🔒 D1 REGRESYON KAPISI GERÇEKTEN ISIRIYOR — sabotajsız kanıt DEĞİLDİR',
    () {
      // flutter_test_config.dart'taki `_NoNetworkOverrides` (D1, üç
      // katmandan #2) burada TEKRAR yazılmıyor — o TÜM test koşumunu
      // koruyor. Ama "kurulu" ile "gerçekten çalışıyor" ayrı şeyler
      // (bu ailenin defalarca öğrendiği ders) — burada SABOTAJLA kanıtlanıyor:
      // gerçek bir HttpClient kurmayı DENE, ANINDA düşmeli.
      expect(
        () => HttpClient(),
        throwsA(isA<StateError>()),
        reason:
            'HttpOverrides.global HttpClient kurulmasını engellemiyor — '
            'D1 regresyon kapısı KURULU ama ISIRMIYOR, ki bu "0 ağ isteği" '
            'iddiasını anlamsız kılar (kapı ötmeden geçen bir sabotaj, kapı '
            'yok demektir)',
      );
    },
  );
}
