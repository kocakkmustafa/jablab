# 🚢 YAYIN ENGELİ DENETİM YÖNTEMİ (J-216, 2026-08-12)

> **Bu belge bir LİSTE değil, bir YÖNTEMDİR.** Liste bayatlar; yöntem, bayat
> bir listeyi yakalayan şeydir. Her kalem "bugün ne durumda" diye değil,
> ***"bu soruyu nasıl ölçerim ve sıfır cevabına ne zaman güvenebilirim"***
> diye yazılmıştır.

## Neden yazıldı — iki hattın kör noktaları ÖRTÜŞMEDİ

JabLab ve Lissom aynı denetimi bağımsız yaptı. **İkisi de eksikti, ve
eksikler farklıydı:**

| bulan | ötekinin KAÇIRDIĞI |
|---|---|
| Lissom | Android imza yapılandırması · `AFTER_APPROVAL` (otomatik yayın) |
| JabLab | `PrivacyInfo.xcprivacy` · `targetSdk` (Play eşiği) |

→ ***Yöntem yazılmazsa her hat kendi kör noktasıyla denetler ve dördü de
"engel yok" der.***

## ⚠️ TEMEL KURAL — şablondan gelen her satır AYRI bir denetim kalemidir

> ***Beş hatta da aynı olan bir kusur, hat düzeyinde ÖLÇÜLEMEZ: aynılık onu
> arka plana çevirir.***

Ve daha kötüsü ölçüldü (J-215): **arka plan, kendine bir açıklama uydurtur** —
JDK/Gradle uyuşmazlığını "benim ortamım bozuk" ya da (benim yaptığım gibi)
büsbütün yanlış bir bileşene atfetmek. Bu yüzden **şablon kaynaklı kalemler**
(⑤ imza · ⑥ `PrivacyInfo` · ⑦ ikon · ⑧ izin metni · ④ `targetSdk`) listede
**ayrı satır** olmak zorundadır; "bunlar zaten şablondan gelir, kurcalamadım"
bir denetim cevabı DEĞİLDİR.

## ⚠️ HER "SIFIR" İÇİN POZİTİF KONTROL — ve kontrolün üç katmanı

1. **ARAÇ**: arama aracı çalışıyor mu? (*bir şey* bulabiliyor mu)
2. **DİZGE**: aradığın DİZGE doğru mu? (*bu kavramı çözdüğünü BİLDİĞİM bir
   yerde* isabet ediyor mu — M-F-505)
3. **KAPSAM**: doğru AĞACA mı bakıyorsun? (hat mı, aile mi, çekirdek mi)

⭐ **En güçlü biçim — SABOTAJ KONTROLÜ:** iddia edilen yokluğun **tam
örneğini** kaynağa enjekte et, aramanın onu **bulduğunu** gör, geri al
(enjekte→1, geri al→0, uydurma dizge→0). `rootBundle` bulmak, `HttpClient`
bulacağını **kanıtlamaz.**

🪤 Bu belgeyi yazan turda araç **iki kez** uydurma sıfır üretti:
`git grep` **izlenen** içeriği tarar (çalışma ağacındaki probu görmez) ·
tırnaksız `$VAR` genişlemesi dosya listesini **tek desen** yapar. İkisi de
temiz görünen bir "bulunamadı" raporu verecekti.

## SINIFLANDIRMA — üç sınıf, ve sınırları

| sınıf | tanım | örnek |
|---|---|---|
| **hat-yereli** | hat kendi ağacında kapatabilir | imza *yapılandırması*, kapılar, metin düzeltmeleri |
| **çekirdek** | çekirdek turu gerektirir, beş hattı bağlar | `SessionRecord` alanı, `worldLandmarks` |
| **kurucu** | erişim · sır · tasarım · harcama · beyan | keystore, ikon, ASC girişi, sürüm numarası |

⚖️ **İKİ AYIRIM ŞART, yoksa liste yanlış uzunlukta görünür:**

* **Bir kalem İKİYE bölünebilir.** *"Android imza"* tek kalem değil:
  **keystore** kurucunun (sır), **yapılandırma + sessiz-düşmeyi engelleyen
  kapı** hat-yerelidir. Biri ötekinin altına saklanırsa hat-yereli iş
  "erişim bekliyor" diye bekletilir.
* **Yetenek gediği ≠ yayın engeli.** Ürün dürüstçe *"bunu ölçemiyorum"*
  diyerek sevk edilebiliyorsa o kalem **engel değildir.** ***Bir listeyi
  olduğundan uzun göstermek, kısa göstermek kadar yanıltıcıdır.***

---

## DENETİM KALEMLERİ

