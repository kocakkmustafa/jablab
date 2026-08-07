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
}

/// ⚠️ `corrected`/`streak`/`settled` bu enum'dan ÇIKARILDI (J-105,
/// koordinatör hükmü 2026-08-07) ve üçü AYNI sebeple çıkmadı:
///
/// * **`corrected` YAŞIYOR ama burası onun yeri değildi.** Bu enum ZAMANA
///   bağlı olayları taşır — anlatıcı saatten başka hiçbir şey görmez.
///   "Düzeltme kayboldu" bir MOTOR sinyalidir; `LiveJabController` onu
///   `cues.sayKey('cue.corrected')` ile doğrudan söylüyor (`_phrase`in
///   issue-kodu için yaptığıyla aynı desen). Zaman-sürücülü bir listede
///   motor-sürücülü bir olayı tutmak, onu hiçbir zaman ateşlemeyecek bir
///   yere koymaktı — nitekim öyle oldu.
/// * **`streak` SİLİNDİ:** bir SAYI eşiği ister ve o eşik artefakttan
///   türemiyor; ayrıca ödül-döngüsü öğesi (aile Lissom'da ismen yasakladı).
///   Yetenek VAR, **iddia yasak**.
/// * **`settled` SİLİNDİ:** duruş-kararlılığı eşiği artefakttan
///   türetilemiyor (stance artefaktı `mirrorConfident=false` + `unattested`,
///   BAĞLANMADI 2026-07-29). Türetilemeyen eşik icat edilir.
///
/// Üçü de `session_narrator_test`in `engineDriven` MUAFİYET listesinde
/// duruyordu — "motor üretir" denmiş, üreten hiçbir kod yolu yazılmamıştı.
/// Muafiyet listesi kararın kendisi sanılmıştı; oysa bir muafiyet, kararın
/// ERTELENMESİDİR (aile dersi #6'nın beyan tarafı).

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
  CueBook(this._lines, {Map<String, List<String>> byKey = const <String, List<String>>{}})
      : _byKey = byKey;

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
    return CueBook(byEvent, byKey: flat);
  }

  final Map<NarrationEvent, List<String>> _lines;
  final Map<NarrationEvent, int> _cursor = <NarrationEvent, int>{};

  /// Anahtar → replik (düz harita). Olay tabanlı [_lines] yalnız anlatı
  /// olaylarını kapsıyor; motorun ürettiği HATA KODLARI (J-096) da bir
  /// cümleye çevrilmek zorunda ve onlar bir `NarrationEvent` değil.
  final Map<String, List<String>> _byKey;
  final Map<String, int> _keyCursor = <String, int>{};

  /// Replik anahtarından cümle — varyant DÖNDÜRÜLEREK, [say] ile aynı kural.
  ///
  /// `null` dönerse çağıran **ham anahtarı göstermemeli**: içerik eksikse
  /// kullanıcıya `REAR_HAND_LOW` yazmak, teşhis dizesini yüzeye sızdırmaktır.
  String? sayKey(String key) {
    final List<String>? lines = _byKey[key];
    if (lines == null || lines.isEmpty) return null;
    final int i = _keyCursor.update(key, (int v) => (v + 1) % lines.length,
        ifAbsent: () => 0);
    return lines[i];
  }

  bool hasKey(String key) => _byKey.containsKey(key);

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
    // DOLMAMIŞ ŞABLON SÖYLENMEZ (J-104 kusur #2). `cue.milestone` tetiği
    // bağlandığı ilk anda ekrana literal "{n} in." yazdı: çağıran `vars`
    // geçmiyordu ve bu sınıfın kendi `unfilledPlaceholder` regex'i yalnız
    // TESTTE kullanılıyordu, çalışma zamanında hiçbir şeyi engellemiyordu.
    //
    // Fırlatmak yerine SUSMAK seçildi: eksik bir değişken bir içerik/çağrı
    // kusurudur, kullanıcının seansını öldürmesi için bir sebep değil — ve
    // burada susmanın maliyeti bir sayım anonsunu kaçırmak, HÜKÜM susması
    // değil (o ayrı yuva, `noVerdictReason`, ve orada sessizlik yasak).
    // Kusurun cihaza ulaşmaması testin işi: `session_narrator_test`
    // içeriği tarayıp şablon taşıyan HER anahtarın doldurulduğunu zorluyor.
    if (unfilledPlaceholder.hasMatch(s)) return null;
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
};

