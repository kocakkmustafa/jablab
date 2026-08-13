import 'dart:async';

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

/// ÖĞRETME AŞAMASINDA KAMERA SUSUYOR — sevk edilmiş bir cümlenin kapısı
/// (J-133).
///
/// ## Neden
///
/// Ürün **iki ayrı yüzeyde** aynı şeyi söylüyor:
///
/// * `session_screen`: *"Nothing is being analysed during this part."*
/// * `content_repository`: *"…nothing is scored while you learn the shape."*
///
/// Ölçüldü ve **bugün doğru**: `start()` yalnız `_Live`in `initState`inde
/// çağrılıyor, `_Teach` denetleyiciyi hiç tutmuyor, ve denetleyicinin
/// KURULMASI kamerayı açmıyor (model yolu `start()` içinde geç çözülüyor).
///
/// **Ama hiçbir şey bunu sabitlemiyordu.** Mevcut `startCalls` denetimleri
/// izin hâlleriyle ilgili, AŞAMAYLA değil. Çok makul bir iyileştirme —
/// canlı aşamaya geçişteki gecikmeyi azaltmak için kamerayı öğretme
/// sırasında ısıtmak — sevk edilmiş iki cümleyi **sessizce yalana**
/// çevirirdi. Kimse yalan söylemeye karar vermezdi; performans düzeltmesi
/// yapardı.
///
/// Aile dersi #7'nin bu geceki hâli: kusuru düzeltmek değil, **kusurun
/// imkânsız olduğu yapıyı** seçmek. Buradaki yapı bir kapı, çünkü kodun
/// kendisi bunu zorlayamıyor.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * **"Analiz" ile "kamera"yı** aynı sayıyor. Kamera kapalıyken analiz
///   olamaz, o yönü kesin; ters yönde bir gün kamerasız bir analiz kaynağı
///   (kayıttan oynatma) gelirse bu kapı onu görmez.
/// * **Prova (`rehearse`) aşamasını** — orada ne söylendiği ayrı bir soru.
/// * Cümlenin **kelimelerini**: metin yeniden yazılırsa kapı yine geçer.
///   Kapının işi DAVRANIŞI sabitlemek; metnin kendisi `surface_text_shape`
///   ve vaat dili kapılarının kapsamında.
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

  Future<_SpyCamera> pumpSession(WidgetTester t) async {
    final _SpyCamera cam = _SpyCamera();
    await t.pumpWidget(MaterialApp(
      home: SessionScreen(
        lesson: const ShellLesson(id: 'x', title: 'Test lesson', minutes: 3),
        cues: cues,
        coachedNotScored: const <String>[],
        bands: const <String, String>{'Stance': '—'},
        plan: null,
        rehearseMaterial: const RehearseMaterialNone(reason: 'fixture: no drill named'),
        teachMaterial: const TeachMaterialText(body: 'Body of the lesson.'),
        liveJab: LiveJabController(
          ruleSet: ruleSet,
          cues: cues,
          // Model diske hiç çıkarılmıyor: `start()` içinde geç çözülüyor ve
          // bu testin ölçtüğü şey zaten "oraya HİÇ gelinmiyor mu".
          modelPath: () async => '/dev/null/model.task',
          modelId: 'test-model',
          camera: cam,
          requestPermission: () async => true,
          permissionPermanentlyDenied: () async => false,
        ),
      ),
    ));
    await t.pumpAndSettle();
    return cam;
  }

  testWidgets('öğretme aşamasında kamera AÇILMIYOR — cümle doğru kalıyor',
      (WidgetTester t) async {
    final _SpyCamera cam = await pumpSession(t);

    // VAKUM KAPISI: cümle gerçekten ekranda mı? Değilse bu test, hiç
    // söylenmemiş bir iddiayı koruyor olurdu (aile dersi #4).
    expect(find.byKey(const Key('teach-no-analysis')), findsOneWidget,
        reason: 'korunacak cümle ekranda değil — kapı boşluğu bekliyor');

    expect(cam.startCalls, 0,
        reason: 'ÖĞRETME aşamasında kamera açıldı. Ekran tam bu anda '
            '"Nothing is being analysed during this part" diyor; kamerayı '
            'burada ısıtmak o cümleyi SESSİZCE yalana çevirir');
  });

  testWidgets('POZİTİF İKİZ — canlı aşamada kamera GERÇEKTEN açılıyor',
      (WidgetTester t) async {
    // Bu ikiz olmadan yukarıdaki kapı vakum-doğru olurdu: denetleyici hiç
    // bağlanmasa da `startCalls` 0 kalırdı ve kapı yeşil öterdi. Sıfırın
    // "bağlı ama susuyor" mu yoksa "hiç bağlı değil" mi olduğunu ancak
    // bu ikiz ayırıyor.
    final _SpyCamera cam = await pumpSession(t);
    expect(cam.startCalls, 0);

    // öğret → prova → canlı
    await t.runAsync(() async {
      for (int i = 0; i < 2; i++) {
        await t.tap(find.text('Continue'));
        await t.pump();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
    });
    await t.pump(const Duration(milliseconds: 200));

    expect(cam.startCalls, 1,
        reason: 'canlı aşamaya gelindi ama kamera hiç açılmadı — o zaman '
            'öğretme aşamasındaki sıfır bir KANIT değil, sadece hiç '
            'bağlanmamış bir denetleyicinin gölgesi olurdu');
  });
}

/// Sahte kamera — yalnız `start()` sayısını sayıyor. Gerçek denetleyici
/// platform kanalı açar, test açamaz.
class _SpyCamera implements MotionCameraController {
  final StreamController<CameraFrameEnvelope> _c =
      StreamController<CameraFrameEnvelope>.broadcast();
  int startCalls = 0;

  @override
  Future<CameraSessionInfo> start({
    required String modelPath,
    required String modelId,
    CameraLens lens = CameraLens.front,
    PassPlan initialPlan = PassPlan.uprightOnly,
  }) async {
    startCalls++;
    return const CameraSessionInfo(
      width: 480,
      height: 640,
      clockDomain: ClockDomain.monotonic,
      libraryTag: 'spy',
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
