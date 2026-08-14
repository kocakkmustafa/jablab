import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_page.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_screen.dart';

import 'app_pump.dart';

/// 👁️ YÜZEY YÜRÜYÜŞÜ — ölçtüğü şey *"kullanıcı ne OKUYOR"*.
///
/// ## NEDEN VAR — ailenin en pahalı yarası
///
/// 2026-08-12'de 12 saatte 133 dosya değişti, 20'si üretim kodu, ve
/// *"kullanıcının görebileceği ne değişti?"* sorusunun cevabı **HİÇBİR ŞEY**di.
/// `test/reachable_screens_test.dart` akışın **varılabilirliğini** kanıtlıyor
/// (A1) — ama *"bu ekranda ne YAZIYOR"* sorusunu hiçbir kapı sormuyordu.
///
/// > ***BİR EKRANA VARILABİLİYOR OLMASI, ORADA OKUNACAK BİR ŞEY OLDUĞUNU
/// > GÖSTERMEZ*** — ve boş bir yüzey, yeşil bir yürüyüş testinde
/// > varılabilir görünür.
///
/// ## NE ÖLÇER / NE ÖLÇMEZ
///
/// **Ölçer:** her ekranda kullanıcıya sunulan dizgelerin **sayısı ve kendisi**.
///
/// ⛔ **NE ÖLÇMEDİĞİ, ADIYLA — VE BU BİR DENEMENİN KALINTISI:** bu yürüyüş
/// önce `integration_test/` altında **CİHAZDA** koşacak şekilde yazıldı ve
/// **koşamadı**: Xcode derlemesi geçti (84,1s), ama
/// `Error waiting for a debug connection: The log reader failed unexpectedly`
/// → 12 dk zaman aşımı. Ölçülen muhtemel sebep: makinede **üç simülatör
/// birden ayakta** (biri başka bir hattın) ve diğer hatların cihazları
/// **kapatılmadı**. ⇒ Burada ölçülen şey ekranın **İÇERİĞİ**dir,
/// cihazdaki **ÇİZİMİ** değil. *Bir metnin ağaçta olması, o metnin
/// ekranda okunabilir çizildiğini göstermez.*
/// **ÖLÇMEZ:** düzenin güzelliğini, boşlukları, renkleri — onlar **tasarım
/// yönü** (M-F-77) ve hat oraya dokunmaz. Bu kapı yalnız *"okunacak bir şey
/// var mı ve ne diyor"* sorusunu yanıtlar.
///
/// ⛔ **SINIR, ADIYLA:** `Text` widget'ı olmayan yüzeyler (yalnız ikon/çizim
/// taşıyan bir ekran) burada **boş görünür** ve bu bir yanlış-pozitiftir.
/// Bugün öyle bir ekran yok; çıkarsa bu satır düzeltilmeli.
///
/// Koşum: `flutter test test/yuzey_yuruyusu_test.dart`
///
/// ## ⛔ A3 İLE BİRLEŞTİRİLMEDİ — ve bu bir KARAR, atlama değil (J-260)
///
/// Devir notu (`DEVIR-2026-08-13`, madde ③) şunu öneriyordu: *"yüzey kapısını
/// A3'le birleştir; ikisi aynı yürüyüşten beslenirse 'sessiz yüzey 0' iddiası
/// tek kapıdan doğrulanır."* **Ölçtüm ve BİRLEŞTİRMEDİM** — çünkü ikisi
/// **farklı birimleri** sayıyor ve zorla tek sayıya indirmek bilgi ÜRETMEZ:
///
/// | kapı | BİRİM | bugünkü ölçüm |
/// |---|---|---|
/// | `dead_end_test` (A3) | **KONTROL** (basılabilir öğe) | `30 = 20 iş sunan + 10 adıyla boş + 0 ÇIKMAZ` (8 disiplin + 3 kurs + 19 ders) |
/// | bu kapı | **YÜZEY** (varılan ekran) | **13 yüzey**, her biri en az bir dizge okuyor |
///
/// A3 *"bastığım şey beni bir yere götürüyor mu"* sorusunu; bu kapı
/// *"vardığım yerde bir şey yazıyor mu"* sorusunu cevaplıyor. Paydalar
/// farklı (30 kontrol ↔ 13 yüzey), sorular farklı.
/// > ***AKTARILABİLİR OLAN DESEN DEĞİL KAVRAMDIR*** — J-243'te iki kardeş
/// > hattın birimini kopyalamayı reddederken öğrendiğim kural, bu kez
/// > **kendi iki kapım** arasında geçerli. Birleştirilmiş bir *"0 sessiz"*
/// > sayısı, iki farklı yokluğu tek hücreye yıkardı ve hangisinin
/// > ölçülmediğini kimse göremezdi.
///
/// ⚠️ **SINIR, KARIŞMASIN DİYE ADIYLA:** A3'ün `ÇIKMAZ 0`ı bu kapının
/// *"sessiz yüzey yok"*unu **KAPSAMAZ**, tersi de doğru değil. İkisi
/// komşudur, biri ötekinin yerine geçmez.
///
/// 🪤 Bu satır bir tur önce `integration_test/… -d <udid>` diyordu ve dosya
/// `test/` altına inince **yalan olmuştu** — kapı (`unintended_html_in_doc_comment`)
/// onu başka bir sebeple yakaladı ve bayatlık öyle görüldü.
/// *Bir koşum talimatı, dosyayla birlikte taşınmazsa okuyanı yanlış komuta
/// gönderir — ve yanlış komut "kapı koşmuyor" diye okunur.*
void main() {
  // ⚠️ GÖRÜNTÜ ALANI ÖLÇÜMÜN BİR PARÇASIDIR — varsayılan 800×600'de kurs
  // kartı `y=1030`'da kalıyor ve **ekran dışına** düşüyor. `tap()` bunu
  // hit-test'te yakaladı; ama `visibleText` taraması yakalaMAZDI — dar bir
  // alanda sessizce DAHA AZ dizge sayardı ve sayı düşerken hiçbir şey ötmezdi.
  // > ***BİR YÜZEY ÖLÇÜMÜNÜN SAYISI, ÖLÇÜLDÜĞÜ GÖRÜNTÜ ALANINA BAĞLIDIR —
  // > ALAN YAZILMADAN SAYI OKUNAMAZ.*** (A1 yürüyüşüyle AYNI alan, bilerek:
  // > iki kapı farklı alanda ölçseydi sayıları karşılaştırılamazdı.)
  setUp(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(1200, 3000);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  /// O anda ekranda GÖRÜNEN tüm kullanıcı dizgeleri.
  ///
  /// ⚠️ `find.byType(Text)` **çizilmeyeni de** bulabilir (offstage). Bu yüzden
  /// `skipOffstage` varsayılanına (true) güveniliyor ve boş/whitespace
  /// dizgeler ELENİYOR — *bir boşluk karakteri okunacak bir şey değildir.*
  List<String> visibleText(WidgetTester t) {
    final List<String> out = <String>[];
    for (final Element e in find.byType(Text).evaluate()) {
      final Text w = e.widget as Text;
      final String? s = w.data ?? w.textSpan?.toPlainText();
      if (s != null && s.trim().isNotEmpty) out.add(s.trim());
    }
    return out;
  }

  final List<String> rapor = <String>[];

  void kaydet(WidgetTester t, String ekran) {
    final List<String> ss = visibleText(t);
    rapor.add('── $ekran · görünen dizge: ${ss.length}');
    for (final String s in ss) {
      final String tek = s.replaceAll('\n', ' ⏎ ');
      rapor.add('     ${tek.length > 96 ? '${tek.substring(0, 96)}…' : tek}');
    }
    // 🔴 SESSİZ BOŞ YÜZEY KAPISI — A3'ün cihazdaki karşılığı.
    // *Bir ekranda okunacak hiçbir şey yoksa, kullanıcı sessizliği
    //  "sorun yok" diye okur.*
    expect(ss, isNotEmpty,
        reason: '$ekran: cihazda GÖRÜNEN hiçbir metin yok. Ekrana varılıyor '
            'ama okunacak bir şey sunmuyor — A3\'ün yasakladığı sessiz boş '
            'yüzey, ve widget testinde varılabilir görünür.');
  }

  testWidgets('YÜZEY yürüyüşü — her ekranda ne YAZIYOR',
      (WidgetTester t) async {
    final Directory tmp =
        Directory.systemTemp.createTempSync('jablab_yuzey_');
    final File flagFile = File('${tmp.path}/seen.flag');
    // ③ SOĞUK AÇILIŞ — bayrak diskte YOK, karşılama gerçekten çıkacak.
    expect(flagFile.existsSync(), isFalse);

    await t.runAsync(() async {
      await t.pumpWidget(
        JabLabApp(onboarding: OnboardingStore(fileOverride: flagFile)),
      );
    });
    await settleAppLoad(t);
    await t.pumpAndSettle();

    // ── KARŞILAMA — her PERDE ayrı ayrı okunuyor ────────────────────────
    int perde = 0;
    while (find.byType(OnboardingPage).evaluate().isNotEmpty) {
      perde++;
      expect(perde, lessThanOrEqualTo(8),
          reason: 'karşılama kapanmıyor — sonsuz perde');
      kaydet(t, 'KARŞILAMA perde $perde');
      await t.tap(find.byKey(const Key('onboarding-next')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
    }

    // ── SEÇİM ──────────────────────────────────────────────────────────
    expect(find.byType(SelectPage), findsWidgets);
    kaydet(t, 'SEÇİM');

    // ── AYARLAR — YÜRÜYÜŞE J-254'TEN SONRA EKLENDİ ──────────────────────
    // Bu yüzey **canlı bir rota** olduğu hâlde yürüyüşte YOKTU, ve o boşluk
    // bir kusuru barındırdı: ayarlarda tam genişlik, ember dolgulu, ekranın
    // en baskın öğesi olan bir `Continue` düğmesi duruyordu ve **hiçbir şey
    // yapmıyordu** (ölü affordans + olmayan bir ödeme adımını ima). Kusuru
    // bulan şey bir kapı değil, simülatörde ELLE yürümek oldu.
    // > ***BİR YÜZEYİ HİÇBİR KAPI OKUMUYORSA, ORADAKİ HER İDDİA
    // > DENETİMSİZDİR*** — o yüzden yüzey artık okunuyor.
    await t.tap(find.byKey(const Key('settings-button')));
    await t.pumpAndSettle();
    kaydet(t, 'AYARLAR');

    // ── NEDEN YOK sayfası — ayarlardan BİR TIK ötede, ve o da okunmuyordu.
    // ⚠️ Bu sayfa `shell_candidate/` altında (DONMUŞ ağaç) ama **canlı bir
    // rota**: `jablab_app.dart:427` onu `MaterialPageRoute` ile itiyor.
    // *Donmuş olmak, ulaşılamaz olmak değildir* — ve ürünün 12 kapsam-dışı
    // gerekçesinin tamamı burada yaşıyor, yani dürüstlük yükü en ağır
    // yüzeylerden biri.
    await t.tap(find.byKey(const Key('why-not-link')));
    await t.pumpAndSettle();
    kaydet(t, 'NEDEN YOK (kapsam-dışı gerekçeleri)');
    await t.pageBack();
    await t.pumpAndSettle();

    // Geri dön: yürüyüşün geri kalanı seçim ekranından devam ediyor.
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.byType(SelectPage), findsWidgets,
        reason: 'ayarlardan dönüşte seçim ekranı yok — yürüyüşün geri kalanı '
            'yanlış yüzeyden devam ederdi');

    // 🪤 `item-boxing` SAYFA DEĞİŞTİRMİYOR — `setState` ile YERİNDE açılıyor
    // (`select_page.dart`); kurs kartları AYNI `SelectPage`'de beliriyor.
    // İlk yazımımda burada `CoursePage` bekledim ve kapı **yüksek sesle**
    // düştü. Bu, A1'in kök-takas bulgusunun ikinci örneği:
    // > ***BİR YÜZEYİN DEĞİŞMESİ, BİR ROTANIN DEĞİŞMESİ DEMEK DEĞİLDİR***
    // — ve ayrı bir yüzey hâli olduğu için AYRI okunuyor.
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    expect(find.byType(SelectPage), findsWidgets);
    kaydet(t, 'SEÇİM · kurs kartları açık (setState, rota YOK)');

    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    expect(find.byType(CoursePage), findsWidgets);
    kaydet(t, 'KURS (ders listesi)');

    await t.tap(find.byKey(const Key('lesson-boxing.foundations.stance')));
    await t.pumpAndSettle();
    expect(find.byType(SessionScreen), findsWidgets);

    // ── SEANS — her AŞAMA ayrı ayrı okunuyor ────────────────────────────
    int asama = 0;
    while (find.byKey(const Key('advance-button')).evaluate().isNotEmpty) {
      asama++;
      expect(asama, lessThanOrEqualTo(10),
          reason: 'seans kapanmıyor — sonsuz aşama');
      kaydet(t, 'SEANS aşama $asama');
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pumpAndSettle();
    }
    kaydet(t, 'SEANS son yüzey (ilerlet düğmesi YOK)');

    // ⭐ VAKUM KORUMASI — yürüyüş hiç ekran görmediyse "0 sessiz yüzey"
    // vakum-doğru olarak YEŞİL öterdi.
    expect(perde, greaterThan(0), reason: 'VAKUM: hiç karşılama perdesi yok');
    expect(asama, greaterThan(0), reason: 'VAKUM: hiç seans aşaması yok');
    expect(rapor, isNotEmpty, reason: 'VAKUM: hiçbir ekran okunmadı');

    // Raporu çıktıya bas — bu kapının ÜRÜNÜ sayı değil, OKUNAN METİN.
    // ⚠️ Başlık bilerek *"CİHAZDA"* DEMİYOR. İlk yazımda diyordu ve kapı
    // `integration_test/` altındayken doğruydu; `test/` altına inince
    // **yalan olmuştu**. Bir çıktı başlığı, ölçümün NEREDE koştuğunu iddia
    // eder — ve taşınan bir kapının bayat başlığı, okuyanı ölçmediği bir
    // gerçeğe inandırır.
    //
    // 🪤 Ve aşağıdaki `ignore` bir tur önce BURADAYDI; bu yorum bloğunu
    // araya sokunca hedefinden KOPTU ve `analyze` kırmızıya döndü.
    // > ***BİR YÖNERGE YORUMUNUN KONUMU, ONUN ANLAMIDIR*** — araya giren
    // > masum bir açıklama, çalışan bir bastırmayı sessizce silahsızlandırır.
    // ignore: avoid_print
    print('\n════ SUNULAN YÜZEY (ağaçta; cihaz ÇİZİMİ değil) ════\n'
        '${rapor.join('\n')}\n'
        '════ perde $perde · aşama $asama · okunan ekran '
        '${rapor.where((String l) => l.startsWith('──')).length} ════\n');

    tmp.deleteSync(recursive: true);
  });
}
