# `lib/shell_candidate/` — motion_shell'e terfi adayları

**Karar:** M-F-25 — platform katmanı ailede **BİR KEZ** üretilir (`motion-core/packages/motion_shell`). JabLab bu üretimin **pilotudur**.

## Kural

Bu klasördeki her şey, 5 app'in de kullanacağı **alan-bağımsız** kabuk parçasıdır ve koordinatör tarafından `motion_shell`'e terfi ettirilecektir. Buraya yazarken tek soru: *"Bu dosya Ostinato'da (çello) ve Choreia'da (salsa) da anlamlı mı?"*

- ✅ **Buraya ait:** sekme çatısı · kütüphane/öğe/kurs/ders sayfa şablonları · ilerleme grafikleri · ayarlar/profil · paywall iskeleti · dürüstlük kutusu · "yakında" rozeti · "Neden yok?" sayfası
- ❌ **Buraya ait DEĞİL:** canlı kamera seansı, yumruk görselleştirmesi, tur zamanlayıcısı, disipline özgü metin — bunlar `lib/app/` altında

## Sözleşme

1. **Alan sözlüğü yok.** Bu klasörde `punch`, `jab`, `round`, `boxing` gibi kelimeler geçmez. Öğeler `Item`/`Course`/`Lesson` genel adlarıyla anılır.
2. **İçerik enjekte edilir, gömülmez.** Widget'lar veriyi parametre olarak alır; hiçbir dosya `library.json`'ı kendi okumaz — okuma `lib/app/` katmanının işidir.
3. **Tema token üzerinden.** Sabit renk/ölçü yazılmaz; `Theme.of(context)` kullanılır.
4. **Bağımlılık yönü tek yönlü:** `app → shell_candidate`, asla tersi. Bir dosya `lib/app/`'e veya `jablab_engine`'e bağımlıysa **terfi edemez** — olsaydı `motion_shell` Ostinato'ya boks kural motorunu da taşırdı.

> ## 🔒 ENVANTER DONDURULDU (2026-07-29)
> Koordinatör sabah turunda bu 13 bileşeni `motion_shell`'e taşıyacak.
> **Bu klasöre yeni bileşen EKLENMEZ** — yeni kabuk-adayı parçalar terfi
> tamamlanana dek `lib/app/` altında yaşar ve sonraki turda taşınır.
> Mevcut bileşenlerde düzeltme serbest; ekleme değil.

