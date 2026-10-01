import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// K8 BANT KAPISI — sevk edilmiş bir cümlenin koruması (J-134).
///
/// ## Neden: iddia doğru, koruma yok
///
/// `_HonestBands` kullanıcıya şunu söylüyor:
///
/// > *"Scores are unavailable because the thresholds have not been calibrated
/// > on real recordings. **A precise-looking number we cannot back up would be
/// > worse than no number.**"*
///
/// Ölçüldü: bugün doğru — iki çağrı yerinin ikisinde de değerler `—`.
/// Ama widget `Map<String, String>` alıyor ve **hiçbir şey oraya bir sayı
/// konmasını engellemiyor**. J-133'ün ölçütünü uyguladım: *bu cümleyi
/// yanlışa çevirecek en makul değişiklik ne?* — birinin hesaplanmış bir
/// değeri banda bağlaması (`'Guard': '72'`). Serbest bir `String` yuvası
/// için bu gayet makul.
///
/// ## Kural KOŞULLU — ve bu kasıtlı
///
/// Yasak mutlak değil: **`numericScoresUnlocked` false olduğu sürece**
/// geçerli. Kalibrasyon gerçekten yapılırsa sayı meşrulaşır ve kapı
/// **kendiliğinden** gevşer. Mutlak yazsaydım, doğru bir ilerleme bir gün
/// kırmızıya dönerdi ve kapı silinerek aşılırdı — J-120'de bir kez ödendi.
/// Kural, hükmü veren KONFIGÜRASYONA bağlı; kapı onun gölgesi.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * **Çalışma zamanında hesaplanan** bant değerleri — kaynak taraması
///   yalnız sabit haritaları görür. Sınıfı *ölçüm yöntemi*: kapatması
///   ekranı render edip değerleri okumak, ve bugün iki çağrı yerinin
///   ikisi de sabit olduğu için kovalanmadı.
/// * **Bandın DOĞRULUĞUNU** — `Wide`/`Even` gibi bir değerin gerçeği
///   yansıttığını değil, yalnız sayı OLMADIĞINI ölçüyor.
/// * **Sayının başka yollardan** yüzeye gelmesini (özet metni, replik).
void main() {
  test('K8 — kalibrasyon açılmadan bant değerinde SAYI yok', () {
    final Map<String, dynamic> rules =
        (jsonDecode(
                  File('assets/rulesets/boxing@1.0.0.json').readAsStringSync(),
                )
                as Map)
            .cast<String, dynamic>();
    final Map<String, dynamic> display = (rules['display'] as Map)
        .cast<String, dynamic>();
    final bool unlocked = display['numericScoresUnlocked'] as bool? ?? false;

    // Kuralın ÖNCÜLÜ: kalibrasyon kapalı. Açıldığı gün bu test kendi
    // gerekçesini kaybeder ve bunu SÖYLEMELİ — sessizce geçmemeli.
    expect(
      unlocked,
      isFalse,
      reason:
          'numericScoresUnlocked artık TRUE. Bu kapının öncülü '
          'düştü: sayı meşrulaştı. Kapıyı silmeden ÖNCE ekrandaki '
          '"Scores are unavailable" cümlesinin de '
          'güncellendiğini doğrula — cümle kalırsa o zaman yalan olur',
    );

    final List<String> offenders = <String>[];
    int literals = 0;
    for (final FileSystemEntity f in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String src = f.readAsStringSync();
      int i = src.indexOf('bands:');
      while (i >= 0) {
        final int open = src.indexOf('{', i);
        if (open < 0) break;
        int depth = 1;
        int j = open + 1;
        while (j < src.length && depth > 0) {
          if (src[j] == '{') depth++;
          if (src[j] == '}') depth--;
          j++;
        }
        final String body = src.substring(open + 1, j - 1);
        // Yalnız harita LİTERALİ sayılıyor; `bands: bands` gibi geçişler
        // bir değer taşımaz ve burada ölçülemez (bilinçli sınır).
        if (body.contains(':')) {
          literals++;
          for (final RegExpMatch m in RegExp(
            r"'([^']*)'\s*:\s*'([^']*)'",
          ).allMatches(body)) {
            final String value = m.group(2)!;
            if (RegExp(r'\d').hasMatch(value)) {
              offenders.add('${f.path}: "${m.group(1)}" → "$value"');
            }
          }
        }
        i = src.indexOf('bands:', j);
      }
    }

    // VAKUM KAPISI: hiç literal bulunmazsa kural boşa döner ve kapı yeşil
    // öter (aile dersi #4). İki çağrı yeri ölçüldü — biri kaybolursa da
    // haber vermeli.
    expect(
      literals,
      greaterThanOrEqualTo(2),
      reason:
          'bant haritası literali bulunamadı ($literals) — tarama '
          'kendi girdisini kaybetmiş olabilir ve kapı hiçbir şeye '
          'bakmadan geçiyor',
    );

    expect(
      offenders,
      isEmpty,
      reason:
          'BANT DEĞERİNDE SAYI var, ama ekran tam yanında '
          '"a precise-looking number we cannot back up would be worse '
          'than no number" diyor (J-134): ${offenders.join(" · ")}',
    );
  });
}
