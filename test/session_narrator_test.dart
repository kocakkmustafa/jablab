import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/shell_candidate/live_surface.dart';

/// Anlatıcı + replik bağlarının değişmezleri (G7 bağlama turu).
///
/// **Replay denetimi** (aile standardı): anlatıcı gerçek bir seans zaman
/// çizgisinde koşturulur ve HİÇ ATEŞLENMEYEN durum aranır. Bir olayı tanımlayıp
/// hiç tetiklememek, kodda ölü dal bırakmakla aynı sınıf: derleyici susar,
/// testler yeşil kalır, kullanıcı o anı sessiz yaşar.
void main() {
  group('SAYIM yolu saatten BAĞIMSIZ (J-158)', () {
    test('counted() kilometre taşını saat olmadan üretir', () {
      // TEK kameralı ders (`boxing.foundations.jab`) tur planı TAŞIMIYOR,
      // yani `_Live` saati hiç kurmuyor. `tick()` tek çağıran olduğu sürece
      // `cue.milestone` **sayan tek derste** ulaşılamazdı — J-104 tetiği
      // bağladı, YOL kapalı kaldı.
      final SessionNarrator n = SessionNarrator(
        mode: SessionMode.steady,
        milestoneEvery: 5,
      );
      expect(n.counted(4), isEmpty, reason: 'eşiğe gelmeden söylenmemeli');
      expect(n.counted(5), <NarrationEvent>[NarrationEvent.milestone]);
    });

    test('AYNI sayı iki kez söylenmez, FARKLI sayılar ayrı ayrı söylenir', () {
      // Anahtar interpolasyonu bir kez KAÇIRILMIŞ yazıldı
      // (`'milestone-\$eventCount'`) ve o hâliyle her taş AYNI anahtarı
      // kullanırdı: yalnız ilki ateşlenir, 50. hiç söylenmezdi. Tek taş
      // atan bir test bunu göremezdi — bu yüzden ikisi de ölçülüyor.
      final SessionNarrator n = SessionNarrator(
        mode: SessionMode.steady,
        milestoneEvery: 5,
      );
      expect(n.counted(5), isNotEmpty);
      expect(n.counted(5), isEmpty, reason: 'aynı sayı tekrar söylendi');
      expect(
        n.counted(10),
        isNotEmpty,
        reason:
            'İKİNCİ kilometre taşı hiç söylenmedi — anahtar sayıya '
            'göre değişmiyor olabilir',
      );
    });

    test('tick() ile counted() AYNI sayıyı iki kez söylemez', () {
      // İki yol tek `_fired` kümesini paylaşıyor; paylaşmasalardı saatli
      // bir derste taş İKİ KEZ söylenirdi.
      final SessionNarrator n = SessionNarrator(
        mode: SessionMode.steady,
        milestoneEvery: 3,
      );
      expect(n.counted(3), isNotEmpty);
      expect(
        n.tick(
          elapsed: const Duration(seconds: 1),
          total: const Duration(seconds: 60),
          eventCount: 3,
        ),
        isNot(contains(NarrationEvent.milestone)),
      );
    });
  });

  final String cueSource = File(
    'assets/content/cues.en.json',
  ).readAsStringSync();
  CueBook book() => CueBook.fromJson(cueSource, jabLabCueMapping);

  test('[J-040] her olayın bir repliği var — eşlemesiz olay SESSİZ kalır', () {
    final CueBook b = book();
    for (final NarrationEvent e in NarrationEvent.values) {
      expect(
        jabLabCueMapping.containsKey(e),
        isTrue,
        reason:
            '$e eşlenmemiş — o an hiçbir şey söylenmez, kullanıcı da '
            'sessizliği "sorun yok" diye okur',
      );
      expect(b.covers(e), isTrue, reason: '$e için replik yüklenemedi');
    }
  });

  test('[J-040] sarkan atıf: olmayan replik anahtarına eşleme patlar', () {
    expect(
      () => CueBook.fromJson(cueSource, <NarrationEvent, String>{
        NarrationEvent.halfway: 'cue.yok_boyle',
      }),
      throwsA(isA<StateError>()),
      reason: 'sessizce atlanırsa o olay sonsuza kadar sessiz kalır',
    );
  });

  test('[replay] 3 dakikalık tur: beklenen her an konuşuluyor', () {
    final SessionNarrator n = SessionNarrator(mode: SessionMode.steady);
    const Duration total = Duration(minutes: 3);
    final Set<NarrationEvent> fired = <NarrationEvent>{};
    for (int s = 0; s <= total.inSeconds; s++) {
      fired.addAll(
        n.tick(
          elapsed: Duration(seconds: s),
          total: total,
          eventCount: s,
        ),
      );
    }
    expect(
      fired,
      containsAll(<NarrationEvent>[
        NarrationEvent.roundStart,
        NarrationEvent.halfway,
        NarrationEvent.lastTen,
        NarrationEvent.lastFive,
        NarrationEvent.roundEnd,
        NarrationEvent.milestone,
      ]),
    );
  });

  test('[replay] her olay tur içinde BİR KEZ — tekrar gürültüdür', () {
    final SessionNarrator n = SessionNarrator(mode: SessionMode.steady);
    const Duration total = Duration(seconds: 60);
    final List<NarrationEvent> all = <NarrationEvent>[];
    for (int s = 0; s <= 60; s++) {
      all.addAll(
        n.tick(
          elapsed: Duration(seconds: s),
          total: total,
        ),
      );
    }
    final Map<NarrationEvent, int> counts = <NarrationEvent, int>{};
    for (final NarrationEvent e in all) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    for (final MapEntry<NarrationEvent, int> c in counts.entries) {
      expect(
        c.value,
        1,
        reason:
            '${c.key} ${c.value} kez söylendi — sesli koç gürültüye '
            'dönüşür, gürültü de susmakla aynı sonucu verir',
      );
    }
  });

  test('[replay] tur sıfırlanınca "yarıladın" YENİDEN söylenir', () {
    final SessionNarrator n = SessionNarrator(mode: SessionMode.steady);
    const Duration total = Duration(seconds: 60);
    n.tick(elapsed: const Duration(seconds: 30), total: total);
    expect(n.tick(elapsed: const Duration(seconds: 30), total: total), isEmpty);
    n.startRound();
    expect(
      n.tick(elapsed: const Duration(seconds: 30), total: total),
      contains(NarrationEvent.halfway),
      reason:
          'sonraki turda da yarı noktası var; söylenmezse tur ilerledikçe '
          'ürün sessizleşir',
    );
  });

  test('[replay] aralık kipi: geçişler konuşuluyor, sürekli kip SUSUYOR', () {
    final SessionNarrator hiit = SessionNarrator(mode: SessionMode.interval);
    expect(
      hiit.interval(inBurst: true, wasInBurst: false, untilNext: Duration.zero),
      contains(NarrationEvent.burstStart),
    );
    expect(
      hiit.interval(inBurst: false, wasInBurst: true, untilNext: Duration.zero),
      containsAll(<NarrationEvent>[
        NarrationEvent.burstEnd,
        NarrationEvent.recover,
      ]),
    );
    expect(
      hiit.interval(
        inBurst: false,
        wasInBurst: false,
        untilNext: const Duration(seconds: 8),
      ),
      contains(NarrationEvent.nextBurst),
    );

    final SessionNarrator steady = SessionNarrator(mode: SessionMode.steady);
    expect(
      steady.interval(
        inBurst: true,
        wasInBurst: false,
        untilNext: Duration.zero,
      ),
      isEmpty,
      reason:
          'sürekli turda aralık repliği söylenirse kullanıcı olmayan bir '
          'yapıyı takip etmeye çalışır',
    );
  });

  test(
    '[replay] HİÇ ATEŞLENMEYEN olay yok — iki kip birlikte hepsini kapsar',
    () {
      // Zamanlayıcının ürettikleri + aralık geçişleri + motor sinyalleri.
      // Bir olay üç kanalın hiçbirinde çıkmıyorsa tanımlanmış ama ulaşılamazdır.
      final Set<NarrationEvent> reachable = <NarrationEvent>{};
      final SessionNarrator steady = SessionNarrator(mode: SessionMode.steady);
      for (int s = 0; s <= 180; s++) {
        reachable.addAll(
          steady.tick(
            elapsed: Duration(seconds: s),
            total: const Duration(minutes: 3),
            eventCount: s,
          ),
        );
      }
      final SessionNarrator hiit = SessionNarrator(mode: SessionMode.interval);
      bool was = false;
      for (int s = 0; s <= 120; s++) {
        final bool inBurst = (s ~/ 20).isEven;
        reachable.addAll(
          hiit.interval(
            inBurst: inBurst,
            wasInBurst: was,
            untilNext: Duration(seconds: 20 - (s % 20)),
          ),
        );
        was = inBurst;
      }
      // ⚠️ MUAFİYET LİSTESİ KÜÇÜLDÜ (J-105, 2026-08-07). Burada altı ad
      // vardı ve üçü (`corrected`/`streak`/`settled`) hiçbir kod yolundan
      // üretilmiyordu — liste "motor üretir" diyordu, üreten yazılmamıştı.
      // **Bir muafiyet bir karar değil, kararın ERTELENMESİDİR** ve bu liste
      // tam da o ertelemeyi kalıcı kılan yerdi: test yeşil kaldıkça kimse
      // bakmadı. Üçü de artık enum'da YOK — `corrected` motor-sürücülü olarak
      // `LiveJabController`a taşındı, `streak`/`settled` silindi (eşik icadı
      // ve ödül-döngüsü). Kalan üçü GERÇEKTEN ekran tarafından elle ekleniyor
      // (`_Live._tick`) ya da eklenmeyi bekliyor — ve `sessionStart` hâlâ
      // hiçbir yerden üretilmiyor, bu yüzden burada kalıyor ve `$producers`ta
      // `mapped-not-fired` diye BEYAN ediliyor.
      // ⚠️ MUAFİYET LİSTESİ 3→2 (J-120). `sessionStart` buradan da çıktı ve
      // enum'dan da: "seni görüyorum" ZAMANA değil MOTORA bağlı bir olay ve
      // artık `LiveJabController` onu ilk çözülen karede söylüyor.
      //
      // J-105'te bu listeyi 6→3 indirirken `sessionStart`ı *"gerçekten
      // eklenmeyi bekliyor"* diye bırakmıştım — **o bir karar değil, kararın
      // ertelenmesiydi**, yani muafiyet listelerinin ölü dalı sakladığı
      // mekanizmayı, o mekanizmayı BİLEN kişi olarak yeniden kurmuştum.
      //
      // Kalan ikisi gerçekten ekran tarafından elle ekleniyor
      // (`_Live._tick`): `rest` dinlenmenin başında, `sessionEnd` son turun
      // sonunda. İkisi de zaman olayı ve ikisinin de üreticisi VAR.
      const Set<NarrationEvent> engineDriven = <NarrationEvent>{
        NarrationEvent.sessionEnd,
        NarrationEvent.rest,
      };
      final Set<NarrationEvent> unreachable = NarrationEvent.values.toSet()
        ..removeAll(reachable)
        ..removeAll(engineDriven);
      expect(
        unreachable,
        isEmpty,
        reason:
            'tanımlı ama hiçbir kipte ateşlenmeyen olay: $unreachable — '
            'ölü dal, kullanıcı için sessiz an demektir',
      );
    },
  );

  test('varyantlar DÖNÜYOR — aynı cümle art arda gelmiyor', () {
    final CueBook b = book();
    final String? a = b.say(NarrationEvent.roundStart);
    final String? c = b.say(NarrationEvent.roundStart);
    expect(a, isNotNull);
    expect(
      a,
      isNot(c),
      reason: 'tekrar körlüğü: aynı cümleyi iki kez duyan onu duymaz olur',
    );
  });

  test('yer tutucu DOLDURULMADAN sesli okunmuyor', () {
    final CueBook b = book();
    // Yer tutucu taşıyan repliklerin hepsi değişkenle çağrılmalı; aksi hâlde
    // kullanıcı gerçekten "Round brace n brace" duyar.
    for (final NarrationEvent e in <NarrationEvent>[NarrationEvent.milestone]) {
      final String? filled = b.say(e, vars: <String, Object>{'n': 25});
      expect(filled, isNotNull);
      expect(
        CueBook.unfilledPlaceholder.hasMatch(filled!),
        isFalse,
        reason: '$e: doldurulmamış yer tutucu kaldı — "$filled"',
      );
      expect(
        filled,
        contains('25'),
        reason:
            '$e: yer tutucu kayboldu ama DEĞER de yok — '
            'kullanıcı sayıyı hiç duymuyor',
      );

      // ⭐ NEGATİF İKİZ (J-104 kusur #2). `vars` GEÇİLMEZSE ne oluyor?
      // Cevap 2026-08-07'ye kadar "ekrana literal `{n} in.` yazılıyordu"
      // idi: `cue.milestone`un tetiği bağlandığı ilk anda yakalandı.
      // Bu regex TESTTE vardı ama ÇALIŞMA ZAMANINDA hiçbir şeyi
      // engellemiyordu — beyanla korumanın farkı. Artık `say()` şablonu
      // SÖYLEMİYOR; susmak, şablon göstermekten dürüst.
      expect(
        b.say(e),
        isNull,
        reason:
            '$e: değişkensiz çağrıda ŞABLON döndü — '
            'kullanıcı "{n} in." okur/duyar',
      );
    }
  });

  test('[J-041] liveKeys İDDİASI ekranın gerçekten söylediğiyle eşleşir', () {
    // "Canlı" en güçlü iddia: kullanıcı bunu BUGÜN duyar. İddiayı ekranın
    // gerçek çağrısıyla karşılaştırmazsak, beyan zamanla gerçeğin önüne geçer
    // ve dosya "bağlandı" derken kullanıcı sessizlik yaşar.
    //
    // ⚠️ `eventCount` ARTIK GEÇİLİYOR (J-104). Bu satır eskiden yoktu ve
    // yorumu *"_Live ekranı eventCount VERMEDEN tick ediyor — o yüzden
    // sayıma bağlı replikler canlı DEĞİL"* diyordu. Doğruydu: ekran gerçekten
    // geçmiyordu, yani `cue.milestone` HİÇBİR koşulda ateşlenemiyordu.
    // Kamera köprüsü (J-096) sayımı getirdi ama çağrı güncellenmemişti;
    // `_LiveState._completedJabs` o boşluğu kapattı. Burada sayacın ARTAN
    // hâli taklit ediliyor — ekranın yaptığı da bu.
    final SessionNarrator n = SessionNarrator(mode: SessionMode.steady);
    const Duration total = Duration(minutes: 3);
    final Set<NarrationEvent> screenDriven = <NarrationEvent>{};
    for (int s = 0; s <= total.inSeconds; s++) {
      screenDriven.addAll(
        n.tick(
          elapsed: Duration(seconds: s),
          total: total,
          eventCount: s,
        ),
      );
    }
    final Set<String> actuallyLive = screenDriven
        .map((NarrationEvent e) => jabLabCueMapping[e])
        .whereType<String>()
        .toSet();

    final Map<String, dynamic> cues = (jsonDecode(cueSource) as Map)
        .cast<String, dynamic>();
    final Map<String, dynamic> producers = (cues[r'$producers'] as Map)
        .cast<String, dynamic>();
    final Set<String> claimed = <String>{};
    for (final MapEntry<String, dynamic> g in producers.entries) {
      if (g.key.startsWith(r'$')) continue;
      claimed.addAll(
        ((g.value as Map)['liveKeys'] as List<dynamic>? ?? <dynamic>[])
            .cast<String>(),
      );
    }

    expect(
      claimed.difference(actuallyLive),
      isEmpty,
      reason:
          'canlı DENEN ama ekranın söylemediği replik: '
          '${claimed.difference(actuallyLive)}',
    );
    expect(
      actuallyLive.difference(claimed),
      isEmpty,
      reason:
          'ekran söylüyor ama canlı BEYAN EDİLMEMİŞ: '
          '${actuallyLive.difference(claimed)} — beyan gerçeğin gerisinde '
          'kalırsa bir sonraki tur bunu "hâlâ bağlanmadı" sanır',
    );
  });

  testWidgets('[M-F-49] anlatı EKRANDA görünüyor, hüküm yuvası SUSUYOR', (
    WidgetTester t,
  ) async {
    // "Bağlandı" iddiası ancak görünen yüzeyde doğrulanırsa gerçektir.
    final CueBook b = book();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveCoachSurface(
            state: LiveState.noVerdict,
            eventCount: 0,
            narration: b.say(NarrationEvent.halfway),
            noVerdictReason: 'camera not connected',
          ),
        ),
      ),
    );
    expect(
      find.byKey(const Key('live-narration')),
      findsOneWidget,
      reason: 'anlatı yuvası çizilmiyor — replikler bağlandı denemez',
    );
    expect(
      find.byKey(const Key('live-cue')),
      findsNothing,
      reason: 'hüküm yuvası konuştu — kamera yokken form hükmü sızıyor',
    );
    expect(find.byKey(const Key('live-no-verdict')), findsOneWidget);
  });

  test('KİLOMETRE TAŞI EŞİĞE VARINCA ATEŞLENİYOR ve {n} DOLUYOR (J-121)', () {
    // ## J-104'ün açık borcunun kapanabilen yarısı
    //
    // Borç şuydu: *kilometre taşı repliğinin EKRANDA göründüğü
    // kanıtlanmadı.* Bu gece o kanıtın peşine düştüm ve **hangi katmanın
    // sorunlu olduğunu ayırdım** — ölçümle, tahminle değil:
    //
    //   ürün katmanı (bu test)   → 0 ms, replik doğru dolduruluyor
    //   widget koşumu            → kilometre taşı ATEŞLENDİĞİ an takılıyor
    //
    // Ayırıcı deney: eşik 25 iken 24 tekrar hızlı, 25 tekrar zaman aşımı;
    // eşik 2'ye indirilince 2 tekrarda da AYNI takılma. Yani hacim değil,
    // komşu testlerin zamanlayıcıları değil — **olayın kendisi.** Ve ürün
    // katmanı temiz olduğu için bu bir SEVKİYAT riski değil; koşum tarafı
    // borç olarak isimli duruyor.
    //
    // Bu test o borcun ölçülebilen yarısını KAPATIYOR: eşiğe varınca olay
    // üretiliyor, replik seçiliyor ve `{n}` GERÇEK sayıyla doluyor.
    final CueBook b = book();
    final SessionNarrator n = SessionNarrator(
      mode: SessionMode.steady,
      milestoneEvery: 2,
    );

    final List<String> spoken = <String>[];
    for (int s = 0; s <= 5; s++) {
      final List<NarrationEvent> ev = n.tick(
        elapsed: Duration(seconds: s),
        total: const Duration(seconds: 600),
        eventCount: s,
      );
      if (ev.contains(NarrationEvent.milestone)) {
        final String? line = b.say(
          NarrationEvent.milestone,
          vars: <String, Object>{'n': s},
        );
        expect(line, isNotNull, reason: 'eşikte replik seçilmedi');
        spoken.add(line!);
      }
    }

    expect(spoken, isNotEmpty, reason: 'eşiğe varıldı, olay hiç üretilmedi');
    for (final String line in spoken) {
      expect(
        CueBook.unfilledPlaceholder.hasMatch(line),
        isFalse,
        reason: 'yer tutucu dolmamış: "$line"',
      );
      expect(
        RegExp(r'^\d+').hasMatch(line),
        isTrue,
        reason:
            'replik SAYIYLA başlamıyor: "$line" — sayı gerçek '
            'sayaçtan gelmiyor olabilir',
      );
    }
    // ⭐ NEGATİF İKİZ: eşik ALTINDA olay YOK. Bu olmadan test, her tick'te
    // ateşlenen bir kilometre taşıyla da geçerdi — ve o koç her saniye
    // sayı sayardı.
    final SessionNarrator quiet = SessionNarrator(
      mode: SessionMode.steady,
      milestoneEvery: 100,
    );
    final List<NarrationEvent> none = quiet.tick(
      elapsed: const Duration(seconds: 3),
      total: const Duration(seconds: 600),
      eventCount: 5,
    );
    expect(
      none.contains(NarrationEvent.milestone),
      isFalse,
      reason: 'eşiğin ALTINDA kilometre taşı ateşlendi',
    );
  });
}
