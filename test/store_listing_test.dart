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
  final Map<String, dynamic> listing = (jsonDecode(
              File('docs/store/listing.json').readAsStringSync()) as Map)
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
    expect(hits, isEmpty,
        reason: 'MAĞAZA METNİNDE VAAT DİLİ: ${hits.join(" · ")}\n'
            'Kullanıcı bunu satın almadan ÖNCE görüyor — düzeltme şansı yok.');
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
    expect(hits, isEmpty,
        reason: 'CİHAZ-KANITI İDDİASI: ${hits.join(" · ")}\n'
            'KAMERA-KOPRUSU-CANLILIK.md §7.3-7.7 hâlâ açık — bu iddiayı '
            'destekleyecek bir ölçüm yok.');
  });

  test('ilk sürümde kamera koçluğu ve abonelik satışı vaat edilmiyor', () {
    final String desc = (listing['description'] as String).toLowerCase();
    final String short =
        ((listing['playStore'] as Map)['shortDescription'] as String)
            .toLowerCase();
    expect(desc, contains('camera coaching, punch counting, training '
        'sessions and subscriptions are not available'));
    expect(short, contains('camera coaching is not open'));
    expect(desc, isNot(contains('live solo shadow-boxing with')));
    expect(desc, isNot(contains('active jablab or motion+ subscription')));
  });

  test('kamera izin metni Info.plist ile TUTARLI', () {
    final String plist =
        File('ios/Runner/Info.plist').readAsStringSync();
    final String storeRationale =
        (listing['cameraPermissionRationale'] as Map)['ios'] as String;
    expect(plist, contains(storeRationale),
        reason: 'mağaza metnindeki kamera-izin gerekçesi Info.plist\'in '
            'NSCameraUsageDescription\'ından SAPMIŞ — ikisi birebir aynı '
            'olmalı, kullanıcı ikisini de görüyor');
  });
}
