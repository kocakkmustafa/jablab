import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/solo_boxing_course.dart';

/// JAB-P1-001 — en az 30 öğretim dersi ve eski kamera kataloğu.
///
/// 2026-09-26: ilk tam kurs artık ayrı, sürümlü canonical assetten gelir.
/// Öğretim envanteri o dosyayı sayar; eski 21 derslik kamera kataloğunun
/// kilitleri ve numaralandırma sınırı aşağıda ayrı doğrulanır. Öğretim
/// dersinin varlığı yeni bir kamera tekniğine veya puanına izin vermez.
///
void main() {
  Map<String, dynamic> loadLibrary() =>
      (jsonDecode(File('assets/content/library.json').readAsStringSync())
              as Map)
          .cast<String, dynamic>();

  Map<dynamic, dynamic> boxingDiscipline(Map<String, dynamic> lib) =>
      (lib['disciplines'] as List<dynamic>).firstWhere(
            (dynamic d) => (d as Map)['id'] == 'boxing',
          )
          as Map<dynamic, dynamic>;

  List<Map<dynamic, dynamic>> allBoxingLessons(Map<dynamic, dynamic> boxing) {
    final List<Map<dynamic, dynamic>> out = <Map<dynamic, dynamic>>[];
    for (final dynamic c in boxing['courses'] as List<dynamic>) {
      for (final dynamic l in (c as Map)['lessons'] as List<dynamic>) {
        out.add(l as Map<dynamic, dynamic>);
      }
    }
    return out;
  }

  test('POZİTİF KONTROL — library.json okunuyor ve boxing bulunuyor', () {
    final Map<String, dynamic> lib = loadLibrary();
    expect(
      lib['disciplines'],
      isNotEmpty,
      reason:
          'library.json okunamadı ya da boş — aşağıdaki sayım '
          'ANLAMSIZ olurdu',
    );
    final Map<dynamic, dynamic> boxing = boxingDiscipline(lib);
    expect(boxing['id'], 'boxing');
    expect(
      allBoxingLessons(boxing),
      hasLength(21),
      reason: 'Yeni öğretim kursu eski kamera kataloğunu genişletmez.',
    );
  });

  test('canonical solo boks kursu ≥30 özgün öğretim dersi taşıyor', () {
    final SoloBoxingCourse course = SoloBoxingCourse.fromJsonString(
      File('assets/content/solo_boxing_course.v1.json').readAsStringSync(),
    );
    expect(course.lessons.length, greaterThanOrEqualTo(30));
    expect(
      course.modules.map((SoloModule module) => module.id),
      containsAll(<String>[
        'boxing.start',
        'boxing.footwork',
        'boxing.straights',
        'boxing.defence',
        'boxing.curves',
        'boxing.combinations',
        'boxing.rounds',
        'boxing.integration',
      ]),
    );
    expect(
      course.lessons.every(
        (SoloLesson lesson) => lesson.evidenceMode == 'self_report',
      ),
      isTrue,
      reason: 'Öğretim dersi kamera ustalık onayı olarak sayılamaz.',
    );
  });

  test('kilitli dersler SAYIMA girer ama İÇERİĞİ olmayan bir ders gibi '
      'DAVRANMAZ — kilit gerekçesi her zaman yazılı', () {
    // Vakum/tutarlılık muhafızı: bir ders "locked" olabilir ama SESSİZ
    // olamaz — teach_material_test.dart'ın UI tarafını, burada İÇERİK
    // tarafını sınıyor.
    final Map<dynamic, dynamic> boxing = boxingDiscipline(loadLibrary());
    final List<Map<dynamic, dynamic>> locked = allBoxingLessons(
      boxing,
    ).where((Map<dynamic, dynamic> l) => l['status'] == 'locked').toList();
    expect(
      locked,
      isNotEmpty,
      reason:
          'hiç kilitli ders yok — combinations dersinin kilidi '
          'kaybolmuş olabilir, bu ölçüm ANLAMSIZ olurdu',
    );
    for (final Map<dynamic, dynamic> l in locked) {
      expect(
        l['lockedReason'],
        isA<String>(),
        reason:
            '${l['id']} kilitli ama kullanıcıya gösterilecek '
            'lockedReason YOK',
      );
      expect(
        (l['lockedReason'] as String).length,
        greaterThan(20),
        reason: '${l['id']}nin kilit gerekçesi çok kısa/anlamsız',
      );
    }
  });

  test('numaralandırma iddiası SINIRLI — yalnız 1-2 açıklanıyor, '
      '3-6 (kanca/çengel) HENÜZ öğretilmeyen bir tekniğe uydurulmuyor', () {
    // Bu testin amacı YUKARIDAKİ dosya-başlığı bulgusunu KALICI kılmak:
    // "numaralandırma açıklanmıyor" iddiası bir daha körlemesine
    // miras alınıp yeni bir görev açmasın.
    final Map<dynamic, dynamic> boxing = boxingDiscipline(loadLibrary());
    final Map<dynamic, dynamic> oneTwo = allBoxingLessons(boxing).firstWhere(
      (Map<dynamic, dynamic> l) => l['id'] == 'boxing.foundations.one_two',
    );
    final String teach = (oneTwo['teach'] as String).toLowerCase();
    expect(
      teach,
      contains('one is the jab'),
      reason:
          '1-2 numaralandırma açıklaması dersten KAYBOLMUŞ — '
          'DEVIR-2026-08-14-GECE.md\'nin eski (ve bu turda düzeltilen) '
          'bulgusu yeniden GEÇERLİ hâle gelmiş olabilir',
    );
    // Negatif ikiz: 3-6 hiçbir açık derste UYDURULMAMALI (hook/uppercut
    // henüz kilitli).
    for (final Map<dynamic, dynamic> l in allBoxingLessons(boxing)) {
      if (l['status'] == 'locked') continue;
      final String t = (l['teach'] as String? ?? '').toLowerCase();
      for (final String phrase in <String>[
        'three is',
        'four is',
        'five is',
        'six is',
      ]) {
        expect(
          t.contains(phrase),
          isFalse,
          reason:
              '${l['id']} "$phrase" diyor — kanca/çengel numarası '
              'henüz öğretilmeyen bir tekniğe erken uydurulmuş olabilir',
        );
      }
    }
  });
}
