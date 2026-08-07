/// JabLab tasarım tokenları — `JabLab.dc.html` "Spec board"tan BİREBİR
/// (design turu, koordinatör Hüküm 1/2/3, 2026-08-06). Sayı/renk/eğri
/// buraya ELLE tahmin edilerek değil, tasarım dosyasının kendi spec
/// bölümünden okunarak girildi (`§ palette`, `§ type scale`, `§ glass`,
/// `§ motion tokens`).
///
/// Bu dosya `lib/shell_candidate/` DEĞİL — tema tamamen JabLab'a özgü
/// (kırmızı/ember/cool üçlüsü "her app tamamen farklı" kurucu kararının
/// ta kendisi, M-F-279), dondurulmuş kabuk envanterine eklenmedi.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OKLCH(lightness 0-1, chroma, hue-derece) → sRGB [Color].
///
/// Björn Ottosson'un OKLab tanımının standart matrisleri (CSS Color 4 aynı
/// matrisleri kullanır). Tasarım dosyası renkleri `oklch(...)` yazıyor;
/// hex buraya ELLE kopyalanmadı — dönüşüm koddadır, sayı tasarımla
/// birebir izlenebilir kalsın diye (bir sonraki tur oklch değerini
/// değiştirirse hex bayatlamaz).
Color oklch(double l, double c, double hDeg, [double alpha = 1]) {
  final double h = hDeg * math.pi / 180;
  final double a = c * math.cos(h);
  final double b = c * math.sin(h);

  final double lp = l + 0.3963377774 * a + 0.2158037573 * b;
  final double mp = l - 0.1055613458 * a - 0.0638541728 * b;
  final double sp = l - 0.0894841775 * a - 1.2914855480 * b;

  final double l3 = lp * lp * lp;
  final double m3 = mp * mp * mp;
  final double s3 = sp * sp * sp;

  final double rLin = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
  final double gLin = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  final double bLin = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  double gamma(double x) {
    final double v = x.clamp(0.0, 1.0);
    return v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
  }

  int byte(double x) => (gamma(x) * 255).round().clamp(0, 255);
  return Color.fromARGB((alpha * 255).round().clamp(0, 255), byte(rLin), byte(gLin), byte(bLin));
}

/// § PALETTE — "No green anywhere" (tasarımın kendi kuralı, §6.4 karşılığı).
class JColors {
  JColors._();

  static const Color ground = Color(0xFF0A0608);
  static final Color backdropCore = oklch(.34, .14, 27);
  static final Color accent = oklch(.56, .195, 24); // scarlet
  static final Color ember = oklch(.76, .155, 46); // JUDGEMENT ONLY
  static final Color deep = oklch(.30, .135, 26);

  static const Color cool = Color(0xFFAFC0CE); // OBSERVATION ONLY
  static final Color cool2 = cool.withValues(alpha: .62);
  static final Color cool3 = cool.withValues(alpha: .34);

  static const Color ink = Color(0xFFF7F4F5);
  static final Color ink2 = ink.withValues(alpha: .64);
  static final Color ink3 = ink.withValues(alpha: .40);
  static final Color ink4 = ink.withValues(alpha: .22);

  static const Color border = Color(0x24FFFFFF); // rgba(255,255,255,.14)
  static const Color hairline = Color(0x2EFFFFFF); // rgba(255,255,255,.18)
}

/// § TYPE SCALE — iki aile, tek kural: **mono yalnız ÖLÇÜLEN şeyler için**
/// (saat, sayaç, teknik sebep). Öznel hiçbir şey mono'da DİZİLMEZ.
class JText {
  JText._();

  static TextStyle correction = GoogleFonts.familjenGrotesk(
      fontSize: 40, fontWeight: FontWeight.w700, height: .96, letterSpacing: -1.4, color: JColors.ink);

