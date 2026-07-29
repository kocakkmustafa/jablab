import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/jablab_app.dart';

/// G5 iskelet testleri.
///
/// Bu testlerin amacı "widget çiziliyor mu" değil — **dürüstlük kurallarının
/// UI'da da tutulduğunu** kanıtlamak. Kurallar config'de ve motorda zaten
/// zorlanıyor; ilk ekran tasarımında delinen tam olarak bu tür sözlerdir.
void main() {
  setUp(() {
    // Varsayılan test yüzeyi (800×600) 8 disiplini ve uzun ders listelerini
    // kadraja sığdırmıyor; kaydırma jimnastiği yerine yüzeyi büyütüyoruz.
    // Bu bir "testi geçirme" hilesi değil: sınadığımız şey yerleşim değil,
    // içerik kurallarının tutup tutmadığı.
    final TestWidgetsFlutterBinding b = TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(1200, 3000);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding b = TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // Asset yükleme GERÇEK async I/O'dur; widget test'inin sanal saati onu
    // ilerletmez. runAsync olmadan içerik hiç gelmez, yükleme göstergesi
    // ekranda kalır ve pumpAndSettle (sonsuz animasyon yüzünden) zaman aşımına
    // uğrar — sabit bir gecikmeyle "çözmek" yarış durumu üretirdi.
    await tester.runAsync(() async {
      await tester.pumpWidget(const JabLabApp());
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('içerik dürüstlük denetiminden geçerek yüklenir', (WidgetTester t) async {
    await pumpApp(t);
    // ContentRepository, library.validate() başarısız olursa fırlatır.
    expect(find.byKey(const Key('content-error')), findsNothing);
    expect(find.byKey(const Key('today-heading')), findsOneWidget);
  });

  testWidgets('kütüphane 8 disiplini de gösterir — kapsam baştan görünür',
      (WidgetTester t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('tab-library')));
    await t.pumpAndSettle();

    for (final String id in <String>['boxing', 'kickboxing', 'tai_chi',
      'karate', 'muay_thai', 'taekwondo', 'mma_striking', 'wing_chun']) {
      expect(find.byKey(Key('item-$id')), findsOneWidget, reason: id);
    }
    // 7'sinde "yakında" rozeti, Boxing'de yok.
    expect(find.byKey(const Key('soon-boxing')), findsNothing);
    expect(find.byKey(const Key('soon-kickboxing')), findsOneWidget);
  });

  testWidgets('"yakında" disiplinde KURS GÖSTERİLMEZ', (WidgetTester t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('tab-library')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('item-tai_chi')));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('coming-soon-note')), findsOneWidget);
    expect(find.text('Courses'), findsNothing,
        reason: 'açılmamış disiplinde kurs başlığı bile görünmemeli');
    // Dürüstlük kutusu yine de zorunlu.
    expect(find.text("What it doesn't"), findsOneWidget);
  });

  testWidgets('canlı disiplinde kurs → ders → seans zinciri yürür',
      (WidgetTester t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('tab-library')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();

    expect(find.text('Courses'), findsOneWidget);
    expect(find.byKey(const Key('course-boxing.foundations')), findsOneWidget);

    await t.tap(find.byKey(const Key('course-boxing.foundations')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('lesson-boxing.foundations.jab')), findsOneWidget);

    await t.tap(find.byKey(const Key('lesson-boxing.foundations.jab')));
    await t.pumpAndSettle();
    // Ders akışı öğret→dene→canlı→özet sırasıyla açılır.
    expect(find.byKey(const Key('stage-teach')), findsOneWidget);
    expect(find.byKey(const Key('teach-no-analysis')), findsOneWidget,
        reason: 'öğrenme aşamasında analiz YAPILMADIĞI söylenmeli');
  });

  testWidgets('seans akışı: öğret → dene → canlı → özet', (WidgetTester t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('tab-library')));
    await t.pumpAndSettle();
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
    expect(find.byKey(const Key('coached-not-scored-note')), findsOneWidget);
    expect(find.textContaining('Guard hand position'), findsOneWidget);
  });

  testWidgets('[J-038] KİLİTLİ ders görünür ama AÇILMAZ, sebebi yazılı',
      (WidgetTester t) async {
    // Kilitli dersi gizlemek kapsamı saklardı; açmak ölçemediğimiz bir
    // beceriye seans vermek olurdu. Üçüncü yol: göster, açma, sebebini yaz.
    await pumpApp(t);
    await t.tap(find.byKey(const Key('tab-library')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.intermediate')));
    await t.pumpAndSettle();

    const String locked = 'boxing.intermediate.counter';
    expect(find.byKey(const Key('lesson-$locked')), findsOneWidget,
        reason: 'kilitli ders listeden gizlenmiş — kapsam saklanıyor');
    expect(find.byKey(const Key('locked-why-$locked')), findsOneWidget,
        reason: 'kilit sebepsiz — "yakında" rozetine dönüşmüş');

    await t.tap(find.byKey(const Key('lesson-$locked')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('stage-teach')), findsNothing,
        reason: 'kilitli ders seans açtı — ölçemediğimiz beceriye hüküm yolu');
  });

  testWidgets('K8: ilerleme sayfası SAYI göstermez, bant gösterir',
      (WidgetTester t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('tab-progress')));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('bands-only-note')), findsOneWidget);
    expect(find.byKey(const Key('band-Guard discipline')), findsOneWidget);
    // Kalibrasyon kapısı geçilmeden hiçbir sayısal skor render edilmemeli.
    final Iterable<Text> texts = t.widgetList<Text>(find.byType(Text));
    for (final Text w in texts) {
      final String s = w.data ?? '';
      expect(RegExp(r'^\d{1,3}%?$').hasMatch(s.trim()), isFalse,
          reason: 'kalibrasyonsuz sayısal skor sızdı: "$s"');
    }
  });

  testWidgets('"Neden yok?" sayfası gerekçeleriyle açılır',
      (WidgetTester t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('tab-library')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('why-not-button')));
    await t.pumpAndSettle();

    expect(find.text('Brazilian Jiu-Jitsu'), findsOneWidget);
    expect(find.text('Punch power'), findsOneWidget);
    expect(find.textContaining('sensor'), findsWidgets,
        reason: 'güç ölçümünün neden yapılamadığı açıkça yazılmalı');
  });

  testWidgets('fiyat sabit yazılmamış — kurucu kararı', (WidgetTester t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('tab-profile')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('pricing-not-set')), findsOneWidget);
  });
}
