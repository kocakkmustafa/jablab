# Replik Erişilebilirlik Taraması — 2026-08-06

> Ders ekranı turunun ilk işi (koordinatör: *"bir repliğin VARLIĞINI tetiğinin varlığı
> sandım"* — kendi öz-eleştirisi). Kapsam yalnız `cue.low_light`/`cue.partial_analysis`
> ile sınırlanmadı, **tüm `cues.en.json`** tarandı (62 anahtar).

## Yöntem

1. `assets/content/cues.en.json`'daki HER anahtar çıkarıldı (62).
2. `lib/`de HER `'cue.xxx'` dize-sabiti grep'lendi (30 — `jabLabCueMapping` 16 +
   `jabLabIssueCueMapping` 14).
3. Fark = kodun hiçbir yerinde `cues.say()`/`cues.sayKey()`e ARGÜMAN olarak
   geçmeyen anahtarlar.

## 🔴 Sonuç: 62 anahtarın 32'si (%52) ÖLÜ — hiçbir kod yolu tarafından tetiklenmiyor

| Grup | Toplam | Canlı | Ölü | Ölü anahtarlar |
|---|---|---|---|---|
| `technique` | 13 | 12 | 1 | `cue.strike_not_extended` |
| `noVerdict` | 4 | 2 | **2** | **`cue.low_light`, `cue.structural`** |
| `counting` | 5 | 4 | 1 | `cue.count` |
| `encouragement` | 3 | 3 | 0 | — |
| `session` | 7 | 5 | 2 | `cue.round_of`, `cue.next_up` |
| `summary` | 9 | 0 | **9** | tümü — bkz. aşağı |
| `interval` | 4 | 4 | 0 | — |
| `setup` | 7 | 0 | **7** | tümü — bkz. aşağı |
| `drill` | 10 | 0 | **10** | tümü — bkz. aşağı |

## Sınıflandırma — ölü olmanın İKİ farklı sebebi var, karıştırılmasın

### (A) Muhtemelen İÇERİK-ÖNCÜ — beklenen bir özelliğin taslağı, henüz kod yok
- **`setup.*` (7):** `setup_step_back/center/angle/light/phone/space/done` — bir
  "kamera kurulum sihirbazı" akışının repliği gibi okunuyor.
  `shell_candidate/README.md`'nin "henüz yok" listesinde AYNEN var: *"kamera kurulum
  sihirbazı çatısı"*. Muhtemelen kod DAHA YAZILMADI, replik ONA hazırlanmış.
- **`drill.*` (10):** `drill.guard_discipline/snap_back/stance_reset/...` — tek-hareket
  mikro-drill kipi gibi görünüyor, bugünkü ders modeliyle eşleşmiyor (dersler tur/aralık
  planlı, tek-drill kipi yok).
- **`summary.trend_*`/`no_trend_yet` (4):** oturumlar-arası eğilim gösterimi — bugünkü
  `SessionSummaryView`'de böyle bir kavram yok (yalnız TEK seansın özeti var).

### (B) Muhtemelen GERÇEKTEN ölü/yetim — kodun içinde bir karşılığı olması beklenirdi
- **🔴🔴 `cue.low_light`, `cue.structural`** — koordinatörün kendi bulgusu, ölçüldü:
  motorun `QualityIssue` enum'u (`outOfFrame`/`lowTrackingConfidence`/`torsoUnreliable`)
  ile `StrikingEngine`'in `structural:` suppress sınıfı BUNLARI hiç `cues.sayKey()`e
  vermiyor (aşağıdaki 🔴🔴🔴 bulgusuna bakın — sebebi rastgele değil, YAPISAL).
- **`cue.strike_not_extended`** — "technique" grubunun 13.'ü, diğer 12'si
  `jabLabIssueCueMapping`de ama bu YOK. Karşılık gelen bir RuleSet kodu da yok
  (`assets/rulesets/boxing@1.0.0.json`da 14 kod var, hepsi eşlemede — bu 13. cue'ya
  karşılık gelen 15. bir kod YOK). Ya eski bir kodun kalıntısı ya unutulmuş bir eşleme.
- **`cue.count`** — `counting` grubunda tek başına yetim; kardeşleri
  (`halfway`/`last_ten`/`last_five`/`milestone`) hepsi `jabLabCueMapping`de.
- **`cue.round_of`, `cue.next_up`** — `session` grubunda; `round_start`/`round_end`/
  `rest`/`setup_ok`/`finished` eşlenmişken bu ikisi değil.
- **`cue.coached_not_scored`, `cue.not_measured_power`, `cue.scored_topics`,
  `cue.coached_topics`, `cue.partial_analysis`** — `summary` grubunun geri kalanı.
  **Özellikle `cue.coached_not_scored` dikkat ister:** `SessionSummaryView`de AYNI
  KAVRAM ZATEN VAR ama farklı bir yoldan — `coachedNotScored: List<String>` parametresi,
  `ContentRepository.coachedNotScoredLabels()`den geliyor, `cues.sayKey()`den DEĞİL.
  Muhtemelen iki paralel temsil aynı anda var; hangisi "doğru" olan belirsiz.

