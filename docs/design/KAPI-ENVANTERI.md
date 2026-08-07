# Kapı Envanteri — JabLab

> **Tek soru:** *bu kapı **neyi ölçmüyor?***
>
> *"Ne ölçüyor"* diye sorulsaydı liste özetlerle dolardı ve **kapsam boşluğu
> çıkmazdı** — yayın envanterinde (J-124) *"ne eksik"* sorusunun fazlalığı
> göremediği gibi. Bir kapının tehlikeli tarafı ölçtüğü şey değil, **ölçtüğü
> sanılan ama ölçmediği** şeydir: o alanda kimse bakmaz, çünkü kapı yeşildir.

**Tarih:** 2026-08-07 · **Kapılar:** 210/210 · `flutter analyze` temiz

## Neden bu envanter gerekti — dört kanıt, hepsi aynı gece

| # | kapı kusuru | ne oldu |
|---|---|---|
| J-122 | **kapsam ≠ alan** | Vaat dili kapısı donmuş ağacı taramıyordu; *"16 örnek temizlendi"* derken **17.'si ekrandaydı** |
| J-116 | **örnek ≠ örüntü** | Kontrast kapısı bir `ink4` örneğini ölçtü, **tokenın kendisini** değil |
| J-126 | **kapsamın yarısı** | Aynı kapı token *varsayılanlarını* ölçüyordu, **yerinde geçilen** renkleri değil — iki rozet 3,51:1'de duruyordu |
| J-120 | **fazla geniş** | Bir kapı *"hiç anlatı yok"* diye yazılmıştı; ürün doğru genişleyince **kırmızıya döndü** |
| J-121 | **çalışmayan kapı** | Bir kapı 10 dk zaman aşımına düşüyordu → **silindi** (yanlış öten kapı, olmayandan kötüdür) |

Beşi de tek sınıftan: **kapının ne ölçtüğü ile ne ölçtüğü sanılan şey ayrışıyor.**

**Ve gece ilerledikçe bir alt-desen çıktı: kapıların KATMAN kapsamı, KELİME
kapsamından daha sık yanlış.** Beş örnek, beşi de aynı gece: J-122 (donmuş ağaç
taranmıyor) · J-126 (token yolu) · J-129 (içerik dosyası) · J-131 (`unlock`
kapısı yalnız `lib/` Dart dizelerini tarıyordu, sızıntı içerikteydi) · J-132
(disiplin katmanı vardı, kurs katmanı yoktu). Kapı yazarken sorulacak ilk soru
*"hangi kelimeler"* değil, ***"hangi katmanlar"***.

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

### 9. Öksüz içerik anahtarı — `content_orphan_key_test` (J-129)
| | |
|---|---|
| **ölçmüyor** | ① `curriculum.json` — tüketicisi uygulama değil TESTLER, şekli serbest sözlük; "tanımlı anahtar"ı test kodundan türetmek testi kendi kâhini yapardı (*ölçüm yöntemi*) ② `cues.en.json` — gerek yok, `CueBook.fromJson` tanımadığında FIRLATIYOR (*zaten imkânsız*) ③ **ters yön**: parser okuyor ama içerikte hiç geçmiyor (ölü alan, J-044) — **ÖLÇÜLDÜ: bugün sıfır**, ve kapı BİLEREK konmadı (aşağı bak) ④ **doğruluk** — okunuyor olmak doğru olmak değil |
| **kanıt** | Kapı kurulduğunda **10 öksüz anahtar** buldu ve ikisi YANLIŞ iddia taşıyordu. Tanımlı anahtarlar parser KAYNAĞINDAN türetiliyor: elle liste doğruyu iki yere yazmak olurdu |
| **negatif ikiz** | Mutasyonla kırmızı görüldü (silinen `blurb` geri kondu → tam yol+değerle öttü) · parser'ın `blurb`i DİSİPLİN düzeyinde okuduğu ayrıca ölçülüyor, yoksa ikiz canlı alanı da öksüz sayardı |

