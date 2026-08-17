# Cihaz günü reçetesi (F5, 2026-08-16)

**Amaç:** kurucu telefonunu bağladığında beş dakikada yürünecek, üç adımlı
bir akış. **Kurulum** (adım 2) otomatik/betiklenebilir — **yürüyüş**
(adım 3) kurucunun elini ister (`H-9`: fiziksel cihazda dokunuş MCP ile
sürülemez, simülatör araçları yalnız simülatör listeler).

Şema Ostinato'dan alındı (`docs/device-day/RECIPE.md`, O-160, aile-geneli
emsal — orkestratörün kendi sevki); adımların içeriği JabLab'ın kendisi.

📌 **Aile-geneli tuzaklar** (bu turda + Gravita'nın yayın provasında bulunan
dördü) paylaşılan tek yerde: `motion-core/workspace/CIHAZ-GUNU-AILE-
RECETESI.md` — bu dosya yalnız JabLab'ın kendi yürüyüş tablosunu taşır.

---

## 0 — "Görünüyor" ≠ "bağlı" (aile-geneli H-9 sınıfı bulgu)

`devicectl list devices` bir telefonu `available (paired)` gösterebilir **USB'ye
hiç takılı olmadan** — eşleşme kalıcı bir durumdur, canlı bağlantı değil. Ön-uçuş
betiği bunu ayırt ETMEZ (yalnız `paired` arar). **Kablosuz kurulum kilitli/uykudaki
telefonda ya düşer ya asılır** — cihaz gününe başlamadan ÖNCE gözle doğrula: telefon
fiziksel olarak USB'ye takılı VE kilidi açık mı, yoksa yalnız önceden eşleşmiş mi.
Emin değilsen `system_profiler SPUSBDataType | grep -i iphone` ile ikinci kaynaktan
doğrula (USB ağacında GERÇEKTEN görünüyor mu).

## 1 — Ön-uçuş (30 saniye, komut satırından)

```bash
python3 tools/device_day_preflight.py
```

Telefon USB ya da güvenilir Wi-Fi ile bağlıyken koş. Üç şeyi ölçer —
tahmin etmez: geçerli codesign kimliği var mı, `com.yulalab.jablab`
profili var/güncel mi, **bağlı cihazın GERÇEK UDID'si** (`devicectl`'in
kendi eşleşme kimliği DEĞİL — `H-9` dersi, ikisi ayrı değer) profilin
`ProvisionedDevices` listesinde mi.

**Bugün ölçülen durum (2026-08-16, cihaz BAĞLI DEĞİLKEN koşuldu — bu
turun kendi ölçümü, kurucunun cihazı değil):** ✅ 4 geçerli codesign
kimliği bulundu · ⛔ `com.yulalab.jablab` için HENÜZ hiçbir provisioning
profili yok (jablab bu makinede hiç on-device build/imzalama turu
geçirmedi). **Kurucu cihazı bağladığında bu adım YENİDEN koşulmalı** —
bugünkü "⛔" sonucu bir hata değil, henüz denenmemiş olmanın ölçümü.

⚠️ Betik `✅ ÖN-UÇUŞ TEMİZ` DEMEZSE, aşağıdaki adım 2'ye geçme —
önce şu komutla profili tazele (Automatic signing kendi üretir, kod
değişmez):

```bash
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination "id=<GERÇEK-UDID>" \
  -allowProvisioningUpdates build
```

## 2 — Kurulum (tek komut)

```bash
flutter install --release -d <cihaz-adı-veya-id-öneki>
```

**Neden `--release`, `--debug` DEĞİL** (`H-9`/aile ölçümü, bu kod
tabanında da doğrulanmış — kişisel hafıza `feedback-ios-cihaz-kurulum-
imza.md`): Flutter debug motoru cihazda JIT ister, iOS onu engelliyor —
paket kurulur, süreç başlatılabilir bile görünebilir, ama anında
`signal 11` ile ölür. Yalnız `--release` (AOT derleme) cihazda GERÇEKTEN
çalışır. `--release` zaten `flutter install`ın VARSAYILANI — ekstra
bayrak GEREKMEZ, ama yanlışlıkla `--debug` yazılmasın diye burada adıyla
uyarılıyor.

