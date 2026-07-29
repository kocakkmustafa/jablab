import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';

/// Kural 7 için BAĞIMSIZ kanıt üreticisi (J-061).
///
/// Kanonik CLI'nin ayna kararı DTW iz karşılaştırmasından gelir ve simetrik
/// malzemede kararsız kalabilir (`mirrorSearchDecisive=false`). JabLab'ın
/// elinde çekirdekte olmayan bir sinyal var: M-F-06 geometrik duruş
/// dedektörü. Bu araç her pencerede baskın duruşu ve güveni ölçer — bir
/// referans havuzunun TEK YÖNLÜ olup olmadığını (yani soyut `lead`/`rear`
/// adlarının anatomik sol/sağa güvenle eşlenip eşlenemeyeceğini) sayıyla
/// söyler.
///
/// Çıktı çekirdeğin bayrağının YERİNE GEÇMEZ — sözleşme kuralı 7 çekirdeğin
/// kendi ölçüsüne atıf yapar. Bu, koordinatör kararına giden bir GİRDİDİR.
///
///   dart run tool/probe_window_stance.dart pencere1.json pencere2.json ...
void main(List<String> args) {
  final Map<String, dynamic> cfg = (jsonDecode(
          File('../../assets/rulesets/boxing@1.0.0.json').readAsStringSync())
      as Map).cast<String, dynamic>();
  final RuleSet rules = RuleSet.fromJson(cfg);

  for (final String srcPath in args) {
    final String txt = File(srcPath).readAsStringSync();
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
        'calibrationProfileId': 'stance_probe',
      },
    );

    final Map<String, int> counts = <String, int>{};
    double confSum = 0;
    int n = 0;
    for (final PoseFrame frame in fixture.frames) {
      final EngineOutput out = engine.process(frame);
      final StanceReading s = out.stance;
      final String k = s.stance.name;
      counts[k] = (counts[k] ?? 0) + 1;
      confSum += s.confidence;
      n++;
    }
    final String dominant = counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    final double share = n == 0 ? 0 : counts[dominant]! / n;
    stdout.writeln('${srcPath.split('/').last}: dominant=$dominant '
        'share=${(share * 100).toStringAsFixed(1)}% '
        'meanConf=${(confSum / n).toStringAsFixed(3)} counts=$counts');
  }
}
