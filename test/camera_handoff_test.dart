import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/live_jab_controller.dart';
import 'package:jablab/app/live_session_failure.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_camera/motion_camera.dart';

import 'support/owned_native_fixture.dart';

/// DERSTEN DERSE KAMERA DEVRİ — kapanış bitmeden açılış (J-195 / aile C-195).
///
/// ## Kusur, ve neden N=1'de GÖRÜNMEZ
///
/// `State.dispose` **senkron**; bu yüzden `session_screen` çıkarken
/// `unawaited(widget.liveJab?.stop())` diyor. Ama `stop` bir **platform
/// kanalı gidiş-dönüşü** — bitmesi zaman alır. Kullanıcı dersten çıkıp
/// **hemen** bir ders daha açarsa, yeni controller'ın `start()`i sistem
/// kamerayı **hâlâ kapatırken** koşar ve eklenti **`already-running`** der.
///
/// > **İkinci ders, BİRİNCİ dersin sebep olduğu bir arızayla karşılanır.**
///
/// Ve bu kusur **N=1'de yapısal olarak görünmez**: henüz durdurulmuş bir
/// şey yoktur. Bir seans süiti onu **kaçırır**, çünkü her testi *"ekran
/// çalışıyor mu"* diye sorar ve cevap **ilk seferinde evettir.**
///
/// ## Neden kilit STATIC
///
/// Her ders **kendi** `LiveJabController`ını (ve kendi
/// `MotionCameraController`ını) kuruyor — ama **cihazda tek kamera var.**
/// Örnek düzeyinde bir kilit iki AYRI nesneyi hiç görmez. **Kaynak
/// static olduğu için kilit de static.**
///
/// ## Neden `stop()` `async` DEĞİL
///
/// `async` bir gövde `_closing` atamasını **gövdenin içine** koyar; çağıran
/// `unawaited(stop())` dediği an atama **bir mikrotask geç** yayınlanır — ve
/// tam o mikrotask içinde açılan ders kilidi **göremez.** Kilidin **senkron**
/// yayınlanması bu tasarımın bütün amacı.
///
/// ## Maliyet
///
/// **N=1'de sıfır:** `_closing` null ise hiçbir bekleme eklenmez. Nadir bir
/// kusur, **her açılıştaki gecikmeyle takas edilmiyor.**
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Gerçek platformun `already-running` davranışını — burada **taklit**
///   ediliyor. Sahte, gerçek eklentinin sözleşmesine göre yazıldı; cihazda
///   doğrulanması **cihaz turuna** ait.
/// * İzin akışını, kamera donanım hatalarını.
void main() {
  setUp(LiveJabController.debugResetCameraLock);

  RuleSet rules() {
    // Motor kuralları burada sınanmıyor; controller'ın YAŞAM DÖNGÜSÜ sınanıyor.
    return RuleSet.fromJson(<String, dynamic>{
      'schemaVersion': 1,
      'rulesetId': 'boxing',
      'version': 'test',
      'techniques': <dynamic>[],
      'combinations': <dynamic>[],
      'errors': <dynamic>[],
      'trackedComponents': <dynamic>[],
    });
  }

  LiveJabController build(_SlowCamera cam) => LiveJabController(
        ruleSet: rules(),
        cues: CueBook(const <NarrationEvent, List<String>>{}),
        camera: cam,
        modelPath: () async => '/tmp/model.task',
        modelId: 'test',
        requestPermission: () async => true,
      );

  test('POZİTİF KONTROL — sahte kamera, kapanış uçarken GERÇEKTEN reddediyor',
      () async {
    // Kapının kendisi ölçülüyor: aşağıdaki "devir temiz" sonucu, sahtenin
    // hiç reddetmemesinden de doğabilirdi ve o zaman test bir şey ölçmezdi.
    final _SlowCamera cam = _SlowCamera();
    unawaited(cam.stop());
    expect(cam.closing, isTrue);
    await expectLater(
      cam.start(modelPath: '/tmp/m', modelId: 't'),
      throwsA(isA<StateError>()),
      reason: 'sahte kamera kapanış sırasında reddetmiyor — bu testin '
          'ölçtüğü yarış SİMÜLE EDİLEMİYOR demektir',
    );
    await cam.settle();
  });

  test('DERS→DERS DEVRİ: kapanış uçarken açılan ders ARIZA GÖRMÜYOR',
      () async {
    final _SlowCamera first = _SlowCamera();
    final LiveJabController a = build(first);
    expect(await a.start(), isNull, reason: 'ilk ders açılamadı');

    // Kullanıcı çıkıyor: `dispose` senkron, `stop` BEKLENMİYOR.
    unawaited(a.stop());

    // Ve HEMEN yeni bir ders açıyor — ayrı controller, ayrı kamera nesnesi,
    // ama cihazda AYNI kamera.
    final _SlowCamera second = _SlowCamera();
    final LiveJabController b = build(second);
    final LiveSessionFailure? f = await b.start();

    expect(f, isNull,
        reason: 'ikinci ders BİRİNCİ dersin kapanışı yüzünden arıza gördü: '
            '$f\n\nKilit çalışmıyor. `LiveJabController._closing` süreç '
            'geneli olmalı (cihazda tek kamera var) ve `stop()` onu '
            'SENKRON yayınlamalı — `async` yapılırsa atama bir mikrotask '
            'geç görünür ve tam o aralıkta açılan ders kilidi kaçırır.');
    expect(second.startCalls, 1);
    await b.stop();
  });

  test('KİLİT GERÇEKTEN BEKLETİYOR — açılış, kapanıştan SONRA', () async {
    // Yukarıdaki test kilit olmadan da geçebilirdi: sahte kamera yeterince
    // hızlı kapanırsa yarış hiç doğmaz. Bu ölçüm SIRAYI çiviliyor.
    final _SlowCamera first = _SlowCamera();
    final LiveJabController a = build(first);
    await a.start();
    unawaited(a.stop());

    final _SlowCamera second = _SlowCamera();
    await build(second).start();

    expect(first.stopFinishedAt, isNotNull, reason: 'kapanış hiç bitmedi');
    expect(second.startedAt, isNotNull, reason: 'açılış hiç olmadı');
    expect(second.startedAt! >= first.stopFinishedAt!, isTrue,
        reason: 'açılış (${second.startedAt}) kapanıştan '
            '(${first.stopFinishedAt}) ÖNCE koştu — kilit beklemiyor');
  });

  test('N=1 MALİYETİ SIFIR — bekleyen kapanış yokken açılış gecikmiyor',
      () async {
    // Kilit doğru kurulmazsa, nadir bir kusur her açılışa gecikme olarak
    // ödenir. Bu ölçüm o takası yasaklıyor.
    final _SlowCamera cam = _SlowCamera();
    final LiveJabController c = build(cam);
    expect(cam.closing, isFalse, reason: 'ön koşul: uçan kapanış yok');
    await c.start();
    expect(cam.awaitedClosingBeforeStart, isFalse,
        reason: 'ilk açılışta bile bir kapanış beklendi — kilit N=1\'e '
            'maliyet bindiriyor');
    await c.stop();
  });
}

