# JabLab — UI-BRIEF (tasarım girdisi)

**Tarih:** 2026-07-29 · **Amaç:** `claude.ai/design` oturumlarına girdi ·
**Bu doküman KOD DEĞİL** — ekran envanteri, durumlar, akış ve ton.
Uygulama dili **EN** (`library.json` `language: en`); bu brief TR yazılır,
**ürün metinleri EN verilir** (tasarıma girecek olan onlar).

> **Ürün tek cümlede:** Telefonu önüne koy ve gölge boks yap. Köşen gardı,
> duruşu, sırayı ve dengeyi söyler — torba yok, sensör yok.
> *"Put your phone in front of you and shadow box. Your corner calls out
> guard, stance, sequence and balance — no bag, no sensors."*

---

## 1. MARKA TONU — "dürüst köşe"

JabLab'ın sesi bir **köşe adamı**dır: kısa, sakin, abartısız, ve **bilmediğini
söyleyen**. Ürünün tüm ayırt ediciliği buradan gelir; tasarım bunu taşımazsa
ürün başka bir fitness app'i olur.

**Üç ses kuralı:**
1. **Ölçmediğini iddia etme.** Ekranda "power", "force", "kph" gibi bir sayı
   ASLA görünmez — ölçülemiyor. Bu bir eksik değil, konumlandırma.
2. **Sessizlik yalandır.** Sistem bir şeyi göremiyorsa bunu SÖYLER. Boş bir
   ekran kullanıcıya "her şey yolunda" diye okunur — bu yüzden "göremiyorum"
   ayrı ve tasarlanmış bir durumdur, hata değil.
3. **Neden'i söyle.** Bir şey puanlanmıyorsa sebebi yazılır ("deneyimli
   eğitmenler bunda anlaşmıyor"). Açıklamasız puan-yokluğu "sistem bozuk"
   diye okunur.

**Görsel karşılığı (öneri, tasarımcıya açık):** spor salonu değil **köşe**;
ter/neon klişesi değil, **odak ve netlik**. Karanlıkta okunabilirlik birinci
sınıf vatandaş — kullanıcı telefonu 2-3 m uzakta yere/rafa koyuyor, ekrana
yakından bakmıyor. **Uzaktan-okunurluk canlı ekranın 1 numaralı kısıtı.**

**Ton örnekleri (gerçek ürün metni, aynen kullanılabilir):**
- Öğretme anı: *"Nothing is being analysed yet — watch first. Scoring you
  while you are still learning the shape would punish learning."*
- Kamera yokken: *"The camera feed is not connected yet, so nothing is being
  judged. The round clock and the engine both work."*
- Puanlanmayan eklemler: *"Experienced instructors disagree about these, so we
  point them out but do not grade them."*
- Kapsam dışı: *"Some things a single phone camera genuinely cannot see.
  Rather than ship a version that guesses, we leave them out and tell you why."*

---

## 2. AKIŞ DİYAGRAMI (metin)

```
                      ┌─────────────────────────────┐
                      │  ONBOARDING (henüz YOK —    │
                      │  tasarlanacak: 3-4 ekran)   │
                      └──────────────┬──────────────┘
                                     ▼
        ┌────────────── 4 SEKMELİ KABUK (alt navigasyon) ──────────────┐
        │  Today          Library          Progress         Profile    │
        └────┬──────────────┬──────────────────┬───────────────┬───────┘
             │              │                  │               │
             │              ▼                  ▼               ▼
             │      ┌──────────────┐    ┌────────────┐  ┌────────────┐
             │      │ LibraryPage  │    │ProgressPage│  │ProfilePage │
             │      │ 8 disiplin   │    │ BANTLAR    │  │ + Paywall  │
             │      │ 1 canlı      │    │ (sayı YOK) │  │  iskeleti  │
             │      │ 7 "yakında"  │    └────────────┘  └────────────┘
             │      │ + "Neden yok?"────────► WhyNotPage (7 gerekçe)
             │      └──────┬───────┘
             │             ▼
             │      ┌──────────────┐
             │      │  ItemPage    │  tanıtım + DÜRÜSTLÜK KUTUSU
             │      │  (disiplin)  │  ("neler ölçülür / ÖLÇÜLMEZ")
             │      └──────┬───────┘  ⚠ "yakında" öğede kurs BAŞLIĞI BİLE yok
             │             ▼
             │      ┌──────────────┐
             │      │  CoursePage  │  3 kurs · 17 ders
             │      │  ders listesi│  kilitli dersler GÖRÜNÜR + sebebi yazılı
             │      └──────┬───────┘
             └─────────────┤ (Today kısayolu aynı yere iner — 2-TIK KURALI)
                           ▼
        ┌──────────── SEANS AKIŞI (4 aşama, tek ekran çatısı) ─────────┐
        │  ① teach  →  ② rehearse  →  ③ live  →  ④ summary            │
        │  öğret       dene           CANLI      özet                  │
        │  hüküm YOK   hüküm YOK      hüküm VAR  hüküm YOK             │
        └──────────────────────────────────────────────────────────────┘
                           │
                           ▼  (Done) → kurs sayfasına geri
```

