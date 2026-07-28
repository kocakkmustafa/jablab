import 'dart:math' as math;

import 'package:motion_core/motion_core.dart';

/// Hangi taraf önde: motorun taraf sözlüğü.
///
/// Motorun tamamı **lead/rear** ile konuşur, left/right ile DEĞİL (ADR-004).
/// Aile kuralı M-F-06: modelin `left/right` etiketine ham güvenilmez —
/// StructuralValidator kanıtladı ki model yüksek güvenle kol↔bacak takas
/// edebiliyor. Taraf kimliği bu yüzden **geometrik** kurulur.
enum Stance { orthodox, southpaw }

extension StanceSides on Stance {
  /// Öndeki (lead) tarafın landmark indeksleri.
  int get leadShoulder =>
      this == Stance.orthodox ? Lm.leftShoulder : Lm.rightShoulder;
  int get leadElbow => this == Stance.orthodox ? Lm.leftElbow : Lm.rightElbow;
  int get leadWrist => this == Stance.orthodox ? Lm.leftWrist : Lm.rightWrist;
  int get leadAnkle => this == Stance.orthodox ? Lm.leftAnkle : Lm.rightAnkle;
  int get leadFoot =>
      this == Stance.orthodox ? Lm.leftFootIndex : Lm.rightFootIndex;

  int get rearShoulder =>
      this == Stance.orthodox ? Lm.rightShoulder : Lm.leftShoulder;
  int get rearElbow => this == Stance.orthodox ? Lm.rightElbow : Lm.leftElbow;
  int get rearWrist => this == Stance.orthodox ? Lm.rightWrist : Lm.leftWrist;
  int get rearAnkle => this == Stance.orthodox ? Lm.rightAnkle : Lm.leftAnkle;
  int get rearFoot =>
      this == Stance.orthodox ? Lm.rightFootIndex : Lm.leftFootIndex;

  Stance get mirrored =>
      this == Stance.orthodox ? Stance.southpaw : Stance.orthodox;
}

/// Duruş tespitinin sonucu ve **ne kadar güvenilebileceği**.
final class StanceReading {
  const StanceReading({
    required this.stance,
    required this.confidence,
    required this.sideLabelsReportable,
    required this.reason,
  });

  final Stance stance;

  /// 0-1. Ayaklar birbirine çok yakınsa (kare duruş) düşer.
  final double confidence;

  /// M-F-06: kullanıcıya "sol/sağ" denip denemeyeceği.
  ///
  /// Yalnız kalibrasyon eşlemesi kurulmuş VE yapısal denetim temizken true.
  /// False iken UI taraf-agnostik dil kullanır ("lead hand", "rear hand") —
  /// footwork cue'ları (`step left`) susar.
  final bool sideLabelsReportable;

  final String reason;
}

/// Duruşu vücut geometrisinden okur — model etiketinden değil.
final class StanceDetector {
  const StanceDetector({
    this.minAnkleSeparation = 0.35,
    this.hysteresis = 0.12,
  });

  /// Ayak ayrımının omuz genişliğine oranı; altındaysa duruş "kare" sayılır
  /// ve önceki okuma korunur (histerezis) — kullanıcı adım atarken duruşun
  /// kare kare zıplaması, tüm lead/rear eşlemesini bozardı.
  final double minAnkleSeparation;

  final double hysteresis;

  /// [calibrationMapped] kalibrasyon sihirbazının taraf eşlemesini kurup
  /// kurmadığı; [structurallyClean] StructuralValidator'ın verdiği hüküm.
  StanceReading read(
    PoseFrame frame, {
    required bool calibrationMapped,
    required bool structurallyClean,
    Stance? previous,
    ({double width, double height})? frameSize,
  }) {
    // En-boy düzeltmesi ölçülerdekiyle AYNI nedenle zorunlu (J-028):
    // x genişliğe, y yüksekliğe ayrı normalize edilmiştir.
    final double sx = frameSize?.width ?? 1.0;
    final double sy = frameSize?.height ?? 1.0;
    Vec3 pt(int i) {
      final Vec3 p = frame.point(i);
      return Vec3(p.x * sx, p.y * sy, p.z * sx);
    }

    final Vec3 ls = pt(Lm.leftShoulder);
    final Vec3 rs = pt(Lm.rightShoulder);
    final Vec3 la = pt(Lm.leftAnkle);
    final Vec3 ra = pt(Lm.rightAnkle);

    final double shoulderWidth = _dist2(ls, rs);
    if (shoulderWidth <= 1e-6) {
      return StanceReading(
        stance: previous ?? Stance.orthodox,
        confidence: 0,
        sideLabelsReportable: false,
        reason: 'omuz genişliği ölçülemedi',
      );
    }

    // Duruş derinliği: hangi ayak kameraya göre ÖNDE. Ön-eğik kamerada
    // (ADR-003) derinlik farkı görüntü düzleminde yatay ayrım olarak görünür.
    final double sep = (la.x - ra.x).abs() / shoulderWidth;
    if (sep < minAnkleSeparation - (previous != null ? hysteresis : 0.0)) {
      return StanceReading(
        stance: previous ?? Stance.orthodox,
        confidence: 0.2,
        sideLabelsReportable: false,
        reason: 'ayaklar hizada (kare duruş) — önceki okuma korundu',
      );
    }

    // Omuz çizgisinin yönü, hangi omzun önde olduğunu söyler; gard duruşunda
    // lead omuz daima hedefe (kameraya) daha yakındır.
    final bool leftLeads = ls.x < rs.x ? la.x < ra.x : la.x > ra.x;
    final Stance stance = leftLeads ? Stance.orthodox : Stance.southpaw;

    final double conf = (sep / (minAnkleSeparation * 2)).clamp(0.0, 1.0);
    return StanceReading(
      stance: stance,
      confidence: conf,
      sideLabelsReportable: calibrationMapped && structurallyClean,
      reason: calibrationMapped
          ? (structurallyClean ? 'geometrik okuma temiz' : 'yapısal denetim kirli')
          : 'kalibrasyon eşlemesi kurulmadı',
    );
  }
}

double _dist2(Vec3 a, Vec3 b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
