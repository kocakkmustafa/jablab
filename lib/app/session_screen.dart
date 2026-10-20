import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:jablab_engine/jablab_engine.dart' show IntervalPlan, RoundPlan;
import 'package:motion_camera/motion_camera.dart' show CameraFailure;

import '../shell_candidate/live_surface.dart';
import '../shell_candidate/session_flow.dart';
import '../shell_candidate/shell_models.dart';
import 'course_locale.dart';
import 'design_tokens.dart';
import 'session_narrator.dart';
import 'live_honesty.dart';
import 'live_jab_controller.dart';
import 'live_session_failure.dart';
import 'rehearse_material.dart';
import 'session_store.dart';
import 'skeleton_overlay.dart';
import 'teach_material.dart';
import 'teach_locale.dart';
import 'summary_locale.dart';
import 'ui_language.dart';

/// Canlı seans ekranı — **app'e özgü**, `motion_shell`'e terfi ETMEZ.
///
/// Kabuk parçaları (`SessionFlowScaffold`, `LiveCoachSurface`,
/// `SessionSummaryView`, `IntervalTimer`) buradan besleniyor; boksa özgü olan
/// yalnız içerik: cue metinleri, sayılan olayın adı, kamera önizlemesi.
/// Görsel giydirme `jablabSessionTheme`den (design_tokens.dart) — kabuk
/// parçaları frozen olduğu için `Theme(data:, child:)` sarmalıyla dışarıdan
/// besleniyor (design turu Parça 2, 2026-08-06).
///
/// ⚠️ Kamera GÖRÜNTÜSÜ (piksel akışı) henüz bağlı değil — Texture tabanlı
/// önizleme bilinçli ertelendi (`docs/70-KAMERA-KOPRUSU-SOZLESMESI.md`).
/// Ekran bunu **saklamıyor**: `skeleton_overlay.dart`'ın kamera-yer-tutucusu
/// bunu açıkça yazıyor. **Kamera ANALİZİ** (poz çıkarımı, `LiveJabController`)
/// bundan AYRI ve BAĞLI — motor kişiyi görüyor, yalnız o görüntüyü ekrana
/// basmıyoruz; iskelet çizimi bunun kanıtı (gerçek koordinatlardan).
class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    required this.lesson,
    required this.cues,
    required this.coachedNotScored,
    required this.bands,
    required this.plan,
    required this.teachMaterial,
    required this.rehearseMaterial,
    this.intervalPlan,
    this.store,
    this.liveJab,
    this.liveJabSetupFailure,
    this.milestoneEvery,
    this.accountUserId,
    this.resourceAdmission,
  });

  final ShellLesson lesson;

  /// Dersin tur planı (J-063). `null` ise canlı aşama SÜRE KOŞMAZ ve bunu
  /// söyler — eskiden burada sabit 3 dakika koşuluyordu ve "Twenty minutes"
  /// yazan ders 3 dakikada bitiyordu (J-062, `beyan ≠ canlı`).
  ///
  /// Bugün plansız bir dersin AÇIK olması `Library.validate` tarafından
  /// reddediliyor; yani bu yol pratikte yalnız kilitli/plansız bir derse
  /// doğrudan gidilirse görünür. Sessizce bir süre uydurmak yerine
  /// görünür kalması bilinçli.
  final RoundPlan? plan;

  /// Aralık planı (J-068). `plan` ile aynı anda dolu olamaz — `validate`
  /// bunu içerik tarafında reddediyor.
  final IntervalPlan? intervalPlan;

  /// Seans geçmişi (J-064). `null` iken akış aynen çalışır, yalnız KAYIT
  /// tutulmaz — testlerde ve plansız (öğretme) derslerinde böyle.
  final SessionStore? store;

  /// Current identity from the host; a session belongs to its opening scope.
  final ValueListenable<String?>? accountUserId;
  final ValueListenable<bool>? resourceAdmission;

  /// Replik kitabı app'ten enjekte edilir; kabuk sözlüğü GÖRMEZ.
  final CueBook cues;

  /// KAMERA hattı (J-096) — `null` ise ders kamerasız koşar.
  ///
  /// Opsiyonel olması bir geçici çözüm DEĞİL, kalıcı tasarım: Fitness
  /// dersleri kamerasız TAM çalışıyor ve kanıtlı. Kamerayı zorunlu kılmak
  /// çalışan bir hattı olmayan bir donanıma bağımlı yapardı.
  final LiveJabController? liveJab;

  /// Hat KURULAMADI (model çıkarılamadı, I/O…) — ama ders yine AÇILIR.
  ///
  /// Kurulum hatasının dersi açılmaz yapması sessiz bir çıkmaz sokaktı:
  /// kullanıcı derse dokunuyor ve hiçbir şey olmuyordu. Saat kamerasız da
  /// koşuyor; eksik olan analiz ve o BEYAN EDİLİYOR.
  final LiveSessionFailure? liveJabSetupFailure;

  /// Öğretme aşamasının materyali (J-094) —
  /// `ContentRepository.teachMaterialFor` üretir, ekran ondan TÜRETİR.
  ///
  /// Zorunlu ve nullable DEĞİL: `null` geçilebilse "materyal yok" ile
  /// "kimse sormadı" aynı değere düşerdi ve ekran ikisini ayırt edemezdi —
  /// bu ekranın düzelttiği kusurun ta kendisi.
  final TeachMaterial teachMaterial;

  /// Prova aşamasının materyali (J-247) —
  /// `ContentRepository.rehearseMaterialFor` üretir, ekran ondan TÜRETİR.
  ///
  /// `teachMaterial` ile aynı sebeple zorunlu ve nullable DEĞİL: `null`
  /// geçilebilse "teknik listelenmemiş" ile "kimse sormadı" aynı değere
  /// düşerdi. Bu aşama tam olarak o ayrımı kaybettiği için 19 derste tek
  /// cümle gösteriyordu.
  final RehearseMaterial rehearseMaterial;

  /// Kaç sayımda bir kilometre taşı söylenir — **yalnız test dikişi**
  /// (J-121). Üretimde `null` ve `SessionNarrator`ın kendi sabiti (25)
  /// geçerli; bu alan o sabiti DEĞİŞTİRMİYOR, yalnız testin ona daha erken
  /// ulaşmasını sağlıyor.
  ///
  /// ## Neden gerekti
  ///
  /// Zincirin son halkası — *ekran `_completedJabs`i `tick(eventCount:)`e
  /// geçiriyor mu* — yalnız sayaç 25'e ulaşınca gözlenebiliyordu ve o
  /// noktaya varan widget testi **koşum tarafında 10 dakikalık zaman
  /// aşımına** düşüyordu (ölçüldü: 20 tekrar 2 sn, 25 tekrar zaman aşımı;
  /// ayrı dosyada da, derlenen hâlde de). Sebep üründe DEĞİL — motor
  /// profili doğrusal ölçüldü (100→800 kare 23 ms).
  ///
  /// İki seçenek vardı: kanıtı "teftişle doğrulandı" diye bırakmak, ya da
  /// kanıtlanamayanı kanıtlanabilir yapmak. Bu depo ikincisini seçmiş
  /// durumda ve emsali çok: `storeOverride` · `loadStringOverride` ·
  /// `seenOverride` · `camera` · `engineFactory`. Hepsi üretimde `null`,
  /// hepsi TEK yerde okunuyor.
  final int? milestoneEvery;

  /// `ContentRepository.coachedNotScoredLabels` — config'in
  /// `stanceCoachedOnlyJoints`'inden türetilir (J-033/rule 9); burada
  /// elle kopyalanmaz ki kova kararı değişince metin sessizce bayatlamasın.
  final List<String> coachedNotScored;

  /// Özet bantları — `RuleSet.trackedComponents`tan TÜREVİ (J-144).
  final Map<String, String> bands;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  SessionStage _stage = SessionStage.teach;
  late final String? _openingOwner;
  bool _ownerRetired = false;
  ModalRoute<void>? _ownerRoute;
  NavigatorState? _ownerNavigator;

  @override
  void initState() {
    super.initState();
    _openingOwner = widget.accountUserId?.value;
    widget.accountUserId?.addListener(_onOwnerChanged);
    widget.resourceAdmission?.addListener(_onAdmissionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ownerRoute = ModalRoute.of<void>(context);
    _ownerNavigator = Navigator.of(context);
    _onAdmissionChanged();
    _onOwnerChanged();
  }

  void _onAdmissionChanged() {
    if (widget.resourceAdmission?.value == false) _retireOwner();
  }

  void _onOwnerChanged() {
    if (widget.accountUserId?.value != _openingOwner) _retireOwner();
  }

  @override
  void didUpdateWidget(covariant SessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.resourceAdmission, widget.resourceAdmission)) {
      oldWidget.resourceAdmission?.removeListener(_onAdmissionChanged);
      widget.resourceAdmission?.addListener(_onAdmissionChanged);
      _retireOwner();
    }
    if (identical(oldWidget.accountUserId, widget.accountUserId)) return;
    oldWidget.accountUserId?.removeListener(_onOwnerChanged);
    widget.accountUserId?.addListener(_onOwnerChanged);
    _retireOwner();
  }

  void _retireOwner() {
    if (_ownerRetired) return;
    _ownerRetired = true;
    unawaited(widget.liveJab?.stop());
    final ModalRoute<void>? route = _ownerRoute;
    final NavigatorState? navigator = _ownerNavigator;
    // Remove this route even when another route covers it. A blind pop would
    // remove the user's unrelated foreground screen and retain the old owner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          navigator == null ||
          !navigator.mounted ||
          route == null ||
          !route.isActive) {
        return;
      }
      if (!route.isFirst) navigator.removeRoute(route);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Canlı aşamada sayılan olay — `null` = **analiz hiç koşmadı** (J-156).
  ///
  /// Kamerasız derste ya da kurulum başarısızsa `null` kalır ve özet hiçbir
  /// sayı göstermez. Analiz koştuysa gerçek sayı gelir — **0 dahil**, çünkü
  /// o zaman sıfır DOĞRUDUR: ölçtük, hiç yumruk yoktu.
  int? _countedEvents;

  /// Canlı aşamanın bildirdiği son durum — özet aşamasına geçerken
  /// kaydedilir. Canlı bileşenin içinde tutulup orada yazmak, ekran
  /// dispose edilirken async yazma yapmak olurdu.
  int _workedSeconds = 0;
  int _roundsCompleted = 0;

  /// TAM ÇÖZÜLMÜŞ birim etiketi — [_record]in `unitLabel` alanıyla AYNI
  /// desen (`plan != null ? 'round' : 'interval'`), artık tekil/çoğul da
  /// dahil. Kabuğa (`SessionSummaryView`, M-F-25 terfi kapısı) yalnız bu
  /// ÇÖZÜLMÜŞ dize geçer — çoğulluk kararı app'te kalır (İngilizce'ye
  /// özgü "N==1 ise tekil" kuralı, dile göre değişir).
  String get _unitLabel {
    final String singular = widget.plan != null ? 'round' : 'interval';
    return _roundsCompleted == 1 ? singular : '${singular}s';
  }

  void _advance() {
    if (_ownerRetired || widget.resourceAdmission?.value == false) return;
    final bool leavingLive = _stage == SessionStage.live;
    final int i = SessionStage.values.indexOf(_stage);
    if (i + 1 < SessionStage.values.length) {
      setState(() => _stage = SessionStage.values[i + 1]);
    } else {
      Navigator.of(context).pop();
    }
    // Kayıt canlı aşamadan ÇIKARKEN yazılır — seans sonuna ulaşılmasa bile.
    // "Yarıda bıraktı" bir veridir; yalnız tamamlananı kaydetmek, kullanıcının
    // gerçekten yaptığı işi görünmez kılardı.
    if (leavingLive) unawaited(_record());
  }

  /// GERİ ÇIKIŞTA DA KAYDET (J-192, koordinatör hükmü 14:05).
  ///
  /// Ölçüldü: kayıt yalnız `_next()` yolunda yazılıyordu, yani kullanıcı
  /// canlı turun ortasında **geri okuna** basarsa yaptığı iş **kayboluyordu**
  /// — ileri gitseydi *"tamamlanmadı"* diye kaydedilecekti.
  ///
  /// > **Aynı çalışma, çıkış YÖNÜNE göre var ya da yok.**
  ///
  /// Belirleyici olan *"geri = vazgeçme mi"* değil, bu **asimetri**: sistem
  /// vazgeçmeyi **zaten** kaydediyor, sadece **bir** kapıdan çıkanı kaydedip
  /// diğerinden çıkanı kaybediyordu. Ve tutarsızlık kullanıcı tarafında
  /// **görünmez** — *kullanıcının göremediği bir kural, kural değil kazadır.*
  ///
  /// `dispose` seçildi çünkü **her** çıkış yolunu kapsıyor: geri oku, kenar
  /// jesti, programatik pop. `PopScope` yalnız birini yakalardı.
  ///
  /// **Çift kayıt riski yok:** `_next()` canlıdan çıkarken aşamayı zaten
  /// ilerletmiş olur (`summary`), bu yüzden buradaki koşul tutmaz — ve o
  /// `session_exit_test`in pozitif ikiziyle ölçülüyor.
  @override
  void dispose() {
    widget.accountUserId?.removeListener(_onOwnerChanged);
    widget.resourceAdmission?.removeListener(_onAdmissionChanged);
    if (_stage == SessionStage.live) unawaited(_record());
    super.dispose();
  }

  Future<void> _record() async {
    final SessionStore? store = widget.store;
    final RoundPlan? plan = widget.plan;
    // Plansız (öğretme) derste çalışma süresi diye bir şey YOK — sıfır
    // saniyelik kayıt yazmak, geçmişi anlamsız satırlarla doldurmak olurdu.
    if (_ownerRetired ||
        widget.resourceAdmission?.value == false ||
        widget.accountUserId?.value != _openingOwner ||
        store == null ||
        (plan == null && widget.intervalPlan == null) ||
        _workedSeconds <= 0) {
      return;
    }
    try {
      await store.append(
        SessionRecord(
          lessonId: widget.lesson.id,
          completedAt: DateTime.now(),
          workedSeconds: _workedSeconds,
          unitsCompleted: _roundsCompleted,
          plannedUnits: plan?.rounds ?? widget.intervalPlan!.bursts,
          // Birim KAYIT BAŞINA (çekirdek sözleşmesi): aynı ilerleme ekranında
          // tur-birimli ve aralık-birimli ders yan yana durabilir.
          unitLabel: plan != null ? 'round' : 'interval',
          // SINIF, YAZMA ANINDA (J-095). Bugün JabLab'ta hiçbir ders
          // puanlanmıyor: kalibrasyon kapısı (K8) geçilmedi ve kamera bağlı
          // değil. `'unscored'` bunu yazma anında mühürlüyor — ders yarın terfi
          // ederse YENİ kayıtlar farklı sınıf taşır ve bugünküler doğru şekilde
          // puansız kalır. Sınıfı sonradan HESAPLAMAK geçmişi sessizce yeniden
          // yorumlamak olurdu (çekirdeğin kendi uyarısı).
          //
          // Ayrıca en-az-yetki: yalnız `'scored'` puanlı okunur, bu değer değil.
          lessonClass: 'unscored',
          // `unmeasuredUnits` SIFIR ve bu bir varsayım değil: o alan "motorun
          // GÖRDÜĞÜ ama yargılayamadığı" birimler için (kadraj/ışık/takip).
          // JabLab'ta kamera HİÇ yok — tur sayısı saatten gelen bir olgu, kamera
          // ölçümü değil. Yargılanmamışlığı taşıyan alan `lessonClass`; buraya
          // yazmak iki farklı olguyu karıştırırdı.
        ),
      );
    } on SessionStoreRetiredException {
      // An admitted append can settle after retirement. The owner barrier
      // drains it before erase; the retired route must not report a new record.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ownerRetired) return const SizedBox.shrink();
    // Theme(sarma): kabuk parçaları (SessionFlowScaffold + içindekiler)
    // frozen — `JColors`/`JText`i doğrudan okuyamaz, yalnız
    // `Theme.of(context)` üzerinden beslenir (bkz. sınıf dokümanı +
    // design_tokens.dart'taki `jablabSessionTheme` yorumu).
    return Theme(
      data: jablabSessionTheme,
      child: SessionFlowScaffold(
        title: lessonTitle(context, widget.lesson.id, widget.lesson.title),
        stage: _stage,
        advanceLabel: UiLanguage.text(context, en: (_stage == SessionStage.summary ? 'Done' : 'Continue'), tr: (_stage == SessionStage.summary ? 'Bitti' : 'Devam et')),
        onAdvance: _advance,
        child: switch (_stage) {
          SessionStage.teach => _Teach(
            lesson: widget.lesson,
            material: widget.teachMaterial,
          ),
          SessionStage.rehearse => _Rehearse(material: widget.rehearseMaterial),
          SessionStage.live => _Live(
            cues: widget.cues,
            plan: widget.plan,
            milestoneEvery: widget.milestoneEvery,
            intervalPlan: widget.intervalPlan,
            liveJab: widget.liveJab,
            liveJabSetupFailure: widget.liveJabSetupFailure,
            onProgress: (int rounds, int worked) {
              _roundsCompleted = rounds;
              _workedSeconds = worked;
            },
            // J-156: sayım canlı aşamada YAŞIYOR ve özete hiç taşınmıyordu;
            // `_Summary` sabit `0` veriyordu. `null` = analiz hiç koşmadı.
            onCounted: (int? n) => _countedEvents = n,
          ),
          SessionStage.summary => _Summary(
            coachedNotScored: widget.coachedNotScored,
            bands: widget.bands,
            eventCount: _countedEvents,
            unitsCompleted: _roundsCompleted,
            unitLabel: _unitLabel,
            workedSeconds: _workedSeconds,
            tempoBand: widget.liveJab?.dominantTempoBand,
          ),
        },
      ),
    );
  }
}

