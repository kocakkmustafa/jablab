# Yayın Envanteri — JabLab

> **Tek soru:** *bir kullanıcı bugün bu uygulamayı açsa, hangi yüzey onu
> **yanlış bilgilendirir?***
>
> Bu bir yapılacaklar listesi değil. "Eksik" ile "yanlış" ayrı şeyler: eksik bir
> özellik dürüstçe beyan edilebilir ve yayına engel değildir. **Yanlış bir cümle
> yayına engeldir** — kullanıcı ona göre davranır.

**Tarih:** 2026-08-07 · **Ağaç:** `main` · **Kapılar:** 196/196 · `flutter analyze` temiz

## Biçim — ve neden bu üçlü

Her kalem üç şey taşır:

| alan | ne yapar | atlanırsa |
|---|---|---|
| **yüzey** | kullanıcı bunu NEREDE görüyor | "bir yerlerde var" diye kapatılır, kimse bulamaz |
| **iddia** | o yüzey NE söylüyor | tartışma niyete kayar; iddia sabit metindir |
| **kanıt** | doğru mu, NASIL ölçüldü | "bence doğru" ile "ölçtüm" ayrılır |

**Ölçülemeyen kalem silinmez, isimlendirilir.** Envanterin değeri kapananlarda
değil, **isimli açıklarda**: kapanan zaten kapanmıştır, açık olan ancak adı
varsa kovalanabilir.

---

## 🔴 BULUNAN VE DÜZELTİLEN — bu envanterin ürettiği

### J-124 · "İlerleme kapısı" — var olmayan bir mekanizma anlatılıyordu

