import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show ByteData;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jablab/app/pose_model.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart' show BodyOrientation;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
/// Artefakt: uygulamanın Documents dizinine
/// `device_liveness_probe_<epoch-ms>.json` — tam yol test çıktısına basılır.
///
/// Ölçtükleri (H-82'nin istediği dörtlü + düşme modları):
///   * fps                  — `ThroughputMonitor` (motion_camera'da zaten
///     var; burada yeniden icat edilmedi, aynı ölçüm sınıfı kullanıldı).
///   * ilk-poz gecikmesi     — kamera seansı başladıktan `pass()`ın İLK
///     non-null döndüğü zarfa kadar geçen süre. Bu YENİ bir ölçüm: hiçbir
///     yerde tutulmuyordu (`camera_harness_screen.dart` yalnız "kaç kez"
///     sayıyor — `_emptyPasses` — "ne kadar sürdü" değil).
///   * landmark geçerlilik oranı — judged zarfların kaçında `pass()` bir
///     insan döndürdü. `ThroughputMonitor.judgedRatio`dan FARKLI: o
///     kanal-teslimatını (kaç zarf düşmedi) ölçer, bu MODELİN kimseyi
///     görüp görmediğini ölçer — ikisi karışırsa "akış var ama kimse
///     görülmüyor" durumu "akış yok" ile aynı sayı gibi okunur.
///   * düşme modları        — betik kendi kendine ayırt eder (izin/model/
///     kanal/kişi-yok), "çalışmıyor" un görünümünü İSİMLİ kaydeder (H-68:
///     bir yokluk raporu ortam adıyla yazılır — burada "ortam" düşme
///     modunun kendisidir).
///
/// ⛔ `H-69` aynen geçerli: bu prob YALNIZ ölçer, atlatma/tolerans
/// gevşetme YOK. Kendi deponda kalır (kapsam: `com.yulalab.jablab`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cihaz günü canlılık probu — artefakt yazar',
      (WidgetTester tester) async {
    final Map<String, dynamic> artifact = <String, dynamic>{
      'schemaVersion': 1,
      'probe': 'device_liveness_probe',
      'app': 'com.yulalab.jablab',
      'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
    };
    String? failureMode;
    String? failureDetail;

    Future<void> writeArtifact() async {
      artifact['failureMode'] = failureMode; // null == temiz koşum
      artifact['failureDetail'] = failureDetail;
      final Directory dir = await getApplicationDocumentsDirectory();
      final String path = '${dir.path}/device_liveness_probe_'
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

    // 1) İZİN — reddi KENDİ BAŞINA bir düşme modudur; ölçüm burada durur
    //    ama artefakt yine de yazılır (yokluk sessizce atlanmaz, H-68).
    final PermissionStatus perm = await Permission.camera.request();
    if (!perm.isGranted) {
      failureMode = 'permission_denied';
      failureDetail = '$perm';
      await writeArtifact();
      fail('kamera izni verilmedi ($perm) — artefakt yine de yazıldı, '
          'düşme modu adıyla kaydedildi');
    }

    // 2) MODEL — asset'ten diske çıkar (camera_harness_screen ile AYNI
    //    mekanizma; kopyalandı, icat edilmedi — H-71).
    late final String modelPath;
    try {
      final Directory dir = await getApplicationSupportDirectory();
      final File out =
          File('${dir.path}/${PoseModelPin.assetPath.split('/').last}');
      if (!out.existsSync()) {
        final ByteData data = await rootBundle.load(PoseModelPin.assetPath);
        await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      modelPath = out.path;
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

    // 4) ÖLÇÜM PENCERESİ — 30 sn, `camera_smoke_test.dart` ile AYNI taban
    //    (sözleşme §7.3).
    const Duration window = Duration(seconds: 30);
    int envelopeCount = 0;
    int judgedWithPerson = 0;
    int judgedEmpty = 0;
    Duration? firstPoseLatency;
    Object? streamError;

    final StreamSubscription<CameraFrameEnvelope> sub =
        camera.frames().listen(
      (CameraFrameEnvelope e) {
        monitor.record(e);
        envelopeCount += 1;
        if (e.pass(BodyOrientation.upright) != null) {
          judgedWithPerson += 1;
          firstPoseLatency ??= sessionClock.elapsed;
        } else {
          judgedEmpty += 1;
        }
      },
      onError: (Object err) => streamError = err,
    );
    await Future<void>.delayed(window);
    await sub.cancel();
    try {
      await camera.stop();
    } on Object catch (_) {
      // stop hatası ölçümü geçersiz kılmaz (camera_harness_screen dersi).
    }

    // 5) DÜŞME MODU SINIFLANDIRMASI — "çalışmıyor" un görünümü İSİMLİ.
    if (streamError != null) {
      failureMode = 'stream_error';
      failureDetail = '$streamError';
    } else if (envelopeCount == 0) {
      failureMode = 'no_envelope_flow';
      failureDetail = '30 sn içinde tek bir zarf gelmedi — kanal/çıkarım '
          'tesisatı canlı değil (emülatörde kanıtlanmıştı, cihazda değil)';
    } else if (judgedWithPerson == 0) {
      failureMode = 'no_person_detected';
      failureDetail = '$envelopeCount zarf geldi ama hiçbirinde insan '
          'ölçülmedi — kamera yanlış yöne bakıyor/karanlık/çerçeve dışı '
          'olabilir; kanal canlı, MODEL kimseyi görmüyor';
    }
    // failureMode == null ⇒ zincir uçtan uca ölçüldü, kişi görüldü.

    artifact['fps'] = <String, dynamic>{
      'judgedPerSecond': monitor.judgedPerSecond,
      'capturedPerSecond': monitor.capturedPerSecond,
      'judgedRatio': monitor.judgedRatio,
      'meanInferenceUs': monitor.meanInferenceUs,
      'sessionDroppedCount': monitor.sessionDroppedCount,
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

    await writeArtifact();

    // KAPI: bir düşme modu bulunduysa test KIRILIR — sayı raporlamak
    // yerine adıyla söylenir (H-31: yarım kanıt tam kapalı yazılmaz).
    // Artefakt her durumda yazıldı; bu satır yalnız CI/terminal sinyalini
    // belirler.
    expect(failureMode, isNull,
        reason: 'canlılık probu bir düşme modu buldu: '
            '$failureMode — $failureDetail (artefakt yine de yazıldı, '
            'yol yukarıda)');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
