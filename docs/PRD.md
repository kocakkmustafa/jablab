# JabLab — PRD (G2)

**Tarih:** 2026-07-26 · **Statü:** G1/D2 şartlı geçişi sonrası yazıldı; eşik SAYILARI D2-D kalibrasyonuna bağlı, YAPI bağımsız.
**Hiyerarşi:** `00-AILE-MIMARISI` > `20-URETIM-SURECI` > `10-ARAC-KATALOGU` > `jablab-roadmap.md` > **bu dosya** > `jablab-plan.md`.
**Kararlar:** `adr/ADR-001..004` · **Kanıt:** `gates/D2-KAPI-RAPORU.md` · **Ürün dili: İngilizce** (i18n katmanı baştan, V1 yalnız `en`).

---

## 1. Ürün ve kuzey yıldızı

**JabLab: Shadow Training** — telefonu karşına koy, ekipmansız shadow boxing yaparken köşendeki antrenör gibi kısa sesli düzeltme al.

**Kuzey yıldızı:** *aynı seans içinde düzeltme yapabilen kullanıcı oranı.* Bir hata söylendikten sonraki 60 sn içinde aynı hatanın tekrar oranı düşüyorsa koçluk döngüsü çalışıyordur. Ders tamamlama sayısı ilerleme sayılmaz (`plan §15`).

**İkincil:** kamera kurulum başarı oranı · geçerli analiz oranı · yanlış-pozitif hata oranı · D7/D30.

## 2. V1 kapsamı — güvenilirlik bandına göre kesilmiştir

D2 ölçümü, kapsamı "ne istiyoruz"a göre değil **"neyi kanıtlayabiliyoruz"a** göre belirledi (`D2-KAPI-RAPORU §4.2`).

| Bant | Yayınlanır mı | İçerik |
|---|---|---|
| 🟢 **A** | V1'de tam | Yumruk **olayı** tespiti + sayım · kombinasyon **sırası** doğrulama · `STANCE_TOO_NARROW/WIDE` · `FEET_CROSSED` · `BALANCE_LOSS` · `TORSO_FALLING_FORWARD` |
| 🟡 **B** | V1'de, kamera kapısı geçilmişse | `REAR_HAND_LOW` · `LEAD_HAND_NOT_RECOVERED` (ADR-003 kapısı sağlanmazsa bu kodlar susar) |
| 🟡 **B-kal** | V1'de, D2-D kalibrasyonundan SONRA | `ELBOW_FLARED` · `OVERREACH` |
| 🟠 **C** | V1'de bant olarak | tempo göstergesi · `TEMPO_TOO_FAST_FOR_FORM` (ADR-001: sayı değil bant) |
| 🔴 **D** | **V1 DIŞI** | hook / uppercut ayrımı · slip/duck/roll hükmü · pivot · darbe gücü |

**Teknikler V1:** stance (orthodox/southpaw) · guard · **jab** · **cross** · **1-2** · 1-1-2 · temel footwork (ileri/geri/yan). Hook/uppercut *sayılır* (yumruk olayı) ama **tipi iddia edilmez** ve form hükmü verilmez — uzanma-oranı detektörü bu tekniklerde kol tam açılmadığı için çalışmıyor (J-003).

**V1 dışı (plan §20 aynen geçerli):** torba, pad, partner, sparring, silah, grappling, darbe gücü, canlı LLM, avatar, çoklu kamera, sosyal ağ, medikal tavsiye.

> **Dürüstlük kuralı:** yarım özellik gizlenmez, **kapsamdan çıkarılır** (`20-URETIM-SURECI §5`). Hook/uppercut "yakında" olarak gösterilir, çalışıyormuş gibi değil.

## 3. Kullanıcı akışları