  static TextStyle clock = GoogleFonts.ibmPlexMono(
      fontSize: 76,
      fontWeight: FontWeight.w500,
      height: .9,
      letterSpacing: -3.0,
      color: JColors.ink,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]);

  static TextStyle pageTitle = GoogleFonts.familjenGrotesk(
      fontSize: 46, fontWeight: FontWeight.w700, height: 1, letterSpacing: -1.6, color: JColors.ink);

  static TextStyle body = GoogleFonts.familjenGrotesk(
      fontSize: 17, fontWeight: FontWeight.w400, height: 1.35, color: JColors.ink);

  static TextStyle bodyMuted = body.copyWith(color: JColors.ink2, fontSize: 15);

  static TextStyle label = GoogleFonts.ibmPlexMono(
      fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.8, color: JColors.cool2);

  /// ⚠️ Varsayılan renk `ink3`ten `ink2`ye ÇEKİLDİ (J-116). ÖLÇÜLDÜ:
  /// `ink3` 12 puntoda zemine karşı **3,51:1**, WCAG 2.2 AA'nın normal
  /// metin eşiği **4,5**. Bu token "ölçülen şeyler" için — saat, sayaç,
  /// teknik sebep — yani okunması GEREKEN yerler. `ink2` 7,61:1.
  ///
  /// Sönüklük hiyerarşisi KAYBOLMADI: `ink` (18,43) ile `ink2` (7,61)
  /// arasında hâlâ belirgin bir fark var ve ikisi de eşiği geçiyor.
  /// Kaybolan tek şey, okunamayacak kadar sönük olma seçeneği.
  static TextStyle mono = GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w400, color: JColors.ink2);
}

/// Ders akışının frozen kabuk parçalarını (`SessionFlowScaffold`,
/// `LiveCoachSurface`, `SessionSummaryView`, `IntervalTimer` —
/// `shell_candidate/`, `motion_shell` adayı) DEĞİŞTİRMEDEN dışarıdan
/// giydirmek için. Settings/Sayfa A/B'nin aksine bu parçalar `JColors`/
/// `JText`i DOĞRUDAN okuyamaz — yalnız `Theme.of(context)` üzerinden
/// beslenirler, o yüzden token'lar burada bir `ThemeData`ya eşleniyor ve
/// `Theme(data: jablabSessionTheme, child: ...)` ile o alt ağaca sarılıyor
/// (bkz. `session_screen.dart`). Eşleme yalnız o dört bileşenin GERÇEKTEN
/// okuduğu alanları kapsıyor — kullanılmayan bir `TextTheme` girişi icat
/// edilmedi.
final ThemeData jablabSessionTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: JColors.ground,
  colorScheme: ColorScheme.fromSeed(
    seedColor: JColors.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primaryContainer: JColors.ember.withValues(alpha: .28),
    error: JColors.ember,
    outline: JColors.ink3,
    surfaceContainerHighest: JColors.deep,
  ),
  textTheme: TextTheme(
    // `_Teach`in ders başlığı (session_screen.dart).
    headlineSmall: JText.pageTitle.copyWith(fontSize: 26, letterSpacing: -.8),
    // `LiveCoachSurface`in DÜZELTME yuvası — JText.correction'ın ta kendisi
    // için var olduğu yer (§ TYPE SCALE dokümanı).
    titleLarge: JText.correction,
    // "Keep going" (temiz hâl).
    titleMedium: JText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 17),
    // Özet bant değerleri + "Coached but not scored" başlığı.
    titleSmall: JText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
    bodyMedium: JText.body,
    bodySmall: JText.bodyMuted,
    // Anlatı (narration) — GÖZLEM tonlu, hüküm değil.
    labelLarge: JText.mono.copyWith(color: JColors.cool2, fontSize: 13),
    labelMedium: JText.label,
    // `IntervalTimer`in geri sayımı — SAYAÇ, mono ailesinin tam da var
    // olduğu yer.
    displaySmall: JText.clock.copyWith(fontSize: 44, letterSpacing: -1.6),
    // Yumruk/olay sayacı (canlı VE özet) — aynı gerekçe.
    displayMedium: JText.clock,
  ),
  // ⚠️ ÖLÇÜLDÜ (simülatör, design turu Parça 2, 2026-08-06): `Chip`
  // (`SessionFlowScaffold`in aşama rozetleri — Learn/Try/Live/Summary)
  // VARSAYILAN olarak `textTheme.labelLarge`i okuyor — bu, narration için
  // BİLEREK mono seçilen stille AYNI yuva. Sonuç: "Learn"/"Live" rozetlerde
  // KIRPILIYORDU ("Lear"/"Liv") — mono harfler aynı punto boyutunda daha
  // GENİŞ, sabit rozet genişliğine sığmadı. `chipTheme` AÇIKÇA ayrılıyor ki
  // narration'ın mono kimliği (JText'in "yalnız ÖLÇÜLEN şeyler" kuralı)
  // aşama ETİKETLERİNE (ölçüm değil, gezinme) sızmasın.
  chipTheme: ChipThemeData(
    labelStyle: JText.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
  ),
);

