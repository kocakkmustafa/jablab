import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_failure_screen.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';

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
  Future<void> pumpApp(WidgetTester t, ContentRepository repo) async {
    await t.runAsync(() async {
      await t.pumpWidget(JabLabApp(repository: repo));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
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
    //    sebebi tam bu; sekmeler arkada dursaydı kullanıcı bozuk içerikte
    //    gezinebilirdi.
    // Kabuk M3 `NavigationBar` kullanıyor — ilk yazdığımda
    // `BottomNavigationBar` aramıştım ve o iddia BEDAVAYA geçiyordu
    // (hiçbir koşulda bulunamayacak bir tip). Sekme anahtarı da ayrıca
    // aranıyor: tip adı değişse bile kapı ayakta kalsın.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('tab-library')), findsNothing);
    expect(find.byKey(const Key('today-heading')), findsNothing);

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
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('tab-library')), findsOneWidget);
  });
}
