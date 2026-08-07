import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// KURS HEDEFİ BAŞKA KURSUN DERSİNİ ANMAZ (J-164).
///
/// ## Bu kapı, YANLIŞ SINIFLANDIRILMIŞ bir kör noktadan doğdu
///
/// J-132 kurs hedefi kusurunu bulduğunda ikinci bir sorun daha ölçmüştü:
/// `boxing.intermediate`in hedefi **`tempo control`** diyordu ve o konu
/// **başka bir kursta** (`boxing.conditioning`). O kör noktayı **`imkânsız`**
/// diye sınıfladım — *"anlam işi, mekanikleştirilemez"* — ve **imkânsız
/// kutusuna konan şeye bir daha bakılmaz.**
///
/// Doğru-pozitif sınaması yanlışladı: `boxing.conditioning`de **tam adı
/// "Tempo control" olan bir ders var.** Ölçüt basit ve mekanik:
///
/// > **Bir kurs hedefi, BAŞKA bir kursun dersinin tam adını anmamalı.**
///
/// Yani sınıf `imkânsız` değil **ölçüm yöntemi** idi — ve M-F-322'ye göre
/// bu **kuyruğu değiştirir**: kapatılabilir olan kapatılır.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * **Eşanlamlıyı**: hedef *"pacing"* derse ve ders *"Tempo control"*
///   olsun — kapı görmez. Tam ad eşleşmesi bilerek: kelime bazlı eşleşme
///   *"Technique round"* ↔ *"Technique under fatigue"* gibi meşru
///   komşulukları yanlış yakalardı.
/// * Hedefin **kendi kursundaki** dersleri anmasını — o zaten doğru.
/// * Hiç ders adı taşımayan bir hedefin doğru olup olmadığını.
void main() {
  test('hedef, başka kursun dersini ANMIYOR', () {
    final Map<String, dynamic> lib = (jsonDecode(
            File('assets/content/library.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();

    final List<String> offenders = <String>[];
    int goals = 0;
    for (final dynamic d in lib['disciplines'] as List<dynamic>) {
      final List<dynamic> courses =
          (d as Map)['courses'] as List<dynamic>? ?? const <dynamic>[];
      // ders adı → sahibi kurs
      final Map<String, String> owner = <String, String>{};
      for (final dynamic c in courses) {
        for (final dynamic l
            in ((c as Map)['lessons'] as List<dynamic>? ?? const <dynamic>[])) {
          owner[((l as Map)['displayName'] as String).toLowerCase()] =
              c['id'] as String;
        }
      }
      for (final dynamic c in courses) {
        final String goal =
            ((c as Map)['goal'] as String? ?? '').toLowerCase();
        if (goal.isEmpty) continue;
        goals++;
        owner.forEach((String name, String home) {
          if (home == c['id']) return; // kendi dersi — doğru
          if (goal.contains(name)) {
            offenders.add('${c['id']} hedefi "$name" diyor — o ders $home\'da');
          }
        });
      }
    }

    // VAKUM KAPISI: hedef bulunamazsa kural boşa döner.
    expect(goals, greaterThanOrEqualTo(3),
        reason: 'kurs hedefi bulunamadı ($goals) — kapı boşluğa bakıyor');

    expect(offenders, isEmpty,
        reason: 'KURS HEDEFİ BAŞKA KURSUN DERSİNİ ANIYOR: '
            '${offenders.join(" · ")}. Kullanıcı o konuyu bu kursta arar '
            've bulamaz (J-164)');
  });
}
