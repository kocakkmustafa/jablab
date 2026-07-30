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
> | "hook malzemesi jab/cross diye YANLIŞ sayılıyor" | 6 tamamlanma + **0 abort** → çoğu kanca hiç deneme başlatmıyor | yoğunluk + abort sayacı atlanmıştı |
> | "kanca GÖRÜNMEZ, o 6 olay demo jab'di" (J-077) | **bu da düştü (J-081):** transkriptte hook 61 / jab 1 → demo-jab açıklaması ayakta duramaz. **Artık mekanizma iddia edilmiyor** | damgalı altyazı |
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

## 1. FSM hook malzemesinde ne okuyor: **neredeyse hiçbir şey — ve okuduğu azı yanlış etiketliyor**

`pVvOF2kQuIQ` = 24,8 dakikalık lead-hook öğretim videosu (44.423 kare,
%40,6 hüküm verilebilir). Bir kanca dersi **onlarca kanca** içerir. Sonuç:

```
TAMAMLANMIŞ:      {jab: 3, cross: 3}   → 1488 saniyede 6 olay
YARIDA KESİLEN:   yok                  → 0 abort
unclassified_strike:                    → 6/6 kez tetiklenmedi
```

Üç sayı birlikte okunmalı:

* **6 tamamlanma / 24,8 dk.** Düzinelerce kancanın atıldığı bir derste bu,
  kancaların **büyük çoğunluğunun hiç deneme başlatmadığı** anlamına gelir.
* **0 yarıda-kesilme.** Bir kanca `GUARD_READY → EXTENSION` geçişini
  tetikleyip sonra elenmiş DEĞİL — o geçiş hiç olmuyor.
* **Fallback hiç tetiklenmedi**, ama tetiklenen 6 olay da boşluğa gitmedi:
  **jab/cross etiketi aldılar.**

**Ölçülen bu; MEKANİZMA İDDİA EDİLMİYOR** (aşağıda: üç kez iddia ettim, üçü
de düştü). Kullanıcı açısından iki kusur aynı kapıya çıkıyor: kancaların
çoğu sayılmaz, sayılan azı yanlış sayılır.

⚠️ Üçüncü bir olasılık da elenmedi: %40,6 hüküm-verilebilirlik, bu kaynakta
kancaların bir kısmının **görünürlük kapısında** düşmüş olabileceği anlamına
geliyor — yani "teknik tanınmıyor" ile "kare yargılanamıyor" bu ölçümde
ayrışmıyor.

### O 6 olay neydi? — açıklamam TRANSKRİPTLE düştü (J-081)

J-077'de *"muhtemelen eğitmenin anlatırken attığı gerçek düz yumruklar"*
demiştim. Kaynağın damgalı altyazısı çekildi (613 olay, 1491 s) ve bu
açıklama ayakta duramıyor:

| kelime | anma |
|---|---|
| **hook** | **61** |
| **jab** | **1** |
| cross / straight | 4 |
| uppercut | 2 |
| shadow 0 · bag/mitt | 2 |

25 dakikada **tek bir jab anması** olan bir videoda "o 6 olay demo jab'di"
denemez. Kaynak baştan sona kanca.

Ayrıca bir gözlemi **kullanmadan attım**: "6 olayın 3'ü hook konuşmasına
yakın" doğru ama **taban orana normalize edilince bilgi taşımıyor** —
±12 s pencerelerin birleşimi videonun **%57'sini** kaplıyor, 3/6 = %50,
yani tesadüften ayrılamaz. (Aynı normalizasyon hatası J-073'ün manşetini
düşürmüştü; bu kez ölçtüm.)

**Geriye kalan okuma — ve MEKANİZMA İDDİA ETMİYORUM.** Üç kez mekanizma
iddia ettim, üçü de ölçümle düştü. Ölçülen şu: düzinelerce kancanın olduğu
24,8 dakikada FSM **6 tamamlanma + 0 abort** üretti ve fallback'i hiç
kullanmadı. Yani kancaların **büyük çoğunluğu hiç deneme başlatmıyor**;
tetiklenen az sayıdaki olay da **jab/cross etiketi alıyor**. Kullanıcı
açısından ikisi aynı kapıya çıkıyor: yanlış sayı.

**Hâlâ eksik:** o 6 anda gerçekten bir yumruk atıldığının doğrulanması.
Transkript **KONU** veriyor, **HAREKET OLAYI** vermiyor — eğitmen
konuşurken çoğu zaman duruyor. Kurucu göz-doğrulaması kuyrukta
(t = 265,2 · 481,5 · 625,9 · 859,5 · 882,4 · 1113,7 s).

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
okumuştum. **O okuma geçersiz — ama J-077'de yazdığım gerekçeyle DEĞİL.**
J-077 "sol kolon muhtemelen gerçek jab" diyordu; transkript bunu düşürdü
(hook 61 / jab 1). Geçersizliğin gerçek sebebi daha basit ve daha sağlam:
**sol kolonun ne olduğunu BİLMİYORUM.** Doğrulanmış bir kanca olayı
olmadan, o üç olayın kanca mı, kısmi bir gösterim mi, yoksa başka bir
hareket mi olduğu açık değil. Etiketsiz bir kolonla yapılan karşılaştırma
"ayrım yok" sonucunu veremez; **"ölçüm yapılmadı"** sonucunu verir.

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
