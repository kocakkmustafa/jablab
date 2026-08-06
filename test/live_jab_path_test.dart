import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/live_session_failure.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:flutter/material.dart';
import 'package:jablab/shell_candidate/live_surface.dart'
    show LiveCoachSurface, LiveState;
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
        modelPath: () async => '/dev/null/model.task',
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

  group('sayı yuvası', _countSlotTests);

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

    test('İSKELET hükümden BAĞIMSIZ — çözülen karede HER ZAMAN var', () async {
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

      final List<LiveJabRunning> runs = seen.whereType<LiveJabRunning>().toList();
      expect(runs, isNotEmpty);
      for (final LiveJabRunning r in runs) {
        expect(r.skeleton, isNotNull,
            reason: 'çözülmüş bir kare varken iskelet YOK olamaz — '
                '`skeleton_overlay.dart` çizecek bir şey bulamaz');
        // Lm.count == 33 (MediaPipe Pose Landmarker topolojisi) — motorun
        // içindeki bir sabiti burada TEKRAR yazmak yerine ham uzunluk
        // doğrudan kontrol ediliyor, bu paketin kendi kontratı zaten
        // `landmark_index.dart`ta sabit.
        expect(r.skeleton!.length, 33);
      }
      await c.dispose();
    });

    test('KİMSE YOK iken İSKELET de YOK — çizecek koordinat icat edilmez',
        () async {
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
      expect(r.skeleton, isNull);
      await c.dispose();
    });

    group('BASTIRMA yolu — suppressionReason ÇEVRİLİYOR (J-099)', () {
      // Bu grup `_jabSequence()`in hiç dokunmadığı dalı hedefler: motorun
      // `!judgeable` dediği kare. Taramanın bulduğu bulgu tam burada —
      // `noVerdictReason: out.suppressionReason` ham teşhis dizesini
      // DOĞRUDAN yüzeye yazıyordu. `_jabSequence()`in "HAM KOD" testi bu
      // dalı hiç ÇALIŞTIRMADIĞI için kusuru YAKALAYAMAZDI — burada gerçek
      // motor, gerçek eşiklerle, bu dalı BİLEREK tetikliyoruz.

      test('gövde landmarkı DÜŞÜK GÜVEN → torsoUnreliable, AYRI cümle',
          () async {
        final _FakeCamera cam = _FakeCamera();
        final LiveJabController c = build(cam, permission: () async => true);
        final List<LiveJabState> seen = <LiveJabState>[];
        final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
        await c.start();
        // ConfidenceGate.torsoThreshold=0.6 — gövde bunun ALTINA düşünce
        // her şeyden ÖNCE (kol/bacak güveninden bile önce) kontrol ediliyor.
        for (final PoseFrame f in SyntheticNoise.occlude(
            _steadyFrames(), <int>[Lm.leftShoulder], visibility: 0.3)) {
          cam.emit(_envelope(f));
        }
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        final LiveJabRunning r = seen.whereType<LiveJabRunning>().last;
        expect(r.surface, LiveState.noVerdict);
        expect(r.noVerdictReason, isNot(contains('torsoUnreliable')),
            reason: 'ham motor kodu sızdı');
        expect(r.noVerdictReason, isNot(contains(':')),
            reason: 'ham teşhis dizesi biçimi ("kategori:detay") sızdı');
        expect(r.noVerdictReason,
            "I can't get a steady read on your torso — square up so your "
            'shoulders and hips are both visible.');
        await c.dispose();
      });

      test('bilek DÜŞÜK GÜVEN (gövde temiz) → cue.low_confidence GERÇEK metni',
          () async {
        final _FakeCamera cam = _FakeCamera();
        final LiveJabController c = build(cam, permission: () async => true);
        final List<LiveJabState> seen = <LiveJabState>[];
        final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
        await c.start();
        // Gövde (torso) tam güvende kalıyor — yalnız bilek düşük, böylece
        // ConfidenceGate `lowTrackingConfidence`e düşüyor, `torsoUnreliable`e
        // değil (sıra: gövde → kadraj-dışı → düşük-güven, evaluate() içinde).
        for (final PoseFrame f in SyntheticNoise.occlude(
            _steadyFrames(), <int>[Lm.leftWrist], visibility: 0.2)) {
          cam.emit(_envelope(f));
        }
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        final LiveJabRunning r = seen.whereType<LiveJabRunning>().last;
        expect(r.surface, LiveState.noVerdict);
        expect(_lowConfidencePhrases.contains(r.noVerdictReason), isTrue,
            reason: '`cue.low_confidence`in bilinen 4 varyantından biri '
                'değil — ham teşhis dizesi sızmış olabilir: '
                '"${r.noVerdictReason}"');
        await c.dispose();
      });

      // ⚠️ `structural:` öneki (`cue.structural`) BURADA canlı-hat üzerinden
      // GERÇEK bir sentetik yapısal-kusurla tetiklenip test EDİLEMEDİ — dört
      // ayrı fixture denendi (aşırı bacak kısaltma, yalnız kol uzatma, büyük
      // kemik sıçraması, eşik-sınırı kemik sıçraması) ve HEPSİ, motora hiç
      // ulaşmadan, `resolution.usable=false`e (BAŞKA bir hardcoded cümleye)
      // düştü. Kaynağı OKUYUNCA sebep netleşti — kusur DEĞİL, mimari:
      // `OrientationAwarePoseSource._run` (motion_core) HER karede KENDİ
      // `StructuralValidator`ını çalıştırıyor ve `OrientationCandidate.usable
      // => structural.plausible` diyor (orientation_aware_source.dart:42) —
      // yani motorun `StrikingEngine.process()`teki `structural:` bastırması
      // (striking_engine.dart:295-297) ile TAMAMEN AYNI koşulu, TAMAMEN AYNI
      // `StructuralValidator` sınıfıyla, motor daha kareyi GÖRMEDEN önce
      // kontrol ediyor. Zaman-bağımsız kusurlar için (limbProportionImplausible,
      // bilateralAsymmetry) bu iki kontrol MATEMATİKSEL OLARAK AYNI kareyi,
      // aynı formülle değerlendiriyor — yani `structural:` bastırması canlı
      // hatta YAPISAL OLARAK ERİŞİLEMEZ, motion_core'un kendi kapısı her zaman
      // önce davranıyor ve FARKLI bir mesajla kapatıyor. Bu üçüncü bir "ölü
      // dal" bulgusu — `docs/design/REPLIK-ERISILEBILIRLIK-TARAMASI-2026-08-06.md`nin
      // "cue.structural ölü" satırına bir SEVİYE daha derin bir açıklama
      // ekliyor (içerik-eksikliği değil, erişilemezlik). `_suppressionSentence`
      // içindeki `structural:` dalı yine de KORUNUYOR — savunma amaçlı
      // (motion_core'un kapı sırası bir gün değişirse ham dize sızmasın) ve
      // doğruluğu diğer iki dalla AYNI kod-örüntüsüyle inşa edildiği için
      // teftişle (inspection) doğrulanıyor, canlı-hat testiyle değil.
    });
  });
}

