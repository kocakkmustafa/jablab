import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_page.dart';
import 'package:jablab/app/onboarding_store.dart';

/// YERLEŞİM KAPISI — çakışan metin/ikon (J-128).
///
/// ## Neden bu kapı vardı da yoktu
///
/// Kapı envanteri (J-126) üç ortak kör nokta buldu; **yerleşim** onlardan
/// biriydi ve sınıfı **kod** idi — yani mekanikleştirilebilir ama
/// yapılmamış. J-117 **tek bir** örtüşmeyi ölçtü (altyazı ↔ iskelet) ve
/// onu scrim'le çözdü; genel bir kapı yoktu.
///
/// Ailedeki kanıt: Gravita'nın bu geceki kusurlarından biri tam bu sınıftı
/// — Start düğmesi `NavigationBar` etiketlerini kapatıyordu ve **79 test
/// yeşilken** yalnız GÖZ yakaladı. Taşma kapısı onu göremez: hiçbir şey
/// taşmıyor, sadece biri ötekinin üstünde duruyor.
///
/// ## Ne ölçüyor
///
/// 375×812'de her ekranın **yaprak** `Text` ve `Icon` kutuları alınıyor ve
/// ikişerli kesişim aranıyor. Kardeş iki metnin çakışması bir kusurdur;
/// biri okunmaz.
///
/// ## ⚠️ NE ÖLÇMÜYOR — beyan (kapı envanterinin kendi kuralı)
///
/// * **Kasıtlı katmanları** ayırt etmiyor: bir `Stack` bilerek üst üste
///   çizebilir. Bugün JabLab'da tek canlı `Stack` iskelet önizlemesi ve
///   orada çakışan şey `CustomPaint` — `Text`/`Icon` değil, yani bu kapı
///   onu zaten görmez. Bir gün kasıtlı bir metin katmanı gelirse bu kapı
///   **yanlış öter** ve o zaman istisna ADIYLA yazılmalı, kapı
///   gevşetilmemeli.
/// * **Kısmi örtüşmenin okunabilirliğe etkisini** ölçmüyor — 1 piksellik
///   kesişim de, tam kapanma da aynı sayılır. Eşik icat etmemek için
///   kesişim ALANI değil VARLIĞI ölçülüyor.
/// * **Z sırasını** bilmiyor: hangisinin üstte olduğunu söylemez, yalnız
///   ikisinin aynı yeri paylaştığını.
void main() {
  const OnboardingStore seen = OnboardingStore(seenOverride: true);

  setUp(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(375, 812);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  /// Görünür yaprak kutular: `Text` ve `Icon`. Boş metinler atlanıyor —
  /// görünmeyen bir kutu kimseyi kapatmaz.
  List<(String, Rect)> boxes(WidgetTester t) {
    final List<(String, Rect)> out = <(String, Rect)>[];
    for (final Element e in find.byType(Text).evaluate()) {
      final Text w = e.widget as Text;
      final String? d = w.data;
      if (d == null || d.trim().isEmpty) continue;
      final RenderBox? r = e.renderObject as RenderBox?;
      if (r == null || !r.hasSize || r.size.isEmpty) continue;
      out.add((
        '"${d.length > 28 ? '${d.substring(0, 28)}…' : d}"',
        r.localToGlobal(Offset.zero) & r.size,
      ));
    }
    for (final Element e in find.byType(Icon).evaluate()) {
      final RenderBox? r = e.renderObject as RenderBox?;
      if (r == null || !r.hasSize || r.size.isEmpty) continue;
      out.add((
        'icon:${(e.widget as Icon).icon?.codePoint}',
        r.localToGlobal(Offset.zero) & r.size,
      ));
    }
    return out;
  }

  void expectNoOverlap(WidgetTester t, String screen) {
    final List<(String, Rect)> bs = boxes(t);
    expect(bs.length, greaterThan(1),
        reason: '$screen: kapı bir şey bulamadı — ekran çizilmemiş olabilir '
            've kapı VAKUM-DOĞRU olur (aile dersi #4)');
    final List<String> clashes = <String>[];
    for (int i = 0; i < bs.length; i++) {
      for (int j = i + 1; j < bs.length; j++) {
        final Rect a = bs[i].$2;
        final Rect b = bs[j].$2;
        if (!a.overlaps(b)) continue;
        // İÇ İÇE OLANLAR muaf: bir ikon kendi metniyle aynı satırda ve
        // biri ötekini TAMAMEN içeriyorsa bu bir kapatma değil, kalıptır
        // (rozetin çerçevesi, düğmenin etiketi). Kısmi kesişim ise gerçek
        // bir çakışmadır — biri ötekinin bir parçasını örtüyor.
        if (a.contains(b.topLeft) && a.contains(b.bottomRight)) continue;
        if (b.contains(a.topLeft) && b.contains(a.bottomRight)) continue;
        clashes.add('${bs[i].$1} ↔ ${bs[j].$1}');
      }
    }
    expect(clashes, isEmpty,
        reason: '$screen: çakışan kutular — biri ötekini örtüyor ve taşma '
            'kapısı bunu GÖREMEZ (hiçbir şey taşmıyor): '
            '${clashes.join(" · ")}');
  }

  testWidgets('Karşılama — üç perdede de çakışma YOK', (WidgetTester t) async {
    late final dynamic lib;
    await t.runAsync(() async {
      const ContentRepository repo = ContentRepository();
      lib = repo.toShell((await repo.load()).library);
    });
    await t.pumpWidget(MaterialApp(
      home: OnboardingPage(
          library: lib, onDone: () {}, onOpenWhyNot: () {}),
    ));
    await t.pumpAndSettle();
    for (int step = 0; step < 3; step++) {
      expectNoOverlap(t, 'karşılama perde ${step + 1}');
      if (step < 2) {
        await t.tap(find.byKey(const Key('onboarding-next')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
      }
    }
  });

  testWidgets('Sayfa A — kartlar ve rozetler çakışmıyor',
      (WidgetTester t) async {
    await t.runAsync(() async {
      await t.pumpWidget(const JabLabApp(onboarding: seen));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await t.pumpAndSettle();
    expectNoOverlap(t, 'Sayfa A');
  });
}
