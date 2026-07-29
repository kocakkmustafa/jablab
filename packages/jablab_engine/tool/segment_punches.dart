/// M-F-87 deseni: tekrar-sınıfı malzemede (yumruk) en iyi kesici ürünün
/// KENDİ FSM'idir — `hold_isolator`ın duruş/tutuş sınıfı için yaptığının
/// yumruk karşılığı. Ham hasat fixture'ını `StrikingEngine`den geçirir,
/// TAMAMLANMIŞ (`AttemptOutcome.completed`) her denemeyi kendi faz
/// geçişlerinin (GUARD_READY→...→GUARD_RECOVERED) ilk/son µs'ine göre keser
/// ve `windowRule: punch_fsm` provenance'ıyla ayrı fixture'lar yazar.
///
/// Kullanım:
///   dart run tool/segment_punches.dart <ham-fixture.json> <technique-id> <out-dir>
///
/// Çıktılar kanonik CLI'ya (`build_reference.dart --technique <id>`)
/// beslenmeye hazırdır. M-C-04 (≥3 bağımsız kaynak) gerektiği gibi
/// zorlanır — 2 kaynaktan gelen pencereler isimli-sebepli REDDEDİLİR
/// (bu bir kusur değil, hedefli-hasat ihtiyacının ölçülmüş kanıtıdır).
import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';

void main(List<String> args) {
  final String srcPath = args[0];
  final String techniqueId = args[1];
  final String outDir = args[2];

  final Map<String, dynamic> raw =
      (jsonDecode(File(srcPath).readAsStringSync()) as Map)
          .cast<String, dynamic>();
  final Fixture fixture = Fixture.decode(File(srcPath).readAsStringSync());

  final String? resolution = raw['recordingMeta']?['resolution'] as String?;
  FrameSize? frameSize;
  if (resolution != null) {
    final List<String> wh = resolution.split('x');
    if (wh.length == 2) {
      frameSize = FrameSize(int.parse(wh[0]), int.parse(wh[1]));
    }
  }

  final Map<String, dynamic> cfg = (jsonDecode(File(
              '../../assets/rulesets/boxing@1.0.0.json')
          .readAsStringSync()) as Map)
      .cast<String, dynamic>();
  final RuleSet rules = RuleSet.fromJson(cfg);

  final StrikingEngine engine = StrikingEngine(
    ruleSet: rules,
    calibrationMapped: true,
    frameSize: frameSize,
    provenance: <String, String>{
      'poseModelVariant': fixture.modelVersion,
      'calibrationProfileId': 'punch_fsm_segmenter',
    },
  );

  final List<({int start, int end, AttemptDigest digest})> found =
      <({int start, int end, AttemptDigest digest})>[];
  for (final PoseFrame frame in fixture.frames) {
    final EngineOutput out = engine.process(frame);
    final AttemptDigest? d = out.completedAttempt;
    if (d == null || d.techniqueId != techniqueId) continue;
    if (d.outcome != AttemptOutcome.completed) continue;
    final List<int> ts = d.transitions.values.toList(growable: false);
    if (ts.isEmpty) continue;
    ts.sort();
    found.add((start: ts.first, end: ts.last, digest: d));
  }

  stdout.writeln('${srcPath.split('/').last}: $techniqueId — '
      '${found.length} tamamlanmış deneme bulundu');

  final List<dynamic> rawFrames = raw['frames'] as List<dynamic>;
  Directory(outDir).createSync(recursive: true);
  int i = 0;
  for (final ({int start, int end, AttemptDigest digest}) f in found) {
    i++;
    // Küçük dolgu: FSM sınırı GUARD_READY girişinde başlar, torbaya/hedefe
    // dönüş birkaç kare sürebilir — 150ms dolgu (J-009 EXTENSION_TIMEOUT
    // mertebesinin altında, MAX_EXT_MS 400'ün altında kalır).
    const int padUs = 150000;
    final int startUs = f.start - padUs;
    final int endUs = f.end + padUs;
    final List<dynamic> slice = rawFrames.where((dynamic rf) {
      final num tMs = (rf as Map<String, dynamic>)['t'] as num;
      final int tUs = (tMs * 1000).round();
      return tUs >= startUs && tUs <= endUs;
    }).toList();
    if (slice.isEmpty) continue;

    final Map<String, dynamic> outJson = Map<String, dynamic>.from(raw);
    outJson['frames'] = slice;
    final Map<String, dynamic> prov =
        Map<String, dynamic>.from((raw['provenance'] as Map?) ?? const {});
    prov['windowRule'] = <String, dynamic>{
      'tool': 'jablab_engine/tool/segment_punches.dart',
      'mechanism': 'punch_fsm',
      'rulesetVersion': '${rules.rulesetId}@${rules.version}',
      'technique': techniqueId,
      'transitions': f.digest.transitions,
      'padUs': padUs,
    };
    outJson['provenance'] = prov;
    final String outPath =
        '$outDir/${srcPath.split('/').last.replaceAll('.full.json', '')}'
        '_${techniqueId}_$i.json';
    File(outPath).writeAsStringSync(jsonEncode(outJson));
    stdout.writeln('  -> $outPath (${slice.length} kare, '
        '${f.digest.extensionMs?.toStringAsFixed(0)}ms uzanma, '
        '${f.digest.tempoBand})');
  }
}
