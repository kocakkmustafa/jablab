import 'package:flutter/material.dart';

import '../shell_candidate/live_surface.dart';
import '../shell_candidate/session_flow.dart';
import '../shell_candidate/shell_models.dart';

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
  const SessionScreen({super.key, required this.lesson});

  final ShellLesson lesson;

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
        SessionStage.live => const _Live(),
        SessionStage.summary => const _Summary(),
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

class _Live extends StatelessWidget {
  const _Live();

  @override
  Widget build(BuildContext context) {
    // Motor hazır ve testli; besleyen kamera köprüsü değil. Bu yüzden yüzey
    // "noVerdict" durumunda ve SEBEBİ yazılı — ürünün "göremiyorum demek,
    // yanlış hüküm vermekten üstündür" ilkesinin ilk görünür uygulaması.
    return const LiveCoachSurface(
      state: LiveState.noVerdict,
      eventCount: 0,
      noVerdictReason:
          'The camera feed is not connected yet, so nothing is being judged. '
          'The analysis engine itself is built and tested.',
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) => const SessionSummaryView(
        eventCount: 0,
        // K8 (M-F-04): kalibrasyon kapısı geçilmeden sayı yok — bant bile
        // ölçüm olmadığı için boş.
        bands: <String, String>{
          'Stance': '—',
          'Balance': '—',
          'Footwork': '—',
        },
        // J-033: eğitmenler gard/kol pozisyonunda 36,7° ayrışıyor → koçlanır
        // ama SKORLANMAZ. Kullanıcı neden puan almadığını bilmeli.
        coachedNotScored: <String>[
          'Guard hand position',
          'Elbow angle',
          'Lead hip and thigh placement',
        ],
      );
}
