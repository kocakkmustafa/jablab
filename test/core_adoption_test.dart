import 'dart:io' show FileSystemException;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/session_store.dart';

/// ADOPSİYON NÖBETİ — motion_core 0.11.0 (J-095, doc-75 test asgarisi).
///
/// ## Neden ayrı dosya ve neden UÇTAN UCA
///
/// doc-75 değişmez 7: **"pin bump tek başına adopsiyon DEĞİLDİR."** Çekirdek
/// arayüzü `unreadableRecords()`i zorunlu üye yaptı — ama zorunluluk
/// UYGULAYANI bağlar, KULLANANI değil. Adaptörüm o üyeyi yazıp yüzeyde hiç
/// sormasaydı her şey derlenir, bütün birim testleri geçer ve ürün eskisi
/// gibi sessiz kalırdı: *"çekirdek cevap veriyordu, yüzey bakmıyordu."*
///
/// Bu yüzden buradaki testler `RecordedSummary`yi değil **GERÇEK UYGULAMAYI**
/// sürüyor ve iki şeyi ayrı ayrı kanıtlıyor:
///   1. ürün `unreadableRecords()`i GERÇEKTEN çağırıyor (casus depo sayıyor);
///   2. yüzey `HistoryPartial`da DALLANIYOR (metin görünüyor ve SAYIYI taşıyor).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester t, SessionStore store) async {
    await t.runAsync(() async {
      await t.pumpWidget(JabLabApp(
          key: ValueKey<Object>(store),
          repository: ContentRepository(storeOverride: store)));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tab-progress')));
    await t.pumpAndSettle();
  }

  String textOf(WidgetTester t, Key k) => t.widget<Text>(find.byKey(k)).data!;

  testWidgets('① ÜRÜN unreadableRecords()i GERÇEKTEN ÇAĞIRIYOR',
      (WidgetTester t) async {
    // Değişmez 7'nin can alıcı yarısı. Bu test olmadan, çekirdeğin zorunlu
    // üyesi sessizce cevapsız kalabilir.
    final _SpyStore spy = _SpyStore(unreadable: 0, records: 1);
    await pumpApp(t, spy);
    expect(spy.unreadableAsked, greaterThan(0),
        reason: 'yüzey kayıp sayısını hiç sormadı — pin bump adopsiyon '
            'sanıldı (doc-75/7)');
  });

  testWidgets('② KISMİ: metin görünür, SAYIYI taşır ve "at least" der',
      (WidgetTester t) async {
    // "Sayıyı taşır" ayrıca sınanıyor: sabit bir cümle ("bazıları
    // okunamadı") kullanıcıya eksiğin BÜYÜKLÜĞÜNÜ vermez ve bir
    // interpolasyon kaçağı (metinde `$` unutmak) hiçbir anahtar testinde
    // görünmezdi.
    await pumpApp(t, _SpyStore(unreadable: 3, records: 2));
    final String s = textOf(t, const Key('recorded-incomplete'));
    expect(s, contains('3'), reason: 'kayıp SAYISI metne girmemiş');
    expect(s.toLowerCase(), contains('at least'),
        reason: 'kısmi hâlde toplamlar TABANDIR ve taban dili şart (doc-75/3)');
    expect(find.byKey(const Key('recorded-Time worked')), findsOneWidget,
        reason: 'kısmi hâlde sayılar GÖSTERİLİR (yalnız nitelenir)');
  });

  testWidgets('③ SIFIR UCU: ayrı metin ve "at least" İÇERMEZ',
      (WidgetTester t) async {
    // doc-75/4: okunabilir kayıt 0 iken "en az bu kadar" demek doğru ve
    // İŞE YARAMAZ — taban sıfırdır. O uç AYRI cümledir.
    await pumpApp(t, _SpyStore(unreadable: 4, records: 0));
    final String s = textOf(t, const Key('recorded-unavailable'));
    expect(s.toLowerCase(), isNot(contains('at least')));
    expect(find.byKey(const Key('recorded-incomplete')), findsNothing,
        reason: 'sıfır ucunda kısmi-dal da çizilirse ekran hem "sayı yok" '
            'hem "sayılar eksik" der');
    expect(find.byKey(const Key('recorded-Time worked')), findsNothing);
  });

  testWidgets('④ AÇILAMAMA: sayı YOK, beyan VAR', (WidgetTester t) async {
    await pumpApp(t, _ThrowingStore());
    expect(find.byKey(const Key('recorded-unavailable')), findsOneWidget);
    expect(find.byKey(const Key('recorded-Time worked')), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget,
        reason: 'geçmiş hatası BLOKLAMAZ — içerik sağlam');
  });

  testWidgets('⑤ TEMİZ HÂL İKİZİ: hiçbir beyan YOK', (WidgetTester t) async {
    // doc-75/6: koşulsuz uyaran bir yüzey yukarıdaki bütün testleri geçer.
    // Bu ikiz olmadan "her zaman uyar" kusuru görünmez.
    await pumpApp(t, _SpyStore(unreadable: 0, records: 2));
    expect(find.byKey(const Key('recorded-unavailable')), findsNothing);
    expect(find.byKey(const Key('recorded-incomplete')), findsNothing);
    expect(find.byKey(const Key('recorded-Time worked')), findsOneWidget,
        reason: 'temiz hâlde sayılar normal gösterilir');
  });

  testWidgets('⑥ HAM DETAY yüzeye SIZMIYOR', (WidgetTester t) async {
    // doc-75/5: kullanıcı metni app'in sesiyle yazılır; teşhis dizesi
    // geliştirici içindir.
    await pumpApp(t, _ThrowingStore());
    for (final Text w in t.widgetList<Text>(find.byType(Text))) {
      expect(w.data ?? '', isNot(contains('FileSystemException')));
      expect(w.data ?? '', isNot(contains('gizli-teşhis-dizesi')));
    }
  });

  // ⑦ pin eşitliği BURADA sınanmıyor: `pubspec.yaml` asset olarak
  // paketlenmediği için widget testinden okunamaz ve atlanmış bir test,
  // kapsama gibi görünen ama olmayan bir satırdır. Eşitlik
  // `dependency_pin_test.dart`ta ÇÖZÜMLENMİŞ sürümlerden sınanıyor —
  // metni değil sonucu ölçtüğü için daha güçlü.
}

