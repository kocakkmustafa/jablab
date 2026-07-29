# Fitness-track SHIP denetimi (J-062)

**Tarih:** 2026-07-29 · **Soru:** PROGRESS.md'nin *"Fitness şimdi çıkabilir"*
iddiası uçtan uca doğru mu? · **Yöntem:** içerik beyanı ↔ çalışan kod karşılaştırması
(kamera köprüsü kapsam DIŞI, gece paketi talimatı)

---

## HÜKÜM: iddia YARIM doğru — ve yarısı yanlış olduğu için ship'i TUTUYOR

İddianın dayanağı şuydu (PROGRESS.md, G6 turu):

> Fitness'ın kapıları süre/katılım ölçer, teknik hükmü vermez — "10 dakika
> çalıştın" demek için eğitmen uzlaşısı gerekmiyor.

**Bu cümlenin SKORLAMA yarısı DOĞRU** ve kanıtı bu oturumda güçlendi: Fitness
(`boxing.conditioning`) hiçbir referans artefaktına bağımlı değil, dolayısıyla
J-061'in jab referansı gibi kapılardan geçmesi gerekmiyor.

**Ama cümle sessiz bir varsayım taşıyor:** uygulamanın "10 dakika çalıştın"ı
gerçekten SÖYLEYEBİLDİĞİ. Söyleyemiyor. İddia, *"referans gerekmiyor"* ile
*"ship edilebilir"* i birbirine karıştırmış.

---

## Kanıt: 7 dersin 7'si de beyan ettiği yapıyı KOŞMUYOR

`lib/app/session_screen.dart` `_Live` bileşeni ders nesnesini HİÇ almıyor
(`_Live({required this.cues})` — `lesson` parametresi yok) ve iki sabit taşıyor:

| yer | sabit | sonuç |
|---|---|---|
| `session_screen.dart:136` | `static const Duration _round = Duration(minutes: 3)` | her ders 3 dakika |
| `session_screen.dart:138` | `SessionNarrator(mode: SessionMode.steady)` | hiçbir ders aralıklı koşamaz |

Beyan ↔ canlı tablosu:

| ders | beyan (`minutes` + ad/blurb) | CANLI davranış | durum |
|---|---|---|---|
| `conditioning.r3` | 12 dk · "3 x 3 minute rounds" | 1 × 3 dk | ❌ 3 turun 1'i |
| `conditioning.tempo` | 10 dk · tempo kontrolü | 1 × 3 dk | ❌ |
| `conditioning.r5` | 5 dk · "One short round" | 1 × 3 dk | ❌ süre yanlış |
| `conditioning.r10` | 10 dk · "Three rounds with rest" | 1 × 3 dk | ❌ dinlenme yok |
| `conditioning.r20` | 20 dk · "Six rounds" | 1 × 3 dk | ❌ 6 turun 1'i |
| `conditioning.hiit` | 12 dk · "Interval burst" | 1 × 3 dk **düz** | ❌ aralık yok |
| `conditioning.technique_round` | 9 dk | 1 × 3 dk | ❌ |

**Bu bir "eksik özellik" değil, `beyan ≠ canlı` sınıfı bir DÜRÜSTLÜK kusuru**
(M-F-56 / J-039 ailesi): kullanıcı "Twenty minutes" yazan bir dersi açıp 3
dakika sonra bitmiş buluyor. Uygulamanın kendi `$producers` bloğu bunu zaten
dürüstçe yazıyor ("ekran su an tek tur kosuyor") — çelişki KOD ile İÇERİK
arasında değil, **PROGRESS.md'nin ship iddiası** ile ikisi arasında.

## Çalışan kısım (uçtan uca doğrulandı)

`test/shell_test.dart` zinciri bugün yeşil ve gerçekten yürüyor:
kütüphane → canlı disiplin → kurs → ders → `öğret → dene → canlı → özet` → çıkış.
Tur saati akıyor, anlatı konuşuyor (`round_start`/`halfway`/`last_ten`/
`last_five`/`round_end` canlı), hüküm yuvası SUSUYOR ve sebebini yazıyor.
Yani **iskelet sağlam; eksik olan seans PLANI.**

