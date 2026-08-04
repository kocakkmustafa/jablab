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

    test('BUGÜN hiçbir derste materyal YOK — ve bu ölçülen bir olgu', () {
      // Varsayım değil: `Lesson` modelinde materyal alanı bulunmuyor.
      // Kütüphanedeki HER ders tek tek soruluyor ki, biri sessizce materyal
      // kazandığında bu test kırılsın ve ekran yolu unutulmasın.
      int lessons = 0;
      for (final Discipline d in library.disciplines) {
        for (final Course c in d.courses) {
          for (final Lesson l in c.lessons) {
            lessons++;
            expect(
                const ContentRepository().teachMaterialFor(library, l.id),
                isA<TeachMaterialNone>(),
                reason: '${l.id} materyal kazanmış — ekran yolu bağlanmalı');
          }
        }
      }
      expect(lessons, greaterThan(0),
          reason: 'kütüphane boş okunmuş; yukarıdaki döngü hiç koşmadı');
    });

    test('BİLİNMEYEN ders: yokluk döner ama SEBEBİ farklı', () {
      // İki durum ("materyal yok" / "ders yok") aynı cümleye düşerse, saha
      // teşhisi imkânsızlaşır: kullanıcı da geliştirici de hangisi olduğunu
      // bilemez.
      final TeachMaterial missing =
          const ContentRepository().teachMaterialFor(library, 'boyle.bir.ders.yok');
      final TeachMaterial normal = const ContentRepository()
          .teachMaterialFor(library, library.disciplines.first.courses.first.lessons.first.id);
      expect(missing, isA<TeachMaterialNone>());
      expect((missing as TeachMaterialNone).reason,
          isNot((normal as TeachMaterialNone).reason));
    });
  });
}
