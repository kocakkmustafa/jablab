# 🚢 YAYIN ENGELİ DENETİM YÖNTEMİ (J-216, 2026-08-12)

> **Bu belge bir LİSTE değil, bir YÖNTEMDİR.** Liste bayatlar; yöntem, bayat
> bir listeyi yakalayan şeydir. Her kalem "bugün ne durumda" diye değil,
> ***"bu soruyu nasıl ölçerim ve sıfır cevabına ne zaman güvenebilirim"***
> diye yazılmıştır.

## Neden yazıldı — iki hattın kör noktaları ÖRTÜŞMEDİ

JabLab ve Lissom aynı denetimi bağımsız yaptı. **İkisi de eksikti, ve
eksikler farklıydı:**

| bulan | ötekinin KAÇIRDIĞI |
|---|---|
| Lissom | Android imza yapılandırması · `AFTER_APPROVAL` (otomatik yayın) |
| JabLab | `PrivacyInfo.xcprivacy` · `targetSdk` (Play eşiği) |

→ ***Yöntem yazılmazsa her hat kendi kör noktasıyla denetler ve dördü de
"engel yok" der.***

## ⚠️ TEMEL KURAL — şablondan gelen her satır AYRI bir denetim kalemidir

> ***Beş hatta da aynı olan bir kusur, hat düzeyinde ÖLÇÜLEMEZ: aynılık onu
> arka plana çevirir.***

Ve daha kötüsü ölçüldü (J-215): **arka plan, kendine bir açıklama uydurtur** —
JDK/Gradle uyuşmazlığını "benim ortamım bozuk" ya da (benim yaptığım gibi)
büsbütün yanlış bir bileşene atfetmek. Bu yüzden **şablon kaynaklı kalemler**
(⑤ imza · ⑥ `PrivacyInfo` · ⑦ ikon · ⑧ izin metni · ④ `targetSdk`) listede
**ayrı satır** olmak zorundadır; "bunlar zaten şablondan gelir, kurcalamadım"
bir denetim cevabı DEĞİLDİR.

## ⚠️ HER "SIFIR" İÇİN POZİTİF KONTROL — ve kontrolün üç katmanı

1. **ARAÇ**: arama aracı çalışıyor mu? (*bir şey* bulabiliyor mu)
2. **DİZGE**: aradığın DİZGE doğru mu? (*bu kavramı çözdüğünü BİLDİĞİM bir
   yerde* isabet ediyor mu — M-F-505)
3. **KAPSAM**: doğru AĞACA mı bakıyorsun? (hat mı, aile mi, çekirdek mi)

⭐ **En güçlü biçim — SABOTAJ KONTROLÜ:** iddia edilen yokluğun **tam
örneğini** kaynağa enjekte et, aramanın onu **bulduğunu** gör, geri al
(enjekte→1, geri al→0, uydurma dizge→0). `rootBundle` bulmak, `HttpClient`
bulacağını **kanıtlamaz.**

🪤 Bu belgeyi yazan turda araç **iki kez** uydurma sıfır üretti:
`git grep` **izlenen** içeriği tarar (çalışma ağacındaki probu görmez) ·
tırnaksız `$VAR` genişlemesi dosya listesini **tek desen** yapar. İkisi de
temiz görünen bir "bulunamadı" raporu verecekti.

## SINIFLANDIRMA — üç sınıf, ve sınırları

| sınıf | tanım | örnek |
|---|---|---|
| **hat-yereli** | hat kendi ağacında kapatabilir | imza *yapılandırması*, kapılar, metin düzeltmeleri |
| **çekirdek** | çekirdek turu gerektirir, beş hattı bağlar | `SessionRecord` alanı, `worldLandmarks` |
| **kurucu** | erişim · sır · tasarım · harcama · beyan | keystore, ikon, ASC girişi, sürüm numarası |

⚖️ **İKİ AYIRIM ŞART, yoksa liste yanlış uzunlukta görünür:**

