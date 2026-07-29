import 'package:motion_core/motion_core.dart';

import 'measures.dart';
import 'ruleset.dart';
import 'stance.dart';

/// Bir denemenin (tek teknik icrası) native→Dart sözleşmesi (ADR-002).
///
/// Kural motoru 30fps ham landmark GÖRMEZ; her denemeden yalnız bu özeti alır:
/// faz zaman damgaları + üç anahtar anın ölçü anlık görüntüsü. Yumruk başına
/// yük ~3 anlık görüntü — kanal için ihmal edilebilir, kurallar için yeterli.
final class AttemptDigest {
  const AttemptDigest({
    required this.techniqueId,
    required this.limb,
    required this.outcome,
    required this.transitions,
    required this.snapshots,
    required this.extensionMs,
    required this.tempoBand,
    required this.provenance,
  });

  final String techniqueId;
  final Side limb;
  final AttemptOutcome outcome;

  /// faz kimliği → giriş anı (µs).
  final Map<String, int> transitions;

  /// t0 / tPeak / t1 anlarının ölçüleri.
  final Map<String, MeasureSet> snapshots;

  /// ADR-001: hız/tempo YALNIZ buradan türetilir, kare-arası pikselden DEĞİL.
  final double? extensionMs;

  /// ADR-001: kullanıcıya sayı değil BANT gösterilir.
  final String? tempoBand;

  /// M-F-07: model varyantı/SHA, kural-seti sürümü, kalibrasyon profili.
  final Map<String, String> provenance;

  bool get completed => outcome == AttemptOutcome.completed;

  @override
  String toString() => 'AttemptDigest($techniqueId/${limb.name}, '
      '${outcome.name}, ext=${extensionMs?.toStringAsFixed(1)}ms, $tempoBand)';
}

final class DetectedIssue {
  const DetectedIssue({
    required this.code,
    required this.severity,
    required this.band,
    required this.confidence,
    required this.evidence,
    required this.feedbackKey,
    required this.tUs,
    this.drillId,
  });

  final String code;
  final String severity;
  final String band;
  final double confidence;

  /// Açıklanabilirlik ürün gereği: hangi ölçü, hangi değer, hangi eşik.
  final String evidence;
  final String feedbackKey;
  final String? drillId;
  final int tUs;

  @override
  String toString() => 'DetectedIssue($code @ ${tUs / 1000}ms — $evidence)';
}

final class EngineOutput {
  const EngineOutput({
    required this.tUs,
    required this.judgeable,
    required this.stance,
    this.measures,
    this.suppressionReason,
    this.completedAttempt,
    this.issues = const <DetectedIssue>[],
  });

  final int tUs;

  /// false iken TEKNİK HÜKÜM VERİLMEZ (plan §12). Sebep [suppressionReason].
  final bool judgeable;
  final StanceReading stance;
  final MeasureSet? measures;
  final String? suppressionReason;
  final AttemptDigest? completedAttempt;
  final List<DetectedIssue> issues;
}

/// Değişebilir değerlendirme bağlamı — faz koşulu kapanışları bunu okur.
final class _Ctx implements EvalContext {
  _Ctx(this.ruleSet);

  final RuleSet ruleSet;

  @override
  late MeasureSet measures;
  @override
  Side limb = Side.lead;
  @override
  double frameQuality = 1;
  @override
  bool requiredRegionOutOfFrame = false;
  @override
  String? sequenceMismatch;
  @override
  String? tempoBand;
  @override
  double errorRateInWindow = 0;

  final Map<String, double> _phaseDurations = <String, double>{};

  @override
  double? phaseDurationMs(String phaseId) => _phaseDurations[phaseId];

  void setPhaseDuration(String id, double ms) => _phaseDurations[id] = ms;
  void clearPhaseDurations() => _phaseDurations.clear();
}

