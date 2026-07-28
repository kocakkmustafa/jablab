import 'dart:math' as math;

import 'package:motion_core/motion_core.dart';

import 'stance.dart';

/// Bir karedeki tüm ölçüler.
///
/// **Tasarım kararı — hepsi AYNI KAREDEKİ oranlardır.** Hiçbir ölçü mutlak
/// piksele, kamera mesafesine veya bir kalibrasyon sabitine bölünmez; her biri
/// aynı karedeki bir başka vücut uzunluğuna oranlanır. Sonuç: ölçüler kamera
/// mesafesinden, çözünürlükten ve vücut ölçüsünden **yapısı gereği** bağımsız.
/// (Bu, D2 kapısındaki Python analizörüyle birebir aynı matematiktir — motor
/// ile ölçüm hattı aynı sayıyı üretmezse biri yanlıştır, ikisi de aynı
/// tanımdan türediği için karşılaştırılabilir.)
///
/// **2B çalışılır.** MediaPipe `z`'si tek başına güvenilecek kadar kararlı
/// değil; ADR-003'ün ön-eğik (~30-45°) kamera kararı kısmen bunun için alındı:
/// o açıda düz yumruk görüntü düzleminde ölçülebilir bir uzanma üretiyor.
final class MeasureSet {
  const MeasureSet._({
    required this.tUs,
    required this.stance,
    required Map<String, double> values,
    required this.feetCrossed,
  }) : _values = values;

  final int tUs;
  final Stance stance;
  final Map<String, double> _values;
  final bool feetCrossed;

  /// Ölçüyü adıyla okur. Anahtar `lead.` / `rear.` önekli olabilir; öneksiz
  /// taraf-bağımlı ölçüler [limb] tarafına çözülür.
  double? read(String key, {Side? limb}) {
    if (key.contains('.')) return _values[key];
    if (_sided.contains(key)) {
      final Side s = limb ?? Side.lead;
      return _values['${s.name}.$key'];
    }
    return _values[key];
  }

  Map<String, double> get all => Map<String, double>.unmodifiable(_values);

  /// Taraf-bağımlı ölçüler: öneksiz okunduklarında [Side]'a çözülürler.
  /// `extensionRatioDelta` buraya AİT — faz geçiş koşulları ve `localMax`
  /// vekili onu öneksiz sorar; listede olmazsa değer null döner ve EXTENSION
  /// fazı hiç açılmaz (sessiz kilitlenme).
  static const Set<String> _sided = <String>{
    'extensionRatio',
    'extensionRatioDelta',
    'guardHeightDelta',
    'elbowFlareAngle',
  };

  @override
  String toString() => 'MeasureSet(t=$tUs, ${_values.length} ölçü)';
}

enum Side { lead, rear }

/// Ölçüleri kareden hesaplar.
/// Kare boyutu — **en-boy düzeltmesi için zorunlu**.
///
/// MediaPipe normalize koordinatları `x`'i GENİŞLİĞE, `y`'yi YÜKSEKLİĞE ayrı
/// ayrı böler. Bu iki eksen farklı ölçekte olduğu için, piksel uzayına
/// dönmeden alınan her mesafe ve açı en-boy oranı kadar bozulur (1920×1080'de
/// dikey mesafeler ~1,78× küçük görünür). Hasat hattı ↔ motor çapraz
/// doğrulaması bu kusuru yakaladı (J-028).
typedef FrameSize = ({double width, double height});

final class MeasureCalculator {
  const MeasureCalculator();

