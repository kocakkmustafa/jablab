import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab/app/session_screen.dart';

import 'app_pump.dart';

/// "VARILABİLİR AMA BOŞ" ORANI (J-230) — aile 08-07'de ROTA saydı, kimse
/// VARILAN YERDE bir şey olup olmadığını saymadı.
///
/// ## ⛔ TANIM ÖNCE YAZILDI, SONRA ÖLÇÜLDÜ
///
/// Sıra bağlayıcıydı: *tanım ölçümden sonra yazılırsa, tanım sayıyı takip
/// eder* — eşiği adaya bakarak yazmanın aynısı. Choreia'nın tanımı
/// (`library.cards × offers(runnableSteps) × canStart`) **onun içerik
/// modeline özgü** ve kopyalanmadı.
///
/// ### JabLab'ın birimi: BASILABİLİR İÇERİK KONTROLÜ
///
/// Choreia'da birim *stil kartı*. Bende içerik üç kademede sunuluyor ve
/// üçü de basılabilir: **disiplin kartı** (Sayfa A) → **kurs kartı** →
/// **ders kartı** (Sayfa B). Ekran değil **kontrol** sayılıyor, çünkü
/// sorulan şey *"kaç ekran var"* değil ***"bastığım şey beni bir yere
/// götürüyor mu"***.
///
/// ### ÇIKMAZ SOKAK — üç şartın ÜÇÜ birden
///
/// Bir kontrol **çıkmaz sokaktır** ancak ve ancak:
/// 1. kullanıcı ona **basabiliyorsa** (ekranda, etkin), **ve**
/// 2. bastığında **yapılabilir bir iş sunulmuyorsa**, **ve**
/// 3. **neden sunulmadığı ADIYLA söylenmiyorsa.**
///
/// ⚠️ **Üçüncü şart bu hattın ayırt edici yeri.** JabLab'ın kapalı
/// yüzeyleri **gerekçe taşıyor** (`lockedReason`, `blurb`,
/// `honesty.notMeasured`). ***Kilitli-ama-gerekçeli bir yüzey çıkmaz sokak
/// DEĞİLDİR*** — kullanıcı bir yere varır ve **neden burada bir şey
/// olmadığını öğrenir**; bu, ürünün dürüst-hâl tasarımının kendisi.
/// Çıkmaz sokak, **sessiz** boşluktur.
///
/// > ***Bir yokluk, ADI konmuşsa bir cevaptır; adı konmamışsa bir çıkmaz.***
///
/// ### Envanter YÜRÜYEREK üretiliyor
///
/// Kodda desen aranmıyor: uygulama açılıyor ve **ekranda görünen her
/// içerik kontrolüne basılıyor.** Sayılan şey *kodda var olan rota* değil,
/// **kullanıcının VARABİLDİĞİ yer** — koddan türetilen bir envanter,
/// ulaşılamayan bir kartı da sayardı.
///
/// ## 📊 SONUÇ (2026-08-12): 30 = 20 iş sunan + 10 adıyla boş + **0 ÇIKMAZ**
///
/// 8 disiplin + 3 kurs + 19 ders = 30 kontrol; payda içerik modeliyle
/// birebir tutuyor.
///
/// ## ⚠️ SIFIRIN MEKANİZMASI — ve BU KAPININ KANITLANAMAYAN YARISI
///
/// Sıfır **şans değil, YAPISAL**: JabLab'ın içerik doğrulayıcısı
/// (`Library.validate`, `ContentRepository.load` içinde) çıkmaz sokağı
/// **ifade edilemez** kılıyor. İki sabotaj denendi, **ikisi de UI'a
/// varmadan reddedildi**:
/// * gerekçesiz kapalı disiplin → doğrulama fırlattı
/// * **açık ama kurssuz** disiplin (Choreia'nın tam şekli) → doğrulama
///   fırlattı; ürün **dürüst hata ekranını** gösterdi, çıkmaz sokağı değil.
///
/// 🔴 **AMA BUNUN BEDELİ VAR VE ADIYLA YAZILIYOR:** bu kapının **çıkmaz
/// dalı hiç ateşlenmedi** — çünkü doğrulamayı geçen bir çıkmaz sokak
/// **kuramadım.** Yani *"0 çıkmaz"* iki şeye dayanıyor: yürüyüşün
/// bulamaması **ve** yukarıdaki kapının kurulamaz kılması — ***ama
/// dedektörün kendisi pozitif kontrolsüz.***
/// > *Bir kapının yeşili, ateşlendiği görülmeden tam kanıt değildir.*
///
/// 🪤 Ve dedektör bu turda **iki kez** yanlıştı, ikisini de sabotaj buldu:
/// ① yürüyüş modeli yanlıştı (`item-` sayfa değiştirmiyor, yerinde
/// açılıyor) → *"iş sunan 0"* deyip **vakum-doğru** geçti ② gerekçe
/// araması **tüm ekranı** tarıyordu → komşu disiplinin metni kickboxing'i
/// "gerekçeli" sayıyordu. ***Bir kontrolün gerekçesini ekran düzeyinde
/// aramak, KOMŞUNUN dürüstlüğünü ona mal etmektir.***
/// DEDEKTÖR — hem gerçek yürüyüş hem sentetik fixture bunu kullanır.
///
/// Ayrı bir fonksiyon olması şart: fixture bir KOPYAyı sınasaydı, gerçek
/// yürüyüşteki dedektörün ateşlendiğini kanıtlamazdı.
///
/// `id` kartına basıldıktan SONRA çağrılır. Gerekçe araması **kartın ALT
/// AĞACINA** kapsanmış — ekran düzeyinde aramak komşunun dürüstlüğünü ona
/// mal ederdi (bu turda sabotajla ölçüldü).
bool hasNamedReason(String id) => find
    .descendant(
        of: find.byKey(ValueKey<String>(id)),
        matching: find.textContaining(RegExp(
            'not open|not in the rule set|left out|rule set',
            caseSensitive: false)))
    .evaluate()
    .isNotEmpty;

