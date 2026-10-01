import 'package:flutter/material.dart';

import 'content_failure.dart';
import 'ui_language.dart';

/// DÜRÜST HATA EKRANI (J-079) — UI-BRIEF §4/3.
///
/// Bu ekranın işi kötü haberi YUMUŞATMAK değil, **doğru söylemek.** Ürünün
/// tamamı "ölçemediğimi söylerim" iddiası üzerine kurulu; o iddia açılış
/// ekranında çöküyorsa geri kalan her dürüstlük beyanı da inandırıcılığını
/// kaybeder. Bu yüzden burada bilinçli olarak:
///
///  * **"Yine dene" düğmesi YALNIZ işe yarayabileceği sınıfta var**
///    ([ContentFailureKind.unreadable]). Bütünlük hatasında aynı asset aynı
///    sonucu verir; orada bir retry düğmesi kullanıcıyı boşa uğraştıran bir
///    nezaket jesti olurdu — ve iki kez basınca ürünün bozuk olduğunu
///    öğrenmesi, ilk seferde dürüstçe söylenmesinden kötüdür.
///  * **"Yine de devam et" düğmesi HİÇ YOK.** Doğrulamanın bloklama sebebi
///    tam olarak kısmi/sahte bir kütüphane göstermemek. Bir kaçış kapısı,
///    doğrulamayı süs hâline getirirdi.
///  * **Geliştirici ayrıntısı GİZLENMEDİ, ikincilleştirildi.** Sahada tek
///    teşhis malzemesi o metin; ama birincil mesaj olarak kullanıcıya
///    `StateError` gövdesi göstermek (bugünkü davranış) dürüstlük değil,
///    sorumluluğu kullanıcıya devretmektir.
///  * **Suç kullanıcıya atılmıyor.** Bütünlük hatası bizim hatamızdır ve
///    ekran bunu birinci şahısla söylüyor.
///
/// Aile notu: bu ekran alan-sözlüğü İÇERMİYOR ve 5 app'in hepsinde aynı
/// probleme sahip — yani `shell_candidate/` adayı. **Terfi burada yapılmadı:**
/// ikinci tüketici görülmeden ortak katmana taşımak, kabuğu tek app'in
/// varsayımlarıyla şekillendirmek olur (SessionStore'da aynı disiplin).
class ContentFailureScreen extends StatelessWidget {
  const ContentFailureScreen({
    super.key,
    required this.failure,
    this.onRetry,
    this.onExit,
  });

  final ContentFailure failure;

  /// `null` ise yeniden deneme sunulmaz. Çağıran taraf karar verir —
  /// ekran kendi başına bir retry uydurmaz.
  final Future<void> Function()? onRetry;

  /// A pushed course route may return to its parent without exposing the
  /// rejected course. Root startup failures leave this null and stay blocked.
  final VoidCallback? onExit;

  bool get _retryable => failure.kind == ContentFailureKind.unreadable;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool tr = UiLanguage.isTurkish(context);
    return Scaffold(
      appBar: onExit == null
          ? null
          : AppBar(
              leading: BackButton(
                key: const Key('failure-exit-course'),
                onPressed: onExit,
              ),
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const SizedBox(height: 24),
            Icon(Icons.report_outlined,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              tr ? _headlineTr : _headline,
              key: const Key('failure-headline'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              tr ? _bodyTr : _body,
              key: const Key('failure-body'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            if (_retryable && onRetry != null)
              FilledButton(
                key: const Key('failure-retry'),
                onPressed: () => onRetry!(),
                child: Text(tr ? 'Tekrar dene' : 'Try again'),
              ),
            const SizedBox(height: 24),
            // Ayrıntı KATLANMIŞ: birincil mesaj insan cümlesi, ikincil
            // katman makine metni. İkisini yer değiştirmek bugünkü kusur.
            Card(
              child: ExpansionTile(
                key: const Key('failure-detail-tile'),
                title: Text(tr ? 'Teknik ayrıntı' : 'Technical detail'),
                subtitle: Text(tr
                    ? 'Sorunu bildirirken paylaşabileceğiniz bilgi'
                    : 'What to send us if you report this'),
                childrenPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: <Widget>[
                  SelectableText(
                    failure.detail.isEmpty
                        ? (tr ? '(ayrıntı bildirilmedi)' : '(no detail reported)')
                        : failure.detail,
                    key: const Key('failure-detail'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _headline => switch (failure.kind) {
        // "Bir şeyler ters gitti" DEMİYOR: o cümle hiçbir şey söylemez ve
        // kullanıcıya ne yapacağını bırakmaz.
        ContentFailureKind.integrity => 'We stopped ourselves',
        ContentFailureKind.unreadable => 'We could not read our own content',
      };

  String get _headlineTr => switch (failure.kind) {
        ContentFailureKind.integrity => 'İçeriği durdurduk',
        ContentFailureKind.unreadable => 'Uygulama içeriği okunamadı',
      };

  String get _bodyTr => switch (failure.kind) {
        ContentFailureKind.integrity =>
          'Bu sürümün paketlenmiş eğitim içeriği eksik veya bütünlük kontrollerimizden geçmedi. Güvenle sunamadığımız için içeriği göstermiyoruz. Sorun cihazınızda değil; bu bizim sürüm hatamız. Aynı dosyayı yeniden okumak sonucu değiştirmez. Düzeltme için yeni bir uygulama sürümü gerekiyor.',
        ContentFailureKind.unreadable =>
          'Eğitim içeriğini bu denemede okuyamadık. Geçici bir okuma hatası olabilir. Bir kez yeniden deneyin; sorun sürerse destek ekibine bildirin.',
      };

  String get _body => switch (failure.kind) {
        ContentFailureKind.integrity =>
          'The training content bundled with this build is missing or failed '
              'our integrity checks. We cannot vouch for it, so we do not '
              'show it. This is on us; trying again cannot change the files '
              'in this build. We need to fix it in an app update.',
        ContentFailureKind.unreadable =>
          'We could not read the training content on this attempt. It may be '
              'a temporary read error. Trying again is worth one attempt; '
              'if it continues, please contact support.',
      };
}
