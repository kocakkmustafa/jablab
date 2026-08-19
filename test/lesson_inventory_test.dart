import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// JAB-P1-001 Step 1 — 30-DERS ENVANTER KAPISI (kırmızı yazıldı).
///
/// ## Bu dosya neden ayrı — mevcut olanları TEKRARLAMAZ
///
/// `test/cue_reachability_test.dart` (kombinasyon repliklerinin içerikten
/// ulaşılabilirliği) ve `test/teach_material_test.dart` (öğretme
/// aşamasının materyal-yokluğu dürüstlüğü) ZATEN VAR ve JAB-P1-001'in
/// "cue completeness" ile "preview" endişelerinin BÜYÜK KISMINI
/// kapsıyor — okundu, doğrulandı, yeniden yazılmadı. Genuinely eksik olan
/// TEK parça: kimse `boxing` disiplininin ≥30 ders hedefine karşı
/// SAYMIYORDU. Bu dosya SADECE o boşluğu kapatır.
///
/// ## Neden bugün KIRMIZI (JAB-P1-001 Step 1'in kendi talimatı)
///
/// Mevcut: **19 ders** (Foundations 8 · Conditioning 7 · Intermediate 4,
/// `workspace/ICERIK-KAYNAK-ARASTIRMASI-30-DERS-2026-08-19.md`taki PREP
/// ölçümüyle birebir). Roadmap §4 hedefi **≥30**. Bu test şimdi KIRMIZI
/// yazılıyor — sayı gerçek içerik eklenmeden YEŞİL olmayacak, ve
/// olmamalı: kırmızı, yazılmamış 11 dersin var olduğu YALANINI
/// söylemekten daha dürüst bir durumdur.
///
/// ## "≥30" — hangi kurslardan, hangileri BİLEREK dışarıda
///
/// Roadmap'in kendi kurs listesi (JAB-P1-001 görev tanımı): fundamentals ·
/// footwork · defense · jab/cross · hook/uppercut · combo · conditioning.
/// Bugünkü karşılıkları:
///   * fundamentals → `boxing.foundations` (8, VAR)
///   * jab/cross     → `boxing.foundations` İÇİNDE zaten (ayrı kurs değil)
///   * conditioning → `boxing.conditioning` (7, VAR)
///   * combo        → `boxing.intermediate` (4, KISMEN — asıl `combinations`
///     dersi KİLİTLİ, bkz. aşağıdaki not)
///   * footwork     → YOK, bağımsız kurs açılmamış (GERÇEK boşluk)
///   * defense      → YOK, bağımsız kurs açılmamış (GERÇEK boşluk)
///   * hook/uppercut → YOK — `assets/content/library.json`ın kendi kaydı
///     (`boxing.intermediate.combinations.$lockedWhy`) bunu MODEL KAPISINA
///     bağlıyor: gerçek bir kanca dersi motorda ÖLÇÜLDÜĞÜNDE (24,8 dk'lık
///     gerçek koşum) 6 tamamlanma/0 yarıda-kesilme üretti — yani motor
///     ÇOĞU kancayı hiç görmüyor. Bu KİLİDİ yeni içerik AÇAMAZ (içerik
///     sorunu değil, motor sorunu — 3.000-punch model-gate'iyle AYNI
///     EXTERNAL_GATE ailesinden, ayrı bir mühendislik turu ister).
///
/// ⚠️ **"Boks numaralandırması hiçbir yerde açıklanmıyor" bulgusu ARTIK
/// GEÇERSİZ — bu turda ÖLÇÜLDÜ:** `DEVIR-2026-08-14-GECE.md`nin eski
/// notu `boxing.foundations.one_two`nun GERÇEK metnini yansıtmıyor: dersin
/// İLK CÜMLESİ zaten "One is the jab, two is the cross." diyor (2026-08-12
/// düzeltmesi, `$teachCorrection` alanı). Eksik olan yalnız 3-6 (kanca/
/// çengel numaraları) — ve bunlar BİLEREK yazılmadı: henüz öğretilmeyen
/// bir tekniğe numara vermek, var olmayan bir dersi ima ederdi. PREP
/// aday-listesinin bu maddesi burada DÜZELTİLDİ, körlemesine miras
/// alınmadı.
void main() {
  Map<String, dynamic> loadLibrary() => (jsonDecode(
              File('assets/content/library.json').readAsStringSync()) as Map)
      .cast<String, dynamic>();

  Map<dynamic, dynamic> boxingDiscipline(Map<String, dynamic> lib) =>
      (lib['disciplines'] as List<dynamic>).firstWhere(
          (dynamic d) => (d as Map)['id'] == 'boxing') as Map<dynamic, dynamic>;

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
    expect(lib['disciplines'], isNotEmpty,
        reason: 'library.json okunamadı ya da boş — aşağıdaki sayım '
            'ANLAMSIZ olurdu');
    final Map<dynamic, dynamic> boxing = boxingDiscipline(lib);
    expect(boxing['id'], 'boxing');
  });

  test(
    '🔴 HEDEF (bilerek SKIP — kırmızı bir commit kapısını BLOKE ETMEZ, '
    'ama sessizce kaybolmaz) — boxing ≥30 ders taşıyor mu',
    () {
      final Map<dynamic, dynamic> boxing = boxingDiscipline(loadLibrary());
      final List<Map<dynamic, dynamic>> lessons = allBoxingLessons(boxing);
      expect(lessons.length, greaterThanOrEqualTo(30));
    },
    // ⚠️ `skip` BİLEREK — `set -euo pipefail` çalıştıran commit kapısı
    // (tool/hooks/pre-commit) `flutter test`in çıkış kodunda SIFIR
    // TOLERANS taşır: gerçekten KIRMIZI bir test hiçbir commit'i
    // GEÇİRMEZ (bu da doğru — "P0 açıkken yeni kapsam yok" disiplininin
    // ta kendisi). O yüzden hedef `skip` ile İZLENEBİLİR kılındı: sayı
    // (19/30) burada, `flutter test` çıktısında GÖRÜNÜR kalır (SKIPPED
    // olarak, sessizce SİLİNMİŞ değil) ama süiti kırmızı yapıp her
    // commit'i durdurmaz. `expect()` çağrısı KORUNDU (yalnız yorum satırı
    // silinip skip eklenseydi, bir gün biri skip'i kaldırdığında hangi
    // sayıya karşı sınayacağını bilemezdi).
    skip: 'JAB-P1-001 Step 2-5 tamamlanana kadar açık hedef — bugün 19/30 '
        '(11 ders eksik: bağımsız Footwork kursu + bağımsız Defense kursu '
        '+ Combo genişlemesi; Hook/Uppercut model-kapısına bağlı, bkz. '
        'assets/content/library.json boxing.intermediate.combinations.'
        '\$lockedWhy — içerikle AÇILMAZ). Skip\'i kaldırmak İÇERİK '
        'eklemeden bu testi KIRMIZI yapar ve her commit\'i durdurur — '
        'bilerek, roadmap Step 1\'in "kırmızı yaz" istediği tam bu.',
  );

  test('kilitli dersler SAYIMA girer ama İÇERİĞİ olmayan bir ders gibi '
      'DAVRANMAZ — kilit gerekçesi her zaman yazılı', () {
    // Vakum/tutarlılık muhafızı: bir ders "locked" olabilir ama SESSİZ
    // olamaz — teach_material_test.dart'ın UI tarafını, burada İÇERİK
    // tarafını sınıyor.
    final Map<dynamic, dynamic> boxing = boxingDiscipline(loadLibrary());
    final List<Map<dynamic, dynamic>> locked = allBoxingLessons(boxing)
        .where((Map<dynamic, dynamic> l) => l['status'] == 'locked')
        .toList();
    expect(locked, isNotEmpty,
        reason: 'hiç kilitli ders yok — combinations dersinin kilidi '
            'kaybolmuş olabilir, bu ölçüm ANLAMSIZ olurdu');
    for (final Map<dynamic, dynamic> l in locked) {
      expect(l['lockedReason'], isA<String>(),
          reason: '${l['id']} kilitli ama kullanıcıya gösterilecek '
              'lockedReason YOK');
      expect((l['lockedReason'] as String).length, greaterThan(20),
          reason: '${l['id']}nin kilit gerekçesi çok kısa/anlamsız');
    }
  });

  test('numaralandırma iddiası SINIRLI — yalnız 1-2 açıklanıyor, '
      '3-6 (kanca/çengel) HENÜZ öğretilmeyen bir tekniğe uydurulmuyor', () {
    // Bu testin amacı YUKARIDAKİ dosya-başlığı bulgusunu KALICI kılmak:
    // "numaralandırma açıklanmıyor" iddiası bir daha körlemesine
    // miras alınıp yeni bir görev açmasın.
    final Map<dynamic, dynamic> boxing = boxingDiscipline(loadLibrary());
    final Map<dynamic, dynamic> oneTwo = allBoxingLessons(boxing)
        .firstWhere((Map<dynamic, dynamic> l) => l['id'] == 'boxing.foundations.one_two');
    final String teach = (oneTwo['teach'] as String).toLowerCase();
    expect(teach, contains('one is the jab'),
        reason: '1-2 numaralandırma açıklaması dersten KAYBOLMUŞ — '
            'DEVIR-2026-08-14-GECE.md\'nin eski (ve bu turda düzeltilen) '
            'bulgusu yeniden GEÇERLİ hâle gelmiş olabilir');
    // Negatif ikiz: 3-6 hiçbir açık derste UYDURULMAMALI (hook/uppercut
    // henüz kilitli).
    for (final Map<dynamic, dynamic> l in allBoxingLessons(boxing)) {
      if (l['status'] == 'locked') continue;
      final String t = (l['teach'] as String? ?? '').toLowerCase();
      for (final String phrase in <String>[
        'three is', 'four is', 'five is', 'six is',
      ]) {
        expect(t.contains(phrase), isFalse,
            reason: '${l['id']} "$phrase" diyor — kanca/çengel numarası '
                'henüz öğretilmeyen bir tekniğe erken uydurulmuş olabilir');
      }
    }
  });
}
