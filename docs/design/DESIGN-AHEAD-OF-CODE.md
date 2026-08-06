# DESIGN-AHEAD-OF-CODE

> Design turu kapanış artefaktı (Choreia'nın deseni, aile standardı — koordinatör
> 2026-08-06). İki yönlü envanter: tasarımda var kodda yok · kodda var tasarımda yok.
> Tasarım bağlamı sıcakken üretildi; sonra çok pahalı olurdu.
>
> Kapsam: bu tur yalnız **Ayarlar köşesini** giydirdi (bkz. `git log` — `677849c`,
> `1a5a565`). Ders ekranı + dürüst hâller AYRI bir turun işi; oradan çıkacak yeni
> kalemler bu dosyaya EKLENECEK, üzerine yazılmayacak.

## Tasarımda VAR, kodda YOK

| Kalem | Tasarımdaki hâli | Kodun bugünkü hâli | Neden şimdi yapılmadı |
|---|---|---|---|
| Ayarlar — profil kartı (isim, "Orthodox · lead hand left") | `isSettings` dalında ilk blok | Yok — hiç render edilmiyor | Karşılığı olan gerçek bir kullanıcı/hesap sistemi yok. Sahte isim/stance basmak bu app'in "ölçmediğimi söylerim" kimliğini ilk ekranda çiğnerdi. |
| Ayarlar — koçluk tercihleri listesi (ses seviyesi, düzeltme sıklığı, stance, haptik) | `isSettings` dalında "COACHING" bloğu, 4 satır | Yok | Karşılığı olan bir ayarlar-kalıcılık katmanı yok. Sabit değerler ("Loud", "One at a time") basmak çalışmayan düğmeler üretirdi — düğme olmamasından kötü (J-079 dersi). |
| Canlı kamera GÖRÜNTÜSÜ (tam-kadraj video) | Ders ekranı arkaplanı, tüm "dürüst hâller"in temeli | **İskelet overlay VAR/uygulanabilir; kamera GÖRÜNTÜSÜ yok.** `motion_camera` (Dart) görüntüye dokunmuyor — `Texture`-tabanlı preview (`registrar.textures`) `docs/70-KAMERA-KOPRUSU-SOZLESMESI.md`ye göre **bilinçli ERTELENDİ**, kalıcı değil. | Çekirdek yetenek kararı, koordinatörün kuyruğunda. Ders ekranı turunda `PLACEHOLDER(asset)` olarak işaretlenecek. |
| 8 "dürüst hâl" (tasarım) vs 5 (brief) — özellikle **"Too dark"**, **"Tracking looks wrong"**, **"Partial round" özeti** | `states` bölümü, 8 kart | Motorun `QualityIssue` enum'u yalnız 3 değer taşıyor: `outOfFrame` · `lowTrackingConfidence` · `torsoUnreliable` — "karanlık" diye bir sinyal YOK. `LiveJabRunning`de "%kaç okundu" alanı YOK. | Ölçüldü (2026-08-06, motor kaynağına kadar indi), koordinatöre raporlandı. "Too dark" muhtemelen tasarımın SEBEP icadı (Gravita'nın "düşük ışık" emsaliyle aynı sınıf) — hüküm koordinatörde, ders ekranı turunun İLK işi. |
| Seçim→Kurs kart-devralma geçişi + ders-öncesi sahne (Z5, "ana akış") | Motion tokens: `takeover` 420ms, `scene` 340ms+stagger | Yok — bugünkü navigasyon Flutter'ın varsayılan `MaterialPageRoute` geçişini kullanıyor, özel animasyon yok | Z5 bunu "çalışan geçiş" gereken TEK yer sayıyor; Ayarlar turunda kapsam dışı bırakıldı, ders ekranı/Sayfa A-B turunda ele alınacak. |
| Disipline özgü kodlanmış arka plan geometrisi (8 gradyan, Katman 1) | Backdrop spec, Z1 | Sayfa A bugün düz koyu zemin (`Scaffold` varsayılanı), disiplin başına ayrışan gradyan YOK | Yalnız Ayarlar giydirildi bu turda; Sayfa A/B'nin görsel katmanı henüz tokenlara geçmedi. |
| AI-üretilmiş fotoğraf katmanı + ifşa rozeti yuvası (Katman 2, opsiyonel) | Backdrop spec, Z1 | Yok | Katman 2 zaten "opsiyonel, sonra" — Katman 1 bile henüz yok. |
| Düzeltme metni kompozisyonunun 2-3 varyantı (Z4) | Ders ekranı, tek kalem varyant gerektiren yer | Yok — ders ekranına hiç dokunulmadı | Ders ekranı turu başlamadı. |

## Kodda VAR, tasarımda YOK

| Kalem | Kodun hâli | Tasarımın hâli | Not |
|---|---|---|---|
| **Progress'in 3 bandı** (Guard discipline / Punch mechanics / Balance, K8 — hepsi "—") | Sayfa B'de bağlamsal dürüst blok (`_HonestBands`, `course_page.dart`) — Hüküm 2 | Design comp'ta (`JabLab.dc.html`) Sayfa B mockup'ında bu blok HİÇ çizilmedi | Bu kategorinin İLK örneği (koordinatör 2026-08-06). Eski Progress sekmesi kalktığında bant düşmedi, taşındı — ama tasarım bunu hiç görmediği için yerleşimi (Sayfa B'nin neresinde, hangi görsel ağırlıkta) tamamen koddan türetildi. Giydirme turunda gözden geçirilmeli. |
| `retry-history` butonu (Sayfa A'nın "geçmiş okunamadı" bandında) | `select_page.dart` — J-092 zincirinin UI karşılığı | Tasarım yalnız kamera-izni hâlleri için "tekrar dene" gösteriyor; Sayfa A'daki bir "geçmiş okunamadı" bandı için ayrı bir tasarım YOK | Küçük ama gerçek fark — buton görsel dili (glass tier, buton şekli) mevcut kamera-izni "tekrar dene" düğmesinden ELLE türetildi, tasarım onayı almadı. |
| `open-select` köşe ikonu (Sayfa B kök/giriş iken Sayfa A'ya dönüş) | `course_page.dart`, yalnız `isCurrent==true` iken görünür | Tasarım her zaman Sayfa B'nin bir ÖNCEKİ ekrandan push edildiğini varsayıyor (geri-oku hep var) — "Sayfa B kök" senaryosu (Hüküm 3) tasarım turundan SONRA kararlaştırıldı | Hüküm 3 giydirmeden sonra geldiği için tasarımın kendisi bu hâli hiç görmedi; ikon yerleşimi/ikonografisi koddan türetildi. |
| Debug kamera-köprüsü girişi (`open-camera-harness`) | Ayarlar köşesinde, yalnız `kDebugMode` | Tasarımda YOK (doğru — dev-only araç, kullanıcı yüzeyi değil) | Kasıtlı fark, düzeltilecek bir şey değil; eksiksizlik için kayıtlı. |
