import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:motion_core/motion_core.dart';

/// `stance` kanonik referansını üç bağımsız eğitmen hasadından üretir.
///
/// **Tolerans MUHAFAZAKÂR alınır (J-032).** M-C-04'ün sert eşiği (≥3 eğitmen)
/// sağlandı ama M-F-32'nin ~5 hedefi sağlanmadı; n=3 ile eğitmenler-arası
/// varyans tahmini geniş güven aralığı taşır. İlk sürümde dar tolerans yazmak,
/// kullanıcıya haksız yere "yanlış" demek olurdu.
///
/// Kullanım:
///   dart run tool/build_stance_reference.dart
void main() {
  const String lib = '/Users/mustafakaankocak/motion-harvest/jablab/landmarks';
  const List<({String id, String file, String source})> takes =
      <({String id, String file, String source})>[
    (id: 'yankello', file: 'yA5WNu-sx34.full.json', source: 'Tom Yankello'),
    (id: 'kennyweldon', file: 'InSkFbZWoBY.full.json', source: 'Kenny Weldon'),
    (id: 'mcleodscott', file: 'ZzqFgVBttIc.full.json', source: 'Sam McLeod'),
  ];

  final List<ReferenceTake> built = <ReferenceTake>[];
  final List<_Segment> segs = <_Segment>[];
  for (final ({String id, String file, String source}) t in takes) {
    final _Segment? seg = _bestStanceSegment(File('$lib/${t.file}'));
    if (seg == null) {
      stderr.writeln('⚠️  ${t.id}: kararlı duruş penceresi bulunamadı — ATLANDI');
      continue;
    }
    stdout.writeln('• ${t.id.padRight(14)} t=${(seg.startMs / 1000).toStringAsFixed(1)}s '
        '· ${seg.angles.length} kare · enerji ${seg.energy.toStringAsFixed(4)} '
        '· ÖNCÜ=${seg.leadIsLeft ? "SOL (orthodox)" : "SAĞ (southpaw)"} '
        '(güven ${seg.leadConfidence.toStringAsFixed(2)})');
    segs.add(seg);
    built.add(ReferenceTake(id: t.id, frames: seg.angles, source: t.source));
  }

  if (built.length < 3) {
    stderr.writeln('❌ ${built.length} take — M-C-04 ≥3 sağlanmıyor, referans ÜRETİLMEZ');
    exit(1);
  }

  const ReferenceBuilder builder = ReferenceBuilder();

  // ═══ AYRIŞTIRMA SINAMASI (M-F-37) ═══
  // Hipotez (b): kol ayrışması artefakt olabilir — take'ler orthodox/southpaw
  // karışımıysa kollar maksimum ayrışır, bacaklar (görece simetrik) uyumlu
  // görünür. n=3'te ReferenceBuilder'ın aynalama konsensüsü zayıf; bu yüzden
  // öncü-taraf ÖNSELİYLE çapalayıp yeniden kuruyoruz.
  final int leftLead = segs.where((_Segment s) => s.leadIsLeft).length;
  final bool mixed = leftLead != 0 && leftLead != segs.length;
  stdout.writeln('\nöncü taraf dağılımı  : $leftLead sol / ${segs.length - leftLead} sağ '
      '→ ${mixed ? "KARIŞIK (hipotez b canlı)" : "TEK YÖNLÜ (hipotez b elendi)"}');

  // M-J-06 (0.5.0): ölçülmüş öncü-taraf ÖNSELİ konsensüsü ezer. Kendi
  // geometrik tespitimizi prior olarak veriyoruz — "düzeltme değil sigorta":
  // n<5'te konsensüs zayıftır ve yanlış çözüldüğünde SESSİZDİR.
  final Map<String, bool> prior = <String, bool>{
    for (int i = 0; i < built.length; i++) built[i].id: segs[i].leadIsLeft,
  };
  // M-F-47 anlasma kapisi bu kumeyi REDDEDIYOR (22,8-29,5 derece). Kapinin
  // ne gorduğunu anlamak icin gevsetilmis esikle de kuruyoruz — eklem-bazli
  // tablonun degisip degismedigi asil soru.
  CanonicalReference? gated;
  try {
    gated = builder.build(built, leadSidePrior: prior);
  } on Object catch (e) {
    stdout.writeln('\n⛔ M-F-47 ANLASMA KAPISI: $e');
  }
  final CanonicalReference ref =
      gated ?? builder.build(built, leadSidePrior: prior, clusterToleranceDeg: 60);

  stdout.writeln('\n─── 0.5.0 kapıları ───');
  stdout.writeln('önselle uyuşmayan take : '
      '${ref.priorDisagreements.isEmpty ? "yok" : ref.priorDisagreements.join(", ")}');
  stdout.writeln('ayna kararı güvenli mi : ${ref.mirrorConfident}');
  stdout.writeln('anlaşma kapısı dışladı : '
      '${ref.excludedOutlierIds.isEmpty ? "yok" : ref.excludedOutlierIds.join(", ")}');

  // Çapalı sürüm: azınlık tarafı aynalanır, hepsi aynı öncü tarafa getirilir.
  final bool anchorLeft = leftLead * 2 >= segs.length;
  final List<ReferenceTake> anchored = <ReferenceTake>[
    for (int i = 0; i < built.length; i++)
      segs[i].leadIsLeft == anchorLeft ? built[i] : built[i].mirrored(),
  ];
  final CanonicalReference refAnchored = builder.build(anchored,
      leadSidePrior: prior, clusterToleranceDeg: 60);

  stdout.writeln('\n═══ CANONICAL REFERENCE: stance ═══');
  stdout.writeln('katkı veren take     : ${ref.contributingTakes}');
  stdout.writeln('kaynaklar            : ${ref.sources.join(" · ")}');
  stdout.writeln('aynalanan take       : ${ref.mirroredTakeIds.isEmpty ? "yok" : ref.mirroredTakeIds.join(",")}');
  stdout.writeln('referans kare sayısı : ${ref.frames.length}');

  final List<String> unreliable = ref.unreliableJoints();
  stdout.writeln('güvenilmez eklemler  : ${unreliable.isEmpty ? "yok" : unreliable.join(", ")}');

  // Uyum eğrisi: eğitmenler nerede anlaşıyor, nerede ayrışıyor.
  final List<double> agreements = <double>[
    for (int i = 0; i < ref.frames.length; i++) ref.agreementAt(i),
  ];
  agreements.sort();
  double q(double p) => agreements[(p * (agreements.length - 1)).round()];
  stdout.writeln('uyum (agreement)     : medyan ${q(0.5).toStringAsFixed(3)} '
      '· p10 ${q(0.1).toStringAsFixed(3)} · p90 ${q(0.9).toStringAsFixed(3)}');

  // J-032 MUHAFAZAKÂRLIK: n=3 ile eğitmenler-arası varyans tahmini geniş
  // güven aralığı taşır. Serbest bandın TABANINI yükseltiyoruz (8°→14°) —
  // yani "kesin yanlış" demeden önce daha çok sapmaya izin veriyoruz.
  // Dar tolerans yazmak, ölçemediğimiz varyansı kullanıcının hatası saymaktır.
  const double conservativeFloorDeg = 14;

  stdout.writeln('\n─── toleranceAt bantları (orta kare) — varsayılan vs MUHAFAZAKÂR ───');
  final int mid = ref.frames.length ~/ 2;
  final List<JointSpec> specs = ref.frames[mid].specs;
  const double radToDeg = 180 / math.pi;
  final Set<String> unreliableSet = unreliable.toSet();
  for (int j = 0; j < specs.length; j++) {
    final Tolerance d = ref.toleranceAt(mid, j);
    final Tolerance c =
        ref.toleranceAt(mid, j, freeFloorDeg: conservativeFloorDeg);
    final String flag = unreliableSet.contains(specs[j].id) ? '  ⚠️' : '';
    stdout.writeln('  ${specs[j].id.padRight(24)} '
        'serbest ${(d.free * radToDeg).toStringAsFixed(1)}° → '
        '${(c.free * radToDeg).toStringAsFixed(1)}°   '
        'sıfır ${(d.zeroAt * radToDeg).toStringAsFixed(0)}° → '
        '${(c.zeroAt * radToDeg).toStringAsFixed(0)}°$flag');
  }
  // ── Çapalı vs çapasız karşılaştırma ──
  double armDispersion(CanonicalReference r) {
    const List<String> arms = <String>[
      'left_elbow', 'right_elbow', 'left_upper_arm',
      'right_upper_arm', 'left_forearm', 'right_forearm',
    ];
    final int m = r.frames.length ~/ 2;
    final List<JointSpec> sp = r.frames[m].specs;
    double sum = 0;
    int n = 0;
    for (int j = 0; j < sp.length; j++) {
      if (!arms.contains(sp[j].id)) continue;
      final double d = r.dispersion[m][j];
      if (d.isNaN) continue;
      sum += d * 180 / math.pi;
      n++;
    }
    return n == 0 ? double.nan : sum / n;
  }

  stdout.writeln('\n═══ AYRIŞTIRMA SINAMASI ═══');
  stdout.writeln('kol dispersiyonu  çapasız: ${armDispersion(ref).toStringAsFixed(1)}°  '
      '→ öncü-taraf ÇAPALI: ${armDispersion(refAnchored).toStringAsFixed(1)}°');
  stdout.writeln('güvenilmez eklem  çapasız: ${ref.unreliableJoints().length}  '
      '→ çapalı: ${refAnchored.unreliableJoints().length}');
  final double a0 = List<double>.generate(
          ref.frames.length, (int i) => ref.agreementAt(i))
      .reduce((double a, double b) => a + b) / ref.frames.length;
  final double a1 = List<double>.generate(
          refAnchored.frames.length, (int i) => refAnchored.agreementAt(i))
      .reduce((double a, double b) => a + b) / refAnchored.frames.length;
  stdout.writeln('ortalama uyum     çapasız: ${a0.toStringAsFixed(3)}  '
      '→ çapalı: ${a1.toStringAsFixed(3)}');
  stdout.writeln(armDispersion(refAnchored) < armDispersion(ref) * 0.7
      ? '\n>>> HÜKÜM: kol ayrışması ARTEFAKTTI — aynalama çözülmemişti.'
      : '\n>>> HÜKÜM: çapalama düzeltmedi — kol ayrışması GERÇEK stil varyansı.');

  stdout.writeln('\n⚠️  TOLERANS MUHAFAZAKÂR (J-032): n=3 eğitmen, M-F-32 hedefi ~5;');
  stdout.writeln('    serbest bant tabanı 8°→${conservativeFloorDeg.toStringAsFixed(0)}°.');
  stdout.writeln('    4./5. eğitmen geldiğinde YENİDEN HESAPLANACAK.');
}

