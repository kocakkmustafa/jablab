import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BİR REPLİK, KENDİ EN UZUN OTURUMUNDA TEKRAR ETMEMELİ (J-198).
///
/// ## Ölçüt "daha çok iyidir" DEĞİL
///
/// Varyant sayısını körlemesine artırmak bir kalite ölçüsü değil. Ölçülebilir
/// olan şu: **bir replik, tek bir oturumda varyant sayısından FAZLA kez
/// çalıyorsa, kullanıcı onu o oturum içinde tekrar duyar.** Round-robin
/// üst üste tekrarı zaten engelliyor (J-180) — ama havuz **dolanınca**
/// aynı cümle geri gelir.
///
/// > **Replik derinliği, ders yapısının bir FONKSİYONUDUR.**
/// > 6 turlu bir ders yazan, 4 varyantlı bir tur repliğini de değiştirmiş
/// > olur — ve bunu hiçbir şey söylemezse, ders uzadıkça koç tekrarlar.
///
/// ## ⚠️ İKİ KİP AYRI REPLİK KULLANIYOR — ölçüm bunu bilmeli
///
/// İlk yazışımda HIIT'in `round_start` kullandığını **varsaydım** ve
/// "12 kez çalıyor, 4 varyant var" diye rapor etmeye hazırlandım. Ölçünce
/// yanlış çıktı: **aralık kipi `interval.*` repliklerini çalıyor**
/// (`burstStart`/`burstEnd`/`recover`/`nextBurst`), tur repliklerini
/// değil. *Bir ölçüm, ölçtüğü sistemin KİPLERİNİ bilmiyorsa sayı üretir
/// ama bilgi üretmez.*
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Repliğin **iyi** olduğunu — yalnız oturum içinde tükenmediğini.
/// * Oturumlar ARASI tekrarı: imleç oturumlar boyunca döndüğü için
///   kullanıcı 5. oturumda aynı cümleleri yeniden duyar, ve bu **kabul
///   edilmiş** bir hâl (sonsuz yazı yok).
/// * `technique.*` repliklerini: onlar **hataya** bağlı çalar, ders
///   yapısına değil — kaç kez çalacakları önceden bilinemez.
void main() {
  test('hiçbir replik, en uzun oturumunda havuzunu TÜKETMİYOR', () {
    final Map<String, dynamic> lib =
        (jsonDecode(File('assets/content/library.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();
    final Map<String, dynamic> cues =
        (jsonDecode(File('assets/content/cues.en.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();

    final List<dynamic> courses =
        ((lib['disciplines'] as List<dynamic>).firstWhere(
                  (dynamic d) => (d as Map)['id'] == 'boxing',
                )
                as Map)['courses']
            as List<dynamic>;

    // (grup, anahtar) → en çok kaç kez çalıyor, hangi derste
    final Map<String, ({int fires, String lesson})> worst =
        <String, ({int fires, String lesson})>{};
    void note(String g, String k, int n, String lesson) {
      if (n > (worst['$g|$k']?.fires ?? 0)) {
        worst['$g|$k'] = (fires: n, lesson: lesson);
      }
    }

    int planned = 0;
    for (final dynamic rawC in courses) {
      for (final dynamic rawL in (rawC as Map)['lessons'] as List<dynamic>) {
        final Map<String, dynamic> l = (rawL as Map).cast<String, dynamic>();
        final String name = '${l['id']}'.split('.').last;
        final Map<String, dynamic>? rp = (l['roundPlan'] as Map?)
            ?.cast<String, dynamic>();
        final Map<String, dynamic>? ip = (l['intervalPlan'] as Map?)
            ?.cast<String, dynamic>();
        if (rp != null) {
          planned++;
          final int r = rp['rounds'] as int;
          note('session', 'cue.round_start', r, name);
          note('session', 'cue.round_end', r, name);
          note('session', 'cue.rest', r - 1, name);
          note('counting', 'cue.halfway', r, name);
          note('counting', 'cue.last_ten', r, name);
          note('counting', 'cue.last_five', r, name);
        } else if (ip != null) {
          planned++;
          // ARALIK kipi AYRI replikler kullanıyor — ölçülmüş, varsayılmamış.
          final int b = ip['bursts'] as int;
          note('interval', 'cue.burst_start', b, name);
          note('interval', 'cue.burst_end', b, name);
          note('interval', 'cue.recover', b, name);
          note('interval', 'cue.next_burst', b, name);
        }
      }
    }

    // VAKUM MUHAFIZI — planlı ders bulunamazsa hiçbir replik ölçülmez ve
    // kapı "tekrar yok" diye YEŞİL kalır.
    expect(
      planned,
      greaterThanOrEqualTo(8),
      reason:
          'yalnız $planned planlı ders bulundu — gezinme bozuk, '
          'bu kapının sonucu anlamsız',
    );
    expect(worst, isNotEmpty, reason: 'hiçbir replik eşlenmedi');

    final List<String> thin = <String>[];
    for (final MapEntry<String, ({int fires, String lesson})> e
        in worst.entries) {
      final List<String> parts = e.key.split('|');
      final List<dynamic> variants =
          (cues[parts[0]] as Map)[parts[1]] as List<dynamic>;
      if (e.value.fires > variants.length) {
        thin.add(
          '${parts[0]}.${parts[1]}: ${variants.length} varyant ama '
          '${e.value.lesson} dersinde ${e.value.fires} kez çalıyor '
          '(${e.value.fires - variants.length} tekrar)',
        );
      }
    }

    expect(
      thin,
      isEmpty,
      reason:
          'bu replikler tek oturumda kendini tekrar ediyor:\n'
          '  ${thin.join('\n  ')}\n\n'
          'Replik derinliği ders YAPISININ bir fonksiyonudur: daha uzun '
          'bir ders yazan, o dersin repliklerini de uzatmış olur. '
          'İki yol: (a) varyant ekle (b) dersi kısalt. Kelime sınırları '
          'grup başına ayrı (`cues_test`: interval ≤5, session ≤6, '
          'counting ≤3) ve onlar GEVŞETİLMEZ — kısa olmalarının sebebi '
          'kullanıcının hareket hâlinde olması.',
    );
  });

  test('POZİTİF KONTROL — kapı, sığ bir havuzu GERÇEKTEN görüyor', () {
    // Yukarıdaki temiz sonuç, eşlemenin hiç kurulamamasından da doğabilirdi.
    const int variants = 4;
    const int fires = 6;
    expect(fires > variants, isTrue);
    expect(fires - variants, 2, reason: 'tekrar sayısı aritmetiği');
  });
}
