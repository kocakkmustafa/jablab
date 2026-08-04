import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/live_session_failure.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/shell_candidate/live_surface.dart' show LiveState;
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

/// CANLI JAB HATTI — uçtan uca, SAHTE kamerayla (J-096).
///
/// ## ⚠️ NE KANITLIYOR, NE KANITLAMIYOR
///
/// **Kanıtlıyor:** zarf → yönelim çözümü → faz makinesi → dürüst yüzey
/// zinciri BAĞLI ve doğru hâlleri üretiyor; izin reddi/kamera hatası tipli
/// dönüyor; ham kod yüzeye sızmıyor.
///
/// **KANITLAMIYOR:** gerçek bir insanın gerçek jab'ının tanınacağını.
/// Buradaki iskeletler SENTETİK (`SyntheticPoseBuilder`) ve gerçek MediaPipe
/// çıktısı değil — cihaz kanıtı §7.3-7.7'de, kurucu-manuel. Bu ayrımı silmek
/// en kolay sahte-ilerleme yolu olurdu (emülatör smoke'unun kendi dersi).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RuleSet ruleSet;
  late CueBook cues;

  setUpAll(() async {
    final ({dynamic library, dynamic boxing}) c =
        await const ContentRepository().load();
    ruleSet = c.boxing as RuleSet;
    cues = await const ContentRepository().loadCues();
  });

  LiveJabController build(_FakeCamera cam,
          {Future<bool> Function()? permission,
          Future<bool> Function()? permanent}) =>
      LiveJabController(
        ruleSet: ruleSet,
        cues: cues,
        modelPath: '/dev/null/model.task',
        modelId: 'test-model',
        camera: cam,
        requestPermission: permission,
        permissionPermanentlyDenied: permanent,
      );

  group('kurulum hâlleri TİPLİ', () {
    test('izin REDDİ — kamera hiç açılmıyor', () async {
      final _FakeCamera cam = _FakeCamera();
      final LiveSessionFailure? f = await build(cam,
              permission: () async => false, permanent: () async => false)
          .start();
      expect(f, isA<LivePermissionDenied>());
      expect((f! as LivePermissionDenied).permanentlyDenied, isFalse);
      expect(cam.startCalls, 0,
          reason: 'izin yokken kamerayı açmaya çalışmak, kullanıcıya '
              '"kamera açılamadı" dedirtirdi — oysa sorun izin');
    });

    test('KALICI ret ayrı işaretleniyor', () async {
      // Sunulan EYLEM değişiyor: geçici rette tekrar sormak çalışır,
      // kalıcıda çalışmaz ve "tekrar dene" düğmesi hiçbir yere götürmez.
      final LiveSessionFailure? f = await build(_FakeCamera(),
              permission: () async => false, permanent: () async => true)
          .start();
      expect((f! as LivePermissionDenied).permanentlyDenied, isTrue);
    });

    test('kamera reddi TİPLİ döner, fırlatmaz', () async {
      final _FakeCamera cam = _FakeCamera(
          startError: const CameraException(
              CameraFailure.noSuchCamera, 'no front lens'));
      final LiveSessionFailure? f =
          await build(cam, permission: () async => true).start();
      expect(f, isA<LiveCameraUnavailable>());
      expect((f! as LiveCameraUnavailable).failure, CameraFailure.noSuchCamera);
    });

    test('TANINMAYAN hata isimli plugin reddi gibi SUNULMUYOR', () async {
      final _FakeCamera cam = _FakeCamera(startError: StateError('disk full'));
      final LiveSessionFailure? f =
          await build(cam, permission: () async => true).start();
      expect(f, isA<LiveSetupFailed>(),
          reason: 'bilinmeyen hatayı isimli bir kamera reddi gibi sunmak, '
              'kullanıcıya bizim adımıza teşhis koymaktır');
    });

    test('POZİTİF İKİZ: izin VARKEN ve kamera açılırken hata YOK', () async {
      final _FakeCamera cam = _FakeCamera();
      expect(await build(cam, permission: () async => true).start(), isNull);
      expect(cam.startCalls, 1);
    });
  });

  group('canlı hat', () {
    test('SENTETİK jab SAYILIYOR ve faz bildiriliyor', () async {
      final _FakeCamera cam = _FakeCamera();
      final LiveJabController c = build(cam, permission: () async => true);
      final List<LiveJabState> seen = <LiveJabState>[];
      final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);

      expect(await c.start(), isNull);
      for (final PoseFrame f in _jabSequence()) {
        cam.emit(_envelope(f));
      }
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final List<LiveJabRunning> runs = seen.whereType<LiveJabRunning>().toList();
      expect(runs, isNotEmpty);
      expect(runs.last.completedCount, greaterThan(0),
          reason: 'sentetik jab hiç sayılmadı — zincir kopuk');
      expect(runs.any((LiveJabRunning r) => r.phase != null), isTrue,
          reason: 'faz geri bildirimi hiç gelmedi');
      await c.dispose();
    });

    test('KİMSE YOK → noVerdict, ama seans KOŞMAYA DEVAM ediyor', () async {
      // Hüküm verilememesi bir HATA değil: canlı hâl, kendi kendine düzelir.
      final _FakeCamera cam = _FakeCamera();
      final LiveJabController c = build(cam, permission: () async => true);
      final List<LiveJabState> seen = <LiveJabState>[];
      final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);

      await c.start();
      cam.emit(_envelope(null));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final LiveJabRunning r = seen.whereType<LiveJabRunning>().last;
      expect(r.surface, LiveState.noVerdict);
      expect(r.noVerdictReason, isNotNull,
          reason: 'sessiz kalmak "her şey yolunda" diye okunur');
      expect(seen.whereType<LiveJabFailed>(), isEmpty,
          reason: 'görünmemek bir kurulum hatası DEĞİL');
      await c.dispose();
    });

    test('BAŞLANGIÇ hâli ayrı — sıfır sayı GÖSTERİLMİYOR', () async {
      // İlk zarf gelmeden `completedCount` 0'dır ve sıfırı göstermek
      // "hiç yumruk atmadın" demektir; oysa henüz hiçbir şey ölçülmedi.
      final _FakeCamera cam = _FakeCamera();
      final LiveJabController c = build(cam, permission: () async => true);
      final List<LiveJabState> seen = <LiveJabState>[];
      final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
      await c.start();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen.first, isA<LiveJabStarting>());
      await c.dispose();
    });

    test('AKIŞ HATASI seansı öldürüyor ve SÖYLÜYOR', () async {
      // Sessizce son durumu bırakmak, donmuş bir sayıyı canlıymış gibi
      // göstermek olurdu (J-092 bayat-özet dersinin canlı karşılığı).
      final _FakeCamera cam = _FakeCamera();
      final LiveJabController c = build(cam, permission: () async => true);
      final List<LiveJabState> seen = <LiveJabState>[];
      final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
      await c.start();
      cam.emitError(const CameraException(CameraFailure.notRunning, 'lost'));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen.last, isA<LiveJabFailed>());
      await c.dispose();
    });

    test('HAM KOD yüzeye SIZMIYOR — hiçbir hâlde', () async {
      final _FakeCamera cam = _FakeCamera();
      final LiveJabController c = build(cam, permission: () async => true);
      final List<LiveJabState> seen = <LiveJabState>[];
      final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
      await c.start();
      for (final PoseFrame f in _jabSequence()) {
        cam.emit(_envelope(f));
      }
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final RegExp codeLike = RegExp(r'\b[A-Z][A-Z_]{4,}\b');
      for (final LiveJabRunning r in seen.whereType<LiveJabRunning>()) {
        for (final String? s in <String?>[r.cue, r.noVerdictReason]) {
          if (s == null) continue;
          expect(codeLike.hasMatch(s), isFalse,
              reason: 'teşhis dizesi kullanıcıya gösterildi: "$s"');
        }
      }
      await c.dispose();
    });
  });
}

