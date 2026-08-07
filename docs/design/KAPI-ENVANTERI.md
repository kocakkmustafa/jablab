# Kapı Envanteri — JabLab

> **Tek soru:** *bu kapı **neyi ölçmüyor?***
>
> *"Ne ölçüyor"* diye sorulsaydı liste özetlerle dolardı ve **kapsam boşluğu
> çıkmazdı** — yayın envanterinde (J-124) *"ne eksik"* sorusunun fazlalığı
> göremediği gibi. Bir kapının tehlikeli tarafı ölçtüğü şey değil, **ölçtüğü
> sanılan ama ölçmediği** şeydir: o alanda kimse bakmaz, çünkü kapı yeşildir.

**Tarih:** 2026-08-07 · **Kapılar:** 200/200 · `flutter analyze` temiz

## Neden bu envanter gerekti — dört kanıt, hepsi aynı gece

| # | kapı kusuru | ne oldu |
|---|---|---|
| J-122 | **kapsam ≠ alan** | Vaat dili kapısı donmuş ağacı taramıyordu; *"16 örnek temizlendi"* derken **17.'si ekrandaydı** |
| J-116 | **örnek ≠ örüntü** | Kontrast kapısı bir `ink4` örneğini ölçtü, **tokenın kendisini** değil |
| J-126 | **kapsamın yarısı** | Aynı kapı token *varsayılanlarını* ölçüyordu, **yerinde geçilen** renkleri değil — iki rozet 3,51:1'de duruyordu |
| J-120 | **fazla geniş** | Bir kapı *"hiç anlatı yok"* diye yazılmıştı; ürün doğru genişleyince **kırmızıya döndü** |
| J-121 | **çalışmayan kapı** | Bir kapı 10 dk zaman aşımına düşüyordu → **silindi** (yanlış öten kapı, olmayandan kötüdür) |

Beşi de tek sınıftan: **kapının ne ölçtüğü ile ne ölçtüğü sanılan şey ayrışıyor.**

---

## Envanter

Her satır: **kapı · neyi ölçmüyor · kanıt (kapsamı nasıl biliyorum) · negatif ikiz**

### 1. Ölü replik kapısı — `live_cue_mapping_test`
| | |
|---|---|
| **ölçmüyor** | **Çalışma-zamanı ulaşılabilirliği.** Bir anahtar eşleme tablosunda durabilir ve onu ateşleyen olay hiç üretilmiyor olabilir |
| **kanıt** | `cue.milestone` bu kapıdan **geçiyordu** ve hiçbir koşulda ateşlenmiyordu (J-104). Kapsam sınırı kodun içine yazılı |
| **negatif ikiz** | — (kapı listeyi tarıyor; ikiz yerine **beyan edilmiş sınır**) |

### 2. Vaat dili — `promise_language_test`
| | |
|---|---|
| **ölçmüyor** | ① Listede olmayan yeni bir vaat ifadesi (*"in due course"*, *"planned"*) ② Rengi/metni **değişkenden** gelen dizeler ③ Erişim yürüyüşü **regex** tabanlı: bir sınıf adının yorumda geçmesi "kullanılıyor" sayılabilir → **fazla geniş** tarafa hata verir |
| **kanıt** | Kapsam J-123'te ölçülerek genişletildi (konum→erişim). `show` bildirimine saygı duyuyor; ilk hâli `_ItemCard`ı yanlışlıkla canlı ilan etti ve **kapı kendi fazla genişliğini gösterdi** |
| **negatif ikiz** | Erişilemez borç **ayrı sayılıyor** (≤5) — toplam düşerken canlı olan dururken *"azaldı"* denemesin |

### 3. Portre kilidi — `portrait_lock_test`
| | |
|---|---|
| **ölçmüyor** | **Davranışı.** Widget testinde cihaz döndürülemez; ölçülen şey üç katmanın **aynı şeyi ilan ettiği** |
| **kanıt** | Sınır kodun içinde yazılı: *"Bu testin ölçtüğü şey BEYAN, davranış DEĞİL"* |
| **negatif ikiz** | Yasaklı yön adları ayrıca aranıyor (`landscapeLeft` vb. geri eklenirse kırılır) |

### 4. Kontrast + hiyerarşi — `live_honesty_bucket_test`
| | |
|---|---|
| **ölçmüyor** | ① Rengi **değişkenden** alan yerler (`color: fg`) — statik metinde değer yok ② `Theme` üzerinden gelen ve `JText` dışı stiller ③ **Algı**: iki rengin ayırt edilebilirliği (luminans ölçüsü bunu ölçmez) |
| **kanıt** | J-126 kapsamı **yarım** yakaladı: token varsayılanları ölçülüyordu, yerinde geçilenler değil → iki rozet ihlali. Genişletildi; kalan boşluk (değişken renk) **beyan edildi** |
| **negatif ikiz** | Scrim testi: *"scrim olmasaydı kırılırdı"* ayrıca ölçülüyor · hiyerarşi testi: sönük ↔ birincil ayrımının **korunduğu** ölçülüyor (yoksa her şeyi `ink` yapmak kapıyı geçerdi) |