> ## ⚠️ ŞERH (2026-08-06, M-F-267 sınıfı — koordinatör talebi)
> **JabLab bu tarihte `ShellScaffold`/`ProgressPage`/`LibraryPage`/`ItemPage`/
> `library_pages.dart`'ın kendi `CoursePage`'ini ÇAĞIRMAYI BIRAKTI** (design
> turu, 4-sekme kabuk → 3 sayfa + köşe; `lib/app/course_page.dart` adında
> AYNI-ADLI ama AYRI bir dosya yazıldı — karıştırmayın; bkz.
> `docs/design/DESIGN-PANEL-PROMPT.md` + `jablab_app.dart` git tarihi
> `fb9ba8f`). Dosyalar SİLİNMEDİ — terfi kaderi aile kararı, koordinatörde
> (ölçüm: `packages/motion_shell` çekirdekte hiç doğmadı; bu klasör YALNIZ
> JabLab'da var).
>
> **Neyi ölçtüğü artık değişti:** `test/shell_promotion_test.dart` hâlâ
> yeşil ve hâlâ doğru şeyi ölçüyor — dosyaların sözlük/bağımlılık
> sözleşmesini. Ama **canlı bir tüketici üzerinden değil**: JabLab'ın kendi
> app akışı bu dört bileşene artık dokunmuyor. Test bir kapının ÇALIŞTIĞINI
> değil, kapının hâlâ AYAKTA DURDUĞUNU kanıtlıyor — ikisi aynı şey değil.
> Bayat yeşil kırmızıdan tehlikelidir: bunu ölçmeden okuyan biri "JabLab
> hâlâ bunu kullanıyor" sanabilir.
>
> `test/progress_recorded_test.dart` (66 testten biri — `session_rounds_test`
> · `live_jab_path_test` · `teach_material_test` · `session_narrator_test`
> · `shell_promotion_test` ile birlikte) de aynı sınıftan: `ProgressPage`'i
> DOĞRUDAN pompalıyor, JabLab'ın kendi kök yönlendirmesinden geçmiyor —
> bileşen sağlam, ama artık hangi ekranda göründüğünü DEĞİL, hiç
> görünmediğini test etmiyor.

## Bileşen listesi (terfi kapsamı)

> **Kayıt ölçüldü (2026-08-07, J-135).** `PaywallStub` satırı *"JabLab hâlâ
> kullanıyor"* diyordu; **0 atıf** çıktı. Zarar geliştirici-yüzüydü ama somut:
> bir sonraki oturum paywall iskeletini sevk ediliyor sanır ve oradaki
> `"Pricing is not set **yet**"` — yasaklı sözcük — canlı zannedilir. (Gerçek:
> erişilemez borcun içinde, `promise_language_test`te sayılı; canlı ayarlar
> sayfası `"Pricing is not set."` diyor.)
>
> **Koordinatör hükmü (08:32): freeze KODU dondurur, KAYDI değil.** Donmuş kod
> dokunulmaz; donmuş kod HAKKINDAKİ kayıt canlıdır ve doğru tutulmak
> zorundadır — çünkü terfi kararı bu kayda bakarak verilecek ve **yanlış kayıt
> donmuş kodu korumaz, onun hakkındaki kararı bozar.**
>
> ⚠️ *"JabLab çağırmıyor"* = **uygulama** çağırmıyor. `ProgressPage` ve
> `ShellScaffold`u **testler çağırıyor** (`progress_recorded_test`,
> `shell_test`). Erişilemez bir sayfayı sabitleyen test, kapsam sayarken
> **kapsama benzer ama kullanıcıya ulaşan hiçbir şeyi ölçmez** — terfi turunda
> bu ayrım korunmalı.

| Dosya | Bileşen | Rolü | Terfi |
|---|---|---|---|
| `shell_models.dart` | `ShellLibrary` · `ShellItem` · `ShellCourse` · `ShellLesson` · `ShellExclusion` | Kabuğun nötr görünüm modelleri; app kendi alan modelini bunlara çevirir | ✅ hazır |
| `shell_scaffold.dart` | `ShellScaffold` | 4 sekmeli alt navigasyon (Today · Library · Progress · Profile); **2-tık kuralının** taşıyıcısı | ✅ hazır · ⚠️ JabLab çağırmıyor (08-06) |
| `shell_scaffold.dart` | `ProgressPage` | Bant + eğri gösterimi; `numericUnlocked=false` iken **sayı render eden yol yoktur** (K8/M-F-04'ün UI karşılığı) | ✅ hazır · ⚠️ JabLab çağırmıyor (08-06) |
| `shell_scaffold.dart` | `PaywallStub` | Fiyat sabit yazılmaz — kurucu kararı | 🟡 iskelet (IAP bağlanınca genişler) · ⚠️ **JabLab çağırmıyor** (ölçüldü 08-07: 0 atıf) |
| `library_pages.dart` | `LibraryPage` | Öğe ızgarası + "Neden yok?" girişi; kapsamın tamamı görünür, "yakında" rozetli | ✅ hazır · ⚠️ JabLab çağırmıyor (08-06) |
| `library_pages.dart` | `ItemPage` | Öğe sayfası: tanıtım + dürüstlük kutusu + kurs listesi; **açılmamış öğede kurs başlığı bile render edilmez** | ✅ hazır · ⚠️ JabLab çağırmıyor (08-06) |
| `library_pages.dart` | `CoursePage` | Ders listesi | ✅ hazır · ⚠️ JabLab çağırmıyor (08-06, kendi `lib/app/course_page.dart`ını yazdı) |
| `library_pages.dart` | `WhyNotPage` | Kapsam-dışı gerekçe sayfası | ✅ hazır · JabLab hâlâ kullanıyor |
| `honesty_box.dart` | `HonestyBox` | "Neler ölçülür / neler ÖLÇÜLMEZ"; `notMeasured` boşsa **assert ile patlar** | ✅ hazır |
| `session_flow.dart` | `SessionStage` + `SessionFlowScaffold` | Ders akışı: öğret → dene → canlı → özet. `stage.judges` yalnız `live`'da true — öğrenme anında puanlamak öğrenmeyi cezalandırır | ✅ hazır |
| `session_flow.dart` | `IntervalTimer` | Süreli çalışma aralığı. **Adı bilerek "round" değil**: boks turu, dans kombosu, kata tekrarı ve enstrüman pasajı aynı şey | ✅ hazır |
| `live_surface.dart` | `LiveState` + `LiveCoachSurface` | Canlı seans yüzeyi (ürünün yıldızı): tek düzeltme, ses birincil, **"göremiyorum" ayrı bir durum** — sessizlik "her şey yolunda" derdi | ✅ hazır |
| `live_surface.dart` | `SessionSummaryView` | Bant özeti + **koçlanan-ama-skorlanmayan** başlıklar; kullanıcı neden puan almadığını bilmeli (J-033) | ✅ hazır |

**Henüz yok (sıradaki dalgalarda buraya eklenecek):** kamera önizleme yuvası (app-özel içerik enjekte edilir) · arama + filtre (seviye/süre/ekipman) · "tüm kurslar" dizini · streak/rozet · hatırlatıcı ayarları · hesap silme akışı · paylaşım kartı · onboarding + hedef akışı · kamera kurulum sihirbazı çatısı (⚠️ *sihirbazın kendisi* app-özel eşiklerle çalışır; kabuğa yalnız **akış iskeleti** çıkar, kabul kriterleri app'ten enjekte edilir).

## Terfi şartları

Bir bileşen `motion_shell`'e ancak şu beşini birden sağlarsa alınır:

1. **Sözlük denetimi temiz** — dosyada alan terimi geçmiyor (`grep -riE 'punch|jab|round|boxing|cello|salsa|handstand'` boş dönmeli).
2. **İçe aktarma denetimi temiz** — `jablab_engine` veya `lib/app/` import'u yok.
3. **En az iki app'te anlamlı** — soyut değil somut kontrol: bileşenin Ostinato (çalgı) ve Choreia (stil) sayfalarında ne göstereceği bir cümleyle yazılabiliyor.
4. **Davranış testi var ve app'ten bağımsız koşuyor** — widget testi kabuk modeliyle besleniyor, `library.json` okumuyor.
5. **Dürüstlük değişmezi taşıyorsa o değişmez testli** — ör. `HonestyBox`'ın boş `notMeasured` ile patlaması, `ProgressPage`'in kalibrasyonsuz sayı sızdırmaması.

Terfi sonrası bu klasör boşalır ve `motion_shell` bağımlılığı gelir; app tarafında kalan tek şey import satırı + çeviri katmanı olur.

## Bilinen borç

- Widget testleri şu an `lib/app/` üzerinden uçtan uca koşuyor (gerçek `library.json` ile). Terfi şartı #4 bunların **kabuk modeliyle beslenen** sürümlerini istiyor; ayrıştırma terfi turunda yapılacak.

> ## ✅ ŞERH (2026-08-19, JAB-P0-001) — "JabLab çağırmıyor" artık BEYAN değil KAPI
>
> Yukarıdaki tablonun "⚠️ JabLab çağırmıyor" satırları (2026-08-06/07
> tarihli) o günün ÖLÇÜMÜYDÜ — koruması yoktu, bir sonraki oturum bu altı
> bileşenden birini yanlışlıkla `lib/app/`e bağlarsa hiçbir test kırmızı
> ötmezdi. Ölçüldü: `test/shell_promotion_test.dart` (halihazırda mevcut)
> bunu SINAMIYOR — sözlük/bağımlılık terfi ön-koşulunu ölçüyor, kullanıcı
> erişilebilirliğini değil (isim çakışması: JAB-P0-001'in beklediği
> "duplicate route/dead candidate FAIL" testi bu DEĞİL). Ve
> `test/reachable_screens_test.dart`nin aday-türetme deseni (`Scaffold(`
> gövde-içi araması) `ProgressPage`/`PaywallStub`/`LibraryPage`yi HİÇ
> görmüyor (düz `ListView(`/`Card(` döndürüyorlar) ve candidate
> `CoursePage`yi `lib/app/course_page.dart`taki AYNI-ADLI gerçek sınıfla
> karıştırıp "varılan" sanıyor (`Set<String>` ad çakışması).
>
> `test/canonical_shell_reachability_test.dart` + `docs/evidence/
> production-line/baseline.json` artık altı bileşenin ALTISINI da eşit
> sıkılıkla zorluyor: beşi kod-metni taraması (`mentionedOutside`,
> yorumsuz), `CoursePage` isim çakışması yüzünden import-grafiği/`show`
> kısıtlaması ile (derleyicinin kendisi zorluyor, metin taraması değil).
> Terfi/silme kararı **hâlâ koordinatörde** — bu şerh o kararı ÖNCELEMİYOR,
> yalnız "çağırmıyor" iddiasını sessizce bayatlayamaz hâle getiriyor.
