# Yumruk-tipi imza ölçümü — hook vs jab (J-073)

**Çerçeve (M-F-180):** `combinations` dersinin kilidi için gereken şey önce bir
sınıflandırıcı DEĞİL, bir ÖLÇÜM. İki soru: (1) mevcut jab/cross FSM'i hook
malzemesinde ne okuyor, yanlış-pozitif sayım var mı? (2) ayırt edici kinematik
imza mevcut fixture'larda görünüyor mu? **Eşik önerilmiyor; sınıf tasarımı
ölçümden sonra.**

**Araç:** `packages/jablab_engine/tool/measure_punch_signature.dart`
**Kural seti:** `boxing@1.0.0` — modellenen teknikler: `jab` · `cross` ·
`unclassified_strike`. **hook ve uppercut HİÇ modellenmiyor.**

---

## 0. Kapsam sınırı — ÖNCE bu okunmalı

Talebin cümlesi *"iki yumruk tipinin ayırt edici imzası"* idi. Bugün o
kıyaslama **yapılamadı**, çünkü:

| tip | indirilmiş fixture | durum |
|---|---|---|
| jab | `umI6jNMVG-s` (precision_striking) · `xOeEqDjkaVE` (tony_jeffries) | ✅ 2 kaynak |
| **hook** | `pVvOF2kQuIQ` (precision_striking lead_hook) | 🟡 **TEK kaynak** |
| **uppercut** | — | 🔴 **HİÇ YOK** (`KcagWYVfvBg` yalnız doğrulanmamış aday) |

Yani bugünkü ölçüm **hook↔jab** kıyaslamasıdır. **hook↔uppercut ölçülmedi ve
ölçülemez.** Tek hook kaynağı ayrıca M-C-04'ün (≥3 bağımsız eğitmen) çok
altında — buradan çıkan hiçbir sayı bir eşiğe dönüşemez, ve bu doküman
dönüştürmüyor.

---

## 1. YANLIŞ-POZİTİF SAYIM: var, ve kilit gerekçesinden DAHA KÖTÜ

`pVvOF2kQuIQ` **bir lead-hook öğretim videosu** (24,8 dk, %99,5 tespit). FSM
üzerinde koşturulduğunda:

```
kare: 44423 · hüküm verilebilir: 18054 (%40,6)
TAMAMLANMIŞ: {jab: 3, cross: 3}
YARIDA KESİLEN: yok
```

**`unclassified_strike` HİÇ tetiklenmedi — 6 tamamlanmanın 0'ı.**

Bu, `combinations` dersinin kilit gerekçesini isimli olarak yanlışlıyor.
Gerekçe *"hook ve uppercut sayılıyor ama sınıflandırılmıyor"* diyor; ölçüm
gösteriyor ki sayılmıyor + sınıflandırılmıyor DEĞİL, **aktif olarak jab ve
cross diye YANLIŞ sınıflandırılıyor.** İkisi aynı şey değil:

* "sayıldı ama sınıflandırılmadı" → kullanıcı eksik geri bildirim alır;
* "jab diye sayıldı" → kullanıcı **yanlış** geri bildirim alır ve rakam
  ekranda doğru görünür.

İkincisi bir dürüstlük kusuru, kapsam eksiği değil. Kilit gerekçesi bu
cümleyle güncellenmeli.

## 2. AYIRT EDİCİ İMZA: ölçülen hiçbir nicelik ayırmıyor

Her tamamlanmış denemenin faz-geçiş penceresi boyunca ölçülerin açıklığı (Δ),
teknik başına medyan:

| nicelik | HOOK malzemesi → "jab" | JAB malzemesi (aynı eğitmen) | JAB (tony_jeffries) |
|---|---|---|---|
| `lead.elbowFlareAngle` | Δ 57,9° | Δ 61,5° | Δ 97,0° |
| `rear.elbowFlareAngle` | Δ 40,7° | Δ 33,0° | Δ 37,9° |
| **`shoulderRotation`** | **Δ 10,0°** | **Δ 10,6°** | Δ 16,1° |
| `lead.extensionRatio` | Δ 0,7 | Δ 0,5 | Δ 0,8 |
| `trunkLeanAngle` | Δ 5,1° | Δ 9,0° | Δ 9,4° |
| `lead.guardHeightDelta` | Δ 0,3 | Δ 0,2 | Δ 0,6 |

Talep gövde rotasyonunu ve dirsek yörüngesini isimle sordu; ikisi de ayırmıyor:

* **`shoulderRotation` 10,0° vs 10,6°** — hook için en sezgisel ayırt edici
  nicelik, ve fark ölçüm gürültüsünün altında.