| | |
|---|---|
| **yüzey** | Sayfa A / Sayfa B, kayıt notu — **yalnız kayıt yapmış kullanıcıya** görünür |
| **iddia** | *"Every progress gate also asks how much of the session the camera could actually analyse, and the camera is not connected."* |
| **kanıt** | 🔴 **İkisi de yanlış.** `unlock` sözcüğü tüm depoda YALNIZ o cümlede geçiyordu (`numericScoresUnlocked` ayrı kavram, K8 skor kapısı); içerikte `gate`/`unlock`/`sessionMinutes` alanı YOK; `SessionStore.workedSecondsFor` hiç çağrılmıyor → **ilerleme kapısı diye bir şey yok.** Ve kamera **bağlı**: `boxing.foundations.jab` `usesCamera:true`, `_liveJabFor` gerçek bir `LiveJabController` kuruyor (J-096'dan beri). |

**Neden en pahalı sınıf:** cümlenin **sonucu doğruydu** (*"bu dakikalar geçmişin,
kredi değil"*) — çünkü zaten hiçbir şey kilit açmıyor. Doğru sonucu **yanlış
gerekçeyle** söylemek en zor yakalanan hatadır: kimse sonucu sorgulamaz, ve
kullanıcı ürünün **yanlış bir modelini** öğrenir (kapılar olduğunu ve kameranın
bağlı olmadığını).

Yeni metin gerçek mekanizmayı gösteriyor: kilitler **içerik** düzeyindedir ve her
biri kendi isimli teknik gerekçesini taşır. Kapıya bağlandı (`unlock` bir mekanizma
sözcüğü; ürün dilinde ancak o mekanizma varsa yeri var).

---

## ✅ ÖLÇÜLDÜ VE DOĞRU

| yüzey | iddia | kanıt |
|---|---|---|
| **Karşılama ②** | *"$n şey bilerek bu uygulamada değil"* | Sayı `library.exclusions`tan TÜREVİ — içerik 7→12 olunca ekrana dokunmadan güncellendi (J-107 testi) |
| **Karşılama ③** | *"İzin vermezsen conditioning turları yine çalışır"* | `SessionScreen.liveJab` nullable ve kamerasız ders TAM koşuyor — `session_rounds_test` saati sürerek ölçüyor |
| **Disiplin kartları** | *"This discipline is not open"* + isimli teknik gerekçe | 7/7 gerekçe kod-gerçeğine bağlı; kapı her kapalı disiplinin engel sözcüğü taşımasını zorluyor (J-112) |
| **Kapsam-dışı (12)** | *"bir kamera bunu göremez"* | Her biri kamera fiziğine ya da ölçüm yokluğuna bağlı; *Slipping and rolling* ayrı sınıf: **görüyoruz ama puanlayamıyoruz** |
| **Kilitli 3 ders** | *"şu ölçüm yok, o yüzden puanlamıyoruz"* | `combinations` gerçek kanca dersiyle ÖLÇÜLDÜ (6 tamamlanma/0 kesilme); `footwork_combo` referans boşluğunu adıyla söylüyor (M-C-04) |
| **Öğretme aşaması (14 ders)** | ders anlatımı + ürünün sınırları | Metinler ürünün ölçülmüş sınırlarını tekrarlıyor ve **üçü teste bağlı** — sınır değişirse metin kırılır (J-118) |
| **Canlı — 11 dürüst hâl** | *"seni göremiyorum" / "okumam bozuk"* | J-103 iki dalı ayırdı; J-110 sorumluluk eksenini görsele taşıdı; üç kovanın kontrastı WCAG 1.4.11'i geçiyor (J-114/116/117) |
| **Özet — bantlar `—`** | *"ölçüyoruz ama puanlayamıyoruz"* | K8: kalibrasyon kapısı geçilmedi; `numericScoresUnlocked=false` config'te |
| **Özet — coached-not-scored** | *"eğitmenler anlaşmıyor"* | `references.stance.coachedOnlyJoints` — gard eli orada, dağılım 45° tavana kırpılı |
| **Ayarlar — fiyat** | *"Pricing is not set."* | Doğru: fiyat kararı verilmedi ve sabit yazılmadı |

---

## 🟡 ÖLÇÜLDÜ, SINIRI BEYAN EDİLDİ — her biri SINIFIYLA

Sınıf ayrımı M-F-287: **imkânsız** (fizik) · **ertelenmiş** (yapılabilir, biz
yapmadık) · **ölçülmemiş** (ölçülebilir, ölçmedik). Sınıf, kullanıcıya
söylenecek cümleyi de belirliyor — üçü aynı şey değil.

| yüzey | iddia | **sınıf** | sınırın bugünkü genişliği |
|---|---|---|---|
| **Kamera önizlemesi** | *"left out on purpose — analysis runs without it"* | **ERTELENMİŞ** | Gravita ile aynı çekirdek kısıtı, aynı sınıf. Sorumluluğu üstleniyor, tarih vermiyor. Daraltılamaz — açılması Texture önizlemesinin yazılması demek |
| **İskelet çizimi** | "ne gördüğümü çiziyorum" | **ÖLÇÜLMEMİŞ** | 🔽 **DARALTILDI (J-125).** Testler artık yalnız *temiz* sentetikle değil, **titreme** (çekirdek varsayılanı σ=0.004, sabit tohum) ve **%50 kare düşmesi** altında da koşuyor; jab ikisinde de sayılıyor ve ham kod sızmıyor. Kalan mesafe: gerçek MediaPipe topolojisi — cihaz turunda |
| **Kova ayrımı (ikon)** | üç hâl görsel olarak ayrışır | **ÖLÇÜLMEMİŞ (mekanikleştirilemez)** | Renk tarafı kapandı (WCAG 1.4.11 + AA). *Ikon 2-3 m'den ayırt ediliyor mu* bir ALGI sorusu; luminans ölçüsü onu ölçmez ve ölçüyormuş gibi kullanmak standardı ölçmediği şey için kullanmak olurdu. **Yalnız göz** |

**Neden bu üçü aynı kutuda değil:** *ertelenmiş* bir iş kararıdır ve kapatılması
kod yazmaktır; *ölçülmemiş* bir bilgi boşluğudur ve kapatılması ölçüm yapmaktır;
*mekanikleştirilemez* olan ise ne kadar kod yazılırsa yazılsın kapanmaz. İkisini
karıştırmak, birini yanlış kuyruğa koyar.

---

## ⛔ ÖLÇÜLEMEDİ — isimli açıklar

| kalem | neden ölçülemedi | ne zaman ölçülür |
|---|---|---|
| **Onboarding'in görünen hâli** | sim erişimi kurucu onayında (9 deneme) | Erişim açılınca — **build hazır**, launch saniyeler |
| **İkon 2-3 m'den ayırt** | algı; hiçbir mekanik kapı ölçemez | Sim turu, 375pt |
| **Kilometre taşının ekranda görünmesi** | widget koşumu olay ateşlenince takılıyor; **ürün katmanı 0 ms ölçüldü**, sevkiyat riski değil | Sim turu ya da koşum tuzağı çözülünce |
| **Gerçek insanla jab tanıma** | sim'de kamera yok | Cihaz günü §7.3-7.7 (kurucu-manuel) |

---

### J-131 · "Progress gate" — doğru sayı, yanlış model (koordinatör hükmü)

| | |
|---|---|
| **yüzey** | `r10` öğretme metni — dersi açan herkes görüyor |
| **iddia** | *"the **progress gate** for this lesson asks for ten minutes of work"* |
| **kanıt** | Sayı **gerçek** (`curriculum.json` `gates.sessionMinutes=10`) ama o kapı bir **içerik doğrulama sözleşmesi**: `curriculum_binding_test` plan aritmetiğini ona karşı zorluyor. **Çalışma zamanında geçilen bir kapı yok** — `workedSecondsFor` hiç çağrılmıyor (J-124). Kullanıcı *"geçeceğim bir kapı var"* modelini kuruyordu. |

**Sınıfı neden J-124 ile aynı:** cümle teknik olarak yanlış değildi. Dürüstlük
sınırı cümlenin doğruluğuna değil **kullanıcının kurduğu modele** bakıyor —
doğru sayı + yanlış model, en zor yakalanan hâl.

Sayı korundu, mekanizma dili düştü: *"ten minutes of work, split three ways."*

## ⚠️ BU ENVANTERİN YAPISAL KÖR NOKTASI (J-129'da ölçüldü)

Envanterin sorusu *"hangi **yüzey** kullanıcıyı yanlış bilgilendirir"* — ve gücü
buradan geliyor. Ama aynı cümle sınırını da çiziyor: **yüzeyi olmayan içeriği
yapısal olarak göremez.**

J-129'da `library.json`'da parser'ın hiç okumadığı 10 anahtar bulundu ve ikisi
**yanlış** iddia taşıyordu — biri J-119'un ölçüp çürüttüğü iddianın ta kendisi.
Bu envanter onları kaçırmadı: **bakmadı**, çünkü hiçbir yüzeyde değillerdi ve
tanımı gereği kapsam dışıydılar. Kapatan şey ayrı bir kapı oldu
(`content_orphan_key_test`), envanterin genişletilmesi değil.

**Ders:** doğru soru sormak, o sorunun sormadığını görmezden gelmek değildir.
Yüzey-merkezli bir envanter yüzey-öncesi katmanı asla kapsamaz; o katmanın
kendi kapısı olmalı.

## Şablon notu — diğer hatlara

İki şey bu envanteri işe yarar kıldı:

1. **Soru kullanıcı tarafından soruldu.** *"Ne eksik"* diye sorsaydım liste
   yapılacaklarla dolardı ve J-124 çıkmazdı — çünkü o kalem **eksik değildi,
   fazlaydı**: var olmayan bir mekanizma anlatılıyordu.
2. **Kanıt sütunu zorunlu tutuldu.** Doğru saydığım her satırı yazarken *"nasıl
   biliyorum"* diye sormak zorunda kaldım; J-124 tam orada, *"kamera bağlı değil"*
   satırının kanıtını yazmaya çalışırken düştü.
