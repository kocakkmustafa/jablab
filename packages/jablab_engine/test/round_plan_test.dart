import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:test/test.dart';

/// Tur planı değişmezleri (J-063) — J-062'nin ölçtüğü kusurun kapısı.
///
/// Ölçülen kusur: canlı ekran sabit 3 dakika koşarken 9 süreli dersin 9'u da
/// kendi beyanından farklı çalışıyordu ve HİÇBİR test bunu görmüyordu.
/// Buradaki testler o boşluğu kapatıyor: beyan ile plan arasındaki aritmetik
/// artık mekanik olarak zorlanıyor.
void main() {
  final Map<String, dynamic> libJson =
      (jsonDecode(File('../../assets/content/library.json').readAsStringSync())
              as Map)
          .cast<String, dynamic>();
  final Map<String, dynamic> cfg = (jsonDecode(
              File('../../assets/rulesets/boxing@1.0.0.json').readAsStringSync())
          as Map)
      .cast<String, dynamic>();
  final Library lib = Library.fromJson(libJson);
  final RuleSet boxing = RuleSet.fromJson(cfg);

  List<Lesson> allLessons() => <Lesson>[
        for (final Discipline d in lib.disciplines)
          for (final Course c in d.courses) ...c.lessons,
      ];

  group('RoundPlan aritmetiği', () {
    test('totalSeconds son turdan sonra dinlenme SAYMAZ', () {
      // rounds * (round + rest) yazmak her derse fazladan bir dinlenme
      // ekler ve beyan edilen toplamı sessizce aşar.
      const RoundPlan p = RoundPlan(
        rounds: 3,
        roundSeconds: 180,
        restSeconds: 90,
        planProvenance: 'test',
      );
      expect(p.totalSeconds, 3 * 180 + 2 * 90);
      expect(p.totalSeconds, 720);
      expect(p.totalSeconds, isNot(3 * (180 + 90)));
    });

    test('tek turda toplam = tur süresi', () {
      const RoundPlan p = RoundPlan(
        rounds: 1,
        roundSeconds: 300,
        restSeconds: 0,
        planProvenance: 'test',
      );
      expect(p.totalSeconds, 300);
      expect(p.isSingleRound, isTrue);
    });
  });

  group('içeriğin kendisi', () {
    test('AÇIK her süreli ders plan taşır', () {
      // Plan ÇALIŞMA süresinin doğruluğu `minutes`e karşı DEĞİL, dersin
      // kendi ilerleme kapısına karşı sınanır (`curriculum_binding_test`,
      // J-063) — `minutes` alanının tek bir anlamı yok: r3'te
      // çalışma+dinlenme, r10'da yalnız çalışma, Foundations'ta ders süresi.
      final List<String> checked = <String>[];
      for (final Lesson l in allLessons()) {
        final bool timed = l.focus == 'round' || l.focus == 'conditioning';
        if (!timed || l.isLocked) continue;
        // Ders ya TURLU ya ARALIKLI olabilir; ikisi de "süreyi koşabiliyor"
        // demektir. İkisi BİRDEN olamaz (validate reddediyor) — canlı ekran
        // hangi saati koşacağını bilemezdi.
        expect(l.roundPlan != null || l.intervalPlan != null, isTrue,
            reason: '${l.id}: açık süreli ders ama ne tur ne aralık planı var');
        expect(l.roundPlan != null && l.intervalPlan != null, isFalse,
            reason: '${l.id}: hem tur hem aralık planı taşıyor');
        checked.add(l.id);
      }
      // Testin kendisi boşa dönmesin: sıfır ders kontrol edildiyse yukarıdaki
      // döngü hiçbir şey kanıtlamamıştır.
      expect(checked, isNotEmpty,
          reason: 'hiç açık süreli ders bulunamadı — test kendini kandırıyor');
      expect(checked, contains('boxing.conditioning.r3'));
      expect(checked, contains('boxing.conditioning.r5'));
      expect(checked, contains('boxing.conditioning.r10'));
      expect(checked, contains('boxing.conditioning.r20'));
    });

    test('her plan KAYNAĞINI beyan eder (icat ile taslak ayırt edilebilir)',
        () {
      const Set<String> known = <String>{'arithmetic'};
      for (final Lesson l in allLessons()) {
        final RoundPlan? p = l.roundPlan;
        if (p == null) continue;
        expect(p.planProvenance.trim(), isNotEmpty,
            reason: '${l.id}: planProvenance boş');
        final bool ok = known.contains(p.planProvenance) ||
            p.planProvenance.startsWith('advisor-draft-');
        expect(ok, isTrue,
            reason: '${l.id}: tanınmayan plan kaynağı '
                '"${p.planProvenance}" — kaynak beyanı serbest metin olamaz');
      }
    });

    test('türetilmemiş her SEÇİM sınır beyanı taşır', () {
      // Bugün AÇIK derslerin hepsi `arithmetic`: ilerleme kapıları
      // (`sessionMinutes`) çalışma süresini beyan ettiği için tur süreleri
      // saf aritmetikle çıkıyor ve antrenman-tasarımı taslağına GEREK
      // KALMADI. Ama planların bir kısmı hâlâ türetilmemiş bir seçim taşıyor
      // (dinlenme oranı) — o seçim `$planBoundary` ile İSİMLİ olmalı.
      //
      // "Hiç taslak yok" bir kusur DEĞİL, daha iyi bir durum: bu yüzden
      // burada taslak sayısına alt sınır konmuyor. Ama bir taslak GİRERSE
      // sınır beyanı zorunlu kalır.
      final Map<String, dynamic> boxing = (libJson['disciplines'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((Map<String, dynamic> d) => d['id'] == 'boxing');
      int boundaries = 0;
      for (final dynamic c in boxing['courses'] as List) {
        for (final dynamic raw in (c as Map)['lessons'] as List) {
          final Map<String, dynamic> l = (raw as Map).cast<String, dynamic>();
          final Map<String, dynamic>? p =
              (l['roundPlan'] as Map?)?.cast<String, dynamic>();
          if (p == null) continue;
          final bool isDraft =
              (p['planProvenance'] as String).startsWith('advisor-draft-');
          if (isDraft) {
            expect(p[r'$planBoundary'], isNotNull,
                reason: '${l['id']}: advisor taslağı ama sınır beyanı yok');
          }
          if (p[r'$planBoundary'] != null) {
            boundaries++;
            expect((p[r'$planBoundary'] as String).length, greaterThan(40),
                reason: '${l['id']}: sınır beyanı fazla kısa — türetilmemiş '
                    'bir seçimin neden türetilmediği yazılmalı');
          }
        }
      }
      expect(boundaries, greaterThan(0),
          reason: 'dinlenme oranı seçimi taşıyan ders var ama hiçbiri sınır '
              'beyan etmiyor — test kendini kandırıyor');
    });

    test('her planın dayanağı YAZILI', () {
      final Map<String, dynamic> boxing = (libJson['disciplines'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((Map<String, dynamic> d) => d['id'] == 'boxing');
      for (final dynamic c in boxing['courses'] as List) {
        for (final dynamic raw in (c as Map)['lessons'] as List) {
          final Map<String, dynamic> l = (raw as Map).cast<String, dynamic>();
          final Map<String, dynamic>? p =
              (l['roundPlan'] as Map?)?.cast<String, dynamic>();
          if (p == null) continue;
          expect(p[r'$planBasis'], isNotNull,
              reason: '${l['id']}: planın dayanağı yazılmamış');
          expect((p[r'$planBasis'] as String).length, greaterThan(40));
        }
      }
    });

    test('KİLİTLİ her süreli ders sebebini yazar', () {
      int locked = 0;
      for (final Lesson l in allLessons()) {
        if (!l.isLocked) continue;
        locked++;
        expect(l.lockedReason!.trim().length, greaterThan(30),
            reason: '${l.id}: kilit sebebi fazla kısa — sebepsiz kilit '
                'pazarlama rozetine dönüşür');
      }
      expect(locked, greaterThanOrEqualTo(4));
    });
  });

  group('validate KAPISI gerçekten tutuyor mu (kapı sınaması)', () {
    Map<String, dynamic> mutate(
      void Function(Map<String, dynamic> lesson) edit, {
      String lessonId = 'boxing.conditioning.r3',
    }) {
      final Map<String, dynamic> copy =
          jsonDecode(jsonEncode(libJson)) as Map<String, dynamic>;
      for (final dynamic d in copy['disciplines'] as List) {
        for (final dynamic c in ((d as Map)['courses'] as List? ?? const [])) {
          for (final dynamic l in (c as Map)['lessons'] as List) {
            if ((l as Map)['id'] == lessonId) {
              edit(l.cast<String, dynamic>());
            }
          }
        }
      }
      return copy;
    }

    List<String> errsFor(Map<String, dynamic> doc) =>
        Library.fromJson(doc).validate(<String, RuleSet>{'boxing': boxing});

    test('bugünkü içerik TEMİZ (taban çizgisi)', () {
      expect(errsFor(libJson), isEmpty);
    });

    test('süreli ders planını kaybederse REDDEDİLİR', () {
      final Map<String, dynamic> doc =
          mutate((Map<String, dynamic> l) => l.remove('roundPlan'));
      expect(errsFor(doc), contains(contains('TUR PLANI YOK')));
    });

    test('kaynak beyanı silinirse REDDEDİLİR', () {
      final Map<String, dynamic> doc = mutate((Map<String, dynamic> l) {
        (l['roundPlan'] as Map)['planProvenance'] = '  ';
      });
      expect(errsFor(doc), contains(contains('planProvenance')));
    });

    test('tek turlu derse tur ARASI dinlenme konursa REDDEDİLİR', () {
      final Map<String, dynamic> doc = mutate(
        (Map<String, dynamic> l) {
          (l['roundPlan'] as Map)['restSeconds'] = 30;
        },
        lessonId: 'boxing.conditioning.r5',
      );
      expect(errsFor(doc), contains(contains('tek turlu')));
    });

    test('KİLİTLİ ders plansız kalabilir (kilit zaten beyandır)', () {
      final Map<String, dynamic> doc = mutate(
        (Map<String, dynamic> l) => l.remove('roundPlan'),
        lessonId: 'boxing.conditioning.r3',
      );
      // r3'ü kilitle → plansızlık artık kusur değil
      for (final dynamic d in doc['disciplines'] as List) {
        for (final dynamic c in ((d as Map)['courses'] as List? ?? const [])) {
          for (final dynamic l in (c as Map)['lessons'] as List) {
            if ((l as Map)['id'] == 'boxing.conditioning.r3') {
              l['status'] = 'locked';
              l['lockedReason'] =
                  'Bu dersin tur yapısı henüz yazılmadı, bu yüzden kapalı.';
            }
          }
        }
      }
      expect(errsFor(doc), isEmpty);
    });
  });
}
