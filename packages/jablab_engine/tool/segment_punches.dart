import 'dart:convert';
import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';

/// M-F-87 deseni: tekrar-sınıfı malzemede (yumruk) en iyi kesici ürünün
/// KENDİ FSM'idir — `hold_isolator`ın duruş/tutuş sınıfı için yaptığının
/// yumruk karşılığı. Ham hasat fixture'ını `StrikingEngine`den geçirir,
/// TAMAMLANMIŞ (`AttemptOutcome.completed`) her denemeyi kendi faz
/// geçişlerinin (GUARD_READY→...→GUARD_RECOVERED) ilk/son µs'ine göre keser
/// ve `windowRule: punch_fsm` provenance'ıyla ayrı fixture'lar yazar.
///
/// Kullanım:
///   dart run tool/segment_punches.dart ham-fixture.json technique-id out-dir [--strict]
///
/// Çıktılar kanonik CLI'ya (`build_reference.dart --technique` ile)
/// beslenmeye hazırdır. M-C-04 (≥3 bağımsız kaynak) gerektiği gibi
/// zorlanır — 2 kaynaktan gelen pencereler isimli-sebepli REDDEDİLİR
/// (bu bir kusur değil, hedefli-hasat ihtiyacının ölçülmüş kanıtıdır).
///
/// `--strict`: pencere GUARD_READY girişinden değil EXTENSION girişinden
/// başlar (M-F-91/J-059 — extensionMs'in GUARD_READY beklemesini kapsadığı
/// beyanının pencereleme karşılığı). Varsayılan (strict OLMAYAN) davranış
/// tüm deneme aralığını (ilk faz→son faz) kapsar; "yavaş gösterim" bir
/// eğitmende bu, uzun bir GUARD_READY bekleyişini pencereye katıp DTW'nin
/// "yumruk" ile "bekleyiş+yumruk"u hizalamasına (L-139 sınıfı sessiz-yanlış)
/// yol açabilir — --strict bunu ayırt etmek için var, "doğru" mod değil.
///
/// M-F-138 (J-065): uygunluk türev pencerede BAYATLAR. Kesici, kaynağın
/// provenance'ını olduğu gibi kopyalarsa uygunluğu KESİM ANINDA snapshot'lar
/// ve kaynak sonradan bloklansa bile eski pencereler kanonik kapıdan geçmeye
/// devam eder — ölçülmüş bir kapı-atlatma yolu (J-064: jab referansı tam bu
/// yüzden bir kez "geçti"). Bu yüzden pencere yazılırken uygunluk KAYNAĞIN
/// GÜNCEL manifestinden tazelenir; kesim anındaki değer `eligibilitySnapshot`
/// altında TARİHÇE olarak durur.
///
/// `--manifests <dizin>`: kaynak manifestlerinin bulunduğu dizin. VERİLMEZSE
/// tazeleme YAPILMAZ ve pencerelere `eligibilityStale: true` damgası
/// basılır — sessizce bayat üretmek yerine bayatlığı İTİRAF etmek, çünkü
/// damgasız bayat pencere ile taze pencere birbirinden ayırt edilemez.
const String _manifestsFlag = '--manifests';

