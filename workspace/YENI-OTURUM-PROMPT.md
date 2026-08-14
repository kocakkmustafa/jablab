# 🔬 5-KATMANLI ULAŞILABİLİRLİK YIĞINI + 3 CANLI YALAN KAPANDI · devir 2026-08-12 (gece vardiyası)

> **Bu blok en güncel talimattır ve altındaki her şeyden ÖNCELİKLİDİR.**
> Aşağıdaki "GİYDİRME — FAZ 3" bloğu (2026-08-06) hâlâ TEKNİK ARKA PLAN
> için geçerli (o turun sınırları/gotcha'ları durur) — ama bu gecenin
> ölçümü ondan sonra geldi ve **yeni bir iş sınıfı** açtı: bu blok o sınıfı
> anlatıyor, giydirmenin yerine geçmiyor.

## 0. NEREDE KALDIK (git-doğrulandı)

`main` = **`41c0afd`**, origin ile eşit, ağaç temiz. **app 285/285 · motor
125/125 · `flutter analyze` temiz.** 20 commit bu gece, hepsi kendi kurulan
commit-kapısından (3/3: analyze+app+motor, borusuz) geçti.

**Commit kapısı artık DEPODA:** `tool/hooks/pre-commit` + `tool/setup_hooks.sh`
— taze klonda `bash tool/setup_hooks.sh` ÇALIŞTIRILMALI (bir kerelik,
`core.hooksPath`i bağlar + pose modelini indirir + `build/` symlink'ini
üretir). Koşulmazsa 44 kapının koruması SIFIR.

## 1. BU GECENİN ZİNCİRİ — 5 katman, her biri sevk edilmiş bir yalan açtı

Mağaza liste taslağı yazılırken ("Combination order and timing" iddiası)
başlayan tek bir çapraz kontrol, JabLab'ın ulaşılabilirlik mimarisini BEŞ
katmana ayırdı. **Desen: bir katmanı kapatmak kusuru yok etmedi, bir
sonrakini GÖRÜNÜR kıldı — ve her katman kendi sevk edilmiş yanlış iddiasını
açığa çıkardı:**

| katman | soru | kapı | bulduğu CANLI yalan |
|---|---|---|---|
| ① config | ders kamerayı açıyor mu? | `test/gate_reachability_test.dart` | (J-197'nin kendisi — $cameraBasis, ADR-005) |
| ② primitif | olayı üreten bir mekanizma var mı? | `packages/jablab_engine/test/gate_primitive_producer_test.dart` | — (setupCheckPassed/stanceHold isimli kaldı, aşağı bak) |
| ③ hata kodu | `evaluateAt` gerçek bir marker'a mı bakıyor? | `packages/jablab_engine/test/error_reachability_test.dart` | `one_two`: "we watch the order and the timing" |
| ④ koşul alanı | alan gerçekten ATANIYOR mu? | `packages/jablab_engine/test/condition_field_assignment_test.dart` | `jab`/`guard`: "we call it out by name" / "comes home late" |
| ⑤ koşul TRUE'su | atanan alan gerçek veriye karşı hiç TRUE oluyor mu? | **YOK — ÖLÇÜLMEDİ** | ? |

Üçü de düzeltildi (canlı metin, ders-içi dürüst beyan ile). `tempo`
(TEMPO_TOO_FAST_FOR_FORM, ③'te bulundu) yanlış iddia TAŞIMIYORDU, yalnız
SESSİZDİ — ona da açık bir yokluk-beyanı eklendi (sessizlik bu üründe
"her şey yolunda" diye okunur, M-F-101).

**`boxing@1.0.0.json`da tam kayıt:** `$unreachableErrorCodes` (3 kod) +
`$unassignedConditionFields` (4 alan) + `$openLayer5_conditionNeverTrue`
(açık, ölçülmedi) — hepsi gerekçeli, hepsi kapılı, hepsi çift yönlü
mutasyonla doğrulandı.

## 2. KURUCU DİREKTİFLERİ (2026-08-12 sabah, doğrudan) — ⚠️ KURUCU BUGÜN ULAŞILAMAZ

- **G3 çekimi SONA ötelendi** — artık blokaj değil.
- **İnternet videolarından referans yolu AÇILDI**, ön koşullu: statik tutuş
  için `hold_isolator` (M-F-75) **Ostinato'da** inşa edilecek (JabLab'ın
  kendi kalemi değil, aile-paylaşımlı). Referanslar §50 altında açı/landmark
  verisi olarak türetilir; video yeniden dağıtılmaz, kaynak kaydedilir.
- **Kurucu bugün ULAŞILAMAZ** — bu yüzden **"İş 1" kurucuya bağlı olan
  hiçbir madde OLAMAZ.** Mağaza taslağı onayı bu yüzden İş 1 değil,
  aşağıdaki "kurucu dönene dek bekler" bölümünde.

## 3. YENİ OTURUMUN İŞ SIRASI — sıfır kurucu kararı gerektirir, SORU SORMADAN başla

### İş 1 — ÖNCE ÖLÇ: onboarding + gezilebilirlik yeniden ölçümü

*"Onboarding beş hatta da YOK"* ölçümü **2026-08-07'den** — üzerine **80
commit indi** (bu gecenin 18'i dahil) ve **yeniden ölçülmedi.** Bayat
satırdan iş sevk edilmiyor. ⚠️ **"10 ekran" sayısı da güvenme:** bu gecenin
kendi ölçümü (`reachable_screens_test.dart`, J-167) kanonik sayının **katı
okumada 6, gevşek okumada 11** olduğunu gösterdi — "10" hiçbir kapıdan
gelmiyor, muhtemelen UI-BRIEF'in "11 ekran" ifadesinin yanlış hatırlanmışı.
Bu iş İKİSİNİ birden yeniden ölçsün: onboarding akışı BUGÜN var mı (canlı
kod, tarih değil) + gezilebilir ekran sayısı `reachable_screens_test.dart`
kapısından TAZE okunsun (katı/gevşek ikisi de). Kurucu direktifi: *"önce
yayınlanabilir hâl, sonra içerik"* — Ostinato'dan sonra ailenin en
gezilebilir ikinci hattı olmak, yayına yakın olmak demek, ve onboarding son
gediğin. **SONRA kapat** (ölçüm hangi yönü gösterirse).

Sıfır kurucu kararı gerektirir — ölçüm + varsa mekanik düzeltme senin
elinde.

### İş 2 (serbest, gerçek içerik tavanın) — `setupCheckPassed` + `stanceHold` ÜRETİCİLERİ

Hüküm aynen korunuyor: bu, **tek tek ders açmak değil — İÇERİK YOLUNUN
KENDİSİNİ açmak.** Bu gece "yeni ders yaz" talimatı geldi ve **denendi,
ölçüldü, DURULDU**: tek kanıtlanmış güvenli gate deseni **olay-sayımı**
(jab/guard/range'in `event:"jab", minCompletedAttempts` deseni). Footwork
gibi olay-sayımına doğal oturmayan her yeni ders fikri, ya (a) o deseni
zorlar ya da (b) `stance`ın kendi kırık `stanceHold` desenini TEKRARLAR —
yani **yeni bir üretilemez primitif icat etmek** olur, tam bu gecenin
düzelttiği hata sınıfı. **JabLab'ın içerik tavanı yazma emeği değil,
PRİMİTİF ENVANTERİ.** İki eksik üye üretilmeden yeni ders türü açılamaz —
bunu bilmeden başlarsan aynı duvara çarparsın. **Yeni primitif icat etme**
— tek kanıtlanmış güvenli kapı deseni olay-sayımı, o kalıba uy.

⛔ Bu, YENİ MOTOR YÜZEYİ demek — koordinatöre SOR, tek başına yazma
(bu gece üç kez aynı sınıf için doğru şekilde reddedildi).

## 3b. Kurucu dönene dek bekler

- **Mağaza liste taslağı onayı** (`docs/store/listing.json`, taslak hazır,
  kod-gerçeğine dayalı) — özellikle hook-dürüstlüğü konumlandırması:
  *"gerçek bir hook dersini uygulamadan geçirdik ve neredeyse hepsini
  kaçırdı, o yüzden güvenilir göremediğimizi puanlamıyoruz."* Gönderim
  zaten kurucu kalemi (M-F-77) — bu yalnız İÇERİK onayı.
- İkon · cihaz turu · store metadata gönderimi (erişim-kilitli).
- Sürüm: `0.1.0+1`→`1.0.0+1` kararı.

## 4. Adıyla açık kalanlar (kaydedildi, çözülmedi — bilerek)

- **⑤. katman** (`$openLayer5_conditionNeverTrue`, `boxing@1.0.0.json`):
  atanan bir alan gerçek veriye karşı hiç TRUE olmuyor mu? Statik kaynak
  taramasıyla ölçülemez — gerçek fixture/replay gerektirir.
- **`gateable` alanının dar tanımı:** yalnız bant+eklem-uzlaşısı ölçüyor,
  `evaluateAt`-ulaşılabilirliğini ÖLÇMÜYOR. Soru: bir alan adı, tanımı
  dosyada yazılı olsa bile, adıyla vaat ettiğinden dar kalıyorsa okuyucuyu
  yanıltır mı? (`drills.drill.combo_slow` `gateable:true` diyor, hedefleri
  ölü kodlara ait — teknik olarak yanlış değil, "yanıltıcıya komşu".)
- **`footwork_combo`nun M-C-04 riski:** kesin ikinci engel yok ama adıyla
  ("Footwork WITH combinations") bir tasarım riski var — M-C-04 kapandığında
  combination-bağlamı varsayarsa aynı ölü mekanizmaya (③) çarpar.
- **3 kilitli dersin durumu:** `combinations` — İKİ engel (teknik-modelleme
  + ③'ün kalıcı erişilemezliği). `counter` — TEK engel, taranmış, ikinci
  yok (yapısal-tam). `footwork_combo` — TEK kesin engel + yukarıdaki risk.
- **Store metadata ikiye ayrıldı:** liste İÇERİĞİ (`docs/store/listing.json`,
  taslak hazır, ASC erişimi gerektirmez) vs yükleme/gönderim (erişim-kilitli,
  kurucu). `docs/KURUCU-BRIFI-2026-08-12.md`: ikon/cihaz-turu/store hâlâ
  değişmedi (07-08'den beri), ekran sayısı 3↔10 sapması çözüldü (kanonik:
  katı 6 / gevşek 11, `reachable_screens_test.dart`).

## 5. Bu gece öğrenilen, adlandırılmamışsa aktarılamayacak şey

**Yeni bir yüzey yazmak, ESKİ yüzeylerin iddialarını denetler.** Mağaza
metnini yazmak (yeni bir yüzey) beni "bu iddia neye dayanıyor?" sorusunu
sormaya ZORLADI — ve o soru `one_two`nun aylardır canlı olan yanlış
iddiasını açığa çıkardı. Yayın envanterinin (J-124) "içerik yazmak kapıları
sınar" dersinin bir üst basamağı: **içerik yazmak yalnız kendi kapılarını
değil, KOMŞU yüzeylerin kapılarını da sınar.** Bir sonraki oturum yeni bir
yüzey (metin, ekran, mağaza sayfası) yazdığında bu soruyu sorsun: *bu
iddia, benim yazdığım yüzeyin DIŞINDA da doğrulanmış mı?*

**Vekil ölçüt tuzağı, bu gece HEM ailede HEM bende:** koordinatörün
`*screen*.dart` grep'i (3↔6/11 sapması) ve benim `tail` ile workspace
DEFTER'i okumam (J-204) aynı sınıf — bir dosyanın SONU, onun EN YENİSİ
anlamına gelmez; sıralama varsayımını ÖNCE doğrula.

---
---

# 🎨 GİYDİRME — FAZ 3 (kalan yüzeyler) · devir 2026-08-06, koordinatör yazdı

> **Bu blok en güncel talimattır ve altındaki her şeyden ÖNCELİKLİDİR.**
> Kurucu direktifi: **beş hattın giydirmesi bitmeden başka işe geçilmiyor.** Bu, kalan
> son büyük giydirme parçası.

## 0. NEREDE KALDIK (git-doğrulandı)
`main` = `e3c1bee`, 0/0, ağaç temiz. Faz 1 (yeniden yapılandırma) + Faz 2 (tokenlar +
Ayarlar) bitti — 6 commit.

**Yapı artık:** `SelectPage`(A) · `CoursePage`(B, `lib/app/`) · `SessionScreen`(C) ·
`SettingsPage`(köşe). 4-sekme kabuk kalktı; kurs varsa giriş B, yoksa A.
`lib/shell_candidate/` **DOKUNULMAZ** (dondurulmuş terfi envanteri; şerh düşüldü).

**GİYDİRİLEN:** tema tokenları (OKLCH→sRGB kodda) + Ayarlar köşesi.
**GİYDİRİLMEYEN — bu turun işi:** **Sayfa A · Sayfa B · Ders ekranı (C).**

## 1. İLK İŞ — KOD YAZMADAN: REPLİK ERİŞİLEBİLİRLİK TARAMASI
Koordinatörün öz-hatası: `cues.en.json`'ı panele *"bunlar gerçek metinler"* diye verdi;
panel `cue.low_light` ve `cue.partial_analysis`'e **ekran tasarladı** — ama motorda ışık
ölçümü YOK ve kısmi-okuma yüzdesi alanı YOK. **Repliğin varlığı, tetiğinin varlığı değil.**

→ **Tüm cue kitabını tara:** hangi replikler hiç ateşlenmiyor?
→ Ateşlenmeyen = **ÖLÜ KOPYA** (var olmayan yeteneği iddia eden kullanıcı-görünür metin).
→ Bulguyu J-kaydı olarak yaz. **İkisiyle sınırlama, tam tarama.**

## 2. DÜRÜST HÂLLER — ÖLÇÜM YAPILDI, HÜKÜMLER VERİLDİ
Motor **~8** hâl üretiyor; koordinatörün brief'i **5** yazmıştı → **brief eksikti**,
tasarımın 8'i gerçeğe daha yakın. Kaynak: motorun sealed tipleri, tasarım değil.

| Hâl | Hüküm |
|---|---|
| `resolution.usable==false` (kimse yok) | ✅ uygula |
| `QualityIssue.outOfFrame` (kadraj dışı) | ✅ uygula |
| `QualityIssue.lowTrackingConfidence` | ✅ uygula — metin: *"I can't see you clearly enough to judge."* |
| `QualityIssue.torsoUnreliable` | ✅ **AYRI tut** — *"gövdeni okuyamıyorum"* ≠ *"kadraj dışındasın"*, eylem farklı |
| `structural:` suppress (M-019) | ✅ hâl gerçek — metin: *"My tracking looks wrong — holding off."* |
| `LivePermissionDenied` geçici/kalıcı | ✅ ikisi ayrı (kalıcıda "tekrar dene" YOK) |
| `LiveCameraUnavailable`/`LiveSetupFailed` | ✅ uygula |
| ⛔ **"Too dark"** | **SEBEP UYDURMA — ship EDİLMEZ.** Motor "güven düşük" der, nedenini bilmez |
| ⛔ **"%62 okudum"** | **alan YOK — sayı gösterilmez.** Hâl meşru olabilir, veri yok |

**04 "yanlış iskelet çizimi" — ŞARTLI:** çizilecekse **sistemin hatalı okuması olduğu
tartışmasız belli olmalı** (kullanıcı *kendini* öyle sanmamalı). Belirsizliğe yer
bırakmadan yapamıyorsan **çizme** — metin tek başına dürüst. *Ayrım derece değil TÜR.*

## 3. KAMERA ÖN-İZLEMESİ — brief'teki "✅ var" YANLIŞTI
Çekirdek sözleşmesi (`~/motion-worktrees/coordinator-main/docs/70-KAMERA-KOPRUSU-SOZLESMESI.md`):
· **iskelet overlay UYGULANABİLİR** (landmark'lar Dart'ta, gerçek)
· ⛔ **kamera görüntüsü BUGÜN YOK** — Dart görüntüye dokunamaz; `Texture` tabanlı preview
  **bilinçli ERTELENMİŞ** (kalıcı sınır DEĞİL)
→ Sahte görüntü/stok/blur-doku **UYDURMA**. Yokluğu dürüstçe göster +
`PLACEHOLDER(asset): camera preview — unblocked by: Texture-based preview
(registrar.textures), deliberately deferred, docs/70-KAMERA-KOPRUSU-SOZLESMESI.md`

## 4. BAĞLAYICI KAYNAK: brief + ZEYİL
`docs/design/DESIGN-PANEL-PROMPT.md` — **Z1-Z8 zeylini de oku.** Panel Q&A'sında alınan
kararlar orada; brief tek başına eksik. (Z1 gradyan-zemin · Z6 metinler GERÇEK ·
Z8 portrait + iOS çerçeve · Z7 `{price}` yuvası.)
**Sapma raporlamadan önce zeyle bak** — bir kez onaylı karar "sapma" diye raporlandı.

## 5. AİLE DERSLERİ — hepsi ölçülmüş, hepsi sende geçerli
- **375pt kapısı ZATEN KURULU** (`test/narrow_viewport_overflow_test.dart`) — yeni ekranları
  da kapsamına al. `flutter_test` varsayılanı **800pt**, gerçek telefonun 2 katı.
- **Gerçek metinle giydir**, fixture'la değil. Ekran kanıtı **en dar cihazda**.
- **Gölge `ClipRRect` içinde kırpılır** · **`borderRadius` yalnız tek-renkli border'da**
  (ikisi de sende bir kez ısırdı).
- **Çıkmaz sokak yasağı:** dokunulan her şey bir yere gitmeli (Ostinato demo derslerinde
  "Begin" düğmesi olmadığını buldu — aynı sınıf).
- **Türetilmemiş eşik → kullanıcıya HÜKÜM cümlesi** üretemez (Ostinato'da
  `> 0.66 → "Needs focus."` reddedildi; kişiyi değil olguyu betimle).
- **Ekran kanıtı KAPIDIR** ama **periyodik öğede tek kare yetmez** (M-F-281).

## 6. KAPANIŞ ZİNCİRİ
`DESIGN-AHEAD-OF-CODE.md` güncelle (**iki yön**) · `PLACEHOLDER-REGISTER` (kapı: `unblocked
by` yoksa exit 1) · uyum tablosu (**uyumlu / ihlal / ölçülmedi** — üç sınıf) · kapılar ·
ekran kanıtı · DEFTER+PROGRESS · commit+push · rapor.

## 7. YETKİ
commit+push+merge KALICI İZİNLİ. Yapı/IA değişikliği ve ürün davranışı → koordinatöre.
Bağlam sıkışırsa **tamamlanmış ekran grubunda İSİMLİ DUR** — yarım ders ekranı,
başlanmamış ders ekranından kötüdür.

---
---

# ⏸️ BEKLEME MODU — DESIGN LİNKİ BEKLENİYOR (devir: 2026-08-05, koordinatör yazdı)

> **Bu blok en güncel talimattır ve altındaki her şeyden ÖNCELİKLİDİR.**
> Aşağıdaki eski bölüm (önceki oturumun devir promptu) teknik durum/sınırlar için
> GEÇERLİ — ama "kendi tasarımını sen yap" varsayımı **SÜPERSEDE** edildi (M-F-279).

## 🎨 Yeni model (kurucu kararı 2026-08-05)
Tasarımlar **TEK design-orkestrasyonu oturumunda** üretilir (Remotion + Claude design
paneli), sonra sana **tasarım linki + giydirme brief'i** olarak gelir. Her uygulama
KENDİ dilinde, birbirinden TAMAMEN FARKLI tasarlanacak.

**BU OTURUMDA YAPMAYACAKLARIN:**
- ❌ Tasarım kararı üretme (renk/tipografi/düzen/akış dili) — yön koordinatörden gelir.
- ❌ Kendi başına design turu başlatma, UI yeniden yazma, "cila" turu koşma.
- ❌ Kurucuya doğrudan tasarım sorusu sorma (M-F-77; koordinatörden geçer).

**BU OTURUMDA YAPACAKLARIN:**
1. Aşağıdaki okuma listesini bitir (bağlam kopukluğu olmasın).
2. Ağacı doğrula: `git -C ventures/jablab/app status` + `git -C ventures/jablab/app log -1` (**beyana değil ağaca güven**).
3. Kısa bir "hazırım" özeti yaz: okuduklarını + doğrulanan tepe commit'i + varsa
   ağaçta beklenmedik bir şey. **Sonra BEKLE.**
4. Giydirme brief'i gelince: tasarımı KENDİ yüzeyine uygula, dürüstlük sınırlarını
   ESNETMEDEN (aşağıda), kapılarını koştur, commit+push (kalıcı yetkin var).

## 📖 Okuma listesi (sırayla — bağlam bunlarda)
1. **Vault:** `knowledge/Yula Lab/20 Şirketler/Motion/🔄 Oturum Devri 2026-08-05 — JabLab Kamera Entegrasyonu.md` — senin son turunun kaydı.
2. **Vault:** `📊 Durum Panosu — Motion.md` → **08-05 "GÜNCEL DURUM BU BLOK"** (altı tarihsel).
3. **Vault:** `🔄 Oturum Devri 2026-08-05 — Orkestratör Kamera Dalgası Kapanışı → Design Orkestrasyonu Devri.md` — §4 yeni model + §5 kalan işler.
4. `ventures/jablab/workspace/DEFTER.md` + `PROGRESS.md` — **son bölüm** (kendi hükümlerin).
5. `ventures/motion-core/workspace/DEFTER.md` — **M-F-260 → M-F-279** (aile kuralları, bağlayıcı).
6. Bu dosyanın altındaki eski bölüm — teknik durum, ölçülmüş tuzaklar, bağlayıcı sınırlar.

## 📍 Senin durumun (2026-08-05, git-doğrulandı)
**Kamera entegrasyonu TAM** — main `0f4ef25`, push 0/0, ağaç temiz. Canlı yol (J-096) kapalı; yerel store emekli, v1→v2 göç CİHAZDA doğrulanmış; doc-75 adopsiyonu ✅. Onboarding ürün-kararı design turuna park edilmişti — brief gelince açılır.

**İlk işin:** okuma listesi + ağaç doğrulaması + 'hazırım' özeti, sonra BEKLE (tasarım linki gelecek).

## 🚧 Tasarımda da ESNEMEYEN sınırlar (giydirme sırasında geçerli)
- **K8:** kalibre edilmemiş sayısal skor YOK ("bant, nokta değil").
- **M-F-186:** vaat dili (`comingSoon`/"yakında") YASAK · engelli özellik İSİMLİ
  gerekçeyle görünür · `measurementOnly` beyanı **yüzeyin TEPESİNDE** (konum içeriğin parçası).
- **Dürüst hâller birinci sınıf ekrandır** (izin · kamera-yok · kimse-yok · kadraj-dışı) —
  tasarım bunları "artık" gibi ele alamaz; hâl-başına ayrı render yolu korunur.
- **Türetimli listeler elle yazılmaz** · ham `detail`/hata kodu yüzeye sızmaz.
- **Ekran kanıtı KAPIDIR:** "testler metnin VARLIĞINI sınar, DOĞRULUĞUNU sınamaz"
  (95 yeşil test yanlış-anatomi metnini görmedi — Lissom P0 dersi).
- Yeni ölçü/kapı/eşik tasarımı veya dürüstlük-metriği hükmü → **koordinatöre**.

## ⚙️ Kalıcı kurallar
- commit + push + merge **KALICI YETKİLİ**; `ventures/motion-core/lib` paylaşımlı ağacında
  **dal değiştirmek YASAK** (M-F-22).
- **iCloud-altı repoda `git add -A` yerine DOSYA-İSİMLİ add** (0-bayt `index.lock` riski, M-F-273);
  başkasının untracked dosyasına dokunma (M-016; `* 2.plist`-sınıfı iCloud artıkları dahil).
- **Bağlam sıkışırsa İSİMLİ DURDUR** — sessiz kalite düşüşü yerine isimli duruş (aile standardı).
- **Cihaz-kanıtı vaat edilmez:** iOS sim'de kamera YOK; gerçek-kamera canlılığı cihaz gününe
  ertelendi (kurucu, tek oturum). Hiçbir yüzey "cihazda kanıtlı" demez.

---
---

# JabLab — yeni oturum devir promptu

**Bunu aynen yeni bir Claude Code oturumuna yapıştır.** Tek devir kaynağı
budur; başka hiçbir dosyayı önceden okumana gerek yok, aşağıdaki sıra seni
doğru yerlere götürür.

> Son güncelleme: **2026-08-05 kamera paketi kapanışı.** Önceki devir
> SÜPERSEDE — kayıtlar J-092…J-096.
>
> ## 🎨 SIRADAKİ TUR: DESIGN
>
> Bu oturumun işi **tasarım turudur**. Kamera hattı ürüne bağlandı ve
> yapı katmanı testli; eksik olan **görsel dil**. Yapı DEVRALINIR, yeniden
> keşfedilmez — aşağıdaki "Tasarım turu girişi" bölümü ne hazır, ne
> bekliyor, neye dokunulmaz onu söylüyor.

---

## Kimlik ve rol

Sen JabLab'ın (Yula Motion ailesinin boks/gölge-antrenman app'i) geliştirme
oturumusun. Koordinasyon "Motion Orchestration" adlı ayrı bir oturumdan
gelir — cross-session mesajlarla iş sevk eder, kararları hakemlik eder,
aile-geneli kuralları yayar. Sen **repro sahibisin**: ölçüm, kod, test,
commit senin işin; plan/strateji kararları koordinatöre sorularak alınır
(founder'a doğrudan soru YASAK — tüm tereddüt koordinatöre gider).

**Standing yetki (kurucu 2026-07-29 doğrudan verdi, hâlâ geçerli):**
commit/push/merge bu ailede (Motion app'leri) kalıcı izinli. Diğer TÜM
venture'larda genel kural aynen: commit/push/submit/deploy öncesi kurucuya
sor.

## Başlangıç sırası

1. `../VENTURE.md` + bu dizindeki (`workspace/`) diğer dosyaları tara.
2. Aile sözleşmesi: `ventures/motion-core/lib/docs/00-AILE-MIMARISI.md`
   **+ `docs/75-SESSION-SURFACE-HONESTY.md`** (oturum-geçmişi yüzeylerinin
   normatif dürüstlük sözleşmesi — JabLab'ın kendi ölçümleri girdiydi).
3. `../app/docs/jablab-plan.md` + `../app/CLAUDE.md` (kod başlatma kilidi
   AÇIK).
4. `DEFTER.md`nin **son 30-40 satırını** oku (J-092→J-096 + vardiya mührü).
5. Aşağıdaki "Güncel durum" ve "İş kuyruğu"nu oku, ilk işe geç.

## 🎨 TASARIM TURU GİRİŞİ (bu oturumun ASIL işi)

**Kanonik brief:** `../app/docs/design/UI-BRIEF.md` — §3 ekran envanteri
(her ekranın GERÇEK durumları), §4 açık sorular, **§5 tasarımı BAĞLAYAN
sert kurallar** (ihlal = test kırılır, estetik tercih değil).

**Yapı katmanı BİTMİŞ, görsel dil BEKLEYEN kalemler:**

| kalem | yapı | tasarımcıya kalan |
|---|---|---|
| Dürüst hata ekranı (J-079) | ✅ testli | görsel dil |
| Öğretici materyal yuvası (J-094) | ✅ testli | materyal VARKEN nasıl görünür (oynatıcı/çizim) + yokluk beyanının dili |
| **Canlı kamera yüzeyi (J-096)** | ✅ testli | **ön-izleme yuvası**, sayım/faz tipografisi (2-3 m'den okunur), üç dürüst hâlin görsel ayrımı |
| Kilit görsel dili | ✅ içerik hazır | ceza değil BEYAN gibi görünmeli (3 ders kilitli) |
| İlerleme sayfası üç-hâl (J-092/J-095) | ✅ testli | beyan/kısmi/temiz hâllerin görsel ayrımı |

**Comp gerektiren ama ÜRÜN KARARI da bekleyen (tek kalem):**
**Onboarding** — bilerek yapılmadı. Belirsiz olan görsel dil DEĞİL: UI-BRIEF
"hedef seçimi — ürün kararı bekliyor" diyor ve bir kalıcılık kararı
(onboarding-tamamlandı bayrağı nerede yaşar) gerekiyor. Tasarım turuyla
BİRLİKTE ele alınacak (koordinatör parked kalemi).

**⛔ TASARIMIN DEĞİŞTİREMEYECEĞİ ŞEYLER** (mekanik olarak zorlanıyor):
kalibrasyonsuz SAYI yok (K8) · `power`/`force`/`kph` kelimeleri replikte
geçemez · "yakında" disiplinde kurs render edilmez · dürüstlük kutusunda
`notMeasured` boş olamaz (assert) · kilitli ders SEBEBİYLE gösterilir ·
kalibrasyon kurulmadan "sol/sağ" denmez (M-F-06) · fiyat sabit yazılmaz ·
**kabuk klasöründe alan sözlüğü yasak** · **kabuk envanteri DONDURULDU**
(yeni bileşen eklenmez; mevcutta düzeltme serbest).

**Tasarım turunda ekrana BAKMADAN bitirme:** bu vardiyada üç kusur yalnız
simülatörde göründü (gotcha #8).

## Güncel durum (2026-08-05 kapanışı)

**Repo:** `jablab/app` main **`1ca4b23`**, origin ile eşit.
`flutter analyze` temiz · `flutter test` **130/130** ·
`packages/jablab_engine`: `dart analyze` temiz · `dart test` **113/113**.
Açık dal YOK · bekleyen merge YOK · kırmızı kapı YOK.

**🎥 KAMERA HATTI ÜRÜNE BAĞLI (J-096).** `boxing.foundations.jab` dersi
kamerayı açıyor (karar İÇERİKTEN: `Lesson.usesCamera`). Zincir:
`frames()` → `EnvelopeDriver` → `OrientationAwarePoseSource` →
`StrikingEngine` → `LiveJabState`. Sayım + faz geri bildirimi K8-uyumlu
(sayım bir OLGU, skor değil).

> ⚠️ **CİHAZDA KANITLANMADI — isimli release-gate.** Kurucu direktifi
> (M-F-263): cihaz günü TEK SEFERE ertelendi. Elimizdeki: iOS sim +
> Android debug DERLEME · sahte-kaynaklı uçtan uca testler · simülatör
> ekran kanıtı. **§7.3-7.7 açık.** Hiçbir beyan "cihazda kanıtlı" DEMEZ;
> iki beyan (derleniyor / cihazda çalışıyor) AYRIDIR.

**Çekirdek pini: `motion_core` 0.11.0 + `motion_camera` 0.1.2**, ikisi de
tek commit `f13bdc9`ten (tag'ler AYRI commit'lerde durur; pin TEK olmak
zorunda — `dependency_pin_test.dart` bunu çözümlenmiş sürümden zorluyor).
Seans geçmişi artık **çekirdekten** gelir (`HistoryReadStatus` üç-hâl
sözleşmesi); yerel depo modeli J-095'te emekli oldu.

**Fitness-track: 4/4 SHIP-PROOF** (değişmedi). Kanıt:
`../app/docs/gates/FITNESS-SHIP-KANITI.txt`.

**Jab referansı:** `attested-provisional` (değişmedi). Artefakt:
`ventures/motion-core/workspace/artifacts/reference-boxing-jab.json`.

**🏆 HOOK HAVUZU: M-C-04 tabanı KARŞILANDI — 6 uygun eğitmen**
(precision_striking · yankello · tony_jeffries · myboxingcoach ·
marvin_cook · fightcamp). Marka payı fightcamp 1/6 → yoğunlaşma kuralı
sağlanıyor. **AMA hook REFERANSI KURULAMAZ** ve sebebi malzeme DEĞİL:
`segment_punches.dart` pencereleri FSM'in faz geçişlerinden kesiyor, FSM
kancayı **hiç modellemiyor** (`lockedBy: technique-unmodelled`) → kesilecek
pencere üretilmiyor. **Kilit MEKANİZMA tarafında;** bu tur malzemeyi
getirdi, kilit açıldığı gün hazır olacak.

**Kamera köprüsü: DERLENİYOR ✅ · CİHAZDA ÇALIŞIYOR ⏳** (iki beyan AYRI
tutulur, karıştırma). **§7.1 YÜKSELTİLDİ: artık "derleniyor" değil
"simülatörde KOŞTU"** — codesign panzehiri uygulandı ve `build/` →
`~/jablab_buildout` symlink'i KURULU. Cihaz günü yalnız §7.3-7.7 için.

## İş kuyruğu

0. **🎨 TASARIM TURU — bu oturumun işi** (yukarıdaki giriş bölümü).
1. **D3 göz-doğrulaması** — `D3-GOZ-DOGRULAMA-KUYRUGU.md`, **4 kalem**,
   12-18 dk, **kurucu-manuel**. Bu gelmeden hook/uppercut hakkında YENİ
   sayısal iddia kurma. Sonrası: hook-mekanizması kararı **koordinatörle**.
2. **Gerçek cihaz §7.3-7.7** — **kurucu-manuel**. Codesign panzehiri ZATEN
   uygulandı; hazırlık işi kalmadı, doğrudan koşuma geçilebilir.
3. **Onboarding** — tasarım turuyla BİRLİKTE ele alınır (madde 0).
   Bilerek yapılmadı: belirsiz olan görsel dil DEĞİL, **ürün kararı**
   (UI-BRIEF "hedef seçimi — ürün kararı bekliyor" diyor) + bir kalıcılık
   kararı. Comp döndüğünde ikisi birlikte ele alınacak.
4. **Hasat turu devamı** — `HASAT-TURU-HOOK-UPPERCUT.md` §7 "kalanlar":
   `2I4HLsi0RuU` altyazısız (yalnız göz) · `ihifYbOBBHM` D3 kalem 4'te
   (havuz ona bağlı DEĞİL) · `vlLmPtwSQlM` triyaj reti payı 0,8 (39,2 vs 40).
5. Yeni koordinatör paketi.

## Kritik gotcha'lar

**#1 — "X videosu" ≠ "X olayı".** Bir kaynağın KONUSU, içindeki her olayın o
teknik olduğu anlamına gelmez. D3 kuyruğu tam bu boşluk için var.

**#2 — Uygunluk (romMode) CÜMLE değil KAYNAK düzeyinde ölçülür.** Cümle-
düzeyi yanlış-pozitifi kaynak-düzeyi yanlış-pozitifle KARIŞTIRMA.

**#3 — Paylaşımlı git ağacından ARAÇ KOŞMAK, HEAD'e dokunmak kadar
kirletir.** `motion-core/lib` başka bir oturumun dalında olabilir. Her zaman
izole worktree:
```bash
git -C ventures/motion-core/lib fetch origin
git -C ventures/motion-core/lib worktree add --detach ~/motion-worktrees/<isim> origin/main
```
**Venv İSTİSNASI** (J-058 emsali): `fixture_pipeline/.venv/bin/python` yalnız
YORUMLAYICI olarak paylaşımlı ağaçtan kullanılabilir — kod izole
worktree'den gelir, o ağacın HEAD'ine dokunulmaz.

**#4 — Rig kendi bayatlığını söylüyor.** `rig_version()` çıktısında
`behindOriginMain` > 0 / `vendored: true` / `onMainLineage: false` varsa o
koşumun kararlarına güvenme. **Ama uyarıyı görünce paniğe kapılma: SINIRI
ÖLÇ.** J-093'te behind=2 çıktı; eksik commit'ler yalnız
`fixture_pipeline/mocore/`ye dokunuyordu → `harvest_rig/` kararları
etkilenmedi.

**#5 — Her "X yok" testinin yanına "X var" testi yaz.** Tek yönlü bakan her
regresyon testi şüpheli. **Ve `skip`li test bırakma** — kapsama gibi görünen
ama olmayan bir satırdır; metni değil SONUCU ölç.

**#6 — Fallback'in ölü olmasının İKİ mekanizması var**, ayırt eden sayı
ABORT sayacı. Reçete: `ventures/motion-core/workspace/FALLBACK-CANLILIK-RECETESI.md`.

**#7 — Bir orana "düşük" demek, kontrol koşulundaki değerini ölçmeden
mümkün değil.** Her `oov:` ölçümü, aynı raporda en az bir kontrol satırıyla.

**#8 — TESTLER YEŞİL ≠ KULLANICI DOĞRU ŞEYİ GÖRÜYOR (ÜÇ KEZ ölçüldü).**
Widget testi metinlerin VARLIĞINI görür; aralarındaki MESAFEYİ, ÇELİŞKİYİ
ve ANLAMINI görmez. Yakalananlar: kısmi-beyan üst paragrafa yapışıktı ·
gövde "materyal yok" derken sekme "Watch" diyordu · analiz başlamamışken
çıplak **0** ("sıfır yumruk attın").
**Kullanıcı-görünür her değişiklikten sonra simülatörde BAK.**

**#9 — Simülatörde veri enjeksiyonu: BAYAT CONTAINER TUZAĞI.** Uygulama her
yeniden kurulduğunda container UUID'si değişir. Saklanmış bir yola yazmak
sessizce YANLIŞ ŞEYİ kanıtlar — hata mesajı YOK, yalnız beklenmedik bir
ekran (ve onu kolayca "kod bozuk" diye okursun). `get_app_container`ı
enjeksiyondan HEMEN ÖNCE çağır. Reçete:
`../app/docs/gates/KAMERA-KOPRUSU-CANLILIK.md`.

**#10 — "Eğitmen elendi" ≠ "video elendi".** Eleme kayıtları KAYNAK
düzeyinde tutulur; kimlik düzeyi türetilir, birincil olmaz. Havuz-içi
kimlik = **ekrandaki eğitmen**, marka/kanal DEĞİL — bir kanal, adı geçmeyen
bir eğitmenin kendi kanalı olabilir (J-093'te tam bunu yanlış okudum).

**#12 — MAKİNE PAYLAŞIMLI: 5 hat paralel koşuyor.** Simülatör çekişmeli —
başka bir hattın `flutter run`ı seni tekrar tekrar arka plana atabilir.
Çözüm: diğer app'leri `simctl terminate`, kendi app'ini `launch`, HEMEN
screenshot. Yeni bir cihaz açmak MCP izni ister (kurucu başında değilse
kullanılamaz). Build çakışırsa bekle-yeniden dene.

**#11 — Pin bump tek başına ADOPSİYON DEĞİLDİR** (doc-75/7). Çekirdek bir
üyeyi zorunlu yapabilir; zorunluluk UYGULAYANI bağlar, KULLANANI değil.
Adaptör üyeyi yazıp yüzeyde hiç sormazsa her şey derlenir ve ürün sessiz
kalır. Emsal nöbet: `test/core_adoption_test.dart` **casus depo** —
`unreadableRecords()` gerçekten çağrılmazsa test düşer.

## Araçlar

- `../app/packages/jablab_engine/tool/` — `measure_punch_signature.dart` ·
  `measure_window_band.dart` · `measure_fallback_liveness.dart` (`oov:` ön
  eki ZORUNLU beyan) · `fetch_pose_model.sh`.
- **`d1_gate.py` artık KALICI ve motion-core main'de**
  (`tools/harvest_rig/d1_gate.py`). Alan sözlüğü PARAMETREYLE:
  `../app/docs/harvest/lexicon-boxing.json`. Çekirdek alan-bağımsız kalır —
  boks terimi çekirdeğe YAZILMAZ. Kapı konu SAFLIĞINI ölçer; `material`
  alanı yalnız UYARIDIR, eleme değil.
- Hasat kütüphanesi: `~/motion-harvest/jablab/` (git DIŞI); `queue.txt`
  eleme kayıtlarını SEBEBİYLE taşır.

## Sert kurallar (özet, tam liste `../app/CLAUDE.md`)

Ortak altyapı motion-core'dan PİNLİ gelir, kopyalanmaz · gerçek-zamanlı LLM
yok · düşük güvende hüküm yok · kural = versiyonlu config · replay-fixture'sız
teknik eklenmez · tıbbi dil yasak · kalibrasyonsuz sayı gösterilemez (K8) ·
kabuk klasöründe alan sözlüğü yasak · **kabuk envanteri DONDURULDU** (yeni
bileşen eklenmez; mevcutta düzeltme serbest).
