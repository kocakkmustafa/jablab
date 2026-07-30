import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';

/// YUMRUK-TİPİ İMZA ÖLÇÜMÜ — betimsel, eşiksiz (J-073).
///
/// **Bu araç sınıflandırıcı DEĞİL ve bir eşik ÖNERMİYOR.** Koordinatör
/// çerçevesi (M-F-180): `combinations` dersinin kilidi için gereken şey önce
/// bir sınıflandırıcı değil bir ÖLÇÜM — mevcut jab/cross FSM'i hook
/// malzemesinde NE OKUYOR, ve iki yumruk tipinin ayırt edici kinematik
/// imzası MEVCUT fixture'larda nasıl görünüyor. Sınıf tasarımı ölçümden
/// SONRA gelir.
///
/// İki soruyu ayrı ayrı yanıtlar:
///  1. **Yanlış-pozitif sayım var mı?** FSM'in TAMAMLANMIŞ ilan ettiği her
///     denemeyi tekniğe göre sayar. Hook malzemesinde "jab tamamlandı"
///     çıkıyorsa, o ders bugün sessizce yanlış sayıyor demektir.
///  2. **İmza neye benziyor?** Her tamamlanmış denemenin PENCERESİ boyunca
///     ölçülerin (dirsek açılması, omuz rotasyonu, uzanma oranı, gövde
///     eğimi) min/maks/açıklığını toplar. Ayrım varsa burada görünür;
///     yoksa YOKLUĞU da bir bulgudur.
///
/// Kullanım:
///   dart run tool/measure_punch_signature.dart <fixture.json> <etiket> [...]
void main(List<String> args) {
  if (args.length < 2 || args.length.isOdd) {
    stderr.writeln('usage: measure_punch_signature.dart '
        '<fixture.json> <etiket> [<fixture.json> <etiket> ...]');
    exitCode = 64;
    return;
  }

  final Map<String, dynamic> cfg = (jsonDecode(
              File('../../assets/rulesets/boxing@1.0.0.json').readAsStringSync())
          as Map)
      .cast<String, dynamic>();
  final RuleSet rules = RuleSet.fromJson(cfg);

  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('YUMRUK-TİPİ İMZA ÖLÇÜMÜ (J-073) — betimsel, eşiksiz');
  stdout.writeln('kural seti: ${rules.rulesetId}@${rules.version}');
  stdout.writeln('modellenen teknikler: '
      '${rules.techniques.map((TechniqueConfig t) => t.id).join(" · ")}');
  stdout.writeln('═══════════════════════════════════════════════════════');

  for (int i = 0; i < args.length; i += 2) {
    _measure(args[i], args[i + 1], rules);
  }
}

/// Bir pencere boyunca bir ölçünün gördüğü aralık.
class _Span {
  double lo = double.infinity;
  double hi = double.negativeInfinity;
  int n = 0;

  void add(double v) {
    if (!v.isFinite) return;
    lo = math.min(lo, v);
    hi = math.max(hi, v);
    n++;
  }

  bool get measured => n > 0;
  double get range => measured ? hi - lo : double.nan;
  String get label => measured
      ? '${lo.toStringAsFixed(1)}…${hi.toStringAsFixed(1)} '
          '(Δ${range.toStringAsFixed(1)})'
      : '—';
}

const List<String> _tracked = <String>[
  'lead.elbowFlareAngle',
  'rear.elbowFlareAngle',
  'shoulderRotation',
  'lead.extensionRatio',
  'trunkLeanAngle',
  'lead.guardHeightDelta',
];

/// Ölçü kataloğunda OLMAYAN, landmark'tan türetilen betimleyiciler.
/// Kataloğa EKLENMEDİLER — burada yalnız "ayırt edici bir şey var mı"
/// sorusunu yanıtlamak için hesaplanıyorlar.
const List<String> _derived = <String>[
  'wrist.dxOverShoulder',
  'wrist.dyOverShoulder',
  'wrist.pathOverNet',
];

