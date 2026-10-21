import 'package:flutter/material.dart';

import 'self_guided_practice.dart';
import 'ui_language.dart';

/// Controlled by the lesson's in-memory state. No storage, camera or progress API.
class SelfGuidedPracticePanel extends StatelessWidget {
  const SelfGuidedPracticePanel({
    super.key,
    required this.practice,
    required this.attempt,
    required this.admitted,
    required this.onChanged,
  });

  final SelfGuidedPractice practice;
  final PracticeAttempt attempt;
  final bool Function() admitted;
  final ValueChanged<PracticeAttempt> onChanged;

  @override
  Widget build(BuildContext context) {
    String text(String en, String tr) =>
        UiLanguage.text(context, en: en, tr: tr);
    String copy(PracticeCopy value) => text(value.en, value.tr);
    final available = practice.offersMovement;
    final ended =
        attempt == PracticeAttempt.stopped ||
        attempt == PracticeAttempt.uncertain;
    return Card(
      key: const Key('self-guided-practice-panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text(
                'Optional beginner practice',
                'İsteğe bağlı başlangıç denemesi',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              available
                  ? text(
                      'Small, slow and non-contact only. Your technique and individual suitability are not verified.',
                      'Yalnız küçük, yavaş ve temassız. Tekniğin ve kişisel uygunluğun doğrulanmaz.',
                    )
                  : text(
                      'No movement trial is offered here. Use the written or grounded explanation below.',
                      'Burada hareket denemesi sunulmuyor. Aşağıdaki yazılı veya iki ayak yerde açıklama seçeneğini kullan.',
                    ),
              key: const Key('self-guided-practice-scope'),
            ),
            if (practice.sourceReview == PracticeSourceReview.pending)
              Text(
                text(
                  'The source review record is pending. A link or a self-report cannot complete it.',
                  'Kaynak inceleme kaydı bekliyor. Bağlantı veya öz beyan bu incelemeyi tamamlamaz.',
                ),
                key: const Key('self-guided-source-pending'),
              ),
            if (practice.sourceReview == PracticeSourceReview.writtenSource)
              Text(
                text(
                  'This task uses written source review; no source video is claimed as watched.',
                  'Bu görev yazılı kaynak incelemesine dayanır; kaynak videosu izlenmiş sayılmaz.',
                ),
              ),
            if (practice.sourceReview == PracticeSourceReview.videoSegments)
              Text(
                text(
                  'Source video sections informed this task; your own attempt is not observed.',
                  'Bu görevde kaynak video bölümlerinden yararlanıldı; senin denemen gözlemlenmiyor.',
                ),
              ),
            if (available ||
                practice.mode == SelfGuidedPracticeMode.conceptOnly)
              Text(copy(practice.task), key: const Key('self-guided-task')),
            Text(copy(practice.observe), key: const Key('self-guided-observe')),
            Text(
              text('Safety and stopping', 'Sınırlar ve durma'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(copy(practice.safety), key: const Key('self-guided-safety')),
            Text(
              text(
                'A smaller or written option',
                'Daha küçük veya yazılı seçenek',
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              copy(practice.adaptation),
              key: const Key('self-guided-adaptation'),
            ),
            Text(
              text(
                'Your self-report stays in this lesson visit and is cleared on exit or interruption. It does not change written progress, a technique grade or clearance.',
                'Beyanın yalnız bu ders ziyareti içinde kalır; çıkış veya kesintide temizlenir. Yazılı ilerlemeyi, teknik notunu veya uygunluk onayını değiştirmez.',
              ),
              key: const Key('self-guided-unsaved'),
            ),
            if (ended)
              Text(
                text(
                  'This movement trial has ended for this visit. Continue with the written alternative.',
                  'Bu ziyaretin hareket denemesi sona erdi. Yazılı alternatifle devam et.',
                ),
                key: const Key('self-guided-ended'),
              ),
            RadioGroup<PracticeAttempt>(
              groupValue: attempt,
              onChanged: (value) {
                if (value == null || ended || !admitted()) return;
                if (!available && value == PracticeAttempt.attempted) return;
                onChanged(value);
              },
              child: Column(
                children: [
                  for (final value in PracticeAttempt.values)
                    RadioListTile<PracticeAttempt>(
                      key: Key('self-guided-attempt-${value.name}'),
                      value: value,
                      enabled:
                          !ended &&
                          admitted() &&
                          (available || value != PracticeAttempt.attempted),
                      title: Text(switch (value) {
                        PracticeAttempt.unrecorded => text(
                          'Not recorded',
                          'Beyan edilmedi',
                        ),
                        PracticeAttempt.attempted => text(
                          'I tried the optional task; correctness is unverified',
                          'İsteğe bağlı görevi denedim; doğruluğu doğrulanmadı',
                        ),
                        PracticeAttempt.skipped => text(
                          'I skipped movement and used the alternative',
                          'Hareketi atlayıp alternatifini kullandım',
                        ),
                        PracticeAttempt.stopped => text(
                          'I stopped; no harder retry this session',
                          'Durdum; bu oturumda zor görevi yeniden denemiyorum',
                        ),
                        PracticeAttempt.uncertain => text(
                          'Uncertain; I will not add movement',
                          'Belirsiz; hareket eklemeyeceğim',
                        ),
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