void main(List<String> args) {
  final String srcPath = args[0];
  final String techniqueId = args[1];
  final String outDir = args[2];
  final bool strict = args.contains('--strict');
  final int mfIdx = args.indexOf(_manifestsFlag);
  final String? manifestsDir =
      mfIdx >= 0 && mfIdx + 1 < args.length ? args[mfIdx + 1] : null;

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
    final int? extensionUs = d.transitions['EXTENSION'];
    final int start =
        strict && extensionUs != null ? extensionUs : ts.first;
    found.add((start: start, end: ts.last, digest: d));
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
    Map<String, dynamic> prov =
        Map<String, dynamic>.from((raw['provenance'] as Map?) ?? const {});
    prov = _refreshEligibility(prov, srcPath, manifestsDir);
    prov['windowRule'] = <String, dynamic>{
      'tool': 'jablab_engine/tool/segment_punches.dart',
      'mechanism': 'punch_fsm',
      'windowStart': strict ? 'EXTENSION' : 'firstTransition',
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

/// Uygunluğu kaynağın GÜNCEL manifestinden tazeler (M-F-138).
///
/// Python tarafındaki `tools/harvest_rig/eligibility.py` ile AYNI sözleşme:
/// karar alanları tazelenir, kesim anındaki değerler `eligibilitySnapshot`
/// altına taşınır, fark `eligibilityRefreshed` ile işaretlenir. İki dilde iki
/// uygulama olması hoş değil ama kesiciler iki dilde yaşıyor; sözleşmenin
/// AYNI olması ve ikisinin de testli olması bunu taşınabilir kılıyor.
Map<String, dynamic> _refreshEligibility(
  Map<String, dynamic> prov,
  String srcPath,
  String? manifestsDir,
) {
  const List<String> fields = <String>[
    'referenceEligible',
    'romMode',
    'contextTags',
    'contextSource',
  ];
  final Map<String, dynamic> out = Map<String, dynamic>.from(prov);

  if (manifestsDir == null) {
    // Damgasız bayat pencere, taze pencereden ayırt edilemez. Sessizce
    // üretmek yerine bayatlığı İTİRAF ediyoruz.
    out['eligibilityStale'] = true;
    out[r'$eligibilityStaleWhy'] =
        'Kesim sırasında $_manifestsFlag verilmedi; uygunluk KAYNAKTAN '
        'tazelenmedi ve bu pencerenin taşıdığı değer KESİM ANINA aittir '
        '(M-F-138). Kanonik kapıya sunulmadan önce tazelenmeli.';
    return out;
  }

  final String id =
      srcPath.split('/').last.replaceAll('.full.json', '').replaceAll('.json', '');
  final File mf = File('$manifestsDir/$id.json');
  if (!mf.existsSync()) {
    // FAIL-CLOSED: kaynağı bulamadıysak bayat değerle devam etmek kuralı
    // iptal eder. Pencere üretilmez.
    throw StateError('kaynak manifesti yok: ${mf.path} — uygunluk '
        'tazelenemez, pencere kapıya SUNULMAMALI (M-F-138 fail-closed)');
  }
  final Map<String, dynamic> m =
      (jsonDecode(mf.readAsStringSync()) as Map).cast<String, dynamic>();
  final Map<String, dynamic> fresh = <String, dynamic>{
    'referenceEligible': m['reference_eligible'],
    'romMode': m['rom_mode'],
    'contextTags': m['context_tags'] ?? <dynamic>[],
    'contextSource': m['context_source'],
  };

  final Map<String, dynamic> snapshot = <String, dynamic>{
    for (final String k in fields)
      if (prov.containsKey(k)) k: prov[k],
  };
  bool changed = false;
  for (final String k in fields) {
    final Object? a = prov[k];
    final Object? b = fresh[k];
    // `contextTags`ta YOK ile BOŞ LİSTE aynıdır (gürültü uyarıyı işlevsiz
    // kılar). `referenceEligible`ta YOK ile `false` AYNI DEĞİLDİR: yokluk
    // "henüz sınıflandırılmadı", `false` "BLOKLU" — J-064'ün çekirdeği.
    if (k == 'contextTags') {
      final int an = (a as List<dynamic>?)?.length ?? 0;
      final int bn = (b as List<dynamic>?)?.length ?? 0;
      if (an != bn) changed = true;
      continue;
    }
    if (a != b) changed = true;
  }

  out.addAll(fresh);
  if (snapshot.isNotEmpty) {
    out['eligibilitySnapshot'] = <String, dynamic>{
      ...snapshot,
      r'$doc': 'KESİM ANINDAKİ değerler — yalnız TARİHÇE (M-F-138). Kapı bu '
          'alanları OKUMAZ; karar kaynağın güncel kaydından gelir.',
    };
  }
  out['eligibilityRefreshed'] = changed;
  if (changed) {
    out[r'$eligibilityRefreshedWhy'] =
        'Kaynağın uygunluk kaydı, bu pencere kesildikten SONRA değişti. '
        'Kapıya TAZE değer sunuluyor; kesim anındaki değer '
        'eligibilitySnapshot altında duruyor.';
  }
  return out;
}
