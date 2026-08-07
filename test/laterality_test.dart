import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TARAFLILIK KAPISI — `left`/`right` bir VÜCUT TARAFI olarak kullanılamaz
/// (J-142).
///
/// ## Bu bir üslup değil DOĞRULUK kuralı
///
/// Bulunan ihlal canlı bir koçluk repliğiydi: **`"Right hand home."`**
/// (`cue.rear_hand_low`). Southpaw duruşlu bir kullanıcıda **arka el SOL
/// eldir** — yani replik yanlış eli söylüyordu. Kamera duruşu okuyor ama
/// kullanıcının hangi elini "sağ" saydığını bilmiyor; `lead`/`rear` duruşa
/// GÖRE tanımlıdır ve **her iki duruşta da doğrudur**.
///
/// İkinci ihlal `curriculum.json`daki bir drill talimatındaydı
/// (*"Right order, right hand, every time"*). O dosyanın tüketicisi bugün
/// testler (J-129'da ölçüldü), yani sızıntı kullanıcıya **ulaşmıyordu** —
/// drill'ler bağlandığı gün ulaşırdı. Sınıf: **gizli**, ama kapıda.
///
/// Kural gecenin brief'inde yazılıydı (*"sol/sağ denmez → lead/rear hand"*)
/// ve **hiçbir kapı zorlamıyordu** — J-133 ölçütünün ta kendisi: sevk
/// edilmiş bir sınır, korumasız.
///
/// ## Neden VÜCUT SÖZCÜĞÜNE bakıyor, `left`/`right`e değil
///
/// Düz bir yasak yanlış olurdu ve ölçüldü: *"Ten **left**."* · *"Camera
/// preview is **left** out on purpose"* · *"Where you **left** off"* ·
/// *"the **right** move"* · *"**right** now" · "**Correct** order"* —
/// hepsi doğru İngilizce ve hiçbiri taraf belirtmiyor. **Aynı sözcük, zıt
/// sınıflar** (`will` ve `gate` ölçümlerinden sonra dördüncü kez): kapı
/// sözcüğe değil **kullanıma** bakmalı.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Vücut sözcüğü **yakınında olmayan** taraf atfını (*"lead with the
///   right"*) — liste genişletilebilir, bugün örneği yok.
/// * `lead`/`rear` kullanımının **doğruluğunu** — yalnız `left`/`right`
///   yokluğunu ölçüyor; `lead` yazıp `rear` kastetmek bu kapıdan geçer.
/// * Dart tarafındaki dizeleri — ölçüldü, bugün ihlal yok; içerik katmanı
///   asıl risk çünkü replikler orada yazılıyor.
void main() {
  const List<String> bodyWords = <String>[
    'hand', 'hands', 'foot', 'feet', 'arm', 'arms', 'leg', 'legs',
    'shoulder', 'shoulders', 'hip', 'hips', 'elbow', 'elbows',
    'knee', 'knees', 'fist', 'side', 'eye', 'ear', 'jab', 'cross', 'hook',
  ];
  // `left`/`right` ile vücut sözcüğü arasında en fazla bir kelime
  // (`the`, `your`) — "right hand", "right rear hand", "left elbow".
  final RegExp laterality = RegExp(
      r'\b(left|right)\b(\s+\w+)?\s+(' + bodyWords.join('|') + r')\b',
      caseSensitive: false);

  test('içerik dosyalarında TARAF atfı yok — lead/rear kullanılıyor', () {
    final List<String> hits = <String>[];
    int scanned = 0;
    for (final String file in <String>[
      'cues.en.json',
      'library.json',
      'curriculum.json',
    ]) {
      void walk(Object? node, String path) {
        if (node is String) {
          scanned++;
          if (laterality.hasMatch(node)) {
            hits.add('$file $path: "$node"');
          }
        } else if (node is List) {
          for (int i = 0; i < node.length; i++) {
            walk(node[i], '$path[$i]');
          }
        } else if (node is Map) {
          node.forEach((Object? k, Object? v) {
            // `$` notları geliştiriciye yazılır ve bu kuralı ANLATIRKEN
            // yasak biçimi alıntılamak zorundadır.
            if (k is String && k.startsWith(r'$')) return;
            walk(v, '$path.$k');
          });
        }
      }

      walk(jsonDecode(File('assets/content/$file').readAsStringSync()), '');
    }

    // VAKUM KAPISI: hiç dize taranmadıysa kural boşa döner.
    expect(scanned, greaterThan(100),
        reason: 'yalnız $scanned dize tarandı — tarama girdisini bulamamış '
            'olabilir ve kapı hiçbir şeye bakmıyor');

    expect(hits, isEmpty,
        reason: 'TARAF ATFI: `left`/`right` bir vücut tarafını gösteriyor. '
            'Southpaw duruşta arka el SOL eldir — bu bir üslup değil '
            'DOĞRULUK hatası. `lead`/`rear` duruşa göre tanımlıdır ve her '
            'iki duruşta da doğrudur (J-142): ${hits.join(" · ")}');
  });

  test('NEGATİF İKİZ — masum `left`/`right` kullanımları hâlâ geçiyor', () {
    // Düz bir yasak, bu cümleleri de öldürürdü. Kapı sözcüğe değil
    // KULLANIMA baktığı için ikisi bir arada yaşayabiliyor. Bu ikiz
    // olmadan bir sonraki tur kuralı "left/right yasak" diye
    // basitleştirip doğru İngilizceyi kırabilirdi.
    for (final String innocent in <String>[
      'Ten left.',
      'Where you left off',
      'Camera preview is left out on purpose',
      'we cannot tell you whether it was the right move',
      'we simply cannot open the file right now',
    ]) {
      expect(laterality.hasMatch(innocent), isFalse,
          reason: 'kapı masum bir cümleyi yakaladı — fazla genişlemiş: '
              '"$innocent"');
    }
    // Ve gerçekten ihlal olanı YAKALIYOR (kapının çalıştığının kanıtı,
    // yoksa yukarıdaki "hepsi geçti" sonucu bir şey kanıtlamaz).
    for (final String violation in <String>[
      'Right hand home.',
      'Keep your left elbow in.',
      'Right order, right hand, every time.',
    ]) {
      expect(laterality.hasMatch(violation), isTrue,
          reason: 'kapı gerçek bir ihlali kaçırıyor: "$violation"');
    }
  });
}
