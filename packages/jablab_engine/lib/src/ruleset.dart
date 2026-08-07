import 'measures.dart';

/// Kural setinin koşul DSL'i için değerlendirme bağlamı.
///
/// Ölçüler [MeasureSet]'ten gelir; faz süresi, kare kalitesi, dizi uyumu gibi
/// **motorun bildiği** büyüklükleri motor sağlar. Bu ayrım, config'in motor
/// içine mantık sızdırmasını engeller: config yalnız *hangi büyüklük hangi
/// eşikte* der, o büyüklüğün nasıl hesaplandığını bilmez.
abstract interface class EvalContext {
  MeasureSet get measures;
  Side get limb;

  /// `phaseDurationMs.RETRACTION` gibi anahtarlar için.
  double? phaseDurationMs(String phaseId);

  /// 0-1; ConfidenceGate'in kare kalitesi.
  double get frameQuality;

  bool get requiredRegionOutOfFrame;

  /// Kombinasyon motorundan: 'limb' | 'order' | null.
  String? get sequenceMismatch;

  /// ADR-001 tempo bandı: 'controlled' | 'brisk' | 'fast'.
  String? get tempoBand;

  /// Son pencerede hata oranı (TEMPO_TOO_FAST_FOR_FORM için).
  double get errorRateInWindow;
}

/// Tek bir `{"anahtar": kısıt}` çifti.
final class Clause {
  const Clause(this.key, this.spec);

  final String key;
  final Object spec;

  bool test(EvalContext ctx) {
    // Boolean/dizgi literalleri
    if (spec is bool) return _readBool(ctx, key) == spec;
    if (spec is String) return _readString(ctx, key) == spec;

    final Map<String, dynamic> m = (spec as Map).cast<String, dynamic>();
    final double? value = _readNumber(ctx, key);
    if (value == null) return false;

    for (final MapEntry<String, dynamic> e in m.entries) {
      switch (e.key) {
        case 'gt':
          if (!(value > (e.value as num).toDouble())) return false;
        case 'lt':
          if (!(value < (e.value as num).toDouble())) return false;
        case 'gte':
          if (!(value >= (e.value as num).toDouble())) return false;
        case 'lte':
          if (!(value <= (e.value as num).toDouble())) return false;
        case 'outsideBy':
          if (!(value > (e.value as num).toDouble())) return false;
        case 'localMax':
          // Gerçek yerel maksimum sonraki kareyi ister; canlı akışta o kare
          // henüz yok. Çalışma zamanı vekili: değişim işaret değiştirdi mi
          // (artıyordu → artık artmıyor). Ölçüm hattındaki parabolik tepe
          // tahmini bunun offline karşılığıdır.
          if (e.value == true) {
            final double? d = ctx.measures.read('${key}Delta', limb: ctx.limb);
            if (d == null || d > 0) return false;
          }
        default:
          return false; // bilinmeyen operatör → koşul sağlanmaz (fail-closed)
      }
    }
    return true;
  }

  double? _readNumber(EvalContext ctx, String k) {
    if (k.startsWith('phaseDurationMs.')) {
      return ctx.phaseDurationMs(k.substring('phaseDurationMs.'.length));
    }
    if (k == 'frameQuality') return ctx.frameQuality;
    if (k == 'errorRateInWindow') return ctx.errorRateInWindow;
    if (k.startsWith('lead.') || k.startsWith('rear.')) {
      return ctx.measures.read(k);
    }
    return ctx.measures.read(k, limb: ctx.limb);
  }

  bool? _readBool(EvalContext ctx, String k) => switch (k) {
        'feetCrossed' => ctx.measures.feetCrossed,
        'requiredRegionOutOfFrame' => ctx.requiredRegionOutOfFrame,
        _ => null,
      };

  String? _readString(EvalContext ctx, String k) => switch (k) {
        'sequenceMismatch' => ctx.sequenceMismatch,
        'tempoBand' => ctx.tempoBand,
        _ => null,
      };
}

/// AND'lenmiş cümleler.
final class Condition {
  const Condition(this.clauses);