class _Teach extends StatelessWidget {
  const _Teach({required this.lesson, required this.material});

  final ShellLesson lesson;

  /// Materyal DIŞARIDAN gelir — ekran kendi içeriğini icat etmez.
  final TeachMaterial material;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // ⚠️ KAYDIRILABİLİR — ve bunu 375pt kapısı BULDU (J-118). Materyal
    // yokken bu aşama üç kısa satırdı ve sabit `Column` yetiyordu; gerçek
    // öğretme metni gelir gelmez 375×812'de **61 piksel** taştı. Aile
    // dersi #3'ün birebir tekrarı: *gerçek metin fixture'dan uzundur* —
    // ve bu kez fixture değil, İÇERİĞİN KENDİSİ uzadı.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.school_outlined, size: 36),
            const SizedBox(height: 16),
            Text(
              lessonTitle(context, lesson.id, lesson.title),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (lesson.subtitle.isNotEmpty)
              Text(lesson.subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            // MATERYAL — ekran KENDİSİ karar vermez, `ContentRepository`den
            // türetir (J-094). Eskiden burada elle yazılmış *"watch first"*
            // duruyordu ve izlenecek hiçbir şey yoktu: kullanıcıya
            // yapamayacağı bir eylem söyleniyordu.
            switch (material) {
              TeachMaterialText(body: final String body) => Text(
                localizedTeachBody(context, lesson.id, body),
                key: const Key('teach-material'),
                style: theme.textTheme.bodyMedium,
              ),
              TeachMaterialNone(reason: final String reason) => Text(
                localizedMaterialReason(context, reason),
                key: const Key('teach-material-none'),
                style: theme.textTheme.bodySmall,
              ),
            },
            const SizedBox(height: 12),
            // Bu cümle materyalden BAĞIMSIZ ve her hâlde doğru: hüküm
            // aşamanın kendisinde susuyor (`SessionStage.teach.judges == false`).
            Text(
              UiLanguage.text(
                context,
                en: 'Nothing is being analysed during this part. Scoring you while you are still learning the shape would punish learning.',
                tr: 'Bu bölümde analiz yapılmıyor. Hareketi öğrenirken puan vermek öğrenmeyi cezalandırır.',
              ),
              key: const Key('teach-no-analysis'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Prova aşaması — **artık dersi tanıyor** (J-247).
///
/// Eskiden `const _Rehearse()` idi: ders girdisi YOKTU ve 19 dersin
/// 19'unda da ekranda yalnız *"Go slow…"* yazıyordu. O cümle hâlâ burada
/// ve hâlâ doğru — ama artık **neyi** yavaş yapacağını da söylüyor, ve
/// söylediği her şey `library.json`da yazılı (bkz. `rehearse_material.dart`).
class _Rehearse extends StatelessWidget {
  const _Rehearse({required this.material});

  /// Materyal DIŞARIDAN gelir — ekran kendi içeriğini icat etmez
  /// (`_Teach` ile aynı sözleşme).
  final RehearseMaterial material;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // KAYDIRILABİLİR — J-118'in dersi burada ÖNCEDEN uygulanıyor: bu aşama
    // bugün kısa, ama teknik/kombinasyon listesi içerikten geliyor ve
    // içerik uzayabilir. `_Teach` aynı hatayı gerçek metin gelince ödedi.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.timer_outlined, size: 36),
            const SizedBox(height: 16),
            // Aşamanın DEĞİŞMEYEN sözü: hüküm yok, saat yok. Materyalden
            // bağımsız ve her hâlde doğru.
            Text(
              UiLanguage.text(
                context,
                en: 'Go slow. One thing at a time, no clock.',
                tr: 'Yavaş ilerleyin. Her seferinde bir şeye odaklanın; süre sınırı yok.',
              ),
              key: const Key('rehearse-copy'),
            ),
            const SizedBox(height: 20),
            switch (material) {
              RehearseMaterialDrill(
                techniques: final List<String> techniques,
                combinations: final List<String> combinations,
              ) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      UiLanguage.text(
                        context,
                        en: 'What to run through',
                        tr: 'Çalışılacak hareketler',
                      ),
                      key: const Key('rehearse-drill-heading'),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final String t in techniques)
                      Padding(
                        key: Key('rehearse-technique-$t'),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text('· $t', style: theme.textTheme.bodyMedium),
                      ),
                    // BOŞ kombinasyon listesi hiç çizilmez — "kombinasyon
                    // yok" diye duyurmak gürültü olurdu (bkz. varyant dokümanı).
                    if (combinations.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      // ⚠️ BAŞLIK "Then put them together" DEĞİL — ölçüldü:
                      // `combinations` TEK yumrukları da taşıyor
                      // (`first_round` ve `r3`: `['1','2','1-2',…]`). Tek
                      // yumruğu "bunları birleştir" başlığı altına koymak
                      // içeriğin söylemediği bir şeyi söylemek olurdu.
                      // Alan aslında ÇALIŞILACAK SIRALAR listesi.
                      Text(
                        UiLanguage.text(
                          context,
                          en: 'Sequences to run',
                          tr: 'Çalışılacak diziler',
                        ),
                        key: const Key('rehearse-combos-heading'),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      for (final String c in combinations)
                        Padding(
                          key: Key('rehearse-combination-$c'),
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '· $c',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ],
                ),
              RehearseMaterialNone(reason: final String reason) => Text(
                localizedMaterialReason(context, reason),
                key: const Key('rehearse-material-none'),
                style: theme.textTheme.bodySmall,
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// Canlı tur: süre AKAR ve anlatı konuşur, hüküm SUSAR.
///
/// İkisinin ayrı olması tasarım kararı: turu saymak poza bakmayı gerektirmez.
/// Kamera bağlı değilken bile "yarıladın" doğru bir cümledir; "gardın düştü"
/// ise olmayan bir ölçüme dayanırdı.
class _Live extends StatefulWidget {
  const _Live({
    required this.cues,
    required this.plan,
    required this.intervalPlan,
    required this.onProgress,
    required this.onCounted,
    this.liveJab,
    this.liveJabSetupFailure,
    this.milestoneEvery,
  });

  final CueBook cues;
  final int? milestoneEvery;
  final RoundPlan? plan;
  final IntervalPlan? intervalPlan;
  final LiveJabController? liveJab;
  final LiveSessionFailure? liveJabSetupFailure;

  /// (tamamlanan tur, ÇALIŞILAN saniye) — dinlenme sayılmaz.
  final void Function(int roundsCompleted, int workedSeconds) onProgress;

  /// Sayılan olayı yukarı taşır. `null` = analiz hiç koşmadı (J-156).
  final void Function(int? counted) onCounted;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> with WidgetsBindingObserver {
  bool _foreground =
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  bool _cameraRetired = false;
  Completer<void>? _foregroundGate;

  /// Kip PLANA göre seçilir — `interval()` yalnız `SessionMode.interval`de
  /// olay üretir, `steady`de sessizce boş döner. Sabit `steady` bırakmak,
  /// aralık repliklerini hiç duyulmaz kılardı (kodu var, kullanıcı duymuyor).
  late final SessionNarrator _narrator = SessionNarrator(
    mode: widget.intervalPlan != null
        ? SessionMode.interval
        : SessionMode.steady,
    // ⚠️ Üretimde `null` → `SessionNarrator`ın kendi sabiti (25) geçerli.
    // Bu satır ilk yazışımda EKSİK kaldı: alan `_Live`e kadar geliyordu ve
    // burada OKUNMUYORDU — yani "alan var, tüketicisi yok", tam da bu
    // dikişin KANITLAMAK için var olduğu desen. Testin kırmızısı onu
    // yakaladı; teftişle geçseydim dikiş kendi ölçtüğü kusuru taşıyacaktı.
    milestoneEvery: widget.milestoneEvery ?? 25,
  );
  Timer? _ticker;

  /// Kamera hattının son bildirdiği hâl — `null` iken ders kamerasız.
  LiveJabState? _jab;
  StreamSubscription<LiveJabState>? _jabSub;
  late LiveSessionFailure? _jabFailure = widget.liveJabSetupFailure;

  /// O anki turun (ya da dinlenmenin) İÇİNDEKİ konum — toplam değil.
  /// `IntervalTimer` bir aralığın ilerlemesini gösterir; toplam seansı
  /// göstermek "son 10 saniye" anlatısını anlamsız yapardı.
  Duration _elapsed = Duration.zero;
  int _roundIndex = 0;
  bool _resting = false;
  bool _finished = false;
  String? _line;

  RoundPlan? get _plan => widget.plan;
  IntervalPlan? get _ivl => widget.intervalPlan;

  /// Kameranın o ana kadar SAYDIĞI tamamlanmış jab — anlatıcının sayım
  /// kilometre taşı için okuduğu tek girdi.
  ///
  /// ⚠️ **Bu getter bir kusurun kapanışı (J-104).** `SessionNarrator.tick`
  /// `eventCount` parametresini en baştan taşıyordu ve `milestoneEvery`
  /// (25) testliydi — ama çağıran onu HİÇ geçmiyordu, yani `eventCount`
  /// her zaman 0'a düşüyor ve `NarrationEvent.milestone` **hiçbir koşulda
  /// ateşlenemiyordu**. `cue.milestone` bu yüzden "kodda eşlenmiş ama
  /// kullanıcı asla duymuyor" sınıfındaydı: aile dersi #6'nın
  /// (*"repliğin varlığı tetiğinin varlığı değil"*) tam örneği — ve grep
  /// taraması bunu YAKALAYAMAZ, çünkü anahtar `jabLabCueMapping`de duruyor.
  ///
  /// Kamerasız derste 0 döner ve bu DOĞRU: sayacak bir şey yok, dolayısıyla
  /// kilometre taşı da yok. Uydurulmuş bir eşik EKLENMEDİ — `milestoneEvery`
  /// zaten `SessionNarrator`ın kendi sabiti.
  int get _completedJabs {
    final LiveJabState? jab = _jab;
    return jab is LiveJabRunning ? jab.completedCount : 0;
  }

  /// Özete taşınan sayı — **`null` = analiz hiç koşmadı** (J-156).
  ///
  /// `_completedJabs`ten AYRI: o, canlı ekranın kilometre taşı sayacı ve
  /// kamerasız derste 0 dönmesi orada doğru (sayacak bir şey yok, dolayısıyla
  /// kilometre taşı da yok). Ama ÖZET için 0 ile *"analiz koşmadı"* aynı şey
  /// DEĞİL: birincisi *"ölçtük, hiç yumruk yoktu"*, ikincisi *"ölçmedik"* —
  /// ve çıplak `0` ikincisini *"hiç yapmadın"* diye okutur (J-092/J-096).
  ///
  /// Bir kez `LiveJabRunning` görüldüyse sayı BİLİNİYOR sayılıyor: analiz
  /// koştu ve durdu diye bilgi kaybolmaz.
  int? _countedForSummary;

  /// Sayımı yukarı bildirir. Analiz koşmadıysa `null` gider ve özet hiçbir
  /// sayı çizmez.
  void _reportCount() {
    final LiveJabState? jab = _jab;
    if (jab is LiveJabRunning) _countedForSummary = jab.completedCount;
    widget.onCounted(_countedForSummary);
  }

  Duration get _segment {
    final IntervalPlan? ip = _ivl;
    if (ip != null) {
      return Duration(seconds: _resting ? ip.recoverSeconds : ip.burstSeconds);
    }
    return _resting
        ? Duration(seconds: _plan!.restSeconds)
        : Duration(seconds: _plan!.roundSeconds);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startCamera());
    if (_plan == null && _ivl == null) return;
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Kamerayı başlatır. **Saat kameradan BAĞIMSIZ koşar**: kamera açılmasa
  /// bile tur saati ve anlatı çalışmaya devam eder — süre saymak poza
  /// bakmayı gerektirmez ve bir izin reddi antrenmanı durdurmamalı.
  Future<void> _startCamera() async {
    final LiveJabController? live = widget.liveJab;
    if (live == null) return;
    _jabSub = live.states.listen((LiveJabState st) {
      if (!mounted || _cameraRetired) return;
      setState(() {
        _jab = st;
        if (st is LiveJabFailed) _jabFailure = st.failure;
      });
      // Sayıma bağlı anlatı da BURADA sorulur (J-158): narrator'ın kendi
      // yorumu *"kilometre taşı sayıma bağlı, zamana değil"* diyordu ama
      // tek çağıranı saat tikiydi — ve TEK kameralı dersin (`jab`) tur
      // planı YOK, yani saat hiç kurulmuyor. Sayan tek dersin saati
      // olmadığı için `cue.milestone` pratikte ulaşılamazdı.
      final List<NarrationEvent> counted = _narrator.counted(_completedJabs);
      if (counted.isNotEmpty) {
        final String? said = widget.cues.say(
          counted.last,
          vars: <String, Object>{'n': _completedJabs},
        );
        if (said != null && mounted) setState(() => _line = said);
      }
      // Sayım DEĞİŞTİĞİNDE bildiriliyor, tik attığında değil (J-157).
      // İlk yazışımda `_reportCount()` yalnız tur/aralık tiklerinden
      // çağrılıyordu ve **plansız bir derste tik yoktur** — yani sayı
      // özete hiç ulaşmazdı. Kusurun kendisi J-156'nın sınıfıydı:
      // üretici vardı ama yolu yoktu.
      _reportCount();
    });
    final LiveSessionFailure? f = await live.start(
      beforeCameraStart: _waitForForeground,
    );
    if (f != null && mounted && !_cameraRetired) {
      setState(() => _jabFailure = f);
    }
  }

  Future<void> _waitForForeground() {
    if (_foreground || _cameraRetired) return Future<void>.value();
    return (_foregroundGate ??= Completer<void>()).future;
  }

  void _releaseForegroundGate() {
    final Completer<void>? gate = _foregroundGate;
    _foregroundGate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _releaseForegroundGate();
      return;
    }
    // Permission prompts can be inactive before native startup. Backgrounding
    // retires all setup; an already-started camera also retires on inactive.
    if (state == AppLifecycleState.inactive &&
        _jab == null &&
        !(widget.liveJab?.hasNativeSession ?? false)) {
      return;
    }
    if (_cameraRetired || widget.liveJab == null) return;
    _cameraRetired = true;
    unawaited(widget.liveJab?.stop());
    _releaseForegroundGate();
    unawaited(_jabSub?.cancel());
    setState(() {
      _jab = null;
      _jabFailure = const LiveCameraUnavailable(
        failure: CameraFailure.sessionInterrupted,
      );
    });
  }

  void _tick() {
    if (_ivl != null) {
      _tickInterval(_ivl!);
      return;
    }
    final RoundPlan plan = _plan!;
    if (_finished) return;

    final List<NarrationEvent> events = <NarrationEvent>[];
    if (_resting) {
      // Dinlenme anlatılmaz saniye saniye; başında bir kez söylenir.
      if (_elapsed <= Duration.zero) events.add(NarrationEvent.rest);
    } else {
      events.addAll(
        _narrator.tick(
          elapsed: _elapsed,
          total: _segment,
          eventCount: _completedJabs,
        ),
      );
    }

    Duration next = _elapsed + const Duration(seconds: 1);
    bool segmentOver = next > _segment;

    if (segmentOver) {
      if (_resting) {
        // Dinlenme bitti → sıradaki tur. `startRound()` olay setini
        // sıfırlar; yoksa "yarıladın" yalnız ilk turda söylenirdi.
        _resting = false;
        _roundIndex++;
        _narrator.startRound();
        next = Duration.zero;
      } else if (_roundIndex + 1 < plan.rounds) {
        if (plan.restSeconds > 0) {
          _resting = true;
          next = Duration.zero;
        } else {
          _roundIndex++;
          _narrator.startRound();
          next = Duration.zero;
        }
      } else {
        // Son turun sonu = SEANS sonu. Son turdan sonra dinlenme YOKTUR.
        _finished = true;
        events.add(NarrationEvent.sessionEnd);
        next = _segment;
        _ticker?.cancel();
      }
    }

    // Aynı anda birden çok olay düşerse SONUNCUSU söylenir: üst üste iki
    // cümle sesli koçta anlaşılmaz, kullanıcı ikisini de kaçırır.
    //
    // ⚠️ `vars` ZORUNLU: `cue.milestone` "{n} in." şablonudur ve tetiği
    // bağlandığı ilk anda ekrana LİTERAL "{n} in." yazdı (J-104'ün ikinci
    // kusuru — tetik testi yakaladı). `{n}` sayımın kendisi, yani
    // `eventCount` ile AYNI değer; ayrı bir sayaç tutmak ikisinin
    // ayrışabileceği bir yol açardı.
    final String? said = events.isEmpty
        ? null
        : widget.cues.say(
            events.last,
            vars: <String, Object>{'n': _completedJabs},
          );
    if (!mounted) return;
    setState(() {
      if (said != null) _line = said;
      _elapsed = next;
    });

    // ÇALIŞILAN süre: tamamlanan turlar + içinde bulunulan turun geçen
    // kısmı. Dinlenme HİÇ sayılmaz — ilerleme kapısı çalışma süresini
    // soruyor, dinlenmeyi de eklemek kapıyı hak etmeden geçirmek olurdu.
    // DİNLENMEDEYKEN biten tur SAYILIR. `_roundIndex` dinlenme BİTİNCE
    // artıyor; onu doğrudan kullanmak, dinlenme sırasında bırakılan seansı
    // "hiç çalışmadı" diye kaydediyordu (testin yakaladığı gerçek kusur).
    final int completed = _finished
        ? plan.rounds
        : (_resting ? _roundIndex + 1 : _roundIndex);
    final int inRound = (_resting || _finished)
        ? 0
        : _elapsed.inSeconds.clamp(0, plan.roundSeconds);
    widget.onProgress(completed, completed * plan.roundSeconds + inRound);
    _reportCount();
  }

  /// Aralık kipi (J-068): patla → topla → patla ... son toparlanma DAHİL.
  ///
  /// Turlu kipten iki yapısal fark var ve ikisi de bilinçli:
  ///  * SON patlamadan sonra da toparlanma koşar (soğuma döngünün parçası);
  ///    `RoundPlan` tam tersini yapar ve bu yüzden ayrı tipler.
  ///  * Form repliklerinin sustuğu tek kip budur (`cues.en.json` grup notu):
  ///    yüksek tempoyu ürün istedi, sonra "formun bozuldu" demek kendi
  ///    tasarladığımız egzersiz için ceza kesmek olurdu.
  void _tickInterval(IntervalPlan plan) {
    if (_finished) return;

    final bool wasInBurst = !_resting;
    Duration next = _elapsed + const Duration(seconds: 1);
    final bool segmentOver = next > _segment;
    bool nowResting = _resting;

    if (segmentOver) {
      if (!_resting) {
        nowResting = true;
        next = Duration.zero;
      } else if (_roundIndex + 1 < plan.bursts) {
        nowResting = false;
        _roundIndex++;
        next = Duration.zero;
      } else {
        // Son toparlanmanın sonu = SEANS sonu.
        _finished = true;
        next = _segment;
        _ticker?.cancel();
      }
    }

    final Duration untilNext = _segment - next;
    final List<NarrationEvent> events = <NarrationEvent>[
      ..._narrator.interval(
        inBurst: !nowResting,
        wasInBurst: wasInBurst,
        untilNext: nowResting ? untilNext : Duration.zero,
      ),
      if (_finished) NarrationEvent.sessionEnd,
    ];

    final String? said = events.isEmpty ? null : widget.cues.say(events.last);
    if (!mounted) return;
    setState(() {
      if (said != null) _line = said;
      _resting = nowResting;
      _elapsed = next;
    });

    // ÇALIŞMA = yalnız PATLAMALAR. Toparlanmayı da saymak kullanıcıyı
    // kapıdan hak etmeden geçirirdi (turdaki dinlenmeyle aynı ilke).
    final int done = _finished
        ? plan.bursts
        : (_resting ? _roundIndex + 1 : _roundIndex);
    final int inBurst = (_resting || _finished)
        ? 0
        : _elapsed.inSeconds.clamp(0, plan.burstSeconds);
    widget.onProgress(done, done * plan.burstSeconds + inBurst);
    _reportCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraRetired = true;
    _releaseForegroundGate();
    _ticker?.cancel();
    unawaited(_jabSub?.cancel());
    // Kamerayı KAPAT: açık bırakmak modeli ve kamerayı ekran kapandıktan
    // sonra da meşgul tutardı ve plugin tek oturuma izin veriyor — sonraki
    // ders `already-running` ile açılamazdı.
    unawaited(widget.liveJab?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RoundPlan? plan = _plan;
    final IntervalPlan? ivl = _ivl;

    return Column(
      children: <Widget>[
        // SAAT YALNIZ PLANLI DERSTE AKAR. Öğretme dersleri (kamera, duruş,
        // jab...) süreli çalışma DEĞİL — onlarda bir tur saati göstermek
        // olmayan bir yapıyı varmış gibi gösterirdi. Süreli bir dersin
        // plansız AÇIK kalması `Library.validate` tarafından reddediliyor,
        // yani bu dal "planı yazılmamış tur" anlamına gelmez.
        if (plan != null || ivl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: IntervalTimer(elapsed: _elapsed, total: _segment),
          ),
        if (ivl != null)
          Text(
            UiLanguage.format(context,
              en: _resting ? 'Recover — burst {position} of {total} next' : 'Burst {position} of {total}',
              tr: _resting ? 'Toparlanma — sıradaki seri {position}/{total}' : 'Seri {position}/{total}',
              args: {'position': _resting ? (_roundIndex + 2 > ivl.bursts ? ivl.bursts : _roundIndex + 2) : _roundIndex + 1, 'total': ivl.bursts}),
            key: const Key('live-burst-position'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        // Tur konumu YAZILI. Çok turlu bir seansta hangi turda olduğunu
        // bilmemek, süreyi hiç bilmemekle aynı: kullanıcı ne kadar kaldığını
        // hesaplayamaz.
        if (plan != null && plan.rounds > 1)
          Text(
            UiLanguage.format(context,
              en: _resting ? 'Rest — round {position} of {total} next' : 'Round {position} of {total}',
              tr: _resting ? 'Dinlenme — sıradaki tur {position}/{total}' : 'Tur {position}/{total}',
              args: {'position': _roundIndex + (_resting ? 2 : 1), 'total': plan.rounds}),
            key: const Key('live-round-position'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        Expanded(child: _coachSurface()),
      ],
    );
  }
}

/// Canlı yüzey — kameralı ve kamerasız dersin AYNI yuvası, farklı içerikle.
extension on _LiveState {
  /// Donmuş yüzeyi kovanın rengiyle giydirir (J-110). `LiveCoachSurface`
  /// `shell_candidate/` altında DONDURULMUŞ ve `colorScheme.error`ü
  /// "göremiyorum" ikonuna basıyor; widget'a dokunmadan tek yol bu sarmal —
  /// J-100'ün `jablabSessionTheme` deseninin aynısı, bir katman içeride.
  Widget _bucketed(LiveHonestyBucket bucket, Widget surface) {
    ThemeData t = bucket.themeFor(Theme.of(context));
    // ARALIK KİPİNDE DÜZELTME GÖZLEM TONUNDA (J-119). Susturulmuyor —
    // sessizlik bu üründe "her şey yolunda" diye okunur ve HIIT'te form
    // gerçekten bozulur; olguyu saklamak kullanıcıdan kendi vücuduna dair
    // bir şeyi gizlemek olurdu. Değişen HÜKÜM tonu, bilginin kendisi değil.
    if (_ivl != null) t = jablabIntervalTone(t);
    return Theme(data: t, child: surface);
  }

  Widget _coachSurface() {
    final LiveSessionFailure? failure = _jabFailure;
    if (failure != null) {
      // KURULUM hatası: seans başlamadı. Saat koşmaya devam ediyor (yukarıda)
      // ama analiz yok ve bu SÖYLENİYOR — "yine de devam et" düğmesi YOK,
      // çünkü kamera dersinin vaadi analizdir.
      // KOVA KURULUM HATASININ SINIFINDAN TÜRÜYOR, hepsi aynı değil:
      // izin reddi analizin HİÇ başlamadığı hâldir (kullanıcı bilerek
      // seçti, ortada bir arıza yok); kamera açılamadı/kurulum düştü ise
      // BİZİM tarafımızda bir sorun. İkisine aynı görseli vermek, J-103'ün
      // metinde ayırdığı şeyi görselde birleştirmek olurdu.
      final LiveHonestyBucket bucket = failure is LivePermissionDenied
          ? LiveHonestyBucket.none
          : LiveHonestyBucket.ours;
      return _bucketed(
        bucket,
        LiveCoachSurface(
          state: LiveState.noVerdict,
          // Analiz HİÇ başlamadı → sayı YOK. `0` yazmak "sıfır yumruk
          // attın" demektir ve hiçbir şey ölçülmedi (J-096).
          eventCount: null,
          narration: _line,
          noVerdictReason: _failureSentence(failure),
          preview: SkeletonPreview(
            state: LiveState.noVerdict,
            bucket: bucket,
            analysisRunning: false,
          ),
        ),
      );
    }

    final LiveJabState? jab = _jab;
    if (widget.liveJab == null) {
      // KAMERASIZ ders. ⚠️ AMA HEPSİ SAATLİ DEĞİL (J-159).
      //
      // Cümle *"This lesson runs on the clock"* diyordu ve **dersin saati
      // olup olmadığına bakmıyordu.** Ölçüm: dört ders (`camera` ·
      // `stance` · `cross` · `one_two`) hem kamerasız hem **plansız** —
      // `_Live.initState` planı olmayan derste ticker'ı **hiç kurmuyor**
      // (`if (_plan == null && _ivl == null) return;`). Yani o dört derste
      // ekran **var olmayan bir saati** anlatıyordu.
      //
      // Aynı kusur sınıfı J-158'le kardeş: orada saatin YOKLUĞU bir
      // repliği ulaşılamaz yapıyordu, burada aynı yokluk bir cümleyi
      // YANLIŞ yapıyor.
      final bool timed = _plan != null || _ivl != null;
      return _bucketed(
        LiveHonestyBucket.none,
        LiveCoachSurface(
          state: LiveState.noVerdict,
          eventCount: null,
          narration: _line,
          noVerdictReason: UiLanguage.text(context, en: (timed
                    ? 'This lesson runs on the clock — nothing is being judged. '
                          'The timer and the on-screen pacing cues still work.'
                    : 'Nothing is being judged here, and there is no clock '
                          'either. Work at your own pace and move on when you are '
                          'done.'), tr: (timed
                    ? 'Bu ders süreyle ilerler; hareketiniz değerlendirilmez. Zamanlayıcı ve ekrandaki tempo yönergeleri çalışmaya devam eder.'
                    : 'Bu bölümde hareketiniz değerlendirilmez ve zamanlayıcı yoktur. Kendi hızınızda çalışıp bitirdiğinizde ilerleyin.')),
          preview: const SkeletonPreview(
            analysisRunning: false,
            state: LiveState.noVerdict,
            bucket: LiveHonestyBucket.none,
          ),
        ),
      );
    }
    if (jab == null || jab is LiveJabStarting) {
      // Henüz hiçbir kare gelmedi. SIFIR GÖSTERİLMİYOR: sıfır "hiç yumruk
      // atmadın" demektir, oysa daha hiçbir şey ölçülmedi. İskelet de YOK
      // (henüz çözülmüş bir kare yok) — yalnız yer tutucu görünür.
      return _bucketed(
        LiveHonestyBucket.none,
        LiveCoachSurface(
          state: LiveState.noVerdict,
          eventCount: null,
          narration: _line,
          noVerdictReason: UiLanguage.text(
            context,
            en: 'Getting the camera ready…',
            tr: 'Kamera hazırlanıyor…',
          ),
          preview: const SkeletonPreview(
            analysisRunning: false,
            state: LiveState.noVerdict,
            bucket: LiveHonestyBucket.none,
          ),
        ),
      );
    }

    final LiveJabRunning r = jab as LiveJabRunning;
    return _bucketed(
      r.bucket,
      LiveCoachSurface(
        state: r.surface,
        eventCount: r.completedCount,
        cue: r.cue,
        // MOTOR ANLATISI SAATİNKİNİ EZER (J-105). İkisi de aynı yuvaya
        // yazıyor ve yuva tek; hangisi kazanacağı bir tercih değil bir ZAMAN
        // meselesi: "düzeltme kayboldu" TAM O ANDA doğru ve bir saniye sonra
        // artık haber değil, oysa "yarıladın" tur boyunca doğru kalır.
        // Kaybolan cümleyi bekleten bir kuyruk kurmak, en taze sinyali en geç
        // söylemek olurdu.
        narration: r.narration ?? _line,
        noVerdictReason: r.noVerdictReason,
        preview: SkeletonPreview(
          analysisRunning: true,
          state: r.surface,
          skeleton: r.skeleton,
          bucket: r.bucket,
        ),
      ),
    );
  }

  /// Tipli hâl → kullanıcı cümlesi. **Ham `detail` KULLANILMIYOR** (doc-75/5
  /// kamera tarafı): teşhis dizesi geliştirici içindir.
  String _failureSentence(LiveSessionFailure f) => UiLanguage.text(context, en: _failureSentenceEn(f), tr: _failureSentenceTr(f));

  String _failureSentenceTr(LiveSessionFailure f) => switch (f) {
    LivePermissionDenied(permanentlyDenied: final bool permanent) =>
      permanent
          ? 'JabLab için kamera erişimi kapalı ve sistem yeniden izin istemeyecek. Ayarlar bölümünden açabilirsiniz. Kamera olmadan da tur saati çalışır.'
          : 'Jab hareketinizi izlemek için kameraya ihtiyacımız var. Kamera olmadan analiz yapılmaz; tur saati çalışmaya devam eder.',
    LiveCameraUnavailable() => 'Bu cihazda kamera açılamadı, bu yüzden analiz yapılmıyor. Tur saati çalışmaya devam eder.',
    LiveSetupFailed() => 'Kamera hazırlanırken bir sorun oluştu, bu yüzden analiz yapılmıyor. Tur saati çalışmaya devam eder.',
  };

  String _failureSentenceEn(LiveSessionFailure f) => switch (f) {
    LivePermissionDenied(permanentlyDenied: final bool permanent) =>
      permanent
          // "Tekrar dene" demek anlamsız: sistem bir daha sormayacak.
          ? 'Camera access is off for JabLab, and the system will not ask '
                'again. You can turn it on in Settings. The round clock '
                'still runs without it.'
          : 'We need the camera to watch your jab. Nothing is analysed '
                'without it — the round clock still runs.',
    LiveCameraUnavailable() =>
      'We could not open the camera on this device, so nothing is being '
          'analysed. The round clock still runs.',
    LiveSetupFailed() =>
      'Something went wrong setting up the camera, so nothing is being '
          'analysed. The round clock still runs.',
  };
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.coachedNotScored,
    required this.bands,
    required this.eventCount,
    required this.unitsCompleted,
    required this.unitLabel,
    required this.workedSeconds,
    required this.tempoBand,
  });

  /// `null` = analiz hiç koşmadı → özet SAYI GÖSTERMEZ (J-156).
  final int? eventCount;

  final List<String> coachedNotScored;

  /// Kural setinin `trackedComponents`ından TÜRETİLİR (J-144) — elle
  /// yazılmaz. Elle yazıldığı sürece iki ekran iki farklı üçlü gösterdi.
  final Map<String, String> bands;

  /// J-259: `_SessionScreenState`in zaten izlediği + diske yazdığı
  /// olgular — bu widget'a kadar hiç ULAŞMIYORLARDI.
  final int unitsCompleted;

  /// TAM ÇÖZÜLMÜŞ (tekil/çoğul dahil) — [SessionRecord.unitLabel]'ın
  /// AYNI deseni, `_SessionScreenState`de hesaplanır. Kabuk (M-F-25 terfi
  /// kapısı) ne alan kelimesi ne çoğul mantığı taşıyabilir.
  final String unitLabel;
  final int workedSeconds;

  /// D18: motor `AttemptDigest.tempoBand` üretiyordu (ADR-001, "controlled/
  /// brisk/fast"), hiçbir yüzey göstermiyordu. `null` = bu seansta hiç
  /// tamamlanmış deneme yok — ölçülmedi, "controlled" DEĞİL (K8'in
  /// "bilmiyorum" ≠ "en düşük bant" ilkesiyle aynı sınıf).
  final String? tempoBand;

  @override
  Widget build(BuildContext context) => SessionSummaryView(
    // J-156: burada SABİT `0` duruyordu ve yanındaki K8 yorumu onu
    // haklı çıkarıyor sanılıyordu. K8 **bantlar** için geçerli; **sayım**
    // bir HÜKÜM değil OLGU — ürünün kendi dürüstlük kutusu böyle diyor:
    // *"Punch events and count — a FACT from the phase machine, not a
    // grade."* Yani sayım K8'e takılmaz; ölçülmüştü ve atılıyordu.
    eventCount: eventCount,
    // K8 (M-F-04): kalibrasyon kapısı geçilmeden BANT sayısı yok.
    // Liste TÜREVİ (J-144).
    bands: <String, String>{
      for (final MapEntry<String, String> entry in bands.entries)
        componentLabel(context, entry.key): entry.value,
    },
    // J-033: eğitmenler gard/kol pozisyonunda ayrışıyor → koçlanır ama
    // SKORLANMAZ. Liste config'ten gelir (ContentRepository), elle
    // yazılmaz — bkz. widget dokümanı.
    coachedNotScored: <String>[
      for (final String label in coachedNotScored)
        componentLabel(context, label),
    ],
    unitsCompleted: unitsCompleted,
    unitLabelContainsCount: true,
    unitLabel: switch (unitLabel) {
      'interval' || 'intervals' => UiLanguage.format(context,
        en: '{count} intervals', tr: '{count} aralık', args: {'count': unitsCompleted}, pluralArg: 'count'),
      'round' || 'rounds' => UiLanguage.format(context,
        en: '{count} rounds', tr: '{count} tur', args: {'count': unitsCompleted}, pluralArg: 'count'),
      _ => '${UiLanguage.number(context, unitsCompleted)} $unitLabel',
    },
    workedSeconds: workedSeconds,
    tempoBand: tempoBandLabel(context, tempoBand),
  );
}