```
1  Onboarding (ne yapar / ne yapmaz — self-defense ve güç iddiası YOK)
2  Güvenlik brifingi (alan, zemin, ağrı, sağlık sorunu)
3  Gard seçimi (orthodox / southpaw)  → lead/rear eşlemesi burada kurulur (ADR-004)
4  ⛔ KAMERA KURULUM SİHİRBAZI — MODA GÖRE KAPI (ADR-003 → aile kuralı M-F-09)
5  Vücut kalibrasyonu (kol uzunluğu L, omuz genişliği, gard taban duruşu — 3 sn sabit)
6  Başlangıç değerlendirmesi (10 jab + 10 cross, kendi temponda) → ilk skor kartı
7  Ders seçimi
8  Hareket öğretimi (kısa video + cue)
9  Kontrollü deneme (yavaş tempo, tek hata odağı, tur saati YOK)
10 Canlı tur (3 dk, sesli koç, tek-hata disiplini)
11 Tur özeti (skor bileşenleri + en sık hata + kanıt anı)
12 Hata odaklı mikro-drill (60-90 sn)
13 Gelişim geçmişi
```

**Kalibrasyon kapısının mod ayrımı (M-F-09 — ADR-003'ün aile kuralı hâli, benim ADR'imi *genişletiyor*):**

| Mod | Kalibrasyon | Gerekçe |
|---|---|---|
| **Değerlendirme / ölçüm** (adım 6, gelişim geçmişine yazan her ölçüm) | 🔴 **SERT KAPI** — geçilmeden analiz başlamaz | Kayda geçen sayı, kadraj bozukken üretilmişse geçmişi kalıcı kirletir |
| **Serbest pratik / tur** (adım 10-12) | 🟡 öneri + kalıcı uyarı bandı | Kullanıcıyı antrenman yapmaktan alıkoymak, kusurlu ölçümden daha zararlı |

Serbest modda kalibrasyon yoksa: yumruk **sayılır**, form hükmü **verilmez**, uyarı bandı görünür kalır.

**Ücretsiz çekirdek (paywall ÖNCESİ):** 1-6 + bir ders + bir tur. Değer önce kanıtlanır (`10-ARAC-KATALOGU §8`, GOWOD deseni). Ayrıntı G9.

**Telefon uzakta kuralı:** 9-12 arasındaki TÜM kritik geri bildirim **sesli** çalışır. Ekrana bakmadan antrenman, G5 kabul testidir.

## 4. Faz spesifikasyonları (Standing Striking Engine)

Ortak büyüklük: `e = |bilek−omuz| / L` (L = kalibrasyonda ölçülen kol uzunluğu). Eşikler `boxing@1.x` config'inde; aşağıdaki değerler **D2 ölçümünden gelen başlangıç değerleridir**, D2-D sonrası kalibre edilecek.

### 4.1 `jab` / `cross` (uzuv-uzatma şablonu)

| Faz | Giriş koşulu | Timeout | Not |
|---|---|---|---|
| `GUARD_READY` | `e < 0.62` ve gard duruşu geçerli | — | Gerekli landmark: lead/rear bilek+dirsek+omuz |
| `EXTENSION` | `e > 0.68` ve `Δe > 0` | **400 ms** | J-009: bu timeout olmadan "uzatıp bekleme" yumruk sanılır |
| `PEAK` | `e > 0.85` ve yerel maksimum | 150 ms | Hata kurallarının çoğu burada değerlendirilir |
| `RETRACTION` | `e < 0.80` ve `Δe < 0` | 600 ms | `LEAD_HAND_NOT_RECOVERED` burada ölçülür |
| `GUARD_RECOVERED` | `e < 0.62` | — | terminal |

**İptal:** takip kaybı > 500 ms · kadraj dışı · `e` hiç 0.85'e ulaşmadan geri dönüş (→ *yumruk değil*, sayılmaz).
**Cross ek fazı:** `REAR_SHOULDER_ROTATION` (gövde-omuz açı farkı eşiği) — `EXTENSION` öncesi; rotasyon yoksa `cross` değil `rear jab` olarak sınıflanır (bu bir *hata* değil, sınıflandırma).

