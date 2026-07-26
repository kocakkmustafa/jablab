# D2-D — Kurucu Çekim Protokolü (JabLab)

**Amaç:** D2 kapısının açık kalan tek bilimsel sorusunu kapatmak: **görünürlük düşüşü blur'dan mı, kapanmadan mı?**
**Süre:** ~35 dk · **Gereken:** iPhone + sabit yer (tripod/kitap yığını) + ~2,5 m boş alan
**Neden sen çekmelisin:** Stok görüntülerin hiçbiri JabLab'ın kurulumu değil (hepsi sinematik yan açı, yarım vücut, 25fps). Ayrıca ship edilecek fixture'lar **lisans olarak temiz kendi kayıtlarımız** olmalı (`10-ARAC-KATALOGU §0/§6`).

---

## 0. Kurulum (bir kez yap, çekim boyunca DEĞİŞTİRME)

Deneyin tüm gücü **kurulumun sabit kalmasından** gelir. Tek değişen şey tempo olacak; kadraj, ışık, mesafe, açı, kıyafet sabit kalırsa görünürlük farkının tek açıklaması hız olur.

1. **Telefon dikey (portre)**, sabit bir yere yaslı, **kalça hizasında** (~1 m yükseklik).
2. **Mesafe:** tam vücut karede + üstte/altta bir avuç boşluk (~2,5 m).
3. **Açı: ön-eğik ~35°** — tam karşıdan değil, tam yandan değil. (Rapordaki en önemli bulgu: saf yan açı iki eli birden göremiyor.) Omuz çizgin kameraya çapraz baksın.
4. **Işık:** normal oda ışığı, arkanda pencere/lamba OLMASIN (arkadan ışık siluet yapıyor).
5. **Kıyafet:** vücuda oturan tişört + şort/tayt. (Bol kıyafet ayrı bir çekimde test edilecek.)
6. Her çekimin başında **2 saniye hareketsiz gard** duruşunda bekle — analiz "gard tabanını" oradan alıyor, bu şart.

## 1. ÇEKİRDEK DENEY — tempo merdiveni (bunu atlama)

**Aynı kurulum, aynı yumruk, üç tempo.** D2'nin açık sorusunu kapatan tek şey bu.

| # | Dosya adı | fps | İçerik | Süre |
|---|---|---|---|---|
| 1 | `01_jab_yavas_60.mov` | **60** | 10× jab — *kasten yavaş*, teknik gösterir gibi | ~20 sn |
| 2 | `02_jab_orta_60.mov` | **60** | 10× jab — antrenman temposu | ~15 sn |
| 3 | `03_jab_tamhiz_60.mov` | **60** | 10× jab — **elinden geldiğince hızlı** | ~12 sn |
| 4 | `04_cross_yavas_60.mov` | 60 | 10× cross — yavaş | ~20 sn |
| 5 | `05_cross_tamhiz_60.mov` | 60 | 10× cross — tam hız | ~12 sn |

> Her yumruk arasında **gard'a tam dön ve bir an bekle**. Seri hâlde peş peşe atma — sistem yumruğun bittiğini gard dönüşünden anlıyor.

## 2. YER GERÇEĞİ — ağır çekim referansı

| # | Dosya adı | fps | İçerik |
|---|---|---|---|
| 6 | `06_jab_tamhiz_240.mov` | **240 (Slo-mo)** | 10× tam hız jab |
| 7 | `07_cross_tamhiz_240.mov` | **240 (Slo-mo)** | 10× tam hız cross |

240fps kaydı, 30/60fps'te *neyin kaybolduğunu* birebir gösteren referans olacak (kareyi atlayarak 60 ve 30'a indireceğiz — aynı yumruk, üç örnekleme).
*iPhone'da: Kamera → SLO-MO sekmesi → sağ üstten `1080p 240`.*

## 3. KARE HIZI KARŞILAŞTIRMASI

| # | Dosya adı | fps | İçerik |
|---|---|---|---|
| 8 | `08_jab_tamhiz_30.mov` | **30** | 10× tam hız jab (aynı kurulum) |

*iPhone'da: Ayarlar → Kamera → Video Kaydet → `1080p HD 30 fps`. Çekim sonrası 60'a geri al.*

## 4. GERÇEK DÜNYA STRES TESTLERİ (her biri 60fps, ~15 sn)

| # | Dosya adı | Değişen tek şey |
|---|---|---|
| 9 | `09_kombinasyon_12_60.mov` | 8× "1-2" kombinasyonu, antrenman temposu |
| 10 | `10_bol_kiyafet_60.mov` | **Bol hoodie/eşofman** giy, 10× tam hız jab |
| 11 | `11_los_isik_60.mov` | **Işıkları kıs** (tek lamba), 10× tam hız jab |
| 12 | `12_kucuk_oda_60.mov` | Telefonu **1,5 m'ye** yaklaştır (ayaklar kadrajın kenarında), 10× jab |
| 13 | `13_saf_yan_60.mov` | Açıyı **90° tam yan** yap, 10× jab — *ön-eğik açının gerçekten gerekli olduğunu kanıtlamak için kontrol çekimi* |
| 14 | `14_southpaw_60.mov` | **Ters gard** (southpaw) dur, 10× jab — sağ/sol dönüşüm testi |

