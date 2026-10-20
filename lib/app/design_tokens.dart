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
  final double gLin =
      -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  final double bLin =
      -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  double gamma(double x) {
    final double v = x.clamp(0.0, 1.0);
    return v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
  }

  int byte(double x) => (gamma(x) * 255).round().clamp(0, 255);
  return Color.fromARGB(
    (alpha * 255).round().clamp(0, 255),
    byte(rLin),
    byte(gLin),
    byte(bLin),
  );
}

/// § PALETTE — "No green anywhere" (tasarımın kendi kuralı, §6.4 karşılığı).
class JColors {
  JColors._();

  static JPalette of(BuildContext context) =>
      JPalette.fromTheme(Theme.of(context));

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

  static JTypography of(BuildContext context) =>
      JTypography(JColors.of(context));

  static const String _familjenGrotesk = 'Familjen Grotesk';
  static const String _ibmPlexMono = 'IBM Plex Mono';

  static const TextStyle correction = TextStyle(
    fontFamily: _familjenGrotesk,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: .96,
    letterSpacing: -1.4,
    color: JColors.ink,
  );

  static const TextStyle clock = TextStyle(
    fontFamily: _ibmPlexMono,
    fontSize: 76,
    fontWeight: FontWeight.w500,
    height: .9,
    letterSpacing: -3.0,
    color: JColors.ink,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle pageTitle = TextStyle(
    fontFamily: _familjenGrotesk,
    fontSize: 46,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -1.6,
    color: JColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _familjenGrotesk,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: JColors.ink,
  );

  static final TextStyle bodyMuted = body.copyWith(
    color: JColors.ink2,
    fontSize: 15,
  );

  static final TextStyle label = TextStyle(
    fontFamily: _ibmPlexMono,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.8,
    color: JColors.cool2,
  );

  /// ⚠️ Varsayılan renk `ink3`ten `ink2`ye ÇEKİLDİ (J-116). ÖLÇÜLDÜ:
  /// `ink3` 12 puntoda zemine karşı **3,51:1**, WCAG 2.2 AA'nın normal
  /// metin eşiği **4,5**. Bu token "ölçülen şeyler" için — saat, sayaç,
  /// teknik sebep — yani okunması GEREKEN yerler. `ink2` 7,61:1.
  ///
  /// Sönüklük hiyerarşisi KAYBOLMADI: `ink` (18,43) ile `ink2` (7,61)
  /// arasında hâlâ belirgin bir fark var ve ikisi de eşiği geçiyor.
  /// Kaybolan tek şey, okunamayacak kadar sönük olma seçeneği.
  static final TextStyle mono = TextStyle(
    fontFamily: _ibmPlexMono,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: JColors.ink2,
  );
}

/// Immutable resolved semantic roles. Static JColors/JText members above
/// remain transitional dark-only compatibility APIs for unmigrated consumers.
/// New rendered UI reads JColors.of(context) and JText.of(context).
class JPalette extends ThemeExtension<JPalette> {
  const JPalette({
    required this.ground,
    required this.gradientTop,
    required this.surface,
    required this.accent,
    required this.onAccent,
    required this.judgement,
    required this.onJudgement,
    required this.observation,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.disabled,
    required this.outline,
    required this.focus,
    required this.glassResting,
    required this.glassObservation,
    required this.glassJudgement,
    required this.shadow,
  });

  final Color ground;
  final Color gradientTop;
  final Color surface;
  final Color accent;
  final Color onAccent;
  final Color judgement;
  final Color onJudgement;
  final Color observation;
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;
  final Color disabled;
  final Color outline;
  final Color focus;
  final Color glassResting;
  final Color glassObservation;
  final Color glassJudgement;
  final Color shadow;

