import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/live_honesty.dart';
import 'package:jablab/app/skeleton_overlay.dart';
import 'package:jablab/shell_candidate/live_surface.dart' show LiveState;

/// PLACEHOLDER'IN **KULLANICI** KATMANI — kayıt kapısı bunu görmüyor (J-224).
///
/// ## Ölçülen zayıflık, ve nerede bulundu
///
/// Lissom kendi ağacında ölçtü: `PLACEHOLDER` işaretçisini ekleyip **karta
/// dokunmadan sildi** → kapı **yeşil kaldı.** Sebep, bizde de aynı:
/// `tool/gen_placeholder_register.dart` **kaynak işaretçisinin BİÇİMİNİ**
/// denetliyor (`unblocked by:` var mı) — **kullanıcıya ulaşan cümleyi
/// değil.**
///
/// **JabLab'da aynı ölçüm koşuldu (2026-08-12) ve zayıflık DOĞRULANDI:**
/// `PLACEHOLDER(asset)` işaretçisi yerinde bırakılıp ekrandaki cümle boş
/// dizgeye çevrildi →
/// * `gen_placeholder_register.dart` → **exit 0**
/// * tam süit → **323/323, sıfır düşen**
///
/// Yani dürüstlük beyanı **kullanıcı için sessizleşebiliyor**, ve kayıt onu
/// hâlâ *"beyanlı"* diye listeliyor olurdu.
///
/// > ***Kaynakta beyanlı olmak, KULLANICIYA beyanlı olmak değildir — iki
/// > ayrı yüzey, iki ayrı kapı.***
///
/// Bu, bu turun tekrar eden dersinin bir biçimi daha: *bir kapının
/// doğrulayabildiği şey, kapının GÖRDÜĞÜ KATMANLA sınırlıdır.* Kayıt
/// katmanı ile ekran katmanı **ayrı ölçülmedikçe** biri ötekini garanti
/// etmiyor.
///
/// ## NE ÖLÇMÜYOR
///
/// Cümlenin **okunabilir** olduğunu (kontrast/örtüşme) — o ayrı bir kapı
/// (J-116/J-117 scrim ölçümü, sınıf dokümanında). Burada sınanan: cümle
/// **var mı**, **sorumluluğu üstleniyor mu**, ve **tarih vermiyor mu.**
void main() {
  Future<void> pumpPlaceholder(WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 375,
          height: 500,
          child: SkeletonPreview(
            state: LiveState.clean,
            bucket: LiveHonestyBucket.ours,
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('KULLANICI KATMANI — yokluk cümlesi EKRANDA ve DOLU',
      (WidgetTester t) async {
    await pumpPlaceholder(t);
    final Finder card = find.byKey(const Key('camera-preview-placeholder'));
    expect(card, findsOneWidget,
        reason: 'kamera-yokluğu cümlesi ekranda YOK — kaynak işaretçisi '
            'dursa bile kullanıcı için yokluk SESSİZLEŞTİ; kayıt onu hâlâ '
            '"beyanlı" diye listeliyor olurdu');

    final String text = t.widget<Text>(card).data ?? '';
    expect(text.trim(), isNotEmpty,
        reason: 'cümle BOŞ — widget duruyor ama beyan yok. Kaynak '
            'işaretçisinin varlığı bunu yakalamaz (ölçüldü: betik exit 0, '
            'süit 323/323 yeşil kalıyor)');
  });

  testWidgets('SORUMLULUĞU ÜSTLENİYOR — ve TARİH VERMİYOR',
      (WidgetTester t) async {
    await pumpPlaceholder(t);
    final String text =
        t.widget<Text>(find.byKey(const Key('camera-preview-placeholder')))
                .data ??
            '';

    // Sınıf ERTELENMİŞ (yapılabilir, biz yapmadık) → cümle sorumluluğu
    // üstlenir. "Kamera bunu göremez" (imkânsız) ya da "bilmiyoruz"
    // (ölçülmemiş) DEĞİL.
    expect(text.toLowerCase(), contains('on purpose'),
        reason: 'cümle sorumluluğu üstlenmiyor — ERTELENMİŞ bir sınırı '
            'imkânsız ya da bilinmiyor gibi göstermek yanlış sınıf');

    // M-F-186 / Ostinato hükmü: "gerekçenin varlığı 'yet'i affetmiyor".
    expect(
        RegExp(r'\b(yet|soon|coming|will be)\b', caseSensitive: false)
            .hasMatch(text),
        isFalse,
        reason: 'yokluk beyanı bir TARİH ya da söz veriyor: "$text"');
  });

  test('KAYIT KATMANI DURUYOR — ama tek başına YETMEDİĞİ yazılı', () {
    // İki katmanın AYRI olduğu belgede de kalsın: kaynak işaretçisi kaydı
    // besliyor, bu dosya ekranı sınıyor. Biri ötekini garanti etmiyor.
    final String src = File('lib/app/skeleton_overlay.dart').readAsStringSync();
    expect(src, contains('PLACEHOLDER(asset)'),
        reason: 'kaynak işaretçisi düşmüş — kayıt (PLACEHOLDER-REGISTER) '
            'artık bu yokluğu listelemez');
    expect(src, contains('unblocked by:'),
        reason: '"unblocked by" düşmüş — bir placeholder "ne zaman kalkar" '
            'sorusunu taşımadan bırakılamaz (gen_placeholder_register kapısı)');
  });
}
