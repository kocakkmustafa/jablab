# ADR-001 — Hız/tempo metriği yalnız faz süresinden türetilir

**Tarih:** 2026-07-26 · **Statü:** KABUL (ölçümle doğrulandı) · **Bağlam:** `00-AILE-MIMARISI D2`, `gates/D2-KAPI-RAPORU.md`

## Karar

Kullanıcıya gösterilen hiçbir hız/tempo değeri kare-arası landmark yer değiştirmesinden hesaplanmaz. Tek kaynak **state-machine faz zaman damgalarıdır** (`AttemptRun.phaseDurationUs`). Kare-arası hız yalnız iki iç amaçla hesaplanır: (a) fiziksel-olmayan sıçrama tespiti (`jump_rate` güven kapısı), (b) native ↔ Dart implementasyon eşleştirme testi.

Kullanıcıya sunum **bant** olarak yapılır (`controlled` / `brisk` / `fast`), milisaniye veya m/s olarak **değil**.

## Gerekçe (ölçüm)

6 gerçek boks klibi, 128 yumruk. Örnekleme 2× seyreltildiğinde (gerçek 60→30fps sorusuyla aynı oran), **aynı yumruk** iki seviyede eşleştirilerek:

| Klip | CV faz-süresi | CV piksel-hızı | oran |
|---|---|---|---|
| punches_air | 0,027 | 0,091 | 3,39× |
| gym_10988078 | 0,066 | 0,080 | 1,21× |
| woman_vert | 0,067 | 0,265 | 3,98× |
| slowmo_6296438 | 0,079 | 0,305 | 3,85× |
| slowmo_4761714 | 0,097 | 0,248 | 2,57× |
| bag | 0,113 | 0,150 | 1,33× |

Yön **6/6 klipte** faz-süresi lehine. Mekanizma da beklenen yönde: seyreltme piksel-hızı tepesini **sistematik olarak aşağı çeker** (tepe kaçırılır, yanlı hata), faz-süresi ise yalnız kuantizasyon gürültüsü alır (yansız).

Bant sunumu kararının ayrı gerekçesi: ölçülen uzanma süreleri 68–257 ms arasında dağılıyor (J-008) — kullanıcılar her yumruğu tam hızda atmıyor. Tek bir "speed" sayısı bu dağılımı yanlış temsil eder.

## Sonuçlar

- Faz sınırı çözünürlüğü kritik hâle gelir → ADR-002 (native katman) bunun doğrudan sonucudur.
- Pazarlamada **"kanıtlanmış hız ölçümü" DENMEZ**: literatür bu tasarımı dolaylı destekliyor, doğrudan doğrulamıyor (araştırma korpusu jablab-domain RISKS). `00-AILE-MIMARISI §7` ölçüm dürüstlüğü geçerli.
- `TEMPO_TOO_FAST_FOR_FORM` hata kodu bant eşiğine bağlanır, ms eşiğine değil.

## Reddedilen alternatifler

- **Kare-arası tepe hızı:** yukarıdaki tablo. Ayrıca tam olarak en çok önemsediğimiz anda (tepe hız) en çok bozulur.
- **Optical flow / piksel-uzayı hız:** aynı blur sorununa ek olarak on-device maliyet; landmark hattının üstüne ikinci bir görüntü işleme katmanı gerektirir.
- **Ham ms değeri gösterme:** CV yeterince dar değil (0,027–0,113) ve tempo dağılımı geniş; sahte hassasiyet olur.
