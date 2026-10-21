import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_store.dart';

import 'app_pump.dart';

/// DAR-CİHAZ TAŞMA KAPISI (Lissom + Ostinato emsali, koordinatör 2026-08-06).
///
/// `flutter_test`in VARSAYILAN yüzeyi ~800pt geniş — gerçek telefonun
/// neredeyse İKİ KATI. `shell_test.dart`ın 1200×3000'i (8 disiplini kaydırma-
/// sız sığdırmak için, İÇERİK denetimi amaçlı) bu riski daha da büyütüyor.
/// Bu dosya BİLEREK 375×812'ye (iPhone SE sınıfı, en dar yaygın cihaz)
/// sabitliyor: **"taşmayı en geniş ekranda test etmek, taşmayı test
/// etmemektir"** (Lissom standardı). Kalıcı regresyon kapısı, tek seferlik
/// kontrol değil.
///
/// Risk burada özellikle yüksek: 7 kapsam-dışı gerekçesi uzun paragraf,
/// disiplin blurb'leri uzun, kilit sebepleri uzun, ve düzeltme metni
/// KASITLI clamp'siz (koordinatör hükmü) — kırpma yerine akan yükseklik
/// tercih edildi, yani satır sayısı ekranı GERÇEKTEN esnetebilir.
///
/// `tester.takeException()` her adımdan sonra kontrol edilir — Flutter'ın
/// kendi hata bölgesi bir `RenderFlex overflowed` durumunda burada
/// yakalanabilir bir istisna bırakır; global `FlutterError.onError`
/// müdahalesi BİLEREK YAPILMADI (ilk denemede semantics ağacını bozup
/// `pumpAndSettle`i sonsuz döngüye soktu — düzeltme değil, yeni bir kusur).
/// KARŞILAMA ATLANIYOR (J-106). Bu dosyanın sınadığı şey karşılama DEĞİL;
/// gerçek bayrağı okumak her testi "ilk açılış" hâline sokup kabuğa hiç
/// ulaştırmazdı. `seenOverride` üretimde `null` — bu yalnız bir test dikişi.
const OnboardingStore _seen = OnboardingStore(seenOverride: true);

// Each test owns a storage namespace; replacements inside it share this registry.
late OwnerResourceRegistry _owners;

Future<void> showBoxingControl(WidgetTester t, Key key) async {
  final Finder control = find.byKey(key);
  await t.scrollUntilVisible(
    control,
    250,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 40,
  );
  await Scrollable.ensureVisible(t.element(control), alignment: 0.5);
  await t.pumpAndSettle();
  expect(control.hitTestable(), findsOneWidget);
}