/// Standing Striking Engine — branş-bağımsız ayakta-vuruş analiz motoru.
///
/// Boks bilgisi YOKTUR: teknikler, fazlar, eşikler ve hatalar [RuleSet]'ten
/// gelir (ADR-004). Kickboks/Muay Thai aynı motora yeni bir config ile takılır.
final class StrikingEngine {
  StrikingEngine({
    required this.ruleSet,
    PosePipeline? pipeline,
    this.stanceDetector = const StanceDetector(),
    this.measureCalculator = const MeasureCalculator(),
    this.calibrationMapped = false,
    this.frameSize,
    MotionClock? clock,
    CueGate? cueGate,
    this.provenance = const <String, String>{},
  })  : clock = clock ?? StopwatchMotionClock.start(),
        cueGate = cueGate ?? CueGate(),
        _pipeline = pipeline ??
            PosePipeline(
              // Filtre config'ten gelir: eşikler ve filtre AYRI AYRI
              // değiştirilemez (M-C-07/J-016). Varsayılan çekirdek filtresi
              // (1 Hz) bir yumruğu yok eder — ölçüldü.
              smoother: PoseSmoother(
                minCutoff: ruleSet.smoothingMinCutoff,
                beta: ruleSet.smoothingBeta,
                derivativeCutoff: ruleSet.smoothingDerivativeCutoff,
              ),
            ) {
    _ctx = _Ctx(ruleSet);
    for (final TechniqueConfig t in ruleSet.techniques) {
      _machines[t.id] = PhaseStateMachine(
        techniqueId: t.id,
        phases: _compile(t),
        lostTrackingGraceUs: t.trackingLostMs * 1000,
      );
    }
  }

  final RuleSet ruleSet;
  final PosePipeline _pipeline;
  final StanceDetector stanceDetector;
  final MeasureCalculator measureCalculator;

  /// M-F-09: ölçüm modlarında kalibrasyon SERT KAPI. Motor bunu bilmez ama
  /// taraf etiketinin raporlanabilirliğini (M-F-06) belirler.
  final bool calibrationMapped;

  /// Gerçek kamera karelerinde ZORUNLU (J-028): verilmezse ölçüler sessizce
  /// en-boy oranı kadar yanlış olur — MediaPipe x'i genişliğe, y'yi yüksekliğe
  /// AYRI normalize eder. Sentetik fixture'larda null bırakılır.
  final FrameSize? frameSize;

  /// Tek monotonik saat — analiz, sesli koç ve kayıt aynı zamanı kullanır.
  final MotionClock clock;

  /// Koç konuşurken hüküm kapısı.
  ///
  /// ⚠️ JabLab semantiği Ostinato'dan FARKLI: orada cue mikrofonu kirletir ve
  /// TÜM analiz susar. Burada kamera kirlenmez — ama koç konuşurken kullanıcı
  /// bir ÖNCEKİ düzeltmeye tepki veriyordur; o anda yeni hüküm vermek,
  /// düzeltmenin ortasındaki insanı yargılamaktır. Bu yüzden **tespit sürer,
  /// hüküm susar**: yumruk sayılmaya devam eder, yeni hata kodu üretilmez.
  /// (plan §13 "tur içinde TEK hata" disiplininin motor tarafı.)
  final CueGate cueGate;

  final Map<String, String> provenance;

  final Map<String, PhaseStateMachine> _machines = <String, PhaseStateMachine>{};
  final Map<String, int> _lastFiredUs = <String, int>{};
  final Map<String, int> _firedThisRound = <String, int>{};
  final Map<String, Map<String, MeasureSet>> _snapshots =
      <String, Map<String, MeasureSet>>{};
  final Map<String, Map<String, int>> _transitions = <String, Map<String, int>>{};

  late final _Ctx _ctx;
  MeasureSet? _previous;
  Stance? _lastStance;
  int _lastStanceSampleUs = -1 << 30;

  /// Sesli koç bir cue çalmaya başladı.
  void cueStarted(int tUs) => cueGate.cueStarted(tUs);

  /// Cue bitti; [CueGate.ringOutUs] kadar daha hüküm verilmez.
  void cueEnded(int tUs) => cueGate.cueEnded(tUs);

  /// Yeni tur: cooldown ve tur-başı sayaçları sıfırlanır.
  void startRound() {
    _firedThisRound.clear();
    _lastFiredUs.clear();
  }

  void reset() {
    _pipeline.reset();
    for (final PhaseStateMachine m in _machines.values) {
      m.reset();
    }
    _snapshots.clear();
    _transitions.clear();
    _previous = null;
    _lastStance = null;
  }

  List<PhaseDefinition> _compile(TechniqueConfig t) {
    return t.phases.map((PhaseConfig p) {
      return PhaseDefinition(
        id: p.id,
        enter: (PhaseContext _) {
          _ctx.limb = t.limb;
          return p.enter.test(_ctx);
        },
        timeoutUs: p.timeoutMs == null ? null : p.timeoutMs! * 1000,
        isTerminal: p.terminal,
      );
    }).toList(growable: false);
  }

