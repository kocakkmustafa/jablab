import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Müfredat ↔ hata kataloğu bağlarının değişmezleri (G6).
///
/// Bu iki dosya arasındaki bağ **iki ayrı anahtarla** kurulu: hata `drillId`
/// ile drill'e, drill `targets` ile hatanın `feedbackKey`'ine işaret eder.
/// Çift anahtarlı bağ sessizce kayar — biri düzenlenip diğeri unutulduğunda
/// hiçbir şey patlamaz, sadece kullanıcı yanlış egzersize yönlendirilir.
void main() {
  final Map<String, dynamic> cfg = (jsonDecode(
              File('../../assets/rulesets/boxing@1.0.0.json').readAsStringSync())
          as Map)
      .cast<String, dynamic>();
  final Map<String, dynamic> cur = (jsonDecode(
              File('../../assets/content/curriculum.json').readAsStringSync())
          as Map)
      .cast<String, dynamic>();

  final List<Map<String, dynamic>> errors = <Map<String, dynamic>>[
    for (final dynamic e in cfg['errors'] as List<dynamic>)
      (e as Map).cast<String, dynamic>()
  ];
  final Map<String, dynamic> drills =
      (cur['drills'] as Map).cast<String, dynamic>();
  final Map<String, dynamic> progression =
      (cur['progression'] as Map).cast<String, dynamic>();
  final Map<String, dynamic> measures =
      (cfg['measures'] as Map).cast<String, dynamic>();
  final Set<String> coachedJoints =
      ((cfg['references'] as Map)['stance'] as Map)['coachedOnlyJoints']
          .keys
          .cast<String>()
          .toSet();

  test('gidiş-dönüş: hata → drill → hatanın kendi cue\'su', () {
    for (final Map<String, dynamic> e in errors) {
      if (e['errorClass'] == 'setup') continue;
      final String? did = e['drillId'] as String?;
      expect(did, isNotNull, reason: '${e['code']} form hatası ama drill\'siz');
      final Map<String, dynamic> d =
          (drills[did] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      expect(d, isNotEmpty, reason: '${e['code']} → $did: böyle bir drill yok');
      expect((d['targets'] as List<dynamic>).contains(e['feedbackKey']), isTrue,
          reason: '${e['code']} $did\'e işaret ediyor ama $did onun cue\'sunu '
              'hedeflemiyor — çift anahtarlı bağ kaymış');
    }
  });

  test('[J-037] SETUP hatası drill ÖNEREMEZ', () {
    // "Çerçeveden çıktın" bir form hatası değil. Buna egzersiz reçete etmek,
    // kullanıcıyı kendi tripodunun açısı için suçlamaktır; düzeltme kamerada.
    for (final Map<String, dynamic> e in errors) {
      if (e['errorClass'] != 'setup') continue;
      expect(e['drillId'], isNull,
          reason: '${e['code']} setup sınıfı ama drill öneriyor');
    }
    expect(errors.where((Map<String, dynamic> e) => e['errorClass'] == 'setup'),
        isNotEmpty,
        reason: 'setup sınıfı boşaldıysa bu testin koruduğu şey kalmamış');
  });

  test('her hata bir sınıf taşır — sınıfsız hata sessizce kaçar', () {
    for (final Map<String, dynamic> e in errors) {
      expect(<String>['form', 'setup'].contains(e['errorClass']), isTrue,
          reason: '${e['code']} sınıfsız');
    }
  });

  test('[M-F-41] drill kapı olabilir mi — İKİ bağımsız kısıt', () {
    // Bir ölçüye kapı kurabilmek için ikisi birden gerekir:
    //   (1) tespit güvenilir mi     → hata bandı A olmalı
    //   (2) eğitmenler uzlaşıyor mu → dayandığı eklem SKORLANAN olmalı
    // Biri bile düşerse trend. Yetki anatomiden değil ölçümden gelir.
    final Map<String, Map<String, dynamic>> byCue =
        <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> e in errors)
        if (e['feedbackKey'] != null) e['feedbackKey'] as String: e
    };
    for (final MapEntry<String, dynamic> entry in drills.entries) {
      final Map<String, dynamic> d =
          (entry.value as Map).cast<String, dynamic>();
      bool blocked = false;
      for (final dynamic t in d['targets'] as List<dynamic>) {
        final Map<String, dynamic>? e = byCue[t];
        if (e == null) continue;
        if (e['band'] == 'B' || e['band'] == 'B-kal') blocked = true;
        for (final String m in (e['condition'] as Map).keys.cast<String>()) {
          final Map<String, dynamic>? spec =
              (measures[m.split('.').last] as Map?)?.cast<String, dynamic>();
          for (final dynamic j
              in (spec?['dependsOnJoints'] as List<dynamic>?) ?? <dynamic>[]) {
            if (coachedJoints.contains(j)) blocked = true;
          }
        }
      }
      expect(d['gateable'], !blocked,
          reason: '${entry.key}: gateable=${d['gateable']} ama türetme '
              '${!blocked} diyor — el ile düzenlenmiş veya bayat');
      expect(d['reportsAs'], blocked ? 'trend' : 'gate');
    }
  });

  test('[J-036] KAPI, koçlanan eklemden veya oran ölçüsünden kurulamaz', () {
    // İlerleme kapısı kullanıcının ilerlemesini KİLİTLER. Eğitmenlerin
    // anlaşmadığı bir ölçüde kilit, kullanıcıyı stil farkı için cezalandırır.
    for (final MapEntry<String, dynamic> lesson in progression.entries) {
      final Map<String, dynamic> v =
          (lesson.value as Map).cast<String, dynamic>();
      for (final dynamic g in v['gates'] as List<dynamic>) {
        final Map<String, dynamic> gate = (g as Map).cast<String, dynamic>();
        final String? metric = gate['metric'] as String?;
        if (metric == null) continue; // olay/süre kapıları bu kuralın dışında
        final Map<String, dynamic>? spec =
            (measures[metric] as Map?)?.cast<String, dynamic>();
        expect(spec, isNotNull,
            reason: '${lesson.key}: $metric ölçü kataloğunda yok');
        final List<dynamic> deps =
            (spec!['dependsOnJoints'] as List<dynamic>?) ?? <dynamic>[];
        expect(deps, isNotEmpty,
            reason: '${lesson.key}: $metric bir kapı ama hangi eklem '
                'dispersiyonuna dayandığı YAZILMAMIŞ — ölçülmemiş bir iddiaya '
                'kapı kurulmuş olabilir (stanceWidthRatio bu şekilde kaçmıştı)');
        for (final dynamic j in deps) {
          expect(coachedJoints.contains(j), isFalse,
              reason: '${lesson.key}: $metric → $j koçlanan eklem');
        }
      }
    }
  });

  test('[J-038] KİLİTLİ ders kapı taşımaz, CANLI ders kapısız kalmaz', () {
    // Kapsamı baştan göstermek (kilitli ders kartta durur) ile ölçemediğimizi
    // vaat etmek ayrı şeyler. Kilitli bir dersin kapısı olsaydı, o kapı
    // ölçülemeyen bir beceriyi puanlıyor olurdu; kapısız canlı bir ders ise
    // "dersi izledin, geçtin" derdi — plan §15 bunu açıkça yasaklıyor.
    final Map<String, dynamic> lib = (jsonDecode(
                File('../../assets/content/library.json').readAsStringSync())
            as Map)
        .cast<String, dynamic>();
    final List<dynamic> disciplines = lib['disciplines'] as List<dynamic>;
    final Map<String, dynamic> boxing = disciplines
        .cast<Map<String, dynamic>>()
        .firstWhere((Map<String, dynamic> d) => d['id'] == 'boxing');

    int locked = 0;
    for (final dynamic c in boxing['courses'] as List<dynamic>) {
      for (final dynamic raw in (c as Map)['lessons'] as List<dynamic>) {
        final Map<String, dynamic> les = (raw as Map).cast<String, dynamic>();
        final String id = les['id'] as String;
        final bool isLocked = les['status'] == 'locked';
        if (isLocked) {
          locked++;
          expect(progression.containsKey(id), isFalse,
              reason: '$id kilitli ama kapısı var — ölçülemeyen beceri puanlanıyor');
          expect(les['lockedBy'], isNotNull,
              reason: '$id kilitli ama SEBEBİ yok; kilit "yakında" rozetine dönüşmüş');
          expect(les[r'$lockedWhy'], isNotNull,
              reason: '$id: eksik ÖLÇÜMÜN adı yazılmamış');
        } else {
          expect(progression.containsKey(id), isTrue,
              reason: '$id canlı ama ilerleme kapısı yok — "dersi izledi" '
                  'ilerleme sayılırdı (plan §15)');
        }
      }
    }
    expect(locked, greaterThan(0),
        reason: 'kilitli ders kalmadıysa bu testin koruduğu şey de kalmamış');
  });

  test('[J-035] koçlanan eklem ya dispersiyonla ya AÇIKLIKLA düşer', () {
    // sd n=3'te dayanıklı değil: {-1,9 · -3,8 · -28,4} → sd 12,0° (tabanın
    // altında) ama ortada uzlaşı değil bimodal bölünme var. Bu yüzden 14°
    // altındaki bir eklem koçlanan kovadaysa gerekçesi AÇIKÇA yazılmalı.
    final Map<String, dynamic> coached =
        ((cfg['references'] as Map)['stance'] as Map)['coachedOnlyJoints']
            .cast<String, dynamic>();
    for (final MapEntry<String, dynamic> e in coached.entries) {
      final Map<String, dynamic> j = (e.value as Map).cast<String, dynamic>();
      final double disp = (j['measuredDispersionDeg'] as num).toDouble();
      if (disp > 14.0) continue;
      expect(j['demotedBy'], 'takeSpread',
          reason: '${e.key}: dispersiyonu tabanda ama koçlanan — gerekçesiz '
              'düşürülmüş bir eklem, kapsamı sessizce daraltır');
      expect((j['takeSpreadDeg'] as num).toDouble(), greaterThan(14.0));
      expect((j['maxWithinTakeDeviationDeg'] as num).toDouble(), lessThan(5.0),
          reason: '${e.key}: take-İÇİ sapma büyükse ayrışma gerçek değil, '
              'gürültüdür — düşürme gerekçesi çürük');
    }
  });
}
