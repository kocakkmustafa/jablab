import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// HATA KODU ULAŞILABİLİRLİĞİ — `gate_reachability_test`/
/// `gate_primitive_producer_test`in bir katman AŞAĞISI (2026-08-12).
///
/// ## Nereden çıktı
///
/// Mağaza metni taslağı yazılırken (koordinatör sevki) *"Combination order
/// and timing"* iddiası çapraz kontrole takıldı. Ölçüm: `WRONG_HAND_FOR_
/// COMBINATION`/`COMBINATION_ORDER_ERROR` ikisi de `evaluateAt:
/// ['COMBINATION_END']` istiyor; `COMBINATION_END` motorun dispatch
/// ettiği HİÇBİR markerla eşleşmiyor (ne bir teknik fazı ne bir literal
/// dispatch noktası) — bu iki hata **kalıcı erişilemez.**
///
/// Süpürme aynı ölçütü TÜM hata kodlarına uyguladı ve **üçüncü** bir kod
/// buldu: `TEMPO_TOO_FAST_FOR_FORM` de yalnız `COMBINATION_END`de
/// değerlendiriliyor — aynı sınıf, önceden fark edilmemiş.
///
/// `boxing.foundations.one_two`nun canlı öğretme metni bu boşluğu
/// *"We watch the order and the timing between the two"* diye
/// anlatıyordu — **sevk edilmiş bir aşırı-iddia** (mağaza taslağındaki
/// aynı iddiadan daha ciddi, çünkü kullanıcı onu ZATEN görüyor).
/// Düzeltildi; bu kapı geri dönüşü engelliyor VE gelecekteki benzer
/// sapmaları — dördüncü tekrarı — isimlendirir.
///
/// ## Mekanik ölçüt
///
/// Bir hata kodu ULAŞILABİLİR ⟺ `evaluateAt` listesindeki değerlerden EN
/// AZ biri şu iki kaynaktan birinde gerçekten üretiliyor:
/// 1. Bir tekniğin (`techniques[].phases[].id`) gerçek faz kimliği —
///    motor bunları `_evaluateErrors(t, phaseId, …)` ile geçiş anında
///    dispatch eder.
/// 2. `striking_engine.dart`daki LİTERAL `_evaluateErrorsAtMarker('…')`
///    çağrı noktaları (`STANCE_SAMPLE`, `ANY`).
///
/// `FOOTWORK_STEP` bu iki kaynakta da YOK (yalnız `FEET_CROSSED`/
/// `BALANCE_LOSS`ın `evaluateAt` listesinde bir isim olarak duruyor) —
/// ama bu iki hata BAŞKA gerçek markerlar üzerinden zaten ulaşılabilir,
/// bu yüzden `FOOTWORK_STEP`in kendisinin ölü olması onları etkilemiyor.
/// Ölçüt bu yüzden "listede EN AZ bir gerçek marker var mı", "listedeki
/// HER marker gerçek mi" değil — ikincisi `FEET_CROSSED`i de yanlışlıkla
/// ölü sayardı.
void main() {
  final Map<String, dynamic> rules = (jsonDecode(
              File('../../assets/rulesets/boxing@1.0.0.json')
                  .readAsStringSync()) as Map)
      .cast<String, dynamic>();

  test('ULAŞILAMAZ hata kodu kümesi, ÖLÇÜLEN hâlle birebir aynı', () {
    final Set<String> phaseIds = <String>{};
    for (final dynamic t in rules['techniques'] as List<dynamic>) {
      for (final dynamic p in (t as Map)['phases'] as List<dynamic>) {
        phaseIds.add((p as Map)['id'] as String);
      }
    }
    // VAKUM MUHAFIZI — teknik fazları gerçekten okundu mu?
    expect(phaseIds, isNotEmpty,
        reason: 'hiçbir teknik fazı okunamadı — kapının sonucu anlamsız');

    final String engineSrc =
        File('lib/src/striking_engine.dart').readAsStringSync();
    final Set<String> literalMarkers = RegExp(
            r"_evaluateErrorsAtMarker\('([A-Z_]+)'")
        .allMatches(engineSrc)
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();
    expect(literalMarkers, isNotEmpty,
        reason: 'motorda hiçbir literal marker dispatch\'i bulunamadı — '
            'kaynak dosya taşınmış olabilir, kapının sonucu anlamsız');

    final Set<String> reachable = <String>{...phaseIds, ...literalMarkers};

    final List<String> unreachable = <String>[];
    int reachableCount = 0;
    for (final dynamic eRaw in rules['errors'] as List<dynamic>) {
      final Map<String, dynamic> e = (eRaw as Map).cast<String, dynamic>();
      final List<String> evalAt =
          (e['evaluateAt'] as List<dynamic>).cast<String>();
      if (evalAt.any(reachable.contains)) {
        reachableCount++;
      } else {
        unreachable.add(e['code'] as String);
      }
    }
    unreachable.sort();

    expect(reachableCount, greaterThan(0),
        reason: 'HİÇBİR hata kodu ulaşılabilir değil — dispatch mekanizması '
            'tamamen kopmuş olabilir, ki bu ayrı ve daha büyük bir kusurdur');

    final List<String> recorded =
        (rules[r'$unreachableErrorCodes'] as List<dynamic>).cast<String>()
          ..sort();

    expect(unreachable, recorded,
        reason: 'ULAŞILAMAZ hata kodu kümesi DEĞİŞTİ.\n'
            '  ölçülen : $unreachable\n'
            '  kayıtlı : $recorded\n\n'
            'KÜÇÜLDÜYSE: iyi haber — bir hata koduna gerçek bir dispatch '
            'noktası eklendi. `\$unreachableErrorCodes` listesini ve bu '
            'kodları anlatan içerik metinlerini (varsa) güncelle.\n'
            'BÜYÜDÜYSE: yeni bir hata kodu, motorun hiç dispatch etmediği '
            'bir markera bağlandı — o hata asla tetiklenmez. İçerik '
            'metinlerinde bu koda dayanan bir CANLI-mekanizma iddiası '
            'varsa (one_two J-162/163 sınıfı), o iddia da yanlış olur.');
  });
}
