import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/session_narrator.dart';

/// MOTOR KODU → KULLANICI CÜMLESİ eşlemesinin eksiksizliği (J-096).
///
/// Sınanan dürüstlük değişmezi: **ham teşhis dizesi kullanıcıya gösterilemez.**
/// `REAR_HAND_LOW` bir kod adıdır; ekranda görünmesi doc-75/5 sınıfının
/// kamera tarafıdır.
///
/// ## Neden İKİ YÖN
///
/// Tek yön yeterli değil ve bu ölçüldü. Mekanik `cue.${code.toLowerCase()}`
/// kısayolu **14 kodun 7'sinde** tutmuyor (`TEMPO_TOO_FAST_FOR_FORM` →
/// `cue.slow_down` gibi). Bu yüzden:
///   * her kural-seti kodu eşlemede OLMALI (yoksa o hata ham kodla ya da
///     genel cümleyle geçer — düzeltme kaybolur);
///   * eşlemedeki her anahtar içerikte OLMALI (sarkan atıf; `CueBook`un
///     olay tarafında zaten fırlattığı kural).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Kural setindeki TÜM hata kodları — elle liste YAZILMIYOR, dosyadan
  /// süpürülüyor: yeni bir kod eklenince test onu kendiliğinden kapsar ve
  /// unutulamaz (`fitness_ship_audit`in içerikten-sürme deseni).
  Set<String> ruleSetCodes() {
    final Object doc = jsonDecode(
        File('assets/rulesets/boxing@1.0.0.json').readAsStringSync());
    final Set<String> codes = <String>{};
    void walk(Object? o) {
      if (o is Map) {
        final Object? c = o['code'];
        if (c is String) codes.add(c);
        o.values.forEach(walk);
      } else if (o is List) {
        o.forEach(walk);
      }
    }

    walk(doc);
    return codes;
  }

  Set<String> cueKeys() {
    final Map<String, dynamic> doc =
        (jsonDecode(File('assets/content/cues.en.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();
    final Set<String> keys = <String>{};
    for (final MapEntry<String, dynamic> g in doc.entries) {
      if (g.key.startsWith(r'$') || g.value is! Map) continue;
      for (final String k in (g.value as Map).keys.cast<String>()) {
        if (!k.startsWith(r'$')) keys.add(k);
      }
    }
    return keys;
  }

  test('kural setindeki HER kod eşlemede var', () {
    final Set<String> missing =
        ruleSetCodes().difference(jabLabIssueCueMapping.keys.toSet());
    expect(missing, isEmpty,
        reason: 'eşlenmemiş kod(lar) $missing — bu hatalar kullanıcıya '
            'genel cümleyle geçer, gerçek düzeltme KAYBOLUR');
  });

  test('eşlemedeki HER anahtar içerikte var (sarkan atıf yok)', () {
    final Set<String> dangling =
        jabLabIssueCueMapping.values.toSet().difference(cueKeys());
    expect(dangling, isEmpty,
        reason: 'içerikte olmayan replik anahtar(lar)ı: $dangling');
  });

  test('MEKANİK eşleme YETMİYOR — kısayolun neden reddedildiği ölçülü', () {
    // Bu test bir davranışı değil bir KARARI pinliyor: biri "şu haritayı
    // silip toLowerCase() yazalım" derse, kaç kodun sessizce düşeceğini
    // sayıyla görsün.
    final Set<String> keys = cueKeys();
    final List<String> wouldBreak = ruleSetCodes()
        .where((String c) => !keys.contains('cue.${c.toLowerCase()}'))
        .toList()
      ..sort();
    expect(wouldBreak.length, greaterThanOrEqualTo(7),
        reason: 'mekanik kısayol artık tutuyorsa bu kararı yeniden gözden '
            'geçir — ama ÖLÇEREK');
    for (final String c in wouldBreak) {
      expect(jabLabIssueCueMapping.containsKey(c), isTrue,
          reason: '$c mekanik eşlemede düşerdi ve elle de eşlenmemiş');
    }
  });

  test('GÖRÜNÜRLÜK kodları düzeltme sayılmıyor', () {
    // Kullanıcı yanlış bir şey yapmıyor, biz göremiyoruz. Düzeltme yuvasına
    // koymak olmayan bir hatayı düzelttirmek olurdu.
    for (final String c in jabLabVisibilityIssueCodes) {
      expect(jabLabIssueCueMapping.containsKey(c), isTrue,
          reason: '$c görünürlük kodu ama eşlemesi yok');
    }
    expect(jabLabVisibilityIssueCodes.contains('REAR_HAND_LOW'), isFalse,
        reason: 'teknik kusuru görünürlük sınıfına düşerse kullanıcıya '
            '"göremiyorum" denir ve gerçek düzeltme hiç verilmez');
  });

  test('replik kitabı anahtarla CÜMLE döndürüyor, kodu değil', () async {
    final CueBook book = await const ContentRepository().loadCues();
    for (final MapEntry<String, String> e in jabLabIssueCueMapping.entries) {
      final String? line = book.sayKey(e.value);
      expect(line, isNotNull, reason: '${e.value} için cümle yok');
      expect(line, isNot(contains(e.key)),
          reason: 'cümle ham kodu (${e.key}) taşıyor');
      expect(line, isNot(matches(RegExp(r'^[A-Z_]+$'))),
          reason: 'cümle bir kod adı gibi görünüyor: "$line"');
    }
  });

  test('replikte doldurulmamış yer tutucu YOK', () async {
    // Sesli okunduğunda "Round {n} of {total}" diye duyulur.
    final CueBook book = await const ContentRepository().loadCues();
    for (final String key in jabLabIssueCueMapping.values) {
      final String line = book.sayKey(key)!;
      expect(CueBook.unfilledPlaceholder.hasMatch(line), isFalse,
          reason: '"$line" doldurulmamış yer tutucu taşıyor');
    }
  });
}
