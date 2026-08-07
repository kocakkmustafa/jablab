import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jablab_engine/jablab_engine.dart' show IntervalPlan, RoundPlan;

import '../shell_candidate/live_surface.dart';
import '../shell_candidate/session_flow.dart';
import '../shell_candidate/shell_models.dart';
import 'design_tokens.dart';
import 'session_narrator.dart';
import 'live_honesty.dart';
import 'live_jab_controller.dart';
import 'live_session_failure.dart';
import 'session_store.dart';
import 'skeleton_overlay.dart';
import 'teach_material.dart';

/// Canlı seans ekranı — **app'e özgü**, `motion_shell`'e terfi ETMEZ.
///
/// Kabuk parçaları (`SessionFlowScaffold`, `LiveCoachSurface`,
/// `SessionSummaryView`, `IntervalTimer`) buradan besleniyor; boksa özgü olan
/// yalnız içerik: cue metinleri, sayılan olayın adı, kamera önizlemesi.
/// Görsel giydirme `jablabSessionTheme`den (design_tokens.dart) — kabuk
/// parçaları frozen olduğu için `Theme(data:, child:)` sarmalıyla dışarıdan
/// besleniyor (design turu Parça 2, 2026-08-06).
///
/// ⚠️ Kamera GÖRÜNTÜSÜ (piksel akışı) henüz bağlı değil — Texture tabanlı
/// önizleme bilinçli ertelendi (`docs/70-KAMERA-KOPRUSU-SOZLESMESI.md`).
/// Ekran bunu **saklamıyor**: `skeleton_overlay.dart`'ın kamera-yer-tutucusu
/// bunu açıkça yazıyor. **Kamera ANALİZİ** (poz çıkarımı, `LiveJabController`)
/// bundan AYRI ve BAĞLI — motor kişiyi görüyor, yalnız o görüntüyü ekrana
/// basmıyoruz; iskelet çizimi bunun kanıtı (gerçek koordinatlardan).
class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    required this.lesson,
    required this.cues,
    required this.coachedNotScored,
    required this.plan,
    required this.teachMaterial,
    this.intervalPlan,
    this.store,
    this.liveJab,
    this.liveJabSetupFailure,
  });

  final ShellLesson lesson;

  /// Dersin tur planı (J-063). `null` ise canlı aşama SÜRE KOŞMAZ ve bunu
  /// söyler — eskiden burada sabit 3 dakika koşuluyordu ve "Twenty minutes"
  /// yazan ders 3 dakikada bitiyordu (J-062, `beyan ≠ canlı`).
  ///
  /// Bugün plansız bir dersin AÇIK olması `Library.validate` tarafından
  /// reddediliyor; yani bu yol pratikte yalnız kilitli/plansız bir derse
  /// doğrudan gidilirse görünür. Sessizce bir süre uydurmak yerine
  /// görünür kalması bilinçli.
  final RoundPlan? plan;

  /// Aralık planı (J-068). `plan` ile aynı anda dolu olamaz — `validate`
  /// bunu içerik tarafında reddediyor.
  final IntervalPlan? intervalPlan;

  /// Seans geçmişi (J-064). `null` iken akış aynen çalışır, yalnız KAYIT
  /// tutulmaz — testlerde ve plansız (öğretme) derslerinde böyle.
  final SessionStore? store;

  /// Replik kitabı app'ten enjekte edilir; kabuk sözlüğü GÖRMEZ.
  final CueBook cues;

  /// KAMERA hattı (J-096) — `null` ise ders kamerasız koşar.
  ///
  /// Opsiyonel olması bir geçici çözüm DEĞİL, kalıcı tasarım: Fitness
  /// dersleri kamerasız TAM çalışıyor ve kanıtlı. Kamerayı zorunlu kılmak
  /// çalışan bir hattı olmayan bir donanıma bağımlı yapardı.
  final LiveJabController? liveJab;

  /// Hat KURULAMADI (model çıkarılamadı, I/O…) — ama ders yine AÇILIR.
  ///
  /// Kurulum hatasının dersi açılmaz yapması sessiz bir çıkmaz sokaktı:
  /// kullanıcı derse dokunuyor ve hiçbir şey olmuyordu. Saat kamerasız da
  /// koşuyor; eksik olan analiz ve o BEYAN EDİLİYOR.
  final LiveSessionFailure? liveJabSetupFailure;

  /// Öğretme aşamasının materyali (J-094) —
  /// `ContentRepository.teachMaterialFor` üretir, ekran ondan TÜRETİR.
  ///
  /// Zorunlu ve nullable DEĞİL: `null` geçilebilse "materyal yok" ile
  /// "kimse sormadı" aynı değere düşerdi ve ekran ikisini ayırt edemezdi —
  /// bu ekranın düzelttiği kusurun ta kendisi.
  final TeachMaterial teachMaterial;

  /// `ContentRepository.coachedNotScoredLabels` — config'in
  /// `stanceCoachedOnlyJoints`'inden türetilir (J-033/rule 9); burada
  /// elle kopyalanmaz ki kova kararı değişince metin sessizce bayatlamasın.
  final List<String> coachedNotScored;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  SessionStage _stage = SessionStage.teach;

  /// Canlı aşamanın bildirdiği son durum — özet aşamasına geçerken
  /// kaydedilir. Canlı bileşenin içinde tutulup orada yazmak, ekran
  /// dispose edilirken async yazma yapmak olurdu.
  int _workedSeconds = 0;
  int _roundsCompleted = 0;

  void _advance() {
    final bool leavingLive = _stage == SessionStage.live;
    final int i = SessionStage.values.indexOf(_stage);
    if (i + 1 < SessionStage.values.length) {
      setState(() => _stage = SessionStage.values[i + 1]);
    } else {
      Navigator.of(context).pop();
    }
    // Kayıt canlı aşamadan ÇIKARKEN yazılır — seans sonuna ulaşılmasa bile.
    // "Yarıda bıraktı" bir veridir; yalnız tamamlananı kaydetmek, kullanıcının
    // gerçekten yaptığı işi görünmez kılardı.
    if (leavingLive) unawaited(_record());
  }

  Future<void> _record() async {
    final SessionStore? store = widget.store;
    final RoundPlan? plan = widget.plan;
    // Plansız (öğretme) derste çalışma süresi diye bir şey YOK — sıfır
    // saniyelik kayıt yazmak, geçmişi anlamsız satırlarla doldurmak olurdu.
    if (store == null ||
        (plan == null && widget.intervalPlan == null) ||
        _workedSeconds <= 0) {
      return;
    }
    await store.append(
      SessionRecord(
        lessonId: widget.lesson.id,
        completedAt: DateTime.now(),
        workedSeconds: _workedSeconds,
        unitsCompleted: _roundsCompleted,
        plannedUnits: plan?.rounds ?? widget.intervalPlan!.bursts,
        // Birim KAYIT BAŞINA (çekirdek sözleşmesi): aynı ilerleme ekranında
        // tur-birimli ve aralık-birimli ders yan yana durabilir.
        unitLabel: plan != null ? 'round' : 'interval',
        // SINIF, YAZMA ANINDA (J-095). Bugün JabLab'ta hiçbir ders
        // puanlanmıyor: kalibrasyon kapısı (K8) geçilmedi ve kamera bağlı
        // değil. `'unscored'` bunu yazma anında mühürlüyor — ders yarın terfi
        // ederse YENİ kayıtlar farklı sınıf taşır ve bugünküler doğru şekilde
        // puansız kalır. Sınıfı sonradan HESAPLAMAK geçmişi sessizce yeniden
        // yorumlamak olurdu (çekirdeğin kendi uyarısı).
        //
        // Ayrıca en-az-yetki: yalnız `'scored'` puanlı okunur, bu değer değil.
        lessonClass: 'unscored',
        // `unmeasuredUnits` SIFIR ve bu bir varsayım değil: o alan "motorun
        // GÖRDÜĞÜ ama yargılayamadığı" birimler için (kadraj/ışık/takip).
        // JabLab'ta kamera HİÇ yok — tur sayısı saatten gelen bir olgu, kamera
        // ölçümü değil. Yargılanmamışlığı taşıyan alan `lessonClass`; buraya
        // yazmak iki farklı olguyu karıştırırdı.
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme(sarma): kabuk parçaları (SessionFlowScaffold + içindekiler)
    // frozen — `JColors`/`JText`i doğrudan okuyamaz, yalnız
    // `Theme.of(context)` üzerinden beslenir (bkz. sınıf dokümanı +
    // design_tokens.dart'taki `jablabSessionTheme` yorumu).
    return Theme(
      data: jablabSessionTheme,
      child: SessionFlowScaffold(
        title: widget.lesson.title,
        stage: _stage,
        advanceLabel: _stage == SessionStage.summary ? 'Done' : 'Continue',
        onAdvance: _advance,
        child: switch (_stage) {
          SessionStage.teach => _Teach(
            lesson: widget.lesson,
            material: widget.teachMaterial,
          ),
          SessionStage.rehearse => const _Rehearse(),
          SessionStage.live => _Live(
            cues: widget.cues,
            plan: widget.plan,
            intervalPlan: widget.intervalPlan,
            liveJab: widget.liveJab,
            liveJabSetupFailure: widget.liveJabSetupFailure,
            onProgress: (int rounds, int worked) {
              _roundsCompleted = rounds;
              _workedSeconds = worked;
            },
          ),
          SessionStage.summary => _Summary(
            coachedNotScored: widget.coachedNotScored,
          ),
        },
      ),
    );
  }
}

class _Teach extends StatelessWidget {
  const _Teach({required this.lesson, required this.material});

  final ShellLesson lesson;

  /// Materyal DIŞARIDAN gelir — ekran kendi içeriğini icat etmez.
  final TeachMaterial material;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // ⚠️ KAYDIRILABİLİR — ve bunu 375pt kapısı BULDU (J-118). Materyal
    // yokken bu aşama üç kısa satırdı ve sabit `Column` yetiyordu; gerçek
    // öğretme metni gelir gelmez 375×812'de **61 piksel** taştı. Aile
    // dersi #3'ün birebir tekrarı: *gerçek metin fixture'dan uzundur* —
    // ve bu kez fixture değil, İÇERİĞİN KENDİSİ uzadı.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.school_outlined, size: 36),
            const SizedBox(height: 16),
            Text(lesson.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (lesson.subtitle.isNotEmpty)
              Text(lesson.subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            // MATERYAL — ekran KENDİSİ karar vermez, `ContentRepository`den
            // türetir (J-094). Eskiden burada elle yazılmış *"watch first"*
            // duruyordu ve izlenecek hiçbir şey yoktu: kullanıcıya
            // yapamayacağı bir eylem söyleniyordu.
            switch (material) {
              TeachMaterialText(body: final String body) => Text(
                body,
                key: const Key('teach-material'),
                style: theme.textTheme.bodyMedium,
              ),
              TeachMaterialNone(reason: final String reason) => Text(
                reason,
                key: const Key('teach-material-none'),
                style: theme.textTheme.bodySmall,
              ),
            },
            const SizedBox(height: 12),
            // Bu cümle materyalden BAĞIMSIZ ve her hâlde doğru: hüküm
            // aşamanın kendisinde susuyor (`SessionStage.teach.judges == false`).
            Text(
              'Nothing is being analysed during this part. Scoring you while '
              'you are still learning the shape would punish learning.',
              key: const Key('teach-no-analysis'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Rehearse extends StatelessWidget {
  const _Rehearse();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.timer_outlined, size: 36),
        SizedBox(height: 16),
        Text(
          'Go slow. One thing at a time, no clock.',
          key: Key('rehearse-copy'),
        ),
      ],
    ),
  );
}

/// Canlı tur: süre AKAR ve anlatı konuşur, hüküm SUSAR.
///
/// İkisinin ayrı olması tasarım kararı: turu saymak poza bakmayı gerektirmez.
/// Kamera bağlı değilken bile "yarıladın" doğru bir cümledir; "gardın düştü"
/// ise olmayan bir ölçüme dayanırdı.
class _Live extends StatefulWidget {
  const _Live({
    required this.cues,
    required this.plan,
    required this.intervalPlan,
    required this.onProgress,
    this.liveJab,
    this.liveJabSetupFailure,
  });

  final CueBook cues;
  final RoundPlan? plan;
  final IntervalPlan? intervalPlan;
  final LiveJabController? liveJab;
  final LiveSessionFailure? liveJabSetupFailure;

  /// (tamamlanan tur, ÇALIŞILAN saniye) — dinlenme sayılmaz.
  final void Function(int roundsCompleted, int workedSeconds) onProgress;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  /// Kip PLANA göre seçilir — `interval()` yalnız `SessionMode.interval`de
  /// olay üretir, `steady`de sessizce boş döner. Sabit `steady` bırakmak,
  /// aralık repliklerini hiç duyulmaz kılardı (kodu var, kullanıcı duymuyor).
  late final SessionNarrator _narrator = SessionNarrator(
    mode: widget.intervalPlan != null
        ? SessionMode.interval
        : SessionMode.steady,
  );
  Timer? _ticker;

  /// Kamera hattının son bildirdiği hâl — `null` iken ders kamerasız.
  LiveJabState? _jab;
  StreamSubscription<LiveJabState>? _jabSub;
  late LiveSessionFailure? _jabFailure = widget.liveJabSetupFailure;

  /// O anki turun (ya da dinlenmenin) İÇİNDEKİ konum — toplam değil.
  /// `IntervalTimer` bir aralığın ilerlemesini gösterir; toplam seansı
  /// göstermek "son 10 saniye" anlatısını anlamsız yapardı.
  Duration _elapsed = Duration.zero;
  int _roundIndex = 0;
  bool _resting = false;
  bool _finished = false;
  String? _line;

  RoundPlan? get _plan => widget.plan;
  IntervalPlan? get _ivl => widget.intervalPlan;

  /// Kameranın o ana kadar SAYDIĞI tamamlanmış jab — anlatıcının sayım
  /// kilometre taşı için okuduğu tek girdi.
  ///
  /// ⚠️ **Bu getter bir kusurun kapanışı (J-104).** `SessionNarrator.tick`
  /// `eventCount` parametresini en baştan taşıyordu ve `milestoneEvery`
  /// (25) testliydi — ama çağıran onu HİÇ geçmiyordu, yani `eventCount`
  /// her zaman 0'a düşüyor ve `NarrationEvent.milestone` **hiçbir koşulda
  /// ateşlenemiyordu**. `cue.milestone` bu yüzden "kodda eşlenmiş ama
  /// kullanıcı asla duymuyor" sınıfındaydı: aile dersi #6'nın
  /// (*"repliğin varlığı tetiğinin varlığı değil"*) tam örneği — ve grep
  /// taraması bunu YAKALAYAMAZ, çünkü anahtar `jabLabCueMapping`de duruyor.
  ///
  /// Kamerasız derste 0 döner ve bu DOĞRU: sayacak bir şey yok, dolayısıyla
  /// kilometre taşı da yok. Uydurulmuş bir eşik EKLENMEDİ — `milestoneEvery`
  /// zaten `SessionNarrator`ın kendi sabiti.
  int get _completedJabs {
    final LiveJabState? jab = _jab;
    return jab is LiveJabRunning ? jab.completedCount : 0;
  }

  Duration get _segment {
    final IntervalPlan? ip = _ivl;
    if (ip != null) {
      return Duration(seconds: _resting ? ip.recoverSeconds : ip.burstSeconds);
    }
    return _resting
        ? Duration(seconds: _plan!.restSeconds)
        : Duration(seconds: _plan!.roundSeconds);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_startCamera());
    if (_plan == null && _ivl == null) return;
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Kamerayı başlatır. **Saat kameradan BAĞIMSIZ koşar**: kamera açılmasa
  /// bile tur saati ve anlatı çalışmaya devam eder — süre saymak poza
  /// bakmayı gerektirmez ve bir izin reddi antrenmanı durdurmamalı.
  Future<void> _startCamera() async {
    final LiveJabController? live = widget.liveJab;
    if (live == null) return;
    _jabSub = live.states.listen((LiveJabState st) {
      if (!mounted) return;
      setState(() {
        _jab = st;
        if (st is LiveJabFailed) _jabFailure = st.failure;
      });
    });
    final LiveSessionFailure? f = await live.start();
    if (f != null && mounted) setState(() => _jabFailure = f);
  }

  void _tick() {
    if (_ivl != null) {
      _tickInterval(_ivl!);
      return;
    }
    final RoundPlan plan = _plan!;
    if (_finished) return;

    final List<NarrationEvent> events = <NarrationEvent>[];
    if (_resting) {
      // Dinlenme anlatılmaz saniye saniye; başında bir kez söylenir.
      if (_elapsed <= Duration.zero) events.add(NarrationEvent.rest);
    } else {
      events.addAll(
        _narrator.tick(
          elapsed: _elapsed,
          total: _segment,
          eventCount: _completedJabs,
        ),
      );
    }

    Duration next = _elapsed + const Duration(seconds: 1);
    bool segmentOver = next > _segment;

    if (segmentOver) {
      if (_resting) {
        // Dinlenme bitti → sıradaki tur. `startRound()` olay setini
        // sıfırlar; yoksa "yarıladın" yalnız ilk turda söylenirdi.
        _resting = false;
        _roundIndex++;
        _narrator.startRound();
        next = Duration.zero;
      } else if (_roundIndex + 1 < plan.rounds) {
        if (plan.restSeconds > 0) {
          _resting = true;
          next = Duration.zero;
        } else {
          _roundIndex++;
          _narrator.startRound();
          next = Duration.zero;
        }
      } else {
        // Son turun sonu = SEANS sonu. Son turdan sonra dinlenme YOKTUR.
        _finished = true;
        events.add(NarrationEvent.sessionEnd);
        next = _segment;
        _ticker?.cancel();
      }
    }

    // Aynı anda birden çok olay düşerse SONUNCUSU söylenir: üst üste iki
    // cümle sesli koçta anlaşılmaz, kullanıcı ikisini de kaçırır.
    //
    // ⚠️ `vars` ZORUNLU: `cue.milestone` "{n} in." şablonudur ve tetiği
    // bağlandığı ilk anda ekrana LİTERAL "{n} in." yazdı (J-104'ün ikinci
    // kusuru — tetik testi yakaladı). `{n}` sayımın kendisi, yani
    // `eventCount` ile AYNI değer; ayrı bir sayaç tutmak ikisinin
    // ayrışabileceği bir yol açardı.
    final String? said = events.isEmpty
        ? null
        : widget.cues.say(
            events.last,
            vars: <String, Object>{'n': _completedJabs},
          );
    if (!mounted) return;
    setState(() {
      if (said != null) _line = said;
      _elapsed = next;
    });

    // ÇALIŞILAN süre: tamamlanan turlar + içinde bulunulan turun geçen
    // kısmı. Dinlenme HİÇ sayılmaz — ilerleme kapısı çalışma süresini
    // soruyor, dinlenmeyi de eklemek kapıyı hak etmeden geçirmek olurdu.
    // DİNLENMEDEYKEN biten tur SAYILIR. `_roundIndex` dinlenme BİTİNCE
    // artıyor; onu doğrudan kullanmak, dinlenme sırasında bırakılan seansı
    // "hiç çalışmadı" diye kaydediyordu (testin yakaladığı gerçek kusur).
    final int completed = _finished
        ? plan.rounds
        : (_resting ? _roundIndex + 1 : _roundIndex);
    final int inRound = (_resting || _finished)
        ? 0
        : _elapsed.inSeconds.clamp(0, plan.roundSeconds);
    widget.onProgress(completed, completed * plan.roundSeconds + inRound);
  }

  /// Aralık kipi (J-068): patla → topla → patla ... son toparlanma DAHİL.
  ///
  /// Turlu kipten iki yapısal fark var ve ikisi de bilinçli:
  ///  * SON patlamadan sonra da toparlanma koşar (soğuma döngünün parçası);
  ///    `RoundPlan` tam tersini yapar ve bu yüzden ayrı tipler.
  ///  * Form repliklerinin sustuğu tek kip budur (`cues.en.json` grup notu):
  ///    yüksek tempoyu ürün istedi, sonra "formun bozuldu" demek kendi
  ///    tasarladığımız egzersiz için ceza kesmek olurdu.
  void _tickInterval(IntervalPlan plan) {
    if (_finished) return;

    final bool wasInBurst = !_resting;
    Duration next = _elapsed + const Duration(seconds: 1);
    final bool segmentOver = next > _segment;
    bool nowResting = _resting;

    if (segmentOver) {
      if (!_resting) {
        nowResting = true;
        next = Duration.zero;
      } else if (_roundIndex + 1 < plan.bursts) {
        nowResting = false;
        _roundIndex++;
        next = Duration.zero;
      } else {
        // Son toparlanmanın sonu = SEANS sonu.
        _finished = true;
        next = _segment;
        _ticker?.cancel();
      }
    }

    final Duration untilNext = _segment - next;
    final List<NarrationEvent> events = <NarrationEvent>[
      ..._narrator.interval(
        inBurst: !nowResting,
        wasInBurst: wasInBurst,
        untilNext: nowResting ? untilNext : Duration.zero,
      ),
      if (_finished) NarrationEvent.sessionEnd,
    ];

    final String? said = events.isEmpty ? null : widget.cues.say(events.last);
    if (!mounted) return;
    setState(() {
      if (said != null) _line = said;
      _resting = nowResting;
      _elapsed = next;
    });

    // ÇALIŞMA = yalnız PATLAMALAR. Toparlanmayı da saymak kullanıcıyı
    // kapıdan hak etmeden geçirirdi (turdaki dinlenmeyle aynı ilke).
    final int done = _finished
        ? plan.bursts
        : (_resting ? _roundIndex + 1 : _roundIndex);
    final int inBurst = (_resting || _finished)
        ? 0
        : _elapsed.inSeconds.clamp(0, plan.burstSeconds);
    widget.onProgress(done, done * plan.burstSeconds + inBurst);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_jabSub?.cancel());
    // Kamerayı KAPAT: açık bırakmak modeli ve kamerayı ekran kapandıktan
    // sonra da meşgul tutardı ve plugin tek oturuma izin veriyor — sonraki
    // ders `already-running` ile açılamazdı.
    unawaited(widget.liveJab?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RoundPlan? plan = _plan;
    final IntervalPlan? ivl = _ivl;

    return Column(
      children: <Widget>[
        // SAAT YALNIZ PLANLI DERSTE AKAR. Öğretme dersleri (kamera, duruş,
        // jab...) süreli çalışma DEĞİL — onlarda bir tur saati göstermek
        // olmayan bir yapıyı varmış gibi gösterirdi. Süreli bir dersin
        // plansız AÇIK kalması `Library.validate` tarafından reddediliyor,
        // yani bu dal "planı yazılmamış tur" anlamına gelmez.
        if (plan != null || ivl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: IntervalTimer(elapsed: _elapsed, total: _segment),
          ),
        if (ivl != null)
          Text(
            _resting
                ? 'Recover — burst ${_roundIndex + 2 > ivl.bursts ? ivl.bursts : _roundIndex + 2} of ${ivl.bursts} next'
                : 'Burst ${_roundIndex + 1} of ${ivl.bursts}',
            key: const Key('live-burst-position'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        // Tur konumu YAZILI. Çok turlu bir seansta hangi turda olduğunu
        // bilmemek, süreyi hiç bilmemekle aynı: kullanıcı ne kadar kaldığını
        // hesaplayamaz.
        if (plan != null && plan.rounds > 1)
          Text(
            _resting
                ? 'Rest — round ${_roundIndex + 2} of ${plan.rounds} next'
                : 'Round ${_roundIndex + 1} of ${plan.rounds}',
            key: const Key('live-round-position'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        Expanded(child: _coachSurface()),
      ],
    );
  }
}

/// Canlı yüzey — kameralı ve kamerasız dersin AYNI yuvası, farklı içerikle.
extension on _LiveState {
  /// Donmuş yüzeyi kovanın rengiyle giydirir (J-110). `LiveCoachSurface`
  /// `shell_candidate/` altında DONDURULMUŞ ve `colorScheme.error`ü
  /// "göremiyorum" ikonuna basıyor; widget'a dokunmadan tek yol bu sarmal —
  /// J-100'ün `jablabSessionTheme` deseninin aynısı, bir katman içeride.
  Widget _bucketed(LiveHonestyBucket bucket, Widget surface) =>
      Theme(data: bucket.themeFor(Theme.of(context)), child: surface);

  Widget _coachSurface() {
    final LiveSessionFailure? failure = _jabFailure;
    if (failure != null) {
      // KURULUM hatası: seans başlamadı. Saat koşmaya devam ediyor (yukarıda)
      // ama analiz yok ve bu SÖYLENİYOR — "yine de devam et" düğmesi YOK,
      // çünkü kamera dersinin vaadi analizdir.
      // KOVA KURULUM HATASININ SINIFINDAN TÜRÜYOR, hepsi aynı değil:
      // izin reddi analizin HİÇ başlamadığı hâldir (kullanıcı bilerek
      // seçti, ortada bir arıza yok); kamera açılamadı/kurulum düştü ise
      // BİZİM tarafımızda bir sorun. İkisine aynı görseli vermek, J-103'ün
      // metinde ayırdığı şeyi görselde birleştirmek olurdu.
      final LiveHonestyBucket bucket = failure is LivePermissionDenied
          ? LiveHonestyBucket.none
          : LiveHonestyBucket.ours;
      return _bucketed(
        bucket,
        LiveCoachSurface(
          state: LiveState.noVerdict,
          // Analiz HİÇ başlamadı → sayı YOK. `0` yazmak "sıfır yumruk
          // attın" demektir ve hiçbir şey ölçülmedi (J-096).
          eventCount: null,
          narration: _line,
          noVerdictReason: _failureSentence(failure),
          preview: SkeletonPreview(state: LiveState.noVerdict, bucket: bucket),
        ),
      );
    }

    final LiveJabState? jab = _jab;
    if (widget.liveJab == null) {
      // KAMERASIZ ders — hâlâ doğru olan eski cümle.
      return _bucketed(
        LiveHonestyBucket.none,
        LiveCoachSurface(
          state: LiveState.noVerdict,
          eventCount: null,
          narration: _line,
          noVerdictReason:
              'This lesson runs on the clock — nothing is being judged. '
              'The round timer and the voice coach both work.',
          preview: const SkeletonPreview(
            state: LiveState.noVerdict,
            bucket: LiveHonestyBucket.none,
          ),
        ),
      );
    }
    if (jab == null || jab is LiveJabStarting) {
      // Henüz hiçbir kare gelmedi. SIFIR GÖSTERİLMİYOR: sıfır "hiç yumruk
      // atmadın" demektir, oysa daha hiçbir şey ölçülmedi. İskelet de YOK
      // (henüz çözülmüş bir kare yok) — yalnız yer tutucu görünür.
      return _bucketed(
        LiveHonestyBucket.none,
        LiveCoachSurface(
          state: LiveState.noVerdict,
          eventCount: null,
          narration: _line,
          noVerdictReason: 'Getting the camera ready…',
          preview: const SkeletonPreview(
            state: LiveState.noVerdict,
            bucket: LiveHonestyBucket.none,
          ),
        ),
      );
    }

    final LiveJabRunning r = jab as LiveJabRunning;
    return _bucketed(
      r.bucket,
      LiveCoachSurface(
        state: r.surface,
        eventCount: r.completedCount,
        cue: r.cue,
        // MOTOR ANLATISI SAATİNKİNİ EZER (J-105). İkisi de aynı yuvaya
        // yazıyor ve yuva tek; hangisi kazanacağı bir tercih değil bir ZAMAN
        // meselesi: "düzeltme kayboldu" TAM O ANDA doğru ve bir saniye sonra
        // artık haber değil, oysa "yarıladın" tur boyunca doğru kalır.
        // Kaybolan cümleyi bekleten bir kuyruk kurmak, en taze sinyali en geç
        // söylemek olurdu.
        narration: r.narration ?? _line,
        noVerdictReason: r.noVerdictReason,
        preview: SkeletonPreview(
          state: r.surface,
          skeleton: r.skeleton,
          bucket: r.bucket,
        ),
      ),
    );
  }

  /// Tipli hâl → kullanıcı cümlesi. **Ham `detail` KULLANILMIYOR** (doc-75/5
  /// kamera tarafı): teşhis dizesi geliştirici içindir.
  String _failureSentence(LiveSessionFailure f) => switch (f) {
    LivePermissionDenied(permanentlyDenied: final bool permanent) =>
      permanent
          // "Tekrar dene" demek anlamsız: sistem bir daha sormayacak.
          ? 'Camera access is off for JabLab, and the system will not ask '
                'again. You can turn it on in Settings. The round clock '
                'still runs without it.'
          : 'We need the camera to watch your jab. Nothing is analysed '
                'without it — the round clock still runs.',
    LiveCameraUnavailable() =>
      'We could not open the camera on this device, so nothing is being '
          'analysed. The round clock still runs.',
    LiveSetupFailed() =>
      'Something went wrong setting up the camera, so nothing is being '
          'analysed. The round clock still runs.',
  };
}

class _Summary extends StatelessWidget {
  const _Summary({required this.coachedNotScored});

  final List<String> coachedNotScored;

  @override
  Widget build(BuildContext context) => SessionSummaryView(
    eventCount: 0,
    // K8 (M-F-04): kalibrasyon kapısı geçilmeden sayı yok — bant bile
    // ölçüm olmadığı için boş.
    bands: const <String, String>{
      'Stance': '—',
      'Balance': '—',
      'Footwork': '—',
    },
    // J-033: eğitmenler gard/kol pozisyonunda ayrışıyor → koçlanır ama
    // SKORLANMAZ. Liste config'ten gelir (ContentRepository), elle
    // yazılmaz — bkz. widget dokümanı.
    coachedNotScored: coachedNotScored,
  );
}