* `trunkLeanAngle` hook malzemesinde **daha DÜŞÜK** (5,1° vs 9,0°) — sezgiye
  ters yön.
* `lead.elbowFlareAngle` iki jab kaynağı arasında 61,5° ↔ 97,0° ile ayrışıyor;
  yani **eğitmen-arası fark, teknik-arası farktan büyük.** Bu tek başına
  "katalog nicelikleriyle sınıflandırıcı" fikrini bitirir: sınıf sınırı
  koyacak yer yok, çünkü sınıf-içi yayılım sınıflar-arası mesafeyi yutuyor.

### Katalog dışına çıkma denemesi de ayırmadı

Katalogda olmayan, landmark'tan türetilmiş üç betimleyici hesaplandı (kataloğa
EKLENMEDİ — yalnız "ayırt edici bir şey var mı" sorusu için). Bilek gezinme
kutusu, omuz genişliğine bölünmüş:

| betimleyici | HOOK→"jab" | JAB (aynı eğitmen) | JAB (tony) |
|---|---|---|---|
| `wrist.dxOverShoulder` (yatay) | 1,38 | 1,89 | 2,51 |
| `wrist.dyOverShoulder` (dikey) | 0,68 | 0,46 | 1,20 |

Hipotez şuydu: düz yumruk kameraya doğru gider (küçük yatay gezinme), kanca
YANDAN gelir (büyük yatay). Ölçüm **tersini** gösteriyor — yatay gezinme hook
malzemesinde en KÜÇÜK. Hipotez ölü.

## 3. Yol boyunca çıkan iki kendi-kusurum

**(a) `wrist.pathOverNet` kötü seçilmiş bir betimleyici.** Yol
uzunluğu / uçtan-uca mesafe olarak tanımlandı; ama yumruk gard pozisyonuna
GERİ DÖNER, yani uçtan-uca mesafe ≈ 0 ve oran patlar (ölçülen değerler 2,7 ile
**102,4** arası). Bu bir bulgu değil, ill-conditioned bir orandır. Sonuç
tablosuna alınmadı; burada kayda geçiyor ki tekrar denenmesin.

**(b) Pencereler tek bir yumruk DEĞİL.** 29,97 fps'te ölçülen pencere
süreleri **0,47 s ile 3,97 s** arasında. Gerçek bir jab uzanma+geri çekilme
~0,3-0,5 s. Yani en kısa pencereler yumruk-boyunda, uzunlar (2-4 s) tek bir
yumruk olamaz. Bu, yukarıdaki Δ sayılarının bir kısmının yumruğu değil
**yumruk + çevresindeki gezinmeyi** ölçtüğü anlamına gelir. Bir sonraki
ölçümün ilk işi bu: pencere tanımı sıkılaşmadan imza ölçümü tekrarlanmamalı.

---

## 4. Ne öğrenildi, ne öğrenilmedi

**Öğrenildi:**
1. Hook malzemesi sessizce jab+cross olarak sayılıyor; fallback sınıfı hiç
   devreye girmiyor. `combinations` kilidi bu cümleyle düzeltilmeli.
2. Mevcut ölçü kataloğu (dirsek açılması, omuz rotasyonu, gövde eğimi, uzanma,
   gard) **hook ile jab'ı ayırmıyor**. Eğitmen-arası yayılım teknik-arası
   farktan büyük.
3. İlk akla gelen katalog-dışı aday (bilek yatay gezinmesi) de ayırmıyor —
   ölçülen yön hipotezin tersi.

**Öğrenilmedi (ve bugün öğrenilemez):**
* uppercut hakkında **hiçbir şey** — fixture yok.
* Hook'un gerçek imzası olup olmadığı: tek kaynak + gevşek pencere ile
  "imza yok" denemez, yalnız **"bu ölçüm setinde görünmüyor"** denir.

## 5. Öneri (karar koordinatörün)

Sınıf tasarımına geçmek için ölçüm YETERLİ DEĞİL. Sıra şu görünüyor:

1. **Kilit gerekçesini düzelt** — "sayılıyor ama sınıflandırılmıyor" →
   "jab/cross olarak yanlış sayılıyor". Bu kod işi değil, dürüstlük işi ve
   bugün yapılabilir.
2. **Pencere tanımını sıkılaştır** (madde 3b) — imza ölçümünün ön koşulu.
3. **Fixture tabanı** — hook için ≥3 eğitmen, uppercut için ≥1 kaynak. Bunlar
   olmadan 2. ve 3. maddeler tekrar edilse bile eşiğe dönüşemez.

Bu sıra tersine çevrilirse (önce sınıflandırıcı) elde edilecek şey, bugün
ölçtüğüm yanlış-pozitif sayımın üzerine kurulmuş bir eşik olur.
