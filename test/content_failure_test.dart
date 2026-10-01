import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_failure.dart';
import 'package:jablab/app/content_failure_screen.dart';
import 'package:motion_content/motion_content.dart';

/// DÜRÜST HATA EKRANI değişmezleri (J-079) — UI-BRIEF §4/3.
///
/// Buradaki testler estetik değil, İDDİA sınırını koruyor: bu ürünün tamamı
/// "ölçemediğimi söylerim" vaadine dayanıyor ve o vaat açılış ekranında
/// çökerse geri kalan her dürüstlük beyanı inandırıcılığını kaybeder.
void main() {
  group('sınıflandırma tek yerde yapılır (ekran yorum yapmaz)', () {
    test('ContentIntegrityException → integrity, ihlaller ayrıntıya taşınır',
        () {
      final ContentFailure f = ContentFailure.from(
          const ContentIntegrityException(<String>['a bozuk', 'b eksik']));
      expect(f.kind, ContentFailureKind.integrity);
      expect(f.detail, contains('a bozuk'));
      expect(f.detail, contains('b eksik'));
    });

    test('motor tarafı StateError/ArgumentError da BÜTÜNLÜK sayılır', () {
      // Replik eşlemesi, kural seti ve eklem etiketleri tutarsızlığı bu iki
      // tiple bildiriyor. Dosya OKUNDU, içeriği tutmuyor → integrity.
      expect(ContentFailure.from(StateError('replik yok')).kind,
          ContentFailureKind.integrity);
      expect(ContentFailure.from(ArgumentError('eşleşmeyen anahtar')).kind,
          ContentFailureKind.integrity);
    });

    test('paket içi eksik varlık bütünlük; geçici erişim okunamazdır', () {
      for (final ContentErrorCode code in <ContentErrorCode>[
        ContentErrorCode.missingAsset,
        ContentErrorCode.schema,
        ContentErrorCode.hashMismatch,
      ]) {
        expect(
          ContentFailure.from(ContentException(ContentError(code: code))).kind,
          ContentFailureKind.integrity,
          reason: '$code: aynı paket tekrar denenince değişmez',
        );
      }
      for (final ContentErrorCode code in <ContentErrorCode>[
        ContentErrorCode.timeout,
        ContentErrorCode.io,
      ]) {
        expect(
          ContentFailure.from(ContentException(ContentError(code: code))).kind,
          ContentFailureKind.unreadable,
          reason: '$code: geçici erişim hatası yeniden denenebilir',
        );
      }
    });

    test('BİLİNMEYEN hata tipi unreadable tarafına düşer', () {
      // Yanlış tarafa düşmek gerekiyorsa: "bir kez yeniden dene" demek,
      // "bu bizim içerik hatamız" demekten daha az yanlış — ikincisi
      // kullanıcıya bizim adımıza teşhis koyar.
      expect(ContentFailure.from(const FormatException('bozuk JSON')).kind,
          ContentFailureKind.unreadable);
      expect(ContentFailure.from('düz bir string').kind,
          ContentFailureKind.unreadable);
    });
  });

  Future<void> pump(WidgetTester t, ContentFailure f,
          {Future<void> Function()? onRetry}) async =>
      t.pumpWidget(MaterialApp(
          home: ContentFailureScreen(failure: f, onRetry: onRetry)));

  const ContentFailure integrity = ContentFailure(
      kind: ContentFailureKind.integrity, detail: 'lesson X refers to hook');
  const ContentFailure unreadable = ContentFailure(
      kind: ContentFailureKind.unreadable, detail: 'asset not found');

  testWidgets('BÜTÜNLÜK hatasında "Try again" SUNULMAZ', (WidgetTester t) async {
    // Aynı asset aynı sonucu verir. Orada bir retry düğmesi, kullanıcıyı
    // boşa uğraştıran bir nezaket jesti olur.
    await pump(t, integrity, onRetry: () async {});
    expect(find.byKey(const Key('failure-retry')), findsNothing);
  });

  testWidgets('OKUNAMAZ hatasında "Try again" VAR ve GERÇEKTEN çağırıyor',
      (WidgetTester t) async {
    int calls = 0;
    await pump(t, unreadable, onRetry: () async => calls++);
    await t.tap(find.byKey(const Key('failure-retry')));
    await t.pump();
    expect(calls, 1, reason: 'çalışmayan bir retry, retry olmamasından kötü');
  });

  /// YAPISAL KAÇIŞ-KAPISI KAPISI (J-139).
  ///
  /// Sınır zaten korunuyordu — ama **kelime listesiyle** (`Continue` · `Skip`
  /// · `Ignore` · `Dismiss`). O liste ilk yeni ada karşı kör: *"Use offline
  /// copy"*, *"Show what loaded"*, *"Proceed"* hiçbirini yakalamaz — J-124
  /// `unlock` kapısının beyan edilmiş kör noktasının aynısı.
  ///
  /// Bu iki test aynı sınırı **yapıyla** ölçüyor: ekranda retry DIŞINDA
  /// düğme yok. Kelime listesi kalıyor (ucuz ve okunur bir belge), yapı onu
  /// **kapsıyor**.
  ///
  /// ⚠️ NE ÖLÇMÜYOR: ① düğme olmayan kaçış yolu (metne gömülü link, geri
  /// jesti) ② ayrıntı katmanının açılabilirliği — o bir kaçış değil ③ aynı
  /// sınırın beyan edildiği diğer iki yeri (`live_session_failure` ·
  /// `session_screen`); onlar ayrı ekranlar ve ayrı kapı ister.
  ///
  /// İki AYRI test: tek gövdede iki kez `pumpWidget` çağırmak bu koşumda
  /// ikinci ağacı güvenilir kurmuyor — bu gecenin `pumpLive` dersinin aynısı.
  testWidgets('BÜTÜNLÜK ekranında HİÇ düğme yok', (WidgetTester t) async {
    await pump(t, integrity, onRetry: () async {});
    await t.pumpAndSettle();
    // `find.byType` ALT SINIFLARI eşleştirmez (tam runtimeType karşılaştırır)
    // — `FilledButton`ı `ButtonStyleButton` diye aramak HER ZAMAN sıfır
    // döndürür ve bu test VAKUM-DOĞRU geçerdi. Ölçüldü: aşağıdaki pozitif
    // ikiz (1 bekleyen) bozuk aracı ifşa etti. Predicate şart.
    expect(find.byWidgetPredicate((Widget w) => w is ButtonStyleButton),
        findsNothing,
        reason: 'bütünlük hatasında düğme çıktı — retry burada zaten '
            'yasak (aynı asset aynı sonucu verir) ve başka her düğme bir '
            'KAÇIŞ KAPISI olur: doğrulama süs hâline gelir (J-139)');
  });

  testWidgets('OKUNAMAZ ekranında TEK düğme var ve o retry',
      (WidgetTester t) async {
    await pump(t, unreadable, onRetry: () async {});
    await t.pumpAndSettle();
    final Finder buttons =
        find.byWidgetPredicate((Widget w) => w is ButtonStyleButton);
    expect(buttons, findsOneWidget,
        reason: 'okunamaz ekranında beklenen 1 düğme yok/fazla — ikinci bir '
            'düğme ne olursa olsun bir kaçış kapısıdır (J-139)');
    expect(find.byKey(const Key('failure-retry')), findsOneWidget,
        reason: 'tek düğme var ama retry DEĞİL — sayı doğru, kimlik yanlış');
  });

  testWidgets('onRetry verilmezse düğme UYDURULMAZ', (WidgetTester t) async {
    await pump(t, unreadable);
    expect(find.byKey(const Key('failure-retry')), findsNothing);
  });

  testWidgets('"Yine de devam et" kaçış kapısı HİÇ YOK',
      (WidgetTester t) async {
    // Doğrulamanın bloklama sebebi tam olarak kısmi/sahte bir kütüphane
    // göstermemek. Bir kaçış kapısı doğrulamayı süs hâline getirirdi.
    for (final ContentFailure f in <ContentFailure>[integrity, unreadable]) {
      await pump(t, f, onRetry: () async {});
      for (final String banned in <String>[
        'Continue',
        'continue anyway',
        'Skip',
        'Ignore',
        'Dismiss',
      ]) {
        expect(find.textContaining(banned), findsNothing,
            reason: '"$banned" bir kaçış kapısı sunuyor');
      }
    }
  });

  testWidgets('geliştirici ayrıntısı GİZLENMEZ ama İKİNCİLDİR',
      (WidgetTester t) async {
    await pump(t, integrity);
    // Ayrıntı ekranda VAR (sahada tek teşhis malzemesi)...
    expect(find.byKey(const Key('failure-detail-tile')), findsOneWidget);
    // ...ama katlanmış: açılmadan görünmüyor.
    expect(find.byKey(const Key('failure-detail')), findsNothing);
    await t.tap(find.byKey(const Key('failure-detail-tile')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('failure-detail')), findsOneWidget);
    expect(
        t.widget<SelectableText>(find.byKey(const Key('failure-detail'))).data,
        contains('lesson X refers to hook'));
  });

  testWidgets('BİRİNCİL metin makine metni DEĞİL — istisna gövdesi sızmaz',
      (WidgetTester t) async {
    // Bugünkü kusur tam buydu: ekran `'$_error'` basıyordu, yani kullanıcı
    // `StateError` gövdesi görüyordu.
    await pump(t, integrity);
    final String headline =
        t.widget<Text>(find.byKey(const Key('failure-headline'))).data!;
    final String body =
        t.widget<Text>(find.byKey(const Key('failure-body'))).data!;
    for (final String leak in <String>[
      'StateError',
      'Exception',
      'ContentIntegrityException',
      'lesson X refers to hook', // ayrıntının kendisi de birincil olamaz
    ]) {
      expect(headline, isNot(contains(leak)));
      expect(body, isNot(contains(leak)));
    }
    // Ve "bir şeyler ters gitti" boşluğu da kabul değil: metin ne olduğunu
    // ve kimin hatası olduğunu SÖYLEMEK zorunda.
    expect(body.length, greaterThan(80));
    expect(body.toLowerCase(), contains('on us'),
        reason: 'bütünlük hatası bizim hatamız — suç kullanıcıya atılamaz');
  });

  testWidgets('OKUNAMAZ metni bir yeniden deneme önerir, paket teşhisi koymaz',
      (WidgetTester t) async {
    await pump(t, unreadable);
    final String body =
        t.widget<Text>(find.byKey(const Key('failure-body'))).data!;
    expect(body.toLowerCase(), contains('trying again'));
    expect(body.toLowerCase(), contains('contact support'));
    // Bu sınıfta içeriğin YANLIŞ olduğunu iddia etmiyoruz — okunamadı.
    expect(body.toLowerCase(), isNot(contains('honesty check')));
  });

  testWidgets('K8: hata ekranında ÇIPLAK SAYI yok', (WidgetTester t) async {
    // Kalibrasyonsuz sayı yasağı (M-F-04) bu ekranda da geçerli; bir hata
    // ekranı "3 ihlal" diye sayı basmaya en yatkın yerdir.
    await pump(t, integrity, onRetry: () async {});
    final RegExp bare = RegExp(r'^\d{1,3}%?$');
    for (final Element e in find.byType(Text).evaluate()) {
      final String? d = (e.widget as Text).data;
      if (d != null) expect(bare.hasMatch(d.trim()), isFalse, reason: d);
    }
  });
}
