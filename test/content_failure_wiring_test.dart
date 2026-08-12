import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_failure_screen.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_store.dart';

import 'app_pump.dart';

/// BAĞLANTI testi (J-079): bozuk içerik GERÇEKTEN dürüst hata ekranını açıyor
/// mu?
///
/// `content_failure_test.dart` ekranı tek başına sınıyor; bu dosya ZİNCİRİ
/// sınıyor: **bozuk asset → tipli fırlatma → sınıflandırma → ekran.** İkisi
/// ayrı test: ekran kusursuz olup `_Root` onu hiç göstermiyor olabilirdi ve
/// bileşen testleri bunu göremezdi.
///
/// İlk deneme `flutter/assets` kanalını taklit etmekti ve **ölçülerek
/// bırakıldı:** o kanal yalnız bizim üç asset'imizi değil framework'ün
/// istediği her şeyi (font/manifest) taşıyor; hepsini dosyadan servis etmeye
/// çalışan taklit uygulamayı sonsuz yükleme hâlinde bırakıyordu. Onun yerine
/// `ContentRepository.loadStringOverride` dikişi kullanılıyor —
/// `storeOverride`'ın kurduğu emsal: tek yerde okunan dar bir kanca.
/// KARŞILAMA ATLANIYOR (J-106). Bu dosyanın sınadığı şey karşılama DEĞİL;
/// gerçek bayrağı okumak her testi "ilk açılış" hâline sokup kabuğa hiç
/// ulaştırmazdı. `seenOverride` üretimde `null` — bu yalnız bir test dikişi.
const OnboardingStore _seen = OnboardingStore(seenOverride: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Kütüphaneyi DÜRÜSTLÜK DENETİMİNİ bozacak şekilde değiştirir: bir derse
  /// kural setinde bulunmayan bir tekniğe atıf eklenir (library.json'ın kendi
  /// 3. kuralı). Bu, gerçek bir bozuk içerik güncellemesinin en olası hâli —
  /// testleri atlayıp cihaza ulaşan bir asset.
  Future<String> brokenLibraryLoader(String key) async {
    final String raw = await rootBundle.loadString(key);
    if (key != ContentRepository.libraryAsset) return raw;
    final Map<String, dynamic> j =
        (jsonDecode(raw) as Map).cast<String, dynamic>();
    final Map<String, dynamic> discipline =
        ((j['disciplines'] as List).first as Map).cast<String, dynamic>();
    final Map<String, dynamic> course =
        ((discipline['courses'] as List).first as Map).cast<String, dynamic>();
    final Map<String, dynamic> lesson =
        ((course['lessons'] as List).first as Map).cast<String, dynamic>();
    lesson['techniques'] = <String>['spinning_backfist_that_does_not_exist'];
    return jsonEncode(j);
  }

  /// Asset yüklemesi gerçek async I/O'dur; widget testinin sanal saati onu
  /// ilerletmez (shell_test'teki aynı gerekçe).
  ///
  /// ## ⚠️ SABİT GECİKME KALDIRILDI — bu test KARARSIZDI (J-218)
  ///
  /// Önceki hâli `runAsync` içinde **sabit 200 ms** bekliyordu. Süit tek
  /// başına koşarken yetiyordu; **paralel yük altında yetmedi** ve bu test
  /// 2026-08-12'de bir commit'i **yanlış yere** durdurdu (değişiklik tek bir
  /// markdown dosyasıydı). İzole koşumda 4/4, tam süitte 315/315 — yani
  /// başarısızlık **gerçek bir kusuru değil, zamanlamayı** ölçüyordu.
  ///
  /// > ***Kararsız bir kapı, YEŞİL de KIRMIZI da bilgi taşımaz hâle
  /// > getirir*** — ve en tehlikelisi, kararsızlık bir kez kabul edilince
  /// > **her kırmızı için bir mazeret** doğması.
  ///
  /// Panzehir, bu turda `reachable_screens_test`te kurulanla aynı:
  /// **sabit süre değil, GERÇEK bir durum değişikliği beklenir** — burada
  /// yükleme göstergesinin kaybolması (`_Root` içerik ya da hata gelene
  /// kadar `CircularProgressIndicator` çiziyor, `jablab_app.dart:283`).
  /// Sınırlı (≈2 s): takılan bir yükleme sessizce beklemez, `pumpAndSettle`
  /// sonsuz animasyonda zaten patlar.
  Future<void> pumpApp(WidgetTester t, ContentRepository repo) async {
    await t.runAsync(() async {
      await t.pumpWidget(JabLabApp(repository: repo, onboarding: _seen));
    });
    await settleAppLoad(t);
    await t.pumpAndSettle();
  }

  testWidgets('bozuk kütüphane → DÜRÜST HATA EKRANI (kütüphane DEĞİL)',
      (WidgetTester t) async {
    await pumpApp(
        t, ContentRepository(loadStringOverride: brokenLibraryLoader));

    // 1. Dürüst hata ekranı açıldı.
    expect(find.byType(ContentFailureScreen), findsOneWidget);

    // 2. BÜTÜNLÜK sınıfı: "Try again" YOK (aynı asset aynı sonucu verir).
    expect(find.byKey(const Key('failure-retry')), findsNothing,
        reason: 'bütünlük hatasında retry sunmak kullanıcıyı boşa uğraştırır');

    // 3. Suç bizde ve metin bunu söylüyor.
    expect(
        t
            .widget<Text>(find.byKey(const Key('failure-body')))
            .data!
            .toLowerCase(),
        contains('on us'));

    // 4. EN ÖNEMLİSİ: kısmi kütüphane RENDER EDİLMEDİ. Doğrulamanın bloklama
    //    sebebi tam bu; kabuk arkada dursaydı kullanıcı bozuk içerikte
    //    gezinebilirdi.
    // 2026-08-06: kabuk 4-sekme `NavigationBar`dan 3-sayfa+köşe yapısına
    // geçti (Hüküm 1) — o yapının GİRİŞ yüzeyi `SelectPage`. İlk yazdığımda
    // `BottomNavigationBar` aramıştım ve o iddia BEDAVAYA geçiyordu (hiçbir
    // koşulda bulunamayacak bir tip); aynı gotcha'ya bir daha düşmemek için
    // hem TİP hem anahtar burada da ayrı ayrı aranıyor.
    expect(find.byType(SelectPage), findsNothing);
    expect(find.byKey(const Key('item-boxing')), findsNothing);

    // 5. Ayrıntı ihlali TAŞIYOR — sahada teşhis edilebilsin.
    await t.tap(find.byKey(const Key('failure-detail-tile')));
    await t.pumpAndSettle();
    expect(
        t.widget<SelectableText>(find.byKey(const Key('failure-detail'))).data,
        contains('spinning_backfist_that_does_not_exist'),
        reason: 'ihlal metni kaybolursa saha teşhisi imkânsız');
  });

  testWidgets('SAĞLAM içerikle hata ekranı HİÇ açılmaz (yanlış-pozitif kapısı)',
      (WidgetTester t) async {
    // Yukarıdaki test, ekranı HER koşulda açan bir kusuru da "geçti"
    // sayabilirdi.
    await pumpApp(t, const ContentRepository());
    expect(find.byType(ContentFailureScreen), findsNothing);
    // Kabuğun açıldığına POZİTİF kanıt: "hâlâ yükleniyor" hâli bu testi
    // sessizce geçemesin (test 1'in tam simetriği).
    expect(find.byType(SelectPage), findsOneWidget);
    expect(find.byKey(const Key('item-boxing')), findsOneWidget);
  });

  /// ⭐ J-092 ZİNCİRİ — geçmiş okunamıyor, ama İÇERİK sağlam.
  ///
  /// `progress_recorded_test` bölümü tek başına sınıyor; burada sınanan şey
  /// HATTIN BAĞLI OLDUĞU: depo fırlatıyor → `_refreshRecorded` yakalıyor →
  /// `HistoryFailure` → ilerleme sekmesi beyan ediyor. Bileşen kusursuz olup
  /// `_Root` onu hiç beslemiyor olabilirdi ve bileşen testi bunu göremezdi
  /// (aynı gerekçe: J-079 zinciri).
  group('⭐ J-092 zinciri', () {
    // 2026-08-06: eskiden `tab-progress`e dokunuyordu (kalıcı sekme). O
    // sekme kalktı — geçmiş TAMAMEN okunamazsa (aşağıdaki `_ThrowingStore`)
    // hangi kursun "güncel" olduğu hiç bilinemez (Hüküm 3), dolayısıyla
    // beyan artık Sayfa A'nın kendi banner'ında görünüyor; ek dokunuş
    // gerekmiyor.
    Future<void> openProgress(WidgetTester t, ContentRepository repo) =>
        pumpApp(t, repo);

    testWidgets('depo okuması FIRLATIRSA Sayfa A BEYAN ediyor',
        (WidgetTester t) async {
      await openProgress(
          t, ContentRepository(storeOverride: _ThrowingStore()));

      // İçerik sağlam → bloklanmadı: kabuk ayakta, dersler açılabilir.
      expect(find.byType(SelectPage), findsOneWidget);
      // ...ama sessiz de değil.
      expect(find.byKey(const Key('recorded-unavailable')), findsOneWidget);
      expect(find.byType(ContentFailureScreen), findsNothing,
          reason: 'depolama hatası yüzünden antrenmanı engellemek, çözümü '
              'sorundan kötü yapardı — bu sınıf BLOKLAMAZ');
    });

    testWidgets('POZİTİF İKİZ: depo SAĞLAMKEN beyan hiç çizilmiyor',
        (WidgetTester t) async {
      // Yukarıdaki test, beyanı HER koşulda çizen bir kusuru da "geçti"
      // sayardı.
      //
      // ⚠️ İkiz ÇALIŞAN bir depo enjekte etmek ZORUNDA: varsayılan
      // `ContentRepository` burada `getApplicationSupportDirectory()`e gider
      // ve widget testinde `path_provider` eklentisi yoktur — yani varsayılan
      // depo test ortamında GERÇEKTEN açılamıyor ve beyan HAKLI olarak
      // çıkıyor. İlk yazdığımda ikizi varsayılanla kurmuştum ve test düştü;
      // düşme sebebi kusur değil, hattın çalıştığının kanıtıydı.
      await openProgress(t, ContentRepository(storeOverride: _WorkingStore()));
      expect(find.byKey(const Key('recorded-unavailable')), findsNothing);
      // `_WorkingStore` BOŞ (kayıt yok) → güncel kurs çözülmez → giriş
      // Sayfa A'dır (Hüküm 3) ve K8 bant bloğu burada değil, bir kursta
      // gösterilir — bu yüzden pozitif kanıt artık `bands-only-note` değil,
      // Sayfa A'nın gerçekten açıldığının kendisi.
      expect(find.byType(SelectPage), findsOneWidget,
          reason: 'seçim ekranının gerçekten açıldığına pozitif kanıt');
      expect(find.byKey(const Key('item-boxing')), findsOneWidget);
    });
  });
}

/// Sorunsuz çalışan boş depo — ikizin "beyan yok" iddiasının anlamlı olması
/// için hattın diğer ucunun GERÇEKTEN sağlam olması gerekiyor.
class _WorkingStore implements SessionStore {
  final List<SessionRecord> _all = <SessionRecord>[];

  @override
  Future<void> append(SessionRecord record) async => _all.add(record);

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => _all;

  @override
  Future<int> unreadableRecords() async => 0;

  @override
  Future<int> workedSecondsFor(String lessonId) async => 0;
}

/// Okuması FIRLAYAN depo — gerçek sahada karşılığı: izin hatası, bozulmuş
/// dosya sistemi, `path_provider`ın döndürdüğü dizinin kaybolması.
class _ThrowingStore implements SessionStore {
  @override
  Future<void> append(SessionRecord record) async =>
      throw const FileSystemException('append');

  @override
  Future<List<SessionRecord>> recent({int? limit}) async =>
      throw const FileSystemException('recent');

  @override
  Future<int> unreadableRecords() async =>
      throw const FileSystemException('unreadableRecords');

  @override
  Future<int> workedSecondsFor(String lessonId) async =>
      throw const FileSystemException('workedSecondsFor');
}
