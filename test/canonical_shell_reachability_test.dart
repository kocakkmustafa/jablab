import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// JAB-P0-001 · CANONICAL SHELL ERİŞİLEBİLİRLİK KAPISI
///
/// ## Bu dosya neden var — iki boşluk, tek kapının DIŞINDA
///
/// `test/reachable_screens_test.dart` zaten `ItemPage`/`ShellScaffold`'u
/// "lib/shell_candidate/ — DONDURULMUŞ terfi envanteri" diye ölçüyor
/// (`mentionedOutside`, o dosyada). Ama o testin ADAY kümesi TEK kanaldan
/// türüyor: bir sınıfın gövdesinde `Scaffold(` GEÇMESİ. Bu kanal YAPISAL
/// ama TAM DEĞİL — kendi yorumu bunu adıyla yazıyor ("HİÇBİR KANALIN
/// GÖRMEDİĞİ BİR EKRAN GÖRÜNMEZ KALIR"). Bu oturum (2026-08-19) iki gerçek
/// boşluk ÖLÇTÜ:
///
/// 1. **Görünmezlik.** `ProgressPage`/`PaywallStub`/`LibraryPage` düz
///    `ListView(`/`Card(` döndürüyor, `Scaffold(` KURMUYOR — o kanala hiç
///    ADAY olarak girmiyorlar, yani ne "varılan" ne "varılamayan" kovasına
///    düşüyorlar: TAMAMEN görünmezler. Bugün erişilemez olmaları bir
///    KANIT değil bir TESADÜF — kimse ölçmedi.
/// 2. **İsim-çatışması yanlış-pozitifi.** `CoursePage` (candidate)
///    `Scaffold(` KURUYOR, aday kümesine giriyor — ama `lib/app/course_
///    page.dart`taki GERÇEK/shipped `CoursePage` ile AYNI ÇIPLAK ADI
///    taşıyor. `Set<String>` aritmetiğinde ikisi TEK girdiye çöküyor;
///    gerçek olan yürünüyor (`walked`) ve bu tekil ad kümeden düşüyor —
///    candidate hiç var olmamış gibi "varılamayan" kovasına da hiç
///    sorulmuyor. Ad-tabanlı bir kapı bu ayrımı YAPISAL OLARAK göremez.
///
/// Bu dosya `docs/evidence/production-line/baseline.json`ı (JAB-P0-001
/// Step 1 makine-okur envanteri, bu oturumda üretildi) TEK doğruluk
/// kaynağı sayarak ikisini de kapatır: boşluk-1 için aynı `mentionedOutside`
/// sözleşmesini tüm 6 sembole eşit uygular; boşluk-2 için ad yerine
/// DERLEYİCİNİN ZORLADIĞI import `show` kısıtlamasını okur.
///
/// ## Neden "önce kırmızı" burada SABOTAJ biçiminde
///
/// Layer B bugün ZATEN erişilemez (donmuş, JabLab kendi akışı çağırmıyor —
/// `lib/shell_candidate/README.md`nin kendi kaydı, 2026-08-06/07). Yani
/// gerçek kodda kırmızı üretecek bir KUSUR yok; klasik kırmızı→yeşil
/// TDD'nin konusu burada mevcut değil. Onun yerine (repo'nun başka
/// yerlerde de kullandığı desen): dedektörün KENDİSİ sentetik bir ihlale
/// karşı önce ÇALIŞTIRILIR (aşağıdaki "sabotaj" grubu) — ancak dedektör
/// gerçekten ötüyorsa, bugünkü temiz koda karşı yeşilliği KANIT sayılır.
void main() {
  final Map<String, dynamic> inventory =
      ((jsonDecode(
                        File(
                          'docs/evidence/production-line/baseline.json',
                        ).readAsStringSync(),
                      )
                      as Map)
                  .cast<String, dynamic>()['canonicalShell']
              as Map)
          .cast<String, dynamic>();

  /// Yorumları söker — `reachable_screens_test.dart`taki `codeOnly` ile
  /// AYNI mantık, bilerek yeniden icat edilmedi. Bir dosyanın kendi
  /// hakkında konuşan yorumu, o dosyanın ÇALIŞAN kısmıyla karışmasın diye:
  /// `lib/app/course_page.dart` gerçekten `shell_candidate/library_pages.
  /// dart'ın CoursePage'inden` diye bir açıklama satırı TAŞIYOR — bu
  /// GERÇEK bir kod-referansı değil, yorumsuz taransaydı bu dosyanın
  /// kendisi kendi ölçtüğü ihlali üretirdi.
  String codeOnly(String s) => s
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ')
      .split('\n')
      .map((String l) {
        final int i = l.indexOf('//');
        return i < 0 ? l : l.substring(0, i);
      })
      .join('\n');

  Map<String, String> loadLibSrc() {
    final Map<String, String> out = <String, String>{};
    for (final FileSystemEntity e in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      out[e.path] = codeOnly(e.readAsStringSync());
    }
    return out;
  }

  /// `name` dizgesi, `dir` DIŞINDAKİ herhangi bir dosyanın (yorumsuz)
  /// kaynağında geçiyor mu? `reachable_screens_test.dart`taki
  /// `mentionedOutside` ile BİREBİR aynı sözleşme — iki dosyanın aynı
  /// soruyu farklı cevaplaması, hangisinin doğru olduğunu belirsizleştirir.
  bool mentionedOutside(Map<String, String> src, String name, String dir) =>
      src.entries.any(
        (MapEntry<String, String> e) =>
            !e.key.startsWith(dir) && e.value.contains(name),
      );

  test('envanter dosyası okunabilir ve üç katmanı da taşıyor', () {
    expect(inventory['layerA_sharedInfraPendingPromotion'], isNotNull);
    expect(inventory['layerB_deadCandidate'], isNotNull);
    expect(
      inventory['layerC_staleGreenTests'],
      isNotNull,
      reason:
          'envanter üç katmanlı olmalı — SHELL-ENVANTERI-ANALIZI-'
          '2026-08-19.md\'nin ölçtüğü yapı budur, iki katmana düşerse '
          'PREP bulgusu sessizce kaybolur',
    );
  });

  group('sabotaj — dedektörün kendisi önce sınanır (kırmızı ikiz)', () {
    test('mentionedOutside SENTETİK bir dış-referansı gerçekten yakalar', () {
      final Map<String, String> fake = <String, String>{
        'lib/shell_candidate/shell_scaffold.dart': 'class ProgressPage {}',
        'lib/app/some_new_file.dart': 'final w = ProgressPage();',
      };
      expect(
        mentionedOutside(fake, 'ProgressPage', 'lib/shell_candidate/'),
        isTrue,
        reason:
            'dedektör sentetik bir dış-referansı YAKALAMADI — '
            'aşağıdaki bugünkü temiz sonucun ne kanıtladığı belirsizleşir',
      );
    });

    test('mentionedOutside TEMİZ durumda ötmez (negatif ikiz)', () {
      final Map<String, String> fake = <String, String>{
        'lib/shell_candidate/shell_scaffold.dart': 'class ProgressPage {}',
        'lib/app/some_other_file.dart': 'final w = SomethingElse();',
      };
      expect(
        mentionedOutside(fake, 'ProgressPage', 'lib/shell_candidate/'),
        isFalse,
        reason:
            'dedektör gerçekte olmayan bir ihlali UYDURUYOR — yanlış '
            'alarm veren bir kapı er geç kapatılır',
      );
    });

    test('yorum-sökücü sembol adını gerçekten YORUMDAN siler', () {
      // course_page.dart'ın gerçek satırının küçültülmüş hâli: sembol adı
      // bir BAŞKA dosyanın açıklayıcı yorumunda geçiyor — bu GERÇEK bir
      // referans değil, ölçülmeden fark edilmezdi.
      const String withComment =
          "// shell_candidate/library_pages.dart'ın CoursePage'inden\n"
          'final x = 1;';
      expect(
        codeOnly(withComment),
        isNot(contains('CoursePage')),
        reason:
            'yorum sökücü çalışmıyor — bir dosyanın kendi hakkındaki '
            'açıklayıcı notu GERÇEK bir kod-referansı gibi sayılır ve '
            'aşağıdaki tüm ölçüm YANLIŞ ALARM üretirdi',
      );
    });
  });

  final Map<String, String> libSrc = loadLibSrc();

  group(
    'Layer A — paylaşılan altyapı GERÇEKTEN tüketiliyor (vakum muhafızı)',
    () {
      test('envanterdeki her Layer-A dosyasının en az bir tüketicisi '
          'GERÇEKTEN onu anıyor', () {
        final List<dynamic> entries =
            (inventory['layerA_sharedInfraPendingPromotion'] as Map)['entries']
                as List<dynamic>;
        expect(
          entries,
          isNotEmpty,
          reason:
              'Layer A listesi BOŞ — bu bir vakum: aşağıdaki Layer-B '
              'kontrollerinin "hiç kimse hiçbir şeyi anmıyor" diye '
              'YANLIŞLIKLA yeşil geçip geçmediği hiç sınanmamış olurdu',
        );
        for (final dynamic raw in entries) {
          final Map<String, dynamic> e = (raw as Map).cast<String, dynamic>();
          final List<String> symbols = (e['symbols'] as List<dynamic>)
              .cast<String>();
          final List<String> consumers = (e['consumers'] as List<dynamic>)
              .cast<String>();
          for (final String consumer in consumers) {
            expect(
              libSrc[consumer],
              isNotNull,
              reason:
                  '${e['file']} için beyan edilen tüketici $consumer '
                  'artık depoda yok — envanter bayatlamış',
            );
          }
          final bool anyConsumerMentionsAnySymbol = consumers.any(
            (String c) =>
                symbols.any((String s) => (libSrc[c] ?? '').contains(s)),
          );
          expect(
            anyConsumerMentionsAnySymbol,
            isTrue,
            reason:
                '${e['file']}: HİÇBİR beyan edilen tüketici HİÇBİR '
                'sembolü anmıyor — vakum riski, bkz. grup açıklaması',
          );
        }
      });
    },
  );

  group('Layer B — donmuş aday ÜRETİMDE hiçbir yerden anılmıyor', () {
    final List<dynamic> entries =
        (inventory['layerB_deadCandidate'] as Map)['entries'] as List<dynamic>;

    test('envanterde tam 6 donmuş sembol kayıtlı', () {
      // Sabit sayı BİLEREK: `lib/shell_candidate/README.md`nin envanteri
      // 2026-07-29'da DONDURULDU ("Bu klasöre yeni bileşen EKLENMEZ") —
      // sayı 6'nın dışına çıkarsa ya envanter yanlış türetilmiş ya da
      // dondurulmuş klasöre biri sessizce yeni bir aday eklemiş; ikisi de
      // bu satırın ötmesini HAK EDER.
      expect(
        entries.length,
        6,
        reason:
            'Layer-B sembol sayısı değişti (${entries.length}) — '
            'shell_candidate/README.md §"Bileşen listesi" ile çapraz '
            'kontrol et: ya envanter bayatlamış ya da dondurulmuş '
            'klasöre yeni bir aday eklenmiş (README kuralı bunu yasaklar)',
      );
    });

    for (final dynamic raw in entries) {
      final Map<String, dynamic> e = (raw as Map).cast<String, dynamic>();
      final String file = e['file'] as String;
      final String symbol = e['symbol'] as String;
      final String method = e['verificationMethod'] as String;

      test('$symbol ($file) — $method', () {
        expect(
          libSrc[file],
          isNotNull,
          reason:
              '$file envanterde var ama artık depoda yok — dosya '
              'taşınmış/silinmiş olabilir, envanter bayatlamış',
        );
        expect(
          libSrc[file],
          contains('class $symbol'),
          reason:
              '$symbol artık $file içinde tanımlı değil — envanter '
              'bayatlamış ya da sembol zaten kaldırılmış (bu durumda '
              'envanterden de düşürülmeli, "0 aday" farklı bir iddiadır)',
        );

        if (method == 'codeOnlyContainmentOutsideFolder') {
          expect(
            mentionedOutside(libSrc, symbol, 'lib/shell_candidate/'),
            isFalse,
            reason:
                '$symbol lib/shell_candidate/ DIŞINDA bir dosyada '
                'anılıyor — donmuş aday sessizce ÜRETİME sızmış olabilir.',
          );
        } else if (method == 'importGraphShowClause') {
          // Ad çatışması yüzünden (candidate CoursePage == shipped
          // CoursePage, bkz. dosya başlığı) ad-tabanlı tarama SAĞLIKSIZ.
          // Gerçek kanıt: dosyayı içe aktaran HER satır, derleyicinin
          // ZORLADIĞI bir `show` kısıtlaması taşımalı — bir isim ancak
          // `show` listesindeyse o dosyanın ad alanına girebilir, bunu
          // metin taraması değil Dart'ın kendisi garanti eder.
          final RegExp importLine = RegExp(
            r"""import\s+'[^']*library_pages\.dart'([^;]*);""",
          );
          final List<String> outsideImports = <String>[];
          for (final MapEntry<String, String> src in libSrc.entries) {
            if (src.key.startsWith('lib/shell_candidate/')) continue;
            for (final RegExpMatch m in importLine.allMatches(src.value)) {
              outsideImports.add('${src.key}: ${m.group(0)}');
            }
          }
          expect(
            outsideImports,
            isNotEmpty,
            reason:
                'library_pages.dart artık lib/shell_candidate/ '
                'DIŞINDAN HİÇBİR yerden içe aktarılmıyor (WhyNotPage '
                'dahil) — bu bir vakum, "$symbol sızmadı" iddiası '
                'anlamsızlaşır, bu satır o durumda da ÖTMELİ',
          );
          for (final String imp in outsideImports) {
            expect(
              imp,
              matches(RegExp(r'show\s+WhyNotPage\s*;\s*$')),
              reason:
                  'library_pages.dart bir yerde KISITSIZ ya da '
                  "$symbol'ı da açan bir import ile içe aktarılıyor: "
                  '$imp — derleyici artık $symbol\'ı o dosyanın ad '
                  'alanına sokabilir, ihlal çalışma-zamanında değil '
                  'DERLEME zamanında olur ve bu kapı onu ÖNCEDEN yakalar',
            );
          }
        } else {
          fail('bilinmeyen doğrulama yöntemi: $method (${e['file']})');
        }
      });
    }
  });

  test('Layer C — bayat-yeşil olarak kayıtlı testler hâlâ mevcut', () {
    final List<dynamic> entries =
        (inventory['layerC_staleGreenTests'] as Map)['entries']
            as List<dynamic>;
    expect(entries, isNotEmpty);
    for (final dynamic raw in entries) {
      final Map<String, dynamic> e = (raw as Map).cast<String, dynamic>();
      final File f = File(e['file'] as String);
      expect(
        f.existsSync(),
        isTrue,
        reason:
            '${e['file']} envanterde "bayat-yeşil" diye kayıtlı ama '
            'artık depoda yok — envanterden düşürülmeli ya da dosya '
            'geri getirilmeli (silindiyse bu iyi haber, ama envanter '
            'onu bilmiyor)',
      );
    }
  });
}
