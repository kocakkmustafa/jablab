import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/app/rehearse_material.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/teach_material.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import 'support/owned_native_fixture.dart';

/// ⭐ POZİTİF ZİNCİR — analiz koştuğunda sayı ÖZETE ULAŞIYOR (J-157).
///
/// J-156'nın **isimli borcu**: negatif yön (kamerasız derste sayı YOK)
/// gerçek uygulamayla ölçülmüştü, **pozitif yön** ölçülmemişti. Ve o
/// eksiklik tehlikeliydi: `null` döndüren bir tesisat da negatif testi
/// geçerdi — kapı *"sayı yok"*u korur, *"sayı geliyor"*u korumazdı.
///
/// Bu test zinciri **uçtan uca** koşuyor: sahte kamera → sentetik jab
/// dizisi → `StrikingEngine` → `LiveJabRunning.completedCount` →
/// `onCounted` → `_SessionScreenState` → `SessionSummaryView`.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Sayının **doğru** olduğunu — sentetik dizinin kaç jab içerdiğini
///   `live_jab_path_test` ölçüyor; burada ölçülen **taşınma**.
/// * Gerçek MediaPipe topolojisini (cihaz günü §7.3-7.7).
void main() {
  setUp(LiveJabController.debugResetCameraLock);

  TestWidgetsFlutterBinding.ensureInitialized();

  late RuleSet ruleSet;
  late CueBook cues;

  setUpAll(() async {
    final ({dynamic library, dynamic boxing}) c =
        await const ContentRepository().load();
    ruleSet = c.boxing as RuleSet;
    cues = await const ContentRepository().loadCues();
  });

  testWidgets('⭐ KİLOMETRE TAŞI EKRANDA GÖRÜNÜYOR (J-158 — isimli borç)', (
    WidgetTester t,
  ) async {
    // ## Kapatılan borç
    //
    // J-104 `cue.milestone`un tetiğini bağladı; `session_narrator_test`
    // repliğin ÜRETİLDİĞİNİ ölçüyor. Ama **ekranda göründüğü** hiç
    // kanıtlanmadı: ilk denemede widget koşumu, kilometre taşı olayı
    // ateşlendiği anda takılıyordu ve test SİLİNİP borç **isimli**
    // bırakıldı.
    //
    // J-157'nin canlı koşumu (sahte kamera + sentetik jab + `runAsync`)
    // artık çalışıyor. Borç, **koşum tekniği değiştiği için** kapanıyor —
    // ürün değişmedi.
    //
    // `milestoneEvery` bir TEST DİKİŞİ: varsayılan 25, burada 2. Eşiği
    // ürün için değiştirmiyoruz; yalnız sentetik tekrar sayısını makul
    // tutuyoruz.
    final _SeqCamera cam = _SeqCamera();
    final LiveJabController live = LiveJabController(
      ruleSet: ruleSet,
      cues: cues,
      modelPath: () async => '/dev/null/model.task',
      modelId: 'test-model',
      camera: cam,
      requestPermission: () async => true,
      permissionPermanentlyDenied: () async => false,
    );
    addTearDown(() => _closeOwnedSession(t, cam, live));
    await t.pumpWidget(
      MaterialApp(
        home: SessionScreen(
          lesson: const ShellLesson(id: 'x', title: 'Jab', minutes: 3),
          cues: cues,
          coachedNotScored: const <String>[],
          bands: const <String, String>{'Stance': '—'},
          plan: null,
          milestoneEvery: 2,
          rehearseMaterial: const RehearseMaterialNone(
            reason: 'fixture: no drill named',
          ),
          teachMaterial: const TeachMaterialText(body: 'Body.'),
          liveJab: live,
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.runAsync(() async {
      for (int i = 0; i < 2; i++) {
        await t.tap(find.text('Continue'));
        await t.pump();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
    });
    await t.pump(const Duration(milliseconds: 200));

    await t.runAsync(() async {
      for (int rep = 0; rep < 3; rep++) {
        for (final PoseFrame f in _jabSequence(repOffsetUs: rep * 800000)) {
          cam.emit(_envelope(f));
        }
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    });
    await t.pump(const Duration(milliseconds: 150));

    // Kilometre taşı replikleri (J-141 varyantlarıyla): `{n}` DOLDURULMUŞ
    // olmalı — yer tutucu görünüyorsa J-104'ün ikinci kusuru geri gelmiş
    // demektir ve sayının GERÇEK sayaçtan geldiği de böylece ölçülüyor.
    final List<String> onScreen = t
        .widgetList<Text>(find.byType(Text))
        .map((Text w) => w.data ?? '')
        .toList();
    final bool milestone = onScreen.any(
      (String s) =>
          RegExp(r'^\d+ (in|down)\.$').hasMatch(s) ||
          RegExp(r'^\d+ so far\.$').hasMatch(s) ||
          RegExp(r"^That's \d+\.$").hasMatch(s),
    );
    expect(
      milestone,
      isTrue,
      reason:
          'kilometre taşı repliği EKRANDA YOK. Zincirin son halkası '
          '(narrator → canlı yüzey) kopuk olabilir. Ekrandakiler: '
          '${onScreen.where((String s) => s.isNotEmpty).take(8).toList()}',
    );
    expect(
      onScreen.any((String s) => s.contains('{n}')),
      isFalse,
      reason: 'yer tutucu doldurulmamış — sayı gerçek sayaçtan gelmiyor',
    );
    await _closeOwnedSession(t, cam, live);
  });

  testWidgets('sentetik jab SAYILIYOR ve özette GÖRÜNÜYOR', (
    WidgetTester t,
  ) async {
    final _SeqCamera cam = _SeqCamera();
    final LiveJabController live = LiveJabController(
      ruleSet: ruleSet,
      cues: cues,
      modelPath: () async => '/dev/null/model.task',
      modelId: 'test-model',
      camera: cam,
      requestPermission: () async => true,
      permissionPermanentlyDenied: () async => false,
    );
    addTearDown(() => _closeOwnedSession(t, cam, live));
    await t.pumpWidget(
      MaterialApp(
        home: SessionScreen(
          lesson: const ShellLesson(id: 'x', title: 'Jab', minutes: 3),
          cues: cues,
          coachedNotScored: const <String>[],
          bands: const <String, String>{'Stance': '—'},
          plan: null,
          rehearseMaterial: const RehearseMaterialNone(
            reason: 'fixture: no drill named',
          ),
          teachMaterial: const TeachMaterialText(body: 'Body.'),
          liveJab: live,
        ),
      ),
    );
    await t.pumpAndSettle();

    // öğret → prova → canlı
    await t.runAsync(() async {
      for (int i = 0; i < 2; i++) {
        await t.tap(find.text('Continue'));
        await t.pump();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
    });
    await t.pump(const Duration(milliseconds: 200));

    // Sentetik jab'ları besle — üç tekrar.
    await t.runAsync(() async {
      for (int rep = 0; rep < 3; rep++) {
        for (final PoseFrame f in _jabSequence(repOffsetUs: rep * 800000)) {
          cam.emit(_envelope(f));
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await t.pump(const Duration(milliseconds: 120));

    // canlı → özet
    await t.runAsync(() async {
      await t.tap(find.text('Continue'));
      await t.pump();
      await Future<void>.delayed(const Duration(milliseconds: 60));
    });
    await t.pumpAndSettle();

    // VAKUM KAPISI: gerçekten özet aşamasında mıyız?
    expect(
      find.byKey(const Key('summary-band-Stance')),
      findsOneWidget,
      reason: 'özet aşamasına gelinmedi — kapı boşluğa bakıyor',
    );

    final Finder count = find.byKey(const Key('summary-count'));
    expect(
      count,
      findsOneWidget,
      reason:
          'ANALİZ KOŞTU ama özette sayı YOK — zincir kopuk. '
          'J-156 sabit 0 gösteriyordu; bu testin varlık sebebi, '
          'düzeltmenin ters yönde (hep null) kopmadığını kanıtlamak',
    );
    final String shown = (t.widget<Text>(count)).data ?? '';
    expect(
      int.tryParse(shown),
      isNotNull,
      reason: 'özetteki sayı bir sayı değil: "$shown"',
    );
    expect(
      int.parse(shown),
      greaterThan(0),
      reason:
          'sentetik jab beslendi ama özet 0 diyor — sayım yolda '
          'kayboluyor',
    );
    await _closeOwnedSession(t, cam, live);
  });
}

/// Mock native protocol plus the actual controller/lease; synthetic frames only.
class _SeqCamera extends OwnedTestCamera {
  _SeqCamera() : super(libraryTag: 'summary-sequence-fixture');
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

/// `live_jab_path_test`in sentetik jab dizisi — ara kareler DAHİL.
///
/// Ara kareler ŞART: motor 30 fps'lik bir akış okuyor, anahtar kareleri
/// değil. Yalnız anahtar kare gönderilirse jab hiç sayılmaz ve kusur
/// zincirde değil, sahte kameranın gerçekçi olmamasındadır.
List<PoseFrame> _jabSequence({int repOffsetUs = 0}) {
  const SyntheticPoseBuilder b = SyntheticPoseBuilder();
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
  final SyntheticSequence seq = SyntheticSequence(<SyntheticKeyframe>[
    const SyntheticKeyframe(0, guard),
    const SyntheticKeyframe(200000, guard),
    const SyntheticKeyframe(320000, extended),
    const SyntheticKeyframe(520000, guard),
    const SyntheticKeyframe(750000, guard),
  ]);
  const int stepUs = 33333;
  final List<PoseFrame> out = <PoseFrame>[];
  for (int t = seq.startUs; t <= seq.endUs; t += stepUs) {
    out.add(b.build(seq.poseAt(t), tUs: repOffsetUs + t));
  }
  return out;
}

/// Unmount while this test owns its FakeAsync zone. Advance both widget work
/// and mock-channel Futures, then remove handlers only after owned close settles.
Future<void> _closeOwnedSession(
  WidgetTester tester,
  OwnedTestCamera camera,
  LiveJabController live,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  bool settled = false;
  Object? failure;
  StackTrace? failureStack;
  live
      .dispose()
      .then<void>(
        (_) => settled = true,
        onError: (Object error, StackTrace stack) {
          failure = error;
          failureStack = stack;
          settled = true;
        },
      )
      .ignore();
  for (int i = 0; i < 80 && !settled; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  expect(
    settled,
    isTrue,
    reason: 'owned close must settle before native fixture teardown',
  );
  if (failure != null) {
    Error.throwWithStackTrace(failure!, failureStack!);
  }
  if (camera.startCalls > 0) {
    expect(camera.native.nativeCloseAcknowledged.isCompleted, isTrue);
    expect(camera.native.state.phase, 'closed');
    expect(camera.activeListeners, 0);
    expect(camera.cancelCalls, 1);
    expect(camera.native.globalStopCalls, 0);
  }
  await camera.close();
}