  factory Condition.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Condition(<Clause>[]);
    final List<Clause> out = <Clause>[];
    for (final MapEntry<String, dynamic> e in json.entries) {
      if (e.key.startsWith(r'$')) continue; // $doc/$note yorum alanları
      out.add(Clause(e.key, e.value as Object));
    }
    return Condition(out);
  }

  final List<Clause> clauses;

  bool get isEmpty => clauses.isEmpty;

  bool test(EvalContext ctx) {
    if (clauses.isEmpty) return false;
    for (final Clause c in clauses) {
      if (!c.test(ctx)) return false;
    }
    return true;
  }
}

final class TechniquePhase {
  const TechniquePhase({
    required this.id,
    required this.enter,
    this.timeoutMs,
    this.terminal = false,
    this.requiredLandmarks = const <String>[],
  });

  factory TechniquePhase.fromJson(Map<String, dynamic> j) => TechniquePhase(
        id: j['id'] as String,
        enter: Condition.fromJson((j['enter'] as Map?)?.cast<String, dynamic>()),
        timeoutMs: (j['timeoutMs'] as num?)?.toInt(),
        terminal: j['terminal'] as bool? ?? false,
        requiredLandmarks:
            ((j['requiredLandmarks'] as List?) ?? const <dynamic>[])
                .cast<String>(),
      );

  final String id;
  final Condition enter;
  final int? timeoutMs;
  final bool terminal;
  final List<String> requiredLandmarks;
}

final class TechniqueConfig {
  const TechniqueConfig({
    required this.id,
    required this.limb,
    required this.phases,
    this.displayKey,
    this.number,
    this.band = 'A',
    this.emitsErrors = true,
    this.isFallback = false,
    this.abortOnRetreat,
    this.trackingLostMs = 500,
    this.abortIfPeakNeverReached = true,
  });

  factory TechniqueConfig.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> abort =
        ((j['abort'] as Map?) ?? const <String, dynamic>{}).cast<String, dynamic>();
    return TechniqueConfig(
      id: j['id'] as String,
      limb: (j['limb'] as String?) == 'rear_arm' ? Side.rear : Side.lead,
      phases: ((j['phases'] as List?) ?? const <dynamic>[])
          .map((dynamic p) => TechniquePhase.fromJson((p as Map).cast<String, dynamic>()))
          .toList(growable: false),
      displayKey: j['displayKey'] as String?,
      number: (j['number'] as num?)?.toInt(),
      band: j['band'] as String? ?? 'A',
      emitsErrors: j['emitsErrors'] as bool? ?? true,
      isFallback: j['fallback'] as bool? ?? false,
      abortOnRetreat: j['abortOnRetreat'] == null
          ? null
          : AbortOnRetreat.fromJson(
              (j['abortOnRetreat'] as Map).cast<String, dynamic>()),
      trackingLostMs: (abort['trackingLostMs'] as num?)?.toInt() ?? 500,
      abortIfPeakNeverReached: abort['peakNeverReached'] as bool? ?? true,
    );
  }

  final String id;
  final Side limb;
  final List<TechniquePhase> phases;
  final String? displayKey;
  final int? number;
  final String band;
  final bool emitsErrors;

  /// J-026: bu teknik yalnız SPESİFİK bir teknik eşleşmediğinde sayılır.
  /// Bir jab aynı zamanda "sınıflandırılmamış vuruş"tur; bayrak olmadan her
  /// yumruk iki kez sayılır.
  final bool isFallback;

  /// Girişim-kapatma sözleşmesi (M-F-60). Yoksa teknik erken kapanmaz.
  final AbortOnRetreat? abortOnRetreat;

  final int trackingLostMs;
  final bool abortIfPeakNeverReached;
}

final class ErrorConfig {
  const ErrorConfig({
    required this.code,
    required this.band,
    required this.severity,
    required this.evaluateAt,
    required this.condition,
    required this.feedbackKey,
    this.drillId,
    this.minConfidence = 0.6,
    this.cooldownMs = 8000,
    this.maxPerRound = 3,
    this.suppressesJudgement = false,
  });

