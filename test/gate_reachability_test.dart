import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// İLERLEME KAPILARININ ULAŞILABİLİRLİĞİ — ölçülmüş hâl çivilendi (J-197).
///
/// ## ✅ ÇÖZÜLDÜ — 2026-08-11 (ADR-005)
///
/// ~~Müfredatın 15 kapısından 12'si bugün sağlanamaz. Sebep tek ve yapısal:
/// kapıların tamamı tespit istiyor, tespit kamera demek, ve o 12 dersin
/// `usesCamera` alanı false.~~ Eski cümlenin üstü çizildi, silinmedi — neyin
/// yanlış olduğunu göstermek öğretici.
///
/// Koordinatör hükmü (2026-08-11 22:44): **`$cameraBasis` kararı cihaz
/// turuna bağlı değil** — cihaz turu köprünün ÇALIŞTIĞINI kanıtlar,
/// `$cameraBasis` bir dersin kamerayı GEREKTİRDİĞİNİ beyan eder, ikisi ayrı
/// eksen (`docs/adr/ADR-005-camera-basis-politikasi.md`). 12 dersin hepsine
/// `usesCamera:true` + gerekçeli `$cameraBasis` eklendi. Unreachable küme
/// şimdi **boş**.
///
/// > En çarpıcı kanıt hâlâ kayıtta: **`camera` dersinin kapısı
/// > `setupCheckPassed` istiyordu — ve o ders kamerayı AÇMIYORDU.** Artık
/// > açıyor; ama `setupCheckPassed` olayının kendisi motor kodunda hâlâ
/// > **hiçbir yerde üretilmiyor** — bu NAMED açık kalem, ADR-005'te
/// > kaydedildi, gizlenmedi (ikincisi: `stanceHold`, aynı sınıf).
///
/// ## Neden BUGÜN düzeltildi
///
/// Önceki koordinatör hükmü (14:35, 2026-08-07): kapsam 5 dersten 12 derse
/// + müfredata büyüdüğü için karar bir ders kararı değil ürün mimarisi
/// kararıydı ve o gün ertelendi. Dört gün sonra (2026-08-11) aynı
/// koordinatör kararı verdi: beş kurucu-kapılı kalemden (harcama/store/
/// fiyat/lisans/tasarım) hiçbiri değil, içerik-doğruluğu sorusu.
/// **Zarar hâlâ latent:** `curriculum.json`u uygulama hâlâ yüklemiyor
/// (J-179) — bu ADR onu değiştirmedi, yalnız kamera-temelini düzeltti.
///
/// > **Bir kusuru kaydetmek, yarım düzeltmekten iyidir.** — ve bir kusuru
/// > ÇÖZERKEN bulunan yeni, daha dar kusurları da kaydetmek aynı kural.
///
/// ## Bu kapı İYİ HABERİ de söyler
///
/// Liste **küçüldüğü** an test öter ve *"bir kapı ulaşılabilir oldu, kaydı
/// güncelle"* der. **Büyüdüğü** an da öter — yeni bir kamerasız ders
/// yazıldı demektir ve o, **13. ulaşılamaz kapıyı** eklemiş olur.
void main() {
  test('ULAŞILAMAZ kapı kümesi, ÖLÇÜLEN hâlle birebir aynı', () {
    final Map<String, dynamic> cur =
        (jsonDecode(File('assets/content/curriculum.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();
    final Map<String, dynamic> lib =
        (jsonDecode(File('assets/content/library.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();

    final Map<String, Map<String, dynamic>> lessons =
        <String, Map<String, dynamic>>{};
    for (final dynamic c in (lib['disciplines'] as List<dynamic>).firstWhere(
        (dynamic d) => (d as Map)['id'] == 'boxing')['courses'] as List<dynamic>) {
      for (final dynamic l in (c as Map)['lessons'] as List<dynamic>) {
        final Map<String, dynamic> m = (l as Map).cast<String, dynamic>();
        lessons['${m['id']}'] = m;
      }
    }

    final Map<String, dynamic> progression =
        (cur['progression'] as Map).cast<String, dynamic>();

    // VAKUM MUHAFIZI — müfredat gerçekten okundu mu? Boş bir harita
    // "ulaşılamaz kapı yok" diye okunur ve bu kayıt sessizce ölür.
    expect(progression.length, greaterThanOrEqualTo(10),
        reason: 'yalnız ${progression.length} ilerleme kaydı okundu — '
            'gezinme bozuk, bu kapının sonucu anlamsız');

    final List<String> unreachable = <String>[];
    int reachable = 0;
    for (final MapEntry<String, dynamic> e in progression.entries) {
      final Map<String, dynamic> pr = (e.value as Map).cast<String, dynamic>();
      final Map<String, dynamic>? l = lessons[e.key];
      if (l == null || l['lockedBy'] != null) continue;
      if ((pr['gates'] as List<dynamic>?)?.isEmpty ?? true) continue;
      // Kendini ETKİSİZ beyan eden kapı bu sayıma girmez — o zaten dürüst.
      if (pr[r'$blocked'] != null) continue;
      if (l['usesCamera'] == true) {
        reachable++;
      } else {
        unreachable.add(e.key);
      }
    }
    unreachable.sort();

    expect(reachable, greaterThan(0),
        reason: 'HİÇBİR kapı ulaşılabilir değil — kamera hattı tamamen '
            'kapanmış olabilir, ki bu ayrı ve daha büyük bir kusurdur');

    final List<String> recorded =
        (cur[r'$gateReachabilityUnreachable'] as List<dynamic>).cast<String>()
          ..sort();

    expect(unreachable, recorded,
        reason: 'ULAŞILAMAZ kapı kümesi DEĞİŞTİ.\n'
            '  ölçülen : $unreachable\n'
            '  kayıtlı : $recorded\n\n'
            'KÜÇÜLDÜYSE: iyi haber — bir ders kamerayı açtı ya da kapısı '
            'düzeltildi. `\$gateReachabilityUnreachable` listesini ve '
            '`\$gateReachability` beyanını güncelle.\n'
            'BÜYÜDÜYSE: yeni bir KAMERASIZ ders yazıldı ve o ders '
            'ULAŞILAMAZ bir kapı taşıyor — kullanıcı onu asla geçemez. '
            'J-197: içerik yazmak, kapıların ULAŞILABİLİRLİĞİNİ de sınar.');
  });
}
