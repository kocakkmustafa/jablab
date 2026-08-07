import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/shell_candidate/shell_scaffold.dart';

/// F-4 (J-066): ilerleme sayfasında KAYDEDİLEN olgu ile SUSAN hüküm ayrımı.
///
/// K8/M-F-04 kalibrasyonsuz SKORU yasaklar; süre ve seans sayısı skor
/// DEĞİLDİR (kameradan bağımsız ölçülür). Ama ikisi aynı listede görünürse
/// kullanıcı olguyu ("24 dakika çalıştın") hükümle ("gardın iyi") aynı
/// otoritede okur — bu yüzden AYRI bölümde duruyorlar ve testte de öyle
/// zorlanıyor.
void main() {
  Future<void> pumpProgress(
    WidgetTester t, {
    Map<String, String> recorded = const <String, String>{},
    String? note,
    String? unavailable,
    String? incomplete,
  }) async {
    await t.pumpWidget(MaterialApp(
      // `ListTile` bir Material ata ister; gerçek uygulamada bunu
      // `ShellScaffold` sağlıyor.
      home: Scaffold(
          body: ProgressPage(
        bands: const <String, String>{
          'Guard discipline': '—',
          'Punch mechanics': '—',
        },
        recorded: recorded,
        recordedNote: note,
        historyUnavailable: unavailable,
        historyIncomplete: incomplete,
      )),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('kayıt YOKKEN "kaydedilenler" bölümü HİÇ görünmez',
      (WidgetTester t) async {
    // Sıfır satırlık bir tablo, hiç seans yapmamış kullanıcıya boş bir
    // vitrin göstermek olurdu.
    await pumpProgress(t);
    expect(find.byKey(const Key('recorded-heading')), findsNothing);
    expect(find.byKey(const Key('recorded-vs-judged-note')), findsNothing);
    expect(find.byKey(const Key('bands-only-note')), findsOneWidget,
        reason: 'hüküm bölümünün susma gerekçesi her hâlde durmalı');
  });

  testWidgets('kayıt VARKEN olgu bölümü AYRI ve "hüküm değil" diyor',
      (WidgetTester t) async {
    await pumpProgress(t, recorded: <String, String>{
      'Time worked': '24 min',
      'Sessions': '3 recorded',
    });
    expect(find.byKey(const Key('recorded-heading')), findsOneWidget);
    expect(find.byKey(const Key('recorded-vs-judged-note')), findsOneWidget);
    expect(find.byKey(const Key('recorded-Time worked')), findsOneWidget);
    // Hüküm bantları HÂLÂ susuyor — olgu geldi diye hüküm konuşmaya
    // başlamamalı.
    expect(find.byKey(const Key('band-Guard discipline')), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('K8: olgu bölümü ÇIPLAK SAYI sızdırmıyor',
      (WidgetTester t) async {
    // Kapıyı kendi rahatım için gevşetmemek: değerler birimiyle yazılır.
    await pumpProgress(t, recorded: <String, String>{
      'Time worked': '1h 24m',
      'Sessions': '7 recorded, 2 stopped early',
    });
    for (final Text w in t.widgetList<Text>(find.byType(Text))) {
      final String s = (w.data ?? '').trim();
      expect(RegExp(r'^\d{1,3}%?$').hasMatch(s), isFalse,
          reason: 'çıplak sayı sızdı: "$s"');
    }
  });

  testWidgets('kaydın NE İŞE YARAMADIĞI yazılı', (WidgetTester t) async {
    // Biriken süreyi görüp hiçbir şeyin açılmadığını fark eden kullanıcı
    // sebebini burada bulmalı; yoksa sessizlik "bozuk" diye okunur.
    await pumpProgress(
      t,
      recorded: <String, String>{'Time worked': '24 min'},
      note: 'Recorded time does not unlock lessons.',
    );
    expect(find.byKey(const Key('recorded-note')), findsOneWidget);
  });

  group('⭐ J-092 — "hiç yapmadın" ≠ "bilmiyorum" (M-F-209, Gravita G-102)', () {
    testWidgets('geçmiş okunamadıysa bölüm ÇİZİLİR ve sayı YERİNE beyan var',
        (WidgetTester t) async {
      // Kusurun kendisi buydu: `openStore()` patlayınca özet hiç gelmiyor,
      // `recorded` boş kalıyor ve bölüm HİÇ çizilmiyordu — ekran, hiç
      // antrenman yapmamış kullanıcınınkiyle birebir aynı görünüyordu.
      await pumpProgress(t,
          unavailable: 'We could not read your saved sessions on this device.');
      expect(find.byKey(const Key('recorded-heading')), findsOneWidget);
      expect(find.byKey(const Key('recorded-unavailable')), findsOneWidget);
      // Sayı satırı YOK: bilmediğimizi sıfır yazmayız.
      expect(find.byKey(const Key('recorded-Time worked')), findsNothing);
      expect(find.byKey(const Key('recorded-note')), findsNothing,
          reason: '"kaydedilen süre ders açmıyor" notu, kaydedilen süre '
              'okunamazken anlamsız — söyleyecek sayı yok');
    });

    testWidgets('POZİTİF İKİZ: geçmiş SAĞLAMKEN beyan YOK, sayılar VAR',
        (WidgetTester t) async {
      // Gotcha #5: yukarıdaki "X yok" iddiaları, o anahtarlar hiç
      // çizilmiyorsa da geçerdi. Bu ikiz o boşluğu kapatıyor.
      await pumpProgress(t,
          recorded: <String, String>{'Time worked': '24 min'},
          note: 'Recorded time does not unlock lessons.');
      expect(find.byKey(const Key('recorded-unavailable')), findsNothing);
      expect(find.byKey(const Key('recorded-Time worked')), findsOneWidget);
      expect(find.byKey(const Key('recorded-note')), findsOneWidget);
    });

    testWidgets('beyan hiçbir SAYI göstermiyor', (WidgetTester t) async {
      await pumpProgress(t,
          unavailable: 'We could not read your saved sessions on this device.');
      final RegExp anyCount =
          RegExp(r'\b\d+\s*(min|h|m|sessions?|recorded)\b', caseSensitive: false);
      for (final Text w in t.widgetList<Text>(find.byType(Text))) {
        expect(anyCount.hasMatch(w.data ?? ''), isFalse,
            reason: 'geçmiş okunamazken sayı gösterildi: "${w.data}"');
      }
    });

    testWidgets('KISMİ kayıp: sayılar VAR ama ALT SINIR olduğu SATIRLARDAN '
        'ÖNCE söyleniyor', (WidgetTester t) async {
      // JabLab deltası: depo bozuk satırı bilerek atlıyor, yani "hiç
      // yapmadın"ın yanında bir de "az yaptın" yalanı mümkün.
      await pumpProgress(t,
          recorded: <String, String>{'Time worked': '24 min'},
          incomplete: 'Some saved sessions could not be read (2 of them).');
      expect(find.byKey(const Key('recorded-incomplete')), findsOneWidget);
      expect(find.byKey(const Key('recorded-Time worked')), findsOneWidget);

      // Sıra iddiası: nitelik, nitelediği sayıdan ÖNCE okunmalı. Altında
      // dursaydı kullanıcı toplamı önce tam sanar, sonra düzeltirdi.
      final double caveatY =
          t.getTopLeft(find.byKey(const Key('recorded-incomplete'))).dy;
      final double rowY =
          t.getTopLeft(find.byKey(const Key('recorded-Time worked'))).dy;
      expect(caveatY, lessThan(rowY));
    });

    testWidgets('POZİTİF İKİZ: kayıp YOKKEN kısmi-beyan çizilmiyor',
        (WidgetTester t) async {
      await pumpProgress(t,
          recorded: <String, String>{'Time worked': '24 min'});
      expect(find.byKey(const Key('recorded-incomplete')), findsNothing);
      expect(find.byKey(const Key('recorded-Time worked')), findsOneWidget);
    });

    testWidgets('beyan varken satır YOLU KAPALI — ikisi aynı anda çizilemez',
        (WidgetTester t) async {
      // "Okuyamadım" ile bir sayı listesi aynı ekranda dururlarsa hangisine
      // inanılacağı belirsiz kalır; yapı bunu mümkün kılmamalı.
      await pumpProgress(t,
          unavailable: 'We could not read your saved sessions.',
          recorded: <String, String>{'Time worked': '24 min'},
          incomplete: 'partial');
      expect(find.byKey(const Key('recorded-unavailable')), findsOneWidget);
      expect(find.byKey(const Key('recorded-Time worked')), findsNothing);
      expect(find.byKey(const Key('recorded-incomplete')), findsNothing);
    });
  });

  group('RecordedSummary', () {
    SessionRecord rec({int worked = 540, int rounds = 3, int planned = 3}) =>
        SessionRecord(
          lessonId: 'x',
          completedAt: DateTime.utc(2026, 7, 30),
          workedSeconds: worked,
          unitsCompleted: rounds,
          plannedUnits: planned,
          unitLabel: 'round',
          lessonClass: 'unscored',
        );

    test('süre etiketi SANİYE göstermez', () {
      // Antrenman süresinde saniye hassasiyeti bilgi taşımaz, yalnız
      // kesinlik izlenimi verir.
      expect(
          const RecordedSummary(
                  sessions: 1,
                  completed: 1,
                  workedSeconds: 545,
                  status: HistoryOk())
              .workedLabel,
          '9 min');
      expect(
          const RecordedSummary(
                  sessions: 1,
                  completed: 1,
                  workedSeconds: 3600,
                  status: HistoryOk())
              .workedLabel,
          '1h');
      expect(
          const RecordedSummary(
                  sessions: 1,
                  completed: 1,
                  workedSeconds: 5040,
                  status: HistoryOk())
              .workedLabel,
          '1h 24m');
    });

    test('yarıda bırakılan seans SAYILIR ve ayırt edilir', () async {
      final _MemStore s = _MemStore(<SessionRecord>[
        rec(),
        rec(worked: 200, rounds: 1, planned: 6),
      ]);
      final RecordedSummary sum = await RecordedSummary.from(s);
      expect(sum.sessions, 2);
      expect(sum.completed, 1);
      expect(sum.stoppedEarly, 1);
      expect(sum.workedSeconds, 740,
          reason: 'yarıda bırakılanın çalışma süresi de sayılır — yapılan iş '
              'yapılmıştır');
    });

    test('okunamayan kayıt özete TAŞINIYOR ve özet KISMİ işaretleniyor',
        () async {
      final RecordedSummary sum = await RecordedSummary.from(
          _MemStore(<SessionRecord>[rec()], unreadable: 2));
      expect(sum.sessions, 1);
      expect(sum.status, isA<HistoryPartial>());
      expect((sum.status as HistoryPartial).unreadable, 2,
          reason: 'gösterilen toplam bir ölçüm değil ALT SINIR');
    });

    test('POZİTİF İKİZ: kayıp yokken özet KISMİ DEĞİL', () async {
      final RecordedSummary sum =
          await RecordedSummary.from(_MemStore(<SessionRecord>[rec()]));
      expect(sum.status, isA<HistoryOk>(),
          reason: 'sıfır kayıplı "kısmi" beyanı yalandır (doc-75/1)');
    });

    test('boş depoda her şey sıfır, patlamıyor', () async {
      final RecordedSummary sum =
          await RecordedSummary.from(_MemStore(<SessionRecord>[]));
      expect(sum.sessions, 0);
      expect(sum.workedSeconds, 0);
      expect(sum.workedLabel, '0 min');
    });
  });
}

class _MemStore implements SessionStore {
  _MemStore(this._all, {int unreadable = 0}) : _unreadable = unreadable;

  final List<SessionRecord> _all;
  final int _unreadable;

  @override
  Future<void> append(SessionRecord record) async => _all.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => _all;

  @override
  Future<int> unreadableRecords() async => _unreadable;

  @override
  Future<int> workedSecondsFor(String lessonId) async {
    int t = 0;
    for (final SessionRecord r in _all) {
      if (r.lessonId == lessonId) t += r.workedSeconds;
    }
    return t;
  }
}
