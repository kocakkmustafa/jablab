import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// MAĞAZA LİSTE METNİ KAPISI — koordinatör sevki (2026-08-12).
///
/// ## Neden bu dosya var
///
/// `promise_language_test.dart` bilerek `docs/` klasörünü taramaz — sevk
/// edilmiyor. Mağaza liste metni de `docs/store/listing.json`da yaşıyor
/// (kod değil, taslak) ama ürünün DİĞER yüzeylerinden farklı bir şey:
/// **kullanıcının yüklemeden ÖNCE gördüğü yüzey.** İlk sürümde satış yok;
/// kullanıcı yine bu metinle karar veriyor. Koordinatör hükmü: *"mağaza
/// metni de bir yüzeydir ve bayatlar"* — bu yüzden `docs/` istisnasının
/// KENDİ istisnası: bu dosya taranır.
///
/// ## Neydi bu OLMASAYDI kaçırılırdı
///
/// `promise_language_test.dart`ın kapsamı `lib/` + `assets/content/` —
/// `docs/store/listing.json` YAPISAL OLARAK göremez. Bu dosya olmadan
/// mağaza metnine sızan bir "coming soon" ya da bir "tested on device"
/// iddiası hiçbir kapıdan geçmeden App Store Connect'e giderdi.
void main() {
  final Map<String, dynamic> listing =
      (jsonDecode(File('docs/store/listing.json').readAsStringSync()) as Map)
          .cast<String, dynamic>();

  /// AYNI regex — `promise_language_test.dart`daki tanımla birebir.
  final RegExp promise = RegExp(
    r"\b(yet|soon|coming soon|for now|in a future|will be added|"
    r"we'll add|planned for)\b",
    caseSensitive: false,
  );

  /// `$` önekli alanlar bu dosyanın KENDİ gerekçe/kaynak notlarıdır —
  /// kullanıcıya gitmez, `promise_language_test.dart`ın `$planBasis` sınıfı
  /// muafiyetiyle aynı gerekçe.
  List<String> userStrings(Object? node) {
    final List<String> out = <String>[];
    void walk(Object? n) {
      if (n is String) {
        out.add(n);
      } else if (n is List) {
        n.forEach(walk);
      } else if (n is Map) {
        n.forEach((Object? k, Object? v) {
          if (k is String && k.startsWith(r'$')) return;
          walk(v);
        });
      }
    }

    walk(node);
    return out;
  }

  test('VAAT DİLİ YOK — promise_language_test ile AYNI regex', () {
    final List<String> hits = <String>[];
    for (final String s in userStrings(listing)) {
      if (promise.hasMatch(s)) hits.add('"$s"');
    }
    expect(
      hits,
      isEmpty,
      reason:
          'MAĞAZA METNİNDE VAAT DİLİ: ${hits.join(" · ")}\n'
          'Kullanıcı bunu satın almadan ÖNCE görüyor — düzeltme şansı yok.',
    );
  });

  test('CİHAZ-KANITI İDDİASI YOK — cihaz turu (§7.3-7.7) henüz yapılmadı', () {
    final RegExp deviceProof = RegExp(
      r'\b(tested on (a )?real device|verified on device|proven on device|'
      r'device[- ]tested|device[- ]verified|clinically)\b',
      caseSensitive: false,
    );
    final List<String> hits = <String>[];
    for (final String s in userStrings(listing)) {
      if (deviceProof.hasMatch(s)) hits.add('"$s"');
    }
    expect(
      hits,
      isEmpty,
      reason:
          'CİHAZ-KANITI İDDİASI: ${hits.join(" · ")}\n'
          'KAMERA-KOPRUSU-CANLILIK.md §7.3-7.7 hâlâ açık — bu iddiayı '
          'destekleyecek bir ölçüm yok.',
    );
  });

  test(
    'ilk sürümde kamera koçluğu vaat edilmiyor; abonelik koşulları açık',
    () {
      final String desc = (listing['description'] as String).toLowerCase();
      final String short =
          ((listing['playStore'] as Map)['shortDescription'] as String)
              .toLowerCase();
      // First release: five written beginner areas (2026-10-22), not only the
      // 39-lesson boxing path.
      for (final String area in <String>[
        'boxing: 39 lessons in 8 modules',
        'kickboxing: 16 lessons',
        'muay thai: 16 lessons',
        'karate: 16 kihon lessons',
        'taikyoku shodan',
        'tai chi: 14 fixed-foot foundation lessons',
      ]) {
        expect(desc, contains(area));
      }
      expect(desc, contains('do not teach sparring or contact training'));
      expect(
        desc,
        contains(
          'camera coaching and automatic punch counting '
          'are not available',
        ),
      );
      // Sales are open in the first release (Core R3): the listing states the
      // free part, both plans, the 14-day trial and auto-renewal/cancellation.
      for (final String sale in <String>[
        'the first lessons of every course are free',
        'jablab (\$11.99/month or \$69.99/year)',
        'motion+ (\$19.99/month or \$129.99/year',
        '14-day free trial',
        'renews automatically unless cancelled at least 24 hours',
      ]) {
        expect(desc, contains(sale));
      }
      expect(desc, isNot(contains('subscription sales are not available')));
      expect(short, contains('camera coaching is not open'));
      expect(desc, isNot(contains('live solo shadow-boxing with')));
      expect(desc, isNot(contains('active jablab or motion+ subscription')));
    },
  );

  // JAB-05a (2026-10-27): yerel listing'ler EN'in çevirisidir; metni dil
  // bilmeden doğrulayamayız ama bayatlığı sayılardan yakalarız. Eski kopya
  // yalnız 39 derslik boksu anlatıyordu: 16/10/14 ve fiyatlar orada yoktu.
  group('yerel listing\'ler EN kaynağıyla AYNI olguları taşıyor', () {
    const Map<String, int> limits = <String, int>{
      'name': 30,
      'subtitle': 30,
      'promotionalText': 170,
      'keywords': 100,
      'shortDescription': 80,
      'description': 4000,
    };
    int count(String text, String number) =>
        RegExp('(?<![0-9])$number(?![0-9])').allMatches(text).length;

    for (final String locale in <String>[
      'ar',
      'de',
      'es-419',
      'fr',
      'ja',
      'pt-BR',
    ]) {
      test(locale, () {
        final Map<String, dynamic> local =
            (jsonDecode(
                      File(
                        'docs/store/listing.$locale.json',
                      ).readAsStringSync(),
                    )
                    as Map)
                .cast<String, dynamic>();
        final Map<String, dynamic> app = (local['appStore'] as Map)
            .cast<String, dynamic>();
        final String desc = local['description'] as String;
        final Map<String, String> fields = <String, String>{
          for (final String k in <String>[
            'name',
            'subtitle',
            'promotionalText',
            'keywords',
          ])
            k: app[k] as String,
          'shortDescription':
              (local['playStore'] as Map)['shortDescription'] as String,
          'description': desc,
        };
        // Anahtar kelimeler UTF-8 bayt sayılır (tool/prepare_store_packet.py
        // ile aynı); ar/ja/hi'de karakter sayısı 100'ün altında kalıp bayt
        // olarak aşabiliyor.
        limits.forEach((String k, int max) {
          final int size = k == 'keywords'
              ? utf8.encode(fields[k]!).length
              : fields[k]!.runes.length;
          expect(size, lessThanOrEqualTo(max), reason: k);
        });

        // Boks 39/8 modül; KB, MT, karate kihon 16 (+ Yang Family 16);
        // Taikyoku 10; Tai Chi 14 (+ 14 dil, 14 gün).
        expect(count(desc, '39'), greaterThanOrEqualTo(1));
        expect(count(desc, '8'), greaterThanOrEqualTo(1));
        expect(count(desc, '16'), greaterThanOrEqualTo(4));
        expect(count(desc, '10'), greaterThanOrEqualTo(1));
        expect(count(desc, '14'), greaterThanOrEqualTo(3));
        for (final String price in <String>['11', '69', '19', '129']) {
          expect(
            desc,
            matches(RegExp('(?<![0-9])$price[.,]99')),
            reason: price,
          );
        }
        expect(desc, contains('Motion+'));
        expect(count(desc, '24'), greaterThanOrEqualTo(1));

        final String strings = File(
          'ios/Runner/$locale.lproj/InfoPlist.strings',
        ).readAsStringSync();
        expect(
          strings,
          contains(
            '"NSCameraUsageDescription" = '
            '"${(local['cameraPermissionRationale'] as Map)['ios']}"',
          ),
        );
        expect(local['supportUrl'], listing['supportUrl']);
        expect(local['privacyPolicyUrl'], listing['privacyPolicyUrl']);
      });
    }
  });

  test('kamera izin metni Info.plist ile TUTARLI', () {
    final String plist = File('ios/Runner/Info.plist').readAsStringSync();
    final String storeRationale =
        (listing['cameraPermissionRationale'] as Map)['ios'] as String;
    expect(
      plist,
      contains(storeRationale),
      reason:
          'mağaza metnindeki kamera-izin gerekçesi Info.plist\'in '
          'NSCameraUsageDescription\'ından SAPMIŞ — ikisi birebir aynı '
          'olmalı, kullanıcı ikisini de görüyor',
    );
  });
}
