# JabLab — Referans Video Adayları (J-015 / M-C-01)

**Tarih:** 2026-07-26 · **Statü:** ADAY LİSTESİ — hiçbir video izlenmedi, kadraj uygunluğu **doğrulanmadı**
**Dayanak:** M-C-01 (referans kaynağı = kamuya açık gerçek eğitmen videoları) · M-C-04 (≥3, tercihen 6+ bağımsız eğitmen) · M-C-02 (skorlama referansı **doğru** olmalı) · M-C-03 (hatalı örnekler referansın kontrollü bozulmasından)
**İndirme/erişim koordinasyonu koordinatör oturumdadır** — bu doküman yalnız *hangi kaynak, hangi şerit, hangi kriter* sorusunu cevaplar.

---

## 1. Referansın teknik şartları (eleme kriterleri)

Bir video "skorlama referansı" olabilmek için şunları sağlamalı. Bunlar D2 ölçümünden çıkan gerçek kısıtlar, temenni değil:

| # | Şart | Neden |
|---|---|---|
| R1 | **Tam vücut kadrajda** (ayak bileği + baş, kenardan içeride) | Duruş/ayak hataları A bandının tamamı; ayak kadraj dışıysa video yalnız üst-gövde referansı olur |
| R2 | **Sabit kamera** (kesme/zoom/kaydırma yok, en az bir bölümde) | Kamera hareketi normalizasyonu bozar; elde çekim `jump_rate`'i patlatıyor (ölçüldü: 0,108-0,189) |
| R3 | **Ön-eğik ~25-55°** | ADR-003/M-F-09: saf yan iki eli birden göremiyor, saf ön foreshortening yapıyor |
| R4 | **Tek kişi karede** | Çoklu kişi pose atamasını belirsizleştirir |
| R5 | **Yumruklar arasında gard'a dönüş** | Faz sınırı gard dönüşünden okunuyor; kesintisiz seri fazları birleştirir |
| R6 | **Bilinen/okunabilir fps**, tercihen ≥30 | Faz süresi gerçek zamana bağlanmalı |
| R7 | **Ağır çekim DEĞİL** (veya ağır çekim olduğu açıkça biliniyor) | Yavaşlatılmış klip `t_ext`'i sistematik şişirir |
| R8 | Eğitmen **orthodox ve/veya southpaw** açıkça belirtilmiş | Aynalama çözümünün girdisi (M-C-04) |

**Beklenti gerçekçi olsun:** yayınlanmış koçluk videolarının çoğu R1+R2+R3'ü aynı anda sağlamaz (yakın plan, kesme, yan açı yaygın). Bu yüzden liste geniş tutuldu — eleme **izleyerek** yapılacak.

## 2. Hukuki şeritler — risk sırasına göre

M-C-01 "kamuya açık eğitmen videoları" diyor ve eğitmenle sözleşme gerekmediğine hükmetti. Ama **"kamuya açık" ≠ "indirilebilir"**: YouTube'un standart şartları indirmeyi yasaklar. Bu ayrım kararı bozmaz, *şerit seçimini* belirler. Katalog §0'ın lisans disiplini burada da geçerli.

| Şerit | Ne | Risk | Not |
|---|---|---|---|
| **A — CC-BY işaretli YouTube videoları** | YouTube'da yükleyici videoyu CC-BY olarak işaretleyebilir; arama filtresi: Filtreler → Özellikler → Creative Commons | 🟢 düşük | **Tercih edilen şerit.** Atıf zorunlu. Boks eğitiminde arz sınırlı olabilir — taranması gereken ilk yer |
| **B — Lisanslı stok görüntü** (Pexels / Wikimedia CC / Internet Archive) | Ticari kullanıma açık boks görüntüsü | 🟢 düşük | Bu gece D2 ölçümünde zaten kullanıldı; **ama koçluk kalitesi yok** — hareket "doğru icra" garantisi taşımıyor. Referans için R-şartlarını sağlasa bile M-C-02'nin "doğru olmalı" şartını sağlamaz |
| **C — Eğitmenin kendi sitesi / basın kiti / indirilebilir kurs materyali** | Doğrudan yayıncıdan | 🟢 düşük | Şartlar okunur; genelde net |
| **D — Tek satırlık izin e-postası** | "Landmark çıkarımı için kullanabilir miyiz" | 🟢 düşük | M-C-01 sözleşme gerektirmiyor ama **izin ucuz**; ayrıca ship-öncesi kural kontrolü için doğal temas noktası |
| **E — Standart YouTube videosundan indirme** | — | 🔴 **ToS ihlali** | Karar kurucunun; bu doküman risk olarak işaretler, kendiliğinden kullanmaz |

**Önerim:** A → C/D → B sırası. E'ye ihtiyaç duyulursa bu bir *kurucu kararı* olarak ayrıca kaydedilmeli (katalog §10 sapma prosedürü).

## 3. Aday eğitmenler (kimlik + neden aday)

⚠️ Aşağıdakiler **kaynak adaylarıdır**, onaylanmış video değil. Hiçbiri izlenmedi; R1-R8 doğrulanmadı. Kimlik bilgileri web araştırmasından, birincil kaynaktan teyit edilmedi.