* **Bir kalem İKİYE bölünebilir.** *"Android imza"* tek kalem değil:
  **keystore** kurucunun (sır), **yapılandırma + sessiz-düşmeyi engelleyen
  kapı** hat-yerelidir. Biri ötekinin altına saklanırsa hat-yereli iş
  "erişim bekliyor" diye bekletilir.
* **Yetenek gediği ≠ yayın engeli.** Ürün dürüstçe *"bunu ölçemiyorum"*
  diyerek sevk edilebiliyorsa o kalem **engel değildir.** ***Bir listeyi
  olduğundan uzun göstermek, kısa göstermek kadar yanıltıcıdır.***

---

## DENETİM KALEMLERİ

Her satır: **soru · nasıl ölçülür · pozitif kontrol · sınıf.**
`$auditItems` tablosu `test/ship_audit_method_test.dart` tarafından
denetleniyor: **pozitif kontrol sütunu boş bir kalem eklenemez.**

| # | katman | soru | nasıl ölçülür | pozitif kontrol | sınıf |
|---|---|---|---|---|---|
| 1 | ağ | ürün gerçekten hiçbir şey göndermiyor mu? | üretim Dart'ında ağ çağrısı/importu | **sabotaj**: `HttpClient()` enjekte→bulunmalı, geri al→0 | hat-yereli |
| 2 | kalıcılık | diske ne yazılıyor — iddia edilenle aynı mı? | tüm `writeAs*`/store çağrıları sayılır, iddia metniyle karşılaştırılır | aynı tarama bilinen yazımları (`onboarding_seen`, `sessions.jsonl`) bulmalı | hat-yereli |
| 3 | izin metni | kullanıcının gördüğü İLK cümle doğru mu? | `Info.plist` + Android manifest metinleri, madde madde koda karşı | metnin her iddiası için ayrı ölçüm; "keeps/stores" fiilleri ayrı sorgulanır | hat-yereli |
| 4 | platform eşiği | `targetSdk`/`minSdk` mağaza eşiğini karşılıyor mu? | `flutter.targetSdkVersion` → SDK'daki gerçek değer çözülür | SDK ağacı okunabildi mi (dosya sayısı > 0) | hat-yereli |
| 5 | imza | release SESSİZCE debug anahtarıyla imzalanıyor mu? | `build.gradle.kts` release bloğu + `key.properties`/keystore varlığı | imzası **bilinen** bir projede (ör. LifeOS) desen isabet etmeli | **ikiye böl**: yapılandırma+kapı = hat-yereli · keystore = kurucu |
| 6 | gizlilik manifesti | `PrivacyInfo.xcprivacy` var mı, beyanı ölçümle uyuşuyor mu? | dosya + üç anahtar; `AccessedAPITypes` **pinli çekirdeğe karşı** ölçülür | pinli çekirdek okunabildi mi (`JsonlSessionStore` bulunuyor mu) | hat-yereli |
| 7 | ikon | uygulama ikonu hâlâ şablon varsayılanı mı? | **HASH karşılaştırması**: her yoğunluk `md5` ile Flutter şablonuyla kıyaslanır (git geçmişi DEĞİL) | şablon dosyası bulunabildi mi — `md5` iki tarafta da hesaplandı mı | kurucu |
| 8 | mağaza iddiaları | liste metnindeki HER cümle ölçüme dayanıyor mu? | her canlı alan ayrı iddiaya bölünür, tek tek koda karşı | canlı alan sayısı sayılır; "tamamı denetlendi" iddiası kapsam kanıtı ister | hat-yereli (içerik) · kurucu (onay) |
| 9 | otomatik yayın | ASC `AFTER_APPROVAL` mı — onay anında kendiliğinden yayımlanır mı? | ASC `appStoreVersions.releaseType` **okunur** (app-publish MCP) | **kaynağa ERİŞİLDİ mi** — `apple_list_apps` kayıt döndürdü mü (bkz. 15) | kurucu (karar) · hat (ölçüm) |
| 10 | cihaz kanıtı | kamera/ölçüm yolu gerçek cihazda koştu mu? | `kanit/`-türü artefakt aranır; **yokluğu iddia edilmez** | artefakt dizini okunabiliyor mu | kurucu |
| 11 | sürüm | sürüm numarası bir BEYANDIR — `0.x` "ön sürüm" der | `pubspec.yaml` | — (tek satır, ölçüm değil karar) | kurucu |
| 12 | **araç zinciri** | **Gradle görevleri gerçekten KOŞUYOR mu — koşmuyorsa sebep hangi KATMANDA?** | `./gradlew :app:assembleDebug --dry-run`; düşerse **yığın izi** alınır (aşağı bak) | debug dry-run **BUILD SUCCESSFUL** vermeli; vermiyorsa üstteki hiçbir Gradle-tabanlı kalem ölçülemez | hat-yereli (teşhis) · kurucu (makine geneli düzeltme) |

