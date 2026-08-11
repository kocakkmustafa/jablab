import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// 4. KATMAN — ATANMAYAN KOŞUL ALANLARI (koordinatör öngörüsü, 2026-08-12).
///
/// ## Katman haritası
///
/// `gate_reachability_test` → CONFIG: ders kamerayı açıyor mu?
/// `gate_primitive_producer_test` → PRİMİTİF: olayı üreten var mı?
/// `error_reachability_test` → HATA KODU: `evaluateAt` gerçek bir marker'a
/// mı bakıyor?
/// **Bu dosya → KOŞUL ALANI: `evaluateAt` geçse bile, koşulun okuduğu
/// veri kaynağı hiç BESLENİYOR mu?**
///
/// Koordinatör öngörüsü ölçüldü ve DOĞRULANDI: `sequenceMismatch`i
/// (`_Ctx`) elle bulmuştuk ("tek yerde deklare, hiçbir yerde atanmıyor").
/// Aynı ölçütü `EvalContext`in TÜM 8 üyesine uygulayınca **3 alan +
/// 1 metot daha** aynı sınıfta çıktı: `tempoBand`, `errorRateInWindow`,
/// `phaseDurationMs` (`_phaseDurations`i dolduran setter'lar hiç
/// çağrılmıyor).
///
/// ## Bu katmanın kendine özgü bulduğu şey
///
/// `error_reachability_test` (3. katman) `LEAD_HAND_NOT_RECOVERED`i
/// ULAŞILABİLİR sayardı — `evaluateAt:['RETRACTION']` gerçekten dispatch
/// ediliyor. Ama koşulu (`phaseDurationMs.RETRACTION`) hep `null` okunur
/// → hata YİNE kalıcı erişilemez, 3. katmanın GÖREMEDİĞİ bir sebeple. Bu
/// yüzden 3. katman ve bu katman AYRI listeler tutuyor — biri diğerinin
/// yerine geçmiyor, ikisi birlikte tam resmi verir.
///
/// ## Mekanik ölçüt
///
/// `EvalContext` arayüzünün (`ruleset.dart`) her üyesi için, motor
/// kaynağında (`lib/src/*.dart`) en az bir GERÇEK atama/çağrı var mı:
/// `_ctx.üye = …` (alanlar) ya da `setPhaseDuration(`/`clearPhaseDurations(`
/// çağrısı (`phaseDurationMs`in tek veri kaynağı). Yok ise alan
/// "atanmayan" sayılır.
void main() {
  test('ATANMAYAN koşul alanı kümesi, ÖLÇÜLEN hâlle birebir aynı', () {
    final String interfaceSrc = File('lib/src/ruleset.dart').readAsStringSync();
    final int start = interfaceSrc.indexOf('abstract interface class EvalContext');
    expect(start, greaterThanOrEqualTo(0),
        reason: 'EvalContext arayüzü bulunamadı — kaynak taşınmış olabilir');
    final int end = interfaceSrc.indexOf('\n}', start);
    final String body = interfaceSrc.substring(start, end);

    // Arayüz üyeleri: `Tip get ad;`, `Tip ad;` (get bildirimsiz alan
    // OLMAZ arayüzde, hepsi get/metot) ve `Tip? ad(Tip param);` metotları.
    final Set<String> members = <String>{
      for (final RegExpMatch m
          in RegExp(r'\b(?:get\s+)?([a-zA-Z]\w*)\s*[;(]').allMatches(body))
        m.group(1)!,
    }..removeWhere((String s) => s == 'get');
    // VAKUM MUHAFIZI — arayüz gerçekten okundu mu?
    expect(members.length, greaterThanOrEqualTo(6),
        reason: 'yalnız ${members.length} üye okundu — EvalContext ayrıştırma '
            'kırık olabilir, bu kapının sonucu anlamsız');

    final StringBuffer engineSrc = StringBuffer();
    for (final FileSystemEntity f in Directory('lib/src').listSync()) {
      if (f is File && f.path.endsWith('.dart')) {
        engineSrc.write(f.readAsStringSync());
        engineSrc.write('\n');
      }
    }
    final String src = engineSrc.toString();

    final List<String> unassigned = <String>[];
    for (final String member in members) {
      final bool fieldAssigned =
          RegExp(r'\.' + RegExp.escape(member) + r'\s*=[^=]').hasMatch(src);
      final bool phaseDurationBacked = member == 'phaseDurationMs' &&
          (src.contains('setPhaseDuration(') &&
              RegExp(r'void setPhaseDuration[^{]*=>\s*_phaseDurations')
                      .hasMatch(src) &&
              // setter'ın KENDİSİ dışında bir ÇAĞRI noktası var mı?
              RegExp(r'(?<!void )setPhaseDuration\(').allMatches(src).length >
                  1);
      if (!fieldAssigned && !phaseDurationBacked) {
        unassigned.add(member);
      }
    }
    unassigned.sort();

    final Map<String, dynamic> rules = (jsonDecode(
                File('../../assets/rulesets/boxing@1.0.0.json')
                    .readAsStringSync()) as Map)
        .cast<String, dynamic>();
    final List<String> recorded =
        (rules[r'$unassignedConditionFields'] as List<dynamic>)
            .cast<String>()
          ..sort();

    expect(unassigned, recorded,
        reason: 'ATANMAYAN koşul alanı kümesi DEĞİŞTİ.\n'
            '  ölçülen : $unassigned\n'
            '  kayıtlı : $recorded\n\n'
            'KÜÇÜLDÜYSE: iyi haber — bir alana gerçek bir atama eklendi. '
            '`\$unassignedConditionFields`i güncelle, o alana bağlı hata '
            'kodlarının artık ateşlenip ateşlenmediğini `error_'
            'reachability_test`le çapraz kontrol et.\n'
            'BÜYÜDÜYSE: `EvalContext`e yeni bir üye eklendi ama motor onu '
            'hiç doldurmuyor — o üyeye dayanan her koşul KALICI '
            'ERİŞİLEMEZ olur, kamera açık ve evaluateAt geçerli olsa bile.');
  });
}