  factory ErrorConfig.fromJson(Map<String, dynamic> j) => ErrorConfig(
        code: j['code'] as String,
        band: j['band'] as String? ?? 'A',
        severity: j['severity'] as String? ?? 'medium',
        evaluateAt: ((j['evaluateAt'] as List?) ?? const <dynamic>[]).cast<String>(),
        condition:
            Condition.fromJson((j['condition'] as Map?)?.cast<String, dynamic>()),
        feedbackKey: j['feedbackKey'] as String? ?? j['code'] as String,
        drillId: j['drillId'] as String?,
        minConfidence: (j['minConfidence'] as num?)?.toDouble() ?? 0.6,
        cooldownMs: (j['cooldownMs'] as num?)?.toInt() ?? 8000,
        maxPerRound: (j['maxPerRound'] as num?)?.toInt() ?? 3,
        suppressesJudgement: j['suppressesJudgement'] as bool? ?? false,
      );

  final String code;
  final String band;
  final String severity;
  final List<String> evaluateAt;
  final Condition condition;
  final String feedbackKey;
  final String? drillId;
  final double minConfidence;
  final int cooldownMs;
  final int maxPerRound;
  final bool suppressesJudgement;
}

final class CombinationConfig {
  const CombinationConfig({
    required this.id,
    required this.sequence,
    this.maxGapMs = 900,
  });

  factory CombinationConfig.fromJson(Map<String, dynamic> j) => CombinationConfig(
        id: j['id'] as String,
        sequence: ((j['sequence'] as List?) ?? const <dynamic>[]).cast<String>(),
        maxGapMs: (j['maxGapMs'] as num?)?.toInt() ?? 900,
      );

  final String id;
  final List<String> sequence;
  final int maxGapMs;
}

/// Bir branşın tüm kural paketi (`boxing@1.x.json`).
/// Motorun İZLEDİĞİ bir bileşen — ve puanlanıp puanlanmadığı.
///
/// Ad bilerek `trackedComponents`: eski adı `scoreComponents` idi ve YANLIŞTI.
/// Kanıtı kendi içindeydi — `trackingConfidence` listedeydi ve o **asla**
/// puanlanmaz (koordinatör hükmü 2026-08-07, J-144).
///
/// Liste ayrıca ÖLÜYDÜ (bu parser onu okumuyordu) ve ölü olması bir çelişkiyi
/// GİZLEDİ: iki ekran kendi bant üçlüsünü ELLE yazdı, biri kaynakta hiç
/// olmayan bir öğe icat etti, öteki puanlanmayacak bir bileşeni
/// *"kalibrasyon gelene kadar"* başlığının altına koydu — **karşılıksız bir
/// vaat**, çünkü o bileşen kalibrasyonla değil eğitmen uzlaşmazlığıyla
/// kapalı.
final class TrackedComponent {
  const TrackedComponent({
    required this.id,
    required this.displayName,
    required this.graded,
    this.gradedWhyNot,
    this.surfacedKeyword,
  });

  factory TrackedComponent.fromJson(Map<String, dynamic> j) {
    final bool graded = j['graded'] as bool? ?? false;
    final String? why = j['gradedWhyNot'] as String?;
    // Puanlanmayan bir bileşen SEBEPSİZ kalamaz. Sebepsiz "puanlanmıyor",
    // kullanıcıya *"bir gün belki"* diye okunur ve bu ürünün tamamı o
    // okumaya karşı yazıldı.
    if (!graded && (why == null || why.trim().isEmpty)) {
      throw StateError(
          '${j['id']}: graded=false ama gerekçe YOK — sebepsiz bir sınır, '
          'gizli bir vaattir');
    }
    return TrackedComponent(
      id: j['id'] as String,
      displayName: j['displayName'] as String,
      graded: graded,
      gradedWhyNot: why,
      surfacedKeyword: j['surfacedKeyword'] as String?,
    );
  }

  final String id;
  final String displayName;

