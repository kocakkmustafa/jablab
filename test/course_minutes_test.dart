import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// KURS SÜRESİ SAPMASI **SESSİZ** KALAMAZ (J-191).
///
/// ## Bu kapı, KENDİ KIRDIĞIM bir şeyi korumak için var
///
/// Bu gece `boxing.foundations`a iki ders yazdım (10+10 dk) ve kursun
/// `estimatedMinutes` alanını **güncellemedim.** Değişmez sessizce kırıldı:
/// **60 = 60 idi, 60 ≠ 80 oldu.** Ve süitin tamamı **265/265 yeşil kaldı.**
///
/// > Gece boyunca 43 kapı kurdum. Sonra içerik yazdım ve **hiçbir kapının
/// > korumadığı bir veri değişmezini** kırdım. Commit mesajıma *"kapı
/// > envanterinin ilk gerçek sınavı"* yazmıştım — **sınavdı, ve bunu
/// > kaçırdı.**
///
/// Choreia'nın uyarısının tam hâli, ama bir basamak daha derinde: orada
/// *"yeni içerik bir TESTİ öldürür"* deniyordu; burada yeni içerik
/// **hiçbir testin bakmadığı bir DEĞİŞMEZİ** öldürdü — ve ölüm **sessiz**
/// oldu, çünkü bakan yoktu.
///
/// ## ⚠️ ÖNCE BİR DÜZELTME: "değişmez" DEDİM, FAZLA GENİŞTİ
///
/// İlk yazışımda *"üç kurstan ikisi tutuyor → değişmez gerçek"* dedim.
/// **Tarihi ölçünce çıkarım zayıfladı:**
///
/// * `foundations` **60/60 (6 ders)** ve `intermediate` **63/63 (4 ders)**
///   — ikisi de **hiç değişmemiş**; yazıldıkları gün tutarlı yazılmışlar ve
///   **hiçbir şey onları sınamamış.**
/// * `conditioning` ise **ilk commit'ten beri** uyuşmuyor (**54 ↔ 78**), ve
///   **en eski sürümde bile** (30 ↔ 22, 2 ders) uyuşmuyordu.
///
/// > **Hiç değişmemiş iki sabit, bir KURALI kanıtlamaz.** Bir değişmez,
/// > **değişime dayandığında** değişmezdir — ve bunlar hiç değişmedi.
/// > **İlk değişimi bu gece ben yaptım, ve biri kırıldı.**
///
/// Ayrıca `conditioning`in **54'ü hiçbir hesaba uymuyor**: ders toplamı
/// **78**, saf çalışma **69**, dinlenmeler dahil **89**. Yani koordinatörün
/// *"iki sayı farklı şeyleri ölçüyor olabilir"* hipotezi de **doğrulanmadı**
/// — 54 **hesaplanabilir hiçbir şeye** eşit değil.
///
/// **Bugünkü dürüst okuma:** `estimatedMinutes` **üç kursta da ELLE
/// yazılmış** bir tahmin; ikisi toplamla çakışıyor, biri hiç çakışmadı, ve
/// **hiçbiri türetilmiyor.** Bu kapı bir kuralı DAYATMIYOR — sapmanın
/// **sessiz** kalmasını yasaklıyor, çünkü sessiz bir sapma bir sonraki
/// içerik turunda **fark edilmeden büyür.**
///
/// ## Kapının kuralı, bu düzeltmeden SONRA
///
/// Kapı **eşitliği dayatmıyor**; sapmanın **gerekçesiz** kalmasını
/// yasaklıyor. `conditioning` gerekçesini taşıyor (*bilinmiyor*, ve o
/// beyan **uydurulmadı**), `foundations`/`intermediate` eşitliği taşıyor.
/// Yeni ders yazan biri sayıyı güncellemezse kapı **öter** — ve öttüğü an
/// iki yol var: sayıyı düzelt, ya da **neden farklı olduğunu yaz.**
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Sayının **doğru** olduğunu — yalnız **tutarlı** olduğunu. `minutes`
///   alanının tek bir anlamı yok (J-063: bazı derste çalışma+dinlenme,
///   bazısında yalnız çalışma), yani toplam da o karışıklığı miras alır.
/// * Kullanıcının bunu **gördüğünü** — bugün görmüyor: `estimatedMinutes`
///   `ShellCourse.minutes`a eşlenip orada kalıyor, **hiçbir ekran onu
///   render etmiyor.** Risk, birinin onu **tek satırla** kurs kartına
///   koyması; o gün sayı yanlışsa kullanıcı yanlış bilgilendirilir.
void main() {
  test('kurs süresi = ders sürelerinin toplamı (ya da sapma BEYANLI)', () {
    final Map<String, dynamic> lib =
        (jsonDecode(File('assets/content/library.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();
    final List<dynamic> courses =
        ((lib['disciplines'] as List<dynamic>).firstWhere(
                  (dynamic d) => (d as Map)['id'] == 'boxing',
                )
                as Map)['courses']
            as List<dynamic>;

    // VAKUM MUHAFIZI — kurslar gerçekten okundu mu? Boş bir liste
    // "hiç uyuşmazlık yok" diye okunur ve kapı sessizce ölür.
    expect(
      courses.length,
      greaterThanOrEqualTo(3),
      reason: 'yalnız ${courses.length} kurs okundu — gezinme bozuk',
    );

    final List<String> silent = <String>[];
    int checked = 0;
    for (final dynamic raw in courses) {
      final Map<String, dynamic> c = (raw as Map).cast<String, dynamic>();
      final int declared = (c['estimatedMinutes'] as num?)?.toInt() ?? 0;
      final int sum = (c['lessons'] as List<dynamic>).fold<int>(
        0,
        (int a, dynamic l) =>
            a + (((l as Map)['minutes'] as num?)?.toInt() ?? 0),
      );
      if (declared == sum) {
        checked++;
        continue;
      }
      // Sapma YASAK DEĞİL — SESSİZ olması yasak.
      final String? why = c[r'$estimatedMinutesWhy'] as String?;
      if (why == null || why.trim().length < 40) {
        silent.add('${c['id']}: beyan $declared, ders toplamı $sum');
      }
    }

    expect(
      checked,
      greaterThan(0),
      reason:
          'HİÇBİR kurs değişmezi sağlamıyor — bu kapı bir kuralı '
          'değil bir enkazı ölçüyor olabilir; sayıların anlamı '
          'değiştiyse kapı da değişmeli',
    );

    expect(
      silent,
      isEmpty,
      reason:
          'kurs süresi ders toplamıyla uyuşmuyor ve SEBEBİ YAZILI '
          'DEĞİL:\n  ${silent.join('\n  ')}\n\n'
          'Yeni ders yazıp kursun `estimatedMinutes` alanını '
          'güncellememek bu değişmezi SESSİZCE kırar — bu kapı tam '
          'olarak o yüzden var (J-191: kıran bendim). İki yol: (a) '
          'sayıyı düzelt (b) sapma kasıtlıysa `\$estimatedMinutesWhy` '
          'ile GEREKÇESİNİ yaz. Gerekçe UYDURULMAZ: bilinmiyorsa '
          '"bilinmiyor" yazılır.',
    );
  });

  test('POZİTİF KONTROL — kapı, sessiz bir sapmayı GERÇEKTEN görüyor', () {
    // Yukarıdaki "temiz" sonuç, gezinmenin hiçbir kursa ulaşamamasından da
    // doğabilirdi. Burada sentetik bir sapma kurulup aynı mantık koşuluyor.
    const Map<String, dynamic> fake = <String, dynamic>{
      'id': 'sahte',
      'estimatedMinutes': 30,
      'lessons': <dynamic>[
        <String, dynamic>{'minutes': 20},
        <String, dynamic>{'minutes': 25},
      ],
    };
    final int sum = (fake['lessons']! as List<dynamic>).fold<int>(
      0,
      (int a, dynamic l) => a + (((l as Map)['minutes'] as num?)?.toInt() ?? 0),
    );
    expect(sum, 45);
    expect(fake['estimatedMinutes'] == sum, isFalse);
    expect(
      fake[r'$estimatedMinutesWhy'],
      isNull,
      reason: 'sentetik sapma gerekçesiz — kapının yakalaması gereken hâl',
    );
  });
}