### 4.2 `stance` (sürekli değerlendirici, faz makinesi değil)
Her karede değil, **her yumruk olayında + 2 sn'de bir** değerlendirilir: ayak bileği mesafesi / omuz genişliği oranı, ayak çaprazlanması, ağırlık merkezi (kalça orta noktası) ayak tabanına göre konumu, gövde öne eğimi.

### 4.3 `combination` (sıra motoru)
Beklenen dizi (`1-2`) ile gerçekleşen `AttemptDigest` dizisi karşılaştırılır: `WRONG_HAND_FOR_COMBINATION`, `COMBINATION_ORDER_ERROR`, ve **faz süreleri** üzerinden `TEMPO_TOO_FAST_FOR_FORM` (ADR-001 bandı).

## 5. Hata modeli

Her hata: `code · severity · confidence · evidence · cooldown · feedbackKey · relatedDrill · band`.

- **`confidence` zorunlu ve yayınlanır.** `minConfidence` altında **hüküm verilmez** — "Sağ bileğin bu açıdan güvenilir görünmüyor" denir, "yanlış yaptın" denmez (`plan §12`).
- **Kanıt (`evidence`) saklanır:** hangi faz, hangi landmark, hangi eşik, hangi değer. Tur özetinde kullanıcıya gösterilebilir olmalı — açıklanabilirlik pazarlama değil, ürün gereği.
- **Cooldown** hata koduna özgü (varsayılan 8 sn); aynı uyarı turda 3 kereden fazla tekrarlanmaz.

## 6. Sesli koç politikası

- **Tur içinde aynı anda TEK hata.** Öncelik: güvenlik > tekrarlayan hata > yeni hata > olumlu pekiştirme.
- Kombinasyon **ortasında** konuşma yok — cue, `GUARD_RECOVERED` sonrasına kuyruklanır.
- Kullanıcı düzeltince **olumlu sinyal** (kuzey yıldızının ölçüm anı da burasıdır).
- Ducking: müzik kısılır, bastırılmaz (`10-ARAC-KATALOGU §5`). Cue gecikme bütçesi ≤500 ms.
- V1 ses: sabit repliklerde voice-pack, dinamik sayılarda sistem TTS (hibrit; katalog §5).

## 7. Skorlar — ⚠️ K8 aile kuralına göre revize (M-F-04)

Tek "doğruluk" skoru **YOK** (`plan §14`). Bileşenler: `guardDiscipline` · `punchMechanics` · `recovery` · `footwork` · `balance` · `timing` · `combinationAccuracy` · `trackingConfidence`.

**Kurucu kararı M-F-04 (5 app için bağlayıcı): kalibrasyon kapısı geçilmeden kullanıcıya SAYISAL skor gösterilmez.**

| | V1 başlangıç | Kalibrasyon kapısından sonra |
|---|---|---|
| Gösterim | **bant + ilerleme eğrisi** — "Guard discipline: solid" | mutlak sayı açılabilir |
| Bantlar | `needs_work` · `developing` · `solid` · `strong` | — |
| Kilidi açan | JabLab eşik kalibrasyonu (J-007, kurucu çekimi) | — |

Bu karar J-008 ile (hız = sayı değil bant) zaten aynı yöndeydi; M-F-04 onu **tüm skor bileşenlerine** genelleştirdi. `boxing@1.0.0 → display.numericScoresUnlocked` bayrağı tek anahtardır.

`trackingConfidence` **kullanıcıya gösterilir** — düşükse diğer bantlar soluklaştırılır ve nedeni söylenir. "Ölçemedim" demek, yanlış ölçmekten üstündür (`00-AILE-MIMARISI §7`).
"Power" gösterilmez. Hız **tempo bandı** olarak gösterilir (ADR-001).