void main() {
  const OnboardingStore seen = OnboardingStore(seenOverride: true);

  setUp(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(1200, 4000);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('VARILABİLİR AMA BOŞ — oran ölçülüyor', (WidgetTester t) async {
    await t.runAsync(() async {
      await t.pumpWidget(const JabLabApp(onboarding: seen));
    });
    await settleAppLoad(t);
    await t.pumpAndSettle();
    expect(find.byType(SelectPage), findsOneWidget,
        reason: 'giriş yüzeyi Sayfa A değil — yürüyüş yanlış yerden başlıyor');

    // ── 1. KADEME: disiplin kartları ────────────────────────────────────
    final Finder discCards = find.byWidgetPredicate((Widget w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('item-'));
    final List<String> discIds = discCards
        .evaluate()
        .map((e) => (e.widget.key! as ValueKey<String>).value)
        .toList();
    expect(discIds, isNotEmpty, reason: 'hiç disiplin kartı bulunamadı');

    int reachable = 0;      // basılabilen kontrol
    int withWork = 0;       // bastığında yapılabilir iş sunan
    int namedEmpty = 0;     // boş AMA gerekçesi adıyla yazılı
    final List<String> deadEnds = <String>[];

    Future<bool> tapIfEnabled(Finder f) async {
      if (f.evaluate().isEmpty) return false;
      await t.tap(f.first, warnIfMissed: false);
      await t.pumpAndSettle();
      return true;
    }

    // ⚠️ GEZİNME MODELİ ÖLÇÜLDÜ, VARSAYILMADI (ilk yürüyüşüm YANLIŞTI):
    // `item-X`e basmak sayfa DEĞİŞTİRMİYOR — `setState` ile YERİNDE açılıyor
    // (`select_page.dart:136`) ve kurs kartları AYNI sayfada beliriyor.
    // İlk sürümüm "sayfa değişti mi" diye bakıyordu, hiç inemedi ve
    // "iş sunan 0" diyerek YEŞİL geçti — vakum-doğru bir geçiş.
    for (final String id in discIds) {
      reachable++;
      final int before = find
          .byWidgetPredicate((Widget w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('course-'))
          .evaluate()
          .length;
      if (!await tapIfEnabled(find.byKey(ValueKey<String>(id)))) {
        deadEnds.add('$id (basılamadı)');
        continue;
      }
      final Finder courseCards = find.byWidgetPredicate((Widget w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('course-'));
      final List<String> courseIds = courseCards
          .evaluate()
          .map((e) => (e.widget.key! as ValueKey<String>).value)
          .toList();

      if (courseIds.length <= before) {
        // Açıldı ama KURS ÇIKMADI → gerekçe görünüyor mu?
        //
        // ⚠️ KAPSAM KARTIN ALT AĞACINA İNDİRİLDİ — ve bunu SABOTAJ buldu.
        // İlk sürüm `find.textContaining(...)` ile TÜM EKRANI tarıyordu;
        // kickboxing'in gerekçesini sildim ve kapı ÖTMEDİ, çünkü KOMŞU
        // disiplinlerin metni ölçütü karşılıyordu.
        // > ***Bir kontrolün gerekçesini ekran düzeyinde aramak, KOMŞUNUN
        // > dürüstlüğünü ona mal etmektir.***
        // Ölçüldü (`find.descendant`): gerekçe metni `item-` kartının
        // ALT AĞACINDA — kickboxing alt ağacı 1, tüm ekran 2.
        final bool named = hasNamedReason(id);
        if (named) {
          namedEmpty++;
        } else {
          deadEnds.add('$id (açıldı, kurs YOK, gerekçe de yok)');
        }
        continue;
      }
      withWork++;

      for (final String cid in courseIds) {
        reachable++;
        if (!await tapIfEnabled(find.byKey(ValueKey<String>(cid)))) {
          deadEnds.add('$cid (basılamadı)');
          continue;
        }
        expect(find.byType(CoursePage), findsWidgets,
            reason: '$cid: kurs kartına basıldı ama CoursePage açılmadı — '
                'yürüyüş modeli yine yanlış olabilir');
        final List<String> lessonIds = find
            .byWidgetPredicate((Widget w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('lesson-'))
            .evaluate()
            .map((e) => (e.widget.key! as ValueKey<String>).value)
            .toList();
        if (lessonIds.isEmpty) {
          deadEnds.add('$cid (kurs açıldı, DERS YOK)');
        } else {
          withWork++;
        }

        for (final String lid in lessonIds) {
          reachable++;
          final Finder card = find.byKey(ValueKey<String>(lid));
          if (card.evaluate().isEmpty) {
            deadEnds.add('$lid (kart kayboldu)');
            continue;
          }
          await t.tap(card.first, warnIfMissed: false);
          await t.pumpAndSettle();
          if (find.byType(SessionScreen).evaluate().isNotEmpty) {
            withWork++;
            await t.pageBack();
            await t.pumpAndSettle();
          } else {
            // Gerekçe DERS KARTININ ALT AĞACINDA aranır — disiplin kademesindeki
            // aynı ders: ekran düzeyinde regex, komşu kurs metnine yaslanıyordu
            // ("not available" → "unavailable" olunca üç kilitli ders gerekçesi
            // görünürken çıkmaz sayıldı). Ürünün kilit gerekçesi
            // `locked-why-<ders>` anahtarlı metindir (course_page.dart).
            final Finder why = find.descendant(
              of: card.first,
              matching: find.byKey(
                ValueKey<String>('locked-why-${lid.substring('lesson-'.length)}'),
              ),
            );
            final bool named = why.evaluate().any(
                  (Element e) =>
                      ((e.widget as Text).data ?? '').trim().isNotEmpty,
                );
            if (named) {
              namedEmpty++;
            } else {
              deadEnds.add('$lid (açılmadı, gerekçe de görünmüyor)');
            }
          }
        }
        await t.pageBack();
        await t.pumpAndSettle();
      }
    }

    // (d) YÜRÜYÜŞ EKSİK YÜRÜNMÜŞ OLABİLİR — İÇERİKTEN TÜRETİLEN BEKLENEN
    // SAYIYA karşı denetleniyor (J-232, Lissom'un bulgusu).
    //
    // > ***Yürüyüş de eksik yürünürse yalan söyler:*** kaydırmayan bir
    // > yürüyüş "0 kusur"u YANLIŞ SEBEPLE basar. Kendi payda toplamım bunu
    // > yakalayamaz — yalnız YÜRÜDÜĞÜMÜ sayar. Referans içerikten gelmeli.
    final Map<String, dynamic> lib = (jsonDecode(
            File('assets/content/library.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();
    int expected = 0;
    for (final dynamic d in lib['disciplines'] as List<dynamic>) {
      expected++; // disiplin kartı
      for (final dynamic c
          in ((d as Map)['courses'] as List<dynamic>? ?? const <dynamic>[])) {
        expected++; // kurs kartı
        expected +=
            ((c as Map)['lessons'] as List<dynamic>? ?? const <dynamic>[])
                .length; // ders kartları
      }
    }
    expect(reachable, expected,
        reason: 'YÜRÜYÜŞ EKSİK: içerikten türetilen $expected kontrol '
            'beklenirken $reachable yürünmüş. Kaydırma/ulaşamama yüzünden '
            'atlanan kartlar "çıkmaz yok" sonucunu YANLIŞ SEBEPLE üretir.');

    // ③ PAYDA + İŞLEM — ve sayaçlar BAĞIMSIZ (türetilmiyor).
    // ignore: avoid_print
    print('  ÇIKMAZ SOKAK · varılabilir kontrol $reachable = '
        'iş sunan $withWork + adıyla boş $namedEmpty + ÇIKMAZ '
        '${deadEnds.length}');
    expect(withWork + namedEmpty + deadEnds.length, reachable,
        reason: 'payda TOPLAMIYOR — bir kontrol hiçbir kovaya girmemiş');

    // ignore: avoid_print
    if (deadEnds.isNotEmpty) print('  🔴 ${deadEnds.join("\n  🔴 ")}');

    expect(deadEnds, isEmpty,
        reason: 'ÇIKMAZ SOKAK: basılıyor, bir şey sunmuyor, ve NEDEN '
            'sunmadığını da söylemiyor. Bir yokluk adı konmuşsa cevaptır; '
            'adı konmamışsa çıkmazdır.');
  });

  /// 🧪 DEDEKTÖRÜN POZİTİF KONTROLÜ — DOĞRULAYICININ ALTINDAN (J-232).
  ///
  /// J-230'da *"0 çıkmaz"* raporladım ama **dedektörün ateşlendiğini
  /// kanıtlayamadım**: `Library.validate` çıkmaz sokağı **ifade edilemez**
  /// kılıyor, iki sabotaj da UI'a varmadan reddedildi.
  /// > *Bir kapının yeşili, ateşlendiği görülmeden tam kanıt değildir.*
  ///
  /// Koordinatör hükmü: doğrulayıcı üstte engelliyorsa, dedektörü
  /// **ALTINDAN** sına — `ShellLibrary` **doğrudan** kurulur (JSON yolu ve
  /// `validate` hiç çalışmaz) ve `SelectPage`e verilir.
  /// ⛔ Ürün yolu değişmedi, doğrulayıcı gevşetilmedi.
  ///
  /// 📌 Ostinato'nun vakasının TERSİ: orada **var olmayan** bir riski test
  /// etmek vakum-doğru olurdu; burada risk **gerçek ama üretimde
  /// ERİŞİLEMEZ**, ve fixture onu erişilebilir kılıyor.
  testWidgets('🧪 DEDEKTÖR ATEŞLENİYOR — sentetik çıkmaz sokakta',
      (WidgetTester t) async {
    const ShellLibrary synthetic = ShellLibrary(
      title: 'Sentetik',
      items: <ShellItem>[
        // AÇIK görünüyor, kursu YOK, ve gerekçe metni de YOK → çıkmaz sokak.
        ShellItem(
          id: 'ghost',
          title: 'Ghost',
          status: ItemStatus.live,
          courses: <ShellCourse>[],
          // ⚠️ BOŞ DEĞİL — üçüncü bir yapısal engel var: honesty_box
          // 'notMeasured.length > 0' assert'i boş listeyle çizdirmiyor.
          // Bu yüzden liste DOLU ama içinde KAPALILIK SEBEBİ yok: kart bir
          // şey söylüyor, ama "burada neden iş yok"u söylemiyor.
          measured: <String>['Stance'],
          notMeasured: <String>['Leg technique'],
        ),
      ],
      exclusions: <ShellExclusion>[],
    );

    await t.pumpWidget(MaterialApp(
      home: SelectPage(
        library: synthetic,
        onOpenCourse: (_) {},
        onOpenWhyNot: () {},
        onOpenSettings: () {},
      ),
    ));
    await t.pumpAndSettle();

    final Finder card = find.byKey(const ValueKey<String>('item-ghost'));
    expect(card, findsOneWidget,
        reason: 'sentetik kart çizilmedi — fixture UI\'a ulaşmıyor, '
            'bu kontrolün sonucu ANLAMSIZ');
    await t.tap(card.first, warnIfMissed: false);
    await t.pumpAndSettle();

    // Kurs YOK.
    expect(
        find.byWidgetPredicate((Widget w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('course-')),
        findsNothing,
        reason: 'sentetik öğe kurs üretti — fixture yanlış kurulmuş');

    // 🎯 ASIL İDDİA: dedektör bu kartı GEREKÇESİZ sayıyor → ÇIKMAZ.
    expect(hasNamedReason('item-ghost'), isFalse,
        reason: 'DEDEKTÖR ATEŞLENMİYOR: gerekçesi olmayan, kurssuz, AÇIK bir '
            'kart "gerekçeli" sayıldı. J-230\'un "0 çıkmaz" sonucu bu '
            'kontrol olmadan pozitif-kontrolsüzdü; bu test onu kapatıyor.');

    // NEGATİF İKİZ: gerekçe VARSA dedektör susmalı (aksi hâlde kapı, dürüst
    // kapalı yüzeyleri de çıkmaz sayardı — 10 meşru kova kırmızıya boyanırdı).
    await t.pumpWidget(MaterialApp(
      home: SelectPage(
        library: const ShellLibrary(
          title: 'Sentetik',
          items: <ShellItem>[
            ShellItem(
              id: 'named',
              title: 'Named',
              status: ItemStatus.comingSoon,
              courses: <ShellCourse>[],
              measured: <String>[],
              notMeasured: <String>['This discipline is not open'],
            ),
          ],
          exclusions: <ShellExclusion>[],
        ),
        onOpenCourse: (_) {},
        onOpenWhyNot: () {},
        onOpenSettings: () {},
      ),
    ));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey<String>('item-named')).first,
        warnIfMissed: false);
    await t.pumpAndSettle();
    expect(hasNamedReason('item-named'), isTrue,
        reason: 'gerekçeli bir kapalı yüzey ÇIKMAZ sayılıyor — kapı fazla '
            'geniş, dürüst hâlleri kusur diye raporlar');
  });
}
