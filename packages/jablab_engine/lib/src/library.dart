import 'ruleset.dart';

// Bilgi mimarisi modeli — standart §2 (Kütüphane → Disiplin → Kurs → Ders).
//
// BU DOSYANIN ASIL İŞİ DOĞRULAMAKTIR. Ürün sözü net: "yarım özellik
// gizlenmez, kapsamdan çıkarılır" ve "SAHTE/boş kurs asla listelenmez".
// Bunlar niyet beyanı olarak kalırsa ilk içerik dalgasında delinir; burada
// mekanik değişmez olarak kodlanır ve testte zorlanır (standart §5: mekanik
// denetim betikle yapılır, LLM denetimiyle değil).
//
// NOT: bu blok bilinçli olarak `//` — `///` olduğunda altına eklenen ilk
// sınıfın dokümanı oluyordu (J-068'de RoundPlan'a yapıştı ve dosyayı
// anlatan metin bir plan sınıfını anlatır göründü).

/// Bir dersin TUR PLANI — kaç tur, ne kadar, arada ne kadar dinlenme (J-063).
///
/// **Neden içerikte, kodda değil:** ADR-004 gereği motor hiçbir boks sayısını
/// gömmez. Ama asıl sebep daha keskin: plan olmadığında canlı ekran sabit bir
/// 3 dakika koşuyordu ve "Twenty minutes" yazan ders 3 dakikada bitiyordu
/// (J-062, `beyan ≠ canlı`). Plan içerikte olduğu için artık beyanla
/// aritmetik olarak KARŞILAŞTIRILABİLİR — [totalSeconds] o karşılaştırmanın
/// zeminidir ve `Library.validate` onu zorlar.
///
/// [planProvenance] sayıların NEREDEN geldiğini taşır ve boş olamaz:
///  * `arithmetic` — tur sayısı/süresi içerikte beyanlı, kalan tek bilinmeyen
///    toplam süreden tam çıkıyor (icat yok);
///  * `advisor-draft-<tarih>` — antrenman-tasarımı danışmanının ilk-geçiş
///    taslağı; her sayının dayanağı var ama BAĞLAYICI doğrulama insan
///    antrenörüdür. Bu durumda `$planBoundary` neyin beklendiğini yazar.
///
/// Kaynağı beyan etmeyen bir plan, uydurulmuş bir planla aynı görünür — bu
/// alanın zorunlu olması, ikisini ayırt edilebilir tutan tek şey.
final class RoundPlan {
  const RoundPlan({
    required this.rounds,
    required this.roundSeconds,
    required this.restSeconds,
    required this.planProvenance,
  });

  factory RoundPlan.fromJson(Map<String, dynamic> j) => RoundPlan(
        rounds: (j['rounds'] as num).toInt(),
        roundSeconds: (j['roundSeconds'] as num).toInt(),
        restSeconds: (j['restSeconds'] as num?)?.toInt() ?? 0,
        planProvenance: j['planProvenance'] as String? ?? '',
      );

  final int rounds;
  final int roundSeconds;
  final int restSeconds;
  final String planProvenance;

  /// Çalışma + tur ARASI dinlenmeler. Son turdan sonra dinlenme YOKTUR —
  /// seans biter; `rounds * (round + rest)` yazmak her derse fazladan bir
  /// dinlenme ekler ve toplam beyanı sessizce aşar.
  int get totalSeconds =>
      rounds * roundSeconds + (rounds - 1) * restSeconds;

  bool get isSingleRound => rounds == 1;
}

/// ARALIK planı — patla/topla döngüsü (J-068).
///
/// **Neden [RoundPlan] DEĞİL, ayrı bir tip:** ikisinin toplam-süre matematiği
/// YAPISAL olarak farklı. `RoundPlan` son turdan sonra dinlenme SAYMAZ (seans
/// biter); aralıkta ise son patlamadan sonra da toparlanma VARDIR — soğuma o
/// döngünün parçası. Aynı tipe sığdırmak ya `RoundPlan`ın değişmezini kırar
/// ya aralığın toplamını yanlış hesaplar; ikisi de sessiz-yanlış üretir.
/// Bu yüzden `bursts * (burst + recover)` — eksiltme yok.
///
/// **Neden çalışma süresi yalnız PATLAMA:** ilerleme kapısı çalışılan süreyi
/// sorar; toparlanmayı da eklemek kullanıcıyı kapıdan hak etmeden geçirirdi
/// (turdaki dinlenme ile aynı ilke).
final class IntervalPlan {
  const IntervalPlan({
    required this.bursts,
    required this.burstSeconds,
    required this.recoverSeconds,
    required this.planProvenance,
  });

  factory IntervalPlan.fromJson(Map<String, dynamic> j) => IntervalPlan(
        bursts: (j['bursts'] as num).toInt(),
        burstSeconds: (j['burstSeconds'] as num).toInt(),
        recoverSeconds: (j['recoverSeconds'] as num).toInt(),
        planProvenance: j['planProvenance'] as String? ?? '',
      );

  final int bursts;
  final int burstSeconds;
  final int recoverSeconds;
  final String planProvenance;

  /// Patlama + toparlanma çiftlerinin toplamı. Son toparlanma DAHİL.
  int get totalSeconds => bursts * (burstSeconds + recoverSeconds);