**Taraf dili (M-F-06 aile kuralı):** kullanıcıya "left/right" **yalnız** kalibrasyon eşlemesi kurulduktan *ve* `StructuralValidator` temizken söylenir. Aksi hâlde taraf-agnostik dil kullanılır ("lead hand", "rear hand"). Bu, footwork cue'larını (`step left/right`) doğrudan kısıtlar — J-019.

## 8. Veri modeli

`UserProfile · StancePreference · CalibrationProfile(L, shoulderWidth, guardBaseline) · Technique · TechniquePhase · RuleSet · Lesson · Workout · Round · AttemptDigest · AttemptMetric · DetectedIssue · FeedbackEvent · Session · ProgressMetric · SafetyEvent · ModelVersion · RuleSetVersion`

**Provenance zorunlu (M-F-07 aile kuralı).** Her `AttemptDigest` ve `Session` kaydı şunları taşır: `poseModelVariant` · `poseModelSha256` · `ruleSetVersion` · `metricConfigVersion` · `calibrationProfileId`. **Zaman-içi karşılaştırma ("bu hafta jab'in düzeldi") bu alanlar olmadan YAPILMAZ** — model varyantı veya eşik değişmişse "gelişme" model gürültüsü olabilir.

- **Ham video varsayılan olarak kaydedilmez** ve cihazdan çıkmaz.
- `PoseFrame` **kalıcı değildir**: yalnız `AttemptDigest` (ADR-002) saklanır. Bu hem gizlilik hem depolama kararıdır.
- Her `Session` kaydı `ModelVersion` + `RuleSetVersion` taşır; eşik değişince geçmiş yeniden yorumlanmaz.
- Yerel-öncelikli depolama (LifeOS Drift/SQLCipher deseni). Bulut yalnız hesap/içerik/abonelik + izinli senkron.

## 9. Ders yapısı

**Başlangıç:** kamera ve alan → stance → guard → jab → cross → 1-2 → footwork → ilk 3 dk tur.
**Orta:** kombinasyon → tempo değişimi → footwork ile kombinasyon → teknik yorgunluk.
**Fitness:** 5 / 10 / 20 dk + HIIT (teknik odaklı kondisyon).

İlerleme kriteri **ölçülebilir beceri**dir: örn. "son 3 turda `REAR_HAND_LOW` oranı < %10" — "dersi izledi" değil.

## 10. Güvenlik ve dil (G9 uyum girdisi)

Temiz alan · kaymayan zemin · ağrıda dur · sağlık sorununda profesyonel görüş · çocukta ebeveyn gözetimi. **Self-defense garantisi YOK · gerçek dövüş güvenliği iddiası YOK · darbe gücü ölçümü YOK · tıbbi dil YOK** (wellness). Birine vurma veya riskli pratik önerilmez.

## 11. V1 tamamlanma kriterleri

Android/iOS tam vücut takip · kamera sihirbazı **kapı olarak** çalışıyor · orthodox+southpaw · stance/guard/jab/cross/1-2 · **≥10 güvenilir hata (bant A+B)** · temel footwork · canlı kısa sesli feedback · tur özeti · yerel geçmiş · internetsiz antrenman · ham video gizliliği · replay testleri yeşil · **boks antrenörü doğrulaması** · performans/ısı ölçümü · abonelik öncesi çalışan ücretsiz çekirdek.

## 12. Bu PRD'nin açık bağımlılıkları

| Ne | Kime bağlı |
|---|---|
| Hata eşiklerinin nihai sayıları | D2-D kurucu çekimi (J-007) |
| fps politikasının kesinleşmesi | D2-C cihaz ölçümü (J-011) |
| Kamera açısı kararının kesin kanıtı | çekim #13 saf-yan kontrol (J-006) |
| Kural setinin fizyolojik doğrulaması | `movement-science-advisor` turu → sonra gerçek boks antrenörü |
| motion_core sürüm pinlemesi | çekirdek uzlaştırma kararı (M-017) |