### ⚠️ Kalem 12 neden EN ÖNE alınmalı — ve nasıl teşhis edilir

**Bu kalem üstteki her Gradle-tabanlı ölçümün ÖN KOŞULUDUR.** Araç zinciri
çalışmıyorsa ⑤ (imza) ve ④ (`targetSdk`) hakkında verdiğin her cevap
*"ölçemedim"*dir — ama **öyle görünmez**, çünkü build bir hata mesajıyla
düşer ve o mesaj bir sebep söylüyormuş gibi durur.

🪤 **2026-08-12'de ÜÇ oturum aynı katmanı yanlış okudu.** Mesaj çıplak bir
sürüm dizgesiydi:

```
* What went wrong:
  25.0.2
```

`25.0.2` **NDK sürümlerine benziyor** ve NDK 25.x gerçekten var → üç okuyucu
da NDK sandı. **Gerçek: JAVA sürümü** (Temurin 25.0.2); Gradle 8.14'ün gömülü
Kotlin'i (2.0.21) onu ayrıştıramıyor → `.kts` **derlenemiyor** → *hiçbir*
görev koşmuyor (debug dahil). Yığın izi bunu tek satırda söylüyordu:
`JavaVersion.parse` → `KotlinCoreEnvironment`.

**Teşhis sırası — mesajın BİÇİMİNE güvenme:**

1. `--stacktrace` ile yeniden koş; **hangi bileşenin** fırlattığını oku.
2. Katmanı adıyla ayır: **JDK** (script derlemesi) · **Android SDK/NDK**
   (bileşen çözümü) · **yapılandırma** (senin kodun) · **ağ/offline**.
3. Şüphelendiğin katmanı **ayrı ölç**: NDK kurulu mu, `flutter doctor` ne
   diyor, depoda o sürüm dizgesi geçiyor mu (JabLab'da `25.0.2` referansı
   **yoktu** — tek başına bu bile atfı çürütürdü).
4. Düzeltmeyi **çağrı başına** dene (`JAVA_HOME=… ./gradlew …`), depoya
   yazmadan. Çalışıyorsa kusur **makinede**, depoda değil.

> ***Bir hata mesajının BİÇİMİ, kaynağı hakkında bir İDDİADIR — ve o iddia
> da ölçülmelidir.*** Çıplak bir sürüm dizgesi hangi bileşene ait olduğunu
> söylemez; benzerlik bir kanıt değildir.

⛔ **Düzeltmenin ŞEKLİ hat kalemi DEĞİL:** `gradle.properties`'e makineye
özel `org.gradle.java.home` yazmak depoyu **başka makinede ve CI'da kırar**;
Gradle yükseltmesi **beş depoyu** birden değiştirir. Kalıcı çözüm (makine
geneli `flutter config --jdk-dir` mi, yükseltme mi) **venture-ötesidir** —
LifeOS ve Burun Farkı da aynı makinede. Hat yalnız **teşhis eder ve
raporlar**; ara çözüm çağrı başına `JAVA_HOME`.

---

## 13 · DERLEME DOĞRULAMASI — metin kapısı bunu YAPAMAZ

