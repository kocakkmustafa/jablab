import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jablab_engine/jablab_engine.dart' show RoundPlan;

import '../shell_candidate/live_surface.dart';
import '../shell_candidate/session_flow.dart';
import '../shell_candidate/shell_models.dart';
import 'session_narrator.dart';

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

  void _advance() {
    final int i = SessionStage.values.indexOf(_stage);
    if (i + 1 < SessionStage.values.length) {
      setState(() => _stage = SessionStage.values[i + 1]);
    } else {
      Navigator.of(context).pop();
    }
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
        SessionStage.live =>
          _Live(cues: widget.cues, plan: widget.plan),
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
  const _Live({required this.cues, required this.plan});

  final CueBook cues;
  final RoundPlan? plan;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  final SessionNarrator _narrator = SessionNarrator(mode: SessionMode.steady);
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

  Duration get _segment => _resting
      ? Duration(seconds: _plan!.restSeconds)
      : Duration(seconds: _plan!.roundSeconds);

  @override
  void initState() {
    super.initState();
    if (_plan == null) return;
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
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
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RoundPlan? plan = _plan;

    return Column(
      children: <Widget>[
        // SAAT YALNIZ PLANLI DERSTE AKAR. Öğretme dersleri (kamera, duruş,
        // jab...) süreli çalışma DEĞİL — onlarda bir tur saati göstermek
        // olmayan bir yapıyı varmış gibi gösterirdi. Süreli bir dersin
        // plansız AÇIK kalması `Library.validate` tarafından reddediliyor,
        // yani bu dal "planı yazılmamış tur" anlamına gelmez.
        if (plan != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: IntervalTimer(elapsed: _elapsed, total: _segment),
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
