# 🧭 GEZİLEBİLİRLİK SAYMA KURALI — JabLab (J-221, 2026-08-12)

> **Sayı (2026-09-26):** katı **8** · gevşek **13** — kapı: `test/reachable_screens_test.dart`.
> **Bu belge sayıyı DEĞİŞTİRMEZ**, sayının hangi kuralla çıktığını yazar.
> Gravita'nın uyarısı: *"sekmeleri farklı sayıyorsak iki sayı AYNI ŞEYİ
> ÖLÇMÜYOR; fark içerik değil SAYMA KURALI olur."*

## Dört soru, dört cevap

### ① Sekme — KATI'da kaç, GEVŞEK'te kaç?

**Sıfır ve sıfır. JabLab'da SEKME YOK.**

4-sekmeli `NavigationBar` kabuğu **2026-08-06'da kaldırıldı** (Hüküm 1);
yapı bugün `SelectPage`(A) · `CoursePage`(B) · `SessionScreen`(C) +
`SettingsPage`(köşe düğmesi). Yani sekme sorusu bu hatta **ayırt edici
değil** — ama cevapsız bırakılamaz: 6'yı Gravita'nın 7'siyle kıyaslayan
biri, sekmelerin 6'nın **içine katlanmış** olabileceğini varsayabilir.
***Bir kuralın "bende yok" cevabı da kuralın parçasıdır.***

### ② Aday envanteri nasıl türetiliyor — desen mi, elle mi?

**ELLE — ve daha darı: YÜRÜYEREK.** Kapı bir desenden aday üretmiyor;
açılıştan başlayıp **ekranda görünen kontrollere basarak** gezip ulaştığı
ekranları işaretliyor, sonra **isimli beklenen kümeyle** karşılaştırıyor:

```
{onboarding, select, soloCourse, soloLesson, settings, whyNot, course, session}
```

Gravita **desenden türetiyor**, Lissom **elle tutuyor** (deseni bir ekranı
kaçırdığı için). JabLab **üçüncü bir noktada**: envanter elle yazılı ama
üyeliğin kanıtı **yürüyüş** — bir ad listede olsa bile ona **basarak
gidilemiyorsa** test düşer.

### ③ Ölçüm nereden başlıyor — kabuk mu, uygulama kökü mü?

**Uygulama kökü.** Kapı `pumpWidget(JabLabApp(...))` ile başlıyor, kabukla
değil. Bunun sonucu: **karşılama ölçümün İÇİNDE** (aşağı bak) ve
"uygulamayı ilk açan kullanıcı" hâli gerçekten ölçülüyor.

### ④ Onboarding içeride mi?

**EVET.**
* **Katı okumada 1** — `rota 1/6`, `seenOverride:false` ile ilk açılış.
* **Gevşek okumada 3** — üç perdesi ayrı sayılıyor (yürüyerek ölçülüyor).

`kLooseScreens = kStrictRoutes − 2 + kOnboardingPanels + kSessionStages`
= `8 − 2 + 3 + 4` = **13**. Çıkarılan 2, katıda birer sayılan **karşılama**
ve **seans**; yerlerine kendi perdeleri/aşamaları geçiyor.

---

## 🔍 Sayı DOĞRU SEBEPLE mi çıkıyor — gizli dayanak ÖLÇÜLDÜ

Lissom kendi sayısının dayanağını Flutter kaynağında doğruladı
(`skipOffstage: true`). JabLab'da karşılığı **aynı bayrak** ve ölçüldü:

| durum | `find.byType(SelectPage)` |
|---|---|
| Sayfa A ekranda | **1** |
| üstüne Ayarlar itilmiş, `skipOffstage: true` (varsayılan) | **0** |
| üstüne Ayarlar itilmiş, `skipOffstage: false` | **1** |

→ Yürüyüş **yalnız o an GÖRÜNEN** ekranı işaretliyor. Bu tesadüf değil,
sayının şartı: `mark()` çağrıları biriken bir `Set`e yazıyor ve
`skipOffstage: false` olsaydı **altta kalan** sayfalar da işaretlenip sayı
**şişerdi.** ***Bir sayının doğru olması yetmez; onu doğru yapan bayrağın
ne olduğu yazılı olmalı, yoksa bir sonraki tur onu farkında olmadan
değiştirir.***

