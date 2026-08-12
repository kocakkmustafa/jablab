import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// UYGULAMA KÖKÜNÜ YÜKLENENE KADAR PUMP'LA — sabit gecikmenin yerine (J-219).
///
/// ## Neden ortak bir yardımcı
///
/// 11 test dosyası aynı satırı ayrı ayrı taşıyordu:
///
/// ```dart
/// await t.runAsync(() async {
///   await t.pumpWidget(JabLabApp(...));
///   await Future<void>.delayed(const Duration(milliseconds: 200)); // ⛔
/// });
/// ```
///
/// Asset yüklemesi **gerçek async I/O** ve widget testinin sanal saati onu
/// ilerletmez — bu yüzden `runAsync` doğru, **sabit süre yanlıştı.** 150-250
/// ms tek başına koşarken yetiyor, **paralel yük altında yetmiyor**; içerik
/// gelmeden `pumpAndSettle` koşuyor. 2026-08-12'de bu, bir commit'i **yanlış
/// yere** durdurdu (J-218).
///
/// > ***Bir yarışın hangi yöne düştüğü, onun ne kadar tehlikeli olduğunu
/// > ölçmez.*** O vaka yanlış bir DURDURMA üretti; aynı yarış, içerik gelmiş
/// > olsaydı testi **sessizce geçirirdi.**
///
/// Ortak yardımcı, düzeltmenin 11 dosyada **ayrışmasını** da engelliyor:
/// tek yer, tek eşik, tek gerekçe.
///
/// ## Ölçüt: SÜRE değil, DURUM
///
/// `_Root` içerik **ve** karşılama bayrağı gelene kadar
/// `CircularProgressIndicator` çiziyor (`jablab_app.dart`). Yükleme bittiğinde
/// — başarıyla **ya da** hata ekranıyla — gösterge kalkar. Beklenen şey bu.
///
/// **Sınırlı** (~2 s): takılan bir yükleme *sessizce beklemez*. Süre dolarsa
/// döngü çıkar ve çağıranın `pumpAndSettle`ı sonsuz animasyonda **patlar** —
/// yani başarısızlık görünür kalır, gizlenmez.
Future<void> settleAppLoad(WidgetTester t) async {
  for (int i = 0; i < 40; i++) {
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump();
  }
}

/// Belirli bir widget GÖRÜNENE kadar pump'la — sınırlı.
///
/// `settleAppLoad` "yükleme bitti"yi bekler; bu ise **belirli bir hedefi.**
/// Ayrı olmalarının sebebi: bazı testler yükleme penceresinin KENDİSİNİ
/// sınıyor (ör. *"bayrak okunana kadar ne kabuk ne karşılama çizilir"*) ve
/// orada "gösterge kalktı" yeterli bir ölçüt değil.
Future<void> settleUntil(WidgetTester t, Finder target) async {
  for (int i = 0; i < 40; i++) {
    if (target.evaluate().isNotEmpty) return;
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump();
  }
}