| # | Kaynak | Neden aday | Doğrulanacak |
|---|---|---|---|
| 1 | **Tony Jeffries** — 2008 Pekin Olimpiyat bronz madalyalı, Box 'N Burn kurucu ortağı; 2007'den beri teknik videosu, ~2,56M abone | En güçlü kimlik belgesi + uzun temel-teknik arşivi. **Southpaw** — M-C-04'ün aynalama/duruş çeşitliliği için değerli | kadraj, lisans şeridi |
| 2 | **Thomas Yankello Jr.** — World Class Boxing Channel; Hall of Fame antrenör | Antrenör (boksör değil) perspektifi; öğretim amaçlı çekim olasılığı yüksek | kadraj, lisans şeridi |
| 3 | **Precision Striking** | Teknik ayrıştırmaya odaklı kanal; ücretli üyelikte birebir teknik geri bildirim veriyor → öğretim çerçevelemesi muhtemelen düzenli | kadraj, lisans şeridi |
| 4 | **Nate Bower** — eski yarışmacı boksör, sertifikalı antrenör | Shadow boxing formatı JabLab'ın senaryosuna en yakın olan aday (ekipmansız, tam vücut, karşıya bakan çekim eğilimi) | kadraj, lisans şeridi |
| 5 | **Joe Vargas / The Arena** | Jab-cross-hook temelleri üzerine doğrudan içerik | kadraj, lisans şeridi |
| 6 | **Final Round Training (Gary & Colleen)** | Jab-cross kombinasyonu öğretimi; **iki eğitmen** → tek kanaldan iki bağımsız icra | kadraj, lisans şeridi |
| 7 | **ExpertBoxing** | Yaygın referans, ama forumlarda **tartışmalı** güvenilirlik | önce kimlik değerlendirmesi |

**M-C-04 gereği en az 3, tercihen 6+ bağımsız eğitmen birleştirilecek.** Aday sayısı 7 tutuldu çünkü kadraj elemesi listeyi ciddi biçimde kırpacak.

## 4. Video başına doğrulama protokolü

Her aday video için, kabul edilmeden önce:

1. **R1-R8 gözle kontrol** → geçen bölümün zaman aralığı kaydedilir (tüm video değil, uygun *segment*).
2. **Landmark çıkarımı** (mocore hattı) → `jump_rate ≤ %5` ve gövde `visibility ≥ 0,8` şartı.
3. **Yapısal denetim** (`StructuralValidator`, M-019) → ihlal varsa video elenir.
4. **Ağır çekim testi:** çıkarılan `t_ext` medyanı 68-257 ms bandının dışındaysa (D2 havuzu) klip yavaşlatılmış veya hızlandırılmış demektir → ya oran düzeltilir ya elenir.
5. **Duruş etiketi:** orthodox/southpaw geometrik olarak belirlenir (modelin left/right etiketine güvenilmez — M-F-06).
6. **Aynalama konsensüsü:** ≥3 eğitmen birleşince her take iki yönde denenir, grup uyumunu en çoklayan atama seçilir (M-C-04 / `ReferenceBuilder.resolveMirroring`).
7. **Provenance kaydı** (M-F-07): kaynak URL, lisans şeridi, erişim tarihi, model varyantı + SHA, segment aralığı.

**Eleme kaynağa dayanır, sonuca değil** — Gravita'nın D1 turundaki ders: bir görüntü "sonucu bozduğu için" elenmez, *şartı sağlamadığı için* elenir ve gerekçe kaydedilir.

## 5. JabLab'a özel iki uyarı

- **Aynalama JabLab'da dansa göre daha az tehlikeli** (J-017): `lead/rear` vücut geometrisinden türetiliyor, modelin `left/right` etiketinden değil → aynalanmış video jab'i cross sanmaya yol açmaz. **Ama footwork yönü etkilenir** — footwork referansında konsensüs yine şart.
- **Hatalı örnek çekmeye gerek yok** (M-C-03): eğitmen videoları yalnız doğru icra içeriyor; hatalı fixture'lar referansın kontrollü bozulmasından üretilecek. Bu, kurucu çekim protokolünün §5'ini 8 çekimden 3'e indirdi — kalan 3 çekim *sentetik bozulmanın gerçek hatayı temsil edip etmediğini* doğrulamak için.

## 6. Koordinatör / kurucudan gereken

1. **Şerit kararı** — A/C/D ile yetinilecek mi, yoksa E (YouTube indirme) kurucu kararıyla mı açılacak?
2. **Erişim/indirme yürütmesi** — M-F-03 gereği çekirdek+hat koordinatörde; bu liste ona girdi.
3. Şerit A seçilirse: YouTube CC-BY filtresiyle boks eğitimi taraması (arz belirsiz — arama yapılmadı).
4. Şerit D seçilirse: 7 adaya tek satırlık izin e-postası (kurucu eli — dış iletişim).

**Kaynaklar:** [Tony Jeffries](https://en.wikipedia.org/wiki/Tony_Jeffries) · [Thomas Yankello](https://en.wikipedia.org/wiki/Thomas_Yankello) · [YouTube lisans türleri](https://support.google.com/youtube/answer/2797468?hl=en) · [En iyi boks YouTube kanalları](https://www.honourandglory.co.uk/blog/best-boxing-youtube-channels) · [Online boks koçları](https://brawlbros.com/best-online-boxing-coaches/)
