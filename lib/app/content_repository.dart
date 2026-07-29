import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:jablab_engine/jablab_engine.dart';

import '../shell_candidate/shell_models.dart';

/// İçeriği asset'lerden yükler ve kabuğun nötr modellerine çevirir.
///
/// **Çeviri katmanı bilinçli:** kabuk `Discipline`/`RuleSet` gibi alan
/// tiplerini görmez (bkz. `shell_candidate/README.md` sözleşmesi), yoksa
/// `motion_shell`'e terfi ettiğinde boks kural motorunu da beraberinde
/// taşırdı. Alan → kabuk dönüşümü **yalnız burada** olur.
final class ContentRepository {
  const ContentRepository();

  static const String libraryAsset = 'assets/content/library.json';
  static const String boxingRuleSetAsset = 'assets/rulesets/boxing@1.0.0.json';

  Future<({Library library, RuleSet boxing})> load() async {
    final Library lib = Library.fromJson(
        (jsonDecode(await rootBundle.loadString(libraryAsset)) as Map)
            .cast<String, dynamic>());
    final RuleSet boxing = RuleSet.fromJson(
        (jsonDecode(await rootBundle.loadString(boxingRuleSetAsset)) as Map)
            .cast<String, dynamic>());

    // Dürüstlük değişmezleri çalışma zamanında da denetlenir: bozuk bir
    // içerik güncellemesi testleri atlayıp cihaza ulaşırsa, uygulama sessizce
    // sahte kurs göstermek yerine burada patlar.
    final List<String> errs = lib.validate(<String, RuleSet>{'boxing': boxing});
    if (errs.isNotEmpty) {
      throw StateError('İçerik dürüstlük denetimi başarısız:\n${errs.join("\n")}');
    }
    return (library: lib, boxing: boxing);
  }

  ShellLibrary toShell(Library lib) => ShellLibrary(
        title: lib.productName,
        whyNotIntro: lib.whyNotIntro,
        items: lib.disciplines.map(_item).toList(growable: false),
        exclusions: lib.excluded
            .map((ExcludedItem e) => ShellExclusion(e.displayName, e.reason))
            .toList(growable: false),
      );

  ShellItem _item(Discipline d) => ShellItem(
        id: d.id,
        title: d.displayName,
        status: d.status == DisciplineStatus.live
            ? ItemStatus.live
            : ItemStatus.comingSoon,
        waveLabel: d.wave,
        blurb: d.blurb,
        measured: d.measured,
        notMeasured: d.notMeasured,
        courses: d.courses
            .map((Course c) => ShellCourse(
                  id: c.id,
                  title: c.displayName,
                  goal: c.goal,
                  level: c.level,
                  minutes: c.estimatedMinutes,
                  lessons: c.lessons
                      .map((Lesson l) => ShellLesson(
                            id: l.id,
                            title: l.displayName,
                            minutes: l.minutes,
                            subtitle: l.techniques.isEmpty
                                ? ''
                                : l.techniques.join(' · '),
                            lockedReason: l.lockedReason,
                          ))
                      .toList(growable: false),
                ))
            .toList(growable: false),
      );
}
