# ADR-003 — Kamera yerleşimi ön-eğik (~30–45°), sihirbaz kapı olarak zorunlu

**Tarih:** 2026-07-26 · **Statü:** KABUL (kesin kanıt D2-D çekimini bekliyor) · **Bağlam:** `gates/D2-KAPI-RAPORU §3.3`, DEFTER J-006

## Karar

Kamera kurulum sihirbazı kullanıcıyı **ön-eğik yerleşime** yönlendirir: omuz çizgisi kameraya ~30–45° çapraz, tam vücut karede, telefon dikey, kalça hizasında, ~2–2,5 m mesafede. Sihirbaz bir **kapıdır**, öneri değil: kabul kriteri sağlanmadan canlı tur başlamaz.

Kabul kriterleri (kalibrasyon duruşunda ölçülür):
1. Tam vücut kadrajda — ayak bileği ve baş landmark'ları kenardan ≥%5 içeride.
2. **Her iki el** ayrı ayrı görünür: gard duruşunda iki bilek de `visibility ≥ 0,6`.
3. Omuz çizgisi görüntü düzlemine göre ~25–55° arasında (saf ön ve saf yan reddedilir).
4. Gövde landmark'ları (omuz+kalça) `visibility ≥ 0,8`.

## Gerekçe

D2 ölçümünün en tekrarlanan bulgusu: **sonuçları bozan şey kare hızı değil, uzvun kadraj dışında veya kapanmış olması.**

Yan açıdan çekilen kliplerde kameradan uzak kol, kullanıcı **gard hâlinde dururken bile** düşük görünürlükte (taban 0,03–0,62). Bu, blur değil geometridir: gövde kolu kapatıyor. Tek ön-eğik klipte (`punches_air`) arka elin `<0,5` oranı **0,07** — yan-açı kliplerinde 0,22–0,60.

Saf ön açı da reddedilir, ayrı bir nedenle: düz yumruk kameraya doğru gittiğinde 2B uzanma ölçüsü kısalarak neredeyse değişmez (foreshortening) — faz tespiti 2B'de çalışamaz, MediaPipe'ın `z` değeri ise tek başına güvenilecek kadar kararlı değil. Ön-eğik açı hem kapanmayı hem foreshortening'i aynı anda çözer.

## Sonuçlar

- Sihirbaz, ürünün **en yüksek getirili tek bileşeni**dir; G5'te ilk yazılacak akış odur (motor ekranından önce).
- `OUT_OF_FRAME` ve `LOW_TRACKING_CONFIDENCE` hata kodları sihirbaza geri besleme yapar; tur sırasında kadraj bozulursa tur duraklatılır, hüküm verilmez (`plan §12` düşük-güvende-hüküm-yok ilkesi).
- Kullanıcı ev ortamında bu açıyı kuramıyorsa (dar oda) ürün **dürüstçe kısıtlanır**: `12_kucuk_oda` çekimi bu senaryonun ölçüsünü verecek; gerekirse "üst gövde modu" (ayak hataları kapalı) ayrı bir mod olur — gizlenmiş bozuk özellik değil.
- Sihirbaz başarı oranı `plan §19`'un birinci başarı ölçütü; analytics'te ilk izlenecek metrik.

## Açık kalan

Kesin kanıt için `D2-CEKIM-PROTOKOLU` #13 (saf yan kontrol çekimi) gerekli: aynı kişi, aynı ışık, yalnız açı değişken. Sonuç ön-eğik lehine çıkmazsa bu ADR yeniden değerlendirilir.
