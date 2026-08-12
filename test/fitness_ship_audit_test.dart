import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab_engine/jablab_engine.dart';

import 'app_pump.dart';

/// FITNESS-TRACK SHIP DENETİMİ — uçtan uca KOŞUM (J-070).
///
/// **Bu dosya bir beyan değil, bir KANIT üreticisidir.** J-062'de "Fitness
/// şimdi çıkabilir" cümlesini yazdım ve YANLIŞTI: 7 dersin 7'si de beyan
/// ettiği yapıyı koşmuyordu ve hiçbir test bunu görmüyordu. O cümlenin
/// yerine artık bu koşumun çıktısı geçiyor —
/// `docs/gates/FITNESS-SHIP-KANITI.txt` bu testin stdout'udur.
///
/// Denetim İÇERİKTEN sürülür, ders listesi ELLE YAZILMAZ: yeni bir ders
/// eklenirse denetim onu kendiliğinden kapsar, unutulamaz.
///
/// Her canlı süreli ders için kanıtlanan altı şey:
///   1. Uygulama açılışından derse ULAŞILABİLİYOR (kütüphane → disiplin →
///      kurs → ders) — "2-tık kuralı"nın gerçek yürüyüşü.
///   2. Seans akışı DÖRT aşamayı yürüyor (öğret → dene → canlı → özet).
///   3. Saat, dersin BEYAN ETTİĞİ yapıyı koşuyor (tur/patlama ilerliyor).
///   4. Seans sonunda ÇALIŞMA süresi dersin KENDİ KAPISINA birebir eşit.
///   5. Kayıt diske/depoya YAZILIYOR (kamera olmadan da çalışan hat).
///   6. Kaydedilen olgu ilerleme sayfasında GÖRÜNÜYOR.
/// KARŞILAMA ATLANIYOR (J-106). Bu dosyanın sınadığı şey karşılama DEĞİL;
/// gerçek bayrağı okumak her testi "ilk açılış" hâline sokup kabuğa hiç
/// ulaştırmazdı. `seenOverride` üretimde `null` — bu yalnız bir test dikişi.
const OnboardingStore _seen = OnboardingStore(seenOverride: true);

