import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/design_tokens.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/app/rehearse_material.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/skeleton_overlay.dart';
import 'package:jablab/app/teach_material.dart';
import 'package:jablab/shell_candidate/session_flow.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';

/// Çok turlu seans saatinin GERÇEKTEN turları koştuğu (J-063).
///
/// J-062'nin ölçtüğü kusur tam buradaydı: canlı ekran sabit 3 dakika
/// koşuyordu ve "Twenty minutes / Six rounds" dersi 3 dakikada bitiyordu.
/// Aşağıdaki testler saatin turdan tura ve dinlenmeye geçtiğini SANAL SAATİ
/// İLERLETEREK kanıtlıyor — "widget çiziliyor mu" değil, "süre koşuyor mu".
void main() {
  setUp(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(1200, 2400);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  /// Canlı aşamayı doğrudan kurar — kütüphane gezinmesini tekrarlamaya gerek
  /// yok, sınanan şey saat.
  Future<void> pumpLive(
    WidgetTester t, {
    required RoundPlan? plan,
    IntervalPlan? intervalPlan,
    SessionStore? store,
  }) async {
    late final CueBook cues;
    await t.runAsync(() async {
      cues = await const ContentRepository().loadCues();
    });
    await t.pumpWidget(MaterialApp(
      home: SessionScreen(
        lesson: const ShellLesson(id: 'x', title: 'Test lesson', minutes: 12),
        cues: cues,
        coachedNotScored: const <String>['Rear guard hand position'],
        bands: const <String, String>{'Stance': '—'},
        plan: plan,
        intervalPlan: intervalPlan,
        store: store,
        rehearseMaterial: const RehearseMaterialNone(reason: 'fixture: no drill named'),
        teachMaterial:
            const TeachMaterialNone(reason: 'test: materyal yok'),
      ),
    ));
    await t.pumpAndSettle();
    // teach → rehearse → live
    await t.tap(find.byKey(const Key('advance-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('advance-button')));
    await t.pump();
  }

  testWidgets('çok turlu plan: tur konumu yazılı ve TURDAN TURA GEÇİYOR',
      (WidgetTester t) async {
    // Kısa ama gerçek yapı: 3 tur × 4sn + 2 dinlenme × 2sn = 16sn.
    const RoundPlan plan = RoundPlan(
      rounds: 3,
      roundSeconds: 4,
      restSeconds: 2,
      planProvenance: 'test',
    );
    await pumpLive(t, plan: plan);

    // Konum YUVASINDAN okunur. `textContaining('Rest')` kullanmak yanlış
    // olurdu: anlatı yuvası da "Rest." diyor ve iki eşleşme çıkıyor —
    // tam olarak "anlatı ile hüküm/konum AYRI yuva" tasarımının kanıtı.
    String position() =>
        t.widget<Text>(find.byKey(const Key('live-round-position'))).data!;

    expect(position(), 'Round 1 of 3');

    // 1. tur bitene kadar ilerlet → dinlenmeye geçmeli
    await t.pump(const Duration(seconds: 5));
    expect(position(), 'Rest — round 2 of 3 next',
        reason: 'tur bitti ama dinlenmeye geçilmedi');

    // dinlenme bitince 2. tur
    await t.pump(const Duration(seconds: 3));
    expect(position(), 'Round 2 of 3',
        reason: 'dinlenme bitti ama 2. tur başlamadı');

    // 2. tur + dinlenme + 3. tura geç
    await t.pump(const Duration(seconds: 5));
    expect(position(), 'Rest — round 3 of 3 next');
    await t.pump(const Duration(seconds: 3));
    expect(position(), 'Round 3 of 3', reason: 'son tura ulaşılmadı');

    // Son turun sonu = seans sonu. SON TURDAN SONRA DİNLENME YOK.
    await t.pump(const Duration(seconds: 6));
    expect(position(), 'Round 3 of 3',
        reason: 'son turdan sonra dinlenme gösterildi ya da 4. tur uyduruldu — '
            'seans bitmeliydi');

    // Saat durmuş olmalı: daha fazla ilerletmek 4. tur uydurmamalı.
    await t.pump(const Duration(seconds: 30));
    expect(position(), 'Round 3 of 3');
  });

  testWidgets('tek turlu planda tur konumu GÖSTERİLMEZ',
      (WidgetTester t) async {
    // "Round 1 of 1" bir bilgi değil, gürültü.
    const RoundPlan plan = RoundPlan(
      rounds: 1,
      roundSeconds: 5,
      restSeconds: 0,
      planProvenance: 'test',
    );
    await pumpLive(t, plan: plan);
    expect(find.byKey(const Key('live-round-position')), findsNothing);
    expect(find.byKey(const Key('live-no-verdict')), findsOneWidget);
  });

  testWidgets('plansız (öğretme) derste SAAT HİÇ AKMAZ, hüküm yuvası konuşur',
      (WidgetTester t) async {
    // Öğretme dersleri süreli çalışma DEĞİL; olmayan bir tur yapısını
    // varmış gibi göstermek J-062 kusurunun aynadaki hâli olurdu.
    await pumpLive(t, plan: null);
    expect(find.byType(IntervalTimer), findsNothing,
        reason: 'plansız derste tur saati gösterilmemeli');
    expect(find.byKey(const Key('live-round-position')), findsNothing);
    expect(find.byKey(const Key('live-no-verdict')), findsOneWidget,
        reason: 'kamera yok beyanı plansız derste de görünmeli');
  });

  testWidgets('anlatı her turda YENİDEN konuşuyor (startRound sıfırlaması)',
      (WidgetTester t) async {
    // startRound() olay setini sıfırlamazsa "yarıladın" yalnız ilk turda
    // söylenir ve sonraki turlar sessiz geçer — sesli koçta sessizlik
    // "sorun yok" diye okunur.
    const RoundPlan plan = RoundPlan(
      rounds: 2,
      roundSeconds: 6,
      restSeconds: 2,
      planProvenance: 'test',
    );
    await pumpLive(t, plan: plan);

    // 1. turun yarısını geç → bir replik görünmüş olmalı
    await t.pump(const Duration(seconds: 4));
    final Finder cue = find.byKey(const Key('live-narration'));
    expect(cue, findsOneWidget,
        reason: 'ilk turda hiç replik söylenmedi');
    final String firstRoundLine = t.widget<Text>(cue).data!;

    // 2. tura geç: 1. turu bitir (6sn) → dinlenme (2sn) → 2. tur.
    await t.pump(const Duration(seconds: 3)); // t≈7 → tur bitti, dinlenme
    await t.pump(const Duration(seconds: 3)); // dinlenme bitti → 2. tur
    expect(find.text('Round 2 of 2'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
    expect(find.byKey(const Key('live-narration')), findsOneWidget,
        reason: '2. turda anlatı sustu — startRound sıfırlaması çalışmıyor');
    // Varyant döndürmesi gereği aynı olay farklı cümle verir; en azından bir
    // cümle GÖRÜNÜYOR olması yeterli kanıt (sessizlik yok).
    expect(firstRoundLine, isNotEmpty);
  });

  group('kayıt (J-064)', () {
    testWidgets('tamamlanan seans ÇALIŞMA süresiyle kaydedilir — '
        'dinlenme SAYILMAZ', (WidgetTester t) async {
      // Kapı çalışma süresini soruyor; dinlenmeyi de eklemek kullanıcıyı
      // kapıdan hak etmeden geçirirdi.
      final _FakeStore store = _FakeStore();
      const RoundPlan plan = RoundPlan(
        rounds: 3,
        roundSeconds: 4,
        restSeconds: 2,
        planProvenance: 'test',
      );
      await pumpLive(t, plan: plan, store: store);
      // Tüm seansı koştur: 3×4 çalışma + 2×2 dinlenme.
      await t.pump(const Duration(seconds: 30));
      // canlı → özet: kayıt burada yazılır
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pumpAndSettle();

      expect(store.written.length, 1, reason: 'seans kaydedilmedi');
      final SessionRecord r = store.written.single;
      expect(r.lessonId, 'x');
      expect(r.unitsCompleted, 3);
      expect(r.plannedUnits, 3);
      expect(r.isComplete, isTrue);
      expect(r.workedSeconds, 12,
          reason: 'çalışma 3×4=12sn olmalı; 16 çıkarsa dinlenme de sayılmış');
    });

    // ⚠️ KAPSAM NOTU (J-192): bu kapının ADI 2026-08-07'ye kadar
    // ölçümünden GENİŞTİ — "yarıda bırakılan seans" diyordu ama yalnız
    // İLERİ düğmesiyle çıkışı ölçüyordu; GERİ okuyla çıkan kullanıcının
    // işi kaydedilmiyordu ve bunu hiçbir test görmüyordu.
    //
    //   Devralınan bir kapı, kurulduğu günkü kapsamıyla değil,
    //   ADININ vaat ettiği kapsamla okunur — ve fark zamanla büyür,
    //   çünkü kimse adı yeniden ölçmez.
    //
    // Geri yolu artık `session_exit_test` ölçüyor ve `dispose` onu
    // kaydediyor; bu ad BUGÜN gerçekten genel.
    testWidgets('YARIDA bırakılan seans da kaydedilir, tamamlanmamış işaretli',
        (WidgetTester t) async {
      final _FakeStore store = _FakeStore();
      const RoundPlan plan = RoundPlan(
        rounds: 6,
        roundSeconds: 4,
        restSeconds: 2,
        planProvenance: 'test',
      );
      await pumpLive(t, plan: plan, store: store);
      await t.pump(const Duration(seconds: 5)); // 1. tur bitti, dinlenmede
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pumpAndSettle();

      final SessionRecord r = store.written.single;
      expect(r.isComplete, isFalse);
      expect(r.unitsCompleted, 1);
      expect(r.plannedUnits, 6);
      expect(r.workedSeconds, 4,
          reason: 'tek tur çalışıldı (4sn); dinlenmede geçen süre sayılmamalı');
    });

    testWidgets('plansız derste KAYIT YAZILMAZ', (WidgetTester t) async {
      // Sıfır saniyelik kayıt, geçmişi anlamsız satırlarla doldurmak olurdu.
      final _FakeStore store = _FakeStore();
      await pumpLive(t, plan: null, store: store);
      await t.pump(const Duration(seconds: 10));
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pumpAndSettle();
      expect(store.written, isEmpty);
    });

    testWidgets('depo YOKKEN akış çalışmaya devam eder', (WidgetTester t) async {
      // Depolama hatası antrenmanı engellememeli.
      const RoundPlan plan = RoundPlan(
        rounds: 2,
        roundSeconds: 3,
        restSeconds: 1,
        planProvenance: 'test',
      );
      await pumpLive(t, plan: plan);
      await t.pump(const Duration(seconds: 20));
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('coached-not-scored-note')), findsOneWidget,
          reason: 'depo yokken özet aşamasına geçilemedi');
    });
  });

  group('aralık kipi (J-068)', () {
    // 3 patlama × 4sn + 3 toparlanma × 2sn = 18sn TOPLAM (son toparlanma
    // DAHİL — turdan yapısal fark burada).
    const IntervalPlan ivl = IntervalPlan(
      bursts: 3,
      burstSeconds: 4,
      recoverSeconds: 2,
      planProvenance: 'test',
    );

    String pos(WidgetTester t) =>
        t.widget<Text>(find.byKey(const Key('live-burst-position'))).data!;

    testWidgets('patlama → toparlanma → patlama döngüsü YÜRÜYOR',
        (WidgetTester t) async {
      await pumpLive(t, plan: null, intervalPlan: ivl);
      expect(pos(t), 'Burst 1 of 3');

      await t.pump(const Duration(seconds: 5));
      expect(pos(t), 'Recover — burst 2 of 3 next',
          reason: 'patlama bitti ama toparlanmaya geçilmedi');

      await t.pump(const Duration(seconds: 3));
      expect(pos(t), 'Burst 2 of 3',
          reason: 'toparlanma bitti ama 2. patlama başlamadı');

      await t.pump(const Duration(seconds: 5));
      await t.pump(const Duration(seconds: 3));
      expect(pos(t), 'Burst 3 of 3');
    });

    testWidgets('SON patlamadan sonra da toparlanma KOŞAR (turdan fark)',
        (WidgetTester t) async {
      // `RoundPlan` son turdan sonra dinlenme saymaz; aralıkta soğuma
      // döngünün parçası. İki tipin ayrı olmasının sebebi tam bu.
      await pumpLive(t, plan: null, intervalPlan: ivl);
      // 3. patlamanın sonuna kadar ilerlet
      for (int i = 0; i < 2; i++) {
        await t.pump(const Duration(seconds: 5));
        await t.pump(const Duration(seconds: 3));
      }
      expect(pos(t), 'Burst 3 of 3');
      await t.pump(const Duration(seconds: 5));
      expect(pos(t), contains('Recover'),
          reason: 'son patlamadan sonra toparlanma koşmadı');
      // toparlanma bitince seans biter, 4. patlama UYDURULMAZ
      await t.pump(const Duration(seconds: 30));
      expect(pos(t), isNot(contains('Burst 4')));
    });

    testWidgets('aralık replikleri KONUŞUYOR (kip interval seçildi)',
        (WidgetTester t) async {
      // `SessionMode.steady` bırakılsaydı `interval()` boş döner ve
      // cue.burst_start/recover hiç duyulmazdı ("kod var, kullanıcı duymuyor").
      await pumpLive(t, plan: null, intervalPlan: ivl);
      await t.pump(const Duration(seconds: 5));
      expect(find.byKey(const Key('live-narration')), findsOneWidget,
          reason: 'toparlanmaya geçişte hiçbir replik söylenmedi');
    });

    testWidgets('ÇALIŞMA süresi yalnız PATLAMALARI sayar',
        (WidgetTester t) async {
      final _FakeStore store = _FakeStore();
      await pumpLive(t, plan: null, intervalPlan: ivl, store: store);
      await t.pump(const Duration(seconds: 60));
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pumpAndSettle();

      final SessionRecord r = store.written.single;
      expect(r.workedSeconds, 12,
          reason: 'çalışma 3×4=12sn olmalı; 18 çıkarsa toparlanma da sayılmış');
      expect(r.unitsCompleted, 3);
      expect(r.plannedUnits, 3);
      expect(r.isComplete, isTrue);
    });
  });

  // ## J-119 — aralık kipinde düzeltme SUSTURULMUYOR, TONU değişiyor
  //
  // `cues.en.json` eskiden form repliklerinin bu kipte SUSTURULDUĞUNU
  // varsayıyordu ve kod susturmuyordu — varsayım uygulanmış sanılabilirdi.
  // Susturmayı ürünün kendi kuralı öldürüyor: **bu uygulamada sessizlik
  // "her şey yolunda" diye okunur**, yani susmak nötr değil YANLIŞ bir şey
  // söyler. Üçüncü ilke ikisini de kesiyor: ÖLÇÜM ≠ HÜKÜM — *"formun
  // bozuldu"* bir hüküm, *form bozulması* bir olgu.
  //
  // ⚠️ İKİ AYRI TEST, tek test değil: `pumpLive` bir testte iki kez
  // çağrılamıyor — birinci canlı aşamanın `Timer.periodic`i koşarken
  // ikinci çağrının `runAsync`i ilerlemiyor. Ölçüldü (üç farklı bulucu
  // aynı sebeple düştü). Bölmek, kurulumu ikinci kez yazmaktan iyi.

  /// Hüküm yuvasının okuduğu stili, `_bucketed` sarmalının İÇİNDEN okur.
  /// `SkeletonPreview` her iki kipte de orada çiziliyor (kamerasız dalda
  /// da — J-110'da eklendi).
  TextStyle cueStyle(WidgetTester t) => Theme.of(
          t.element(find.byType(SkeletonPreview).first))
      .textTheme
      .titleLarge!;

  testWidgets('ARALIK kipinde düzeltme GÖZLEM tonunda (J-119)',
      (WidgetTester t) async {
    await pumpLive(t,
        plan: null,
        intervalPlan: const IntervalPlan(
            bursts: 2,
            burstSeconds: 10,
            recoverSeconds: 10,
            planProvenance: 'test'));
    expect(cueStyle(t).color, JColors.cool,
        reason: 'aralık kipinde düzeltme hâlâ HÜKÜM tonunda çiziliyor');
  });

  testWidgets('⭐ NEGATİF İKİZ: TURLU kipte ton DEĞİŞMİYOR (J-119)',
      (WidgetTester t) async {
    // Bu olmadan yukarıdaki test, her iki kipte de gözlem tonu kullanılsa
    // bile geçerdi — hüküm yuvası sessizce hükmünü kaybeder ve ayrım
    // vakum-doğru olurdu (ders #4).
    await pumpLive(t,
        plan: const RoundPlan(
            rounds: 1,
            roundSeconds: 60,
            restSeconds: 0,
            planProvenance: 'test'));
    final TextStyle steady = cueStyle(t);
    expect(steady.color, isNot(JColors.cool),
        reason: 'turlu kipte de gözlem tonu kullanılıyor — hüküm yuvası '
            'hükmünü kaybetmiş');
    expect(steady.fontSize, JText.correction.fontSize,
        reason: 'punto değişmiş: kullanıcı 2-3 m uzakta ve okunurluk '
            'tonun altında değil — ton rengi değiştirir, boyutu değil');
  });

}

/// Bellekte tutan sahte depo — kalıcılık davranışı `session_store_test`'te
/// sınanıyor; burada sınanan şey EKRANIN NE KAYDETTİĞİ.
class _FakeStore implements SessionStore {
  final List<SessionRecord> written = <SessionRecord>[];

  @override
  Future<void> append(SessionRecord record) async => written.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => written;

  @override
  Future<int> unreadableRecords() async => 0;

  @override
  Future<int> workedSecondsFor(String lessonId) async {
    int total = 0;
    for (final SessionRecord r in written) {
      if (r.lessonId == lessonId) total += r.workedSeconds;
    }
    return total;
  }


}