**İki yapısal kural tasarımı bağlar:**
- **2-tık kuralı:** kullanıcı en fazla 2 dokunuşla bir seansa girebilir.
- **`stage.judges` yalnız `live`'da true.** Öğretme/deneme anında puan
  göstermek öğrenmeyi cezalandırır. Tasarım bu üç aşamayı görsel olarak da
  ayırmalı: *ölçülmeyen an* ile *ölçülen an* karışırsa kullanıcı sürekli
  yargılandığını sanır.

---

## 3. EKRAN ENVANTERİ + HER EKRANIN DURUMLARI

Aşağıdaki durumların **hepsi gerçek** — hiçbiri varsayımsal değil, bugünkü
kodda ya var ya da isimli olarak eksik.

### 3.1 Onboarding · **HENÜZ YOK, TASARLANACAK** 🔴
Bugün uygulama doğrudan kabuğa açılıyor. Tasarım ihtiyacı:
| durum | içerik |
|---|---|
| karşılama | tek cümle vaat + "no bag, no sensors" |
| dürüstlük ön-beyanı | ürünün ölçmediği şeyler BAŞTA söylenir (ton kuralı 1) |
| kamera yerleşimi | telefon nereye konur (ön-eğik ~30-45°, ADR-003) |
| hedef seçimi | *(ürün kararı bekliyor — tasarımda opsiyonel tutulsun)* |
| **izin reddi** | kamera izni verilmezse: Fitness turları YİNE ÇALIŞIR (saat+ses); bu ekran çıkmaz sokak OLMAMALI |

### 3.2 Today (sekme 1)
| durum | içerik |
|---|---|
| ilk kullanım | hiç seans yok → "başla" önerisi (hangi dersle başlanacağı önerilir) |
| dönen kullanıcı | ⚠️ **bugün üretilemez** — seans geçmişi yok (F-3, aşağıda) |
| boş | ilk-kullanım ile aynı |

### 3.3 Library (sekme 2)
| durum | içerik |
|---|---|
| normal | 8 disiplin ızgarası: **1 canlı** (Boxing) + **7 "yakında"** dalga rozetli (W1-W4) |
| "yakında" öğe | rozet + tıklanır ama **kurs listesi RENDER EDİLMEZ** (boş kurs göstermek yalan olurdu) |
| yükleniyor | `CircularProgressIndicator` (asset yüklemesi, çok kısa) |
| hata | ✅ **YAPILDI (J-079).** Dürüst hata ekranı bağlı: `ContentFailureScreen`. İki sınıf ayrı — **integrity** (içerik kendi içinde tutarsız; "We stopped ourselves", retry YOK çünkü aynı asset aynı sonucu verir) ve **unreadable** (okunamadı; retry VAR, yeniden kurmayı önerir). Kaçış kapısı YOK, geliştirici ayrıntısı katlanmış hâlde. **Tasarımcıya kalan:** ekranın görsel dili — bugün sade Material. Kural: kaçış kapısı eklenemez, ayrıntı birincil metne çıkamaz. |
| "Neden yok?" girişi | her zaman görünür — kapsamın sınırı gizlenmez |

### 3.4 ItemPage (disiplin sayfası)
| durum | içerik |
|---|---|
| canlı disiplin | tanıtım + **dürüstlük kutusu** + 3 kurs |
| "yakında" | tanıtım + dalga etiketi; kurs YOK |
| dürüstlük kutusu | "neler ölçülür" / "neler ÖLÇÜLMEZ" — `notMeasured` boşsa **assert ile patlar**, yani bu kutu asla yarım gösterilemez |

