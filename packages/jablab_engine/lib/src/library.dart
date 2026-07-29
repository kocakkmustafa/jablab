import 'ruleset.dart';

/// Bilgi mimarisi modeli — standart §2 (Kütüphane → Disiplin → Kurs → Ders).
///
/// **Bu dosyanın asıl işi doğrulamaktır.** Ürün sözü net: "yarım özellik
/// gizlenmez, kapsamdan çıkarılır" ve "SAHTE/boş kurs asla listelenmez".
/// Bunlar niyet beyanı olarak kalırsa ilk içerik dalgasında delinir; burada
/// **mekanik değişmez** olarak kodlanır ve testte zorlanır (standart §5:
/// mekanik denetim betikle yapılır, LLM denetimiyle değil).
final class Lesson {
  const Lesson({
    required this.id,
    required this.displayName,
    required this.techniques,
    this.combinations = const <String>[],
    this.errorFocus = const <String>[],
    this.focus,
    this.minutes = 0,
    this.lockedReason,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        displayName: j['displayName'] as String,
        techniques:
            ((j['techniques'] as List?) ?? const <dynamic>[]).cast<String>(),
        combinations:
            ((j['combinations'] as List?) ?? const <dynamic>[]).cast<String>(),
        errorFocus:
            ((j['errorFocus'] as List?) ?? const <dynamic>[]).cast<String>(),
        focus: j['focus'] as String?,
        // Kilit, İÇERİĞİN kendi beyanı. Bir dersi kilitlemek "yakında" demek
        // değil: o dersin hükmünü verecek ÖLÇÜM yok demek. Sebep kullanıcıya
        // gösterilmek üzere burada taşınır; sebepsiz kilit sessizce pazarlama
        // rozetine dönüşür.
        lockedReason:
            j['status'] == 'locked' ? j['lockedReason'] as String : null,
        minutes: (j['minutes'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String displayName;
  final List<String> techniques;
  final List<String> combinations;
  final List<String> errorFocus;
  final String? focus;
  final int minutes;

  /// Doluysa ders KİLİTLİ ve bu cümle sebebidir (kullanıcıya gösterilir).
  final String? lockedReason;

  bool get isLocked => lockedReason != null;
}

final class Course {
  const Course({
    required this.id,
    required this.displayName,
    required this.lessons,
    this.level = 'all',
    this.goal = '',
    this.estimatedMinutes = 0,
  });

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'] as String,
        displayName: j['displayName'] as String,
        lessons: ((j['lessons'] as List?) ?? const <dynamic>[])
            .map((dynamic l) => Lesson.fromJson((l as Map).cast<String, dynamic>()))
            .toList(growable: false),
        level: j['level'] as String? ?? 'all',
        goal: j['goal'] as String? ?? '',
        estimatedMinutes: (j['estimatedMinutes'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String displayName;
  final List<Lesson> lessons;
  final String level;
  final String goal;
  final int estimatedMinutes;
}

enum DisciplineStatus { live, comingSoon }

final class Discipline {
  const Discipline({
    required this.id,
    required this.displayName,
    required this.status,
    required this.wave,
    required this.courses,
    required this.measured,
    required this.notMeasured,
    this.rulesetId,
    this.blurb = '',
  });

  factory Discipline.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> h =
        ((j['honesty'] as Map?) ?? const <String, dynamic>{}).cast<String, dynamic>();
    return Discipline(
      id: j['id'] as String,
      displayName: j['displayName'] as String,
      status: (j['status'] as String?) == 'live'
          ? DisciplineStatus.live
          : DisciplineStatus.comingSoon,
      wave: j['wave'] as String? ?? '',
      rulesetId: j['rulesetId'] as String?,
      blurb: j['blurb'] as String? ?? '',
      courses: ((j['courses'] as List?) ?? const <dynamic>[])
          .map((dynamic c) => Course.fromJson((c as Map).cast<String, dynamic>()))
          .toList(growable: false),
      measured: ((h['measured'] as List?) ?? const <dynamic>[]).cast<String>(),
      notMeasured:
          ((h['notMeasured'] as List?) ?? const <dynamic>[]).cast<String>(),
    );
  }

  final String id;
  final String displayName;
  final DisciplineStatus status;
  final String wave;
  final String? rulesetId;
  final String blurb;
  final List<Course> courses;

  /// "Bu öğede neler ölçülür" — standart §2 dürüstlük kutusu.
  final List<String> measured;

  /// "…ve neler ÖLÇÜLMEZ." Boş bırakılamaz: ölçemediğimizi söylemek,
  /// ölçüyormuş gibi yapmaktan her zaman üstündür.
  final List<String> notMeasured;
}

final class ExcludedItem {
  const ExcludedItem(this.id, this.displayName, this.reason);

  factory ExcludedItem.fromJson(Map<String, dynamic> j) => ExcludedItem(
        j['id'] as String,
        j['displayName'] as String,
        j['reason'] as String,
      );

  final String id;
  final String displayName;

  /// Gerekçesiz kapsam-dışı madde olamaz — "Neden yok?" sayfasının tamamı
  /// bu alandan oluşuyor.
  final String reason;
}

final class Library {
  const Library({
    required this.productName,
    required this.disciplines,
    required this.excluded,
    required this.whyNotIntro,
  });

  factory Library.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> why =
        ((j['whyNotIncluded'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>();
    return Library(
      productName: j['productName'] as String? ?? '',
      disciplines: ((j['disciplines'] as List?) ?? const <dynamic>[])
          .map((dynamic d) => Discipline.fromJson((d as Map).cast<String, dynamic>()))
          .toList(growable: false),
      excluded: ((why['items'] as List?) ?? const <dynamic>[])
          .map((dynamic e) => ExcludedItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
      whyNotIntro: why['intro'] as String? ?? '',
    );
  }

  final String productName;
  final List<Discipline> disciplines;
  final List<ExcludedItem> excluded;
  final String whyNotIntro;

  Iterable<Discipline> get live =>
      disciplines.where((Discipline d) => d.status == DisciplineStatus.live);

  /// Kütüphanenin dürüstlük değişmezlerini denetler.
  ///
  /// Boş liste = geçerli. Her ihlal, kullanıcıya verilmiş somut bir sözün
  /// çiğnenmesidir — bu yüzden uyarı değil, **hata** olarak döner.
  List<String> validate(Map<String, RuleSet> ruleSets) {
    final List<String> errs = <String>[];

    for (final Discipline d in disciplines) {
      if (d.notMeasured.isEmpty) {
        errs.add('${d.id}: "neler ölçülmez" kutusu boş — standart §2 zorunlu');
      }

      if (d.status == DisciplineStatus.comingSoon) {
        if (d.courses.isNotEmpty) {
          errs.add('${d.id}: "yakında" disiplinde ${d.courses.length} kurs var '
              '— sahte kurs listelenemez');
        }
        continue;
      }

      if (d.courses.isEmpty) {
        errs.add('${d.id}: "canlı" ama hiç kursu yok');
      }
      if (d.measured.isEmpty) {
        errs.add('${d.id}: canlı disiplinde "neler ölçülür" boş');
      }

      final RuleSet? rs = d.rulesetId == null ? null : ruleSets[d.rulesetId];
      if (d.rulesetId != null && rs == null) {
        errs.add('${d.id}: kural seti "${d.rulesetId}" yüklenemedi');
      }

      for (final Course c in d.courses) {
        if (c.lessons.isEmpty) {
          errs.add('${c.id}: boş kurs listelenemez');
        }
        for (final Lesson l in c.lessons) {
          if (rs == null) continue;
          for (final String t in l.techniques) {
            if (rs.technique(t) == null) {
              errs.add('${l.id}: kural setinde olmayan tekniğe atıf → "$t"');
            }
          }
          for (final String combo in l.combinations) {
            if (!rs.combinations.any((CombinationConfig x) => x.id == combo)) {
              errs.add('${l.id}: tanımsız kombinasyon → "$combo"');
            }
          }
          for (final String code in l.errorFocus) {
            if (!rs.errors.any((ErrorConfig x) => x.code == code)) {
              errs.add('${l.id}: tanımsız hata kodu → "$code"');
            }
          }
        }
      }
    }

    for (final ExcludedItem x in excluded) {
      if (x.reason.trim().length < 20) {
        errs.add('${x.id}: kapsam-dışı madde yeterli gerekçe taşımıyor');
      }
    }

    return errs;
  }
}
