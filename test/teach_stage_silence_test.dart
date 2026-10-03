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

import 'support/owned_native_fixture.dart';

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

  Future<({_SpyCamera camera, Future<void> Function() close})> pumpSession(
    WidgetTester t,
  ) async {
    final _SpyCamera cam = _SpyCamera();
    final LiveJabController live = LiveJabController(
      ruleSet: ruleSet,
      cues: cues,
      // Model diske hiç çıkarılmıyor: `start()` içinde geç çözülüyor ve
      // bu testin ölçtüğü şey zaten "oraya HİÇ gelinmiyor mu".
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
          lesson: const ShellLesson(id: 'x', title: 'Test lesson', minutes: 3),
          cues: cues,
          coachedNotScored: const <String>[],
          bands: const <String, String>{'Stance': '—'},
          plan: null,
          rehearseMaterial: const RehearseMaterialNone(
            reason: 'fixture: no drill named',
          ),
          teachMaterial: const TeachMaterialText(body: 'Body of the lesson.'),
          liveJab: live,
        ),
      ),
    );
    await t.pumpAndSettle();
    return (camera: cam, close: () => _closeOwnedSession(t, cam, live));
  }

  testWidgets('öğretme aşamasında kamera AÇILMIYOR — cümle doğru kalıyor', (
    WidgetTester t,
  ) async {
    final fixture = await pumpSession(t);
    final _SpyCamera cam = fixture.camera;

    // VAKUM KAPISI: cümle gerçekten ekranda mı? Değilse bu test, hiç
    // söylenmemiş bir iddiayı koruyor olurdu (aile dersi #4).
    expect(
      find.byKey(const Key('teach-no-analysis')),
      findsOneWidget,
      reason: 'korunacak cümle ekranda değil — kapı boşluğu bekliyor',
    );

    expect(
      cam.startCalls,
      0,
      reason:
          'ÖĞRETME aşamasında kamera açıldı. Ekran tam bu anda '
          '"Nothing is being analysed during this part" diyor; kamerayı '
          'burada ısıtmak o cümleyi SESSİZCE yalana çevirir',
    );
    await fixture.close();
  });

  testWidgets('POZİTİF İKİZ — canlı aşamada kamera GERÇEKTEN açılıyor', (
    WidgetTester t,
  ) async {
    // Bu ikiz olmadan yukarıdaki kapı vakum-doğru olurdu: denetleyici hiç
    // bağlanmasa da `startCalls` 0 kalırdı ve kapı yeşil öterdi. Sıfırın
    // "bağlı ama susuyor" mu yoksa "hiç bağlı değil" mi olduğunu ancak
    // bu ikiz ayırıyor.
    final fixture = await pumpSession(t);
    final _SpyCamera cam = fixture.camera;
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

    expect(
      cam.startCalls,
      1,
      reason:
          'canlı aşamaya gelindi ama kamera hiç açılmadı — o zaman '
          'öğretme aşamasındaki sıfır bir KANIT değil, sadece hiç '
          'bağlanmamış bir denetleyicinin gölgesi olurdu',
    );
    await fixture.close();
  });
}

/// Mock native protocol plus the actual controller/lease; no real device.
class _SpyCamera extends OwnedTestCamera {
  _SpyCamera() : super(libraryTag: 'teach-stage-fixture');
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
