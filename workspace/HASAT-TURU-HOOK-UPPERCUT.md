# Hasat turu planı — hook ≥3 + uppercut ≥1, OLAY-DAMGALI

**Slot:** koordinatör M-F-194 (Choreia bıraktı, sıra JabLab'da).
**Şart:** olay-zaman-damgalı fixture · damga kaynağı İSİMLE · M-F-175 varyant
taraması · izole worktree.
**Durum:** plan hazır, indirme BAŞLAMADI (damga kaynağı önce doğrulandı).

---

## 0. Bu turu tetikleyen ders

Önceki tur (J-073→J-077) etiketsiz videoyla imza ölçmeye çalıştı ve
**ölçüm yapılamadı**: "kanca videosu" ≠ "kanca olayı". Bu tur o dersin
üzerine kuruluyor — **damga kaynağı, kaynak seçiminden ÖNCE gelir.**

## 1. DAMGA KAYNAĞI — isimlendirildi ve SINANDI

| katman | kaynak | ne verir | ne VERMEZ | maliyet |
|---|---|---|---|---|
| **D1** | **YouTube damgalı altyazı** (`yt-dlp --write-auto-subs --sub-format json3`) | saniye çözünürlüğünde **KONU** penceresi | hareket olayı | ~0,4 MB, saniyeler |
| D2 | `faster_whisper` transkripti (rig'de var, KURULU DEĞİL) | aynı şey, ses kaynağından | aynı sınır | model indirme + CPU |
| **D3** | **kurucu göz-doğrulaması** — D1'in daralttığı pencerelere bakış | **OLAY** onayı | ölçek (elle) | dakikalar/kaynak |

**Seçim: D1 + D3.** D1 aramayı daraltır, D3 olayı doğrular. D2 gereksiz —
D1 aynı bilgiyi bedavaya veriyor ve YAYIMLANMIŞ metin (whisper'ın kendi
hata payını eklemiyor).

### D1 SINANDI — mevcut hook kaynağında koşuldu (kanıt)

`pVvOF2kQuIQ` için altyazı çekildi (613 olay, 1491 s kapsam):

```
hook            61 anma
jab              1 anma      ← bu kaynak baştan sona KANCA
cross/straight   4
uppercut         2
shadow           0 · bag/mitt 2
```

**Ne kanıtladı:** kaynak sınıfı belirsizliği ORTADAN KALKTI. J-077'de
"o 6 FSM olayı muhtemelen eğitmenin demo jab'leri" demiştim; 25 dakikada
**tek bir jab anması** olan bir videoda bu açıklama ayakta duramaz.

**Ne KANITLAMADI — ve bu sınır tura yazılıyor:** "hook konuşmasına yakın"
gözlemi TABAN ORANA normalize edilince **bilgi taşımadı** (±12 s
pencerelerin birleşimi videonun **%57**'sini kaplıyor; 6 olayın 3'ü
içeride = %50, yani tesadüften ayrılamaz). **Konu penceresi bir olay
etiketi DEĞİLDİR** — eğitmen konuşurken çoğu zaman duruyor.

> **Tur kuralı:** D1 penceresi ARAMAYI daraltmak içindir, olay saymak için
> değil. Her sayısal iddia D3 onayına bağlanır ya da "onaysız" diye
> işaretlenir.

## 2. Kaynak şartnamesi

**hook ≥3 bağımsız eğitmen · uppercut ≥1** (M-C-04 tabanı).

Her aday için sırayla:

1. **D1 çek** → anma sayımı. Kapı: aranan teknik anması, diğer tekniklerin
   toplamının **en az 2 katı** olmalı. (Karışık "boxing basics" videosu bu
   kapıdan geçmez — ve geçmemeli, çünkü olay ataması imkânsızlaşır.)
2. **M-F-175 VARYANT TARAMASI — JabLab kipi: gölge ↔ torba/mitt.**
   Torbaya/mitte atılan kanca FARKLI TEKNİKTİR (temas, yavaşlama profili,
   duruş). D1'de `bag|mitt|pad|partner` anmaları sayılır; sıfır değilse
   **göz-doğrulaması ZORUNLU**, oto-ret YOK (M-F-175'in kendi hükmü: zayıf
   metin kanıtı → göz zinciri). Varyant `contextTags`e yazılır.
   *Mevcut kaynakta ölçüm: `bag/mitt` 2 anma, `shadow` 0 → göz-doğrulaması
   gerekiyor, kurucu listesine eklendi.*
3. **romMode** (mevcut rig) + **triyaj** (keskinlik/tespit) — değişmedi.
4. **D3 kuyruğu:** D1'in işaretlediği en yoğun 3 pencere + FSM'in
   tamamlanma damgaları → kurucuya tek liste hâlinde.

## 3. Neden uppercut ayrı ve daha zor

Bugün fixture **SIFIR**. Ek olarak uppercut dikey bir yörünge ve **önden
görünümde en çok kısalan** yumruk — pose tarafında en zayıf sinyal.
Beklenti dürüstçe düşük tutuluyor: bu turun uppercut hedefi
"sınıflandırılabilir mi" değil, **"bir kaynağımız olsun ve FSM'in ne
okuduğunu görelim"**.

## 4. İzolasyon ve yazma disiplini

* Hasat `~/motion-harvest/jablab/` altında (git DIŞI) — değişmedi.
* Kod/doküman değişikliği gerekirse **izole `git worktree`** (M-F-22);
  paylaşımlı ağaçta HEAD'e dokunulmaz.
* Alt-ajan kullanılırsa: `model:'sonnet'`, git-YAZMA yasağı, bağlam gömülü.

## 5. Kapanış kapısı — tur ne zaman "bitti" sayılır

1. hook ≥3 bağımsız eğitmen, her biri D1 kapısından geçmiş, varyantı
   işaretli;
2. uppercut ≥1 kaynak (ya da **isimli başarısızlık**: neden bulunamadığı);
3. her kaynak için D3 kuyruğu yazılmış (kurucu-bekleyen, tur onu BEKLEMEZ);
4. FSM'in her kaynakta ne okuduğu ölçülmüş (tamamlanma/abort/fallback
   üçlüsü + yoğunluk normalizasyonu — reçetenin Adım 3'ü);
5. **imza iddiası YOK** — o, D3 onayı geldikten sonraki turun işi.

Madde 5 kasıtlı: bu tur **malzeme** turudur, sonuç turu değil. Önceki tur
tam bu sırayı ters çevirdiği için üç kez düzeltme yazmak gerekti.

---

# KOŞUM SONUÇLARI

## D1 kapısı — 16 aday, video İNDİRİLMEDEN triyaj edildi

Araç: `d1_gate.py` (altyazı çeker, anma sayar, kapıyı uygular). Maliyet
aday başına ~0,4 MB ve saniyeler; bir video ~200 MB ve dakikalar.

### hook — hedef ≥3 bağımsız eğitmen ✅ **KARŞILANDI (4)**

| eğitmen | video | süre | hook | diğer | sonuç |
|---|---|---|---|---|---|
| precision_striking | `pVvOF2kQuIQ` | 24,8 dk | 61 | 7 | ✅ zaten FETCHED |
| yankello | `1B5Ja7Bry5k` | 8,0 dk | **30** | 0 | ✅ GEÇTİ |
| expert_boxing | `NxIWai9sDR8` | 4,9 dk | **28** | 4 | ✅ GEÇTİ |
| kennyweldon | `FJJy6Zc3XhM` | 2,0 dk | 4 | 0 | 🟡 GEÇTİ ama **malzeme ince** |
| tony_jeffries | `9OL0Mt0La6M` | 6,1 dk | 12 | 8 | ❌ karışık içerik |
| mcleodscott | `2I4HLsi0RuU` | — | — | — | ⬜ **altyazı YOK** → D1 ile triyaj edilemez |

### uppercut — hedef ≥1 ✅ **KARŞILANDI (3 bağımsız eğitmen)**

**Kuyruğun KENDİ 5 adayının HEPSİ kaldı.** Taze arama kurtardı:

| eğitmen | video | süre | uppercut | diğer | sonuç |
|---|---|---|---|---|---|
| fightcamp | `KcagWYVfvBg` | 4,6 dk | **23** | 3 | ✅ GEÇTİ ⚠️bag/mitt 2 anma |
| protips4u | `lqvdxbOyTgU` | 3,3 dk | **12** | 0 | ✅ GEÇTİ |
| howcast | `6KPs2tFATI0` | 2,0 dk | 7 | 1 | ✅ GEÇTİ |
| howcast | `On3ICoRfYDk` | 1,2 dk | 4 | 0 | ✅ GEÇTİ |
| tony_jeffries | `iInkodqd5pE` | 5,3 dk | 7 | 4 | ❌ oran 1,75 — **kapıya en yakın** |
| tony_jeffries | `zl2bZwxM_ws` | 5,8 dk | 5 | 5 | ❌ |
| tony_jeffries | `eBxn21FtqPg` | 3,0 dk | 1 | 6 | ❌ **başlığı uppercut, içeriği cross** |
| mcleodscott | `PxVQ7HKKchQ` | 4,7 dk | 0 | 0 | ❌ hiç teknik anması yok |
| frolov | `eO2QmJAKzp4` · `FC3GXrf2d54` | 0,8 · 0,3 dk | 4 · 0 | 8 · 0 | ❌ |
| fighttips | `VljZoHO1OLk` | 1,5 dk | 5 | 3 | ❌ |

## Bu koşumun ÖĞRETTİKLERİ

1. **Başlık bir kapı değil.** `eBxn21FtqPg` başlığı "The Correct Way to
   Throw Uppercut" ama içerikte `uppercut` 1, `cross` 5 anma. Kuyruğun
   uppercut adayları başlıktan seçilmiş ve **hepsi kaldı** — D1 bunu
   indirmeden yakaladı. Eski kuyruk "uppercut kaynağı yok" izlenimi
   veriyordu; gerçek sorun kaynak yokluğu değil, **aday seçim yöntemiydi.**
2. **Kapı iki BOYUTU karıştırıyor** — kendi kusurum, isimle kayıtta:
   oran kapısı **konu saflığını** ölçer, **malzeme miktarını** ölçmez.
   `FJJy6Zc3XhM` (2,0 dk, hook=4, diğer=0) mükemmel saflıkla geçiyor ama
   2 dakikadan kaç yargılanabilir kare çıkacağı ayrı bir soru
   (`SH1dLzI7vfI` dersi: **kaynak uygun ≠ ölçülebilir**). İkinci boyut
   ekstraksiyondan sonra ölçülecek; şimdiden elemedim, çünkü tahmin olurdu.
3. **Altyazısız kaynak elenmiş DEĞİL.** `2I4HLsi0RuU` ayrı kutuda: D1 ile
   triyaj edilemiyor, ama D3 (göz) hâlâ mümkün. "Aracım göremiyor" ile
   "uygun değil" aynı şey değil.

## FSM üçlüsü — mevcut kaynaklarda taban ölçümü (J-083)

Yeni fixture'lar gelmeden ÖNCE mevcutlarda taban alındı; yenileri bu
tabanla kıyaslanacak.

| kaynak | süre | fallback | modellenmiş | red | judgeable |
|---|---|---|---|---|---|
| **oov:** hook · precision_striking | 24,7 dk | 0 · 0,00/dk | 6 · **0,24/dk** | 0 | %40,6 |
| jab · precision_striking (kontrol) | 7,3 dk | 0 | 4 · **0,55/dk** | 0 | %46,1 |
| jab · tony_jeffries (kontrol) | 8,0 dk | 0 | 8 · **1,00/dk** | 0 | %22,4 |

**Pozitif kontrol olmadan bu tablo yanlış okunur** — ve ben bir kez yanlış
okudum (J-083). FSM kendi tekniğinde de 0,55-1,00/dk tetikliyor; öğretim
videosunda eğitmen çoğunlukla konuşuyor. Hook'un 0,24'ü daha düşük ama
"düzinelerce vs 6" değil.

**Yeni kaynaklar için kural:** her `oov:` ölçümü, aynı raporda en az bir
sözlük-içi kontrol satırıyla birlikte verilir. Tek başına verilen bir oran
okunamaz.

---

# TUR KAPANIŞI — FSM üçlüsü, 7 kaynak

| kaynak | tip | süre | judgeable | fallback | modellenmiş | red |
|---|---|---|---|---|---|---|
| `pVvOF2kQuIQ` precision | **oov** hook | 24,7 dk | %40,6 | **0** | 6 · 0,24/dk | 0 |
| `1B5Ja7Bry5k` yankello | **oov** hook | 7,8 dk | %19,2 | **0** | 1 · 0,13/dk | 0 |
| `FJJy6Zc3XhM` kennyweldon | **oov** hook | 2,0 dk | **%61,0** | **0** | **0** | 0 |
| `KcagWYVfvBg` fightcamp | **oov** uppercut | 4,8 dk | %45,5 | **0** | 1 · 0,21/dk | 0 |
| `lqvdxbOyTgU` protips4u | **oov** uppercut | 3,0 dk | %19,2 | **0** | **0** | 0 |
| `umI6jNMVG-s` precision | jab (kontrol) | 7,3 dk | %46,1 | **0** | 4 · 0,55/dk | 0 |
| `xOeEqDjkaVE` tony | jab (kontrol) | 8,0 dk | %22,4 | **0** | 8 · 1,00/dk | 0 |

## 1. En sağlam bulgu: fallback **0/7**

`unclassified_strike` **hiçbir kaynakta, hiç tetiklenmedi** — sözlük-içi ve
sözlük-dışı, 7 kaynak, ~58 dakika malzeme. Tamamen dekoratif. Aile
reçetesinin öncülü artık 7 kaynakla doğrulanmış durumda.

## 2. Kontrol artık VAR: sözlük-dışı, sözlük-içinden belirgin düşük

oov 0-0,24/dk · kontrol 0,55-1,00/dk. Bu ilk kez **taban orana karşı**
söyleniyor (J-083'te kontrolsüz söylemiştim ve o yüzden düşmüştü).

## 3. Beklenmedik: "görünürlük düşük olduğu için" AÇIKLAMASI ÇÜRÜDÜ

J-081'de üçüncü bir olasılık bırakmıştım: *"%40,6 hüküm-verilebilirlik →
teknik tanınmıyor mu, kare yargılanamıyor mu ayrışmıyor."*

`FJJy6Zc3XhM` onu ayırıyor: **korpusun EN İYİ görünürlüğü (%61,0 — iki jab
kontrolünden de yüksek)** ve **hiçbir şey tetiklenmiyor** (0 tamamlanma,
0 abort). Görünürlük mükemmelken de FSM kancada deneme başlatmıyor.

Tek kaynak ve 2 dakika — genelleme değil, ama **temiz bir karşı-örnek**:
"az yargılanabilir kare" açıklaması bu vakada geçerli değil.

## 4. Değişmeyen: imza iddiası YOK

Olay-başı ground truth hâlâ yok. Yukarıdaki hiçbir sayı bir eşiğe
dönüşmüyor. D3 kuyruğu bu yüzden var.

## 5. Kaynak muhasebesi — hedeflere karşı dürüst

**hook ≥3 bağımsız eğitmen:** 🟡 **2 tam + 1 kısmi.** precision_striking ✅ ·
yankello ✅ · kennyweldon 🟡 (fixture var ama romMode `unknown` →
**referansa GİREMEZ**; 2 dk'da yeterli konuşma yok) · expert_boxing ❌
**triyaj reddi: netlik 25 < 40** (D1'den geçmişti — konu saflığı mükemmel,
görüntü ölçülemez; "saflık ≠ ölçülebilirlik" ikinci kez ve bu kez isimli).

**uppercut ≥1:** ✅ **2 kaynak referans-uygun** (fightcamp · protips4u) —
sıfırdan ikiye. Ama ⚠️ `KcagWYVfvBg` netlik **47,3** (eşik 40'ın hemen
üstünde) ve `lqvdxbOyTgU` uygunluğu **tek bir zayıf işarete** dayanıyor
(§6).

## 6. Açık kalem: kendi işaret ailemde zayıf kalıp

`lqvdxbOyTgU` uygunluğu `FIRST_PERSON_DEMO_MARKERS`in `here('s| is) the`
kalıbından geliyor (J-058'de BEN ekledim). Ölçüldü: o transkriptte ailenin
**fiil gerektiren** kalıplarından **0** eşleşme var; tek eşleşme
*"this is the lead uppercut, and here's the other one"*.

Kalıp hareket fiili İSTEMİYOR — "here's the thing/deal/problem" de eşleşir.
Yani bir kaynağın referans-uygunluğu, hareket kanıtı olmayan tek bir
sunum ifadesine dayanabiliyor. **Ostinato'nun `keep your head` boşluğunun
aynadaki hâli, bu kez benim ailemde.**

Öneri (karar koordinatörde): kalıp ya bir teknik-ismine yakınlık şartı
alsın, ya da **tek başına uygunluk taşıyamayan "zayıf işaret"** sınıfına
düşsün. Ailenin tamamına dokunduğu için tek başıma değiştirmedim.

---

# TUR #2 — 2026-08-04 (J-093): D3-BAĞIMSIZ ADAY ARAMASI

Koordinatör sevki: **(b)** `expert_boxing` yerine yeni hook adayı (netlik-25
dersi akılda) · **(c)** daha uzun kennyweldon kaynağı. İmza iddiası YOK
(D3 hâlâ kurucuda).

## 0. Araç artık KALICI — ve iki tuzağı koda yazıldı

`d1_gate.py` scratchpad'te kaybolmuştu; motion-core
`tools/harvest_rig/d1_gate.py` olarak yazıldı (dal `feat/d1-gate-tool`).
**Çekirdek alan-bağımsız kalıyor:** dosyada tek boks terimi yok, terimler
`--lexicon` ile geliyor (`app/docs/harvest/lexicon-boxing.json`).

**Regresyon:** eski 5 kaynak **birebir aynı** sayıları verdi (61/7 · 30/0 ·
4/0 · 12/8 · nosub) — yeniden-yazım sadık.

Kapatılan sessiz-kırılmalar: `-` ile başlayan kimlik (argparse bayrak sanıyor,
Lissom L-191 sınıfı) · **0 hedef anması "0 ≥ 2×0" ile SESSİZCE geçerdi**
(`PxVQ7HKKchQ` tam buydu) · altyazı-yok ≠ uygun-değil · sözlükte dize verilirse
`list("metin")` harflere bölünürdü. Kapının bilinen kusuru (saflık ≠ malzeme)
artık **iki ayrı alan**: `purity` kapı, `material` yalnız uyarı.

## 1. (c) UZUN KENNYWELDON — ARANDI, BULUNDU, KULLANILAMAZ

| video | süre | hook | diğer | oran | sonuç |
|---|---|---|---|---|---|
| `dZiJ35ZdhyQ` (BudoVideo, yayıncı) | 55,0 dk | 12 | 60 | 0,20 | ❌ ⚠️bag/mitt **60** |
| `U5sU_soO0kg` (3. taraf yükleme) | 64,1 dk | 6 | 21 | 0,29 | ❌ |
| `f1kcXjj1HHw` | 2,8 dk | 0 | 0 | — | ❌ anma yok |
| `lw1mwKUX9JI` | 2,1 dk | 0 | 5 | — | ❌ |

**İSİMLİ NEGATİF SONUÇ — iki boyut bu eğitmende BİRBİRİNE TERS.**
kennyweldon'ın kısa videoları saf ama **ince** (`FJJy6Zc3XhM`: 2,0 dk, hook=4);
uzun videoları kalın ama **karışık** — çünkü uzunluğun kaynağı tam da
çok-teknik kapsamı. Bu bir arama başarısızlığı değil, ölçülmüş bir yapı:
*tek-teknik dersi veren eğitmen kısa çeker.* `dZiJ35ZdhyQ`de 60 bag/mitt
anması ayrıca M-F-175 varyant sorununun ölçek hâli.

## 2. (b) YENİ HOOK ADAYLARI — 6 D1-GEÇTİ, 4 TRİYAJLANDI, 3 TEMİZ

D1 kapısı (`--lexicon lexicon-boxing.json`):

| eğitmen | video | süre | hook | diğer | oran | D1 |
|---|---|---|---|---|---|---|
| myboxingcoach | `Hy94qxbdtvI` | 15,4 dk | 46 | 5 | 9,20 | ✅ ⚠️varyant 5 |
| marvin_cook | `vfEKHujQ-_g` | 10,7 dk | 25 | 2 | 12,50 | ✅ ⚠️varyant 1 |
| tony_jeffries | `i3G3HsI1GGU` | 8,7 dk | 37 | 5 | 7,40 | ✅ ⚠️varyant 2 |
| coach_anthony | `vlLmPtwSQlM` | 6,2 dk | 15 | 3 | 5,00 | ✅ varyant **0** |
| fightcamp | `1ZZncRfkt0A` | 5,1 dk | 18 | 0 | ∞ | ✅ ⚠️kimlik çakışması |
| world_class_boxing | `ihifYbOBBHM` | 4,4 dk | 27 | 10 | 2,70 | ✅ ⚠️**sahne şüpheli** |
| dynamic_striking | `8DY4vMNA4nw` | 13,6 dk | 7 | 12 | 0,58 | ❌ karışık |

Triyaj (`--no-extract --no-transcribe`; ağ-hafif, MediaPipe slotu ALINMADI):

| aday | netlik | çözünürlük | üst-gövde | kesme/dk | triyaj |
|---|---|---|---|---|---|
| `i3G3HsI1GGU` | **563,8** | 1920×1080 | **1,00** | 0,6 | ✅ |
| `Hy94qxbdtvI` | 159,9 | 1920×1080 | 0,83 | 0,3 | ✅ |
| `vfEKHujQ-_g` | 64,3 | 1920×1080 | 0,92 | 0,4 | ✅ |
| `vlLmPtwSQlM` | **39,2** | 1920×1080 | — | 1,6 | ❌ ret (eşik 40) |

rom ÖN-sınıflandırma (yayımlanmış altyazıyla; **manifest'e yazılmadı**,
kanonik damga tam koşumda): üçü de `active` / referansa **uygun**, güçlü
işaretlerle — `i throw`·`i pull` · `we drive`·`we move` · `we throw`·`we step`.

## 3. Bu turun ÖĞRETTİKLERİ

1. **Çözünürlük netliği ÖNGÖRMÜYOR — ölçüldü.** Dördü de 1920×1080, ret alan
   dahil; netlik **39,2 → 563,8, 14 kat** aralık. D1 kapısına çözünürlüğü
   "netlik vekili" olarak eklemeyi düşünüp *"tahmin olur"* diye vazgeçmiştim;
   artık tahmin değil ölçüm. **Kapıya eklenmeyecek.**
2. **"Eğitmen elendi" ≠ "video elendi".** `9OL0Mt0La6M` D1-FAIL alınca kuyruk
   tony_jeffries'i örtük olarak yazmıştı. Aynı eğitmenin başka videosu şimdi
   **korpusun en iyi triyaj skorunu** veriyor (563,8 / üst-gövde 1,00).
   Eleme kaydı KAYNAK düzeyinde tutulmalı, kimlik düzeyinde değil.
3. **D1'in ÜÇÜNCÜ boyutu: konu saf ama SAHNE yanlış.** `ihifYbOBBHM` kapıyı
   geçiyor (hook=27) ama muhtemelen arşiv maç görüntüsü üzerine anlatım —
   ekranda eğitmen tekniği *yapmıyor*. "Başlık ≠ içerik"in bir üst hâli:
   **içerik ≠ gösterim.** D1 metni sayar, sahneyi göremez; triyajın üst-gövde
   sondası kısmen yakalar, kesin ayrım göz-doğrulamasıdır. İNDİRİLMEDİ.
4. **Bayat-rig uyarısı GERÇEKTEN tetiklendi ve işe yaradı** (gotcha #4):
   koşum sırasında `behindOriginMain=2` çıktı. Sınır **ölçüldü, varsayılmadı**
   (J-085 disiplini): eksik iki commit yalnız `fixture_pipeline/mocore/`
   dosyalarına dokunuyor, `harvest_rig/`e sıfır → triyaj/rom kararları
   etkilenmiyor.

## 4. Kaynak muhasebesi — hook

precision_striking ✅ · yankello ✅ · **+3 aday** (myboxingcoach ·
marvin_cook · tony_jeffries) triyaj-temiz ve ön-sınıflandırmada uygun.
M-C-04'ün ≥3 bağımsız eğitmen tabanı **rahatça karşılanabilir görünüyor** —
ama "görünüyor" kelimesi kasıtlı: kanonik damga tam koşumda gelir.

## 5. TAM KOŞUM — M-F-239 slotuyla AYNI TURDA yapıldı

Rig `5bbced9` · `onMainLineage=true` · `behindOriginMain=0` · `dirty=false` ·
uyarı YOK (kendi aracım artık main'de, kendi aracımı main'den koştum).

**4/4 transkriptle `unknown → active`, dördü de referansa UYGUN, fixture ✓:**

| kaynak | eğitmen | netlik | üst-gövde | güçlü işaretler |
|---|---|---|---|---|
| `i3G3HsI1GGU` | tony_jeffries | 563,8 | 1,00 | `i throw` · `i'm leaning` |
| `Hy94qxbdtvI` | myboxingcoach | 159,9 | 0,83 | `we drive` · `we move` |
| `1ZZncRfkt0A` | fightcamp | 87,3 | 0,92 | `bring your` · `follow along` |
| `vfEKHujQ-_g` | marvin_cook | 64,3 | 0,92 | `we throw` · `we step` · `we shift` |

`Hy94qxbdtvI` özellikle önemli: başlık+açıklamada **yalnız zayıf** işaret
vardı (`here is the`) ve M-F-208 kademesi onu doğru şekilde eliyordu;
transkriptle J-090'ın birinci-şahıs ÇOĞUL ailesi devreye girdi ve kaynağı
kazandı. Zayıf-kademe + çoğul-aile birlikte çalıştı.

### 5.1 ⚠️ KİMLİK DÜZELTMESİ — kendi etiketim yanıltıcıydı

`ihifYbOBBHM`i "world_class_boxing" diye **ayrı bir eğitmen** sandım. Değil:
kanal, havuzda **zaten bulunan** `1B5Ja7Bry5k`in eğitmeni **Tom Yankello'nun
kendi kanalı**. M-F-239: havuz-içi kimlik = **ekrandaki eğitmen**, marka
değil. Sonuç: o video her iki göz-sonucunda da havuza yeni kaynak eklemez
(arşivse elenir; Yankello gösteriyorsa aynı kimlik). Kuralın kendi verimde
anında ısırması — kanal adını kimlik sanmak tam da kuralın yasakladığı şey.

### 5.2 ⚠️ MANİFEST VERİ KUSURU — özet, kanıtıyla çelişiyordu

`1B5Ja7Bry5k` üst düzeyinde `rom_mode=unknown / eligible=False` yazıyordu,
oysa **en yeni** `romMode` stage kaydı `active/True` (J-085'in tazeleme
turu). O tur stage kaydı EKLEMİŞ, **özet alanlarını güncellememiş**.
Bugünkü `harvest.py` ikisini birlikte yazıyor → **kod kusuru değil**, o
turdaki elle-tazeleme yolunun kusuru. Ama veri CANLI ve yanıltıcı:
`reference_eligible` okuyan bir tüketici UYGUN bir kaynağı dışlar — ve
benim ilk muhasebe tablom da tam bu yüzden yanlış çıktı, stage kayıtlarına
inene kadar. **Manifest elle DÜZELTİLMEDİ** (provenance kaydı); kanonik tam
koşum yeniden koşuldu ki özeti kodun kendi yolu yazsın. Bu, J-039/M-F-56
"beyan ≠ canlı" sınıfının veri-katmanındaki hâli.

## 6. HOOK HAVUZU — kaynak muhasebesi (ekrandaki eğitmen bazında)

| # | eğitmen | kaynak | durum |
|---|---|---|---|
| 1 | tony_jeffries | `i3G3HsI1GGU` | ✅ active/uygun |
| 2 | myboxingcoach | `Hy94qxbdtvI` | ✅ active/uygun |
| 3 | marvin_cook | `vfEKHujQ-_g` | ✅ active/uygun |
| 4 | fightcamp | `1ZZncRfkt0A` | ✅ active/uygun · ⚠️marka-korelasyonu notu |
| 5 | yankello | `1B5Ja7Bry5k` | ✅ active/uygun (özet düzeltildi) |
| — | precision_striking | `pVvOF2kQuIQ` | 🔄 kanonik tazeleme koşuyor |
| — | kennyweldon | `FJJy6Zc3XhM` | ❌ `unknown` + malzeme ince |
| — | coach_anthony | `vlLmPtwSQlM` | ❌ triyaj reti (netlik 39,2 < 40) |

**M-C-04 (≥3 bağımsız eğitmen): karşılandı — 5 uygun kimlik.**
Marka payı: fightcamp 1/5 → **hiçbir marka konsensüsün çoğunluğunu vermiyor**
(M-F-239 yoğunlaşma kuralı sağlanıyor; Gravita'nın %72-tek-kaynak arızasının
tekrarı yok). fightcamp'in uppercut havuzunda da bulunması **çakışma değil**
— bağımsızlık şartı havuz İÇİNDE geçerli.

## 7. NE YAPILMADI — ve neden

**Hook REFERANSI KURULMADI ve kurulamaz.** Kaynak yokluğundan değil:
`segment_punches.dart` pencereleri **FSM'in faz geçişlerinden** kesiyor ve
FSM kancayı **hiç modellemiyor** (`lockedBy: technique-unmodelled`). Yani
kesilecek kanca penceresi üretilmiyor. Zincir şurada kilitli ve kilit
**malzeme değil MEKANİZMA** tarafında — bu turun malzemeyi getirmesi o
kilidi açmıyor, sadece açıldığı gün hazır olmasını sağlıyor.

**İmza iddiası YOK**, hiçbir eşik önerilmedi (D3 hâlâ kurucuda).

### Kalanlar
* `2I4HLsi0RuU` hâlâ altyazısız → yalnız göz (D3 kalem 3).
* `ihifYbOBBHM` → D3 kalem 4; havuz buna bağlı DEĞİL.
* `vlLmPtwSQlM` ret payı 0,8 (39,2 vs 40) — eşik tartışılacaksa veri burada.