## ⚠️ ENVANTER YÖNTEMİNİN KÖR NOKTASI — adıyla

> ***Yürüyüş yalnız UĞRADIĞI yeri bulur.*** Ulaşılabilir ama kimsenin
> basarak gitmediği bir ekran, bu kapıya **görünmez.**

Desen-türetimli envanterin (Gravita) kör noktası bunun **tersi**: kodda
duran ama ulaşılamayan bir ekranı sayabilir. İki yöntem **farklı yönde**
yanılıyor; hangisinin kullanıldığı yazılmazsa iki sayı kıyaslanamaz.

**Bu kör nokta bir kez ölçüldü ve bugün boş çıktı** (J-206): `Scaffold(`
taşıyan tüm sınıflar tarandı (pozitif kontrol: bilinen 6 ekranın hepsi
bulundu; negatif kontrol 0) → adsız-ulaşılamaz ekran **yok**; iki tanesi
kapıda adıyla dışlanmış (`CameraHarnessScreen` debug-kapılı ·
`ContentFailureScreen` hata yolu), `lib/shell_candidate/` dondurulmuş
envanter ve kendi kapısı var.

🔴 **AMA O TARAMA KAPILI DEĞİL** — tek seferlik bir ölçümdü. Yani kör
nokta bugün **kapalı ama korumasız**: yeni bir ekran eklenip yürüyüşe
katılmazsa, sayı sessizce eksik kalır ve **hiçbir test ötmez.**
*Kusur iddiada değil, korumasızlığında* (M-F-436) — kayda geçti, bu turda
kapatılmadı (ölçüyü değiştirme sınırı).

## 2026-09-26 güncel yöntem

Yukarıdaki tek seferlik tarama ve altı ekran anlatımı tarihsel temeldir.
Güncel kapı `Scaffold(` adaylarını çalışan kaynak metninden türetir,
tanıklı tek kök yürüyüşündeki varışlarla karşılaştırır ve altı varılamayan
adayın gerekçelerini ayrı sınar. Yeni solo kurs ve solo ders ekranları
ilk açılış kataloğundaki görünür karttan yürünür; ikisi de `push` varışıdır.
Katı sekiz ekran iki kök varış ve altı gerçek `push` ekranından oluşur.
Bu widget ölçümü gerçek cihaz, kamera veya mağaza kabulü değildir.


## 2026-10-04 Tai Chi written candidate route measurement

This candidate retains the historical counts above. Its extended single-root
witnessed walk adds TaiChiCoursePage and TaiChiLessonPage through visible
catalogue and lesson controls, returning by the actual back controls before
continuing the boxing/session walk. Current candidate: katı **10** · gevşek **15**, computed as `10 − 2 + 3 + 4`. Two root arrivals remain; both new
arrivals are witnessed pushes. The unreachable-class set and its checks are
unchanged. These are software route observations, not physical-course acceptance.


## 2026-10-05 Kickboxing written candidate route expectations — execution pending

The historical route measurements above remain unchanged. Kickboxing A adds
KickboxingCoursePage and KickboxingLessonPage to the existing single-root
control walk. The current source expectation is katı **12** · gevşek **17**,
computed as `12 − 2 + 3 + 4` = **17**. Two root arrivals remain; the two
Kickboxing routes are expected pushes through visible course and lesson
controls. The witnessed-walk, route membership, unreachable-class and
document/formula assertions all remain active; the actual loose-count
expectation is updated from 15 to 17.

These are source expectations for the extended walk. No Kickboxing route
measurement has been executed yet; the assigned test lane must provide the
new witness and exit-code receipt. This addition does not revise historical
10/15 observations or establish physical, device, store or full-domain
acceptance. The historical replay/aggregate and NO_CALL limits remain open.


## 2026-10-05 Karate source proposal over qualified Kickboxing v5

The existing historical contract above is preserved. The proposed current walk adds Karate course and lesson arrival by actual controls from the same fresh root. Its expected strict count is 14 (12 push + 2 root); loose count is 19 (plus 3 onboarding panels and 4 session stages). These are source expectations, not measured Karate results. The route test must witness every existing and new arrival; runtime remains UNRUN until a new lane is explicitly assigned. No historical 422-file or aggregate acceptance transfers to this source candidate.


### 2026-10-05 Karate route expectation — exact gate notation

