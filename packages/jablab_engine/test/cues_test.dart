import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Sesli koç replikleri — mekanik değişmezler.
///
/// Replikler ürünün AĞZI. Bir hata kodu üretilip karşılığında söylenecek bir
/// şey olmaması, kullanıcı için "sistem sustu" demektir; fazla uzun bir replik
/// ise telefon uzaktayken duyulmaz. İkisi de sessizce olur, o yüzden testle
/// zorlanır.
void main() {
  final Map<String, dynamic> cues = (jsonDecode(
          File('../../assets/content/cues.en.json').readAsStringSync()) as Map)
      .cast<String, dynamic>();
  final RuleSet rules = loadBoxingRuleSet();

  Map<String, dynamic> group(String g) =>
      (cues[g] as Map).cast<String, dynamic>();

  Iterable<String> allLines() sync* {
    for (final String g in <String>[
      'technique', 'noVerdict', 'counting', 'encouragement', 'session', 'summary'
    ]) {
      for (final dynamic v in group(g).values) {
        yield* (v as List<dynamic>).cast<String>();
      }
    }
  }

  test('config\'teki HER hata kodunun repliği var', () {
    final Set<String> haveCues = <String>{
      ...group('technique').keys,
      ...group('noVerdict').keys,
    };
    for (final ErrorConfig e in rules.errors) {
      expect(haveCues, contains(e.feedbackKey),
          reason: '${e.code} üretiliyor ama söylenecek bir şey yok — '
              'kullanıcı için sistem susmuş olur');
    }
  });

  test('uzunluk sınırı NE ZAMAN söylendiğine bağlı (plan §13)', () {
    // "Kombinasyon ortasında uzun anlatım yok · tur sonunda ayrıntı."
    // Düz bir sınır bu kuralı yanlış temsil ederdi: tur ortasında 8 kelime
    // bile fazla, tur sonunda 13 kelime gayet normal.
    const Map<String, int> limits = <String, int>{
      'technique': 5,      // tur ortasında, kullanıcı hareket hâlinde
      'noVerdict': 10,     // durur ve dinler; sebep açıklanmalı
      'counting': 3,
      'encouragement': 5,
      'session': 6,
      'summary': 20,       // tur sonu, dinlenirken okunur/duyulur
    };
    for (final MapEntry<String, int> lim in limits.entries) {
      for (final MapEntry<String, dynamic> e in group(lim.key).entries) {
        for (final String line in (e.value as List<dynamic>).cast<String>()) {
          final int words = line.split(RegExp(r'\s+')).length;
          expect(words, lessThanOrEqualTo(lim.value),
              reason: '${lim.key}/${e.key}: "$line" ($words kelime, '
                  'sınır ${lim.value})');
        }
      }
    }
  });

  test('teknik replikleri ≤5 kelime — tur içinde söylenecekler en kısası', () {
    for (final MapEntry<String, dynamic> e in group('technique').entries) {
      for (final String line in (e.value as List<dynamic>).cast<String>()) {
        expect(line.split(RegExp(r'\s+')).length, lessThanOrEqualTo(5),
            reason: '${e.key}: "$line" tur ortasında söylenemeyecek kadar uzun');
      }
    }
  });

  test('"göremiyorum" replikleri VAR — sessizlik alternatifi', () {
    // plan §12: susmak "her şey yolunda" der. Bu grup boşsa, hüküm
    // verilemeyen anlarda ürün sessizce yalan söyler.
    expect(group('noVerdict'), isNotEmpty);
    expect(group('noVerdict').keys, contains('cue.low_confidence'));
  });

  test('hiçbir replik ölçmediğimiz şeyi iddia etmiyor', () {
    // "power", "force", "speed: 42" gibi ifadeler ürünün ölçemediği şeyler.
    final RegExp forbidden = RegExp(r'\b(power|force|kph|mph|newton)\b',
        caseSensitive: false);
    for (final String line in allLines()) {
      if (line.contains("don't measure")) continue; // dürüstlük cümlesi
      expect(forbidden.hasMatch(line), isFalse,
          reason: 'ölçemediğimiz bir şeyi iddia eden replik: "$line"');
    }
  });

  test('her anahtarın en az bir varyantı var (tekrar körlüğüne karşı)', () {
    for (final String g in <String>['technique', 'session']) {
      for (final MapEntry<String, dynamic> e in group(g).entries) {
        expect((e.value as List<dynamic>), isNotEmpty, reason: e.key);
      }
    }
  });
}
