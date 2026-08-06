# JabLab — Claude Design Paneli Promptu (v1, 2026-08-05)

> Koordinatör hazırladı, **kurucu onayı sonrası** panele verilir.
> Kaynak: kurucu tasarım yönü (M-F-282) + 2 referans görsel + ölçülmüş yüzey envanteri.
> Bağlayıcı kısıtlar `UI-BRIEF.md §5` ve aile defterinden türetildi — estetik tercih değil,
> testlerle zorlanıyor.

---

## 0. Ne tasarlıyorsun

**JabLab** — telefon kamerasıyla **solo boks** çalıştıran bir mobil uygulama. Kullanıcı
telefonu karşısına koyar, ders seçer, yumruk atar; uygulama hareketi görür ve **tek bir
düzeltme** söyler, bir yandan tur saatini ve sesli koçluğu sürdürür.

**Ürünün duruşu — tasarımın taşıması gereken karakter:** bu uygulama **abartmaz.**
Ölçmediği şeyi söylemez, bilmediğinde bilmediğini yazar. Bu bir zayıflık değil, ürünün
kimliğidir: *"dürüst köşe"*. Tasarım bunu bir özür gibi değil, bir **güven** işareti gibi
göstermeli.

---

## 1. Görsel yön (kurucu kararı)