## 3 — Yürüyüş (kurucu eli ister — beklenen kanıt listesi)

Bu tablo `lib/app/`nin GERÇEK dosyalarından türetildi (grep ile
doğrulandı, uydurulmadı) — cihazda AYNI ekranların GERÇEKTEN böyle
davrandığını doğrulamak bu reçetenin işi.

| # | Ekran/eylem | Ne YAPILACAK | "Çalışıyor" NASIL görünür | Sorun işareti |
|---|---|---|---|---|
| 1 | Uygulama açılışı | Ana ekrandan `JabLab` ikonuna dokun | Koyu zemin (`#0A0608`) açılış ekranı bir an görünür (J-282: şimdilik saydam — marka glifi kurucu-kapılı, `D8`), sonra "THE CORNER — Boxing practice you can do alone." onboarding kartı gelir | Beyaz ekran/kırpışma/çökme (debug paketiyse SIGNAL 11 burada olur) |
| 2 | Onboarding (3 kart) | İlerlet | "THE CORNER" (karşılama) → "BEFORE YOU START — What this cannot do." (dürüstlük: güç ölçülmez, kişisel antrenör değil) → "EVERY SESSION — Where to put the phone." (kurulum) sırayla | Metinler boş/placeholder görünüyorsa içerik paketi eksik demektir |
| 3 | Kamera izni | "EVERY SESSION" kartındaki izin adımı | Sistem izin diyaloğu ÇIKAR (uygulamanın kendi ekranı DEĞİL) — reddedilirse "IF YOU SAY NO TO THE CAMERA" bloğu izinsiz akışı anlatır | İzin diyaloğu HİÇ çıkmazsa `NSCameraUsageDescription` sorunu |
| 4 | Ana ekran (`select_page.dart`) | Onboarding biter | "Where you left off" (varsa) + "Courses": Foundations (8 ders) · Rounds and conditioning (7 ders) · Intermediate (4 ders) | Ders sayıları bunlardan farklıysa `library.json` paketleme sorunu VEYA bu reçete güncellenmeli |
| 5 | Bir ders seç → canlı seans | Foundations'tan bir ders aç, "Start" | Canlı kamera görüntüsü ÜZERİNE iskelet-nokta çizimi biner, doğru yumruk atınca sayaç ARTAR | Kare gelmiyor/donuk görüntü → kamera köprüsü canlılık sorunu (**bu turda YALNIZ simülatörde test edildi, kamera izni orada otomatik reddediliyor — cihaz günü bunun İLK gerçek kanıtı olacak**) |
| 6 | Bir yumruğu EKSİK/yanlış at (örn. kolu tam uzatma) | Bilerek eksik hareket yap | Sayılmaz — motor yalnız FSM'in tam faz zincirini (GUARD_READY→…→GUARD_RECOVERED) gördüğünde sayar | Her hareket sayılıyorsa faz-kapısı devre dışı kalmış demektir (P0) |
| 7 | Seansı bitir | Dur/bitir | Özet ekranı: "`N` intervals/rounds • `M` worked" + tamamlanan deneme varsa "Pace: controlled/brisk/fast" (D18) + "Coached but not scored" kutusu | Özet alanları boş/`—` kalıyorsa `SessionSummaryView`e veri ulaşmıyor demektir |
| 8 | Ana ekrana dön, başka bir kurs aç | Rounds and conditioning ya da Intermediate'a dokun | Ders listesi + her dersin süre/teknik etiketleri görünür | Kurs açılmıyorsa/boşsa `content_repository.dart` yükleme sorunu |
| 9 | Bir ders detayına gir | "The cross" ya da "The 1-2" dersini aç | Öğretim metni + "We cannot tell you how hard it lands" / "judging the two together... is not something the app does today" gibi dürüstlük cümleleri görünür | Vaat-dili (güç/otomatik puan) görünüyorsa `promise_language_test.dart`ın canlıda YAKALAMADIĞI bir satır demektir — adıyla bildir |
| 10 | Uygulamayı tamamen kapat, YENİDEN aç | Home'a dön, app switcher'dan kapat, yeniden aç | Onboarding TEKRAR ÇIKMAZ (bir kez tamamlandı, hatırlanır), doğrudan ana ekrana düşer | Onboarding her seferinde çıkıyorsa `onboarding_store.dart` yazmıyor demektir |

