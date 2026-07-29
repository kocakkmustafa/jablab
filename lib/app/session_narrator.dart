import 'dart:convert';

/// Seans anlatıcısı — **hangi an ne söylenir** kararı.
///
/// Kabuk envanteri donduruldu (M-F-25), bu yüzden burada yaşıyor; ama
/// alan-bağımsız yazıldı ve terfi turunda `motion_shell`'e taşınabilir:
/// içinde tek bir boks terimi, tek bir `cue.` anahtarı yok. Kabuk NE
/// söyleneceğini bilmez, YALNIZCA ne zaman konuşulacağını bilir. Metin
/// eşlemesi [CueBook] ile app tarafında yapılır — çello ve salsa aynı
/// zamanlamayı farklı sözlükle kullanır.
enum NarrationEvent {
  sessionStart,
  roundStart,
  halfway,
  lastTen,
  lastFive,
  milestone,
  roundEnd,
  rest,
  burstStart,
  burstEnd,
  recover,
  nextBurst,
  sessionEnd,
  corrected,
  streak,
  settled,
}

/// Seans kipi. Aralıklı çalışma, sürekli turdan farklı konuşur.
enum SessionMode { steady, interval }

/// Zamana bağlı olayları üretir. **Saf ve deterministik**: aynı zaman
/// çizgisi her koşuda aynı olayları verir, bu yüzden replay ile denetlenebilir.
///
/// Her olay bir tur içinde **bir kez** ateşlenir; tekrar sesli koçu gürültüye
/// çevirir ve gürültü, susmakla aynı sonucu verir — kullanıcı dinlemeyi bırakır.
class SessionNarrator {
  SessionNarrator({required this.mode, this.milestoneEvery = 25});

  final SessionMode mode;

  /// Kaç olayda bir sayım kilometre taşı söylenir.
  final int milestoneEvery;

  final Set<Object> _fired = <Object>{};

  /// Turlar arasında sıfırlanır — "yarıladın" her turda yeniden söylenmeli.
  void startRound() => _fired.removeWhere((Object k) => k is NarrationEvent);

  /// [elapsed]/[total] tur içi konum; [eventCount] o ana kadar sayılan olay.
  List<NarrationEvent> tick({
    required Duration elapsed,
    required Duration total,
    int eventCount = 0,
  }) {
    final List<NarrationEvent> out = <NarrationEvent>[];
    void fire(NarrationEvent e) {
      if (_fired.add(e)) out.add(e);
    }

    if (elapsed <= Duration.zero) fire(NarrationEvent.roundStart);
    final Duration left = total - elapsed;
    if (total > Duration.zero && elapsed >= total ~/ 2) {
      fire(NarrationEvent.halfway);
    }
    if (left <= const Duration(seconds: 10) && left > Duration.zero) {
      fire(NarrationEvent.lastTen);
    }
    if (left <= const Duration(seconds: 5) && left > Duration.zero) {
      fire(NarrationEvent.lastFive);
    }
    if (left <= Duration.zero) fire(NarrationEvent.roundEnd);

    // Kilometre taşı sayıma bağlı, zamana değil — ayrı anahtarla izlenir ki
    // 25. ve 50. ayrı ayrı söylenebilsin.
    if (milestoneEvery > 0 && eventCount > 0 &&
        eventCount % milestoneEvery == 0 &&
        _fired.add('milestone-$eventCount')) {
      out.add(NarrationEvent.milestone);
    }
    return out;
  }

  /// Aralık kipi geçişleri. [inBurst] o anki aralığın sert kısmında olup
  /// olmadığımızı söyler; geçiş anında konuşulur.
  List<NarrationEvent> interval({
    required bool inBurst,
    required bool wasInBurst,
    required Duration untilNext,
  }) {
    if (mode != SessionMode.interval) return const <NarrationEvent>[];
    final List<NarrationEvent> out = <NarrationEvent>[];
    if (inBurst && !wasInBurst) out.add(NarrationEvent.burstStart);
    if (!inBurst && wasInBurst) {
      out
        ..add(NarrationEvent.burstEnd)
        ..add(NarrationEvent.recover);
    }
    if (!inBurst &&
        untilNext <= const Duration(seconds: 10) &&
        untilNext > Duration.zero &&
        _fired.add('nextBurst-${untilNext.inSeconds}')) {
      out.add(NarrationEvent.nextBurst);
    }
    return out;
  }
}

