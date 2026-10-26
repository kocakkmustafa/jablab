import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// JAB-P0-004 Step 1 — "boş required-reason" için NEGATİF DENETİM.
///
/// ## Neden bu dosya var
///
/// `ios/Runner/PrivacyInfo.xcprivacy`nin `NSPrivacyAccessedAPITypes` alanı
/// bugün BİLEREK BOŞ (`<array/>`) — dosyanın kendi yorumu bunu "app kodu
/// dosya YAZIP OKUYOR ama zaman damgası okumuyor" diye gerekçelendiriyor.
/// Ama bu BEYAN hiçbir kapıyla ZORLANMIYORDU: Apple'ın "gerekli-sebep API"
/// kategorileri (developer.apple.com, bu turda CANLI sayfadan doğrulandı —
/// tahmin edilmedi) TAM OLARAK beş tane —
/// `NSPrivacyAccessedAPICategoryFileTimestamp` ·
/// `NSPrivacyAccessedAPICategorySystemBootTime` ·
/// `NSPrivacyAccessedAPICategoryDiskSpace` ·
/// `NSPrivacyAccessedAPICategoryActiveKeyboards` ·
/// `NSPrivacyAccessedAPICategoryUserDefaults` — ve BU BEYANIN doğru
/// kalması, gelecekte hiçbir Swift dosyasının bu kategorilerin API'lerini
/// SESSİZCE eklemediğine bağlı. `ITMS-91055: Invalid API reason
/// declaration` App Store Connect'in GERÇEK bir ret sınıfı (Apple forum
/// kayıtları) — bu kapı onu YEREL olarak, submission'dan ÖNCE yakalar.
///
/// ⚠️ NE ÖLÇMÜYOR: Yalnız birinci-taraf `ios/Runner/*.swift` taranıyor.
/// Bir CocoaPod bağımlılığının kendi native kodu bu kapının GÖRÜŞ ALANI
/// DIŞINDA — Xcode 15+'ın kendi arşiv-zamanı manifest birleştirmesi o
/// katmanı zaten denetler (Apple'ın kendi altyapısı, burada YENİDEN
/// İCAT EDİLMEDİ). Bu kapı yalnız BİZİM yazdığımız koda bakar.
void main() {
  final Directory runnerDir = Directory('ios/Runner');
  final File manifest = File('ios/Runner/PrivacyInfo.xcprivacy');

  /// (kategori, [API sembolleri]) — Apple'ın CANLI sayfasından birebir
  /// (bu oturumda `mcp__Claude_Browser__get_page_text` ile okundu, tahmin
  /// edilmedi). Yalnız BİRİNCİ-TARAF Swift'te makul biçimde çağrılabilecek
  /// sembol adları — `getattrlist` gibi düşük seviye C API'leri bu app
  /// katmanında zaten kullanılmıyor, listeye alınmadı (grep gürültüsü
  /// yaratırdı, kapının kendi amacına aykırı).
  const Map<String, List<String>> requiredReasonApis = <String, List<String>>{
    'NSPrivacyAccessedAPICategoryFileTimestamp': <String>[
      '.creationDate',
      '.modificationDate',
      '.contentModificationDateKey',
      '.creationDateKey',
    ],
    'NSPrivacyAccessedAPICategorySystemBootTime': <String>[
      'systemUptime',
      'mach_absolute_time(',
    ],
    'NSPrivacyAccessedAPICategoryDiskSpace': <String>[
      'volumeAvailableCapacityKey',
      'volumeTotalCapacityKey',
    ],
    'NSPrivacyAccessedAPICategoryActiveKeyboards': <String>['activeInputModes'],
    'NSPrivacyAccessedAPICategoryUserDefaults': <String>[
      'UserDefaults(',
      'UserDefaults.standard',
    ],
  };

  test('POZİTİF KONTROL — Runner/ Swift dosyaları gerçekten taranıyor', () {
    final List<File> swiftFiles = runnerDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.swift'))
        .toList();
    expect(
      swiftFiles,
      isNotEmpty,
      reason:
          'ios/Runner altında hiç .swift dosyası bulunamadı — '
          'gezinme bozuk, aşağıdaki "temiz" sonucu ANLAMSIZ olurdu',
    );
  });

  test('🔒 SABOTAJ — dedektör sentetik bir gerekli-sebep API çağrısını '
      'gerçekten yakalar', () {
    // Gerçek dosyalara dokunmadan, TARAMA MANTIĞINI sentetik girdiyle sınar
    // (repo'nun her yerde kullandığı desen: önce dedektörü sına, sonra
    // temiz koda güven).
    const String fakeSource = 'let d = FileManager.default.creationDate';
    bool found = false;
    for (final String api
        in requiredReasonApis['NSPrivacyAccessedAPICategoryFileTimestamp']!) {
      if (fakeSource.contains(api)) found = true;
    }
    expect(
      found,
      isTrue,
      reason:
          'dedektör sentetik bir ihlali YAKALAMADI — bugünkü temiz '
          'sonucun ne kanıtladığı belirsizleşir',
    );
  });

  test('🔴 ios/Runner/*.swift hiçbir gerekli-sebep API\'si BEYANSIZ '
      'ÇAĞIRMIYOR', () {
    final List<File> swiftFiles = runnerDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.swift'))
        .toList();
    final String manifestSrc = manifest.readAsStringSync();

    final List<String> offenders = <String>[];
    for (final File f in swiftFiles) {
      final String src = f.readAsStringSync();
      for (final MapEntry<String, List<String>> cat
          in requiredReasonApis.entries) {
        for (final String api in cat.value) {
          if (!src.contains(api)) continue;
          // API sembolü BULUNDU — manifestte AYNI kategori beyan edilmiş mi?
          if (!manifestSrc.contains(cat.key)) {
            offenders.add('${f.path}: "$api" (${cat.key}) manifestte YOK');
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'BEYANSIZ gerekli-sebep API çağrısı:\n'
          '  ${offenders.join("\n  ")}\n\n'
          'PrivacyInfo.xcprivacy NSPrivacyAccessedAPITypes\'a ilgili '
          'kategori + gerekçe eklenmeden bu API kullanılamaz — '
          'App Store Connect bunu ITMS-91055 ile REDDEDER (submission '
          'anında, bu kapıdan çok daha pahalı bir yerde).',
    );
  });

  test('POZİTİF KONTROL — manifest gerçekten okunuyor', () {
    expect(manifest.existsSync(), isTrue);
    expect(
      manifest.readAsStringSync(),
      contains('NSPrivacyAccessedAPITypes'),
      reason:
          'manifest okunamadı ya da beklenen anahtarı taşımıyor — '
          'yukarıdaki "temiz" sonucu ANLAMSIZ olurdu',
    );
  });
}