### 10-11. Mekanizma dili + kurs hedefi — `promise_language_test` (J-131·J-132)
| | |
|---|---|
| **ölçmüyor** | ① **Başka sözcüklerle söylemeyi** — hedef "punch chains" derse görmez ② **ters yönü**: hedefin kursta hiç olmayan konuyu anması (`tempo control`) — anlam işi, sınıfı **imkânsız** ③ **gerekçenin kalitesini** — işareti taşımak yeterli sayılıyor ④ mekanizma listesi DAR ve kanıta dayalı: yeni bir geliştirici kavramı sızarsa görmez |
| **kanıt** | J-131'de 9 eşleşme ölçüldü, **6'sı bilerek durdu** — ölçüt kelimede değil: *mekanizma gözlenebiliyor mu · cümle eyleme çağırıyor mu*. J-132'de kurs katmanı ölçüldü ve **kusur bulundu** |
| **negatif ikiz** | **İkisi de TERS yönde**: J-131 → `confidence gate` içerikten kalkarsa öter (kapı fazla genişlemiş demektir) · J-132 → kilitsiz her kurs da caveat taşırsa öter (**olmayan bir sınırı beyan etmek dürüstlük değil gürültüdür**) |

### 12. Öğretme aşamasında sessizlik — `teach_stage_silence_test` (J-133)
| | |
|---|---|
| **ölçmüyor** | ① **"analiz" ile "kamera"yı** aynı sayıyor — kamerasız bir analiz kaynağı (kayıttan oynatma) gelirse görmez ② **prova aşamasını** ③ cümlenin **kelimelerini** — metin yeniden yazılırsa yine geçer; kapının işi DAVRANIŞI sabitlemek |
| **kanıt** | İddia ölçüldü ve **bugün doğru**; bulgu *"yanlış"* değil **"korunmasız"** idi. Mutasyon **ürün kodunda** yapıldı (`initState`e kamera ısıtma) → kırmızı |
| **negatif ikiz** | **Pozitif** ikiz: canlı aşamada kamera gerçekten açılıyor — yoksa öğretmedeki sıfır *"bağlı ama susuyor"* değil *"hiç bağlanmamış"* olurdu |

### 🎯 Yeni kapı sebebi: DOĞRU ama KORUNMASIZ

Bu geceki kapıların çoğu bir kusurdan doğdu. J-133 farklı: **iddia doğruydu.**
Kapının sebebi, onu yanlışa çevirecek değişikliğin **makul** olması —
*"canlı geçiş gecikmesini azaltmak için kamerayı öğretmede ısıtalım"*. Kimse
yalan söylemeye karar vermez; performans düzeltmesi yapar ve iki sevk edilmiş
cümle sessizce yalan olur.

**Ölçüt: bir cümle sevk edildiyse, onu yanlışa çevirecek en MAKUL değişikliği
sor. Makulse, kapı gerekir.**

### ⭐ Yeni araç: TERS NEGATİF İKİZ

Standart ikiz kapının **daralmasını** engeller (*"düzeltme kaldırılırsa kırılsın"*).
Ters ikiz **genişlemesini** engeller (*"meşru kullanım silinirse kırılsın"*).

Gerekçesi ölçülmüş: **fazla geniş kapı bu gece iki kez ödendi** (J-120 · J-126'nın
ilk hâli) ve ikisinde de kapıyı geri daraltan şey bir ölçüm değil, **fark
etmemdi**. Ters ikiz onu mekanikleştiriyor — aile dersi #7'nin (*hatayı
düzeltmek ≠ hatanın imkânsız olduğu yapıyı seçmek*) kapı tasarımına uygulanmış
hâli. **Kural: her dar kapı, darlığını koruyan bir ikiz taşımalı.**

### Ters yön neden kapıya bağlanmadı — ölçülmüş bir kısıtlama (J-130)

Öksüz-anahtar kapısının aynası: *parser bir alanı okuyor ama içerikte hiç
geçmiyor mu?* Türetilmiş anahtar setleriyle ölçmek bedava — **ölçüldü, bugün
sıfır.**

Kapıya **bağlanmadı** ve sebebi kendi dersim: *"parser'ın okuduğu her alan
içerikte bulunmalı"* kuralı, bir alanı içeriğinden önce eklemeyi **kırmızıya**
çevirirdi. Bu tam olarak J-120'nin kusuru — sınırı olduğundan geniş yazmak
testte daha sinsi: **doğru ilerleme, gerçek kusur gibi görünür.**

Öksüz yönde asimetri yok: yazılmış ama okunmayan içeriğin meşru bir hâli
**yok** — ya bir yüzeye bağlanır ya silinir. Bu yüzden o yön kapı, bu yön
kayıt.

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