/// Olay → replik eşlemesi ve varyant seçimi.
///
/// Varyant **döndürülerek** seçilir, rastgele değil: rastgele seçim aynı
/// cümleyi arka arkaya iki kez verebilir ve tam da kaçınmak istediğimiz şey
/// bu. Tekrar körlüğü pratikte susmaya eşdeğerdir.
class CueBook {
  CueBook(this._lines);

  factory CueBook.fromJson(String source, Map<NarrationEvent, String> mapping) {
    final Map<String, dynamic> doc =
        (jsonDecode(source) as Map).cast<String, dynamic>();
    final Map<String, List<String>> flat = <String, List<String>>{};
    for (final MapEntry<String, dynamic> g in doc.entries) {
      if (g.key.startsWith(r'$') || g.value is! Map) continue;
      for (final MapEntry<String, dynamic> e
          in (g.value as Map).cast<String, dynamic>().entries) {
        if (e.key.startsWith(r'$')) continue;
        flat[e.key] = (e.value as List<dynamic>).cast<String>();
      }
    }
    final Map<NarrationEvent, List<String>> byEvent =
        <NarrationEvent, List<String>>{};
    for (final MapEntry<NarrationEvent, String> m in mapping.entries) {
      final List<String>? lines = flat[m.value];
      if (lines == null) {
        throw StateError('sarkan atıf: ${m.key} → ${m.value} repliği yok');
      }
      byEvent[m.key] = lines;
    }
    return CueBook(byEvent);
  }

  final Map<NarrationEvent, List<String>> _lines;
  final Map<NarrationEvent, int> _cursor = <NarrationEvent, int>{};

  bool covers(NarrationEvent e) => _lines.containsKey(e);

  /// [vars] içindeki `{n}` gibi yer tutucular doldurulur.
  String? say(NarrationEvent e, {Map<String, Object>? vars}) {
    final List<String>? lines = _lines[e];
    if (lines == null || lines.isEmpty) return null;
    final int i = _cursor.update(e, (int v) => (v + 1) % lines.length,
        ifAbsent: () => 0);
    String s = lines[i];
    if (vars != null) {
      for (final MapEntry<String, Object> v in vars.entries) {
        s = s.replaceAll('{${v.key}}', '${v.value}');
      }
    }
    return s;
  }

  /// Yer tutucusu doldurulmamış replik kaldı mı — sesli okunduğunda
  /// "Round {n} of {total}" diye duyulur.
  static final RegExp unfilledPlaceholder = RegExp(r'\{[a-z]+\}');

  int get eventCount => _lines.length;
}

/// JabLab'ın olay→replik sözlüğü. **Kabuk bunu görmez** — anlatıcı olayı
/// üretir, sözlük app'te kalır. Ostinato aynı olaylara çello sözlüğü bağlar.
///
/// Eksiksizlik testle zorlanıyor: yeni bir [NarrationEvent] eklenip buraya
/// yazılmazsa olay sessizce sessiz kalırdı — sesli koçta en pahalı kusur,
/// çünkü kullanıcı "bir şey söylenmedi"yi "sorun yok" diye okur.
const Map<NarrationEvent, String> jabLabCueMapping = <NarrationEvent, String>{
  NarrationEvent.sessionStart: 'cue.setup_ok',
  NarrationEvent.roundStart: 'cue.round_start',
  NarrationEvent.halfway: 'cue.halfway',
  NarrationEvent.lastTen: 'cue.last_ten',
  NarrationEvent.lastFive: 'cue.last_five',
  NarrationEvent.milestone: 'cue.milestone',
  NarrationEvent.roundEnd: 'cue.round_end',
  NarrationEvent.rest: 'cue.rest',
  NarrationEvent.burstStart: 'cue.burst_start',
  NarrationEvent.burstEnd: 'cue.burst_end',
  NarrationEvent.recover: 'cue.recover',
  NarrationEvent.nextBurst: 'cue.next_burst',
  NarrationEvent.sessionEnd: 'cue.finished',
  NarrationEvent.corrected: 'cue.corrected',
  NarrationEvent.streak: 'cue.streak',
  NarrationEvent.settled: 'cue.settled',
};
