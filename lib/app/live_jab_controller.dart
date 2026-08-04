import 'dart:async';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import '../shell_candidate/live_surface.dart' show LiveState;
import 'live_session_failure.dart';
import 'session_narrator.dart';

/// CANLI JAB HATTI — kamera zarfından dürüst yüzeye (J-096).
///
/// ## Zincir
///
/// ```
/// MotionCameraController.frames()   → CameraFrameEnvelope
///   → EnvelopeDriver.load()          (çekirdek dikişi, push→pull)
///   → OrientationAwarePoseSource.next()
///   → StrikingEngine.process()       → EngineOutput
///   → LiveJabState                   (yüzeyin okuduğu tek şey)
/// ```
///
/// Halkaların hiçbiri burada YENİDEN yazılmadı: sürücü adaptörü
/// (`EnvelopeDriver`) ve yönelim çözümü çekirdekten geliyor. Bu sınıfın işi
/// **çeviri ve dürüstlük**: motorun teknik çıktısını kullanıcının okuyacağı
/// hâle çevirmek ve çevirirken hiçbir şey uydurmamak.
///
/// ## ⚠️ CİHAZDA KANITLANMADI
///
/// Bu hat iOS simülatöründe ve Android emülatöründe **derleniyor ve
/// sahte-kaynakla uçtan uca koşuyor**. Gerçek cihazda gerçek bir insanla
/// **hiç çalıştırılmadı** (§7.3-7.7 kurucu-manuel, isimli release-gate).
/// Bu dosyadaki hiçbir yorum "cihazda kanıtlı" demez; iki beyan ayrıdır.
///
/// ## K8 — sayım evet, SKOR hayır
///
/// [LiveJabState.completedCount] bir OLGUDUR (faz makinesi bir denemeyi
/// tamamladı), bir hüküm değil — `RecordedSummary`nin seans sayısıyla aynı
/// sınıf. Kalibrasyonsuz yasak olan şey SKORDUR (M-F-04/K8): "gardın %72
/// iyi" gibi bir sayı. Sayım ve faz adı kalibrasyon gerektirmez.
final class LiveJabController {
  LiveJabController({
    required this.ruleSet,
    required this.cues,
    required this.modelPath,
    required this.modelId,
    MotionCameraController? camera,
    Future<bool> Function()? requestPermission,
    Future<bool> Function()? permissionPermanentlyDenied,
    OrientationAwarePoseSource Function(PoseSourceDriver)? sourceFactory,
    StrikingEngine Function(FrameSize)? engineFactory,
  })  : _camera = camera ?? MotionCameraController(),
        _requestPermission = requestPermission,
        _permissionPermanentlyDenied = permissionPermanentlyDenied,
        _sourceFactory = sourceFactory ?? OrientationAwarePoseSource.new,
        _engineFactory = engineFactory;

  final RuleSet ruleSet;

  /// Replik kitabı — motorun hata KODUNU kullanıcı cümlesine çeviren tek yol.
  /// Enjekte ediliyor ki testler içerikten bağımsız koşabilsin.
  final CueBook cues;

  final String modelPath;
  final String modelId;

  final MotionCameraController _camera;
  final Future<bool> Function()? _requestPermission;
  final Future<bool> Function()? _permissionPermanentlyDenied;
  final OrientationAwarePoseSource Function(PoseSourceDriver) _sourceFactory;
  final StrikingEngine Function(FrameSize)? _engineFactory;

  final EnvelopeDriver _driver = EnvelopeDriver();
  final StreamController<LiveJabState> _states =
      StreamController<LiveJabState>.broadcast();

  OrientationAwarePoseSource? _source;
  StrikingEngine? _engine;
  StreamSubscription<CameraFrameEnvelope>? _sub;
  bool _running = false;
  int _completed = 0;

  Stream<LiveJabState> get states => _states.stream;