---

## EKSİK ENVANTERİ (isimli — kamera köprüsü hariç)

### 🔴 F-1 · Seans planı yok → ders süresi/tur yapısı koşulmuyor
**Ship'i TUTAN tek zorunlu kalem.** `_Live` dersi görmüyor; tur sayısı,
tur süresi ve dinlenme kavramı hiçbir yerde yok.
`SessionNarrator` GEREKENİ ZATEN TAŞIYOR: `startRound()` (turlar arası
sıfırlama), `NarrationEvent.rest`, `NarrationEvent.sessionEnd`. Yani
anlatıcı tarafı hazır, **süren plan yok**.
Yeni ekran GEREKMEZ (kabuk dondurma kuralına dokunmaz) — `_Live`'ın dersi
alıp turları sırayla koşması yeterli.
Tur yapısı İCAT EDİLMEZ, içerikte ZATEN yazılı olanın makine-okur hâle
getirilmesidir ("3 x 3 minute rounds", "Three rounds with rest", "Six rounds").

### 🟡 F-2 · Aralık (HIIT) kipini süren yol yok
`SessionNarrator.interval()` uygulanmış ve testli; `hiit` dersi düz tur
koşuyor. **Bilinçli olarak AYRI KAPI** (J-051: "HIIT ekranı ayrı kapı",
kabuk envanteri dondurulmuş). F-1 çözülse bile `hiit` dersi dürüst olmaz —
o yüzden F-1 ile birlikte `hiit`'in ya kilitlenmesi ya da kapının açılması
gerekir. Karar koordinatörde.

### 🟡 F-3 · Seans geçmişi/kalıcılık yok
`lib/` genelinde `SharedPreferences`/`sqflite`/`Hive`/`path_provider`: **0 eşleşme**;
`pubspec.yaml`'da tek bağımlılık `jablab_engine`. Sonuç: bitmiş seans
KAYDEDİLMİYOR. "10 dakika çalıştın" tek oturum içinde söylenebilir ama
yarın hatırlanmaz; `summary` replik grubunun trend cümleleri
(`awaiting-wiring`) bu yüzden açılamıyor. Fitness'ın ÇEKİRDEK vaadi
("çalıştığını kaydet") için gerekli — ship için zorunlu olup olmadığı
ürün kararı.

### 🟢 F-4 · İlerleme sayfası kalıcı olarak "—"
`jablab_app.dart:107` `ProgressPage` üç bandı sabit `'—'` ile besliyor.
K8/M-F-04 gereği kalibrasyonsuz SAYI yasak — ama Fitness'ın SÜRE bantları
teknik hükmü değil; kalibrasyon kapısı onları kapatmıyor. F-3 gelince
süre/katılım bandı dürüstçe doldurulabilir. Bugün yanlış bir şey
göstermiyor, yalnız boş.

### 🟢 F-5 · Kurulum sihirbazı yok (`setup` grubu `awaiting-surface`)
`cue.setup_ok` sessiz. Kamera köprüsüne komşu ama aynı şey değil; kapsam
dışı bırakıldı (gece paketi talimatı).

---

## Ship kararı için özet

| kalem | Fitness ship'ini tutuyor mu? |
|---|---|
| F-1 seans planı | **EVET — tek zorunlu blokaj** |
| F-2 HIIT aralık | `hiit` dersi için evet; diğer 6 ders için hayır |
| F-3 kalıcılık | ürün kararı (vaadin çekirdeği ama tek-oturum akışı çalışır) |
| F-4 ilerleme bandı | hayır (boş, yanlış değil) |
| F-5 sihirbaz | hayır (kapsam dışı) |
| kamera köprüsü | Fitness için **HAYIR** — iddianın doğru yarısı budur |

**Fitness'ın skorlama hikâyesi ship'e hazır; ZAMAN TUTMA ve KAYIT TUTMA
hikâyesi değil.** F-1 kapanınca 6/7 ders beyan ettiği işi gerçekten koşar.
