# 🎯 MODEL KAPISI VERİ TOPLAMA / ETİKETLEME / RIZA PLANI (TASLAK) — 2026-08-19

> PREP lane çıktısı — **TASLAK/ÖNERİ**, uygulama değil. Gerçek insan denek +
> fiziksel çekim + rıza içerdiği için 00-HOLDING-BEYNI §3.4 ve §19 gereği
> nihai onay **kurucu kapısı** (R3/MANUAL_GATE). Bu belge, o pakete
> dönüştürülebilecek bir ön-analiz; hiçbir adım tek taraflı başlatılmadı.

## 0. Boşluğun büyüklüğü

Roadmap §10 Model kapısı: **en az 20 kişi ve 3.000 etiketli punch holdout.**
Elde (D2 ölçümü, 2026-07-26): **128 tespit edilmiş yumruk, 6 klip, 1 kişi
havuzu** (Wikimedia/Pexels lisanslı 3. parti klipler) — ve bu 128'in kendisi
zaten JAB-P0-003 tarafından *"acceptance cohort'una dahil etme"* diye
işaretli (yalnız hız-metodolojisi doğrulaması içindi, model eğitimi/kabulü
için değil). **Fiili boşluk 3.000/3.000 ve 20/20 kişi — sıfırdan başlıyoruz.**

## 1. Neden 3. parti video (HASAT-TURU yolu) BU kapıyı KAPATAMAZ

`HASAT-TURU-CROSS-KRITERLER.md`/`TUR1.md` metodolojisi (bağımsız eğitmen
bulma, netlik≥40, transkript-doğrulama) **REFERANS türetmek** içindir —
"doğru cross nasıl görünür" sorusuna tek bir kalibrasyon kaynağı üretir, ve
motion-core aile sözleşmesi bunu **"video yeniden dağıtılmaz, kaynak
kaydedilir"** sınırıyla açıkça ölçüm/referans amacına hapsediyor. 3.000
etiketli holdout ise farklı bir şey ister: **20 FARKLI KİŞİNİN** kendi
bedenleriyle attığı, **çeşitlilik dağılımı kontrol edilebilir**, **açık
rızalı** ve **modelin DOĞRUDAN değerlendirilmesinde kullanılacak** bir
kohort. YouTube 3. parti içeriğinde bu rıza YOK — D2'nin kendi 6 klibi bile
"model eğitilmez" kısıtı taşıyordu. Bu yüzden holdout'un ağırlıklı
çoğunluğu **kendi düzenlediğimiz, rızalı çekim turlarından** gelmeli.

## 2. Kim çeker — katılımcı havuzu tasarımı

### 2.1 Sayı ve rol ayrımı (02-MOTION §10 madde 5 ile tutarlı)

- **Holdout kohortu: 20 kişi, AYRI bir havuz.** İçerik protokolünün "en az
  üç demonstratör" (referans/ideal-form oluşturma) ile **AYNI KİŞİLER
  OLMAMALI** — referans oluşturan demonstratörler modelin "doğru" tanımını
  şekillendiriyor; aynı kişiler holdout'ta da olursa model kendi referansına
  karşı sınanmış olur (train/test sızıntısının insan-denek karşılığı).
- **Roadmap'in Beta kohortu ("en az 20 hedef beta kullanıcı", §10 Beta/revenue)
  İLE bu holdout AYNI havuz mu olsun — açık soru, orkestratöre sorulmalı.**
  Aynı kohort kullanmak recruitment verimliliği sağlar, ama iki süreç
  AMAÇ olarak ayrı: holdout **yapılandırılmış/talimatlı çekim** (belirli
  teknik, belirli tekrar sayısı, kontrollü açı/mesafe) isterken, beta
  **organik/serbest kullanım** ölçer. Öneri: aynı havuzdan recruit edilsin
  (tek duyuru/onam süreci), ama **iki ayrı oturum** olarak koşulsun (biri
  "laboratuvar" tarzı etiketleme çekimi, biri gerçek ürün kullanımı) —
  nihai karar kurucuda.

### 2.2 Çeşitlilik kotaları (kapıların matematiksel gereksinimi)