### 5. Kod-biçimli metin — `surface_text_shape_test`
| | |
|---|---|
| **ölçmüyor** | Dize **olmayan** her şey: düğme rengi/konumu, örtüşen yerleşim, ikon seçimi. Ve **beyaz liste** dışında kalan yeni bir metin alanı |
| **kanıt** | Kapının üçüncü testi bu sınırı **kod içinde tutuyor** — bir sonraki tur *"metin kapıları var, ekran taraması gereksiz"* diye okumasın diye |
| **negatif ikiz** | — (bugün sıfır bulgu; kapı **önleme**, düzeltme değil — ve bu da yazılı) |

### 6. Gerçekçilik — `live_jab_path_test` (J-125)
| | |
|---|---|
| **ölçmüyor** | **Gerçek MediaPipe topolojisi.** Sentetik iskelet kusursuz bir insan; gerçek model güvenle yanlış topoloji üretebilir |
| **kanıt** | Sınıf **ÖLÇÜLMEMİŞ** ve daraltıldı: titreme (çekirdeğin σ'sı) + %50 kare düşmesi altında da ölçülüyor. Kalan mesafe cihaz turunda |
| **negatif ikiz** | Gürültülü yolda **ham kod sızmadığı** ayrıca ölçülüyor — yeni yolda eski kapının tuttuğu varsayılmadı |

### 7. `unlock` mekanizması — `promise_language_test` (J-124)
| | |
|---|---|
| **ölçmüyor** | Başka **var olmayan mekanizma** sözcükleri: *streak · level · badge · XP · rank*. Kapı tek sözcüğe bakıyor |
| **kanıt** | Bulgu tek sözcükten geldi; genişletmek **ölçmeden** yapılamaz (hangileri gerçekten yok, hangileri var?) |
| **negatif ikiz** | Kural **dize sabitlerine** bakıyor, tanımlayıcılara değil — `numericScoresUnlocked` gerçek bir mekanizma ve kırılmıyor |

### 8. 375pt taşma — `narrow_viewport_overflow_test` · `onboarding_test`
| | |
|---|---|
| **ölçmüyor** | **Okunabilirliği.** Taşma yoksa geçer; metin okunmuyor olabilir (Lissom'un çift-tire dersi) |
| **kanıt** | J-118'de gerçek içerik gelince **61 piksel** taşma yakaladı — yani taşma tarafı çalışıyor; okunabilirlik tarafı **hiç ölçmüyor** ve o kısmı kontrast kapısı devraldı |
| **negatif ikiz** | — |

---

## Ortak kör nokta — üçtü, ikisi kapandı

Envanterin bulduğu üç kör nokta ve **sınıflarının söylediği kuyruk**:

| kör nokta | sınıf | kapatması | durum |
|---|---|---|---|
| **Algı** — 2-3 m okunurluk, ikon ayırt | **imkânsız** | hiçbir kod | **açık ve öyle kalacak** — sim turu |
| **Yerleşim** — çakışan kutular | **kod** | kapı yazmak | ✅ **KAPANDI (J-128)** — `layout_overlap_test` |
| **Değişkenden gelen renkler** | **ölçüm yöntemi** | ayrıştırıcıyı genişletmek | ✅ **KAPANDI (J-127)** — ve **boş değildi** |

**Sınıf, kuyruğu belirledi ve bu somut bir kazanç oldu:** *kod* ve *ölçüm
yöntemi* olanlar kapatıldı; *imkânsız* olanı kovalamaya hiç başlamadım. Üçünü
aynı kutuya koysaydım, kapanmayacak olanı kovalayıp kapanacak ikisini geciktirirdim.

### J-127 — "değişkenden gelen renk" kör noktası boş değildi
`final Color fg = locked ? JColors.ink3 : JColors.ink;` → **kilitli dersin ADI**
17 puntoda **3,51:1** (eşik 4,5). Ve yanındaki kilit ikonu `ink4` = **1,80:1**
(metin-dışı eşiği 3,0'ın bile altında) — **pratikte görünmüyordu.** İkisi de
J-111'de güçlendirdiğim kilit gerekçesinin hemen yanındaydı.

### J-128 — yerleşim kapısı
375×812'de her ekranın yaprak `Text`/`Icon` kutuları ikişerli kesişim için
taranıyor. **İç içe olanlar muaf** (rozetin çerçevesi, düğmenin etiketi bir
kapatma değil kalıptır); **kısmi kesişim** gerçek çakışmadır. Eşik icat etmemek
için kesişim **alanı** değil **varlığı** ölçülüyor.

**Bu kapının kendi kör noktaları da yazılı:** kasıtlı katmanları ayırt etmiyor ·
kısmi örtüşmenin okunabilirliğe etkisini ölçmüyor · z-sırasını bilmiyor. Bir gün
kasıtlı bir metin katmanı gelirse kapı **yanlış öter** ve o zaman istisna
**adıyla** yazılmalı — kapı gevşetilmemeli.

---

## Şablon notu — diğer hatlara

**Kapı envanteri, kapıları kurduktan HEMEN sonra çıkarılmalı** — bu gece dört
kapı kusurunun dördü de kapılar kurulduktan **saatler sonra** bulundu, ve
ikisi (J-122 · J-126) kullanıcının gördüğü canlı ihlaller taşıyordu.

Ve envanterin kendisi kusur üretti: **J-126, bu dokümanı yazmak için
*"kontrast kapısı neyi ölçmüyor?"* diye sorarken düştü.** Yayın envanterinde
J-124 nasıl kanıt sütununu doldururken düştüyse, aynısı.
