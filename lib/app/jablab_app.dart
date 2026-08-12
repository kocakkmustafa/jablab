import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jablab_engine/jablab_engine.dart';

import '../shell_candidate/library_pages.dart' show WhyNotPage;
import '../shell_candidate/shell_models.dart';
import 'package:permission_handler/permission_handler.dart';

import 'content_failure.dart';
import 'content_failure_screen.dart';
import 'content_repository.dart';
import 'course_page.dart';
import 'live_jab_controller.dart';
import 'live_session_failure.dart';
import 'onboarding_page.dart';
import 'onboarding_store.dart';
import 'progress_gates.dart';
import 'pose_model.dart';
import 'select_page.dart';
import 'session_narrator.dart';
import 'session_store.dart';
import 'session_screen.dart';
import 'settings_page.dart';

/// JabLab uygulaması — kabuğu içerikle bağlar.
class JabLabApp extends StatelessWidget {
  const JabLabApp({
    super.key,
    this.repository = const ContentRepository(),
    this.onboarding = const OnboardingStore(),
    this.navigatorObservers = const <NavigatorObserver>[],
  });

  final ContentRepository repository;

  /// "Karşılama görüldü mü" bayrağı (J-106). Enjekte ediliyor ki testler
  /// gerçek dosya sistemine dokunmadan İKİ yolu da (ilk açılış / dönen
  /// kullanıcı) koşturabilsin.
  final OnboardingStore onboarding;

