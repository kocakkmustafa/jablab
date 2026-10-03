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

import 'support/owned_native_fixture.dart';

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

  LiveJabController build(
    _FakeCamera cam, {
    Future<bool> Function()? permission,
    Future<bool> Function()? permanent,
  }) => LiveJabController(
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
      final LiveSessionFailure? f = await build(
        cam,
        permission: () async => false,
        permanent: () async => false,
      ).start();
      expect(f, isA<LivePermissionDenied>());
      expect((f! as LivePermissionDenied).permanentlyDenied, isFalse);
      expect(
        cam.startCalls,
        0,
        reason:
            'izin yokken kamerayı açmaya çalışmak, kullanıcıya '
            '"kamera açılamadı" dedirtirdi — oysa sorun izin',
      );
    });

    test('KALICI ret ayrı işaretleniyor', () async {
      // Sunulan EYLEM değişiyor: geçici rette tekrar sormak çalışır,
      // kalıcıda çalışmaz ve "tekrar dene" düğmesi hiçbir yere götürmez.
      final LiveSessionFailure? f = await build(
        _FakeCamera(),
        permission: () async => false,
        permanent: () async => true,
      ).start();
      expect((f! as LivePermissionDenied).permanentlyDenied, isTrue);
    });

    test('kamera reddi TİPLİ döner, fırlatmaz', () async {
      final _FakeCamera cam = _FakeCamera(
        startError: const CameraException(
          CameraFailure.noSuchCamera,
          'no front lens',
        ),
      );
      final LiveSessionFailure? f = await build(
        cam,
        permission: () async => true,
      ).start();
      expect(f, isA<LiveCameraUnavailable>());
      expect((f! as LiveCameraUnavailable).failure, CameraFailure.noSuchCamera);
    });

    test('TANINMAYAN hata isimli plugin reddi gibi SUNULMUYOR', () async {
      final _FakeCamera cam = _FakeCamera(startError: StateError('disk full'));
      final LiveSessionFailure? f = await build(
        cam,
        permission: () async => true,
      ).start();
      expect(
        f,
        isA<LiveSetupFailed>(),
        reason:
            'bilinmeyen hatayı isimli bir kamera reddi gibi sunmak, '
            'kullanıcıya bizim adımıza teşhis koymaktır',
      );
    });

    test('POZİTİF İKİZ: izin VARKEN ve kamera açılırken hata YOK', () async {
      final _FakeCamera cam = _FakeCamera();
      expect(await build(cam, permission: () async => true).start(), isNull);
      expect(cam.startCalls, 1);
    });
  });

  group('sayı yuvası', _countSlotTests);

  group('D18 — modeOfCounts SAF fonksiyon', () {
    // Kamera/motor kurmadan doğrudan sınanır — bkz. dosya sonundaki
    // "D18 — tamamlanan denemenin tempo bandı SAYILIYOR" testi (TELİ
    // kanıtlar), bu grup ALGORİTMAYI kanıtlar (boş/tekil/kazanan/eşitlik).
    test(
      'BOŞ harita → null (hiç tamamlanmış deneme yok, "controlled" DEĞİL)',
      () {
        expect(modeOfCounts(<String, int>{}), isNull);
      },
    );

    test('TEK bant → o bant', () {
      expect(modeOfCounts(<String, int>{'brisk': 3}), 'brisk');
    });

    test('AÇIK KAZANAN → en çok görülen', () {
      expect(
        modeOfCounts(<String, int>{'controlled': 2, 'brisk': 5, 'fast': 1}),
        'brisk',
      );
    });

    test('EŞİTLİK → İLK EKLENEN kazanır (rastgele DEĞİL, deterministik)', () {
      final Map<String, int> tie = <String, int>{};
      tie['fast'] = 4;
      tie['controlled'] = 4;
      expect(
        modeOfCounts(tie),
        'fast',
        reason:
            'eşitlikte eklenme sırası korunmalı — her koşumda AYNI '
            'sonucu vermeyen bir kapı, kararsız bir özet üretir',
      );
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

      final List<LiveJabRunning> runs = seen
          .whereType<LiveJabRunning>()
          .toList();
      expect(runs, isNotEmpty);
      expect(
        runs.last.completedCount,
        greaterThan(0),
        reason: 'sentetik jab hiç sayılmadı — zincir kopuk',
      );
      expect(
        runs.any((LiveJabRunning r) => r.phase != null),
        isTrue,
        reason: 'faz geri bildirimi hiç gelmedi',
      );
      await c.dispose();
    });

    test(
      'D18 — tamamlanan denemenin tempo bandı SAYILIYOR (J-096 sınıfı)',
      () async {
        // `_completed`in aynı sınıf kusuru: bileşen (`modeOfCounts`, ayrı
        // test edildi) kusursuz olup CONTROLLER onu hiç BESLEMİYOR olabilir.
        // Bu test yalnız TELİ kanıtlıyor — engine'in ürettiği tempoBand'ın
        // gerçekten controller'ın sayacına ULAŞTIĞINI.
        final _FakeCamera cam = _FakeCamera();
        final LiveJabController c = build(cam, permission: () async => true);

        expect(
          c.dominantTempoBand,
          isNull,
          reason: 'seans başlamadan bant iddiası olmamalı',
        );

        expect(await c.start(), isNull);
        expect(
          c.dominantTempoBand,
          isNull,
          reason:
              'YENİ seansta ÖNCEKİ testin kalıntısı sızmamalı — '
              '_startFor sıfırlamalı',
        );
        for (final PoseFrame f in _jabSequence()) {
          cam.emit(_envelope(f));
        }
        await Future<void>.delayed(Duration.zero);

        expect(
          c.dominantTempoBand,
          isNotNull,
          reason:
              'motor tempoBand üretti ama controller sayamadı — '
              'D18 teli kopuk',
        );
        await c.dispose();
      },
    );

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
      expect(
        r.noVerdictReason,
        isNotNull,
        reason: 'sessiz kalmak "her şey yolunda" diye okunur',
      );
      expect(
        r.noVerdictReason,
        contains('step back'),
        reason:
            'J-103: KİMSE YOK dalında "geri çekil" DOĞRU tavsiye — '
            'kullanıcı kadrajda değil ve eylem onun elinde',
      );
      expect(
        seen.whereType<LiveJabFailed>(),
        isEmpty,
        reason: 'görünmemek bir kurulum hatası DEĞİL',
      );
      await c.dispose();
    });

    test('KİŞİ VAR ama OKUMA BOZUK → "geri çekil" DEMİYOR (J-103)', () async {
      // `!resolution.usable`in İKİNCİ hâli: model bir iskelet üretti
      // (`structural != null`) ama anatomik olarak imkânsız çıktı. Eski
      // kod ikisine de aynı "step back" cümlesini basıyordu ve BURADA
      // yanlıştı: kullanıcı zaten kadrajda; geri çekilmek okumayı
      // düzeltmez, kötüleştirir. Kusur BİZDE, tavsiye onda değil.
      final _FakeCamera cam = _FakeCamera();
      final LiveJabController c = build(cam, permission: () async => true);
      final List<LiveJabState> seen = <LiveJabState>[];
      final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
      await c.start();
      for (final PoseFrame f in _steadyFrames(body: _swappedChainBody)) {
        cam.emit(_envelope(f));
      }
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final LiveJabRunning r = seen.whereType<LiveJabRunning>().last;
      expect(r.surface, LiveState.noVerdict);
      expect(
        r.noVerdictReason,
        isNot(contains('step back')),
        reason:
            'J-103 kusuru geri geldi: kadrajdaki kullanıcıya '
            '"geri çekil" deniyor',
      );
      expect(
        _structuralPhrases.contains(r.noVerdictReason),
        isTrue,
        reason:
            '`cue.structural`in bilinen 3 varyantından biri değil: '
            '"${r.noVerdictReason}"',
      );
      expect(
        r.skeleton,
        isNull,
        reason:
            'güvenmediğimiz iskeleti çizmek, "okumam bozuk" '
            'cümlesiyle çelişirdi — üstelik koordinatlar zaten yok',
      );
      expect(
        seen.whereType<LiveJabFailed>(),
        isEmpty,
        reason: 'bozuk okuma bir kurulum hatası DEĞİL, canlı bir hâl',
      );
      await c.dispose();
    });

    test(
      'SAYAÇ BİRİKİYOR — anlatıcının sayım girdisi gerçek (J-104)',
      () async {
        // ## Neden bu test var
        //
        // `_LiveState._completedJabs` bu sayacı okuyup
        // `SessionNarrator.tick(eventCount:)`e geçiyor. O çağrı J-104'e kadar
        // YOKTU: `eventCount` her zaman 0'a düşüyor ve `cue.milestone`
        // hiçbir koşulda ateşlenemiyordu — oysa anahtar `jabLabCueMapping`de
        // duruyordu, yani grep taraması ve ölü-replik kapısı ikisi de onu
        // "canlı" sayıyordu (aile dersi #6).
        //
        // Burada sayacın GERÇEKTEN biriktiği ölçülüyor: sabit 0 olmadığı,
        // yani anlatıcıya beslenen şeyin bir olgu olduğu.
        //
        // ## ⛔ NE ÖLÇÜLMEDİ — beyan ediyorum
        //
        // Kilometre taşı repliğinin (eşik 25) EKRANDA göründüğü. O yüzey
        // testi yazıldı ve KOŞTURULAMADI: `session_rounds_test` süiti içinde
        // 10 dakikalık zaman aşımına düşüyor, TEK BAŞINA 20 tekrarda 2
        // saniyede bitiyor — yani maliyet süit etkileşiminde, hacimde değil.
        // Sebebin ÜRÜNDE olmadığı ayrıca ölçüldü: motor profili DOĞRUSAL
        // (100→800 kare toplam 23 ms, kare başına maliyet DÜŞÜYOR), yani
        // uzun seansta biriken bir yavaşlama YOK. Kalan dikiş —
        // `_completedJabs` → `tick(eventCount:)` — teftişle doğrulanıyor ve
        // cihaz/simülatör turunda göz-doğrulaması bekliyor (J-104 açık borç).
        final _FakeCamera cam = _FakeCamera();
        final LiveJabController c = build(cam, permission: () async => true);
        final List<LiveJabState> seen = <LiveJabState>[];
        final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
        await c.start();
        // Aynı diziyi 6 kez, zaman ekseninde ÖTELEYEREK. Öteleme şart:
        // damgaları tekrar göndermek faz makinesini geriye sarardı ve
        // tekrarlar ayrı jab sayılmazdı.
        for (int rep = 0; rep < 6; rep++) {
          for (final PoseFrame f in _jabSequence(repOffsetUs: rep * 800000)) {
            cam.emit(_envelope(f));
          }
        }
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        final LiveJabRunning last = seen.whereType<LiveJabRunning>().last;
        expect(
          last.completedCount,
          6,
          reason:
              'altı sentetik jab gönderildi, sayaç ${last.completedCount} '
              '— sayaç birikmiyorsa anlatıcıya geçen şey de sabit kalır ve '
              'kilometre taşı asla ateşlenemez',
        );
        await c.dispose();
      },
    );

    test('İLK ÇÖZÜLEN KAREDE "seni görüyorum" — bir kez (J-120)', () async {
      // `cue.setup_ok` J-105'te muafiyet listesinde bırakılmıştı: *"gerçekten
      // eklenmeyi bekliyor."* O bir karar değil kararın ERTELENMESİYDİ.
      // Karar: bağlanır — yetenek zaten var ve eşik gerektirmiyor, "seni
      // görüyorum" çözülmüş ilk karenin ta kendisi.
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

      final List<String> lines = seen
          .whereType<LiveJabRunning>()
          .map((LiveJabRunning r) => r.narration)
          .whereType<String>()
          .toList();
      expect(lines, isNotEmpty, reason: '"seni görüyorum" hiç söylenmedi');
      expect(
        _readyPhrases.contains(lines.first),
        isTrue,
        reason:
            '`cue.setup_ok`in bilinen 3 varyantından biri değil: '
            '"${lines.first}"',
      );
      // TEK KEZ: her karede tekrarlamak canlı koçu gürültüye çevirir ve
      // gürültü susmakla aynı sonucu verir — kullanıcı dinlemeyi bırakır.
      expect(
        lines.where(_readyPhrases.contains).length,
        1,
        reason:
            '"seni görüyorum" ${lines.where(_readyPhrases.contains).length} '
            'kez söylendi — her karede tekrarlanıyor',
      );
      await c.dispose();
    });

    test('KİMSE YOKKEN "seni görüyorum" DENMİYOR', () async {
      // ⭐ NEGATİF İKİZ: çözülmüş kare yoksa cümle de yok. Bu olmadan
      // yukarıdaki test, seansın başında koşulsuz konuşan bir koçla da
      // geçerdi — ve o koç görmediği bir şeyi gördüğünü söylerdi.
      final _FakeCamera cam = _FakeCamera();
      final LiveJabController c = build(cam, permission: () async => true);
      final List<LiveJabState> seen = <LiveJabState>[];
      final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
      await c.start();
      cam.emit(_envelope(null));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      for (final LiveJabRunning r in seen.whereType<LiveJabRunning>()) {
        expect(
          _readyPhrases.contains(r.narration),
          isFalse,
          reason: 'kimse görünmezken "seni görüyorum" denildi',
        );
      }
      await c.dispose();
    });

    group('DÜZELTME KAYBOLDU (J-105)', () {
      // `cue.corrected` J-105'e kadar ölüydü: `jabLabCueMapping`de duruyordu
      // ama `NarrationEvent.corrected`i üreten hiçbir kod yolu yoktu ve
      // `session_narrator_test`in `engineDriven` MUAFİYET listesi onu
      // testten de saklıyordu. Artık motor-sürücülü ve burada ölçülüyor.

      test(
        'TEMİZ dizide düzeltme repliği ÇIKMIYOR — övülecek bir şey yok',
        () async {
          // NEGATİF İKİZ ÖNCE: kaybolan bir işaret yoksa cümle de yok.
          // Bu olmadan pozitif test, her denemede konuşan bir koçla da geçerdi.
          final _FakeCamera cam = _FakeCamera();
          final LiveJabController c = build(cam, permission: () async => true);
          final List<LiveJabState> seen = <LiveJabState>[];
          final StreamSubscription<LiveJabState> sub = c.states.listen(
            seen.add,
          );
          await c.start();
          for (int rep = 0; rep < 3; rep++) {
            for (final PoseFrame f in _jabSequence(repOffsetUs: rep * 800000)) {
              cam.emit(_envelope(f));
            }
          }
          await Future<void>.delayed(Duration.zero);
          await sub.cancel();

          // ⚠️ "HİÇ anlatı yok" DİYE ölçmüyor — o fazla geniş bir iddia
          // olurdu ve nitekim öyleydi: J-120'de `cue.setup_ok` aynı yuvaya
          // bağlanınca bu test kırıldı, oysa ölçtüğü şey bozulmamıştı.
          // Ölçülen şey DÜZELTME repliğinin çıkmaması; anlatı yuvasının başka
          // doğru şeyler söylemesi bu testi ilgilendirmez.
          final Iterable<String> corrected = seen
              .whereType<LiveJabRunning>()
              .map((LiveJabRunning r) => r.narration)
              .whereType<String>()
              .where(_correctedPhrases.contains);
          expect(
            corrected,
            isEmpty,
            reason:
                'hiçbir işaret kaybolmadan "düzeltildi" denildi: '
                '${corrected.toList()}',
          );
          await c.dispose();
        },
      );

      test('replik ÖLÇÜM DİLİ — tezahürat DEĞİL', () async {
        // Koordinatör hükmü (2026-08-07): "That correction is gone." evet,
        // "Nice!" hayır. Eski varyantlar ("Yes — keep that.", "Better.")
        // övgü ve KARŞILAŞTIRMA taşıyordu; ikincisi ayrıca K8'e komşu bir
        // iddia — kalibrasyonsuz "daha iyi" diyemeyiz.
        final CueBook book = await const ContentRepository().loadCues();
        final RegExp cheer = RegExp(
          r"\b(nice|great|awesome|well done|good job|perfect|"
          r"better|best|improv)",
          caseSensitive: false,
        );
        for (int i = 0; i < 8; i++) {
          final String? line = book.sayKey('cue.corrected');
          expect(line, isNotNull);
          expect(
            cheer.hasMatch(line!),
            isFalse,
            reason: 'tezahürat/karşılaştırma dili: "$line"',
          );
        }
      });

      test('GÖRÜNÜRLÜK kodu kaybolunca düzeltme DENMİYOR', () async {
        // "Seni göremiyordum, artık görüyorum" bir DÜZELTME değil: kullanıcı
        // bir şey düzeltmedi, koşullar değişti. Onu övmek yapmadığı bir işi
        // ona mal etmek olurdu.
        expect(
          jabLabVisibilityIssueCodes.every(jabLabIssueCueMapping.containsKey),
          isTrue,
          reason:
              'görünürlük kodları eşlemeden düşmüş — hariç tutma '
              'kuralı sessizce boşa döner',
        );
        expect(
          jabLabVisibilityIssueCodes,
          isNotEmpty,
          reason:
              'küme boşalırsa kontrolcüdeki hariç tutma HİÇBİR ŞEYİ '
              'dışarıda bırakmaz ve kural vakum-doğru olur (ders #4)',
        );
      });
    });

    group('GERÇEKÇİ GÜRÜLTÜ — sentetik sınırını DARALTMA (J-125)', () {
      // ## Neden bu grup var
      //
      // Yayın envanterinin 🟡 satırlarından biri: *"iskelet gerçek MediaPipe
      // çıktısı değil, sentetik."* Sınıfı **ÖLÇÜLMEMİŞ** (M-F-287) — imkânsız
      // değil, ertelenmiş de değil: ölçülebilir ama ölçülmedi.
      //
      // Bugüne kadarki sentetik diziler **TEMİZDİ**: kusursuz görünürlük,
      // sıfır titreme, sıfır kare düşmesi. Gerçek kamera bunların üçünü de
      // yapmaz. Yani testler "sentetik" olduğu için değil, **temiz** olduğu
      // için gerçekten uzaktı — ve o mesafenin bir kısmı ölçülebilir.
      //
      // Bu grup mesafeyi KAPATMIYOR (gerçek model hâlâ cihaz turunda), ama
      // **daraltıyor**: zincir titreme ve kare düşmesi altında da ayakta mı?
      // Sınıf hâlâ ölçülmemiş, ama artık daha küçük bir şey ölçülmemiş.

      test('TİTREME altında jab hâlâ SAYILIYOR', () async {
        // `sigma = 0.004` çekirdeğin kendi varsayılanı — uydurulmuş bir
        // gürültü seviyesi değil. Tohum sabit: kırılan bir test birebir
        // yeniden üretilebilmeli, çünkü kararsız bir fixture herkesi
        // kırmızıyı görmezden gelmeye alıştırır.
        final _FakeCamera cam = _FakeCamera();
        final LiveJabController c = build(cam, permission: () async => true);
        final List<LiveJabState> seen = <LiveJabState>[];
        final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
        await c.start();
        for (final PoseFrame f in SyntheticNoise.jitter(
          _jabSequence(),
          seed: 7,
        )) {
          cam.emit(_envelope(f));
        }
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        final List<LiveJabRunning> runs = seen
            .whereType<LiveJabRunning>()
            .toList();
        expect(runs, isNotEmpty);
        expect(
          runs.last.completedCount,
          greaterThan(0),
          reason:
              'titreme altında jab hiç sayılmadı — zincir yalnız '
              'kusursuz girdiyle çalışıyor demektir ve gerçek kamera '
              'kusursuz değildir',
        );
        await c.dispose();
      });

      test('KARE DÜŞMESİ altında jab hâlâ SAYILIYOR', () async {
        // `decimate(2)` = karelerin yarısı düşüyor (~30 fps → ~15).
        // Termal kısıtlama altında gerçekleşen şey bu; motor faz süreleriyle
        // çalıştığı için kare SAYISINA değil ZAMANA bağlı olmalı — bu test
        // o tasarım iddiasını sınıyor.
        final _FakeCamera cam = _FakeCamera();
        final LiveJabController c = build(cam, permission: () async => true);
        final List<LiveJabState> seen = <LiveJabState>[];
        final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
        await c.start();
        for (final PoseFrame f in SyntheticNoise.decimate(_jabSequence(), 2)) {
          cam.emit(_envelope(f));
        }
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        final List<LiveJabRunning> runs = seen
            .whereType<LiveJabRunning>()
            .toList();
        expect(runs, isNotEmpty);
        expect(
          runs.last.completedCount,
          greaterThan(0),
          reason:
              'kare düşünce jab sayılmıyor — motor kare SAYISINA '
              'bağımlı demektir, oysa faz süreleri ZAMANA bağlı olmalı',
        );
        await c.dispose();
      });

      test('İKİSİ BİRDEN — ve ham kod yine SIZMIYOR', () async {
        // Gürültü, hüküm verilemeyen dalları da tetikleyebilir; o dallardan
        // ham teşhis dizesi sızmadığı burada da ölçülüyor. Yeni bir yol
        // açıldığında eski kapının ORADA da tuttuğunu varsaymak, kapıyı
        // yalnız test edilmiş yolda kurmak olurdu.
        final _FakeCamera cam = _FakeCamera();
        final LiveJabController c = build(cam, permission: () async => true);
        final List<LiveJabState> seen = <LiveJabState>[];
        final StreamSubscription<LiveJabState> sub = c.states.listen(seen.add);
        await c.start();
        for (final PoseFrame f in SyntheticNoise.decimate(
          SyntheticNoise.jitter(_jabSequence(), seed: 11),
          2,
        )) {
          cam.emit(_envelope(f));
        }
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        final RegExp codeLike = RegExp(r'\b[A-Z][A-Z_]{4,}\b');
        for (final LiveJabRunning r in seen.whereType<LiveJabRunning>()) {
          for (final String? s in <String?>[r.cue, r.noVerdictReason]) {
            if (s == null) continue;
            expect(
              codeLike.hasMatch(s),
              isFalse,
              reason: 'gürültülü yolda teşhis dizesi sızdı: "$s"',
            );
          }
        }
        expect(
          seen.whereType<LiveJabFailed>(),
          isEmpty,
          reason:
              'gürültü seansı ÖLDÜRDÜ — titreme bir kurulum hatası '
              'değil, canlı bir hâl',
        );
        await c.dispose();
      });
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
      await expectLater(
        c.dispose(),
        throwsA(
          isA<CameraException>().having(
            (error) => error.failure,
            'failure',
            CameraFailure.closeUncertain,
          ),
        ),
      );
      expect(cam.activeListeners, 0);
      expect(cam.stopCalls, 1);
      final nextCamera = _FakeCamera();
      final next = build(nextCamera, permission: () async => true);
      try {
        expect(
          await next.start(),
          isA<LiveCameraUnavailable>().having(
            (failure) => failure.failure,
            'failure',
            CameraFailure.closeUncertain,
          ),
        );
        expect(
          nextCamera.startCalls,
          0,
          reason: 'closing a failed stream cannot reopen sticky admission',
        );
      } finally {
        await next.dispose();
        await nextCamera.close();
        await cam.close();
      }
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
          expect(
            codeLike.hasMatch(s),
            isFalse,
            reason: 'teşhis dizesi kullanıcıya gösterildi: "$s"',
          );
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

      final List<LiveJabRunning> runs = seen
          .whereType<LiveJabRunning>()
          .toList();
      expect(runs, isNotEmpty);
      for (final LiveJabRunning r in runs) {
        expect(
          r.skeleton,
          isNotNull,
          reason:
              'çözülmüş bir kare varken iskelet YOK olamaz — '
              '`skeleton_overlay.dart` çizecek bir şey bulamaz',
        );
        // Lm.count == 33 (MediaPipe Pose Landmarker topolojisi) — motorun
        // içindeki bir sabiti burada TEKRAR yazmak yerine ham uzunluk
        // doğrudan kontrol ediliyor, bu paketin kendi kontratı zaten
        // `landmark_index.dart`ta sabit.
        expect(r.skeleton!.length, 33);
      }
      await c.dispose();
    });

    test(
      'KİMSE YOK iken İSKELET de YOK — çizecek koordinat icat edilmez',
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
      },
    );

    group('BASTIRMA yolu — suppressionReason ÇEVRİLİYOR (J-099)', () {
      // Bu grup `_jabSequence()`in hiç dokunmadığı dalı hedefler: motorun
      // `!judgeable` dediği kare. Taramanın bulduğu bulgu tam burada —
      // `noVerdictReason: out.suppressionReason` ham teşhis dizesini
      // DOĞRUDAN yüzeye yazıyordu. `_jabSequence()`in "HAM KOD" testi bu
      // dalı hiç ÇALIŞTIRMADIĞI için kusuru YAKALAYAMAZDI — burada gerçek
      // motor, gerçek eşiklerle, bu dalı BİLEREK tetikliyoruz.

      test(
        'gövde landmarkı DÜŞÜK GÜVEN → torsoUnreliable, AYRI cümle',
        () async {
          final _FakeCamera cam = _FakeCamera();
          final LiveJabController c = build(cam, permission: () async => true);
          final List<LiveJabState> seen = <LiveJabState>[];
          final StreamSubscription<LiveJabState> sub = c.states.listen(
            seen.add,
          );
          await c.start();
          // ConfidenceGate.torsoThreshold=0.6 — gövde bunun ALTINA düşünce
          // her şeyden ÖNCE (kol/bacak güveninden bile önce) kontrol ediliyor.
          for (final PoseFrame f in SyntheticNoise.occlude(
            _steadyFrames(),
            <int>[Lm.leftShoulder],
            visibility: 0.3,
          )) {
            cam.emit(_envelope(f));
          }
          await Future<void>.delayed(Duration.zero);
          await sub.cancel();

          final LiveJabRunning r = seen.whereType<LiveJabRunning>().last;
          expect(r.surface, LiveState.noVerdict);
          expect(
            r.noVerdictReason,
            isNot(contains('torsoUnreliable')),
            reason: 'ham motor kodu sızdı',
          );
          expect(
            r.noVerdictReason,
            isNot(contains(':')),
            reason: 'ham teşhis dizesi biçimi ("kategori:detay") sızdı',
          );
          expect(
            r.noVerdictReason,
            "I can't get a steady read on your torso — square up so your "
            'shoulders and hips are both visible.',
          );
          await c.dispose();
        },
      );

      test(
        'bilek DÜŞÜK GÜVEN (gövde temiz) → cue.low_confidence GERÇEK metni',
        () async {
          final _FakeCamera cam = _FakeCamera();
          final LiveJabController c = build(cam, permission: () async => true);
          final List<LiveJabState> seen = <LiveJabState>[];
          final StreamSubscription<LiveJabState> sub = c.states.listen(
            seen.add,
          );
          await c.start();
          // Gövde (torso) tam güvende kalıyor — yalnız bilek düşük, böylece
          // ConfidenceGate `lowTrackingConfidence`e düşüyor, `torsoUnreliable`e
          // değil (sıra: gövde → kadraj-dışı → düşük-güven, evaluate() içinde).
          for (final PoseFrame f in SyntheticNoise.occlude(
            _steadyFrames(),
            <int>[Lm.leftWrist],
            visibility: 0.2,
          )) {
            cam.emit(_envelope(f));
          }
          await Future<void>.delayed(Duration.zero);
          await sub.cancel();

          final LiveJabRunning r = seen.whereType<LiveJabRunning>().last;
          expect(r.surface, LiveState.noVerdict);
          expect(
            _lowConfidencePhrases.contains(r.noVerdictReason),
            isTrue,
            reason:
                '`cue.low_confidence`in bilinen 4 varyantından biri '
                'değil — ham teşhis dizesi sızmış olabilir: '
                '"${r.noVerdictReason}"',
          );
          await c.dispose();
        },
      );

      // ⚠️ `StrikingEngine`in `structural:` BASTIRMASI (bu dosyadaki
      // `_suppressionSentence` dalı) canlı-hat üzerinden GERÇEK bir sentetik
      // yapısal-kusurla tetiklenip test EDİLEMEDİ — dört ayrı fixture
      // denendi (aşırı bacak kısaltma, yalnız kol uzatma, büyük kemik
      // sıçraması, eşik-sınırı kemik sıçraması) ve HEPSİ, motora hiç
      // ulaşmadan, `resolution.usable=false`e düştü. Sebep — kusur DEĞİL,
      // mimari:
      // `OrientationAwarePoseSource._run` (motion_core) HER karede KENDİ
      // `StructuralValidator`ını çalıştırıyor ve `OrientationCandidate.usable
      // => structural.plausible` diyor (orientation_aware_source.dart:42) —
      // yani motorun `StrikingEngine.process()`teki `structural:` bastırması
      // (striking_engine.dart:295-297) ile TAMAMEN AYNI koşulu, TAMAMEN AYNI
      // `StructuralValidator` sınıfıyla, motor daha kareyi GÖRMEDEN önce
      // kontrol ediyor. Zaman-bağımsız kusurlar için (limbProportionImplausible,
      // bilateralAsymmetry) bu iki kontrol MATEMATİKSEL OLARAK AYNI kareyi,
      // aynı formülle değerlendiriyor — yani `StrikingEngine`in `structural:`
      // bastırması canlı hatta YAPISAL OLARAK ERİŞİLEMEZ; motion_core'un
      // kendi kapısı her zaman önce davranıyor.
      //
      // ✅ J-103 BUNU ÇÖZDÜ — dalı erişilebilir kılarak DEĞİL, ÜSTTEKİ kapıyı
      // düzelterek. Erken kapı artık iki hâli ayırıyor ve yapısal hâlde AYNI
      // `cue.structural` anahtarını söylüyor; yukarıdaki *"KİŞİ VAR ama OKUMA
      // BOZUK"* testi tam da o dört fixture'ın düştüğü yolu ölçüyor. Yani
      // `cue.structural` artık ÖLÜ DEĞİL (tarama dokümanının 🔴🔴 satırı
      // kapandı) — canlı olan yol bu dosyada test edilen erken kapı.
      // `_suppressionSentence` içindeki geç dal KORUNUYOR: savunma amaçlı
      // (motion_core'un kapı sırası bir gün değişirse ham dize sızmasın),
      // doğruluğu teftişle doğrulanıyor — ama artık kullanıcının duyduğu
      // cümle her iki kapıda da AYNI, yani "sessizce farklı davranma" riski
      // de kalmadı.
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

/// `cue.structural` varyantları — `_lowConfidencePhrases` ile aynı gerekçe.
/// `cue.setup_ok` varyantları — `_lowConfidencePhrases` ile aynı gerekçe.
/// `cue.corrected` varyantları — aynı gerekçe.
const List<String> _correctedPhrases = <String>[
  'That correction is gone.',
  'The flag cleared that time.',
  'Not seeing it on that one.',
  'That one came back clean.',
];

/// `cue.setup_ok` varyantları — `_lowConfidencePhrases` ile aynı gerekçe.
const List<String> _readyPhrases = <String>[
  'I can see you. Ready?',
  'Got you. Whenever you are.',
  "You're in frame. Ready?",
];

const List<String> _structuralPhrases = <String>[
  'My tracking looks wrong — holding off.',
  "Not confident in what I'm seeing.",
  "Something's off in my read. Staying quiet.",
];

/// KOL/BACAK ZİNCİRİ TAKAS EDİLMİŞ gövde — `StructuralValidator`ın
/// `limbProportionImplausible` kapısını BİLEREK tetikler.
///
/// Kapının kuralı: `arm/leg > 1.15` (kol = üstkol+önkol ortalaması, bacak =
/// uyluk+baldır; `structural_validator.dart`). Bu gövdede kol 0.23, bacak
/// 0.15 → oran **1.53**. Ölçüler 2B ve z=0 olduğu için üretilen kemik
/// uzunlukları burada YAZILAN değerlerin AYNISI — eşik hesabı poza bağlı
/// değil, yani test kırılgan değil.
///
/// Bu senaryonun gerçek karşılığı motion_core'un kendi dokümanında: ters
/// duran bir gövdede poz modeli kol ve bacak zincirlerini takas edip sonucu
/// **yüksek güvenle** bildirebiliyor — güven kapısı bunu yakalayamaz, çünkü
/// belirsiz olan hiçbir şey yok. Kullanıcı kadrajda ve doğru duruyor;
/// yanlış olan bizim okumamız.
const SyntheticBody _swappedChainBody = SyntheticBody(
  upperArmLength: 0.12,
  forearmLength: 0.11,
  thighLength: 0.08,
  shinLength: 0.07,
);

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
      SyntheticPoseBuilder(
        body: body,
      ).build(SyntheticPose.neutral, tUs: i * stepUs, visibility: visibility),
  ];
}