/// § MOTION TOKENS — "No curve overshoots. JabLab arrives and stops."
class JMotion {
  JMotion._();

  static const Duration snapIn = Duration(milliseconds: 180);
  static const Duration panelIn = Duration(milliseconds: 260);
  static const Duration takeover = Duration(milliseconds: 420);
  static const Duration scene = Duration(milliseconds: 340);
  static const Duration countTick = Duration(milliseconds: 120);
  static const Duration roundFlip = Duration(milliseconds: 300);

  static const Curve sharp = Cubic(.16, 1, .24, 1);
  static const Curve snap = Cubic(.55, 0, .1, 1);
}

enum GlassTier {
  /// Tier 1 — dinlenme hâli, çoğu panel.
  resting,

  /// Tier 2 — gözlem (cool/mavi-gri tonlu; saat, sayaç, anlatı).
  observation,

  /// Tier 3 — hüküm (yalnız TEK düzeltme burada; ember; tek glow taşıyan katman).
  judgement,
}

/// § GLASS · THREE TIERS — buzlu cam katmanları, tasarımdan BİREBİR
/// (`blur 26 · sat 125%` her katmanda; ember yalnız Tier 3'te, glow yalnız
/// Tier 3'te). CSS `backdrop-filter: blur(26px)` ile Flutter'ın
/// `ImageFilter.blur` sigma'sı BİREBİR aynı birim değil — sigma ~13,
/// görsel olarak eşdeğer yoğunluk için yaklaşık değer (kesin ölçü yok,
/// CSS ve Skia farklı blur çekirdekleri kullanıyor).
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.tier = GlassTier.resting,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.margin,
  });

  final Widget child;
  final GlassTier tier;
  final EdgeInsets padding;
  final double borderRadius;
  final EdgeInsets? margin;

  static const double _blurSigma = 13;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(borderRadius);
    final Color fill = switch (tier) {
      GlassTier.resting => const Color(0x13E4ECF3),
      GlassTier.observation => JColors.cool.withValues(alpha: .095),
      GlassTier.judgement => JColors.ember.withValues(alpha: .16),
    };
    final Color edge = switch (tier) {
      GlassTier.resting => JColors.border,
      GlassTier.observation => JColors.cool.withValues(alpha: .24),
      GlassTier.judgement => JColors.ember.withValues(alpha: .5),
    };
    // ⚠️ Gölge, KIRPILMAYAN bir dış katmanda — Gravita'nın kalıp-dersi
    // (koordinatör 2026-08-06): `BoxShadow` kutunun DIŞINA taşar, ama
    // `ClipRRect` çocuğunu kendi sınırına kırpar; gölgeyi `ClipRRect`in
    // İÇİNDEKİ `Container`a koymak onu görünmez yapardı (10 test bunu
    // Gravita'da kırmıştı). Cam-blur kırpması ayrı, gölge ayrı katman.
    Widget panel = Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: tier == GlassTier.judgement
            ? <BoxShadow>[
                BoxShadow(
                    color: JColors.deep.withValues(alpha: .4),
                    blurRadius: 40,
                    offset: const Offset(0, 12)),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: br,
              border: Border.all(color: edge),
            ),
            child: child,
          ),
        ),
      ),
    );
    if (margin != null) panel = Padding(padding: margin!, child: panel);
    return panel;
  }
}

/// Tier 2-d — "bilmiyorum". Kesikli kenar tasarımda REZERVE: yalnız
/// ölçülemeyen/okunamayan hâller için, hiçbir zaman dekoratif değil.
class UnknownGlassPanel extends StatelessWidget {
  const UnknownGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
        child: CustomPaint(
          painter: _DashedRRectPainter(radius: borderRadius, color: JColors.cool3),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(color: JColors.cool.withValues(alpha: .03), borderRadius: br),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Yuvarlak buzlu-cam ikon düğmesi — geri/köşe gezinme için ortak kalıp
/// (Ayarlar'da doğdu, Sayfa B/A da AYNI görsel dili istiyor; üç kopya yerine
/// tek paylaşılan widget).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: GlassPanel(
          tier: GlassTier.resting,
          borderRadius: 22,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: Icon(icon, size: 18, color: JColors.ink),
              tooltip: tooltip,
              onPressed: onTap,
            ),
          ),
        ),
      );
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius));
    final Path path = Path()..addRRect(rrect);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const double dashWidth = 5, gapWidth = 4;
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, math.min(next, metric.length)), paint);
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