  /// GEZİLEBİLİRLİK TANIĞI için dikiş (J-240, sözleşme maddesi **(b)**).
  ///
  /// Sözleşme *"üyelik YÜRÜYEREK kanıtlanır — `NavigatorObserver`
  /// tanıklığıyla"* diyor. Tanık ancak `MaterialApp`e bağlanabilir ve
  /// `MaterialApp` burada kuruluyor; dışarıdan sarmalanamaz. Üretimde
  /// **boş liste** — `repository`/`onboarding` ile aynı emsal: dikiş TEK
  /// yerde, üretim davranışı değişmiyor.
  ///
  /// ⚠️ Bu alan bir KOLAYLIK değil, ölçümün ön koşulu: tanıksız bir yürüyüş
  /// *"vardım"* diyebilir ama **NASIL vardığını** söyleyemez — ve bu ağaçta
  /// varışların bir kısmı `push` DEĞİL (karşılama→seçim aynı kökte
  /// `setState` ile takas ediliyor). Ayrımı yalnız tanık görür.
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JabLab',
      debugShowCheckedModeBanner: false,
      navigatorObservers: navigatorObservers,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB3261E), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: _Root(repository: repository, onboarding: onboarding),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({required this.repository, required this.onboarding});

  final ContentRepository repository;
  final OnboardingStore onboarding;

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

  /// En son tamamlanan seansın ders kimliği — "kaldığın yer"in hedefi ve
  /// "güncel kurs" (Hüküm 3, koordinatör 2026-08-06) buradan türetilir.
  /// `_recorded` gibi bu da `_refreshRecorded()`te tazelenir; ayrı alan
  /// olmasının sebebi `RecordedSummary`nin toplu bir özet olması — hangi
  /// DERSTE olduğumuzu taşımaz, yalnız KAÇ seans/saniye taşır.
  String? _lastLessonId;

  /// İçerik yükleme başarısızlığı — TİPLİ (J-079). Eskiden burada ham `Object`
  /// duruyordu ve ekrana `'$_error'` basılıyordu; kullanıcı Türkçe bir
  /// `StateError` gövdesi görüyordu.
  ContentFailure? _failure;

  /// İlerleme kapıları (J-208). `null` = henüz yüklenmedi. Yükleme
  /// BAŞARISIZ olursa da `null` kalır ve kapı beyanı hiç çizilmez —
  /// yüklenemeyen bir dosyadan hüküm doğmaz, ve bir kapı beyanı uğruna
  /// dersin açılışını bloklamak çözümü sorundan kötü yapardı.
  Map<String, dynamic>? _curriculum;

  /// Karşılama gösterilecek mi (J-106). **`null` = HENÜZ BİLİNMİYOR** ve bu
  /// üçüncü hâl şart: `false` başlatmak, bayrak diskten okunana kadar geçen
  /// bir karelik pencerede kabuğu gösterir, sonra karşılamayı üstüne
  /// açardı — ilk açılışta ekran zıplaması. "Bilmiyorum" ile "hayır" ayrımı,
  /// bu depoda `HistoryUnavailable` ve `LiveJabStarting` ile aynı ilke.
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _loadContent();
    unawaited(widget.repository.loadCurriculum().then((Map<String, dynamic> c) {
      if (mounted) setState(() => _curriculum = c);
    }).catchError((Object _) {
      // Bilerek yutuluyor: kapı beyanı bir EK bilgidir, ürünün çalışması
      // ona bağlı değil. Sessizlik burada güvenli çünkü yokluğun sonucu
      // "beyan çizilmez" — yanlış bir beyan değil.
    }));
    unawaited(widget.onboarding.seen().then((bool seen) {
      if (mounted) setState(() => _showOnboarding = !seen);
    }));
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
      // "Güncel kurs" (Hüküm 3) EN SON tamamlanan seansın dersinden
      // türetilir. İki ayrı `recent()` okuması var burada (biri
      // `RecordedSummary.from` içinde, biri burada) — `RecordedSummary`
      // hangi DERSTE olduğumuzu taşımıyor, yalnız toplu sayıları taşıyor;
      // onu genişletmek yerine ikinci bir küçük okuma tercih edildi ki
      // zaten test edilmiş toplu-özet mantığına dokunulmasın.
      final List<SessionRecord> all = await s.recent();
      String? lastId;
      DateTime? lastAt;
      for (final SessionRecord r in all) {
        if (lastAt == null || r.completedAt.isAfter(lastAt)) {
          lastAt = r.completedAt;
          lastId = r.lessonId;
        }
      }
      if (mounted) {
        // Başarılı okuma önceki beyanı KALDIRIR: geçici bir I/O hatasından
        // sonra "geçmişini okuyamıyorum" cümlesini ekranda bırakmak, artık
        // doğru olmayan bir şeyi söylemeye devam etmek olurdu.
        setState(() {
          _recorded = sum;
          _historyUnavailable = null;
          _lastLessonId = lastId;
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
          // Kurs da BİLİNMEZ hâle döner: bayat bir dersten türetilen
          // "kaldığın yer" iddiası, bayat sayılarla aynı yalan sınıfı olurdu.
          _lastLessonId = null;
        });
      }
    }
  }

  /// Kullanıcının içinde bulunduğu kurs (Hüküm 3) — en son tamamlanan
  /// seansın dersini TAŞIYAN kurs. Kayıt yoksa ya da kayıtlı ders artık
  /// kütüphanede yoksa (içerik değişti, ya da senkron/test verisi gerçek
  /// bir dersle eşleşmiyor) `null` döner ve giriş yüzeyi Sayfa A'ya düşer —
  /// bu bir hata değil, dürüst varsayılan: bilmediğimiz bir kursu "güncel"
  /// diye göstermeyiz.
  ShellCourse? get _currentCourse {
    final String? id = _lastLessonId;
    final ShellLibrary? lib = _library;
    if (id == null || lib == null) return null;
    for (final ShellItem item in lib.items) {
      for (final ShellCourse course in item.courses) {
        if (course.lessons.any((ShellLesson l) => l.id == id)) return course;
      }
    }
    return null;
  }

  /// "Kaldığın yer"in resume hedefi — [_currentCourse] içindeki, kimliği
  /// [_lastLessonId]e eşit ders. `_currentCourse` zaten bu eşleşme
  /// üzerinden bulunduğu için burada tekrar bulunamama ihtimali yoktur;
  /// yine de `null`-güvenli çünkü ikisi ayrı getter'lar.
  ShellLesson? get _resumeLesson {
    final ShellCourse? course = _currentCourse;
    final String? id = _lastLessonId;
    if (course == null || id == null) return null;
    for (final ShellLesson l in course.lessons) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ContentFailure? failure = _failure;
    if (failure != null) {
      return ContentFailureScreen(failure: failure, onRetry: _loadContent);
    }
    final ShellLibrary? lib = _library;
    final bool? showOnboarding = _showOnboarding;
    if (lib == null || showOnboarding == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    // KARŞILAMA, kabuktan ÖNCE (J-106). Dürüstlük ön-beyanı ürünün içine
    // girmeden okunmak zorunda — sonradan bir ayar sayfasına gömmek onu
    // hiç okunmayacak bir yere koymak olurdu (UI-BRIEF §3.1).
    if (showOnboarding) {
      return OnboardingPage(
        library: lib,
        onOpenWhyNot: () => _openWhyNot(context, lib),
        onDone: () {
          // Bayrak YAZILMASI BEKLENMİYOR: I/O'yu beklemek kullanıcıyı
          // "Start"a bastıktan sonra bekletirdi ve yazma başarısız olsa
          // bile ekran açılmalı (`OnboardingStore` hatayı yutuyor —
          // maliyeti karşılamanın bir daha görünmesi, katlanılır).
          unawaited(widget.onboarding.markSeen());
          setState(() => _showOnboarding = false);
        },
      );
    }

    // Hüküm 3 (koordinatör 2026-08-06): kurs VARSA giriş yüzeyi Sayfa B
    // (kurs sayfası), YOKSA Sayfa A (seçim). Bu bir fallback değil,
    // tasarlanmış bir hâl — boş bir kabuk göstermek yerine "birini seç"
    // demek tek dürüst şey.
    final ShellCourse? current = _currentCourse;
    if (current != null) {
      return CoursePage(
        course: current,
        onStart: _openSession,
        onOpenSettings: () => _openSettings(context, lib),
        onOpenSelect: () => _openSelect(context, lib),
        isCurrent: true,
        resumeLesson: _resumeLesson,
        gateNote: _gateNoteFor(current),
        historyUnavailable: _historyUnavailableText(),
        historyIncomplete: _historyIncompleteText(),
        recorded: _recordedRows(),
        recordedNote: _recordedNoteText(),
        // K8 (M-F-04): kalibrasyon kapısı geçilmeden sayısal skor YOK.
        // Hüküm 2 (koordinatör 2026-08-06): bu bant düşmedi, Sayfa B'ye
        // bağlamsal dürüst blok olarak taşındı.
        //
        // LİSTE TÜREVİ (J-144, koordinatör hükmü 09:24). Elle yazılıyken
        // `Guard discipline` buradaydı ve o bileşen **puanlanmıyor** —
        // eğitmenler uzlaşmıyor, yani kalibrasyonla KAPANMAZ. Bant
        // başlığı ("until the thresholds are calibrated") onun için
        // karşılıksız bir vaatti.
        bands: _boxing == null
            ? const <String, String>{}
            : widget.repository.gradedBands(_boxing!),
        onRetryHistory: _refreshRecorded,
      );
    }

    return SelectPage(
      library: lib,
      onOpenCourse: (ShellCourse c) => _openCourse(context, lib, c),
      onOpenWhyNot: () => _openWhyNot(context, lib),
      onOpenSettings: () => _openSettings(context, lib),
      // current==null buraya iki farklı sebepten düşebilir: hiç kayıt yok
      // (sağlıklı, banner YOK) ya da kayıt okunamadı (banner VAR) —
      // `_historyUnavailableText()` zaten bu ayrımı yapıyor.
      historyUnavailable: _historyUnavailableText(),
      onRetryHistory: _refreshRecorded,
    );
  }

  /// Bu kursun İLERLEME KAPISI beyanı (J-208) — kapı sisteminin ilk
  /// kullanıcıya ulaşan hâli.
  ///
  /// ## Neden SAYI GÖSTERMİYOR
  ///
  /// Dört kapı yumruk SAYIYOR (`jab` 30 · `cross` 30 · `guard`/`range` 40) ve
  /// o sayaç canlı aşamada GERÇEKTEN çalışıyor — ama hiçbir yere yazılmıyor:
  /// `SessionRecord` olay sayısı taşımıyor, ve dört dersin dördü de plansız
  /// olduğu için `_record()` onlar için hiç satır yazmıyor. Bu durumda
  /// *"0/30"* göstermek, uygulamanın SAYIP ATTIĞI bir işi "hiç yapmadın"
  /// diye raporlamak olurdu — doc-75/2'nin (*"açılamayan geçmişten sayı
  /// doğmaz"*) kapı karşılığı, ve J-092'de kapattığımız yalanın aynısı.
  ///
  /// Cümledeki sayı TÜREVİ: kaç dersin olay-sayımı kapısı olduğu
  /// `evaluateEventGate`ten sayılıyor, elle yazılmıyor (J-107/J-151 sınıfı —
  /// elle yazılmış sayı, liste değişince sessizce yalan olur).
  ///
  /// `null` döner = bu kursta olay-sayımı kapısı olan ders YOK → hiçbir şey
  /// çizilmez (doc-75/6 temiz-hâl sessizliği).
  String? _gateNoteFor(ShellCourse course) {
    final Map<String, dynamic>? cur = _curriculum;
    if (cur == null) return null;
    final RecordedGateEvidence evidence =
        const RecordedGateEvidence(<SessionRecord>[]);
    int gated = 0;
    int notEvaluable = 0;
    for (final ShellLesson l in course.lessons) {
      final GateVerdict? v = evaluateEventGate(cur, l.id, evidence);
      if (v == null) continue;
      gated++;
      if (v is GateNotEvaluable) notEvaluable++;
    }
    if (gated == 0) return null;
    // Bugün gated == notEvaluable; ama eşitliği VARSAYMIYORUZ — kanıt
    // kalıcı katmana geldiği gün bu dal kendiliğinden doğru cümleyi seçsin
    // diye ayrı sayılıyor (bir dalın bugün ulaşılmaz olması, onu yanlış
    // yazmak için gerekçe değil).
    if (notEvaluable == 0) return null;
    final String lessons = notEvaluable == 1 ? 'lesson' : 'lessons';
    return '$notEvaluable $lessons here have a progress gate that counts '
        'punches. We are not showing you a count, because we are not keeping '
        'one: the session counts while it runs and then lets the number go. '
        'A zero would tell you that you did nothing, and that is not what we '
        'measured. Nothing here is blocked — the gates do not close anything.';
  }

  void _openSettings(BuildContext context, ShellLibrary lib) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            SettingsPage(
              onOpenWhyNot: () => _openWhyNot(context, lib),
              excludedCount: lib.exclusions.length,
            ),
      ),
    );
  }

  void _openWhyNot(BuildContext context, ShellLibrary lib) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => WhyNotPage(library: lib)),
    );
  }

  /// Sayfa A'yı PUSH eder — yalnız Sayfa B kök/giriş iken (`isCurrent`)
  /// kullanılır, kullanıcı başka bir disiplin/kurs seçmek istediğinde.
  /// Push (replace değil) ki geri gitmek "kaldığın yer"e dönsün.
  void _openSelect(BuildContext context, ShellLibrary lib) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SelectPage(
          library: lib,
          onOpenCourse: (ShellCourse c) => _openCourse(context, lib, c),
          onOpenWhyNot: () => _openWhyNot(context, lib),
          onOpenSettings: () => _openSettings(context, lib),
          historyUnavailable: _historyUnavailableText(),
          onRetryHistory: _refreshRecorded,
        ),
      ),
    );
  }

  void _openCourse(BuildContext context, ShellLibrary lib, ShellCourse c) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CoursePage(
          course: c,
          onStart: _openSession,
          onOpenSettings: () => _openSettings(context, lib),
        ),
      ),
    );
  }

  /// Kaydedilen sürenin ders açmadığını söyleyen not — yalnız kayıt varken.
  ///
  /// ## ⚠️ İKİ İDDİA BAYATLAMIŞTI (J-124, yayın envanterinin ilk bulgusu)
  ///
  /// Eski metin şunu diyordu: *"Every progress gate also asks how much of
  /// the session the camera could actually analyse, and the camera is not
  /// connected."* İkisi de ÖLÇÜLDÜ ve ikisi de YANLIŞTI:
  ///
  /// * **İlerleme kapısı diye bir şey YOK.** `unlock` sözcüğü tüm depoda
  ///   YALNIZ bu cümlede geçiyor (`numericScoresUnlocked` ayrı kavram, K8
  ///   skor kapısı); içerikte `gate`/`unlock`/`sessionMinutes` diye bir
  ///   alan yok; `SessionStore.workedSecondsFor` hiç çağrılmıyor. Cümle
  ///   kullanıcıya VAR OLMAYAN bir mekanizmayı öğretiyordu.
  /// * **Kamera BAĞLI.** `boxing.foundations.jab` `usesCamera:true` ve
  ///   `_liveJabFor` onun için gerçek bir `LiveJabController` kuruyor
  ///   (J-096'dan beri). Cümle J-096 ÖNCESİNDE doğruydu ve öyle kaldı.
  ///
  /// SONUÇ doğruydu (*"bu dakikalar geçmişin, kredi değil"*) — çünkü zaten
  /// hiçbir şey kilit açmıyor. Ama GEREKÇE iki kez yanlıştı, ve doğru
  /// sonucu yanlış gerekçeyle söylemek kullanıcıya ürünün yanlış bir
  /// modelini öğretir: kapılar olduğunu ve kameranın bağlı olmadığını.
  ///
  /// Yeni metin gerçek mekanizmayı gösteriyor: kilitler İÇERİK
  /// düzeyindedir ve her birinin isimli teknik gerekçesi vardır
  /// (`lockedReason`) — süreyle ilgisi yok.
  String? _recordedNoteText() {
    // ⚠️ J-161 (koordinatör hükmü 11:36 ②): not artık HANGİ seansların
    // buraya girdiğini de söylüyor.
    //
    // Ölçüldü: `_record()` **plansız** dersi bilerek atlıyor ve gerekçesi
    // savunulabilir (saat yokken `workedSeconds: 0` yazmak yanlış olurdu).
    // Ama beş açık ders plansız — **kameralı `jab` DAHİL** — yani ürünün
    // bayrak dersi geçmişte **hiç iz bırakmıyordu ve söylenmiyordu.**
    // *Olan bir yokluğu susmak yanıltmadır* (J-159).
    //
    // ⛔ Bu bir ARA çözüm: hüküm ① (*sayımı yaz, süreyi yazma*) çekirdek
    // sözleşmesinde ifade EDİLEMİYOR — `SessionRecord.workedSeconds`
    // required non-nullable `int` ve JSON'da düz sayı; *"süre ölçülmedi"*
    // diye bir hâl yok. `0` yazmak, J-156'nın kusurunu **kalıcı katmanda**
    // yeniden üretirdi. Çekirdek değişikliği koordinatörde.
    return _recorded == null || _recorded!.sessions == 0
        ? null
        : 'These minutes are your history, not credit. Only lessons with a '
            'round clock are counted here — the free-practice lessons have '
            'no timer, so their time is not measured and they leave no line. '
            'Nothing here opens with time either: the lessons that are '
            'closed are closed for a named technical reason, and each one '
            'tells you its own.';
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
  /// **"Try again" SUNULUYOR — ve bu yorum bunun tersini söylüyordu (J-138).**
  ///
  /// Eski hâli *"'Try again' bilerek sunulmuyor: kullanıcının yapabileceği bir
  /// şey yok"* diyordu. Gerçek render ölçtü: düğme ekranda
  /// (`select_page.dart`), `onRetryHistory` her çağrı yerinde besleniyor, ve
  /// `_refreshRecorded` **gerçekten** yeniden okuyup başarıda bu beyanı
  /// kaldırıyor. Yani J-079'un kuralı (*çalışmayan retry, retry olmamasından
  /// kötüdür*) burada **ihlal edilmiyor** — düğme çalışıyor; ihlal eden şey
  /// yorumun kendisiydi.
  ///
  /// Bayat beyanın maliyeti burada somut: bu satırı okuyan bir sonraki tur,
  /// **çalışan bir düğmeyi "yanlışlıkla eklenmiş" sanıp silebilirdi.** Bu
  /// yüzden davranış artık yoruma değil kapıya bağlı
  /// (`history_retry_test`): düğme VAR · geri çağırıyor · beyan yokken
  /// düğme de YOK.
  ///
  /// (İçerik yükleme tarafındaki ayrı kural yerinde duruyor: `content_failure`
  /// ekranı retry'ı yalnız `unreadable` sınıfında sunar, çünkü BÜTÜNLÜK
  /// hatasında aynı asset aynı sonucu verir — orada retry gerçekten
  /// çalışmayan bir düğme olurdu.)
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
                  bands: widget.repository.gradedBands(_boxing!),
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