### 3.5 CoursePage (ders listesi)
| durum | içerik |
|---|---|
| normal | ders adı + süre + teknikler |
| **kilitli ders** | görünür ama açılmaz; **sebebi eksik ÖLÇÜMÜN adıyla** yazılı. Örnek: *"Hooks and uppercuts are counted but not classified, so we can't judge combination order here yet."* → **Tasarım: kilit bir CEZA gibi değil, bir DÜRÜSTLÜK BEYANI gibi görünmeli.** Bugün 3 ders kilitli. |

### 3.6 Seans — ① teach
| durum | içerik |
|---|---|
| materyal YOK (bugün **her ders**) | ders başlığı + alt başlık + **yokluk beyanı** (*"There is no lesson material to watch or read here yet — we have not made it…"*) + *"Nothing is being analysed yet."* |
| materyal VAR | aynı çerçeve, beyan yerine **materyal gövdesi** (`teach-material`); hüküm-susuyor cümlesi YİNE durur |
| ders bulunamadı | ayrı gerekçe (*"We could not find this lesson in the library…"*) — iki durum aynı cümleye düşmesin diye |
| **kalan** | 🟡 **görsel dil + içeriğin kendisi.** Yapı testli (J-094); "watch first" yalanı KALDIRILDI. Tasarımın işi: materyal varken nasıl görünür (oynatıcı/çizim/animasyon) ve yokluk beyanı nasıl durur. |

### 3.7 Seans — ② rehearse
| durum | içerik |
|---|---|
| normal | *"Go slow. One thing at a time, no clock."* — saat YOK, hüküm YOK |

### 3.8 Seans — ③ live · **ÜRÜNÜN YILDIZI**
| durum | içerik |
|---|---|
| süre akıyor | `IntervalTimer` — tur ilerlemesi |
| anlatı konuşuyor | 5 replik canlı: tur başı · yarıladın · son 10 sn · son 5 sn · tur sonu |
| **hüküm: `noVerdict`** | **BUGÜNKÜ TEK DURUM.** Kamera köprüsü yok → *"The camera feed is not connected yet, so nothing is being judged. The round clock and the engine both work."* |
| hüküm: tek düzeltme | (köprü gelince) **AYNI ANDA TEK düzeltme** gösterilir — iki uyarı birden kullanıcıyı dondurur |
| hüküm: "göremiyorum" | ayrı ve tasarlanmış durum: kullanıcı kadraj dışı / güven düşük |
| olumlu sinyal | (köprü gelince) "düzeltmeyi gördüm" |
| **kamera önizleme yuvası** | 🔴 henüz YOK |

**Tasarım kısıtları (canlı ekran):**
- **Ses BİRİNCİL, ekran İKİNCİL.** Kullanıcı yumruk atarken ekrana bakmıyor.
- **Uzaktan okunur** olmalı (2-3 m).
- **Anlatı yuvası ile HÜKÜM yuvası AYRI.** Turu saymak poza bakmayı
  gerektirmez; ikisi aynı yerde görünürse kamera yokken kullanıcı sistemin
  kendisini yargıladığını sanır. **Bu ayrım tasarımda korunmalı.**
- Sayı yerine **BANT** (ADR-001: tempo sayı değil bant).

### 3.9 Seans — ④ summary
| durum | içerik |
|---|---|
| bantlar | Stance / Balance / Footwork — bugün hepsi **"—"** (kalibrasyon kapısı K8) |
| **koçlanan-ama-skorlanmayan** | başlıklar AYRI gösterilir + sebebi: *"Experienced instructors disagree about these…"* — **J-061 sonrası jab için bu liste öncü kolun TAMAMINI içeriyor** |
| trend ("geçen turdan iyi") | 🔴 üretilemez — seans geçmişi yok (F-3) |

