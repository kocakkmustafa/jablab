import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// VAAT DİLİ KAPISI (M-F-186) — kullanıcının gördüğü hiçbir cümle bir
/// ZAMAN TAAHHÜDÜ vermez.
///
/// ## Hüküm
///
/// Ostinato'nun 2026-08-07 turunun hükmü, aileye taşındı: **"gerekçenin
/// varlığı 'yet'i affetmiyor — 'yet' bir zaman taahhüdüdür."** İyi yazılmış
/// bir gerekçenin yanına konmuş bir *"yet"* gerekçeyi geçersiz kılmıyor;
/// yanına karşılığı olmayan bir söz ekliyor. *"Bu disiplin açık değil"*
/// dürüstlük; *"henüz açık değil"* takvim.
///
/// ## Neden dosya-dosya düzeltmek YETMEZ
///
/// Bu tur 15 kullanıcı-görünür örneği temizledi. Aile dersi #8 (*tuzak
/// dosyaya değil DESENE yazılır*) 16.'sının yarın sessizce eklenmesini
/// engellemeyi istiyor: bir sonraki içerik turunda *"Not open yet"* yazmak
/// hâlâ en doğal cümle ve hiçbir şey onu durdurmuyordu.
///
/// ## Kapsam — ve BEYAN EDİLMİŞ sınırları
///
/// **Taranan:** `lib/` içindeki Dart DİZE SABİTLERİ ve `assets/content/`
/// JSON'larındaki kullanıcıya giden metin alanları.
///
/// **Taranmayan, gerekçesiyle:**
/// * `lib/shell_candidate/` — DONDURULMUŞ (M-F-25). Orada 6 eşleşme var (biri
///   ERİŞİLEBİLİR ve kullanıcıya görünüyor — J-122) ve
///   bu kapı onları görmüyor; dondurulmuş bir ağacı düzeltmek bu turun
///   yetkisinde değil. **Kabuk terfi turunun borcu** olarak buraya yazıldı;
///   sessizce "temiz" demiyoruz.
/// * **Yorumlar ve doküman satırları** — kullanıcı görmez. Üstelik bu
///   dosyanın kendisi ve kuralı anlatan yorumlar "yet" kelimesini taşımak
///   ZORUNDA; onları ihlal saymak kuralı yazılamaz hâle getirirdi.
/// * `docs/` — sevk edilmiyor. (İçerik-öncü replikler dosyası bir istisna
///   olarak elle temizlendi: oradaki metin bir gün BAĞLANACAK, yani
///   bugünkü hâliyle sevk edilmeye aday.)
void main() {
  /// Bir zaman taahhüdü veren ifadeler. `yet` tek başına yeterli değil —
  /// aynı sınıfın diğer üyeleri de burada, çünkü "yet"i yasaklayıp
  /// "coming soon" yazmak kuralı harfiyen tutup ruhunu çiğnemek olurdu.
  final RegExp promise = RegExp(
    r"\b(yet|soon|coming soon|for now|in a future|will be added|"
    r"we'll add|planned for)\b",
    caseSensitive: false,
  );

  /// Dart kaynağından KULLANICI dizelerini çıkarır.
  ///
  /// Yorumlar ATILIYOR: `///` ve `//` satırları ile `/* */` blokları. Bu
  /// kapının kendi gerekçesi de dahil, bu depoda kuralı ANLATAN yorumlar
  /// kaçınılmaz olarak yasak kelimeyi taşıyor.
  ///
  /// WIDGET ANAHTARLARI da atılıyor (`Key('soon-x')`): anahtar kullanıcıya
  /// görünmez, testlerin tutunduğu bir tanımlayıcıdır. `coming-soon-note`
  /// anahtarını ihlal saymak, görünmeyen bir adı değiştirmeye zorlardı —
  /// görünen kusuru düzeltmeden gürültü üretmek.
  List<String> dartStrings(String source) {
    final String noKeys =
        source.replaceAll(RegExp(r"Key\('[^']*'\)"), 'Key(_)');
    final String noBlock =
        noKeys.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    final String noLine = noBlock
        .split('\n')
        .where((String l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    return RegExp(r"'((?:[^'\\\n]|\\.)*)'")
        .allMatches(noLine)
        .map((RegExpMatch m) => m.group(1)!)
        .toList();
  }

  test('lib/ — kullanıcı dizgelerinde vaat dili YOK', () {
    final List<String> hits = <String>[];
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      // DONDURULMUŞ ağaç — sınıf dokümanındaki gerekçe.
      if (f.path.contains('shell_candidate')) continue;
      for (final String s in dartStrings(f.readAsStringSync())) {
        if (promise.hasMatch(s)) hits.add('${f.path}: "$s"');
      }
    }
    expect(hits, isEmpty,
        reason: 'VAAT DİLİ: ${hits.join(" · ")}\n'
            'Gerekçenin varlığı bunu affetmiyor — bir zaman taahhüdü '
            'veriyorsun ve onu tutan hiçbir şey yok. Cümlenin geri kalanı '
            'zaten dürüstse, taahhüdü SİL: "Not open yet" → "Not open".');
  });

  test('assets/content — kullanıcı metinlerinde vaat dili YOK', () {
    final List<String> hits = <String>[];
    for (final FileSystemEntity f
        in Directory('assets/content').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.json')) continue;
      void walk(Object? node, String path) {
        if (node is String) {
          if (promise.hasMatch(node)) hits.add('${f.path} $path: "$node"');
        } else if (node is List) {
          for (int i = 0; i < node.length; i++) {
            walk(node[i], '$path[$i]');
          }
        } else if (node is Map) {
          node.forEach((Object? k, Object? v) {
            // `$` önekli alanlar TÜRETİM/GEREKÇE notudur, kullanıcıya
            // gitmez — `$planBasis` gibi alanlar bu kuralı ANLATIRKEN
            // kelimeyi kullanabilmeli.
            if (k is String && k.startsWith(r'$')) return;
            walk(v, '$path.$k');
          });
        }
      }

      walk(jsonDecode(f.readAsStringSync()), '');
    }
    expect(hits, isEmpty,
        reason: 'VAAT DİLİ (içerik): ${hits.join(" · ")}');
  });

  test('KAPALI disiplinlerde GELECEK-ZAMAN iddiası YOK', () {
    // ## Neden düz bir `will` yasağı YANLIŞ olurdu
    //
    // İki cümle ölçüldü, ikisi de AYNI kelimeyi taşıyor, ama yalnız biri
    // vaat:
    //
    //   r20 dersi   "…it will tell you if it loses you"      → DOĞRU
    //   taekwondo   "…will carry a visible accuracy warning" → VAAT
    //
    // Fark kelimede değil ÖZNEDE: birincisi kullanıcının birazdan koşacağı
    // turun BUGÜNKÜ davranışını tarif ediyor (`noVerdict` yuvası çalışıyor
    // ve gerçekten söylüyor); ikincisi var OLMAYAN bir disiplin hakkında
    // konuşuyor. Düz bir `will` yasağı doğru cümleyi de kırmızıya çevirir
    // ve kapıyı gürültüye boğardı — ders #5: bir sınırı olduğundan GENİŞ
    // yazmak, dar yazmak kadar pahalı. Bu yüzden kural KAPSAMLI: gelecek
    // zaman yalnız `coming_soon` disiplinlerin metninde yasak.
    final List<String> hits = <String>[];
    final RegExp future = RegExp(r'\bwill\b(?!\s+not\b)', caseSensitive: false);
    for (final Map<String, dynamic> d in _comingSoon()) {
      for (final String text in _userText(d)) {
        if (future.hasMatch(text)) hits.add('${d['id']}: "$text"');
      }
    }
    expect(hits, isEmpty,
        reason: 'kapalı bir disiplin hakkında GELECEK ZAMAN: '
            '${hits.join(" · ")}\nKart zaten "not open" diyor; bu metnin '
            'işi NEDEN kapalı olduğunu söylemek, ne geleceğini değil.');
  });

  test('KAPALI disiplinlerin hepsi kapalı olma SEBEBİNİ taşıyor', () {
    // 2026-08-07 ölçümü: 7'nin YALNIZ 1'i (kickboxing) sebebi söylüyordu;
    // kalanı ya içerik listeliyordu ("Siu Nim Tao through Biu Jee") ya da
    // kapsam beyanı yapıyordu. Bir YOL HARİTASI ile bir DÜRÜSTLÜK BEYANI
    // aynı şey değil: birincisi ne geleceğini söyler, ikincisi neden bugün
    // olmadığını. Kart zaten "not open" diyor — NEDEN'i bu metin taşımalı.
    //
    // ⚠️ BEYAN EDİLMİŞ SINIR: bu kapı metnin bir engel sözcüğü TAŞIDIĞINI
    // ölçer, gerekçenin DOĞRU ya da iyi olduğunu değil. Kelime listesi bir
    // kalite ölçüsü değil, "burada bir gerekçe olması gerektiği"nin
    // hatırlatıcısı. Kaliteyi insan okuması doğrular; bu ayrımı silmek
    // testi yalancı yapar.
    final RegExp blocker = RegExp(
        r"\b(not in|not built|missing|reference|cannot|can't|do not|"
        r"does not|we have one|refuses|stays out|is not)\b",
        caseSensitive: false);
    final List<String> silent = <String>[];
    for (final Map<String, dynamic> d in _comingSoon()) {
      final String blurb = (d['blurb'] as String?) ?? '';
      if (!blocker.hasMatch(blurb)) silent.add(d['id'] as String);
    }
    expect(silent, isEmpty,
        reason: 'kapalı ama NEDEN kapalı olduğunu söylemeyen disiplin: '
            '$silent');
  });

  test('VAR OLMAYAN MEKANİZMA anlatılmıyor — "unlock" (J-124)', () {
    // ## Yayın envanterinin ilk bulgusu, kapıya çevrildi
    //
    // `_recordedNoteText()` kullanıcıya *"Every progress gate also asks how
    // much of the session the camera could actually analyse"* diyordu.
    // Ölçüldü: **ilerleme kapısı diye bir şey YOK** — `unlock` sözcüğü tüm
    // depoda yalnız o cümlede geçiyordu, içerikte gate alanı yok,
    // `workedSecondsFor` hiç çağrılmıyor. Yani cümle kullanıcıya VAR
    // OLMAYAN bir mekanizmayı öğretiyordu.
    //
    // Bu kapı o sınıfı tutuyor: `unlock` bir MEKANİZMA sözcüğü ve ürün
    // dilinde ancak o mekanizma varsa yeri var. `numericScoresUnlocked`
    // (K8 skor kapısı) AYRI ve gerçek — o yüzden kural dize sabitlerine
    // bakıyor, tanımlayıcılara değil.
    final List<String> hits = <String>[];
    final RegExp mech = RegExp(r'\bunlock', caseSensitive: false);
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final String str in dartStrings(f.readAsStringSync())) {
        if (mech.hasMatch(str)) hits.add('${f.path}: "$str"');
      }
    }
    expect(hits, isEmpty,
        reason: 'kullanıcıya var olmayan bir kilit-açma mekanizması '
            'anlatılıyor: ${hits.join(" · ")}. Böyle bir kapı yazılırsa bu '
            'testin kapsamı da değişmeli — cümle ondan ÖNCE gelemez.');
  });

  test('İÇERİKTE geliştirici-sözleşmesi mekanizması anlatılmıyor (J-131)', () {
    // ## Koordinatör hükmü: iç sözleşme dili ≠ kullanıcı dili
    //
    // `r10`in öğretme metni *"the **progress gate** for this lesson asks for
    // ten minutes of work"* diyordu. Sayı GERÇEK (`curriculum.json`
    // `gates.sessionMinutes=10`) — ama o kapı bir **içerik doğrulama
    // sözleşmesi**: `curriculum_binding_test` plan aritmetiğini ona karşı
    // zorluyor. **Çalışma zamanında geçilen bir kapı DEĞİL** (J-124:
    // `workedSecondsFor` hiç çağrılmıyor).
    //
    // Cümle teknik olarak yanlış değildi; **kullanıcının kurduğu MODEL**
    // yanlıştı — *"geçeceğim bir kapı var"*. Bir doğrulama kavramının
    // gerçek olması, kullanıcıya anlatılabilir olduğunu göstermez.
    //
    // ## ÖLÇÜT — ve neden kelime yasağı DEĞİL
    //
    // İki kapılı test: ① mekanizma çalışma zamanında var ve kullanıcı onu
    // **gözleyebiliyor** mu · ② cümle kullanıcıyı bir **eyleme** çağırıyor
    // mu. `progress gate` ①'de kaldı ve ②'yi yapıyordu.
    //
    // Ölçüm 9 eşleşme buldu ve **6'sı bilerek DURDU**: `confidence gate`
    // (①VAR — kullanıcı "seni göremiyorum"u görür), `phase machine`
    // (①gözlenmez ama ②YOK — bu bir KÖKEN beyanı), `engine`/`rule set`/
    // `flag` (mekanizma adı değil, sade İngilizce). Blanket bir kelime
    // yasağı bunları da öldürürdü — ailenin 04:50'de `will` için ölçtüğü
    // tuzağın aynısı: 17 eşleşmenin hepsi `will not`/`will never` idi,
    // yani hattın EN GÜÇLÜ dürüstlük dili.
    //
    // Bu yüzden liste DAR ve KANITA dayalı: yalnız geliştirici-tarafı
    // doğrulama sözleşmesini adlandıran ifadeler.
    const List<String> devContract = <String>[
      'progress gate', 'sessionMinutes', 'curriculum',
    ];
    final List<String> hits = <String>[];
    void walk(Object? node, String path) {
      if (node is String) {
        for (final String w in devContract) {
          if (node.toLowerCase().contains(w.toLowerCase())) {
            hits.add('$path: "$w" → "$node"');
          }
        }
      } else if (node is List) {
        for (int i = 0; i < node.length; i++) {
          walk(node[i], '$path[$i]');
        }
      } else if (node is Map) {
        node.forEach((Object? k, Object? v) {
          // `$` notları geliştiriciye yazılır ve bu kuralı ANLATIRKEN
          // kavramı adıyla anmak zorundadır.
          if (k is String && k.startsWith(r'$')) return;
          walk(v, '$path.$k');
        });
      }
    }
    walk(
        jsonDecode(File('assets/content/library.json').readAsStringSync()),
        'library.json');

    expect(hits, isEmpty,
        reason: 'GELİŞTİRİCİ SÖZLEŞMESİ kullanıcı metnine sızdı — sayı '
            'gerçek olabilir ama mekanizma kullanıcının GÖZLEYEBİLECEĞİ bir '
            'şey değilse anlatılamaz (J-131): ${hits.join(" · ")}');
  });

  test('KİLİTLİ ders içeren KURSUN hedefi bunu söylüyor (J-132)', () {
    // ## Katman: disiplin kapısı vardı, KURS kapısı yoktu
    //
    // `boxing.intermediate`in hedefi *"Combinations, tempo control and
    // recovery under fatigue"* diyordu. Ölçüldü: kursun **4 dersinin 3'ü
    // KİLİTLİ**, ilk andığı konu (`Combinations`) tam da kilitli dersin
    // kendisi, ve `tempo control` bu kursta **hiç yok** — o ders
    // `conditioning`de.
    //
    // Sınıf J-131 ile aynı: cümle kelime kelime yanlış değil, ama
    // kullanıcının kurduğu **model** ürünle çelişiyor — ve çelişme bir
    // dokunuş sonra ortaya çıkıyor. Hedef **iki** canlı yüzeyde:
    // `select_page` (disiplin listesi) ve `course_page` (kurs başlığı).
    //
    // Kapalı DİSİPLİN için gerekçe kapısı J-112'den beri var; aynı standart
    // kurs katmanına inmemişti. Bu, gecenin beşinci **katman** kapsam
    // kusuru (J-122 donmuş ağaç · J-126 token yolu · J-129 içerik dosyası ·
    // J-131 içerik katmanı · J-132 kurs katmanı) — ve ilk kez ölçüm
    // kusurdan ÖNCE geldi.
    //
    // ## ⚠️ NE ÖLÇMÜYOR
    //
    // * **Başka sözcüklerle söylemeyi**: hedef "punch chains" derse kapı
    //   görmez. Sınırlı ama kanıta dayalı — bulunan kusur birebir addı.
    // * **Ters yönü**: hedefin kursta HİÇ olmayan bir konuyu anması
    //   (`tempo control`). Anlam işi, mekanikleştirilemez — sınıfı
    //   **imkânsız**, ve bu yüzden kovalanmıyor.
    // * **Gerekçenin KALİTESİNİ**: işareti taşımak yeterli sayılıyor.
    const List<String> limitMarkers = <String>[
      'locked', 'not open', 'closed',
    ];
    final Map<String, dynamic> lib = (jsonDecode(
            File('assets/content/library.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();
    final List<String> hits = <String>[];
    int coursesWithLocks = 0;
    for (final dynamic d in lib['disciplines'] as List<dynamic>) {
      for (final dynamic c
          in ((d as Map)['courses'] as List<dynamic>? ?? const <dynamic>[])) {
        final Map<dynamic, dynamic> course = c as Map<dynamic, dynamic>;
        final List<dynamic> lessons =
            course['lessons'] as List<dynamic>? ?? const <dynamic>[];
        final List<dynamic> locked = lessons
            .where((dynamic l) => (l as Map)['status'] == 'locked')
            .toList();
        if (locked.isEmpty) continue;
        coursesWithLocks++;
        final String goal = (course['goal'] as String? ?? '').toLowerCase();
        if (!limitMarkers.any(goal.contains)) {
          hits.add('${course['id']}: ${locked.length}/${lessons.length} ders '
              'kilitli ama hedef bunu SÖYLEMİYOR → "${course['goal']}"');
        }
      }
    }
    // VAKUM KAPISI: kilitli dersi olan kurs hiç bulunamazsa kural boşa döner
    // ve kapı sessizce geçer (aile dersi #4).
    expect(coursesWithLocks, greaterThan(0),
        reason: 'kilitli ders içeren kurs bulunamadı — kapı kendi girdisini '
            'bulamamış olabilir');
    expect(hits, isEmpty,
        reason: 'KURS HEDEFİ açılamayan bir kursu açılabilir gibi tarif '
            'ediyor: ${hits.join(" · ")}');
  });

  test('NEGATİF İKİZ — kilitsiz kurstan CAVEAT İSTENMİYOR (J-132)', () {
    // Ters ikiz: kapı *"her hedef sınır işareti taşısın"*a genişlerse
    // `foundations` ve `conditioning` kırmızıya döner — oysa oralarda
    // kilitli ders YOK ve söylenecek bir sınır da yok. **Olmayan bir
    // sınırı beyan etmek, dürüstlük değil gürültüdür.**
    final Map<String, dynamic> lib = (jsonDecode(
            File('assets/content/library.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();
    final List<String> clean = <String>[];
    for (final dynamic d in lib['disciplines'] as List<dynamic>) {
      for (final dynamic c
          in ((d as Map)['courses'] as List<dynamic>? ?? const <dynamic>[])) {
        final Map<dynamic, dynamic> course = c as Map<dynamic, dynamic>;
        final List<dynamic> lessons =
            course['lessons'] as List<dynamic>? ?? const <dynamic>[];
        if (lessons.any((dynamic l) => (l as Map)['status'] == 'locked')) {
          continue;
        }
        final String goal = (course['goal'] as String? ?? '').toLowerCase();
        if (!goal.contains('locked') && !goal.contains('not open')) {
          clean.add(course['id'] as String);
        }
      }
    }
    expect(clean, isNotEmpty,
        reason: 'kilitsiz her kurs da sınır işareti taşıyor — kapı fazla '
            'genişlemiş ve olmayan bir sınırı beyan ettiriyor olabilir');
  });

  test('NEGATİF İKİZ — kapı FAZLA GENİŞ değil: gözlenebilir mekanizma DURUYOR',
      () {
    // Bu ikiz alışılmışın tersini koruyor. Normalde ikiz *"düzeltme
    // kaldırılırsa kırılır mı"* diye sorar; bu ikiz **kapının kendisi fazla
    // genişlerse** kırılır.
    //
    // Somut risk: bir sonraki tur *"gate kelimesini tamamen yasaklayalım"*
    // diyebilir. O an `muay_thai`in *"our confidence gate already refuses
    // to judge"* cümlesi ölür — oysa o mekanizma ÇALIŞIYOR ve kullanıcı
    // sonucunu ekranda görüyor. Onu silmek, çalışan bir dürüstlüğü
    // kelimenin biçimi yüzünden kaybetmek olurdu.
    final Map<String, dynamic> lib = (jsonDecode(
            File('assets/content/library.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();
    final String muay = ((lib['disciplines'] as List<dynamic>)
            .firstWhere((dynamic d) => (d as Map)['id'] == 'muay_thai')
        as Map)['blurb'] as String;
    expect(muay.toLowerCase(), contains('confidence gate'),
        reason: 'gözlenebilir bir mekanizmanın adı içerikten kalkmış — '
            'kapı fazla genişlemiş olabilir. J-131 ölçütü kelimeye değil '
            'MEKANİZMANIN GÖZLENEBİLİRLİĞİNE bakar');
  });

  test('İTHAL EDİLEN kabuk sınıflarında VAAT DİLİ YOK (J-123)', () {
    // ## Kategori düzeltmesi: "donmuş" konum değil, ERİŞİM
    //
    // Bu kapı önce `shell_candidate/`ı hiç taramıyordu (dondurulmuş) ve
    // sayıyı (6) kör nokta olarak kaydediyordu. J-122 o sayının **ne
    // olduğunu** ölçtü: 6'nın **5'i erişilemez**, **1'i CANLI** ve 7 kapalı
    // disiplin kartında kullanıcıya görünüyordu.
    //
    // Ders (koordinatör hükmü): **bir bileşen ithal edildiği anda donmuş
    // olmaktan çıkar.** Etiket dosyanın KONUMUNA değil ERİŞİLEBİLİRLİĞİNE
    // bakmalı:
    //   app hiç ithal etmiyor  → gerçekten donmuş, freeze kapsamında
    //   app ithal ediyor       → CANLI, freeze kapsamında DEĞİL
    //
    // ## `show` bildirimine SAYGI — yoksa kapı fazla geniş olur
    //
    // `library_pages.dart` ithal ediliyor ama **yalnız `WhyNotPage` ile**
    // (`show`). Dosyayı bütün olarak taramak, erişilemez 4 ihlali "canlı"
    // ilan ederdi — ve fazla geniş bir kapı, doğru bir ilerlemeyi kırmızıya
    // çevirir (ders #5'in test tarafı, J-120'de bir kez ödendi). Bu yüzden
    // kapsam SINIFA iniyor: `show` varsa yalnız o sınıfların gövdesi.
    final Map<String, Set<String>?> imported = _importedShellFiles();
    expect(imported, isNotEmpty,
        reason: 'app donmuş ağaçtan hiçbir şey ithal etmiyor görünüyor — '
            'tarama kendi girdisini bulamamış, kapı vakum-doğru');

    final List<String> live = <String>[];
    imported.forEach((String file, Set<String>? shown) {
      final String src = File('lib/shell_candidate/$file').readAsStringSync();
      final Map<String, String> bodies = _classBodies(src);
      // ⚠️ İLK YAZIŞIMDA "özel sınıf = erişilebilir" varsaydım ve kapı
      // kendi FAZLA GENİŞLİĞİNİ gösterdi: `_ItemCard`ı canlı ilan etti,
      // oysa onu yalnız `LibraryPage` kullanıyor ve o `show` listesinde
      // YOK. Varsayım değil YÜRÜYÜŞ gerekiyor — özel bir sınıf ancak
      // ERİŞİLEBİLİR bir sınıf ondan söz ediyorsa erişilebilirdir.
      for (final String name in _reachableClasses(bodies, shown)) {
        for (final String str in dartStrings(bodies[name]!)) {
          if (promise.hasMatch(str)) live.add('$file/$name: "$str"');
        }
      }
    });

    expect(live, isEmpty,
        reason: 'KULLANICIYA GÖRÜNEN vaat dili: ${live.join(" · ")}\n'
            'Bu dosya donmuş ağaçta olabilir ama app onu İTHAL EDİYOR — '
            'konum freeze verir, erişim vermez.');
  });

  test('ERİŞİLEMEZ kabuk borcu SESSİZ DEĞİL — sayı ölçülü', () {
    // Kalan borç: app'in hiç ithal etmediği kabuk dosyaları. Bunlar
    // kullanıcıya ULAŞMIYOR, yani ürün kusuru değil — ama "orada bir şey
    // yok" da değil. Sayı burada duruyor ki kabuk terfi turu neyi
    // devraldığını bilsin.
    final Map<String, Set<String>?> imported = _importedShellFiles();
    int unreachable = 0;
    for (final FileSystemEntity f
        in Directory('lib/shell_candidate').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String name = f.uri.pathSegments.last;
      final String src = f.readAsStringSync();
      if (!imported.containsKey(name)) {
        unreachable += dartStrings(src).where(promise.hasMatch).length;
        continue;
      }
      // İthal EDİLEN dosyanın `show` dışında kalan sınıfları da erişilemez.
      final Set<String>? shown = imported[name];
      if (shown == null) continue;
      final Map<String, String> bodies = _classBodies(src);
      final Set<String> live = _reachableClasses(bodies, shown);
      bodies.forEach((String cls, String body) {
        if (live.contains(cls)) return;
        unreachable += dartStrings(body).where(promise.hasMatch).length;
      });
    }
    expect(unreachable, lessThanOrEqualTo(5),
        reason: 'erişilemez kabuk borcu ARTTI ($unreachable) — donmuş bir '
            'ağaca yeni ihlal eklenmiş olamaz, biri dosyayı değiştirdi');
  });
}

/// `library.json`daki kapalı disiplinler.
List<Map<String, dynamic>> _comingSoon() {
  final Map<String, dynamic> lib =
      (jsonDecode(File('assets/content/library.json').readAsStringSync())
              as Map)
          .cast<String, dynamic>();
  return (lib['disciplines'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .where((Map<String, dynamic> d) => d['status'] == 'coming_soon')
      .toList();
}

/// Bir disiplin düğümünün KULLANICIYA giden metinleri — `$` önekli
/// türetim/gerekçe alanları hariç (onlar kuralı ANLATIRKEN kelimeyi
/// kullanabilmeli).
List<String> _userText(Object? node) {
  final List<String> out = <String>[];
  void walk(Object? n) {
    if (n is String) {
      out.add(n);
    } else if (n is List) {
      n.forEach(walk);
    } else if (n is Map) {
      n.forEach((Object? k, Object? v) {
        if (k is String && k.startsWith(r'$')) return;
        walk(v);
      });
    }
  }

  walk(node);
  return out;
}

/// `lib/app/` + `lib/main.dart`ın donmuş ağaçtan İTHAL ETTİĞİ dosyalar.
///
/// Değer: `show` listesindeki adlar, ya da `show` yoksa `null` (= dosyanın
/// tamamı erişilebilir). Bu ayrım kapının kapsamını belirliyor ve
/// **konumla erişimi karıştırmamanın** tek yolu.
Map<String, Set<String>?> _importedShellFiles() {
  final Map<String, Set<String>?> out = <String, Set<String>?>{};
  final RegExp imp = RegExp(
      r"""^\s*import\s+'[^']*shell_candidate/([a-z_]+\.dart)'([^;]*);""",
      multiLine: true);
  final List<File> sources = <File>[
    File('lib/main.dart'),
    ...Directory('lib/app')
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart')),
  ];
  for (final File f in sources) {
    for (final RegExpMatch m in imp.allMatches(f.readAsStringSync())) {
      final String file = m.group(1)!;
      final String tail = m.group(2)!;
      final RegExpMatch? show = RegExp(r'show\s+([A-Za-z0-9_,\s]+)').firstMatch(tail);
      final Set<String>? names = show
          ?.group(1)!
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toSet();
      // AYNI dosya iki yerden ithal edilebilir: biri `show`suz ise dosyanın
      // tamamı erişilebilir demektir — dar olanı korumak yanlış olurdu.
      if (out.containsKey(file) && (out[file] == null || names == null)) {
        out[file] = null;
      } else if (out.containsKey(file)) {
        out[file] = <String>{...out[file]!, ...names!};
      } else {
        out[file] = names;
      }
    }
  }
  return out;
}

/// Kaynaktaki üst düzey sınıfları gövdeleriyle döndürür — kaba ama yeterli
/// bir ayrıştırma: süslü parantez sayarak sınır buluyor. Kapının işi
/// derleyicilik değil, KAPSAM belirlemek.
Map<String, String> _classBodies(String source) {
  final Map<String, String> out = <String, String>{};
  final RegExp head = RegExp(r'^(?:abstract\s+|final\s+|sealed\s+)*class\s+(\w+)',
      multiLine: true);
  for (final RegExpMatch m in head.allMatches(source)) {
    final int braceStart = source.indexOf('{', m.end);
    if (braceStart < 0) continue;
    int depth = 0;
    int i = braceStart;
    for (; i < source.length; i++) {
      if (source[i] == '{') depth++;
      if (source[i] == '}') {
        depth--;
        if (depth == 0) break;
      }
    }
    out[m.group(1)!] = source.substring(braceStart, i.clamp(0, source.length));
  }
  return out;
}

/// [shown] adlarından başlayıp GEÇİŞLİ olarak erişilebilir sınıf kümesini
/// yürür. `shown` `null` ise dosyanın tamamı erişilebilirdir.
///
/// Neden yürüyüş: özel (`_`) bir sınıf kendiliğinden erişilebilir DEĞİL —
/// yalnız erişilebilir bir sınıfın gövdesinde adı geçiyorsa öyledir.
/// "Özel = erişilebilir" varsayımı bu kapının ilk hâliydi ve `_ItemCard`ı
/// yanlışlıkla canlı ilan etti; fazla geniş bir kapı, doğru bir ilerlemeyi
/// kırmızıya çevirir.
Set<String> _reachableClasses(Map<String, String> bodies, Set<String>? shown) {
  final Set<String> seen = <String>{};
  final List<String> queue = <String>[
    ...bodies.keys.where((String c) => shown == null || shown.contains(c)),
  ];
  while (queue.isNotEmpty) {
    final String cls = queue.removeLast();
    if (!seen.add(cls)) continue;
    final String? body = bodies[cls];
    if (body == null) continue;
    for (final String other in bodies.keys) {
      if (seen.contains(other) || other == cls) continue;
      if (RegExp('\\\\b$other\\\\b').hasMatch(body)) queue.add(other);
    }
  }
  return seen;
}
