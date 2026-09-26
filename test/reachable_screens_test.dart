import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/camera_harness_screen.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_page.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/settings_page.dart';
import 'package:jablab/app/solo_boxing_course_page.dart';
import 'package:jablab/shell_candidate/library_pages.dart' show WhyNotPage;
import 'package:jablab/shell_candidate/session_flow.dart';

import 'app_pump.dart';

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
// 2026-09-26: the visible solo-course path adds two witnessed push routes.
const int kStrictRoutes = 8;

/// Karşılama perdesi sayısı — "perde yürüyüşü" testi bunu YÜRÜYEREK doğrular.
const int kOnboardingPanels = 3;

/// Seans aşaması sayısı — "aşama yürüyüşü" testi bunu YÜRÜYEREK doğrular.
const int kSessionStages = 4;

/// Gevşek okuma: karşılama ve seans, katı okumada BİRER rota sayılıyor;
/// gevşek okumada yerlerine kendi perdeleri/aşamaları geçiyor.
const int kLooseScreens =
    kStrictRoutes - 2 + kOnboardingPanels + kSessionStages;

/// ⛔ KÖK VARIŞ SAYISI — ÇAPALI (J-240).
///
/// Ostinato'nun bulgusu (M-F-582) bu ağaçta da doğrulandı: sayılan üyelerin
/// hepsi `push` DEĞİL. Burada **ikisi** kök varış — `OnboardingPage` ve onun
/// yerine geçen `SelectPage` **aynı kök rotada** yaşıyor, aralarındaki geçiş
/// `_RootState.setState` ile bir TAKAS (`jablab_app.dart`, `_showOnboarding`).
/// Eski toplam-assert bunu **görünmez** kılıyordu.
///
/// > ***Sayı çapalanır ki ÜÇÜNCÜ bir kök varış bir BEYAN değil, bir BULGU
/// > olsun.***
const int kRootArrivals = 2;

/// Bir ekrana **NASIL** varıldığı — (b)'nin tanıkla ölçebildiği büyüklük.
enum Arrival {
  /// Tanık yeni bir rota `push`u gördü.
  push,

  /// Yeni rota YOK: kök rotanın kendisi ya da onun içinde `setState` takası.
  root,
}

/// (b) TANIĞI — ***varış ADIYLA değil OLAYLA sayılır.***
///
/// ⚠️ Bu ağaçta `route.settings.name` **her rotada `null`** (hepsi anonim
/// `MaterialPageRoute`; `jablab_app.dart` 398-435, 632). Ada bakan bir tanık
/// ***sessizce boş*** kalırdı — Ostinato'nun M-F-582'de ödediği bedel. O
/// yüzden tanık **olay sayıyor**, ve adların gerçekten boş olduğu aşağıda
/// AYRICA sınanıyor: bir gün rotalar ad taşımaya başlarsa bu varsayım
/// sessizce bayatlamasın.
class _RouteWitness extends NavigatorObserver {
  int pushes = 0;
  int pops = 0;
  final List<String?> pushedNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    pushedNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    super.didPop(route, previousRoute);
  }
}

// ══════════════════════════════════════════════════════════════════════
// YÜRÜYÜŞÜN ÇIKTISI — denklem artık BUNU okuyor.
//
// 🔴 ÖNCEKİ HÂL VE NEDEN YANLIŞTI (J-240): denklemdeki `walked`, **elle
// yazılmış bir `const Set`**ti; gerçek yürüyüş BAŞKA bir testte yaşıyordu
// (`reached`) ve ***ikisinin uzlaştığını hiçbir şey sınamıyordu.*** Yani
// (e) ile "kaynak olmaktan çıkarılan" elle küme, arka kapıdan **(b)'nin
// işini** görüyordu.
//
// > ***BİR KÜMEYİ "KAYNAK DEĞİL" İLAN ETMEK, ONU KAYNAK OLARAK KULLANMAYI
// > BIRAKMAK DEĞİLDİR.***
//
// Artık üyelik yalnız **yürünerek** buraya yazılıyor; elle küme aşağıda
// `knownFloor` adıyla ve YALNIZ (e) rolünde duruyor.
// ══════════════════════════════════════════════════════════════════════

/// Yürüyüşün vardığı ekranların SINIF adları — denklemin `varılan` tarafı.
final Set<String> walkedClasses = <String>{};

/// Her varışın KİPİ — kısa ad → `push`/`root`.
final Map<String, Arrival> walkArrivals = <String, Arrival>{};

/// Yürüyüşte gerçekten basılarak görülen karşılama perdesi sayısı.
int? walkedPanels;

