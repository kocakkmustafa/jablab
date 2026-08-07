import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// İKİ DOSYA AYNI DRILL'LERİ TANIMLIYOR (J-148).
///
/// `boxing@1.0.0.json` ve `curriculum.json` **aynı 10 drill kimliğini**
/// taşıyor. Çelişmiyorlar — alanlar farklı: kural setinde `id`/`displayKey`/
/// `durationSec`, müfredatta `displayName`/`instruction`/`targets`/…
///
/// **Ama `durationSec` İKİSİNDE DE var ve bugün değerler eşit.** Hiçbir şey
/// eşit kalmasını sağlamıyordu: biri değişirse ikisi sessizce ayrışır ve
/// hangisinin doğru olduğunu kimse bilemez — J-144'ün bant listelerinde
/// gördüğümüz *iki doğruluk kaynağı* durumunun aynısı, bir adım öncesinde
/// yakalanmış hâli.
///
/// Kural seti tarafı **hiç okunmuyor** (`$unreadFields`te beyanlı), yani
/// bugün kullanıcıya ulaşan taraf müfredat. Kural seti tarafı **silinmedi**:
/// bu gece *"kimse okumuyor"* ölçümünde **iki kez** yanıldım (J-145), o
/// yüzden **silme eşiği beyan eşiğinden yüksek** tutuluyor.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Sürelerin **doğruluğunu** — yalnız iki dosyanın aynı şeyi söylediğini.
/// * Diğer alanların örtüşmediğini (bugün örtüşmüyorlar; örtüşürlerse bu
///   kapı onu görmez ve genişletilmeli).
void main() {
  test('drill kimlikleri ve süreleri İKİ DOSYADA da aynı', () {
    final Map<String, dynamic> rs = (jsonDecode(
            File('assets/rulesets/boxing@1.0.0.json').readAsStringSync())
        as Map).cast<String, dynamic>();
    final Map<String, dynamic> cur = (jsonDecode(
            File('assets/content/curriculum.json').readAsStringSync())
        as Map).cast<String, dynamic>();

    final Map<String, int> fromRules = <String, int>{
      for (final dynamic d in rs['drills'] as List<dynamic>)
        (d as Map)['id'] as String: d['durationSec'] as int,
    };
    final Map<String, dynamic> fromCur =
        (cur['drills'] as Map).cast<String, dynamic>();

    // VAKUM KAPISI: iki taraf da dolu olmalı, yoksa "hepsi eşit" bedavaya
    // doğru olur (aile dersi #4).
    expect(fromRules.length, greaterThanOrEqualTo(10));
    expect(fromCur.length, fromRules.length,
        reason: 'drill SAYILARI ayrıştı: kural seti ${fromRules.length}, '
            'müfredat ${fromCur.length}');

    expect(fromCur.keys.toSet(), fromRules.keys.toSet(),
        reason: 'drill KİMLİKLERİ ayrıştı — iki dosya farklı drill '
            'kümelerini tanımlıyor');

    final List<String> drift = <String>[];
    fromRules.forEach((String id, int sec) {
      final int? other = (fromCur[id] as Map)['durationSec'] as int?;
      if (other != sec) drift.add('$id: kural=$sec ≠ müfredat=$other');
    });
    expect(drift, isEmpty,
        reason: 'AYNI ALAN İKİ DOSYADA FARKLI: ${drift.join(" · ")}. '
            'İki doğruluk kaynağı — hangisinin doğru olduğunu kimse '
            'bilemez (J-148)');
  });
}
