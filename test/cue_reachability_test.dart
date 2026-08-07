import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// REPLİK ULAŞILABİLİRLİĞİ — İÇERİK düzeyinde (J-162).
///
/// ## J-158'in matrisi GRUP düzeyindeydi
///
/// J-158 *ders × replik-grubu* matrisini çıkardı ve temiz buldu: `technique`
/// grubu **ateşlenebilir**, çünkü kameralı bir ders var. Ama **grup
/// ateşlenebilir olması, her repliğinin ateşlenebilir olması değil.**
///
/// Ölçüm: `cue.combo_order` ve `cue.wrong_hand` **`COMBINATION_END`**'de
/// değerlendiriliyor ve **hiçbir AÇIK derste kamera + kombinasyon bir arada
/// yok** — yedi kombinasyonlu ders var, hepsi kamerasız; tek kameralı ders
/// (`boxing.foundations.jab`) tek teknikli.
///
/// Ve bunun kullanıcı-görünür bedeli vardı: disiplin vaadi *"Your corner
/// calls out guard, stance, **sequence** and balance"* diyordu — vaat
/// edilen dört şeyin **biri teslim edilemiyordu**.
///
/// ## Bu kapı NE yapar
///
/// Kombinasyon-bağımlı replikler için **içerikten** ulaşılabilirlik
/// hesaplar. Ulaşılamazsa: ya bir ders kamera+kombinasyon taşımalı, ya
/// durum **beyan edilmeli** (`$producers` → `awaiting-content`). Sessiz
/// kalmak seçenek değil.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Diğer replikleri — yalnız **kombinasyon** bağımlılığını. Başka bir
///   çapraz-koşul (örn. belirli bir teknik gerektiren replik) çıkarsa bu
///   kapı onu görmez ve **genişletilmeli**.
/// * Çalışma-zamanı ulaşılabilirliğini — motorun o kombinasyonu gerçekten
///   tanıyıp tanımadığını (`live_jab_path_test`in işi).
void main() {
  final Map<String, dynamic> lib = (jsonDecode(
          File('assets/content/library.json').readAsStringSync()) as Map)
      .cast<String, dynamic>();
  final Map<String, dynamic> rules = (jsonDecode(
          File('assets/rulesets/boxing@1.0.0.json').readAsStringSync()) as Map)
      .cast<String, dynamic>();
  final Map<String, dynamic> cues = (jsonDecode(
          File('assets/content/cues.en.json').readAsStringSync()) as Map)
      .cast<String, dynamic>();

  List<Map<dynamic, dynamic>> openLessons() {
    final List<Map<dynamic, dynamic>> out = <Map<dynamic, dynamic>>[];
    for (final dynamic d in lib['disciplines'] as List<dynamic>) {
      for (final dynamic c
          in ((d as Map)['courses'] as List<dynamic>? ?? const <dynamic>[])) {
        for (final dynamic l
            in ((c as Map)['lessons'] as List<dynamic>? ?? const <dynamic>[])) {
          if ((l as Map)['status'] == 'locked') continue;
          out.add(l);
        }
      }
    }
    return out;
  }

  test('KOMBİNASYON replikleri ya ULAŞILABİLİR ya BEYANLI', () {
    final List<Map<dynamic, dynamic>> lessons = openLessons();
    expect(lessons.length, greaterThan(5),
        reason: 'açık ders bulunamadı — kapı vakum-doğru olurdu');

    final bool reachable = lessons.any((Map<dynamic, dynamic> l) =>
        (l['usesCamera'] as bool? ?? false) &&
        ((l['combinations'] as List<dynamic>?) ?? const <dynamic>[]).isNotEmpty);

    final List<String> comboCues = <String>[
      for (final dynamic e in rules['errors'] as List<dynamic>)
        if (((e as Map)['code'] as String).contains('COMBINATION'))
          e['feedbackKey'] as String,
    ];
    // VAKUM KAPISI: kombinasyon repliği hiç bulunmazsa kural boşa döner.
    expect(comboCues.length, greaterThanOrEqualTo(2),
        reason: 'kombinasyon repliği bulunamadı (${comboCues.length}) — '
            'kural setinin şekli değişmiş olabilir');

    if (reachable) return; // ulaşılabiliyorsa beyan gerekmez

    final String declared =
        jsonEncode((cues[r'$producers'] as Map)['technique']);
    expect(declared, contains('awaiting-content'),
        reason: 'KOMBİNASYON REPLİKLERİ ULAŞILAMAZ ($comboCues) ve durum '
            'BEYAN EDİLMEMİŞ. Hiçbir açık derste kamera+kombinasyon bir '
            'arada yok. Ya bir ders ikisini taşımalı, ya `\$producers` '
            'bunu söylemeli — sessizlik seçenek değil (J-162)');
    for (final String cue in comboCues) {
      expect(declared, contains(cue.split('.').last),
          reason: '$cue beyanda ADIYLA geçmiyor — "bir şeyler ulaşılamaz" '
              'demek, hangisinin ulaşılamaz olduğunu söylemez');
    }
  });

  test('NEGATİF İKİZ — disiplin vaadi ULAŞILAMAZ bir şeyi söz vermiyor', () {
    // Beyan etmek yetmez: kullanıcıya verilen söz de gerçeğe uymalı.
    // Eski vaat *"guard, stance, SEQUENCE and balance"* diyordu ve dizi
    // koçluğu teslim edilemiyordu.
    final Map<dynamic, dynamic> boxing =
        (lib['disciplines'] as List<dynamic>).firstWhere(
            (dynamic d) => (d as Map)['id'] == 'boxing') as Map<dynamic, dynamic>;
    final String blurb = (boxing['blurb'] as String).toLowerCase();
    final List<Map<dynamic, dynamic>> lessons = openLessons();
    final bool reachable = lessons.any((Map<dynamic, dynamic> l) =>
        (l['usesCamera'] as bool? ?? false) &&
        ((l['combinations'] as List<dynamic>?) ?? const <dynamic>[]).isNotEmpty);
    if (reachable) return;
    for (final String w in <String>['sequence', 'combination', 'combo']) {
      expect(blurb.contains(w), isFalse,
          reason: 'disiplin vaadi "$w" diyor ama kombinasyon koçluğu '
              'hiçbir açık derste ULAŞILAMAZ (J-162)');
    }
  });
}
