# İçerik-Öncü Replikler — kodun henüz yetişmediği yazı

> **Neden bu dosya var.** `assets/content/cues.en.json` **sevk edilen** bir varlıktır.
> İçinde duran her replik, uygulamanın o cümleyi söyleyebildiğini iddia eder. Bugün
> söylenemeyen bir cümleyi orada tutmak, aile kuralı **M-F-186**'nın (*vaat dili yasak*)
> veri tarafıdır: kimse görmese bile beyan yanlıştır, ve bir gün biri o dosyaya bakıp
> "bu özellik var" diye okur.
>
> Ama **iyi yazıyı silmek de kayıptır.** Bu dosya üçüncü yolu tutuyor: replik sevk
> edilen varlıktan ÇIKARILIR, buraya **aynen** taşınır, ve **neyin eksik olduğu
> isimle** yazılır. Kod yetiştiğinde metin hazır; yetişene kadar hiçbir şey iddia
> edilmiyor.

**Tarih:** 2026-08-07 · **Kaynak:** J-104 ölü-replik temizliği
(`REPLIK-ERISILEBILIRLIK-TARAMASI-2026-08-06.md`nin uygulanması)

## Sınıflandırma kuralı

Bir replik `cues.en.json`dan çıkarıldıysa üç sebepten biriyle çıkmıştır:

| Sınıf | Anlamı | Nereye gider |
|---|---|---|
| **(a)** | Yetenek VAR, tetiği yazılmamış | Hiçbir yere — **tetiği yazılır**, replik kalır |
| **(b)** | Yetenek YOK ya da canlı bir yol AYNI ŞEYİ zaten söylüyor | **Silinir**, buraya girmez |
| **(c)** | Yetenek var/olabilir ama **yüzeyi** yok | **Bu dosya** |

(b) buraya girmez çünkü geri gelecek bir şey değildir: ya iddia asılsızdı ya da
metin zaten başka bir yerde canlı yaşıyor. Bu dosya yalnız **bekleyen** yazıdır.

---

## 1. SES KATMANI YOK — dördü de ekranda zaten var

**Eksik yüzey:** sesli koç (TTS). Bugün "anlatı" ekranda bir metin satırıdır
(`live-narration`), kulakta bir cümle değil.

**Neden bu dördü özel:** her birinin ekran karşılığı **zaten canlı**. Ekranda
`Round 2 of 3` yazarken anlatı yuvasına da "Round 2 of 3." basmak aynı olguyu iki
kez göstermektir — telefon uzaktayken *duymak* değerlidir, *iki kez okumak* değil.
Yani bunlar "yazılmamış özellik" değil, **sesli koçun sese özgü değeri**.

```json
"cue.count": ["{n}"],
"cue.round_of": ["Round {n} of {total}."],
"cue.scored_topics": ["Graded this round: {list}."],
"cue.coached_topics": ["Flagged but not graded: {list}."]
```

**Ekrandaki canlı karşılıkları:** `event-count` (sayım) · `live-round-position`
(tur konumu) · `SessionSummaryView`in bant listesi (skorlanan) ve
`coached-not-scored-note` + madde listesi (koçlanan).

