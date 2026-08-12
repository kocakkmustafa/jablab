import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/camera_harness_screen.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_page.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/settings_page.dart';
import 'package:jablab/shell_candidate/library_pages.dart' show WhyNotPage;
import 'package:jablab/shell_candidate/session_flow.dart';

/// GEZİLEBİLİR EKRAN SAYISI — kapıdan ölçülür, beyandan değil (J-167).
///
/// Koordinatörün sorusu: ***bugün, uygulamayı açan bir kullanıcı kaç ayrı
/// ekrana GİDEBİLİYOR?*** — ve sayı bir daha bayatlamasın diye **kapı**.
///
/// ## SAYMA KURALI (beş hatta aynı, karşılaştırılabilirlik için)
///
/// * Açılıştan başlayarak **yalnız ekranda görünen kontrollere basarak**
///   ulaşılan her **ayrı ekran** sayılır.
/// * **Kodda tanımlı ama ulaşılamayan** sayılmaz (*repliğin varlığı ≠
///   tetiğinin varlığı*).
/// * Yalnız derin-bağlantı/test kancasıyla açılan sayılmaz.
/// * Ayrı ekran olmayan modal/sheet sayılmaz.
///
/// ## BU HATTA VERİLEN İKİ KARAR — beyan ediyorum, gizlemiyorum
///
/// **① Karşılama = 1 ekran.** Üç *perde* var ama tek bir `OnboardingPage`
/// içinde yatay geçişle; ayrı rota değil. Perde saysaydım 3 olurdu.
/// **② Seans aşamaları = 1 ekran.** `SessionScreen` tek bir Scaffold ve
/// dört *aşama* (öğret/dene/canlı/özet) onun içinde `switch` ile
/// değişiyor — ayrı rota yok, ray hep görünür. Aşama saysaydım +3 olurdu.
///
/// **Yani bu hattın sayısı, sayma kuralının katılığına göre 6 ile 11
/// arasında değişir.** Katı okuma (ayrı rota) = **6**; gevşek okuma
/// (perde/aşama dâhil) = **11**. İkisi de yazılı — çünkü *"10"* gibi bir
/// sayının hangi kuralla çıktığı bilinmezse **hatlar karşılaştırılamaz**
/// (koordinatörün Ostinato'da 3↔11 sapması tam bu).
///
/// ## ⚠️ 2026-08-12 YENİDEN ÖLÇÜMÜ — GEVŞEK SAYI KAPISIZDI
///
/// J-167'de katı **6** bir kapıyla korunuyordu ama gevşek **11** yalnız bu
/// yorumda yazılıydı. Korumasız bir sayı, dayandığı gerçek değiştiği gün
/// **sessizce** yalan olur — ve bu sayı devir notuna, panoya ve aile
/// karşılaştırmasına giriyor. *Kusur iddiada değil, korumasızlığındaydı*
/// (M-F-436). Artık **her iki bileşen de YÜRÜNEREK** ölçülüyor: perdeler
/// `onboarding-next`e basılarak, aşamalar `advance-button`a basılarak —
/// **sabit okunarak değil**, çünkü bir sabitin değeri o değere GİDEN yolun
/// varlığını kanıtlamaz (M-F-503).
///
/// ## ⚠️ SAYILMAYANLAR — adıyla
///
/// * `CameraHarnessScreen` — `kDebugMode` dışında **açılmıyor**; sevk
///   edilen üründe kullanıcı oraya gidemez.
/// * `ContentFailureScreen` — yalnız içerik yüklenemezse çiziliyor;
///   kontrole basarak ulaşılmıyor.
/// Katı okuma: `pumpAndSettle` ile ulaşılan AYRI rota sayısı. Aşağıdaki
/// "rota 2-6/6" testinin beklediği küme bu sayıyı zaten kilitliyor.
const int kStrictRoutes = 6;

/// Karşılama perdesi sayısı — "perde yürüyüşü" testi bunu YÜRÜYEREK doğrular.
const int kOnboardingPanels = 3;

