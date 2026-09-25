import 'package:flutter/material.dart';

/// Alt-sekme çatısı (standart §3): Ana · Kütüphane · İlerleme · Profil.
///
/// **2-tık kuralı** buradan doğar: ana sayfadan aktif kursa ≤2 dokunuş,
/// kütüphaneden herhangi bir kursa ≤3. Sekme sayısı bilinçli olarak dörtte
/// tutuldu — beşinci sekme, tek elle kullanımda dokunma hedefini küçültüyor.
class ShellScaffold extends StatefulWidget {
  const ShellScaffold({
    super.key,
    required this.home,
    required this.library,
    required this.progress,
    required this.profile,
  });

  final Widget home;
  final Widget library;
  final Widget progress;
  final Widget profile;

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      widget.home,
      widget.library,
      widget.progress,
      widget.profile,
    ];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            key: Key('tab-home'),
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            key: Key('tab-library'),
            icon: Icon(Icons.grid_view),
            label: 'Library',
          ),
          NavigationDestination(
            key: Key('tab-progress'),
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            key: Key('tab-profile'),
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// İlerleme sayfası iskeleti.
///
/// ⚠️ K8 aile kuralı (M-F-04): kalibrasyon kapısı geçilmeden **sayısal skor
/// gösterilmez**. Bu sayfa bu yüzden bant + eğri gösterir; [numericUnlocked]
/// false iken sayı render eden bir yol YOKTUR — kilidin UI tarafındaki
/// karşılığı budur, yoksa kural yalnız config'de kalır ve ilk ekran
/// tasarımında delinir.
class ProgressPage extends StatelessWidget {
  const ProgressPage({
    super.key,
    required this.bands,
    this.recorded = const <String, String>{},
    this.recordedNote,
    this.historyUnavailable,
    this.historyIncomplete,
    this.numericUnlocked = false,
  });

  final Map<String, String> bands;

  /// KAYDEDİLEN olgular — hüküm DEĞİL (F-4).
  ///
  /// [bands] "yargımız" bölümüdür ve kalibrasyon gelmeden susar. Bu ise
  /// "ne olduğunu kaydettik" bölümü: süre, seans sayısı gibi ölçmek için
  /// hüküm gerektirmeyen şeyler. **İkisi AYRI bölümde durur** çünkü
  /// karışırlarsa kullanıcı bir olguyu (24 dakika çalıştın) bir notla
  /// (gardın iyi) aynı otoritede okur — canlı ekrandaki anlatı/hüküm
  /// ayrımının ilerleme sayfasındaki karşılığı.
  final Map<String, String> recorded;

  /// Kaydedilenin ne İŞE YARAMADIĞINI söyleyen cümle. Boş bırakılamaz
  /// olması istenmez ama verildiğinde gösterilir: biriken süreyi görüp
  /// hiçbir şeyin açılmadığını fark eden kullanıcı, sebebini burada bulur.
  final String? recordedNote;

  /// Geçmiş HİÇ okunamadı — bölüm sayı yerine bu cümleyi gösterir (J-092).
  ///
  /// Bu alan olmadan boş [recorded] iki BAMBAŞKA durumu aynı ekrana çeviriyordu:
  /// *"henüz hiç çalışmadın"* ve *"çalıştıklarını okuyamıyorum"*. İkincisinde
  /// bölümü hiç çizmemek, kullanıcının aylarca birikmiş işini yok saymaktır.
  /// Sessizlik burada da bir cümle kurar; kurduğu cümle yanlıştır.
  ///
  /// Ostinato/Choreia karşılığı birebir aynı (terfi şartı #3): geçmiş
  /// okunamadığında "hiç çalgı çalmadın" demek de aynı yalandır.
  final String? historyUnavailable;

  /// Geçmiş KISMEN okundu — [recorded] gösterilir ama ALT SINIR olduğu
  /// söylenerek (J-092 JabLab deltası).
  ///
  /// Ayrı alan olmasının sebebi: bu bir hata bildirimi değil, gösterilen
  /// sayıların **anlamını değiştiren** bir nitelik. Cümle sayıların ALTINDA
  /// dursaydı kullanıcı toplamları önce tam sanıp sonra düzeltirdi — o yüzden
  /// başlığın hemen altında, satırlardan ÖNCE çizilir.
  final String? historyIncomplete;

  final bool numericUnlocked;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Progress', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (!numericUnlocked)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Scores are unavailable because the thresholds have not been '
                'calibrated on real recordings. A precise-looking number we '
                'cannot back up would be worse than no number.',
                key: const Key('bands-only-note'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ...bands.entries.map(
          (MapEntry<String, String> e) => ListTile(
            key: Key('band-${e.key}'),
            title: Text(e.key),
            trailing: Text(e.value, style: theme.textTheme.titleSmall),
          ),
        ),
        // Geçmiş okunamadığında bölüm YİNE çizilir — sayısız. Onu gizlemek,
        // hiç çalışmamış kullanıcının ekranıyla aynı şeyi göstermek olurdu.
        if (historyUnavailable != null) ...<Widget>[
          const Divider(height: 32),
          Text(
            'What we recorded',
            key: const Key('recorded-heading'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              historyUnavailable!,
              key: const Key('recorded-unavailable'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ] else if (recorded.isNotEmpty) ...<Widget>[
          const Divider(height: 32),
          Text(
            'What we recorded',
            key: const Key('recorded-heading'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'These are measurements, not marks. Nothing here is a judgement '
              'about how well you moved.',
              key: const Key('recorded-vs-judged-note'),
              style: theme.textTheme.bodySmall,
            ),
          ),
          // Nitelik satırlardan ÖNCE: toplamlar okunmadan önce eksik oldukları
          // bilinmeli.
          //
          // ⚠️ Boşluk simülatörde eklendi (J-092): testler yeşilken ekranda bu
          // paragraf üstündeki "ölçüm, not değil" cümlesine YAPIŞIK duruyordu
          // ve ikisi tek blok gibi okunuyordu — ayrı bir uyarı olduğu
          // kaybolmuştu. Widget testi iki metnin varlığını görür, aralarındaki
          // mesafeyi görmez (Gravita G-100 dersinin aynısı).
          if (historyIncomplete != null) ...<Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                historyIncomplete!,
                key: const Key('recorded-incomplete'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          ...recorded.entries.map(
            (MapEntry<String, String> e) => ListTile(
              key: Key('recorded-${e.key}'),
              title: Text(e.key),
              trailing: Text(e.value, style: theme.textTheme.titleSmall),
            ),
          ),
          if (recordedNote != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  recordedNote!,
                  key: const Key('recorded-note'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Paywall iskeleti — fiyat KURUCU kararıdır, burada sabit yazılmaz.
class PaywallStub extends StatelessWidget {
  const PaywallStub({super.key, required this.freeUntil});

  /// Ücretsiz çekirdeğin nerede bittiğini anlatan tek cümle.
  final String freeUntil;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Subscription', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(freeUntil, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          const Text('Pricing is not set yet.', key: Key('pricing-not-set')),
        ],
      ),
    ),
  );
}
