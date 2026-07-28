# JABLAB — Tam Kapsam Blueprint (oturumun kapsam otoritesi)

**Tarih:** 2026-07-28 · **Statü:** KURUCU-ONAYLI (revizyonlu: Cardio-Kickboxing modu ve Krav Maga ÇIKARILDI). Ortak omurga: motion-core `docs/30-URUN-BLUEPRINT-STANDARDI.md` (IA, UI, yürütme, ajan/token kuralları — ÖNCE onu oku).
**Nihai ürün:** "Solo Combat Training" — 8 disiplinli, her disiplin kendi sayfasında kurslarıyla listelenen, canlı sesli koçluklu, ölçülebilir-ilerlemeli TAM dövüş antrenmanı uygulaması.

---

## 1. TAM KAPSAM — 8 disiplin (kurucu-kesin; ekleme/çıkarma yeniden tartışılmaz)

| Dalga | Disiplin (kendi sayfası) | Fizibilite | Motor ihtiyacı | Müfredat çatısı |
|---|---|---|---|---|
| V1 ✅ | **Boxing** | ✅ | Mevcut (D2 kapılı faz-motoru) | 1-6 numaralı yumruk, stance, savunma, kombolar, round yapısı |
| 1 | **Kickboxing** | ⚠️ tekme apex blur | Tekme sınıflandırıcı (chambering-diz ile front/round/side ayrımı); geniş kadraj yönergesi | WAKO-esinli seviye bantları; boks-kombo numaralandırmasının uzantısı |
| 1 | **Tai Chi** | ✅ (blur yok — DTW motorunun kuruluş yeri) | **Paylaşımlı DTW uzun-sekans motoru İLK BURADA** + küçük-adım embusen takibi | 24-form (standart) → uzun formlar; push-hands/silah formları ❌ |
| 2 | **Karate (Kihon + Kata)** | ⚠️ embusen yer-deseni | DTW motoru (Tai Chi'den) + duruş-sınıfları (zenkutsu/kiba/kokutsu) + yer-deseni ("kata kutusu" kalibrasyonu) | Kyu/Dan bantları; Heian 1-5'ten başlayan kata dizisi; kihon çizgi-drilleri |
| 2 | **Muay Thai** | ⚠️ klinç yalnız simüle-drill | Dirsek + diz + teep sınıflandırıcıları | Kru-onaylı seviye bantları; Wai Kru/Ram Muay = DTW-skorlu form |
| 3 | **Taekwondo (Poomsae + tekmeler)** | ⚠️ EN ZOR: sıçrama/dönüş tekmesi blur — görünür doğruluk-uyarısıyla | Yüksek-tekme sınıflandırıcı (kare-arası güven-sönümleme); poomsae = DTW | Geup/Dan; Taegeuk 1-8 → Yudanja formları |
| 3 | **MMA Striking** (mod) | ✅ | Yeni motor YOK — Boks+KB+MT tekniklerinin serbest-karışım drill modu | "Striking-only" olarak açık pazarlanır |
| 4 | **Wing Chun (Solo Formlar)** | ⚠️ ince el/dirsek çözünürlüğü | DTW + hassas üst-uzuv açı ayarı | Siu Nim Tao → Chum Kiu → Biu Jee; dummy-formu ❌ (ekipman) |

**ÇIKARILDI (kurucu 2026-07-28):** Fitness/Cardio-Kickboxing modu (fitness-dans kapsamı Choreia'da) · Krav Maga.
**❌ Kapsam-dışı ("Neden yok?" sayfasında):** BJJ/Güreş/Judo (partner teması/direnci fiziksel zorunluluk) · silahlı sanatlar (teknik silah-konumuyla tanımlı, pose göremez) · klinç/sparring/darbe-gücü ölçümü.

## 2. Bilgi mimarisi (standart §2'nin JabLab örneği)

Kütüphane → **Disiplin sayfası** (ör. "Muay Thai": tanıtım + teknik haritası + kurs listesi [Temeller · Kombolar · Savunma · Form/Ram Muay · Kondisyon-drilleri] + disiplin istatistikleri + ölçüm-dürüstlük kutusu) → Kurs → Ders (öğret→kontrollü dene→canlı round→özet→mikro-drill). Ortak araçlar her sayfadan: round-timer (Live Activity!), serbest shadow-work modu, kombo-oluşturucu.

## 3. Motor iş listesi (sıra = bağımlılık sırası)

1. V1 boks motoru tamamla (roadmap G4 — J-serisi bulgular: EXTENSION_TIMEOUT, faz-süresi hız bandı, ön-eğik kamera).
2. **DTW uzun-sekans motoru** (motion-core'a; Choreia ile ortak — koordinatörle tek implementasyon): referans-forma hizalama + bölüm-bazlı sapma raporu + warp-cezası (C-009 dersi).
3. Tekme sınıflandırıcı ailesi (KB → MT teep → TKD yüksek tekme kademeleri; her kademe kendi fixture+blur profiliyle — D2 metodolojisi tekrar kullanılır).
4. Dirsek/diz sınıflandırıcıları (MT).
5. Duruş-sınıfı + embusen takibi (Karate/TKD/Tai Chi küçük-adım).
6. Round/seans motoru + kombo-sıra doğrulayıcı (mevcut) tüm disiplinlere parametreli.

## 4. İçerik hattı (hasat → kurs)

Kaynak havuzları (katalog §6.2): Precision Striking, Tony Jeffries, ExpertBoxing (boks ≥3 ✓); disiplin-başına ≥3 eğitmen havuzu G0-hasat göreviyle genişletilir (Tai Chi: standart 24-form kaynakları bol; Karate/TKD: federasyon-standart form videoları ideal — form adları telifsiz, ORİJİNAL anlatım bizden). Her disiplin sayfası için: teknik envanteri → referans çıkarımı (ReferenceBuilder) → hata-taksonomisi (perturbasyon) → kurs config'leri → voice-pack replikleri (EN) → iskelet-avatar dersleri. Slow-mo tek-kişi kaynak İNCE (bilinen bulgu) — tempo-merdiveni kamu taramasıyla, bulunamayan noktada eşikler muhafazakâr + "cihazda doğrulanacak" etiketi.

## 5. Görev backlog'u (dalga-bazlı; oturum roadmap'ine işler)

**W0:** Boks V1'i bitir (G4→G5 iskelet→G6 içerik) + platform katmanı + IA çatısı (8 disiplin sayfası "yakında" durumlarıyla) ✚ "Neden yok?" sayfası.
**W1:** DTW motoru (Tai Chi 24-form pilotu) + tekme sınıflandırıcı v1 → Kickboxing + Tai Chi sayfaları canlı.
**W2:** Karate kihon+ilk 5 kata + MT (dirsek/diz/teep + Ram Muay) sayfaları.
**W3:** TKD (Taegeuk 1-8 + tekme kademeleri, doğruluk-uyarılı) + MMA-striking modu.
**W4:** Wing Chun formları + kapsam-tamamlama turu (her sayfada kurs doluluğu ≥ hedef, ölü içerik 0).
Her dalga sonunda: runtime sweep + DEFTER mühürü + vault pano güncellemesi.

## 6. JabLab-özel platform deltaları
Round-timer + Live Activity/Dynamic Island · shadow-work serbest modu (skorsuz ısınma) · kombo-oluşturucu (kullanıcı kendi kombosunu kurar, motor doğrular) · Lissom "dövüşçü ısınması" deep-link'i · HealthKit "Boxing/Martial Arts" workout yazımı.

## 7. Dürüstlük/güvenlik (JabLab-özel)
"Power" = hız/tempo bandı (kuvvet İDDİA EDİLMEZ) · sıçrama/dönüş tekmelerinde görünür doğruluk notu · self-defense sonucu vaat edilmez · temiz alan/zemin uyarıları · TKD/KB yüksek tekme esneklik ön-koşulu (Lissom köprüsü) · çocuk-gözetim dili.

## 8. Manuel-sona listesi (kurucu)
Boks/branş antrenörü doğrulama turları (dalga-sonu) · cihaz-benchmark (G8) · fiyat onayı · voice-pack bütçesi · store submission.
