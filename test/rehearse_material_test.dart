import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/rehearse_material.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/teach_material.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';

/// PROVA AŞAMASI MATERYAL YUVASI (J-247) — `teach_material_test`in kardeşi.
///
/// ## Sınanan kusur, ölçülmüş hâliyle
///
/// Prova ("Try it") aşaması `const _Rehearse()` idi: **ders girdisi YOKTU.**
/// 19 dersin 19'unda da ekranda yalnız *"Go slow. One thing at a time, no
/// clock."* yazıyordu — 12 dakikalık, `jab · cross` çalıştıran bir dersin
/// prova ekranı, neyi prova edeceğini söylemiyordu. Simülatörde elle
/// yürünüp ekran görüntüsüyle doğrulandı.
///
/// ⭐ **Bu dosyadaki en önemli kapı `AYRIŞMA` testi:** kusur "yanlış cümle"
/// değil **"HER DERSTE AYNI cümle"** idi. Tek bir dersi doğru render etmeyi
/// ölçen bir test, 19 dersin aynı şeyi göstermesini YAKALAYAMAZDI —
/// eski kod her tekil dersi "doğru" render ediyordu zaten.
void main() {
  late final Library library;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final ({dynamic library, dynamic boxing}) c =
        await const ContentRepository().load();
    library = c.library as Library;
  });

  Iterable<Lesson> allLessons() sync* {
    for (final Discipline d in library.disciplines) {
      for (final Course c in d.courses) {
        yield* c.lessons;
      }
    }
  }

  test('TEKNİKLİ ders DRILL, tekniksiz ders YOKLUK döndürüyor', () {
    int drilled = 0;
    int none = 0;
    for (final Lesson l in allLessons()) {
      final RehearseMaterial m =
          const ContentRepository().rehearseMaterialFor(library, l.id);
      if (l.techniques.isEmpty) {
        expect(m, isA<RehearseMaterialNone>(),
            reason: '${l.id} teknik listelemiyor ama YOKLUK demiyor — '
                'boşluk sessizce dolduruluyor');
        none++;
      } else {
        expect(m, isA<RehearseMaterialDrill>(),
            reason: '${l.id} içerikte teknik taşıyor ama ekrana ulaşmıyor — '
                'türetim kopmuş');
        // İÇERİK DEĞİŞMEDEN geçmeli: depo kendi teknik adını UYDURAMAZ.
        expect((m as RehearseMaterialDrill).techniques, l.techniques,
            reason: '${l.id} teknik listesi yolda DEĞİŞMİŞ');
        expect(m.combinations, l.combinations,
            reason: '${l.id} kombinasyon listesi yolda DEĞİŞMİŞ');
        drilled++;
      }
    }
    // VAKUM KORUMASI — iki dal da GERÇEKTEN koşmalı; biri boşalırsa bu test
    // sessizce yarısını ölçmeyi bırakır (`teach_material_test`in dersi).
    expect(drilled, greaterThan(0),
        reason: 'hiçbir ders teknik taşımıyor — türetim ölçülmedi');
    expect(none, greaterThan(0),
        reason: 'her ders teknik taşıyor: YOKLUK dalı artık ölçülmüyor '
            '(vakum-doğru). Ya kapsamı değiştir ya da ayrı kanıt yaz.');
  });

  test('⭐ AYRIŞMA: prova yüzeyi derse göre DEĞİŞİYOR', () {
    // Kusurun tam kalbi. Eski kodda bu kümenin boyutu **1** idi (tek sabit
    // cümle, 19 derste aynı). Bir dersi tek başına ölçen test bunu göremez.
    final Set<String> distinct = <String>{};
    for (final Lesson l in allLessons()) {
      final RehearseMaterial m =
          const ContentRepository().rehearseMaterialFor(library, l.id);
      distinct.add(switch (m) {
        RehearseMaterialDrill(
          techniques: final List<String> t,
          combinations: final List<String> c
        ) =>
          'drill:${t.join(",")}|${c.join(",")}',
        RehearseMaterialNone(reason: final String r) => 'none:$r',
      });
    }
    expect(distinct.length, greaterThan(1),
        reason: 'prova yüzeyi TÜM derslerde aynı — J-247 kusuru geri gelmiş: '
            'aşama dersin adını bile anmıyor');
  });

  test('BİLİNMEYEN ders: yokluk döner ama SEBEBİ farklı', () {
    // İki durum ("teknik listelenmemiş" / "ders yok") aynı cümleye düşerse
    // saha teşhisi imkânsızlaşır.
    final RehearseMaterial missing = const ContentRepository()
        .rehearseMaterialFor(library, 'boyle.bir.ders.yok');
    final Lesson noTech =
        allLessons().firstWhere((Lesson l) => l.techniques.isEmpty);
    final RehearseMaterial empty =
        const ContentRepository().rehearseMaterialFor(library, noTech.id);

    expect(missing, isA<RehearseMaterialNone>());
    expect(empty, isA<RehearseMaterialNone>());
    expect((missing as RehearseMaterialNone).reason,
        isNot((empty as RehearseMaterialNone).reason),
        reason: 'iki farklı yokluk AYNI cümleyi veriyor — hangisi olduğu '
            'ekrandan da loglardan da anlaşılamaz');
  });

  Future<void> pumpRehearse(WidgetTester t, RehearseMaterial m) async {
    late final CueBook cues;
    await t.runAsync(() async {
      cues = await const ContentRepository().loadCues();
    });
    await t.pumpWidget(MaterialApp(
      home: SessionScreen(
        lesson: const ShellLesson(id: 'x', title: 'Test lesson', minutes: 12),
        cues: cues,
        coachedNotScored: const <String>[],
        bands: const <String, String>{'Stance': '—'},
        plan: null,
        rehearseMaterial: m,
        teachMaterial: const TeachMaterialText(body: 'Body.'),
      ),
    ));
    await t.pumpAndSettle();
    // Prova aşamasına GEÇ: ilk aşama `teach`.
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
  }

  testWidgets('DRILL: teknikler ekranda ADIYLA görünüyor',
      (WidgetTester t) async {
    await pumpRehearse(
      t,
      const RehearseMaterialDrill(
        techniques: <String>['jab', 'cross'],
        combinations: <String>['jab-cross'],
      ),
    );
    expect(find.byKey(const Key('rehearse-technique-jab')), findsOneWidget);
    expect(find.byKey(const Key('rehearse-technique-cross')), findsOneWidget);
    expect(find.byKey(const Key('rehearse-combination-jab-cross')),
        findsOneWidget);
    // Aşamanın değişmeyen sözü DURUYOR — yeni içerik onu kovmadı.
    expect(find.byKey(const Key('rehearse-copy')), findsOneWidget);
  });

  testWidgets('DRILL kombinasyonsuz: başlık HİÇ çizilmiyor',
      (WidgetTester t) async {
    // Boş listeyi "kombinasyon yok" diye duyurmak gürültü olurdu.
    await pumpRehearse(
        t, const RehearseMaterialDrill(techniques: <String>['jab']));
    expect(find.byKey(const Key('rehearse-technique-jab')), findsOneWidget);
    expect(find.byKey(const Key('rehearse-combos-heading')), findsNothing);
  });

  testWidgets('YOKLUK: sebep BEYAN ediliyor, teknik listesi çizilmiyor',
      (WidgetTester t) async {
    await pumpRehearse(
        t, const RehearseMaterialNone(reason: 'No named technique here.'));
    expect(find.byKey(const Key('rehearse-material-none')), findsOneWidget);
    expect(find.byKey(const Key('rehearse-drill-heading')), findsNothing);
    expect(find.text('No named technique here.'), findsOneWidget);
  });
}