  static final dark = JPalette(
    ground: JColors.ground,
    gradientTop: const Color(0xFF170809),
    surface: const Color(0xFF21181D),
    accent: JColors.accent,
    onAccent: JColors.ink,
    judgement: JColors.ember,
    onJudgement: const Color(0xFF180A05),
    observation: JColors.cool,
    ink: JColors.ink,
    inkMuted: const Color(0xFFB3ADB0),
    inkSubtle: const Color(0xFFA49BA1),
    disabled: const Color(0xFF766D72),
    outline: const Color(0xFF81747C),
    focus: JColors.cool,
    glassResting: const Color(0x13E4ECF3),
    glassObservation: JColors.cool.withValues(alpha: .095),
    glassJudgement: JColors.ember.withValues(alpha: .16),
    shadow: JColors.deep.withValues(alpha: .4),
  );

  // Proposed light roles: require effective-background/glyph/device review.
  // These values are draft design inputs, not a contrast or language PASS.
  static final light = JPalette(
    ground: const Color(0xFFFFF8F9),
    gradientTop: const Color(0xFFFBECEE),
    surface: const Color(0xFFFFFFFF),
    accent: JColors.accent,
    onAccent: JColors.ink,
    judgement: const Color(0xFF8B3F0F),
    onJudgement: const Color(0xFFFFFFFF),
    observation: const Color(0xFF345166),
    ink: const Color(0xFF251D22),
    inkMuted: const Color(0xFF584D55),
    inkSubtle: const Color(0xFF675C63),
    disabled: const Color(0xFF9F959B),
    outline: const Color(0xFF80717A),
    focus: const Color(0xFFB3261E),
    glassResting: const Color(0xE6FFFFFF),
    glassObservation: const Color(0xE6ECF1F5),
    glassJudgement: const Color(0xE6FAE8DD),
    shadow: const Color(0x1A4A1422),
  );

  static JPalette fromTheme(ThemeData theme) =>
      theme.extension<JPalette>() ??
      (theme.brightness == Brightness.dark ? dark : light);

  @override
  JPalette copyWith({
    Color? ground,
    Color? gradientTop,
    Color? surface,
    Color? accent,
    Color? onAccent,
    Color? judgement,
    Color? onJudgement,
    Color? observation,
    Color? ink,
    Color? inkMuted,
    Color? inkSubtle,
    Color? disabled,
    Color? outline,
    Color? focus,
    Color? glassResting,
    Color? glassObservation,
    Color? glassJudgement,
    Color? shadow,
  }) => JPalette(
    ground: ground ?? this.ground,
    gradientTop: gradientTop ?? this.gradientTop,
    surface: surface ?? this.surface,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    judgement: judgement ?? this.judgement,
    onJudgement: onJudgement ?? this.onJudgement,
    observation: observation ?? this.observation,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    inkSubtle: inkSubtle ?? this.inkSubtle,
    disabled: disabled ?? this.disabled,
    outline: outline ?? this.outline,
    focus: focus ?? this.focus,
    glassResting: glassResting ?? this.glassResting,
    glassObservation: glassObservation ?? this.glassObservation,
    glassJudgement: glassJudgement ?? this.glassJudgement,
    shadow: shadow ?? this.shadow,
  );

