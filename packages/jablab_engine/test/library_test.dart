import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Library loadLibrary() {
  final File f = File('../../assets/content/library.json');
  return Library.fromJson(
      (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>());
}

void main() {
  final Library lib = loadLibrary();
  final RuleSet boxing = loadBoxingRuleSet();
  final Map<String, RuleSet> ruleSets = <String, RuleSet>{'boxing': boxing};

  group('Kütüphane IA', () {
    test('blueprint kapsamı: her disiplin ya CANLI ya İSİMLİ GEREKÇELİ', () {
      // ÖZNE DEĞİL ÖZELLİK (Choreia dersi, J-189). Bu test önce
      // `disciplines.length == 8` diyordu ve o **sayı-bağlı** bir iddiaydı:
      // dokuzuncu bir disiplin eklendiği gün test **mümkün olan en iyi
      // sebeple** düşerdi (içerik geldi), ve düştüğü an "iyi haber" olacağı
      // için yerine 9 yazılıp geçilirdi — kusuru çözmek değil, **bir
      // sonraki disiplinin arkasına kuyruklamak.**
      //
      // Sayı KALDI ama artık **iddia değil, vakum muhafızı**: kütüphane
      // boşalırsa aşağıdaki "hepsi gerekçeli" döngüsü **hiçbir şey
      // ölçmeden** yeşil kalırdı.
      expect(lib.disciplines.length, greaterThanOrEqualTo(8),
          reason: 'disiplin sayısı ${lib.disciplines.length} — kütüphane '
              'küçülmüş; bu bir İÇERİK KAYBI ve sebebi araştırılmalı');

      // ASIL İDDİA: kapalı olan her disiplin NEDEN kapalı olduğunu söyler.
      // "Yakında" demek yasak; mühendislik sebebi vermek zorunlu.
      for (final Discipline d in lib.disciplines) {
        if (lib.live.contains(d)) continue;
        expect(d.blurb.trim().length, greaterThan(60),
            reason: '${d.id}: kapalı ama gerekçesi ${d.blurb.trim().length} '
                'karakter — bu bir MÜHENDİSLİK SEBEBİ taşıyamayacak kadar '
                'kısa. Kullanıcı kısa bir gerekçeyi "bir gün belki" diye '
                'okur, ve bu ürünün tamamı o okumaya karşı yazıldı. '
                '(Ölçüldü: bugünkü 7 gerekçenin en kısası bile bunun '
                'üstünde ve en yüksek ikili benzerlik 0.38 — şablon yok.)');
      }
      expect(lib.live.map((Discipline d) => d.id), <String>['boxing']);
      // Kapsamın TAMAMI kullanıcıya baştan görünür — dar app algısı yaratılmaz.
      expect(lib.disciplines.map((Discipline d) => d.id),
          containsAll(<String>['kickboxing', 'tai_chi', 'karate', 'muay_thai',
            'taekwondo', 'mma_striking', 'wing_chun']));
    });

    test('DÜRÜSTLÜK DEĞİŞMEZLERİ — sahte kurs, boş kurs, hayalet teknik yok',
        () {
      // Tek test, beş kuralı birden zorlar. İhlal = kullanıcıya verilmiş
      // somut bir sözün çiğnenmesi, bu yüzden uyarı değil hata.
      expect(lib.validate(ruleSets), isEmpty);
    });

    test('"yakında" disiplinlerin kursu YOK', () {
      for (final Discipline d in lib.disciplines) {
        if (d.status == DisciplineStatus.comingSoon) {
          expect(d.courses, isEmpty, reason: '${d.id} sahte kurs listeliyor');
        }
      }
    });

    test('her disiplin "neler ÖLÇÜLMEZ" kutusu taşır', () {
      for (final Discipline d in lib.disciplines) {
        expect(d.notMeasured, isNotEmpty, reason: d.id);
      }
    });

    test('canlı disiplinin dersleri gerçek tekniklere bağlı', () {
      final Discipline boxingD = lib.live.first;
      final Set<String> referenced = <String>{
        for (final Course c in boxingD.courses)
          for (final Lesson l in c.lessons) ...l.techniques,
      };
      expect(referenced, isNotEmpty);
      for (final String t in referenced) {
        expect(boxing.technique(t), isNotNull,
            reason: 'ders var olmayan tekniğe atıf yapıyor: $t');
      }
      // V1 kapsamı: hook/uppercut form hükmü YOK — ders de olmamalı.
      expect(referenced, isNot(contains('unclassified_strike')));
    });

    test('"Neden yok?" sayfası gerekçesiz madde içermez', () {
      expect(lib.excluded.length, greaterThanOrEqualTo(5));
      for (final ExcludedItem x in lib.excluded) {
        expect(x.reason.length, greaterThan(20), reason: x.id);
      }
      expect(lib.excluded.map((ExcludedItem x) => x.id),
          containsAll(<String>['bjj', 'wrestling', 'judo', 'weapon_arts']));
    });

    test('güç ölçümü açıkça kapsam-dışı ilan edilmiş', () {
      // 00-AILE-MIMARISI §7 + plan §14: ölçemediğimiz şeyi ölçüyormuş gibi
      // sunmayız. Bu, pazarlamaya sızması en kolay iddia.
      final ExcludedItem power =
          lib.excluded.firstWhere((ExcludedItem x) => x.id == 'power_measurement');
      expect(power.reason.toLowerCase(), contains('sensor'));

      final Discipline boxingD = lib.live.first;
      expect(boxingD.notMeasured.join(' ').toLowerCase(),
          contains('force'));
    });
  });
}
