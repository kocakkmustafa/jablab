import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SABİT-GECİKMELİ YÜKLEME BEKLEMESİ GERİ GELEMEZ (J-219).
///
/// ## Neden bir kapı
///
/// `runAsync` içinde `pumpWidget(...)` + **sabit** `Future.delayed(...)`
/// deseni **11 test dosyasında** vardı ve **gizli bir yarış**tı: asset
/// yüklemesi gerçek async I/O, 150-250 ms tek başına yetiyor, **paralel yük
/// altında yetmiyor.** 2026-08-12'de bir commit'i yanlış yere durdurdu
/// (J-218) — ve o vakanın *ucuz* tarafa düşmesi **tesadüftü**:
///
/// > ***Bir yarışın hangi yöne düştüğü, onun ne kadar tehlikeli olduğunu
/// > ölçmez.*** Aynı yarış, içerik gelmiş olsaydı testi **sessizce
/// > geçirirdi.**
///
/// Panzehir `test/app_pump.dart`ta tek yerde: **süre değil DURUM** beklenir,
/// sınırlı, ve takılan yükleme sessizce beklemez. Bu kapı, düzeltmenin
/// **geri alınmasını** engeller — 11 dosyayı düzeltip kapıyı kurmamak,
/// aynı satırın yarın bir dosyaya geri sızmasına açık kapı bırakırdı.
///
/// ## ÖLÇÜT — ve neden B-SINIFINI KAPSAMIYOR
///
/// Denetlenen şey dar: **aynı `runAsync` bloğunda hem `pumpWidget` hem
/// sabit `Future.delayed` bulunması.** Bu, "uygulama kökü yüklenene kadar
/// bekle" niyetinin imzası.
///
/// ⛔ **Kapsam DIŞI (bilerek):** `pumpWidget` İÇERMEYEN `runAsync` blokları.
/// Onlar (10 site: `summary_count_chain` · `clock_claim` ·
/// `teach_stage_silence` · `camera_handoff` · `narrow_viewport` ·
/// `summary_count`) dokunuş sonrası **gerçek zamanın akmasını** bekliyor —
/// tur saatinin tiklemesi, kamera karelerinin akıştan boşalması. Orada
/// beklenen bir *render durumu* değil, bir *zaman aralığı*; aynı panzehir
/// uygulanamaz ve **uydurulmadı.** Ölçüldü, adıyla dışarıda bırakıldı
/// (koordinatör sınırı: aynı desen, aynı panzehir, icat yok).
void main() {
  final List<File> testFiles =
      Directory('test')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('_test.dart'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));

  test('POZİTİF KONTROL — test dosyaları okunuyor ve desen ARANABİLİYOR', () {
    expect(
      testFiles.length,
      greaterThan(20),
      reason:
          'yalnız ${testFiles.length} test dosyası bulundu — gezinme '
          'bozuk, aşağıdaki "temiz" sonucu ANLAMSIZ olurdu',
    );
    // Aracın bu dizgeyi bulabildiğini kanıtla: `runAsync` hâlâ kullanılıyor
    // olmalı (panzehir onu KALDIRMADI, sabit süreyi kaldırdı).
    final int withRunAsync = testFiles
        .where((File f) => f.readAsStringSync().contains('runAsync'))
        .length;
    expect(
      withRunAsync,
      greaterThan(5),
      reason: 'hiçbir dosyada `runAsync` görünmüyor — tarama bozuk',
    );
  });

  test('🔒 runAsync bloğunda pumpWidget + SABİT gecikme YOK', () {
    final List<String> offenders = <String>[];

    for (final File f in testFiles) {
      final String src = f.readAsStringSync();
      // `runAsync(` sonrası dengeli parantez taramasıyla blok gövdesi.
      int i = 0;
      while ((i = src.indexOf('runAsync(', i)) != -1) {
        int depth = 0;
        int j = src.indexOf('(', i);
        final int start = j;
        for (; j < src.length; j++) {
          if (src[j] == '(') depth++;
          if (src[j] == ')') {
            depth--;
            if (depth == 0) break;
          }
        }
        final String block = src.substring(start, j.clamp(start, src.length));
        final bool pumps = block.contains('pumpWidget(');
        final bool fixedDelay = RegExp(
          r'Future<void>\.delayed\(\s*const Duration\(',
        ).hasMatch(block);
        if (pumps && fixedDelay) {
          final int line = '\n'.allMatches(src.substring(0, i)).length + 1;
          offenders.add('${f.path}:$line');
        }
        i = j > i ? j : i + 1;
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'SABİT-GECİKMELİ YÜKLEME BEKLEMESİ geri gelmiş:\n'
          '  ${offenders.join("\n  ")}\n\n'
          'Asset yüklemesi gerçek async I/O; sabit süre paralel yük '
          'altında yetmez ve test SESSİZCE yanlış tarafa düşebilir '
          '(J-218). Bunun yerine `test/app_pump.dart`:\n'
          '  await t.runAsync(() async { await t.pumpWidget(...); });\n'
          '  await settleAppLoad(t);            // ya da settleUntil(t, …)\n'
          '  await t.pumpAndSettle();',
    );
  });

  test(
    '🔒 ORTAK PANZEHİR TEK YERDE — app_pump.dart duruyor ve kullanılıyor',
    () {
      final File helper = File('test/app_pump.dart');
      expect(
        helper.existsSync(),
        isTrue,
        reason: 'ortak yardımcı silinmiş — 11 dosya yeniden ayrışır',
      );
      final String src = helper.readAsStringSync();
      for (final String fn in <String>['settleAppLoad', 'settleUntil']) {
        expect(src, contains('Future<void> $fn'), reason: '$fn kaybolmuş');
      }
      // Sınırlılık, panzehrin ayrılmaz parçası: sonsuza kadar bekleyen bir
      // yardımcı, takılan yüklemeyi SESSİZLEŞTİRİRDİ.
      expect(
        src,
        contains('i < 40'),
        reason:
            'bekleme SINIRI kaldırılmış — takılan bir yükleme artık '
            'sessizce bekler, kararsızlık geri döner',
      );

      final int users = testFiles
          .where((File f) => f.readAsStringSync().contains('app_pump.dart'))
          .length;
      expect(
        users,
        greaterThanOrEqualTo(10),
        reason:
            'yalnız $users dosya ortak yardımcıyı kullanıyor — '
            'düzeltme ayrışmış olabilir',
      );
    },
  );
}
