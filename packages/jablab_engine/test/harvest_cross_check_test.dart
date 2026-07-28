import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

/// Python hasat hattı ↔ Dart motoru çapraz doğrulaması.
///
/// ADR-002'nin altın-fixture ilkesinin küçük ölçekli uygulaması: **aynı-kare
/// oranı matematiği iki hatta da aynı sayıyı vermeli.** Vermezse biri yanlış
/// ve hangisi olduğu belli değildir — bu yüzden uyuşmazlık hata sayılır.
///
/// Veri gerçek hasattan: Precision Striking jab dersi, MediaPipe `full`,
/// şema v2 (13.182/13.332 kare tespitli), 59 kare örneklendi.
void main() {
  final Map<String, dynamic> golden =
      (jsonDecode(File('test/golden/harvest_cross_check.json').readAsStringSync())
              as Map)
          .cast<String, dynamic>();

  // Şema sürümü kontrolü — M-J-03 dersi: beklemediği sürümde okuyucu
  // sessizce boş dönmemeli, PATLAMALI.
  test('golden şema sürümü beklenen', () {
    expect(golden['schemaVersion'], 2);
  });

  final List<int> wh = (golden['resolution'] as String)
      .split('x')
      .map(int.parse)
      .toList(growable: false);
  final List<dynamic> frames = golden['frames'] as List<dynamic>;
  final List<dynamic> expected = golden['expected'] as List<dynamic>;

  PoseFrame toFrame(Map<String, dynamic> f) {
    final List<dynamic> lm = f['lm'] as List<dynamic>;
    return PoseFrame(
      tUs: ((f['t'] as num) * 1000).round(),
      modelVersion: 'harvest-v2',
      landmarks: List<PoseLandmark>.generate(
        lm.length,
        (int i) {
          final List<dynamic> p = lm[i] as List<dynamic>;
          return PoseLandmark((p[0] as num).toDouble(), (p[1] as num).toDouble(),
              (p[2] as num).toDouble(), (p[3] as num).toDouble());
        },
        growable: false,
      ),
    );
  }

  test('gerçek hasat verisinde Dart ölçüleri Python hattıyla UYUŞUR', () {
    const MeasureCalculator calc = MeasureCalculator();
    final List<String> mismatches = <String>[];

    for (int i = 0; i < frames.length; i++) {
      final PoseFrame frame = toFrame((frames[i] as Map).cast<String, dynamic>());
      // Orthodox: lead = sol. Golden left/right ile yazıldığı için duruşu
      // sabitliyoruz; sınanan şey ölçü matematiği, duruş tespiti değil.
      final MeasureSet m = calc.compute(frame, Stance.orthodox,
          frameSize: FrameSize(wh[0], wh[1]));
      final Map<String, dynamic> exp =
          (expected[i] as Map).cast<String, dynamic>();

      void check(String goldenKey, double? got) {
        final double want = (exp[goldenKey] as num).toDouble();
        if (got == null || (got - want).abs() > 1e-6) {
          mismatches.add('kare $i · $goldenKey: python=${want.toStringAsFixed(6)} '
              'dart=${got?.toStringAsFixed(6) ?? "null"}');
        }
      }

      check('left.extensionRatio', m.read('extensionRatio', limb: Side.lead));
      check('right.extensionRatio', m.read('extensionRatio', limb: Side.rear));
      check('stanceWidthRatio', m.read('stanceWidthRatio'));
    }

    expect(mismatches, isEmpty,
        reason: 'iki hat farklı sayı üretiyor — biri yanlış:\n'
            '${mismatches.take(8).join("\n")}'
            '${mismatches.length > 8 ? "\n… (+${mismatches.length - 8})" : ""}');
  });
}
