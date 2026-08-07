import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/shell_candidate/shell_models.dart';

/// GEÇMİŞ RETRY'I — çalışan bir düğmeyi silinmekten koruyan kapı (J-138).
///
/// ## Neden: yorum, kodun tersini söylüyordu
///
/// `jablab_app.dart` şöyle diyordu: *"'Try again' bilerek sunulmuyor:
/// kullanıcının yapabileceği bir şey yok ve çalışmayan bir düğme, düğme
/// olmamasından kötüdür."* Gerçek render ölçtü: **düğme ekranda**,
/// `onRetryHistory` her çağrı yerinde besleniyor, ve `_refreshRecorded`
/// gerçekten yeniden okuyup başarıda beyanı kaldırıyor.
///
/// Yani J-079'un kuralı ihlal edilmiyordu — **ihlal eden şey yorumdu.** Ve
/// maliyeti somut: o satırı okuyan bir sonraki tur, **çalışan bir düğmeyi
/// "yanlışlıkla eklenmiş" sanıp silebilirdi.** Bu, bayat beyanın en pahalı
/// hâli: yanlış kayıt, doğru kodu bozmaya davet ediyor.
///
/// J-133 ölçütü: *bu davranışı yanlışa çevirecek en makul değişiklik ne?* —
/// **yorumu okuyup düğmeyi silmek.** Makul; kapı gerekli.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * **Başarıdan sonra beyanın kalkmasını** — o `_JabLabAppState` yolunda
///   (`_historyUnavailable = null`) ve zinciri `content_failure_wiring_test`
///   tarafında. Burada ölçülen şey **yüzey sözleşmesi**.
/// * Retry'ın **kaç kez** denenebileceğini ya da geri-çekilme (backoff)
///   davranışını — bugün öyle bir kural yok.
/// * Düğmenin **erişilebilirlik** hedef boyutunu.
void main() {
  const ShellLibrary library = ShellLibrary(
    title: 'JabLab',
    items: <ShellItem>[],
    exclusions: <ShellExclusion>[],
  );

  Future<void> pump(
    WidgetTester t, {
    required String? unavailable,
    VoidCallback? onRetry,
  }) async {
    await t.pumpWidget(MaterialApp(
      home: SelectPage(
        library: library,
        onOpenCourse: (_) {},
        onOpenWhyNot: () {},
        onOpenSettings: () {},
        historyUnavailable: unavailable,
        onRetryHistory: onRetry,
      ),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('geçmiş okunamıyorsa "Try again" VAR ve GERÇEKTEN çağırıyor',
      (WidgetTester t) async {
    int calls = 0;
    await pump(t,
        unavailable: 'We could not read your saved sessions on this device.',
        onRetry: () => calls++);

    final Finder retry = find.byKey(const Key('retry-history'));
    expect(retry, findsOneWidget,
        reason: 'beyan ekranda ama retry yok — yorumu okuyup düğmeyi silen '
            'tur tam bunu üretirdi (J-138)');

    await t.tap(retry);
    await t.pumpAndSettle();
    expect(calls, 1,
        reason: 'düğme çizildi ama geri çağırmadı — çalışmayan bir retry, '
            'retry olmamasından kötüdür (J-079)');
  });

  testWidgets('NEGATİF İKİZ — beyan YOKKEN ne cümle ne düğme var',
      (WidgetTester t) async {
    // İkiz olmadan yukarıdaki kapı, düğmenin HER hâlde çizilmesini de
    // geçerli sayardı: retry sürekli ekranda dururdu ve kullanıcı okunacak
    // bir sorun olmadığı hâlde bir hata varmış gibi okurdu.
    await pump(t, unavailable: null, onRetry: () {});
    expect(find.byKey(const Key('retry-history')), findsNothing,
        reason: 'sorun yokken retry çiziliyor — düğmenin varlığı, olmayan '
            'bir hatayı beyan eder');
    expect(find.textContaining('could not read'), findsNothing);
  });
}
