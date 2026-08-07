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

## 🟡 ÖLÇÜLDÜ, SINIRI BEYAN EDİLDİ

| yüzey | iddia | sınır |
|---|---|---|
| **Kamera önizlemesi** | *"left out on purpose — analysis runs without it"* | Sınıf **ERTELENMİŞ** (M-F-287), Gravita ile aynı. Sorumluluğu üstleniyor, tarih vermiyor |
| **İskelet çizimi** | "ne gördüğümü çiziyorum" | Gerçek koordinatlardan — ama **sentetik** iskeletlerle sınandı; gerçek MediaPipe çıktısı cihaz turunda |
| **Kova ayrımı (renk)** | üç hâl görsel olarak ayrışır | Kontrast kapıda; **ikon 2-3 m'den ayırt ediliyor mu ÖLÇÜLMEDİ** — WCAG luminans ölçüsü bu soruyu ölçmez |

---

## ⛔ ÖLÇÜLEMEDİ — isimli açıklar

| kalem | neden ölçülemedi | ne zaman ölçülür |
|---|---|---|
| **Onboarding'in görünen hâli** | sim erişimi kurucu onayında (9 deneme) | Erişim açılınca — **build hazır**, launch saniyeler |
| **İkon 2-3 m'den ayırt** | algı; hiçbir mekanik kapı ölçemez | Sim turu, 375pt |
| **Kilometre taşının ekranda görünmesi** | widget koşumu olay ateşlenince takılıyor; **ürün katmanı 0 ms ölçüldü**, sevkiyat riski değil | Sim turu ya da koşum tuzağı çözülünce |
| **Gerçek insanla jab tanıma** | sim'de kamera yok | Cihaz günü §7.3-7.7 (kurucu-manuel) |

---

## Şablon notu — diğer hatlara

İki şey bu envanteri işe yarar kıldı:

1. **Soru kullanıcı tarafından soruldu.** *"Ne eksik"* diye sorsaydım liste
   yapılacaklarla dolardı ve J-124 çıkmazdı — çünkü o kalem **eksik değildi,
   fazlaydı**: var olmayan bir mekanizma anlatılıyordu.
2. **Kanıt sütunu zorunlu tutuldu.** Doğru saydığım her satırı yazarken *"nasıl
   biliyorum"* diye sormak zorunda kaldım; J-124 tam orada, *"kamera bağlı değil"*
   satırının kanıtını yazmaya çalışırken düştü.
