import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TÜRKÇE DESEN + `caseSensitive: false` YASAK — bu kapı DART'A ÖZGÜ (J-229).
///
/// ## ⛔ ÖNCE SINIR: BU KURAL DİLE ÖZGÜDÜR, AİLE GENELİ DEĞİL
///
/// Dart'ta `RegExp(caseSensitive: false)` Türkçe `ı/İ`yi katlamıyor →
/// **yasak**. **Python'da tam TERSİ doğrudur:** orada `re.IGNORECASE`
/// ÇALIŞIR, kırık olan `.lower()`/`.casefold()`tır. Bu dosyanın kuralını
/// Python araçlarına taşımak, **kusur talimatı** vermek olur.
///
/// > ***Bir panzehir, DİL DEĞİŞİNCE kusurun kendisine dönüşebilir.***
///
/// Ölçüldü (2026-08-12, ikisi de bu makinede koşuldu):
///
/// | | `.lower()` / `.toLowerCase()` | duyarsız REGEX |
/// |---|---|---|
/// | **Python** | 🔴 `'İ'.lower()` → `'i̇'` (105,775) | ✅ `re.I` çalışıyor |
/// | **Dart** | 🔴 yalnız `ı` (`'I'.toLowerCase()`→`'i'`) · `İ` ✅ | 🔴 `ı` **ve** `İ` |
///
/// ⚠️ Koordinatörün tablosu `bir ↔ BİR`i **🔴** gösteriyordu; o **Python'un**
/// davranışı. **Dart'ta ölçtüm: `'BİR'.toLowerCase() == 'bir'` → true.**
/// Yani Dart'ta `.toLowerCase()` yalnız **noktasız ı**da kırılıyor.
/// ***Türkçenin iki `i`si var ve ikisi de kırık — ama farklı YOLLARDA.***
///
/// ## Neden kapı — "temizlik bir tasarım değil, rastlantı"
///
/// Bugün bu depoda **21** `caseSensitive: false` sitesi var ve **hiçbiri**
/// Türkçe desen taşımıyor. Ama bunun sebebi bir kural değil, **desenlerimin
/// İngilizce olması** (`yet|soon|will|unlock…`). Yarın biri
/// `RegExp('AİLE…', caseSensitive: false)` yazarsa **sessizce kör olur ve
/// hiçbir şey ötmez** — kapının var olma sebebi tam olarak bu.
///
/// ## Kapsam kararı: KIRANLARLA değil, HEPSİYLE
///
/// Bugün yalnız `ı/İ` kırıyor; `ş ğ ç ö ü` sağlam. Kural yine de **tüm
/// Türkçe karakterleri** kapsıyor, çünkü o sağlamlık **Dart'ın bugünkü
/// davranışı, bir sözleşme değil.** *Bugün geçerli olmayan bir kuralı,
/// geçerli olacağı gün için kaydetmek.*
void main() {
  const String turkish = 'ıİşŞğĞçÇöÖüÜ';
  final RegExp turkishChar = RegExp('[$turkish]');

  /// `caseSensitive: false` içeren her RegExp çağrısının DESEN kısmı.
  ///
  /// ⚠️ Regex ile Dart kaynağı ayrıştırmak kırılgan — ilk denemem çok
  /// satırlı çağrılarda **1 site** bulmuştu (gerçek: 21). O yüzden burada
  /// desen değil, **çağrı penceresi** taranıyor: `RegExp(` ile ondan sonraki
  /// `caseSensitive: false` arasındaki metin. Pencere fazla geniş olursa
  /// yanlış-pozitif üretir — bu yüzden pencere `RegExp(`ten başlıyor ve
  /// **ilk** `caseSensitive`e kadar gidiyor, gövdeye taşmıyor.
  /// ⚠️ BU DOSYA KENDİNİ DIŞLAR — ve dışlama TEK dosyayla sınırlı, kapıda
  /// sayılıyor. Sebep: sabotaj fixture'ları (`RegExp('YAKINDA', …)`) yasak
  /// deseni **bilerek** taşıyor; kendini taramak, kapının kendi kanıtını
  /// ihlal saymasıdır. *Bir muafiyet, sayısı yazılmadan kaçış kapısına
  /// dönüşür* — bu yüzden aşağıda muaf dosya sayısı da sınanıyor.
  const String selfPath = 'turkish_case_fold_test.dart';

  List<({String file, int line, String window})> sites() {
    final List<({String file, int line, String window})> out = [];
    for (final File f
        in Directory('test')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (File f) =>
                  f.path.endsWith('.dart') && !f.path.endsWith(selfPath),
            )) {
      final String src = f.readAsStringSync();
      for (final Match m in RegExp('caseSensitive:\\s*false').allMatches(src)) {
        final int open = src.lastIndexOf('RegExp(', m.start);
        if (open < 0) continue;
        out.add((
          file: f.path,
          line: '\n'.allMatches(src.substring(0, open)).length + 1,
          window: src.substring(open, m.start),
        ));
      }
    }
    return out;
  }

  test('POZİTİF KONTROL — siteler bulunuyor ve pencere doğru', () {
    final all = sites();
    expect(
      all.length,
      greaterThan(15),
      reason:
          'yalnız ${all.length} `caseSensitive: false` sitesi bulundu — '
          'ayrıştırma bozuk (ilk denememde 21 yerine 1 bulmuştu); bu '
          'kapının sonucu ANLAMSIZ olurdu',
    );
    // Pencere gövdeye taşmıyor mu: hiçbiri absürt uzun olmamalı.
    final longest = all
        .map((s) => s.window.length)
        .fold<int>(0, (a, b) => a > b ? a : b);
    expect(
      longest,
      lessThan(600),
      reason:
          'en uzun pencere $longest karakter — `RegExp(` çapası '
          'kaymış olabilir, yanlış-pozitif riski var',
    );

    // MUAFİYET SAYILI: tam bir dosya, ve o da bu dosya.
    final int exempt = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith(selfPath))
        .length;
    expect(
      exempt,
      1,
      reason:
          'muaf dosya sayısı $exempt — muafiyet TEK dosya olmalı '
          '(bu kapının kendi sabotaj fixture\'ları); büyürse kaçış '
          'kapısına dönüşür',
    );
  });

  test('🔒 TÜRKÇE DESEN + caseSensitive:false YOK', () {
    final all = sites();
    final offenders = all
        .where((s) => turkishChar.hasMatch(s.window))
        .map((s) => '${s.file}:${s.line}')
        .toList();

    // ② PAYDA + İŞLEM basılıyor: "0" derken 21'den 0 dediği görünsün.
    // ignore: avoid_print
    print(
      '  TÜRKÇE KATLAMA · caseSensitive:false sitesi ${all.length} − '
      'Türkçe desen taşıyan ${offenders.length} = temiz '
      '${all.length - offenders.length}',
    );

    expect(
      offenders,
      isEmpty,
      reason:
          'Türkçe karakterli desen `caseSensitive: false` ile '
          'aranıyor: $offenders\n'
          'Dart bu bayrakla `ı/İ` KATLAMIYOR (ölçüldü: '
          '`RegExp("aile", caseSensitive:false).hasMatch("AİLE")` → false) '
          '→ eşleşme SESSİZCE kaçar ve kapı yeşil kalır.\n'
          'Yerine: `.toLowerCase()` kullan (Dart\'ta `İ` için ÇALIŞIYOR) '
          'ama `ı` için o da kırık — noktasız `ı` içeren jetonlarda '
          'TAM KİP karşılaştır.\n'
          '⛔ Bu kuralı Python araçlarına TAŞIMA: orada `re.IGNORECASE` '
          'DOĞRU yoldur, kırık olan `.lower()`tır.',
    );
  });

  test(
    '🧪 SABOTAJ — kapı ötmesi gerekende ötüyor, susması gerekende susuyor',
    () {
      // ③ İKİ YÖNLÜ. Tek yön sınanırsa kapı "her caseSensitive:false'ı
      // yasakla"ya kayar ve 20 MEŞRU siteyi kırmızıya boyar.
      bool flags(String window) => turkishChar.hasMatch(window);

      // ÖTMELİ — Türkçe KARAKTER taşıyan desen
      expect(flags("RegExp('yakında', "), isTrue, reason: 'ı kaçırıldı');
      expect(flags("RegExp('AİLE', "), isTrue, reason: 'İ kaçırıldı');
      expect(flags(r"RegExp(r'\b(görüş|ölçüm)\b', "), isTrue);
      // SUSMALI — ASCII desen (bugünkü 21 sitenin hepsi böyle)
      expect(
        flags("RegExp('SOON', "),
        isFalse,
        reason:
            'meşru site kırmızıya '
            'boyanıyor — kapı fazla geniş',
      );
      expect(flags(r"RegExp(r'\b(yet|soon|coming|will be)\b', "), isFalse);
      expect(flags(r"RegExp(r'\bunlock', "), isFalse);

      // 🔴 KÖR NOKTA — SABOTAJ BUNU ORTAYA ÇIKARDI, ve adıyla duruyor.
      //
      // İlk sabotaj fixture'ım `RegExp('YAKINDA', …)` idi ve kapı ÖTMEDİ.
      // Sebep ölçüldü: **`YAKINDA` saf ASCII.** Türkçede `ı`nın BÜYÜK hâli
      // ASCII `I`dir — yani BÜYÜK KİPTE yazılmış Türkçe bir jeton, hiçbir
      // Türkçe-özgü glif TAŞIMAYABİLİR.
      //
      // > ***Bir dilin karakter kümesiyle tanınması, o dilin HER KİPİNDE
      // > tanınacağı anlamına gelmez.***
      //
      // Sonuç: bu kapı `ı İ ş Ş ğ Ğ ç Ç ö Ö ü Ü` taşıyan deseni yakalar;
      // `YAKINDA`/`ISIK` gibi **ASCII'ye düşen büyük-kip** Türkçeyi
      // YAKALAYAMAZ. Kapatılmadı — çünkü kapatmanın tek yolu sözlük tutmak
      // ya da her ASCII deseni şüpheli saymak; ikisi de bugünkü 21 meşru
      // siteyi kırmızıya boyar. **Ölçüldü, adıyla bırakıldı.**
      expect(
        flags("RegExp('YAKINDA', "),
        isFalse,
        reason: 'kör nokta kapanmış olabilir — ölçümü ve bu şerhi güncelle',
      );
    },
  );
}
