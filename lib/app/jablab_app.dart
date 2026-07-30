import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jablab_engine/jablab_engine.dart';

import '../shell_candidate/library_pages.dart';
import '../shell_candidate/shell_models.dart';
import '../shell_candidate/shell_scaffold.dart';
import 'camera_harness_screen.dart';
import 'content_failure.dart';
import 'content_failure_screen.dart';
import 'content_repository.dart';
import 'session_narrator.dart';
import 'session_store.dart';
import 'session_screen.dart';

/// JabLab uygulaması — kabuğu içerikle bağlar.
class JabLabApp extends StatelessWidget {
  const JabLabApp({super.key, this.repository = const ContentRepository()});

  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JabLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB3261E), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: _Root(repository: repository),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({required this.repository});

  final ContentRepository repository;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  ShellLibrary? _library;
  CueBook? _cues;
  RuleSet? _boxing;

  /// Alan kütüphanesi de tutulur: kabuk modeli tur planını TAŞIMAZ (kabukta
  /// "round" alan sözlüğüdür, README sözleşmesi) — plan burada, app
  /// katmanında aranıp canlı ekrana verilir.
  Library? _domain;

  /// Seans geçmişi (J-064). Kurulumu async olduğu için `null` başlar; henüz
  /// gelmemişken seans açılırsa akış çalışır, yalnız o seans KAYDEDİLMEZ —
  /// açılışı bloklamak, kayıt için kullanıcıyı bekletmek olurdu.
  SessionStore? _store;

  /// KAYDEDİLEN olgu özeti (F-4). Boşken ilerleme sayfası yalnız bantları
  /// gösterir — sıfır satırlık bir "kaydedilenler" bölümü, hiç seans
  /// yapmamış kullanıcıya boş bir tablo göstermek olurdu.
  RecordedSummary? _recorded;

  /// İçerik yükleme başarısızlığı — TİPLİ (J-079). Eskiden burada ham `Object`
  /// duruyordu ve ekrana `'$_error'` basılıyordu; kullanıcı Türkçe bir
  /// `StateError` gövdesi görüyordu.
  ContentFailure? _failure;

  @override
  void initState() {
    super.initState();
    _loadContent();
    unawaited(widget.repository.openStore().then((SessionStore s) async {
      if (!mounted) return;
      setState(() => _store = s);
      await _refreshRecorded();
    }).catchError((Object e) {
      // Kalıcılık kurulamazsa uygulama ÇALIŞMAYA DEVAM EDER, yalnız kayıt
      // tutmaz. Depolama hatası yüzünden antrenmanı engellemek, çözümü
      // sorundan kötü yapardı.
      if (mounted) setState(() => _store = null);
    }));
  }

  /// İçeriği yükler. **Yeniden çağrılabilir** olması J-079'un gereği: hata
  /// ekranı yalnız `unreadable` sınıfında "Try again" sunuyor ve o düğmenin
  /// gerçekten bir şey yapması gerekiyor — çalışmayan bir retry, retry
  /// olmamasından kötüdür.
  Future<void> _loadContent() async {
    // KOŞUL ŞART: bu metod `initState`ten de çağrılıyor ve orada henüz
    // `setState` çağrılamaz (State yaşam döngüsü `created` aşamasında —
    // "setState() called in constructor"). İlk çağrıda `_failure` zaten null
    // olduğu için bu satır atlanır; yalnız RETRY yolunda çalışır.
    if (_failure != null && mounted) setState(() => _failure = null);
    try {
      final List<Object> r = await Future.wait<Object>(<Future<Object>>[
        widget.repository.load(),
        widget.repository.loadCues(),
      ]);
      if (!mounted) return;
      final ({dynamic library, dynamic boxing}) content =
          r[0] as ({dynamic library, dynamic boxing});
      setState(() {
        _domain = content.library as Library;
        _library = widget.repository.toShell(content.library);
        _boxing = content.boxing as RuleSet;
        _cues = r[1] as CueBook;
      });
    } on Object catch (e) {
      if (!mounted) return;
      // Sınıflandırma tek yerde (ContentFailure.from), ekranda DEĞİL.
      setState(() => _failure = ContentFailure.from(e));
    }
  }

  Future<void> _refreshRecorded() async {
    final SessionStore? s = _store;
    if (s == null) return;
    final RecordedSummary sum = await RecordedSummary.from(s);
    if (mounted) setState(() => _recorded = sum);
  }

  @override
  Widget build(BuildContext context) {
    final ContentFailure? failure = _failure;
    if (failure != null) {
      return ContentFailureScreen(failure: failure, onRetry: _loadContent);
    }
    final ShellLibrary? lib = _library;
    if (lib == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return ShellScaffold(
      home: _TodayPage(library: lib, onStart: (ShellLesson l) => _openSession(l)),
      library: LibraryPage(
        library: lib,
        onOpenItem: (ShellItem i) => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ItemPage(
              item: i,
              onOpenCourse: (ShellCourse c) => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => CoursePage(course: c, onStart: _openSession),
                ),
              ),
            ),
          ),
        ),
        onOpenWhyNot: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => WhyNotPage(library: lib)),
        ),
      ),
      // K8 (M-F-04): kalibrasyon kapısı geçilmeden sayısal skor YOK.
      // Bantlar SUSAR; kaydedilen OLGULAR ayrı bölümde konuşur (F-4).
      progress: ProgressPage(
        bands: const <String, String>{
          'Guard discipline': '—',
          'Punch mechanics': '—',
          'Balance': '—',
        },
        recorded: _recordedRows(),
        recordedNote: _recorded == null || _recorded!.sessions == 0
            ? null
            : 'Recorded time does not unlock lessons yet. Every progress gate '
                'also asks how much of the session the camera could actually '
                'analyse, and the camera is not connected — so these minutes '
                'are your history, not credit toward the next lesson. We would '
                'rather say that than let a number quietly mean nothing.',
      ),
      profile: const _ProfilePage(),
    );
  }

  Map<String, String> _recordedRows() {
    final RecordedSummary? r = _recorded;
    if (r == null || r.sessions == 0) return const <String, String>{};
    // Hiçbir değer ÇIPLAK SAYI değil — K8 kapısı (`shell_test`) sayfadaki
    // her metni `^\d{1,3}%?$`e karşı tarıyor. Seans sayısı bir skor DEĞİL,
    // ama kapıyı kendi rahatım için gevşetmek yerine değerleri birimiyle
    // yazıyorum: kapı sıkı kalır, cümle de daha okunur olur.
    return <String, String>{
      'Time worked': r.workedLabel,
      'Sessions': r.stoppedEarly == 0
          ? '${r.sessions} recorded'
          : '${r.sessions} recorded, ${r.stoppedEarly} stopped early',
    };
  }

  void _openSession(ShellLesson l) => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
            builder: (_) => SessionScreen(
                  lesson: l,
                  cues: _cues!,
                  coachedNotScored:
                      widget.repository.coachedNotScoredLabels(_boxing!),
                  plan: widget.repository.roundPlanFor(_domain!, l.id),
                  intervalPlan:
                      widget.repository.intervalPlanFor(_domain!, l.id),
                  store: _store,
                )),
      // Seanstan dönünce özet TAZELENİR; yoksa kullanıcı biraz önce
      // yaptığı işi ilerleme sayfasında göremez ve kaydın çalışmadığını
      // sanar (çalışıyor ama görünmüyor, en kötü kombinasyon).
      ).then((_) => _refreshRecorded());
}

