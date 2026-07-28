# JabLab — Ürün Yol Haritası (G0→G10)

**Tarih:** 2026-07-26 · **Statü:** Kurucu-onaylı çerçeve; oturumlar bu haritayı işler, sapmalar DEFTER'e.
**Hiyerarşi:** `00-AILE-MIMARISI.md` (D2!) > `20-URETIM-SURECI.md` > `10-ARAC-KATALOGU.md` > bu dosya > `jablab-plan.md`.
**Ürün dili: İNGİLİZCE.** Aile sırası **2** (dik vücut ama hızlı hareket).

> ⚡ **REVİZYON 2026-07-26 (kurucu direktifi — KURUCUSUZ VERİ FABRİKASI + GENİŞ KÜTÜPHANE, M-F-13..16):** Bu haritadaki "kurucu çekimi / fixture çekim listesi kurucuya" varsayımları KALDIRILDI — kurucu çekim YAPMAZ. Birincil veri = kamu-video hasadı + sentetik (katalog §6.2; ücretli klip İPTAL — M-F-17); doğrulama = §6.3 merdiveni; öğretim görselleri = §6.4 katmanlı AI-eğitmen hattı (T1 = iskelet-sürümlü uygulama-içi avatar, $0 ve form-garantili). Kurucudan yalnız onay/kapı kararları + EN SONDA (G8'de, deneme amaçlı) cihaz-benchmark'ı beklenir — erken fazlar benchmark'ı BEKLEMEZ. **Geniş kütüphane:** 6 yumruk + savunma + footwork + kickboks/Muay Thai ön-hasadı GENİŞ yürür (Precision Striking/Tony Jeffries/ExpertBoxing ≥3 ✓); J-007 tempo-merdiveni kamu slow-mo taramasıyla (tek-kişi 240fps İNCE — spor-bilim kanalları dahil özel tarama görevi); J-011 cihaz-benchmark'ı kurucuda kalır (beceri gerektirmez). Sorularını bu çerçevede kendin karara bağla — kurucuya soru YOK.

## 0. Dalga tablosu (M-F-18 blueprint'inden işlendi — kapsam otoritesi `docs/JABLAB-BLUEPRINT.md`)

**Ürün adı artık dar değil:** JabLab = *Solo Combat Training* — 8 disiplin, her biri kendi sayfasında. Boks V1; kalanlar dalga dalga.

| Dalga | Kapsam | Yeni motor ihtiyacı | Durum |
|---|---|---|---|
| **V1** | **Boxing** | mevcut faz-motoru (D2 kapılı) | 🟠 W0 sürüyor |
| **W1** | Kickboxing · Tai Chi | **paylaşımlı DTW uzun-sekans motoru** (Tai Chi'de kurulur — blur yok) + tekme sınıflandırıcı v1 | ⏳ |
| **W2** | Karate (kihon+kata) · Muay Thai | duruş-sınıfları + embusen yer-deseni · dirsek/diz/teep sınıflandırıcı | ⏳ |
| **W3** | Taekwondo (Taegeuk 1-8 + tekmeler) · MMA Striking modu | yüksek-tekme sınıflandırıcı (güven-sönümlemeli) · MMA'de **yeni motor YOK** | ⏳ |
| **W4** | Wing Chun solo formlar | DTW + hassas üst-uzuv açı ayarı | ⏳ |

**Motor bağımlılık sırası (blueprint §3):** boks motoru → DTW uzun-sekans → tekme ailesi → dirsek/diz → duruş-sınıfı+embusen → round/kombo motorunun tüm disiplinlere parametrelenmesi.

**Kapsam-dışı (kurucu-kesin, "Neden yok?" sayfasında gerekçelenir):** BJJ/güreş/judo (partner teması fiziksel zorunluluk) · silahlı sanatlar (teknik silah-konumuyla tanımlı, pose göremez) · klinç/sparring/darbe-gücü ölçümü. **Çıkarıldı:** Cardio-Kickboxing modu · Krav Maga.

### W0 görev listesi (bu oturumun kapsamı)
1. Boks V1 motoru (G4) — `boxing@1.0.0` config'inden derlenen faz makineleri + ölçü hesaplayıcıları + hata değerlendirici + kombinasyon sıra motoru; fixture-replay testli.
2. IA çatısı — 4 seviyeli hiyerarşi (kütüphane → disiplin → kurs → ders); 8 disiplin sayfası (7'si "yakında"); **"Neden yok?" sayfası**. Sahte/boş kurs ASLA listelenmez.
3. G5 iskelet uygulama + platform katmanı (bir kez, 5 app deseninde).
4. G6 boks içeriği (müfredat + drill + sesli koç replikleri EN).

### Bu haritayı bağlayan güncel kararlar
- **M-F-17:** ücretli klip **İPTAL** (bütçelenmez) · cihaz benchmark'ı **G8'de, deneme amaçlı** — erken fazlar beklemez, eşikler `"cihazda doğrulanacak"` etiketiyle taşınır.
- **M-F-04 (K8):** kalibrasyon kapısı geçilmeden **sayısal skor gösterilmez** — bant + eğri.
- **M-F-06:** kurallar taraf-agnostik (`lead/rear`); "left/right" yalnız kalibrasyon eşlemesi + `StructuralValidator` temizken.
- **M-F-09:** kalibrasyon = **ölçüm modlarında sert kapı**, serbest pratikte öneri+uyarı.
- **M-F-03:** Dart `motion_core` kanonik çekirdek; JabLab ona pinli bağımlıdır, çekirdeğe app mantığı sızmaz.

## 1. Kimlik ve Kuzey Yıldızı

**JabLab: Shadow Training** — telefonu karşına koy, ekipmansız boks/shadow-boxing antrenmanında köşendeki antrenör gibi sesli düzeltme al: gard, duruş, sıra, denge. LLM değil; pose + state-machine + uzman kural motoru.
**Kuzey Yıldızı:** aynı seans içinde düzeltme yapabilen kullanıcı oranı (koçluk döngüsü kanıtı). İkincil: yanlış-pozitif hata oranı, D7/D30, ilk ders tamamlama.
**Vizyon (tavansız):** Standing Striking Engine — boks V1; kickboks/Muay Thai/karate aynı motora sonraki kollar.

## 2. Konumlandırma ve rakip boşluğu (kanıtlı)

| Rakip | Ne yapıyor | Boşluk |
|---|---|---|
| FightCamp ($39/ay) | Torba + giyilebilir tracker | DONANIM zorunlu; kamera-CV değil |
| PunchLab | Torba modu, sensör | Donanıma yaslanır |
| Boxx (£39.99/yıl) | "Boks temalı kardiyo" + opsiyonel Punch Pod | Kendi itirafıyla kardiyo; form analizi yok |
| Shadow Boxing Workout tarzı app'ler | Sesli script'li follow-along | Seni GÖRMÜYOR — gerçek CV yok |
**Araştırma hükmü: telefon-kamerası-tek, donanımsız, gerçek-zamanlı yumruk-tipi CV koçu PAZARDA YOK** (ticari SDK de yok — Roboflow/akademik alan). Bu beyaz alan aynı zamanda "kopyalanacak kanıtlı mimari de yok" demek — teknik risk bizde (DEFTER'e).
**Konumlandırma (EN):** *"The boxing coach in your corner — no bag, no sensors, just your phone. Real form feedback on every jab."*

## 3. Teknik mimari kararları

- Pose: MediaPipe **full** (canlı, fps öncelikli); katalog §1-2 köprü mimarisi. Sağ/sol gard merkezi transform (plan §21).
- **D2 (bağlayıcı):** hız metrikleri ASLA kare-arası pikselden değil; **faz-süresinden** (state-machine timestamp: GUARD_READY→EXTENSION→PEAK→RETRACTION→RECOVERED). Motion-blur literatürü dolaylı destek — pazarlamada "kanıtlanmış hız ölçümü" DENMEZ; "speed estimate / tempo" dili (plan §14).
- Taksonomi: 6 yumruk = klasik 1-6 (jab, cross, lead hook, rear hook, lead uppercut, rear uppercut) — BoxingVI + kurs literatürü kesişimi. V1 güvenilir çekirdek: 1, 2, 1-2, temel slip/duck; hook/uppercut doğruluk kanıtlayana dek beta bayrağıyla (plan §5).
- Hata kodları: plan §11'in 15'lik seti; İLK 5 çok-güvenilir hata: REAR_HAND_LOW, LEAD_HAND_NOT_RECOVERED, ELBOW_FLARED, STANCE_TOO_NARROW/WIDE, FEET_CROSSED. Kural = versiyonlu config.
- Kombinasyon motoru: sıra+zamanlama doğrulaması (WRONG_HAND / ORDER_ERROR / TEMPO_TOO_FAST_FOR_FORM).
- Sesli koç: tur içinde TEK hata, kısa cümle, cooldown; müzik ducking (katalog §5). Round yapısı: 3dk tur + tur-sonu özet.
- Cihaz-adaptif fps politikası: V0'da ölçülür; 60fps destekleyen cihazda 60'a çıkma opsiyonu (blur azaltır) — pil/ısı dengesiyle.

## 4. Faz planı

### G0 — Derin araştırma & bilgi kütüphanesi
1. Rakip elle-doğrulama: PunchLab/Boxx/FightCamp app'lerini gerçekten kur, kamera modu var mı çöz; fiyatları store'dan ekran görüntülü teyit et.
2. Müfredat kütüphanesi: başlangıç boks müfredatı (stance→jab→cross→1-2→footwork→savunma; plan §15) — saygın koçluk kaynaklarından ORİJİNAL sentez; koçların gerçek hata-taksonomisi (gard düşürme, telegraphing, dirsek açma, ağırlık hatası) → kural-seti tohumu. `movement-science-advisor` ilk geçiş.
3. Dataset lisans yazışmaları listesi: BoxingVI, ShadowPunch, MPOSE2021 boxing subset, serp-ai repo (BoxMAC KULLANILMAZ — arXiv'den çekildi).
4. Fizyolojik güvenlik dosyası: omuz/bilek yüklenmesi, ısınma zorunluluğu (Lissom skorlarıyla aile-içi köprü tasarımı — motion_core sözleşmesi).

### G1 — V0 fizibilite kapısı (D2 — ZORUNLU)
1. Çekim listesi (kurucuya): jab/cross/hook × {yavaş, orta, TAM HIZ} × {iyi ışık, loş} × {30fps, cihaz destekliyorsa 60fps} × 2-3 kişi; ayrıca "bol kıyafet" ve "küçük oda" senaryoları.
2. Ölçüm: tam-hız yumrukta peak-extension kaç karede? Landmark güveni blur'da ne kadar düşüyor? El landmark'ı kayboluyor mu?
3. Faz-süresi hız metriği prototipi fixture'da: aynı yumruğun yavaş/hızlı çekimlerinde metrik tutarlılığı; kare-arası piksel yaklaşımıyla KARŞILAŞTIRMALI çürütme kanıtı.
4. fps politikası önerisi: cihaz-sınıfına göre hedef fps + degrade merdiveni.
**Kapı çıktısı (kurucuya):** blur/fps profili raporu + hız-metriği tasarım kararı + V1 hareket setinin güvenilirlik sıralaması.

### G2 — PRD + teknik tasarım
Akışlar (onboarding→güvenlik→orthodox/southpaw→kamera sihirbazı→kalibrasyon→değerlendirme→ders→kontrollü deneme→canlı tur→özet→mikro-drill), veri modeli (plan §16), state-machine spesifikasyonları (jab/cross/slip başlangıç-bitiş-timeout-iptal koşulları), kural-config şeması, round/ders yapısı. `game-design-architect`: tur döngüsü + ilerleme hissi (ölçülebilir beceri kriteri, ders-izleme değil — plan §15).

### G3 — Veri & fixture kütüphanesi
Fixture seti (katalog §6 şeması): doğru jab/cross/1-2 + 8 hata sınıfı + kadraj-dışı/düşük-güven/blur senaryoları (D2 zorunlu kılıyor). InfiniteRep genel hareket fixture'ları destek; BoxingVI lisans çıkarsa vahşi-koşul doğrulama seti (YouTube kaynaklı — anotasyon-tek dağıtım, ToS'a dikkat). Replay harness motion-core'dan (Lissom kurduysa pinli tüket; kurmadıysa çekirdek kurulumunu bu oturum üstlenir — Lissom G4 listesi).

### G4 — Motor inşası
Stance/orientation tespiti → gard state-machine → jab/cross state-machine'leri (faz timestamp'leri = hız kaynağı) → savunma (slip/duck) → footwork temel → kombinasyon sıra motoru → hata üretici (severity/confidence/evidence/cooldown/feedback/drill bağı) → skor bileşenleri (guard discipline, punch mechanics, recovery, footwork, balance, timing, combination accuracy, tracking confidence — TEK genel skor YOK).
**Kapı:** tüm state-machine'ler fixture-replay yeşil; yanlış-pozitif oranı fixture setinde raporlu; "5 çok-güvenilir hata" kanıtlı.

### G5 — İskelet uygulama (alpha, İngilizce)
Tüm akışlar cilasız: kamera+overlay canlı tur, sesli düzeltme, tur özeti, ders akışı, geçmiş. Impeller benchmark. `mobile-runtime-tester` sweep. Telefon uzakta senaryosu: TÜM kritik geri bildirim SESLİ çalışır (ekrana bakmadan antrenman testi).

### G6 — İçerik üretimi
Ders müfredatı config'leri (Başlangıç/Orta/Fitness hatları — plan §15) · drill kütüphanesi (hata→düzeltici drill eşlemesi) · sesli koç replikleri (EN; kısa, ritmik, tur içi tek-hata disiplini; ~400-600 satır: teknik cue + count + tebrik + tur yönetimi) → aile voice-pack hattı (harcama kurucu-onaylı) · HIIT/kondisyon turu tasarımları. Boks antrenörü doğrulama ihtiyacı manuel listeye.

### G7 — UI giydirme (Claude Design)
Enerjik/karanlık "gym" estetiği; canlı tur ekranı = vitrin (overlay + tur saati + combo göstergesi). Token sistemi; polish turu (`visual-polish-critic`); dark/light + büyük font.

### G8 — Sertleştirme
20-40dk seans termal/pil profili (kritik!) + adaptif degrade kanıtı · cihaz matrisi fps tablosu · a11y (sesli-öncelik zaten avantaj; VoiceOver uyumu) · crash + analytics (geçerli-analiz oranı, yanlış-pozitif proxy'si, seans-içi düzeltme metriği) · offline antrenman kanıtı.

### G9 — Monetizasyon + uyum
Paywall: ilk ders + ilk değerlendirme ücretsiz (GOWOD deseni) → kurs/tur kütüphanesi + gelişim geçmişi abonelik. Koridor katalog §8; öneri → kurucu. IAP sandbox + Opus doğrulama. Uyum: `privacy-data-guardian` + `store-policy-officer`; güvenlik dili (plan §17): self-defense garantisi YOK, gerçek dövüş güvenliği iddiası YOK; "power" fiziksel güç olarak sunulmaz.

### G10 — Pazarlama & lansman
ASO: "shadow boxing, boxing workout at home, boxing trainer" seti; ekran görüntüsü anlatısı: kamera kur→canlı düzeltme→tur özeti→gelişim. Reklam kreatifi: gerçek düzeltme anı klibi (izinli); "no bag, no sensors" mesajı. Kreatif üretimde `content-video-producer`. Submission kurucu.

## 5. Riskler / DEFTER tohumları
J-001 (mevcut): D2 hız örnekleme. Yeni: J-002 kanıtlanmış mimari yokluğu (beyaz alan = ar-ge riski) · J-003 hook/uppercut güvenilirlik eşiği (beta bayrağı politikası) · J-004 60fps cihaz parçalanması · J-005 dataset lisans belirsizlikleri.

## 6. Manuel / kurucu görevleri
Yumruk fixture çekimleri (liste G1'de) · boks antrenörü doğrulaması · voice-pack harcaması · fiyat onayı · submission · domain (jablab.app $9.99 ✓boş — M-006).

## 7. Oturum örgütlenmesi
Fable/high ana oturum; `motion-cv-engineer` D2 sahibi; fan-out sonnet; IAP/güvenlik Opus doğrulamalı; /loop. Başlangıç promptu: vault `🚀 Başlangıç Promptu — JabLab`.