  @override
  JPalette lerp(covariant ThemeExtension<JPalette>? other, double t) {
    if (other is! JPalette) return this;
    return JPalette(
      ground: Color.lerp(ground, other.ground, t)!,
      gradientTop: Color.lerp(gradientTop, other.gradientTop, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      judgement: Color.lerp(judgement, other.judgement, t)!,
      onJudgement: Color.lerp(onJudgement, other.onJudgement, t)!,
      observation: Color.lerp(observation, other.observation, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkSubtle: Color.lerp(inkSubtle, other.inkSubtle, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      glassResting: Color.lerp(glassResting, other.glassResting, t)!,
      glassObservation: Color.lerp(
        glassObservation,
        other.glassObservation,
        t,
      )!,
      glassJudgement: Color.lerp(glassJudgement, other.glassJudgement, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Font geometry is preserved; every returned style resolves its current role.
class JTypography {
  const JTypography(this.colors);
  final JPalette colors;
  TextStyle get correction => JText.correction.copyWith(color: colors.ink);
  TextStyle get clock => JText.clock.copyWith(color: colors.ink);
  TextStyle get pageTitle => JText.pageTitle.copyWith(color: colors.ink);
  TextStyle get body => JText.body.copyWith(color: colors.ink);
  TextStyle get bodyMuted => JText.bodyMuted.copyWith(color: colors.inkMuted);
  TextStyle get label => JText.label.copyWith(color: colors.observation);
  TextStyle get mono => JText.mono.copyWith(color: colors.inkMuted);
}

ThemeData jablabTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? JPalette.dark : JPalette.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: brightness,
      ).copyWith(
        primary: p.accent,
        onPrimary: p.onAccent,
        secondary: p.observation,
        onSecondary: p.ground,
        surface: p.surface,
        onSurface: p.ink,
        onSurfaceVariant: p.inkMuted,
        error: p.accent,
        onError: p.onAccent,
        outline: p.outline,
      );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );
  return base.copyWith(
    scaffoldBackgroundColor: p.ground,
    cardColor: p.glassResting,
    disabledColor: p.disabled,
    focusColor: p.focus.withValues(alpha: .2),
    iconTheme: base.iconTheme.copyWith(color: p.inkSubtle),
    textTheme: base.textTheme.apply(
      fontFamily: 'Familjen Grotesk',
      bodyColor: p.ink,
      displayColor: p.ink,
    ),
    extensions: <ThemeExtension<dynamic>>[p],
  );
}

/// Context-preserving adapters for the frozen shell components. They keep
/// the resolved brightness, palette extension and all unrelated base settings.
ThemeData jablabSessionThemeFor(ThemeData base) {
  final p = JPalette.fromTheme(base);
  final text = JTypography(p);
  return base.copyWith(
    scaffoldBackgroundColor: p.ground,
    colorScheme: base.colorScheme.copyWith(
      primaryContainer: p.judgement.withValues(alpha: .28),
      error: p.judgement,
      outline: p.outline,
      surfaceContainerHighest: p.surface,
    ),
    textTheme: base.textTheme.copyWith(
      headlineSmall: text.pageTitle.copyWith(fontSize: 26, letterSpacing: -.8),
      titleLarge: text.correction,
      titleMedium: text.body.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
      titleSmall: text.body.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
      bodyMedium: text.body,
      bodySmall: text.bodyMuted,
      labelLarge: text.mono.copyWith(color: p.observation, fontSize: 13),
      labelMedium: text.label,
      displaySmall: text.clock.copyWith(fontSize: 44, letterSpacing: -1.6),
      displayMedium: text.clock,
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: text.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

ThemeData jablabHonestyThemeFor(ThemeData base) {
  final p = JPalette.fromTheme(base);
  final text = JTypography(p);
  return base.copyWith(
    cardColor: p.glassResting,
    cardTheme: base.cardTheme.copyWith(
      color: p.glassResting,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    iconTheme: base.iconTheme.copyWith(color: p.inkSubtle),
    textTheme: base.textTheme.copyWith(
      titleSmall: text.body.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
      bodySmall: text.bodyMuted,
    ),
  );
}

/// Immutable compatibility value for legacy tests. Production subtrees use
/// jablabSessionThemeFor(Theme.of(context)); this is never a mutable singleton.
final ThemeData jablabSessionTheme = jablabSessionThemeFor(
  jablabTheme(Brightness.dark),
);

/// ARALIK KİPİNİN DÜZELTME TONU (J-119, koordinatör hükmü 2026-08-07).
///
/// ## Neden ayrı bir ton, neden SUSTURMA değil
///
/// `cues.en.json`un aralık grup notu, form repliklerinin bu kipte
/// **susturulduğunu VARSAYIYORDU** — ve kod susturmuyordu. Gerekçesi
/// iyiydi: *yüksek tempoyu ürün istedi, sonra "formun bozuldu" demek kendi
/// tasarımına ceza kesmektir.*
///
/// Ama susturma seçeneğini ürünün kendi kuralı öldürüyor: **bu üründe
/// sessizlik "her şey yolunda" diye okunur.** Yani susmak nötr değil,
/// YANLIŞ bir şey söyler; susturulmuş bir replik, anlatısı olmayan bir
/// yokluktur ve kullanıcı o boşluğu kendi doldurur.
///
/// Çözüm üçüncü ilkeden geliyor: **ÖLÇÜM ≠ HÜKÜM.** *"Formun bozuldu"* bir
/// hüküm; *form bozulması* bir olgu ve gerçek. Olguyu saklamak kullanıcıdan
/// kendi vücuduna dair bir şeyi gizlemek olurdu. O yüzden replik ÇİZİLİR,
/// yalnız **hüküm tonundan gözlem tonuna** geçer.
///
/// Mekanizma J-110'un dil tarafı: aynı bilgi, farklı sorumluluk ekseni.
/// Orada renk/ikon ayırdı, burada TON ayırıyor — ve ton icat edilmedi,
/// tasarımın kendi katman sistemi kullanıldı (Tier 3 hüküm = `ink`
/// ağırlığı · Tier 2 gözlem = `cool`). Punto DÜŞÜRÜLMEDİ: kullanıcı 2-3 m
/// uzakta ve okunurluk tonun altında değil.
ThemeData jablabIntervalTone(ThemeData base) => base.copyWith(
  textTheme: base.textTheme.copyWith(
    titleLarge: JTypography(JPalette.fromTheme(base)).correction.copyWith(
      color: JPalette.fromTheme(base).observation,
      fontWeight: FontWeight.w500,
    ),
  ),
);

/// A fixed dark image/camera canvas with paired caption and observation
/// colors. It is content rendering, not an app-level forced-dark subtree.
/// Surrounding controls continue to resolve the app palette from context.
class JCameraCanvasAppearance {
  const JCameraCanvasAppearance({
    required this.background,
    required this.gradientTop,
    required this.captionScrim,
    required this.captionStyle,
    required this.observation,
    required this.neutralIcon,
    required this.noAnalysisIcon,
  });
  final Color background;
  final Color gradientTop;
  final Color captionScrim;
  final TextStyle captionStyle;
  final Color observation;
  final Color neutralIcon;
  final Color noAnalysisIcon;

  static final dark = JCameraCanvasAppearance(
    background: JPalette.dark.ground,
    gradientTop: JPalette.dark.shadow.withValues(alpha: .55),
    captionScrim: JPalette.dark.ground.withValues(alpha: .81),
    captionStyle: JTypography(JPalette.dark).mono.copyWith(fontSize: 11),
    observation: JPalette.dark.observation,
    neutralIcon: JPalette.dark.inkMuted,
    noAnalysisIcon: JPalette.dark.inkSubtle,
  );
}

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
    final colors = JColors.of(context);
    final Color fill = switch (tier) {
      GlassTier.resting => colors.glassResting,
      GlassTier.observation => colors.glassObservation,
      GlassTier.judgement => colors.glassJudgement,
    };
    final Color edge = switch (tier) {
      GlassTier.resting => colors.outline.withValues(alpha: .45),
      GlassTier.observation => colors.observation.withValues(alpha: .5),
      GlassTier.judgement => colors.judgement.withValues(alpha: .6),
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
                  color: colors.shadow,
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
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
          painter: _DashedRRectPainter(
            radius: borderRadius,
            color: JColors.of(context).outline,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: JColors.of(context).observation.withValues(alpha: .03),
              borderRadius: br,
            ),
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
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: GlassPanel(
      tier: GlassTier.resting,
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: SizedBox(
        // Keep the actual IconButton target at Android's 48dp minimum.
        width: 48,
        height: 48,
        child: IconButton(
          icon: Icon(icon, size: 18, color: JColors.of(context).ink),
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
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
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
        canvas.drawPath(
          metric.extractPath(distance, math.min(next, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
