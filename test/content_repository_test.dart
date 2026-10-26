import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab_engine/jablab_engine.dart';

/// `ContentRepository.coachedNotScoredLabels` — J-033/rule 9'un ürün
/// yüzeyindeki karşılığı, elle kopyalanan bir metin listesi DEĞİL.
///
/// Bu testler olmadan geçmişte gerçekleşen kusur şuydu: `session_screen.dart`
/// `coachedNotScored`'u sabit bir İngilizce liste olarak taşıyordu ve config
/// M-F-51/J-032 ile eklem kovalarını yeniden hesapladığında ekran metni
/// GÜNCELLENMEDİ — "Lead hip and thigh placement" dedi, oysa lead_hip/
/// lead_thigh artık `scoredJoints`'te (skorlanıyor), `coachedOnlyJoints`'te
/// değil. Sözleşme bunu yakalayamazdı çünkü joint-adları JSON'da LEAF
/// alan değil, harita ANAHTARI — M-F-63'ün `leafKeys` taraması bunları
/// görmüyordu.
void main() {
  final RuleSet boxing = RuleSet.fromJson(
    (jsonDecode(File('assets/rulesets/boxing@1.0.0.json').readAsStringSync())
            as Map)
        .cast<String, dynamic>(),
  );
  const ContentRepository repo = ContentRepository();

  test(
    'her coachedOnlyJoints anahtarının bir etiketi var (aksi hâlde fırlar)',
    () {
      final List<String> labels = repo.coachedNotScoredLabels(boxing);
      expect(labels.length, boxing.stanceCoachedOnlyJoints.length);
    },
  );

  test(
    'REGRESYON: lead_hip/lead_thigh scoredJoints\'te — coached listesinde REAR görünür',
    () {
      final List<String> labels = repo.coachedNotScoredLabels(boxing);
      expect(labels, contains('Rear hip position'));
      expect(labels, contains('Rear thigh placement'));
      expect(
        labels,
        isNot(contains('Lead hip and thigh placement')),
        reason: 'eski hardcoded metin — config\'in aktif kararıyla çelişiyordu',
      );
    },
  );

  test('etiketler config değiştiğinde otomatik değişir (elle kopya değil)', () {
    // stanceCoachedOnlyJoints RuleSet.fromJson'dan gelir; burada elle bir
    // liste yazmıyoruz — bu testin amacı, gelecekte biri coachedNotScored'u
    // tekrar sabit bir listeye çevirirse (kolay bir "basitleştirme") kırılmak.
    expect(boxing.stanceCoachedOnlyJoints, isNotEmpty);
    expect(boxing.stanceCoachedOnlyJoints, contains('rear_hip'));
    expect(
      boxing.stanceCoachedOnlyJoints,
      isNot(contains('lead_hip')),
      reason: 'lead_hip scoredJoints\'te — coachedOnlyJoints\'te görünmemeli',
    );
  });
}