- **Tema: liquid glass** — koyu zemin üzerinde buzlu cam panelller, arkadaki görüntü
  camdan süzülerek geçer. (Referans-1'deki `FitPulse` cam dili tam hedef.)
- **Renk: KIRMIZI ailesi** — referans mavi; biz kırmızı istiyoruz. Derin/koyu kırmızı
  zemin, sıcak kor tonları, yüksek kontrastlı beyaz tipografi. Boks ringi enerjisi.
- **Arka plan: tam-kadraj sporcu görselleri** — cam panellerin ardında, hafif karartılmış.
  **Her dövüş disiplini kendi hareketiyle temsil edilir** (boks jab, kickboks tekme, muay
  thai diz vb.) — disiplin değişince arka plan da değişir.
- **Karakter: teşvik edici, parlak, enerjik.** Ama teşvik **tonda** olacak, **iddiada**
  değil (bkz. §6).

**Bu tasarım 4 kardeş uygulamayla AYNI ELDEN ÇIKMIŞ GÖRÜNMEMELİ.** JabLab'ın ayrışma
ekseni: yüksek kontrast · sıkı/enerjik yoğunluk · keskin ve hızlı hareket karakteri ·
geniş ağır tipografi. (Kardeşleri pastel-yumuşak, soft, romantik-sıcak yönlerde
tasarlanacak — JabLab bunların hiçbirine benzemesin.)

---

## 2. Sayfa yapısı — AZ SAYFA (kurucu direktifi)

Sadece **üç sayfa** + bir köşe. Sayfa sayısını artırma, akışı bunların içine katla.

> ⚠️ Aşağıdaki **"Sayfa A'nın alt bölümü"** ayrı bir sayfa DEĞİLDİR — Sayfa A'nın altında
> bir bölüm ya da ayarlar köşesinden açılan bir panel olarak çözülecek. **Toplam sayfa
> sayısı üçtür ve artmayacak.**

### Sayfa A — **Disiplin & Kurs Seçimi**

**Tasarım HEDEF DURUMA göre yapılır** (kurucu kararı): sekiz disiplinin tamamı ekranda,
her biri **kendi dövüş sporuna özgü bir hareket görseliyle**. İçerik zamanla dolacak.

| # | Disiplin | Dalga | Görsel için hareket |
|---|---|---|---|
| 1 | **Boxing** | V1 — **canlı** | jab / gard |
| 2 | **Kickboxing** | W1 | round-house tekme |
| 3 | **Tai Chi** | W1 | yavaş form, akan duruş |
| 4 | **Karate — Kihon & Kata** | W2 | kihon duruşu / kata anı |
| 5 | **Muay Thai** | W2 | teep veya diz |
| 6 | **Taekwondo** | W3 | yüksek/dönen tekme |
| 7 | **MMA Striking** | W3 | karma vuruş duruşu |
| 8 | **Wing Chun — Solo Forms** | W4 | Siu Nim Tao merkez hattı |

Seçilen disiplinin altında **kursları** açılır (Boxing için bugün: *Foundations ·
Conditioning · Intermediate*). Katmanı aynı sayfada tut — ayrı sayfa açma.

**🔴 KRİTİK: ekran HER DOLULUK SEVİYESİNDE düzgün görünmeli.** Bugün sekizden **biri**
canlı; içerik geldikçe dolacak. Tasarım hem tam dolu hâli hem **kısmi dolu** hâli
(1 canlı / 3 canlı / 8 canlı) kasıtlı görünecek şekilde çözülmeli — canlı olmayan kartlar
ekranı "eksik/bozuk" göstermemeli.

**Canlı olmayan disiplin kartı nasıl görünür (dikkat, ince ayrım):**
- ✅ Kart **görünür** ve **İSİMLİ TEKNİK GEREKÇE** taşır — mevcut metinler zaten böyle
  yazılmış: *"Kicks join the engine. Needs a wider frame and a kick classifier."*
- ⛔ **"Coming soon" / "Yakında" / geri sayım / "çok yakında sizlerle" YASAK** — boş vaat.
  Fark şu: *"neden henüz yok"* dürüstlüktür, *"yakında gelecek"* vaattir.
- ⛔ Canlı olmayan disiplin **kurs listesine açılmaz** — kart bilgilendirir, içine girmez.
- Görsel olarak canlı kartlardan **ayrışmalı** (ör. sönük/desatüre) ama **ölü veya
  ikinci sınıf** görünmemeli.

### Sayfa A'nın alt bölümü (**ayrı sayfa DEĞİL**) — **"Neyi yapmıyoruz, neden"** · markanın en güçlü kartı

Ürünün yedi **bilerek kapsam dışı** başlığı var ve her birinin yazılı gerekçesi
mevcut — bunlar gizlenecek eksikler değil, **güven inşa eden içerik**. Seçim sayfasının
altında ya da ayarlar köşesinde erişilebilir bir yüzey olarak tasarla (kurucu onayıyla
konumu değişebilir):

Brazilian Jiu-Jitsu · Wrestling · Judo · Silahlı sanatlar · Clinch & sparring ·
**Yumruk gücü** · **Kendini savunma garantisi**

Mevcut gerekçe metinleri aynen kullanılacak, yumuşatılmayacak. Örnekler:
> *"Force needs a sensor. A camera can estimate timing and tempo — we show those as
> bands — but we will not print a power number we cannot measure."*
> *"Grappling is defined by contact and resistance from another person. A solo camera
> sees neither, so any score would be invented."*

Bu yüzey **özür tonunda değil, duruş tonunda** tasarlanmalı. Rakiplerin sustuğu yerde
konuşan bir ürün olduğumuzu burası anlatıyor.

### Sayfa B — **Kurs Sayfası** (giriş ekranı da bu)
Uygulama açılınca kullanıcının **bulunduğu kurs** burada karşılar:
- hangi kurstasın · seçili ders · **kurs içi bölüm ilerlemesi** · **kaldığın yer**
- ders listesi: tamamlanana **geri dönebilir**, **ileri bir dersi seçebilir**
- kilitli ders varsa **sebebiyle** görünür

> ⚠️ **"Kaldığın yer" paneli ÜÇ HÂLLİDİR** — bu bir tasarım detayı değil, zorunlu:
> ① geçmiş okundu → ilerleme göster · ② **kısmen okundu** → "kayıtların bir kısmı
> okunamadı" beyanı + eldeki sayı · ③ **okunamadı** → **sayı GÖSTERME**, durumu beyan et.
> ③'te "hiç başlamadın" ya da "0" göstermek YASAK: *"hiç yapmadın"* ile *"bilmiyorum"*
> farklı şeylerdir. Üçü için de ayrı görsel çözüm istiyoruz.

### Sayfa C — **Ders Ekranı (canlı)** · **ÜRÜNÜN YILDIZI** — §3

### Köşe — **Ayarlar**
Küçük bir köşe girişi; profil, ödeme/abonelik, tercihler hepsi buraya. Ayrı sekme değil.
- **Fiyat sabit yazılmaz** (test bunu zorluyor) — paywall fiyatı dinamik yuvadan alır.

---

## 3. Ders ekranı (canlı) — kompozisyon

Referans-2'deki (Back Squat) **DÜZEN** hedef: tam ekran canlı görüntü + kenarlarda liquid
glass paneller + iskelet overlay. **Referansın kopyası istenmiyor** — istenen, o cam panel
mimarisinin **bizim ürettiğimiz bilgilerle** ve **kullanıcının görmek isteyeceği**
bilgilerle doldurulması. Aşağıdaki liste elimizdeki gerçek malzeme; panel bunları
kompozisyona özgürce dağıtabilir, gruplayabilir, öne/arkaya alabilir.

**Ekranda olacaklar:**

| Panel | İçerik | Not |
|---|---|---|
| Canlı görüntü + **iskelet overlay** | landmark'lar gerçek, çizilebilir | ✅ var |
| **Tur saati / faz** | süre akışı, hangi fazdasın | durum bildirimi, hüküm değil |
| **Tamamlanan deneme sayısı** | sayaç | **OLGU**, skor değil |
| **TEK düzeltme** | aynı anda **yalnız bir** düzeltme | iki uyarı birden kullanıcıyı dondurur |
| **Asistan seslendirmesi** | tur başı · yarıladın · son 10 sn · son 5 sn · tur sonu | **ses BİRİNCİL** |
| **"Neden hüküm yok" beyanı** | ölçüm yapılamıyorsa sebebi | ayrı yuva |

**İki kritik kural:**

1. **Ses birincil, ekran ikincil.** Kullanıcı yumruk atarken ekrana bakmıyor. Ekran
   **2-3 metreden okunmalı** — büyük tipografi, yüksek kontrast, az öğe.
2. **Anlatı yuvası ile HÜKÜM yuvası görsel olarak AYRI olmalı.** Tur saati saymak poza
   bakmayı gerektirmez. İkisi aynı yerde görünürse kullanıcı, sistem onu yargılamıyorken
   yargılıyor sanır. Bu ayrım tasarımda korunacak.

**Dürüst hâller — bunlar "hata ekranı" değil, BİRİNCİ SINIF tasarlanmış ekranlar:**
- kamera izni **geçici** reddedildi → "tekrar dene" anlamlı
- kamera izni **kalıcı** reddedildi → "tekrar dene" **YOK**, ayarlara yönlendir
- kamera açılamadı
- **kimse görünmüyor** → bu bir arıza DEĞİL, canlı hâldir ve kendi kendine düzelir
  ("kadraja gir")
- **eklem kadraj dışı** → "geri çekil" (yukarıdakinden FARKLI eylem, ayrı tasarım)

Her biri için ayrı görsel çözüm istiyoruz — hiçbiri jenerik "bir şeyler ters gitti"
ekranına düşmeyecek. Bu ekranlar ürünün dürüstlük vaadinin görünür kanıtı.

---

## 4. Hareket ve geçişler (kurucu özellikle istedi)

- **Ekranlar arası geçişler animasyonlu** olacak — özellikle **kurs seçimi → kurs
  sayfası** geçişi: seçilen kartın arka plan görseli ekranı devralarak açılsın.
- **Kurs seçildikten sonra bir geçiş anı** olsun — disiplinin kendi hareketi/görseliyle,
  kullanıcıyı derse hazırlayan kısa bir sahne.
- Ders başlangıcı ve tur geçişleri için **enerjik, keskin** hareket dili (yumuşak
  yaylanma değil — JabLab'ın karakteri hızlı ve net).
- Cam panellerin giriş/çıkışı, sayaç değişimleri, düzeltme belirmesi: hepsi hareketli.
- **Düzeltme belirirken dikkat çekmeli ama okumayı bölmemeli** — kullanıcı hareket
  hâlinde.

---

## 5. Görsel varlıklar

Arka plan sporcu görselleri **AI ile üretilebilir** — bunlar öğretim/atmosfer görselidir,
ölçüm referansı değil. **Ancak AI üretimi varlıklar ifşa işareti taşımak zorundadır**
(yasal gereklilik, CI kapısı zorluyor). Panel görselleri üretirken bunu varsay.

---

## 6. ⛔ ASLA — bunlar test kırar, "tasarım tercihi" değildir

Referans görsellerde bunların bir kısmı VAR; **bilerek çıkarıldılar**:

1. **Kalibre edilmemiş sayısal skor YOK.** `92%`, `Depth Score`, `Form Score`, yüzde
   halkası, 5 üzerinden puan — hiçbiri. Gerekiyorsa **bant** kullan ("nokta değil bant").
2. **Kalori / kcal / kcal-rate YOK.** Ölçülmüyor.
3. **Kas ısı haritası YOK.** Ölçülmüyor.
4. **Çok maddeli yeşil "form checklist" YOK.** O ölçümler yok; ayrıca aynı anda tek
   düzeltme kuralı var.
5. **"AI detection active" gibi ibareler YOK.** Motor deterministik.
6. **`power` / `force` / `kph` / hız-kuvvet dili YOK.** Ölçülmüyor.
7. **"Yakında" / `coming soon` / geri sayım dili YOK.** Henüz canlı olmayan disiplin
   **görünür** — ama **isimli teknik gerekçesiyle**, vaatle değil. (*"Needs a kick
   classifier"* ✅ / *"Coming soon!"* ⛔). Canlı olmayan disiplin kurs listesine açılmaz.
8. **SOL / SAĞ denmez** → `lead hand` / `rear hand` (kalibrasyon yok).
9. **Analiz başlamamışken çıplak "0" YOK** — "hiç başlamadın" demektir; "başlamadı" ayrı
   bir hâldir.
10. **Fiyat sabit yazılmaz.**
11. **Motivasyon TONDA olur, İDDİADA değil.** "Daha güçlü olacaksın", "formunu
    düzelteceğiz" gibi sonuç vaatleri yasak — ölçülmemiş iddialardır. Enerji görselde,
    renkte, ritimde; sözde değil.

---

## 7. Teslim

- 3 sayfa (A · B · C) + ayarlar köşesi + Sayfa A'nın "neyi yapmıyoruz" alt bölümü
- Ders ekranının **tüm hâlleri**: canlı · izin geçici · izin kalıcı · kamera yok ·
  kimse yok · kadraj dışı
- Kurs sayfasının **üç geçmiş hâli** (okundu · kısmen okundu · okunamadı)
- Seçim ekranının **kısmi doluluk** hâlleri (1 canlı / 3 canlı / 8 canlı)
- Geçiş animasyonlarının tarifi/prototipi
- Renk paleti, tipografi ölçeği, cam panel spesifikasyonu (bulanıklık, opaklık, kenar)
- **Arayüz metinleri İNGİLİZCE** yazılır.

---

*Bağlayıcı kaynak: `docs/design/UI-BRIEF.md` §5 · aile defteri M-F-186 (vaat dili) ·
K8 (skorsuz yüzey) · doc-75 (geçmiş üç-hâl) · M-F-282 (kurucu tasarım yönü).*
