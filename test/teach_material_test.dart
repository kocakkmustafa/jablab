import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/teach_material.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';

/// ÖĞRETME AŞAMASI MATERYAL YUVASI (J-094) — UI-BRIEF §4/2 kod tarafı.
///
/// Sınanan dürüstlük değişmezi tek cümleyle: **ekran, yapılamayacak bir
/// eylemi söylememeli.** Eski metin *"watch first"* diyordu ve izlenecek
/// hiçbir şey yoktu — `Lesson` modelinde materyal alanı bile bulunmuyor.
///
/// Bu dosya comp'un işini SINAMIYOR (video/çizim nasıl görünecek tasarımın
/// kararı); sınadığı şey materyalin VARLIĞINA göre ekranın ne dediği.
void main() {
  Future<void> pumpTeach(WidgetTester t, TeachMaterial material) async {
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
        plan: null,
        teachMaterial: material,
      ),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('materyal YOKKEN yokluk BEYAN edilir', (WidgetTester t) async {
    await pumpTeach(
        t, const TeachMaterialNone(reason: 'There is no lesson material yet.'));
    expect(find.byKey(const Key('teach-material-none')), findsOneWidget);
    expect(find.byKey(const Key('teach-material')), findsNothing);
  });

  testWidgets('materyal YOKKEN "izle/oku" TALİMATI VERİLMEZ',
      (WidgetTester t) async {
    // Kusurun kendisi buydu: ekran kullanıcıya yapamayacağı bir eylemi
    // söylüyordu. Emir kipindeki fiiller taranıyor — cümle yeniden yazılsa
    // bile nöbet ayakta kalsın diye metnin tamamına bakılıyor.
    await pumpTeach(
        t, const TeachMaterialNone(reason: 'There is no lesson material yet.'));
    final RegExp instruction =
        RegExp(r'\b(watch|read|play|view)\s+(first|this|it|along)\b',
            caseSensitive: false);
    for (final Text w in t.widgetList<Text>(find.byType(Text))) {
      expect(instruction.hasMatch(w.data ?? ''), isFalse,
          reason: 'materyal yokken izleme/okuma talimatı verildi: "${w.data}"');
    }
  });

  testWidgets('AŞAMA ETİKETİ de talimat vermiyor — gövdeyle ÇELİŞMİYOR',
      (WidgetTester t) async {
    // Simülatörde yakalandı (J-094): gövde "izlenecek materyal yok" derken
    // üstteki sekme hâlâ "Watch" diyordu — aynı ekranda çelişen iki cümle.
    // Widget testleri iki metnin VARLIĞINI görür, aralarındaki ÇELİŞKİYİ
    // görmez; bu nöbet o boşluğu kapatıyor.
    await pumpTeach(t, const TeachMaterialNone(reason: 'yok'));
    expect(find.text('Watch'), findsNothing,
        reason: 'aşama etiketi bir MEDYA vaadi veriyor; materyal video '
            'olmayabilir ya da hiç olmayabilir');
    expect(find.text('Learn'), findsOneWidget);
  });

  testWidgets('POZİTİF İKİZ: materyal VARKEN gövde çizilir, yokluk beyanı YOK',
      (WidgetTester t) async {
    // Gotcha #5: yukarıdaki iki "X yok" iddiası, materyal dalı HİÇ
    // çizilmiyorsa da geçerdi.
    await pumpTeach(
        t, const TeachMaterialText(body: 'Keep the lead hand high.'));
    expect(find.byKey(const Key('teach-material')), findsOneWidget);
    expect(find.byKey(const Key('teach-material-none')), findsNothing);
    expect(find.text('Keep the lead hand high.'), findsOneWidget);
  });

  testWidgets('hüküm-susuyor cümlesi HER İKİ hâlde de duruyor',
      (WidgetTester t) async {
    // Bu beyan materyalden BAĞIMSIZ: `teach` aşaması tanım gereği hükümsüz.
    // Materyal geldiği gün sessizce düşerse, kullanıcı öğrenirken
    // puanlanmadığını bilmez.
    await pumpTeach(t, const TeachMaterialNone(reason: 'yok'));
    expect(find.byKey(const Key('teach-no-analysis')), findsOneWidget);
    await pumpTeach(t, const TeachMaterialText(body: 'gövde'));
    expect(find.byKey(const Key('teach-no-analysis')), findsOneWidget);
  });

  group('içerikten TÜRETME (ekran kendi cevabını uydurmuyor)', () {
    late Library library;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final ({dynamic library, dynamic boxing}) c =
          await const ContentRepository().load();
      library = c.library as Library;
    });

    test('MATERYALLİ ders METİN, materyalsiz ders YOKLUK döndürüyor', () {
      // ## Bu test bir TEL-TUZAĞIN devri (J-094 → J-118)
      //
      // Eskiden şunu ölçüyordu: *"BUGÜN hiçbir derste materyal YOK"* — ve
      // her dersi tek tek sorup birinin sessizce materyal kazanmasını
      // bekliyordu. Hata mesajı bile talimatı taşıyordu: *"materyal
      // kazanmış — ekran yolu bağlanmalı."*
      //
      // **Tuzak 2026-08-07'de ateşlendi ve talimatı yerine getirildi:**
      // `Lesson.teach` eklendi, `ContentRepository` onu okuyor, Foundations
      // altı dersi metin taşıyor. Test SİLİNMEDİ — devredildi: artık ölçtüğü
      // şey "hiç yok" değil, **iki hâlin de doğru yere gittiği.** Silseydim
      // yokluk dalının dürüstlüğü ölçüsüz kalırdı (ders #4).
      int withText = 0;
      int withoutText = 0;
      for (final Discipline d in library.disciplines) {
        for (final Course c in d.courses) {
          for (final Lesson l in c.lessons) {
            final TeachMaterial m =
                const ContentRepository().teachMaterialFor(library, l.id);
            if (l.teach != null && l.teach!.trim().isNotEmpty) {
              expect(m, isA<TeachMaterialText>(),
                  reason: '${l.id} içerikte metin taşıyor ama ekrana '
                      'ulaşmıyor — türetim kopmuş');
              expect((m as TeachMaterialText).body, l.teach,
                  reason: '${l.id} metni yolda DEĞİŞMİŞ — depo kendi '
                      'cümlesini uyduruyor');
              withText++;
            } else {
              expect(m, isA<TeachMaterialNone>(),
                  reason: '${l.id} materyalsiz ama YOKLUK demiyor — '
                      'boşluk sessizce dolduruluyor');
              withoutText++;
            }
          }
        }
      }
      expect(withText, greaterThan(0),
          reason: 'hiçbir ders metin taşımıyor — J-118 geri alınmış');
      expect(withoutText, greaterThan(0),
          reason: 'her ders metin taşıyor: bu test artık YOKLUK dalını '
              'ölçmüyor (vakum-doğru). Ya kapsamı değiştir ya da yokluk '
              'dalının ayrı bir kanıtını yaz.');
    });

    test('BİLİNMEYEN ders: yokluk döner ama SEBEBİ farklı', () {
      // İki durum ("materyal yok" / "ders yok") aynı cümleye düşerse, saha
      // teşhisi imkânsızlaşır: kullanıcı da geliştirici de hangisi olduğunu
      // bilemez.
      final TeachMaterial missing =
          const ContentRepository().teachMaterialFor(library, 'boyle.bir.ders.yok');
      // ⚠️ MATERYALSİZ bir ders seçiliyor: ilk ders artık metin taşıyor
      // (J-118) ve `TeachMaterialText` dönerdi — o zaman bu test iki
      // YOKLUK sebebini değil, elma ile armudu karşılaştırırdı.
      final Lesson bare = library.disciplines
          .expand((Discipline d) => d.courses)
          .expand((Course c) => c.lessons)
          .firstWhere((Lesson l) => l.teach == null);
      final TeachMaterial normal =
          const ContentRepository().teachMaterialFor(library, bare.id);
      expect(missing, isA<TeachMaterialNone>());
      expect((missing as TeachMaterialNone).reason,
          isNot((normal as TeachMaterialNone).reason));
    });
  });

  group('İÇERİKTEN TÜRETİLEN öğretme metni (J-118)', () {
    // `TeachMaterialText` varyantı J-094'ten beri VARDI ve render
    // ediliyordu — ama hiçbir yer onu ÜRETMİYORDU: 17 canlı dersin
    // 17'sinde de öğretme aşaması boştu. Beyan ("yapmadık") dürüsttü,
    // boşluk gerçekti. Bu grup boşluğun kapandığını ve KAPANMAYAN yerin
    // hâlâ dürüst kaldığını birlikte ölçüyor.

    test('Foundations derslerinin HEPSİ metin taşıyor', () async {
      final ({Library library, RuleSet boxing}) c =
          await const ContentRepository().load();
      final List<Lesson> foundations = c.library.disciplines
          .firstWhere((Discipline d) => d.id == 'boxing')
          .courses
          .firstWhere((Course k) => k.id == 'boxing.foundations')
          .lessons;
      expect(foundations, isNotEmpty);
      for (final Lesson l in foundations) {
        final TeachMaterial m =
            const ContentRepository().teachMaterialFor(c.library, l.id);
        expect(m, isA<TeachMaterialText>(),
            reason: '${l.id} öğretme aşaması hâlâ boş');
        expect((m as TeachMaterialText).body.trim().length,
            greaterThan(200),
            reason: '${l.id} metni bir cümlelik yer tutucu — öğretme '
                'aşamasını "dolu" göstermek onu doldurmaktan kolaydır');
      }
    });

    test('METNİ OLMAYAN ders hâlâ DÜRÜST hâl döndürüyor', () async {
      // ⭐ NEGATİF İKİZ. Bu olmadan yukarıdaki test, `teachMaterialFor`
      // her derse aynı metni dönse bile geçerdi — ve boşluğun dürüst
      // beyanı sessizce kaybolurdu (ders #4: yapısal doldurma, yokluk
      // iddialarını vakum-doğru yapar).
      final ({Library library, RuleSet boxing}) c =
          await const ContentRepository().load();
      final Lesson noMaterial = c.library.disciplines
          .expand((Discipline d) => d.courses)
          .expand((Course k) => k.lessons)
          .firstWhere((Lesson l) => l.teach == null,
              orElse: () => throw StateError(
                  'her dersin metni var — bu test artık bir şey ölçmüyor, '
                  'ya sil ya da kapsamı değiştir'));
      expect(
          const ContentRepository()
              .teachMaterialFor(c.library, noMaterial.id),
          isA<TeachMaterialNone>());
    });

    test('öğretme metni ÜRÜNÜN ÖLÇÜLMÜŞ SINIRLARINI tekrarlıyor', () async {
      // J-112 sınıfı: en iyi içerik kod-gerçeğine dayalı olandır. Bu test
      // metnin GÜZEL olduğunu ölçemez — ölçtüğü şey, ürünün başka yerde
      // beyan ettiği sınırların öğretme dilinde de GEÇTİĞİ. Sınır
      // değişirse bu metinler de bayatlar ve bunu bilerek bağlıyorum.
      final ({Library library, RuleSet boxing}) c =
          await const ContentRepository().load();
      String bodyOf(String id) => (const ContentRepository()
              .teachMaterialFor(c.library, id) as TeachMaterialText)
          .body
          .toLowerCase();

      expect(bodyOf('boxing.foundations.camera'), contains('do not measure'),
          reason: 'kamera dersi ışığı ölçmediğimizi söylemiyor — oysa '
              'cue.low_light tam bu yüzden silindi');
      expect(bodyOf('boxing.foundations.stance'), contains('do not put a number'),
          reason: 'duruş dersi gard elinin puanlanmadığını söylemiyor — '
              'config coachedOnlyJoints kovasında (J-113)');
      expect(bodyOf('boxing.foundations.cross'), contains('not force'),
          reason: 'cross dersi kuvveti ölçmediğimizi söylemiyor');
    });
  });
}