/// SAYI YUVASI — "henüz sayılmıyor" ile "sıfır" AYRI (J-096).
///
/// Simülatörde bulundu: analiz hiç başlamamışken ekranda kocaman bir **0**
/// duruyordu, yani "sıfır yumruk attın". J-092'nin canlı ekrandaki birebir
/// tekrarı — ve hiçbir widget testi görmüyordu çünkü hepsi metnin VARLIĞINI
/// sınıyordu, ANLAMINI değil.
void _countSlotTests() {
  testWidgets('analiz başlamamışken SAYI GÖSTERİLMİYOR', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveCoachSurface(
            state: LiveState.noVerdict,
            eventCount: null,
            noVerdictReason: 'camera off',
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('event-count')), findsNothing);
  });

  testWidgets('POZİTİF İKİZ: koşan seansta SAYI gösteriliyor (0 dahil)', (
    WidgetTester t,
  ) async {
    // Koşan bir seansta 0 DOĞRUDUR: ölçüyoruz ve henüz yumruk yok.
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveCoachSurface(state: LiveState.clean, eventCount: 0),
        ),
      ),
    );
    expect(find.byKey(const Key('event-count')), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}

/// Motorun jab olarak tanıdığı sentetik dizi (engine_test'in aynısı).
List<PoseFrame> _jabSequence({int repOffsetUs = 0}) {
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
    out.add(b.build(seq.poseAt(t), tUs: repOffsetUs + t));
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

/// Mock native wire plus actual production controller/lease; no real device.
class _FakeCamera extends OwnedTestCamera {
  _FakeCamera({super.startError}) : super(libraryTag: 'live-path-fixture');
}
