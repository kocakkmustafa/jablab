import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/shell_candidate/live_surface.dart';

/// ÖZET SAYISI — ölçülmüşse gösterilir, ölçülmemişse SUSULUR (J-156).
///
/// ## Ölçülen kusur
///
/// `_Summary` `SessionSummaryView`e **sabit `eventCount: 0`** veriyordu ve
/// sayım canlı aşamada yaşayıp oraya **hiç taşınmıyordu**. Yani kullanıcı
/// kaç yumruk atarsa atsın seans sonunda **"0 recorded this session"**
/// yazıyordu — kameralı derste **doğrudan yanlış bir olgu.**
///
/// Ve yanındaki K8 yorumu bunu haklı çıkarmıyordu: o yorum **bantlar** için
/// geçerli, **sayım** için değil. Ürünün kendi dürüstlük kutusu: *"Punch
/// events and count — a **FACT** from the phase machine, **not a grade**."*
///
/// ## Bu gecenin 50+ düzeltmesinin TERS yönü
///
/// Hepsi *"olmayan bir şeyi iddia etme"* eksenindeydi. Bu **olan bir şeyi
/// kaybetmek** — ve sonucu daha kötü, çünkü ortaya çıkan boşluk **sessiz
/// kalmıyor, `0` diye konuşuyor.**
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Sayının **doğru** olduğunu — yalnız *"ölçülmediyse gösterilmiyor,
///   ölçüldüyse gösteriliyor"* ayrımını. Sayının motorla uyumu
///   `live_jab_path_test`in işi.
/// * Ekrandaki **yerleşimi**.
void main() {
  Future<void> pump(WidgetTester t, int? count) => t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SessionSummaryView(
            eventCount: count,
            bands: const <String, String>{'Stance': '—'},
            coachedNotScored: const <String>['Rear guard hand position'],
          ),
        ),
      ));

  testWidgets('analiz KOŞMADIYSA sayı da cümle de YOK', (WidgetTester t) async {
    await pump(t, null);
    expect(find.byKey(const Key('summary-count')), findsNothing,
        reason: 'analiz koşmadı ama ekranda sayı var — çıplak sıfır '
            '"hiç yapmadın" diye okunur (J-092/J-096/J-156)');
    expect(find.text('recorded this session'), findsNothing,
        reason: 'sayı gizlendi ama başlığı kaldı — boş bir iddia');
  });

  testWidgets('POZİTİF İKİZ — analiz KOŞTUYSA sayı GÖSTERİLİR (0 dahil)',
      (WidgetTester t) async {
    // İkiz olmadan kapı, sayının HER ZAMAN gizlenmesini de geçerli sayardı:
    // hiç sayı yok, dolayısıyla hiç yanlış sayı yok. Kapı bir iddiayı değil
    // **bir sessizliği** korurdu.
    //
    // Ve `0` burada DOĞRUDUR: ölçtük, hiç yumruk yoktu. Ayrım "ölçmedik"
    // ile "ölçtük ve sıfırdı" arasında.
    await pump(t, 12);
    expect(find.byKey(const Key('summary-count')), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await pump(t, 0);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('summary-count')), findsOneWidget,
        reason: 'ölçülmüş sıfır GİZLENMEMELİ — "ölçtük, hiç yumruk yoktu" '
            'dürüst bir sonuçtur');
  });

  testWidgets('⭐ ZİNCİR — kamerasız ders özetinde sayı YOK (J-156)',
      (WidgetTester t) async {
    // ## Neden widget testi YETMİYOR
    //
    // Yukarıdaki iki test `SessionSummaryView`in SÖZLEŞMESİNİ ölçüyor.
    // Ama kusur sözleşmede değildi: bileşen doğruydu, **besleyen taraf**
    // ona sabit `0` veriyordu. Mutasyonu denedim (`eventCount: eventCount`
    // → `eventCount: 0`) ve **hiçbir test kırılmadı** — J-096'nın dersi:
    // *bileşen kusursuz olup `_Root` onu hiç beslemiyor olabilir.*
    //
    // Bu test ZİNCİRİ koşuyor: gerçek uygulama → kamerasız ders →
    // öğret/dene/canlı/özet → ekranda sayı var mı.
    //
    // ⚠️ NE ÖLÇMÜYOR: zincirin POZİTİF yönünü (analiz koştuğunda sayının
    // GERÇEKTEN geldiğini). O, sentetik kare besleyen bir canlı koşum
    // gerektiriyor (`live_jab_path_test` makinesi) ve bu turda
    // kurulmadı — **isimli borç**, sessiz değil.
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(1200, 3000);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(() {
      b.platformDispatcher.views.first.resetPhysicalSize();
      b.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    await t.runAsync(() async {
      await t.pumpWidget(
          const JabLabApp(onboarding: OnboardingStore(seenOverride: true)));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    // `stance` KAMERASIZ (usesCamera yok) — analiz hiç koşmaz.
    await t.tap(find.byKey(const Key('lesson-boxing.foundations.stance')));
    await t.pumpAndSettle();
    for (int i = 0; i < 3; i++) {
      await t.runAsync(() async {
        await t.tap(find.text('Continue'));
        await t.pump();
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await t.pump(const Duration(milliseconds: 250));
    }

    // VAKUM KAPISI: gerçekten ÖZET aşamasında mıyız?
    expect(find.byKey(const Key('summary-band-Stance')), findsOneWidget,
        reason: 'özet aşamasına gelinmedi — kapı boşluğa bakıyor olabilir');

    expect(find.byKey(const Key('summary-count')), findsNothing,
        reason: 'KAMERASIZ derste özet SAYI gösteriyor. Analiz hiç '
            'koşmadı; çıplak bir sayı burada ölçülmemiş bir olguyu '
            'ölçülmüş gibi sunar (J-156)');
    expect(find.text('recorded this session'), findsNothing);
  });
}
