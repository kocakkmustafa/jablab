import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'session_narrator.dart';
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

  static const String cuesAsset = 'assets/content/cues.en.json';

  /// Eklem anahtarı → kullanıcıya gösterilen ad. `RuleSet.stanceCoachedOnlyJoints`
  /// bu sözlükten okunmadan ürüne çıkamaz (bkz. [coachedNotScoredLabels]) —
  /// bir eklem kovası değişince (M-F-51 türü yeniden hesap) metnin eski
  /// kovayı anlatmaya devam etmesini engelleyen tek şey bu zorunluluk.
  static const Map<String, String> _jointLabels = <String, String>{
    'lead_hip': 'Lead hip position',
    'lead_knee': 'Lead knee position',
    'rear_knee': 'Rear knee position',
    'lead_thigh': 'Lead thigh placement',
    'rear_shin': 'Rear shin angle',
    'lead_shoulder': 'Lead shoulder position',
    'lead_shin': 'Lead shin angle',
    'rear_shoulder': 'Rear shoulder position',
    'rear_hip': 'Rear hip position',
    'rear_thigh': 'Rear thigh placement',
    'lead_elbow': 'Lead elbow angle',
    'rear_elbow': 'Rear elbow angle',
    'lead_upper_arm': 'Lead upper arm angle',
    'rear_upper_arm': 'Rear upper arm angle',
    'lead_forearm': 'Lead guard hand position',
    'rear_forearm': 'Rear guard hand position',
    'trunk_tilt': 'Torso lean',
  };

  /// Seans özetinin "coached but not scored" listesi — config'in
  /// `stanceCoachedOnlyJoints`'inden TÜRETİLİR, elle kopyalanmaz (J-033/
  /// rule 9). Beyansız eklem sessizce atlanmaz: sözlükte karşılığı olmayan
  /// bir anahtar, kovalar arasında bir eklem taşındığında fark edilmeden
  /// metnin bayatlamasını önlemek için burada FIRLATIR.
  List<String> coachedNotScoredLabels(RuleSet boxing) =>
      _labelsFor(boxing.stanceCoachedOnlyJoints);

  /// Jab'ın "coached but not scored" listesi (J-061). Duruştan AYRI tutulur
  /// çünkü kovalar farklı: jab'da öncü kol da koçlanan tarafta — tekniğin
  /// kendisi ölçülüyor ama eğitmen uzlaşısı olmadığı için yargılanmıyor.
  List<String> jabCoachedNotScoredLabels(RuleSet boxing) =>
      _labelsFor(boxing.jabCoachedOnlyJoints);

  List<String> _labelsFor(List<String> keys) => keys.map((String key) {
        final String? label = _jointLabels[key];
        if (label == null) {
          throw StateError('coachedOnlyJoints eklemi "$key" için etiket yok — '
              'ContentRepository._jointLabels güncellenmeli');
        }
        return label;
      }).toList(growable: false);

  /// Bir dersin tur planını alan kütüphanesinden arar (J-063).
  ///
  /// Kabuk modeli planı taşımaz — kabukta "round" alan sözlüğüdür ve
  /// `shell_candidate/README.md` sözleşmesi onu yasaklıyor. Çeviri katmanının
  /// işi tam bu: kabuk nötr kalır, plan app tarafında çözülür.
  RoundPlan? roundPlanFor(Library lib, String lessonId) {
    for (final Discipline d in lib.disciplines) {
      for (final Course c in d.courses) {
        for (final Lesson l in c.lessons) {
          if (l.id == lessonId) return l.roundPlan;
        }
      }
    }
    return null;
  }

  /// Replik kitabı. Yükleme sırasında eşleme doğrulanır: bir olayın repliği
  /// yoksa [CueBook.fromJson] FIRLATIR. Sessizce boş geçmek, o anı sonsuza
  /// kadar sessiz bırakırdı ve kullanıcı sessizliği "sorun yok" diye okur.
  Future<CueBook> loadCues() async => CueBook.fromJson(
      await rootBundle.loadString(cuesAsset), jabLabCueMapping);

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
