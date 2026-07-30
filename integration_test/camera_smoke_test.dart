import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jablab/app/camera_harness_screen.dart';

/// KÖPRÜ TESİSAT SMOKE'U — CİHAZDA koşar (J-072).
///
/// ⚠️ **BU BİR TESİSAT KANITIDIR, GERÇEK-İNSAN ÖLÇÜMÜ DEĞİL.** Emülatörün
/// sanal kamerası bir insan gövdesi göstermez; buradan çıkan sayılar
/// "kanal + çıkarım + zarf akışı ayakta mı" sorusunu yanıtlar, "poz ne kadar
/// doğru okunuyor" sorusunu YANITLAMAZ. Sözleşme §7.3-7.7'nin gerçek
/// sayıları (judgedRatio/meanInferenceUs'un anlamlı değerleri, dual-pass
/// maliyeti, buffer-tutma, clock-domain gözlemi, ters-geçiş fikstürü)
/// GERÇEK CİHAZDA, gerçek bir insanla ölçülecek — kurucu-manuel kalemi.
///
/// Bu ayrımı silmek en kolay sahte-ilerleme yolu olurdu: emülatörde akan bir
/// zarf akışını "kamera çalışıyor" diye raporlamak. Akan şey TESİSAT.
///
/// Koşum:
///   flutter test integration_test/camera_smoke_test.dart -d emulator-5554
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('köprü tesisatı: zarf akışı ≥30 sn ayakta kalıyor',
      (WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(home: CameraHarnessScreen()));
    await t.pumpAndSettle();

    String metric(String k) =>
        t.widget<Text>(find.byKey(Key('metric-$k'))).data ?? '(yok)';

    // Başlamadan önce her ölçüm "—" olmalı (sıfır DEĞİL).
    expect(metric('judgedRatio'), '—');
    expect(metric('envelopes'), '0');

    await t.tap(find.byKey(const Key('harness-start')));
    // start() izin + model yükleme + AVCapture/CameraX kurulumu yapıyor;
    // pumpAndSettle burada bloklanabilir (süren timer'lar var), o yüzden
    // sabit pump'larla ilerliyoruz.
    for (int i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 250));
    }

    // Hata çıktıysa İSİMLİ göster — sessiz başarısızlık en kötü sonuç.
    final Finder err = find.byKey(const Key('harness-error'));
    if (err.evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('HARNESS ERROR: ${t.widget<Text>(err).data}');
    }

    // ≥30 sn: sözleşme §7.3'ün istediği süre.
    const int seconds = 32;
    for (int i = 0; i < seconds * 4; i++) {
      await t.pump(const Duration(milliseconds: 250));
    }

    final Map<String, String> report = <String, String>{
      for (final String k in <String>[
        'session',
        'elapsed',
        'envelopes',
        'judgedRatio',
        'judged/s',
        'captured/s',
        'meanInferenceUs',
        'dropped (session)',
        'dropped (last)',
        'clockDomain',
        'frame',
        'modelVersion (envelope)',
        'library',
        'no-person passes',
      ])
        k: metric(k),
    };

    // ignore: avoid_print
    print('=== KÖPRÜ TESİSAT SMOKE — EMÜLATÖR (tesisat kanıtı) ===');
    report.forEach((String k, String v) {
      // ignore: avoid_print
      print('  $k = $v');
    });
    if (err.evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('  HATA = ${t.widget<Text>(err).data}');
    }
    // ignore: avoid_print
    print('=== / SMOKE ===');

    // KAPI: zarf AKMIŞ olmalı. Akmadıysa tesisat ölü ve bunu bilmek
    // istiyoruz — sayı raporlamak yerine test KIRILIR.
    final int envelopes = int.tryParse(report['envelopes'] ?? '0') ?? 0;
    expect(envelopes, greaterThan(0),
        reason: 'hiç zarf gelmedi — kanal/çıkarım tesisatı ölü. '
            'Hata alanı: ${err.evaluate().isEmpty ? "(yok)" : t.widget<Text>(err).data}');
    expect(report['clockDomain'], isNot('—'),
        reason: 'seans açıldı ama clock domain bildirilmedi (§7.6)');
    expect(report['modelVersion (envelope)'], contains('float16/1'),
        reason: 'zarf pinli model kimliğini taşımıyor (§6) — model takası '
            'sessizce başka bir bundle ile koşuyor olabilir');

    await t.tap(find.byKey(const Key('harness-stop')));
    await t.pump(const Duration(seconds: 1));
  });
}
