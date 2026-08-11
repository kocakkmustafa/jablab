# Mağaza Liste İçeriği — TASLAK (koordinatör sevki, 2026-08-12)

> **Taslak BENİM, onay KURUCUNUN.** Gönderim zaten kurucu kalemi (M-F-77,
> ASC erişimi + ekran görüntüsü çekimi); bu doküman yalnız **liste
> içeriğini** yetkilendiriyor — açıklama, anahtar kelime, yaş
> derecelendirme gerekçesi. Kod tarafı: `docs/store/listing.json` +
> `test/store_listing_test.dart`.

## Neden bu ikiye ayrıldı (KURUCU-BRIFI-2026-08-12'nin bulgusu)

"Store metadata ölçülmemiş" tek cümlesi iki farklı şeyi gizliyordu:
**liste içeriği** (bu doküman — ASC erişimi gerektirmez, bugün yazılabilir)
ve **yükleme/gönderim** (ekran görüntüsü + ASC girişi + submit — erişim-kilitli,
bu session'da app-publish MCP'si yok). Bu ayrım netleşince yarısı hemen
başlanabilir çıktı.

## Sınırlar — mağaza metni ailenin en sıkı dürüstlük yüzeyi

Bu, kullanıcının satın almadan ÖNCE gördüğü tek yüzey — düzeltme şansı yok,
kullanıcı zaten karar vermiş oluyor. Bu yüzden üç kısıt DAHA sıkı uygulandı:

1. **Ölçülmemiş hiçbir iddia yok** — `power`/`force` kelimeleri yalnız
   *"ölçmüyoruz"* cümlesinde geçiyor, iddia olarak değil.
2. **Vaat dili YOK** (M-F-186) — `promise_language_test.dart`daki AYNI
   regex bu dosyaya da uygulandı (`test/store_listing_test.dart`).
3. **"Cihazda kanıtlı" denmiyor** — cihaz turu (§7.3-7.7) henüz yapılmadı.
   Her cümle **bugünkü kod-gerçeğine** dayanıyor: `MEASURED AND GRADED` /
   `WATCHED AND COACHED, NOT SCORED` / `WHAT WE DO NOT MEASURE` üçlüsü
   `library.json`'ın `honesty.measured`/`notMeasured` listelerinden **birebir**
   türedi — icat yok, uygulamanın kendi `HonestyBox`ının mağaza karşılığı.

## İçerik — `docs/store/listing.json`'dan

| alan | kaynak | not |
|---|---|---|
| **Subtitle** (ASC, ≤30 krk) | yeni yazıldı | "Solo boxing form coach" — ürünün tek cümlelik özeti |
| **Promotional Text** (ASC, ≤170 krk) | yeni yazıldı | Vaat dili taramasından geçti |
| **Keywords** (ASC, ≤100 krk) | yeni yazıldı | Yalnız gerçek özellik adları — "professional"/"pro" gibi abartı sözcük YOK |
| **Short description** (Play, ≤80 krk) | yeni yazıldı | |
| **Description** (her iki mağaza, ~4000 krk) | `library.json` `boxing.honesty` | Ölçülen/koçlanan/ölçülmeyen üçlüsü uygulamanın kendi beyanından **kopyalandı**, uydurulmadı |
| **Kamera izin gerekçesi** | `ios/Runner/Info.plist` `NSCameraUsageDescription` | **Değiştirilmedi**, yalnız kopyalandı — description'daki "never leaves your device" ile tutarlı |
| **Yaş derecelendirme gerekçesi** | yeni yazıldı, CLAUDE.md'nin "tıbbi dil yasak" kuralına bağlı | Beklenen tavan: ASC 4+ / Play Everyone — **tahmin**, nihai karar mağazanın kendi süreci |

## Kapı — `test/store_listing_test.dart`

`promise_language_test.dart`'ın AYNI `promise` regex'i bu dosyaya da
uygulanıyor + iki ek kontrol: (1) "cihazda kanıtlı/doğrulandı" türünde bir
cihaz-kanıtı iddiası yok (2) ölçüm-beyanı üçlüsü (`MEASURED`/`WATCHED`/
`WHAT WE DO NOT`) `description` içinde gerçekten var. **Mağaza metni de bir
yüzeydir ve bayatlar** — içerik değişirse (yeni ders, yeni ölçüm) bu dosya
da güncellenmeli, kapı bunu hatırlatır.

## ⚠️ Bu taslağın ÖLÇMEDİĞİ şey

* **Metnin ASC/Play karakter sınırlarını TAM karşıladığını** — kabaca
  hesaplandı, kesin sayaç mağazanın kendi arayüzünde.
* **Ekran görüntülerini** — ayrı kalem, cihaz/sim turuna bağlı.
* **Yaş derecelendirmesinin NİHAİ sonucunu** — yalnız gerekçe yazıldı,
  mağazanın kendi sorgu formu doldurulmadı (ASC erişimi yok).