The current Karate source expectation in the notation required by the preserved
document gate is katı **14** · gevşek **19**, computed as `14 − 2 + 3 + 4` = **19**.
This append-only notation correction retains every historical paragraph and
every route/document assertion. It changes no course, runtime logic or test.
The v1 walk reached 14 strict arrivals and 19 loose screens; its document-format
failure remains preserved in the separate qualification evidence. This new v2
source needs its own exact-source qualification before local software closure;
physical, device, product and historical aggregate acceptance remain open.


## 2026-10-05 Muay Thai source-only expectation over qualified Karate v3

All historical text above remains exact. The proposed fresh-root control walk adds Muay Thai course and lesson arrivals. Its source expectation is katı **16** · gevşek **21**; formula **16 − 2 + 3 + 4** (14 proposed push arrivals plus 2 roots; 3 onboarding panels and 4 session stages). Every previous traversal and assertion remains active. These counts are not observed Muay Thai results: tests, analyzer, build, render and download remain UNRUN until a separately assigned heavy lane. Prior Karate qualification applies only to tree339cc944accef6ee79c256c6260d72aad4514506; no result or historical aggregate acceptance transfers.


## 2026-10-06 Taikyoku Shodan same-root source expectation — execution pending

Every historical paragraph above is preserved byte for byte. The current source
walk enters TaikyokuCoursePage through the visible kata entry on KarateCoursePage,
opens TaikyokuLessonPage through the first lesson control, and uses the actual
back controls to return to the kata overview and then the Karate overview before
continuing the original Karate lesson and every later traversal. New membership
is recorded only by the existing visit/witness logic after those control actions;
the discovery, vacuity, root-arrival, unreachable-class and document assertions
remain active.

The source expectation is katı **18** · gevşek **23**, computed as
`18 − 2 + 3 + 4` = **23**: 16 expected push arrivals and the existing 2 root
arrivals, with 3 onboarding panels and 4 session stages. These are prepared
expectations, not observed route results. Independent v1 code review identified
the missing same-root kata traversal; this narrow v2 source delta awaits focused
review and its own exact-tree execution receipt.

The existing reachability suite and all 33 new Taikyoku cases remain UNRUN for
this candidate. Tests, analyzer, build, render and download remain deferred until
Braavo releases the shared heavy lane and the parent explicitly assigns it.
The historical qualification receipt applies only to the old 445-file tree
`dcb466024b2da49e068fc33499260c7cddf879cf`; it does not qualify this new
453-file candidate or establish physical, device, store, full-domain or historical
aggregate acceptance.


## 2026-10-06 Yang16 written form-order source expectation — execution pending

All prior paragraphs remain exact. The current same-root control walk enters
Yang16WrittenCoursePage from the visible Yang16 written-order card on the
existing TaiChiCoursePage, then Yang16WrittenTargetPage through the Preparation
control. It returns by the actual back controls before continuing the original
Tai Chi lesson and every prior traversal. These two witnessed route classes
cover all 18 written sections and six final targets; they are not 24 routes.

Source expectation: katı **20** · gevşek **25**, computed as
20 − 2 + 3 + 4 = **25**: 18 expected pushes and the existing two roots.
Every discovery, membership, root/push, unreachable-class and formula assertion
is retained. No new route measurement has run. Braavo owns the heavy lane.

This candidate extends the accepted 453-file tree
3d197a8a01bf50108bb56e6cab41123b04290396; its software and historical
receipts do not qualify this new source. Written form-order learning preserves
all false physical flags. Physical mechanics, media/device/store acceptance
and publication remain separate.


## 2026-10-12 Written recall routes — witnessed local source check

All historical paragraphs above remain byte-identical. The first-run select
surface now exposes a written recall entry after the existing course entries.
The same-root test taps that visible control, observes StudyReviewPage, taps
an actual lesson control, observes RecallLessonPage, and uses both visible back
controls to return before continuing every original traversal. Neither route is
registered as unreachable merely to satisfy the inventory.

Current source/walk count: katı **22** · gevşek **27**; formula
22 − 2 + 3 + 4 = **27**: 20 push arrivals and two root arrivals, with three
onboarding panels and four session stages. The witnessed local walk reached
all 22 classes and recorded both new arrivals as push events. This counts
reading routes; it does not establish physical curricula or mastery.
