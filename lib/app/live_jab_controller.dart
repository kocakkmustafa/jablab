import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import '../shell_candidate/live_surface.dart' show LiveState;
import 'camera_capture_coordinator.dart';
import 'live_honesty.dart';
import 'live_session_failure.dart';
import 'session_narrator.dart';

/// CANLI JAB HATTI — kamera zarfından dürüst yüzeye (J-096).
///
/// ## Zincir
///
/// ```
/// CameraCaptureLease.frames()       → CameraFrameEnvelope
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
    Set<String>? allowedTechniqueIds,
    MotionCameraController? camera,
    Future<bool> Function()? requestPermission,
    Future<bool> Function()? permissionPermanentlyDenied,
    OrientationAwarePoseSource Function(PoseSourceDriver)? sourceFactory,
    StrikingEngine Function(FrameSize)? engineFactory,
  }) : allowedTechniqueIds = allowedTechniqueIds == null
           ? null
           : Set.unmodifiable(allowedTechniqueIds),
       _camera = camera ?? MotionCameraController(),
       _requestPermission = requestPermission,
       _permissionPermanentlyDenied = permissionPermanentlyDenied,
       _sourceFactory = sourceFactory ?? OrientationAwarePoseSource.new,
       _engineFactory = engineFactory;

  final RuleSet ruleSet;

  /// Immutable lesson intent; null retains unscoped diagnostic/test behavior.
  /// Production always supplies the explicit lesson selection, including empty.
  final Set<String>? allowedTechniqueIds;

  /// Replik kitabı — motorun hata KODUNU kullanıcı cümlesine çeviren tek yol.
  /// Enjekte ediliyor ki testler içerikten bağımsız koşabilsin.
  final CueBook cues;

  /// Model yolu **GEÇ çözülür** — `start()` içinde, ders açılışında değil.
  ///
  /// İlk yazışımda `String` idi ve çağıran onu ders açılmadan ÖNCE
  /// hazırlıyordu: 9 MB'lık asset diske çıkarılana kadar kullanıcı derse
  /// dokunuyor ve HİÇBİR ŞEY olmuyordu. Maliyet, gerçekten gerektiği ana
  /// (canlı aşama) ertelendi.
  final Future<String> Function() modelPath;
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
  bool _starting = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void>? _disposal;
  bool _nativeSubmitted = false;
  CameraCaptureLease? _capture;
  Future<void>? _retirement;
  int _completed = 0;

  /// D18: motor her tamamlanmış denemede bir tempo bandı üretiyordu
  /// (ADR-001, `AttemptDigest.tempoBand`) ve hiçbir yüzey göstermiyordu —
  /// ürünün kendi dürüstlük metni bunu itiraf ediyordu ("there is no
  /// screen that shows you the band"). MS-1 sonrasında bant yalnız geçerli
  /// EXTENSION→PEAK gözleminden gelir. Bu yazılım aralığı ve ham eşikler,
  /// fiziksel tempo kalibrasyonu veya kamera aktivasyonu kabulü değildir.
  ///
  /// Tekil bant yerine SAYAÇ tutuluyor: bir seansta yumruklar farklı
  /// bantlara düşebilir (yorgunluk yavaşlatır), "son yumruk" o değişimi
  /// gizler. Özet ekranı en SIK görüleni gösterir — [dominantTempoBand].
  final Map<String, int> _tempoBandCounts = <String, int>{};

  /// Geçerli tempo gözlemi olan tamamlanmış denemelerde en sık bant.
  /// `null`, geçerli tempo gözlemi yok demektir; tamamlanmış deneme sayısı
  /// pozitif olabilir. Varsayılan bant veya sıfır uydurulmaz.
  String? get dominantTempoBand => modeOfCounts(_tempoBandCounts);

  /// Son TAMAMLANMIŞ denemenin ilk hata kodu — `cue.corrected`in tek girdisi
  /// (J-105). `null` iki şey demek olabilir: henüz deneme yok, ya da son
  /// deneme temizdi; ikisinde de "düzeltildi" DİYEMEYİZ, çünkü ortada
  /// kaybolan bir işaret yok. Bu yüzden ayrı bir "henüz deneme yok" hâline
  /// gerek kalmadı — her iki hâlde de doğru davranış aynı: sus.
  String? _lastAttemptIssueCode;

  /// "Seni görüyorum" bir kez söylendi mi (J-120). Her karede tekrarlamak
  /// canlı koçu gürültüye çevirir ve gürültü susmakla aynı sonucu verir.
  bool _announcedReady = false;

  Stream<LiveJabState> get states => _states.stream;

  /// True once native startup is submitted, including an outstanding reply.
  bool get hasNativeSession => _nativeSubmitted;

  /// Seansı başlatır. Başarısızlıkta **fırlatmaz** — tipli hâl DÖNER.
  ///
  /// Fırlatmak çağıranı `catch` içinde sınıflandırmaya zorlardı ve
  /// sınıflandırmanın tek yerde olması bu tasarımın bütün amacı
  /// (`ContentFailure.from` ile aynı gerekçe).
  Future<LiveSessionFailure?> start({
    Future<void> Function()? beforeCameraStart,
  }) async {
    if (_disposed) return _interrupted;
    if (_starting || _running) {
      return const LiveCameraUnavailable(
        failure: CameraFailure.alreadyRunning,
        nativeDetail: 'controller already started',
      );
    }
    _starting = true;
    final int generation = ++_generation;
    final capture = _camera.createCaptureLease();
    _capture = capture;
    bool current() => !_disposed && generation == _generation;
    LiveSessionFailure? failure;
    try {
      failure = await _prepareCapture(capture, current, beforeCameraStart);
    } on CameraException catch (e) {
      failure = current()
          ? LiveCameraUnavailable(failure: e.failure, nativeDetail: e.detail)
          : _interrupted;
    } on Object catch (e) {
      failure = current() ? LiveSetupFailed(e) : _interrupted;
    }
    try {
      if (failure != null) {
        try {
          if (identical(_capture, capture)) {
            await stop();
          } else {
            await CameraCaptureCoordinator.close(capture);
          }
        } on Object catch (e) {
          final closeFailure = CameraCaptureCoordinator.recordUncertainty(e);
          failure = LiveCameraUnavailable(
            failure: closeFailure.failure,
            nativeDetail: closeFailure.detail,
          );
        }
      }
      return failure;
    } finally {
      _starting = false;
    }
  }

  Future<LiveSessionFailure?> _prepareCapture(
    CameraCaptureLease capture,
    bool Function() current,
    Future<void> Function()? beforeCameraStart,
  ) async {
    await CameraCaptureCoordinator.waitForClosure();
    if (!current() || capture.isRetired) return _interrupted;
    // İZİN ÖNCE, kamera SONRA. Ters sırada plugin kendi isimli reddiyle
    // dönerdi ve kullanıcıya "kamera açılamadı" derdik — oysa sorun izin
    // ve çözümü kullanıcının elinde.
    final Future<bool> Function()? ask = _requestPermission;
    final bool granted = ask == null || await ask();
    if (!current()) return _interrupted;
    if (!granted) {
      final bool permanent =
          await (_permissionPermanentlyDenied?.call() ??
              Future<bool>.value(false));
      if (!current()) return _interrupted;
      return LivePermissionDenied(permanentlyDenied: permanent);
    }

    final String path = await modelPath();
    if (!current()) return _interrupted;
    // An OS permission dialog may temporarily make the app inactive.
    // The screen supplies a foreground gate; stop invalidates this work.
    await beforeCameraStart?.call();
    if (!current()) return _interrupted;
    _nativeSubmitted = true;
    final CameraSessionInfo info = await capture.start(
      modelPath: path,
      modelId: modelId,
      lens: CameraLens.front,
      // Jab DİK bir teknik: ters-geçiş planlamak her kare için ikinci bir
      // çıkarım koşturur (ADR-001 sonucu #2, 2× maliyet) ve boksta ters
      // gövde beklenen bir hâl değil. Gravita'nın el-standı hattı bunun
      // tersini ister — plan TEKNİĞE aittir, app'e değil.
      initialPlan: PassPlan.uprightOnly,
    );
    if (!current()) return _interrupted;
    _startFor(info, capture);
    return null;
  }

  static const LiveCameraUnavailable _interrupted = LiveCameraUnavailable(
    failure: CameraFailure.sessionInterrupted,
    nativeDetail: 'session retired during camera setup',
  );

  void _startFor(CameraSessionInfo info, CameraCaptureLease capture) {
    _running = true;
    _completed = 0;
    _tempoBandCounts.clear();
    _engine = null;
    _lastAttemptIssueCode = null;
    _announcedReady = false;
    _source = _sourceFactory(_driver);
    _sub = capture.frames().listen(_onEnvelope, onError: _onStreamError);
    _states.add(const LiveJabState.starting());
  }

  void _onEnvelope(CameraFrameEnvelope envelope) {
    final OrientationAwarePoseSource? source = _source;
    if (!_running || source == null) return;

    // ⚠️ MOTOR İLK ZARFTA KURULUYOR, ÖNCE DEĞİL: `frameSize` gerçek kamera
    // karelerinde ZORUNLU (J-028) ve doğru değeri yalnız zarf biliyor.
    // Sabit bir boyut yazmak ölçüleri en-boy oranı kadar SESSİZCE yanlış
    // yapardı — hiçbir test görmeden.
    _driver.load(envelope);
    final OrientationResolution resolution = source.next(
      envelope.tUs,
      const OrientationExpectation.exactly(BodyOrientation.upright),
    );

    if (!resolution.usable) {
      _discardPartialObservation();
      // ⚠️ `!usable` TEK bir hâl DEĞİL, İKİ ayrı hâl (J-103). Ayrım verisi
      // `resolution.structural`da: `_run()` yalnız model bir iskelet
      // ÜRETTİĞİNDE doğrulayıcıyı çalıştırır, dolayısıyla
      //   `structural == null` → model kimseyi bulamadı
      //   `structural != null` → model BİRİNİ buldu, okuma anatomik olarak
      //                          imkânsız çıktı (`plausible == false`)
      // Tek cümle ikisine birden basılıyordu ve ikincisinde YANLIŞTI:
      // kullanıcı zaten kadrajda, "geri çekil" onu düzeltmez — üstelik
      // uzaklaşmak okumayı kötüleştirir. J-099 ailesinin dördüncü örneği:
      // veri elimizde ama dal ayrılmamış.
      _states.add(
        LiveJabState.live(
          surface: LiveState.noVerdict,
          completedCount: _completed,
          noVerdictReason: resolution.structural == null
              // KİMSE YOK: eylem kullanıcının elinde ve gerçekten kadraja
              // girmek. İskelet YOK — çizilecek hiçbir koordinat yok, boş bir
              // figür çizmek görmediğimiz bir şeyi görüyormuş gibi yapardı.
              ? _nobodyFoundReason
              // KİŞİ VAR, OKUMA BOZUK: kusur BİZDE. Kullanıcıya yapması
              // gereken bir şey söylenmiyor çünkü yok — susmak yerine
              // sorumluluğu üstlenen cümle (`cue.structural`). İskelet burada
              // da YOK ama başka sebeple: `resolution.frame` bu dalda null,
              // yani güvenmediğimiz koordinatlara zaten erişimimiz yok.
              : cues.sayKey('cue.structural') ?? _genericNoVerdict,
          // KİMSE YOK → eylem SENDE (kadraja gir). OKUMA BOZUK → eylem BİZDE.
          // J-103 bu ikisini metinde ayırmıştı; kova ayrımı GÖRSELE taşıyor.
          bucket: resolution.structural == null
              ? LiveHonestyBucket.yours
              : LiveHonestyBucket.ours,
        ),
      );
      return;
    }

    // İLK ÇÖZÜLEN KARE = "seni görüyorum" (J-120). Bir OLGU, eşik yok:
    // model bir iskelet çözdü, o kadar. Motor henüz hüküm veremiyor olabilir
    // (`!judgeable`) ve cümle yine DOĞRU — söylediği şey görmek, yargılamak
    // değil. Bu yüzden dalların HEPSİNDEN önce hesaplanıyor.
    String? readyLine;
    if (!_announcedReady) {
      _announcedReady = true;
      readyLine = cues.sayKey(jabLabReadyCueKey);
    }

    // İSKELET, HÜKÜMDEN BAĞIMSIZ: "ne gördüğüm" ile "ne yargıladığım" ayrı
    // katmanlar (aynen `narration`ın hüküm susarken bile konuşabilmesi gibi).
    // Motor hüküm veremese BİLE (aşağıdaki `!judgeable` dalı) çözülmüş bir
    // kare varsa iskelet çiziliyor — kullanıcı "beni görüyor ama okuyamıyor"
    // ile "beni hiç görmüyor" arasındaki farkı GÖZÜYLE de ayırt edebilsin.
    final List<PoseLandmark> skeleton = resolution.frame!.landmarks;

    final StrikingEngine engine = _engine ??= _buildEngine(envelope.size);
    final EngineOutput out = engine.process(resolution.frame!);

    // DÜZELTME KAYBOLDU MU (J-105). Bir OLGU ölçülüyor, bir eşik DEĞİL:
    // önceki tamamlanmış denemede işaretlenmiş bir hata kodu vardı ve bu
    // tamamlanmış denemede o kod YOK. Kod ya var ya yok — araya sığacak bir
    // sayı, bir süre ya da bir "yeterince" yok.
    //
    // ⚠️ DENEME SINIRINDA ölçülüyor, karede değil. Kare-kare bakmak bir
    // eşik icat etmeye zorlardı ("kaç kare boyunca yok olursa düzeldi
    // sayılır") ve motor zaten denemeyi kendisi kapatıyor — sınırı ondan
    // almak, uydurmamanın tek yolu.
    // This is a source-level guard for the current uncalibrated configuration.
    // A future calibrated label still needs separate capability/model/device
    // acceptance before production camera admission; these flags cannot grant it.
    final bool technicalJudgementsAdmitted =
        !ruleSet.calibrationPending && ruleSet.thresholdStatus == 'calibrated';
    String? correctedLine;
    if (out.completedAttempt?.completed ?? false) {
      _completed += 1;
      final String? band = out.completedAttempt?.tempoBand;
      if (band != null) {
        _tempoBandCounts[band] = (_tempoBandCounts[band] ?? 0) + 1;
      }
      final String? previous = _lastAttemptIssueCode;
      final String? current =
          technicalJudgementsAdmitted && out.issues.isNotEmpty
          ? out.issues.first.code
          : null;
      // GÖRÜNÜRLÜK kodları hariç: "seni göremiyordum, artık görüyorum" bir
      // DÜZELTME değil — kullanıcı bir şey düzeltmedi, koşullar değişti.
      // Onu övmek, yapmadığı bir işi ona mal etmek olurdu.
      if (technicalJudgementsAdmitted &&
          previous != null &&
          current != previous &&
          !jabLabVisibilityIssueCodes.contains(previous)) {
        correctedLine = cues.sayKey(jabLabCorrectedCueKey);
      }
      _lastAttemptIssueCode = current;
    }

    if (!out.judgeable) {
      _discardPartialObservation();
      _states.add(
        LiveJabState.live(
          surface: LiveState.noVerdict,
          completedCount: _completed,
          noVerdictReason: _suppressionSentence(out.suppressionReason),
          // Bastırma sebepleri KULLANICININ düzeltebileceği şeyler
          // (kadraj-dışı, düşük güven, gövde okunamıyor) — `structural:`
          // dalı hariç, ama o dal canlı hatta erişilemez (üstteki kapı
          // önce davranıyor ve zaten `ours` diyor).
          bucket: LiveHonestyBucket.yours,
          // Hüküm susarken bile ANLATI konuşabilir (ayrı yuva): deneme
          // kapandı ve önceki işaret gitti — bunu söylememek için bir sebep
          // yok, hükmün verilememesi ayrı bir olgu.
          narration: readyLine ?? correctedLine,
          skeleton: skeleton,
        ),
      );
      return;
    }

    // TEK düzeltme (kabuk ilkesi): telefonu uzağa koymuş kullanıcı bir liste
    // uygulayamaz. İlk sıradaki alınıyor — motor zaten önceliğe göre üretiyor.
    final DetectedIssue? issue = out.issues.isEmpty ? null : out.issues.first;

    // GÖRÜNÜRLÜK kodu bir DÜZELTME DEĞİL: kullanıcı yanlış bir şey yapmıyor,
    // biz göremiyoruz. Düzeltme yuvasına koymak, olmayan bir hatayı
    // düzelttirmek olurdu.
    if (issue != null && jabLabVisibilityIssueCodes.contains(issue.code)) {
      _states.add(
        LiveJabState.live(
          surface: LiveState.noVerdict,
          completedCount: _completed,
          noVerdictReason: _phrase(issue.code) ?? _genericNoVerdict,
          // GÖRÜNÜRLÜK kodu: "seni göremiyorum" — eylem sende.
          bucket: LiveHonestyBucket.yours,
          narration: readyLine ?? correctedLine,
          phase: out.activePhase,
          skeleton: skeleton,
        ),
      );
      return;
    }

    if (!technicalJudgementsAdmitted) {
      _states.add(
        LiveJabState.live(
          surface: LiveState.noVerdict,
          completedCount: _completed,
          noVerdictReason: _calibrationUnavailableReason,
          bucket: LiveHonestyBucket.ours,
          narration: readyLine,
          phase: out.activePhase,
          skeleton: skeleton,
        ),
      );
      return;
    }

    _states.add(
      LiveJabState.live(
        surface: issue == null ? LiveState.clean : LiveState.correcting,
        completedCount: _completed,
        // HAM KOD ASLA: `REAR_HAND_LOW` bir teşhis dizesidir. İçerik eksikse
        // kod gösterilmez, genel ama DÜRÜST bir cümle gösterilir.
        cue: issue == null ? null : (_phrase(issue.code) ?? _genericIssue),
        narration: readyLine ?? correctedLine,
        phase: out.activePhase,
        skeleton: skeleton,
      ),
    );
  }

  // Lost or unreliable observations cannot finish a previously started
  // attempt. Recreate both the smoother and phase state on the next usable
  // frame; keep only completed session counts. No correction comparison may
  // cross an unobserved interval either.
  void _discardPartialObservation() {
    _engine = null;
    _lastAttemptIssueCode = null;
  }

  void _onStreamError(Object error) {
    if (!_running || _disposed) return;
    // Akış ortasında gelen hata seansı ÖLDÜRÜR ve söyler. Sessizce son
    // durumu ekranda bırakmak, kullanıcıya donmuş bir sayıyı canlıymış gibi
    // göstermek olurdu (J-092'nin bayat-özet dersinin canlı karşılığı).
    _running = false;
    _states.add(
      LiveJabState.failed(
        error is CameraException
            ? LiveCameraUnavailable(
                failure: error.failure,
                nativeDetail: error.detail,
              )
            : LiveSetupFailed(error),
      ),
    );
    // A Dart envelope decode error does not prove native capture stopped.
    unawaited(stop());
  }

  /// Kod → cümle. Eşlenmemiş ya da içerikte olmayan kod için `null`.
  String? _phrase(String code) {
    final String? key = jabLabIssueCueMapping[code];
    return key == null ? null : cues.sayKey(key);
  }

  /// `EngineOutput.suppressionReason` → kullanıcı cümlesi (J-099 düzeltmesi).
  ///
  /// Eskiden bu ham teşhis dizesi (`'quality:lowTrackingConfidence'` gibi)
  /// DOĞRUDAN yüzeye yazılıyordu — doc-75/5'in ("ham teşhis dizesi kullanıcıya
  /// SIZMAZ") üçüncü, hiç test edilmemiş ihlal noktası (bkz.
  /// `docs/design/REPLIK-ERISILEBILIRLIK-TARAMASI-2026-08-06.md`). `_phrase`
  /// issue-kodu için ne yapıyorsa, bu da bastırma-öneki için yapıyor.
  String _suppressionSentence(String? reason) {
    if (reason == null) return _genericNoVerdict;
    if (reason.startsWith('structural:')) {
      // ⚠️ ÖLÇÜLDÜ (test/live_jab_path_test.dart): bu dal canlı hatta bugün
      // ERİŞİLEMEZ — `OrientationAwarePoseSource._run` (motion_core) HER
      // karede kendi `StructuralValidator`ını çalıştırıp
      // `OrientationCandidate.usable => structural.plausible` diyor; motor
      // aynı kareyi görmeden önce zaten `resolution.usable=false`e düşüyor.
      // ✅ J-103: o üstteki kapı ARTIK aynı `cue.structural` anahtarına
      // yönlendiriyor, yani KULLANICININ DUYDUĞU cümle bu dal erişilebilir
      // olsa da olmasa da AYNI — iki kapı, tek replik. Bu dal yine de
      // KORUNUYOR: savunma amaçlı (kapı sırası bir gün değişirse ham dize
      // sızmasın) ve `_phrase`in issue-kodu için yaptığı örüntüyü bozmamak
      // için. Erişilebilirliği yukarıdaki daldan ÖLÇÜLÜYOR.
      return cues.sayKey('cue.structural') ?? _genericNoVerdict;
    }
    if (reason == 'quality:outOfFrame') {
      return cues.sayKey('cue.out_of_frame') ?? _genericNoVerdict;
    }
    if (reason == 'quality:lowTrackingConfidence') {
      return cues.sayKey('cue.low_confidence') ?? _genericNoVerdict;
    }
    if (reason == 'quality:torsoUnreliable') {
      // AYRI TUTULUR (koordinatör hükmü): kadraj-dışı DEĞİL — gövdesi
      // kadrajda ama motor referans alamıyor, farklı bir düzeltme ister.
      // `cues.en.json`de bu senaryoya özel bir anahtar yok; satır ~161'deki
      // `resolution.usable==false` hardcoded cümlesiyle AYNI emsal (içerik
      // eksikse yeni cue icat edilmez, dürüst sabit cümle yazılır).
      return _torsoUnreliableReason;
    }
    // integrity:extensionRatio=... vb.: içerikte özel replik yok, ham dize
    // yine sızmaz — dürüst genele düşer.
    return _genericNoVerdict;
  }

  /// İçerik boşluğunda gösterilen cümle. Kodun kendisi DEĞİL — ve sessizlik
  /// de değil: sessizlik canlı koçta "her şey yolunda" diye okunur.
  static const String _calibrationUnavailableReason =
      'Technique feedback is unavailable while this setup is awaiting calibration. '
      'The count records detected attempts; it is not a judgement of technique.';

  static const String _genericIssue =
      'Something in that one needs fixing, but we do not have the words for '
      'it.';
  static const String _genericNoVerdict =
      'I cannot judge that clearly enough right now.';

  /// KİMSE YOK hâli — `cues.en.json`da karşılığı YOK ve bilerek: bu cümle
  /// bir koçluk repliği değil, kurulum yönergesi. `cue.out_of_frame`
  /// ("kısmen görüyorum") ile karıştırılmaması için ayrı tutuluyor —
  /// `_torsoUnreliableReason` ile aynı emsal.
  static const String _nobodyFoundReason =
      'I cannot see you well enough to judge — step back so your head and '
      'hands are in frame.';
  static const String _torsoUnreliableReason =
      "I can't get a steady read on your torso — square up so your "
      'shoulders and hips are both visible.';

  StrikingEngine _buildEngine(FrameSize size) =>
      _engineFactory?.call(size) ??
      StrikingEngine(
        ruleSet: ruleSet,
        allowedTechniqueIds: allowedTechniqueIds,
        frameSize: size,
        // KALİBRASYON YOK ve bu bilerek: taraf etiketi (M-F-06) raporlanamaz
        // ve K8 sayısal skoru kapalı tutar. `true` yazmak kalibre edilmemiş
        // bir kurulumda "sol/sağ" demeye izin verirdi.
        calibrationMapped: false,
        provenance: <String, String>{'modelId': modelId},
      );

  /// Shared camera admission reset, restricted to isolated tests.
  @visibleForTesting
  static void debugResetCameraLock() =>
      // This facade is itself restricted to isolated tests.
      // ignore: invalid_use_of_visible_for_testing_member
      CameraCaptureCoordinator.debugResetForTests();

  /// Invalidates this attempt and publishes its owned closure before returning.
  /// Callers may leave cleanup unawaited; errors are observed and stay sticky.
  Future<void> stop() {
    _generation++;
    _running = false;
    _nativeSubmitted = false;
    final capture = _capture;
    _capture = null;
    final StreamSubscription<CameraFrameEnvelope>? subscription = _sub;
    _sub = null;
    if (capture == null) return _retirement ?? Future<void>.value();
    // The lease retires and the shared gate is installed before app cancellation.
    final closing = CameraCaptureCoordinator.close(capture);
    final retirement = _stopInner(subscription, closing);
    _retirement = retirement;
    unawaited(
      retirement.then<void>(
        (_) {},
        onError: (Object error, StackTrace stack) {
          final failure = CameraCaptureCoordinator.recordUncertainty(error);
          if (!_disposed && !_states.isClosed) {
            _states.add(
              LiveJabState.failed(
                LiveCameraUnavailable(
                  failure: failure.failure,
                  nativeDetail: failure.detail,
                ),
              ),
            );
          }
        },
      ),
    );
    return retirement;
  }

  Future<void> _stopInner(
    StreamSubscription<CameraFrameEnvelope>? subscription,
    Future<void> closing,
  ) async {
    await Future.wait<void>([
      closing,
      if (subscription != null) subscription.cancel(),
    ]);
  }

  Future<void> dispose() {
    _disposed = true;
    final disposal = _disposal ??= _disposeInner();
    unawaited(
      disposal.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
    return disposal;
  }

  Future<void> _disposeInner() async {
    try {
      await stop();
    } finally {
      await _states.close();
    }
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
    List<PoseLandmark>? skeleton,
    LiveHonestyBucket bucket,
  }) = LiveJabRunning;

  const factory LiveJabState.failed(LiveSessionFailure failure) = LiveJabFailed;
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
    this.skeleton,
    this.bucket = LiveHonestyBucket.none,
  });

  /// SORUMLULUK KOVASI (J-110) — "eylem kimde". Kontrolcü hangi dala
  /// girdiğini zaten biliyor; yüzey yalnız CÜMLEYİ görüyordu ve bu yüzden
  /// 11 hâli aynı renkte çiziyordu. Kova burada TÜRETİLİYOR, yüzeyde
  /// cümleden tahmin EDİLMİYOR — tahmin, ayrımın sessizce yanlış olacağı
  /// tek yol olurdu.
  final LiveHonestyBucket bucket;

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

  /// Çözülmüş karenin HAM 33 nokta iskeleti — hükümden BAĞIMSIZ (yukarıdaki
  /// `_onEnvelope` dokümanı). `null` yalnız `resolution.usable==false`
  /// iken (kimse bulunamadı): o zaman çizilecek hiçbir koordinat yok.
  ///
  /// Bilerek ÇEVRİLMEDİ — bu sınıfın "çeviri" işi kullanıcıya SÖZ söylemek
  /// (cümleler), iskeleti hangi kemiklerle nasıl çizeceği bir RENDER kararı
  /// ve o karar UI katmanına ait (`skeleton_overlay.dart`).
  final List<PoseLandmark>? skeleton;
}

final class LiveJabFailed extends LiveJabState {
  const LiveJabFailed(this.failure);

  final LiveSessionFailure failure;
}

/// D18: `counts`taki en sık anahtarı döner — `LiveJabController` durumundan
/// bağımsız SAF fonksiyon (kamera/motor kurmadan doğrudan test edilir).
///
/// `counts` boşsa `null` — hiç tamamlanmış deneme yoktu, "controlled"
/// UYDURULMAZ. Eşitlikte İLK EKLENEN anahtar kazanır (Dart `Map` ekleme
/// sırasını korur) — kararsız/rastgele bir seçim yerine deterministik.
@visibleForTesting
String? modeOfCounts(Map<String, int> counts) {
  if (counts.isEmpty) return null;
  String best = counts.keys.first;
  int bestCount = counts[best]!;
  for (final MapEntry<String, int> e in counts.entries) {
    if (e.value > bestCount) {
      best = e.key;
      bestCount = e.value;
    }
  }
  return best;
}