## 5. HATA KÜTÜPHANESİ — ⚠️ ARTIK OPSİYONEL (2026-07-26 güncellemesi)

> **Bu bölüm M-C-01/M-C-03 kararlarıyla zorunluluktan çıktı.** Aile kararı: doğru icra referansı kamuya açık eğitmen videolarından çıkarılır; **hatalı örnekler referansın kontrollü bozulmasından sentezlenir** (etiket bedava, çeşitlilik sınırsız). Yani aşağıdaki 8 çekim olmadan da G3 fixture kütüphanesi kurulabilir.
>
> **Yine de çekmeye değer olan 3 tanesi var** — çünkü sentetik bozulma *senin vücudunda gerçek hatanın nasıl göründüğünü* göstermez: **#15 (arka el düşük)**, **#17 (dirsek açık)**, **#21 (overreach)**. Bu üçü `ELBOW_FLARED`/`OVERREACH` eşik kalibrasyonunun (J-007) doğrulama seti olur. Diğer 5'i atlayabilirsin.
>
> ⚠️ Çekersen: **fixture, sınadığı toleranstan BÜYÜK olmalı** (M-C-06). Hatayı *abartılı* yap — 45° eşiği için 45°'lik dirsek açısı testi hiçbir şey sınamaz.

Her biri 60fps, ~12 sn, **kasten abartılı** hata:

| # | Dosya adı | Kasten yapılacak hata |
|---|---|---|
| 15 | `15_hata_rear_hand_low_60.mov` | Jab atarken **arka eli çeneden indir** |
| 16 | `16_hata_lead_not_recovered_60.mov` | Jab sonrası **eli aşağıdan geri getir**, gard'a geç dön |
| 17 | `17_hata_elbow_flared_60.mov` | Cross atarken **dirseği dışa aç** |
| 18 | `18_hata_stance_narrow_60.mov` | **Ayaklar bitişik** dur, 10× jab |
| 19 | `19_hata_stance_wide_60.mov` | **Ayaklar çok açık** dur, 10× jab |
| 20 | `20_hata_feet_crossed_60.mov` | Adım atarken **ayakları çaprazla** |
| 21 | `21_hata_overreach_60.mov` | Jab'ı **gövdeni öne devirerek** uzat |
| 22 | `22_hata_balance_loss_60.mov` | Yumruk sonrası **dengeni kasten kaybet** |

## 6. VÜCUT ÇEŞİTLİLİĞİ (varsa)

Bir kişi daha bulabilirsen (farklı boy/kilo): `23_kisi2_jab_tamhiz_60.mov` + `24_kisi2_hata_rear_hand_low_60.mov`. Zorunlu değil, ama eşiklerin tek vücuda aşırı-uymasını (overfit) engeller.

---

## Güncellenmiş süre

| Bölüm | Durum | Süre |
|---|---|---|
| §1 tempo merdiveni (1-5) | 🔴 **ZORUNLU** — D2'nin açık sorusunu tek başına kapatır | ~8 dk |
| §2 ağır çekim (6-7) | 🟠 çok değerli | ~5 dk |
| §3 30fps karşılaştırma (8) | 🟠 değerli | ~3 dk |
| §4 stres testleri (9-14) | 🟡 ürün sınırlarını belirler | ~10 dk |
| §5 hata kütüphanesi | 🟢 **opsiyonel** — 8 yerine 3 çekim yeter (#15/#17/#21) | ~5 dk |
| §6 ikinci kişi | 🟢 opsiyonel | ~5 dk |

**Toplam: ~36 dk → ~26 dk** (M-C-01/03 kararı 8 çekimi 3'e indirdi).

## Teslim

Dosyaları **isimleri bozmadan** şuraya at:
`~/Documents/YULAlab-AI/scratch/jablab-cekimler/`

Sonra tek satır yeter: **"JabLab çekimleri hazır."** Gerisi (landmark çıkarımı, tempo↔bozulma testi, eşik kalibrasyonu, fixture üretimi, replay testleri) otomatik.

## Neden bu sırayla?

- **1-3 (tempo merdiveni)** tek başına D2-D'yi kapatır. Zamanın azsa **sadece bunları çek.**
- **6-7 (240fps)** olmadan "30fps'te ne kaybediyoruz" sorusu tahmin olarak kalır.
- **15-22 (hata kütüphanesi)** G3'ün fixture setinin çekirdeği — motor kodu bunlar olmadan test edilemez (`replay-fixture'sız teknik eklenmez` kuralı).
- **13 (saf yan kontrol)** raporun kamera-açısı önerisini ya doğrular ya çürütür; ürünün kurulum sihirbazı buna dayanacak.