  /// Bu bileşen bir HÜKÜM üretiyor mu. `false` ise izleniyor ama
  /// puanlanmıyor — ve [gradedWhyNot] neden olduğunu söylüyor.
  final bool graded;

  /// `graded == false` iken ZORUNLU gerekçe.
  ///
  /// ## ⚠️ BUGÜN HİÇBİR YÜZEY BUNU ÇİZMİYOR — ve bu isimli bir borç (J-147)
  ///
  /// Alanı yazdıktan bir saat sonra ölçtüm: `gradedWhyNot`ı **yalnız
  /// testler okuyor.** Yani J-129'un tam sınıfını (*içerik var, yüzeyi
  /// yok*) onu isimlendirdikten kısa süre sonra kendim ürettim.
  ///
  /// Ölçüm sonucu bunu **ikiye ayırıyor**:
  ///
  /// * **5 gerekçe canlı yüzeyde ZATEN söyleniyor** — dürüstlük kutusu
  ///   (`honesty.measured`/`notMeasured`) ve kilitli ders gerekçeleri.
  ///   Onlar için bu alan **iç gerekçe**: aynı sınırın makine-okur hâli,
  ///   yeni bir iddia değil.
  /// * **2'si (`punchMechanics`, `recovery`) hiçbir yüzeyde YOK.** Onları
  ///   yüzeye taşımak bir IA kararı ve koordinatöre soruldu.
  ///
  /// Ve alanın kendisi bir kusur yakaladı: `punchMechanics`in ilk
  /// gerekçesini **uydurmuştum** (*"no reference set"* — oysa
  /// `references.jab` var, 3 bağımsız kaynak). Doğrusu kural setinin kendi
  /// `$splitRule`unda yazılıydı: **öncü kol, eğitmenlerin en çok ayrıştığı
  /// yer.** Yani gerekçeyi yazmak zorunda olmak, yanlış gerekçeyi de
  /// görünür kıldı.
  final String? gradedWhyNot;

  /// Bu sınırın KULLANICI-YÜZÜ olduğunu beyan eder ve dürüstlük kutusundaki
  /// maddeyi bulmaya yarayan anahtar sözcüğü taşır (J-149).
  ///
  /// Ölçüt **beklenti**: kullanıcı bu bileşenin puanlandığını varsayar mı?
  /// Ürün onu sayıyor/gösteriyorsa evet — o zaman sınır beyan edilmeli.
  /// `null` ise bileşen **iç gerekçe** sınıfındadır: sessiz değil, sınıfı
  /// yazılı. Her sınırı her yerde söylemek de gürültüdür.
  final String? surfacedKeyword;
}

final class RuleSet {
  const RuleSet({
    required this.rulesetId,
    required this.version,
    required this.techniques,
    required this.errors,
    required this.combinations,
    required this.tempoBands,
    required this.calibrationPending,
    required this.numericScoresUnlocked,
    required this.thresholdStatus,
    required this.maxExtensionRatio,
    required this.smoothingMinCutoff,
    required this.smoothingBeta,
    required this.smoothingDerivativeCutoff,
    required this.stanceCoachedOnlyJoints,
    required this.jabCoachedOnlyJoints,
    required this.jabScoredJoints,
    required this.trackedComponents,
  });