  /// Seansı başlatır. Başarısızlıkta **fırlatmaz** — tipli hâl DÖNER.
  ///
  /// Fırlatmak çağıranı `catch` içinde sınıflandırmaya zorlardı ve
  /// sınıflandırmanın tek yerde olması bu tasarımın bütün amacı
  /// (`ContentFailure.from` ile aynı gerekçe).
  Future<LiveSessionFailure?> start() async {
    if (_running) {
      return const LiveCameraUnavailable(
          failure: CameraFailure.alreadyRunning,
          nativeDetail: 'controller already started');
    }
    try {
      // İZİN ÖNCE, kamera SONRA. Ters sırada plugin kendi isimli reddiyle
      // dönerdi ve kullanıcıya "kamera açılamadı" derdik — oysa sorun izin
      // ve çözümü kullanıcının elinde.
      final Future<bool> Function()? ask = _requestPermission;
      if (ask != null && !await ask()) {
        final bool permanent =
            await (_permissionPermanentlyDenied?.call() ?? Future<bool>.value(false));
        return LivePermissionDenied(permanentlyDenied: permanent);
      }

      final CameraSessionInfo info = await _camera.start(
        modelPath: modelPath,
        modelId: modelId,
        lens: CameraLens.front,
        // Jab DİK bir teknik: ters-geçiş planlamak her kare için ikinci bir
        // çıkarım koşturur (ADR-001 sonucu #2, 2× maliyet) ve boksta ters
        // gövde beklenen bir hâl değil. Gravita'nın el-standı hattı bunun
        // tersini ister — plan TEKNİĞE aittir, app'e değil.
        initialPlan: PassPlan.uprightOnly,
      );
      _startFor(info);
      return null;
    } on CameraException catch (e) {
      return LiveCameraUnavailable(failure: e.failure, nativeDetail: e.detail);
    } on Object catch (e) {
      // Tanımadığımız hata isimli bir plugin reddi gibi SUNULMAZ.
      return LiveSetupFailed(e);
    }
  }

  void _startFor(CameraSessionInfo info) {
    _running = true;
    _completed = 0;
    _source = _sourceFactory(_driver);
    _sub = _camera.frames().listen(_onEnvelope, onError: _onStreamError);
    _states.add(const LiveJabState.starting());
  }

  void _onEnvelope(CameraFrameEnvelope envelope) {
    final OrientationAwarePoseSource? source = _source;
    if (!_running || source == null) return;

    // ⚠️ MOTOR İLK ZARFTA KURULUYOR, ÖNCE DEĞİL: `frameSize` gerçek kamera
    // karelerinde ZORUNLU (J-028) ve doğru değeri yalnız zarf biliyor.
    // Sabit bir boyut yazmak ölçüleri en-boy oranı kadar SESSİZCE yanlış
    // yapardı — hiçbir test görmeden.
    final StrikingEngine engine = _engine ??= _buildEngine(envelope.size);

    _driver.load(envelope);
    final OrientationResolution resolution =
        source.next(envelope.tUs, const OrientationExpectation.exactly(BodyOrientation.upright));

    if (!resolution.usable) {
      // Model kimseyi göremedi. HATA DEĞİL — canlı bir hâl; seans koşmaya
      // devam ediyor ve kendi kendine düzelebilir.
      _states.add(LiveJabState.live(
        surface: LiveState.noVerdict,
        completedCount: _completed,
        noVerdictReason: 'I cannot see you well enough to judge — step back '
            'so your head and hands are in frame.',
      ));
      return;
    }

    final EngineOutput out = engine.process(resolution.frame!);
    if (out.completedAttempt?.completed ?? false) _completed += 1;

    if (!out.judgeable) {
      _states.add(LiveJabState.live(
        surface: LiveState.noVerdict,
        completedCount: _completed,
        // Motorun KENDİ sebebi kullanılıyor; burada yeniden cümle kurmak
        // iki ayrı gerçeğin (motorun bastırma sebebi / benim tahminim)
        // birbirinden ayrılamaz hâle gelmesi olurdu.
        noVerdictReason: out.suppressionReason,
      ));
      return;
    }

    // TEK düzeltme (kabuk ilkesi): telefonu uzağa koymuş kullanıcı bir liste
    // uygulayamaz. İlk sıradaki alınıyor — motor zaten önceliğe göre üretiyor.
    final DetectedIssue? issue = out.issues.isEmpty ? null : out.issues.first;

    // GÖRÜNÜRLÜK kodu bir DÜZELTME DEĞİL: kullanıcı yanlış bir şey yapmıyor,
    // biz göremiyoruz. Düzeltme yuvasına koymak, olmayan bir hatayı
    // düzelttirmek olurdu.
    if (issue != null && jabLabVisibilityIssueCodes.contains(issue.code)) {
      _states.add(LiveJabState.live(
        surface: LiveState.noVerdict,
        completedCount: _completed,
        noVerdictReason: _phrase(issue.code) ?? _genericNoVerdict,
        phase: out.activePhase,
      ));
      return;
    }

    _states.add(LiveJabState.live(
      surface: issue == null ? LiveState.clean : LiveState.correcting,
      completedCount: _completed,
      // HAM KOD ASLA: `REAR_HAND_LOW` bir teşhis dizesidir. İçerik eksikse
      // kod gösterilmez, genel ama DÜRÜST bir cümle gösterilir.
      cue: issue == null ? null : (_phrase(issue.code) ?? _genericIssue),
      phase: out.activePhase,
    ));
  }

