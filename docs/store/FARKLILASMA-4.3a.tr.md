# Jablab — App Store 4.3(a) farklılaşma dosyası (hazırlık, gönderim YOK)

Bilet: JAB-P1-01 · Tarih: 2026-11-14 · Kapsam: yalnız belge (`docs/store`). Mağazaya, Resolution Center'a ve ASC'ye hiçbir şey gönderilmez; kod ve uygulama davranışı değişmez. Taban: `main` = `c8ae7de`.

**Önemli:** Jablab 1.0.0 için Apple'ın ret gerekçesi bu bilette **okunmadı**. Bu belge gerekçeden bağımsız bir hazırlıktır; gerekçe gelince §3 ve §4 yeniden yazılmalıdır. Emsal biçim: Lissom'un `docs/store/FARKLILASMA-4.3a.tr.md` dosyası (Lissom deposu, salt-okur okundu).

Kaynak kuralı: yollar bu depo köküne göredir. `../../…` ile başlayanlar kardeş depodur (salt-okur). Dosya:satır yalnız bu bilette okunmuş dosyalardandır; satır verilmemişse "dosya düzeyinde"dir.

## 1. Jablab'a özgü olanların kanıtlı envanteri

| # | Özgü öğe | Kanıt (dosya:satır) |
|---|---|---|
| 1 | Beş dövüş sanatında yazılı başlangıç kursları: boks 39 ders / 8 modül, kickboks 16, Muay Thai 16, karate kihon 16 + Taikyoku Shodan 10, Tai Chi 14 + Yang Family 16 yazılı çalışma (18 ders). Sayılar JSON'dan sayıldı (boks modül→ders toplamı 39/8; Taikyoku `content.lessons` 10) | `assets/content/solo_boxing_course.v1.json` (modules); `kickboxing_a.v1.json:134`; `muay_thai_a.v1.json:291`; `karate_a.v1.json:193`; `taikyoku_shodan_jl.v1.json:941`; `tai_chi_course.v1.json:43`; `yang16_angela_written.v2.json:73`; ders sayıları kodda: `lib/app/course_access.dart:38-45` |
| 2 | Kurs başına ayrı yükleyici ve sayfa (7 kurs sayfası/yükleyicisi) | `lib/app/solo_boxing_course.dart`, `kickboxing_course.dart`, `muay_thai_course.dart`, `karate_course.dart`, `taikyoku_shodan_course.dart`, `tai_chi_course.dart`, `yang16_written_course.dart`; sayfalar `*_course_page.dart` |
| 3 | Yazılı hatırlama ve değerlendirme: 5 alanda (boks, tai chi, kickboks, karate, Muay Thai), her alanda 2 dersli yazılı hatırlama; yanıtlar kurs/sensör/hesap deposuna girmez | `lib/app/study_review.dart:9`; içerik `lib/app/study_review_content.dart:36,82,131,177,226` (5 alan kimliği okundu: boxing, taichi, kickboxing, karate, muaythai); giriş düğmesi `lib/app/select_page.dart:225` |
| 4 | Boksa özgü içerik kaynakları: Boxing Canada başlangıç/yarışma kılavuzları, England Boxing Level 1, ACOG gebelik egzersizi | `assets/content/solo_boxing_course.v1.json:17-40` |
| 5 | İsteğe bağlı temassız "başlangıç denemesi" paneli (kamera/depolama/ilerleme API'si yok) | `lib/app/self_guided_practice_panel.dart:6-9`; `lib/app/self_guided_practice.dart:14` |
| 6 | Kurs ilerlemesi: kullanıcının kendi beyanı, cihazda | `lib/app/solo_boxing_progress.dart:11,58,89`; `lib/app/course_progress_io.dart:73-77` |
| 7 | 14 dil (arayüz + dersler): tr, en, es-419, pt-BR, de, fr, ja, ar, it, ko, id, pl, hi, zh-Hans | `lib/app/ui_language.dart:24-39`; `assets/i18n/*.json` (14 dosya); mağaza metni `docs/store/listing*.json` (14 dosya) |
| 8 | Ücretsiz bölüm kuralı kurs başına: boks 10/39, kickboks 5/16, Muay Thai 5/16, karate 5/16, Taikyoku 3/10, Tai Chi 5/14, Yang16 6/18 | `lib/app/course_access.dart:26-34,38-45`; `docs/store/release-review.json:6` ile aynı |
| 9 | Ana ekran: tek sayfa kurs seçimi (alt gezinme yok); yazılı kursu bağlı disiplinlerin "yakında" kartı gizlenir | `lib/app/select_page.dart:42-47,93-98`; `lib/app/jablab_app.dart:653-660` |
| 10 | Onboarding: 3 adım, "KÖŞEN / Tek başına boks pratiği" dili | `lib/app/onboarding_page.dart:62,143-165` |
| 11 | Mağaza kimliği: "JabLab: Shadow Training" / "Solo martial arts practice" (TR: "JabLab: Gölge Boksu") | `docs/store/listing.json:4-5`; `docs/store/listing.tr-TR.json:4` |
| 12 | İkon: koyu mor/siyah zemin, kırmızı bantlı yumruk ve beyaz kavisli "J" kuyruğu (görüntü okundu) | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` |
| 13 | Ders içeriği medyası: kaynak sabitleme katalogları var, ancak paketli medya klasörü yok (`assets/content/media/` bulunamadı) → gösterim videosu yok | `lib/app/lesson_media_catalog.dart:10`; `pubspec.yaml:115` (`assets/content/`); mağaza: `docs/store/listing.json:12` "Demonstration video is not included" |

**Kamera "yok" sayılır.** `jablabCameraCoachingAvailable = motionCameraCoachingAvailable` (`lib/main.dart:48`) ve Core'da `motionCameraCoachingAvailable = false` (`../../motion-core/lib/packages/motion_account/lib/src/motion_release_policy.dart:6`). Üretimde bayrak `JabLabApp`'e geçer (`lib/main.dart:168`); kapalıyken kamera dersleri "kilitli" listelenir (`lib/app/content_repository.dart:728-775`, kilit gerekçesi `lib/app/course_locale.dart:134-136`). Bu nedenle şunlar farklılaştırıcı sayılmadı: canlı kamera/duruş değerlendirmesi (`lib/app/live_jab_controller.dart`, `camera_harness_screen.dart`, `skeleton_overlay.dart`, `packages/jablab_engine/`), boks ruleset'leri (`assets/rulesets/`), otomatik yumruk sayımı, `library.json` içindeki 17 `usesCamera` dersi (boks 21 dersin 17'si; sayım JSON'dan). Hareket paneli yalnız "Bu ders için otomatik hareket değerlendirmesi desteklenmiyor" der (`lib/app/technique_capability_panel.dart:33-38`).

Kapalı kameradan kalan izler (tutarlılık için not): iOS `NSCameraUsageDescription` "Camera coaching is disabled…" diyor (`ios/Runner/Info.plist:55-56`); Android bildiriminde `CAMERA` izni duruyor (`android/app/src/main/AndroidManifest.xml:6`). İkisi de bu bilette değiştirilmedi (kapsam dışı: kod/manifest).

## 2. Ortak şablon tablosu: Lissom §2'ye atıf + Jablab sütunu doğrulaması

Beş uygulamalık karşılaştırma tablosu yeniden yapılmadı; bkz. Lissom `docs/store/FARKLILASMA-4.3a.tr.md` §2 (salt-okur). Orada JabLab sütunu diğer depodan okunmuş, bazı hücreler "doğrulanmadı" bırakılmıştı. Jablab deposundan hücre hücre doğrulama:

| Öğe | Lissom §2'deki JabLab hücresi | Doğrulama (bu depo) |
|---|---|---|
| İkon | "koyu zemin, kırmızı bantlı yumruk" | **Doğru**; ayrıntı: beyaz kavisli "J" kuyruğu da var (§1 #12) |
| Ana düzen | "`shell_candidate/` aday kabuk 4 sekme; üretim kabuğu olduğu doğrulanmadı" | **Üretim kabuğu değil.** Üretimde `SelectPage` açılır, alt gezinme yok (`lib/app/jablab_app.dart:653`; `lib/app/select_page.dart:93-98`). `ShellScaffold` aday kodu (`lib/shell_candidate/shell_scaffold.dart:39-70`, 4 sekme Today/Library/Progress/Profile) uygulama tarafından çağrılmıyor (`lib/shell_candidate/README.md:60-68`: "JabLab … ÇAĞIRMAYI BIRAKTI"; testler çağırıyor). `grep "ShellScaffold("` dışında üretim kullanımı bulunamadı. Yani 4 sekmeli Lissom/Gravita kalıbıyla **ortak değil** |
| Onboarding | `onboarding_page.dart:150,160` | Doğru; 3 adım (`:62`), boks odaklı metin (`:143-165`) |
| Paywall / erişim | `course_access.dart:9,26,114` | Doğru: ücretsiz-önce yorumu `:9-12`, ücretsiz sayılar `:26`, `PaywallSheet` `:114` |
| Abonelik düzeni | "ilk dersler ücretsiz; üyelik" | Doğru; JabLab bireysel + Motion+ ürün kimlikleri `docs/store/release-review.json:146-169` |
| ASC metni | "JabLab: Shadow Training" / "Solo martial arts practice" | Doğru: `docs/store/listing.json:4-5` |
| Core | `motion_core` import eden 8 dosya | Doğru: `lib/` içinde 8 dosya (skeleton_overlay, live_jab_controller, camera_harness_screen, session_store, owner_resource_lifetime, technique_observation, technique_task, technique_provider_adapter); dosya adlarına göre çoğu kamera/oturum kodu (içerikleri tek tek okunmadı) |

Sonuç: Lissom §2'de "ortak olabilir" denen JabLab alt-gezinme benzerliği Jablab'da **yok**; ortak kalan: Core çatısı, ücretsiz-önce erişim kalıbı, "Motion+" üyeliği ve "Ad: Etiket" mağaza kalıbı.

## 3. Boşluk listesi ve düzeltme tahminleri

Resmî ret metni okunmadığından boşluklar kanıtlardan türetilmiştir. Beden: S ≈ metin/not, M ≈ küçük kod+mağaza varlığı, L ≈ ürün farklılığı. Hiçbiri bu bilette uygulanmaz.

| # | Boşluk | Kanıt | Önerilen düzeltme | Beden |
|---|---|---|---|---|
| G1 | Beş Motion uygulaması aynı dönemde, ortak çatı ve erişim kalıbıyla gönderildi | §2; Lissom dosyasının G1'i | Gönderimleri zamana yay; Resolution Center'da olgusal açıklama | S |
| G2 | Üyelik ve erişim kalıbı ortak ("Motion+" beş uygulamayı açar) | `docs/store/release-review.json:161-179` | Yapısal değişiklik kurucu kararı; yalnız metinde Jablab'a özgü kapsamı öne çıkar | M |
| G3 | Onboarding yalnız boksu anlatıyor, uygulama beş alan sunuyor; ilk izlenim tek alanlı, kalan alanlar farklılaşmayı gösteremiyor | `lib/app/onboarding_page.dart:143-165` vs `docs/store/listing.json:12` | Onboarding metnine beş alanı yansıt (kod değişikliği, bu bilet dışı) | M |
| G4 | Kamera ve duruş değerlendirmesi kapalı; envanterdeki en güçlü teknik farklılaştırıcı yok sayılıyor | §1; `lib/main.dart:48` | Kamerayı gerekçe gösterme; bayrak kararı kurucuda | L (karar kurucuda) |
| G5 | Boks kütüphanesinde 17 "kilitli kamera dersi" listeleniyor; hakem boş/eksik içerik izlenimi alabilir | `lib/app/content_repository.dart:773-775`; `assets/content/library.json` 17 `usesCamera` | Ekranda doğrula; gerekirse kilitli dersleri gizle (kod, bu bilet dışı) | M |
| G6 | `library.json` içinde `coming_soon` disiplinler (taekwondo, mma_striking, wing_chun dahil; kalan dördü yazılı kursu varsa gizlenir) "yakında" rozetiyle çıkabilir; ekranda doğrulanmadı | `assets/content/library.json:492-534`; `lib/app/select_page.dart:42-47,371` | Ekranda doğrula; yayınlanmayan alanları gizle | S–M |
| G7 | Gösterim videosu yok, yalnız yazılı içerik; Apple "ince/şablon içerik" okuyabilir | §1 #13 | Mağaza metninde içeriğin özgünlüğünü ve kapsamını (`listing.json:12`) öne çıkar; ekran görüntülerini içerik sayfalarıyla yap (`release-review.json:89-110`) | S |
| G8 | Android'de `CAMERA` izni, iOS'ta kamera açıklaması bayrak kapalıyken bildirimde duruyor | `AndroidManifest.xml:6`; `Info.plist:55-56` | Kod/manifest işi; ayrı bilet | S |

Toplam: **8 boşluk** (S: 3 — G1, G7, G8; S–M: 1 — G6; M: 3 — G2, G3, G5; L: 1 — G4).

## 4. App Review notu / reviewer-notes denetimi (flag kapalı özelliğe atıf)

Denetlenen: `docs/store/release-review.json`, `STORE-LISTING-TASLAK.md`, `listing.json`, `listing.tr-TR.json` (diğer 12 dil dosyası: yalnız `cameraPermissionRationale` anahtarı var, içerik okunmadı).

- **Düzeltilen (1 yer):** `release-review.json` `screenshots.scenes` 5. sahne "movement feedback calibration-required panel" idi. Kamera/ölçüm kapalıyken kullanıcıya böyle bir "kalibrasyon gerekli" paneli gösterilmez; panel yalnız "otomatik değerlendirme desteklenmiyor" der (`lib/app/technique_capability_panel.dart:33-38`). Sahne, kapalı özelliğe atıf yaptığı için "written recall and review entry" olarak değiştirildi (gerçek, ulaşılabilir giriş: `lib/app/select_page.dart:225`).
- **Atıf yapmayan (doğru) ifadeler:** `appReview.en-US`/`tr-TR` kamera ve yumruk sayımının kapalı olduğunu ve eski kamera derslerinin kilitli gösterildiğini söylüyor (`release-review.json:15-16`; kodla uyumlu: `content_repository.dart:773`). `listing.json:12` ve `:10` kamera kapalı diyor. Değişiklik gerekmedi.
- **Not (bu bilette düzeltilmedi, kamera dışı):** `STORE-LISTING-TASLAK.md` girişi "abonelik satışı yoktur" diyor; `release-review.json:5` `subscriptionSalesAvailable: true` ve `listing.json:12` abonelik sunuyor. Tutarsızlık; ayrı karar/bilet.

## 5. Resolution Center yanıt taslağı (taslak, gönderilmez)

> Merhaba,
> JabLab, beş Motion uygulamasından biri olarak aynı dönemde incelemeye gönderildi; benzer bir paket gibi göründüğünü anlıyoruz. Gönderimleri zamana yayıyor ve JabLab'ı ayrı ele alıyoruz.
> JabLab beş dövüş sanatında (boks, kickboks, Muay Thai, karate, Tai Chi) özgün, 14 dilde yazılı başlangıç dersleri sunar: boks 39 ders / 8 modül, kickboks 16, Muay Thai 16, karate 16 + Taikyoku Shodan 10, Tai Chi 14 + Yang Family 16 yazılı çalışma. Dersler temassız solo pratiktir; yazılı hatırlama ve değerlendirme, kullanıcının kendi çalışma kaydı ve boks kursunda kaynak gösterilen içerik uygulamaya özgüdür. Diğer Motion uygulamaları başka alanlara aittir.
> Hesap, abonelik ve güvenlik altyapısı ile ücretsiz-önce erişim kalıbı ortaktır; içerik, ikon, ad ve alan ayrıdır. Bu sürümde kamera koçluğu kapalıdır ve bir farklılık olarak öne sürülmemektedir.
> Ek bilgi isterseniz memnuniyetle sağlarız.

Notlar: (a) Ret metni görülünce yeniden yazılır. (b) "Diğer uygulamalar başka alanlara aittir" cümlesi, yapısal olarak benzer içerik yapısı olmadığı varsayımına dayanır; gönderimden önce Motion orchestration doğrulasın. (c) Gönderim ve zamanlama kurucu/Motion orchestration işidir.

## 6. Doğrulanmayanlar

- Apple'ın resmî 4.3(a) ret metni (Jablab 1.0.0).
- Ekran düzeyi: boks kütüphanesinin kilitli kamera dersleri ve "yakında" kartlarının gerçek görünümü (G5, G6); `SelectPage` filtre uygulama satırı okunmadı.
- Çalışma sırasında okunmayanlar: 12 dil dosyasının içeriği, `lesson_media_source_pins_*.dart` içerikleri, paywall ekranının görsel düzeni.
- Yazılı içeriğin diğer Motion uygulamalarıyla alan/şema farkı karşılaştırılmadı.
- Lissom §2'deki diğer uygulama hücreleri bu bilette yeniden okunmadı.