class _TodayPage extends StatelessWidget {
  const _TodayPage({required this.library, required this.onStart});

  final ShellLibrary library;
  final void Function(ShellLesson) onStart;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Iterable<ShellItem> live =
        library.items.where((ShellItem i) => i.status == ItemStatus.live);
    final ShellCourse? first =
        live.isEmpty || live.first.courses.isEmpty ? null : live.first.courses.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Today',
            key: const Key('today-heading'), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (first != null)
          Card(
            child: ListTile(
              key: const Key('continue-course'),
              title: Text(first.title),
              subtitle: Text(first.lessons.first.title),
              trailing: const Icon(Icons.play_arrow),
              // 2-tık kuralı: ana sayfa → derse tek dokunuş.
              onTap: () => onStart(first.lessons.first),
            ),
          ),
      ],
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const PaywallStub(
            freeUntil:
                'The first assessment and the first course are free — you see '
                'what the coaching is actually like before anything is asked of you.',
          ),
          // DEV HARNESS girişi — YALNIZ debug derlemede (J-072). Release'de
          // bu satır hiç render edilmez: bir dev-harness'ın yayın
          // derlemesinde erişilebilir kalması, "kamera var" izlenimini
          // kullanıcıya sızdırmanın en kolay yolu olurdu (§7.8 ruhu).
          if (CameraHarnessScreen.isAvailable) ...<Widget>[
            const SizedBox(height: 24),
            const Divider(),
            Builder(
              builder: (BuildContext context) => ListTile(
                key: const Key('open-camera-harness'),
                leading: const Icon(Icons.biotech_outlined),
                title: const Text('Camera bridge — dev harness'),
                subtitle: const Text(
                    'Debug build only. Raw bridge metrics, no preview, '
                    'no judgement.'),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                      builder: (_) => const CameraHarnessScreen()),
                ),
              ),
            ),
          ],
        ],
      );
}
