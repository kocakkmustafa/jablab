# ADR-004 — Standing Striking Engine: branş-bağımsız motor, boks bir içerik paketi

**Tarih:** 2026-07-26 · **Statü:** KABUL · **Bağlam:** `jablab-roadmap §1` (tavansız vizyon), `jablab-plan §23`, başlangıç promptu "ileriye dönük mimari"

## Karar

Motorun adı ve sınırı **Standing Striking Engine**'dir. Boks, motorun *içine gömülü* değil, motorun tükettiği bir **içerik paketidir**. Kod hiçbir yerde `jab`, `cross`, `orthodox` gibi boks terimlerini sabitlemez; bunlar versiyonlu config'ten gelir.

Katman sınırı:

| Katman | Nerede | Değişme sıklığı | Örnek |
|---|---|---|---|
| `motion_core` | ayrı repo, pinli sürüm | çok seyrek | faz state-machine altyapısı, güven kapısı, normalizasyon, fixture/replay |
| **Standing Striking Engine** | `jablab/app` | seyrek | ayakta-vuruş alanının *ortak* mekaniği: gard durumu, duruş/oryantasyon tespiti, sağ↔sol gard transformu, uzuv-uzatma faz şablonu, kombinasyon sıra motoru, hata üretici |
| **Branş paketi** (config) | `assets/rulesets/boxing@1.x.json` | sık | teknik tanımları, faz eşikleri, hata kodları+şiddet, drill eşlemesi, müfredat |

Kickboks/Muay Thai/karate ileride **yeni bir config paketi** olarak gelir; motor kodu değişmez. Tekme/diz gibi alt-uzuv teknikleri motora *yeni bir uzuv-uzatma şablonu* ekler — mevcut şablonu bozmaz.

## Gerekçe

`00-AILE-MIMARISI §1.1` vizyonu tavansız ilan ediyor: "V1 = sıra, tavan değil". Kurucunun gece direktifi bunu mimari şarta çeviriyor: "motor adı üstünde branş-bağımsız — boks'a hardcode etme".

Somut bedel farkı: boks state-machine'lerini doğrudan kod olarak yazmak V1'de ~2 gün kazandırır, ama ikinci branşta motoru yeniden yazmayı gerektirir ve o noktada 5 app'in ortak çekirdeği de kirlenir. Config-tabanlı yaklaşım V1'de yalnız bir şema tasarımı maliyeti getirir.

## Sağ/sol gard: tek merkezî transform

`jablab-plan §21` şartı. Motor her şeyi **lead/rear** terimleriyle çalışır, `left/right` ile değil. Duruş tespiti (orthodox/southpaw) tek bir yerde `lead↔left|right` eşlemesini kurar; motorun geri kalanı taraf körü kalır. Bu, hata kodlarının (`REAR_HAND_LOW`) her iki gard için tek tanımla çalışmasını sağlar ve southpaw'ı "sonradan eklenen özel durum" olmaktan çıkarır.

## Kural config şeması (v1 taslağı)

```jsonc
{
  "schemaVersion": 1,
  "rulesetId": "boxing",  "version": "1.0.0",
  "techniques": [{
    "id": "jab", "displayKey": "technique.jab", "limb": "lead_arm",
    "phases": [
      {"id":"GUARD_READY","enter":{"extensionRatio":{"lt":0.62}},"requiredLandmarks":["lead_wrist","lead_elbow","lead_shoulder"]},
      {"id":"EXTENSION","enter":{"extensionRatio":{"gt":0.68}},"timeoutMs":400},
      {"id":"PEAK","enter":{"extensionRatio":{"gt":0.85,"localMax":true}},"timeoutMs":150},
      {"id":"RETRACTION","enter":{"extensionRatio":{"lt":0.80}},"timeoutMs":600},
      {"id":"GUARD_RECOVERED","enter":{"extensionRatio":{"lt":0.62}},"terminal":true}
    ],
    "abort": {"trackingLostMs": 500}
  }],
  "errors": [{
    "code":"REAR_HAND_LOW", "severity":"high", "band":"B",
    "evaluateAt":["PEAK"],
    "condition":{"rearWristHeightBelowChin":{"gt":0.08}},
    "minConfidence":0.6, "cooldownMs":8000,
    "feedbackKey":"cue.rear_hand_low", "drillId":"drill.guard_discipline"
  }]
}
```

Eşik sayıları bu dosyada **yer tutucudur** — nihai değerler D2-D çekimlerinden kalibre edilecek (DEFTER J-007). Şemanın kendisi kalibrasyondan bağımsızdır.

## Sonuçlar

- Hata kodları UI metnine gömülmez (`plan §21`): kod → `feedbackKey` → i18n. V1 yalnız `en` ama katman baştan var.
- `ruleSetVersion` her seansa yazılır (`plan §16`); eşik değişince eski seansların skorları yeniden yorumlanmaz.
- Yeni teknik **replay-fixture olmadan eklenmez** — config'e teknik eklemek testi atlamanın yolu değildir; CI, her `techniques[]` girdisi için ≥1 doğru + ≥2 hatalı fixture arar.
