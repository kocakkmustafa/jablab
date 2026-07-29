import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jablab_engine/jablab_engine.dart'
    show IntervalPlan, RoundPlan;

import '../shell_candidate/live_surface.dart';
import '../shell_candidate/session_flow.dart';
import '../shell_candidate/shell_models.dart';
import 'session_narrator.dart';
import 'session_store.dart';

/// Canlı seans ekranı — **app'e özgü**, `motion_shell`'e terfi ETMEZ.
///
/// Kabuk parçaları (`SessionFlowScaffold`, `LiveCoachSurface`,
/// `SessionSummaryView`, `IntervalTimer`) buradan besleniyor; boksa özgü olan
/// yalnız içerik: cue metinleri, sayılan olayın adı, kamera önizlemesi.
///
/// ⚠️ Kamera hattı henüz bağlı değil (native köprü ADR-002, koordinatör
/// kuyruğunda). Ekran bunu **saklamıyor** — sahte bir "analiz ediliyor"
/// animasyonu yerine hangi parçanın eksik olduğunu yazıyor.
class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    required this.lesson,
    required this.cues,
    required this.coachedNotScored,
    required this.plan,
    this.intervalPlan,
    this.store,
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
    await store.append(SessionRecord(
      lessonId: widget.lesson.id,
      completedAt: DateTime.now(),
      workedSeconds: _workedSeconds,
      roundsCompleted: _roundsCompleted,
      plannedRounds: plan?.rounds ?? widget.intervalPlan!.bursts,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SessionFlowScaffold(
      title: widget.lesson.title,
      stage: _stage,
      advanceLabel: _stage == SessionStage.summary ? 'Done' : 'Continue',
      onAdvance: _advance,
      child: switch (_stage) {
        SessionStage.teach => _Teach(lesson: widget.lesson),
        SessionStage.rehearse => const _Rehearse(),
        SessionStage.live => _Live(
            cues: widget.cues,
            plan: widget.plan,
            intervalPlan: widget.intervalPlan,
            onProgress: (int rounds, int worked) {
              _roundsCompleted = rounds;
              _workedSeconds = worked;
            },
          ),
        SessionStage.summary => _Summary(coachedNotScored: widget.coachedNotScored),
      },
    );
  }
}

class _Teach extends StatelessWidget {
  const _Teach({required this.lesson});

  final ShellLesson lesson;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
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
          Text(
            'Nothing is being analysed yet — watch first. '
            'Scoring you while you are still learning the shape would '
            'punish learning.',
            key: const Key('teach-no-analysis'),
            style: theme.textTheme.bodySmall,
          ),
        ],
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
            Text('Go slow. One thing at a time, no clock.',
                key: Key('rehearse-copy')),
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
  });

  final CueBook cues;
  final RoundPlan? plan;
  final IntervalPlan? intervalPlan;

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
          : SessionMode.steady);
  Timer? _ticker;

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

  Duration get _segment {
    final IntervalPlan? ip = _ivl;
    if (ip != null) {
      return Duration(
          seconds: _resting ? ip.recoverSeconds : ip.burstSeconds);
    }
    return _resting
        ? Duration(seconds: _plan!.restSeconds)
        : Duration(seconds: _plan!.roundSeconds);
  }

  @override
  void initState() {
    super.initState();
    if (_plan == null && _ivl == null) return;
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
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
      events.addAll(_narrator.tick(elapsed: _elapsed, total: _segment));
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
    final String? said = events.isEmpty ? null : widget.cues.say(events.last);
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
        Expanded(
          child: LiveCoachSurface(
            state: LiveState.noVerdict,
            eventCount: 0,
            narration: _line,
            // Motor hazır ve testli; besleyen kamera köprüsü değil. Hüküm
            // yuvası bu yüzden susuyor ve SEBEBİ yazılı.
            noVerdictReason:
                'The camera feed is not connected yet, so nothing is being '
                'judged. The round clock and the engine both work.',
          ),
        ),
      ],
    );
  }
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
