import 'dart:async';

import 'package:flutter/material.dart';

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
  });

  final ShellLesson lesson;

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
        SessionStage.live => _Live(cues: widget.cues),
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
  const _Live({required this.cues});

  final CueBook cues;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  static const Duration _round = Duration(minutes: 3);

  final SessionNarrator _narrator = SessionNarrator(mode: SessionMode.steady);
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  String? _line;

  @override
  void initState() {
    super.initState();
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final List<NarrationEvent> events =
        _narrator.tick(elapsed: _elapsed, total: _round);
    // Aynı anda birden çok olay düşerse SONUNCUSU söylenir: üst üste iki
    // cümle sesli koçta anlaşılmaz, kullanıcı ikisini de kaçırır.
    final String? said =
        events.isEmpty ? null : widget.cues.say(events.last);
    if (!mounted) return;
    setState(() {
      if (said != null) _line = said;
      if (_elapsed < _round) _elapsed += const Duration(seconds: 1);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: IntervalTimer(elapsed: _elapsed, total: _round),
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