### 3.10 Progress (sekme 3)
| durum | içerik |
|---|---|
| bugün | 3 bant, hepsi **"—"** · `numericUnlocked=false` iken **sayı render eden KOD YOLU YOK** (K8'in UI karşılığı) |
| eksik | 🟡 süre/katılım bandı doldurulabilir ama kalıcılık yok (F-3) |

### 3.11 Profile (sekme 4) + Paywall
| durum | içerik |
|---|---|
| profil | ayarlar iskeleti |
| paywall | **fiyat SABİT YAZILMAZ** — kurucu kararı; test bunu zorluyor |
| eksik | hesap silme akışı · hatırlatıcı ayarları · streak/rozet (hiçbiri yok) |

---

## 4. TASARIMCIYA AÇIK SORULAR / BOŞLUKLAR

**🔴 Tasarım gerektiren, kod beklemeyen (şimdi yapılabilir):**
1. **Onboarding akışı** — hiç yok. Dürüstlük ön-beyanını sıkıcı olmadan
   anlatmak bu ürünün en zor tasarım problemi.
2. **Öğretici içerik yuvası** (teach aşaması) — 🟢 **YAPI KATMANI BİTTİ
   (J-094)**, geriye yalnız görsel dil + içeriğin kendisi kaldı.
   Kusur kayıtta yazandan daha ciddiydi: ekran *"watch first"* diyordu ve
   izlenecek hiçbir şey **yoktu** — `Lesson` modelinde materyal alanı bile
   bulunmuyor, yani kullanıcıya **yapamayacağı bir eylem** söyleniyordu.
   Bugün ekran materyali `ContentRepository.teachMaterialFor()`den TÜRETİYOR
   ve yokluğu gerekçesiyle beyan ediyor.
   **Tasarımcıya kalan:** materyal VARKEN nasıl görünecek (video oynatıcı mı,
   adım-adım çizim mi, animasyon mu) ve yokluk beyanının görsel dili.
   Zengin biçimler `TeachMaterial` hiyerarşisine **yeni varyant** olarak
   girer — bugün yalnız `Text` var, çünkü comp'suz dürüstçe render
   edebildiğimiz tek biçim o. Spekülatif alan (videoUrl, poster, süre)
   **bilerek yazılmadı**: tasarımın kararını kodun tahminiyle doldurmak,
   J-044'ün "17 okunmayan alan" kutusunu büyütmek olurdu.
3. ~~**Dürüst hata ekranı**~~ ✅ **yapı katmanı BİTTİ (J-079)** — geriye
   yalnız görsel dil kaldı (bkz. §3.3 "hata" satırı). Kusur kayıtta yazandan
   sinsiydi: crash değil, kullanıcıya basılan Türkçe `StateError` gövdesiydi.
4. **Kilit görsel dili** — ceza değil beyan gibi görünmeli (3 ders kilitli).
5. **Canlı ekranın uzaktan-okunur tipografisi** — 2-3 m mesafe.

**🟡 Kod kararı bekleyen (tasarım hazırlanabilir, bağlanamaz):**
6. Kamera önizleme yuvası (native köprü, koordinatör kuyruğu).
7. Çok-turlu seans göstergesi ("tur 2/6", dinlenme ekranı) — F-1 blokajı.
8. HIIT/aralık göstergesi — F-2, ayrı kapı.
9. Trend/geçmiş yüzeyleri — F-3 kalıcılık yok.

**Referans:** eksik envanterin tamamı ve sebepleri
`docs/gates/FITNESS-SHIP-DENETIMI.md` (F-1…F-5).
Kabuk bileşen listesi ve terfi kuralları `lib/shell_candidate/README.md`.

---

## 5. TASARIMI BAĞLAYAN SERT KURALLAR (ihlal = test kırılır)

Bunlar estetik tercih değil; mekanik olarak zorlanıyor:

1. **Kalibrasyonsuz SAYI gösterilemez** (K8/M-F-04) — bant kullan.
2. **`power` / `force` / `kph` kelimeleri replikte GEÇEMEZ** — ölçülmüyor.
3. **"Yakında" disiplinde kurs render EDİLMEZ.**
4. **Dürüstlük kutusunda `notMeasured` boş olamaz** (assert).
5. **Kapsam-dışı her madde GEREKÇELİ** olmak zorunda.
6. **Kilitli her ders SEBEBİYLE** gösterilir.
7. **Kalibrasyon kurulmadan "sol/sağ" DENMEZ** (M-F-06) — taraf-agnostik dil
   ("lead hand" / "rear hand"), footwork replikleri susar.
8. **Fiyat sabit yazılmaz.**
9. **Kabuk klasöründe alan sözlüğü yasak** — `punch`/`jab`/`round`/`boxing`
   kelimeleri `lib/shell_candidate/` içinde geçemez (5 app aynı kabuğu
   kullanacak).
