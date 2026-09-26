# 🧭 GEZİLEBİLİRLİK SAYMA KURALI — JabLab (J-221, 2026-08-12)

> **Sayı (2026-09-26):** katı **8** · gevşek **13** — kapı: `test/reachable_screens_test.dart`.
> **Bu belge sayıyı DEĞİŞTİRMEZ**, sayının hangi kuralla çıktığını yazar.
> Gravita'nın uyarısı: *"sekmeleri farklı sayıyorsak iki sayı AYNI ŞEYİ
> ÖLÇMÜYOR; fark içerik değil SAYMA KURALI olur."*

## Dört soru, dört cevap

### ① Sekme — KATI'da kaç, GEVŞEK'te kaç?

**Sıfır ve sıfır. JabLab'da SEKME YOK.**

4-sekmeli `NavigationBar` kabuğu **2026-08-06'da kaldırıldı** (Hüküm 1);
yapı bugün `SelectPage`(A) · `CoursePage`(B) · `SessionScreen`(C) +
`SettingsPage`(köşe düğmesi). Yani sekme sorusu bu hatta **ayırt edici
değil** — ama cevapsız bırakılamaz: 6'yı Gravita'nın 7'siyle kıyaslayan
biri, sekmelerin 6'nın **içine katlanmış** olabileceğini varsayabilir.
***Bir kuralın "bende yok" cevabı da kuralın parçasıdır.***

### ② Aday envanteri nasıl türetiliyor — desen mi, elle mi?

**ELLE — ve daha darı: YÜRÜYEREK.** Kapı bir desenden aday üretmiyor;
açılıştan başlayıp **ekranda görünen kontrollere basarak** gezip ulaştığı
ekranları işaretliyor, sonra **isimli beklenen kümeyle** karşılaştırıyor:

```
{onboarding, select, soloCourse, soloLesson, settings, whyNot, course, session}
```

Gravita **desenden türetiyor**, Lissom **elle tutuyor** (deseni bir ekranı
kaçırdığı için). JabLab **üçüncü bir noktada**: envanter elle yazılı ama
üyeliğin kanıtı **yürüyüş** — bir ad listede olsa bile ona **basarak
gidilemiyorsa** test düşer.

### ③ Ölçüm nereden başlıyor — kabuk mu, uygulama kökü mü?

**Uygulama kökü.** Kapı `pumpWidget(JabLabApp(...))` ile başlıyor, kabukla
değil. Bunun sonucu: **karşılama ölçümün İÇİNDE** (aşağı bak) ve
"uygulamayı ilk açan kullanıcı" hâli gerçekten ölçülüyor.

### ④ Onboarding içeride mi?

**EVET.**
* **Katı okumada 1** — `rota 1/6`, `seenOverride:false` ile ilk açılış.
* **Gevşek okumada 3** — üç perdesi ayrı sayılıyor (yürüyerek ölçülüyor).

`kLooseScreens = kStrictRoutes − 2 + kOnboardingPanels + kSessionStages`
= `8 − 2 + 3 + 4` = **13**. Çıkarılan 2, katıda birer sayılan **karşılama**
ve **seans**; yerlerine kendi perdeleri/aşamaları geçiyor.

---

## 🔍 Sayı DOĞRU SEBEPLE mi çıkıyor — gizli dayanak ÖLÇÜLDÜ

Lissom kendi sayısının dayanağını Flutter kaynağında doğruladı
(`skipOffstage: true`). JabLab'da karşılığı **aynı bayrak** ve ölçüldü:

| durum | `find.byType(SelectPage)` |
|---|---|
| Sayfa A ekranda | **1** |
| üstüne Ayarlar itilmiş, `skipOffstage: true` (varsayılan) | **0** |
| üstüne Ayarlar itilmiş, `skipOffstage: false` | **1** |

→ Yürüyüş **yalnız o an GÖRÜNEN** ekranı işaretliyor. Bu tesadüf değil,
sayının şartı: `mark()` çağrıları biriken bir `Set`e yazıyor ve
`skipOffstage: false` olsaydı **altta kalan** sayfalar da işaretlenip sayı
**şişerdi.** ***Bir sayının doğru olması yetmez; onu doğru yapan bayrağın
ne olduğu yazılı olmalı, yoksa bir sonraki tur onu farkında olmadan
değiştirir.***

## ⚠️ ENVANTER YÖNTEMİNİN KÖR NOKTASI — adıyla

> ***Yürüyüş yalnız UĞRADIĞI yeri bulur.*** Ulaşılabilir ama kimsenin
> basarak gitmediği bir ekran, bu kapıya **görünmez.**

Desen-türetimli envanterin (Gravita) kör noktası bunun **tersi**: kodda
duran ama ulaşılamayan bir ekranı sayabilir. İki yöntem **farklı yönde**
yanılıyor; hangisinin kullanıldığı yazılmazsa iki sayı kıyaslanamaz.

**Bu kör nokta bir kez ölçüldü ve bugün boş çıktı** (J-206): `Scaffold(`
taşıyan tüm sınıflar tarandı (pozitif kontrol: bilinen 6 ekranın hepsi
bulundu; negatif kontrol 0) → adsız-ulaşılamaz ekran **yok**; iki tanesi
kapıda adıyla dışlanmış (`CameraHarnessScreen` debug-kapılı ·
`ContentFailureScreen` hata yolu), `lib/shell_candidate/` dondurulmuş
envanter ve kendi kapısı var.

🔴 **AMA O TARAMA KAPILI DEĞİL** — tek seferlik bir ölçümdü. Yani kör
nokta bugün **kapalı ama korumasız**: yeni bir ekran eklenip yürüyüşe
katılmazsa, sayı sessizce eksik kalır ve **hiçbir test ötmez.**
*Kusur iddiada değil, korumasızlığında* (M-F-436) — kayda geçti, bu turda
kapatılmadı (ölçüyü değiştirme sınırı).

## 2026-09-26 güncel yöntem

Yukarıdaki tek seferlik tarama ve altı ekran anlatımı tarihsel temeldir.
Güncel kapı `Scaffold(` adaylarını çalışan kaynak metninden türetir,
tanıklı tek kök yürüyüşündeki varışlarla karşılaştırır ve altı varılamayan
adayın gerekçelerini ayrı sınar. Yeni solo kurs ve solo ders ekranları
ilk açılış kataloğundaki görünür karttan yürünür; ikisi de `push` varışıdır.
Katı sekiz ekran iki kök varış ve altı gerçek `push` ekranından oluşur.
Bu widget ölçümü gerçek cihaz, kamera veya mağaza kabulü değildir.