## 🔴🔴🔴 EN ÖNEMLİ BULGU — ölü replikten daha ciddi: CANLI bir yol ham teşhis sızdırıyor

`cue.low_light`/`cue.structural` neden hiç çağrılmıyor diye izleyince şunu buldum:
**`LiveJabController._onEnvelope`, `!out.judgeable` dalında `noVerdictReason`'a
`out.suppressionReason`'ı DOĞRUDAN yazıyor** (`lib/app/live_jab_controller.dart:177`):

```dart
if (!out.judgeable) {
  _states.add(LiveJabState.live(
    surface: LiveState.noVerdict,
    completedCount: _completed,
    noVerdictReason: out.suppressionReason,   // ← cues.sayKey() DEĞİL, ham motor dizesi
  ));
  return;
}
```

`suppressionReason` motorun kendi iç biçimlendirmesi
(`packages/jablab_engine/lib/src/striking_engine.dart:294-309`):
`'quality:lowTrackingConfidence'` · `'quality:outOfFrame'` · `'quality:torsoUnreliable'`
· `'structural:limbSwap,unnaturalAngle'` gibi dizeler — **cümle değil, teşhis kodu.**
`LiveCoachSurface` bunu `Text(noVerdictReason ?? ...)` ile OLDUĞU GİBİ basıyor
(`shell_candidate/live_surface.dart`).

**Bu doc-75/5'in ("ham teşhis dizesi kullanıcıya SIZMAZ") tam da önlemeye çalıştığı
sınıf** — ve JabLab'ın kendi tarihinde İKİ KEZ aynı hatayı yakalayıp düzelttiği bir
şey (J-096 kusur #1: ham `issue.code` · `ContentFailure.detail`in ikincilleştirilmesi).
Üçüncü kez, farklı bir yerde, hiç test edilmeden yaşıyor: `test/live_cue_mapping_test.dart`
YALNIZ `jabLabIssueCueMapping` yolunu (yani `issue`-tabanlı düzeltmeleri) sınıyor,
`suppressionReason` yoluna (yani `quality:`/`structural:`/`integrity:` bastırmalarına)
HİÇ DOKUNMUYOR — `live_jab_path_test.dart`da da bu dal koşulmamış (12/12 yeşil ama
hangi senaryoları kapsadığına bakılmalı).

**Neden `resolution.usable==false` dalı bu hataya düşmüyor:** o dal (kişi hiç
bulunamadı) elle yazılmış gerçek bir İngilizce cümle kullanıyor (satır 161-162),
`suppressionReason`e hiç dokunmuyor. Hata YALNIZ `engine.process()`in
`!out.judgeable` dediği, yani kişi VAR ama (kalite/yapısal/bütünlük nedeniyle)
HÜKÜM verilemeyen dalda.

**Bu bir "ders ekranı turu" kararı değil, bir DÜZELTME — 8 dürüst hâlin doğru
inşası buna bağlı** (özellikle "Tracking looks wrong"/`structural:` hâli): önce bu
yol kapatılmadan o hâli doğru göstermek mümkün değil, çünkü bugün o yol zaten YANLIŞ
bir şey gösteriyor.

## Sonuç — ders ekranı turu için doğrudan girdi

1. **`cue.low_light` SHİP EDİLMEZ** (koordinatör hükmü zaten böyleydi — motor sebep
   bilmiyor). Bu tarama nedenini de gösterdi: zaten hiç çağrılmıyor, "kapatmak" değil
   "hiç açmamak" doğru.
2. **`cue.structural` hâli GERÇEK bir sinyale karşılık geliyor** (`structural:` suppress,
   M-019) ama bugün o sinyal `cues.sayKey('cue.structural')`e hiç uğramıyor —
   `out.suppressionReason`in ham hâli kullanıcıya gidiyor. **Düzeltme gerekiyor:**
   `quality:*`/`structural:*`/`integrity:*` önekine göre dallanıp doğru `cue.` anahtarına
   yönlendiren bir çeviri katmanı eksik (issue-code yolunun zaten sahip olduğu
   `jabLabIssueCueMapping` deseninin bir benzeri).
3. **`cue.partial_analysis`** için `LiveJabRunning`de veri YOK (koordinatör hükmü:
   alan yoksa yüzde gösterilmez) — ship edilmez, hâlin kendisi (meşru olabilir) ayrı
   sorulacak.
4. **`cue.coached_not_scored` çelişkisi** koordinatöre/ders-ekranı turuna taşınmalı:
   iki paralel temsil (cue-key vs `coachedNotScoredLabels()`) hangisi kanonik?
5. **`setup.*`/`drill.*`/`summary.trend_*`** muhtemelen bilinçli içerik-öncü — ship
   kararı gerektirmiyor, yalnız DESIGN-AHEAD-OF-CODE'a not düşüldü (aşağıda).
