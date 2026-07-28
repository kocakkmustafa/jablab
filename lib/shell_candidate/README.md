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

## Bileşen listesi (terfi kapsamı)

| Dosya | Bileşen | Rolü | Terfi |
|---|---|---|---|
| `shell_models.dart` | `ShellLibrary` · `ShellItem` · `ShellCourse` · `ShellLesson` · `ShellExclusion` | Kabuğun nötr görünüm modelleri; app kendi alan modelini bunlara çevirir | ✅ hazır |
| `shell_scaffold.dart` | `ShellScaffold` | 4 sekmeli alt navigasyon (Today · Library · Progress · Profile); **2-tık kuralının** taşıyıcısı | ✅ hazır |
| `shell_scaffold.dart` | `ProgressPage` | Bant + eğri gösterimi; `numericUnlocked=false` iken **sayı render eden yol yoktur** (K8/M-F-04'ün UI karşılığı) | ✅ hazır |
| `shell_scaffold.dart` | `PaywallStub` | Fiyat sabit yazılmaz — kurucu kararı | 🟡 iskelet (IAP bağlanınca genişler) |
| `library_pages.dart` | `LibraryPage` | Öğe ızgarası + "Neden yok?" girişi; kapsamın tamamı görünür, "yakında" rozetli | ✅ hazır |
| `library_pages.dart` | `ItemPage` | Öğe sayfası: tanıtım + dürüstlük kutusu + kurs listesi; **açılmamış öğede kurs başlığı bile render edilmez** | ✅ hazır |
| `library_pages.dart` | `CoursePage` | Ders listesi | ✅ hazır |
| `library_pages.dart` | `WhyNotPage` | Kapsam-dışı gerekçe sayfası | ✅ hazır |
| `honesty_box.dart` | `HonestyBox` | "Neler ölçülür / neler ÖLÇÜLMEZ"; `notMeasured` boşsa **assert ile patlar** | ✅ hazır |

**Henüz yok (sıradaki dalgalarda buraya eklenecek):** arama + filtre (seviye/süre/ekipman) · "tüm kurslar" dizini · streak/rozet · hatırlatıcı ayarları · hesap silme akışı · paylaşım kartı · onboarding + hedef akışı · kamera kurulum sihirbazı çatısı (⚠️ *sihirbazın kendisi* app-özel eşiklerle çalışır; kabuğa yalnız **akış iskeleti** çıkar, kabul kriterleri app'ten enjekte edilir).

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
