# DESIGN-AHEAD-OF-CODE

> Design turu kapanış artefaktı (Choreia'nın deseni, aile standardı — koordinatör
> 2026-08-06). İki yönlü envanter: tasarımda var kodda yok · kodda var tasarımda yok.
> Tasarım bağlamı sıcakken üretildi; sonra çok pahalı olurdu.
>
> Kapsam: bu tur yalnız **Ayarlar köşesini** giydirdi (bkz. `git log` — `677849c`,
> `1a5a565`). Ders ekranı + dürüst hâller AYRI bir turun işi; oradan çıkacak yeni
> kalemler bu dosyaya EKLENECEK, üzerine yazılmayacak.
>
> **2026-08-06 ek:** Replik erişilebilirlik taraması (`REPLIK-ERISILEBILIRLIK-TARAMASI-2026-08-06.md`)
> `cues.en.json`'da kodun hiç çağırmadığı 32/62 anahtar buldu. Aşağıdaki üç grup
> muhtemelen **İÇERİK-öncü** (kasıtlı, bir sonraki özelliğin taslağı) — "tasarımda
> var, kodda yok" tablosuna yeni satırlar olarak eklendi. Geri kalanı (gerçekten
> yetim görünen anahtarlar) tarama dosyasının kendisinde.

## Tasarımda VAR, kodda YOK

| Kalem | Tasarımdaki hâli | Kodun bugünkü hâli | Neden şimdi yapılmadı |
|---|---|---|---|
| Ayarlar — profil kartı (isim, "Orthodox · lead hand left") | `isSettings` dalında ilk blok | Yok — hiç render edilmiyor | Karşılığı olan gerçek bir kullanıcı/hesap sistemi yok. Sahte isim/stance basmak bu app'in "ölçmediğimi söylerim" kimliğini ilk ekranda çiğnerdi. |
| Ayarlar — koçluk tercihleri listesi (ses seviyesi, düzeltme sıklığı, stance, haptik) | `isSettings` dalında "COACHING" bloğu, 4 satır | Yok | Karşılığı olan bir ayarlar-kalıcılık katmanı yok. Sabit değerler ("Loud", "One at a time") basmak çalışmayan düğmeler üretirdi — düğme olmamasından kötü (J-079 dersi). |
| Canlı kamera GÖRÜNTÜSÜ (tam-kadraj video) | Ders ekranı arkaplanı, tüm "dürüst hâller"in temeli | **✅ 2026-08-06 (Parça 2): İskelet overlay GERÇEK ve BAĞLI** (`skeleton_overlay.dart`, `LiveJabController.skeleton` → `SkeletonPreview` → gerçek `PoseLandmark` koordinatlarından çiziliyor, 2 gerçek-motor testiyle kanıtlı). **Kamera GÖRÜNTÜSÜ hâlâ yok** — `Texture`-tabanlı preview (`registrar.textures`) `docs/70-KAMERA-KOPRUSU-SOZLESMESI.md`ye göre bilinçli ERTELENDİ; ekranda `PLACEHOLDER(asset)` yorumu var ve `docs/design/PLACEHOLDER-REGISTER.md`de kayıtlı (ilk gerçek girdi). | Çekirdek yetenek kararı, koordinatörün kuyruğunda — yalnız bu parça kaldı. |
| 8 "dürüst hâl" (tasarım) vs 5 (brief) | `states` bölümü, 8 kart | **✅ 2026-08-06 (Parça 2) — J-099 DÜZELTİLDİ:** `LiveJabController._suppressionSentence` artık `quality:outOfFrame`→`cue.out_of_frame`, `quality:lowTrackingConfidence`→`cue.low_confidence`, `structural:*`→`cue.structural`, `quality:torsoUnreliable`→AYRI hardcoded cümle yönlendiriyor; ham teşhis dizesi ARTIK sızmıyor (2 gerçek-motor regresyon testi, `test/live_jab_path_test.dart`). **🔍 Yeni bulgu (ölçüldü, dört fixture denemesiyle):** `structural:` bastırması canlı hatta **mimari olarak erişilemez** — `OrientationAwarePoseSource` (motion_core) motor kareyi görmeden ÖNCE AYNI `StructuralValidator` kontrolünü çalıştırıp `resolution.usable=false`e (FARKLI, hardcoded bir cümleyle) düşüyor. Kod savunma amaçlı KORUNUYOR ama canlı-hat testiyle kanıtlanamıyor (bkz. `test/live_jab_path_test.dart`in ilgili grup yorumu). **"Too dark"/"Partial round %" hâlâ ship edilmiyor** (koordinatör hükmü değişmedi). | Motor tarafı KAPANDI. Kalan: skeleton/camera-placeholder'ın GÖRSEL cilası (bu turda `jablabSessionTheme`ile yapıldı) — 8 hâlin TAMAMININ ayrı ayrı görsel varyantı (renk/ikon farkı) henüz yok, hepsi aynı `LiveCoachSurface` şablonundan geçiyor. |
| Seçim→Kurs kart-devralma geçişi + ders-öncesi sahne (Z5, "ana akış") | Motion tokens: `takeover` 420ms, `scene` 340ms+stagger | Yok — bugünkü navigasyon Flutter'ın varsayılan `MaterialPageRoute` geçişini kullanıyor, özel animasyon yok | Z5 bunu "çalışan geçiş" gereken TEK yer sayıyor; Ayarlar turunda kapsam dışı bırakıldı, ders ekranı/Sayfa A-B turunda ele alınacak. |
| Disipline özgü kodlanmış arka plan geometrisi (8 gradyan, Katman 1) | Backdrop spec, Z1 | Sayfa A bugün düz koyu zemin (`Scaffold` varsayılanı), disiplin başına ayrışan gradyan YOK | Yalnız Ayarlar giydirildi bu turda; Sayfa A/B'nin görsel katmanı henüz tokenlara geçmedi. |
| AI-üretilmiş fotoğraf katmanı + ifşa rozeti yuvası (Katman 2, opsiyonel) | Backdrop spec, Z1 | Yok | Katman 2 zaten "opsiyonel, sonra" — Katman 1 bile henüz yok. |
| Düzeltme metni kompozisyonunun 2-3 varyantı (Z4) | Ders ekranı, tek kalem varyant gerektiren yer | Yok — ders ekranına hiç dokunulmadı | Ders ekranı turu başlamadı. |
| **"Kamera kurulum sihirbazı" akışı** (2026-08-06 replik taramasından) | `cues.en.json` `setup.*` — 7 anahtar (`setup_step_back/center/angle/light/phone/space/done`), hiçbiri kodda çağrılmıyor | Yok — `shell_candidate/README.md`nin "henüz yok" listesinde zaten adı var | Replik hazır, akış/UI hiç yazılmadı. Ship kararı gerektirmez (kimse tetiklemiyor), yalnız kayıt. |
| **Tek-hareket "mikro-drill" kipi** (2026-08-06 replik taramasından) | `cues.en.json` `drill.*` — 10 anahtar (`guard_discipline/snap_back/stance_reset/...`) | Yok — bugünkü ders modeli yalnız tur/aralık planlı, tek-drill kipi kavramı yok | Muhtemelen gelecek özellik taslağı. Ship kararı gerektirmez. |
| **Oturumlar-arası eğilim özeti** (2026-08-06 replik taramasından) | `cues.en.json` `summary.trend_improving/worse/flat/no_trend_yet` — 4 anahtar | Yok — bugünkü `SessionSummaryView` yalnız TEK seansı özetliyor, geçmişe kıyas yok | Muhtemelen gelecek özellik taslağı. Ship kararı gerektirmez. |