void main() {
  setUp(() => _owners = OwnerResourceRegistry());
  setUp(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(375, 812);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Future<void> pumpApp(
    WidgetTester t, {
    ContentRepository? repo,
    Key? key,
  }) async {
    await t.runAsync(() async {
      await t.pumpWidget(
        JabLabApp(
          key: key,
          onboarding: _seen,
          repository: repo ?? ContentRepository(ownerRegistry: _owners),
        ),
      );
    });
    await settleAppLoad(t);
    await t.pumpAndSettle();
  }

  // 8 disiplinin HEPSİNİ genişlet — en uzun blurb'ler/gerekçeler burada
  // (kickboxing/tai_chi/karate/muay_thai/taekwondo/mma/wing_chun hepsi çok
  // satırlı "neden henüz yok" metni taşıyor). **Her disiplin TAZE bir
  // ağaçta** (`fitness_ship_audit_test.dart`ın deseni, aynı gerekçe): tek
  // ağaçta sırayla genişletmek denendi, ilk disiplinin 375pt'teki uzun
  // gövdesi listeyi o kadar uzatıyordu ki `ensureVisible` bir SONRAKİ
  // öğeyi bulamadı — bu bir test kırılganlığıydı, uygulama hatası değil,
  // ama düzeltmek yerine ailenin zaten kanıtlı desenine geçmek daha sağlam.
  //
  // Yazılı kursu açık dört disiplinin kapalı katalog kartı Sayfa A'da artık
  // listelenmez (`writtenCourseDisciplineIds`); onların giriş kartları açık
  // kurs sayfası testlerinde ölçülür. Kalan dört kart burada genişletilir.
  for (final String id in <String>[
    'boxing',
    'kickboxing',
    'tai_chi',
    'karate',
    'muay_thai',
    'taekwondo',
    'mma_striking',
    'wing_chun',
  ].where((String id) => !writtenCourseDisciplineIds.contains(id))) {
    testWidgets('Sayfa A — $id genişletilmiş, 375pt taşma yok', (
      WidgetTester t,
    ) async {
      await pumpApp(t, key: ValueKey<String>(id));
      final Finder tile = find.byKey(Key('item-$id'));
      // `ensureVisible` listenin son öğelerinde (mma_striking/wing_chun)
      // "No element" ile fırlıyordu — liste TAMAMEN eager (`ListView`,
      // `.builder` değil) yani öğe var ama tek-adımlık scroll hesabı
      // uzak hedefte güvenilir değildi. `dragUntilVisible` adım adım
      // kaydırıp HER adımda kontrol ediyor — uzak hedefte doğru araç bu.
      await t.dragUntilVisible(
        tile,
        find.byType(Scrollable).first,
        const Offset(0, -400),
      );
      await t.pumpAndSettle();
      await t.tap(tile);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Sayfa A — "Neden yok?" sayfası, 375pt taşma yok', (
    WidgetTester t,
  ) async {
    await pumpApp(t);
    // Buton 8 disiplinin ALTINDA — 375pt'te ilk viewport'ta değil.
    final Finder button = find.byKey(const Key('why-not-button'));
    await t.dragUntilVisible(
      button,
      find.byType(Scrollable).first,
      const Offset(0, -400),
    );
    await t.pumpAndSettle();
    await t.tap(button);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('Sayfa B — kilitli/uzun ders listeleri, 375pt taşma yok', (
    WidgetTester t,
  ) async {
    await pumpApp(t);
    await showBoxingControl(t, const Key('item-boxing'));
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    // intermediate: en uzun kilit-sebebi metinleri burada. `boxing`
    // genişleyince liste 375pt'te uzun olduğu için `ensureVisible` şart —
    // aksi hâlde tap noktası kök render ağacının dışına düşebiliyor.
    final Finder course = find.byKey(const Key('course-boxing.intermediate'));
    await t.ensureVisible(course);
    await t.pumpAndSettle();
    await t.tap(course);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Sayfa B — GÜNCEL kurs (kaldığın yer + K8 bant), 375pt taşma yok',
    (WidgetTester t) async {
      final _FakeStore store = _FakeStore(<SessionRecord>[
        SessionRecord(
          lessonId: 'boxing.foundations.jab',
          completedAt: DateTime.utc(2026, 8, 1),
          workedSeconds: 300,
          unitsCompleted: 2,
          plannedUnits: 3,
          unitLabel: 'round',
          lessonClass: 'unscored',
        ),
      ]);
      await pumpApp(
        t,
        repo: ContentRepository(storeOverride: store, ownerRegistry: _owners),
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Ayarlar köşesi, 375pt taşma yok', (WidgetTester t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('settings-button')));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Ders ekranı — öğret→dene→CANLI(iskelet+yer tutucu)→özet, 375pt taşma yok',
    (WidgetTester t) async {
      // `boxing.foundations.jab` BİLEREK: kamera KULLANAN gerçek bir ders —
      // `jablabSessionTheme`/`SkeletonPreview`in giydirdiği tam da bu yol
      // (design turu Parça 2, 2026-08-06). Fitness-track dersleri (diğer
      // testlerin kullandığı) kamerasız, bu yolu hiç ÇALIŞTIRMAZ.
      await pumpApp(t);
      await t.dragUntilVisible(
        find.byKey(const Key('item-boxing')),
        find.byType(Scrollable).first,
        const Offset(0, -400),
      );
      await t.pumpAndSettle();
      await showBoxingControl(t, const Key('item-boxing'));
      await t.tap(find.byKey(const Key('item-boxing')));
      await t.pumpAndSettle();
      await t.dragUntilVisible(
        find.byKey(const Key('course-boxing.foundations')),
        find.byType(Scrollable).first,
        const Offset(0, -400),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('course-boxing.foundations')));
      await t.pumpAndSettle();
      await showBoxingControl(t, const Key('lesson-boxing.foundations.jab'));
      await t.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'öğret aşaması');

      final Finder advance = find.byKey(const Key('advance-button'));
      await t.tap(advance); // öğret → dene
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'dene aşaması');

      await t.tap(advance); // dene → CANLI (yıldız ekran)
      // Kamera izni isteği + `LiveJabController.start()` asenkron —
      // `runAsync` gerçek zamanlayıcıların akmasına izin veriyor
      // (`fitness_ship_audit_test.dart`ın kendi deseniyle aynı gerekçe).
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await t.pumpAndSettle();
      expect(
        t.takeException(),
        isNull,
        reason: 'CANLI aşama (iskelet + yer tutucu)',
      );
      // Yalnız "çökmedi" değil: `SkeletonPreview` GERÇEKTEN kullanıldığını
      // doğruluyor — `preview:` yuvası boş kalıp eski jenerik ikona sessizce
      // düşseydi (bir bağlama hatası) bu bulunamazdı, `takeException()` yine
      // de `isNull` olurdu (ÖLÇÜLDÜ: flutter test'te gerçek kamera platform
      // kanalı yok, bu yüzden bu koşuda hep yer-tutucu dalı render ediliyor).
      expect(
        find.byKey(const Key('camera-preview-placeholder')),
        findsOneWidget,
      );

      await t.tap(advance); // CANLI → özet
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'özet aşaması');
    },
  );
}

class _FakeStore implements SessionStore {
  _FakeStore(this._all);
  final List<SessionRecord> _all;

  @override
  Future<void> append(SessionRecord record) async => _all.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => _all;

  @override
  Future<int> unreadableRecords() async => 0;

  @override
  Future<int> workedSecondsFor(String lessonId) async {
    int t = 0;
    for (final SessionRecord r in _all) {
      if (r.lessonId == lessonId) t += r.workedSeconds;
    }
    return t;
  }
}