**Açılma koşulu:** TTS katmanı. ⚠️ `{n}`/`{total}`/`{list}` yer tutucuları
`CueBook.say(vars:)` ile DOLDURULMAK ZORUNDA — doldurulmamış şablon artık çalışma
zamanında susturuluyor (J-104 kusur #2), yani bağlarken var geçmeyi unutmak sessiz
bir kayıp üretir, ekranda `{n}` değil.

---

## 2. KAMERA KURULUM SİHİRBAZI YOK

**Eksik yüzey:** kullanıcıyı telefonu yerleştirirken adım adım yönlendiren akış.
`shell_candidate/README.md`nin "henüz yok" listesinde adıyla duruyor.

**Bugün ne var:** kamera dersi canlı ve kurulum sorunlarını **tepki olarak**
söylüyor (`cue.out_of_frame`, `cue.low_confidence`, gövde-okunamıyor cümlesi,
J-103'ün iki dalı). Eksik olan **önden rehberlik**.

```json
"cue.setup_step_back":  ["Step back until I can see your feet.",
                         "A bit further back.",
                         "I need your whole body in frame."],
"cue.setup_center":     ["Move to the middle of the frame.",
                         "Centre yourself.",
                         "Slide over a little."],
"cue.setup_angle":      ["Turn slightly toward me.",
                         "A front-oblique angle reads your guard best.",
                         "Angle yourself about forty-five degrees."],
"cue.setup_light":      ["Face the light if you can.",
                         "Try not to stand against a window."],
"cue.setup_phone":      ["Prop the phone at hip height.",
                         "Waist height works best.",
                         "Lean it somewhere stable."],
"cue.setup_space":      ["Give yourself two steps in every direction.",
                         "Clear a little space around you."],
"cue.setup_done":       ["That's a good setup. Remember this spot."]
```

**Grup notu (korunuyor):** *Kamera ve alan dersi. Kullanıcı hareketsiz ve dinliyor,
bu yüzden sınır tur-içi repliklerden geniş. Bu grup KURULUM koşulunu tarif eder;
form hükmü VERMEZ.*

⚠️ **Bağlarken dikkat — `cue.setup_light` ayrı bir kapıya bağlı.** *"Face the light
if you can"* bir **öneri**dir ve ölçüm gerektirmez; ama ondan *"Too dark to read
your form"* (silinen `cue.low_light`) türetilemez — motorda ışık ölçümü YOK. İkisini
aynı sepete koymak, öneriyi sessizce ölçüm iddiasına terfi ettirir.

---

## 3. TEK-HAREKET DRILL KİPİ YOK

**Eksik yüzey:** dersin tur/aralık planı yerine tek bir hedefe kilitlenen kısa
tekrar kipi. Bugünkü ders modeli `RoundPlan`/`IntervalPlan` — ikisi de süre planlı,
"drill" kavramı yok.

```json
"cue.drill.guard_discipline":  ["Slow jabs. Only the other hand matters.",
                                "Forget speed. Watch the hand that stays home."],
"cue.drill.snap_back":         ["Throw and bring it straight back.",
                                "The return is the rep, not the punch."],
"cue.drill.stance_reset":      ["Reset your stance between each one.",
                                "Step out, step back, find the base."],
"cue.drill.footwork_basics":   ["Step and slide. Never cross.",
                                "Small steps. Feet never meet."],
"cue.drill.balance":           ["Punch, then hold your finish.",
                                "Freeze at the end of each one."],
"cue.drill.posture_reset":     ["Chest tall. Punch without folding.",
                                "Stay stacked through the shot."],
"cue.drill.combo_slow":        ["One, then two. No rush.",
                                "Half speed. Order over speed."],
"cue.drill.controlled_tempo":  ["Match my count. Not faster.",
                                "Stay on the beat."],
"cue.drill.straight_line":     ["Punch along a straight line.",
                                "Elbow follows the fist."],
"cue.drill.range_control":     ["Stay planted. Don't chase.",
                                "Punch from where you stand."]
```

**Grup notu (korunuyor):** *Drill başlangıç replikleri. Drill BAŞLAMADAN önce,
kullanıcı dururken söylenir — bu yüzden tur-içi sınırdan geniş. Her drill'in
hedefi tek.*

⚠️ **Eski `$producers` beyanı YANLIŞTI:** `"drill": {"by": "curriculum.drills[].introCue",
"status": "bound"}` yazıyordu. `library.json`da `drills` diye bir alan **yok** —
onunla üretilecek denmiş, üretici hiç yazılmamış, beyan güncellenmemiş. Bu, aile
dersi #6'nın beyan tarafı: *bir üreticinin ADININ yazılı olması, üreticinin var
olduğunu kanıtlamaz.*

---

## 4. TURLAR-ARASI EĞİLİM HESABI YOK

**Eksik yüzey:** iki turu birbiriyle karşılaştıran bir hesap. `SessionStore`
(append-only JSONL) seans geçmişini **tutuyor**, ama tur bazında bir ölçüm
saklamıyor ve "gard daha az düştü" diyebilecek bir karşılaştırma katmanı yok.

```json
"cue.trend_improving": ["Your guard dropped less this round than last. That's your own trend, not a score."],
"cue.trend_worse":     ["Guard dropped more often this round. Usually that's fatigue, not technique."],
"cue.trend_flat":      ["About the same as last round."],
"cue.no_trend_yet":    ["Not enough rounds to call a trend."]
```

⚠️ **Bağlarken dikkat — K8 sınırı burada ince.** Bu dördü sayısal skor DEĞİL, bu
yüzden K8'e takılmıyor; ama *"daha az düştü"* bir **karşılaştırma iddiasıdır** ve
kalibre edilmemiş bir ölçümden türetilirse K8'i arka kapıdan ihlal eder. Bağlanması
için gereken şey bir ekran değil, **turlar arası karşılaştırılabilir bir ölçüm** —
ve o ölçümün türetimi makine-okunur taşınmalı (*eşik icadı YOK*).

`cue.trend_worse` ayrıca yorum yapıyor (*"usually that's fatigue, not technique"*).
Bu iyi bir cümle ama bir **hüküm**: bağlanırken yorgunluk ile teknik ayrımının neye
dayandığı da yazılmak zorunda, yoksa dürüst görünen bir tahmin olur.

---

## Silinenler — burada DEĞİL, ve neden

Tamlık için: aşağıdakiler `cues.en.json`dan çıkarıldı ama bu dosyaya **girmedi**,
çünkü geri gelecek bir şey değiller.

| Replik | Sınıf | Sebep |
|---|---|---|
| `cue.low_light` | (b) | Motorda **ışık ölçümü alanı yok**. *"Too dark to read your form"* ölçmediğimiz bir şeyi ölçtüğümüzü iddia ediyor. |
| `cue.partial_analysis` | (b) | `LiveJabRunning`de **kısmi-okuma yüzdesi alanı yok**. *"I could only read {pct} percent"* doldurulacak veriye sahip değil. |
| `cue.next_up` | (b) | *"Next: {name}"* — `{name}` kaynağı **yok**. `RoundPlan` turların adını taşımıyor; bir seans tek dersten oluşuyor, "sıradaki" diye bir şey yok. |
| `cue.not_measured_power` | (b) | **Üçüncü ikiz.** `library.json → power_measurement` **canlı** (WhyNotPage'de görünüyor) ve daha güçlü yazılmış: *"Force needs a sensor… we will not print a power number we cannot measure."* |
| `cue.coached_not_scored` | (b) | **İkinci ikiz.** `SessionSummaryView` aynı cümleyi `coached-not-scored-note` anahtarıyla **gösteriyor**. J-098'in ("hangisi kanonik?") cue tarafı: kullanıcının OKUDUĞU olan kanonik. |

**J-098'in kalan yarısı (koordinatöre):** kanonik metin bugün `SessionSummaryView`
içinde **hardcoded** duruyor ve o widget `shell_candidate/` altında DONDURULMUŞ.
Yani cümle içerik katmanından değil kod katmanından geliyor — çeviri/varyant
alamıyor. Bu bir kusur değil, **donmuş kabuğun sınırı**; kabuk terfi turunda
`SessionSummaryView` içerikten beslenmeye açılırsa cue-key yolu geri gelmeli.

---

## Bakım kuralı

`test/live_cue_mapping_test.dart` içindeki **ölü-replik kapısı** bu dosyayı
zorluyor: `cues.en.json`daki her anahtarın kodda bir çağrı yolu olmak zorunda.
Yeni bir replik yazıp tetiğini yazmazsan test kırmızıya döner ve seni üç seçenekten
birini **isimle** seçmeye zorlar — tam da J-104'ün 30 anahtarda bir kerede yaptığı
işi, bir sonraki anahtarda otomatik yapar.
