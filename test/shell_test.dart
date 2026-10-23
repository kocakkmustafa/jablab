import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/settings_page.dart';

import 'app_pump.dart';

/// G5 iskelet testleri — 2026-08-06 yeniden yapılandırma (design turu,
/// koordinatör Hüküm 1/2/3).
///
/// Bu testlerin amacı "widget çiziliyor mu" değil — **dürüstlük kurallarının
/// UI'da da tutulduğunu** kanıtlamak. Kurallar config'de ve motorda zaten
/// zorlanıyor; ilk ekran tasarımında delinen tam olarak bu tür sözlerdir.
///
/// ## Bu dosyadaki değişim (sayarak — koordinatörün istediği gibi)
/// Eski 4-sekme kabuk (`tab-home/library/progress/profile`) yerini 3 sayfa +
/// köşeye bıraktı: Sayfa A (`SelectPage`, disiplin+kurs seçimi tek sayfada),
/// Sayfa B (`CoursePage`, kurs varsa GİRİŞ ekranı da budur), Ayarlar köşesi.
/// **9 eski test SİLİNMEDİ** — her biri aynı iddiayı yeni navigasyon
/// yolundan yeniden kuruyor. **3 yeni test EKLENDİ** (Hüküm 3 iki yönlü +
/// "devam et" hedefinin GERÇEKTEN doğru derse gittiğinin ölçümü — bu son
/// tur öncesinde VARSAYILMIŞTI, şimdi ölçülüyor).
/// KARŞILAMA ATLANIYOR (J-106). Bu dosyanın sınadığı şey karşılama DEĞİL;
/// gerçek bayrağı okumak her testi "ilk açılış" hâline sokup kabuğa hiç
/// ulaştırmazdı. `seenOverride` üretimde `null` — bu yalnız bir test dikişi.
const OnboardingStore _seen = OnboardingStore(seenOverride: true);

// Each test owns a storage namespace; replacements inside it share this registry.
late OwnerResourceRegistry _owners;

