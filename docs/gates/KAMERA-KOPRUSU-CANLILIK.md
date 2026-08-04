# Kamera köprüsü — canlılık durumu (J-071 / J-072)

**Sözleşme:** motion-core `docs/70-KAMERA-KOPRUSU-SOZLESMESI.md` §7 ·
**Plugin:** `motion_camera-v0.1.1` (`f34acd8…`) ·
**Cihaz-harness:** JabLab (§7 notu: *"canlılık koşumu doğal sahibi cihazı olan
app oturumu"*)

> **İKİ BEYAN AYRIDIR ve karıştırılmayacak:**
> **DERLENİYOR** (§7.1-7.2 ✅ kapandı) · **CİHAZDA ÇALIŞIYOR** (§7.3-7.7 ⏳ açık).
> Aşağıdaki emülatör sayıları **TESİSAT KANITIDIR**, gerçek-insan ölçümü DEĞİL.

---

## ✅ §7.1 — iOS: pod çözülür, Swift derlenir

| ölçüm | sonuç |
|---|---|
| `pod install` | `MediaPipeTasksVision (0.10.21)` + `MediaPipeTasksCommon (0.10.21)` kuruldu |
| Swift derleme | `xcodebuild -scheme motion_camera` → **BUILD SUCCEEDED** |
| framework | 458 KB, 168 sembol, `swiftmodule` üretildi |

**İKİ GERÇEK KIRIK bulundu ve düzeltildi** (v0.1.0 → v0.1.1):
`Cannot find 'ImageProcessingOptions' in scope` · `Extra argument
'imageProcessingOptions' in call`. Pod'un kendi başlıkları okundu: 0.10.21'de
o tip **hiç yok** ve `detect(videoFrame:timestampInMilliseconds:)` böyle bir
parametre almıyor; bu sürümün rotasyon yüzeyi
`MPImage(pixelBuffer:orientation:)` (`.down` = 180°). Ters-geçiş geri-eşlemesi
(x→1-x, y→1-y) **aynen korundu**.

**App tarafı üç tesisat engeli:** Podfile `platform :ios, '14.0'` + deployment
target 13→14 · `use_frameworks! :linkage => :static` (MediaPipe STATİK
xcframework dağıtıyor) · `ios/Flutter/Profile.xcconfig` **yoktu** → §7.3-7.4
perf sayıları Profile yapısından geleceği için oluşturuldu.

⚠️ **iOS CİHAZ paketleme ayrı bir engel:** codesign "detritus" hatası
(macOS 26 + Xcode 26 aile gotcha'sı). §7.1'in sorusu "Swift derleniyor mu"
olduğu için pod-target derlemesiyle kanıtlandı; **cihaz koşumu günü bu
çözülmeli** (kurucu-manuel kalemi).

**PANZEHİR — ÇİFTE EMSALLİ, cihaz gününün İLK adımı** (koordinatör M-F-197;
Gravita iOS aynı duvara çarptı, LifeOS kaydıyla aynı kök):

> Çözüm **wrapper DEĞİL** — `~/.local/bin/codesign` tek başına yetmiyor,
> ölçüldü. Gerçek kök: tüm motion app'leri `~/Documents` altında ve orası
> iCloud'a senkronlanıyor; iCloud'un `build/` içine koyduğu artıklar
> codesign'a "detritus" olarak görünüyor.

```bash
cd ventures/jablab/app
mkdir -p ~/jablab_buildout
rm -rf build && flutter clean          # ÖNCE temizle
ln -s ~/jablab_buildout build          # SONRA symlink — sıra ÖNEMLİ
```

Emsaller diskte **doğrulandı**: `~/gravita_buildout` ve `~/lifeos_buildout`
ikisi de mevcut. İkinci tuzak: **bayat `native_assets`** — `flutter clean`
o yüzden aynı adımda.

> ⚠️ **SIRA DÜZELTİLDİ (2026-08-04, J-092 koşumunda ölçüldü).** Önceki hâli
> `rm -rf build && ln -s … && flutter clean` idi ve **kendi symlink'ini
> siliyordu**: `flutter clean` `build`i bir dizin sanıp kaldırıyor, symlink
> dahil. Komut hatasız bitiyor, `ls -ld build` "No such file or directory"
> diyor ve bir sonraki derleme panzehir HİÇ uygulanmamış gibi codesign'da
> düşüyor. Sessiz-kırılma sınıfı: çıktı temiz, sonuç yok.

**Panzehir 2026-08-04'te UYGULANDI ve İŞE YARADI** (artık "cihaz günü
bekliyor" değil): symlink öncesi `flutter run -d <sim>` → *"Command CodeSign
failed"* + *"Command Libtool failed"*; symlink sonrası aynı komut → uygulama
iPhone 17 Pro Max simülatöründe **koştu**. Yani bu duvar iOS **simülatöründe
de** çıkıyor, yalnız gerçek cihazda değil — ve panzehir ikisinde de aynı.

`build/` şu an `~/jablab_buildout`a bağlı ve öyle kalıyor. Eski "symlink
bilinçli kurulmadı (eşzamanlı oturum riski)" notu artık geçersiz.

## ✅ §7.2 — Android: Gradle çözer, Kotlin derlenir

Gradle `tasks-vision:0.10.29` pinini çözdü, Kotlin derlendi, APK üretildi —
**ilk denemede**. Pin'in gerçekten çözüldüğü **varsayılmadı, APK açıldı**:

| ABI | `libmediapipe_tasks_vision_jni.so` |
|---|---|
| arm64-v8a | 10 422 840 B |
| armeabi-v7a | 6 920 096 B |
| x86_64 | 12 596 280 B |

Model asset de doğrulandı: `assets/flutter_assets/assets/models/
pose_landmarker_full.v1.task` = **9 398 198 B** (MODELS.md'deki beklenen
boyutla birebir).

---

## 🟡 EMÜLATÖR TESİSAT SMOKE — `judgedRatio` ilk kez ÖLÇÜLDÜ

Koşum: `flutter test integration_test/camera_smoke_test.dart -d emulator-5554`
(Pixel 6 AVD, sanal sahne kamerası).

```
session                 = running
elapsed                 = 40 s          ← §7.3'ün istediği ≥30 sn
envelopes               = 1126
judgedRatio             = 0.810
judged/s                = 23.7
captured/s              = 29.3
meanInferenceUs         = 28571         (28,6 ms)
dropped (session)       = 54
clockDomain             = monotonic     ← §7.6
frame                   = 480×640
modelVersion (envelope) = mp-android-0.10.29+pose_landmarker_full/float16/1
library                 = mp-android-0.10.29
no-person passes        = 1126 / 1126
```

### Bu sayılar NEYİ kanıtlıyor

**Kanal + çıkarım + zarf akışı AYAKTA.** 40 saniye boyunca 1126 zarf aktı,
latest-wins geri-baskı çalıştı (54 kare düştü, `judgedRatio` 0,81), saat
alanı `monotonic` bildirildi, ve zarf **pinli model kimliğini taşıdı**
(§6: kütüphane etiketi + app'in beyan ettiği `modelId` birleşik).

### Bu sayılar NEYİ KANITLAMIYOR

**`no-person passes = 1126 / 1126`** — model 1126 kez koştu ve **her seferinde
kimseyi görmedi.** Emülatörün sanal sahnesinde insan gövdesi yok, dolayısıyla:

* **poz doğruluğu hakkında hiçbir şey ölçülmedi;**
* `meanInferenceUs = 28,6 ms` bir **emülatör** sayısıdır (host CPU + ARM
  çeviri) — cihaz perf bütçesi DEĞİL. ADR-001'in "2× dual-pass maliyeti"
  varsayımı **sınanmadı** (§7.4 tek-geçiş koşuldu);
* `judgedRatio = 0,81` gerçek bir termal/yük profilinde farklı olacak;
* §7.5 (iOS buffer-tutma), §7.7 (ters-geçiş fikstürü) bu koşumda **hiç
  dokunulmadı**.

Bu ayrımı silmek en kolay sahte-ilerleme yolu olurdu: akan bir zarf akışını
"kamera çalışıyor" diye raporlamak. **Akan şey TESİSAT.**

### Yol boyunca bulunan GERÇEK bir ürün boşluğu

Smoke ilk koşumda `camera-permission-denied` ile düştü. Sebep test artefaktı
DEĞİLDİ: plugin izni **bilinçli olarak istemiyor** (sözleşme §1 katman
sınırı — isimli retle döner, UX'i app'e bırakır) ve **harness de
istemiyordu**. Yani boşluk gerçekti ve cihaz gününde aynı yerde patlayacaktı.
İzin isteği app katmanına eklendi (`permission_handler`), Android
`CAMERA` izni + `NSCameraUsageDescription` beyan edildi.
`uses-feature android:required="false"` — kamerasız cihazda kurulum
ENGELLENMEZ, çünkü Fitness hattı kamerasız TAM çalışıyor ve kanıtlı
(`FITNESS-SHIP-KANITI.txt`).

---

## ⏳ Açık kalanlar — GERÇEK CİHAZ (kurucu-manuel)

| §7 | kalem | JabLab'da ne açılır |
|---|---|---|
| 7.3 | gerçek cihazda ≥30 sn, gerçek `judgedRatio`/`meanInferenceUs` | ilerleme kapılarının `withValidAnalysisRatio: 0.7` girdisi |
| 7.4 | dual-pass maliyeti (ADR-001 "2×" sınanır) | `hiit`in 30 sn patlaması en sıkı vaka |
| 7.5 | iOS buffer-tutma → `dropped` patlaması | `LiveState.noVerdict` "göremiyorum" yolunun gerçek tetiği |
| 7.6 | `clock:"unknown"` bir vendor cihazda gözlenir | tur/patlama sınırları tek-saat varsayıyor |
| 7.7 | ters-geçiş geri-eşlemesi el-standı fikstürüyle | `StanceDetector` taraf-etiketi (M-F-06) |
| 7.8 | ön-izleme yüzeyi | **KULLANICI-UI'ı hâlâ BLOKLU** — dev harness'ta bilinçli olarak ön-izleme YOK |

Ek olarak: **iOS cihaz paketleme codesign engeli** (yukarıda) cihaz gününün
ilk işi.

**Kural aynen duruyor: ön-izleme bağlanmadan hiçbir app "kamera çalışıyor"
DEMEZ.** Bu doküman da demiyor.
