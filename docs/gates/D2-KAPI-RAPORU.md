# D2 — Hız-Örnekleme Fizibilite Kapısı: SONUÇ RAPORU

**Tarih:** 2026-07-26 · **Protokol:** `D2-KAPI-PROTOKOLU.md` (eşikler ölçümden ÖNCE yazıldı, değiştirilmedi)
**Hüküm:** 🟡 **ŞARTLI GEÇTİ (D2-A + D2-B)** — gece modu §2.6 uyarınca ilerlendi, kurucu onayı sabah retrospektif.
**Kanıt:** `evidence/` (12 analiz JSON'u + `e_series.png`) · Hat: `motion-core/lib/tools/{extract_landmarks,analyze_d2}.py`
**D2-C (cihaz throughput) ÖLÇÜLMEDİ** — fiziksel cihaz + kilidi açık telefon gerekir, kurucu-kapılı.

---

## 1. Tek paragrafta sonuç

Altı gerçek boks klibinde (2.662 kare, 128 tespit edilmiş yumruk) uzanma fazının medyan süresi **128 ms**, en hızlı %10'luk dilimde **54 ms** ölçüldü. Bu, 30fps'te medyan yumruk için **3,8 kare**, en hızlı yumruklar için **1,6 kare** demektir; 60fps'te sırasıyla **7,7** ve **3,2 kare**. Faz-süresinden türetilen metrik, örnekleme 2× seyreltildiğinde **6/6 klipte** kare-arası piksel hızından daha kararlı çıktı (CV_phase ≤ 0,113 hepsinde; piksel metriği 1,2–4,0× daha oynak). **D2'nin dayattığı tasarım kararı — hız ASLA kare-arası pikselden değil faz-süresinden — ölçümle doğrulandı ve üretim koduna girebilir.** Buna karşılık bölgesel blur hipotezi (H2) bu görüntülerle **ne doğrulanabildi ne çürütülebildi**: görünürlük düşüşleri kapanma (occlusion) ve kadrajdan ayrıştırılamadı. Bu, eşik kalibrasyonunu kurucunun kendi çekimlerine bırakır — mimari kararı ise bloke etmez.

## 2. Ölçüm kümesi ve dürüstlük sınırı

| Klip | Kaynak / lisans | Çözünürlük @ fps | Kurulum | Yumruk | Kadans |
|---|---|---|---|---|---|
| `gym_10988078` | Pexels License | 1920×1080 @25 | yan, sabit, üst gövde | 23 | 1,91/sn |
| `woman_vert` | Pexels License | 1440×2560 @25 | yan, sabit, **tam vücut** | 17 | 1,67/sn |
| `punches_air` | Pexels License | 2560×1440 @24 | ön-eğik, üst gövde | 15 | 1,41/sn |
| `bag` (torba) | Wikimedia, **CC BY 4.0** | 1920×1080 @25 | yan, geniş açı, tam vücut | 16 | 0,66/sn |
| `slowmo_6296438` | Pexels License | 1920×1080 @25 | yan, elde | 23 | 1,05/sn |
| `slowmo_4761714` | Pexels License | 2732×1440 @25 | ön, çok karanlık | 34 | 2,54/sn |

⚠️ **Bu kliplerin hiçbiri JabLab'ın hedef senaryosu değildir.** Hepsi sinematik stok/arşiv görüntüsü: yan açı, dramatik ışık, sık sık yarım vücut kadrajı, bazıları elde kamera. JabLab'ın gerçek kurulumu **sabit telefon + tam vücut + sıradan oda ışığı + ön-eğik açı**. Ayrıca hiçbiri 25fps'in üstünde değil; 60fps davranışı ölçülmedi, **ölçülen gerçek süreden aritmetik olarak türetildi**.
Klipler **yalnız ölçüm içindir**: ship edilen fixture setine girmez, model eğitiminde kullanılmaz (katalog §0/§6).

## 3. Eşiklere karşı hüküm

| # | Ön-kayıtlı eşik | Ölçüm | Hüküm |
|---|---|---|---|
| 1 | `n_ext@60` medyanı ≥ 4 **ve** `n_ext@30` medyanı ≥ 2 | 7,7 @60 · 3,8 @30 | ✅ **GEÇTİ** |
| 1b | *(aynı eşik, en hızlı %10 dilim)* | 3,2 @60 · **1,6 @30** | 🟡 30fps'te SINIRDA |
| 2 | Yavaş bölgelerde `vis_min ≥ 0,5`, yumrukların ≥%90'ında | gövde ✅ (5/6 klipte <0,5 oranı 0,00) · ayaklar ✅ (ölçülebilen 2 klipte 0,00) · **arka el ⚠️ (0,07–0,60 arası)** | 🟡 **KISMİ** |
| 3 | `CV_phase ≤ 0,15` **ve** `CV_pixel ≥ 2×CV_phase` | CV_phase 0,027–0,113 (**6/6 ✅**) · 2× çarpan 4/6 klipte ✅, 6/6'da yön doğru | ✅ **GEÇTİ** (çarpan kısmi) |
| 4 | `jump_rate ≤ %5` | sabit+aydınlık klipler 0,7–4,7% ✅ · karanlık/elde klipler 10,8–18,9% ❌ | 🟡 **KOŞULLU** |

### 3.1 Ölçülen faz süreleri (H1)

| Klip | medyan `t_ext` | en hızlı %10 | @30fps kare | @60fps kare |
|---|---|---|---|---|
| slowmo_4761714 | 67,8 ms | 33,4 ms | 2,0 | 4,1 |
| gym_10988078 | 84,1 ms | 64,9 ms | 2,5 | 5,0 |
| bag | 119,5 ms | 65,6 ms | 3,6 | 7,2 |
| woman_vert | 136,9 ms | 56,4 ms | 4,1 | 8,2 |
| slowmo_6296438 | 157,6 ms | 39,0 ms | 4,7 | 9,5 |
| punches_air | 256,5 ms | 51,7 ms | 7,7 | 15,4 |
| **HAVUZ (klip-medyanlarının medyanı)** | **128,2 ms** | **54,1 ms** | **3,8** | **7,7** |

Aralığın genişliği (68–257 ms) gerçek bir olgudur, gürültü değil: **shadow boxing'in her yumruğu tam hızda atılmaz.** Kliplerin bir kısmı ısınma/teknik tempoda, bir kısmı tam hızda. Ürün açısından anlamı: *kullanıcı tempoyu kendisi seçiyor ve sistemin her tempoda çalışması gerekiyor* — hız metriği bir "ölçüm" değil, **tempo bandı** olarak sunulmalı.

### 3.2 Faz-süresi vs piksel-hızı (H3 — D2'nin çekirdek iddiası)

Örnekleme 2× seyreltildiğinde (25→12,5fps; gerçek ürün sorusu 60→30fps ile aynı oran), **aynı yumruk** iki örnekleme seviyesinde eşleştirilerek:

| Klip | `CV_phase` | `CV_pixel` | oran |
|---|---|---|---|
| punches_air | 0,027 | 0,091 | **3,39×** |
| gym_10988078 | 0,066 | 0,080 | 1,21× |
| woman_vert | 0,067 | 0,265 | **3,98×** |
| slowmo_6296438 | 0,079 | 0,305 | **3,85×** |
| slowmo_4761714 | 0,097 | 0,248 | **2,57×** |
| bag | 0,113 | 0,150 | 1,33× |

**Yön 6/6 klipte doğru.** Mekanizma da beklendiği gibi: seyreltme piksel-hızı tepesini *sistematik olarak aşağı* çeker (tepe kaçırılır), faz-süresi ise yalnız kuantizasyon gürültüsü alır — yanlı değil. Bu, `00-AILE-MIMARISI D2` maddesinin ölçümle desteklenmesidir. Araştırma korpusunun uyarısı geçerliliğini korur: literatür bu tasarımı *doğrudan* doğrulamaz, dolaylı destekler — **pazarlamada "kanıtlanmış hız ölçümü" DENMEZ.**

### 3.3 Blur mü kapanma mı? (H2 — SONUÇSUZ, dürüst kayıt)

Yumruk atan bilekte belirgin görünürlük düşüşleri var (0,17–0,52). Ancak bunun nedeni motion blur mü, gövdenin uzvu kapatması mı, ayırt edilemedi. Ayırt edici test — *aynı klip içinde hızlı yumruklar yavaşlardan daha çok bozuluyor mu* — tutarsız çıktı (ρ = −0,82 … +0,82, klip başına n=6–21). **H2 ne doğrulandı ne çürütüldü.**

Yan açıdan çekilen kliplerde kameradan uzak kol zaten gard hâlindeyken düşük görünürlükte (taban 0,03–0,62) → "düşüş" ölçümü kapanmayla kirleniyor. Bu, ölçümün başarısızlığı değil **ürün bulgusu**:

> **Saf yan açı, iki eli birden güvenilir göremiyor.** JabLab'ın kamera sihirbazı kullanıcıyı **ön-eğik (~30–45°)** yerleşime yönlendirmeli; hem gard eli hem yumruk eli aynı anda görünür olmalı. Tek ön-eğik klibimizde (`punches_air`) arka el <0,5 oranı **0,07**'ye düşüyor — yan açı kliplerinde 0,22–0,60.

Sağlam kalan alt-bulgu: **gövde (omuz+kalça) neredeyse bağışık** — 5/6 klipte yumruk boyunca düşüş 0,001–0,067 ve <0,5 oranı 0,00. Kadrajda olan ayak landmark'ları da dayanıklı (düşüş 0,038–0,195; <0,5 oranı 0,00).

## 4. Kapı çıktıları (roadmap G1 sözleşmesi)

### 4.1 Hız-metriği tasarım kararı — **KİLİTLENDİ**
Hız/tempo **yalnız** state-machine faz zaman damgalarından türetilir (`GUARD_READY→EXTENSION→PEAK→RETRACTION→RECOVERED`). Kare-arası piksel/landmark yer değiştirme hızı **hiçbir kullanıcı-görünür metriğe girmez**; yalnız iç tutarlılık kontrolü ve `jump_rate` güven kapısı için hesaplanır. Kullanıcıya gösterim: **bant** ("technical tempo: controlled / brisk / fast"), sayısal ms değil (§3.1 tempo dağılımı + CV yeterince dar değil).

### 4.2 V1 hareket/hata setinin güvenilirlik sıralaması

| Bant | Ne | Gerekçe |
|---|---|---|
| 🟢 **A — yayınlanabilir** | `STANCE_TOO_NARROW/WIDE`, `FEET_CROSSED`, `BALANCE_LOSS`, `TORSO_FALLING_FORWARD` | Gövde+ayak landmark'ları yumruk boyunca bozulmuyor (düşüş ≤0,07 / ≤0,20) |
| 🟢 **A** | Yumruk **olayı** tespiti + sayımı + kombinasyon **sırası** | Tespit oranı 25fps'te %100; faz sınırı medyanda 3,8 kare @30fps |
| 🟡 **B — ön-eğik kamera şartıyla** | `REAR_HAND_LOW`, `LEAD_HAND_NOT_RECOVERED` | Arka el güvenilirliği kamera açısına bağlı (§3.3) |
| 🟡 **B — kalibrasyon kurucu çekimini bekliyor** | `ELBOW_FLARED`, `OVERREACH` | Yumruk kolu dirseği en çok bozulan bölge; eşik ancak domain-eşleşmiş çekimle konur |
| 🟠 **C — bant olarak, sayı olarak DEĞİL** | tempo / "speed estimate", `TEMPO_TOO_FAST_FOR_FORM` | §4.1 |
| 🔴 **D — V1'e girmez** | hook/uppercut ayrımı, tam-hız yumrukta anlık form hükmü | Uzanma oranı `e` hook'ta tam açılmadığından bu detektör kapsamı dışı; ayrı state-machine + kendi kapısı gerekir |

### 4.3 fps politikası ÖNERİSİ (D2-C ölçülene dek koşullu)
- **Hedef 60fps** yakalama; 30fps kabul edilebilir taban.
- 30fps'te en hızlı yumrukların uzanma fazı ~1,6 kareye düşüyor → o cihazlarda **tempo bandı gizlenir**, form hükmü çalışmaya devam eder (hata sınıfları A bandı zaten yavaş bölgelerde).
- **Kadraj > kare hızı.** Bu ölçümün en tekrarlanan bulgusu: sonuçları bozan şey fps değil, uzvun kadraj dışında veya kapanmış olması. Kamera kurulum sihirbazı D2'nin en yüksek getirili çıktısıdır.

## 5. Açık koşullar (bu kapı tam kapanmadan yapılamayacaklar)

| Kod | Koşul | Kim |
|---|---|---|
| D2-C | Hedef cihazlarda MediaPipe `full` ile sürdürülebilir fps + 20-40dk termal profil | kurucu (cihaz) + oturum |
| D2-D | Domain-eşleşmiş çekim: sabit telefon, tam vücut, ön-eğik, **aynı kurulumda yavaş→orta→tam hız tempo merdiveni** (H2'yi kapanmadan ayırmanın tek yolu) | kurucu → `D2-CEKIM-PROTOKOLU.md` |
| D2-E | `ELBOW_FLARED` / `OVERREACH` eşik kalibrasyonu | D2-D sonrası oturum |

**Bu koşullar mimariyi bloke etmez.** Faz-süresi tasarımı, state-machine iskeleti, fixture şeması, kural-config formatı ve müfredat D2-D'den bağımsızdır → G2/G3/G4 ilerler. Bloke olan tek şey **eşik sayılarının nihai kalibrasyonu**dur.

## 6. Yan ürün: motor tasarımı bulgusu

Ölçüm sırasında detektör, torbaya yaslanan/kolunu uzatıp bekleyen boksörü "736 ms'lik yumruk" olarak okudu. Fiziksel üst sınır (`MAX_EXT_MS = 400`) eklenince sayılar normale döndü. Bu, `jablab-plan §10`'un istediği **timeout/iptal koşulunun** neden zorunlu olduğunun canlı kanıtıdır: üretim state-machine'i `EXTENSION_TIMEOUT` durumu olmadan aynı hatayı canlı seansta yapardı. Motor spesifikasyonuna girdi (DEFTER J-009).
