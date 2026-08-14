# 🥊 JABLAB — GECE VARDİYASI DEVRİ, 2026-08-14

> Önceki devir: `DEVIR-2026-08-13-OTURUM.md` (gündüz). Bu not gecenin bıraktığı yeri devreder.
> ⛔ Hiçbir şey sessizce geri alınmadı; her sabotaj geri alındı ve kalıntı ölçüldü.

## 0. MÜHÜR — ölçüldü, beyan edilmedi

| şey | değer |
|---|---|
| HEAD | **`4c20557`** — `J-260: A3 ile yüzey kapısı BİRLEŞTİRİLMEDİ — ölçülüp reddedildi` |
| commit | **251** (gece +11) |
| ağaç | **temiz** · sabotaj kalıntısı **0** (her turda ayrıca ölçüldü) |
| push-bekleyen | **0** |
| DEFTER son kayıt | **`J-260`** |
| kapılar (borusuz) | `analyze` **0** · app **344/344** · motor **125/125** · tazelik **0** + öz-test **0** · commit hook **4/4** |

## 1. ⚠️ İLK İŞ — SİMÜLATÖRE GÜVENME, ÖNCE DOĞRULA

Bu gecenin en pahalı dersi. **Cihaz derlemesi simülatörü zehirliyor** (`J-253`):
bir iOS cihaz derlemesinden sonra artımlı `flutter run`, simülatöre **cihaz platformlu**
`objective_c.framework` kuruyor → dyld reddediyor → `path_provider` **her çağrıda** patlıyor →
onboarding bayrağı ve seans geçmişi **sessizce ölüyor**, ve ekranda *"kaydetmiyor"* gibi görünen
**sahte bir ÜRÜN kusuru** üretiyor.

```bash
vtool -show-build "$(xcrun simctl get_app_container <UDID> com.yulalab.jablab app)/Frameworks/objective_c.framework/objective_c" | grep platform
```
**`platform IOSSIMULATOR` görmeden o koşumdaki hiçbir kalıcılık gözlemine güvenme.**

### 🔴 KURTARMA — `flutter clean` TEK BAŞINA YETMEZ (H-14 ile düzeltildi)

Bu notun ilk sürümü *"`flutter clean` + `flutter run`"* diyordu. **Yetersiz** — Ostinato
(`O-137`) ölçtü ve koordinatör `H-14`te hükmetti: **`build/` bir SEMBOLİK BAĞLANTI**
(iCloud panzehiri → `~/jablab_buildout`) ⇒ `flutter clean` **yalnız bağlantıyı siler**,
hedefteki zehirli artefakta **hiç dokunmaz**.
> ***BİR PANZEHİR, BAŞKA BİR PANZEHİRİN ETKİ YOLUNU KESEBİLİR — VE İKİSİ DE TEK TEK
> DOĞRUYKEN BİRLİKTE HİÇBİR ŞEY YAPMAZLAR.***

Bu, benim 03:30'da ölçtüğüm ve **açıklayamadığım** anomalinin sebebi: clean koştum,
symlink'i geri koydum, `flutter run` yine **platform 2** verdi — çünkü zehir hedefte duruyordu.
Üç mekanizma hipotezim çürümüştü; **dördüncüsünü Ostinato buldu.**

```bash
rm -rf "$(readlink build)/native_assets/ios"      # ← ASIL TEMİZLİK: symlink HEDEFİ
flutter clean && ln -s ~/jablab_buildout build && flutter run -d <sim>
```
📌 **08-14 07:10'da bu ağaç ÖLÇÜLDÜ ve TEMİZ:** symlink hedefi ve kurulu paket, ikisi de
`platform IOSSIMULATOR`. Yani şu an zehir YOK — ama bir cihaz derlemesi koşarsan geri gelir.

> 🪤 Ve tetikleyici **bu gece yazdığım kapının kendisi** (`tool/ios_device_build.sh`, bir cihaz
> derlemesi). Betiğin sonunda artık ölçülmüş yan-etki uyarısı + geri alma reçetesi var.
> ⚠️ **Mekanizma hakkında üç hipotezim çürüdü** (`flutter test` · `SdkRoot` hatası · *"clean her
> zaman düzeltir"*). Sağlam kalan İKİ şey: **cihaz derlemesi → sonraki koşum zehirli** (tek
> değişkenle üretildi) ve **güvenmeden önce doğrula**. Dördüncü tahmini yayma.

## 2. GECENİN İŞİ — 11 commit, hepsi push'lu

