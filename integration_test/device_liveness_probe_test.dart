import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jablab/app/pose_model.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/thermal_channel.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart' show BodyOrientation;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

import 'liveness_metrics.dart';

/// F5 — CİHAZ GÜNÜ KAMERA-CANLILIK ÖLÇÜM PROBU (H-82 görevi, 2026-08-17).
///
/// Kamera→poz→geri-bildirim zinciri bugüne kadar HİÇBİR cihazda ölçülmedi —
/// `camera_smoke_test.dart` yalnız EMÜLATÖR TESİSATINI kanıtlıyor (kendi
/// dosya başlığı adıyla söylüyor: "gerçek-insan ölçümü DEĞİL"). Kurucunun
/// cihaz günü yarım günü bir İZLENİM değil ÖLÇÜM üretmeli — bu prob onu
/// tek komutla üretir ve bir ARTEFAKT DOSYASI bırakır (konsol çıktısı
/// kapanınca kaybolur, dosya kalır).
///
/// Koşum (cihaz USB ya da güvenilir Wi-Fi ile bağlıyken):
///   flutter test integration_test/device_liveness_probe_test.dart -d CIHAZ_ID
///
/// Pencere `--dart-define=LIVENESS_WINDOW_SECONDS=N` ile geçersiz kılınabilir
/// (dev-check için kısa, örn. 30) — varsayılan JAB-P0-002 Step 3'ün istediği
/// 20 dakika (1200 sn), roadmap'in Run: komutu ekstra bayrak taşımıyor.
///
/// Artefakt: uygulamanın Documents dizinine
/// `device_liveness_probe_<epoch-ms>.json` — tam yol test çıktısına basılır.
///
/// Ölçtükleri (H-82'nin orijinal dörtlüsü + JAB-P0-002'nin eklediği ikisi):
///   * fps (anlık + p10/p50/p95) — anlık değerler `ThroughputMonitor`
///     (motion_camera'da zaten var, yeniden icat edilmedi). Yüzdelikler
///     YENİ: 1 sn'de bir örneklenip `reliablePercentile`e (`jablab_engine`,
///     J-283) verilir — o fonksiyonun küçük-örneklem koruması burada da
///     geçerli, kısa bir koşumdan p95 basmak yanıltıcı olurdu.
///   * ilk-poz gecikmesi     — kamera seansı başladıktan `pass()`ın İLK
///     non-null döndüğü zarfa kadar geçen süre. Hiçbir yerde tutulmuyordu
///     (`camera_harness_screen.dart` yalnız "kaç kez" sayıyor —
///     `_emptyPasses` — "ne kadar sürdü" değil).
///   * landmark geçerlilik oranı — judged zarfların kaçında `pass()` bir
///     insan döndürdü. `ThroughputMonitor.judgedRatio`dan FARKLI: o
///     kanal-teslimatını (kaç zarf düşmedi) ölçer, bu MODELİN kimseyi
///     görüp görmediğini ölçer — ikisi karışırsa "akış var ama kimse
///     görülmüyor" durumu "akış yok" ile aynı sayı gibi okunur.
///   * termal (YENİ, JAB-P0-002) — `ThermalChannel` (`lib/app/
///     thermal_channel.dart`, app-özel platform kanalı, motion_core'dan
///     BAĞIMSIZ), 5 sn'de bir örneklenir, tüm okumaların EN KÖTÜSÜ +
///     zaman-serisinin tamamı artefakta yazılır.
///   * blur bucket — YAZILAMADI, adıyla: `CameraFrameEnvelope` (motion_
///     camera, pinli) ham piksel/parlaklık taşımıyor, yalnız poz-iskelet
///     sonucu — bkz. `docs/evidence/production-line/device-matrix.json`
///     `codeReadiness.metricsBlocked`. App katmanında çözülemeyen bir
///     eksik, icat edilmedi/taklit edilmedi.
///   * düşme modları        — betik kendi kendine ayırt eder (izin/model/
///     kanal/kişi-yok), "çalışmıyor" un görünümünü İSİMLİ kaydeder (H-68:
///     bir yokluk raporu ortam adıyla yazılır — burada "ortam" düşme
///     modunun kendisidir).
///
/// ⛔ FİZİKSEL CİHAZ ZORUNLU (JAB-P0-002 Step 2, YENİ): `device_info_plus`
/// ile `isPhysicalDevice` ölçülür, simülatör/emülatörde test KIRMIZI olur
/// — "simülatör kanıt değildir" roadmap kuralının kod karşılığı. Artefakt
/// bu durumda da yazılır (H-68).
///
/// ⛔ `H-69` aynen geçerli: bu prob YALNIZ ölçer, atlatma/tolerans
/// gevşetme YOK. Kendi deponda kalır (kapsam: `com.yulalab.jablab`).
/// Ölçüm penceresi — varsayılan JAB-P0-002 Step 3'ün istediği 20 dakika,
/// `--dart-define=LIVENESS_WINDOW_SECONDS=N` ile dev-check için kısaltılır.
const int _windowSeconds = int.fromEnvironment(
  'LIVENESS_WINDOW_SECONDS',
  defaultValue: 20 * 60,
);

