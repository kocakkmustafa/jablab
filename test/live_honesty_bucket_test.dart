import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/design_tokens.dart';
import 'package:jablab/app/live_honesty.dart';
import 'package:jablab/app/skeleton_overlay.dart';
import 'package:jablab/shell_candidate/live_surface.dart'
    show LiveCoachSurface, LiveState;

/// SORUMLULUK EKSENİ EKRANA ULAŞIYOR MU (J-110).
///
/// ## Neden metin testi YETMEZ
///
/// J-103 *"sen kadrajda değilsin"* ile *"benim okumam bozuk"* farkını
/// METİNDE ayırdı ve testi de metni ölçtü — geçti. Ama telefon 2-3 m uzakta
/// ve kullanıcının okuduğu **ilk şey renk, ikinci şey ikon, cümle üçüncü**.
/// Düzeltme doğruydu ve kullanıcıya ULAŞMIYORDU. Bu dosya o boşluğu ölçer:
/// ayrımın GÖRSEL tarafı gerçekten farklı mı çiziliyor.
void main() {
  test('üç kovanın rengi de BİRBİRİNDEN farklı', () {
    // Ayrım "var" ama iki kova aynı renkteyse ayrım YOK demektir — ve bunu
    // gözle fark etmek zor, testle kolay.
    final Set<Color> colors =
        LiveHonestyBucket.values.map((LiveHonestyBucket b) => b.accent).toSet();
    expect(colors.length, LiveHonestyBucket.values.length,
        reason: 'iki kova aynı rengi paylaşıyor — uzaktan ayırt edilemez');
  });

  test('üç kovanın ikonu da BİRBİRİNDEN farklı', () {
    final Set<IconData> icons =
        LiveHonestyBucket.values.map((LiveHonestyBucket b) => b.icon).toSet();
    expect(icons.length, LiveHonestyBucket.values.length);
  });

  test('HİÇBİR kova HÜKÜM (ember) tonunu kullanmıyor', () {
    // Ember tasarımda Tier 3'e — HÜKÜM katmanına — rezerve. "Göremiyorum"
    // bir hüküm değil; ember'a kaymak, susan bir katmanı konuşuyormuş gibi
    // göstermek olurdu.
    for (final LiveHonestyBucket b in LiveHonestyBucket.values) {
      expect(b.accent, isNot(JColors.ember),
          reason: '$b hüküm tonunu kullanıyor');
    }
  });

  testWidgets('DONMUŞ yüzeyin "göremiyorum" ikonu ARTIK KIRMIZI DEĞİL',
      (WidgetTester t) async {
    // Kusurun kendisi buydu: `LiveCoachSurface` ikonu `colorScheme.error`
    // ile çiziyor ve bu HER dürüst hâle basılıyordu. "Kimse yok" bir hata
    // değildir — kırmızı, kullanıcıya yanlış bir şey yaptığını söyler.
    // Widget DONMUŞ; renk `Theme` sarmalıyla dışarıdan geliyor.
    for (final LiveHonestyBucket bucket in LiveHonestyBucket.values) {
      await t.pumpWidget(MaterialApp(
        home: Theme(
          data: bucket.themeFor(jablabSessionTheme),
          child: Scaffold(
            body: LiveCoachSurface(
              state: LiveState.noVerdict,
              eventCount: null,
              noVerdictReason: 'test',
              preview: SkeletonPreview(
                  state: LiveState.noVerdict, bucket: bucket),
            ),
          ),
        ),
      ));

      final Iterable<Icon> icons = t.widgetList<Icon>(find.byType(Icon));
      expect(icons, isNotEmpty);
      final Icon judgementIcon = icons.firstWhere(
          (Icon i) => i.icon == Icons.visibility_off_outlined,
          orElse: () => throw StateError('donmuş yüzeyin ikonu bulunamadı — '
              'kabuk değişmiş olabilir, bu test onu ölçüyor'));
      expect(judgementIcon.color, bucket.accent,
          reason: '$bucket kovası donmuş yüzeye ULAŞMIYOR — Theme sarmalı '
              'kopmuş ve ikon varsayılan hata rengine dönmüş');
      expect(judgementIcon.color, isNot(const ColorScheme.dark().error),
          reason: 'hata kırmızısı geri gelmiş');
    }
  });

  testWidgets('kova ikonu ÖNİZLEME yuvasında görünüyor', (WidgetTester t) async {
    // İkon ekseni donmuş yüzeyden değil app'in KENDİ yuvasından geliyor
    // (`LiveCoachSurface`in ikonu sabit ve değiştirilemiyor). Bu test o
    // taşımanın gerçekten çalıştığını ölçüyor — yoksa üç kova aynı ikonla
    // çizilir ve renk tek başına kalır.
    for (final LiveHonestyBucket bucket in LiveHonestyBucket.values) {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SkeletonPreview(state: LiveState.noVerdict, bucket: bucket),
        ),
      ));
      expect(find.byIcon(bucket.icon), findsOneWidget,
          reason: '$bucket ikonu önizlemede çizilmiyor');
    }
  });
}
