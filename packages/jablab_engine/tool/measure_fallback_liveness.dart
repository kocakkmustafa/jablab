import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';

/// FALLBACK CANLILIK ÖLÇÜMÜ — aile reçetesi Adım 3 (J-083).
///
/// Reçete: `ventures/motion-core/workspace/FALLBACK-CANLILIK-RECETESI.md`
///
/// Reçetenin **üç sayacı BİRLİKTE** okuma kuralını bir alete çeviriyor.
/// Tek sayaca bakmak beni bir kez yanılttı (J-073: fallback 0 + modellenmiş
/// sayaç > 0 gördüm, "yanlış-sınıflama" dedim; abort sayacını ve yoğunluğu
/// atlamıştım). Alet artık üçünü birden basıyor ve teşhisi KENDİSİ
/// söylemiyor — teşhis tablosunu basıp **kararı insana bırakıyor**, çünkü
/// aynı üçlü farklı yoğunluklarda farklı okunur.
///
/// **Yoğunluk normalizasyonu zorunlu:** "6 olay" ile "24,8 dakikada 6 olay"
/// farklı iki cümle. Beklenen yoğunluk KAYNAKTAN gelir (bir kanca dersi
/// onlarca kanca içerir) ve bu alet onu bilemez — o yüzden dakika-başına
/// oranı basar, "az/çok" demez.
///
/// Kullanım:
///   `dart run tool/measure_fallback_liveness.dart fixture.json etiket [...]`
void main(List<String> args) {
  if (args.length < 2 || args.length.isOdd) {
    stderr.writeln('usage: measure_fallback_liveness.dart '
        '<fixture> <etiket> [<fixture> <etiket> ...]');
    exitCode = 64;
    return;
  }

  final RuleSet rules = RuleSet.fromJson(
    (jsonDecode(File('../../assets/rulesets/boxing@1.0.0.json')
                .readAsStringSync()) as Map)
        .cast<String, dynamic>(),
  );

  // Sözlük ve fallback config'den OKUNUR, sabit yazılmaz (reçete Adım 1):
  // kural seti bir gün hook'u modellerse bu alet kendini günceller.
  const String fallbackId = 'unclassified_strike';
  final List<String> modelled = rules.techniques
      .map((TechniqueConfig t) => t.id)
      .where((String id) => id != fallbackId)
      .toList(growable: false);

  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('FALLBACK CANLILIK ÖLÇÜMÜ (reçete Adım 3) — ${rules.rulesetId}'
      '@${rules.version}');
  stdout.writeln('modellenmiş: ${modelled.join(" · ")}');
  stdout.writeln('fallback   : $fallbackId');
  stdout.writeln('═══════════════════════════════════════════════════════');

  for (int i = 0; i < args.length; i += 2) {
    _run(args[i], args[i + 1], rules, fallbackId, modelled);
  }

  stdout.writeln('');
  stdout.writeln('TEŞHİS TABLOSU (karar İNSANA ait — alet teşhis KOYMAZ)');
  stdout.writeln('  fallback>0                → fallback CANLI');
  stdout.writeln('  fallback=0 · modellenmiş yüksek · red~0 → A yanlış-sınıflama');
  stdout.writeln('  fallback=0 · modellenmiş ~0 · red~0     → B görünmezlik');
  stdout.writeln('  fallback=0 · modellenmiş ~0 · red yüksek → red yolu yiyor');
  stdout.writeln('');
  stdout.writeln('⚠️ Bu aletin GÖREMEDİĞİ: hüküm-verilebilirlik düşükse');
  stdout.writeln('   "teknik tanınmıyor" ile "kare yargılanamıyor" AYRIŞMAZ.');
  stdout.writeln('   O yüzden judgeable oranı da basılıyor — birlikte okuyun.');
}