| # | katman | soru | nasıl ölçülür | pozitif kontrol | sınıf |
|---|---|---|---|---|---|
| 13 | derleme | eklediğim **build-sistemi kodu** (Kotlin DSL / Gradle / native config) gerçekten DERLENİYOR mu? | kaynak/metin kapısı YETMEZ — gerçek araç koşumu (`JAVA_HOME=… ./gradlew <görev> --dry-run`) | **sabotaj**: kasıtlı sözdizimi hatası konur, koşum **kırmızı** yanmalı; geri alınır, **yeşile** döner | hat-yereli |

> ***Bir KAYNAK/METİN kapısı, denetlediği kodun DERLENDİĞİNİ doğrulayamaz.***

2026-08-12'de iki hat aynı gün aynı işi yaptı (release imza kapısı) ve
**metin kapıları ikisinde de yeşildi.** JabLab'ın Kotlin'i derlendi;
**Lissom'unki derlenmedi** — `Unresolved reference: util`, çünkü Gradle
Kotlin DSL'inde `java` adı `JavaPluginExtension`a çözümlenip **paket adını
gölgeliyor** (`import java.util.Properties` zorunlu). Lissom'un cümlesi:

> *"Metin kapım 'koruma VAR' diyordu ve **haklıydı** — ama koruma
> **derlenmiyordu.** Bir kapının doğrulayabildiği şey, kapının **GÖRDÜĞÜ
> KATMANLA** sınırlıdır."*

⚠️ Derlenmeyen bir build script'i yalnız korumayı kaybettirmez: **debug
dâhil her build'i kırar** — sessiz bir boşluk değil, gecikmiş bir kırmızı.

## 14 · KAPI KONTROLÜ İKİ YÖNLÜ OLMALI

| # | katman | soru | nasıl ölçülür | pozitif kontrol | sınıf |
|---|---|---|---|---|---|
| 14 | kapı sağlığı | kurduğum kapı, **koruduğu ürünün kendisini** engelliyor mu? | kaçış/izin yolu varsa koşulur (ör. `-PallowDebugSigning=true`) | **iki yönlü**: ötmesi gerekende **ötüyor** mu · ötmemesi gerekende **susuyor** mu | hat-yereli |

Lissom ölçtü: `-PallowDebugSigning=true` → **BUILD SUCCESSFUL + "Play'e
yüklenemez" uyarısı.** → ***Bir kapı, koruduğu ürünün KENDİSİNİ
engellememelidir.*** Yalnız *ötme* tarafını sınamak yetmez: yanlış-pozitif
üreten kapı kapatılır, ve **kapatılan bir kapı hiç kurulmamış olandan
kötüdür** — güven bırakır, koruma bırakmaz.

### ⛔ Kalem 9 hakkında — JabLab'ın kendi durumu

`AFTER_APPROVAL` **Lissom'un bulduğu kalem** ve JabLab'da bugün
**uygulanamaz**: ASC kaydı yok, sürüm yok, ayar yok. **Ama listeden
düşmüyor** — çünkü ③b (gönderim) açıldığı gün bu ayar **varsayılan olarak**
karşımıza çıkacak ve *"onay olur olmaz otomatik yayın"* sessiz bir karardır.
***Bugün uygulanamaz olması, denetlenmeyecek olması demek değildir.***

---

## YÖNTEMİN KENDİ SINIRI

Bu belge **bir hattın** denetimini tarif eder. Kalem 5'in nasıl bulunduğu
kanıtıdır ki bu yetmez: **şablon kaynaklı kusurlar ancak AİLE taramasıyla
görünür.** Yöntemin son adımı bu yüzden hat-dışıdır ve koordinatöre aittir:

> **Adım N:** hattın listesi çıktıktan sonra, **şablondan gelen kalemler**
> (⑤⑥⑦⑧④) aile düzeyinde çapraz-taranır. Bir hattın *"bende yok"*u,
> beşinde de aynıysa **bulgu değil arka plandır.**

## ⚠️ ŞABLON KALEMLERİ "GÖRÜNÜŞE" GÖRE GEÇİLEMEZ — KİMLİKLE ÖLÇÜLÜR

Gravita bu yöntemi koştu ve **hiç bakmadığı ÜÇ kalem** çıktı — üçü de
şablon kaynaklı: **imza · `PrivacyInfo` · ikon.** Üçüncüsünü *varsayacaktı*;
`md5` karşılaştırması **birebir** çıktı → ***tahmin değil KİMLİK.***

