# 🥊 JabLab — Kurucu Brifi · 2026-08-12 (koordinatör istekli yeniden-ölçüm)

**Soru (koordinatör aktardı):** *"Bugün kod tarafında yayına engel olan NE kaldı — ve kaçı gerçekten KURUCU kalemi?"*

**Cevap: 3 engel, ÜÇÜ DE hâlâ kurucuda — 2026-08-07'den bu yana değişmedi.** Bu gece kod tarafında büyük hacimde iş oldu (kamera-basis politikası, commit kapısı, build/ P0'ı, estimatedMinutes) ama **bu üç kaleme hiçbiri dokunmadı** — sınıfları değil, adları/kanıtları tazelendi.

Ölçüm tarihi: 2026-08-12 · `main 6c2526e` · app 279/279 · motor 123/123 · analyze temiz.

---

## ⛔ GÖNDERMEYİ ENGELLEYEN (3) — 07-08'den değişmedi

| # | engel | sınıf | kanıt (bu turda tazelendi) |
|---|---|---|---|
| 1 | **Uygulama ikonu Flutter varsayılanı** | `manuel-kurucu` | `git log` — ikon dosyalarına dokunan **tek commit** `53a4992` (G5 iskele üretimi, 2026-07-26). O tarihten bu yana **sıfır** düzenleme. |
| 2 | **Kamera yolu gerçek cihazda hiç koşmadı** | `manuel-kurucu` (1 cihaz-oturumu) | Değişmedi — `KAMERA-KOPRUSU-CANLILIK.md` §7.3-7.7 hâlâ açık, simülatör turu bile kurucu onayında bekliyor |
| 3 | **Store metadata** | `manuel-kurucu` **AMA İKİ AYRI ALT-KALEM** (aşağıda) | `find` ile arandı: repoda **sıfır** taslak metin/ekran görüntüsü/liste. `VENTURE.md`: *"store kaydı bekliyor"* |

### #3'ün ayrımı — koordinatörün istediği netlik

Store metadata İKİ FARKLI ŞEY, ve ikisi de bugün eksik ama **sebepleri farklı**:

| alt-kalem | bugünkü hâl | kim başlatabilir |
|---|---|---|
| **Liste İÇERİĞİ** (açıklama, anahtar kelime, yaş derecelendirmesi, gizlilik-beyanı soruları) | **HAZIRLANMADI** — bu ASC erişimi GEREKTİRMEZ, saf metin yazımı | Bir sonraki oturum (ben) BAŞLATABİLİR, ASC beklemeden |
| **Yükleme/gönderim** (ekran görüntüsü çekimi, ASC'ye giriş, submit) | **ERİŞİM YOK** — bu session'da app-publish MCP'si yüklü değil, ASC key erişimim yok | Yalnız kurucu (erişim ver ya da kendisi yapsın) |

**Bu ayrım maliyetli çünkü:** "store metadata ölçülmemiş" tek cümlesi kurucuya *"hiçbir şey yapılamaz, erişim ver"* dedirtir. Gerçek: **yarısı** (liste metni) bugün, erişim beklemeden yazılabilir. Bunu bu turda BAŞLATMADIM (koordinatör talimatı: "yeni iş açma, ölçüm bu") — yalnız sınıfını ayırdım.

---

## 📱 Ekran sayısı — koordinatörün 3↔10 sapması ÇÖZÜLDÜ

Koordinatörün `*screen*.dart` grep'i **3** verdi çünkü JabLab 8 UI-yüzey dosyasının **5'ini** `*_page.dart` adlandırıyor (`onboarding_page`, `select_page`, `course_page`, `settings_page`, `library_pages`), yalnız 3'ünü `*_screen.dart` (`session_screen`, `camera_harness_screen`, `content_failure_screen`) — vekil zayıftı, dosya adı bir yazım kuralı, ölçüt değil.

**Kanonik sayı `test/reachable_screens_test.dart`dan gelir** (J-167, kapılı, 279/279'un içinde koşuyor):

> ***Sayma kuralının katılığına göre 6 ile 11 arasında değişir.*** Katı okuma (yalnız ayrı rota) = **6** — `{onboarding, select, settings, whyNot, course, session}`, testin kendi `expect` kümesi. Gevşek okuma (onboarding'in 3 perdesi + session'ın 4 aşaması ayrı sayılırsa) = **11**.

**"10" muhtemelen `docs/design/UI-BRIEF.md`'nin "11 ekranın envanteri" ifadesinin yanlış hatırlanmış hâli** (11≈10, tasarım-yüzeyi envanteri — gevşek okumaya yakın ama JabLab'ın kendi kapısı 11 diyor, 10 değil). Kanonik: **6 (katı) / 11 (gevşek)**, ikisi de yazılı, ikisi de test'e bağlı — "10" hiçbir kapıdan gelmiyor.

---

## 🔢 Sürüm — bu bir KARAR, ÖLÇÜM DEĞİL

`pubspec.yaml`: `0.1.0+1` (bugünkü gerçek, değişmedi). 2026-08-07 brifinde `1.0.0+1` **önerilmişti**, gerekçesiyle birlikte (sürüm numarası bir beyandır; `0.x` "ön sürüm" der, App Store'da yayımlanan şey ön sürüm değildir). O öneri **kurucu kuyruğunda bekleyen bir karardı** ve hâlâ öyle — ölçülecek yeni bir şey yok, gerekçe zaten yazılı (`KURUCU-BRIFI-2026-08-07.md`). Kod tarafından tek satırlık bir değişiklik ama **numara bir beyan olduğu için** kurucu onayı bekliyor, teknik bir blokaj değil.

---

## ✅ 07-08'den bu yana KAPANAN (kod tarafı, engel değildi zaten)

Bilgi amaçlı — hiçbiri yukarıdaki 3 engeli etkilemedi:

- $cameraBasis politikası (ADR-005) — 12 ders, gate reachability 12→0
- Commit kapısı depoya taşındı + taze klonda kanıtlandı (3 tur, iki gerçek gap bulundu-düzeltildi)
- `build/` sembolik linkin makineye özel mutlak yolu git'ten çıkarıldı (P0)
- `$gatePrimitivesWithoutProducer` — config/motor katman ayrımı isimlendirildi
- `conditioning.estimatedMinutes` 54→78 (J-191), kapı "eşitlik YA DA adlı fark" şeklinde

## ⛔ Bu turda dokunulmayan, adıyla açık

- `one_two` / J-162-163: `COMBINATION_END`'in motorda geçtiği yeniden sınanmadı
- `boxing.foundations.camera`/`stance`'in `setupCheckPassed`/`stanceHold` üreticisi yazılmadı (bilerek — kapsam dışı, ADR-005)

---

## ⛔ Dürüstlük notu

Bu briften çıkan hüküm net: **kod tarafında yayına engel kalan bir şey yok, kalan üçü de gerçekten kurucuda** — ikisi (ikon, cihaz turu) tamamen kurucu-manuel; üçüncüsü (store metadata) YARISI kurucu-erişimli, yarısı bir sonraki oturumun bugün başlatabileceği içerik işi. Ekran sayısı ve sürüm sorularının ikisi de artık ya kapılı bir ölçüme ya da isimli bir karara bağlı — tahmin kalmadı.