  EngineOutput process(PoseFrame frame) {
    final ProcessedFrame pf = _pipeline.process(frame);

    final StanceReading stance = stanceDetector.read(
      pf.smoothed,
      calibrationMapped: calibrationMapped,
      structurallyClean: pf.structure.plausible,
      previous: _lastStance,
      frameSize: frameSize,
    );
    _lastStance = stance.stance;

    final MeasureSet m = measureCalculator
        .compute(pf.smoothed, stance.stance,
            previous: _previous, frameSize: frameSize);
    _previous = m;

    // --- Hüküm verilebilir mi? Üç kapı, sırayla ------------------------
    String? suppress;
    if (!pf.structure.plausible) {
      // M-019: güven yüksek olsa bile vücut yapısı imkânsızsa hüküm YOK.
      suppress = 'structural:${pf.structure.faults.map((StructuralFault f) => f.name).join(",")}';
    } else if (!pf.quality.judgeable) {
      suppress = 'quality:${pf.quality.issue?.name ?? "low"}';
    } else {
      // J-013: anatomik imkânsızlık (e>1 düz kolda geometrik olarak olamaz).
      for (final Side s in Side.values) {
        final double? e = m.read('extensionRatio', limb: s);
        if (e != null && e > ruleSet.maxExtensionRatio) {
          suppress = 'integrity:extensionRatio=${e.toStringAsFixed(2)}';
          break;
        }
      }
    }

    _ctx.measures = m;
    _ctx.frameQuality = pf.quality.meanVisibility;
    _ctx.requiredRegionOutOfFrame = pf.quality.offFrameLandmarks.isNotEmpty;

    if (suppress != null) {
      return EngineOutput(
        tUs: frame.tUs,
        judgeable: false,
        stance: stance,
        measures: m,
        suppressionReason: suppress,
        issues: _blockingIssues(frame.tUs, suppress),
      );
    }

    // --- Faz makineleri ------------------------------------------------
    // J-026: aynı harekette birden çok teknik tamamlanabilir (bir jab AYNI
    // ZAMANDA sınıflandırılmamış vuruştur). Bu kare içindeki tamamlanmalar
    // toplanır, sonra tahkim edilir — yoksa her yumruk iki kez sayılır.
    AttemptDigest? specific;
    AttemptDigest? fallback;
    final List<DetectedIssue> issues = <DetectedIssue>[];

    for (final TechniqueConfig t in ruleSet.techniques) {
      final PhaseStateMachine machine = _machines[t.id]!;
      final String? before = machine.currentPhase;
      final AttemptRun? run = machine.update(pf.smoothed, pf.angles);
      final String? after = machine.currentPhase;

      if (after != null && after != before) {
        _snapshots.putIfAbsent(t.id, () => <String, MeasureSet>{})[after] = m;
        _transitions.putIfAbsent(t.id, () => <String, int>{})[after] = frame.tUs;
        if (t.emitsErrors) {
          issues.addAll(_evaluateErrors(t, after, m, frame.tUs));
        }
      }

      if (run != null) {
        final AttemptDigest digest = _buildDigest(t, run);
        _snapshots.remove(t.id);
        _transitions.remove(t.id);
        if (digest.completed) {
          if (t.isFallback) {
            fallback ??= digest;
          } else {
            specific ??= digest;
          }
        }
      }
    }

    // Tahkim: spesifik teknik kazanır. Yedek yalnız hiçbir spesifik teknik
    // tamamlanmadı VE hiçbiri hâlâ çalışmıyorken sayılır — çalışan bir makine,
    // birkaç kare sonra tamamlanacak spesifik bir yumruk demektir.
    final bool specificRunning = ruleSet.techniques.any((TechniqueConfig t) =>
        !t.isFallback && (_machines[t.id]?.isRunning ?? false));
    final AttemptDigest? finished =
        specific ?? (specificRunning ? null : fallback);

    // Koç konuşurken YENİ hüküm yok (yukarıdaki gerekçe). Deneme tespiti ve
    // sayım etkilenmez — yalnız hata kodu emisyonu susar.
    final bool verdictsAllowed = cueGate.isAnalysisClean(frame.tUs);
    if (!verdictsAllowed) issues.clear();

    // Duruş örneklemesi: her karede değil, 2 sn'de bir (config STANCE_SAMPLE).
    if (frame.tUs - _lastStanceSampleUs > 2000000) {
      _lastStanceSampleUs = frame.tUs;
      if (verdictsAllowed) {
        issues.addAll(_evaluateErrorsAtMarker('STANCE_SAMPLE', m, frame.tUs));
      }
    }
    issues.addAll(_evaluateErrorsAtMarker('ANY', m, frame.tUs));
    if (!verdictsAllowed) issues.clear();

    return EngineOutput(
      tUs: frame.tUs,
      judgeable: true,
      stance: stance,
      measures: m,
      completedAttempt: finished,
      issues: issues,
    );
  }