Her satır: **soru · nasıl ölçülür · pozitif kontrol · sınıf.**
`$auditItems` tablosu `test/ship_audit_method_test.dart` tarafından
denetleniyor: **pozitif kontrol sütunu boş bir kalem eklenemez.**

| # | katman | soru | nasıl ölçülür | pozitif kontrol | sınıf |
|---|---|---|---|---|---|
| 1 | ağ | ürün gerçekten hiçbir şey göndermiyor mu? | üretim Dart'ında ağ çağrısı/importu | **sabotaj**: `HttpClient()` enjekte→bulunmalı, geri al→0 | hat-yereli |
| 2 | kalıcılık | diske ne yazılıyor — iddia edilenle aynı mı? | tüm `writeAs*`/store çağrıları sayılır, iddia metniyle karşılaştırılır | aynı tarama bilinen yazımları (`onboarding_seen`, `sessions.jsonl`) bulmalı | hat-yereli |
| 3 | izin metni | kullanıcının gördüğü İLK cümle doğru mu? | `Info.plist` + Android manifest metinleri, madde madde koda karşı | metnin her iddiası için ayrı ölçüm; "keeps/stores" fiilleri ayrı sorgulanır | hat-yereli |
| 4 | platform eşiği | `targetSdk`/`minSdk` mağaza eşiğini karşılıyor mu? | `flutter.targetSdkVersion` → SDK'daki gerçek değer çözülür | SDK ağacı okunabildi mi (dosya sayısı > 0) | hat-yereli |
| 5 | imza | release SESSİZCE debug anahtarıyla imzalanıyor mu? | `build.gradle.kts` release bloğu + `key.properties`/keystore varlığı | imzası **bilinen** bir projede (ör. LifeOS) desen isabet etmeli | **ikiye böl**: yapılandırma+kapı = hat-yereli · keystore = kurucu |
| 6 | gizlilik manifesti | `PrivacyInfo.xcprivacy` var mı, beyanı ölçümle uyuşuyor mu? | dosya + üç anahtar; `AccessedAPITypes` **pinli çekirdeğe karşı** ölçülür | pinli çekirdek okunabildi mi (`JsonlSessionStore` bulunuyor mu) | hat-yereli |
| 7 | ikon | uygulama ikonu hâlâ şablon varsayılanı mı? | ikon yollarına dokunan commit + dosya kimliği | ikon yolları bulunuyor mu (dosya sayısı > 0) | kurucu |
| 8 | mağaza iddiaları | liste metnindeki HER cümle ölçüme dayanıyor mu? | her canlı alan ayrı iddiaya bölünür, tek tek koda karşı | canlı alan sayısı sayılır; "tamamı denetlendi" iddiası kapsam kanıtı ister | hat-yereli (içerik) · kurucu (onay) |
| 9 | otomatik yayın | ASC `AFTER_APPROVAL` mı — onay anında kendiliğinden yayımlanır mı? | ASC sürüm ayarı (erişim gerektirir) | *(JabLab'da ASC kaydı YOK — kalem **uygulanamaz**, ama listede kalır)* | kurucu |
| 10 | cihaz kanıtı | kamera/ölçüm yolu gerçek cihazda koştu mu? | `kanit/`-türü artefakt aranır; **yokluğu iddia edilmez** | artefakt dizini okunabiliyor mu | kurucu |
| 11 | sürüm | sürüm numarası bir BEYANDIR — `0.x` "ön sürüm" der | `pubspec.yaml` | — (tek satır, ölçüm değil karar) | kurucu |

### ⛔ Kalem 9 hakkında — JabLab'ın kendi durumu

`AFTER_APPROVAL` **Lissom'un bulduğu kalem** ve JabLab'da bugün
**uygulanamaz**: ASC kaydı yok, sürüm yok, ayar yok. **Ama listeden
düşmüyor** — çünkü ③b (gönderim) açıldığı gün bu ayar **varsayılan olarak**
karşımıza çıkacak ve *"onay olur olmaz otomatik yayın"* sessiz bir karardır.
***Bugün uygulanamaz olması, denetlenmeyecek olması demek değildir.***

---

## YÖNTEMİN KENDİ SINIRI

Bu belge **bir hattın** denetimini tarif eder. Kalem 5'in nasıl bulunduğu
kanıtıdır ki bu yetmez: **şablon kaynaklı kusurlar ancak AİLE taramasıyla
görünür.** Yöntemin son adımı bu yüzden hat-dışıdır ve koordinatöre aittir:

> **Adım N:** hattın listesi çıktıktan sonra, **şablondan gelen kalemler**
> (⑤⑥⑦⑧④) aile düzeyinde çapraz-taranır. Bir hattın *"bende yok"*u,
> beşinde de aynıysa **bulgu değil arka plandır.**