**Bu turda YAPILMAYAN, cihaz günü İLK KEZ ölçülecek olanlar (adıyla,
belirsizlik gizlenmedi):** kamera köprüsünün canlılığı (madde 5-6) —
bugüne kadar YALNIZ simülatörde koşuldu ve simülatörde kamera izni
genelde OTOMATİK REDDEDİLİYOR, yani GERÇEK bir telefon kamerasının
GERÇEK bir insan gövdesini okuyup okumadığı bu proje için **hiç
ölçülmedi.** Cihaz günü bunun ilk kanıtı olacak — reçete bunu bir "son
kontrol" değil **asıl soru** olarak çerçeveliyor (Ostinato'nun kendi
çerçevesi, aile-geneli).

## 3b — Otomatik canlılık probu (madde 5-6'nın YERİNE değil YANINA — ölçüm, göz değil)

Yukarıdaki madde 5-6 "iskelet noktaları çiziliyor mu" diye GÖZLE bakar —
göz bir sayı üretmez. `integration_test/device_liveness_probe_test.dart`
(H-82 görevi, 2026-08-17) AYNI zinciri (izin→model→kamera→30 sn ölçüm)
kodla sürer ve bir **artefakt dosyası** bırakır: fps (judged/captured/
judgedRatio/meanInferenceUs), **ilk-poz gecikmesi** (hiçbir yerde
tutulmuyordu — YENİ), **landmark geçerlilik oranı** (kaç zarfta model
bir insan gördü — `judgedRatio`dan FARKLI, o kanalı ölçer bu modeli) ve
kendiliğinden ayırt edilen **düşme modu** (`permission_denied` ·
`model_materialize_failed` · `camera_start_failed` · `no_envelope_flow`
· `no_person_detected` · `stream_error` · ya da hiçbiri = temiz koşum).

```bash
flutter test integration_test/device_liveness_probe_test.dart -d <cihaz-id>
```

Madde 5'e girip canlı seansı açtıktan sonra (kameranın kendine baktığından
emin ol) koş — 30 saniye boyunca telefonu kendine doğru tut. Artefakt
uygulamanın Documents dizinine JSON olarak yazılır, tam yol terminale
basılır (Xcode "Cihaz ve Simülatörler" ya da eşdeğeriyle çekilebilir).

**Durum (2026-08-17 yazıldı):** `flutter analyze` temiz, kod cihaz
BAĞLI DEĞİLKEN yazıldı — bu turun kendi ölçümü GERÇEK cihazda henüz
KOŞULMADI (H-68: yazıldı ≠ koşuldu, iki ayrı durum). Cihaz günü ilk
koşum bu betiğin kendisini de sınayacak.

---

## Kaynaklar

- Ön-uçuş betiği: `tools/device_day_preflight.py`
- Canlılık probu: `integration_test/device_liveness_probe_test.dart`
  (H-82, 2026-08-17 — artefakt yazan, tek komutlu ölçüm)
- İmza/kurulum dersi: kişisel hafıza `feedback-ios-cihaz-kurulum-imza.md`
  (aile çapında `H-9`, Ostinato `O-129`/`O-130`)
- İçerik/dürüstlük zemini: bu reçete `lib/app/onboarding_page.dart` ·
  `lib/app/select_page.dart` · `assets/content/library.json`in GERÇEK
  metin/sayılarını taşır (grep ile doğrulandı) — cihazda AYNI davranıp
  davranmadığını doğrulamak bu reçetenin işi.
