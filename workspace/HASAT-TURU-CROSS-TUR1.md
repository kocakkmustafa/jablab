# 🥊 CROSS — HASAT TURU-1 İCRA KAYDI

> Ölçütler `HASAT-TURU-CROSS-KRITERLER.md`de donduruldu (2026-08-16, hiçbir aday
> görülmeden). Bu belge o dondurulmuş ölçütlerin turu-1'deki UYGULAMA kaydı —
> hiçbir eşik burada değiştirilmedi/yorumlanmadı.

## §5.1 havuzunun ölçümü — GERÇEK FSM koşumu, varsayım değil (J-061 emsali)

`segment_punches.dart --technique cross` zaten-hasat-edilmiş 13 video / ~9
kimliğe uygulandı (`--manifests` ile tazelik zorlandı):

| kimlik (§5.1) | test edilen video(lar) | netlik | eligible+active | cross pencere |
|---|---|---|---|---|
| **precision_striking** | umI6jNMVG-s | 84,2 | ✅ | **1** |
| **precision_striking** | pVvOF2kQuIQ | 141,8 | ✅ | **3** |
| **fightcamp** | KcagWYVfvBg | 47,3 | ✅ | **1** |
| fightcamp | 1ZZncRfkt0A | 87,3 | ✅ | 0 |
| yankello | 1B5Ja7Bry5k | — | ✅ | 0 |
| yankello | yA5WNu-sx34 | — | ✅ | 0 |
| tony_jeffries | xOeEqDjkaVE | — | ✅ | 0 |
| tony_jeffries | i3G3HsI1GGU | — | ✅ | 0 |
| myboxingcoach | Hy94qxbdtvI | — | ✅ | 0 |
| marvin_cook | vfEKHujQ-_g | — | ✅ | 0 |
| Sören (havuz-dışı, mevcut) | InSkFbZWoBY | — | ✅ | 0 |
| Russian School of Boxing (havuz-dışı, mevcut) | JDVmntRBjH4 | — | ✅ | 0 |
| "Fight your way Fit" (havuz-dışı) | SH1dLzI7vfI | — | ✅* | 0 |
| SportVideos (havuz-dışı) | FJJy6Zc3XhM | 24 | ❌ triyaj | — |
| ProTips4U (havuz-dışı) | lqvdxbOyTgU | — | ❌ | 0 |

*SH1dLzI7vfI: J-061'in bilinen "çok-kişili vlog, %41 outOfFrame" tuzağı — eligible
görünse de ölçülebilirlik şüpheli, bu yüzden 0 sonucu ayrıca doğrulayıcı değil.

**Sonuç (yalnız yerel havuz):** 2 kimlikte ölçülmüş cross malzemesi —
precision_striking (4 pencere, 2 video) · fightcamp (1 pencere, 1/2 video).
Altı diğer eligible+active kaynak **0** verdi. ≥3 tabanının ALTINDA.

## Yeni aday arama (hâlâ turu-1, §5.1 penceresi aşılmadı)

Zaten-güvenilir kanallardan (precision_striking hariç, o zaten kapalı) "jab
cross"/"1-2 combo" başlıklı 4 yeni video hasat edildi (channel_id H-48 gereği
kaydedildi):

| video | kimlik | channel_id | netlik | transkript | eligible | cross pencere |
|---|---|---|---|---|---|---|
| vyTaKpylOcU | Tony Jeffries | UCT_8YwHmACxpUootXe7yKjA | 313,2 | ✅ tamamlandı | ❌ **UNKNOWN** (marker yok) | **1** (72 kare, 1902ms) |
| e5ciNJ0h-dw | MyBoxingCoach | UCBsoiiNF96Beqbik3LSxkUA | 156,4 | ✅ tamamlandı | ❌ UNKNOWN | 0 |
| gA8Se6i8mAI | Marvin Cook | UCMsEQzNrJjlRhrJ7TfROOlw | 254,7 | ✅ tamamlandı | ❌ UNKNOWN | 0 |
| z-zev0ftmSQ | Yankello/World Class Boxing | UCFd-tIEZTYhdR3lWCQ7inyg | 222,2 | ✅ tamamlandı | ❌ UNKNOWN | 0 |