/// Gerçek eklentinin sözleşmesini taklit eder: `stop` bitene kadar `start`
/// **reddeder** (`already-running`).
class _SlowCamera extends OwnedTestCamera {
  _SlowCamera()
    : super(
        closeDelay: const Duration(milliseconds: 20),
        libraryTag: 'slow-handoff-fixture',
      );

  bool _legacyClosing = false;
  bool get closing => _legacyClosing || native.state.phase == 'closing';
  int? get startedAt => native.startedAt;
  int? get stopFinishedAt => native.stopFinishedAt;
  bool get awaitedClosingBeforeStart => native.awaitedClosingBeforeStart;

  Future<void> settle() async {
    while (closing) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  // Only the explicit legacy negative control calls these methods. App starts
  // and closure use the inherited production owned protocol and private lease.
  @override
  Future<CameraSessionInfo> start({
    required String modelPath,
    required String modelId,
    CameraLens lens = CameraLens.front,
    PassPlan initialPlan = PassPlan.uprightOnly,
  }) async {
    if (closing) {
      native.awaitedClosingBeforeStart = true;
      throw StateError('already-running: camera still closing');
    }
    return super.start(
      modelPath: modelPath,
      modelId: modelId,
      lens: lens,
      initialPlan: initialPlan,
    );
  }

  @override
  Future<void> stop() async {
    _legacyClosing = true;
    try {
      await super.stop();
    } finally {
      _legacyClosing = false;
    }
  }
}