/// FPS örnekleme aralığı — p10/p50/p95'in anlamlı olması için pencere
/// başına en az birkaç yüz örnek hedefler (20 dk'da ~1200).
const Duration _fpsSampleInterval = Duration(seconds: 1);

/// Termal daha yavaş değişen bir sinyal — her saniye sormak gereksiz OS
/// çağrısı biriktirir, 5 sn yeterli çözünürlük verir.
const Duration _thermalSampleInterval = Duration(seconds: 5);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'cihaz günü canlılık probu — artefakt yazar',
    (WidgetTester tester) async {
      final Map<String, dynamic> artifact = <String, dynamic>{
        'schemaVersion': 3, // Explicit cleanup failure and evidence boundaries.
        'probe': 'device_liveness_probe',
        'app': 'com.yulalab.jablab',
        'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'platform': Platform.operatingSystem,
        'platformVersion': Platform.operatingSystemVersion,
        'windowSeconds': _windowSeconds,
        'sourceTree': const String.fromEnvironment('JABLAB_SOURCE_TREE'),
        'sustainedPerformanceAccepted': false,
        'interruptionResumptionTested': false,
        'physicalTechniqueAccepted': false,
      };
      String? failureMode;
      String? failureDetail;

      Future<void> writeArtifact() async {
        artifact['failureMode'] = failureMode; // null == temiz koşum
        artifact['failureDetail'] = failureDetail;
        final Directory dir = await getApplicationDocumentsDirectory();
        final String path =
            '${dir.path}/device_liveness_probe_'
            '${DateTime.now().millisecondsSinceEpoch}.json';
        const JsonEncoder enc = JsonEncoder.withIndent('  ');
        final String body = enc.convert(artifact);
        await File(path).writeAsString(body, flush: true);
        // ignore: avoid_print
        print('=== CİHAZ GÜNÜ CANLILIK PROBU ===');
        // ignore: avoid_print
        print(body);
        // ignore: avoid_print
        print('ARTEFAKT: $path');
      }

      // Bind each future device artifact to the actual reviewed source.
      if (!RegExp(r'^[0-9a-f]{40}$')
          .hasMatch(artifact['sourceTree'] as String)) {
        failureMode = 'unbound_source_identity';
        failureDetail = 'Pass the exact reviewed tree via JABLAB_SOURCE_TREE';
        await writeArtifact();
        fail(failureDetail);
      }

      // 0) FİZİKSEL CİHAZ ZORUNLU (JAB-P0-002 Step 2) — "simülatör kanıt
      //    değildir" roadmap kuralının kod karşılığı. İzinden bile ÖNCE:
      //    simülatörde kamera izni genelde otomatik reddedilir, o zaman bu
      //    kapı hiç ötmeden `permission_denied`e düşer ve gerçek sebep
      //    (yanlış hedef) gizlenir.
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      bool isPhysicalDevice;
      if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        isPhysicalDevice = info.isPhysicalDevice;
        artifact['deviceModel'] = info.utsname.machine;
      } else if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        isPhysicalDevice = info.isPhysicalDevice;
        artifact['deviceModel'] = info.model;
      } else {
        failureMode = 'unsupported_platform';
        failureDetail =
            'canlılık probu yalnız iOS/Android hedefler, '
            'platform: ${Platform.operatingSystem}';
        await writeArtifact();
        fail(failureDetail);
      }
      artifact['isPhysicalDevice'] = isPhysicalDevice;
      if (!isPhysicalDevice) {
        failureMode = 'not_physical_device';
        failureDetail =
            'simülatör/emülatörde koşuldu — bu ölçüm SAYILMAZ '
            '(roadmap §2: "simülatör kanıt değildir"); gerçek cihaz gerekir';
        await writeArtifact();
        fail(failureDetail);
      }

      // 1) İZİN — reddi KENDİ BAŞINA bir düşme modudur; ölçüm burada durur
      //    ama artefakt yine de yazılır (yokluk sessizce atlanmaz, H-68).
      final PermissionStatus perm = await Permission.camera.request();
      if (!perm.isGranted) {
        failureMode = 'permission_denied';
        failureDetail = '$perm';
        await writeArtifact();
        fail(
          'kamera izni verilmedi ($perm) — artefakt yine de yazıldı, '
          'düşme modu adıyla kaydedildi',
        );
      }

      // 2) MODEL — verified cache, shared with app and debug harness.
      late final String modelPath;
      try {
        modelPath = await const ContentRepository().materializePoseModel();
      } on Object catch (e) {
        failureMode = 'model_materialize_failed';
        failureDetail = '$e';
        await writeArtifact();
        fail('model diske çıkarılamadı: $e');
      }

      // 3) KAMERA BAŞLAT — burdan sonraki süre "ilk-poz gecikmesi"nin sıfır
      //    noktası (izin diyaloğunda kurucunun ne kadar oyalandığı bu
      //    ölçümün parçası DEĞİL — o kullanıcı davranışı, köprü performansı
      //    değil).
      final MotionCameraController camera = MotionCameraController();
      final ThroughputMonitor monitor = ThroughputMonitor();
      late final CameraSessionInfo session;
      try {
        session = await camera.start(
          modelPath: modelPath,
          modelId: PoseModelPin.modelId,
          lens: CameraLens.front,
          initialPlan: PassPlan.uprightOnly,
        );
      } on Object catch (e) {
        failureMode = 'camera_start_failed';
        failureDetail = '$e';
        await writeArtifact();
        fail('kamera başlatılamadı: $e');
      }
      final Stopwatch sessionClock = Stopwatch()..start();
      artifact['clockDomain'] = session.clockDomain.name;
      artifact['libraryTag'] = session.libraryTag;
      artifact['modelId'] = PoseModelPin.modelId;

      // 4) ÖLÇÜM PENCERESİ — varsayılan 20 dk (JAB-P0-002 Step 3), dev-check
      //    için `--dart-define`la kısaltılabilir (bkz. dosya başlığı).
      //    `camera_smoke_test.dart`ın 32 sn'lik sabit tesisat-smoke'u AYRI
      //    bir kapı — o "akıyor mu" sorar, bu "ne kadar İYİ akıyor, 20 dk
      //    boyunca" sorar.
      final Duration window = Duration(seconds: _windowSeconds);
      int envelopeCount = 0;
      int judgedWithPerson = 0;
      int judgedEmpty = 0;
      Duration? firstPoseLatency;
      Object? streamError;

      // JAB-P0-002 — FPS p10/p50/p95 için periyodik örnekleyici. Kaynak
      // `monitor.judgedPerSecond` ZATEN var olan bir kayan-pencere anlık
      // değer (bkz. rate_meter.dart) — bu örnekleyici onu ZAMANA YAYARAK
      // bir SERİYE çevirir, yüzdelik BURADAN türer.
      final PeriodicSampler<double> fpsSampler = PeriodicSampler<double>(
        interval: _fpsSampleInterval,
        read: () async => monitor.judgedPerSecond,
      );
      // Termal daha yavaş değişir; ayrı kanal (motion_core'dan bağımsız).
      final PeriodicSampler<ThermalReading> thermalSampler =
          PeriodicSampler<ThermalReading>(
            interval: _thermalSampleInterval,
            read: const ThermalChannel().read,
          );

      final StreamSubscription<CameraFrameEnvelope> sub = camera
          .frames()
          .listen((CameraFrameEnvelope e) {
            monitor.record(e);
            envelopeCount += 1;
            if (e.pass(BodyOrientation.upright) != null) {
              judgedWithPerson += 1;
              firstPoseLatency ??= sessionClock.elapsed;
            } else {
              judgedEmpty += 1;
            }
          }, onError: (Object err) => streamError = err);
      fpsSampler.start();
      thermalSampler.start();
      await Future<void>.delayed(window);
      fpsSampler.stop();
      thermalSampler.stop();
      final cleanup = await cleanupProbeCapture(
        cancelFrames: sub.cancel,
        stopCamera: camera.stop,
      );
      artifact['cleanup'] = cleanup.toJson();

      // 5) DÜŞME MODU SINIFLANDIRMASI — "çalışmıyor" un görünümü İSİMLİ.
      if (!cleanup.succeeded) {
        failureMode = 'camera_cleanup_failed';
        failureDetail =
            'cancel: ${cleanup.cancelError}; stop: ${cleanup.stopError}';
      } else if (streamError != null) {
        failureMode = 'stream_error';
        failureDetail = '$streamError';
      } else if (envelopeCount == 0) {
        failureMode = 'no_envelope_flow';
        failureDetail =
            '$_windowSeconds sn içinde tek bir zarf gelmedi — '
            'kanal/çıkarım tesisatı canlı değil (emülatörde kanıtlanmıştı, '
            'cihazda değil)';
      } else if (judgedWithPerson == 0) {
        failureMode = 'no_person_detected';
        failureDetail =
            '$envelopeCount zarf geldi ama hiçbirinde insan '
            'ölçülmedi — kamera yanlış yöne bakıyor/karanlık/çerçeve dışı '
            'olabilir; kanal canlı, MODEL kimseyi görmüyor';
      }
      // Null is only a liveness outcome, never J-011 or interruption acceptance.
      artifact['livenessResult'] = failureMode == null ? 'PASS' : 'FAIL';
      artifact['streamError'] = streamError?.toString();
      artifact['sustainedPerformanceReview'] = _windowSeconds < 20 * 60
          ? 'UNRUN_SHORT_WINDOW'
          : 'PENDING_EXACT_DEVICE_FPS_THERMAL_REVIEW';

      artifact['fps'] = <String, dynamic>{
        'judgedPerSecond': monitor.judgedPerSecond,
        'capturedPerSecond': monitor.capturedPerSecond,
        'judgedRatio': monitor.judgedRatio,
        'meanInferenceUs': monitor.meanInferenceUs,
        'sessionDroppedCount': monitor.sessionDroppedCount,
        // YENİ (JAB-P0-002 Step 1) — zaman içine yayılmış örneklemden
        // türetilen yüzdelikler; `reliablePercentile`in kendi küçük-örneklem
        // koruması `Unmeasured` olarak taşınır, sessizce basılmaz.
        'judgedPerSecondSampleCount': fpsSampler.samples.length,
        'judgedPerSecondP10': percentileToJson(fpsSampler.percentile(0.10)),
        'judgedPerSecondP50': percentileToJson(fpsSampler.percentile(0.50)),
        'judgedPerSecondP95': percentileToJson(fpsSampler.percentile(0.95)),
      };
      artifact['firstPoseLatencyMs'] = firstPoseLatency?.inMilliseconds;
      artifact['envelopeCount'] = envelopeCount;
      artifact['landmarkValidity'] = <String, dynamic>{
        'judgedWithPerson': judgedWithPerson,
        'judgedEmpty': judgedEmpty,
        // Ölçülemeyen "—" (null) olarak taşınır, 0 olarak DEĞİL (kapı
        // sözleşmesi genel — camera_harness_screen._fmt'in aynı kuralı).
        'ratio': envelopeCount == 0 ? null : judgedWithPerson / envelopeCount,
      };
      // YENİ (JAB-P0-002) — termal zaman-serisi + en kötü kademe. Kanal
      // desteklenmiyorsa (`read()` hep null dönerse) `samples` boş kalır ve
      // bu SESSİZCE "nominal" sayılmaz — `worstTierMeasured:false` adıyla.
      final ThermalTier? worst = worstTier(thermalSampler.samples);
      artifact['thermal'] = <String, dynamic>{
        'sampleCount': thermalSampler.samples.length,
        'worstTier': worst?.name,
        // API<29 Android'de `measured:false` olabilir (bkz. thermal_channel.
        // dart) — worstTier yine de güvenlik tarafına (critical) yuvarlanmış
        // olabilir, bu alan o farkı taşır.
        'worstTierAllMeasured': thermalSampler.samples.isEmpty
            ? null
            : thermalSampler.samples.every((ThermalReading r) => r.measured),
        'series': thermalSampler.samples
            .map(
              (ThermalReading r) => <String, dynamic>{
                'tier': r.tier.name,
                'platform': r.platform,
                'raw': r.raw,
                'measured': r.measured,
              },
            )
            .toList(),
      };

      await writeArtifact();

      // KAPI: bir düşme modu bulunduysa test KIRILIR — sayı raporlamak
      // yerine adıyla söylenir (H-31: yarım kanıt tam kapalı yazılmaz).
      // Artefakt her durumda yazıldı; bu satır yalnız CI/terminal sinyalini
      // belirler.
      expect(
        failureMode,
        isNull,
        reason:
            'canlılık probu bir düşme modu buldu: '
            '$failureMode — $failureDetail (artefakt yine de yazıldı, '
            'yol yukarıda)',
      );
      // Pencere + izin/model/kamera kurulumu + 3 dk tampon (varsayılan 20 dk
      // pencerede eski sabit 2 dk yetmezdi — JAB-P0-002).
    },
    timeout: Timeout(
      Duration(seconds: _windowSeconds) + const Duration(minutes: 3),
    ),
  );
}
