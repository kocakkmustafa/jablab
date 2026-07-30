import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';

/// TEK-YUMRUK PENCERE BANDI — ölçülmüş süre dağılımı (J-076).
///
/// **Bant LİTERATÜRDEN değil, KENDİ fixture'larımızdan türetiliyor**
/// (koordinatör hükmü M-F-184/2). J-074(a)'da "pencereler 0,47-3,97 s ile tek
/// yumruk olamaz" gözlemim bir hipotezdi; bu araç dağılımı ölçüp o hipotezi
/// ya doğrular ya düzeltir.
///
/// ÜÇ pencere tanımı aynı denemeler üzerinde yan yana ölçülüyor:
///
///  1. `GUARD_READY → GUARD_RECOVERED` — **J-073'ün kullandığı GEVŞEK pencere.**
///     `AttemptDigest.extensionMs`in kendi doküman notu (M-F-91) bunun
///     GUARD_READY bekleme süresini kapsadığını ZATEN söylüyor: faz makinesi
///     bir sonraki hareketi beklerken GUARD_READY'de dakikalarca kalabilir.
///  2. `EXTENSION → PEAK` — SALT uzanma. M-F-91'in "gerçek uzanma zamanlaması
///     bundan türetilir" dediği fark.
///  3. `EXTENSION → GUARD_RECOVERED` — uzanma + geri çekilme = **yumruğun
///     kendisi.** İmza ölçümünün doğru penceresi bu aday.
///
/// Çıktı bir EŞİK DEĞİL, bir DAĞILIM: teknik başına p10/medyan/p90 + min/maks.
/// Bandı bu dağılımdan okumak insanın (koordinatörün) işi.
///
/// Kullanım:
///   dart run tool/measure_window_band.dart <fixture.json> <etiket> [...]
void main(List<String> args) {
  if (args.length < 2 || args.length.isOdd) {
    stderr.writeln('usage: measure_window_band.dart '
        '<fixture.json> <etiket> [<fixture.json> <etiket> ...]');
    exitCode = 64;
    return;
  }

  final RuleSet rules = RuleSet.fromJson(
    (jsonDecode(File('../../assets/rulesets/boxing@1.0.0.json')
                .readAsStringSync()) as Map)
        .cast<String, dynamic>(),
  );

  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('TEK-YUMRUK PENCERE BANDI — ölçülmüş dağılım (J-076)');
  stdout.writeln('kural seti: ${rules.rulesetId}@${rules.version}');
  stdout.writeln('bant literatürden DEĞİL, bu fixture\'lardan türetiliyor');
  stdout.writeln('═══════════════════════════════════════════════════════');

  // Tüm fixture'ların denemeleri TEK havuzda toplanıyor: bant tek bir
  // eğitmenin alışkanlığından değil, elimizdeki tüm malzemeden okunmalı.
  final Map<String, List<_Attempt>> pool = <String, List<_Attempt>>{};

  for (int i = 0; i < args.length; i += 2) {
    final List<_Attempt> found = _collect(args[i], args[i + 1], rules);
    stdout.writeln('');
    stdout.writeln('── ${args[i + 1]}   (${args[i].split('/').last})');
    if (found.isEmpty) {
      stdout.writeln('   tamamlanmış deneme YOK');
      continue;
    }
    final Map<String, int> byTech = <String, int>{};
    for (final _Attempt a in found) {
      byTech[a.technique] = (byTech[a.technique] ?? 0) + 1;
      pool.putIfAbsent(a.technique, () => <_Attempt>[]).add(a);
    }
    stdout.writeln('   tamamlanmış: $byTech');
    for (final _Attempt a in found) {
      stdout.writeln('   · t=${(a.startUs / 1e6).toStringAsFixed(1)}s '
          '${a.technique.padRight(6)} '
          'gevşek ${_ms(a.looseUs).padLeft(8)} · '
          'ext→peak ${_ms(a.extToPeakUs).padLeft(8)} · '
          'ext→gard ${_ms(a.extToEndUs).padLeft(8)}');
    }
  }

  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('HAVUZ DAĞILIMI — teknik başına (ms)');
  stdout.writeln('═══════════════════════════════════════════════════════');
  for (final String tech in pool.keys.toList()..sort()) {
    final List<_Attempt> g = pool[tech]!;
    stdout.writeln('');
    stdout.writeln('▸ $tech — ${g.length} tamamlanmış deneme');
    _band('1 GUARD_READY→GUARD_RECOVERED (J-073 gevşek)',
        g.map((_Attempt a) => a.looseUs).toList());
    _band('2 EXTENSION→PEAK (salt uzanma)',
        g.map((_Attempt a) => a.extToPeakUs).toList());
    _band('3 EXTENSION→GUARD_RECOVERED (yumruğun kendisi)',
        g.map((_Attempt a) => a.extToEndUs).toList());
  }
}