  /// [frameSize] verilmezse koordinatların TEK ve tutarlı bir uzayda olduğu
  /// varsayılır (sentetik iskeletler böyledir). Gerçek kamera/hasat karesinde
  /// **verilmesi zorunludur**, yoksa ölçüler sessizce en-boy oranı kadar yanlış olur.
  MeasureSet compute(PoseFrame f, Stance stance,
      {MeasureSet? previous, FrameSize? frameSize}) {
    final double sx = frameSize?.width ?? 1.0;
    final double sy = frameSize?.height ?? 1.0;
    Vec3 pt(int i) {
      final Vec3 p = f.point(i);
      return Vec3(p.x * sx, p.y * sy, p.z * sx);
    }

    final Vec3 ls = pt(Lm.leftShoulder);
    final Vec3 rs = pt(Lm.rightShoulder);
    final Vec3 lh = pt(Lm.leftHip);
    final Vec3 rh = pt(Lm.rightHip);
    final Vec3 shoulderMid = _mid(ls, rs);
    final Vec3 hipMid = _mid(lh, rh);

    final double trunkLength = _dist(shoulderMid, hipMid);
    final double shoulderWidth = _dist(ls, rs);
    final Vec3 nose = pt(Lm.nose);

    final Map<String, double> v = <String, double>{};

    for (final Side side in Side.values) {
      final int sh = side == Side.lead ? stance.leadShoulder : stance.rearShoulder;
      final int el = side == Side.lead ? stance.leadElbow : stance.rearElbow;
      final int wr = side == Side.lead ? stance.leadWrist : stance.rearWrist;
      final Vec3 pSh = pt(sh);
      final Vec3 pEl = pt(el);
      final Vec3 pWr = pt(wr);

      // e = |bilek-omuz| / kol uzunluğu. Kol uzunluğu AYNI KAREDEN toplanır
      // (omuz-dirsek + dirsek-bilek), böylece kalibrasyon sabitine gerek yok.
      final double armLength = _dist(pSh, pEl) + _dist(pEl, pWr);
      v['${side.name}.extensionRatio'] =
          armLength > 1e-6 ? _dist(pWr, pSh) / armLength : 0;

      // Gard yüksekliği: bilek burnun NE KADAR ALTINDA (görüntüde y aşağı
      // büyür). Pozitif = gard düşmüş. Gövde boyuna oranlanır.
      v['${side.name}.guardHeightDelta'] =
          trunkLength > 1e-6 ? (pWr.y - nose.y) / trunkLength : 0;

      // Dirsek açılması: üst kolun gövde eksenine göre sapması. Dirsek
      // gövdeye yapışıkken üst kol gövdeyle ~paralel (küçük açı); dışa
      // açıldıkça 90°'ye yaklaşır.
      v['${side.name}.elbowFlareAngle'] =
          _angleBetween(pEl - pSh, hipMid - shoulderMid);
    }

    final Vec3 leadAnkle = pt(stance.leadAnkle);
    final Vec3 rearAnkle = pt(stance.rearAnkle);
    final double ankleSpan = _dist(leadAnkle, rearAnkle);

    v['stanceWidthRatio'] =
        shoulderWidth > 1e-6 ? ankleSpan / shoulderWidth : 0;

    // Gövde dikeyden sapması (derece).
    v['trunkLeanAngle'] = _angleBetween(shoulderMid - hipMid, const Vec3(0, -1, 0));

    // Omuz çizgisi ile kalça çizgisi arasındaki açı = gövde rotasyonu vekili.
    // ⚠️ 2B izdüşüm: gerçek transvers rotasyonun alt sınırıdır, tam değeri
    // değil. Cross'un rotasyon eşiği bu yüzden muhafazakâr tutulur.
    v['shoulderRotation'] = _lineAngleDiff(rs - ls, rh - lh);

    // Denge: kalça orta noktasının ayak tabanı üzerindeki izdüşümü.
    // t=0 arka ayak, t=1 ön ayak. Dışarı taşma miktarı ayrıca verilir.
    final double t = _projectParam(hipMid, rearAnkle, leadAnkle);
    v['frontFootLoadRatio'] = t.clamp(0.0, 1.0);
    v['copOverBase'] = t < 0 ? -t : (t > 1 ? t - 1 : 0.0);

    // Ayak çaprazlaması: ön ayak, duruş yönüne göre arka ayağın YANLIŞ
    // tarafına geçmişse.
    final bool crossed = stance == Stance.orthodox
        ? leadAnkle.x > rearAnkle.x
        : leadAnkle.x < rearAnkle.x;

    // Değişim hızları (faz geçiş koşulları bunlara bakar).
    if (previous != null) {
      for (final Side side in Side.values) {
        final String k = '${side.name}.extensionRatio';
        final double? now = v[k];
        final double? before = previous._values[k];
        if (now != null && before != null) {
          v['${side.name}.extensionRatioDelta'] = now - before;
        }
      }
    }

    return MeasureSet._(
      tUs: f.tUs,
      stance: stance,
      values: v,
      feetCrossed: crossed,
    );
  }
}

Vec3 _mid(Vec3 a, Vec3 b) => Vec3((a.x + b.x) / 2, (a.y + b.y) / 2, 0);

double _dist(Vec3 a, Vec3 b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

/// İki 2B vektör arasındaki açı, derece (0-180).
double _angleBetween(Vec3 u, Vec3 w) {
  final double lu = math.sqrt(u.x * u.x + u.y * u.y);
  final double lw = math.sqrt(w.x * w.x + w.y * w.y);
  if (lu < 1e-9 || lw < 1e-9) return 0;
  final double c = ((u.x * w.x + u.y * w.y) / (lu * lw)).clamp(-1.0, 1.0);
  return math.acos(c) * 180 / math.pi;
}

/// İki DOĞRU arasındaki açı (yön farkı önemsiz) — 0-90 derece.
double _lineAngleDiff(Vec3 u, Vec3 w) {
  final double a = _angleBetween(u, w);
  return a > 90 ? 180 - a : a;
}

/// [p]'nin [a]→[b] doğru parçası üzerindeki normalize izdüşümü.
double _projectParam(Vec3 p, Vec3 a, Vec3 b) {
  final double dx = b.x - a.x;
  final double dy = b.y - a.y;
  final double len2 = dx * dx + dy * dy;
  if (len2 < 1e-9) return 0.5;
  return ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2;
}