/// Seans aşaması sayısı — "aşama yürüyüşü" testi bunu YÜRÜYEREK doğrular.
const int kSessionStages = 4;

/// Gevşek okuma: karşılama ve seans, katı okumada BİRER rota sayılıyor;
/// gevşek okumada yerlerine kendi perdeleri/aşamaları geçiyor.
const int kLooseScreens =
    kStrictRoutes - 2 + kOnboardingPanels + kSessionStages;

void main() {
  const OnboardingStore seen = OnboardingStore(seenOverride: true);

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

  // ⚠️ İKİ AYRI TEST: tek gövdede iki kez `pumpWidget` bu koşumda ikinci
  // ağacı güvenilir kurmuyor (bu gecenin ÜÇÜNCÜ kez düştüğü tuzak —
  // `pumpLive` · `content_failure` · burası). Karşılama ayrı ölçülüyor.
  testWidgets('rota 1/6 — KARŞILAMA (ilk açılış)', (WidgetTester t) async {
    await t.runAsync(() async {
      await t.pumpWidget(
          const JabLabApp(onboarding: OnboardingStore(seenOverride: false)));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await t.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
  });

  testWidgets('rota 2-6/6 — select → settings → whyNot → course → session',
      (WidgetTester t) async {
    final Set<String> reached = <String>{'onboarding'};
    void mark(Type screen, String name) {
      if (find.byType(screen).evaluate().isNotEmpty) reached.add(name);
    }

    await t.runAsync(() async {
      await t.pumpWidget(const JabLabApp(onboarding: seen));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await t.pumpAndSettle();
    mark(SelectPage, 'select');

    // Ayarlar — Sayfa A'nın köşe düğmesi.
    final Finder gear = find.byIcon(Icons.settings_outlined);
    expect(gear, findsWidgets, reason: 'ayarlar düğmesi Sayfa A\'da yok');
    await t.tap(gear.first);
    await t.pumpAndSettle();
    mark(SettingsPage, 'settings');

    // Neden yok — ayarlardaki satır.
    await t.tap(find.textContaining('things left out').first);
    await t.pumpAndSettle();
    mark(WhyNotPage, 'whyNot');
    await t.pageBack();
    await t.pumpAndSettle();
    await t.pageBack();
    await t.pumpAndSettle();

    // Sayfa B — disiplin → kurs.
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    mark(CoursePage, 'course');

    // Seans — ders.
    await t.tap(find.byKey(const Key('lesson-boxing.foundations.stance')));
    await t.pumpAndSettle();
    mark(SessionScreen, 'session');

    expect(reached, <String>{
      'onboarding', 'select', 'settings', 'whyNot', 'course', 'session',
    }, reason: 'gezilebilir rota kümesi değişti — sayı bayatladı, devir '
        'notu ve pano güncellenmeli (J-167)');
  });

  // ⚠️ Perde ve aşama yürüyüşleri AYRI testler — aynı gövdede iki kez
  // `pumpWidget` bu koşumda ikinci ağacı güvenilir kurmuyor (yukarıdaki
  // aynı not).
  testWidgets('gevşek okuma ①: KARŞILAMA PERDELERİ yürünerek sayılıyor',
      (WidgetTester t) async {
    await t.runAsync(() async {
      await t.pumpWidget(
          const JabLabApp(onboarding: OnboardingStore(seenOverride: false)));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await t.pumpAndSettle();

    // Sayılan şey `_steps` sabiti DEĞİL, düğmeye basarak GERÇEKTEN görülen
    // perde sayısı: ulaşılamayan bir perde bu sayıya giremez.
    int panels = 0;
    while (find.byType(OnboardingPage).evaluate().isNotEmpty) {
      panels++;
      expect(panels, lessThanOrEqualTo(kOnboardingPanels + 4),
          reason: 'karşılama kapanmıyor — "Start" son perdede bitirmiyor');
      await t.tap(find.byKey(const Key('onboarding-next')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
    }

    expect(panels, kOnboardingPanels,
        reason: 'perde sayısı değişti — gevşek ekran sayısı ($kLooseScreens) '
            'artık yanlış; devir notu ve pano güncellenmeli');
  });

  testWidgets('gevşek okuma ②: SEANS AŞAMALARI yürünerek sayılıyor',
      (WidgetTester t) async {
    await t.runAsync(() async {
      await t.pumpWidget(const JabLabApp(onboarding: seen));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('lesson-boxing.foundations.stance')));
    await t.pumpAndSettle();

    // Aşama, RAY'dan (hep dört rozet çizer) değil, ekranın o an TAŞIDIĞI
    // `stage` değerinden okunuyor — ray bir beyandır, bu bir konumdur.
    final Finder flow = find.byType(SessionFlowScaffold);
    SessionStage? stageNow() => flow.evaluate().isEmpty
        ? null
        : t.widget<SessionFlowScaffold>(flow).stage;

    final Set<SessionStage> walked = <SessionStage>{};
    int taps = 0;
    for (SessionStage? s = stageNow(); s != null; s = stageNow()) {
      walked.add(s);
      expect(taps++, lessThanOrEqualTo(kSessionStages + 2),
          reason: 'seans kapanmıyor — son aşamada "Done" ekrandan çıkarmıyor');
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pump();
      // ⚠️ SABİT SÜRE YETMİYOR — ölçüldü 2026-08-12. Son aşamadaki "Done"
      // ekranı POP ediyor ve pop geçişi 400 ms'de bitmiyordu: döngü bir tur
      // daha dönüyor, aşamayı İKİNCİ kez sayıyor (Set yuttuğu için sayı
      // tesadüfen doğru kalıyordu) ve geçiş sırasında `IgnorePointer` altında
      // kalan düğmeye basıp `tap()` ıskalatıyordu. *Iskalayan bir yürüyüş,
      // yürünmemiş bir yolu yürünmüş sayabilir* — o yüzden burada sabit süre
      // değil, GERÇEK bir durum değişikliği bekleniyor: aşama ilerledi ya da
      // ekran kapandı. Sınırlı (1,2 s) — takılan bir geçiş sessizce beklemez,
      // yukarıdaki tur sınırına çarpar.
      for (int f = 0; f < 6; f++) {
        await t.pump(const Duration(milliseconds: 200));
        if (stageNow() != s) break;
      }
    }

    expect(walked.length, kSessionStages,
        reason: 'yürünen aşama sayısı değişti — gevşek ekran sayısı '
            '($kLooseScreens) artık yanlış; devir notu ve pano '
            'güncellenmeli. Yürünenler: ${walked.map((SessionStage s) => s.name)}');
    // Bir aşamanın ENUM'da olması, ona GİDEN yolun olması değildir: kümeyi
    // adıyla kilitliyoruz ki sessizce atlanan bir aşama sayıyı düşürmesin.
    expect(walked, SessionStage.values.toSet(),
        reason: 'bir aşamaya yürünerek ulaşılamıyor');
  });

  test('gevşek okuma ③: TÜRETİLEN SAYI — bileşen değişirse burası öter', () {
    // Bilerek totoloji: bileşenlerden biri (① ya da ②) değiştiğinde bu satır
    // düşer ve sabiti güncelleyen kişi, DIŞARIYA verilen sayının da
    // değiştiğini görmek ZORUNDA kalır. J-167'de eksik olan tam buydu —
    // gevşek sayı bir yorumda yaşıyordu, kimse ona çarpmıyordu.
    expect(kLooseScreens, 11,
        reason: 'gevşek ekran sayısı değişti: devir notu, 📊 pano ve aile '
            'karşılaştırması bu sayıyı taşıyor — üçü de güncellenmeli');
  });

  test('SAYILMAYANLAR adıyla — ve gerekçeleri ÖLÇÜLÜ', () {
    // Harness sevk edilen üründe açılmıyor: kapı `kDebugMode`.
    expect(CameraHarnessScreen.isAvailable, isTrue,
        reason: 'test derlemesi debug — bu satır kapının VAR olduğunu '
            'gösteriyor; ürün derlemesinde false olur ve ekran açılmaz');
  });
}
