import 'dart:io';

import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

/// `boxing@1.0.0` → mühürlü v3 şeması çevirisi, çekirdeğin KATI linter'ına
/// karşı doğrulanır.
///
/// Bu testin değeri şu: kendi yorumlayıcım kendi config'imi elbette kabul
/// eder. Şemaya gerçekten uyup uymadığımı ancak **başkasının yazdığı** katı
/// linter söyleyebilir — ve linter, aile boyunca ölçülmüş derslerin
/// (J-009 timeout, J-026 fallback, J-027 cutoffHz, M-F-06 taraf-soyutlaması,
/// M-F-34 baseline) hepsini birden zorluyor.
void main() {
  test('v3 çevirisi ayrıştırılıyor ve linter\'dan TEMİZ geçiyor', () {
    final String src =
        File('../../assets/rulesets/boxing.v3.json').readAsStringSync();

    late final PhaseConfig cfg;
    expect(() => cfg = const PhaseConfigParser().parseJson(src), returnsNormally,
        reason: 'v3 çevirisi ayrıştırılamıyor');

    final List<String> issues = const PhaseConfigValidator().validate(cfg);
    expect(issues, isEmpty,
        reason: 'çekirdek linter ihlal buldu:\n${issues.join("\n")}');
  });

  test('çeviri kaynak config\'in ölçülmüş derslerini TAŞIYOR', () {
    final PhaseConfig cfg = const PhaseConfigParser()
        .parseJson(File('../../assets/rulesets/boxing.v3.json').readAsStringSync());

    // J-026: yedek teknik işaretli mi (aksi hâlde her yumruk iki kez sayılır)
    final TechniqueSpec fallback =
        cfg.techniques.firstWhere((TechniqueSpec t) => t.id == 'unclassified_strike');
    expect(fallback.fallback, isTrue);

    // J-027: hızlı-geçişli metrik filtre kesimini BEYAN etmek zorunda —
    // eşik ve filtre ayrılmaz (1 Hz varsayılan tepeyi %22 söndürüyordu).
    expect(cfg.metrics['extensionRatio']!.cutoffHz, isNotNull);

    // M-F-06: taraf soyut adla; config'te LEFT_*/RIGHT_* yasak.
    for (final TechniqueSpec t in cfg.techniques) {
      expect(t.limb, anyOf(isNull, matches(RegExp(r'^(lead|rear)_'))),
          reason: '${t.id}: taraf soyut adla yazılmalı');
    }
  });
}
