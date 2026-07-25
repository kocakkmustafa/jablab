# D2 — Hız-Örnekleme Fizibilite Kapısı: ÖLÇÜM PROTOKOLÜ

**Tarih:** 2026-07-26 · **Statü:** Eşikler ölçümden ÖNCE yazıldı (gece modu kuralı, `20-URETIM-SURECI §2.6`)
**Kapı sahibi:** ana oturum + `motion-cv-engineer` · **Kaynak:** `00-AILE-MIMARISI §3/D2` · **DEFTER:** J-001 (P0), M-002
**Bu dosya ölçüm SONRASI DEĞİŞTİRİLMEZ.** Sonuçlar `D2-KAPI-RAPORU.md`'ye yazılır; eşik revizyonu gerekirse gerekçesiyle DEFTER'e ayrı kayıt açılır.

---

## 0. Kapı ne soruyor?

D2 bir "yapılır mı?" kapısı **değil**, bir **"hangi metrik güvenilir?"** kapısıdır. Üç ayrı soruyu ayırıyoruz — birbirine karıştırılırsa yanlış hüküm çıkar:

| # | Soru | Bu oturumda ölçülebilir mi? |
|---|---|---|
| **D2-A** | Gerçek tam-hız yumrukta, tipik telefon kare hızlarında faz sınırları **görülebiliyor mu**? Blur landmark güvenini ne kadar düşürüyor? | ✅ Evet — gerçek görüntü + MediaPipe hattı |
| **D2-B** | Faz-süresi tabanlı hız metriği, kare-arası piksel hızından **gerçekten daha kararlı mı**? (D2 hipotezinin çürütülebilir sınaması) | ✅ Evet — aynı yumruk, çoklu fps desimasyonu |
| **D2-C** | Hedef cihazlarda MediaPipe full ile **sürdürülebilir fps + termal davranış** nedir? | ❌ Hayır — fiziksel cihaz + kamera + kilidi açık telefon gerekir → **kurucu-kapılı manuel iş** |

**Şartlı geçiş yalnız D2-A + D2-B için ilan edilebilir.** D2-C ölçülmeden "60fps politikası" gibi taahhütler ürün kararına dönüştürülmez; yalnız *koşullu tasarım dalı* olarak yazılır.

---

## 1. Hipotezler (çürütülebilir)

- **H1 (örnekleme):** Tam hız jab/cross'un uzanma (EXTENSION) fazı 30fps'te faz sınırı çıkarımı için yeterli kare barındırmaz; 60fps'te barındırır.
- **H2 (bölgesel blur):** Motion blur **yalnız yumruk atan uzvu** (bilek/dirsek) vurur; arka el, omuz, kalça ve ayak landmark güveni tam-hız yumrukta bile kullanılabilir kalır.
  → Doğrulanırsa, JabLab'ın "5 çok-güvenilir hata"sının en az 4'ü (REAR_HAND_LOW, ELBOW_FLARED, STANCE_TOO_NARROW/WIDE, FEET_CROSSED) hız probleminden **bağımsız** olarak güvenlidir. Bu, kapının ürün açısından en kritik çıktısıdır.
- **H3 (metrik kararlılığı):** Faz-süresinden türetilen hız/tempo metriği, fps değiştikçe kare-arası piksel hızından belirgin biçimde daha az sapar.
- **H4 (kopma):** Tam hızda MediaPipe bilek landmark'ında fiziksel-olmayan sıçrama/kayıp üretir; bu oran ölçülebilir ve güven kapısıyla filtrelenebilir.

**H3 çürürse D2 tasarım kararı çürür** — o durumda faz-süresi dayatması kaldırılır, alternatif (ör. kısıtlı-hız drill modu, yalnız form-hükmü) kurucuya sunulur.

---

## 2. Operasyonel tanımlar (ölçüm kodunun uyacağı sözleşme)

Tüm mesafeler **normalize**: birim = `shoulder_width` (sol-sağ omuz landmark mesafesi, hareket boyunca medyanı alınır — kamera mesafesi ve vücut ölçüsü etkisini siler).

- **Guard referansı `G`:** yumruk atan bilek landmark'ının, hareket öncesi ≥5 karelik durağan penceredeki medyan konumu.
- **Uzanma ölçüsü `r(t)`:** yumruk atan bilek ↔ aynı taraf omuz mesafesi (normalize).
- **EXTENSION başlangıcı `t0`:** `r(t)` guard taban değerinin üzerine çıkıp **+0.15** eşiğini aştığı ilk kare.
- **PEAK `tp`:** `r(t)`'nin yerel maksimumu (yumruk penceresi içinde).
- **RETRACTION bitişi `t1`:** `r(t)`'nin peak sonrası taban+0.15 altına ilk düştüğü kare.
- **`n_ext@fps`:** `[t0, tp]` aralığına düşen kare sayısı (dahil).
- **`t_ext_ms`:** `(tp − t0)` süresi, milisaniye (native fps'ten hesaplanır — fps'ten bağımsız gerçek süre).
- **Vücut bölgeleri (visibility ayrıştırması):**
  - `fast` = yumruk atan bilek + dirsek
  - `slow_guard` = arka el bilek + dirsek
  - `slow_trunk` = iki omuz + iki kalça
  - `slow_base` = iki ayak bileği + topuk/parmak
