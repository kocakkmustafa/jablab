import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/live_honesty.dart';
import 'package:jablab/app/skeleton_overlay.dart';
import 'package:jablab/shell_candidate/live_surface.dart' show LiveState;

/// CANLI YÜZEYDE ÇELİŞKİ KAPISI (J-250).
///
/// ## Ölçtüğü kusur, gözle görülmüş hâliyle
///
/// Simülatörde canlı aşamada **aynı ekranda** şu ikisi yan yana duruyordu:
///
/// > *"Camera preview is left out on purpose — **analysis runs without it**"*
/// > *"We need the camera to watch your jab. **Nothing is analysed without
/// >  it** — the round clock still runs."*
///
/// Her ikisi de TEK BAŞINA savunulabilir: ilkinde *"it"* ÖNİZLEME, ikincisinde
/// KAMERA. Ama kullanıcı ikisini birlikte okur ve ekran kendi kendisiyle
/// çelişir. Ve daha ağırı: analiz koşmuyorken *"analysis runs"* demek
/// **belirsiz değil, YANLIŞTIR.**
///
/// ## Neden ANAHTAR değil METİN taranıyor
///
/// Anahtar (`camera-preview-placeholder`) cümlenin VARLIĞINI ölçer; bu kapı
/// cümlenin İDDİASINI ölçüyor. Metin yeniden yazılsa bile nöbet ayakta
/// kalsın diye iddia eden ifade (`analysis runs`) aranıyor — J-094'ün
/// kapısıyla aynı biçim.
void main() {
  Future<String> placeholderText(
    WidgetTester t, {
    required bool analysisRunning,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 375,
            height: 500,
            child: SkeletonPreview(
              state: LiveState.noVerdict,
              bucket: LiveHonestyBucket.none,
              analysisRunning: analysisRunning,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return t
            .widget<Text>(find.byKey(const Key('camera-preview-placeholder')))
            .data ??
        '';
  }

  testWidgets('ANALİZ KOŞMUYORKEN "analysis runs" İDDİASI YOK', (
    WidgetTester t,
  ) async {
    final String s = await placeholderText(t, analysisRunning: false);
    expect(
      s.toLowerCase(),
      isNot(contains('analysis runs')),
      reason:
          'analiz koşmuyor ama ekran "analysis runs" diyor — bu cümle '
          'kamera arızası / kamerasız ders / "getting ready" hâllerinde '
          'YANLIŞ, ve hemen altındaki arıza cümlesiyle ÇELİŞİYOR',
    );
    // SORUMLULUK YARISI HER HÂLDE KALIR: önizlemenin yokluğu bir TERCİH,
    // bir arıza değil. Bu yarı düşerse kullanıcı yokluğu arıza sanar.
    expect(
      s.toLowerCase(),
      contains('on purpose'),
      reason:
          'sorumluluk üstlenen yarı düşmüş — yokluk artık bir tercih '
          'gibi değil bir kaza gibi okunur',
    );
  });

  testWidgets('ANALİZ KOŞARKEN cümle TAM hâlini koruyor', (
    WidgetTester t,
  ) async {
    // VAKUM KORUMASI: üstteki test, cümle her hâlde boşaltılsa da geçerdi.
    // Bu test iddianın DOĞRU hâlde hâlâ söylendiğini çiviliyor — yoksa
    // "çelişkiyi sil" düzeltmesi bilgiyi de silerdi.
    final String s = await placeholderText(t, analysisRunning: true);
    expect(
      s.toLowerCase(),
      contains('analysis runs'),
      reason:
          'analiz koşuyorken bu bilgi DÜŞMÜŞ — kullanıcı görüntü '
          'olmadığı için analiz de yok sanar',
    );
    expect(s.toLowerCase(), contains('on purpose'));
  });

  testWidgets('İKİ HÂL AYNI CÜMLEYİ VERMİYOR', (WidgetTester t) async {
    // Eğer ikisi aynıysa `analysisRunning` okunmuyor demektir: alan eklenmiş
    // ama BAĞLANMAMIŞ olurdu (J-118'in "biçim vardı, üreticisi yoktu"
    // sınıfı, bu kez tüketici tarafında).
    final String off = await placeholderText(t, analysisRunning: false);
    final String on = await placeholderText(t, analysisRunning: true);
    expect(
      off,
      isNot(on),
      reason: 'iki hâl aynı cümleyi veriyor — `analysisRunning` okunmuyor',
    );
  });
}
