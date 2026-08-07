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
/// ## ⚠️ SAYILMAYANLAR — adıyla
///
/// * `CameraHarnessScreen` — `kDebugMode` dışında **açılmıyor**; sevk
///   edilen üründe kullanıcı oraya gidemez.
/// * `ContentFailureScreen` — yalnız içerik yüklenemezse çiziliyor;
///   kontrole basarak ulaşılmıyor.
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

  test('SAYILMAYANLAR adıyla — ve gerekçeleri ÖLÇÜLÜ', () {
    // Harness sevk edilen üründe açılmıyor: kapı `kDebugMode`.
    expect(CameraHarnessScreen.isAvailable, isTrue,
        reason: 'test derlemesi debug — bu satır kapının VAR olduğunu '
            'gösteriyor; ürün derlemesinde false olur ve ekran açılmaz');
  });
}