| Boyut | Neden zorunlu | Hedef dağılım (öneri) |
|---|---|---|
| Stance (orthodox/southpaw) | Roadmap'in kendi UX kapısı zaten "5 kullanıcıdan 4'ü orthodox/southpaw" diyor; laterality kalibrasyonsuzsa hiç skor verilmiyor (M-F-06) | ≥%25 southpaw (nüfus oranından fazla — azınlık sınıfın kendi κ ölçümü için yeterli örneklem şart) |
| Deneyim seviyesi | Ürünün birincil kullanıcısı "başlangıç/orta seviye" (roadmap §3) | ~%60 başlangıç · %30 orta · %10 deneyimli (deneyimlinin "temiz" form varyansı düşük referans çapası sağlar) |
| Kol uzunluğu/vücut tipi | D2'nin kendi bulgusu: uzanma **kol uzunluğuna** normalize edilmeli, aksi hâlde kadraj artefaktı çıkıyor | geniş boy/kol-uzunluğu aralığı — tek bir vücut tipine kilitlenme yasak |
| Cihaz sınıfı | Aile cihaz matrisinin 8 temsilcisi (02 §9) | mümkün olduğunca 8 sınıfa yayılmış, en az iOS+Android karışımı |
| Işık/mesafe/açı | JAB roadmap §2 zaten 100/300/700 lux · 1.5/2.5/3m · ön-eğik 30-45° tanımlamış | her katılımcı en az 2 farklı lux/mesafe hücresinde çeker |
| Cilt tonu | MediaPipe pose güven skorunun ten tonuna göre sistematik sapması bilinen bir adalet riski (literatür) — ölçülmeden "kapı geçti" denemez | görünür çeşitlilik hedeflenir, çekim sonrası dağılım RAPORLANIR (kota değil, şeffaflık) |

### 2.3 Recruitment — kurucu kapısı

00 §3.4: *"gerçek cihazda fiziksel hareket... testi"* ve *"demonstratör...
sözleşmeleri"* kurucu paketine gider. 20 kişilik holdout recruitment'ı
(nasıl bulunacaklar — arkadaş çevresi mi, yerel spor salonu mu, ücretli
katılımcı platformu mu, ücret/telafi var mı) **kurucu kararı** — bu planda
yalnız gereksinim/seçenekler sunulur, seçim yapılmaz.

## 3. Nasıl etiketlenir — protokol

### 3.1 Araç: icat etme, mevcut boruyu uzat (HASAT-TURU dersi #tekrar)