**4/4'ü AYNI şekilde başarısız: netlik YÜKSEK (156–313, hepsi ≥40'ın kat kat
üstünde), transkript GERÇEKTEN üretildi, ama romMode sınıflandırıcısı hiçbir
işaret bulamadı → fail-closed unknown.** Bu bir süreç arızası DEĞİL —
`vyTaKpylOcU`nun transkripti okundu (Tony Jeffries): dil "I'm going to give
you.../I show you..." — birinci-tekil ANLATICI kalıbı, ne J-090'ın
birinci-çoğul ("we throw") ne J-064'ün ikinci-şahıs emir kipi ("your hands
up") ailesine giriyor. **Muhtemelen sınıflandırıcının ÜÇÜNCÜ bir boşluğu**
(J-064'ün "referans yok" YERİNE "hiçbir zaman aranmadı" örneği) — ama bu
motion-core'un paylaşılan `harvest_rig` kodu, jablab'ın tek taraflı
değiştireceği bir şey değil; adıyla bırakıldı, düzeltilmedi.

**`vyTaKpylOcU`nun 1 penceresi §2 kanıt barının yalnız 1/4'ünü karşılıyor**
(netlik ✅, ama transkript-doğrulanmış coaching ❌, TAM koşum eligible=True ❌)
→ kendi ölçütüme göre "bulundu" SAYILMAZ (kennyweldon'un hook'taki
`fixture VAR ama romMode unknown` emsaliyle AYNI sınıf, J-060/J-064).

## kennyweldon — havuzun son üyesi

Kendi kanalı yok; içerik yalnız 3. taraf yeniden-yüklemelerinde dolaşıyor:
`MMA Combat Lessons` (kOZYFiPTXoY, zaten hasatta, 87s<90s triyaj-reddi) ·
`SportVideos` (kısa klipler, aynı kanal FJJy6Zc3XhM/2qqtwf3hu2s/xzGwiNdShpM,
netlik zaten 24 ile reddedildi) · `Alex Alex` (uzun-form ~45-65dk
derleme/kurs yeniden-yüklemeleri). En olası aday `d7sPW7fuS_E` ("Vol 1",
55:28) denendi: **HTTP 403, İKİ ayrı denemede de aynı hata** (M-F-605
emsali: "araç arızası ≠ malzeme reddi" ayrımı bir kez yeniden-deneme
hakkı verir — verildi, ikinci deneme AYNI şekilde düştü, yani bu geçici
bir takılma değil, bu video için kalıcı bir erişim engeli). Daha fazla
deneme (format zorlama, farklı çıkarıcı yolu) orantısız — tek ve zaten
zayıf bir aday için. **kennyweldon: gerçek bir aday BULUNAMADI** (kanal
yok, mevcut 3. taraf malzeme ya triyaj-reddedilmiş ya erişilemez).

## §5 turu-1 SONUCU — havuz TÜKENDİ, ölçüt kendi hükmünü veriyor

`§5.1` havuzunun **8 üyesinin TAMAMI** işlendi (turun bitiş koşulu §4
karşılandı — hiçbiri "bakılmadı/sırada" değil):

| kimlik | durum | gerekçe |
|---|---|---|
| **precision_striking** | ✅ **BULUNDU** | 4/4 kanıt barı — netlik 84,2/141,8 · eligible+active · 4 cross pencere |
| **fightcamp** | ✅ **BULUNDU** | 4/4 kanıt barı — netlik 47,3 · eligible+active · 1 cross pencere |
| tony_jeffries | ❌ bulunamadı | 3 video denendi (2 eligible+0-pencere, 1 pencereli+unattested) — hiçbiri 4/4'ü birden geçmedi |
| yankello | ❌ bulunamadı | 3 video denendi (2 eligible+0-pencere, 1 unattested+0-pencere) |
| myboxingcoach | ❌ bulunamadı | 2 video (1 eligible+0-pencere, 1 unattested+0-pencere) |
| marvin_cook | ❌ bulunamadı | 2 video (1 eligible+0-pencere, 1 unattested+0-pencere) |
| coach_anthony | ⛔ triyaj-elendi | 4 ayrı video, hepsi netlik<40 (aile hook-hasadının 39,2 bulgusuyla tutarlı) |
| kennyweldon | ⛔ erişim-elendi | kanal yok, tek gerçek aday 403'te kalıcı takıldı (2 deneme) |

**Turu-1 İLK SAYIM: 2 bağımsız kimlik, 4 kanıt barını BİRDEN geçti.
M-C-04 ≥3 tabanının ALTINDA.**

D17'nin penceresi ≤2 tur — turu-1 bunun 1'i. Plan B **tetiklenmedi**
(pencere tükenmedi, 1 tur hakkı kaldı) — orkestratöre bildirildi, tek
taraflı turu-2'ye geçilmedi.

## §6 KÖK-SEBEP DÜZELTMESİ — "4/4 yeni aday aynı şekilde düştü" bir
sınıflandırıcı boşluğu DEĞİL, benim lokal `motion-core` checkout'umun
bayatlığıydı

Orkestratör transkript-dilini benden istedi (marker tasarımı için); önce
çekirdeği okurken `motion-core/lib` (workspace, `.git` ayrı) `feat/lissom-
v3-onayi` dalında, `origin/main`in **9 commit gerisinde** olduğu ölçüldü —
tam `rom_mode.py` üzerinde. `origin/main`de ZATEN VAR: `FIRST_PERSON_DEMO_
MARKERS` (M-F-104) · `MOVEMENT_CUE_MARKERS` (M-F-137) · `POSTURE_CUE_
MARKERS` (M-F-143) · `FIRST_PERSON_PLURAL_CUE_MARKERS` (M-F-213) ·
`WEAK_ACTIVE_MARKERS` (M-F-208) — lokal kopyamda BUNLARIN HİÇBİRİ yoktu.

Aile-geneli `mdfind` taraması (orkestratör, H-55/H-57) **21 kopya** buldu,
2-8 sınıf arasında değişen sürümlerde. Kanonik kaynak: `~/motion-core-main`
(iCloud DIŞINDA taze klon, `main`/`63a0b3e`, 8 sınıf, `rig_staleness_
warning()` temiz).

**4 adayı bu taze rig'le YENİDEN sınıflandırdım** (`HarvestManifest.load/
record/save` ile — GERÇEK aracın kendi mekanizması, elle-yama DEĞİL,
M-F-138 disiplini):

| video | eski (bayat rig) | yeni (taze rig, `63a0b3e`) | isabetler |
|---|---|---|---|
| vyTaKpylOcU (Tony Jeffries) | unknown/False | **active/True** | i throw, i step, i am stepping, i punch |
| e5ciNJ0h-dw (MyBoxingCoach) | unknown/False | active/True | i drive, i rotate |
| gA8Se6i8mAI (Marvin Cook) | unknown/False | active/True | i step, throw your punch, we're going to throw |
| z-zev0ftmSQ (Yankello) | unknown/False | active/True | push your weight, we throw, your chin down |

**`vyTaKpylOcU` (Tony Jeffries) şimdi 4/4 kanıt barını BİRDEN geçiyor:**
netlik 313,2 (✓, zaten ölçülmüştü) · transkript-doğrulanmış coaching ✓
(yeni) · romMode=active+eligible=True ✓ (yeni, taze rig'den, `--manifests`
ile doğrulandı) · ≥1 gerçek cross penceresi ✓ (1, 72 kare, 1902ms —
zaten ölçülmüştü, sonuç DEĞİŞMEDİ, yalnız artık ATTESTED).

## §7 TURU-1 NİHAİ SONUÇ — 3/3 BAĞIMSIZ KİMLİK BULUNDU, TABAN KARŞILANDI

**Precision Striking** (4 pencere) · **FightCamp** (1 pencere) ·
**Tony Jeffries** (1 pencere, yeni). M-C-04 ≥3 tabanı KARŞILANDI. D17/Plan B
sorusu ARTIK GÜNDEM DIŞI — turu-2 gerekmedi.

⚠️ **Adıyla bırakılan, ÇÖZÜLMEMİŞ bir yan-bulgu** (jab'a uygulanan aynı
M-F-239 çoğunluk-clause ölçütüyle, kendi kendime tutarlı davranarak): bu 3
kimliğin pencere dağılımı (4/1/1=6 toplam) Precision Striking'e **%66,7**
veriyor — "çoğunluk" (%50+) düz okumasını aşıyor. Bu, F3 turu-1'in
"bulundu" barını (malzeme yeterliliği ≥1 pencere/kimlik) ETKİLEMEZ — ama
GERÇEK cross referansı kurulurken (bu turun kapsamı DIŞINDA, sonraki bir
adım) aynı yoğunlaşma sorusu sorulacaktır. Kendim işaretliyorum, kendim
karar vermiyorum — tıpkı jab'ın kendi durumunda olduğu gibi.