  factory RuleSet.fromJson(Map<String, dynamic> j) {
    final List<TrackedComponent> tracked =
        ((j['trackedComponents'] as List?) ?? const <dynamic>[])
            .map((dynamic c) =>
                TrackedComponent.fromJson((c as Map).cast<String, dynamic>()))
            .toList(growable: false);
    final Map<String, dynamic> integrity =
        ((j['integrity'] as Map?) ?? const <String, dynamic>{}).cast<String, dynamic>();
    final Map<String, dynamic> display =
        ((j['display'] as Map?) ?? const <String, dynamic>{}).cast<String, dynamic>();
    final Map<String, dynamic> bands =
        ((j['tempoBands'] as Map?) ?? const <String, dynamic>{}).cast<String, dynamic>();
    final Map<String, dynamic> sc =
        ((j['signalConditioning'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>();
    final Map<String, dynamic> references =
        ((j['references'] as Map?) ?? const <String, dynamic>{}).cast<String, dynamic>();
    final Map<String, dynamic> stanceRef =
        ((references['stance'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>();
    final Map<String, dynamic> stanceCoached =
        ((stanceRef['coachedOnlyJoints'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>();
    final Map<String, dynamic> jabRef =
        ((references['jab'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>();
    final Map<String, dynamic> jabCoached =
        ((jabRef['coachedOnlyJoints'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>();
    final Map<String, dynamic> jabScored =
        ((jabRef['scoredJoints'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>();

    final Map<String, ({double? minMs, double? maxMs})> tempo =
        <String, ({double? minMs, double? maxMs})>{};
    for (final MapEntry<String, dynamic> e in bands.entries) {
      if (e.key.startsWith(r'$')) continue;
      final Map<String, dynamic> b = (e.value as Map).cast<String, dynamic>();
      tempo[e.key] = (
        minMs: (b['extensionMsMin'] as num?)?.toDouble(),
        maxMs: (b['extensionMsMax'] as num?)?.toDouble(),
      );
    }

    return RuleSet(
      trackedComponents: tracked,
      rulesetId: j['rulesetId'] as String,
      version: j['version'] as String,
      techniques: ((j['techniques'] as List?) ?? const <dynamic>[])
          .map((dynamic t) =>
              TechniqueConfig.fromJson((t as Map).cast<String, dynamic>()))
          .toList(growable: false),
      errors: ((j['errors'] as List?) ?? const <dynamic>[])
          .map((dynamic e) => ErrorConfig.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
      combinations: ((j['combinations'] as List?) ?? const <dynamic>[])
          .map((dynamic c) =>
              CombinationConfig.fromJson((c as Map).cast<String, dynamic>()))
          .toList(growable: false),
      tempoBands: tempo,
      calibrationPending: j['calibrationPending'] as bool? ?? true,
      numericScoresUnlocked: display['numericScoresUnlocked'] as bool? ?? false,
      thresholdStatus: j['thresholdStatus'] as String? ?? 'unknown',
      maxExtensionRatio:
          (integrity['maxExtensionRatio'] as num?)?.toDouble() ?? 1.05,
      smoothingMinCutoff: (sc['minCutoff'] as num?)?.toDouble() ?? 8.0,
      smoothingBeta: (sc['beta'] as num?)?.toDouble() ?? 0.05,
      smoothingDerivativeCutoff:
          (sc['derivativeCutoff'] as num?)?.toDouble() ?? 1.0,
      stanceCoachedOnlyJoints:
          stanceCoached.keys.toList(growable: false)..sort(),
      jabCoachedOnlyJoints: jabCoached.keys.toList(growable: false)..sort(),
      jabScoredJoints: jabScored.keys.toList(growable: false)..sort(),
    );
  }

  /// Motorun izlediği bileşenler ve her birinin HÜKÜM üretip üretmediği.
  /// Bant listeleri BURADAN türer — elle yazılmaz (J-144).
  final List<TrackedComponent> trackedComponents;

  /// Puanlanan bileşenler — ekranda bant olarak görünenler.
  List<TrackedComponent> get gradedComponents =>
      trackedComponents.where((TrackedComponent c) => c.graded).toList();

  final String rulesetId;
  final String version;
  final List<TechniqueConfig> techniques;
  final List<ErrorConfig> errors;
  final List<CombinationConfig> combinations;
  final Map<String, ({double? minMs, double? maxMs})> tempoBands;

  final bool calibrationPending;

  /// K8 aile kuralı (M-F-04): false iken kullanıcıya SAYISAL skor gösterilmez.
  final bool numericScoresUnlocked;

  /// M-F-17c: 'raw-signal-pending-revision' iken A bandı yayınlanmaz.
  final String thresholdStatus;

  /// M-019/J-013: anatomik imkânsızlık sınırı — aşılırsa hüküm YOK.
  final double maxExtensionRatio;

  /// Yumuşatma filtresi eşiklerin **ayrılmaz parçasıdır** (M-C-07 / J-016):
  /// eşik ve filtre ayrı ayrı değiştirilemez. Ölçüldü — 1 Hz varsayılan kesim
  /// 120 ms'lik yumruğun tepesini %22 sönümlüyor ve PEAK hiç ateşlenmiyor.
  final double smoothingMinCutoff;
  final double smoothingBeta;
  final double smoothingDerivativeCutoff;

  /// `references.stance.coachedOnlyJoints` anahtarları — eğitmenlerin
  /// anlaşmadığı, bu yüzden koçlanan ama SKORLANMAYAN eklemler (M-F-41).
  /// Ürün yüzeyinin bu listeyi kopyalamak yerine buradan okuması, kova
  /// kararı değişince (ör. M-F-51 yeniden hesabı) metnin sessizce
  /// bayatlamasını engeller.
  final List<String> stanceCoachedOnlyJoints;

  /// `references.jab.coachedOnlyJoints` anahtarları (J-061). Jab'da HİÇBİR kol
  /// eklemi skorlanmaz: öncü kol, eğitmenlerin en çok ayrıştığı yerdir
  /// (lead_forearm 51,5° p90) — yani tekniğin kendisi ölçülebilir ama
  /// yargılanamaz. Ürün yüzeyi bu listeyi kopyalamaz, buradan okur (J-047).
  final List<String> jabCoachedOnlyJoints;

  /// `references.jab.scoredJoints` anahtarları — jab sırasında hüküm
  /// verilebilen eklemler (taban + gövde).
  final List<String> jabScoredJoints;

  TechniqueConfig? technique(String id) {
    for (final TechniqueConfig t in techniques) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// ADR-001: tempo SAYI değil BANT.
  String tempoBandFor(double extensionMs) {
    for (final MapEntry<String, ({double? minMs, double? maxMs})> e
        in tempoBands.entries) {
      final double lo = e.value.minMs ?? double.negativeInfinity;
      final double hi = e.value.maxMs ?? double.infinity;
      if (extensionMs >= lo && extensionMs < hi) return e.key;
    }
    return 'unknown';
  }

  /// Yayına hazırlık denetimi — kalibrasyon/eşik durumu A bandını kapatıyor mu?
  List<String> publishBlockers() {
    final List<String> out = <String>[];
    if (calibrationPending) out.add('calibrationPending');
    if (thresholdStatus != 'calibrated') out.add('thresholdStatus=$thresholdStatus');
    return out;
  }
}


/// PEAK'e ulaşmadan geri çekilme → girişim kapanır (M-F-60).
///
/// **Sayımı değiştirmez.** Dış sınır (PEAK eşiği) yerinde durur ve yedek
/// teknik de bu hareket için bastırılmış kalır — yarım hareket yumruk
/// sayılmaz. Değişen tek şey sessizlik: "ulaşmadı" bir teknik hükmü değil,
/// koçlanan katmandan gelen bir gözlemdir.
final class AbortOnRetreat {
  const AbortOnRetreat({
    required this.beforePhase,
    required this.side,
    required this.hysteresis,
    required this.minPeakExtension,
    required this.feedbackKey,
  });

  factory AbortOnRetreat.fromJson(Map<String, dynamic> j) => AbortOnRetreat(
        beforePhase: j['beforePhase'] as String,
        side: j['side'] as String,
        hysteresis: (j['hysteresis'] as num).toDouble(),
        minPeakExtension: (j['minPeakExtension'] as num).toDouble(),
        feedbackKey: j['feedbackKey'] as String,
      );

  /// Bu faza ULAŞILMADAN geri çekilme olursa girişim kapanır.
  final String beforePhase;

  /// Hangi kolun uzanması izlenir ('lead' | 'rear').
  final String side;

  /// Tepe değerden bu kadar düşüş "geri çekilme" sayılır. Ölçüm gürültüsünün
  /// geri çekilme sanılmasını önler.
  final double hysteresis;

  /// Bu tepeye ulaşmamış hareket hiç girişim sayılmaz — gard titremesini eler.
  final double minPeakExtension;

  final String feedbackKey;
}
