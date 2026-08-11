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
/// **kullanıcının satın almadan ÖNCE gördüğü tek yüzey.** Düzeltme şansı
/// yok — kullanıcı zaten karar vermiş oluyor. Koordinatör hükmü: *"mağaza
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

  test('ÖLÇÜM-BEYANI ÜÇLÜSÜ description İÇİNDE VAR', () {
    // HonestyBox'ın (Discipline.measured/notMeasured) mağaza karşılığı —
    // ne ölçtüğünü/ölçmediğini söyleyen satır OLMALI (koordinatör şartı).
    final String desc = listing['description'] as String;
    for (final String marker in <String>[
      'MEASURED AND GRADED',
      'WATCHED AND COACHED, NOT SCORED',
      'WHAT WE DO NOT MEASURE',
    ]) {
      expect(desc, contains(marker),
          reason: 'description ölçüm-beyanı üçlüsünün "$marker" bölümünü '
              'kaybetmiş — mağaza metni HonestyBox\'ın karşılığını taşımıyor');
    }
  });

  test('description library.json\'ın notMeasured GERÇEK cümlesini taşıyor', () {
    // İcat kontrolü: "hook and uppercut" iddiası uydurulmadı mı, uygulamanın
    // KENDİ ölçülmüş cümlesinden mi geldi — negatif ikiz.
    final Map<String, dynamic> lib = (jsonDecode(
                File('assets/content/library.json').readAsStringSync())
            as Map)
        .cast<String, dynamic>();
    final Map<String, dynamic> boxing = (lib['disciplines'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((Map<String, dynamic> d) => d['id'] == 'boxing');
    final List<String> notMeasured =
        (((boxing['honesty'] as Map)['notMeasured'] as List<dynamic>?) ??
                const <dynamic>[])
            .cast<String>();
    final bool hookSourced = notMeasured.any(
        (String s) => s.contains('missed almost every hook'));
    expect(hookSourced, isTrue,
        reason: 'library.json\'ın hook/uppercut cümlesi değişmiş olabilir — '
            'mağaza metnindeki karşılığı elle güncellenmeli');
    expect(listing['description'] as String,
        contains('missed almost every hook'),
        reason: 'mağaza metni library.json\'ın gerçek ölçülmüş cümlesini '
            'taşımıyor — icat edilmiş bir gerekçe olabilir');
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
