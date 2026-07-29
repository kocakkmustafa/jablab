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
      note: 'Recorded time does not unlock lessons yet.',
    );
    expect(find.byKey(const Key('recorded-note')), findsOneWidget);
  });

  group('RecordedSummary', () {
    SessionRecord rec({int worked = 540, int rounds = 3, int planned = 3}) =>
        SessionRecord(
          lessonId: 'x',
          completedAt: DateTime.utc(2026, 7, 30),
          workedSeconds: worked,
          roundsCompleted: rounds,
          plannedRounds: planned,
        );

    test('süre etiketi SANİYE göstermez', () {
      // Antrenman süresinde saniye hassasiyeti bilgi taşımaz, yalnız
      // kesinlik izlenimi verir.
      expect(
          const RecordedSummary(sessions: 1, completed: 1, workedSeconds: 545)
              .workedLabel,
          '9 min');
      expect(
          const RecordedSummary(sessions: 1, completed: 1, workedSeconds: 3600)
              .workedLabel,
          '1h');
      expect(
          const RecordedSummary(sessions: 1, completed: 1, workedSeconds: 5040)
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
  _MemStore(this._all);

  final List<SessionRecord> _all;

  @override
  Future<void> append(SessionRecord record) async => _all.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => _all;

  @override
  Future<int> workedSecondsFor(String lessonId) async {
    int t = 0;
    for (final SessionRecord r in _all) {
      if (r.lessonId == lessonId) t += r.workedSeconds;
    }
    return t;
  }
}
