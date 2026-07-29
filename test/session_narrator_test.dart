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
  final String cueSource =
      File('assets/content/cues.en.json').readAsStringSync();
  CueBook book() => CueBook.fromJson(cueSource, jabLabCueMapping);

  test('[J-040] her olayın bir repliği var — eşlemesiz olay SESSİZ kalır', () {
    final CueBook b = book();
    for (final NarrationEvent e in NarrationEvent.values) {
      expect(jabLabCueMapping.containsKey(e), isTrue,
          reason: '$e eşlenmemiş — o an hiçbir şey söylenmez, kullanıcı da '
              'sessizliği "sorun yok" diye okur');
      expect(b.covers(e), isTrue, reason: '$e için replik yüklenemedi');
    }
  });

  test('[J-040] sarkan atıf: olmayan replik anahtarına eşleme patlar', () {
    expect(
        () => CueBook.fromJson(cueSource,
            <NarrationEvent, String>{NarrationEvent.halfway: 'cue.yok_boyle'}),
        throwsA(isA<StateError>()),
        reason: 'sessizce atlanırsa o olay sonsuza kadar sessiz kalır');
  });

  test('[replay] 3 dakikalık tur: beklenen her an konuşuluyor', () {
    final SessionNarrator n = SessionNarrator(mode: SessionMode.steady);
    const Duration total = Duration(minutes: 3);
    final Set<NarrationEvent> fired = <NarrationEvent>{};
    for (int s = 0; s <= total.inSeconds; s++) {
      fired.addAll(n.tick(
          elapsed: Duration(seconds: s), total: total, eventCount: s));
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
        ]));
  });

  test('[replay] her olay tur içinde BİR KEZ — tekrar gürültüdür', () {
    final SessionNarrator n = SessionNarrator(mode: SessionMode.steady);
    const Duration total = Duration(seconds: 60);
    final List<NarrationEvent> all = <NarrationEvent>[];
    for (int s = 0; s <= 60; s++) {
      all.addAll(n.tick(elapsed: Duration(seconds: s), total: total));
    }
    final Map<NarrationEvent, int> counts = <NarrationEvent, int>{};
    for (final NarrationEvent e in all) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    for (final MapEntry<NarrationEvent, int> c in counts.entries) {
      expect(c.value, 1,
          reason: '${c.key} ${c.value} kez söylendi — sesli koç gürültüye '
              'dönüşür, gürültü de susmakla aynı sonucu verir');
    }
  });

  test('[replay] tur sıfırlanınca "yarıladın" YENİDEN söylenir', () {
    final SessionNarrator n = SessionNarrator(mode: SessionMode.steady);
    const Duration total = Duration(seconds: 60);
    n.tick(elapsed: const Duration(seconds: 30), total: total);
    expect(n.tick(elapsed: const Duration(seconds: 30), total: total),
        isEmpty);
    n.startRound();
    expect(n.tick(elapsed: const Duration(seconds: 30), total: total),
        contains(NarrationEvent.halfway),
        reason: 'sonraki turda da yarı noktası var; söylenmezse tur ilerledikçe '
            'ürün sessizleşir');
  });

  test('[replay] aralık kipi: geçişler konuşuluyor, sürekli kip SUSUYOR', () {
    final SessionNarrator hiit = SessionNarrator(mode: SessionMode.interval);
    expect(
        hiit.interval(
            inBurst: true, wasInBurst: false, untilNext: Duration.zero),
        contains(NarrationEvent.burstStart));
    expect(
        hiit.interval(
            inBurst: false, wasInBurst: true, untilNext: Duration.zero),
        containsAll(
            <NarrationEvent>[NarrationEvent.burstEnd, NarrationEvent.recover]));
    expect(
        hiit.interval(
            inBurst: false,
            wasInBurst: false,
            untilNext: const Duration(seconds: 8)),
        contains(NarrationEvent.nextBurst));

    final SessionNarrator steady = SessionNarrator(mode: SessionMode.steady);
    expect(
        steady.interval(
            inBurst: true, wasInBurst: false, untilNext: Duration.zero),
        isEmpty,
        reason: 'sürekli turda aralık repliği söylenirse kullanıcı olmayan bir '
            'yapıyı takip etmeye çalışır');
  });

  test('[replay] HİÇ ATEŞLENMEYEN olay yok — iki kip birlikte hepsini kapsar',
      () {
    // Zamanlayıcının ürettikleri + aralık geçişleri + motor sinyalleri.
    // Bir olay üç kanalın hiçbirinde çıkmıyorsa tanımlanmış ama ulaşılamazdır.
    final Set<NarrationEvent> reachable = <NarrationEvent>{};
    final SessionNarrator steady = SessionNarrator(mode: SessionMode.steady);
    for (int s = 0; s <= 180; s++) {
      reachable.addAll(steady.tick(
          elapsed: Duration(seconds: s),
          total: const Duration(minutes: 3),
          eventCount: s));
    }
    final SessionNarrator hiit = SessionNarrator(mode: SessionMode.interval);
    bool was = false;
    for (int s = 0; s <= 120; s++) {
      final bool inBurst = (s ~/ 20).isEven;
      reachable.addAll(hiit.interval(
          inBurst: inBurst,
          wasInBurst: was,
          untilNext: Duration(seconds: 20 - (s % 20))));
      was = inBurst;
    }
    // Motor tarafından üretilenler: seans sınırları ve düzeltme sinyalleri.
    const Set<NarrationEvent> engineDriven = <NarrationEvent>{
      NarrationEvent.sessionStart,
      NarrationEvent.sessionEnd,
      NarrationEvent.rest,
      NarrationEvent.corrected,
      NarrationEvent.streak,
      NarrationEvent.settled,
    };
    final Set<NarrationEvent> unreachable = NarrationEvent.values.toSet()
      ..removeAll(reachable)
      ..removeAll(engineDriven);
    expect(unreachable, isEmpty,
        reason: 'tanımlı ama hiçbir kipte ateşlenmeyen olay: $unreachable — '
            'ölü dal, kullanıcı için sessiz an demektir');
  });

  test('varyantlar DÖNÜYOR — aynı cümle art arda gelmiyor', () {
    final CueBook b = book();
    final String? a = b.say(NarrationEvent.roundStart);
    final String? c = b.say(NarrationEvent.roundStart);
    expect(a, isNotNull);
    expect(a, isNot(c),
        reason: 'tekrar körlüğü: aynı cümleyi iki kez duyan onu duymaz olur');
  });

  test('yer tutucu DOLDURULMADAN sesli okunmuyor', () {
    final CueBook b = book();
    // Yer tutucu taşıyan repliklerin hepsi değişkenle çağrılmalı; aksi hâlde
    // kullanıcı gerçekten "Round brace n brace" duyar.
    for (final NarrationEvent e in <NarrationEvent>[
      NarrationEvent.milestone,
    ]) {
      final String? filled = b.say(e, vars: <String, Object>{'n': 25});
      expect(filled, isNotNull);
      expect(CueBook.unfilledPlaceholder.hasMatch(filled!), isFalse,
          reason: '$e: doldurulmamış yer tutucu kaldı — "$filled"');
    }
  });

  test('[J-041] liveKeys İDDİASI ekranın gerçekten söylediğiyle eşleşir', () {
    // "Canlı" en güçlü iddia: kullanıcı bunu BUGÜN duyar. İddiayı ekranın
    // gerçek çağrısıyla karşılaştırmazsak, beyan zamanla gerçeğin önüne geçer
    // ve dosya "bağlandı" derken kullanıcı sessizlik yaşar.
    //
    // _Live ekranı eventCount VERMEDEN tick ediyor (yumruk sayısı kameradan
    // gelir, köprü yok) — o yüzden sayıma bağlı replikler canlı DEĞİL.
    final SessionNarrator n = SessionNarrator(mode: SessionMode.steady);
    const Duration total = Duration(minutes: 3);
    final Set<NarrationEvent> screenDriven = <NarrationEvent>{};
    for (int s = 0; s <= total.inSeconds; s++) {
      screenDriven
          .addAll(n.tick(elapsed: Duration(seconds: s), total: total));
    }
    final Set<String> actuallyLive = screenDriven
        .map((NarrationEvent e) => jabLabCueMapping[e])
        .whereType<String>()
        .toSet();

    final Map<String, dynamic> cues =
        (jsonDecode(cueSource) as Map).cast<String, dynamic>();
    final Map<String, dynamic> producers =
        (cues[r'$producers'] as Map).cast<String, dynamic>();
    final Set<String> claimed = <String>{};
    for (final MapEntry<String, dynamic> g in producers.entries) {
      if (g.key.startsWith(r'$')) continue;
      claimed.addAll(
          ((g.value as Map)['liveKeys'] as List<dynamic>? ?? <dynamic>[])
              .cast<String>());
    }

    expect(claimed.difference(actuallyLive), isEmpty,
        reason: 'canlı DENEN ama ekranın söylemediği replik: '
            '${claimed.difference(actuallyLive)}');
    expect(actuallyLive.difference(claimed), isEmpty,
        reason: 'ekran söylüyor ama canlı BEYAN EDİLMEMİŞ: '
            '${actuallyLive.difference(claimed)} — beyan gerçeğin gerisinde '
            'kalırsa bir sonraki tur bunu "hâlâ bağlanmadı" sanır');
  });

  testWidgets('[M-F-49] anlatı EKRANDA görünüyor, hüküm yuvası SUSUYOR',
      (WidgetTester t) async {
    // "Bağlandı" iddiası ancak görünen yüzeyde doğrulanırsa gerçektir.
    final CueBook b = book();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LiveCoachSurface(
          state: LiveState.noVerdict,
          eventCount: 0,
          narration: b.say(NarrationEvent.halfway),
          noVerdictReason: 'camera not connected',
        ),
      ),
    ));
    expect(find.byKey(const Key('live-narration')), findsOneWidget,
        reason: 'anlatı yuvası çizilmiyor — replikler bağlandı denemez');
    expect(find.byKey(const Key('live-cue')), findsNothing,
        reason: 'hüküm yuvası konuştu — kamera yokken form hükmü sızıyor');
    expect(find.byKey(const Key('live-no-verdict')), findsOneWidget);
  });
}