  AttemptDigest _buildDigest(TechniqueConfig t, AttemptRun run) {
    final Map<String, int> tr = <String, int>{};
    for (final PhaseTransition x in run.transitions) {
      tr[x.toPhase] = x.tUs;
    }
    // ADR-001: uzanma süresi = ilk faz girişi → tepe fazı girişi.
    final int? t0 = run.transitions.isNotEmpty ? run.transitions.first.tUs : null;
    final int? tPeak = tr['PEAK'];
    final double? extMs =
        (t0 != null && tPeak != null) ? (tPeak - t0) / 1000.0 : null;

    return AttemptDigest(
      techniqueId: t.id,
      limb: t.limb,
      outcome: run.outcome,
      transitions: tr,
      snapshots: Map<String, MeasureSet>.from(
          _snapshots[t.id] ?? const <String, MeasureSet>{}),
      extensionMs: extMs,
      tempoBand: extMs == null ? null : ruleSet.tempoBandFor(extMs),
      provenance: <String, String>{
        'ruleSetVersion': '${ruleSet.rulesetId}@${ruleSet.version}',
        'thresholdStatus': ruleSet.thresholdStatus,
        ...provenance,
      },
    );
  }

  List<DetectedIssue> _evaluateErrors(
      TechniqueConfig t, String phaseId, MeasureSet m, int tUs) {
    _ctx.limb = t.limb;
    return _evaluateErrorsAtMarker(phaseId, m, tUs);
  }

  List<DetectedIssue> _evaluateErrorsAtMarker(
      String marker, MeasureSet m, int tUs) {
    final List<DetectedIssue> out = <DetectedIssue>[];
    for (final ErrorConfig e in ruleSet.errors) {
      if (!e.evaluateAt.contains(marker)) continue;
      if (e.suppressesJudgement) continue; // bloklayıcılar ayrı yolda
      if (!_cooldownOk(e, tUs)) continue;
      if (!e.condition.test(_ctx)) continue;
      _fire(e, tUs);
      out.add(DetectedIssue(
        code: e.code,
        severity: e.severity,
        band: e.band,
        confidence: e.minConfidence,
        evidence: _evidence(e),
        feedbackKey: e.feedbackKey,
        drillId: e.drillId,
        tUs: tUs,
      ));
    }
    return out;
  }

  List<DetectedIssue> _blockingIssues(int tUs, String reason) {
    final List<DetectedIssue> out = <DetectedIssue>[];
    for (final ErrorConfig e in ruleSet.errors) {
      if (!e.suppressesJudgement) continue;
      final bool matches = (e.code == 'OUT_OF_FRAME' &&
              reason.startsWith('quality') &&
              _ctx.requiredRegionOutOfFrame) ||
          (e.code == 'LOW_TRACKING_CONFIDENCE' && !reason.startsWith('integrity'));
      if (!matches || !_cooldownOk(e, tUs)) continue;
      _fire(e, tUs);
      out.add(DetectedIssue(
        code: e.code,
        severity: e.severity,
        band: e.band,
        confidence: 1,
        evidence: reason,
        feedbackKey: e.feedbackKey,
        drillId: e.drillId,
        tUs: tUs,
      ));
    }
    return out;
  }

  bool _cooldownOk(ErrorConfig e, int tUs) {
    final int fired = _firedThisRound[e.code] ?? 0;
    if (fired >= e.maxPerRound) return false;
    final int? last = _lastFiredUs[e.code];
    if (last != null && tUs - last < e.cooldownMs * 1000) return false;
    return true;
  }

  void _fire(ErrorConfig e, int tUs) {
    _lastFiredUs[e.code] = tUs;
    _firedThisRound[e.code] = (_firedThisRound[e.code] ?? 0) + 1;
  }

  String _evidence(ErrorConfig e) {
    final List<String> parts = <String>[];
    for (final Clause c in e.condition.clauses) {
      final double? v = _ctx.measures.read(c.key, limb: _ctx.limb);
      parts.add(v == null ? c.key : '${c.key}=${v.toStringAsFixed(3)}');
    }
    return parts.join(' · ');
  }
}