void main() {
  setUp(() => _owners = OwnerResourceRegistry());
  setUp(() {
    // Varsayılan test yüzeyi (800×600) 8 disiplini ve uzun ders listelerini
    // kadraja sığdırmıyor; kaydırma jimnastiği yerine yüzeyi büyütüyoruz.
    // Bu bir "testi geçirme" hilesi değil: sınadığımız şey yerleşim değil,
    // içerik kurallarının tutup tutmadığı.
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

  Future<void> pumpApp(
    WidgetTester tester, {
    ContentRepository? repo,
    Future<bool> Function(BuildContext)? beforeLessonStart,
    bool cameraLessonsAvailable = true,
  }) async {
    // Asset yükleme GERÇEK async I/O'dur; widget test'inin sanal saati onu
    // ilerletmez. runAsync olmadan içerik hiç gelmez, yükleme göstergesi
    // ekranda kalır ve pumpAndSettle (sonsuz animasyon yüzünden) zaman aşımına
    // uğrar — sabit bir gecikmeyle "çözmek" yarış durumu üretirdi.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        JabLabApp(
          repository: repo ?? ContentRepository(ownerRegistry: _owners),
          onboarding: _seen,
          beforeLessonStart: beforeLessonStart,
          cameraLessonsAvailable: cameraLessonsAvailable,
        ),
      );
    });
    await settleAppLoad(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('a denied membership never opens a boxing session', (
    WidgetTester t,
  ) async {
    var checks = 0;
    await pumpApp(
      t,
      beforeLessonStart: (_) async {
        checks++;
        return false;
      },
    );
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
    await t.pumpAndSettle();
    expect(checks, 1);
    expect(find.byType(SessionScreen), findsNothing);
  });

  /// Varsayılan (`storeOverride` yok) test ortamında `path_provider` gerçek
  /// bir platforma bağlanamaz ve `openStore()` fırlatır → `_lastLessonId`
  /// hiç kurulmaz → `_currentCourse` her zaman `null` → giriş HER ZAMAN
  /// Sayfa A'dır. Bu, Hüküm-3'ün "kurs yoksa Sayfa A" dalını bedavaya test
  /// ediyor; kurs-varken dalı için aşağıdaki `pumpAppWithCurrentCourse`
  /// GEREKİYOR.
  testWidgets('içerik dürüstlük denetiminden geçerek yüklenir', (
    WidgetTester t,
  ) async {
    await pumpApp(t);
    // ContentRepository, library.validate() başarısız olursa fırlatır.
    expect(find.byKey(const Key('content-error')), findsNothing);
    expect(
      find.byType(SelectPage),
      findsOneWidget,
      reason: 'kurs geçmişi yok/okunamıyor → giriş Sayfa A olmalı',
    );
    expect(find.byKey(const Key('item-boxing')), findsOneWidget);
  });

  testWidgets('kütüphane 8 disiplini de gösterir — kapsam baştan görünür', (
    WidgetTester t,
  ) async {
    await pumpApp(t);
    // Sayfa A zaten giriş yüzeyi — ayrı bir sekmeye geçmeye gerek yok.
    for (final String id in <String>[
      'boxing',
      'taekwondo',
      'mma_striking',
      'wing_chun',
    ]) {
      expect(find.byKey(Key('item-$id')), findsOneWidget, reason: id);
    }
    // Yazılı kursu AÇIK dört disiplinin kapalı katalog kartı listelenmez;
    // kapsam o disiplinlerin açık kurs giriş kartıyla görünür (2026-10-21:
    // "açık değil, ders yok" notu açık kursun yanında çelişkiydi).
    expect(writtenCourseDisciplineIds, <String>{
      'kickboxing',
      'tai_chi',
      'karate',
      'muay_thai',
    });
    for (final String id in writtenCourseDisciplineIds) {
      expect(find.byKey(Key('item-$id')), findsNothing, reason: id);
      expect(find.byKey(Key('soon-$id')), findsNothing, reason: id);
    }
    expect(find.byKey(const Key('open-kickboxing-course')), findsOneWidget);
    // Kapalı kalanlarda "yakında" rozeti, Boxing'de yok.
    expect(find.byKey(const Key('soon-boxing')), findsNothing);
    expect(find.byKey(const Key('soon-taekwondo')), findsOneWidget);
  });

  testWidgets('"yakında" disiplinde KURS GÖSTERİLMEZ', (WidgetTester t) async {
    await pumpApp(t);
    // Eskiden ayrı bir sayfaya PUSH ediyordu (ItemPage); şimdi Sayfa A'nın
    // kendi içinde satır-içi genişliyor — "az sayfa" kurucu direktifi.
    await t.tap(find.byKey(const Key('item-taekwondo')));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('coming-soon-note')), findsOneWidget);
    expect(
      find.text('Courses'),
      findsNothing,
      reason: 'açılmamış disiplinde kurs başlığı bile görünmemeli',
    );

    // KURAL KOŞULLU OLDU (J-137, koordinatör hükmü 08:47).
    //
    // Bu satır önce *"Dürüstlük kutusu yine de zorunlu"* diyordu ve karar
    // AÇIK disiplinler için doğru, kapalılar için yanlıştı. Gerçek render
    // ölçtü: kapalı kartta kullanıcı aynı olguyu DÖRT kez görüyordu ve
    // kutunun iki tarafı da ölçüm cümlesi değildi — **kapalı olmak bir
    // ölçüm sınırı değildir.**
    //
    // Test SİLİNMEDİ, koşullu oldu: kural, hükmü veren DURUMA bağlı.
    expect(
      find.text("What it doesn't"),
      findsNothing,
      reason:
          'kapalı disiplinde ölçüm kabı çiziliyor — ölçüm yokken '
          '"neyi ölçmez" başlığı, durumu ölçüm sınırı gibi sunar',
    );
  });

  testWidgets('POZİTİF İKİZ — AÇIK disiplinde dürüstlük kutusu VAR', (
    WidgetTester t,
  ) async {
    // M-F-337: kapı iki yönlü olmalı. Yalnız *"kapalıda kutu yok"* ölçülseydi,
    // kutunun HER YERDEN silinmesi de kapıyı geçerdi — kapı bir iddiayı
    // değil **bir sessizliği** korurdu. Kutu açık disiplinde zorunludur ve
    // J-137 o kararı DEĞİŞTİRMEDİ, yalnız kapsamını daralttı.
    await pumpApp(t);
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    expect(
      find.text("What it doesn't"),
      findsOneWidget,
      reason:
          'AÇIK disiplinde dürüstlük kutusu kayboldu — J-137 kapalı '
          'disiplini kapsam dışı bıraktı, kutuyu kaldırmadı',
    );
  });

  testWidgets('camera closed: camera lessons are locked with their reason', (
    WidgetTester t,
  ) async {
    // Production keeps camera coaching on its own closed switch, separate
    // from the shared sales switch that now gates course access.
    final String main = File('lib/main.dart').readAsStringSync();
    expect(
      main,
      contains('cameraLessonsAvailable: jablabCameraCoachingAvailable'),
    );
    expect(main, contains('const bool jablabCameraCoachingAvailable = false;'));
    var gateCalls = 0;
    await pumpApp(
      t,
      cameraLessonsAvailable: false,
      beforeLessonStart: (_) async {
        gateCalls++;
        return false;
      },
    );
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    expect(find.byType(CoursePage), findsOneWidget);

    final Finder row = find.byKey(const Key('lesson-boxing.foundations.jab'));
    expect(row, findsOneWidget);
    expect(
      t.widget<InkWell>(row).onTap,
      isNull,
      reason: 'a camera lesson must not offer a play action while closed',
    );
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining(
          'Live camera lessons are unavailable in this release.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.lock_outline)),
      findsOneWidget,
    );
    await t.tap(row, warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.byType(SessionScreen), findsNothing);
    expect(gateCalls, 0);
  });

  testWidgets('canlı disiplinde kurs → ders → seans zinciri yürür', (
    WidgetTester t,
  ) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();

    expect(find.text('Courses'), findsOneWidget);
    expect(find.byKey(const Key('course-boxing.foundations')), findsOneWidget);

    // Kurs seçimi HÂLÂ push — Sayfa B ayrı bir ekran (design §2 Sayfa B).
    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    expect(find.byType(CoursePage), findsOneWidget);
    expect(
      find.byKey(const Key('lesson-boxing.foundations.jab')),
      findsOneWidget,
    );

    await t.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
    await t.pumpAndSettle();
    // Ders akışı öğret→dene→canlı→özet sırasıyla açılır.
    expect(find.byKey(const Key('stage-teach')), findsOneWidget);
    expect(
      find.byKey(const Key('teach-no-analysis')),
      findsOneWidget,
      reason: 'öğrenme aşamasında analiz YAPILMADIĞI söylenmeli',
    );
  });

  testWidgets('seans akışı: öğret → dene → canlı → özet', (
    WidgetTester t,
  ) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('advance-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('rehearse-copy')), findsOneWidget);

    await t.tap(find.byKey(const Key('advance-button')));
    await t.pumpAndSettle();
    // Kamera bağlı değil → yüzey "göremiyorum" durumunda ve SEBEBİ yazılı.
    // Sessiz kalmak "her şey yolunda" derdi; oysa analiz hiç çalışmıyor.
    expect(find.byKey(const Key('live-no-verdict')), findsOneWidget);
    expect(find.byKey(const Key('live-cue')), findsNothing);

    await t.tap(find.byKey(const Key('advance-button')));
    await t.pumpAndSettle();
    // Özet: skorlanmayan başlıklar kullanıcıya AÇIKÇA söyleniyor (J-033).
    // Liste config'in stanceCoachedOnlyJoints'inden TÜRETİLİR (elle
    // kopyalanmaz) — bkz. ContentRepository.coachedNotScoredLabels.
    expect(find.byKey(const Key('coached-not-scored-note')), findsOneWidget);
    expect(find.textContaining('Rear guard hand position'), findsOneWidget);
    expect(find.textContaining('Rear elbow angle'), findsOneWidget);
    // Regresyon: lead_hip/lead_thigh scoredJoints'te — "Lead hip and thigh
    // placement" eski hardcoded metindi ve config'in aktif kararıyla
    // ÇELİŞİYORDU (coachedOnlyJoints'te rear_hip/rear_thigh var, lead değil).
    expect(find.textContaining('Rear hip position'), findsOneWidget);
    expect(find.textContaining('Lead hip and thigh placement'), findsNothing);
  });

  testWidgets('[J-038] KİLİTLİ ders görünür ama AÇILMAZ, sebebi yazılı', (
    WidgetTester t,
  ) async {
    // Kilitli dersi gizlemek kapsamı saklardı; açmak ölçemediğimiz bir
    // beceriye seans vermek olurdu. Üçüncü yol: göster, açma, sebebini yaz.
    await pumpApp(t);
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.intermediate')));
    await t.pumpAndSettle();

    const String locked = 'boxing.intermediate.counter';
    expect(
      find.byKey(const Key('lesson-$locked')),
      findsOneWidget,
      reason: 'kilitli ders listeden gizlenmiş — kapsam saklanıyor',
    );
    expect(
      find.byKey(const Key('locked-why-$locked')),
      findsOneWidget,
      reason: 'kilit sebepsiz — "yakında" rozetine dönüşmüş',
    );

    await t.tap(find.byKey(const Key('lesson-$locked')));
    await t.pumpAndSettle();
    expect(
      find.byKey(const Key('stage-teach')),
      findsNothing,
      reason: 'kilitli ders seans açtı — ölçemediğimiz beceriye hüküm yolu',
    );
  });

  testWidgets('"Neden yok?" sayfası gerekçeleriyle açılır', (
    WidgetTester t,
  ) async {
    await pumpApp(t);
    // Eskiden Library sekmesindeydi; şimdi Sayfa A zaten giriş yüzeyi.
    await t.tap(find.byKey(const Key('why-not-button')));
    await t.pumpAndSettle();

    expect(find.text('Brazilian Jiu-Jitsu'), findsOneWidget);
    expect(find.text('Punch power'), findsOneWidget);
    expect(
      find.textContaining('Punch force is not measured here'),
      findsWidgets,
      reason: 'güç ölçümünün neden yapılamadığı açıkça yazılmalı',
    );
  });

  testWidgets('satış kapalıyken eski fiyat iskeleti görünmüyor', (
    WidgetTester t,
  ) async {
    await pumpApp(t);
    // Eskiden Profile sekmesindeydi; şimdi köşe ikonundan açılan Ayarlar.
    await t.tap(find.byKey(const Key('settings-button')));
    await t.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byKey(const Key('pricing-not-set')), findsNothing);
    expect(find.textContaining('Pricing is not set yet.'), findsNothing);
  });

  /// Sabit bir kayıtla `_currentCourse`u çözülebilir kılan yardımcı — Hüküm
  /// 3'ün "kurs varken" dalını ve Hüküm 2'nin taşınan bant bloğunu ölçen
  /// testlerin ortak kurulumu.
  Future<void> pumpAppWithCurrentCourse(
    WidgetTester t, {
    String lessonId = 'boxing.foundations.jab',
  }) async {
    final _FakeStore store = _FakeStore(<SessionRecord>[
      SessionRecord(
        lessonId: lessonId,
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
  }

  testWidgets('K8: kurs sayfası SAYI göstermez, bant gösterir', (
    WidgetTester t,
  ) async {
    // Eskiden ayrı bir Progress sekmesindeydi (her zaman erişilebilir); bu
    // bant Hüküm 2 ile Sayfa B'ye TAŞINDI — düşmedi. Bloğu görebilmek için
    // "güncel kurs" gerekiyor, bu yüzden diğerlerinden farklı olarak
    // `pumpAppWithCurrentCourse` kullanıyor.
    await pumpAppWithCurrentCourse(t);
    expect(find.byKey(const Key('bands-only-note')), findsOneWidget);

    // ⚖️ J-144 (koordinatör hükmü 09:24) — BU TEST KUSURU KODLUYORDU.
    //
    // Önce `band-Guard discipline` BEKLİYORDU. Ama guard **puanlanmıyor**:
    // Sayfa A'nın dürüstlük kutusu *"detected and coached, but NOT graded.
    // Coaches disagree"* diyor ve gerekçe ölçülmüş (`rear_forearm` dağılımı
    // 45° tavana kırpılı). Bant başlığı ise *"until the thresholds are
    // calibrated"* — yani guard için **karşılıksız bir vaat**, çünkü o
    // bileşen kalibrasyonla değil **eğitmen uzlaşmazlığıyla** kapalı.
    //
    // KAPI İKİ YÖNLÜ (M-F-337): yalnız *"puanlanmayan yok"* ölçülseydi,
    // bant listesinin tamamen boşalması da geçerli sayılırdı.
    expect(
      find.byKey(const Key('band-Guard discipline')),
      findsNothing,
      reason:
          'puanlanmayan bir bileşen "kalibrasyon gelene kadar bant" '
          'başlığı altında — karşılıksız vaat (J-144)',
    );
    expect(
      find.byKey(const Key('band-Stance')),
      findsOneWidget,
      reason:
          'puanlanan bileşen bant listesinden kayboldu — J-144 '
          'guard\'ı çıkardı, listeyi boşaltmadı',
    );
    expect(find.byKey(const Key('band-Balance')), findsOneWidget);
    // Kalibrasyon kapısı geçilmeden hiçbir sayısal skor render edilmemeli.
    final Iterable<Text> texts = t.widgetList<Text>(find.byType(Text));
    for (final Text w in texts) {
      final String s = w.data ?? '';
      expect(
        RegExp(r'^\d{1,3}%?$').hasMatch(s.trim()),
        isFalse,
        reason: 'kalibrasyonsuz sayısal skor sızdı: "$s"',
      );
    }
  });

  group(
    '🆕 Hüküm 3 (koordinatör 2026-08-06) — landing kurs varlığına göre',
    () {
      testWidgets(
        'kayıt YOKKEN giriş Sayfa A — "az sonra" değil, tasarlanmış hâl',
        (WidgetTester t) async {
          await pumpApp(t);
          expect(find.byType(SelectPage), findsOneWidget);
          expect(find.byType(CoursePage), findsNothing);
        },
      );

      testWidgets('kayıt VARKEN giriş DOĞRUDAN o kursun Sayfa B\'sidir', (
        WidgetTester t,
      ) async {
        await pumpAppWithCurrentCourse(t);
        expect(find.byType(CoursePage), findsOneWidget);
        expect(
          find.byType(SelectPage),
          findsNothing,
          reason: 'boş bir seçim ekranı göstermek yerine doğrudan kursa iner',
        );
        expect(find.text('Foundations'), findsOneWidget);
      });

      testWidgets(
        '⚠️ "devam et" GERÇEK son dersi hedefler — Today\'in eski kısayolu '
        'yanlış derse gidiyordu, bu turda kendiliğinden düzeldiği '
        'VARSAYILMADI, ölçüldü',
        (WidgetTester t) async {
          // `boxing.foundations`'ın İLK dersi `camera` (kurulum dersi), jab
          // ÜÇÜNCÜ ders. Eski `_TodayPage` `courses.first.lessons.first`
          // kısayoluyla HER ZAMAN camera dersine giderdi — kaydedilen dersle
          // İLGİSİZ. Bu test bilerek jab'ı (ilk ders DEĞİL) kaydediyor.
          await pumpAppWithCurrentCourse(t, lessonId: 'boxing.foundations.jab');
          expect(find.byKey(const Key('resume-lesson')), findsOneWidget);
          await t.tap(find.byKey(const Key('resume-lesson')));
          await t.pumpAndSettle();
          // Ders başlığı hem SessionFlowScaffold'da hem _Teach gövdesinde
          // görünür (iki ayrı Text) — o yüzden findsWidgets. Asıl kanıt NEGATİF
          // ikiz: yanlış hedef "Camera and space" HİÇ görünmemeli.
          expect(
            find.text('The jab'),
            findsWidgets,
            reason:
                'devam et kaydedilen DERSE gitmeli, kursun ilk dersine değil',
          );
          expect(
            find.text('Camera and space'),
            findsNothing,
            reason:
                'eski Today kısayolunun hedefi (courses.first.lessons.first) '
                'sızdıysa burada görünürdü',
          );
          expect(find.byKey(const Key('stage-teach')), findsOneWidget);
        },
      );
    },
  );
}

/// Bellekte tutan basit depo — yalnız "güncel kurs" ölçüm testleri için.
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