- **`vis_min(bölge)`:** `[t0, t1]` penceresinde bölgedeki landmark'ların visibility minimumu (bölge içi en kötü landmark, zaman içi minimum).
- **`jump_rate`:** ardışık karede bilek yer değiştirmesi > `0.9 × shoulder_width` olan kare oranı (tam-hız jabda bile fiziksel olarak aşırı → model kopması göstergesi).
- **`v_pixel`:** kare-arası normalize bilek yer değiştirmesinin tepe değeri ÷ kare süresi (klasik "piksel hızı" yaklaşımı — çürütme kolu).
- **`CV`:** aynı yumruğun {native, 60, 30} fps desimasyonlarında hesaplanan metriğin varyasyon katsayısı (std/ortalama).

**Desimasyon kuralı:** Yüksek fps kaynak videodan kare **atlanarak** 60/30fps üretilir (yeniden kodlama YOK — enterpolasyon metriği yapay olarak düzeltir). Blur, kaynak videonun poz süresinden gelir; desimasyon blur'u değiştirmez, yalnız **örnekleme**yi değiştirir. Bu ayrım rapora yazılır: *desimasyon örnekleme sorusunu (H1/H3) sınar, blur sorusunu (H2/H4) kaynak videonun kendi shutter'ı belirler.*

---

## 3. Eşikler (ölçümden ÖNCE sabitlendi)

### ✅ GEÇTİ
1. `n_ext@60` medyanı **≥ 4** VE `n_ext@30` medyanı **≥ 2**
2. `vis_min(slow_guard)`, `vis_min(slow_trunk)`, `vis_min(slow_base)` **≥ 0.5**, yumrukların **≥ %90**'ında
3. `CV_phase ≤ %15` **VE** `CV_pixel ≥ 2 × CV_phase` (H3 kanıtlı)
4. `jump_rate ≤ %5`

### 🟡 SINIRDA (koşullu tasarım dalı; üretim koduna girmeden önce kurucu onayı)
- `n_ext@30 < 2` ama `n_ext@60 ≥ 4` → **fps sınıfı politikası**: 60fps yakalayabilen cihazlarda hız/tempo metriği açık; 30fps cihazlarda metrik **gizlenir** (form hükmü çalışır). D2-C ölçülmeden bu dal ürüne girmez.
- `vis_min(fast) < 0.4` ama tüm yavaş bölgeler ≥ 0.5 → **hız + uzanma-kalitesi metrikleri beta bayrağı**; form hataları (guard/dirsek/duruş/ayak) tam güvende yayınlanır.
- `CV_phase` %15–25 arası → metrik gösterilir ama **sayı olarak değil bant olarak** (ör. "tempo: hızlı/orta/yavaş"), plan §14 "speed estimate" dilinden bir adım daha muhafazakâr.

### ❌ KALDI (üretim koduna girilmez, kurucuya alternatif sunulur)
- `n_ext@60` medyanı **< 2** → faz sınırı çıkarılamaz; yumruk analizi tam hızda mümkün değil.
- Herhangi bir **yavaş** bölgede `vis_min < 0.5` → tam-hız yumrukta form hükmü bile verilemez (ürün vaadinin çekirdeği düşer).
- `CV_phase > CV_pixel` → **H3 çürüdü**, D2'nin dayattığı tasarım yanlış; 00-AILE-MIMARISI D2 maddesi kurucu onayıyla revize edilir.

---

## 4. Ölçüm hattı (kanıt üretimi)

`ventures/motion-core/lib/tools/` altında, **aile-geneli** (Gravita D1 aynı hattı kullanacak):

1. `extract_landmarks.py` — video → MediaPipe Pose Landmarker (Tasks API, `full` ve `heavy` varyantı) → katalog §6 fixture JSON şeması.
2. `decimate.py` — kare atlayarak fps desimasyonu (yeniden kodlama yok).
3. `analyze_d2.py` — §2 tanımlarını uygular, §3 eşiklerine karşı hüküm verir, tablo + CSV üretir.
4. Çıktı: `D2-KAPI-RAPORU.md` + ham CSV + yumruk-başına grafik/özet.

**Model sürümü pinlenir** (`ModelVersion` her fixture kaydında saklanır — katalog §1 uyarısı).

## 5. Görüntü kaynağı ve lisans disiplini

- Her klip için **kaynak URL + lisans + fps + çözünürlük** rapora yazılır.
- Bu oturumun klipleri **YALNIZ ölçüm içindir**: ship edilen fixture setine girmez, model eğitiminde kullanılmaz (katalog §0/§6 kuralı).
- Ship edilecek fixture'lar **kendi kayıtlarımızdan** üretilir (birincil hat) — kurucu çekim protokolü: `docs/gates/D2-CEKIM-PROTOKOLU.md`.

## 6. Kapı çıktısı (roadmap G1 sözleşmesi)

1. Blur/fps profili raporu (bölgesel visibility tabloları)
2. Hız-metriği tasarım kararı (H3 sonucuyla gerekçeli)
3. **V1 hareket setinin güvenilirlik sıralaması** — hangi teknik/hata sınıfı hangi güven bandında yayınlanabilir
4. fps politikası **önerisi** (D2-C ölçülene dek koşullu)
5. Kurucu-kapılı manuel iş listesi (çekim + cihaz ölçümü)
