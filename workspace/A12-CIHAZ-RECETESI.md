# 📱 A12 — CİHAZ GERÇEĞİ REÇETESİ (imzaya kadar hazır)

> **Ölçüldü:** 2026-08-13 (`J-243` turu) → **2026-08-14 gece vardiyasında YENİDEN ÖLÇÜLDÜ ve
> merkezi iddiası DÜZELTİLDİ** (`J-246`). Tetik: koordinatör hükmü **H-6**.
> **Durum:** zincirin **yedi halkasından altısı ✅**, tek eksik **profilin CİHAZ TAZELEMESİ**.

---

## 🔴 ÖNCEKİ SÜRÜMÜN YANLIŞIYDI — ADIYLA

Bu dosyanın 08-13 sürümü *"provisioning profile YOK (portalda 0, yerelde 0)"* diyordu ve
kurucudan **profil ürettirmeyi** istiyordu. **Yerel ölçüm YANLIŞ DİZİNE bakıyordu.**

| | eski ölçüm | 08-14 ölçümü |
|---|---|---|
| bakılan dizin | `~/Library/MobileDevice/Provisioning Profiles/` (**ESKİ**) | `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` (**Xcode'un yeni yeri**) |
| bulunan profil | **0** (jablab için) | **9** — aralarında `T5HZGYBWK8.*` **JOKERİ** |

> ***BİR YOKLUK ÖLÇÜMÜ, DİZİN SEÇİMİ KADAR GEÇERLİDİR.*** (H-6, Lissom ölçtü.)

## 🔴 AMA H-6'NIN DE YARISI JABLAB İÇİN EKSİK — KAPSAMA **İKİ EKSENLİDİR**

H-6 *"joker beş Motion app'ini birden kapsıyor"* diyor. Bu yalnız **bundle-ID ekseninde** doğru.
Bir **development** profili ayrıca `ProvisionedDevices` listesi taşır ve **kurulum o listeye üyelik ister**.

| eksen | joker `T5HZGYBWK8.*` | sonuç |
|---|---|---|
| bundle-ID | `com.yulalab.jablab` ⊂ `*` | ✅ kapsıyor |
| **cihaz** | listede **yalnız `00008132-001A70163AD3801C`** | ❌ **kurucunun telefonu YOK** |

Kurucunun bağlı telefonu **`00008120-001804D83E13C01E`** (`devicectl list devices --json-output`
ile ölçüldü — model adından ÇIKARILMADI). Bu UDID `lifeos` · `lifeos.LifeOSWidget` ·
`burunfarki` · `braavolabs` dev profillerinin **dördünde de var**, jokerde **yok**.

> ⚠️ **H-6'nın kanıtı bu ayrımı GÖREMEZ.** *"İmzalı cihaz derlemesi geçti"* bir **derleme**
> ölçümüdür; cihaz üyeliği ancak **kurulumda** bağlar.
> ***BİR DERLEMENİN GEÇMESİ, BİR KURULUMUN OLACAĞININ KANITI DEĞİLDİR.***

---

## ZİNCİR — ne ölçüldü, hangi komutla

| halka | durum | ölçüm |
|---|---|---|
| Bundle ID portalda kayıtlı | ✅ | ASC API → `3JP6SPRMQ3` · `com.yulalab.jablab` · UNIVERSAL · seed `T5HZGYBWK8` |
| Cihaz portalda kayıtlı | ✅ | `Mustafa Kaan iPhone'u` · iPhone 14 Pro Max · **ENABLED** · `00008120-001804D83E13C01E` |
| `Apple Development` imza kimliği yerelde | ✅ | `security find-identity -v -p codesigning` → `kocakmkaan@outlook.com (W2BWHNL5L2)` |
| Proje imza ayarı | ✅ | `project.pbxproj`: `CODE_SIGN_STYLE = Automatic` · `DEVELOPMENT_TEAM = T5HZGYBWK8` |
| **Profil VAR ve bundle'ı kapsıyor** | ✅ **(08-14 düzeltmesi)** | joker `T5HZGYBWK8.*`, son kullanma **2027-05-12** |
| **🆕 İmzalı cihaz derlemesi GERÇEK JabLab üretiyor** | ✅ **(08-14'te ilk kez ölçüldü)** | `xcodebuild … -destination 'generic/platform=iOS'` **exit 0**, `-allowProvisioningUpdates` OLMADAN. Artefakt: `Identifier=com.yulalab.jablab`, `Authority=Apple Development: kocakmkaan@outlook.com`; pozitif kontrol → 5,6 MB Dart anlık görüntüsü + `library.json`·`curriculum.json`·`boxing.v3.json` + 9,4 MB `pose_landmarker_full.v1.task` |
| **Profil hedef cihazı içeriyor** | ❌ | gömülü `embedded.mobileprovision` → `ProvisionedDevices` = **yalnız `00008132-…`** |
| Cihazın o anki hâli | ⚠️ | `tunnelState=disconnected` · `pairingState=paired` · transport `localNetwork` — **eşleşmiş olmak, bağlı olmak değildir** |

---

## KURUCUNUN ADIMI — tek oturum, ~3 dakika (ADIM DEĞİŞTİ)

Artık gereken **profil üretmek değil, profili TAZELEMEK** — yani jokere bu telefonu eklemek.
`CODE_SIGN_STYLE = Automatic` olduğu için Xcode bunu cihaz bağlıyken kendisi yapar.

1. iPhone'u **kabloyla** bağla, kilidini aç, *"Bu bilgisayara güven"* de.
   ⚠️ Şu an telefon yalnız **yerel ağdan eşleşmiş** ve tüneli kapalı; kurulum için kablo en güvenlisi.
2. **Xcode → Settings → Accounts** → `kocakmkaan@outlook.com` ekli olmalı.
3. ```bash
   open /Users/mustafakaankocak/Documents/YULAlab-AI/ventures/jablab/app/ios/Runner.xcworkspace
   ```
4. Hedef olarak **Mustafa Kaan iPhone'u** → **Run (⌘R)**. Xcode joker profili **cihazı ekleyerek
   yeniden indirir**. (Eşdeğeri: `xcodebuild … -allowProvisioningUpdates` — ama bu kurucu
   hesabında yapılandırma değiştirir, **hat KOŞMAZ**.)
5. Telefonda ilk açılışta: **Ayarlar → Genel → VPN ve Cihaz Yönetimi** → sertifikaya **güven**.

Tazeleme bir kez olduktan sonra hat da koşabilir:
```bash
cd /Users/mustafakaankocak/Documents/YULAlab-AI/ventures/jablab/app && flutter run -d 00008120-001804D83E13C01E
```

**Tazelemenin OLDUĞU nasıl doğrulanır** (tahminle değil, ölçümle):

> 🔴 **BU DOSYANIN İLK SÜRÜMÜ BURAYA BOZUK BİR KOMUT YAZDI — ve kendi kuralıma düştüm.**
> Önerilen `grep -rl "<UDID>" *.mobileprovision` **ÇALIŞMAZ**: profil dosyası CMS ile
> sarılmış İKİLİ bir dosyadır, UDID düz metin olarak aranamaz. **Pozitif kontrolle ölçüldü:**
> jokerin içerdiği BİLİNEN cihaz (`00008132-…`) ham `grep` ile **bulunamadı**, `security cms -D`
> ile çözülünce **bulundu**. ⇒ O komut, başarılı bir tazelemeden sonra bile *"tazelenmemiş"*
> raporlardı. ***BİR ARACIN BULAMAMASI, ARANAN ŞEYİN YOKLUĞU DEĞİLDİR*** (J-243 ⑤'in aynısı,
> bu kez kendi reçetemde).

Doğru ölçüm — **çöz, sonra ara**:
```bash
for f in ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/*.mobileprovision; do
  security cms -D -i "$f" > /tmp/p.plist 2>/dev/null || continue
  id=$(plutil -extract Entitlements.application-identifier raw -o - /tmp/p.plist 2>/dev/null)
  if plutil -extract ProvisionedDevices xml1 -o - /tmp/p.plist 2>/dev/null | grep -q "00008120-001804D83E13C01E"; then
    echo "TELEFONU İÇERİYOR: $id"
  fi
done
```
`T5HZGYBWK8.*` ya da `T5HZGYBWK8.com.yulalab.jablab` bu listede çıkıyorsa tazeleme olmuştur.
En kesin ölçüm ise **artefaktın kendisi**: `tool/ios_device_build.sh <UDID>` (kapı 3/3).

### ⚠️ 2026-08-14 GECE: TAZELEME DENENDİ, CİHAZI EKLEMEDİ — sebep ölçüldü

H-9 yetkisiyle `-allowProvisioningUpdates` **koşuldu** (`exit 0`), ama üretilen artefakt hâlâ
**bayat jokeri** gömüyor (`ProvisionedDevices` = yalnız `00008132-…`).
**Ölçülen sebep adayı:** derleme hedefi `generic/platform=iOS` idi ⇒ portala **eklenecek somut
bir cihaz yoktu**, ve eşleşen joker **yeniden üretilmeden yeniden kullanıldı**.
⚠️ Bu bir **hipotez**, ölçülmüş sonuç değil — kanıtı ancak telefon bağlıyken alınabilir.
⛔ **Bayat joker SİLİNMEDİ:** dosya paylaşımlı makinede dört hattın da kullandığı ortak durum;
gece yarısı silmek başka hatları kırardı. *Bir düzeltmenin bedelini komşu hat ödememeli.*

---

## ⛔ CİHAZ DERLEMESİNDEN ÖNCE — ZORUNLU KAPI (08-14'te bedelle öğrenildi)

```bash
grep FLUTTER_TARGET ios/Flutter/Generated.xcconfig
```
**`lib/main.dart` değilse DUR.** `flutter test`/`integration_test` koşumları bu değeri geçici bir
`flutter_test_listener/listener.dart` yoluna yazıyor; temp dizin silinince derleme ya patlar
(`exit 65`) ya da **sessizce yanlış şeyi derler**. 08-13 12:11'den 08-14'e kadar bu ağaçtaki her
iOS derlemesi böyle zehirliydi; *"84,1s'de geçen ama debug bağlantısı kurulamayan"* derleme ve
*"yalnız durum çubuğu görünen siyah render"* bununla tutarlı.
Panzehir: `flutter build ios --config-only --release` (dosya **gitignore'da**, depo kusuru değil).
> ***BİR DERLEMENİN YEŞİL OLMASI, DERLEDİĞİ ŞEYİN SENİN ÜRÜNÜN OLDUĞUNUN KANITI DEĞİLDİR.***

---

## A12 NE ZAMAN `✅` OLUR — kanıt ölçütü (DEĞİŞMEDİ)

Ölçüt: *"gerçek cihazda **en az A1 akışı** koştu; kanıt ekran kaydı ya da cihaz logu."*
⇒ Kurulum tek başına **yetmez**. Cihazda yürünecek akış:

```
taze kurulum → karşılama (onboarding) → DÜĞMEYE BASARAK geç → seçim → oturum → SONUÇ
```

Kanıt: telefonda Ekran Kaydı ya da bağlıyken `xcrun devicectl device screenshot`.
⚠️ **Bayrağı elle set ederek geçme** — A2 tam olarak bunu yasaklıyor; karşılama **düğmeyle** geçilmeli.
⚠️ Ve bayrağı elle yazacaksan yeri `Application Support`, `Documents` **değil** (`J-244` ⑧).

---

## ⛔ HATTIN DOKUNMADIĞI

- Profil **üretmek/tazelemek** (`apple_create_profile`, `-allowProvisioningUpdates`) → kurucunun
  hesabında kalıcı yapılandırma. **Yapılmadı, yapılmayacak.**
- Kurucunun telefonuna **kurulum** → yapılmadı.
- Android tarafı: `flutter build apk --release` **bilerek exit 1**
  (`J-215` kapısı: `key.properties` yok, keystore **B1**'de). **Kusur değil, ateşlenmiş kapı.**