| kayıt | ne |
|---|---|
| `J-246` | **Yeşil derleme ≠ senin ürünün.** `FLUTTER_TARGET` zehri: 13 Ağu 12:11'den beri her iOS derlemesi silinmiş bir test-listener stub'ını derliyordu. Yeni kapı `tool/ios_device_build.sh` (girdi · çıktı · kurulabilirlik). H-6 iki eksenli olarak düzeltildi. |
| `J-247` | **Ürün derinliği:** prova aşaması `const` idi, 19 dersin 19'unda aynı ekran. `RehearseMaterial` (Drill+None), içerik `library.json`dan — **hiçbir dizge uydurulmadı**. Asıl kapı **AYRIŞMA** testi. |
| `J-248` | **Simülatörde kalıcılık kırık** — kök sebep `objective_c.framework` platform 2. Önceki tur bunu *"test artefaktı"* saymıştı; etiket bir turu maskeledi. **Ürün yalan söylemedi:** dürüstlük kutusu gerçek bir arızayı doğru bildiriyordu. |
| `J-249` | Öz-kusur: A12 reçetesine yazdığım `grep` doğrulaması **bozuktu** (CMS ikili dosya). Kapının muafiyet sözlüğü **genişletilmedi** — *kaydı gerçeğe uydur, kapıyı kayda değil*. |
| `J-250` | **Beşinci canlı yalan:** canlı yüzey *"analysis runs without it"* derken arıza cümlesi *"Nothing is analysed without it"* diyordu; ve altyazı **koşulsuzdu**, dört daldan üçünde **yanlıştı**. `analysisRunning` required. |
| `J-252` | `SkeletonPreview` **ekran değil bileşen** — devir notunun *"asıl soru"*su ölçümle kapandı. |
| `J-253` | Cihaz derlemesi → simülatör zehri (yukarıda). |
| `J-254` | **Ayarlarda ÖLÜ satın alma düğmesi** — ekranın en baskın öğesi, hiçbir şey yapmıyordu, ve olmayan bir ödeme adımını ima ediyordu. Kaldırıldı + 3 kapı. |
| `J-256` | ⭐ **"Bitmiş ürün" ölçütü #4 İLK KEZ uçtan uca kanıtlandı** — gerçek seans tamamlandı, disk kaydı her alanında dürüst (`workedSeconds:17` gerçek · `unitsCompleted:0`/`plannedUnits:4` ⇒ *Done'a basmak kredi satın almıyor* · `lessonClass:"unscored"` mühürlü · **landmark verisi YOK** ⇒ J-211'in gizlilik iddiası diskte doğrulandı). Bu, kalıcılık onarılana kadar **imkânsızdı**. |
| `J-257` | `0 min` hem *"hiç çalışmadın"* hem *"bir dakikadan az"* demekti — 17 sn çalışan, hiç çalışmayanla aynı dizeyi görüyordu (J-096 sınıfı). `under a minute`; saniye hâlâ gizli; **negatif ikiz** gerçek sıfırı koruyor. Gerçek ekranda doğrulandı. |
| `J-258` | **H-14 düzeltmesi:** yaydığım panzehir eksikmiş — `flutter clean` symlink HEDEFİNE dokunmuyor (Ostinato `O-137` buldu). İki yerde düzeltildi; ağacım ölçüldü, **temiz**. H-15 uyumu: kendi simülatörüm, UDID gece boyu sabit. |
| `J-259` | ⏳ **AÇIK (koordinatörde):** özet ekranı `_roundsCompleted`/`_workedSeconds`i **tutuyor ve diske yazıyor** ama ekrana geçirmiyor — 4 turu bitiren kullanıcı yaptığı iş hakkında tek kelime görmüyor. J-251 ile aynı desenin ikinci yüzü. |
| `J-260` | Devralınan *"A3 ile birleştir"* önerisi **ölçülüp reddedildi** — birimler farklı (30 kontrol ↔ 13 yüzey). *Bir önerinin uygulanmaması da teslimattır.* |
| `J-255` | Kusuru doğuran **kapsam boşluğu** kapatıldı: Ayarlar + NEDEN YOK yürüyüşe eklendi (**11→13 yüzey**), pozitif kontrollü. NEDEN YOK'un 26 dizgesi = 1+1+12+12 ⇒ *'12 şey, her biri gerekçeli'* iddiası artık çıktıda SAYILABİLİYOR. |

## 3. ⏳ AÇIK — koordinatörde / kurucuda

- **`J-251` — koordinatör hükmü bekliyor (kod DEĞİŞTİRİLMEDİ).** Özet ekranı `Stance —` ·
  `Balance —` basıyor; **hiçbir açıklama yok**, oysa hemen altındaki *koçlanan-ama-puanlanmayan*
  bölümünün gerekçe notu VAR. `gradedBands` değeri **sabit `'—'`** (K8 geçilmedi) ⇒ bu satırlar
  hiçbir koşulda sayı göstermiyor. `SessionSummaryView` **donmuş ağaçta** ⇒ emsal gereği hüküm
  koordinatörün. App tarafı çözümler ölçüldü ve **reddedildi** (gerekçeler `J-251`de).