## Kodda VAR, tasarımda YOK

| Kalem | Kodun hâli | Tasarımın hâli | Not |
|---|---|---|---|
| **Progress'in 3 bandı** (Guard discipline / Punch mechanics / Balance, K8 — hepsi "—") | Sayfa B'de bağlamsal dürüst blok (`_HonestBands`, `course_page.dart`) — Hüküm 2 | Design comp'ta (`JabLab.dc.html`) Sayfa B mockup'ında bu blok HİÇ çizilmedi | Bu kategorinin İLK örneği (koordinatör 2026-08-06). Eski Progress sekmesi kalktığında bant düşmedi, taşındı — ama tasarım bunu hiç görmediği için yerleşimi (Sayfa B'nin neresinde, hangi görsel ağırlıkta) tamamen koddan türetildi. Giydirme turunda gözden geçirilmeli. |
| `retry-history` butonu (Sayfa A'nın "geçmiş okunamadı" bandında) | `select_page.dart` — J-092 zincirinin UI karşılığı | Tasarım yalnız kamera-izni hâlleri için "tekrar dene" gösteriyor; Sayfa A'daki bir "geçmiş okunamadı" bandı için ayrı bir tasarım YOK | Küçük ama gerçek fark — buton görsel dili (glass tier, buton şekli) mevcut kamera-izni "tekrar dene" düğmesinden ELLE türetildi, tasarım onayı almadı. |
| `open-select` köşe ikonu (Sayfa B kök/giriş iken Sayfa A'ya dönüş) | `course_page.dart`, yalnız `isCurrent==true` iken görünür | Tasarım her zaman Sayfa B'nin bir ÖNCEKİ ekrandan push edildiğini varsayıyor (geri-oku hep var) — "Sayfa B kök" senaryosu (Hüküm 3) tasarım turundan SONRA kararlaştırıldı | Hüküm 3 giydirmeden sonra geldiği için tasarımın kendisi bu hâli hiç görmedi; ikon yerleşimi/ikonografisi koddan türetildi. |
| Debug kamera-köprüsü girişi (`open-camera-harness`) | Ayarlar köşesinde, yalnız `kDebugMode` | Tasarımda YOK (doğru — dev-only araç, kullanıcı yüzeyi değil) | Kasıtlı fark, düzeltilecek bir şey değil; eksiksizlik için kayıtlı. |
| **"Coached but not scored" — İKİ PARALEL temsil** (2026-08-06 replik taramasından) | `SessionSummaryView.coachedNotScored: List<String>` — `ContentRepository.coachedNotScoredLabels()`den, config'ten türetilmiş gerçek başlıklar | `cues.en.json`de AYNI kavram için `cue.coached_not_scored` anahtarı da var ama HİÇ çağrılmıyor | Hangisi kanonik belirsiz. Bugünkü kod-yolu (config-türetimli, test edilmiş — `session_rounds_test.dart`) muhtemelen DOĞRU olan; cue-book kaydı muhtemelen erken bir taslağın kalıntısı. Ders ekranı turunda karara bağlanmalı, ikisi de kalırsa çelişki riski var. |
