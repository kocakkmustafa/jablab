import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/shell_candidate/live_surface.dart';

import 'app_pump.dart';

/// ÖZET — TUR/SÜRE (J-259) VE BANT AÇIKLAMASI (J-251).
///
/// ## Ölçülen kusur (ikisi de D18 ile açılan aynı ekranda)
///
/// `_SessionScreenState` `_roundsCompleted`/`_workedSeconds`i zaten
/// izliyor VE diske yazıyordu (`SessionRecord`) — ama `_Summary`e hiç
/// GEÇMİYORDU. 4 turu 12 dakikada bitiren kullanıcı yaptığı iş hakkında
/// **tek kelime görmüyordu.** Aynı ekranda bantlar hep "—" basıyordu,
/// hiçbir açıklama yoktu — oysa hemen altındaki "Coached but not scored"
/// bölümünün gerekçesi VARDI (`H-24` dürüstlük asimetrisi).
///
/// ## ⚠️ M-F-25 terfi kapısı — `unitsCompleted`+`unitLabel`, `roundsCompleted` DEĞİL
///
/// İlk sürüm `SessionSummaryView`e `roundsCompleted:int` ekledi ve
/// tekil/çoğulu KABUKTA hesapladı — `test/shell_promotion_test.dart`
/// "terfi şartı #1" düştü ("round" alan sözlüğünde). Orkestratör kararı:
/// kabuk `unitsCompleted:int` + `unitLabel:String` alır, ikisi de app'ten
/// TAM ÇÖZÜLMÜŞ gelir (kelime VE tekil/çoğul — çoğulluk bir DİL kuralı,
/// sunum kuralı değil: Türkçe sayıdan sonra çoğul istemez). Aşağıdaki
/// testler kabuğun **gerçekten** alan-kelimesi/dil-kuralı taşımadığını
/// kanıtlıyor: rastgele/yabancı bir etiketle de doğru dizilir.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// `_SessionScreenState._unitLabel`in tekil dalını (`_roundsCompleted==1`)
/// — bunun için gerçek bir turun canlı `onProgress` ile tamamlanması
/// gerekir (`live_jab_path_test` makinesi, kurulmadı). Tek satırlık
/// ternary, çoğul dalı (0 tur — aşağıdaki zincir testi + gerçek simülatör
/// koşumuyla kanıtlı) ile aynı kod yolunu paylaşıyor.
void main() {
  Future<void> pump(
    WidgetTester t, {
    int units = 0,
    String unitLabel = 'rounds',
    int seconds = 0,
    int? eventCount,
    String? tempoBand,
    Map<String, String> bands = const <String, String>{},
  }) => t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SessionSummaryView(
          eventCount: eventCount,
          bands: bands,
          coachedNotScored: const <String>[],
          unitsCompleted: units,
          unitLabel: unitLabel,
          workedSeconds: seconds,
          tempoBand: tempoBand,
        ),
      ),
    ),
  );

  group('J-259 — tur/süre etiketi', () {
    testWidgets('0 tur / 0 sn → dürüst sıfır, gizlenmez', (
      WidgetTester t,
    ) async {
      await pump(t);
      expect(
        find.byKey(const Key('summary-worked')),
        findsOneWidget,
        reason: 'seans yapısı hiçbir koşulda gizlenmemeli — 0 da olgudur',
      );
      expect(find.text('0 rounds • no time recorded'), findsOneWidget);
    });

    testWidgets('NEGATİF İKİZ — 17 sn "0 min" DEĞİL "under a minute" (J-257)', (
      WidgetTester t,
    ) async {
      // J-257'nin ta kendisi, bu kez tek-seans özetinde: 17 sn çalışan
      // kullanıcı hiç çalışmayanla AYNI cümleyi görmemeli.
      await pump(t, units: 1, unitLabel: 'round', seconds: 17);
      expect(find.text('1 round • under a minute'), findsOneWidget);
      expect(
        find.textContaining('0 min'),
        findsNothing,
        reason: '17 saniyelik iş "0 min" diye okunursa yapılmamış görünür',
      );
    });

    testWidgets('90 sn → "1 min" (dakikaya yuvarlama)', (WidgetTester t) async {
      await pump(t, units: 3, unitLabel: 'rounds', seconds: 90);
      expect(find.text('3 rounds • 1 min'), findsOneWidget);
    });

    testWidgets(
      '⛔ KABUK TEKİL/ÇOĞUL BİLMİYOR — rastgele etiket AYNEN basılır (M-F-25)',
      (WidgetTester t) async {
        // Kabuk kendi tekil/çoğul kararını verseydi bu test ANLAMSIZ bir
        // etiketle çelişirdi. "intervals" (İngilizce çoğul biçimi DEĞİL bir
        // dize) ve hatta yabancı bir kelimeyle de doğru dizilmeli — kabuk
        // yalnız YERLEŞTİRİR, kelimeye/dile bakmaz.
        await pump(t, units: 1, unitLabel: 'zörgleplix', seconds: 5);
        expect(
          find.text('1 zörgleplix • under a minute'),
          findsOneWidget,
          reason: 'kabuk etiketi YORUMLUYOR gibi görünüyor — yalnız TAŞIMALI',
        );
      },
    );
  });

  group('D18 — tempo bandı', () {
    testWidgets('completed events without valid tempo do not invent a band', (
      WidgetTester t,
    ) async {
      await pump(t, eventCount: 3);
      expect(find.byKey(const Key('summary-count')), findsOneWidget);
      expect(t.widget<Text>(find.byKey(const Key('summary-count'))).data, '3');
      expect(find.byKey(const Key('summary-tempo-band')), findsNothing);
      expect(find.text('Pace: controlled'), findsNothing);
    });

    testWidgets('bant YOKSA yuva da YOK (hiç ölçülmüş deneme yok)', (
      WidgetTester t,
    ) async {
      await pump(t);
      expect(
        find.byKey(const Key('summary-tempo-band')),
        findsNothing,
        reason:
            'ölçülmemiş deneme için varsayılan bant UYDURULMAMALI '
            '("controlled" yazmak "bilmiyorum"u "en düşük" gibi gösterir)',
      );
    });

    testWidgets(
      'bant VARSA GÖSTERİLİR — kabuk hangi kelime olduğuna karışmaz',
      (WidgetTester t) async {
        await pump(t, tempoBand: 'brisk');
        expect(find.byKey(const Key('summary-tempo-band')), findsOneWidget);
        expect(find.text('Pace: brisk'), findsOneWidget);
      },
    );
  });

  group('J-251 — bant açıklaması', () {
    testWidgets('bant YOKSA açıklama da YOK (vakum-doğru)', (
      WidgetTester t,
    ) async {
      await pump(t);
      expect(
        find.byKey(const Key('summary-bands-note')),
        findsNothing,
        reason: 'açıklayacak bant yokken not göstermek konu-dışı gürültü',
      );
    });

    testWidgets('bant VARSA "—" için gerekçe GÖRÜNÜR (H-24 simetrisi)', (
      WidgetTester t,
    ) async {
      await pump(t, bands: const <String, String>{'Stance': '—'});
      expect(
        find.byKey(const Key('summary-bands-note')),
        findsOneWidget,
        reason:
            'canlı bir yüzey (bantlar) açıklamasız kaldı — engelli '
            'yüzeyler (coached-not-scored) zaten açıklanıyordu',
      );
      // Metin `course_page.dart`taki `_HonestBands`ten AYNEN alındı —
      // aynı olgu iki ekranda FARKLI cümlelerle anlatılırsa biri bayatlar.
      expect(
        find.text(
          'Scores are unavailable because the thresholds have not been '
          'calibrated on real recordings. A precise-looking number we '
          'cannot back up would be worse than no number.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    '⭐ ZİNCİR — kamerasız derste ÖZET GERÇEKTEN besleniyor (J-096 sınıfı)',
    (WidgetTester t) async {
      // `summary_count_test.dart`ın aynı dersi: bileşen kusursuz olup
      // `_SessionScreenState` onu hiç beslemiyor olabilir. Bu test yalnız
      // TELİN VAR OLDUĞUNU kanıtlıyor (widget gerçekten `_SessionScreenState`
      // içinden `unitsCompleted`/`unitLabel`/`workedSeconds` alıyor, sabit-
      // kodlanmış bir varsayılan değil) — pozitif (round tamamlanmış) ucu
      // değil, bkz. dosya dokümanının "NE ÖLÇMÜYOR" bölümü. Gerçek simülatör
      // koşumunda (jablab-hatti, `vtool` ile IOSSIMULATOR doğrulanmış build)
      // aynı ekran elle de doğrulandı: "0 rounds • no time recorded".
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
          const JabLabApp(onboarding: OnboardingStore(seenOverride: true)),
        );
      });
      await settleAppLoad(t);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('item-boxing')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('course-boxing.foundations')));
      await t.pumpAndSettle();
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

      // VAKUM KAPISI: gerçekten özet aşamasında mıyız?
      expect(
        find.byKey(const Key('summary-band-Stance')),
        findsOneWidget,
        reason: 'özet aşamasına gelinmedi — kapı boşluğa bakıyor olabilir',
      );

      expect(
        find.byKey(const Key('summary-worked')),
        findsOneWidget,
        reason: 'gerçek uygulama zincirinde tur/süre yuvası hiç çizilmedi',
      );
      // ⭐ BONUS BULGU: ilk sürüm burada "0 rounds" bekliyordu — kendi
      // gerçek simülatör gözlemimden kopyalanmış, ama YANLIŞ: "stance"
      // dersi `plan`sız (interval tabanlı), `SessionRecord.unitLabel` da
      // zaten 'interval' yazıyordu (session_screen.dart:212). M-F-25 terfi
      // kapısı beni `_unitLabel`i `unitLabel` deseniyle DOĞRU hesaplamaya
      // zorlayınca bu içerik kusuru da kendiliğinden düzeldi.
      expect(
        find.text('0 intervals • no time recorded'),
        findsOneWidget,
        reason:
            'stance dersi plansız (interval tabanlı) — "round" demek '
            'SessionRecord.unitLabel ile ÇELİŞİRDİ (J-268 ilk sürümünün '
            'kendi kusuru, M-F-25 kapısı yakaladı)',
      );
    },
  );
}