- **`J-259` — koordinatör hükmü bekliyor (kod DEĞİŞTİRİLMEDİ), `J-251` ile AYNI TURDA kapanır.**
  Özet ekranı `_roundsCompleted`/`_workedSeconds`i **tutuyor** (`session_screen.dart:151-152`) ve
  **diske yazıyor** (`:207-208`) ama `_Summary`ye geçirmiyor (`:267-271`) ⇒ 4 turu 12 dakikada
  bitiren kullanıcı **yaptığı iş hakkında tek kelime görmüyor.** Bunlar puan değil OLGU; K8 skoru
  kapatır, olguyu değil. İkisini birleştiren desen: *bilgi üründe VAR, başka yüzeyde gösteriliyor,
  seansın bittiği ekranda susuluyor* ⇒ ***ÖZET EKRANI, ÜRÜNÜN EN ÇOK SUSTUĞU YÜZEY.***
- **Bayat joker profil silinsin mi** — dört hattın kullandığı paylaşımlı dosya, hüküm koordinatörde.
- **A12** — `-allowProvisioningUpdates` koşuldu (H-9 yetkisi, `exit 0`) ama joker **cihazı eklemedi**;
  ve telefon `tunnelState=disconnected` (**eşleşmiş ≠ bağlı**). ⇒ **Kurucunun kabloyu takması gerekiyor.**
  Reçete: `A12-CIHAZ-RECETESI.md` (doğrulama komutu bu gece düzeltildi).
- **Kurucu kuyruğu:** B8 ikon · B1 keystore · B3 **İngilizce-tek** · **boks numaralandırması
  (1=jab, 2=cross) içerikte hiçbir yerde açıklanmıyor** (içerik yazarlığı boşluğu) ·
  **ayarlardaki fiyat paneli artık CTA'sız** — fiyat kararı gelince bir DÜĞME değil bir AKIŞ tasarlanacak.

## 4. SIRADAKİ ADAYLAR (sıra önerisi, değiştirebilirsin)

1. **Tempo bandı** — motor `controlled/brisk/fast` üretiyor (`ADR-001`), **hiçbir yüzey göstermiyor**,
   ve ürünün KENDİ dürüstlük metni bunu itiraf ediyor (*"there is no screen that shows you the band"*).
   Kusur değil **kapanmamış bir vaat**; yüzeye çıkarmak tasarım yönü ⇒ kurucuya/koordinatöre sor.
2. **Progress/Library** — `shell_candidate/` altındaki iki sayfa app'te **hiç kullanılmıyor**;
   ilerleme bugün seçim ekranındaki *"Where you left off"* kutusunda yaşıyor. Donmuş ağaç.
3. Kalan canlı yüzeyleri yürü: **kamera köprüsü** (debug, `kDebugMode` kapılı) · **hata ekranları**
   (`ContentFailureScreen`) · seans **kilitli ders** yolu. (*why-not* bu gece eklendi — §2 `J-255`.)

## 5. BU GECENİN KURALLARI (aileye geçmeye aday)

- ***BİR DERLEMENİN YEŞİL OLMASI, DERLEDİĞİ ŞEYİN SENİN ÜRÜNÜN OLDUĞUNUN KANITI DEĞİLDİR.***
- ***BİR EKRANIN DÜRÜSTLÜĞÜ, CÜMLELERİNİN TEK TEK DOĞRULUĞUNUN TOPLAMI DEĞİLDİR.***
- ***BİR YÜZEYİ HİÇBİR KAPI OKUMUYORSA, ORADAKİ HER İDDİA DENETİMSİZDİR.***
- ***BİR KAPININ YAN ETKİSİ, KORUDUĞU ŞEYİ BOZUYORSA, KAPI BUNU KENDİSİ SÖYLEMELİDİR.***
- ***BİR KAPININ ADI "GENEL" OLABİLİR AMA PAYDASI DARDIR.***
- ***BİR VAADİ METİNDEN SİLMEK, ONU ARAYÜZDEN SİLMEZ.***
- ***KAYDI GERÇEĞE UYDUR, KAPIYI KAYDA DEĞİL.***
- ***BİR ORTAM KUSURU, ÜRÜN KUSURU KILIĞINDA EN PAHALI KUSURDUR.***
- ***BİR HİPOTEZİ YAYMAK, ONU ÖLÇME BORCUNU DOĞURUR*** — bu gece üç hipotezim çürüdü, üçünü de
  ölçümle geri aldım.
- ***BİR ADLANDIRMA DESENİNİN YAKALADIĞI ŞEY, O ŞEYİN ROLÜ DEĞİL ADIDIR.***

## 6. YÖNTEM NOTU — gecenin en verimli aracı

**Dört bulgunun dördü de (`J-248` · `J-250` · `J-254` ve `J-247`'nin kombinasyon kusuru)
simülatörde ELLE yürürken bulundu, hiçbiri testten çıkmadı.** Testler dizgelerin *varlığını*
görüyor; aralarındaki **mesafeyi, çelişkiyi ve anlamı** görmüyor. Sıradaki oturum: kod okumadan
önce **uygulamayı aç ve yürü** — ama §1'deki platform doğrulamasını yapmadan gördüğüne inanma.