  void _onStreamError(Object error) {
    // Akış ortasında gelen hata seansı ÖLDÜRÜR ve söyler. Sessizce son
    // durumu ekranda bırakmak, kullanıcıya donmuş bir sayıyı canlıymış gibi
    // göstermek olurdu (J-092'nin bayat-özet dersinin canlı karşılığı).
    _running = false;
    _states.add(LiveJabState.failed(error is CameraException
        ? LiveCameraUnavailable(failure: error.failure, nativeDetail: error.detail)
        : LiveSetupFailed(error)));
  }

  /// Kod → cümle. Eşlenmemiş ya da içerikte olmayan kod için `null`.
  String? _phrase(String code) {
    final String? key = jabLabIssueCueMapping[code];
    return key == null ? null : cues.sayKey(key);
  }

  /// İçerik boşluğunda gösterilen cümle. Kodun kendisi DEĞİL — ve sessizlik
  /// de değil: sessizlik canlı koçta "her şey yolunda" diye okunur.
  static const String _genericIssue =
      'Something in that one needs fixing, but we do not have the words for '
      'it yet.';
  static const String _genericNoVerdict =
      'I cannot judge that clearly enough right now.';

  StrikingEngine _buildEngine(FrameSize size) =>
      _engineFactory?.call(size) ??
      StrikingEngine(
        ruleSet: ruleSet,
        frameSize: size,
        // KALİBRASYON YOK ve bu bilerek: taraf etiketi (M-F-06) raporlanamaz
        // ve K8 sayısal skoru kapalı tutar. `true` yazmak kalibre edilmemiş
        // bir kurulumda "sol/sağ" demeye izin verirdi.
        calibrationMapped: false,
        provenance: <String, String>{'modelId': modelId},
      );

  Future<void> stop() async {
    _running = false;
    await _sub?.cancel();
    _sub = null;
    try {
      await _camera.stop();
    } on Object catch (_) {
      // Kapanışta hata YUTULUR: kullanıcı zaten ayrılıyor ve "kapatılamadı"
      // demenin yapabileceği hiçbir şey yok.
    }
  }

  Future<void> dispose() async {
    await stop();
    await _states.close();
  }
}

/// Yüzeyin okuduğu tek şey — motorun teknik çıktısının ÇEVRİLMİŞ hâli.
sealed class LiveJabState {
  const LiveJabState();

  const factory LiveJabState.starting() = LiveJabStarting;

  const factory LiveJabState.live({
    required LiveState surface,
    required int completedCount,
    String? cue,
    String? narration,
    String? noVerdictReason,
    String? phase,
  }) = LiveJabRunning;

  const factory LiveJabState.failed(LiveSessionFailure failure) =
      LiveJabFailed;
}

/// Kamera açıldı, ilk zarf henüz gelmedi.
///
/// Ayrı hâl olmasının sebebi: bu anda `completedCount` SIFIRDIR ve sıfırı
/// göstermek "hiç yumruk atmadın" demektir — oysa henüz hiçbir şey
/// ölçülmedi. "Bilmiyorum" ile "sıfır" ayrımının canlı ekrandaki hâli.
final class LiveJabStarting extends LiveJabState {
  const LiveJabStarting();
}

final class LiveJabRunning extends LiveJabState {
  const LiveJabRunning({
    required this.surface,
    required this.completedCount,
    this.cue,
    this.narration,
    this.noVerdictReason,
    this.phase,
  });

  final LiveState surface;

  /// Tamamlanmış jab denemesi sayısı — OLGU, hüküm DEĞİL (K8 açıklaması
  /// sınıf dokümanında).
  final int completedCount;

  final String? cue;
  final String? narration;
  final String? noVerdictReason;
  /// Faz makinesinin o andaki fazı — canlı geri bildirim. Bir hüküm DEĞİL,
  /// durum bildirimi; K8 kapısına takılmaz.
  final String? phase;
}

final class LiveJabFailed extends LiveJabState {
  const LiveJabFailed(this.failure);

  final LiveSessionFailure failure;
}