  /// Kapının saydığı süre — yalnız patlamalar.
  int get workSeconds => bursts * burstSeconds;
}

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
    this.roundPlan,
    this.intervalPlan,
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
        roundPlan: j['roundPlan'] == null
            ? null
            : RoundPlan.fromJson((j['roundPlan'] as Map).cast<String, dynamic>()),
        intervalPlan: j['intervalPlan'] == null
            ? null
            : IntervalPlan.fromJson(
                (j['intervalPlan'] as Map).cast<String, dynamic>()),
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

  /// Aralık planı (patla/topla). `roundPlan` ile AYNI ANDA dolu olamaz —
  /// bir ders ya turludur ya aralıklı; ikisi birden, canlı ekranın hangi
  /// saati koşacağını belirsiz bırakır. `validate` bunu reddeder.
  final IntervalPlan? intervalPlan;

  /// Süreli çalışma dersinin tur planı; yoksa canlı aşama SÜRE KOŞAMAZ.
  /// `Library.validate` süreli-odaklı bir dersin plansız AÇIK kalmasını
  /// reddeder — plansız ders, beyan ettiği süreyi koşamayan derstir (J-062).
  final RoundPlan? roundPlan;

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
          _validateRoundPlan(l, errs);
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

  /// J-062/J-063: süreli çalışma dersi beyan ettiği süreyi KOŞABİLMELİ.
  ///
  /// Bu denetimin varlık sebebi ölçülmüş bir kusurdur: canlı ekran sabit 3
  /// dakika koşarken 7 kondisyon dersinin 7'si de kendi beyanından farklı
  /// çalışıyordu ve hiçbir test bunu görmüyordu. Beyan ile plan arasındaki
  /// aritmetik artık burada zorlanıyor — bir sonraki içerik turunda "süreyi
  /// biraz uzatalım" demek, planı düzeltmeden mümkün olmamalı.
  static void _validateRoundPlan(Lesson l, List<String> errs) {
    final RoundPlan? p = l.roundPlan;
    final IntervalPlan? ip = l.intervalPlan;
    final bool timed = l.focus == 'round' || l.focus == 'conditioning';

    if (p != null && ip != null) {
      errs.add('${l.id}: HEM tur HEM aralık planı var — canlı ekran hangi '
          'saati koşacağını bilemez');
      return;
    }

    if (ip != null) {
      if (ip.bursts < 1 || ip.burstSeconds < 1) {
        errs.add('${l.id}: aralık planı geçersiz (patlama ${ip.bursts}× '
            '${ip.burstSeconds}sn)');
      }
      if (ip.recoverSeconds < 1) {
        errs.add('${l.id}: aralıkta toparlanma 1sn\'den küçük olamaz — '
            'toparlanmasız "aralık" sürekli çalışmadır, farklı bir ders');
      }
      if (ip.planProvenance.trim().isEmpty) {
        errs.add('${l.id}: aralık planı planProvenance BOŞ');
      }
      if (l.minutes > 0 && ip.totalSeconds != l.minutes * 60) {
        errs.add('${l.id}: aralık toplamı ${ip.totalSeconds}sn ama ders '
            '${l.minutes} dk beyan ediyor — kullanıcıya söylenen süre ile '
            'koşulan süre AYNI olmalı');
      }
      return;
    }

    if (p == null) {
      // Kilitli ders planı taşımak zorunda değil — kilidin kendisi zaten
      // "bu dersi koşamıyoruz" beyanıdır ve sebebi kullanıcıya yazılıdır.
      if (timed && !l.isLocked) {
        errs.add('${l.id}: süreli çalışma dersi ama TUR PLANI YOK — beyan '
            'ettiği ${l.minutes} dakikayı koşamaz (J-062). Plan yaz ya da '
            'dersi isimli sebeple kilitle.');
      }
      return;
    }

    if (p.rounds < 1) {
      errs.add('${l.id}: tur sayısı ${p.rounds} — en az 1 olmalı');
    }
    if (p.roundSeconds < 1) {
      errs.add('${l.id}: tur süresi ${p.roundSeconds}sn — en az 1 olmalı');
    }
    if (p.restSeconds < 0) {
      errs.add('${l.id}: dinlenme ${p.restSeconds}sn negatif olamaz');
    }
    if (p.rounds == 1 && p.restSeconds != 0) {
      errs.add('${l.id}: tek turlu derste tur ARASI dinlenme olamaz '
          '(${p.restSeconds}sn) — hiç ara yok');
    }
    if (p.planProvenance.trim().isEmpty) {
      errs.add('${l.id}: planProvenance BOŞ — sayıların nereden geldiği '
          'beyan edilmeyen bir plan, uydurulmuş planla aynı görünür');
    }
    // `minutes` ile plan toplamı KASITLI olarak karşılaştırılmıyor.
    // Ölçüldü (J-063): `minutes` alanının tek bir anlamı YOK — bazı derste
    // çalışma+dinlenme (r3: 12), bazısında yalnız çalışma (r10: 10),
    // Foundations'ta ise DERS süresi (first_round: 8, turu 3 dakika).
    // Kurs düzeyinde alanın adı zaten `estimatedMinutes`. Bu yüzden otorite
    // `minutes` değil, dersin KENDİ İLERLEME KAPISI'dır (curriculum.json
    // `sessionMinutes`) — çapraz-dosya olduğu için `curriculum_binding_test`
    // içinde zorlanıyor: plan ÇALIŞMA süresi kapının istediğini vermezse
    // kullanıcı o dersin kapısını ASLA geçemez. Üç derste tam bu kusur
    // bulundu ve ship'ten önce düzeltildi.
  }
}
