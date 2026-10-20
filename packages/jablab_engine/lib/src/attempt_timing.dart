import 'package:motion_core/motion_core.dart';

/// Zaman tanımının provenansı; model veya eşik kalibrasyonu değildir.
const String tempoTimingRevision = 'extension-to-peak@1';
const String tempoTimingWindow = 'EXTENSION->PEAK';

/// Yalnız tamamlanmış, benzersiz ve zaman sırası geçerli gözlenen aralık.
///
/// Haritaya dönüştürmeden listeyi okur: aynı faz adının tekrarı kaybolmamalı.
/// Birim µs → ms; gard/rotasyon beklemesi ve geri dönüş süreye katılmaz.
/// Bir gap/FPS yeterliliği veya fiziksel doğruluk kabulü sağlamaz.
double? extensionToPeakDurationMs(AttemptRun run) {
  if (run.outcome != AttemptOutcome.completed) return null;

  PhaseTransition? extension;
  PhaseTransition? peak;
  int? previousUs;
  for (final PhaseTransition transition in run.transitions) {
    if (previousUs != null && transition.tUs <= previousUs) return null;
    previousUs = transition.tUs;
    if (transition.toPhase == 'EXTENSION') {
      if (extension != null) return null;
      extension = transition;
    } else if (transition.toPhase == 'PEAK') {
      if (peak != null) return null;
      peak = transition;
    }
  }
  if (extension == null || peak == null || peak.tUs <= extension.tUs) {
    return null;
  }
  return (peak.tUs - extension.tUs) / 1000.0;
}