/// Yürüyüşte gerçekten basılarak görülen seans aşaması sayısı.
int? walkedStages;

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('jablab_walk_');
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(1200, 3000);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });
  tearDown(() {
    tmp.deleteSync(recursive: true);
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  /// ⭐ A1 · SÖZLEŞME (b)+③ — **TEK YÜRÜYÜŞ**, TAZE KURULUMDAN, TANIKLA.
  ///
  /// ## Neden bu test var — ve neden ÖNCEKİ dört test yerine BİR tane
  ///
  /// Ölçüm (2026-08-12 kapanışı) şunu buldu: zincir **dört ayrı teste
  /// bölünmüştü** ve *"tam akış çalışıyor"* iddiasının kanıtı **yoktu**.
  /// Bölünmenin kendisi meşru bir sebeple doğmuştu (tek gövdede iki
  /// `pumpWidget` ikinci ağacı güvenilir kurmuyordu) — ama:
  ///
  /// > ***TESTLER BİLEREK BÖLÜNDÜ; BÖLÜNÜNCE YENİDEN BAĞLANMADI.***
  ///
  /// Ve bölünmenin bedeli ölçüldü: karşılamayı yürüyen test **çıkışı**
  /// kanıtlıyordu ama **nereye indiğini** hiç sınamıyordu; kabuğu yürüyen
  /// test ise karşılamayı **atlayarak** başlıyordu — `reached` kümesi
  /// `{'onboarding'}` **literaliyle TOHUMLANIYOR** ve bayrak **set
  /// ediliyordu**. ⇒ *Karşılamanın çıkışı, KATI sayının içinde hiç
  /// basılmamıştı.*
  ///
  /// > ***BİR EKRANI ATLAYARAK YÜRÜYEN ÖLÇÜM, O EKRANIN ÇIKIŞI OLUP
  /// > OLMADIĞINI SÖYLEYEMEZ.*** (sözleşme ③)
  ///
  /// ## Tek `pumpWidget` — eski tuzağa DÜŞMEDEN
  ///
  /// Bölünmenin sebebi olan tuzak (*ikinci `pumpWidget` güvenilir değil*)
  /// burada **hiç doğmuyor**: bu test ağacı **bir kez** kuruyor ve sonuna
  /// kadar aynı ağaçta yürüyor. Yani birleşim, tuzağı geri getirmiyor —
  /// ***tuzağın var olma sebebini ortadan kaldırıyor.***
  ///
  /// ## ③ TAZE KURULUM — bayrak SET EDİLMİYOR, YAZILIYOR
  ///
  /// `seenOverride` **kullanılmıyor**. Depo GERÇEK bir dosyaya bakıyor
  /// (`fileOverride`, bu koşumun geçici dizini) ve dosya **yok** ⇒ ilk-koşu
  /// hâli *kurulmuyor*, **gerçekten öyle**. Karşılama **düğmeye basılarak**
  /// geçiliyor ve `markSeen()` bayrağı **diske yazıyor** — aşağıda dosyanın
  /// varlığı sınanıyor. (⚠️ `seenOverride: false` bunu ölçemezdi:
  /// `OnboardingStore.markSeen` `seenOverride != null` ise **erken dönüyor**,
  /// yani kalıcılık yolu hiç çalışmazdı. *Bir test double, gerçeğin kuralını
  /// uygulamaz.*)
  testWidgets(
      'A1 · TAM AKIŞ — taze kurulum → karşılama → seçim → oturum → SONUÇ',
      (WidgetTester t) async {
    // ── ③ TAZE KURULUM ────────────────────────────────────────────────
    final File flagFile = File('${tmp.path}/${OnboardingStore.fileName}');
    expect(flagFile.existsSync(), isFalse,
        reason: 'taze kurulum DEĞİL — bayrak zaten diskte, karşılama hiç '
            'çıkmayacak ve bu yürüyüş ③\'ü ölçemez');
    final OnboardingStore fresh = OnboardingStore(fileOverride: flagFile);

    final _RouteWitness witness = _RouteWitness();

    await t.runAsync(() async {
      await t.pumpWidget(JabLabApp(
        onboarding: fresh,
        repository: ContentRepository(historyDirectoryOverride: tmp),
        navigatorObservers: <NavigatorObserver>[witness],
      ));
    });
    await settleAppLoad(t);
    await t.pumpAndSettle();

    // ⭐ TANIĞIN KENDİSİ ÖLÇÜLÜYOR — Ostinato'nun bedeli (M-F-582): onun
    // tanığı ilk yazımda **tanımlıydı ama BAĞLI DEĞİLDİ**. Kök rota
    // kurulduğunda tanık BİR push görmüş olmalı; görmemişse tanık bağlı
    // değildir ve aşağıdaki her "varış" ölçümü ANLAMSIZDIR.
    expect(witness.pushes, 1,
        reason: 'tanık kök rotayı görmedi (${witness.pushes} push) — '
            'NavigatorObserver bağlı değil, bu yürüyüşün varış KİPİ '
            'ölçümlerinin hepsi anlamsız olurdu');

    int lastPushes = witness.pushes;

    /// Bir ekrana VARILDIĞINI kaydeder — ve **NASIL** varıldığını tanıktan
    /// okur. Tanık son çağrıdan beri yeni bir push gördüyse `push`,
    /// görmediyse `root` (kök rota ya da onun içinde `setState` takası).
    void visit(Type screen, String name) {
      expect(find.byType(screen), findsWidgets,
          reason: '$name: kontrole basıldı ama ekran gelmedi — yürüyüş '
              'modeli yanlış, bu üyelik SAYILAMAZ');
      final Arrival mode =
          witness.pushes > lastPushes ? Arrival.push : Arrival.root;
      lastPushes = witness.pushes;
      walkedClasses.add(screen.toString());
      walkArrivals[name] = mode;
    }

    // ── 1/6 KARŞILAMA (kök) ───────────────────────────────────────────
    visit(OnboardingPage, 'onboarding');

    // Perdeler YÜRÜNEREK sayılıyor — `_steps` sabiti değil, basarak
    // GERÇEKTEN görülen sayı: ulaşılamayan bir perde bu sayıya giremez.
    int panels = 0;
    while (find.byType(OnboardingPage).evaluate().isNotEmpty) {
      panels++;
      expect(panels, lessThanOrEqualTo(kOnboardingPanels + 4),
          reason: 'karşılama kapanmıyor — "Start" son perdede bitirmiyor');
      await t.tap(find.byKey(const Key('onboarding-next')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
    }
    walkedPanels = panels;
    expect(panels, kOnboardingPanels,
        reason: 'perde sayısı değişti — gevşek ekran sayısı ($kLooseScreens) '
            'artık yanlış; devir notu ve pano güncellenmeli');

    // ③'ÜN KALICILIK YARISI — çıkış yalnız EKRANI değiştirmedi, bayrağı
    // DİSKE yazdı. Bu satır olmadan "çıkış var" demek, dönen kullanıcının
    // karşılamayı bir daha görmeyeceğini SÖYLEMEZ.
    expect(flagFile.existsSync(), isTrue,
        reason: 'karşılama geçildi ama bayrak diske YAZILMADI — kullanıcı '
            'her açılışta karşılamayı yeniden görür');

    // ── 2/6 SEÇİM ─────────────────────────────────────────────────────
    // ⚠️ Eski hâlde burası HİÇ SINANMIYORDU: karşılamayı yürüyen test
    // yalnız `OnboardingPage` findsNothing diyordu.
    // > ***BİR EKRANIN KAYBOLMASI, BİR BAŞKASININ GELDİĞİ ANLAMINA
    // > GELMEZ.*** Çıkışın İNDİĞİ yer artık ölçülüyor.
    visit(SelectPage, 'select');

    // The first product path must be reachable through the visible catalogue.
    await t.tap(find.byKey(const Key('open-solo-boxing-course')));
    await settleUntil(t, find.byKey(const Key('solo-course-progress')));
    await t.pumpAndSettle();
    visit(SoloBoxingCoursePage, 'soloCourse');
    await t.tap(find.byKey(const Key('solo-next-lesson')));
    await settleUntil(t, find.text('LEARN'));
    await t.pumpAndSettle();
    visit(SoloBoxingLessonPage, 'soloLesson');
    await t.pageBack();
    await t.pumpAndSettle();
    await t.pageBack();
    await t.pumpAndSettle();

    // ── 3/6 AYARLAR (push) ────────────────────────────────────────────
    final Finder gear = find.byIcon(Icons.settings_outlined);
    expect(gear, findsWidgets, reason: 'ayarlar düğmesi Sayfa A\'da yok');
    await t.tap(gear.first);
    await t.pumpAndSettle();
    visit(SettingsPage, 'settings');

    // ── 4/6 NEDEN YOK (push) ──────────────────────────────────────────
    await t.tap(find.textContaining('things left out').first);
    await t.pumpAndSettle();
    visit(WhyNotPage, 'whyNot');
    await t.pageBack();
    await t.pumpAndSettle();
    await t.pageBack();
    await t.pumpAndSettle();

    // ── 5/6 KURS (push) ───────────────────────────────────────────────
    // `item-boxing` sayfa DEĞİŞTİRMİYOR — `setState` ile YERİNDE açılıyor
    // (`select_page.dart`), kurs kartları aynı sayfada beliriyor.
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    visit(CoursePage, 'course');

    // ── 6/6 SEANS (push) ──────────────────────────────────────────────
    await t.tap(find.byKey(const Key('lesson-boxing.foundations.stance')));
    await t.pumpAndSettle();
    visit(SessionScreen, 'session');

    // ── SONUÇ — dört aşama YÜRÜNEREK, özet DÂHİL ──────────────────────
    // Aşama, RAY'dan (hep dört rozet çizer) değil, ekranın o an TAŞIDIĞI
    // `stage` değerinden okunuyor — ray bir beyandır, bu bir konumdur.
    final Finder flow = find.byType(SessionFlowScaffold);
    SessionStage? stageNow() => flow.evaluate().isEmpty
        ? null
        : t.widget<SessionFlowScaffold>(flow).stage;

    final Set<SessionStage> stages = <SessionStage>{};
    int taps = 0;
    for (SessionStage? s = stageNow(); s != null; s = stageNow()) {
      stages.add(s);
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
      // değil, GERÇEK bir durum değişikliği bekleniyor.
      for (int f = 0; f < 6; f++) {
        await t.pump(const Duration(milliseconds: 200));
        if (stageNow() != s) break;
      }
    }
    walkedStages = stages.length;

    expect(stages.length, kSessionStages,
        reason: 'yürünen aşama sayısı değişti — gevşek ekran sayısı '
            '($kLooseScreens) artık yanlış; devir notu ve pano '
            'güncellenmeli. Yürünenler: ${stages.map((SessionStage s) => s.name)}');
    // Bir aşamanın ENUM'da olması, ona GİDEN yolun olması değildir.
    expect(stages, SessionStage.values.toSet(),
        reason: 'bir aşamaya yürünerek ulaşılamıyor');

    // AKIŞ KAPANDI: seans POP etti ve kullanıcı kursa döndü. Bir akış,
    // bittiği yerde kullanıcıyı bırakmıyorsa "baştan sona çalışıyor"
    // sayılmaz.
    expect(witness.pops, greaterThan(0),
        reason: 'seans hiç POP etmedi — "Done" kullanıcıyı akıştan '
            'çıkarmıyor, akış SONUÇTA kapanmıyor');
    expect(find.byType(CoursePage), findsWidgets,
        reason: 'seans kapandı ama kullanıcı kurs sayfasına dönmedi');

    // ── ⭐ (b) VARIŞ KİPİ — beyansız varış KIRMIZI ─────────────────────
    expect(walkArrivals, <String, Arrival>{
      'onboarding': Arrival.root,
      'select': Arrival.root,
      'soloCourse': Arrival.push,
      'soloLesson': Arrival.push,
      'settings': Arrival.push,
      'whyNot': Arrival.push,
      'course': Arrival.push,
      'session': Arrival.push,
    }, reason: 'bir üyenin VARIŞ KİPİ değişti. Bu sayı-değil-KİP ölçümü, '
        'eski toplam-assert\'in görünmez kıldığı şeydi: bir ekran artık '
        'push ile mi geliyor, kökte mi takas ediliyor?');

    final int rootArrivals = walkArrivals.values
        .where((Arrival a) => a == Arrival.root)
        .length;
    expect(rootArrivals, kRootArrivals,
        reason: 'kök varış sayısı $kRootArrivals değil $rootArrivals — '
            'ÜÇÜNCÜ bir kök varış bir BEYAN değil BULGUDUR; sözleşme (b) '
            'bunu görünür kılmak için var');

    // ⚠️ TANIĞIN VARSAYIMI DA SINANIYOR — VE İLK YAZIMDA YANLIŞTI.
    //
    // *"Bu ağaçta rotalar anonim"* diye yazmıştım; kapı ilk koşumda ötüp
    // gerçeği gösterdi: `[/, null, null, null, null]` — **kök rota `/`
    // adını TAŞIYOR** (`MaterialApp` `home:`e varsayılan adı verir), gerçek
    // gezinmelerin **dördü** ise anonim.
    //
    // > ***BİR TANIĞIN NEYE BAKAMAYACAĞI DA ÖLÇÜLÜR — VE İLK TAHMİN
    // > YANLIŞTI; DÜZELTEN ŞEY KAPININ KENDİSİ OLDU.***
    //
    // Sonuç aynı yere çıkıyor ama sebebi artık DOĞRU: ad, üyeleri **ayırt
    // etmeye yetmiyor** — dört gerçek varışın dördü de `null`, yani ada
    // bakan bir tanık onları birbirinden ayıramaz ve *sessizce boş* kalır.
    // Bu yüzden tanık **olay** sayıyor.
    expect(witness.pushedNames.first, '/',
        reason: 'kök rotanın adı değişti (${witness.pushedNames.first}) — '
            'tanığın kök/push ayrımı bu varsayıma dayanıyor');
    expect(witness.pushedNames.skip(1).every((String? n) => n == null), isTrue,
        reason: 'bir GEZİNME rotası artık AD taşıyor '
            '(${witness.pushedNames}) — adlar boş olduğu için tanık olay '
            'sayıyordu; artık ada da bakılabilir, ölçüm GÜÇLENDİRİLEBİLİR');

    // ignore: avoid_print
    print('  A1 TAM AKIŞ · varılan ${walkedClasses.length} ekran '
        '(push ${walkArrivals.values.where((Arrival a) => a == Arrival.push).length} + '
        'kök $rootArrivals) · perde $panels · aşama ${stages.length} · '
        'tanık: ${witness.pushes} push / ${witness.pops} pop');
  });

  test('gevşek okuma ①+②: perde ve aşama YÜRÜYÜŞTEN geliyor', () {
    // ⛔ VAKUM MUHAFIZI: yürüyüş koşmadıysa bu kontrol sessizce geçerdi.
    expect(walkedPanels, isNotNull,
        reason: 'yürüyüş koşmadı — perde sayısı ölçülmedi, bu kontrol '
            'ANLAMSIZ olurdu');
    expect(walkedStages, isNotNull,
        reason: 'yürüyüş koşmadı — aşama sayısı ölçülmedi');
    expect(walkedPanels, kOnboardingPanels);
    expect(walkedStages, kSessionStages);
  });

  /// SÖZLEŞME (a)+(c) — aday küme KODDAN TÜRETİLİR, üyelik YÜRÜYEREK
  /// kanıtlanır, ve **varılamayan aday AYRI raporlanır** (J-231).
  ///
  /// Koordinatör hükmü: *yalnız yürüyerek ölçen bir kural, ULAŞAMADIĞINI
  /// göremez* — boyanmış kontrolü olmayan bir rota yürüyüşe hiç görünmez ve
  /// *"orada bir şey yok"* ile *"var, varamadım"* ayırt edilemez.
  /// > ***Yürüyüş VARLIĞI kanıtlar, YOKLUĞU kanıtlamaz — bir yokluk iddiası,
  /// > BEKLENEN bir küme olmadan kurulamaz.***
  ///
  /// Bende eksik olan tek parça **(a)** idi: beklenen küme **elle** yazılıydı
  /// (*hafızadan okuyan* kısım). Artık **koddan türetiliyor**; doğrulama
  /// (yürüyüş) olduğu gibi kaldı.
  ///
  /// ⚠️ Türetim ilk hâlinde **BOZUKTU** ve pozitif kontrol yakaladı: `_XState`
  /// sınıflarını eleyince **her StatefulWidget ekranı** kayboldu (8 aday, ve
  /// `SelectPage`/`SessionScreen`/`OnboardingPage` yoktu). `_XState → X`
  /// eşlemesiyle düzeltildi. *Bir desen, neyi kaçırdığı bilinmeden envanter
  /// sayılamaz.*
  test('SÖZLEŞME (a)+(c) — aday KODDAN türetiliyor, varılamayan AYRI', () {
    // Kaynak ağacı BİR KEZ okunur; hem türetim hem (c) gerekçe yüklemleri
    // aynı anlık görüntüden beslenir (iki ayrı okuma iki ayrı gerçek olurdu).
    //
    // ⚠️ **YORUMLAR SÖKÜLÜR — ve bunun sebebi ÖLÇÜLDÜ (J-242/P7):** kamera
    // kapısı kaynaktan GERÇEKTEN sökülmüşken (`if (true)`), dosyaya düşülen
    // tek bir `// CameraHarnessScreen.isAvailable` yorumu (c) yüklemini
    // **yeşil geçirdi.** Yani J-239'un *"tek ölçülü gerekçe"* dediği yüklem
    // bile zehirlenebiliyordu — ve zehrin yönü **sessiz-yeşildi**, gürültülü
    // kırmızı değil.
    // > ***Bir kaynağı METİN olarak tarayan ölçüm, o metnin ÇALIŞAN kısmıyla
    // > ANLATAN kısmını ayırmıyorsa, kodun kendisi hakkında değil DOSYA
    // > hakkında konuşur.***
    // ⛔ SINIR AÇIK: bu bir ayrıştırıcı değil, satır düzeyi bir sökücü —
    //    içinde `//` geçen bir DİZGE sabiti (örn. bir URL) taranan kopyada
    //    kırpılır. Kalan sapma bu; kapanmadı, ADIYLA duruyor.
    String codeOnly(String s) => s
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ')
        .split('\n')
        .map((String l) {
          final int i = l.indexOf('//');
          return i < 0 ? l : l.substring(0, i);
        })
        .join('\n');

    final Map<String, String> libSrc = <String, String>{};
    for (final FileSystemEntity e
        in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      libSrc[e.path] = codeOnly(e.readAsStringSync());
    }
    // Sökücünün POZİTİF KONTROLÜ: gerçekten söküyor mu? (yeşil bir sökücü,
    // hiç sökmeyen bir sökücüyle aynı görünür.)
    expect(codeOnly('a(); // b();\n/* c(); */ d();'), isNot(contains('b();')));
    expect(codeOnly('a(); // b();\n/* c(); */ d();'), isNot(contains('c();')));
    expect(codeOnly('a(); // b();\n/* c(); */ d();'), contains('d();'));

    final Set<String> derived = <String>{};
    for (final String src in libSrc.values) {
      for (final String chunk in src.split(RegExp(r'\n(?=class )'))) {
        final RegExpMatch? m = RegExp(r'class\s+(\w+)').firstMatch(chunk);
        if (m == null || !chunk.contains('Scaffold(')) continue;
        String name = m.group(1)!;
        // StatefulWidget'ın Scaffold'u State'te yaşar: `_XState` → `X`.
        if (name.startsWith('_') && name.endsWith('State')) {
          name = name.substring(1, name.length - 5);
        }
        if (!name.startsWith('_')) derived.add(name);
      }
    }

    // ══════════════════════════════════════════════════════════════════
    // (a) — KOORDİNATÖR HÜKMÜNÜN İKİ ŞARTI (2026-08-13, J-244)
    //
    // Hüküm: *tek yönlü dedektör KABUL EDİLDİ, ikinci türetim KURULMAYACAK*
    // — gerekçe bu ağaçta ölçüldü: ters yön YAPISAL OLARAK yanlış (kök
    // takaslı `OnboardingPage`/`SelectPage` **hiç push edilmiyor**), yani
    // simetrik bir uzlaşma daha güçlü değil **YANLIŞ** bir kapı kurardı.
    //
    // ⛔ ŞART-2 · ARTIK RİSK, ADIYLA — kapatılmadı, KAPATILAMAZ:
    //
    //   ***HİÇBİR KANALIN GÖRMEDİĞİ BİR EKRAN GÖRÜNMEZ KALIR.***
    //
    // Aday kümesi TEK kanaldan türüyor: `Scaffold(` kuran sınıf. Bu kanal
    // yapısaldır ama TAM DEĞİLDİR — `Scaffold` kurmayan bir ekran-benzeri
    // yüzey (kabuk içine monte olan bir görünüm, bir overlay) bu kapının
    // paydasına HİÇ girmez ve eksikliği **sessizdir**: kapı onu "varılamadı"
    // diye de saymaz, çünkü aday bile değildir.
    // 📌 Ölçüldü, KOPYALANMADI — ve devralınan sayı YANLIŞ ÇIKTI:
    //    devir notu *"ayrışma 4"* diyordu, **gerçek 5**. Türetim replikası
    //    kapının `12`sini birebir ürettiği için replika sadık; eksik olan
    //    **`LiveCoachSurface`** idi. Sebep ölçüldü: devralınan taramanın
    //    deseni `Page|Screen|View`, `Surface` ile bitenleri **hiç görmüyor**.
    //    > ***(a) MADDESİNİN KENDİ UYARISI, (a)'YI ÖLÇEN TARAMAYI ISIRDI:***
    //    > *bir desenin kapsamı, onu yazanın adlandırma alışkanlığı kadardır.*
    //    5 sınıf: `LibraryPage` · `ProgressPage` · `SessionSummaryView` ·
    //    **`LiveCoachSurface`** (dördü dondurulmuş `shell_candidate/`) +
    //    **`SkeletonPreview`** (`app/` altında — CANLI ağaçta, asıl soru bu).
    //    ⛔ Ve BU sayı da tam değil: benim desenim de bir alışkanlık
    //    (`Page|Screen|View|Preview|Surface`). İddia edilen tek şey **5 > 4**.
    //    Kapsam hükmü koordinatörde.
    //
    // ✅ **`SkeletonPreview` HÜKMÜ VERİLDİ (J-252, 2026-08-14) — ölçümle:**
    //    Devir notu bunu *"asıl soru"* diye bırakmıştı (`app/` altında, canlı
    //    ağaçta). Cevap: **BU BİR EKRAN DEĞİL, BİR BİLEŞENDİR** — dolayısıyla
    //    bu kapının paydasında EKSİK DEĞİL, **ALAKASIZ**.
    //    Kanıt (hepsi bu gece ölçüldü, biri iddia değil):
    //     1. Hiçbir rotası yok: `LiveCoachSurface.preview` yuvasına monte
    //        oluyor, o da `SessionScreen`in canlı aşamasının içinde. Tek
    //        başına "varılabilir" değil — `Navigator` onu hiç görmüyor.
    //     2. Dört çağrı yerinin dördü de aynı ekranın içinde
    //        (`session_screen.dart` 834 · 866 · 884 · 907).
    //     3. ⭐ Ve KAPSAMSIZ DEĞİL: J-250'de bu bileşenin CÜMLESİ üç ayrı
    //        kapıyla ölçülüyor (`live_celiski_test`), ayrıca
    //        `placeholder_surface_test` + `live_honesty_bucket_test` onu
    //        doğrudan pump ediyor ve YÜZEY YÜRÜYÜŞÜ çıktısında dizgeleri
    //        görünüyor (aşama 3). Yani bir rotanın alacağından **daha fazla**
    //        kanıt taşıyor.
    //    > ***BİR ADLANDIRMA DESENİNİN YAKALADIĞI ŞEY, O ŞEYİN ROLÜ DEĞİL
    //    > ADIDIR*** — `…Preview` ile biten bir sınıf "ekran" olmak zorunda
    //    > değil. (a) taraması ROL değil AD ölçüyor; bu kalem o farkın örneği.
    //    ⚠️ Kalan dördü (`LibraryPage` · `ProgressPage` · `SessionSummaryView`
    //    · `LiveCoachSurface`) donmuş `shell_candidate/` altında ve hükmü
    //    HÂLÂ koordinatörde — onlar için bir şey iddia edilmiyor.
    //
    // ⚠️ ŞART-1 · VAKUM — ARTIK DOĞRUDAN, ÖRTÜK DEĞİL.
    // Koruma bugüne kadar `knownFloor ⊆ derived` üzerinden GEÇİŞLİYDİ ve
    // gücü `knownFloor`un dolu kalmasına bağlıydı ⇒ o küme bir gün
    // boşaltılsaydı **iki muhafız aynı anda vakuma düşerdi**.
    // > ***İKİ KONTROLÜN AYNI VARSAYIMA DAYANMASI, İKİ KONTROL DEĞİL BİRDİR.***
    // ══════════════════════════════════════════════════════════════════
    expect(
      derived,
      isNotEmpty,
      reason: 'VAKUM: `Scaffold(` deseni HİÇ aday bulamadı. Tek kanallı bir '
          'türetimin en gerçek riski budur — kanal susarsa "0 varılamayan" '
          'vakum-doğru olarak YEŞİL öter. `lib/` taranmadıysa ya da desen '
          'bozulduysa burası ötmeli.',
    );

    // ── (e) ELLE BİLİNEN KÜME — KAYNAK DEĞİL, TÜRETİMİN POZİTİF KONTROLÜ ──
    //
    // ⚠️ **BU KÜME BİR ALT SINIRDIR, TAM ENVANTER DEĞİLDİR.** Aday kümenin
    // kaynağı artık DESEN (yukarıda, koddan türetiliyor); buradaki isimler
    // yalnız *"türetim bunları KAÇIRMAMALI"* diyor. Envanteri buradan
    // okumak, (a) parçasını geri almak olur.
    //
    // ⚠️ **BURAYA EKLEME YAPMAK ENVANTER GÜNCELLEMESİ DEĞİL, KONTROLÜN
    // TABANINI YÜKSELTMEKTİR.** Yeni bir ekran eklendiğinde asıl iş onu
    // *yürüyüşe katmaktır*; bu listeye yazmak yalnız "türetim artık bunu da
    // kaçıramaz" demek. İkisi karıştırılırsa liste altı ay sonra yeniden
    // "envanter" sanılır — (e)'nin var olma sebebi tam bu.
    //
    // 🎯 NEDEN KALDI (kendi vakam): türetimin ilk hâlinde `_XState` elemesi
    // **her StatefulWidget ekranını** yok etmişti (8 aday; `SelectPage`/
    // `SessionScreen`/`OnboardingPage` YOKTU) ve **yakalayan şey bu elle
    // kümeydi.** Koordinatör onu sözleşmede "hafızadan okuyor" diye elemişti;
    // ölçüm gösterdi ki *bir artefaktın bir ROLDE kusurlu olması, her rolde
    // kusurlu olduğu anlamına gelmez.* Kaynak olarak yanlış, KONTROL olarak
    // doğru → silinmedi, **rütbesi düşürüldü.**
    const Set<String> knownFloor = <String>{
      'OnboardingPage', 'SelectPage', 'SettingsPage',
      'WhyNotPage', 'CoursePage', 'SessionScreen',
      'SoloBoxingCoursePage', 'SoloBoxingLessonPage',
    };
    expect(knownFloor.difference(derived), isEmpty,
        reason: 'türetim, bilinen taban ekranlarını kaçırıyor: '
            '${knownFloor.difference(derived)} — desen bozuk, aşağıdaki '
            '"varılamayan" listesi ANLAMSIZ olurdu');

    // ── (b) DENKLEMİN "VARILAN" TARAFI — ARTIK YÜRÜYÜŞTEN ──────────────
    //
    // 🔴 ÖNCEKİ HÂL: yukarıdaki elle küme **aynı zamanda** denklemin
    // `varılan` tarafıydı. Yani (e) ile "kaynak olmaktan çıkarılan" liste,
    // arka kapıdan **(b)'nin işini** görüyordu: gerçek yürüyüş başka bir
    // testteydi ve ***ikisinin uzlaştığını hiçbir şey sınamıyordu.***
    //
    // Artık `varılan`, **A1 yürüyüşünün çıktısı** (`walkedClasses`) — bir
    // ekranın buraya girmesi, ona **boyanmış bir kontrole basılarak
    // varıldığının** ve tanığın varışı GÖRDÜĞÜNÜN kanıtı.
    //
    // ⛔ VAKUM MUHAFIZI: yürüyüş koşmadıysa küme boş olur ve bölme
    // *"her şey varılamaz"* diye **vakum-doğru** geçerdi.
    expect(walkedClasses, isNotEmpty,
        reason: 'A1 yürüyüşü koşmadı — `walkedClasses` boş. Bu bölme '
            'testinin sonucu ANLAMSIZ olurdu: türetilen her aday '
            '"varılamayan" sayılırdı ve kapı yine YEŞİL geçerdi');
    final Set<String> walked = walkedClasses;

    // (e) POZİTİF KONTROL — elle taban, YÜRÜYÜŞÜN de altında mı? Yürüyüş
    // bir ekranı sessizce atlarsa (kontrol kayboldu, tap ıskaladı) burası
    // öter. *Elle liste kaynak olarak yanlış, KONTROL olarak doğru.*
    expect(knownFloor.difference(walked), isEmpty,
        reason: 'yürüyüş, bilinen taban ekranlarına VARAMADI: '
            '${knownFloor.difference(walked)} — bir kontrol kayboldu ya da '
            'tap ıskaladı; "varılamayan" kovası YANLIŞ büyür');
    expect(walked.length, kStrictRoutes,
        reason: 'yürünen küme ile katı sayı ayrışmış');

    // (c) ADAY OLUP VARILAMAYAN — kaybolmuyor, adıyla ve GEREKÇESİYLE duruyor.
    const Map<String, String> unreachableWhy = <String, String>{
      'CameraHarnessScreen': 'kDebugMode kapılı — sevk edilen üründe açılmıyor',
      'ContentFailureScreen': 'yalnız içerik yüklenemezse çizilir; kontrole '
          'basarak ulaşılmıyor',
      'Root': 'uygulama kökünün YÜKLEME iskelesi — ayrı bir ekran değil',
      'SessionFlowScaffold': 'SessionScreen\'in İÇİNDE kullanılan kabuk '
          'parçası, ayrı rota değil',
      'ItemPage': 'lib/shell_candidate/ — DONDURULMUŞ terfi envanteri',
      'ShellScaffold': 'lib/shell_candidate/ — DONDURULMUŞ terfi envanteri',
    };
    final Set<String> registered = unreachableWhy.keys.toSet();
    final Set<String> unreachable = derived.difference(walked);
    expect(unreachable, registered,
        reason: 'ADAY olup VARILAMAYAN küme DEĞİŞTİ.\n'
            '  ölçülen : ${unreachable.toList()..sort()}\n'
            '  kayıtlı : ${unreachableWhy.keys.toList()..sort()}\n'
            'Yeni bir ekran eklenip yürüyüşe katılmadıysa burada görünür — '
            '"orada bir şey yok" ile "var, varamadım" ayrı kovalardır.');
    for (final MapEntry<String, String> e in unreachableWhy.entries) {
      expect(e.value.length, greaterThan(25),
          reason: '${e.key} gerekçesiz — varılamayan bir aday, SEBEBİ '
              'yazılmadan listede duramaz');
    }

    // ── (c) GEREKÇELER ARTIK BEYAN DEĞİL, ÖLÇÜLÜ (J-242) ─────────────────
    //
    // 🔴 ÖNCEKİ HÂL (J-239 ölçümü): denetim yalnız yukarıdaki **uzunluktu**
    //    (`> 25 karakter`). Altı gerekçenin **yalnız biri** ölçülüydü
    //    (`CameraHarnessScreen.isAvailable`), beşi **beyandı** — sözleşme ise
    //    açıkça *"sebep de ÖLÇÜLÜR"* diyor.
    //    > ***Yanlış bir sebep, sebepsizlikten daha kötüdür: denetimi
    //    > DOĞRULANMIŞ gösterir.***
    //    Uzunluk kapısı **silinmedi** — bir taban olarak duruyor (*gerekçe
    //    YAZILMIŞ olmalı*); ölçüm onun ÜSTÜNE bindi, yerine geçmedi.
    //
    // 🔑 ÖLÇÜM PRİMİTİFİ — **İKİNCİ, BAĞIMSIZ KANAL:** aday kümesi `Scaffold(`
    // kuran sınıftan türüyor (yapısal); burada ise **rota hedefleri** kaynaktan
    // çıkarılıyor (`MaterialPageRoute(builder: … => X(`). İkisi farklı şeye
    // bakar: biri *"ekran gibi çiziyor mu"*, öbürü *"rota hedefi mi"*.
    final Set<String> routed = <String>{};
    for (final String src in libSrc.values) {
      for (final RegExpMatch m in RegExp(
              r'MaterialPageRoute<[^>]*>\(\s*builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?(\w+)\s*\(')
          .allMatches(src)) {
        routed.add(m.group(1)!);
      }
    }
    expect(routed, isNotEmpty,
        reason: 'rota kanalı BOŞ döndü — desen bozulmuş olmalı; aşağıdaki '
            '"rota hedefi değil" gerekçeleri VAKUM-DOĞRU geçerdi');

    // ⭐ İKİ KANALIN UZLAŞMASI — ve (d)'nin GÖLGELİ yönünün CANLI karşılığı.
    //
    // (d) altındaki `walked ⊄ derived` yönü bugün mekanik olarak kurulamıyor
    // (taban == yürüyüş). Ama AYNI kusur sınıfı — *"türetimin göremediği bir
    // ekran"* — burada **gölgesiz** ölçülebiliyor: bir sınıf rota hedefiyse
    // ürün onu EKRAN sayıyor demektir; aday kümesinde yoksa `Scaffold(` deseni
    // KÖR demektir. Tam olarak (a)'nın adı konmuş kör noktası:
    // *`Scaffold`unu ortak bir kabuğa devreden ekran aday olmaz.*
    //
    // ⛔ TERS YÖN İSTENMİYOR: `derived ⊄ routed` meşru (kök takasıyla gelen
    //    `OnboardingPage`/`SelectPage` hiç `push` edilmiyor — J-240'ın kök
    //    varış bulgusu). İki kanal aynı şeyi ölçmüyor; uzlaşma TEK YÖNLÜ.
    expect(routed.difference(derived), isEmpty,
        reason: 'İKİ KANAL AYRIŞTI — rota hedefi olan sınıf aday değil: '
            '${routed.difference(derived)}. Rota onu EKRAN sayıyor, '
            '`Scaffold(` deseni GÖREMİYOR ⇒ türetim kör ve "varılamayan" '
            'kovası bu ekranı hiç sormaz.');

    bool mentionedOutside(String name, String dir) => libSrc.entries
        .any((MapEntry<String, String> e) =>
            !e.key.startsWith(dir) && e.value.contains(name));
    bool builtSomewhere(String name, String declPath) => libSrc.entries.any(
        (MapEntry<String, String> e) =>
            e.key != declPath && e.value.contains('$name('));

    // Her gerekçe bir YÜKLEM taşır; yüklem gerekçenin KENDİ iddiasını ölçer.
    final Map<String, bool Function()> reasonHolds = <String, bool Function()>{
      // iddia: "kDebugMode kapılı" → kapı gerçekten kDebugMode'dan mı türüyor,
      // ve onu açan HER çağrı yeri kapının arkasında mı?
      'CameraHarnessScreen': () {
        const String decl = 'lib/app/camera_harness_screen.dart';
        final bool gateFromDebug = RegExp(r'isAvailable\s*=>\s*kDebugMode')
            .hasMatch(libSrc[decl] ?? '');
        final Iterable<String> callers = libSrc.entries
            .where((MapEntry<String, String> e) =>
                e.key != decl && e.value.contains('CameraHarnessScreen('))
            .map((MapEntry<String, String> e) => e.value);
        return gateFromDebug &&
            callers.isNotEmpty &&
            callers.every((String s) => s.contains('CameraHarnessScreen.isAvailable'));
      },
      // iddia: "kontrole basarak ulaşılmıyor" → rota hedefi DEĞİL, ama bir
      // yerde çiziliyor (hiç çizilmiyorsa gerekçe başka olurdu: ölü kod).
      'ContentFailureScreen': () =>
          !routed.contains('ContentFailureScreen') &&
          builtSomewhere('ContentFailureScreen', 'lib/app/content_failure_screen.dart'),
      // iddia: "ayrı bir ekran değil, kökün iskelesi" → sınıf ÖZEL (`_Root`,
      // dışarıdan rota hedefi olamaz) ve yalnız `home:` olarak bağlanıyor.
      'Root': () {
        final String app = libSrc['lib/app/jablab_app.dart'] ?? '';
        return app.contains('class _Root') &&
            RegExp(r'home:\s*_Root\(').hasMatch(app) &&
            !routed.contains('Root');
      },
      // iddia: "SessionScreen'in İÇİNDE kullanılan kabuk parçası, ayrı rota
      // değil" → rota hedefi değil VE SessionScreen onu kuruyor.
      'SessionFlowScaffold': () =>
          !routed.contains('SessionFlowScaffold') &&
          (libSrc['lib/app/session_screen.dart'] ?? '')
              .contains('SessionFlowScaffold('),
      // iddia: "lib/shell_candidate/ — DONDURULMUŞ envanter" → orada tanımlı VE
      // o dizinin DIŞINDAN hiç anılmıyor. (Ayrımı gerçek kılan şey:
      // `SessionFlowScaffold` de orada tanımlı ama DIŞARIDAN anılıyor — bu
      // yüzden gerekçesi ayrı, ve yüklem ikisini birbirine karıştırmıyor.)
      'ItemPage': () =>
          (libSrc['lib/shell_candidate/library_pages.dart'] ?? '')
              .contains('class ItemPage') &&
          !mentionedOutside('ItemPage', 'lib/shell_candidate/'),
      'ShellScaffold': () =>
          (libSrc['lib/shell_candidate/shell_scaffold.dart'] ?? '')
              .contains('class ShellScaffold') &&
          !mentionedOutside('ShellScaffold', 'lib/shell_candidate/'),
    };

    // ⛔ YÜKLEMSİZ KAYIT KALAMAZ — yeni bir varılamayan aday eklenip yüklemi
    // yazılmazsa burası öter; yoksa (c) sessizce "beyan"a geri düşerdi.
    expect(reasonHolds.keys.toSet(), registered,
        reason: 'her varılamayan adayın gerekçesi ÖLÇÜLMEK ZORUNDA — '
            'yüklemi olmayan kayıt: ${registered.difference(reasonHolds.keys.toSet())} · '
            'kaydı olmayan yüklem: ${reasonHolds.keys.toSet().difference(registered)}');
    for (final MapEntry<String, bool Function()> e in reasonHolds.entries) {
      expect(e.value(), isTrue,
          reason: '${e.key} — GEREKÇE ARTIK DOĞRU DEĞİL: '
              '"${unreachableWhy[e.key]}". Kaynak değişti ve kayıt eskidi; '
              'gerekçeyi düzelt ya da ekranı yürüyüşe kat.');
    }
    // ignore: avoid_print
    print('  (c) GEREKÇE · ${reasonHolds.length}/${registered.length} '
        'varılamayan adayın sebebi ÖLÇÜLÜ (rota kanalı: ${routed.length} hedef)');

    // ── (d) BÖLME — YÖN ADIYLA SINANIR, ARİTMETİKLE DEĞİL (J-241) ────────
    //
    // 🔴 ÖNCEKİ HÂL: `expect(walked.length + unreachable.length, derived.length,
    //    reason: 'payda TOPLAMIYOR — bir aday hiçbir kovaya girmemiş')`.
    //    İKİ ayrı kusuru vardı ve ikisi de ÖLÇÜLDÜ (mutasyon, J-241):
    //
    // ① **RAPORU YANLIŞTI — imkânsız bir kusuru anlatıyordu.** `unreachable`
    //    zaten `derived − walked` diye TÜRETİLİYOR ⇒ "bir aday hiçbir kovaya
    //    girmemiş" hâli tanım gereği oluşamaz. O kusuru yakalayan şey yukarıdaki
    //    (c) eşitliğidir — ölçüldü (M2: kayıttan bir isim silindi → ilk kırmızı
    //    *"ADAY olup VARILAMAYAN küme DEĞİŞTİ"*). Aritmetiğin gerçekten sınadığı
    //    TEK şey `walked ⊆ derived` idi; cümlesi bunu SÖYLEMİYORDU.
    //    → ***bir kapının raporu, sınadığı şeyi değil sanılan şeyi anlatıyorsa
    //    yeşili de kırmızısı da yanlış okunur*** (J-226'nın sınıfı, bu kez
    //    kendi bölme testimde).
    //
    // ② **J-239'un "TANIM GEREĞİ HİÇ ÖTEMEZ" HÜKMÜ FAZLA GENİŞTİ.** Dişi VAR:
    //    M3'te üç komşu (`knownFloor ⊆ walked` · `|walked| == kStrictRoutes` ·
    //    (c) eşitliği) kapatılıp yürüyüşe türetimde olmayan bir sınıf eklenince
    //    assert GERÇEKTEN öttü. Komşular yerindeyken (M1) ötmedi — `walked.length`
    //    kontrolü önce yakaladı. Yani kusur **totoloji değil GÖLGELENME**:
    //    → ***bir assert'in yeşilliği, ötme yeteneğinin değil KOMŞULARININ
    //    kanıtı olabilir.*** (M-F-287: sınırı geniş yazmak dar yazmak kadar
    //    pahalı — "hiç ötemez" demek, ötme koşulunu aramayı durdurur.)
    //
    // Yön artık ADIYLA duruyor. Sınadığı şey (a)'nın kör noktasının TA KENDİSİ:
    // türetim `Scaffold(` kuran sınıfa bakar; `Scaffold`unu ortak bir kabuğa
    // DEVREDEN bir ekran aday olmaz ama YÜRÜNEBİLİR — o zaman "varılamayan"
    // kovası onu hiç sormaz ve envanter sessizce eksilir.
    expect(walked.difference(derived), isEmpty,
        reason: 'YÜRÜYÜŞ, türetimin aday saymadığı bir ekrana vardı: '
            '${walked.difference(derived)} — desen bu ekranı GÖREMİYOR '
            '((a) kör noktası). Aday olmadığı için "varılamayan" kovasına da '
            'hiç sorulmaz: envanter SESSİZCE eksilir.');

    // ⚠️ VE BU YÖN BUGÜN CANLI DEĞİL — yeşilliği kanıt sayılmasın diye YAZILIYOR.
    // `knownFloor ⊆ walked` (yukarıda, (e) pozitif kontrolü) + `|walked| ==
    // kStrictRoutes` + `|knownFloor| == kStrictRoutes` üçlüsü bugün
    // `walked == knownFloor` eşitliğini ZORLUYOR; `knownFloor ⊆ derived` de
    // ayrıca kapılı ⇒ `walked ⊆ derived` MEKANİK OLARAK doğru, ihlali
    // kurulamaz. Yön, yürüyüş tabanın ÜSTÜNE çıktığı gün (7. ekran yürünüp
    // tabana yazılmadığında) kendiliğinden canlanır — ve satır bunu BASAR.
    //
    // ⛔ `walked == knownFloor` ASSERT EDİLMEZ: (e) tabanı bir ALT SINIRDIR,
    //    eşitlik yazmak onu envantere geri çevirir (J-233 sözleşmesi).
    final bool splitDirectionLive = walked.length > knownFloor.length;
    // ignore: avoid_print
    print('  (d) YÖN · "walked ⊄ derived" kontrolü: '
        '${splitDirectionLive ? "CANLI" : "GÖLGELİ"} '
        '(yürünen ${walked.length} · taban ${knownFloor.length} — '
        'taban yürüyüşe eşitken ihlal kurulamaz)');

    // Denklemin İKİ YANI AYRI KAYNAKTAN: sol = kod deseni, sağ = tanıklı
    // yürüyüş + elle gerekçeli kayıt. Sayı değişmedi; NEYLE KANITLANDIĞI
    // değişti (J-240'ın provenans dersi, bu kez raporlamada).
    // ignore: avoid_print
    print('  GEZİLEBİLİRLİK · türetilen aday ${derived.length} (kod deseni) = '
        'yürünen ${walked.length} (tanıklı yürüyüş) + '
        'varılamayan ${registered.length} (elle kayıt, gerekçeli)');
  });

  test('SAYMA KURALI YAZILI — ve sayı ondan KOPMUYOR (J-221)', () {
    // Gravita'nın uyarısı: "sekmeleri farklı sayıyorsak iki sayı AYNI ŞEYİ
    // ÖLÇMÜYOR; fark içerik değil SAYMA KURALI olur." Sayı kapılıydı, KURAL
    // değildi — kuralsız bir sayı hatlar arasında kıyaslanamaz.
    final File rule =
        File('docs/gates/GEZILEBILIRLIK-SAYMA-KURALI.md');
    expect(rule.existsSync(), isTrue,
        reason: 'sayma kuralı belgesi yok — 6/11 sayısı kuralsız kalır');
    final String src = rule.readAsStringSync();
    // Dört sorunun dördü de cevaplanmış olmalı.
    for (final String q in <String>[
      'Sekme', 'envanteri', 'nereden başlıyor', 'Onboarding içeride mi',
    ]) {
      expect(src, contains(q), reason: '"$q" sorusu belgeden düşmüş');
    }
    // Sayılar belgede ve kodda AYNI olmalı — belge bayatlarsa öter.
    expect(src, contains('katı **$kStrictRoutes**'),
        reason: 'belgedeki katı sayı koddan KOPMUŞ');
    expect(src, contains('gevşek **$kLooseScreens**'),
        reason: 'belgedeki gevşek sayı koddan KOPMUŞ');
    expect(src, contains('$kStrictRoutes − 2 + $kOnboardingPanels + '
        '$kSessionStages'),
        reason: 'türetim formülü belgede koddakiyle aynı değil');
    // Kör nokta kendi BÖLÜMÜYLE durmalı.
    //
    // ⚠️ İlk hâli `src.toUpperCase().contains('KÖR NOKTA')` idi ve MUTASYONU
    // GEÇTİ: başlığı sildiğimde gövdedeki küçük harfli geçişler ("bu kör
    // nokta bir kez ölçüldü") kapıyı tatmin etti. *Bir kavramdan SÖZ eden
    // cümle, o kavramın BÖLÜMÜ değildir* — kapı bölüm başlığını arıyor.
    expect(src, contains('## ⚠️ ENVANTER YÖNTEMİNİN KÖR NOKTASI'),
        reason: 'envanter yönteminin kör-nokta BÖLÜMÜ belgeden düşmüş; bir '
            'sayma kuralı, neyi göremediğini söylemeden tam değildir');
    expect(src, contains('KAPILI DEĞİL'),
        reason: 'kör noktanın KORUMASIZ olduğu beyanı düşmüş — bugün boş '
            'çıkan bir tarama, korunmadığı yazılmazsa güvence sanılır');
  });

  test('gevşek okuma ③: TÜRETİLEN SAYI — bileşen değişirse burası öter', () {
    // Bilerek totoloji: bileşenlerden biri (① ya da ②) değiştiğinde bu satır
    // düşer ve sabiti güncelleyen kişi, DIŞARIYA verilen sayının da
    // değiştiğini görmek ZORUNDA kalır. J-167'de eksik olan tam buydu —
    // gevşek sayı bir yorumda yaşıyordu, kimse ona çarpmıyordu.
    expect(kLooseScreens, 13,
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
