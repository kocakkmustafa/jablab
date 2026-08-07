import 'package:flutter/material.dart';

import '../shell_candidate/shell_models.dart';
import 'design_tokens.dart';

/// Sayfa B — Kurs Sayfası (design: `docs/design/DESIGN-PANEL-PROMPT.md` §2
/// Sayfa B). Bir kurs "güncel" sayılıyorsa (kullanıcının içinde bulunduğu
/// kurs — Hüküm 3) uygulamanın GİRİŞ ekranı da budur.
///
/// "Kaldığın yer" paneli ve K8 bant bloğu **yalnız [isCurrent] true iken**
/// çizilir — koordinatör Hüküm 2: bantlar düşmüyor, Sayfa B'ye bağlamsal
/// dürüst blok olarak taşınıyor. Başka bir kursa göz atılırken (push ile,
/// `isCurrent: false`) bu bölüm hiç render edilmez; yoksa yanlış kursa ait
/// bir "kaldığın yer" iddiası kurulmuş olurdu.
///
/// `lib/shell_candidate/library_pages.dart`'taki (dondurulmuş envanter)
/// aynı-adlı `CoursePage`'e KASTEN dokunmadım — ders-listesi çizimi burada
/// küçük bir tekrarla yeniden yazıldı, donmuş dosya bozulmasın diye.
///
/// Görsel giydirme design turu Parça 3 (2026-08-06) — `design_tokens.dart`
/// tokenlarıyla, Ayarlar köşesiyle AYNI dilde (`GlassIconButton`/`GlassPanel`).
/// Tier seçimi bilinçli: geçmiş OKUNAMADIĞINDA ve K8 bantları HENÜZ
/// KALİBRE EDİLMEDİĞİNDE ikisi de "bilmiyorum" — `UnknownGlassPanel`in
/// (Tier 2-d, kesikli kenar) rezerve ettiği anlamın TAM KARŞILIĞI. Gerçek
/// kayıtlı geçmiş `GlassTier.observation` (gözlem/cool) — bir HÜKÜM değil,
/// bir OLGU. `ember`/judgement hiçbir yerde kullanılmadı: bu sayfada canlı
/// bir düzeltme yok, ember'ı burada göstermek "JUDGEMENT ONLY" kuralını
/// (palet dokümanı) çiğnerdi.
class CoursePage extends StatelessWidget {
  const CoursePage({
    super.key,
    required this.course,
    required this.onStart,
    required this.onOpenSettings,
    this.onOpenSelect,
    this.isCurrent = false,
    this.resumeLesson,
    this.historyUnavailable,
    this.historyIncomplete,
    this.recorded = const <String, String>{},
    this.recordedNote,
    this.bands = const <String, String>{},
    this.onRetryHistory,
  });

  final ShellCourse course;
  final void Function(ShellLesson) onStart;
  final VoidCallback onOpenSettings;

  /// Yalnız bu sayfa KÖK/giriş (landing) iken doldurulur — pushla açılan bir
  /// kursta geri gitmek zaten Navigator'ın kendi geri okuna aittir.
  final VoidCallback? onOpenSelect;

