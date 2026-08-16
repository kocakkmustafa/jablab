import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// M-F-680 (2026-08-16, aile-geneli): beş hattın gizlilik denetimi bulmuştu —
/// AppIcon Flutter'ın 1×1 desenli VARSAYILANIYDI, LaunchImage üçü de gerçekten
/// 1×1/68 bayttı. J-172③ bunu bu hattın KENDİ envanterine 07 Ağustos'ta
/// (kapısız, yalnız varlığa bakarak) yazmıştı — H-60/H-65'in ikon-ayırt-etme
/// kapısı ve family reçetesi (§3) rehberliğinde kapatıldı.
///
/// İKİ AYRI varlık, ikisi de burada AYRI sınanır (reçetenin kendi dersi:
/// "renk düzeltmesi görseli düzeltmez, görsel düzeltmesi rengi düzeltmez").
void main() {
  const String stockAppIconMd5 = 'c785f8932297af4acd5f5ccb7630f01c';
  const String appIconPath =
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png';

  test('🔒 AppIcon Flutter STOK şablonu DEĞİL (MD5 farklı)', () {
    final List<int> bytes = File(appIconPath).readAsBytesSync();
    final String actualMd5 = md5.convert(bytes).toString();
    expect(actualMd5, isNot(stockAppIconMd5),
        reason: 'AppIcon hâlâ Flutter\'ın 1024×1024 stok şablonuyla '
            'MD5-birebir — gerçek bir ikon değil, "flutter create" '
            'varsayılanı sevk edilirdi');
    // POZİTİF KONTROL: dosya gerçekten okunuyor ve boyutu makul.
    expect(bytes.length, greaterThan(1000),
        reason: 'dosya çok küçük — okuma bozuk olabilir, yukarıdaki "farklı" '
            'sonucu anlamsız olurdu');
  });

  test('🔒 AppIcon gerçekten 1024×1024 (PNG IHDR\'den ölçülü)', () {
    final _PngSize size = _readPngSize(File(appIconPath).readAsBytesSync());
    expect(size.width, 1024);
    expect(size.height, 1024);
  });

  test(
      '🔒 LaunchImage üçü de GERÇEK boyutlu — 1×1 placeholder DEĞİL '
      '(reçete §3: görsel rengi ölçmez, boyutu ölçer)', () {
    // storyboard <resources> bildirimi: LaunchImage 168×185pt @1x.
    const Map<String, ({int w, int h})> expected = <String, ({int w, int h})>{
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png':
          (w: 168, h: 185),
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png':
          (w: 336, h: 370),
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png':
          (w: 504, h: 555),
    };
    for (final MapEntry<String, ({int w, int h})> e in expected.entries) {
      final _PngSize size = _readPngSize(File(e.key).readAsBytesSync());
      expect(size.width, e.value.w, reason: '${e.key}: genişlik');
      expect(size.height, e.value.h, reason: '${e.key}: yükseklik');
      expect(size.width, isNot(1), reason: '${e.key}: hâlâ 1×1 placeholder');
    }
  });

  test('🔒 SABOTAJ — 1×1 bir dosya kapıyı GERÇEKTEN düşürür', () {
    // Kapının kendisinin ısırdığını kanıtlar: gerçek bir 1×1 PNG üret,
    // aynı okuyucudan geçir, reddedildiğini gör. Dosyaya YAZMAZ — yalnız
    // bellekte sentetik bir 1×1 IHDR kurar.
    final List<int> onePixelPng = _syntheticPngBytes(1, 1);
    final _PngSize size = _readPngSize(onePixelPng);
    expect(size.width, 1);
    expect(() => expect(size.width, isNot(1)), throwsA(isA<TestFailure>()),
        reason: '1×1 bir görüntü bu testte GEÇMELİ diye beklenirse kapı '
            'anlamsızdır — sabotaj bunu doğruluyor');
  });
}

class _PngSize {
  const _PngSize(this.width, this.height);
  final int width;
  final int height;
}

/// PNG IHDR'den genişlik/yükseklik okur. `dart:ui`/image-decode paketine
/// bağımlılık EKLEMEZ — PNG imzası (8 bayt) + IHDR chunk'ının ilk 8 baytı
/// (genişlik+yükseklik, big-endian uint32) sabit biçimlidir.
_PngSize _readPngSize(List<int> bytes) {
  const List<int> signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  for (int i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) {
      throw const FormatException('PNG imzası eşleşmiyor');
    }
  }
  // Baytlar 8-11: IHDR chunk uzunluğu. 12-15: "IHDR". 16-19: genişlik.
  // 20-23: yükseklik.
  int u32(int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
  return _PngSize(u32(16), u32(20));
}

List<int> _syntheticPngBytes(int w, int h) {
  final List<int> bytes = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  bytes.addAll(<int>[0, 0, 0, 13]); // IHDR length
  bytes.addAll(utf8.encode('IHDR'));
  void addU32(int v) {
    bytes.addAll(<int>[
      (v >> 24) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
    ]);
  }

  addU32(w);
  addU32(h);
  return bytes;
}
