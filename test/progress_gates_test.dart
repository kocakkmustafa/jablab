import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/progress_gates.dart';
import 'package:jablab/app/session_store.dart';

/// İLERLEME KAPISI DEĞERLENDİRİCİSİ (J-208) — kapı sisteminin eksik
/// TÜKETİCİSİ, ve bugün NE ÖLÇEBİLDİĞİ.
///
/// ## Bu dosyanın en önemli testi POZİTİF İKİZ
///
/// Değerlendirici bugün dört kapının dördünde de *"değerlendirilemez"*
/// diyor — çünkü kanıt kalıcı katmanda yok. **Yalnız bunu sınayan bir süit,
/// hiçbir şey kanıtlamaz:** her zaman `GateNotEvaluable` dönen BOZUK bir
/// değerlendirici de o testi geçerdi (M-F-236 sınıfı: koşulsuz davranan bir
/// yüzey diğer bütün testleri geçer). Bu yüzden mekanizmanın kanıt VARKEN
/// gerçek sayı döndürdüğü ayrıca sınanıyor.
void main() {
  final Map<String, dynamic> curriculum =
      (jsonDecode(File('assets/content/curriculum.json').readAsStringSync())
              as Map)
          .cast<String, dynamic>();

  group('POZİTİF İKİZ — kanıt VARSA mekanizma gerçek sayı üretiyor', () {
    test('gereken karşılanınca GEÇTİ', () {
      final GateVerdict? v = evaluateEventGate(
          curriculum, 'boxing.foundations.jab', _Fake(<String, int?>{'jab': 35}));
      expect(v, isA<GatePassed>());
      expect((v! as GatePassed).measured, 35);
      expect((v as GatePassed).required, 30);
    });

    test('gereken karşılanmayınca İLERLEME — ve sayı GERÇEK', () {
      final GateVerdict? v = evaluateEventGate(
          curriculum, 'boxing.foundations.jab', _Fake(<String, int?>{'jab': 12}));
      expect(v, isA<GateProgress>());
      expect((v! as GateProgress).measured, 12);
    });

    test('ÖLÇÜLMÜŞ SIFIR meşru — ve "değerlendirilemez" DEĞİL', () {
      // İki hâl birbirinin yerine geçemez (doc-75/5): "ölçtük, hiç yoktu"
      // ile "ölçmedik" ayrı cümleler.
      final GateVerdict? v = evaluateEventGate(
          curriculum, 'boxing.foundations.jab', _Fake(<String, int?>{'jab': 0}));
      expect(v, isA<GateProgress>());
      expect(v, isNot(isA<GateNotEvaluable>()));
      expect((v! as GateProgress).measured, 0);
    });

    test('guard/range AYNI olayı (jab) sayıyor ama EŞİĞİ farklı', () {
      // 35 jab: `jab` kapısını (30) geçer, `guard`/`range` kapısını (40)
      // geçmez. Tek kanıtla üç farklı sonuç — eşiğin gerçekten okunduğunu
      // gösterir, sabit bir cevabın değil.
      final _Fake e = _Fake(<String, int?>{'jab': 35});
      expect(evaluateEventGate(curriculum, 'boxing.foundations.jab', e),
          isA<GatePassed>());
      expect(evaluateEventGate(curriculum, 'boxing.foundations.guard', e),
          isA<GateProgress>());
      expect(evaluateEventGate(curriculum, 'boxing.foundations.range', e),
          isA<GateProgress>());
    });

    test('GateProgress, geçmiş bir sayıyla KURULAMAZ (tip düzeyi)', () {
      expect(() => GateProgress(measured: 30, required: 30), throwsA(anything));
    });
  });

  group('BUGÜNKÜ GERÇEK — dört kapı da DEĞERLENDİRİLEMİYOR', () {
    const List<String> gateLessons = <String>[
      'boxing.foundations.jab',
      'boxing.foundations.cross',
      'boxing.foundations.guard',
      'boxing.foundations.range',
    ];

    for (final String id in gateLessons) {
      test('$id — kanıt saklanmıyor, SAYI ÜRETİLMİYOR', () {
        final GateVerdict? v = evaluateEventGate(
            curriculum, id, const RecordedGateEvidence(<SessionRecord>[]));
        expect(v, isA<GateNotEvaluable>(),
            reason: 'İYİ HABER olabilir: kanıt kalıcı katmana geldiyse bu '
                'kapı artık gerçek sayı üretiyor demektir — J-208 beyanını, '
                'ADR ve devir notunu güncelle.');
        // Sebep ADIYLA taşınıyor: sessiz bir "değerlendirilemez" bir sonraki
        // turu "neden?" diye kaynağa göndermek zorunda bırakırdı.
        expect((v! as GateNotEvaluable).reason, contains('J-208'));
        expect((v as GateNotEvaluable).event, isNotEmpty);
      });
    }
  });

  group('KAPSAM SINIRI — kapsam dışı kapı "geçilemedi" diye raporlanmıyor', () {
    // Koordinatör sınırı: yalnız olay-sayımı. Diğer üç sınıfa dokunulmuyor,
    // ve dokunulmadığı `null` ile söyleniyor — `false` demek, ölçmediğimiz
    // bir şeye hüküm vermek olurdu.
    const Map<String, String> outOfScope = <String, String>{
      'boxing.foundations.stance': 'minSeconds (stanceHold, üreticisiz)',
      'boxing.foundations.one_two': 'combination (③ COMBINATION_END riski)',
      'boxing.conditioning.r5': 'sessionMinutes + withValidAnalysisRatio',
      'boxing.foundations.camera': 'minOccurrences (setupCheckPassed)',
    };
    outOfScope.forEach((String id, String why) {
      test('$id → null ($why)', () {
        expect(
            evaluateEventGate(
                curriculum, id, _Fake(<String, int?>{'jab': 999})),
            isNull);
      });
    });

    test('tanımsız ders → null, patlamıyor', () {
      expect(
          evaluateEventGate(curriculum, 'yok.boyle.bir.ders', _Fake(const {})),
          isNull);
    });
  });

  test('KAPSAM SAYISI KİLİTLİ — olay-sayımı kapısı tam 4 tane', () {
    // Beşincisi eklenirse bu test öter: yeni kapı bu değerlendiricinin
    // kapsamına GİRER ve o bir ürün kararıdır, sessizce olmamalı.
    final Map<String, dynamic> pr =
        (curriculum['progression'] as Map).cast<String, dynamic>();
    final List<String> eventGates = <String>[
      for (final MapEntry<String, dynamic> e in pr.entries)
        for (final Object? g
            in ((e.value as Map)['gates'] as List<dynamic>? ?? const <dynamic>[]))
          if (g is Map &&
              g['event'] is String &&
              g['minCompletedAttempts'] is int)
            e.key,
    ]..sort();

    expect(eventGates, <String>[
      'boxing.foundations.cross',
      'boxing.foundations.guard',
      'boxing.foundations.jab',
      'boxing.foundations.range',
    ]);
  });

  _reachabilityGate();

  test('⛔ KİLİT DEĞİŞMİYOR — değerlendirici kilit sözlüğüne DOKUNMUYOR', () {
    // Koordinatör sınırı, mekanik olarak zorlanıyor: bu tur ilerlemeyi
    // ÖLÇÜP GÖSTERİYOR, içerik kilidini oynatmıyor. Kaynakta kilit kavramı
    // geçerse bu test öter ve karar bilinçli alınmak zorunda kalır.
    final String src = File('lib/app/progress_gates.dart').readAsStringSync();
    final List<String> offenders = <String>[
      for (final String line in src.split('\n'))
        if (!line.trimLeft().startsWith('///') &&
            !line.trimLeft().startsWith('//') &&
            RegExp(r'\b(locked|lockedReason|unlock)\b').hasMatch(line))
          line.trim(),
    ];
    expect(offenders, isEmpty,
        reason: 'değerlendirici kilit davranışına dokunuyor — bu turda '
            'YASAK (koordinatör sınırı, J-208)');
    // POZİTİF KONTROL: aynı tarama, gerçekten orada olan bir kavramı bulmalı.
    expect(src.contains('GateNotEvaluable'), isTrue,
        reason: 'kaynak okunamadı — yukarıdaki boş sonuç anlamsız olurdu');
  });
}