void main() {
  final StringBuffer log = StringBuffer();
  void say(String s) {
    log.writeln(s);
    // ignore: avoid_print
    print(s);
  }

  setUp(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(1400, 3200);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  // ---- içerikten sürülen ders envanteri --------------------------------
  final Map<String, dynamic> libJson =
      (jsonDecode(File('assets/content/library.json').readAsStringSync())
              as Map)
          .cast<String, dynamic>();
  final Map<String, dynamic> curJson =
      (jsonDecode(File('assets/content/curriculum.json').readAsStringSync())
              as Map)
          .cast<String, dynamic>();
  final Library lib = Library.fromJson(libJson);
  final Map<String, dynamic> progression =
      (curJson['progression'] as Map).cast<String, dynamic>();

  int? gateSecondsOf(String lessonId) {
    final Map<String, dynamic>? node =
        (progression[lessonId] as Map?)?.cast<String, dynamic>();
    for (final dynamic g in (node?['gates'] as List?) ?? const <dynamic>[]) {
      final num? m = (g as Map)['sessionMinutes'] as num?;
      if (m != null) return m.toInt() * 60;
    }
    return null;
  }

  final List<({Course course, Lesson lesson})> liveTimed =
      <({Course course, Lesson lesson})>[];
  final List<Lesson> lockedLessons = <Lesson>[];
  for (final Discipline d in lib.disciplines) {
    for (final Course c in d.courses) {
      for (final Lesson l in c.lessons) {
        if (l.isLocked) {
          lockedLessons.add(l);
          continue;
        }
        if (l.roundPlan != null || l.intervalPlan != null) {
          liveTimed.add((course: c, lesson: l));
        }
      }
    }
  }

  testWidgets('FITNESS-TRACK SHIP DENETİMİ — uçtan uca', (WidgetTester t) async {
    say('═══════════════════════════════════════════════════════════════');
    say('FITNESS-TRACK SHIP DENETİMİ — KOŞUM ÇIKTISI (J-070)');
    say('Bu dosya elle yazılmadı: `test/fitness_ship_audit_test.dart`');
    say('koşumunun stdout\'udur. Beyan değil kanıt (J-062 dersi).');
    say('═══════════════════════════════════════════════════════════════');
    say('');
    say('Kapsam İÇERİKTEN sürüldü — ders listesi elle yazılmadı.');
    say('canlı süreli ders : ${liveTimed.length}');
    say('kilitli ders      : ${lockedLessons.length}');
    say('');

    final List<String> failures = <String>[];

    for (final ({Course course, Lesson lesson}) e in liveTimed) {
      final Lesson l = e.lesson;
      final _AuditStore store = _AuditStore();
      final ContentRepository repo =
          ContentRepository(storeOverride: store);

      // ---- 1. AÇILIŞTAN DERSE ULAŞ -------------------------------------
      // Her ders TAZE bir ağaçta koşar: `pumpWidget` aynı tipte widget'ta
      // element ağacını yeniden kullanır ve önceki dersin Navigator yığını
      // (kurs/öğe sayfaları) ayakta kalır — ikinci derste sekmeler
      // bulunamaz. Benzersiz `key` ağacı yeniden kurar.
      await t.runAsync(() async {
        await t.pumpWidget(
            JabLabApp(key: ValueKey<String>(l.id), repository: repo, onboarding: _seen));
      });
      await settleAppLoad(t);
      await t.pumpAndSettle();

      // 2026-08-06: Sayfa A (SelectPage) zaten GİRİŞ yüzeyi — `tab-library`
      // dokunuşu kalktı. `item-boxing` artık bir sayfa PUSH etmiyor, aynı
      // sayfada satır-içi genişliyor (Hüküm 1, "az sayfa").
      await t.tap(find.byKey(const Key('item-boxing')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(Key('course-${e.course.id}')));
      await t.pumpAndSettle();
      final Finder lessonTile = find.byKey(Key('lesson-${l.id}'));
      if (lessonTile.evaluate().isEmpty) {
        failures.add('${l.id}: derse kütüphaneden ULAŞILAMADI');
        say('✗ ${l.id}: ULAŞILAMADI');
        continue;
      }
      await t.ensureVisible(lessonTile);
      await t.pumpAndSettle();
      await t.tap(lessonTile);
      await t.pumpAndSettle();

      // ---- 2. DÖRT AŞAMA ------------------------------------------------
      final bool teachOk =
          find.byKey(const Key('teach-no-analysis')).evaluate().isNotEmpty;
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pumpAndSettle();
      final bool rehearseOk =
          find.byKey(const Key('rehearse-copy')).evaluate().isNotEmpty;
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pump();

      // ---- 3. SAAT BEYAN EDİLEN YAPIYI KOŞUYOR --------------------------
      final RoundPlan? rp = l.roundPlan;
      final IntervalPlan? ip = l.intervalPlan;
      final int totalSeconds = ip?.totalSeconds ?? rp!.totalSeconds;
      final String structure = ip != null
          ? '${ip.bursts}×(${ip.burstSeconds}+${ip.recoverSeconds})sn aralık'
          : '${rp!.rounds}×${rp.roundSeconds}sn tur + '
              '${rp.rounds - 1}×${rp.restSeconds}sn dinlenme';

      final Key posKey = ip != null
          ? const Key('live-burst-position')
          : const Key('live-round-position');
      final bool multiSegment = (ip?.bursts ?? rp!.rounds) > 1;
      final bool positionShown =
          !multiSegment || find.byKey(posKey).evaluate().isNotEmpty;

      // Kamera yok → hüküm yuvası SUSUYOR ve sebebi yazılı olmalı.
      final bool noVerdictDeclared =
          find.byKey(const Key('live-no-verdict')).evaluate().isNotEmpty;

      // Seansı SONUNA kadar koştur (sanal saat). +30sn pay: son segmentin
      // BİTİŞ tiki toplamın hemen ardından düşer; tam-toplamda durmak
      // seansı "yarıda" gösteriyordu (çalışma süresi doğruydu, `_finished`
      // henüz kurulmamıştı).
      await t.pump(Duration(seconds: totalSeconds + 30));

      // ---- 4+5. ÇALIŞMA SÜRESİ ve KAYIT ---------------------------------
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pumpAndSettle();
      final bool summaryOk = find
          .byKey(const Key('coached-not-scored-note'))
          .evaluate()
          .isNotEmpty;

      final int? gate = gateSecondsOf(l.id);
      final int expectedWork =
          ip != null ? ip.workSeconds : rp!.rounds * rp.roundSeconds;

      String recordVerdict;
      if (store.written.isEmpty) {
        recordVerdict = '✗ KAYIT YOK';
        failures.add('${l.id}: seans kaydı yazılmadı');
      } else {
        final SessionRecord r = store.written.last;
        final bool workOk = r.workedSeconds == expectedWork;
        final bool gateOk = gate == null || expectedWork == gate;
        if (!workOk) {
          failures.add('${l.id}: kaydedilen çalışma ${r.workedSeconds}sn, '
              'beklenen ${expectedWork}sn');
        }
        if (!gateOk) {
          failures.add('${l.id}: çalışma ${expectedWork}sn ama kapı ${gate}sn');
        }
        recordVerdict = '${workOk ? "✓" : "✗"} kayıt '
            '${r.workedSeconds}sn çalışma · ${r.unitsCompleted}/'
            '${r.plannedUnits} segment · '
            '${r.isComplete ? "tamamlandı" : "yarıda"}';
      }

      if (!teachOk || !rehearseOk || !summaryOk) {
        failures.add('${l.id}: seans aşamaları eksik '
            '(teach=$teachOk rehearse=$rehearseOk summary=$summaryOk)');
      }
      if (!positionShown) {
        failures.add('${l.id}: çok segmentli ders ama konum göstergesi yok');
      }
      if (!noVerdictDeclared) {
        failures.add('${l.id}: kamera yok ama hüküm-susma beyanı görünmüyor');
      }

      say('── ${l.id}');
      say('   yapı        : $structure');
      say('   toplam      : ${totalSeconds}sn (${(totalSeconds / 60).toStringAsFixed(1)} dk)');
      say('   çalışma     : ${expectedWork}sn  ·  kapı: '
          '${gate == null ? "(süre kapısı yok)" : "${gate}sn"}  '
          '${gate != null && expectedWork == gate ? "✓ BİREBİR" : gate == null ? "" : "✗"}');
      say('   ulaşılabilir: ✓ kütüphane → ${e.course.id} → ders');
      say('   4 aşama     : öğret=${teachOk ? "✓" : "✗"} '
          'dene=${rehearseOk ? "✓" : "✗"} canlı=✓ özet=${summaryOk ? "✓" : "✗"}');
      say('   konum       : ${multiSegment ? (positionShown ? "✓ gösteriliyor" : "✗ YOK") : "— (tek segment)"}');
      say('   hüküm       : ${noVerdictDeclared ? "✓ SUSUYOR + sebebi yazılı" : "✗ beyan yok"}');
      say('   $recordVerdict');
      say('');
    }

    // ---- 6. KAYDEDİLEN OLGU İLERLEME SAYFASINDA GÖRÜNÜYOR --------------
    final _AuditStore progressStore = _AuditStore();
    await t.runAsync(() async {
      await t.pumpWidget(JabLabApp(
          key: const ValueKey<String>('progress-leg'),
          onboarding: _seen,
          repository: ContentRepository(storeOverride: progressStore)));
    });
    await settleAppLoad(t);
    await t.pumpAndSettle();
    // Bir seans koş, sonra kaydedilenin göründüğüne bak.
    // 2026-08-06: `tab-library` dokunuşu kalktı (Sayfa A zaten giriş
    // yüzeyi); `item-boxing` artık PUSH değil satır-içi genişleme.
    await t.tap(find.byKey(const Key('item-boxing')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('course-boxing.conditioning')));
    await t.pumpAndSettle();
    final Finder r5 = find.byKey(const Key('lesson-boxing.conditioning.r5'));
    await t.ensureVisible(r5);
    await t.pumpAndSettle();
    await t.tap(r5);
    await t.pumpAndSettle();
    for (int i = 0; i < 2; i++) {
      await t.tap(find.byKey(const Key('advance-button')));
      await t.pumpAndSettle();
    }
    await t.pump(const Duration(seconds: 330));
    await t.tap(find.byKey(const Key('advance-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('advance-button')));
    await t.pumpAndSettle();
    // Seans bitince kurs sayfası yığında kalıyor (kök: Sayfa A). Kullanıcının
    // yaptığı şeyin aynısı: geri dönmek. 2026-08-06: kalıcı bir "progress"
    // sekmesi yok artık — kayıt artık GERÇEK olduğu için (`boxing.conditioning.r5`)
    // köke dönünce `_currentCourse` bu kursu çözer ve kök doğrudan bu kursun
    // Sayfa B'sini (bant+"kaldığın yer" dahil) gösterir (Hüküm 2/3). Sınırlı
    // döngü: yığın derinliği bilinen bir sabit değil, ama sonsuz de olmamalı.
    int pops = 0;
    while (find.byKey(const Key('recorded-heading')).evaluate().isEmpty &&
        pops < 5) {
      await t.pageBack();
      await t.pumpAndSettle();
      pops++;
    }

    final bool recordedShown =
        find.byKey(const Key('recorded-heading')).evaluate().isNotEmpty;
    final bool noteShown =
        find.byKey(const Key('recorded-note')).evaluate().isNotEmpty;
    final bool judgementStillSilent = find.text('—').evaluate().isNotEmpty;
    if (!recordedShown) failures.add('ilerleme: kaydedilen bölüm görünmüyor');
    if (!noteShown) {
      failures.add('ilerleme: "kapılar açılmıyor" notu görünmüyor');
    }
    if (!judgementStillSilent) {
      failures.add('ilerleme: hüküm bantları susmuyor');
    }

    say('── ilerleme sayfası (seans sonrası)');
    say('   kaydedilen bölüm : ${recordedShown ? "✓ görünüyor" : "✗ YOK"}');
    say('   "kapı açılmıyor" : ${noteShown ? "✓ yazılı" : "✗ YOK"}');
    say('   hüküm bantları   : ${judgementStillSilent ? "✓ hâlâ SUSUYOR (—)" : "✗ konuşuyor"}');
    say('');

    // ---- KİLİTLİ DERSLER: sebep sınıfı --------------------------------
    say('── KİLİTLİ DERSLER (${lockedLessons.length}) — hepsi ÖLÇÜM sınıfı');
    for (final Lesson l in lockedLessons) {
      say('   🔒 ${l.id}');
      say('      ${l.lockedReason}');
    }
    say('');

    say('═══════════════════════════════════════════════════════════════');
    if (failures.isEmpty) {
      say('SONUÇ: ${liveTimed.length}/${liveTimed.length} canlı süreli ders '
          'uçtan uca YÜRÜDÜ.');
      say('Her dersin çalışma süresi kendi ilerleme kapısına BİREBİR eşit;');
      say('kayıt hattı kamera OLMADAN çalışıyor; hüküm yuvası susuyor ve');
      say('sebebini söylüyor. Fitness-track için kalan TEK sınıf: KAMERA.');
    } else {
      say('SONUÇ: ${failures.length} KUSUR');
      for (final String f in failures) {
        say('  ✗ $f');
      }
    }
    say('═══════════════════════════════════════════════════════════════');

    File('docs/gates/FITNESS-SHIP-KANITI.txt').writeAsStringSync(log.toString());
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

/// Bellekte tutan denetim deposu — gerçek `JsonlSessionStore` davranışı
/// `session_store_test`te sınanıyor; burada sınanan şey HATTIN BAĞLI OLDUĞU.
class _AuditStore implements SessionStore {
  final List<SessionRecord> written = <SessionRecord>[];

  @override
  Future<void> append(SessionRecord record) async => written.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async =>
      written.reversed.toList();

  /// Bellek deposu kayıp ÜRETEMEZ — sıfır bir varsayım değil, bu uygulamanın
  /// ölçülmüş gerçeği (J-092).
  @override
  Future<int> unreadableRecords() async => 0;

  @override
  Future<int> workedSecondsFor(String lessonId) async {
    int total = 0;
    for (final SessionRecord r in written) {
      if (r.lessonId == lessonId) total += r.workedSeconds;
    }
    return total;
  }
}
