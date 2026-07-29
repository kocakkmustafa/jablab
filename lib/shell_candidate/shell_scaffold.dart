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
              key: Key('tab-home'), icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(
              key: Key('tab-library'),
              icon: Icon(Icons.grid_view),
              label: 'Library'),
          NavigationDestination(
              key: Key('tab-progress'),
              icon: Icon(Icons.show_chart),
              label: 'Progress'),
          NavigationDestination(
              key: Key('tab-profile'),
              icon: Icon(Icons.person_outline),
              label: 'Profile'),
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
                'Scores are shown as bands until the thresholds are calibrated '
                'on real recordings. A precise-looking number we cannot back up '
                'would be worse than no number.',
                key: const Key('bands-only-note'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ...bands.entries.map((MapEntry<String, String> e) => ListTile(
              key: Key('band-${e.key}'),
              title: Text(e.key),
              trailing: Text(e.value, style: theme.textTheme.titleSmall),
            )),
        if (recorded.isNotEmpty) ...<Widget>[
          const Divider(height: 32),
          Text('What we recorded',
              key: const Key('recorded-heading'),
              style: theme.textTheme.titleSmall),
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
          ...recorded.entries.map((MapEntry<String, String> e) => ListTile(
                key: Key('recorded-${e.key}'),
                title: Text(e.key),
                trailing: Text(e.value, style: theme.textTheme.titleSmall),
              )),
          if (recordedNote != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(recordedNote!,
                    key: const Key('recorded-note'),
                    style: theme.textTheme.bodySmall),
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
              Text('Subscription',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(freeUntil,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              const Text('Pricing is not set yet.',
                  key: Key('pricing-not-set')),
            ],
          ),
        ),
      );
}