/// ULAŞILABİLİRLİK — beyanın VARLIĞI, ona GİDEN YOLUN varlığı değildir.
///
/// Kapı beyanı yalnız Sayfa B **giriş yüzeyiyken** (`isCurrent`) çiziliyor,
/// ve o hâl bir SEANS KAYDI gerektiriyor. Foundations kursunda kayıt
/// yazabilen **tek** ders `first_round` — diğer yedisi plansız ve
/// `_record()` onlar için erken dönüyor. Yani bu yüzeye giden gerçek yol
/// TEK, ve dar bir yol test edilmeden "çizilir" sayılamaz (M-F-503).
void _reachabilityGate() {
  testWidgets('KAPI BEYANI GERÇEKTEN ÇİZİLİYOR — first_round yolundan',
      (WidgetTester t) async {
    final _FakeStore store = _FakeStore(<SessionRecord>[
      SessionRecord(
        lessonId: 'boxing.foundations.first_round',
        completedAt: DateTime.utc(2026, 8, 1),
        workedSeconds: 180,
        unitsCompleted: 1,
        plannedUnits: 1,
        unitLabel: 'round',
        lessonClass: 'unscored',
      ),
    ]);
    await t.runAsync(() async {
      await t.pumpWidget(JabLabApp(
          repository: ContentRepository(storeOverride: store),
          onboarding: const OnboardingStore(seenOverride: true)));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await t.pumpAndSettle();

    final Finder note = find.byKey(const Key('gate-note'));
    expect(note, findsOneWidget,
        reason: 'kapı beyanı çizilmiyor — değerlendirici ÖLÜ MEKANİZMA '
            'olur (tüketicisi olmayan bir üretici yazmamak için kurulan '
            'bu turun kendi kusuru)');

    final String text = t.widget<Text>(note).data!;
    // Sayı TÜREVİ: dört olay-sayımı kapısı var, cümle onu taşımalı.
    expect(text, contains('4 lessons'),
        reason: 'beyandaki sayı türetilmiyor ya da kapı kümesi değişti');
    // ⛔ SAYAÇ İDDİASI YOK: "0/30" sınıfı bir sayı sızarsa bu öter.
    expect(RegExp(r'\d+\s*/\s*\d+').hasMatch(text), isFalse,
        reason: 'ölçmediğimiz bir sayacı raporluyoruz (doc-75/2)');
    // Vaat dili yok (M-F-186) — bu yüzey de kapsamda.
    expect(
        RegExp(r'\b(yet|soon|for now|currently not|will be able)\b',
                caseSensitive: false)
            .hasMatch(text),
        isFalse,
        reason: 'kapı beyanı vaat dili taşıyor');
  });

  testWidgets('TEMİZ HÂL SESSİZ — kapısı olmayan kursta beyan ÇİZİLMEZ',
      (WidgetTester t) async {
    // doc-75/6: koşulsuz uyaran bir yüzey diğer bütün testleri geçer.
    // Conditioning kursunun kapıları `sessionMinutes` sınıfı → kapsam dışı →
    // beyan hiç çizilmemeli.
    final _FakeStore store = _FakeStore(<SessionRecord>[
      SessionRecord(
        lessonId: 'boxing.conditioning.r5',
        completedAt: DateTime.utc(2026, 8, 1),
        workedSeconds: 300,
        unitsCompleted: 3,
        plannedUnits: 3,
        unitLabel: 'round',
        lessonClass: 'unscored',
      ),
    ]);
    await t.runAsync(() async {
      await t.pumpWidget(JabLabApp(
          repository: ContentRepository(storeOverride: store),
          onboarding: const OnboardingStore(seenOverride: true)));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await t.pumpAndSettle();
    expect(find.byKey(const Key('gate-note')), findsNothing,
        reason: 'olay-sayımı kapısı OLMAYAN kursta kapı beyanı çiziliyor — '
            'koşulsuz uyaran yüzey');
  });
}

class _FakeStore implements SessionStore {
  _FakeStore(this._records);
  final List<SessionRecord> _records;
  @override
  Future<void> append(SessionRecord record) async => _records.add(record);
  @override
  Future<List<SessionRecord>> recent({int? limit}) async => _records;
  @override
  Future<int> workedSecondsFor(String lessonId) async => 0;
  @override
  Future<int> unreadableRecords() async => 0;
}

/// Sınama kanıtı — `null` da verilebilsin diye değer tipi nullable.
class _Fake implements GateEvidence {
  const _Fake(this.counts);

  final Map<String, int?> counts;

  @override
  int? completedEvents(String event) => counts[event];
}
