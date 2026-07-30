# Yumruk-tipi imza ölçümü — hook vs jab (J-073 → **J-076/077 ile DÜZELTİLDİ**)

**Çerçeve (M-F-180):** `combinations` kilidi için gereken şey önce bir
sınıflandırıcı DEĞİL, bir ÖLÇÜM. **Eşik önerilmiyor.**

**Araçlar:** `tool/measure_punch_signature.dart` (imza) ·
`tool/measure_window_band.dart` (pencere bandı)
**Kural seti:** `boxing@1.0.0` — `jab` · `cross` · `unclassified_strike`.
**hook ve uppercut HİÇ modellenmiyor.**

> ## ⚠️ BU DOKÜMAN KENDİ İLK SÜRÜMÜNÜ DÜZELTİYOR
>
> İlk tur (J-073) iki iddia kurdu ve **ikisi de fazla iddiaydı**:
>
> | ilk iddia | düzeltme | neden düştü |
> |---|---|---|
> | "hook malzemesi jab/cross diye YANLIŞ sayılıyor" | **kanca FSM için GÖRÜNMEZ** — ne sayılıyor ne yanlış sayılıyor | 24,8 dk'lık kanca dersinde yalnız 6 tamamlanma + **0 yarıda-kesilme** |
> | "katalog nicelikleri hook↔jab ayırmıyor" | **ölçülemedi** — doğrulanmış tek bir kanca olayım yok | kıyasladığım "hook" olayları muhtemelen kanca değil |
>
> Ayakta kalan: **`unclassified_strike` hiç tetiklenmedi** (fallback ölü) ve
> **pencere bandı** (aşağıda, bağımsız olarak sağlam). Aile kuralı
> ("fallback'in tetiklendiği ölçülür") bu düzeltmeden ETKİLENMİYOR — hatta
> vaka daha öğretici hâle geldi: fallback iki AYRI sebeple ölü olabilir.

---

## 0. Kapsam sınırı

| tip | fixture | durum |
|---|---|---|
| jab | `umI6jNMVG-s` · `xOeEqDjkaVE` | ✅ 2 kaynak |
| **hook** | `pVvOF2kQuIQ` (precision_striking lead_hook) | 🟡 **1 kaynak, olay-etiketi YOK** |
| **uppercut** | — | 🔴 **HİÇ YOK** |

M-C-04 (≥3 bağımsız eğitmen) çok altında. Buradan hiçbir eşik çıkmaz.

---

## 1. FSM hook malzemesinde ne okuyor: **GÖRMÜYOR**

`pVvOF2kQuIQ` = 24,8 dakikalık lead-hook öğretim videosu (44.423 kare,
%40,6 hüküm verilebilir). Bir kanca dersi **onlarca kanca** içerir. Sonuç:

```
TAMAMLANMIŞ:      {jab: 3, cross: 3}   → 1488 saniyede 6 olay
YARIDA KESİLEN:   yok                  → 0 abort
unclassified_strike:                    → 6/6 kez tetiklenmedi
```

Üç sayı birlikte okunmalı:

* **6 tamamlanma / 24,8 dk.** Kancalar jab diye sayılıyor olsaydı sayı
  düzinelerce olurdu. Olmadı.
* **0 yarıda-kesilme.** Bu daha keskin: bir kanca `GUARD_READY → EXTENSION`
  geçişini tetikleyip sonra elenmiş DEĞİL — **hiç deneme başlatmıyor.**
* **Fallback hiç tetiklenmedi.** Yani `unclassified_strike` dekoratif; ama
  sebebi "girdi en yakın sınıfa tamamlanıyor" DEĞİL, "girdi hiç sınıflandırma
  yoluna girmiyor".

**Sonuç: kanca faz makinesi için görünmezdir.** Bu, kilidin en eski
gerekçesini ("sayılıyor ama sınıflandırılmıyor") ve benim ilk düzeltmemi
("jab diye yanlış sayılıyor") birlikte yanlışlar.

### O 6 olay neydi?

Doğrulanmadı — olay-başı ground truth yok. **Ama sıkı pencerede kinematikleri
düz yumruğa benziyor** (§2): `trunkLeanAngle` Δ 1,3° ve bilek yatay gezinmesi
0,77 omuz genişliği, iki jab kaynağının ikisinden de daha düşük. En muhtemel
açıklama: eğitmenin anlatırken arada attığı **gerçek düz yumruklar** — bir
koç referans olarak sürekli jab atar. Yani bunlar yanlış-pozitif bile
olmayabilir.

Bunu kesinleştirecek ölçüm: o altı zaman damgasına (t = 265,2 · 481,5 · 625,9
· 859,5 · 882,4 · 1113,7 s) videoda bakmak. **Kurucu-manuel kalemi** — 6
zaman damgası, her biri saniyeler.

## 2. İmza: **ölçülemedi**, çünkü doğrulanmış kanca olayı yok

Sıkı pencereyle (§3) yeniden ölçülen değerler:

| nicelik | hook malzemesi → "jab" (n=3) | jab · precision (n=3) | jab · tony (n=8) |
|---|---|---|---|
| `lead.elbowFlareAngle` | Δ 56,0° | Δ 60,3° | Δ 77,0° |
| `rear.elbowFlareAngle` | Δ 26,6° | Δ 21,1° | Δ 8,5° |
| `shoulderRotation` | Δ 8,0° | Δ 8,2° | Δ 3,8° |
| `trunkLeanAngle` | Δ 1,3° | Δ 7,8° | Δ 4,8° |
| `wrist.dxOverShoulder` | 0,77 | 1,35 | 1,56 |

