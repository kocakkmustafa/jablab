import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/session_store.dart';

/// ADOPSİYON TESTLERİ — motion_core 0.11.0 (J-095).
///
/// `JsonlSessionStore`un kendi değişmezleri (append-only, atomiklik, bozuk
/// satır atlama, sürüm damgası) artık ÇEKİRDEKTE test ediliyor ve burada
/// tekrarlanmıyor: aynı iddiayı iki yerde tutmak, biri değişince diğerinin
/// sessizce bayatlaması demek.
///
/// Burada kalan tek şey **JabLab'a ÖZGÜ adopsiyon riski**: bu app'in diskinde
/// `v:1` satırlar var (kendi yazdığım şema) ve çekirdek `v:2` yazıyor. Göç
/// yanlış çalışırsa her eski kayıt "okunamadı" sayılır ve kullanıcı geçmişini
/// **kısmen kayıp** görür — yani J-092'de düzeltmek için kurduğum mekanizma
/// kendi kurbanı olur. Bu dosya tam o senaryoyu sınıyor.
void main() {
  late Directory tmp;
  late File file;
  late JsonlSessionStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('jablab-store-');
    file = File('${tmp.path}/sessions.jsonl');
    store = JsonlSessionStore(file);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// JabLab'ın 0.11.0 ÖNCESİ yazdığı satır — elle değil, o günkü şemayla.
  String v1Line(
    String lesson, {
    int worked = 540,
    int rounds = 3,
    int planned = 3,
    int day = 0,
  }) => jsonEncode(<String, dynamic>{
    'v': 1,
    'lessonId': lesson,
    'completedAt': DateTime.utc(
      2026,
      7,
      30,
    ).add(Duration(days: day)).toIso8601String(),
    'workedSeconds': worked,
    'roundsCompleted': rounds,
    'plannedRounds': planned,
  });

  group('v1 GÖÇÜ — eski kayıtlar KAYIP DEĞİL', () {
    test('v1 satırları OKUNUYOR ve kayıp SAYILMIYOR', () async {
      await file.writeAsString('${v1Line('a')}\n${v1Line('b', day: 1)}\n');

      expect(
        (await store.recent()).length,
        2,
        reason: 'eski kayıtlar okunamadı — adopsiyon geçmişi siler',
      );
      expect(
        await store.unreadableRecords(),
        0,
        reason:
            'OKUNABİLİR satırı kayıp saymak, olmayan bir kaybı '
            'uydurmaktır (aşırı-katı ikiz)',
      );
    });

    test('v1 alan eşlemesi: roundsCompleted → unitsCompleted', () async {
      await file.writeAsString('${v1Line('r6', rounds: 2, planned: 6)}\n');
      final SessionRecord r = (await store.recent()).single;
      expect(r.unitsCompleted, 2);
      expect(r.plannedUnits, 6);
      expect(
        r.isComplete,
        isFalse,
        reason: 'yarıda bırakılmış eski seans tamamlanmış görünüyor',
      );
      expect(r.workedSeconds, 540);
    });

    test('v1 kaydı PUANLI okunmaz — sınıfı yok', () async {
      // En-az-yetki (M-F-193 §3): yalnız `'scored'` puanlı okunur. Göç
      // eski kayda sınıf UYDURAMAZ; uydursaydı, kamera hiç bağlı değilken
      // yazılmış seanslar bir gün "puanlanmış" diye okunurdu.
      await file.writeAsString('${v1Line('a')}\n');
      expect((await store.recent()).single.isScoredClass, isFalse);
    });

    test('KARIŞIK dosya: v1 + v2 birlikte okunur, kayıp yok', () async {
      // Gerçek adopsiyon günü senaryosu: eski satırların üstüne yeni
      // sürümün yazması.
      await file.writeAsString('${v1Line('eski')}\n');
      await store.append(
        SessionRecord(
          lessonId: 'yeni',
          completedAt: DateTime.utc(2026, 8, 4),
          workedSeconds: 300,
          unitsCompleted: 12,
          plannedUnits: 12,
          unitLabel: 'interval',
          lessonClass: 'unscored',
        ),
      );
      expect(
        (await store.recent()).map((SessionRecord r) => r.lessonId),
        <String>['yeni', 'eski'],
        reason: 'en yeni önce sıralaması göç sonrası bozuldu',
      );
      expect(await store.unreadableRecords(), 0);
    });

    test('POZİTİF İKİZ: BİLİNMEYEN sürüm kayıp SAYILIR', () async {
      // Yukarıdaki "kayıp yok" iddiaları, sayaç her koşulda 0 dönse de
      // geçerdi. Bu ikiz sayacın gerçekten saydığını kanıtlıyor.
      await file.writeAsString(
        '${v1Line('a')}\n'
        '${jsonEncode(<String, dynamic>{'v': 999, 'lessonId': 'gelecek'})}\n',
      );
      expect((await store.recent()).length, 1);
      expect(await store.unreadableRecords(), 1);
    });
  });

  group('yüzeyin okuduğu hâl — doc-75 test asgarisi', () {
    test('temiz depo → HistoryOk (yüzey SUSAR)', () async {
      await store.append(
        SessionRecord(
          lessonId: 'a',
          completedAt: DateTime.utc(2026, 8, 4),
          workedSeconds: 540,
          unitsCompleted: 3,
          plannedUnits: 3,
          unitLabel: 'round',
          lessonClass: 'unscored',
        ),
      );
      final RecordedSummary s = await RecordedSummary.from(store);
      expect(s.status, isA<HistoryOk>());
      expect(s.sessions, 1);
    });

    test('bozuk satır → HistoryPartial(n), SAYIYLA', () async {
      // Enjeksiyon store'un KENDİ yazdığı dosyaya yapılıyor (doc-75:
      // "şema anahtarını elle yazma — gerçek yazıcıyı kullan").
      await store.append(
        SessionRecord(
          lessonId: 'a',
          completedAt: DateTime.utc(2026, 8, 4),
          workedSeconds: 540,
          unitsCompleted: 3,
          plannedUnits: 3,
          unitLabel: 'round',
          lessonClass: 'unscored',
        ),
      );
      await file.writeAsString('{bozuk-1\n{bozuk-2\n', mode: FileMode.append);

      final RecordedSummary s = await RecordedSummary.from(store);
      expect(s.status, isA<HistoryPartial>());
      expect((s.status as HistoryPartial).unreadable, 2);
      expect(s.sessions, 1, reason: 'sağlam kayıt da götürüldü');
    });

    test(
      'GEÇERLİ JSON + YANLIŞ TİP → TypeError, sağlam kayıt kaybolmaz (H-21)',
      () async {
        // H-21 sınıfı (Lissom `L-326`): dar `on FormatException` bir cast
        // TypeError'ını YAKALAMAZ (geçerli JSON + yanlış tip ⇒ ayrıştırma
        // hatası değil, tip hatası). Yukarıdaki "bozuk satır" testi
        // `jsonDecode`in KENDİSİNİ düşürüyor (`FormatException`); burası
        // FARKLI bir istisna sınıfını sınıyor — geçerli JSON ama
        // `SessionRecord.fromJson`ın `(j['workedSeconds'] as num)` cast'i
        // `TypeError` fırlatır (motion_core session_store.dart:90). Çekirdeğin
        // satır 253'teki `on Object catch (_)` (dar değil, GENİŞ) bunu da
        // yakalamalı — ölçülmeden varsayılmadı, kaynak okunup doğrulandı.
        await store.append(
          SessionRecord(
            lessonId: 'saglam',
            completedAt: DateTime.utc(2026, 8, 4),
            workedSeconds: 540,
            unitsCompleted: 3,
            plannedUnits: 3,
            unitLabel: 'round',
            lessonClass: 'unscored',
          ),
        );
        await file.writeAsString(
          '${jsonEncode(<String, dynamic>{
            'v': 2,
            'lessonId': 'yanlis-tip',
            'completedAt': DateTime.utc(2026, 8, 5).toIso8601String(),
            'workedSeconds': 'kırk', // ⚠️ sayı yerine dize — GEÇERLİ JSON, YANLIŞ TİP
            'unitsCompleted': 1,
            'plannedUnits': 1,
            'unitLabel': 'round',
            'lessonClass': 'unscored',
          })}\n',
          mode: FileMode.append,
        );

        final RecordedSummary s = await RecordedSummary.from(store);
        expect(
          s.status,
          isA<HistoryPartial>(),
          reason: 'TypeError açılışı ÇÖKERTMEMELİ ve sessizce yutulmamalı',
        );
        expect((s.status as HistoryPartial).unreadable, 1);
        expect(
          s.sessions,
          1,
          reason: 'sağlam kayıt yanlış-tip satırı yüzünden kaybolmamalı',
        );
      },
    );

    test('AÇILAMAYAN geçmiş FIRLATIR — sıfır-dolu özet DÖNMEZ', () async {
      // doc-75/2 (totals-nullable): yol var ama dosya değil. Sessizce boş
      // özet dönmek, dosya-açamamayı "0 seans, 0 dk" diye render ettirirdi.
      final Directory asFile = Directory('${tmp.path}/dizin.jsonl');
      await asFile.create();
      await expectLater(
        RecordedSummary.from(JsonlSessionStore(File(asFile.path))),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('İLK AÇILIŞ (dosya YOK) → ok/0, kayıp DEĞİL', () async {
      // "Hiç yazılmadı" ile "yazıldı ama okunamıyor" ayrı şeyler.
      final RecordedSummary s = await RecordedSummary.from(
        JsonlSessionStore(File('${tmp.path}/hic-yok.jsonl')),
      );
      expect(s.status, isA<HistoryOk>());
      expect(s.sessions, 0);
    });
  });
}
