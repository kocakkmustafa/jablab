import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// REPLİK VARYANT ORANI (J-141).
///
/// ## Ölçülen kusur
///
/// Seçici **round-robin**: `_cursor.update(e, (int v) => (v + 1) %
/// lines.length)` — rastgele değil. Yani iki varyantlı bir replik on iki kez
/// ateşlenirse kullanıcı A,B,A,B… duyar: **aynı cümle 12 dakikada altı kez.**
/// `hiit`te tam bu oluyordu (`cue.burst_end` 12× ÷ 2 varyant), `r20`de
/// `cue.halfway` üç kez.
///
/// Desen yapısaldı: **en çok ateşlenen replikler en az varyanta sahipti**,
/// çünkü sayaç/aralık replikleri *bir kez* çalacakmış gibi yazılmıştı.
///
/// ## Eşik SEÇİLMEDİ — uygulamanın kendi standardından türetildi
///
/// Referans `cue.round_start`: **4 varyant / 6 tur (r20) = 1,5×**. Bu, bugün
/// sevk edilen ve kimsenin şikâyet etmediği oran. Hiçbir replik ondan daha
/// kötü olamaz.
///
/// Bir sabit yazsaydım ("en az 6 varyant") sayı benim olurdu ve bir sonraki
/// tur onu gerekçesiz değiştirebilirdi. Referansa bağlı bir oran, **kuralın
/// nereden geldiğini kendi içinde taşıyor** — J-134'ün `numericScoresUnlocked`
/// bağının aynısı.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * **Teknik repliklerini** — onlar hataya bağlı ateşlenir, kaç kez
///   çalacakları içerikten türetilemez (sınıfı *imkânsız*, kovalanmıyor).
/// * **Varyantların KALİTESİNİ** — yalnız sayı ve uzunluk ölçülüyor;
///   sekiz sıkıcı varyant kapıyı geçer.
/// * Aynı repliğin **ardışık** çalınmasını (round-robin bunu zaten önlüyor).
/// * Referansın kendisinin düşürülmesini — o yüzden referansın varyant
///   sayısı ayrıca sabitleniyor.
void main() {
  final Map<String, dynamic> cues = (jsonDecode(
          File('assets/content/cues.en.json').readAsStringSync()) as Map)
      .cast<String, dynamic>();
  final Map<String, dynamic> lib = (jsonDecode(
          File('assets/content/library.json').readAsStringSync()) as Map)
      .cast<String, dynamic>();

  Map<String, int> variantCounts() {
    final Map<String, int> out = <String, int>{};
    cues.forEach((String g, dynamic v) {
      if (g.startsWith(r'$') || v is! Map) return;
      v.forEach((dynamic k, dynamic lines) {
        final String key = k as String;
        if (key.startsWith(r'$')) return;
        out[key] = (lines as List<dynamic>).length;
      });
    });
    return out;
  }

  /// Bir repliğin EN ÇOK kaç kez ateşlendiği — içerikten türetilir, elle
  /// yazılmaz. Tur planı olan ders tur başına, aralık planı olan patlama
  /// başına ateşler.
  Map<String, int> maxFires() {
    final Map<String, int> out = <String, int>{};
    void bump(String key, int n) {
      if (n > (out[key] ?? 0)) out[key] = n;
    }
    for (final dynamic d in lib['disciplines'] as List<dynamic>) {
      for (final dynamic c
          in ((d as Map)['courses'] as List<dynamic>? ?? const <dynamic>[])) {
        for (final dynamic l
            in ((c as Map)['lessons'] as List<dynamic>? ?? const <dynamic>[])) {
          final Map<dynamic, dynamic> lesson = l as Map<dynamic, dynamic>;
          final Map<dynamic, dynamic>? rp =
              lesson['roundPlan'] as Map<dynamic, dynamic>?;
          final Map<dynamic, dynamic>? ip =
              lesson['intervalPlan'] as Map<dynamic, dynamic>?;
          if (rp != null) {
            final int n = rp['rounds'] as int;
            for (final String k in <String>[
              'cue.round_start', 'cue.round_end',
              'cue.halfway', 'cue.last_ten', 'cue.last_five',
            ]) {
              bump(k, n);
            }
            bump('cue.rest', n - 1);
          } else if (ip != null) {
            final int n = ip['bursts'] as int;
            for (final String k in <String>[
              'cue.burst_start', 'cue.burst_end',
              'cue.recover', 'cue.next_burst',
            ]) {
              bump(k, n);
            }
          }
        }
      }
    }
    return out;
  }

  test('hiçbir replik REFERANSTAN daha çok tekrar etmiyor', () {
    final Map<String, int> variants = variantCounts();
    final Map<String, int> fires = maxFires();

    // VAKUM KAPISI: ateşlenme haritası boşsa kural boşa döner.
    expect(fires.length, greaterThanOrEqualTo(8),
        reason: 'ateşlenme haritası ${fires.length} kalem — plan şekli '
            'değişmiş olabilir ve kapı hiçbir şeye bakmıyor');

    // REFERANS: bugün sevk edilen ve kabul edilmiş oran.
    const String ref = 'cue.round_start';
    expect(variants[ref], greaterThanOrEqualTo(4),
        reason: 'referans repliğin varyantı düştü — kuralın ÇUBUĞU '
            'düşürülerek geçilemez (J-141)');
    final double bar = fires[ref]! / variants[ref]!;

    final List<String> offenders = <String>[];
    fires.forEach((String key, int n) {
      final int v = variants[key] ?? 0;
      expect(v, greaterThan(0), reason: '$key ateşleniyor ama varyantı yok');
      final double rate = n / v;
      if (rate > bar + 0.001) {
        offenders.add('$key: $n× ÷ $v varyant = ${rate.toStringAsFixed(1)}× '
            '(referans ${bar.toStringAsFixed(1)}×)');
      }
    });

    expect(offenders, isEmpty,
        reason: 'AYNI CÜMLE ÇOK TEKRAR EDİYOR. Seçici round-robin, yani '
            'tekrar rastgele değil GARANTİLİ. En çok ateşlenen replikler en '
            'az varyanta sahipti (J-141):\n  ${offenders.join('\n  ')}');
  });

  // ⚠️ UZUNLUK KURALI BURADA DEĞİL — ve olmamalı (J-145).
  //
  // İlk yazışımda buraya global bir `≤8 kelime` testi koydum. Sonra motor
  // süiti koşturunca gördüm ki kural ZATEN VAR ve **daha iyi**:
  // `packages/jablab_engine/test/cues_test.dart` sınırı GRUBA GÖRE
  // uyguluyor — `counting` 3 · `interval` 5 · `technique` 5 · `session` 6 ·
  // `noVerdict` 10 · `summary` 20. Gerekçesi de yazılı: *tur ortasında 8
  // kelime bile fazla, tur sonunda 13 kelime gayet normal.*
  //
  // Benim global kuralım onun **zayıf kopyasıydı** ve zararlıydı: yeşil
  // yanan gevşek bir kapı, sıkı olanın yokluğunu düşündürür. J-139'da
  // kelime listesi için aynı hatayı bulmuştum — bu üçüncüsü ve ilk kez
  // hatayı **kendim ürettim**. Kural tek yerde kalıyor.
}
