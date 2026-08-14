# 🥊 JabLab — Kurucu Brifi · 2026-08-07 sabahı

**Sorunuz:** *"JabLab bugün App Store'a gönderilebilir mi? Gönderilemezse, engelleyen şeylerin tam listesi nedir?"*

**Cevap: HAYIR — 3 engel var, üçü de sizde. Kod tarafında engel kalmadı.**

Ölçüm tarihi: 2026-08-07 · `main 34c4320` · app 256/256 · motor 113/113 · analyze temiz.

---

## ⛔ GÖNDERMEYİ ENGELLEYEN (3)

| # | engel | sınıf | büyüklük | neden bende değil |
|---|---|---|---|---|
| 1 | **Uygulama ikonu Flutter varsayılanı** | `manuel-kurucu` | saatler (tasarım) | Marka varlığı — icat etmem sizin kararınız olmalı |
| 2 | **Kamera yolu gerçek cihazda hiç koşmadı** | `manuel-kurucu` | 1 cihaz-oturumu | Simülatörde kamera yok; fiziksel iPhone gerekiyor |
| 3 | **Store metadata durumu ölçülmedi** | `ölçülmemiş` | bilinmiyor | App Store Connect erişimim yok |

**2 numara hakkında dürüst olmam gereken şey:** uygulamanın çekirdek vaadi kamerayla çalışıyor ve o yol **hiç gerçek donanımda koşmadı.** Testler, fixture'lar ve yapı yeşil — ama *"bir insan telefonuna indirse çalışır mı"* sorusuna **kanıtım yok.** Bunu "muhtemelen çalışır" diye yazmıyorum.

---

## ⚠️ ZAYIFLATAN AMA ENGELLEMEYEN (2)

| engel | durum |
|---|---|
| **Splash marka varlığı** | Beyaz açılış ekranı **düzeltildi** — uygulamanın kendi zeminine çekildi (yeni renk icat edilmedi). Gerçek marka görseli sizde → ⛔ değil ⚠️ |
| **Sürüm numarası** | `1.0.0+1` öneriyorum. Gerekçe: sürüm numarası da bir beyandır; `0.1.0` *"bu bir ön sürüm"* der, oysa App Store'da yayımlanan şey ön sürüm değildir. Kapsam dürüstlüğü **metinlerde** yapılıyor (12 kapsam-dışı madde, 7 kapalı disiplin, hepsi isimli gerekçeli), numarada değil. |

---

## ✅ KAPANAN — SİZİN LİSTENİZDEKİ MADDELER, TEK TEK ÖLÇÜLDÜ

*"var/yok diye değil, kullanıcı akışında çalışıyor mu diye"* dediniz. Ölçüm yöntemi yanına yazılı.

| madde | durum | nasıl ölçüldü |
|---|---|---|
| **Gizlilik beyanı** | ✅ | `PrivacyInfo.xcprivacy` — **release paketinin içinde 167 bayt** (kaynakta değil, pakette) |
| **İkon/splash** | ⚠️ kısmi | splash düzeltildi ve pakette doğrulandı; ikon sizde |
| **Çökme yolları** | ✅ | Saatsiz-ders çökme yolu **kod mutasyonuyla** sınandı: koruma kaldırılınca **9 kapı kırmızı** |
| **Boş durumlar** | ✅ | Geçmiş okunamadığında/boşken dürüst metinler; hepsi kapılı |
| **Kamera izin akışı** | ✅ kod · ⛔ cihaz | İzin reddi/hata yolları render ediliyor ve kapılı — **ama gerçek donanımda koşmadı** |
| **Paywall/IAP** | ✅ yok | Ödeme duvarı **yok**, ürün açık. Ayarlarda `ACCESS / NO PAYWALL` diye dürüstçe yazıyor |
| **Onboarding** | ✅ | İlk ders `camera` — kurulumu öğreten gerçek bir ders |
| **Store metadata** | ⛔ | Ölçemedim (erişim yok) |
| **Release derlemesi** | ✅ | **46,0 MB**, başarılı; içerik pakette doğrulandı |

---

## 📚 İçerik kütüphanesi — bugünkü hâli

- **Boks CANLI:** 17 ders (**14 açık**, 3 kilitli ve **kilit gerekçeleri isimli**)
- **7 disiplin kapalı** ve kartları görünür kalıyor — *"yakında"* demiyor, **neden kapalı olduğunu** söylüyor
- **41 replik anahtarı**, ortanca 4 varyant, seçim round-robin → koç kendini üst üste tekrar **edemiyor**
- **14/14 hata kodu** gerçek bir koçluk cümlesine varıyor
- **Sarkan referans: 0** (teknik · kombinasyon · hata kodu · cue)

**Gece bulunan ve kapatılan gerçek içerik kusuru:** ikinci raunt *"Round one"* diyordu. Replik doğruydu; onu çalan yol tur numarasını bilmiyordu (round-robin havuz). Düzeltildi + dört yönlü kapı + mutasyonla doğrulandı.

---

## 🔴 Sizden beklenen karar (2)

1. **Ses/TTS** — sözleşme §1.1 sesli antrenörü çekirdek vaat sayıyor, ama **beş hatta da ölçüm sıfır ses çıkışı** gösterdi. Bu bir çekirdek-yetenek + harcama kararı, bende değil.
2. **Sürüm numarası** — `1.0.0+1` önerim yukarıda gerekçeli.

---

## ⛔ Dürüstlük notu

Bu brifteki her satır **ölçüldü**, hiçbiri tahmin değil. Ölçemediğim tek şey **store metadata** ve onu "muhtemelen tamamdır" diye yazmadım — **`ölçülmemiş`** diye yazdım.

Gece boyunca kendi ölçüm araçlarım **dört kez yanlış bulgu üretti** (biri sizin sabah planınıza gidecekti: pubspec'te varlıkların bildirilmediği iddiası — **yanlıştı**, paket üçünü de içeriyordu). Bu yüzden her "yok" bulgusunu, aracın o şeyi *bulabildiğini* kanıtladıktan sonra rapor ettim.
