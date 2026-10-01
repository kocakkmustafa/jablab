import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_page.dart';
import 'package:jablab/app/settings_page.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/shell_candidate/shell_models.dart';

import 'app_pump.dart';

/// KARŞILAMA (J-106) — yayın blokajının kapanışı.
///
/// Sınanan şey "ekran çiziliyor mu" değil, **doğru şeyin doğru sırada
/// söylendiği**: dürüstlük ön-beyanı kabuktan ÖNCE geliyor mu, kapsam-dışı
/// sayısı VERİDEN mi türüyor, izin reddi çıkmaz sokak olarak mı sunuluyor,
/// ve vaat dili sızmış mı.
void main() {
  _settingsCountGate();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('jablab_onboarding');
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    // 375×812 — aile kapısı (ortak çekirdek ders #3). `flutter_test`in
    // varsayılan ~800pt yüzeyi gerçek telefonun iki katı ve bu ekranın
    // metni uzun; varsayılanda ölçmek taşmayı GÖRMEZDİ.
    b.platformDispatcher.views.first.physicalSize = const Size(375, 812);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  OnboardingStore store({bool seen = false}) {
    final File f = File('${tmp.path}/${OnboardingStore.fileName}');
    if (seen) f.writeAsStringSync('1');
    return OnboardingStore(fileOverride: f);
  }

  Future<ShellLibrary> loadLibrary(WidgetTester t) async {
    late ShellLibrary lib;
    await t.runAsync(() async {
      const ContentRepository repo = ContentRepository();
      lib = repo.toShell((await repo.load()).library);
    });
    return lib;
  }

  Future<void> pumpOnboarding(WidgetTester t,
      {VoidCallback? onDone, VoidCallback? onWhyNot}) async {
    final ShellLibrary lib = await loadLibrary(t);
    await t.pumpWidget(MaterialApp(
      home: OnboardingPage(
        library: lib,
        onDone: onDone ?? () {},
        onOpenWhyNot: onWhyNot ?? () {},
      ),
    ));
    await t.pumpAndSettle();
  }

  /// ⚠️ `pumpAndSettle` KULLANILMIYOR (uygulama kökünde). `_RootState` içerik
  /// ve bayrak gelene kadar `CircularProgressIndicator` çiziyor; o animasyon
  /// SONSUZ, yani `pumpAndSettle` asla yerleşmez ve test 10 dakikalık zaman
  /// aşımına düşer. Bekleyen iş `runAsync` ile gerçek zamanda bitiriliyor,
  /// sonra elle iki kare çevriliyor.
  /// `shell_test`in kanıtlanmış reçetesi: `pumpWidget` `runAsync` İÇİNDE +
  /// gerçek gecikme. Asset yüklemesi GERÇEK I/O ve widget testinin sanal
  /// saati onu ilerletmez; dışarıda pump'lamak içeriği hiç getirmez ve
  /// yükleme göstergesi (sonsuz animasyon) ekranda kalır.
  Future<void> pumpApp(WidgetTester t, OnboardingStore s) async {
    await t.runAsync(() async {
      await t.pumpWidget(JabLabApp(onboarding: s));
    });
    await settleAppLoad(t);
    await t.pumpAndSettle();
  }

  /// ⚠️ SINIRLI pump — `pumpAndSettle` DEĞİL. Son adım kabuğa geçiyor ve
  /// kabuk (içerik/geçmiş yüklenirken) sonsuz animasyonlu bir gösterge
  /// çizebiliyor; `pumpAndSettle` orada asla yerleşmez ve test 10 dakikalık
  /// zaman aşımına düşer. Perde geçişi için iki kare yeter.
  Future<void> advance(WidgetTester t) async {
    await t.tap(find.byKey(const Key('onboarding-next')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  for (final language in ['en', 'tr']) {
    testWidgets('current course and closed camera intro in $language', (tester) async {
      tester.platformDispatcher.localeTestValue = Locale(language);
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await pumpOnboarding(tester);
      expect(find.textContaining(language == 'tr' ? 'veya kamera gerekmez' : 'No bag, gloves, account or camera is needed'), findsOneWidget);
      expect(find.textContaining(language == 'tr' ? 'canlı kamera seansları ve abonelik satışı kapalıdır' : 'Live camera sessions and subscription sales are closed'), findsOneWidget);
      expect(find.textContaining('Video is read as you move'), findsNothing);
      await advance(tester);
      expect(find.textContaining(language == 'tr' ? 'ustalığı otomatik puanlamaz' : 'automatically grade punch technique'), findsOneWidget);
      await advance(tester);
      expect(find.textContaining(language == 'tr' ? 'kamera izni olmadan çalışır' : 'works without camera permission'), findsOneWidget);
      expect(find.textContaining('form feedback needs'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  group('sıra ve kapı', () {
    testWidgets('İLK AÇILIŞ: karşılama kabuktan ÖNCE gelir',
        (WidgetTester t) async {
      await pumpApp(t, store());
      expect(find.byType(OnboardingPage), findsOneWidget,
          reason: 'dürüstlük ön-beyanı atlandı — kullanıcı ürünün ne '
              'yapmadığını hiç görmeden içeri girdi');
    });

    testWidgets('DÖNEN KULLANICI: karşılama bir daha ÇIKMAZ',
        (WidgetTester t) async {
      await pumpApp(t, store(seen: true));
      expect(find.byType(OnboardingPage), findsNothing,
          reason: 'her açılışta karşılama göstermek, okunan bir metni '
              'atlanan bir engele çevirir');
    });

    testWidgets('bayrak OKUNANA KADAR kabuk da karşılama da çizilmiyor',
        (WidgetTester t) async {
      // "Bilmiyorum" ile "hayır" ayrımı: `false` başlatmak bir karelik
      // pencerede kabuğu gösterip üstüne karşılamayı açardı.
      final OnboardingStore s = store();
      await t.pumpWidget(JabLabApp(onboarding: s));
      await t.pump();
      expect(find.byType(OnboardingPage), findsNothing);
      // ⚠️ Burada `settleAppLoad` DEĞİL `settleUntil` — bu test yükleme
      // penceresinin KENDİSİNİ sınıyor, ve "gösterge kalktı" ölçütü onun
      // için fazla erken olabilir. Beklenen şey hedefin GÖRÜNMESİ.
      await settleUntil(t, find.byType(OnboardingPage));
      await t.pumpAndSettle();
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('SON adımda "Start" bayrağı yazıyor ve kabuğa geçiyor',
        (WidgetTester t) async {
      final OnboardingStore s = store();
      await pumpApp(t, s);
      for (int i = 0; i < 3; i++) {
        await advance(t);
      }
      expect(find.byType(OnboardingPage), findsNothing,
          reason: '"Start" kullanıcıyı hiçbir yere götürmedi');
      // Bekleme YOK ve bu bir kısayol değil: `markSeen()` senkron yazıyor
      // (bkz. `OnboardingStore.markSeen` dokümanı), yani "Start"a basıldığı
      // anda bayrak diskte. Burada bir gecikmeye ihtiyaç duyulması, üründe
      // bir yarış penceresi olduğunun işareti olurdu.
      expect(File('${tmp.path}/${OnboardingStore.fileName}').existsSync(),
          isTrue,
          reason: 'bayrak yazılmadı — karşılama her açılışta geri gelir');
    });
  });

  group('içerik dürüstlüğü', () {
    testWidgets('KAPSAM-DIŞI SAYISI veriden TÜREVİ, elle yazılmamış',
        (WidgetTester t) async {
      // Elle yazılmış bir sayı, liste büyüdüğü gün sessizce yalan olurdu.
      final ShellLibrary lib = await loadLibrary(t);
      await pumpOnboarding(t);
      await advance(t);

      final String line = t
          .widget<Text>(find.byKey(const Key('onboarding-excluded-count')))
          .data!;
      expect(line, contains('${lib.exclusions.length}'),
          reason: 'karşılamadaki sayı içerikteki listeyle uyuşmuyor — '
              'biri elle yazılmış ve bayatlamış');
      expect(lib.exclusions.length, greaterThan(1),
          reason: 'liste boşaldıysa bu ekranın metni de yeniden '
              'düşünülmeli (tekil/çoğul dalı test edilmemiş olur)');
    });

    testWidgets('İZİN REDDİ ÇIKMAZ SOKAK DEĞİL — ne çalıştığı söyleniyor',
        (WidgetTester t) async {
      // UI-BRIEF §3.1'in açık şartı. Kamerasız ders bugün GERÇEKTEN
      // çalışıyor (`SessionScreen.liveJab` null olabiliyor), yani bu bir
      // vaat değil beyan.
      await pumpOnboarding(t);
      await advance(t);
      await advance(t);
      final String note = t
          .widget<Text>(find.byKey(const Key('onboarding-permission-note')))
          .data!;
      expect(note.toLowerCase(), contains('works without camera permission'),
          reason: 'izni reddeden kullanıcıya elinde ne KALDIĞI '
              'söylenmiyor — ekran çıkmaz sokak');
    });

    testWidgets('TAM LİSTEYE giden yol var — karşılama listeyi TAŞIMIYOR',
        (WidgetTester t) async {
      bool opened = false;
      await pumpOnboarding(t, onWhyNot: () => opened = true);
      await advance(t);
      await t.tap(find.byKey(const Key('onboarding-why-not')));
      await t.pumpAndSettle();
      expect(opened, isTrue,
          reason: '"See the list" hiçbir yere gitmiyor — açıklamasız bir '
              'kısıt "sistem bozuk" diye okunur');
    });

    testWidgets('VAAT DİLİ YOK — üç perdenin HİÇBİRİNDE (M-F-186)',
        (WidgetTester t) async {
      // "yakında/şimdilik/yet" bir özelliğin GELECEĞİNİ iddia eder ve o
      // iddiayı tutan hiçbir şey yok. "Neden yok" dürüstlük, "yakında
      // gelecek" vaattir.
      final RegExp promise = RegExp(
          r'\b(yet|soon|coming soon|for now|currently not|will be able)\b',
          caseSensitive: false);
      await pumpOnboarding(t);
      for (int step = 0; step < 3; step++) {
        for (final Text w in t.widgetList<Text>(find.byType(Text))) {
          final String? s = w.data;
          if (s == null) continue;
          expect(promise.hasMatch(s), isFalse,
              reason: 'perde $step vaat dili taşıyor: "$s"');
        }
        if (step < 2) await advance(t);
      }
    });

    testWidgets('SAYISAL SKOR YOK — K8 karşılamada da geçerli',
        (WidgetTester t) async {
      // İlerleme noktaları bilerek nokta; "2/3" bir ölçüm gibi okunur ve
      // bu ürün sayıları ölçüme saklıyor.
      await pumpOnboarding(t);
      for (int step = 0; step < 3; step++) {
        expect(find.text('${step + 1}/3'), findsNothing);
        if (step < 2) await advance(t);
      }
    });
  });

  group('375pt taşma kapısı', () {
    testWidgets('üç perde de en dar cihazda TAŞMIYOR', (WidgetTester t) async {
      await pumpOnboarding(t);
      for (int step = 0; step < 3; step++) {
        expect(t.takeException(), isNull,
            reason: 'perde $step 375×812de taşıyor');
        if (step < 2) await advance(t);
      }
    });
  });
}

/// AYARLAR KÖŞESİ — sayı TÜREVİ, elle yazılmıyor (J-151).
///
/// J-107 aynı kusuru **karşılama ekranında** bulup türeterek çözmüştü.
/// **Ayarlar köşesi o turda taranmadı** ve orada elle yazılmış sayı
/// bayatlamıştı: ekran *"Seven things left out on purpose"* diyordu, gerçek
/// sayı **12**. Kapsamın katman değil **yüzey** bazında dolaşılması
/// gerektiğinin bir örneği daha (J-145 ailesi).
///
/// ⚠️ NE ÖLÇMÜYOR: sayının DOĞRU yerden geldiğini — yalnız ekrandaki
/// değerin `library.exclusions` uzunluğuyla aynı olduğunu.
void _settingsCountGate() {
  testWidgets('ayarlarda kapsam-dışı sayısı TÜREVİ (J-151)',
      (WidgetTester t) async {
    late final int expected;
    late final dynamic lib;
    await t.runAsync(() async {
      const ContentRepository repo = ContentRepository();
      lib = repo.toShell((await repo.load()).library);
      expected = (lib.exclusions as List<dynamic>).length;
    });
    expect(expected, greaterThan(1),
        reason: 'kapsam-dışı listesi boş — kapı vakum-doğru olurdu');

    await t.pumpWidget(MaterialApp(
      home: SettingsPage(onOpenWhyNot: () {}, excludedCount: expected),
    ));
    await t.pumpAndSettle();

    expect(find.textContaining('$expected things left out'), findsOneWidget,
        reason: 'ayarlardaki sayı içerikle uyuşmuyor — elle yazılmış bir '
            'sayı bayatlar ve bu tam olarak J-151de olan şeydi');
    // NEGATİF İKİZ: eski bayat sayı geri gelirse öter.
    expect(find.textContaining('Seven things'), findsNothing,
        reason: 'elle yazılmış sayı geri kondu');
  });
}