/// MOTOR SÜRÜCÜLÜ replik anahtarları — `jabLabCueMapping`in dışında, çünkü
/// karşılık gelen bir [NarrationEvent] YOK ve olmamalı (yukarıdaki not).
/// `LiveJabController` bunları doğrudan [CueBook.sayKey] ile söyler.
const String jabLabCorrectedCueKey = 'cue.corrected';

/// MOTOR HATA KODU → REPLİK ANAHTARI (J-096). **Mekanik değil, ELLE.**
///
/// ## Neden `cue.${code.toLowerCase()}` DEĞİL
///
/// O kısayol açık ara en kolay yoldu ve **14 kodun 7'sinde sessizce
/// tutmuyor**: `TEMPO_TOO_FAST_FOR_FORM` → `cue.slow_down`,
/// `WRONG_HAND_FOR_COMBINATION` → `cue.wrong_hand`,
/// `COMBINATION_ORDER_ERROR` → `cue.combo_order`, `STANCE_TOO_NARROW` →
/// `cue.stance_narrow`, `TORSO_FALLING_FORWARD` → `cue.torso_forward`,
/// `LOW_TRACKING_CONFIDENCE` → `cue.low_confidence`, `STANCE_TOO_WIDE` →
/// `cue.stance_wide`.
///
/// Yazsaydım düzeltmelerin YARISI ham kod olarak yüzeye sızardı — ve yalnız
/// SEYREK hatalarda, yani elle denerken fark edilmezdi. Kod adı bir
/// TEŞHİS dizesidir; kullanıcıya gösterilmesi doc-75/5 sınıfının kamera
/// tarafıdır.
///
/// Eksiksizlik iki yönden testle zorlanıyor (`live_cue_mapping_test.dart`):
/// kural setindeki her kod BURADA olmalı **ve** buradaki her anahtar
/// `cues.en.json`da bulunmalı. Tek yön yeterli değil: sarkan atıf da,
/// eşlenmemiş kod da sessizce ham koda düşürürdü.
const Map<String, String> jabLabIssueCueMapping = <String, String>{
  // — teknik düzeltmeleri —
  'REAR_HAND_LOW': 'cue.rear_hand_low',
  'LEAD_HAND_NOT_RECOVERED': 'cue.lead_hand_not_recovered',
  'ELBOW_FLARED': 'cue.elbow_flared',
  'OVERREACH': 'cue.overreach',
  'TORSO_FALLING_FORWARD': 'cue.torso_forward',
  'STANCE_TOO_NARROW': 'cue.stance_narrow',
  'STANCE_TOO_WIDE': 'cue.stance_wide',
  'FEET_CROSSED': 'cue.feet_crossed',
  'BALANCE_LOSS': 'cue.balance_loss',
  'WRONG_HAND_FOR_COMBINATION': 'cue.wrong_hand',
  'COMBINATION_ORDER_ERROR': 'cue.combo_order',
  'TEMPO_TOO_FAST_FOR_FORM': 'cue.slow_down',
  // — görünürlük/hüküm-verilemez —
  // Bunlar bir TEKNİK kusuru değil: kullanıcı yanlış bir şey yapmıyor,
  // biz göremiyoruz. Yüzeyde de `noVerdict` yuvasına gider, düzeltme
  // yuvasına değil — ikisini karıştırmak kullanıcıyı olmayan bir hatayı
  // düzeltmeye çalıştırmak olurdu.
  'OUT_OF_FRAME': 'cue.out_of_frame',
  'LOW_TRACKING_CONFIDENCE': 'cue.low_confidence',
};

/// Görünürlük sınıfı kodları — düzeltme DEĞİL, "göremiyorum" sebebi.
const Set<String> jabLabVisibilityIssueCodes = <String>{
  'OUT_OF_FRAME',
  'LOW_TRACKING_CONFIDENCE',
};