  final bool isCurrent;
  final ShellLesson? resumeLesson;
  final String? historyUnavailable;
  final String? historyIncomplete;
  final Map<String, String> recorded;
  final String? recordedNote;
  final Map<String, String> bands;
  final VoidCallback? onRetryHistory;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: JColors.ground,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[const Color(0xFF170809), JColors.ground],
              stops: const <double>[0, .42],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // Hüküm 3: KÖK+güncelken geri değil, disiplin ızgarasına
                    // dönüş; pushla açılan bir kursta ise sıradan geri —
                    // ikisi aynı anda DOĞRU olamaz (sınıf dokümanı).
                    if (isCurrent && onOpenSelect != null)
                      GlassIconButton(
                        key: const Key('open-select'),
                        icon: Icons.grid_view_outlined,
                        tooltip: 'Choose a discipline',
                        onTap: onOpenSelect!,
                      )
                    else
                      GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        // `tooltip: 'Back'` yalnız erişilebilirlik süsü DEĞİL
                        // — `tester.pageBack()` (fitness_ship_audit_test.dart
                        // dahil, DOKUNULMAYAN pre-existing testler) TAM BU
                        // dizeyi arıyor (flutter_test kaynağı: önce
                        // `find.byTooltip('Back')`, sonra Cupertino'ya düşer).
                        tooltip: 'Back',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: JText.pageTitle.copyWith(fontSize: 26, letterSpacing: -.8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GlassIconButton(
                      key: const Key('settings-button'),
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onTap: onOpenSettings,
                    ),
                  ],
                ),
                if (course.goal.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(course.goal, style: JText.body.copyWith(color: JColors.ink2, fontSize: 15)),
                ],
                if (isCurrent) ...<Widget>[
                  const SizedBox(height: 20),
                  _WhereYouLeftOff(
                    resumeLesson: resumeLesson,
                    historyUnavailable: historyUnavailable,
                    historyIncomplete: historyIncomplete,
                    recorded: recorded,
                    recordedNote: recordedNote,
                    onResume:
                        resumeLesson == null ? null : () => onStart(resumeLesson!),
                    onRetry: onRetryHistory,
                  ),
                  const SizedBox(height: 14),
                  _HonestBands(bands: bands),
                  const SizedBox(height: 8),
                  Divider(color: JColors.hairline, height: 40),
                ] else
                  const SizedBox(height: 20),
                // Kilitli ders LİSTEDE KALIR ama açılmaz — göster, açma, SEBEBİNİ
                // yaz (shell_candidate/library_pages.dart'ın CoursePage'inden
                // birebir taşınan davranış; bkz. sınıf dokümanı).
                ...course.lessons.map((ShellLesson l) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LessonRow(lesson: l, onTap: onStart),
                    )),
              ],
            ),
          ),
        ),
      );
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.onTap});

  final ShellLesson lesson;
  final void Function(ShellLesson) onTap;

  @override
  Widget build(BuildContext context) {
    final bool locked = lesson.isLocked;
    final Color fg = locked ? JColors.ink3 : JColors.ink;
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        key: Key('lesson-${lesson.id}'),
        onTap: locked ? null : () => onTap(lesson),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              locked ? Icons.lock_outline : Icons.play_circle_outline,
              size: 22,
              color: locked ? JColors.ink4 : JColors.ember,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(lesson.title,
                      style: JText.body.copyWith(color: fg, fontWeight: FontWeight.w600)),
                  if (locked) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(lesson.lockedReason!,
                        key: Key('locked-why-${lesson.id}'),
                        style: JText.bodyMuted.copyWith(fontSize: 12.5)),
                  ] else if (lesson.subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(lesson.subtitle, style: JText.bodyMuted.copyWith(fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            if (lesson.minutes != 0) ...<Widget>[
              const SizedBox(width: 8),
              Text('${lesson.minutes} min',
                  // Kilitli ders SÖNÜK ama okunur: `ink4` 1,80:1 veriyordu
                  // (J-116). Kilitli dersin süresi de bir olgu — dimlemek
                  // "daha az önemli" demek, "okunmasın" demek değil.
                  style: JText.mono
                      .copyWith(color: locked ? JColors.ink2 : JColors.cool2)),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Kaldığın yer" — geçmişin üç-hâlli beyanı (J-092/doc-75), artık kurs
/// bağlamında. Metinler `lib/app/jablab_app.dart`tan AYNEN geliyor; burada
/// yalnız yerleşim var, karar yok.
class _WhereYouLeftOff extends StatelessWidget {
  const _WhereYouLeftOff({
    required this.resumeLesson,
    required this.historyUnavailable,
    required this.historyIncomplete,
    required this.recorded,
    required this.recordedNote,
    required this.onResume,
    required this.onRetry,
  });

  final ShellLesson? resumeLesson;
  final String? historyUnavailable;
  final String? historyIncomplete;
  final Map<String, String> recorded;
  final String? recordedNote;
  final VoidCallback? onResume;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final String? unavailable = historyUnavailable;
    if (unavailable != null) {
      // Beyan varken satır YOLU KAPALI (M-F-209 aile kuralı): "okuyamadım"
      // ile bir sayı listesi aynı ekranda dururlarsa hangisine inanılacağı
      // belirsiz kalır. Tier 2-d: bu TAM OLARAK "bilmiyorum" hâli.
      return UnknownGlassPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Where you left off',
                key: const Key('recorded-heading'),
                style: JText.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(unavailable,
                key: const Key('recorded-unavailable'),
                style: JText.bodyMuted),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('retry-history'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: JColors.ink,
                  side: BorderSide(color: JColors.border),
                ),
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      );
    }
    if (recorded.isEmpty) {
      // Hiç seans yapılmamış: bu bir hata değil, sessizce hiçbir şey
      // göstermemek doğru olan — sıfır satırlık bir vitrin kurmuyoruz.
      return const SizedBox.shrink();
    }
    return GlassPanel(
      tier: GlassTier.observation,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Where you left off',
              key: const Key('recorded-heading'),
              style: JText.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'These are measurements, not marks. Nothing here is a judgement '
            'about how well you moved.',
            key: const Key('recorded-vs-judged-note'),
            style: JText.bodyMuted,
          ),
          // Nitelik satırlardan ÖNCE (J-092): toplamlar okunmadan önce
          // eksik oldukları bilinmeli.
          if (historyIncomplete != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(historyIncomplete!,
                key: const Key('recorded-incomplete'),
                style: JText.bodyMuted),
          ],
          const SizedBox(height: 10),
          // `ListTile` DEĞİL: title+trailing ikisi de uzayabiliyor
          // ("Sessions" · "3 recorded, 1 stopped early") ve `ListTile`
          // dar ekranda (375pt) trailing tile genişliğinin TAMAMINI
          // kaplarsa performLayout'ta fırlıyor — 375pt taşma kapısı bunu
          // yakaladı (koordinatör 2026-08-06, Lissom/Ostinato emsali).
          // `Expanded` + `Flexible` ile iki taraf da esner, hiçbiri
          // sabit-genişlik varsayımıyla diğerini kilitlemiyor.
          ...recorded.entries.map((MapEntry<String, String> e) => Padding(
                key: Key('recorded-${e.key}'),
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(e.key, style: JText.body.copyWith(fontSize: 14))),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(e.value,
                          style: JText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                          textAlign: TextAlign.end),
                    ),
                  ],
                ),
              )),
          if (recordedNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(recordedNote!,
                  key: const Key('recorded-note'),
                  style: JText.bodyMuted),
            ),
          if (resumeLesson != null) ...<Widget>[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: JColors.ember,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('resume-lesson'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: onResume,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text('Resume ${resumeLesson!.title}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF180A05))),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// K8 (M-F-04) bant bloğu — `numericUnlocked` false iken sayı render eden
/// bir yol YOKTUR. `shell_candidate/shell_scaffold.dart`taki `ProgressPage`
/// ile birebir aynı metin/keys; bu blok onun yerini alıyor, davranışını
/// değil. Tier 2-d: bantların HEPSİ bugün "—" — bu da "bilmiyorum"un ta
/// kendisi, kesikli kenar süs değil.
class _HonestBands extends StatelessWidget {
  const _HonestBands({required this.bands});

  final Map<String, String> bands;

  @override
  Widget build(BuildContext context) {
    return UnknownGlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Scores are shown as bands until the thresholds are calibrated '
            'on real recordings. A precise-looking number we cannot back up '
            'would be worse than no number.',
            key: const Key('bands-only-note'),
            style: JText.bodyMuted,
          ),
          if (bands.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            // `ListTile` değil — aynı 375pt taşma sınıfı `_WhereYouLeftOff`teki
            // gibi burada da mümkün (bkz. o widget'ın yorumu); değerler bugün
            // hep "—" ama alan `Map<String,String>` — savunma tüm sınıfa.
            ...bands.entries.map((MapEntry<String, String> e) => Padding(
                  key: Key('band-${e.key}'),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Text(e.key, style: JText.body.copyWith(fontSize: 14))),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(e.value,
                            style: JText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