JabLab'da aynı ölçüm (2026-08-12): Android **5/5 yoğunluk** ve **iOS 1024**
Flutter şablonuyla **bayt-birebir** (`13e9c72e…` / `c785f893…`). Bu ölçüm
git geçmişi okunamadığında bile geçerli — ve o gün `git log` binary yolda
`mmap failed` verdiği için **tek yol buydu.**
→ ***Bir varlığın "değiştirilmemiş" olduğu GEÇMİŞİNDEN değil KİMLİĞİNDEN
okunur;*** geçmiş okunamayabilir, hash okunur.

> **Gravita, yöntemi KULLANAN hat olarak:** ***"Kendi seçtiğin kalemleri
> kapatmak, listeyi kimin yazdığını sormadan denetim yapmaktır."***

Bu cümle, bu belgenin **neden var olduğunun** en iyi ifadesi.

---

## 15 · ERİŞİM GEREKTİREN KALEM — "YOK" ile "ÖLÇÜLEMEDİ" AYRI SINIFTIR

| # | katman | soru | nasıl ölçülür | pozitif kontrol | sınıf |
|---|---|---|---|---|---|
| 15 | erişim | erişim gerektiren bir kalemi ölçerken **kaynağa gerçekten ERİŞTİM mi**? | kalemi ölçmeden önce kaynağın kendisi yoklanır (ör. `apple_list_apps` kayıt döndürüyor mu) | **erişim kanıtı**: kaynak **boş olmayan** bir sonuç döndürmeli; dönmüyorsa cevap *"YOK"* değil ***"ÖLÇÜLEMEDİ"*** | hat-yereli (ölçüm) |

> ***Bir kaydın DEPODA olmaması, MAĞAZADA olmaması demek değildir.***
> Erişim gerektiren bir kalemi **erişimsiz** ölçmeye çalışmak *"yok"* cevabı
> üretir — **ve o cevap ölçüm gibi görünür.**

🪤 **İKİ HAT AYNI HATAYI YAPTI, ikisi de kendi deposuna baktı:**
Gravita ASC'yi **depoda** aradı (`grep com.yulalab.gravita`), bulamayınca
*"kayıt YOK → kalem uygulanamaz"* yazdı. **JabLab aynısını yaptı** — ⑨'un
ilk hâli *"JabLab'da ASC kaydı YOK, kalem uygulanamaz"* diyordu ve dayanağı
kurucu brifinin *"repoda sıfır taslak … store kaydı bekliyor"* satırıydı:
**devralınmış, ölçülmemiş bir iddia.**

✅ **ÖLÇÜLDÜ (2026-08-12, bu hattın kendi erişimiyle — koordinatörün
sonucunu kopyalamadan):** `apple_list_apps` **9 uygulama** döndürdü ve
JabLab **kayıtlı**: `id 6794715669` · *"JabLab: Shadow Training"* ·
`com.yulalab.jablab` · sku `yula-jablab-2026` · oluşturma **2026-07-25**.
`apple_list_versions` → sürüm **`1.0`**, durum `PREPARE_FOR_SUBMISSION`,
**`releaseType: AFTER_APPROVAL`.**

→ Kalem **uygulanamaz DEĞİL, CANLI**: bugün gönderilip onaylansa **kimse
bir düğmeye basmadan yayımlanır.**

📌 Ve bu ölçüm iki satırı daha çürüttü:
* *"ASC erişimi hiçbir hatta yok"* — **yanlış**, bu oturumdan okundu.
* Sürüm kalemi (⑪) *"pubspec `0.1.0+1`"* diyordu; **ASC'de sürüm zaten
  `1.0`** — yani iki yüzey **birbirinden farklı** ve karar sanıldığından
  daha ilerlemiş.

⚠️ **Kalemin sınıfı da ikiye bölündü** (⑤ imzayla aynı desen): **ölçüm**
hat-yereli ve bugün yapılabiliyor · **karar** (otomatik yayın açık mı
kalsın) kurucunun.
