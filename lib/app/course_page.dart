import 'package:flutter/material.dart';

import '../shell_candidate/shell_models.dart';

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
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        leading: isCurrent && onOpenSelect != null
            ? IconButton(
                key: const Key('open-select'),
                icon: const Icon(Icons.grid_view_outlined),
                tooltip: 'Choose a discipline',
                onPressed: onOpenSelect,
              )
            : null,
        actions: <Widget>[
          IconButton(
            key: const Key('settings-button'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (course.goal.isNotEmpty)
            Text(course.goal, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (isCurrent) ...<Widget>[
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
            const SizedBox(height: 16),
            _HonestBands(bands: bands),
            const Divider(height: 32),
          ],
          // Kilitli ders LİSTEDE KALIR ama açılmaz — göster, açma, SEBEBİNİ
          // yaz (shell_candidate/library_pages.dart'ın CoursePage'inden
          // birebir taşınan davranış; bkz. sınıf dokümanı).
          ...course.lessons.map((ShellLesson l) => Card(
                child: ListTile(
                  key: Key('lesson-${l.id}'),
                  enabled: !l.isLocked,
                  leading: Icon(l.isLocked
                      ? Icons.lock_outline
                      : Icons.play_circle_outline),
                  title: Text(l.title),
                  subtitle: l.isLocked
                      ? Text(l.lockedReason!,
                          key: Key('locked-why-${l.id}'),
                          style: theme.textTheme.bodySmall)
                      : (l.subtitle.isEmpty ? null : Text(l.subtitle)),
                  isThreeLine: l.isLocked,
                  trailing: l.minutes == 0 ? null : Text('${l.minutes} min'),
                  onTap: l.isLocked ? null : () => onStart(l),
                ),
              )),
        ],
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
    final ThemeData theme = Theme.of(context);
    final String? unavailable = historyUnavailable;
    if (unavailable != null) {
      // Beyan varken satır YOLU KAPALI (M-F-209 aile kuralı): "okuyamadım"
      // ile bir sayı listesi aynı ekranda dururlarsa hangisine inanılacağı
      // belirsiz kalır.
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Where you left off',
                  key: const Key('recorded-heading'),
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(unavailable,
                  key: const Key('recorded-unavailable'),
                  style: theme.textTheme.bodySmall),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const Key('retry-history'),
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (recorded.isEmpty) {
      // Hiç seans yapılmamış: bu bir hata değil, sessizce hiçbir şey
      // göstermemek doğru olan — sıfır satırlık bir vitrin kurmuyoruz.
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Where you left off',
                key: const Key('recorded-heading'),
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'These are measurements, not marks. Nothing here is a judgement '
              'about how well you moved.',
              key: const Key('recorded-vs-judged-note'),
              style: theme.textTheme.bodySmall,
            ),
            // Nitelik satırlardan ÖNCE (J-092): toplamlar okunmadan önce
            // eksik oldukları bilinmeli.
            if (historyIncomplete != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(historyIncomplete!,
                  key: const Key('recorded-incomplete'),
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            // `ListTile` DEĞİL: title+trailing ikisi de uzayabiliyor
            // ("Sessions" · "3 recorded, 1 stopped early") ve `ListTile`
            // dar ekranda (375pt) trailing tile genişliğinin TAMAMINI
            // kaplarsa performLayout'ta fırlıyor — 375pt taşma kapısı bunu
            // yakaladı (koordinatör 2026-08-06, Lissom/Ostinato emsali).
            // `Expanded` + `Flexible` ile iki taraf da esner, hiçbiri
            // sabit-genişlik varsayımıyla diğerini kilitlemiyor.
            ...recorded.entries.map((MapEntry<String, String> e) => Padding(
                  key: Key('recorded-${e.key}'),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Text(e.key)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(e.value,
                            style: theme.textTheme.titleSmall, textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                )),
            if (recordedNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(recordedNote!,
                    key: const Key('recorded-note'),
                    style: theme.textTheme.bodySmall),
              ),
            if (resumeLesson != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('resume-lesson'),
                onPressed: onResume,
                child: Text('Resume ${resumeLesson!.title}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// K8 (M-F-04) bant bloğu — `numericUnlocked` false iken sayı render eden
/// bir yol YOKTUR. `shell_candidate/shell_scaffold.dart`taki `ProgressPage`
/// ile birebir aynı metin/keys; bu blok onun yerini alıyor, davranışını
/// değil.
class _HonestBands extends StatelessWidget {
  const _HonestBands({required this.bands});

  final Map<String, String> bands;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Scores are shown as bands until the thresholds are calibrated '
              'on real recordings. A precise-looking number we cannot back up '
              'would be worse than no number.',
              key: const Key('bands-only-note'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
        // `ListTile` değil — aynı 375pt taşma sınıfı `_WhereYouLeftOff`teki
        // gibi burada da mümkün (bkz. o widget'ın yorumu); değerler bugün
        // hep "—" ama alan `Map<String,String>` — savunma tüm sınıfa.
        ...bands.entries.map((MapEntry<String, String> e) => Padding(
              key: Key('band-${e.key}'),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(e.key)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(e.value,
                        style: theme.textTheme.titleSmall, textAlign: TextAlign.end),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