`motion-core/lib/tools/` altındaki `fixture_schema.py` / `extract_landmarks.py`
/ `analyze_d2.py` ve `jablab_engine`'in `segment_punches.dart`'ı zaten
video→landmark→event ayrıştırma zincirini kurmuş durumda (D2 kapısında
doğrulandı). **İnsan etiketleyicinin** çalışacağı tek eksik parça: bu
zincirin ürettiği ADAY event'leri bir insanın video karşısında
onaylayacağı/düzelteceği bir arayüz (mevcut mu, yoksa küçük bir
etiketleme-yardımcı script mi gerekiyor — **bu bir geliştirme kararı,
orkestratöre/writer'a bırakılıyor**, burada yalnız gereksinim tanımlanıyor).

### 3.2 Etiket şeması (kapı metriklerinden geriye türetildi)

Her aday punch event'i için:
```
{
  clipId, participantId, deviceClass, lux, distanceM, cameraAngleDeg,
  punchType: jab|cross|hook|uppercut|none,
  tExtensionStartMs, tPeakMs, tRetractionEndMs,   // event boundary — ≤100ms hata kapısı için
  stance: orthodox|southpaw,
  guardState: held|dropped|ambiguous,
  labelerId, secondLabelerId, agreementFlag,       // çift-kör + uzlaşı izi
  confidenceBucket: A|B,                            // mevcut band sözleşmesiyle (K8) tutarlı
  isHoldout: true                                   // referans/demo kohortundan AYRI olduğunu işaretler
}
```

### 3.3 Çift-bağımsız etiketleme + Cohen κ ölçümü

Roadmap açıkça **"Stance ve guard expert agreement Cohen κ ≥0.75"** istiyor
— bu yalnız ÇOK etiketleyicili (≥2, bağımsız, sonra uzlaştırılan) bir
protokolle ölçülebilir; tek etiketleyici κ üretemez. Öneri akış:
1. Her klip **en az 2 bağımsız etiketleyici** tarafından baştan etiketlenir (kör — birbirinin etiketini görmeden).
2. Uyuşmazlıklar bir **3. hakem** (tercihen `movement-science-advisor` danışmanı) tarafından çözülür.
3. κ, uzlaşmadan ÖNCEKİ ham çift-etiket setinden hesaplanır (uzlaşma sonrası veriden hesaplamak κ'yı yapay şişirir — metodolojik hata sınıfı, HASAT-TURU'nun "adayları görmeden eşik dondur" disipliniyle aynı aile).
4. Etiketleyicilerin en az biri alan uzmanı olmalı (CLAUDE.md danışman listesi: `motion-cv-engineer` + `movement-science-advisor`); geri kalan hacim eğitilmiş etiketleyicilerle yapılabilir ama protokol/kalite kontrolü uzman imzası taşır.

### 3.4 Negatif örnekler unutulmamalı

"Non-punch aktivitede false event ≤1/dakika" kapısı **YUMRUK ATMAYAN**
görüntü de gerektirir — footwork, guard tutma, dinlenme, yürüme, konuşma.
Çekim protokolü yalnız "punch at" değil, her oturumda en az bir **saf
negatif segment** (yumruksuz serbest hareket) içermeli.

## 4. Hangi aydınlatma/rıza metniyle — onam formu iskeleti (TASLAK, hukuk gözden geçirmedi)

> ⚠️ Bu metin hukuki tavsiye değildir; 00 §3.4 "Hukukçu... sözleşmeleri"
> maddesi gereği son metin kurucu/hukuk onayından geçmeden kullanılamaz.

**Zorunlu unsurlar:**
1. **Amaç beyanı:** "Bu çekim, JabLab uygulamasının yumruk-tanıma
   yazılımını GELİŞTİRMEK ve DOĞRULAMAK için yapılıyor."
2. **Ne kaydediliyor:** Ham video görüntüsü + türetilmiş vücut-nokta
   (landmark) verisi. Ses kaydedilmiyor (varsayılan; kayıt gerekiyorsa ayrı madde).
3. **Saklama süresi ve İNDİRGEME taahhüdü:** Ham video yalnız etiketleme
   tamamlanana kadar saklanır (öneri: azami 90 gün), sonra **silinir**;
   kalıcı olarak yalnız anonimleştirilmiş landmark+etiket verisi tutulur.
   Bu, ürünün kendi "ham video cihazda kalır, yüklenmez" sözleşmesinden
   **BİLEREK FARKLI bir istisna** — metinde bu fark AÇIKÇA belirtilmeli
   ("bu çekim, uygulamanın normal kullanımından farklıdır").
4. **Kullanım sınırı:** Yalnız model eğitimi/değerlendirmesi; pazarlama,
   store görseli veya üçüncü şahıslarla paylaşım için **AYRI, opsiyonel
   bir onay kutusu** (varsayılan işaretsiz — 00 §15 "explicit marketing
   opt-in" ilkesiyle tutarlı).
5. **Yaş/uygunluk:** 18+ beyanı.
6. **Geri çekme hakkı:** Katılımcı istediği an rızasını geri çekebilir;
   geri çekme talebinde verisi (ham + türetilmiş) silinir — silme SLA'sı belirtilir.
   **Uygulama notu:** ürünün kendi "delete" akışı (JAB-P1-004, henüz
   yazılmadı) bu taahhüdün TEKNİK karşılığı olacak; ikisi TUTARLI tasarlanmalı.
7. **Fiziksel risk bilgilendirmesi:** Shadow boxing sırasında yaralanma
   riski, 2 metre alan/zemin kontrolü uyarısı (roadmap §8 Safety ile
   birebir aynı dil kullanılmalı — üründeki ile çekimdeki güvenlik dili
   AYRIŞIRSA tutarsızlık doğar).
8. **Telafi/ücret alanı:** Kurucu kararı — bu taslak yalnız alanı açık
   bırakıyor.
9. **İletişim/şikayet kanalı:** support@yulalab.com (ürünün kendi destek
   kanalıyla aynı, ayrı bir gölge kanal icat edilmiyor).

## 5. Sayısal fizibilite (kaba tahmin, doğrulanmadı)

Bir 3 dakikalık round'da rahat tempoda tahmini 60-120 punch (D2'nin 128
punch/6 klip oranından kaba ekstrapolasyon — **gerçek oran çekim sonrası
yeniden ölçülmeli**, burada yalnız büyüklük mertebesi). 20 kişi × 3 round
× ~90 punch/round ortalama ≈ **5.400 aday event** — 3.000 hedefinin
üzerinde güvenlik payı bırakır, ancak çeşitlilik kotaları (§2.2) karşılanmadan
saf sayı kapıyı geçirmez; kota-eksik fazlalık holdout'a SAYILMAMALI.

## 6. Açık sorular — orkestratöre/kuruculara

1. Holdout kohortu ile beta kohortu aynı 20 kişi mi, ayrı mı? (§2.1)
2. Recruitment kanalı ve telafi/ücret var mı? (§2.3, §4 madde 8)
3. Etiketleme arayüzü mevcut mu yoksa küçük bir yeni araç mı gerekiyor? (§3.1)
4. Ham video saklama süresi 90 gün öneri — kurucu/hukuk onayı gerekiyor. (§4 madde 3)
5. Çekim mekânı: kurucunun kendi ortamı mı, katılımcıların kendi evleri
   (self-capture) mi? İkincisi çeşitlilik açısından avantajlı ama kalite
   kontrolü (açı/mesafe standardı) zorlaşır.

## 7. Bu planın kapsamadığı şey

Hook/uppercut ve gelecekteki disiplinlerin KENDİ model kapıları (roadmap
§10: "her yeni disiplin aynı kapıyı ayrı geçer") bu plana dahil değil —
jab/cross holdout'u önce, sonra aynı iskelet hook/uppercut'a uyarlanır
(HASAT-TURU-HOOK-UPPERCUT.md zaten o tekniğin REFERANS tarafını
ilerletmiş durumda; holdout tarafı bu planın bir sonraki türevi olur).
