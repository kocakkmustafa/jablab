import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/app/rehearse_material.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/teach_material.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';

/// SEANSTAN **GERİ** ÇIKMAK — kayıt yazılıyor mu (J-192).
///
/// ## Kapsam boşluğu, ölçüldü
///
/// `session_rounds_test`te şu adla bir kapı var: **"YARIDA bırakılan seans
/// da kaydedilir"**. Ad **genel** bir iddia kuruyor; ölçüm ise tek bir
/// yolu kapsıyor — **ileri düğmesi** (`advance-button`). Kaynak tarafında
/// üç şey ölçüldü:
///
/// * `_record()`in **tek çağıranı** var ve o `_next()` içinde,
///   `leavingLive` koşuluyla;
/// * `lib/` ağacının **hiçbir yerinde** `PopScope`/`WillPopScope` yok
///   (pozitif kontrol: aynı tarama `session_screen.dart`ta 3 `Scaffold`
///   buluyor, yani kör değil);
/// * seans ekranı `Navigator.push` ile açılıyor ve `AppBar` varsayılan
///   `automaticallyImplyLeading` ile **geri okunu çiziyor.**
///
/// Yani kullanıcı canlı turun ortasında geri okuna basarsa `_next()` hiç
/// koşmaz. Bu test o yolu **ürünün yaşadığı yerden** ölçüyor: gerçekten
/// bir rota push edilip gerçekten geri dönülüyor.
///
/// ## ⛔ BU TEST BİR HÜKÜM DEĞİL, BİR ÖLÇÜM
///
/// *"Geri çıkış kaydetmeli mi?"* bir **ürün davranışı** sorusu ve
/// koordinatöre soruldu. İki okuma da savunulabilir:
///
/// * **Kaydetmeli** — kullanıcı gerçekten çalıştı; `_next()` yolundaki
///   kod yorumu zaten *"'yarıda bıraktı' bir veridir"* diyor ve o gerekçe
///   çıkış yönüne bağlı değil.
/// * **Kaydetmemeli** — geri, bir **vazgeçme** jesti olabilir.
///
/// Karar hangisi olursa olsun, **bugünkü davranışın yazılı olması** şart:
/// bu test onu çiviliyor, ve karar geldiğinde **beklenti satırı değişir.**
void main() {
  late CueBook cues;

  setUpAll(() async {
    cues = await const ContentRepository().loadCues();
  });

  Future<void> pushSession(WidgetTester t, SessionStore store) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (BuildContext c) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('go'),
              onPressed: () => Navigator.of(c).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => SessionScreen(
                    lesson: const ShellLesson(
                        id: 'x', title: 'Test lesson', minutes: 12),
                    cues: cues,
                    coachedNotScored: const <String>['Rear guard hand position'],
                    bands: const <String, String>{'Stance': '—'},
                    plan: const RoundPlan(
                      rounds: 6,
                      roundSeconds: 4,
                      restSeconds: 2,
                      planProvenance: 'test',
                    ),
                    store: store,
                    rehearseMaterial: const RehearseMaterialNone(reason: 'fixture: no drill named'),
                    teachMaterial:
                        const TeachMaterialNone(reason: 'test: materyal yok'),
                  ),
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.byKey(const Key('go')));
    await t.pumpAndSettle();
    // teach → rehearse → live
    await t.tap(find.byKey(const Key('advance-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('advance-button')));
    await t.pump();
  }

  testWidgets('seans PUSH edilmiş bir rota ve GERİ çıkışı var', (
    WidgetTester t,
  ) async {
    // VAKUM MUHAFIZI — geri oku gerçekten çizilmiyorsa, aşağıdaki testin
    // "geri basıldı" iddiası anlamsız olurdu: basılacak bir şey yok demektir.
    final _FakeStore store = _FakeStore();
    await pushSession(t, store);
    expect(find.byType(BackButton), findsOneWidget,
        reason: 'seans ekranında geri oku YOK — bu testin ölçtüğü çıkış '
            'yolu kullanıcıya kapalı demektir ve J-192 bulgusu yeniden '
            'ölçülmelidir');
  });

  testWidgets('GERİ çıkışta da kayıt YAZILIYOR (hüküm 14:05)', (
    WidgetTester t,
  ) async {
    final _FakeStore store = _FakeStore();
    await pushSession(t, store);

    // Gerçek çalışma: bir tam tur (4sn) + biraz daha.
    await t.pump(const Duration(seconds: 5));

    // Kullanıcı geri basıyor — canlı turun ortasında.
    await t.pageBack();
    await t.pumpAndSettle();

    expect(store.written, isNotEmpty,
        reason: 'geri çıkışta kayıt YAZILMIYOR. Hüküm (14:05): yazılmalı. '
            'Belirleyici olan "geri = vazgeçme mi" değil, ASİMETRİ — '
            'ileri gitseydi "tamamlanmadı" diye kaydedilecekti, yani '
            'sistem vazgeçmeyi ZATEN kaydediyor. Zarar bileşik: yalnız '
            'geçmiş değil, ilerleme de kayboluyor (minCompletedAttempts).');
    expect(store.written.single.isComplete, isFalse,
        reason: 'kayıt sınıfı DEĞİŞMEMELİ: "tamamlandı" değil, mevcut '
            '"yarıda bırakıldı" sınıfı');
  });

  testWidgets('POZİTİF İKİZ — İLERİ çıkışta kayıt YAZILIYOR', (
    WidgetTester t,
  ) async {
    // Yukarıdaki "boş" sonuç, deponun hiç çağrılamamasından da doğabilirdi
    // (yanlış kurulmuş harness, saat akmaması, plan null olması...). Bu ikiz
    // aynı harness'ın kayıt yazabildiğini kanıtlıyor — yani boşluk GERÇEK.
    final _FakeStore store = _FakeStore();
    await pushSession(t, store);
    await t.pump(const Duration(seconds: 5));
    await t.tap(find.byKey(const Key('advance-button')));
    await t.pumpAndSettle();

    expect(store.written, isNotEmpty,
        reason: 'aynı harness ileri yolda da kayıt yazamıyor — o zaman '
            'yukarıdaki "geri çıkışta yazılmıyor" bulgusu ölçüm değil, '
            'kurulum hatasıdır');
    expect(store.written.single.isComplete, isFalse);
  });
}

class _FakeStore implements SessionStore {
  final List<SessionRecord> written = <SessionRecord>[];

  @override
  Future<void> append(SessionRecord record) async => written.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => written;

  @override
  Future<int> unreadableRecords() async => 0;

  @override
  Future<int> workedSecondsFor(String lessonId) async => written
      .where((SessionRecord r) => r.lessonId == lessonId)
      .fold<int>(0, (int a, SessionRecord r) => a + r.workedSeconds);
}
