# ADR-002 — Faz tespiti native'de her kare; Dart olay başına

**Tarih:** 2026-07-26 · **Statü:** KABUL · **Bağlam:** `10-ARAC-KATALOGU §2` ("kanal diyeti"), `gates/D2-KAPI-RAPORU §3.1`, DEFTER J-012

## Karar

| Katman | Nerede | Sıklık | İçerik |
|---|---|---|---|
| **T1 — algı** | native (Kotlin/Swift) | **her kare** | kamera → MediaPipe Tasks → güven kapısı → temporal smoothing → vücut normalizasyonu → **faz state-machine'leri** |
| **T2 — hüküm** | Dart | **olay başına** (~1-3/sn) | kural motoru, hata sınıflandırma, skor bileşenleri, geri bildirim önceliklendirme + cooldown, TTS tetikleme, müfredat, kalıcılık |
| **T3 — sunum** | Dart/Flutter | ~10-15fps | overlay iskeleti (desimasyonlu), tur saati, UI |

Native, her denemede T2'ye tek bir **faz özeti (attempt digest)** gönderir:

```
AttemptDigest {
  techniqueId, outcome,                 // completed | timedOut | aborted | lostTracking
  transitions[ {phase, tUs} ],          // ADR-001'in hız kaynağı
  snapshots{ t0, tPeak, t1 },           // her biri: normalize landmark + görünürlük
  aggregates{ perJoint: {min,max,atPeak}, visMin: {region}, jumpCount },
  quality{ framesSeen, framesGated, modelVersion, ruleSetVersion }
}
```

## Gerekçe

Katalog §2 "30fps ham landmark Dart'a AKITILMAZ; Dart'a ~10-15fps'e desimasyonlu veri gider" diyor. Bu doğru bir **bant genişliği** kuralı ama JabLab'da **faz sınırını yok eder**: D2 ölçümünde uzanma fazı medyan **128 ms**, en hızlı %10'da **54 ms**. 15fps'te kare başına 66 ms → uzanma fazına **1–2 örnek** düşer. ADR-001'in tüm metriği bu faz sınırının hassasiyetine dayanıyor.

Bu yüzden "kanal diyeti" korunur ama **doğru yerde uygulanır**: seyreltilen şey ham landmark akışıdır (T3 overlay'i için), faz tespiti değil.

Faz özeti, kural motorunun ihtiyacı olan her şeyi taşır: kurallar (`REAR_HAND_LOW`, `ELBOW_FLARED`, …) yumruğun **belirli anlarındaki** duruşa bakar, 30 karenin tamamına değil. Yumruk başına yük ≈ 3 anlık görüntü + agregalar — kanal için ihmal edilebilir.

## Sonuçlar

- **Motor iki kez yazılır** (Kotlin + Swift) ama yalnız T1; T2'nin zenginliği tek Dart kodunda kalır. Bu, "5 app × 2 platform" maliyetini kabul edilebilir tutar.
- **Altın-fixture çapraz doğrulama zorunlu:** `motion_core` Dart implementasyonu *normatif referanstır*; native port'lar aynı fixture'ları replay edip aynı `AttemptDigest`'i üretmelidir. Uyuşmazlıkta Dart doğrudur. (Bu ilke `motion_core` paketinin kendi doküman yorumunda da bağımsız olarak yazılmış.)
- T1 dar ve seyrek değişir; kural içerikleri versiyonlu config olarak T2'de yaşar → yeni teknik/branş eklemek native derleme gerektirmez.
- Gecikme bütçesi: cue ≤500 ms (katalog §5). T1→T2→TTS zinciri olay başına tetiklendiği için bütçe rahat.

## Reddedilen alternatifler

- **Her şey Dart'ta (landmark'ları tam fps akıt):** platform kanalı üzerinden 30fps × 33 landmark sürekli akış; jank ve GC baskısı riski, Impeller uyarısıyla birleşince kamera-önizleme ekranında kabul edilemez.
- **Her şey native:** kural motorunu, skorları ve müfredatı Kotlin+Swift'te iki kez yazmak; 5 app boyunca sürdürülemez ve test edilebilirliği düşürür.
- **Ortak C++ çekirdek (FFI):** teknik olarak mümkün, ama solo stüdyoda üçüncü bir dil ve build hattı; T1'in darlığı bunu gereksiz kılıyor.
