import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jablab_engine/jablab_engine.dart';

import '../shell_candidate/library_pages.dart';
import '../shell_candidate/shell_models.dart';
import '../shell_candidate/shell_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_harness_screen.dart';
import 'content_failure.dart';
import 'content_failure_screen.dart';
import 'content_repository.dart';
import 'live_jab_controller.dart';
import 'live_session_failure.dart';
import 'pose_model.dart';
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

  /// Geçmiş AÇILAMADI (J-092; tip artık çekirdekten — J-095).
  ///
  /// `null` iki farklı şey demek DEĞİL: burada `null` yalnız "açılma sorunu
  /// yok" demektir; "hiç kayıt yok" bilgisi [_recorded]'da yaşar. Bu ayrımı
  /// tek alana yıkmak tam da düzeltilen kusurdu.
  ///
  /// **Ayrı alan olmasının sebebi doc-75/2 (totals-nullable):** açılamayan
  /// geçmişten sayı DOĞMAZ, o yüzden bu hâlde [_recorded] hiç kurulmaz —
  /// hâl bilgisi `RecordedSummary.status` içinde taşınamaz, çünkü o nesne
  /// yoktur.
  HistoryUnavailable? _historyUnavailable;

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
      //
      // ⚠️ AMA SESSİZ KALMAZ (J-092). Eskiden yalnız `_store = null` yazıyordu
      // ve ilerleme sayfası "kaydedilenler" bölümünü hiç çizmiyordu — ekran,
      // hiç antrenman yapmamış kullanıcınınkiyle BİREBİR aynı görünüyordu.
      if (mounted) {
        setState(() {
          _store = null;
          _historyUnavailable = HistoryUnavailable(e.toString());
        });
      }
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

  /// Özeti tazeler. **Okuma hatası burada yakalanır** — eskiden yakalanmıyordu
  /// ve `_openSession(...).then(...)` yolundan gelen bir okuma hatası
  /// sahipsiz bir async hata olarak kayboluyordu: ekranda BAYAT sayılar
  /// kalıyor, kullanıcı onları güncel sanıyordu (J-092).
  Future<void> _refreshRecorded() async {
    final SessionStore? s = _store;
    if (s == null) return;
    try {
      final RecordedSummary sum = await RecordedSummary.from(s);
      if (mounted) {
        // Başarılı okuma önceki beyanı KALDIRIR: geçici bir I/O hatasından
        // sonra "geçmişini okuyamıyorum" cümlesini ekranda bırakmak, artık
        // doğru olmayan bir şeyi söylemeye devam etmek olurdu.
        setState(() {
          _recorded = sum;
          _historyUnavailable = null;
        });
      }
    } on Object catch (e) {
      // Elde BAYAT bir özet varsa onu da düşürüyoruz: yanında "okuyamadım"
      // yazan eski sayılar, iki çelişik iddiayı aynı anda göstermek olurdu.
      if (mounted) {
        setState(() {
          // doc-75/2: açılamayan geçmişten SAYI DOĞMAZ. Bayat bir özeti
          // "okuyamadım" cümlesinin yanında bırakmak iki çelişik iddiayı
          // aynı anda göstermek olurdu.
          _recorded = null;
          _historyUnavailable = HistoryUnavailable(e.toString());
        });
      }
    }
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
        historyUnavailable: _historyUnavailableText(),
        historyIncomplete: _historyIncompleteText(),
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

  /// Geçmiş HİÇ okunamadıysa gösterilecek cümle (J-092), yoksa `null`.
  ///
  /// İKİ AYRI yol buraya çıkıyor ve ikisi AYNI cümleyi hak etmiyor:
  /// dosya açılamadı (depo kurulamadı ya da okuma fırlattı) — ve dosya
  /// açıldı ama **içindeki her kayıt** okunamadı. İkincisi ilk bakışta
  /// "kısmi" görünür, oysa okunabilen sıfır kayıtla özet BOŞTUR ve boş özet
  /// ekranda "hiç yapmadın"a dönüşür: tam kapattığımız yalan, uç değerinden
  /// geri sızardı.
  ///
  /// "Try again" bilerek sunulmuyor: kullanıcının yapabileceği bir şey yok ve
  /// çalışmayan bir düğme, düğme olmamasından kötüdür (J-079 dersi).
  String? _historyUnavailableText() {
    if (_historyUnavailable != null) {
      // Ham `detail` yüzeye SIZMAZ (doc-75/5): kullanıcı metni app'in
      // sesiyle yazılır, teşhis dizesi geliştirici içindir.
      return 'We could not read your saved sessions on this device. As far as '
          'we know your training is still there — we simply cannot open the '
          'file right now, so we are not going to show you numbers we did '
          'not measure. Nothing is blocked: you can start a session as usual.';
    }
    final RecordedSummary? r = _recorded;
    if (r != null && r.sessions == 0 && r.status is HistoryPartial) {
      // ⚠️ doc-75/4: bu uçta "taban" DİLİ KULLANILMAZ. Taban sıfırken
      // "en az bu kadar" demek doğru ve işe yaramaz — o yüzden bu metin
      // `at least` TAŞIMAZ ve testte ikiziyle sınanır.
      return 'Your history file is there but none of it could be read, so we '
          'have no totals to show. This is not the same as never having '
          'trained, and we would rather say so than show you a zero. New '
          'sessions will be recorded normally.';
    }
    return null;
  }

  /// Geçmiş KISMEN okunduysa, sayıların ALT SINIR olduğunu söyleyen cümle.
  ///
  /// Okunabilen kayıt yoksa `null` döner — o durum yukarıdaki "hiç okunamadı"
  /// dalına ait; ikisi birden çizilirse bölüm hem "sayı yok" hem "sayılar
  /// eksik" der.
  String? _historyIncompleteText() {
    final RecordedSummary? r = _recorded;
    if (r == null || r.sessions == 0) return null;
    final HistoryReadStatus status = r.status;
    // Hâl-başına AYRI yol (doc-75/5): `HistoryOk` buradan HİÇBİR cümle
    // üretmez — koşulsuz uyaran bir yüzey temiz-hâl ikizini geçemez (doc-75/6).
    if (status is! HistoryPartial) return null;
    // Kayıp SAYISI metne girer: sayısız bir "bazıları okunamadı" beyanı
    // kullanıcıya eksiğin BÜYÜKLÜĞÜNÜ vermez (doc-75 test asgarisi: metin
    // testi sayıyı arar — interpolasyon-kaçağı sınıfı).
    return 'Some saved sessions could not be read (${status.unreadable} of '
        'them), so the totals below are a floor, not a full count — you did '
        'at least this much.';
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

  /// Ders kamera kullanıyorsa canlı hattı kurar (J-096).
  ///
  /// Karar İÇERİKTEN gelir (`Lesson.usesCamera`), burada bir ders kimliği
  /// listesi YOK: kodda bir `if (id == ...)` bırakmak, içerik değişince
  /// sessizce bayatlayan bir eşleme olurdu (J-047 sınıfı).
  /// Dönen çift: hat KURULDUYSA controller, KURULAMADIYSA tipli hâl.
  ///
  /// ⚠️ **Kurulum hatası dersi AÇILMAZ yapmamalı** — ilk yazışımda tam bunu
  /// yapıyordu: `materializePoseModel()` patlayınca `_openSession` hiç
  /// navigasyon yapmıyordu ve kullanıcı derse dokunuyor, hiçbir şey
  /// olmuyordu. **Sessiz çıkmaz sokak**; testler yakaladı.
  ///
  /// `null` controller + `null` hata = ders KAMERASIZ (normal hâl).
  /// `null` controller + hata = ders kameralı ama hat kurulamadı → seans
  /// yine AÇILIR, saat koşar, analiz yokluğu BEYAN EDİLİR.
  ({LiveJabController? controller, LiveSessionFailure? failure}) _liveJabFor(
      String lessonId) {
    final Library? lib = _domain;
    final RuleSet? rules = _boxing;
    if (lib == null || rules == null) {
      return (controller: null, failure: null);
    }
    if (!widget.repository.usesCamera(lib, lessonId)) {
      return (controller: null, failure: null);
    }
    try {
      return (controller: _buildLiveJab(rules), failure: null);
    } on Object catch (e) {
      return (controller: null, failure: LiveSetupFailed(e));
    }
  }

  LiveJabController _buildLiveJab(RuleSet rules) {
    return LiveJabController(
      ruleSet: rules,
      cues: _cues!,
      modelPath: widget.repository.materializePoseModel,
      modelId: PoseModelPin.modelId,
      requestPermission: () async =>
          (await Permission.camera.request()).isGranted,
      permissionPermanentlyDenied: () async =>
          await Permission.camera.isPermanentlyDenied,
    );
  }

  Future<void> _openSession(ShellLesson l) async {
    // Hat SENKRON kurulur ve model yolu GEÇ çözülür: ders açılışını 9 MB'lık
    // bir asset çıkarmasına bağlamak, kullanıcının derse dokunup hiçbir şey
    // olmamasını izlemesi demekti (testler yakaladı).
    final ({LiveJabController? controller, LiveSessionFailure? failure}) live =
        _liveJabFor(l.id);
    await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
            builder: (_) => SessionScreen(
                  lesson: l,
                  cues: _cues!,
                  coachedNotScored:
                      widget.repository.coachedNotScoredLabels(_boxing!),
                  plan: widget.repository.roundPlanFor(_domain!, l.id),
                  intervalPlan:
                      widget.repository.intervalPlanFor(_domain!, l.id),
                  // J-094: materyal kararı TEK yerde (repository), ekranda
                  // değil. Comp geldiğinde değişecek yer orası.
                  teachMaterial:
                      widget.repository.teachMaterialFor(_domain!, l.id),
                  store: _store,
                  liveJab: live.controller,
                  liveJabSetupFailure: live.failure,
                )));
    // Seanstan dönünce özet TAZELENİR; yoksa kullanıcı biraz önce yaptığı
    // işi ilerleme sayfasında göremez ve kaydın çalışmadığını sanar
    // (çalışıyor ama görünmüyor, en kötü kombinasyon).
    await _refreshRecorded();
    // Kamera hattı EKRANLA BİRLİKTE ölür; burada ayrıca kapatmak, açık
    // kalan bir oturumun sonraki dersi `already-running` ile kırmasını
    // önler (plugin tek oturuma izin veriyor).
    await live.controller?.dispose();
  }
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