/// Motorun jab olarak tanıdığı sentetik dizi (engine_test'in aynısı).
List<PoseFrame> _jabSequence() {
  const SyntheticPoseBuilder b = SyntheticPoseBuilder();
  // engine_test'in gard/uzanma pozları — açı tabanlı (kol eklem açıları),
  // bilek koordinatı DEĞİL: motorun okuduğu şey açılar.
  const SyntheticPose guard = SyntheticPose(
    leftUpperArm: 1.35,
    leftForearm: -1.45,
    rightUpperArm: 1.75,
    rightForearm: -1.65,
  );
  const SyntheticPose extended = SyntheticPose(
    leftUpperArm: 0.0,
    leftForearm: 0.0,
    rightUpperArm: 0.0,
    rightForearm: 0.0,
  );
  // ⚠️ ARA KARELER ŞART: motor 30 fps'lik bir AKIŞ okuyor, anahtar kareleri
  // değil. İlk yazışımda yalnız 5 anahtar kare gönderdim ve jab hiç
  // sayılmadı — kusur zincirde değil, sahte kameranın gerçekçi olmamasındaydı.
  // `SyntheticSequence` anahtar kareler arasını dolduruyor (engine_test'in
  // `sequence()` yardımcısıyla aynı yol).
  final SyntheticSequence seq = SyntheticSequence(<SyntheticKeyframe>[
    const SyntheticKeyframe(0, guard),
    const SyntheticKeyframe(200000, guard),
    const SyntheticKeyframe(320000, extended),
    const SyntheticKeyframe(520000, guard),
    const SyntheticKeyframe(750000, guard),
  ]);
  const int stepUs = 33333; // ~30 fps
  final List<PoseFrame> out = <PoseFrame>[];
  for (int t = seq.startUs; t <= seq.endUs; t += stepUs) {
    out.add(b.build(seq.poseAt(t), tUs: t));
  }
  return out;
}

CameraFrameEnvelope _envelope(PoseFrame? frame) => CameraFrameEnvelope(
      tUs: frame?.tUs ?? 0,
      size: const FrameSize(480, 640),
      modelVersion: 'test',
      clockDomain: ClockDomain.monotonic,
      inferenceUs: 1000,
      dropped: 0,
      passes: <BodyOrientation, PoseFrame?>{BodyOrientation.upright: frame},
    );

/// Sahte kamera — gerçek `MotionCameraController` kanal açar, test açamaz.
class _FakeCamera implements MotionCameraController {
  _FakeCamera({this.startError});

  final Object? startError;
  final StreamController<CameraFrameEnvelope> _c =
      StreamController<CameraFrameEnvelope>.broadcast();
  int startCalls = 0;

  void emit(CameraFrameEnvelope e) => _c.add(e);
  void emitError(Object e) => _c.addError(e);

  @override
  Future<CameraSessionInfo> start({
    required String modelPath,
    required String modelId,
    CameraLens lens = CameraLens.front,
    PassPlan initialPlan = PassPlan.uprightOnly,
  }) async {
    startCalls++;
    if (startError != null) throw startError!;
    return const CameraSessionInfo(
      width: 480,
      height: 640,
      clockDomain: ClockDomain.monotonic,
      libraryTag: 'fake',
    );
  }

  @override
  Stream<CameraFrameEnvelope> frames() => _c.stream;

  @override
  Future<void> stop() async {}

  @override
  Future<void> setPassPlan(PassPlan plan) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
