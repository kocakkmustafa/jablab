import 'package:flutter/material.dart';

import '../shell_candidate/shell_models.dart';

/// Canlı seans ekranı — **app'e özgü**, `motion_shell`'e terfi ETMEZ.
///
/// G5 iskelet aşamasında kamera hattı henüz bağlı değil (native köprü
/// ADR-002 kapsamında, koordinatör kuyruğunda). Ekran bunu **saklamıyor**:
/// sahte bir "analiz ediliyor" animasyonu göstermek yerine ne eksik olduğunu
/// yazıyor. Yarım özellik gizlenmez (`20-URETIM-SURECI §5`).
class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key, required this.lesson});

  final ShellLesson lesson;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.videocam_off_outlined, size: 40),
            const SizedBox(height: 16),
            Text('Live coaching is not wired up yet',
                key: const Key('session-not-ready'),
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              'The analysis engine is built and tested, but the camera bridge '
              'that feeds it real frames is still being built. Rather than show '
              'you a screen that looks like it is watching you, this says so.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text('Ready in this lesson', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              lesson.subtitle.isEmpty
                  ? 'Stance and guard checks'
                  : lesson.subtitle,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
