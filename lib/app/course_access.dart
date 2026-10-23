import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ui_language.dart';

/// Courses gated by the shared Motion paywall (founder decision 2026-10-23,
/// option A): the first module / about the first third of every course is
/// free; the remaining lessons and the independent practice stage need a
/// subscription; saved progress always stays readable.
enum GatedCourse {
  boxing,
  kickboxing,
  muayThai,
  karate,
  taikyoku,
  taiChi,
  yang16,
}

/// Free lessons from the start of each course, in course order.
///
/// Boxing: the first two modules (start + footwork, 10 of 39); the rounds and
/// integration modules (independent practice) are paid. Others: about one
/// third of the course, rounded to the nearest lesson.
const Map<GatedCourse, int> freeLessonCount = <GatedCourse, int>{
  GatedCourse.boxing: 10,
  GatedCourse.kickboxing: 5,
  GatedCourse.muayThai: 5,
  GatedCourse.karate: 5,
  GatedCourse.taikyoku: 3,
  GatedCourse.taiChi: 5,
  GatedCourse.yang16: 6,
};

/// Host-supplied access state for the course pages.
///
/// While sales are closed ([salesOpen] false) every lesson stays open: a
/// lock nobody can buy past would be a dead end. With sales open, a lesson
/// past [freeLessonCount] opens only for a verified membership ([entitled]).
class CourseAccess {
  CourseAccess({
    required this.salesOpen,
    required this.unlock,
    ValueNotifier<bool>? entitled,
  }) : entitled = entitled ?? ValueNotifier<bool>(false);

  /// Everything open; the current release policy until sales are enabled.
  factory CourseAccess.open() =>
      CourseAccess(salesOpen: false, unlock: (_) async => true);

  final bool salesOpen;

  /// True only after the store/server verified an active membership.
  final ValueNotifier<bool> entitled;

  /// Account → membership (purchase / restore) → verified status.
  final Future<bool> Function(BuildContext context) unlock;

  bool isFree(GatedCourse course, int lessonIndex) =>
      lessonIndex < freeLessonCount[course]!;

  bool allows(GatedCourse course, int lessonIndex) =>
      !salesOpen || entitled.value || isFree(course, lessonIndex);

  /// Opens the paywall for a locked lesson. Returns true when the lesson may
  /// now be opened.
  Future<bool> requestLesson(
    BuildContext context,
    GatedCourse course,
    int lessonIndex,
  ) async {
    if (allows(course, lessonIndex)) return true;
    final bool? proceed = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext sheet) => const PaywallSheet(),
    );
    if (proceed != true || !context.mounted) return false;
    final bool active = await unlock(context);
    if (active) entitled.value = true;
    return active;
  }
}

/// Short, honest paywall: what is free, what the subscription opens, that
/// saved progress stays readable, and where to buy or restore.
class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      key: const Key('paywall-sheet'),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            UiLanguage.text(
              context,
              en: 'Included with a subscription',
              tr: 'Abonelikle açılır',
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            UiLanguage.text(
              context,
              en: 'The first lessons of every course are free. A JabLab or Motion+ subscription opens the remaining lessons and the independent practice stage. Your saved progress stays readable either way.',
              tr: 'Her kursun ilk dersleri ücretsizdir. JabLab veya Motion+ aboneliği kalan dersleri ve bağımsız pratik aşamasını açar. Kayıtlı ilerlemen her durumda okunabilir kalır.',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            UiLanguage.text(
              context,
              en: 'New subscribers get a 14-day free trial. Prices come from your store, and you can cancel anytime in your store’s subscription settings.',
              tr: 'Yeni abonelere 14 gün ücretsiz deneme sunulur. Fiyatları mağazan gösterir; aboneliği mağazanın abonelik ayarlarından istediğin zaman iptal edebilirsin.',
            ),
            key: const Key('paywall-trial-terms'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('paywall-subscribe'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              UiLanguage.text(
                context,
                en: 'See subscription options or restore purchases',
                tr: 'Abonelik seçeneklerini gör veya satın alımları geri yükle',
              ),
            ),
          ),
          TextButton(
            key: const Key('paywall-not-now'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              UiLanguage.text(context, en: 'Not now', tr: 'Şimdi değil'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Trailing lock for a lesson row that needs a subscription.
class LessonLockBadge extends StatelessWidget {
  const LessonLockBadge({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: UiLanguage.text(
      context,
      en: 'Included with subscription',
      tr: 'Abonelikle açılır',
    ),
    child: const ExcludeSemantics(child: Icon(Icons.lock_outline)),
  );
}
