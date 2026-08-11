import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// KAPI-PRİMİTİFİNİN ÜRETİCİSİ VAR MI — `gate_reachability_test`in
/// bıraktığı boşluğu kapatır (koordinatör hükmü, 2026-08-11).
///
/// ## İki ayrı soru, iki ayrı kapı
///
/// `gate_reachability_test` tek soruyu ölçer: *bu dersin kapısı ait olduğu
/// dersin kamerayı açmasına mı bağlı?* — `usesCamera` alanı, CONFIG
/// katmanı. ADR-005 sonrası bu soru 15/15 EVET diyor.
///
/// Bu dosya AYRI bir soruyu ölçer: *kapının beklediği OLAYIN kendisini
/// üreten bir mekanizma var mı?* — MOTOR katmanı. Kamera açık olması,
/// olayın üretileceğini GARANTİ ETMEZ: `boxing.foundations.camera`
/// (`setupCheckPassed`) ve `boxing.foundations.stance` (`stanceHold`)
/// ikisi de kamerayı açıyor (`usesCamera:true`, ADR-005) ama bu iki olay
/// adı motorun tanıdığı hiçbir teknik ya da kombinasyonla eşleşmiyor.
///
/// > **Ulaşılamazlık yok olmadı; CONFIG katmanından MOTOR katmanına
/// > taşındı.** Önceki hâlde (J-197) 12 kapı adıyla kayıtlıydı — gürültülü
/// > ve dürüst bir artefakt. `$gateReachabilityUnreachable` 0'a düşünce bu
/// > iki kapı SESSİZLEŞTİ; doğru ama sessiz. Bu dosya sesi geri veriyor.
///
/// ## Mekanik ölçüt
///
/// `curriculum.json`daki her `event`/`combination` primitifi,
/// `boxing@1.0.0.json`ın kendi `techniques[].id` ∪ `combinations[].id`
/// kümesiyle karşılaştırılır — motorun jenerik faz-tamamlama/kombinasyon
/// mekanizması YALNIZ bu kümedeki kimlikler için olay üretir (ADR-004:
/// motor branş-bağımsız, "jab" gibi isimler Dart kodunda sabit değil,
/// config'ten TÜRÜYOR). Kümede olmayan bir primitif adı, üretici olmayan
/// bir primitiftir. `sessionMinutes`/`withValidAnalysisRatio` tabanlı
/// kapılar (9 ders) bu ölçütün DIŞINDA — ayrı bir primitif sınıfı
/// (oturum-seviyesi analiz oranı, `judgedRatio`nun karşılığı, ADR-005 §
/// pil/ısı) ve bu turda ayrı bir soru.
///
/// ## Bu turda BİLEREK yazılmayan şey
///
/// `setupCheckPassed`/`stanceHold` üreticisi BU TESTLE yazılmaz — yeni
/// motor yüzeyi açmak (yeni event tipi, yeni faz makinesi) kapsam dışı
/// bırakıldı (koordinatör: "istediğim üretmek değil, yokluğun eski liste
/// kadar yüksek sesle durması"). `one_two`nun `combination:"1-2"`si burada
/// ÜRETİCİLİ sayılır (mekanik ölçüt: '1-2' `combinations[]`de var) — ama
/// J-162/163'ün COMBINATION_END'in motorda gerçekten geçip geçmediği
/// sorusu AYRI ve bu testle sınanmıyor, adıyla açık kalıyor.
///
/// ## İYİ / KÖTÜ HABER — gate_reachability_test'in aynı deseni
///
/// Liste küçülürse test öter: bir primitif üretilir oldu, kaydı güncelle.
/// Büyürse test öter: yeni bir kapı üreticisi olmayan bir primitife
/// bağlandı — içerik yazmak burada da ULAŞILABİLİRLİĞİ sınar.
void main() {
  test('ÜRETİCİSİZ kapı primitifleri, ÖLÇÜLEN hâlle birebir aynı', () {
    final Map<String, dynamic> cur =
        (jsonDecode(File('assets/content/curriculum.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();
    final Map<String, dynamic> rules = (jsonDecode(
            File('assets/rulesets/boxing@1.0.0.json').readAsStringSync())
        as Map)
        .cast<String, dynamic>();

    final Set<String> techniqueIds = (rules['techniques'] as List<dynamic>)
        .map((dynamic t) => (t as Map)['id'] as String)
        .toSet();
    final Set<String> combinationIds = (rules['combinations'] as List<dynamic>)
        .map((dynamic c) => (c as Map)['id'] as String)
        .toSet();

    // VAKUM MUHAFIZI — ruleset gerçekten okundu mu? Boş kümeler "her şey
    // üreticisiz" ya da tersini sessizce iddia eder.
    expect(techniqueIds, isNotEmpty,
        reason: 'ruleset teknik listesi boş okundu — bu kapının sonucu '
            'anlamsız');
    expect(combinationIds, isNotEmpty,
        reason: 'ruleset kombinasyon listesi boş okundu — bu kapının '
            'sonucu anlamsız');

    final Map<String, dynamic> progression =
        (cur['progression'] as Map).cast<String, dynamic>();
    expect(progression.length, greaterThanOrEqualTo(10),
        reason: 'yalnız ${progression.length} ilerleme kaydı okundu — '
            'gezinme bozuk, bu kapının sonucu anlamsız');

    final Set<String> missingProducer = <String>{};
    int withProducer = 0;
    for (final MapEntry<String, dynamic> e in progression.entries) {
      final Map<String, dynamic> pr = (e.value as Map).cast<String, dynamic>();
      if (pr[r'$blocked'] != null) continue;
      for (final dynamic gRaw in (pr['gates'] as List<dynamic>? ?? const <dynamic>[])) {
        final Map<String, dynamic> g = (gRaw as Map).cast<String, dynamic>();
        final String? event = g['event'] as String?;
        final String? combination = g['combination'] as String?;
        if (event != null) {
          if (techniqueIds.contains(event)) {
            withProducer++;
          } else {
            missingProducer.add(event);
          }
        } else if (combination != null) {
          if (combinationIds.contains(combination)) {
            withProducer++;
          } else {
            missingProducer.add(combination);
          }
        }
        // sessionMinutes/withValidAnalysisRatio: ayrı primitif sınıfı,
        // bu ölçütün dışında (yukarıdaki doc'a bak).
      }
    }

    expect(withProducer, greaterThan(0),
        reason: 'HİÇBİR event/combination primitifi üretici bulamadı — '
            'ruleset okunuşu ya da eşleme mantığı bozulmuş olabilir, ki bu '
            'ayrı ve daha büyük bir kusurdur');

    final List<String> missing = missingProducer.toList()..sort();
    final List<String> recorded =
        (cur[r'$gatePrimitivesWithoutProducer'] as List<dynamic>)
            .cast<String>()
          ..sort();

    expect(missing, recorded,
        reason: 'ÜRETİCİSİZ primitif kümesi DEĞİŞTİ.\n'
            '  ölçülen : $missing\n'
            '  kayıtlı : $recorded\n\n'
            'KÜÇÜLDÜYSE: iyi haber — bir primitif üretilir oldu (motora yeni '
            'olay/faz eklendi). `\$gatePrimitivesWithoutProducer` listesini '
            've `\$gateReachability` beyanını güncelle.\n'
            'BÜYÜDÜYSE: yeni bir kapı, motorun tanımadığı bir olay/'
            'kombinasyon adına bağlandı — o kapı kamera açık olsa bile asla '
            'geçilemez. Olayı ya motora ekle ya da kapıyı isimli sebeple '
            'kilitle.');
  });
}