void _measure(String path, String label, RuleSet rules) {
  final String txt = File(path).readAsStringSync();
  final Map<String, dynamic> raw =
      (jsonDecode(txt) as Map).cast<String, dynamic>();
  final Fixture fixture = Fixture.decode(txt);

  final String? resolution = raw['recordingMeta']?['resolution'] as String?;
  FrameSize? frameSize;
  if (resolution != null) {
    final List<String> wh = resolution.split('x');
    if (wh.length == 2) {
      frameSize = FrameSize(int.parse(wh[0]), int.parse(wh[1]));
    }
  }

  final StrikingEngine engine = StrikingEngine(
    ruleSet: rules,
    calibrationMapped: true,
    frameSize: frameSize,
    provenance: <String, String>{
      'poseModelVariant': fixture.modelVersion,
      'calibrationProfileId': 'signature_probe',
    },
  );

  // Tamamlanmış denemeleri ve HER BİRİNİN penceresindeki ölçü aralıklarını
  // topla. Pencere = ilk faz geçişi → son faz geçişi (segment_punches ile
  // AYNI tanım, yoksa sayılar kıyaslanamaz).
  final Map<String, int> completedBy = <String, int>{};
  final Map<String, int> abortedBy = <String, int>{};
  final List<({String technique, Map<String, _Span> spans, int frames})> shots =
      <({String technique, Map<String, _Span> spans, int frames})>[];

  // Kayan tampon: her karenin ölçüsünü zaman damgasıyla tut, deneme
  // kapandığında pencereye düşenleri geri topla.
  final List<({int tUs, MeasureSet m})> buffer =
      <({int tUs, MeasureSet m})>[];
  int judgeable = 0;
  int frames = 0;

  for (final PoseFrame frame in fixture.frames) {
    final EngineOutput out = engine.process(frame);
    frames++;
    if (out.judgeable) judgeable++;
    final MeasureSet? ms = out.measures;
    if (ms != null) buffer.add((tUs: out.tUs, m: ms));

    final AttemptDigest? d = out.completedAttempt;
    if (d == null) continue;
    final String key = d.techniqueId;
    if (d.outcome == AttemptOutcome.completed) {
      completedBy[key] = (completedBy[key] ?? 0) + 1;
    } else {
      abortedBy[key] = (abortedBy[key] ?? 0) + 1;
      continue;
    }

    // PENCERE = `EXTENSION` → `GUARD_RECOVERED` (J-076 ile SIKILAŞTIRILDI).
    //
    // İlk sürüm `transitions.values.first/last` kullanıyordu, yani
    // GUARD_READY girişinden başlıyordu. `AttemptDigest.extensionMs`in kendi
    // doküman notu (M-F-91) tam bunu uyarıyor: faz makinesi bir sonraki
    // hareketi beklerken GUARD_READY'de dakikalarca kalabilir. Ölçüldü:
    // gevşek pencere jab'de 434-3937 ms (9× yayılım), sıkı pencere
    // 167-501 ms (3× yayılım, medyan 334 ms). Yani ilk turun Δ değerleri
    // yumruğu değil yumruk + gard beklemesini ölçüyordu.
    //
    // `EXTENSION→PEAK` (salt uzanma) BİLEREK kullanılmadı: ölçülen dağılım
    // 33-334 ms ve 29,97 fps'te 33 ms = TEK kare. O pencere örnekleme
    // tabanında, imza ölçümüne yetecek kare vermiyor.
    final int? ext = d.transitions['EXTENSION'];
    final int? end = d.transitions['GUARD_RECOVERED'];
    if (ext == null || end == null || end <= ext) continue;
    final int lo = ext, hi = end;
    final Map<String, _Span> spans = <String, _Span>{
      for (final String k in _tracked) k: _Span(),
    };
    int inWindow = 0;
    for (final ({int tUs, MeasureSet m}) s in buffer) {
      if (s.tUs < lo || s.tUs > hi) continue;
      inWindow++;
      for (final String k in _tracked) {
        final double? v = s.m.read(k);
        if (v != null) spans[k]!.add(v);
      }
    }

    // ---- BİLEK YOLU: mevcut ölçü kataloğunda OLMAYAN, ama landmark'tan
    // türetilebilen betimleyiciler. Sebep: aşağıdaki ölçüm gösterdi ki
    // katalogdaki nicelikler hook ile jab'ı AYIRMIYOR (özellikle
    // shoulderRotation). O yüzden soru şuna dönüyor: landmark'tan
    // ayırt edici BİR ŞEY türetilebilir mi? Bu araç onu YALNIZ BETİMLER —
    // eşik önermez, ölçü kataloğuna alan eklemez.
    //
    // İki betimleyici, ikisi de ölçek-bağımsız (omuz genişliğine bölünmüş):
    //  * yatay/dikey yol oranı — düz yumruk ileri gider (2B önden görünümde
    //    x yer değiştirmesi küçük), kanca YANDAN gelir (x büyük);
    //  * yol kıvrımı (yol uzunluğu / uçtan-uca mesafe) — düz ≈1, kavisli >1.
    final List<Vec3> wristPath = <Vec3>[];
    double shoulderW = double.nan;
    for (final PoseFrame f in fixture.frames) {
      if (f.tUs < lo || f.tUs > hi) continue;
      final PoseFrame fr = frameSize == null ? f : f.toIsotropic(frameSize);
      wristPath.add(fr.point(15)); // sol bilek (orthodox = öncü)
      final Vec3 ls = fr.point(11), rs = fr.point(12);
      final double w = math.sqrt(
          math.pow(ls.x - rs.x, 2) + math.pow(ls.y - rs.y, 2));
      if (w.isFinite && w > 0) shoulderW = w;
    }
    double dx = 0, dy = 0, pathLen = 0, netDist = 0;
    if (wristPath.length >= 2 && shoulderW.isFinite && shoulderW > 0) {
      double xLo = double.infinity, xHi = double.negativeInfinity;
      double yLo = double.infinity, yHi = double.negativeInfinity;
      for (int i = 0; i < wristPath.length; i++) {
        final Vec3 p = wristPath[i];
        xLo = math.min(xLo, p.x);
        xHi = math.max(xHi, p.x);
        yLo = math.min(yLo, p.y);
        yHi = math.max(yHi, p.y);
        if (i > 0) {
          final Vec3 q = wristPath[i - 1];
          pathLen += math.sqrt(
              math.pow(p.x - q.x, 2) + math.pow(p.y - q.y, 2));
        }
      }
      dx = (xHi - xLo) / shoulderW;
      dy = (yHi - yLo) / shoulderW;
      netDist = math.sqrt(
              math.pow(wristPath.last.x - wristPath.first.x, 2) +
                  math.pow(wristPath.last.y - wristPath.first.y, 2)) /
          shoulderW;
      pathLen /= shoulderW;
    }
    spans['wrist.dxOverShoulder'] = _Span()..add(dx);
    spans['wrist.dyOverShoulder'] = _Span()..add(dy);
    spans['wrist.pathOverNet'] =
        _Span()..add(netDist > 0.01 ? pathLen / netDist : double.nan);

    shots.add((technique: key, spans: spans, frames: inWindow));
  }

  stdout.writeln('');
  stdout.writeln('── $label   (${path.split('/').last})');
  stdout.writeln('   kare: $frames · hüküm verilebilir: $judgeable '
      '(${(100 * judgeable / math.max(frames, 1)).toStringAsFixed(1)}%)');
  stdout.writeln('   TAMAMLANMIŞ: ${completedBy.isEmpty ? "yok" : completedBy}');
  stdout.writeln('   YARIDA KESİLEN: ${abortedBy.isEmpty ? "yok" : abortedBy}');

  if (shots.isEmpty) {
    stdout.writeln('   (imza ölçülemedi — tamamlanmış deneme yok)');
    return;
  }

  // Teknik başına ortalama aralık — betimsel özet, eşik DEĞİL.
  final Set<String> techs = shots.map((s) => s.technique).toSet();
  for (final String tech in techs) {
    final List<({String technique, Map<String, _Span> spans, int frames})> g =
        shots.where((s) => s.technique == tech).toList();
    stdout.writeln('   ┌ "$tech" olarak sayılan ${g.length} deneme');
    for (final String k in _tracked) {
      final List<double> ranges = <double>[
        for (final s in g)
          if (s.spans[k]!.measured) s.spans[k]!.range,
      ];
      if (ranges.isEmpty) {
        stdout.writeln('   │ ${k.padRight(22)} —');
        continue;
      }
      ranges.sort();
      final double med = ranges[ranges.length ~/ 2];
      stdout.writeln('   │ ${k.padRight(22)} '
          'Δ medyan ${med.toStringAsFixed(1)}° · '
          'min ${ranges.first.toStringAsFixed(1)} · '
          'maks ${ranges.last.toStringAsFixed(1)}');
    }
    // Katalog-DIŞI bilek yolu betimleyicileri: her deneme için TEK değer
    // (aralık değil), o yüzden medyan/min/maks doğrudan denemeler üzerinden.
    for (final String k in _derived) {
      final List<double> vals = <double>[
        for (final s in g)
          if (s.spans[k]?.measured ?? false) s.spans[k]!.hi,
      ];
      if (vals.isEmpty) {
        stdout.writeln('   │ ${k.padRight(22)} — (ölçülemedi)');
        continue;
      }
      vals.sort();
      stdout.writeln('   │ ${k.padRight(22)} '
          'medyan ${vals[vals.length ~/ 2].toStringAsFixed(2)} · '
          'min ${vals.first.toStringAsFixed(2)} · '
          'maks ${vals.last.toStringAsFixed(2)}');
    }
    stdout.writeln('   └ pencere kare sayısı: '
        '${g.map((s) => s.frames).toList()}');
  }
}