class _Segment {
  _Segment(this.startMs, this.angles, this.energy, this.leadIsLeft, this.leadConfidence);
  final double startMs;
  final List<JointAngleVector> angles;
  final double energy;

  /// GEOMETRİK öncü-taraf tespiti (M-F-06: landmark ETİKETİNE güvenilmez).
  final bool leadIsLeft;

  /// Pencerede tespitin ne kadar tutarlı olduğu (0-1).
  final double leadConfidence;
}

/// En kararlı "gard duruşu" penceresini bulur.
///
/// Duruş **sürdürülen** bir postürdür: doğru pencere, hareket enerjisinin en
/// düşük olduğu ve pozun gard-benzeri kaldığı yerdir. Videonun tamamını
/// referans almak konuşma/başka teknik/yürüme karelerini de katardı.
_Segment? _bestStanceSegment(File f) {
  final Map<String, dynamic> doc =
      (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>();
  if (doc['schemaVersion'] != 2) {
    throw StateError('beklenmeyen şema: ${doc['schemaVersion']}');
  }
  final List<int> wh = (doc['recordingMeta']['resolution'] as String)
      .split('x')
      .map(int.parse)
      .toList(growable: false);
  final FrameSize size = FrameSize(wh[0], wh[1]);

  final List<PoseFrame> frames = <PoseFrame>[];
  for (final dynamic raw in doc['frames'] as List<dynamic>) {
    final Map<String, dynamic> fr = (raw as Map).cast<String, dynamic>();
    if (fr['detected'] != true) continue;
    final List<dynamic> lm = fr['lm'] as List<dynamic>;
    frames.add(PoseFrame(
      tUs: ((fr['t'] as num) * 1000).round(),
      modelVersion: 'harvest-v2',
      landmarks: List<PoseLandmark>.generate(lm.length, (int i) {
        final List<dynamic> p = lm[i] as List<dynamic>;
        return PoseLandmark((p[0] as num).toDouble(), (p[1] as num).toDouble(),
            (p[2] as num).toDouble(), (p[3] as num).toDouble());
      }, growable: false).map((PoseLandmark l) => l).toList(growable: false),
    ).toIsotropic(size));
  }
  if (frames.length < 120) return null;

  // Gard testi: iki bilek de kalça hizasının ÜSTÜNDE, ayaklar ayrık.
  bool guardLike(PoseFrame p) {
    final double hipY =
        (p.point(Lm.leftHip).y + p.point(Lm.rightHip).y) / 2;
    final double shoulderW =
        (p.point(Lm.leftShoulder) - p.point(Lm.rightShoulder)).length;
    if (shoulderW < 1e-6) return false;
    final double ankleGap =
        (p.point(Lm.leftAnkle).x - p.point(Lm.rightAnkle).x).abs() / shoulderW;
    return p.point(Lm.leftWrist).y < hipY &&
        p.point(Lm.rightWrist).y < hipY &&
        ankleGap > 0.3;
  }

  const int win = 90; // ~3 sn @30fps
  double best = double.infinity;
  int bestStart = -1;
  for (int i = 0; i + win < frames.length; i += 15) {
    double energy = 0;
    int guard = 0;
    for (int k = i; k < i + win; k++) {
      if (guardLike(frames[k])) guard++;
      if (k > i) {
        energy += (frames[k].point(Lm.leftWrist) -
                    frames[k - 1].point(Lm.leftWrist))
                .length +
            (frames[k].point(Lm.rightWrist) - frames[k - 1].point(Lm.rightWrist))
                .length;
      }
    }
    if (guard < win * 0.8) continue; // pencere boyunca gard korunmalı
    energy /= win;
    if (energy < best) {
      best = energy;
      bestStart = i;
    }
  }
  if (bestStart < 0) return null;

  // ÖNCÜ TARAF — geometrik. Omuz çizgisinin yönü hangi omzun önde olduğunu
  // söyler; öndeki ayak da aynı tarafta olur. Modelin left/right etiketine
  // DEĞİL, iki noktanın birbirine göre konumuna bakılıyor (M-F-06).
  int leftLeadVotes = 0;
  int votes = 0;
  for (int k = bestStart; k < bestStart + win; k++) {
    final PoseFrame p = frames[k];
    final double lsx = p.point(Lm.leftShoulder).x;
    final double rsx = p.point(Lm.rightShoulder).x;
    final double lax = p.point(Lm.leftAnkle).x;
    final double rax = p.point(Lm.rightAnkle).x;
    if ((lax - rax).abs() < 1e-6) continue;
    votes++;
    final bool leftLeads = lsx < rsx ? lax < rax : lax > rax;
    if (leftLeads) leftLeadVotes++;
  }
  final double ratio = votes == 0 ? 0.5 : leftLeadVotes / votes;

  final PosePipeline pipe = PosePipeline();
  final List<JointAngleVector> angles = <JointAngleVector>[];
  for (int k = bestStart; k < bestStart + win; k += 3) {
    angles.add(pipe.process(frames[k]).angles);
  }
  return _Segment(frames[bestStart].tUs / 1000, angles, best,
      ratio >= 0.5, (ratio - 0.5).abs() * 2);
}
