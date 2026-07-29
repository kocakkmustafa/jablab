# Fitness-track — SHIP EKSİK ENVANTERİ (J-070)

**Tarih:** 2026-07-30 · **Kanıt:** [`FITNESS-SHIP-KANITI.txt`](FITNESS-SHIP-KANITI.txt)
(bu doküman değil O dosya kanıttır — `test/fitness_ship_audit_test.dart`
koşumunun stdout'u) · **Hizalama:** motion-core `docs/70-KAMERA-KOPRUSU-SOZLESMESI.md` §7

> **J-062 dersi:** "Fitness şimdi çıkabilir" cümlesini bir kez beyan olarak
> yazdım ve yanlıştı. Bu envanter o cümlenin yerine geçmiyor — **koşum
> çıktısı** geçiyor. Bu doküman yalnızca çıktının GÖSTERMEDİĞİ şeyi, yani
> kalan işi isimlendiriyor.

---

## Kanıtın söylediği (özet)

**9/9 canlı süreli ders uçtan uca yürüdü.** Her ders için: açılıştan derse
ulaşım · 4 aşamalı seans akışı · saatin beyan edilen yapıyı koşması ·
çalışma süresinin dersin **kendi ilerleme kapısına birebir eşitliği** ·
kaydın yazılması · kaydedilen olgunun ilerleme sayfasında görünmesi.

Kapsam **içerikten sürülüyor** — ders listesi teste elle yazılmadı, yeni
ders eklenince denetim onu kendiliğinden kapsar.

---

## 🔴 SINIF A — KAMERA KÖPRÜSÜ (Fitness için kalan TEK sınıf)

Fitness-track'in ölçüm/kayıt/zaman hattı kamerasız çalışıyor ve kanıtlandı.
Kalan her şey köprüye bağlı. Aşağıdakiler **docs/70 §7 canlılık listesiyle
hizalı**; JabLab shell'i köprünün doğal ilk cihaz-harness'ı olduğu için
"kamera gelince JabLab'da ne bağlanacak" kolonu bu listenin app-tarafı
karşılığıdır.

| §7 | canlılık kalemi | JabLab'da ne bağlanır |
|---|---|---|
| 1 | `pod install` 0.10.21 çözer, Swift derlenir | — (platform; JabLab tüketici) |
| 2 | Gradle 0.10.29 çözer, Kotlin derlenir | — (platform) |
| 3 | Gerçek cihazda ≥30 sn zarf akışı; `judgedRatio` + `meanInferenceUs` ÖLÇÜLÜR | **`withValidAnalysisRatio` kapısının ilk gerçek girdisi.** Bugün 0; ilerleme kapılarının TAMAMI bunu bekliyor |
| 4 | Dual-pass maliyeti ölçülür (ADR-001 "2× maliyet" sınanır) | Canlı seans fps bütçesi; `hiit` 30sn patlamada en sıkı vaka |
| 5 | iOS buffer-tutma → `dropped` patlaması | `LiveState.noVerdict` "göremiyorum" yolunun gerçek tetikleyicisi |
| 6 | `clock:"unknown"` yolu bir vendor cihazda gözlenir | Seans saati ile poz saati ayrışırsa tur sınırları kayar — `RoundPlan`/`IntervalPlan` tik'i tek-saat varsayıyor |
| 7 | Ters-geçiş geri-eşlemesi el-standı fikstürüyle doğrulanır | `StanceDetector` taraf-etiketi (M-F-06); yanlış gövdeye rotasyon = lead/rear ters |
| 8 | Ön-izleme yüzeyi bağlanmadan UI entegrasyonu BAŞLAMAZ | **JabLab'da ön-izleme yuvası YOK** (UI-BRIEF §3.8'de isimli boşluk) |

### Köprü gelince JabLab'da açılacak, bugün İSİMLİ kapalı olanlar

1. **İlerleme kapılarının TAMAMI.** Her kapı ya poz-analizi olayı
   (`jab attempts` · `stanceHold` · `setupCheckPassed` ·
   `minCorrectSequences`) ya da `withValidAnalysisRatio: 0.7` istiyor.
   ⚠️ **Ve bu retroaktif DEĞİL:** kapı "kameranın izlediği" süreyi soruyor;
   bugün biriken dakikalar sonradan kredi olmaz. İlerleme sayfası bunu
   kullanıcıya söylüyor (F-4).
2. **`counting` replik grubu** — `cue.count` / `cue.milestone` sayıma bağlı,
   sayım kameradan gelir.
3. **`encouragement` grubu** — "düzeltmeyi GÖRDÜM" demek için görmek gerekir;
   tek anahtarı bile canlı olamaz.
4. **`summary` trend replikleri** — kısmen açıldı (F-3 geçmişi geldi), ama
   *form* trendi hükme bağlı.
5. **`setup` grubu (`awaiting-surface`)** — kamera kurulum sihirbazı yok.
6. **3 kilitli Intermediate dersi** — bunlar köprüye DEĞİL ölçüme bağlı
   (aşağıda, Sınıf B).
