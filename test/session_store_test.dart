import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/session_store.dart';

/// Seans geçmişi değişmezleri (J-064).
///
/// Kalıcılık Fitness vaadinin ("çalıştığını kaydet") VERİ KATMANI. Bir
/// antrenman kaydını kaybetmek, kullanıcının yaptığı işi yok saymaktır — bu
/// yüzden buradaki testler "yazıyor mu" değil, **hangi arıza altında ne
/// kaybediyoruz** sorusunu sınıyor.
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

  SessionRecord rec(
    String lesson, {
    int worked = 540,
    int rounds = 3,
    int planned = 3,
    int dayOffset = 0,
  }) =>
      SessionRecord(
        lessonId: lesson,
        completedAt: DateTime.utc(2026, 7, 30).add(Duration(days: dayOffset)),
        workedSeconds: worked,
        roundsCompleted: rounds,
        plannedRounds: planned,
      );

  test('boş depo boş liste döner — dosya yokluğu HATA DEĞİL', () async {
    // İlk açılışta dosya yok. Bunu hata sayan bir depo, kullanıcıyı ilk
    // seansından önce bir çökmeyle karşılardı.
    expect(await store.recent(), isEmpty);
    expect(await store.workedSecondsFor('x'), 0);
    expect(await file.exists(), isFalse);
  });

  test('ekleme kalıcı, okuma EN YENİ ÖNCE', () async {
    await store.append(rec('a', dayOffset: 0));
    await store.append(rec('b', dayOffset: 2));
    await store.append(rec('c', dayOffset: 1));

    final List<SessionRecord> all = await store.recent();
    expect(all.map((SessionRecord r) => r.lessonId), <String>['b', 'c', 'a']);

    // Yeni bir örnek AYNI dosyayı okur — kalıcılık bellekte değil diskte.
    final List<SessionRecord> reread =
        await JsonlSessionStore(file).recent(limit: 2);
    expect(reread.map((SessionRecord r) => r.lessonId), <String>['b', 'c']);
  });

  test('APPEND-ONLY: eski satırlar korunur, üzerine yazılmaz', () async {
    await store.append(rec('a'));
    await store.append(rec('b'));
    await store.append(rec('c'));
    final List<String> lines = (await file.readAsString())
        .split('\n')
        .where((String l) => l.trim().isNotEmpty)
        .toList();
    expect(lines.length, 3, reason: 'ekleme önceki satırları yok etti');
  });

  test('çalışma süresi ders bazında TOPLANIR', () async {
    await store.append(rec('r3', worked: 540));
    await store.append(rec('r3', worked: 300, dayOffset: 1));
    await store.append(rec('r5', worked: 300, dayOffset: 2));
    expect(await store.workedSecondsFor('r3'), 840);
    expect(await store.workedSecondsFor('r5'), 300);
    expect(await store.workedSecondsFor('yok'), 0);
  });

  test('her satır ŞEMA SÜRÜMÜNÜ taşır', () async {
    // Dosya düzeyinde tek sürüm yazmak, eski satırların hangi kurala göre
    // yazıldığını okunamaz kılar; göç günü ya tüm dosya yeniden yazılır ya
    // tahmin edilir.
    await store.append(rec('a'));
    final Map<String, dynamic> line =
        (jsonDecode((await file.readAsString()).trim()) as Map)
            .cast<String, dynamic>();
    expect(line['v'], JsonlSessionStore.schemaVersion);
    expect(line['lessonId'], 'a');
  });

  test('BİLİNMEYEN sürümlü satır ATLANIR, gerisi okunur', () async {
    // Kullanıcı uygulamayı geri de kurabilir. Gelecekten gelen bir satır
    // yüzünden tüm geçmişi okunamaz ilan etmek, veriyi kaybetmekle aynı.
    await store.append(rec('gecerli'));
    await file.writeAsString(
      '${jsonEncode(<String, dynamic>{'v': 999, 'lessonId': 'gelecek'})}\n',
      mode: FileMode.append,
    );
    final List<SessionRecord> all = await store.recent();
    expect(all.map((SessionRecord r) => r.lessonId), <String>['gecerli']);
    // ...ama SESSİZCE atlanmaz (J-092). Satır sağlam olabilir; bu sürüm onu
    // okuyamıyor — kullanıcı açısından sonuç aynı: özet eksik.
    expect(await store.unreadableRecords(), 1);
  });

  test('BOZUK satır tüm geçmişi silmez', () async {
    await store.append(rec('once'));
    await file.writeAsString('{bu geçerli json değil\n',
        mode: FileMode.append);
    await store.append(rec('sonra', dayOffset: 1));

    final List<SessionRecord> all = await store.recent();
    expect(all.map((SessionRecord r) => r.lessonId), <String>['sonra', 'once'],
        reason: 'ortadaki bozuk satır sağlam kayıtları da götürdü');
    expect(await store.unreadableRecords(), 1,
        reason: 'atlamak DOĞRU karar; atlamayı gizlemek "az yaptın" yalanı');
  });

  test('POZİTİF İKİZ: sağlam dosyada kayıp SIFIR', () async {
    // Gotcha #5: yukarıdaki "1 kayıp" iddiaları, sayaç her koşulda 1 dönse
    // de geçerdi. Bu ikiz sayacın gerçekten SAYDIĞINI kanıtlıyor.
    await store.append(rec('a'));
    await store.append(rec('b', dayOffset: 1));
    expect((await store.recent()).length, 2);
    expect(await store.unreadableRecords(), 0);
  });

  test('KAYIP SAYISI gerçekten sayılıyor — üç bozuk satır ÜÇ döner', () async {
    // Tek-bozuk testleri, sayacın "sıfırdan farklı" dönmesiyle de geçerdi;
    // eksik özetin BÜYÜKLÜĞÜ kullanıcıya söylenen cümlenin kendisi.
    await store.append(rec('saglam'));
    for (int i = 0; i < 3; i++) {
      await file.writeAsString('{bozuk-$i\n', mode: FileMode.append);
    }
    expect((await store.recent()).length, 1);
    expect(await store.unreadableRecords(), 3);
  });

  test('YARIM yazılmış son satır sağlam kayıtları götürmez', () async {
    // Mobilde işletim sistemi uygulamayı her an öldürebilir. Doğrudan
    // append sırasında ölüm, dosyanın sonunda yarım satır bırakır.
    await store.append(rec('tam'));
    await file.writeAsString('{"v":1,"lessonId":"yarim","worked',
        mode: FileMode.append);
    final List<SessionRecord> all = await store.recent();
    expect(all.map((SessionRecord r) => r.lessonId), <String>['tam']);
    expect(await store.unreadableRecords(), 1);
  });

  test('ATOMİKLİK: yazma sonrası geçici dosya KALMAZ', () async {
    await store.append(rec('a'));
    await store.append(rec('b'));
    final List<String> leftovers = tmp
        .listSync()
        .map((FileSystemEntity e) => e.path.split('/').last)
        .where((String n) => n.endsWith('.tmp'))
        .toList();
    expect(leftovers, isEmpty,
        reason: 'geçici dosya sızdı — rename yapılmamış olabilir');
    expect(await file.exists(), isTrue);
  });

  test('yarıda bırakılan seans da KAYDEDİLİR ve ayırt edilebilir', () async {
    // "Bıraktı" bir veridir, silinmesi gereken bir utanç değil.
    await store.append(rec('r20', worked: 400, rounds: 2, planned: 6));
    final SessionRecord r = (await store.recent()).single;
    expect(r.isComplete, isFalse);
    expect(r.roundsCompleted, 2);
    expect(r.plannedRounds, 6);
    expect(r.workedSeconds, 400);
  });

  test('tamamlanmış seans isComplete', () async {
    await store.append(rec('r3', rounds: 3, planned: 3));
    expect((await store.recent()).single.isComplete, isTrue);
  });

  test('zaman UTC olarak yazılır ve gidiş-dönüş korunur', () async {
    // Yerel saatle yazmak, kullanıcı saat dilimi değiştirince geçmişi
    // yeniden sıralar; "dün" birden "bugün" olur.
    await store.append(rec('a'));
    final String raw = (await file.readAsString()).trim();
    expect(raw, contains('2026-07-30T00:00:00.000Z'));
    expect((await store.recent()).single.completedAt.isUtc, isTrue);
  });
}
