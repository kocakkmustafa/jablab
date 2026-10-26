import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/app/rehearse_material.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/teach_material.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';

/// SAAT İDDİASI — yalnız saati OLAN derste (J-159).
///
/// ## Ölçülen kusur
///
/// Kamerasız derste canlı ekran şöyle diyordu: *"This lesson runs on the
/// clock — nothing is being judged. **The round timer** and the voice coach
/// both work."* Ve bu cümle **dersin saati olup olmadığına bakmıyordu.**
///
/// Ölçüm: **dört ders** (`camera` · `stance` · `cross` · `one_two`) hem
/// kamerasız hem **plansız**. `_Live.initState` planı olmayan derste
/// ticker'ı **hiç kurmuyor** (`if (_plan == null && _ivl == null) return;`)
/// — yani o dört derste ekran **var olmayan bir saati** anlatıyordu.
///
/// J-158'in kardeşi: orada saatin **yokluğu** bir repliği **ulaşılamaz**
/// yapıyordu; burada aynı yokluk bir cümleyi **yanlış** yapıyor. Aynı
/// eksik yapı, iki farklı kusur sınıfı.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Saatin **doğru saydığını** — yalnız *"saat var mı"* iddiasının
///   gerçekle uyuştuğunu. Sayma doğruluğu `session_rounds_test`in işi.
/// * Kameralı dersin cümlelerini (o dal `live_jab_path_test`te).
void main() {
  late CueBook cues;

  setUpAll(() async {
    cues = await const ContentRepository().loadCues();
  });

  Future<void> pumpLive(WidgetTester t, {RoundPlan? plan}) async {
    await t.pumpWidget(
      MaterialApp(
        home: SessionScreen(
          lesson: const ShellLesson(id: 'x', title: 'L', minutes: 3),
          cues: cues,
          coachedNotScored: const <String>[],
          bands: const <String, String>{'Stance': '—'},
          plan: plan,
          rehearseMaterial: const RehearseMaterialNone(
            reason: 'fixture: no drill named',
          ),
          teachMaterial: const TeachMaterialText(body: 'Body.'),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.runAsync(() async {
      for (int i = 0; i < 2; i++) {
        await t.tap(find.text('Continue'));
        await t.pump();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
    });
    await t.pump(const Duration(milliseconds: 150));
  }

  testWidgets('PLANSIZ derste "runs on the clock" DENMİYOR', (
    WidgetTester t,
  ) async {
    await pumpLive(t);
    expect(
      find.textContaining('runs on the clock'),
      findsNothing,
      reason:
          'plansız derste saat HİÇ kurulmuyor; "runs on the clock" '
          'var olmayan bir mekanizmayı anlatır (J-159)',
    );
    expect(
      find.textContaining('round timer'),
      findsNothing,
      reason: 'tur sayacı yokken adı geçiyor',
    );
    expect(
      find.textContaining('no clock'),
      findsOneWidget,
      reason:
          'saatin YOKLUĞU söylenmeli — sessizlik "saat var" diye '
          'okunur',
    );
  });

  testWidgets('POZİTİF İKİZ — PLANLI derste cümle DURUYOR', (
    WidgetTester t,
  ) async {
    // İkiz olmadan kapı, cümlenin HER YERDEN silinmesini de geçerli
    // sayardı: hiç saat iddiası yok, dolayısıyla hiç yanlış iddia yok.
    // Kapı bir iddiayı değil **bir sessizliği** korurdu — ve saatli derste
    // kullanıcı saatin çalıştığını bilmeli.
    await pumpLive(
      t,
      plan: const RoundPlan(
        rounds: 2,
        roundSeconds: 60,
        restSeconds: 30,
        planProvenance: 'test',
      ),
    );
    expect(
      find.textContaining('runs on the clock'),
      findsOneWidget,
      reason:
          'saatli derste saat iddiası kaybolmuş — J-159 plansız '
          'dersi kapsam dışı bıraktı, cümleyi kaldırmadı',
    );
  });

  testWidgets('⛔ NEGATİF İKİZ — "voice coach" YOK (D2, V1 SESSİZ)', (
    WidgetTester t,
  ) async {
    // Aynı cümle J-159 kapanışında bir de var-olmayan bir yeteneği
    // "çalışıyor" diye anlatıyordu: "...The round timer and the voice
    // coach both work." V1'de ses YOK — D2 kararı. Bu ikiz olmadan
    // yukarıdaki "runs on the clock" testi geçerdi ama YANLIŞ bir cümlenin
    // YARISINI hiç görmezdi.
    await pumpLive(
      t,
      plan: const RoundPlan(
        rounds: 2,
        roundSeconds: 60,
        restSeconds: 30,
        planProvenance: 'test',
      ),
    );
    expect(
      find.textContaining('voice coach'),
      findsNothing,
      reason:
          'V1 sessiz — var olmayan bir "voice coach"un çalıştığı '
          'iddia ediliyor (D2 ihlali)',
    );
    expect(
      find.textContaining('round timer'),
      findsNothing,
      reason:
          'bu kalem shell_candidate/live_surface.dart DEĞİL app '
          'katmanında — ama yine de alan-nötr "timer" tercih edildi, '
          'gelecekte kabuğa taşınırsa hazır',
    );
  });
}
