import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Müfredat değişmezleri.
///
/// **Kanonik sözleşme:** motion-core `docs/50-REFERANS-TUKETIM-SOZLESMESI.md`
/// kural 9 — "skor yalnız SKORLANAN eklemlerden akar".
///
/// İlerleme bir hüküm biçimidir. Kalibre edilmemiş ya da koçlanan-ama-
/// skorlanmayan bir sinyalle **kapı** kurmak, skoru başka adla vermektir; en
/// sinsi hâli de budur, çünkü kullanıcı "ilerleyemedim" der ve nedenini
/// öğrenemez.
void main() {
  Map<String, dynamic> load(String p) =>
      (jsonDecode(File(p).readAsStringSync()) as Map).cast<String, dynamic>();

  final Map<String, dynamic> cur = load('../../assets/content/curriculum.json');
  final Map<String, dynamic> cues = load('../../assets/content/cues.en.json');
  final Map<String, dynamic> lib = load('../../assets/content/library.json');
  final Map<String, dynamic> boxing =
      load('../../assets/rulesets/boxing@1.0.0.json');
  final RuleSet rules = loadBoxingRuleSet();

  final Map<String, dynamic> drills =
      (cur['drills'] as Map).cast<String, dynamic>();
  final Map<String, dynamic> progression =
      (cur['progression'] as Map).cast<String, dynamic>();

  test('config\'teki her drillId müfredatta TANIMLI', () {
    for (final ErrorConfig e in rules.errors) {
      if (e.drillId == null) continue;
      expect(drills.containsKey(e.drillId), isTrue,
          reason: '${e.code} → ${e.drillId} tanımsız: hata üretiliyor ama '
              'kullanıcıya verilecek düzeltici çalışma yok');
    }
  });

  test('her drill\'in hedeflediği cue GERÇEKTEN var', () {
    final Set<String> known = <String>{
      ...(cues['technique'] as Map).keys.cast<String>(),
      ...(cues['noVerdict'] as Map).keys.cast<String>(),
    };
    for (final MapEntry<String, dynamic> d in drills.entries) {
      for (final String t
          in ((d.value as Map)['targets'] as List<dynamic>).cast<String>()) {
        expect(known, contains(t), reason: '${d.key} → $t repliği yok');
      }
    }
  });

  test('[kural 9] KAPI yalnız skorlanan/A-bandı ölçümlerden kurulur', () {
    // Skorlanmayan bir eklemi kapı yaparsak, skor vermediğimizi iddia
    // ederken ilerlemeyi onunla kilitlemiş oluruz.
    final Map<String, dynamic> coachedOnly =
        (((boxing['references'] as Map)['stance'] as Map)['coachedOnlyJoints']
                as Map)
            .cast<String, dynamic>();
    final Set<String> coachedCues = <String>{'cue.rear_hand_low'};

    for (final MapEntry<String, dynamic> lesson in progression.entries) {
      final List<dynamic> gates =
          ((lesson.value as Map)['gates'] as List<dynamic>);
      for (final dynamic g in gates) {
        final Map<String, dynamic> gate = (g as Map).cast<String, dynamic>();
        expect(coachedCues.contains(gate['cue']), isFalse,
            reason: '${lesson.key}: koçlanan-ama-skorlanmayan sinyal KAPI '
                'yapılmış — skoru başka adla vermek olur');
        if (gate['metric'] != null) {
          expect(coachedOnly.containsKey(gate['metric']), isFalse,
              reason: '${lesson.key}: ${gate['metric']} skorlanmıyor, '
                  'kapı kuramaz');
        }
      }
    }
  });

  test('koçlanan sinyaller kapı DEĞİL, yalnız gösterge', () {
    final List<dynamic> jabSignals =
        ((progression['boxing.foundations.jab'] as Map)['signals']
            as List<dynamic>);
    expect(jabSignals, isNotEmpty,
        reason: 'gard eli ilerlemesi kullanıcıya GÖSTERİLMELİ — '
            'skorlanmıyor olması görünmez olması demek değil');
    expect((jabSignals.first as Map)['cue'], 'cue.rear_hand_low');
  });

  test('ilerleme kriteri "dersi izledi" DEĞİL, ölçülebilir (plan §15)', () {
    for (final MapEntry<String, dynamic> lesson in progression.entries) {
      final List<dynamic> gates =
          ((lesson.value as Map)['gates'] as List<dynamic>);
      expect(gates, isNotEmpty, reason: '${lesson.key}: kapısı yok');
      for (final dynamic g in gates) {
        final Map<String, dynamic> gate = (g as Map).cast<String, dynamic>();
        final bool measurable = gate.keys.any((String k) => const <String>[
              'minCompletedAttempts', 'minCorrectSequences',
              'withinToleranceRatio', 'sessionMinutes',
            ].contains(k));
        expect(measurable, isTrue,
            reason: '${lesson.key}: kapı ölçülebilir bir büyüklüğe bağlı değil');
      }
    }
  });

  test('müfredattaki her ders kütüphanede GERÇEKTEN var', () {
    final Set<String> lessonIds = <String>{
      for (final dynamic d in lib['disciplines'] as List<dynamic>)
        for (final dynamic c in ((d as Map)['courses'] as List<dynamic>))
          for (final dynamic l in ((c as Map)['lessons'] as List<dynamic>))
            (l as Map)['id'] as String,
    };
    for (final String id in progression.keys) {
      expect(lessonIds, contains(id),
          reason: '$id için ilerleme kapısı var ama ders yok');
    }
  });
}
