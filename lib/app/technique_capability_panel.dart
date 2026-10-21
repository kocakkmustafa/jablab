import 'package:flutter/material.dart';

import 'technique_observation.dart';
import 'technique_task.dart';
import 'ui_language.dart';

/// The shipping panel cannot accept a replay provider or turn inference on.
/// Lesson reading/self-report stays separate from movement acceptance.
class TechniqueCapabilityPanel extends StatelessWidget {
  const TechniqueCapabilityPanel({
    super.key,
    required this.courseId,
    required this.lessonId,
  });
  final String courseId, lessonId;

  @override
  Widget build(BuildContext context) {
    final task = TechniqueTasks.forLesson(courseId, lessonId);
    final availability = TechniqueObservationSession.productionForLesson(
      courseId,
      lessonId,
    ).availability;
    String text(String en, String tr) =>
        UiLanguage.text(context, en: en, tr: tr);
    return Card(
      key: const Key('technique-capability-panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text('Movement feedback', 'Hareket geri bildirimi'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              availability.kind == TechniqueObservationKind.calibrationRequired
                  ? text('Calibration required', 'Kalibrasyon gerekli')
                  : text(
                      'Automatic assessment is not supported for this lesson.',
                      'Bu ders için otomatik hareket değerlendirmesi desteklenmiyor.',
                    ),
              key: const Key('technique-capability-status'),
            ),
            if (task != null) ...[
              Text(text('Lesson phases', 'Dersin aşamaları')),
              Text(
                task.phases
                    .map(
                      (phase) => switch (phase) {
                        TechniquePhase.preparation => text(
                          'Preparation',
                          'Hazırlık',
                        ),
                        TechniquePhase.extension => text('Extension', 'Uzatma'),
                        TechniquePhase.retraction => text(
                          'Retraction',
                          'Geri toplama',
                        ),
                        TechniquePhase.returnToStart => text(
                          'Return to start',
                          'Başlangıca dönüş',
                        ),
                      },
                    )
                    .join(' → '),
                key: const Key('technique-task-phases'),
              ),
              Text(
                text(
                  'Camera assessment awaits a calibrated model and independent review. No movement has been measured here.',
                  'Kamera değerlendirmesi kalibre edilmiş model ve bağımsız incelemeyi bekliyor. Burada hareket ölçülmedi.',
                ),
              ),
            ],
            Text(
              text(
                'Your lesson record remains your own report.',
                'Ders kaydı kendi beyanın olarak kalır.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
