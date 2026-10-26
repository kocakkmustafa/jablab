import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PORTRE KİLİDİ ÜÇ KATMANDA DA DURUYOR (J-109).
///
/// ## Neden test edilecek bir şey
///
/// Kilit tek bir satır ve tam da bu yüzden **sessizce kaybolabilir**: bir
/// `flutter create` tazelemesi manifest'i geri yazar, bir platform yükseltmesi
/// Info.plist'i birleştirir, biri `main.dart`ı sadeleştirir. Üçünden biri
/// düşerse kilit "var" görünmeye devam eder ama kullanıcı yatayda
/// **hiç ölçülmemiş** bir yüzey görür.
///
/// ## Bu testin ölçtüğü şey BEYAN, davranış DEĞİL
///
/// Widget testinde cihaz döndürülemez; burada ölçülen, üç katmanın da AYNI
/// şeyi ilan ettiği. Gerçek dönüş davranışı cihaz/simülatör turunun işi —
/// bu ayrım siliniyorsa test yalan söylüyor demektir.
void main() {
  test('main.dart portre kilidini KURUYOR', () {
    final String src = File('lib/main.dart').readAsStringSync();
    expect(
      src,
      contains('setPreferredOrientations'),
      reason: 'Flutter katmanındaki kilit kaldırılmış',
    );
    expect(src, contains('DeviceOrientation.portraitUp'));
    for (final String banned in <String>[
      'landscapeLeft',
      'landscapeRight',
      'portraitDown',
    ]) {
      expect(
        src,
        isNot(contains(banned)),
        reason: '$banned geri eklenmiş — kilit artık kilit değil',
      );
    }
  });

  test('iOS Info.plist YALNIZ portre ilan ediyor (iPad dahil)', () {
    // iPad AYRICA kontrol ediliyor: `~ipad` anahtarı ayrı bir listedir ve
    // varsayılanı dört yönü açar. Yalnız iPhone listesini kilitleyip iPad'i
    // unutmak, kilidi tabletlerde sessizce hiç kurmamak olurdu.
    final String plist = File('ios/Runner/Info.plist').readAsStringSync();
    for (final String banned in <String>[
      'UIInterfaceOrientationLandscapeLeft',
      'UIInterfaceOrientationLandscapeRight',
      'UIInterfaceOrientationPortraitUpsideDown',
    ]) {
      expect(
        plist,
        isNot(contains(banned)),
        reason: '$banned Info.plist\'e geri gelmiş',
      );
    }
    expect(plist, contains('UIInterfaceOrientationPortrait'));
    expect(
      plist,
      contains('UISupportedInterfaceOrientations~ipad'),
      reason: 'iPad anahtarı tamamen silinmiş — varsayılan dört yönü açar',
    );
  });

  test('Android manifest portreye sabitliyor', () {
    final String manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifest,
      contains('android:screenOrientation="portrait"'),
      reason: 'Android tarafı serbest bırakılmış',
    );
  });
}