void _run(String path, String label, RuleSet rules, String fallbackId,
    List<String> modelled) {
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
  final double fps =
      (raw['recordingMeta']?['fps'] as num?)?.toDouble() ?? 29.97;

  final StrikingEngine engine = StrikingEngine(
    ruleSet: rules,
    calibrationMapped: true,
    frameSize: frameSize,
    provenance: <String, String>{
      'poseModelVariant': fixture.modelVersion,
      'calibrationProfileId': 'fallback_liveness',
    },
  );

  final Map<String, int> completed = <String, int>{};
  final Map<String, int> aborted = <String, int>{};
  int frames = 0, judgeable = 0;

  for (final PoseFrame f in fixture.frames) {
    final EngineOutput out = engine.process(f);
    frames++;
    if (out.judgeable) judgeable++;
    final AttemptDigest? d = out.completedAttempt;
    if (d == null) continue;
    final Map<String, int> bucket =
        d.outcome == AttemptOutcome.completed ? completed : aborted;
    bucket[d.techniqueId] = (bucket[d.techniqueId] ?? 0) + 1;
  }

  final double minutes = frames / fps / 60.0;
  final int fbC = completed[fallbackId] ?? 0;
  final int fbA = aborted[fallbackId] ?? 0;
  final int modC =
      modelled.fold(0, (int a, String id) => a + (completed[id] ?? 0));
  final int modA =
      modelled.fold(0, (int a, String id) => a + (aborted[id] ?? 0));
  final int allA = aborted.values.fold(0, (int a, int b) => a + b);

  String per(int n) =>
      minutes <= 0 ? '—' : '${(n / minutes).toStringAsFixed(2)}/dk';

  stdout.writeln('');
  stdout.writeln('── $label   (${path.split('/').last})');
  stdout.writeln('   süre ${minutes.toStringAsFixed(1)} dk · kare $frames · '
      'hüküm verilebilir $judgeable '
      '(%${(100 * judgeable / math.max(frames, 1)).toStringAsFixed(1)})');
  stdout.writeln('   ┌ ÜÇ SAYAÇ (yoğunluk normalize)');
  stdout.writeln('   │ fallback TAMAMLANDI  : $fbC  ${per(fbC)}');
  stdout.writeln('   │ modellenmiş TAMAMLANDI: $modC  ${per(modC)}  '
      '${completed.isEmpty ? "" : completed}');
  stdout.writeln('   │ RED (abort, tümü)    : $allA  ${per(allA)}  '
      '${aborted.isEmpty ? "" : aborted}');
  stdout.writeln('   └ (fallback abort $fbA · modellenmiş abort $modA)');

  // İddia DEĞİL, İŞARET. **Teşhis YALNIZ sözlük-DIŞI kaynakta anlamlı:**
  // ilk sürüm bunu ayırmıyordu ve bir JAB dersini de "A adayı
  // (yanlış-sınıflama)" diye etiketliyordu — oysa jab dersinde jab
  // tamamlanması DOĞRU davranıştır. Yanıltıcı bir etiket rapora
  // kopyalanacak en kolay şeydir; o yüzden çağıran taraf kaynağın
  // sözlük-içi mi dışı mı olduğunu `oov:` ön ekiyle BEYAN ETMEK zorunda.
  final bool oov = label.startsWith('oov:');
  if (!oov) {
    stdout.writeln('   → satır: (sözlük-İÇİ kaynak — teşhis UYGULANMAZ; '
        'bu satır POZİTİF KONTROL, taban oranı verir)');
    return;
  }
  final String row;
  if (fbC > 0) {
    row = 'fallback CANLI';
  } else if (modC > 0 && allA == 0) {
    row = 'A adayı (fallback 0 · modellenmiş>0 · red 0)';
  } else if (modC == 0 && allA == 0) {
    row = 'B adayı (hiçbir şey tetiklenmiyor)';
  } else {
    row = 'karışık — tabloya elle bak';
  }
  stdout.writeln('   → satır: $row  ⚠️ POZİTİF KONTROL olmadan okunamaz: '
      'sözlük-İÇİ bir kaynağın kendi oranı bilinmeden '
      '"düşük" denemez');
}