İlk turda bu tabloyu *"katalog nicelikleri kanca ile jab'ı ayırmıyor"* diye
okumuştum. **O okuma geçersiz:** sol kolon kanca değil, "kanca videosunda
FSM'in jab dediği şey". §1'e göre o şeyler muhtemelen gerçek jab. Yani tablo
"kanca ayrışmıyor" demiyor, **"jab jab'a benziyor"** diyor — beklenen sonuç,
bilgi değil.

**Ayakta kalan tek gözlem** (ve o da yalnız jab içinde, iki DOĞRULANMIŞ jab
kaynağı arasında): `lead.elbowFlareAngle` Δ 60,3° ↔ 77,0°, `rear.elbowFlareAngle`
Δ 21,1° ↔ 8,5°. **Aynı teknikte eğitmen-arası yayılım büyük.** Bu, gelecekte
kurulacak herhangi bir sınıflandırıcı için gerçek bir uyarı — ama teknik-arası
mesafeyle kıyaslanamaz, çünkü teknik-arası mesafe hâlâ ölçülmemiş.

## 3. Pencere bandı — ölçülmüş dağılım (J-076)

Koordinatör hükmü: bant literatürden değil kendi fixture'larımızdan
türetilecek. Üç pencere tanımı aynı denemeler üzerinde ölçüldü (ms):

**jab · n=14 tamamlanmış deneme (3 fixture havuzu)**

| pencere | p10 | medyan | p90 | aralık |
|---|---|---|---|---|
| `GUARD_READY→GUARD_RECOVERED` (J-073'ün kullandığı) | 534 | 1468 | 2436 | **434 … 3937** |
| `EXTENSION→PEAK` (salt uzanma) | 33 | 167 | 300 | 33 … 334 |
| **`EXTENSION→GUARD_RECOVERED` (yumruğun kendisi)** | **234** | **334** | **467** | **167 … 501** |

**cross · n=4:** sıkı pencere p10 200 · medyan 300 · p90 534 · [200 … 534] —
jab bandıyla tutarlı.

Okumalar:

1. **J-074(a) hipotezim doğrulandı, ama yeni bir bulgu DEĞİLDİ.** "Gerçek jab
   ~0,3-0,5 s" tahminim ölçümle tuttu (medyan 334, p90 467 ms). Ancak gevşek
   pencerenin neden şiştiği `AttemptDigest.extensionMs`in **kendi doküman
   notunda (M-F-91) zaten yazılıydı**: ilk faz GUARD_READY ve faz makinesi
   orada dakikalarca bekleyebilir. Not, çözümü de veriyordu
   (`transitions['EXTENSION']`). Yani keşfetmedim, **dokümante edilmiş bir
   tuzağa düştüm** — J-073'ün aracı tam notun uyardığı `values.first/last`
   desenini kullanıyordu.
2. **`EXTENSION→PEAK` imza ölçümü için kullanılamaz.** 29,97 fps'te 33 ms =
   **tek kare**; alt sınır örnekleme tabanına dayanmış. Bu pencere 1-10 kare
   verir.
3. **Sıkı pencere ~7-15 kare veriyor** (234-467 ms), imza ölçümü için
   çalışılabilir taban. J-073 ise 14-119 kare üzerinden ölçmüştü — yani Δ
   değerlerinin bir kısmı gard beklemesinden geliyordu. `measure_punch_signature.dart`
   sıkı pencereye geçirildi.

## 4. Kendi kusurlarım (kayıt, tekrar edilmesin diye)

| # | kusur | ders |
|---|---|---|
| a | Pencere `values.first/last` ile alındı → M-F-91'in isimle uyardığı tuzak | **Alanın doküman notunu okumak, alanı kullanmadan ÖNCE gelir** |
| b | `wrist.pathOverNet` ill-conditioned: yumruk garda döner → uçtan-uca ≈ 0, oran patlıyor (gevşek pencerede 102,4'e kadar) | Döngüsel harekette "yol/net mesafe" oranı tanımsıza yakın |
| c | **Sınıf etiketi olmayan malzemeden sınıf-karşılaştırması kurdum** | "Kanca videosu" ≠ "kanca olayı". Ground truth olmadan hiçbir imza kıyaslaması geçerli değil |

(c) en pahalısı: koordinatör bir bulguyu kabul edip aile kuralına çevirdikten
sonra düzeltmek gerekti.

## 5. Sıra (öneri — karar koordinatörün)

1. ✅ **Kilit gerekçesi düzeltildi** — `technique-coverage` →
   `technique-misclassified` → **`technique-invisible`**. Disiplin dürüstlük
   bloğundaki "counted, but the type is not claimed" satırı da düzeltildi:
   sayılmıyor, GÖRÜLMÜYOR.
2. ✅ **Pencere bandı ölçüldü** ve imza aracı sıkı pencereye geçti.
3. 🔴 **Ground truth ŞART** — sıradaki hasat turunda kanca fixture'ları
   **olay zaman damgalarıyla** alınmalı; etiketsiz video imza ölçümüne
   yetmiyor (bu turun asıl dersi). Ucuz ara adım: mevcut 6 zaman damgasını
   kurucu gözüyle doğrulamak.
4. Ancak sonra sınıf tasarımı.