/// Bir pencere tanımının dağılımını yazar. Yüzdelikler NEAREST-RANK —
/// n küçükken (burada 3-14) interpolasyon uydurma hassasiyet üretir.
void _band(String label, List<int?> raw) {
  final List<int> v = <int>[
    for (final int? x in raw)
      if (x != null) x,
  ]..sort();
  if (v.isEmpty) {
    stdout.writeln('  ${label.padRight(46)} — ölçülemedi');
    return;
  }
  int pct(double p) => v[math.min(v.length - 1, (p * v.length).floor())];
  stdout.writeln('  ${label.padRight(46)} '
      'n=${v.length.toString().padLeft(2)} · '
      'p10 ${_ms(pct(0.10)).padLeft(7)} · '
      'medyan ${_ms(pct(0.50)).padLeft(7)} · '
      'p90 ${_ms(pct(0.90)).padLeft(7)} · '
      '[${_ms(v.first)} … ${_ms(v.last)}]');
}

String _ms(int? us) =>
    us == null ? '—' : '${(us / 1000).toStringAsFixed(0)}ms';

class _Attempt {
  _Attempt({
    required this.technique,
    required this.startUs,
    required this.looseUs,
    required this.extToPeakUs,
    required this.extToEndUs,
  });

  final String technique;

  /// Denemenin videodaki yeri — "bu tamamlanma nerede oldu" sorusu için.
  final int startUs;

  /// İlk faz girişi → son faz girişi. GUARD_READY beklemesini KAPSAR (M-F-91).
  final int? looseUs;
  final int? extToPeakUs;
  final int? extToEndUs;
}

List<_Attempt> _collect(String path, String label, RuleSet rules) {
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
      'calibrationProfileId': 'window_band_probe',
    },
  );

  final List<_Attempt> out = <_Attempt>[];
  for (final PoseFrame frame in fixture.frames) {
    final AttemptDigest? d = engine.process(frame).completedAttempt;
    if (d == null || d.outcome != AttemptOutcome.completed) continue;

    final Map<String, int> tr = d.transitions;
    final List<int> all = tr.values.toList(growable: false)..sort();
    final int? ext = tr['EXTENSION'];
    final int? peak = tr['PEAK'];
    final int? end = tr['GUARD_RECOVERED'];

    out.add(_Attempt(
      technique: d.techniqueId,
      startUs: all.isEmpty ? 0 : all.first,
      looseUs: all.isEmpty ? null : all.last - all.first,
      extToPeakUs: (ext != null && peak != null) ? peak - ext : null,
      // GUARD_RECOVERED yoksa son geçişe düş — ama SESSİZCE değil: aşağıdaki
      // dağılımda bu iki hâl karışırsa bant kirlenir, o yüzden yalnız
      // GUARD_RECOVERED varken ölçüyoruz.
      extToEndUs: (ext != null && end != null) ? end - ext : null,
    ));
  }
  return out;
}
