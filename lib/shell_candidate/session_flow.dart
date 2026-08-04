import 'package:flutter/material.dart';

/// Ders akışının alan-bağımsız iskeleti (standart §2):
/// öğret → dene → canlı analiz → özet → sonraki adım.
///
/// Beş app'in de ders akışı aynı: bir şey gösterilir, kullanıcı kontrollü
/// dener, canlı seansta analiz edilir, özet verilir, bir sonraki adım
/// önerilir. Neyin gösterildiği ve neyin analiz edildiği app'in işi; **sıra**
/// ortaktır ve burada durur.
enum SessionStage {
  /// Hareket/teknik gösterilir. Analiz YOK.
  teach,

  /// Kontrollü deneme: yavaş tempo, tek odak, süre baskısı yok.
  rehearse,

  /// Canlı seans: analiz + sesli koç açık.
  live,

  /// Seans özeti.
  summary,
}

extension SessionStageLabel on SessionStage {
  /// ⚠️ `teach` etiketi **'Watch' DEĞİL** — J-094'te simülatörde yakalandı.
  ///
  /// Ekranın gövdesi *"izlenecek materyal yok"* derken üstteki sekme hâlâ
  /// **"Watch"** diyordu: aynı ekranda, aynı anda, birbiriyle çelişen iki
  /// cümle. Materyal yuvası düzeltilirken bu etiket gözden kaçmıştı ve
  /// **hiçbir widget testi göremezdi** — testler iki metnin varlığını
  /// görür, aralarındaki çelişkiyi değil (aynı vardiyada ikinci kez:
  /// ilki ilerleme sayfasındaki yapışık paragraftı).
  ///
  /// **'Learn' seçildi çünkü ORTAMDAN bağımsız.** "Watch" bir MEDYA vaadidir
  /// ve materyal video değilse (metin, çizim) ya da hiç yoksa yalan olur;
  /// "Learn" aşamanın AMACINI söyler ve üç durumda da doğrudur. Kabuk
  /// zaten materyalin varlığını bilmiyor ve bilmemeli — o app'in işi; bu
  /// yüzden çözüm etiketi duruma göre değiştirmek değil, **her durumda
  /// doğru olan** etiketi seçmek.
  ///
  /// Ostinato/Choreia için de aynı (terfi şartı #3): çello pasajını
  /// "izlemek" ile salsa adımını "izlemek" farklı ortamlar, öğrenmek ortak.
  String get label => switch (this) {
        SessionStage.teach => 'Learn',
        SessionStage.rehearse => 'Try it',
        SessionStage.live => 'Live',
        SessionStage.summary => 'Summary',
      };

  /// Bu aşamada teknik hüküm verilir mi?
  ///
  /// `teach` ve `rehearse` bilinçli olarak hükümsüzdür: kullanıcı henüz
  /// öğreniyor. Öğrenme anında puanlamak, öğrenmeyi cezalandırmaktır.
  bool get judges => this == SessionStage.live;
}

/// Aşamalar arası ilerleyen çatı.
class SessionFlowScaffold extends StatelessWidget {
  const SessionFlowScaffold({
    super.key,
    required this.title,
    required this.stage,
    required this.child,
    required this.onAdvance,
    this.advanceLabel,
    this.canAdvance = true,
  });

  final String title;
  final SessionStage stage;
  final Widget child;
  final VoidCallback onAdvance;
  final String? advanceLabel;
  final bool canAdvance;

  @override
  Widget build(BuildContext context) {
    final List<SessionStage> all = SessionStage.values;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final SessionStage s in all) ...<Widget>[
                  Chip(
                    key: Key('stage-${s.name}'),
                    label: Text(s.label),
                    backgroundColor: s == stage
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                  if (s != all.last) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          key: const Key('advance-button'),
          onPressed: canAdvance ? onAdvance : null,
          child: Text(advanceLabel ?? 'Continue'),
        ),
      ),
    );
  }
}

/// Süreli aralık sayacı.
///
/// **Adı bilerek "round" değil:** boks turu, dans kombosu, kata tekrarı ve
/// enstrüman pasajı aynı şeydir — süreli bir çalışma aralığı. Alan adı
/// kabukta geçerse bileşen `motion_shell`'e terfi edemez.
class IntervalTimer extends StatelessWidget {
  const IntervalTimer({
    super.key,
    required this.elapsed,
    required this.total,
    this.paused = false,
  });

  final Duration elapsed;
  final Duration total;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final Duration left = total - elapsed;
    final String text = '${left.inMinutes.toString().padLeft(2, '0')}:'
        '${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    return Column(
      key: const Key('interval-timer'),
      children: <Widget>[
        Text(text, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total.inMilliseconds == 0
              ? 0
              : elapsed.inMilliseconds / total.inMilliseconds,
        ),
        if (paused)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Paused',
                key: const Key('timer-paused'),
                style: Theme.of(context).textTheme.labelMedium),
          ),
      ],
    );
  }
}
