import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SIRA JETONU YÜZEYE ÇIKMAZ (J-165).
///
/// ## Bu kapı da YANLIŞ SINIFLANDIRILMIŞ bir kör noktadan doğdu
///
/// J-150'de *yapısal vaat* sınıfını buldum (`NOT OPEN · W1` — numaralandırma
/// bir sıra, sıra bir vaat) ve **kapı kurmadım**: sınıfı `ölçüt yetersiz`
/// dedim, çünkü **genel** bir yapısal-vaat dedektörü ölçülemez.
///
/// Genel hâli için bu **doğru**. Ama J-164'ün dersi (*bazı şeyler imkânsız
/// değil, sadece fazla geniş tanımlanmış*) buraya da uyuyor: **dar hâli
/// ölçülebilir.**
///
/// Ölçüm: *"tek büyük harf + rakam"* jetonu (`W1` · `V2` · `P3`) tüm içerik
/// ve kullanıcı dizelerinde **yalnız 8 kez** geçiyor ve **hepsi `wave`** —
/// yani **sıfır yanlış pozitif.** Mevcut kod-biçimli metin kapısı bunları
/// **göremiyor**: deseni `^[A-Z][A-Z0-9_]{3,}$`, yani en az dört karakter
/// istiyor; `W1` iki.
///
/// ## Muafiyet ÖLÇÜME BAĞLI — liste değil
///
/// `wave` alanı içerikte **duruyor** (meşru iç planlama verisi) ama
/// **render edilmiyor** (J-150). Onu düz bir muafiyet listesine yazmak,
/// bu gece uyardığım tuzağı kurardı: *muafiyet listeleri ölü/canlı dalları
/// gizler*. Bunun yerine muafiyet **koşullu**: `wave` ancak **hiçbir
/// widget onu çizmiyorsa** affediliyor — çizmeye başlarsa kapı öter.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * **Genel** yapısal vaadi (sıralı liste, aşama adı, `Phase one`…) —
///   o hâlâ `ölçüt yetersiz` ve kör nokta olarak yazılı.
/// * Çalışma zamanında **birleştirilen** jetonu (`'W' + n`).
void main() {
  final RegExp token = RegExp(r'(?<![\w-])[A-Z]\d{1,2}(?![\w-])');

  test('içerikte sıra jetonu YOK — `wave` dışında, o da RENDER EDİLMİYOR', () {
    // Muafiyetin ÖLÇÜMÜ: hiçbir canlı widget `waveLabel` çizmiyor.
    final List<String> renders = <String>[];
    for (final FileSystemEntity f in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.contains('shell_candidate')) continue; // donmuş, ayrı borç
      // ⚠️ Kural MEKANİK olarak daraltıldı: ilk hâli `waveLabel`ı ANAN
      // her dosyayı işaretliyordu ve `content_repository.dart`ı yakaladı —
      // o bir VERİ EŞLEMESİ, render değil. Muafiyet LİSTESİ yazmak yerine
      // (bu gece uyardığım tuzak: muafiyet listeleri dalları gizler)
      // ölçüt mekanikleştirildi: **`flutter/material.dart` ithal eden
      // dosya = UI dosyası.** Eşleyici onu ithal etmiyor.
      final String src = f.readAsStringSync();
      if (!src.contains('package:flutter/material.dart')) continue;
      for (final String line in src.split('\n')) {
        final String t = line.trimLeft();
        if (t.startsWith('//')) continue;
        if (t.contains('waveLabel')) renders.add('${f.path}: $t');
      }
    }
    expect(
      renders,
      isEmpty,
      reason:
          '`wave` yüzeye çıkıyor — muafiyetin ÖNCÜLÜ düştü. `W1`→`W4` '
          'bir SIRA kurar ve sıra bir VAAT\'tir (J-150): '
          '${renders.join(" · ")}',
    );

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
          if (token.hasMatch(node)) hits.add('$file $path: "$node"');
        } else if (node is List) {
          for (int i = 0; i < node.length; i++) {
            walk(node[i], '$path[$i]');
          }
        } else if (node is Map) {
          node.forEach((Object? k, Object? v) {
            if (k is String && k.startsWith(r'$')) return;
            // `wave` MUAF — ama yukarıdaki ölçüm onu render edilmediği
            // için affetti; edilirse bu test zaten yukarıda kırmızıdır.
            if (k == 'wave') return;
            walk(v, '$path.$k');
          });
        }
      }

      walk(jsonDecode(File('assets/content/$file').readAsStringSync()), '');
    }
    expect(
      scanned,
      greaterThan(100),
      reason: 'yalnız $scanned dize tarandı — kapı girdisini bulamamış',
    );
    expect(
      hits,
      isEmpty,
      reason:
          'SIRA JETONU kullanıcı metninde: ${hits.join(" · ")}. '
          'Numaralandırma bir sıra kurar, sıra bir vaattir (J-165)',
    );
  });

  test('Dart kullanıcı dizelerinde sıra jetonu YOK', () {
    final RegExp str = RegExp(r"'((?:[^'\\\n]|\\.)*)'");
    // Muafiyet ÖLÇÜME BAĞLI (2026-10-26, JAB-03): satırın İLK öğesi olan ve
    // `:` ile biten dize bir map ANAHTARIDIR, kullanıcı metni değil. Ölçüldü:
    // karate/kickboks/Muay Thai parser'ları kaynak envanterini
    // (`'K11': 'https://…'`) böyle doğruluyor; bu kimlikler hiçbir widget'ta
    // çizilmiyor. Üçlü (`? 'x' : 'y'`) satır başında `?`/`:` taşıdığı için
    // bu kurala girmez; map DEĞERİ olan dize yine taranır.
    final RegExp mapKey = RegExp(r"^\s*'((?:[^'\\\n]|\\.)*)'\s*:");
    final List<String> hits = <String>[];
    for (final FileSystemEntity f in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.contains('shell_candidate')) continue;
      for (final String line in f.readAsStringSync().split('\n')) {
        final String t = line.trimLeft();
        if (t.startsWith('//')) continue;
        final RegExpMatch? key = mapKey.firstMatch(line);
        for (final RegExpMatch m in str.allMatches(line)) {
          if (key != null && m.start == key.start + key[0]!.indexOf("'")) {
            continue;
          }
          final String s = m.group(1)!;
          if (token.hasMatch(s)) hits.add('${f.path}: "$s"');
        }
      }
    }
    expect(
      hits,
      isEmpty,
      reason: 'SIRA JETONU Dart dizesinde: ${hits.join(" · ")}',
    );
  });
}
