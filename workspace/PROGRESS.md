# JabLab — İlerleme Kaydı

## 2026-10-01 — QA oynatıcı eşzamanlı kapanış çiti

Bağımsız beş-app medya incelemesi, `play()` hesap iptalini kendi çağrısı
içinde bildirdiğinde bekleyen native Future kaydedilmeden portun emekliye
ayrılabildiğini buldu. Ayrı port fabrikası callback'i de native yuvayı
sızdırabiliyordu. Her iki yol eski kodda deterministik kırmızı testle
yeniden üretildi. Native işlem bekleme işareti init/play/pause çağrısından
önce ayrıldı; fabrika dönüşünde hesap/epoch tekrar okunup yeni port gerekirse
emekliye alınıyor. Fabrika/init/play/pause eşzamanlı iptal testleri **4/4**,
ilgili medya ve 292 satır kaynak projeksiyonu **26/26**; hedefli analiz ve
diff kontrolü temiz. Kanıt:
`scratch/2026-10-01-jablab-reentrant-media-retirement-v1/REPORT.md`.
Bağımsız son yama incelemesi dar PASS; yeni P1/P2 yok
(`scratch/2026-10-01-jablab-reentrant-retire-postfix-peer-v1/REPORT.md`).
Gerçek native cihaz kabulü açık; üretim kataloğu boş, gerçek medya/model
kabulü yok.


## 2026-09-28 — Solo Boks paket ve şema kapısı

Mevcut 39 derslik kurs JSON'u (196.906 bayt; SHA
`5dc65d034569922ba5c85eeedff5ca9a361e5b61c6c7f8c3b23eebb6415f67c3`)
tek varlıklı Motion Content manifestiyle doğrulanıyor. Ana ekran ve doğrudan
kurs rotası doğrulama tamamlanmadan dersi açmıyor. Eksik paket veya SHA
uyuşmazlığı ve manifestle eşleşse bile 39 ders şemasına aykırılık,
yeniden denemeye açık geçici okuma gibi gösterilmiyor. Kurs rotasındaki
hata ekranında görünür geri dönüş var; TR/EN metinler paket sorunu ile
geçici okuma sorununu ayırıyor.

Bağımsız incelemenin iki P2 bulgusu ve takipteki eksik-paket sınıflandırma
açığı kapatıldı (`scratch/2026-09-28-jablab-runtime-integrity-peer/ADDENDUM.md`).
Yerel **49/49** odak Flutter testi, tam analiz, manifest `--check` ve
`git diff --check` geçti. Ders JSON'u, 39 kimlik/sıra ve ilerleme şeması
değişmedi. Gerçek video, kişi-ayrık uzman gard/yumruk modeli, native cihaz
ve kurucu fiziksel kabulü hâlâ açık.

## 2026-09-28 — Solo boks ilk kursu; içerik köprüsü dar PASS, ürün kabulü açık

İlk solo boks kursu **39 ders** ve canlı v8d kaynak paketinde. Hazırlık,
pratik ve ilerleme akışı kaynak/widget düzeyinde denetlendi; gerçek onaylı
video, eğitmen kişi-ayrık gard/yumruk hata verisi ve tam-kurs form modeli
**0**. Sabit Motion Core `motion_content` okuyucusu güncel kurs JSON'unu
SHA ile doğruladı; odak testi **4/4**, bağımsız dar peer PASS
(`scratch/2026-09-28-jablab-content-bridge-peer-v1/REPORT.md`). Üretim
manifesti, ekran/oynatıcı, gerçek cihaz ve kurucu fiziksel kabulü açık.

Güncel kurs ve kaynak düzeyi içerik köprüsü `28f6fe8` commitinde mevcut PR #1
incelemesine taşındı. GitHub Actions'ın üç işi bütçe engeliyle başlamadı;
bu kaynaklar için yararlı CI, merge veya mağaza kabulü yok. Kanonik devam:
`holding/plans/MOTION-MODEL-RESUME-2026-09-27.md`.

## 2026-07-25 — Venture AÇILDI (ayrı repo; kod YOK)
- Kurucu kararıyla monorepo'dan ayrı repoya kuruldu (`kocakkmustafa/jablab`); plan + kilitli CLAUDE.md + defterler hazır; bundle-id `com.yulalab.jablab` rezerve.

## 2026-07-26 — 🔓 KOD KİLİDİ AÇILDI: kurucu "JabLab'a başlayalım" · G1/D2 kapısı ŞARTLI GEÇTİ

**Tetik:** Kurucu JabLab'ı seçti (tavsiye Lissom'du) → J-010: `motion-core` çekirdeğini bu venture kuruyor.

### G1 / D2 kapısı — ölçüldü, hüküm verildi
- **Eşikler ölçümden ÖNCE yazıldı** (gece modu §2.6): `app/docs/gates/D2-KAPI-PROTOKOLU.md` — ölçüm sonrası değiştirilmedi.
- **Ölçüm hattı kuruldu** (aile-geneli, Gravita D1 de kullanacak): `motion-core/lib/tools/` — `fixture_schema.py` (katalog §6 sözleşmesi) · `extract_landmarks.py` (video→MediaPipe Tasks→fixture JSON, model sha256 pinli) · `analyze_d2.py` (faz tespiti + bölgesel görünürlük + eşleştirilmiş desimasyon).
- **Veri:** 6 gerçek boks klibi (1 × Wikimedia CC BY 4.0, 5 × Pexels License), 2.662 kare, **128 tespit edilmiş yumruk**. Klipler yalnız ölçüm içindir — ship edilen fixture'a girmez, model eğitilmez.
- **Sonuç:** medyan `t_ext` = **128,2 ms** (en hızlı %10: 54,1 ms) → **3,8 kare@30fps · 7,7 kare@60fps** (eşik ≥2 / ≥4 ✅). Faz-süresi metriği 2× seyreltmede **6/6 klipte** piksel-hızından kararlı (CV_phase 0,027-0,113; oran 1,2-4,0×).
- **Hüküm: 🟡 ŞARTLI GEÇTİ (D2-A + D2-B).** Hız = faz-süresi kararı ölçümle doğrulandı ve **kilitlendi**. Rapor: `app/docs/gates/D2-KAPI-RAPORU.md`, kanıt `gates/evidence/` (12 analiz JSON + `e_series.png`).

### Ölçüm sırasında düzeltilen 4 metodoloji hatası (kanıtı raporda)
1. Uzanma omuz genişliğine değil **kol uzunluğuna** normalize edilmeli (`e = r/L`, gard ≈0,55 · tam uzanma ≈0,95).
2. Görünürlük **mutlak değil, klibin kendi gard tabanına göre** ölçülmeli — yoksa "ayak görünmüyor" bulgusu blur değil **kadraj** artefaktı olur.
3. Desimasyon karşılaştırması **aynı yumruk eşleştirilerek** yapılmalı; "medyan vs medyan" farklı yumruk kümelerini kıyaslıyordu.
4. **Fiziksel üst sınır (`MAX_EXT_MS=400`)** şart — detektör, kolunu uzatıp bekleyen boksörü "736 ms'lik yumruk" okuyordu. Bu doğrudan motor bulgusu (J-009: `EXTENSION_TIMEOUT`).

### Kapı çıktıları
- Hız metriği **bant** olarak sunulacak, sayı olarak değil (J-008).
- V1 hata seti **güvenilirlik bantlarına** ayrıldı: 🟢 duruş/ayak/denge + yumruk olayı & kombinasyon sırası · 🟡 gard eli (ön-eğik kamera şartıyla) · 🟡 dirsek/overreach (kalibrasyon bekliyor) · 🔴 hook/uppercut V1 dışı.
- **Kamera açısı ürün kararı:** ön-eğik ~30-45° (J-006) — saf yan açı iki eli birden göremiyor.
- **Mimari karar (J-012):** faz tespiti native'de her kare; Dart olay başına. Katalog §2'nin "kanal diyeti" maddesi bu ölçümle sınırlandı.

### Açık kalan (kurucu-kapılı)
- **J-007 / D2-D:** blur ↔ kapanma ayrımı → `app/docs/gates/D2-CEKIM-PROTOKOLU.md` (35 dk, 22 çekim; §1 tempo merdiveni tek başına yeterli).
- **J-011 / D2-C:** cihaz fps + termal profil (fiziksel telefon gerekir).

## 2026-07-29 — W0: İLK ÜRETİM KODU (motor + IA), 20/20 test yeşil

**Bağlam:** M-F-18 blueprint kapsamı 8 disipline genişletti (JabLab = *Solo Combat Training*); M-F-17 kurucu çekimini ve ücretli klip yedeğini iptal etti; M-F-03 ile motion_core kanonik çekirdek oldu ve M-017 blokajı kalktı. Push izni verildi.

### W0.1 — doküman senkronu
Roadmap §0'a 8 disiplinli dalga tablosu + motor bağımlılık sırası + W0 backlog. Ücretli klip iptali 3 yerde işlendi; yerine katalog §6.3 doğrulama merdiveni (AIST++/MM-Fit + TestFlight kohortu) ve yasak set listesi. `boxing@1.0.0`'a `deviceValidation` (G8, muhafazakâr 30fps varsayımı).

### W0.2 — Standing Striking Engine (G4) ✅
`packages/jablab_engine` — motion_core üstünde, **boks bilgisi sıfır**: teknikler/fazlar/eşikler/hatalar config'ten gelir (ADR-004). Modüller: geometrik duruş tespiti (M-F-06) · 8 ölçü (hepsi **aynı-kare oranı** → kamera mesafesi ve vücut tipinden yapısı gereği bağımsız; D2 analizörüyle aynı matematik) · koşul DSL'i · faz derleyici · `AttemptDigest` (ADR-002) · hata değerlendirici.