7. **Ön-izleme yuvası** — §7.8 gereği bu bağlanmadan UI entegrasyonu
   başlamaz; UI-BRIEF'te isimli boşluk olarak duruyor.

---

## 🟡 SINIF B — ÖLÇÜM (köprüden bağımsız, referans/kapsam işi)

Bu üçü kamera gelse bile açılmaz; eksik olan ölçümün KENDİSİ.

| ders | `lockedBy` | eksik olan |
|---|---|---|
| `intermediate.combinations` | `technique-coverage` | hook/uppercut SINIFLANDIRILMIYOR (sayılıyor ama ayırt edilmiyor) → kombinasyon sırası hükmü verilemez |
| `intermediate.footwork_combo` | `missing-reference` | footwork için eğitmen-uzlaşısı ölçülmedi (referans yok) |
| `intermediate.counter` | `no-opponent` | **YAPISAL — çözülemez.** Savunmaya yanıt için rakip gerekir; gölge çalışması sağlayamaz |

`counter` bilinçli olarak "ileride yapılacak" listesinde DEĞİL: tek kişilik
kamerayla ölçülemeyen bir şeyi vaat etmemek ürünün sözü (`whyNotIncluded`
ile aynı ilke).

---

## 🟢 SINIF C — ÜRÜN/TASARIM (kod beklemiyor)

UI-BRIEF §4'ün "kod beklemeyen 5 boşluğu" — `claude.ai/design` oturumlarına
bitişik, kurucu-manuel adım:

1. **Onboarding akışı** — hiç yok.
2. **Öğretici içerik yuvası** — `teach` aşaması "watch first" diyor ama
   izlenecek bir şey yok.
3. **Dürüst hata ekranı** — içerik denetimi başarısızlığı bugün ham hata
   metni (`content-error`).
4. **Kilit görsel dili** — 3 ders kilitli; ceza değil beyan gibi görünmeli.
5. **Canlı ekranın uzaktan-okunur tipografisi** — telefon 2-3 m uzakta.

Ayrıca **kurucu-bekleyen manuel kalem:** antrenör-doğrulama listesi
(jab referansı `attested-provisional`; 4./5. bağımsız eğitmen gelince
eklem tablosu yeniden hesaplanır) + `technique_round` guidance-hypothesis
gerilimi (kamera günü tur-süresi + feedback-solma birlikte, J-069'da
isimli taşındı).

---

## SessionStore delta-notu (aile)

`SessionStore` arayüzü (J-064) bugün **tek tüketicili** ama ikinci tüketici
yolda: **Choreia J-064 desenini port ediyor.** Üçler kuralı **Lissom'da**
tetiklenecek; çekirdek-terfi gününde bu arayüz normatif aday.

Terfi günü için bilinmesi gerekenler — **arayüz farkı görülürse bana gelin:**

* **Kaydedilen alan bilerek AZ:** `lessonId · completedAt · workedSeconds ·
  roundsCompleted · plannedRounds`. **Hüküm/skor alanı YOK** — kamera
  yokken sıfır kaydetmek, yarın ilerleme grafiğinde sıfır çizmek olurdu.
* **`workedSeconds` DİNLENMEYİ SAYMAZ** (turda dinlenme, aralıkta
  toparlanma). Kapı çalışılan süreyi soruyor; eklemek kullanıcıyı kapıdan
  hak etmeden geçirir. Aralık ve tur için iki farklı toplam matematiği var
  (`IntervalPlan` son toparlanmayı toplama KATAR, `RoundPlan` son dinlenmeyi
  KATMAZ) — ikinci tüketici bu ayrımı görmezse sessiz-yanlış üretir.
* **Yarıda bırakılan seans KAYDEDİLİR** ve `isComplete` ile ayırt edilir.
  "Bıraktı" bir veridir.
* **Biçim:** append-only JSONL · atomik tmp+rename · **şema sürümü SATIR
  düzeyinde** · 3. taraf DB YOK. Arıza davranışları testli: bozuk satır tüm
  geçmişi silmez · yarım son satır götürmez · bilinmeyen sürüm atlanır ·
  depo kurulamazsa uygulama çalışmaya devam eder.
* **Enjeksiyon:** `ContentRepository(storeOverride:)` — bu denetimin kaydı
  doğrulayabilmesi için var (`path_provider` widget testinde çalışmaz);
  üretimde `null`.

---

## Ship kararı

**Fitness-track'in zaman/kayıt/dürüstlük hattı ship'e hazır ve kanıtlı.**
Kullanıcıya bugün verilen şey: beyan ettiği süreyi gerçekten koşan 9 ders,
kaydedilen çalışma geçmişi, ve ölçülmeyen hiçbir şeyin iddia edilmemesi.

**Kalan TEK sınıf kamera (Sınıf A).** Sınıf B kamerayla açılmaz (ölçüm işi),
Sınıf C kod beklemiyor (tasarım/kurucu).
