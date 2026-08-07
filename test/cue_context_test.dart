import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// DÖNEN BİR HAVUZDAKİ REPLİK, BAĞLAM İDDİA EDEMEZ (J-180).
///
/// ## Ölçülmüş kusur
///
/// `session.cue.round_start` havuzunda şu replik vardı: **"Round one. Go."**
/// Tek başına doğru bir cümle. Ama **çalınma yolu** onu yanlış yapıyordu:
///
/// * `SessionNarrator.startRound()` her turda `_fired` kümesini temizler →
///   `roundStart` **her turda bir kez** tetiklenir;
/// * `CueBook.say()` havuzu **round-robin** döndürür (olay başına imleç,
///   `(v + 1) % lines.length`).
///
/// Sonuç aritmetikle çıkıyor: 1. turda imleç yok → `[0]`; **2. turda
/// `(0+1)%4 = 1` → kullanıcı ikinci turun başında "Round one" duyuyordu.**
/// Kondisyon derslerinin çoğu 3-4 turlu, yani bu **tipik** bir oturumda
/// olan bir şeydi, kenar durum değil.
///
/// ## Kuralın gerçek gerekçesi
///
/// Yasak olan şey "sıra sayısı" değil. Yasak olan şey **seçim yolunun
/// taşımadığı bir bağlamı iddia etmek**:
///
/// > Bir replik havuzu bağlamsız DÖNÜYORSA, içindeki hiçbir replik
/// > bağlama bağlı bir şey SÖYLEYEMEZ.
///
/// `counting` grubundaki sayılar bu kuralı ÇİĞNEMEZ, çünkü onlar `{n}`
/// şablonuyla **çağrı anında doldurulur** — bağlam yola bağlıdır, metne
/// gömülü değildir. Ayrım tam olarak budur ve dolmamış şablonun
/// söylenmemesi zaten ayrı bir kapıyla korunuyor (J-104 kusur #2).
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Repliğin **iyi** olduğunu — yalnız yanlış bir bağlam iddia etmediğini.
/// * Bağlamın başka türlerini (cinsiyet, ekipman, günün saati). Desen
///   sıra/konum iddialarına bakıyor; yeni bir bağlam sınıfı çıkarsa bu
///   kapı onu **görmez** ve bunu bilerek yazıyorum.
void main() {
  late Map<String, dynamic> cues;

  setUpAll(() {
    cues = (jsonDecode(File('assets/content/cues.en.json').readAsStringSync())
            as Map)
        .cast<String, dynamic>();
  });

  /// Dönen havuzda güvenli olmayan bağlam iddiaları.
  final RegExp contextClaim = RegExp(
      r'\b(round|set|rep)\s+(one|two|three|four|five|\d)\b'
      r'|\b(first|second|third|final|last)\s+(round|set)\b',
      caseSensitive: false);

  List<({String key, int index, String line})> allVariants() {
    final List<({String key, int index, String line})> out =
        <({String key, int index, String line})>[];
    void walk(Object? node, String path) {
      if (node is Map) {
        for (final MapEntry<Object?, Object?> e in node.entries) {
          final String k = '${e.key}';
          if (k.startsWith(r'$')) continue;
          walk(e.value, path.isEmpty ? k : '$path.$k');
        }
      } else if (node is List) {
        for (int i = 0; i < node.length; i++) {
          if (node[i] is String) {
            out.add((key: path, index: i, line: node[i] as String));
          }
        }
      }
    }

    walk(cues, '');
    return out;
  }

  test('hiçbir replik, dönen havuzda TAŞINMAYAN bir bağlam iddia etmiyor', () {
    final List<({String key, int index, String line})> vars = allVariants();

    // VAKUM MUHAFIZI — tarama gerçekten replik gördü mü? Bu olmadan bozuk
    // bir gezinme "sıfır ihlal" diye okunur ve kapı sessizce ölür.
    expect(vars.length, greaterThan(30),
        reason: 'yalnız ${vars.length} replik tarandı — gezinme bozuk, '
            'bu kapının "temiz" sonucu ANLAMSIZ');

    final List<String> bad = vars
        .where((({String key, int index, String line}) v) =>
            contextClaim.hasMatch(v.line))
        .map((({String key, int index, String line}) v) =>
            '${v.key}[${v.index}] → "${v.line}"')
        .toList();

    expect(bad, isEmpty,
        reason: 'bu replik(ler) bir sıra/konum iddia ediyor ama havuz '
            'BAĞLAMSIZ dönüyor:\n  ${bad.join('\n  ')}\n\n'
            'CueBook.say() olay başına imleci döndürür ve tur numarasını '
            'BİLMEZ. Bağlama bağlı bir şey söylenecekse yol bunu taşımalı '
            '({n} şablonu gibi) — metne gömülemez.');
  });

  test('POZİTİF KONTROL — desen bilinen kötü repliği YAKALIYOR', () {
    // Kapının kendisi ölçülüyor: yukarıdaki "temiz" sonucu, desenin hiçbir
    // şeyi yakalayamamasından da doğabilirdi. Gerçek kusur metni:
    expect(contextClaim.hasMatch('Round one. Go.'), isTrue);
    expect(contextClaim.hasMatch('Last round — empty it.'), isTrue);
    expect(contextClaim.hasMatch('Set 2. Go.'), isTrue);
  });

  test('NEGATİF İKİZ — masum replikler ve {n} şablonu YAKALANMIYOR', () {
    // Kapı fazla geniş yazılırsa `counting` grubunun tamamını öldürür.
    // Oradaki sayı bir İHLAL DEĞİL: `{n}` çağrı anında doldurulur, yani
    // bağlam YOLA bağlıdır — tam da bu kapının istediği şey.
    for (final String ok in <String>[
      'Hands up. Go.',
      'Here we go.',
      'Guard up. Begin.',
      '{n} in.',
      'Ten seconds.',
      'Five.',
    ]) {
      expect(contextClaim.hasMatch(ok), isFalse, reason: 'yanlış yakalama: $ok');
    }
  });

  test('N=1 VARSAYIMI YOK — 5. tekrarda da doğru kalan metinler (J-193)', () {
    // Koordinatörün «N'inci kez» ekseninin son maddesi. Yukarıdaki kural
    // *tur* bağlamıydı; bu *oturum* bağlamı — aynı aile, bir basamak
    // yukarıda:
    //
    //   Uygulama bir dersin KAÇINCI kez açıldığını hiçbir yüzeye
    //   taşımıyor. O hâlde hiçbir yüzey "ilk kez"i VARSAYAMAZ.
    //
    // ⚠️ NE ÖLÇMÜYOR: ders ADLARINI. `boxing.foundations.first_round`un
    // başlığı "Your first round" ve bu bir İHLAL DEĞİL — müfredattaki ilk
    // tam turu ADLANDIRIYOR, kullanıcının kaçıncı kez yaptığını iddia
    // etmiyor. Ayrım ölçüldü ve kasıtlı: `displayName` muaf, ANLATI değil.
    final RegExp firstTime = RegExp(
        r"\b(welcome( back)?|first time|for the first time|getting started"
        r"|new here|your first (session|round of|week))\b",
        caseSensitive: false);
    expect(firstTime.hasMatch('Welcome to JabLab'), isTrue,
        reason: 'POZİTİF KONTROL: desen bilinen bir N=1 cümlesini '
            'yakalamıyor — aşağıdaki temiz sonuç anlamsız olurdu');

    final List<String> bad = allVariants()
        .where((({String key, int index, String line}) v) =>
            firstTime.hasMatch(v.line))
        .map((({String key, int index, String line}) v) =>
            '${v.key}[${v.index}] → "${v.line}"')
        .toList();
    expect(bad, isEmpty,
        reason: 'bu replik(ler) oturumun İLKİ olduğunu varsayıyor:\n'
            '  ${bad.join('\n  ')}\n\n'
            'Uygulama bir dersin kaçıncı kez açıldığını hiçbir yüzeye '
            'taşımıyor — depoda kayıt var ama anlatı onu OKUMUYOR. '
            'Taşınmayan bir bağlam iddia edilemez (J-180 ile aynı kural, '
            'tur yerine OTURUM ölçeğinde).');
  });

  test('TERS İKİZ — havuz BOŞALTILARAK geçilemez', () {
    // M-F-337 dersi: yalnız "ihlal yok" ölçülseydi, `round_start` havuzunu
    // tek repliğe indirmek de kapıyı geçerdi — ihlal kalmaz çünkü replik
    // kalmaz. Üstelik round-robin'in tekrar-önleme özelliği de ölürdü.
    final Map<String, dynamic> session =
        (cues['session'] as Map).cast<String, dynamic>();
    final List<dynamic> pool = session['cue.round_start'] as List<dynamic>;
    expect(pool.length, greaterThanOrEqualTo(3),
        reason: 'round_start havuzu ${pool.length} replike düştü — dönen '
            'havuzun tekrar-önleme değeri varyant SAYISINDAN gelir; '
            'ihlali silmek için havuzu daraltmak çözüm değil');
  });
}