**Testin yakaladığı iki gerçek kusur:**
- **J-026 çift sayım:** bir jab aynı zamanda "sınıflandırılmamış vuruş"tur; iki faz makinesi de tamamlanıyordu → her yumruk iki kez sayılırdı. Config'e `fallback` bayrağı + motorda tahkim.
- **J-027 filtre eşiği yok ediyordu:** çekirdeğin varsayılan 1 Hz yumuşatması 120 ms'lik yumruğun tepesini **%22 sönümleyip ~80 ms geciktiriyor**, PEAK (0,85) hiç ateşlenmiyordu — motor tek yumruk tamamlayamıyordu. Eşiği düşürmek yerine **filtre D2'den türetilerek pinlendi** (8 Hz / beta 0,05). Eşik ve filtre artık ayrı ayrı değiştirilemez (M-C-07'nin somut hâli). Tepe 0,776 → **0,991**.

Regresyon testleri: J-009 · J-013 · hüküm-verilemezken-teknik-hata-yok · kalibrasyonsuz-taraf-etiketi-yok.

### W0.3 — IA çatısı ✅
4 seviyeli hiyerarşi; 8 disiplin (Boxing canlı + 2 kurs / 8 ders, 7'si dalga etiketli "yakında"); her disiplinde "neler ölçülür / **neler ÖLÇÜLMEZ**" kutusu; 7 maddelik gerekçeli "Neden yok?" sayfası. **Dürüstlük sözleri mekanik değişmez olarak kodlandı** ve testte zorlanıyor — sahte kurs, boş kurs, hayalet teknik ve gerekçesiz kapsam-dışı madde derleme/test seviyesinde imkânsız.

**Durum:** `feat/g1-d2-gate` origin'de (`5282f18`), 20/20 test yeşil, motion_core 94/94 etkilenmedi.

## 2026-07-29 (gece) — Çekirdek 0.1.0 pinlendi · main'e merge · G5 iskelet

- **Çekirdek pinlendi:** `motion_core-v0.1.0` @ `bffbc53`. Path bağımlılığı KASITLI terk edildi — paylaşımlı ağaçta path, o an hangi dal çıkılıysa onu okur; bağımlılığımız başka oturumun dal değiştirmesiyle sessizce değişirdi (M-F-22 ile de uyumlu). **Kanıt: 0.1.0'a karşı analyze temiz + 20/20 yeşil, kırılma yok.**
- **M-J-01 aile defterine yazıldı:** çekirdek varsayılan yumuşatması hızlı geçişi söndürür; filtre kesimi geçiş süresinden türetilir (≈1/(2T)) ve **eşikle birlikte pinlenir**. Aday muzdaripler Gravita/Choreia/Ostinato — tuzak, varsayılanın *yavaş* hareketlerde doğru çalışmasından geliyor.
- **PRD §2.1:** J-007 tutmazsa `ELBOW_FLARED`/`OVERREACH` V1'den çıkarılır (11→9), "yakında" olarak bile gösterilmez. Şimdiden yazılı.
- **Yetki kullanıldı (M-F-24):** `feat/g1-d2-gate` → `main` ff-merge + push, testler yeşil kanıtıyla. main = `53a4992`.
- **G5 iskelet + shell_candidate pilotu (M-F-25):** 4 sekmeli kabuk, IA sayfa şablonları, dürüstlük kutusu, ilerleme (bant-only), paywall iskeleti — hepsi **alan sözlüğü olmadan** ve `jablab_engine`'e bağımlılık olmadan yazıldı (terfi ettiğinde Ostinato'ya boks motoru taşımasın diye). App katmanı çeviriyi tek yerde yapıyor.
- **Dürüstlük artık UI'da da zorlanıyor:** "yakında" disiplinde kurs render edilmiyor · `HonestyBox` `notMeasured` boşsa assert'le patlıyor · ilerleme sayfasına kalibrasyonsuz sayı sızarsa test kırılıyor · canlı seans ekranı kamera hattının bağlı olmadığını söylüyor (sahte "analiz ediliyor" yok).
- **W1 hasat kuyruğu:** `~/motion-harvest/jablab/queue.txt` (M-F-26, repoya girmez) — 20 PENDING. ⚠️ **`cross` yalnız 2/3 kaynakta**: V1 çekirdeğinin yarısı ve M-C-04 gereği referansa dönüşemiyor → 4. kanal kimlik doğrulaması W1'in ilk işi.

**Durum:** main `53a4992` push'lu · **27/27 test yeşil** (20 motor + 7 widget) · çekirdek 126/126 etkilenmedi.

## 2026-07-29 (gece, tur 2-4) — G5 iskelet · çapraz doğrulama · hasat

**Çekirdek pini:** 0.1.0 → 0.2.0 → **0.2.1** (her adımda 36/36 yeşil, kırılma yok). Path bağımlılığı terk edildi: paylaşımlı ağaçta path, o an çıkılı dalı okur — bağımlılık başka oturumun dal değiştirmesiyle sessizce değişirdi.

**G5 iskelet + shell_candidate pilotu (M-F-25).** Kabuğa iki sert kural: alan sözlüğü yasak, `jablab_engine` bağımlılığı yasak (olsaydı terfi ettiğinde Ostinato'ya boks motoru taşınırdı). Terfi şartları README'ye + **mekanik terfi kapısı testine** yazıldı — ilk grep sürümü `jablab_engine` içindeki "jab"e takılıp yanlış alarm veriyordu; yanlış alarm veren denetim kapatılır, o yüzden kelime sınırı + yorum muafiyetiyle teste taşındı.

**Dürüstlük UI'da da zorlanıyor:** "yakında" disiplinde kurs render edilmiyor · `HonestyBox` boş `notMeasured` ile assert'le patlıyor · ilerleme sayfasına kalibrasyonsuz sayı sızarsa test kırılıyor · canlı seans ekranı kamera hattının bağlı olmadığını söylüyor.

**İki hata, ikisi de kayda geçti:**
- **M-J-03 GERİ ÇEKİLDİ.** "Rig 13.332 karenin hepsine detected:false yazıyor" diye P0 açtım; yanlıştı. Fixture'ı v1 şemasının `landmarks` anahtarıyla okudum, v2 `lm` kullanıyor. Rig **%98,9** ile doğru çalışmış. Kalıcı ders: fixture okuyan her araç `schemaVersion` kontrol edip beklemediği sürümde PATLAMALI.
- **J-028 (gerçek kusur, bende).** Python↔Dart çapraz doğrulaması Dart motorunun mesafeleri ham normalize koordinatlarda hesapladığını yakaladı; MediaPipe x'i genişliğe, y'yi yüksekliğe **ayrı** böler (`stanceWidthRatio` python 2,218 vs dart 0,0013). **22 sentetik test bunu yakalayamazdı** — bozulma yalnız gerçek kamera karesinde çıkıyor. `FrameSize` ile düzeltildi; 59 gerçek karede iki hat artık 1e-6'da uyuşuyor. Aile kuralı oldu (M-F-30).

**Hasat:** kuyruk 20 → **70 satır**, 3 → **9 kanal** (Yankello · Frolov · Kenny Weldon · Coach Anthony · McLeod Scott · Fran Sands eklendi). **3 fixture üretildi, 71.945 tespitli kare** (%98,9-%99,5). Triyaj 2 gerçek eleme yaptı (netlik 31<40; üst-gövde oranı 0,58<0,6). 403 geçiciydi, tek yeniden deneme yetti.

⚠️ **Kapsam gerçeği (J-029):** kuyruğu 3,5 katına çıkarmak ≥3 kuralını çözmedi — darboğaz video değil **bağımsız eğitmen** sayısı. Yalnız `stance` ≥3'e ulaştı; `cross` (V1 çekirdeğinin yarısı) hâlâ referans üretemiyor.

---

## OTURUM SONU — 2026-07-29 (G6 içerik hattı + G7 bağlama + sözleşme denetimi)

**Kapanış durumu:** `main` @ `9d25fa5`, origin ile eşit, çalışma ağacı temiz.
77 engine + 29 Flutter testi yeşil, skip yok.

### Biten

**G6 — içerik hattı tamamlandı.** Boxing 3 kurs · 17 ders · 14 ilerleme kapısı
(önce 2/8/5). Plan §15'in üç hattı da kuruldu. **Fitness şimdi çıkabilir, Orta
çoğunlukla kilitli** ve sebep aynı ilke: Fitness'ın kapıları süre/katılım ölçer,
teknik hükmü vermez — "10 dakika çalıştın" demek için eğitmen uzlaşısı gerekmiyor.
Orta'nın üç dersi ölçümü olmayan beceriye dayanıyor, kilitli ve her kilidin sebebi
eksik ÖLÇÜMÜN adıyla yazılı (J-038, aile deseni M-F-55).

**Sesli koç 27 → 61 anahtar / 165 cümle.** Varyant sayısı bilinçli arttırıldı:
aynı cümleyi turda 40 kez duyan onu duymaz olur, ve bu üründe tekrar körlüğü
sessizliğe eşdeğer.

**G7 — anahtar düzeyinde bağlama.** Canlı tur artık gerçekten sayıyor: süre akıyor,
anlatı konuşuyor, HÜKÜM SUSUYOR. Anlatı ile hüküm AYRI yuvada — turu saymak poza
bakmayı gerektirmez, ama ikisi aynı yerde görünürse kamera yokken kullanıcı
sistemin kendisini yargıladığını sanır. Gerçekten canlı 5 anahtar (round_start ·
halfway · last_ten · last_five · round_end); gerisi anahtar düzeyinde beyanlı.

**J-042 kapandı — M-F-60 girişim-kapatma sözleşmesi.** PEAK'e ulaşmadan
histerezisli geri çekilme → girişim kapanır, `ATTEMPT_ABORTED(peakExtension)`
üretir, bant `coached`. **Sayım değişmedi** ve sözleşmenin kolay çiğnenen yarısı
buydu: girişimi kapatınca yedek teknik aynı yarım hareketi saymaya başlıyordu.

**Sözleşme denetimi ilk geçiş (M-F-63).** 10 kural okundu ve testlere numarayla
bağlandı. Kendi config'imde iki ihlal buldum: kırpılmış sınırın "ölçülen" diye
sunulması (J-043) ve 17 tüketicisiz alan (J-044) — `integrity` bloğunda üç denetim
görünüyordu, biri çalışıyordu.

### Açık — yeni oturumun işi

1. **50-doc ile tam denetim.** Metin artık okunabilir:
   `~/motion-worktrees/coordinator-main/docs/50-REFERANS-TUKETIM-SOZLESMESI.md`.
   Bu turda kural eşlemesi yapıldı; kalan derinleştirme yeni oturuma.
2. **Gerçek stance artefaktı BAĞLANMADI** (`workspace/artifacts/reference-boxing-stance.json`):
   kural 7 (`mirrorConfident=false`, tablom taraf-bağımlı) + kural 8 (üç take de
   `unattested`). ⚠️ Sayıları kalibrasyon gerçeği sanma — CLI tam-videoyu hizalıyor
   (L-139), benim aracım duruşun korunduğu 90 karelik pencereyi seçiyor.
3. **awaiting-wiring (5 grup) + awaiting-surface (1).** Kamera sihirbazı AYRI kapı,
   G7'ye sıkıştırılmayacak. HIIT ekranı da ayrı.
4. **Antrenör-doğrulama listesi** kurucu-bekleyen (manuel iş).
5. **Haftalık kuyruk:** `cross` 3. eğitmen · J-007 (blur↔kapanma, hedge'siz) ·
   J-045 (birim, alan bağlanınca) · J-046 (ayna çelişkisi, koordinatöre soru).

---

## OTURUM SONU — 2026-07-29 (gece vardiyası: 🥊 İLK JAB REFERANSI + Fitness SHIP denetimi + UI-BRIEF)

**Kapanış durumu:** `main` @ `01a0b03`, origin ile eşit, çalışma ağacı temiz.
**90 engine (+13) + 33 Flutter** testi yeşil, skip yok, `flutter analyze` 0.

### 🥊 İLK JAB REFERANSI KURULDU — VARSAYILAN 14° EŞİKTE (J-061)

Stance 35° gerektirmişti (M-F-51); **jab genişletme GEREKTİRMEDİ.**
11 take / **3 bağımsız kaynak** · `meanAgreement` 0,7896 · `unreliableJoints` **1**.
Stance kıyası jab'ın striktly daha güçlü kanıt taşıdığını gösteriyor
(eşik 14 vs 35 · uyum 0,7896 vs 0,7881 · güvenilmez eklem 1 vs 3).

**Kümeyi kapatan şey eşik değil, üçüncü TEMİZ kaynak oldu** — ve o kaynak
beklenmeyen yerden geldi. Hasat turunda denenen 6 yeni jab adayı elendi, ama
`segment_punches.dart` **duruş** videolarına uygulanınca yankello 2 +
kennyweldon 1 tamamlanmış jab verdi. **Video başlığı değil FSM'in kendisi
"bu bir jab mı" sorusunun hakemidir** — sıfır indirme maliyetiyle iki yeni
eğitmen kimliği. LOOSE kontrol koşumu da 14°'de geçti (0,7813), yani pencere
kuralı marjinal: J-060'ın "pencere-içeriği artefaktı değil" hükmü doğrulandı.
frolov `intentVariant: slow-demo` olarak dışlandı — havuzlanmadı, eşik
genişletilmedi (M-F-66 emsali aynen).

**Ürün anlamı rahatsız edici ama ölçülmüş: jab'ın KENDİSİ olan öncü kol,
eğitmenlerin EN ÇOK ayrıştığı yer** (`lead_forearm` 51,5° p90). Hiçbir kol
eklemi skorlanmıyor; taban+gövde skorlanıyor (`trunk_tilt` 5,1°). Bu,
stance'teki "kollar anlaşmıyor" deseninin **üçüncü bağımsız tekrarı** —
çapraz-teknik tutarlılık artık desen değil bulgu.

**Kural 7 için bağımsız kanıt üretildi** (yeni araç `probe_window_stance.dart`):
çekirdeğin DTW ayna-araması kararsız, ama JabLab'ın M-F-06 geometrik duruş
dedektörü var → katkı veren **11 take'in 11'i de %100 orthodox** (güven
≥0,936); tek southpaw pencere küme kapısı tarafından ZATEN dışlanmıştı.
İki bağımsız mekanizma aynı sonuca vardı. Bu ölçüm çekirdeğin bayrağının
YERİNE KONULMADI — artefakt stance emsaliyle birebir bağlanmadı (kural 7+8),
yalnız config tablosu bağlandı.

### ⚠️ ÖNCEKİ TURUN "FITNESS ÇIKABİLİR" İDDİASI DÜZELTİLDİ (J-062)

Aşağıdaki G6 turu bölümünde yazan **"Fitness şimdi çıkabilir"** cümlesi
**yarım doğruydu ve yanlış yarısı ship'i tutuyor.** Skorlama yarısı doğru
(referans gerekmiyor, kamera gerekmiyor); ama cümle sessiz bir varsayım
taşıyordu: uygulamanın "10 dakika çalıştın"ı söyleyebildiği. Söyleyemiyor.

**7 kondisyon dersinin 7'si de beyan ettiği yapıyı koşmuyor:** `_Live`
bileşeni ders nesnesini hiç almıyor ve iki sabit taşıyor (3 dakika +
`SessionMode.steady`). "Twenty minutes / Six rounds" dersi 3 dakikada
bitiyor. `beyan ≠ canlı` sınıfı dürüstlük kusuru.

Çelişki kod↔içerik arasında DEĞİL — `cues.en.json` `$producers` bloğu durumu
zaten dürüstçe yazıyordu ("ekran su an tek tur kosuyor"). Yanlış olan bu
dosyanın ship iddiasıydı.

**Eksik envanteri** (`docs/gates/FITNESS-SHIP-DENETIMI.md`, kamera hariç):
🔴 F-1 seans planı yok (TEK zorunlu blokaj; narrator hazır, yeni ekran
gerekmiyor) · 🟡 F-2 HIIT aralık sürücüsü yok (ayrı kapı) · 🟡 F-3 kalıcılık
YOK (0 eşleşme; bitmiş seans kaydedilmiyor) · 🟢 F-4 ilerleme bandı "—" ·
🟢 F-5 sihirbaz yok.

**F-1 bilinçli olarak UYGULANMADI:** tur alt-bölümlemesi 7 dersin yalnız
2'sinde tam belirli (`r3` aritmetikten çıkıyor, `r5` tek tur); kalan 4 için
dinlenme/tur süresi **icat etmek** gerekirdi. Kalan dersleri kilitlemek ise
ürün-şekli kararı. İkisi de koordinatöre taşındı (A: içeriği yetkin biri
yazsın · B: fail-closed kilit; tavsiye B sonra A).

### UI-BRIEF (ortak gece kalemi)

`docs/design/UI-BRIEF.md` — `claude.ai/design` oturumlarına girdi. Marka tonu
("dürüst köşe" + 3 ses kuralı), metin akış diyagramı, **11 ekranın envanteri
ve her birinin durumları** (normal/boş/yükleniyor/hata/izin-reddi/kilitli),
9 açık boşluk (5'i kod beklemiyor), tasarımı bağlayan 9 sert kural.
Envanterdeki her durum gerçek; sayılar canlı içerikten doğrulandı.

**Tasarımın en büyük üç boşluğu:** onboarding hiç yok · teach aşaması
"watch first" diyor ama izlenecek içerik yuvası yok · içerik denetimi
başarısızlığı bugün ham crash (dürüst hata ekranı gerek).

### Hasat turu kapanışı (M-F-112)

Jab: 6 aday denendi, 6'sı elendi (1× 403 · 4× netlik<40 · 1× özel vaka).
**Özel vaka kayda değer:** "Fight your way Fit" triyajı (netlik 587) VE
romMode'u (active) geçti ama `StrikingEngine` 14.630 karenin **yalnız 48'inde**
hüküm verebildi → 0 tamamlanmış jab. Ders: **"kaynak uygun" ≠ "ölçülebilir"** —
triyaj+romMode kapıları motorun yapısal kapısını öngörmüyor (aile-geneli
hasat-kapısı boşluğu olabilir, koordinatöre bildirildi).
Stance 4. kaynak: 2 retle kapandı, **403 serisi olmadı** (tek 403), cooldown.
1 denenmemiş aday PENDING bırakıldı. `queue.txt` 8 satır sebepli güncellendi.

### Açık — yeni oturumun işi

1. **F-1 kararı koordinatörden gelince uygula** (A veya B) — Fitness'ın
   ship'ini tutan tek zorunlu kalem.
2. **Koordinatörde 2 karar (J-061):** p90 vs medyan istatistik seçimi
   (aile-geneli hüküm mü?) · kural 7'nin lafzı app-side ölçümle ikame
   edilebilir mi.
3. **F-3 kalıcılık** — pubspec'e ilk 3. taraf bağımlılık kararı.
4. Kamera köprüsü (ADR-002) koordinatör kuyruğunda — Fitness için gerekmiyor.
5. Antrenör-doğrulama listesi kurucu-bekleyen (manuel).
6. Haftalık kuyruk: `cross` hâlâ 2/3 kaynakta · J-007 (blur↔kapanma) ·
   J-045 (birim, alan bağlanınca).

---

## 2026-07-29 (gece, tur 2) — Koordinatör hükümleri işlendi: kural 7 · F-1(B) · F-3

**Kapanış:** jablab `main` @ `31a5737`, origin ile eşit, ağaç temiz.
**105 engine + 53 Flutter** yeşil, `analyze` 0.
motion-core dalı `feat/reference-cli-lead-side-prior` (`ce5d407`) origin'de — **merge koordinatörde**.

### ✅ Kural 7 ÖN KAPIDAN sağlandı (M-J-06)

`build_reference.dart`'a `--lead-side-prior` eklendi — çekirdek API zaten
destekliyordu, kanonik ARAÇ yüzeye çıkarmıyordu. 11/11-orthodox ölçümünden
türetilen prior ile `mirrorConfident` TRUE oldu, `searchDecisive` dürüstçe
false kaldı, `frames.meanRad` **bit-özdeş**. Prior veriyi değiştirmedi,
yalnız güven iddiasını ölçüme dayandırdı. Post-hoc ikame YAPILMADI.

### 🔴 Attestation denemesi durumu KÖTÜLEŞTİRDİ — jab tam-zincir OLMADI

4 kaynağın **atlanmış** transcribe+romMode adımını tamamladım (faster-whisper
kurulmadan önce hasat edilmişlerdi). 2'si attest edildi, **2'si `unknown` →
hard block**. Kanonik CLI artık reddediyor: `10 usable take from 2 source(s)`.
**J-061 artefaktı yeniden kurulamıyor** — tablo geçerli, zincir koşulamıyor;
config'e uyarı + test yazıldı, sessiz kalmıyor.

Sebep kaynak kusuru değil, **sınıflandırıcının üçüncü boşluğu**: Precision
Striking transkriptinde 15 emir kipi + 88 "you + fiil", Sören'de 13+77;
`ACTIVE_MARKERS` yalnız PT-tarzı 4 fiil tanıyor. frolov'un (birinci-şahıs)
kardeşi: **ikinci-şahıs koçluk emir kipi**. Sınıflandırıcıya dokunmadım —
kendi artefaktımı geçirmek için aile kapısını değiştirmek olurdu.

**Yan bulgu (aile-geneli):** türev pencere fixture'ları provenance'ı kesim
anında snapshot'lıyor → **uygunluk türev artefaktta bayatlıyor**, kapı-atlatma
yolu. İlk build'im tam bu yüzden geçmişti.

### ✅ F-1(B) — ve denetim üç kusur daha buldu

Süreli dersler artık beyan ettikleri işi koşuyor; yeni kabuk bileşeni yok.
1. **J-062 auditim undercount'muş:** 9 süreli ders var, 7 değil.
2. **`minutes` alanının tek anlamı yok** (çalışma+dinlenme / yalnız çalışma /
   ders süresi) → ilk yazdığım kapı yanlış temeldeydi, kaldırdım.
3. 🔴 **Üç dersin planı kendi kapısını geçirmiyordu** (r10 7,5/10 · r20 15/20 ·
   technique_round 6/9) — kullanıcı dersi sonuna kadar koşsa bile ilerleme
   kapısını asla geçemezdi. Otorite `minutes` değil **kapının kendisi**.

**Kapılar sayesinde icada gerek kalmadı:** r10 3×200 · r20 6×200 (ikisi
bağımsız olarak aynı 200sn'yi doğruluyor) · r3 3×180+2×90 · r5 1×300 ·
`first_round` 1×180 → **kilit açıldı**. 4 ders isimli kilitli (`tempo` ·
`hiit` · `technique_round` · `fatigue`), kapıları silinmedi `$deferredProgression`'a
alındı.

### ✅ F-3 — kalıcılık (Fitness vaadinin veri katmanı)

`SessionStore` + `JsonlSessionStore`: append-only JSONL, atomik tmp+rename,
satır düzeyinde şema sürümü, 3. taraf DB yok. Kaydedilen alan bilerek az;
hüküm/skor alanı yok. Arıza davranışları testli (bozuk satır tüm geçmişi
silmez, yarım son satır götürmez, depo kurulamazsa uygulama çalışır).
Yarıda bırakılan seans da kaydedilir. **Testler iki gerçek kusur yakaladı:**
boş yolda `const []` ilk açılışı çökertiyordu; dinlenmedeyken biten tur
sayılmıyordu.

### Açık — yeni oturumun işi

1. **Koordinatörde:** rom_mode üçüncü boşluk sevki (ikinci-şahıs koçluk kipi)
   → çözülünce jab artefaktı yeniden kurulabilir ve **tam-zincir** olur ·
   türev-pencere bayat-uygunluk kalemi · `--lead-side-prior` merge +
   `priorDisagreements` semantik notu.
2. **F-2 (HIIT):** F-1 mekanizması + `interval()` birleşimi, ayrı kapı —
   tek dersle (`hiit`) sınanacak, işaret bekliyor.
3. **F-1(A):** 4 kilitli dersin tur yapısı yazılınca kilitler açılır.
4. **F-4:** kalıcılık geldi → ilerleme sayfası süre/katılım bandı artık
   doldurulabilir.
5. Kamera köprüsü (ADR-002) koordinatör kuyruğunda — Fitness için gerekmiyor.
6. Antrenör-doğrulama listesi kurucu-bekleyen (manuel).

---

## 2026-07-30 (gece, tur 3) — 🥊 JAB ÜÇÜNCÜ TAM-ZİNCİR · F-4 · F-2 turu

**Kapanış:** jablab `main` @ `6afffdd`, origin ile eşit, ağaç temiz.
**110 engine + 60 Flutter** yeşil, `analyze` 0.
motion-core: `fix/rom-mode-imperative` MERGE EDİLDİ (main `c561204`).

### 🥊 Jab artefaktı BAĞLANDI — üçüncü tam-zincir (J-065)

Üç adım, her biri sonrakini açtı:

**1. rom_mode üçüncü boşluğu** — ayrı demet `MOVEMENT_CUE_MARKERS`. M-O-54'ün
ailesi GEVŞETİLMEDİ: onların sıkılaştırması doğruydu ve bedelini *benim iki
bloklu kaynağımın adıyla* kaydetmişti. Kalıplar transkript kanıtından
türetildi. Kendi negatif korpusum bir yanlış pozitifimi yakaladı ("keep your
head in the game") ve kapattım. Zorunlu süpürme: 0 tehlikeli geçiş, 20
uygunluk geçişi, **20/20 elle doğrulandı**.

**2. M-F-138** — uygunluk artık karar anında kaynaktan çözülüyor; kesim-anı
değeri tarihçe olarak saklanıyor. İki ayrım testle sabit, ikincisi J-064'ün
çekirdeği: `referenceEligible` YOK ≢ False (biri "sınıflandırılmadı",
diğeri "BLOKLU").

**3. Bağlama** — iki kaynak geri kazanıldı, 14/14 pencere taze kesildi,
build `--allow-unattested` OLMADAN koştu: `ATTESTED` · 11/11 attested ·
`mirrorConfident` TRUE (prior) · `priorDisagreements` boş · eşik 14°
VARSAYILAN. **Eklem tablosunu yeniden hesaplamadım** çünkü 17/17 eklemde p90
birebir aynı — geometri hiç değişmedi, yalnız kaynak beyanı tamamlandı.

`toleranceStatus` → `attested-provisional`: artık istatistiksel zayıflığı
işaretliyor, kaynak-uygunluğunu değil.

### F-4 — ilerleme sayfası konuşuyor, hüküm hâlâ susuyor (J-066)

Bantlar (bizim hükmümüz) ve kaydedilenler (ölçtüğümüz olgular) AYRI bölümde.
**Ölçülen ve kullanıcıya söylenen gerçek: hiçbir ilerleme kapısı bugün
geçilemez** — hepsi poz-analizi ya da `withValidAnalysisRatio` istiyor, ve
bu dakikalar sonradan da kredi olmaz (izlenmemiş süre retroaktif sayılamaz).
K8 kapısını gevşetmedim; değerleri birimiyle yazdım.

### F-2 turu — `tempo` açıldı, `hiit`'in gerçek blokajı bulundu (J-067)

**tempo AÇILDI** (v1 = sabit tempo): 1×600sn, beyan ve kapı aynı sayı.
Eski `tempoSwitch` kapısı reddedilen artan-tempo tasarımına aitti ve sabit
tempoda yapısal olarak geçilemez kalırdı → kardeş kapı şekli kondu,
`tempoSwitch` v1.x kilidi olarak saklandı.

**hiit'in blokajı sürücü DEĞİL, sayılar TUTARSIZ:** kapı 12 dk çalışma
istiyor, ders `minutes:12` diyor, blurb "short rest" diyor — üçü birden
doğru olamaz; burst/recover hiçbir yerde beyanlı değil (0 parametre).
Sürücüyü bilinçli EKLEMEDİM: hiçbir dersin süremeyeceği sürücü, projenin
kendi eleştirdiği "kod var ama kullanıcı duymuyor" durumunu üretirdi.

**Kondisyon artık 6 ders canlı**, hepsinin çalışma süresi kendi kapısına
birebir eşit.

### Açık — yeni oturumun işi

1. **hiit için TEK ürün kararı** (koordinatörde): hangi sayı otorite
   (`minutes` mi kapı mı) + burst/recover süresi. Karar gelince sürücü
   küçük bir iş.
2. **F-1(A):** 3 kilitli dersin (`technique_round` · `fatigue` ·
   `combinations` sınıfı) tur yapısı yazılınca kilitler açılır.
3. Kamera köprüsü (ADR-002) koordinatör kuyruğunda — **ilerleme kapılarının
   tamamı buna bağlı**, Fitness'ın kayıt/süre hattı ise bağlı değil.
4. Antrenör-doğrulama listesi kurucu-bekleyen (manuel).
5. Koordinatörde: POSTURE_CUE mecaz açığı (Ostinato'ya sevk edildi) ·
   4 transkriptsiz kaynağın kanıt tabanı · `gateJoints`/M-O-56 bağlamı
   (jab için aksiyon yok, artefakt damgayı sonraki kurulumda kazanır).

---

## 2026-07-30 (gece, tur 4) — F-2 ve F-1(A) KAPANDI: süreli derslerin 9/9'u canlı

**Kapanış:** `main` @ `fd0ccee`, origin ile eşit, ağaç temiz.
**110 engine + 64 Flutter** yeşil, `analyze` 0.

### F-2 — hiit aralık sürücüsü canlı (J-068)

M-F-149 kararı: `minutes:12` toplam otorite + 30/30 → 12×(30+30) = 12 dk
toplam, 6 dk çalışma, kapı 12→**6**. Plan artık kendi kapısını geçiriyor ve
blurb'un "short intervals with short rest" beyanı doğrulandı.

**`IntervalPlan` ayrı bir tip oldu ve sebebi yapısal:** `RoundPlan` son
turdan sonra dinlenme saymaz, aralıkta ise son patlamadan sonra da
toparlanma var — soğuma döngünün parçası. Aynı tipe sığdırmak ya değişmezi
kırar ya toplamı yanlış hesaplar.

Anlatıcı kipi artık plana göre seçiliyor; `steady` sabit kalsaydı aralık
replikleri hiç duyulmazdı ("kod var, kullanıcı duymuyor").

### F-1(A) — yapı-kaynaklı kilit kalmadı (J-069)

`technique_round` → 3×180sn (kapının 540sn'sini tam bölen TEK mevcut
uzunluk). `fatigue` → 4×300sn (iki tam çözümden blurb ayırdı: 200×6 r20 ile
birebir aynı olurdu ve "Long rounds" yanlış olurdu).

**Guidance-hypothesis gerilimi isimli çözüldü:** gerilim tur süresiyle değil
feedback frekansıyla yönetilir, ve bugün kamera olmadığı için "sürekli
feedback" zaten çalışmıyor. Gerilim `$guidanceHypothesisTension` alanında
TAŞINIYOR — kamera canlı hüküm verdiği gün tur süresi ve feedback-solma
birlikte ele alınacak.

Kilit testi güçlendirildi: kalan her kilidin **ölçüm eksikliğinden**
olduğunu zorluyor; yapı-kilidi geri gelirse kırılır.

**Süreli derslerin 9/9'u canlı, hepsinin çalışma süresi kendi kapısına
birebir eşit.** Kilitli 3: `combinations` · `counter` · `footwork_combo` —
üçü de ölçüm eksikliği (rakip yok / referans yok / teknik sınıflandırılmıyor).

### Fitness ship tablosu — 4/4 çekirdek kalem ✅

F-1 ✅ · F-2 ✅ · F-3 ✅ · F-4 ✅ · F-5 kapsam dışı.

### Açık — yeni oturumun işi

1. **Tam-track ship denetimi** (gece paketi 2. kalemi): uçtan-uca replay
   kanıtı — koordinatörün işaret ettiği sıradaki doğal kapak.
2. Kamera köprüsü (ADR-002) koordinatör kuyruğunda — **ilerleme
   kapılarının tamamı buna bağlı**; Fitness'ın kayıt/süre hattı değil.
3. UI tasarım boşlukları (onboarding · öğretici içerik yuvası · dürüst hata
   ekranı) — claude.ai/design oturumlarıyla birleşecek, kurucu-manuel adıma
   bitişik.
4. Antrenör-doğrulama listesi kurucu-bekleyen (manuel).
5. Kalan 3 kilit ölçüm bekliyor: hook/uppercut sınıflandırması ·
   footwork referansı · rakip (yapısal olarak çözülemez).

---

## 2026-07-30 (gece, tur 5) — SHIP DENETİMİ: beyan yerine koşum çıktısı

**Kapanış:** `main` @ `22dc30e`, origin ile eşit, ağaç temiz.
**110 engine + 65 Flutter** yeşil, `analyze` 0.

### Kanıt artefaktı (J-070)

`docs/gates/FITNESS-SHIP-KANITI.txt` **elle yazılmadı** —
`test/fitness_ship_audit_test.dart` koşumunun stdout'u. J-062'de yazdığım
"Fitness şimdi çıkabilir" beyanının yerine bu geçiyor.

**9/9 canlı süreli ders uçtan uca yürüdü.** Her ders için: açılıştan derse
ulaşım · 4 aşamalı akış · saatin beyan edilen yapıyı koşması · çalışma
süresinin kendi kapısına birebir eşitliği · kaydın yazılması · ilerleme
sayfasında görünmesi + hüküm bantlarının hâlâ susması.

**Kapsam içerikten sürülüyor** — ders listesi teste elle yazılmadı. Yeni ders
denetime kendiliğinden girer; bir ders beyanından farklı koşarsa denetim
kırılır. J-062'nin tekrarı artık yapısal olarak imkânsız.

### Eksik envanteri — üç sınıf, docs/70 §7 ile hizalı

`docs/gates/FITNESS-SHIP-EKSIK-ENVANTERI.md`:
- 🔴 **Sınıf A KAMERA** — Fitness için kalan TEK sınıf. §7'nin 8 canlılık
  kalemi JabLab karşılıklarıyla eşlendi. Köprü gelince açılacak 7 kalem
  isimli. ⚠️ İlerleme kapıları retroaktif değil.
- 🟡 **Sınıf B ÖLÇÜM** — 3 kilitli ders kamerayla açılmaz. `counter`
  yapısal olarak çözülemez.
- 🟢 **Sınıf C ÜRÜN/TASARIM** — kod beklemiyor.

**SessionStore delta-notu** envanterde: Choreia ikinci tüketici; üçler
Lissom'da tetiklenecek. Kritik ayrım yazılı — `IntervalPlan` son
toparlanmayı toplama katar, `RoundPlan` son dinlenmeyi katmaz.

### Açık — yeni oturumun işi

1. **Kamera köprüsü** (ADR-002, koordinatör kuyruğu) — JabLab shell'i
   köprünün doğal ilk cihaz-harness'ı (docs/70 §7 notu). Fitness için kalan
   tek sınıf; envanterdeki eşleme hazır girdi.
2. UI tasarım boşlukları (Sınıf C) — claude.ai/design oturumlarına bitişik.
3. Antrenör-doğrulama listesi kurucu-bekleyen (manuel) — jab referansı
   `attested-provisional`, 4./5. eğitmenle eklem tablosu yeniden hesaplanır.
4. Sınıf B ölçüm işleri: hook/uppercut sınıflandırması · footwork referansı.
5. SessionStore çekirdek-terfisi: Choreia portu bitince arayüz farkı
   gelirse bana.

---

## Tur 6 kapanışı — kamera köprüsü canlılığı + Sınıf B ölçümü (2026-07-30)

### Kamera köprüsü (J-071/J-072) — DERLENİYOR ✅ · CİHAZDA ÇALIŞIYOR ⏳

İki beyan ayrı tutuldu ve karıştırılmadı. `motion_camera` tag-pinli bağlandı,
iki platformda İLK KEZ derlendi (§7.1-7.2). iOS'ta **iki gerçek Swift kırığı**
bulundu — pod'un KENDİ başlıkları okunarak düzeltildi, tahminle değil.
Android APK açılarak pin doğrulandı (varsayılmadı).

Emülatör smoke: 40 s, 1126 zarf, `judgedRatio` 0,810 — ailede ilk kez ölçüldü.
**Ama `no-person passes = 1126/1126`:** model 1126 kez koştu ve her seferinde
kimseyi görmedi. Akan şey TESİSAT; poz doğruluğu hakkında hiçbir şey
ölçülmedi. Bu ayrım `docs/gates/KAMERA-KOPRUSU-CANLILIK.md`de korunuyor.
Yol boyunca **gerçek bir ürün boşluğu** çıktı: plugin izni bilinçli olarak
istemiyor, harness de istemiyordu → cihaz gününde aynı yerde patlayacaktı.

### Sınıf B ölçümü (J-073/074/075) — ölçüm "HAYIR" dedi

Koordinatör çerçevesi: önce sınıflandırıcı değil ÖLÇÜM. Uyuldu — eşik
önerilmedi, sınıf tasarımı yapılmadı.

**Bulgu 1 — yanlış-pozitif, kilit gerekçesinden daha kötü.** Bir lead-hook
öğretim videosunda FSM `{jab: 3, cross: 3}` TAMAMLANDI üretiyor ve
`unclassified_strike` 6/6 kez hiç tetiklenmiyor. Kanca "sayılıyor ama
sınıflandırılmıyor" DEĞİL — jab/cross diye **yanlış sayılıyor**. Kilit yerinde
kaldı, gerekçe ölçülen gerçeğe çekildi (`technique-coverage` →
`technique-misclassified`); ship-kanıtı artefaktı bayat kalmasın diye yeniden
üretildi.

**Bulgu 2 — katalog nicelikleri ayırmıyor.** `shoulderRotation` Δ 10,0° vs
10,6°; `trunkLean` kancada daha DÜŞÜK; `elbowFlare` iki jab eğitmeni arasında
61,5°↔97,0° → **eğitmen-arası yayılım teknik-arası farktan büyük**, sınıf
sınırı koyacak yer yok. Katalog-dışı ilk aday da ayırmadı, ölçülen yön
hipotezin tersi.

**Bulgu 3 — kapsam sınırı örtülmedi.** hook 1 kaynak, uppercut **0** kaynak →
"iki yumruk tipi" kıyaslaması yapılamadı. Doküman "imza yok" demiyor, "bu
ölçüm setinde görünmüyor" diyor.

**İki kendi-kusurum kayıtta:** pencereler 0,47-3,97 s ile tek yumruk değil
(bir sonraki ölçümün ön koşulu) · `wrist.pathOverNet` ill-conditioned.

### Açık — yeni oturumun işi

1. **GERÇEK CİHAZ §7.3-7.7** (kurucu-manuel) — ilk iş iOS cihaz paketleme
   codesign engeli. `motion_camera` 0.1.2 README düzeltmesi canlılık gününde.
2. Sınıf B sırası: pencere tanımını sıkılaştır → fixture tabanı (hook ≥3
   eğitmen, uppercut ≥1) → ancak sonra sınıf tasarımı. Ters sıra, ölçülmüş
   yanlış-pozitifin üzerine eşik kurmak olur. `footwork_combo` referansı ayrı;
   `counter` yapısal olarak çözülemez.
3. UI tasarım boşlukları (Sınıf C) — claude.ai/design oturumlarına bitişik.
4. Antrenör-doğrulama listesi kurucu-bekleyen (manuel).
5. SessionStore çekirdek-terfisi: Choreia portu bitince arayüz farkı bana.

### Tur 6 EKİ — kendi bulgumu düşürdüm (J-076/077/078)

Pencere-sıkılaştırma işini yaparken J-073'ün manşeti çöktü. **İki iddiam da
fazlaydı:**

1. "Hook jab/cross diye yanlış sayılıyor" → **kanca GÖRÜNMEZ.** Atladığım iki
   sayı: **0 yarıda-kesilme** (kanca `GUARD_READY→EXTENSION`'ı hiç
   tetiklemiyor) ve **yoğunluk** (24,8 dk'lık kanca dersi onlarca kanca içerir;
   FSM 6 olay verdi — yanlış sayılıyor olsaydı düzinelerce olurdu).
2. "Katalog nicelikleri hook↔jab ayırmıyor" → **ölçülemedi.** Doğrulanmış tek
   bir kanca olayım yok. **"Kanca videosu" ≠ "kanca olayı"** — sol kolonu kanca
   sanıp jab'la kıyaslamak, jab'ı jab'la kıyaslamaktı.

Ürün metni ölçülene çekildi (`technique-invisible`; kullanıcıya görünen
`notMeasured` satırı dahil). J-073 satırı DEFTER'de silinmedi, "manşeti
düzeltildi" diye işaretlendi — yanlış iddianın kaydı da kanıttır.

**Pencere bandı** (jab n=14): sıkı pencere `EXTENSION→GUARD_RECOVERED`
p10 234 · medyan 334 · p90 467 ms · [167…501]; gevşek pencere 434…3937 ms.
"~0,3-0,5 s" tahminim tuttu ama **yeni bulgu değildi**: `extensionMs`in kendi
doküman notu (M-F-91) tuzağı ve çözümünü zaten yazıyordu.

**Aile kuralı reçetesi** yazıldı (`motion-core/workspace/FALLBACK-CANLILIK-RECETESI.md`)
ve düzeltme onu daha iyi yaptı: fallback'in ölü olmasının **iki** mekanizması
var (A yanlış-sınıflama / B görünmezlik) ve **ayırt eden sayı abort
sayacıdır** — tam onu atlayıp B'yi A sanmıştım.

**Hasat turu şartı değişti:** kanca fixture'ları **olay zaman damgalarıyla**
gelmeli. Ucuz ara adım: mevcut 6 damgayı (265,2 · 481,5 · 625,9 · 859,5 ·
882,4 · 1113,7 s) kurucu gözüyle doğrulamak.

### Tur 6 EKİ-2 — Sınıf C: dürüst hata ekranı (J-079/080)

Cihaz sinyali beklenirken kod-beklemeyen Sınıf-C kalemi alındı. Üçünden
bunu seçtim çünkü diğer ikisi (onboarding, öğretici yuva) tasarım comp'u
ister; bu ise saf yapı ve bugün gerçek bir kusur.

**Kusur kayıtta yazandan sinsiydi.** "Ham crash" deniyordu; gerçekte hata
yakalanıyor ve ekrana `'$_error'` basılıyordu — kullanıcı **Türkçe bir
`StateError` gövdesi** görüyordu. "Çökmüyor" ≠ "dürüstçe açıklıyor".

Yapı: tipli hata (`ContentIntegrityException` + `ContentFailure.from`), iki
sınıf — **integrity** (retry yalan) / **unreadable** (retry anlamlı). Sınıfı
hata METNİNDEN çıkarmak reddedildi. Ekranda kaçış kapısı YOK; geliştirici
ayrıntısı gizlenmedi, katlandı.

**J-080 — iki kendi hatam, ikisi de "test sahte geçebilir":** asset kanalı
taklidi çalışmadı (kanal font/manifest'i de taşıyor) ve ara-teşhisim ölçümle
düştü → dar dikişe geçildi · **testin en kritik iddiası bedavaya geçiyordu**
(`BottomNavigationBar` aranıyordu, kabuk M3 `NavigationBar` kullanıyor).
Yakalatan şey: aynı iddianın POZİTİF simetriğini yazmış olmam.
**Kural adayı: her "X yok" kapısının yanına "X var" kapısı yazılmalı.**

UI-BRIEF §3.3 + §4/3 güncellendi: tasarımcıya kalan iş yalnız GÖRSEL DİL.

---

## 🔒 VARDİYA KAPANIŞI — 2026-07-30

Kurucu direktifiyle tüm oturumlar sonlandırılıyor; devir tek dosyada:
`workspace/YENI-OTURUM-PROMPT.md`. Bu vardiyada JabLab çekirdek ürün işini
bitirdi (Fitness 4/4 ship-proof, kamera köprüsü §7.1-7.2, dürüst hata
ekranı) ve aileye 4 motion-core dalı bıraktı (hepsi main'de). Ayrıntı
DEFTER J-071→J-091 + tur/hasat dokümanları. Kod tarafında açık iş yok;
kalan her şey insan eli (D3 göz-doğrulaması, gerçek cihaz koşumu).

---

## 🔒 VARDİYA KAPANIŞI — 2026-08-06 (design turu, Faz 1 + Faz 2 kısmi)

DEFTER J-097+J-098. **Faz 1 TAM:** 4-sekme kabuk (`ShellScaffold`) kalktı,
Sayfa A(Seçim)/Sayfa B(Kurs)/Sayfa C(Ders, dokunulmadı)/Ayarlar köşesi
kondu (koordinatör Hüküm 1/2/3). `lib/shell_candidate/` DOKUNULMADI —
motion_shell'e (5 app ortak paket, hiç doğmadı) terfi adayı olarak
DONDURULMUŞ envanter; JabLab artık çağırmıyor ama silmedi, README+DEFTER'e
M-F-267 sınıfı şerh düşüldü. **Faz 2 KISMİ:** yalnız Ayarlar köşesi
tasarım tokenlarıyla (OKLCH renk, buzlu cam, iki-tipografi) giydirildi;
bu sırada iki GERÇEK Flutter kalıp-hatası bulundu ve düzeltildi (Gravita'nın
`ClipRRect`↔gölge tuzağı kendi kartımda + Lissom/Ostinato'nun 375pt
taşma dersi `course_page.dart`da gerçek bir `ListTile` çökmesi yakaladı —
kalıcı regresyon testi bırakıldı). 8↔5 dürüst-hâl ölçümü motor kaynağına
kadar indi, sonuç koordinatöre raporlandı, hüküm bekleniyor.

**Kapanış artefaktları:** `docs/design/DESIGN-AHEAD-OF-CODE.md` ·
`docs/design/PLACEHOLDER-REGISTER.md` (+ üreteç `tool/gen_placeholder_register.dart`)
· `docs/design/UYUM-DENETIMI-2026-08-06.md` (yalnız Ayarlar kapsamı, 0 ihlal).

**Kod tarafı:** main `1a5a565`, push edildi, ağaç temiz, 145/145 test yeşil.
**Açık:** ders ekranı + Sayfa A/B görsel giydirme + 8↔5 hâl hükmü — AYRI
tur, devir metnini koordinatör yazacak (`YENI-OTURUM-PROMPT.md`'ye bu
vardiyada dokunulmadı, kasıtlı). **BEKLEME MODU.**

---

## Parça 2 kapanışı — 2026-08-06 (kurucu kararıyla AYNI oturumda devam)

DEFTER J-100. Kurucu 4 parçayı (ders ekranı → Sayfa B → Sayfa A → kapanış)
AYNI oturumda sürdürme kararı verdi — devir yok, `YENI-OTURUM-PROMPT.md`ye
dokunulmadı. Risk-azaltma protokolü: her parça sonunda commit+push, kalite
düşerse temiz durulacak.

**J-099 kapandı:** `_suppressionSentence` çeviri katmanı — `quality:`/
`structural:` önekleri gerçek `cue.` metnine, `torsoUnreliable` ayrı
hardcoded cümleye yönleniyor. 2 gerçek-motor testi (torso/wrist,
`SyntheticNoise.occlude` ile GERÇEK `StrikingEngine` üzerinden tetiklendi).
`structural:` dalı canlı hatta motion_core mimarisi yüzünden erişilemez
bulundu (bkz. DEFTER J-100) — savunma amaçlı korundu, aile-geneli olabilir.

**İskelet overlay GERÇEK** (placeholder değil) — `LiveJabController`
motorun ürettiği `PoseLandmark` listesini artık dışa veriyor,
`skeleton_overlay.dart` bunu 12-kemikli bir çizime çeviriyor. Kamera
GÖRÜNTÜSÜ hâlâ ayrı, bilinçli PLACEHOLDER — register'ın ilk gerçek girdisi.

**Tema:** `jablabSessionTheme` frozen kabuğu (`SessionFlowScaffold` ailesi)
`Theme()` sarmalıyla giydiriyor. Simülatörde GERÇEK bir kırpma kusuru
bulundu (aşama rozetleri "Learn"→"Lear") ve düzeltildi — otomatik testler
göremezdi, yalnız ekran kanıtı yakaladı.

**Test-altyapısı düzeltmesi (aile-geneli olabilir):** `google_fonts`in
canlı-ağ indirmesi `flutter test`in `TestWidgetsFlutterBinding`ı altında
her zaman başarısız — Settings/Sayfa A/B testleri bugüne dek yalnız ŞANSLA
(önceden önbelleklenmiş ağırlık) geçiyordu. `test/flutter_test_config.dart`
kalıcı çözdü (binding+HttpOverrides+PathProvider ön-ısınması).

**Kod tarafı:** main `5fc2d65`, push edildi, ağaç temiz, 150/150 test
yeşil, `flutter analyze` proje geneli temiz. **Sıradaki:** Parça 3 (Sayfa B
görsel giydirme).

---

## Parça 3 kapanışı — 2026-08-06/07

DEFTER J-101. `course_page.dart` design_tokens.dart tokenlarıyla giydirildi
— davranış/key'ler değişmedi, yalnız görsel katman. Tier seçimi bilinçli:
geçmiş okunamadığında VE K8 bantları kalibre edilmediğinde ikisi de
`UnknownGlassPanel` (Tier 2-d "bilmiyorum") — iki hâl de o katmanın rezerve
ettiği anlamla TAM örtüşüyor. `GlassIconButton` paylaşıma çıktı
(design_tokens.dart) — Ayarlar'ın kendi kopyası silindi.

**Gerçek regresyon yakalandı ve düzeltildi:** özel geri-butonunun tooltip'i
yoktu, `tester.pageBack()` (pre-existing `fitness_ship_audit_test.dart`)
bunu arıyor. `tooltip: 'Back'` eklendi — yalnız test-uyumu değil, gerçek
erişilebilirlik boşluğuydu.

**Kod tarafı:** main `4945895`, push edildi, ağaç temiz, 150/150 test
yeşil (0 yeni/0 düşen — yalnız görsel), `flutter analyze` temiz. Simülatör
kanıtı: Foundations (kilitsiz) + Intermediate (kilit ayrışması net).
**Sıradaki:** Parça 4 (Sayfa A görsel giydirme) — SON parça.

---

## 🔒 VARDİYA KAPANIŞI — 2026-08-06/07 (design turu, 4 PARÇANIN TAMAMI)

DEFTER J-102 (+ J-100, J-101). Kurucunun "4 parçayı AYNI oturumda sürdür"
kararı tam uygulandı: yıldız ekran → Sayfa B → Sayfa A, üçü de kendi
commit'iyle push edildi, hiçbir parça yarım bırakılmadı, kalite hiç
düşmedi — "İSİMLİ DUR" protokolü hiç tetiklenmedi.

**Dördü de `design_tokens.dart`nin AYNI kaynağından besleniyor** — tek bir
palet/tipografi/glass-tier sözleşmesi, dört ekranda tekrar. Frozen paylaşılan
bileşenler (`SessionFlowScaffold` ailesi, `HonestyBox`) `Theme(data:,
child:)` sarmalıyla dışarıdan giydirildi, hiçbiri İÇERİDEN değiştirilmedi.

**Dördü de en az bir GERÇEK kusur yakaladı ve düzeltti — yalnız görsel
cila değil:**
- J-099: `LiveJabController`in ham `suppressionReason`u canlı ekrana
  sızdırması (doc-75/5'in üçüncü, hiç yakalanmamış vakası).
- Aşama-rozeti kırpması ("Learn"→"Lear") — `Chip`in `labelLarge`i
  narration'la paylaşması, yalnız simülatörde görülebilirdi.
- `tester.pageBack()` regresyonu — özel geri-butonunun `tooltip: 'Back'`i
  yoktu, hem test hem GERÇEK erişilebilirlik boşluğuydu.

**İKİ bulgu aile-geneli olabilir, koordinatöre raporlandı:**
`OrientationAwarePoseSource`un motoru gölgelemesi (motion_core mimarisi) ·
`google_fonts`un `flutter test` altında her zaman başarısız olan canlı-ağ
indirmesi (`flutter_test_config.dart` kalıcı çözdü).

**Kapsam dışı KALAN, bilinçli:** `WhyNotPage`/`ContentFailureScreen`/
`CameraHarnessScreen` (frozen/dev-only) hâlâ genel temayla render ediyor —
tutarsızlık değil, bu turun sınırı. 8 dürüst-hâlin alt-sebeplerinin GÖRSEL
ayrışması (renk/ikon) da bilinçli açık — koordinatöre soru bırakıldı.

**Kapanış artefaktları:** `docs/design/UYUM-DENETIMI-2026-08-06.md`
GENİŞLETİLDİ (6 eski N/A satırı gerçek sonuca döndü — 0 ihlal, 0 N/A
kalan, 2 belirsiz/açık değişmedi) · `PLACEHOLDER-REGISTER.md` doğrulandı
(1 kayıt, değişmedi) · `DESIGN-AHEAD-OF-CODE.md` Parça 2'de güncellendi.

**Kod tarafı:** main `e939a2f` (+`5fc2d65`+`4945895`+`7d6e707` bu turun
diğer 3 kod commit'i), push edildi, ağaç temiz, 150/150 test yeşil, `flutter analyze`
proje geneli temiz. **Açık kalemler (kod tarafı DEĞİL, kurucu/koordinatör
kararı bekliyor):** portrait-kilidi uygulanmadı (⑰) · 8 alt-sebebin görsel
ayrışması (⑮) · `cue.coached_not_scored` çelişkisi (J-098'den beri açık) ·
kardeş-ayrışması yalnız tek-yönlü doğrulanabildi (⑱). **BEKLEME MODU —
devir metnini koordinatör yazacak.**

---

## 🔒 VARDİYA KAPANIŞI — 2026-08-12 (ölçüm + kapı turu · J-206…J-223)

**Giriş `41c0afd` → Çıkış `005cd13`** · `main` = `origin/main`, ağaç temiz.
**17 commit**, hepsi kendi commit kapısından geçti (analyze + app + motor,
borusuz). **app 285/285 → 323/323 · motor 125/125 · `flutter analyze` temiz.**

### Bir cümleyle

Bayat bir sevk satırından (*"onboarding beş hatta da YOK"*) başlayıp; o
satırın **doğduğu gün** yanlış olduğunun ölçülmesine, kapı sisteminin
**tüketicisinin hiç yazılmamış** olduğunun bulunmasına, **dört canlı yalanın**
düzeltilmesine (kamera izin metni ×3 yüzey · tempo · puanlama tier'ı ·
`google_fonts` ağ iddiası), **11 dosyada gizli bir test yarışının**
kapatılmasına ve yayın-engeli denetiminin **yönteme dönüştürülmesine** uzanan
bir tur.

### Kod tarafı — sevk edilenler

| commit | iş |
|---|---|
| `4a98e2c` | gezilebilirlik: gevşek sayı (11) artık **yürünerek** kapılı; onboarding zaten vardı |
| `edbc3f7` | ratio-sınıfı 9 kapı da üreticisiz + **kapı sisteminin tüketicisi yok** |
| `ca9fbe8` | **ilerleme kapısı tüketicisi** (koordinatör hükmü B) — üçüncü hâl tip düzeyinde |
| `684c1f7` | kamera izin metni — 4. canlı yalan, **iki yüzeyde** |
| `635e278` | mağaza taslağı: **27 iddia denetimi**, 3 kök düzeltme |
| `d472e0e` | gizlilik manifestinin atfı **kaynağa** bağlandı |
| `f8e8288` | release **sessizce debug anahtarıyla imzalanamıyor** |
| `69f1681`·`639b5a9` | **yayın-engeli denetim YÖNTEMİ** + kendi kapısı (12 kalem) |
| `5ed601a` | **bağımlılık bölmesi** + kendi yazdığım fazla-geniş iddia düzeltildi |
| `6580d07`·`390fb28` | **kararsız kapı** çözüldü + 11 dosya + regresyon kapısı |
| `1ead32e` | yöntem 13-14. kalem · şablon kalemleri **HASH**'le |
| `9fa3956` | **gezilebilirlik sayma kuralı** yazıldı ve kapıya bağlandı |
| `005cd13` | yöntem 15. kalem · **⑨ düzeltildi** (ASC kaydı VAR) |

### Yayın engeli — ölçülmüş hâl

**hat-yereli 0 · çekirdek 0 · kurucu 6.** Kod tarafında yayına engel yok.
⚠️ **Ama ⑪ sürüm kaleminin SINIFI değişti:** ASC sürümü **`1.0`**, pubspec
**`0.1.0+1`** → aile ölçümü **4/5 hat ayrışık** (yalnız Ostinato hizalı).
Bu bir *beyan* değil **gönderim blokajı**: eşleşmeyen kısa sürüm dizgesiyle
üretilen build o ASC sürümüne **iliştirilemez.** ⛔ Sürüme **dokunulmadı** —
*"beş uygulama hangi sürümle çıkıyor ve bunu kim seçti"* kurucu kalemi.
📌 `AFTER_APPROVAL` **canlı** (ölçüldü): gönderilip onaylanırsa **kimse
düğmeye basmadan yayımlanır.**

### Bu turda ÜÇ kalem İKİYE bölündü

imza (**keystore**=kurucu ↔ **yapılandırma+kapı**=hat) · ③b (**okuma**
erişilebilir ↔ **yazma/gönderim** kilitli) · ⑪ (**numara** ↔ **yüzey
ayrışması**). → ***Bir kalemin bölünebilmesi, yanlış sınıflandırıldığının
işaretidir*** — üçünde de bir yarı hat-yereli çıktı ve *"erişim bekliyor"*
diye bekletiliyordu.

### Adıyla açık bırakılanlar

* **Kör nokta korumasız:** gezilebilirlik envanteri *yürüyüş* tabanlı —
  ulaşılabilir ama kimsenin gitmediği ekranı **görmez.** Bir kez ölçüldü,
  boş çıktı (J-206), **ama o tarama kapılı değil.**
* **B-sınıfı sabit gecikmeler (10 site):** dokunuş sonrası gerçek-zaman
  bekleyen testler; **farklı amaç, farklı panzehir** — dokunulmadı.
* **⑤. katman** (koşul gerçek veriye karşı TRUE oluyor mu) ve
  **`gateable`nin dar tanımı** — önceki turlardan, kapanmadı.
* **Olay sayısının kalıcılığı** — çekirdek turunda; *yetenek gediği,
  yayın engeli değil.*

### Bu turun kendine dönen dersi

Dört ayrı yanlış iddianın **üçü bana aitti ve üçü de "ölçüm" gibi
görünüyordu**: fazla geniş kapsam (`google_fonts`), devralınmış iddia (ASC
kaydı), yanlış atıf (JDK'yı NDK sanmak). ***Ölçümün doğru olması, ondan
kurulan cümlenin doğru olduğunu göstermez*** — ve bu farkı yakalayan şey her
seferinde bir **kapı** ya da bir **aile taraması** oldu, kendi dikkatim değil.

---

## 🔒 OTURUM MÜHRÜ — 2026-08-12 kapanışı

**HEAD** `4e64dc7` · ağaç temiz · `HEAD == @{u}` · `--no-verify` **hiç kullanılmadı**
(bir kez kapı gerçekten durdurdu ve **uyuldu**: `J-095`+`J-105` kırmızısı,
düzeltilip yeşile döndürülerek açıldı).

**Kapılar:** analyze **0** · app **332/332** · motor **125/125** · öz-test **2×0**
· defter tazeliği **0** (`A=14 · B=15 · C: 239/239/239 çakışma 0 · gedik 0`).
**DEFTER:** 238 → **239 kayıt**, bu oturumdan **34** (J-206…J-239).

### Bugün ne KAPANDI

Gezilebilirlik ölçüldü ve gevşek sayı kapıya bağlandı · kapı-sistemi
**tüketicisi** yazıldı (üçüncü hâl tipçe zorunlu) · dört canlı yalan
düzeltildi · 11 dosyalık kararsızlık süpürüldü + regresyon kapısı ·
yayın-engeli denetimi **15 maddelik YÖNTEM**e çevrildi · defter tazeliği
kapısı (ve `J-171`i buldu) · Türkçe kip kapısı · çıkmaz-sokak ölçümü
`30 = 20 + 10 + 0` · gezilebilirlik sözleşmesi (a)–(e) · kapalı-kayıt
envanteri · **4 reddedilmiş yol `Durum` sütununda kalıcı** · defter kapısına
**katman + benzersizlik çapası** · **payda dosyaya yazıldı**
(`tool/defter_inventory.py`) · `J-095` gövdeden kuruldu · `J-105` çakışması
niteleyiciyle çözüldü.

### Ne KAPANMADI — ve sebebi ÖLÇÜLDÜ mü

| kalem | sebep | ölçüldü mü |
|---|---|---|
| Sözleşme **(b)** `NavigatorObserver` yok; denklemdeki `walked` **elle sabit**, yürüyüşün çıktısı değil | sevk *ölçüm+yazım*dı, düzeltme yasaktı | ✅ J-239 |
| Sözleşme **(d)** bölme denetimi ~~**totolojik**~~ → **GÖLGELENMİŞ** (`unreachable = derived − walked`) | aynı sevk sınırı · ⚠️ *"totolojik" nitelemesi J-241'de ölçümle düzeltildi: dişi vardı, komşuları önce ötüyordu* | ✅ J-239 → **kapandı J-241** |
| Sözleşme **③** soğuk açılış **atlanıyor** (`onboarding: seen`, `reached` tohumlu) | testler bilerek bölündü, **bölünce bağlanmadı** | ✅ J-239 |
| **(a)** tek türetim kanalı · **(c)** 6 gerekçenin 5'i **beyan** | ölçüldü, kapsam kararı koordinatörde | ✅ J-239 |
| Gezilebilirlik **kör noktası** (ulaşılabilir ama yürünmemiş ekran) korumasız | bir kez ölçüldü boş çıktı, **tarama kapılı değil** | ✅ J-206 |
| B-sınıfı **10 sabit gecikme** | farklı amaç/panzehir, *tek sınırlı geçiş* sınırı | ✅ J-218 |
| **BÜYÜK KİP** Türkçe (`YAKINDA` saf ASCII) kapıya görünmez | kapatmanın tek yolu sözlük ya da her ASCII deseni şüpheli saymak | ✅ J-229 |
| **⑤. katman** · **`gateable`** dar tanımı | önceki turlardan devir | ⛔ ölçülmedi |
| Olay sayısının **kalıcılığı** | **çekirdek** kararı, hat-yereli değil | ✅ J-208 |
| `workspace/` **sürüm kontrolü dışında** (4 "kalıcı" hüküm hücresi dahil) | yapı kararı, kurucu kuyruğunda | ✅ J-236 |

### Bu turun kendine dönen dersi

Bugün beni **beş kez** kendi kapılarım/ölçümlerim yakaladı, dikkatim değil:
totolojik denetim (iki ayrı dosyada, aynı gün) · inmeyen mutasyonu
"kapı ötmedi" sanmak · canlı kusura dayanan pozitif kontrolün kusur
düzelince yanlış alarma dönüşmesi (iki kontrolde) · yeniden üretilemeyen
payda · ve sözleşmeyi **adına** karşı doğrulamış olmak.

> ***Bir kuralı en çok savunan hat, onu uygulama anında düşürmeye en yakın
> olandır — çünkü kuralı BİLMEK, onu o an ÇALIŞTIRMAK değildir.***

---

## 2026-08-13 — Sözleşme **(d)** kapandı: bölme denetimi yönlendi, ve hüküm ölçümle düzeltildi (J-241)

**Sevk:** J-240'ın adıyla bıraktığı tek açık kalem — *"(d) bilerek ellenmedi, toplam-assert hâlâ totolojik"* (koordinatör sırası ②).

### Önce ÖLÇÜLDÜ, sonra düzeltildi — ve ölçüm sevk cümlesini çürüttü

J-239 (d) için *"tanım gereği hiç ötemez"* demişti. Düzeltmeye başlamadan
mutasyonla sınandı; **sınır fazla genişmiş**:

| mutasyon | ilk kırmızı | hüküm |
|---|---|---|
| `M1` yürüyüşe türetimde olmayan sınıf, komşular **yerinde** | `yürünen küme ile katı sayı ayrışmış` | assert **ötmedi** |
| `M2` kayıttan bir varılamayan silindi | `ADAY olup VARILAMAYAN küme DEĞİŞTİ` | asıl denetim **(c) eşitliği** |
| `M3` aynı ghost + **üç komşu kapatıldı** | `payda TOPLAMIYOR` | assert **gerçekten öttü** |

→ Kusur **totoloji değil GÖLGELENME**. Dişi vardı (`walked ⊆ derived` yönü),
komşuları (`knownFloor ⊆ walked` · `|walked| == kStrictRoutes` · (c) eşitliği)
her seferinde **önce ve daha isabetli** ötüyordu.

> ***Bir assert'in yeşilliği, ötme yeteneğinin değil KOMŞULARININ kanıtı
> olabilir*** — ve *"hiç ötemez"* demek, ötme koşulunu aramayı durdurur.

### Asıl kusur RAPORDAYDI

Cümle *"payda TOPLAMIYOR — bir aday hiçbir kovaya girmemiş"* diyordu; oysa
`unreachable := derived − walked` olduğu için **o kusur tanım gereği
oluşamaz** (M2 gösterdi: onu (c) yakalıyor). Satır, sınadığı şeyi değil
**sanılan şeyi** anlatıyordu.

### Yapılan

- **Yön adıyla sınanıyor:** aritmetik yerine `expect(walked.difference(derived), isEmpty)`,
  gerekçesi **(a)'nın kör noktasının tam adı** — *`Scaffold`unu ortak kabuğa
  devreden ekran aday olmaz ama yürünebilir.* Ötüşü `N2` ile kanıtlandı.
- **⭐ Yönün bugün ölçülemez olduğu İLAN EDİLDİ, sahte kapıyla örtülmedi:**
  taban == yürüyüş olduğu sürece ihlal kurulamaz; kapı her koşumda
  `(d) YÖN · "walked ⊄ derived": GÖLGELİ (yürünen 6 · taban 6)` basıyor ve
  yürüyüş tabanın üstüne çıktığı gün **CANLI** diyecek.
- ⛔ `walked == knownFloor` **assert edilmedi** — (e) tabanı bir ALT SINIRDIR,
  eşitlik yazmak onu envantere geri çevirirdi (J-233 korundu).
- **Denklemin iki yanı ayrı kaynağa bağlandı:** `türetilen 12 (kod deseni) =
  yürünen 6 (tanıklı yürüyüş) + varılamayan 6 (elle kayıt, gerekçeli)`; sağ
  taraf çıkarmayla değil **kayıttan** okunuyor. Sayı değişmedi, **neyle
  kanıtlandığı** değişti.

### Kapılar

`flutter analyze` 0 · `dart analyze` 0 · app **330/330** · motor **125/125** ·
mutasyon `N0` sessiz / `N1` gölge doğrulandı / `N2` yeni assert öttü / `N3` (c) öttü.

### Açık kalanlar (dokunulmadı, bilerek — koordinatör sırasında)

- **(a)** tek türetim kanalı (Ostinato'nun *iki bağımsız türetimin uzlaşması* yok).
- **(c)** 6 gerekçenin **5'i hâlâ beyan** — denetim yalnız uzunluk (`>25`) sınıyor.

## 2026-08-13 — Sözleşme **(c)** kapandı: gerekçeler yüklem oldu — ve yolda **canlı bir sessiz-yeşil** bulundu (J-242)

**Sevk:** J-241'in açık bıraktığı kalem — *"6 gerekçenin 5'i hâlâ beyan, denetim yalnız uzunluk sınıyor."*

### Yapılan

Altı `unreachableWhy` kaydının her biri artık kaynak ağacına karşı koşan bir
**yüklem** taşıyor; parite assert'i yüklemsiz kayıt bırakmıyor. Uzunluk kapısı
**silinmedi** — taban olarak kaldı, ölçüm üstüne bindi.

### 🔴 Ve ölçüm sırasında canlı bir sessiz-yeşil çıktı (P7)

Kamera kapısı kaynaktan **gerçekten sökülüyken** (`if (true)`), dosyaya düşülen
tek bir `// CameraHarnessScreen.isAvailable` **yorumu** yüklemi yeşil geçirdi —
hem de J-239'un *"tek ölçülü gerekçe"* dediği yüklemde.

> ***Bir kaynağı METİN olarak tarayan ölçüm, o metnin ÇALIŞAN kısmıyla ANLATAN
> kısmını ayırmıyorsa, kod hakkında değil DOSYA hakkında konuşur.***

Panzehir: tüm tarama **yorum sökülmüş** kopyadan besleniyor, sökücünün kendi
pozitif kontrolüyle. `P7` artık kırmızı, `P8` (salt yorum enjeksiyonu) etkisiz.
📊 **Δ0 ölçüldü:** yorum sökülünce aday sayısı **12 → 12**.

### 🪤 Panzehir kendi kanıtını çürüttü

`P2`/`P4`/`P6` ilk turda yorum enjeksiyonuyla ötmüştü; sökücü gelince o üç
kanıt **geçersiz** oldu. Üçü kod düzeyinde yeniden alındı (`P2'` gerçek rota ·
`P4'` gerçek rota · `P6'` import+typedef).

> ***Bir kapıyı güçlendiren düzeltme, o kapının ötme kanıtını geçersiz
> kılabilir — kanıt düzeltmeden SONRA yeniden alınır.***

### ⭐ İkinci bağımsız kanal — ve (d)'nin gölgeli yönünün gölgesiz karşılığı

Rota hedefleri (`MaterialPageRoute(builder: … => X(`) ikinci bir kanal; aday
kümesi yapısal (`Scaffold(`). `routed ⊆ derived` kapılandı: bir sınıf rota
hedefiyse ürün onu ekran sayıyordur, aday değilse desen **kördür** — (a)'nın
adı konmuş kör noktası, ve burada **gölgesiz** ölçülüyor (`P9` ötüşü kanıtladı).

⛔ Ters yön bilerek istenmedi (`derived ⊄ routed` meşru: kök takaslı ekranlar
hiç `push` edilmiyor). ⚠️ **(a) KAPANMADI** — aday kümesi hâlâ tek kanaldan
türüyor; kurulan şey uzlaşma değil, tek yönde çelişki dedektörü.

### Kapılar

`flutter analyze` 0 · `dart analyze` 0 · app **330/330** · motor **125/125** ·
mutasyon **9/9 adıyla öttü**, `P0` sessiz.

### Açık kalanlar

- **(a)** aday kümesi tek kanaldan türüyor — *iki bağımsız türetimin uzlaşması* yok.
- ⛔ `codeOnly` bir ayrıştırıcı değil: içinde `//` geçen **dizge sabiti** taranan
  kopyada kırpılır. Kapanmadı, **adıyla** duruyor.

## 2026-08-19 — SOLO rejimi altında dört P0 kapandı + Footwork kursu

**Bağlam:** 14-oturumlu orkestrasyon modeli bugün kurucu kararıyla iptal edildi (oturumlar
silindi, koordinatör posta kutusu artık kaynak değil); bu tur **v3 SOLO model**in ilk JabLab
çalıştırması — roadmap aynı (`21-JABLAB-MASTER-ROADMAP.md`), ama orkestrasyon/mesajlaşma yok.

### JAB-P0-001 — canonical shell, iddia gerçeğe karşı ölçüldü

Roadmap'in "shell_candidate ölü" beyanı yanlış ölçüldü: 6 semboldan 4'ü zaten üretimde
(`reachable_screens_test.dart`'ın `Scaffold(` arama deseni onları görmüyordu ya da `CoursePage`
isim çakışmasıyla yanlış-pozitif kapsıyordu). Yeni `canonical_shell_reachability_test.dart`
(13 test) `docs/evidence/production-line/baseline.json`ı çalışma-zamanında okuyor — üç katman
(A paylaşılan/B ekran/C sözleşme) ayrı ayrı doğrulanıyor. Layer A bilerek `lib/app/shell/`e
taşınmadı (aile-çapında `motion_shell` terfisi bekliyor, taşımak çifte-iş olurdu).

### JAB-P0-002 — fast-motion liveness + termal

FPS p10/p50/p95 + YENİ bir termal-durum MethodChannel'ı (iOS `ProcessInfo.thermalState` +
Android `PowerManager.getCurrentThermalStatus()`, ikisi de gerçek derlemeyle doğrulandı,
motion_core/motion_camera pinine dokunulmadı). Blur-bucket mimari olarak imkansız ölçüldü
(kamera zarfı ham piksel taşımıyor) — taklit edilmedi. Apple'ın 5 "gerekli sebep" API
kategorisi canlı sayfadan doğrulandı (WebFetch JS sayfasını okuyamadı, Browser aracıyla
okundu); termal kanal manifest değişikliği gerektirmedi.

### JAB-P0-003 — boxing event validity: gerçek bir dedektör açığı bulundu

Sentetik negatif fixture'lar (`negative_motion_rejection_test.dart`, 8 test) `StrikingEngine`ye
karşı EMPİRİK kalibre edildi (varsayımla değil — `midPose`nin adının "yarı yol" olması onu
güvenli feint fixture'ı sanmama az kalsın yol açıyordu, ölçünce gerçek `extensionRatio`sunun
0,84-0,89 olduğu, yani PEAK eşiğine neredeyse eşit olduğu çıktı).

> ***`extensionRatio` kol düzlüğünü ölçer, yönünü ölçmez.*** Tempolu (250ms) bir kol sallama
> bugün gerçek jab olarak tamamlanıyor; yavaş (500ms) olan doğru reddediliyor. Repo-geneli
> ilk kez ölçüldü.

Düzeltme (yön/vektör kısıtı) bilerek bu turda YAPILMADI — `StrikingEngine`in çekirdek mantığını
değiştiren bir karar, tek taraflı bir fixture turunda alınmaz. `model-gate.json`da P1 adıyla.

### JAB-P0-004 — release CI + privacy + signing

`.github/workflows/checks.yml` Gravita/Lissom'dan uyarlandı (motion-core private-repo erişim
duvarını onlar zaten çözmüştü — `MOTION_CORE_RO_TOKEN`, yoksa no-op). Android
`-PallowDebugSigning=true` kaçış kapısı: bayrak verilmezse hâlâ `throw GradleException` — iki
yönde gerçek Gradle koşumuyla doğrulandı (`android_signing_test.dart`ta 2 yeni test).

### JAB-P1-001 (kısmi) — Footwork kursu, dört gerçek kapıyı ötürdü

30-ders hedefi `lesson_inventory_test.dart`ta `skip:` ile sayıyla çapalandı (izlenebilir,
commit kapısını bloke etmeden). Yeni `boxing.footwork` kursu (2 ders, ikisi de zaten kalibre
edilmiş tespit — FEET_CROSSED/BALANCE_LOSS) eklenince dört ayrı test bağımsız kırmızı çıktı:
vaat-dili ("yet"), eksik ilerleme-kapısı (`[J-038]` — her canlı ders bir kapı taşımalı), ve iki
hardcoded sayım (`progress_gates_test.dart`, `gate_primitive_producer_test.dart`). Hepsi
düzeltildi, sebep-sonuç DEFTER `J-297`de.

### Kapılar

`flutter analyze` 0 · app **414/414 + 1 izlenen skip** · motor (`jablab_engine`) **137/137**.
Commit'ler: `5129328`→`fcd6c79` (7 commit), DEFTER `J-291`→`J-297`. Push doğrulandı,
`origin/main` ile aynı.

### Açık kalanlar

- **JAB-P0-003'ün tempolu-kol-sallama açığı** — ölçüldü, kayıtlı, düzeltilmedi
  (`motion-cv-engineer` danışman turu önerilir; yön/vektör kısıtı gerektirir).
- **JAB-P1-001 Step 2-5** — Defense kursu + Footwork/Combo genişlemesi, HASAT-TURU kaynak
  triyajından geçmedi, gelecek oturuma bırakıldı (kaynak havuzu hazır: `ICERIK-KAYNAK-
  ARASTIRMASI-30-DERS-2026-08-19.md`).
- **EXTERNAL_GATE'ler değişmedi:** 3.000-punch model-holdout (`model-gate.json`), 20dk
  fiziksel cihaz koşumu (`device-matrix.json`) — ikisi de kurucu/insan işi, kod tarafı hazır.
- **`MOTION_CORE_RO_TOKEN` GitHub secret'ı henüz eklenmedi** — eklenene kadar CI'ın `gates`
  işi motion-core'u çekemeyip kırmızı kalabilir (beklenen, yeni bir bozulma değil).