/// Kayıp sayısı sorulup sorulmadığını SAYAN depo.
class _SpyStore implements SessionStore {
  _SpyStore({required this.unreadable, required int records})
      : _records = List<SessionRecord>.generate(
          records,
          (int i) => SessionRecord(
            lessonId: 'l$i',
            completedAt: DateTime.utc(2026, 8, 4).add(Duration(days: i)),
            workedSeconds: 540,
            unitsCompleted: 3,
            plannedUnits: 3,
            unitLabel: 'round',
            lessonClass: 'unscored',
          ),
        );

  final int unreadable;
  final List<SessionRecord> _records;

  /// Kaç kez soruldu — sıfır kalırsa adopsiyon YAPILMAMIŞ demektir.
  int unreadableAsked = 0;

  @override
  Future<void> append(SessionRecord record) async => _records.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => _records;

  @override
  Future<int> unreadableRecords() async {
    unreadableAsked++;
    return unreadable;
  }

  @override
  Future<int> workedSecondsFor(String lessonId) async => 0;
}

/// Okuması FIRLAYAN depo — izin hatası, bozulmuş dosya sistemi, kaybolan
/// dizin. Teşhis dizesi bilerek ayırt edilebilir yazıldı (⑥ testi).
class _ThrowingStore implements SessionStore {
  Never _boom() => throw const FileSystemException('gizli-teşhis-dizesi');

  @override
  Future<void> append(SessionRecord record) async => _boom();

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => _boom();

  @override
  Future<int> unreadableRecords() async => _boom();

  @override
  Future<int> workedSecondsFor(String lessonId) async => _boom();
}