/// `assets/content/cues.en.json`'daki `cue.low_confidence` varyantları —
/// içerik değişirse bu test de değişsin diye ELLE senkron tutuluyor
/// (dosyayı runtime'da okumak yerine sabit liste: yanlış dosyadan okumak
/// gibi bir hataya kapalı).
const List<String> _lowConfidencePhrases = <String>[
  "I can't see you clearly enough to judge.",
  'Losing track of you.',
  "Tracking isn't clean — holding off.",
  'Not confident enough to call that.',
];

/// Hareketsiz, nötr bir duruş — yalnız güven/yapı kapılarını tetiklemek
/// için var, `_jabSequence()`in aksine bir TEKNİK saymayı hedeflemiyor.
List<PoseFrame> _steadyFrames({
  SyntheticBody body = SyntheticBody.average,
  double visibility = 1.0,
  int count = 8,
}) {
  const int stepUs = 33333; // ~30 fps
  return <PoseFrame>[
    for (int i = 0; i < count; i++)
      SyntheticPoseBuilder(body: body).build(SyntheticPose.neutral,
          tUs: i * stepUs, visibility: visibility),
  ];
}

/// SAYI YUVASI — "henüz sayılmıyor" ile "sıfır" AYRI (J-096).
///
/// Simülatörde bulundu: analiz hiç başlamamışken ekranda kocaman bir **0**
/// duruyordu, yani "sıfır yumruk attın". J-092'nin canlı ekrandaki birebir
/// tekrarı — ve hiçbir widget testi görmüyordu çünkü hepsi metnin VARLIĞINI
/// sınıyordu, ANLAMINI değil.
void _countSlotTests() {
  testWidgets('analiz başlamamışken SAYI GÖSTERİLMİYOR',
      (WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LiveCoachSurface(
          state: LiveState.noVerdict,
          eventCount: null,
          noVerdictReason: 'camera off',
        ),
      ),
    ));
    expect(find.byKey(const Key('event-count')), findsNothing);
  });

  testWidgets('POZİTİF İKİZ: koşan seansta SAYI gösteriliyor (0 dahil)',
      (WidgetTester t) async {
    // Koşan bir seansta 0 DOĞRUDUR: ölçüyoruz ve henüz yumruk yok.
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LiveCoachSurface(state: LiveState.clean, eventCount: 0),
      ),
    ));
    expect(find.byKey(const Key('event-count')), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
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
