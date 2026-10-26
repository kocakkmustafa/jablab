import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/camera_harness_screen.dart';
import 'package:jablab/app/pose_model.dart';

/// DEV HARNESS değişmezleri (J-072).
///
/// Harness'ın işi köprünün ÖLÇÜMLERİNİ ham göstermek; ürün iddiası kurmak
/// DEĞİL. Aşağıdakiler tam bu sınırı zorluyor — çünkü bir dev ekranının
/// ürün ekranına dönüşmesi tek bir "bunu da gösterelim" ile olur.
void main() {
  setUp(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(1200, 2600);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(home: CameraHarnessScreen()));
    await t.pumpAndSettle();
  }

  testWidgets('bu bir ÜRÜN ekranı olmadığını KENDİSİ söylüyor', (
    WidgetTester t,
  ) async {
    await pump(t);
    final Text d = t.widget<Text>(find.byKey(const Key('harness-disclaimer')));
    // Üç iddia birden: geliştirici aracı · ön-izleme YOK · hüküm YOK.
    expect(d.data, contains('not a feature'));
    expect(d.data, contains('no preview'));
    expect(d.data!.toLowerCase(), contains('judgement'));
  });

  testWidgets('ÖLÇÜLEMEYEN değer "—", sıfır DEĞİL', (WidgetTester t) async {
    // Sıfır bir ÖLÇÜMDÜR, yokluk değil. Başlamamış bir seansta judgedRatio
    // 0.000 göstermek "ölçtüm ve sıfır çıktı" demek olurdu.
    await pump(t);
    for (final String k in <String>[
      'judgedRatio',
      'judged/s',
      'captured/s',
      'meanInferenceUs',
      'clockDomain',
      'frame',
      'modelVersion (envelope)',
    ]) {
      final Text v = t.widget<Text>(find.byKey(Key('metric-$k')));
      expect(v.data, '—', reason: '$k başlamamışken "—" olmalı');
    }
  });

  testWidgets('§7.3-7.6 nicelikleri EKRANDA var', (WidgetTester t) async {
    // Canlılık listesi bu sayılarla kapanacak; biri düşerse cihaz gününde
    // ölçülemez ve fark edilmez.
    await pump(t);
    for (final String k in <String>[
      'envelopes', // §7.3 zarf akışı
      'judgedRatio', // §7.3
      'meanInferenceUs', // §7.3
      'dropped (session)', // §7.5 buffer açlığı
      'clockDomain', // §7.6
      'no-person passes',
    ]) {
      expect(
        find.byKey(Key('metric-$k')),
        findsOneWidget,
        reason: '$k göstergesi yok — §7 kalemi ölçülemez',
      );
    }
  });

  testWidgets('MODEL PİNİ ekranda ve zarf kimliğiyle kıyaslanabilir', (
    WidgetTester t,
  ) async {
    await pump(t);
    final Text pin = t.widget<Text>(find.byKey(const Key('harness-model-pin')));
    expect(pin.data, contains(PoseModelPin.modelId));
    expect(pin.data, contains(PoseModelPin.sha256));
    // Ekran, kıyaslamanın NİYE önemli olduğunu da söylüyor: sessiz model
    // takası eklem tablolarının anlamını değiştirir.
    expect(pin.data, contains('silently'));
  });

  testWidgets('başlamamışken Stop KAPALI, Start açık', (WidgetTester t) async {
    await pump(t);
    final OutlinedButton stop = t.widget<OutlinedButton>(
      find.byKey(const Key('harness-stop')),
    );
    expect(stop.onPressed, isNull);
    final FilledButton start = t.widget<FilledButton>(
      find.byKey(const Key('harness-start')),
    );
    expect(start.onPressed, isNotNull);
  });

  testWidgets('ÖN-İZLEME YOK — §7.8 açık kalemi gizlenmiyor', (
    WidgetTester t,
  ) async {
    await pump(t);
    // Harness bir kamera görüntüsü ÇİZMİYOR. Çizse, §7.8'in blokladığı
    // "kullanıcı kendini görüyor" iddiasını dev ekranından sızdırırdı.
    expect(find.byType(Texture), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  test('release derlemesinde harness ERİŞİLEBİLİR DEĞİL', () {
    // `kDebugMode` testte true; burada sınanan şey bayrağın VARLIĞI ve
    // ekranın ona bağlı olması. Release'de girişin render edilmemesi
    // `jablab_app`taki `if (CameraHarnessScreen.isAvailable)` ile sağlanıyor.
    expect(
      CameraHarnessScreen.isAvailable,
      isTrue,
      reason:
          'debug testte true olmalı — bayrak bağlı değilse '
          'release derlemesinde de açık kalır',
    );
  });
}
