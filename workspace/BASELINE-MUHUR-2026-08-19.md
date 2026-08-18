# 🔖 JABLAB — BASELINE MÜHRÜ + ROADMAP DOSYA-YOLU DENETİMİ, 2026-08-19

> Oturum: JABLAB (PREP lane). Protokol §13 madde 1 ve 5 gereği: roadmap dosya
> yolları doğrulanmamış varsayımdır, baseline satırları tarihseldir — bu
> oturum kendi baseline'ını salt-okuma yeniden ölçtü. Hiçbir kod yazılmadı.

## 1. Git baseline (ölçüldü)

| alan | değer |
|---|---|
| HEAD | `1a8615dd0dba9d5eb173062745bebbc320232b33` |
| branch | `main` |
| çalışma ağacı | **temiz** (test/analyze koşumları sonrası da temiz kaldı) |
| origin farkı | **0/0** (tam senkron) |
| son commit | `1a8615d` — 2026-08-17 19:15:29 +0300 — "docs: J-290 — H-85 işlendi, cihaz fiziksel bağlı değil (ölçüldü)" |

**Roadmap karşılaştırması:** 21-JABLAB-MASTER-ROADMAP.md §1 "App HEAD `1a8615d`;
baseline çalışma ağacı temiz" diyor — **DOĞRULANDI, sapma yok.**

## 2. Ortak SHA pin (ölçüldü)

`pubspec.yaml`'da hem `motion_core` hem `motion_camera` için:
```
ref: f13bdc93b2eae2f741bfcdb4c9270a88e5d75e5d
```
02-MOTION-AILESI-ORKESTRASYON.md §2 ve §7'deki beklenen pin ile **birebir eşleşiyor — sapma yok.**

## 3. Kapı durumu (bağımsız yeniden koşuldu, borusuz)

| komut | sonuç |
|---|---|
| `flutter analyze` (app) | **0 issue** (1.3s) |
| `flutter test` (app) | **368/368 PASS** |
| `(cd packages/jablab_engine && flutter test)` | **129/129 PASS** |

DEFTER.md'nin en son sayısal beyanıyla (J-288: "app 368/368 · motor 129/129")
**birebir örtüşüyor** — J-288'den (H-82 görevi, cihaz-canlılık probu yazımı)
bu yana regresyon **yok**. J-289/J-290 yalnız dokümantasyon/keşif kaydı
(kod dokunulmadı), bu da tutarlı.

## 4. Roadmap dosya-yolu varlık denetimi

### §6 "Mevcut" (var olması beklenen) — 11/11 VAR
`lib/app`, `lib/shell_candidate`, `packages/jablab_engine`,
`assets/content/{library,curriculum,cues.en}.json`,
`assets/rulesets/{boxing.v3,boxing@1.0.0}.json`,
`integration_test/{camera_smoke,device_liveness_probe}_test.dart`,
`docs/store/listing.json` — hepsi doğrulandı.

### §11 Görev paketleri — "Modify later" (var olması beklenen): 28/31 VAR

**3 SAPMA — dosya yok, roadmap "Modify later" diyor ama gerçekte hiç yazılmamış (fiilen "Create later" durumunda):**

| Dosya | Roadmap görevi | Gözlem |
|---|---|---|
| `test/combo_builder_test.dart` | JAB-P1-003 | Aynı görevin `test/session_rounds_test.dart` ve `test/progress_recorded_test.dart`'ı ZATEN VAR ve yeşil (368 içinde) — görev KISMEN başlamış, combo builder'ın kendisi henüz değil. |
| `test/storage_migration_test.dart` | JAB-P1-004 | Görevin TÜM "Create later" hedefleri de yok (`jablab_database.dart`, `session_projector.dart`, `data_exporter.dart`) — Storage işi hiç başlamamış, iç-tutarlı. |
| `test/data_delete_test.dart` | JAB-P1-004 | Aynı gerekçe. |

Bu üç eksik dışında hiçbir "Modify later" dosyası eksik değil — roadmap'in
JAB-P0-001…004 ve JAB-P1-001/002 kapsamındaki dosya varsayımları **doğru**.

### §11 Görev paketleri — "Create later" (henüz VAR OLMAMASI beklenen): 17/17 YOK — sapma yok
`docs/evidence/production-line/` (dizin dahil), `.github/workflows/checks.yml`,
`lib/app/lesson/technique_preview.dart`, `lib/app/combo/*`, `lib/app/progress/boxing_progress.dart`,
`lib/app/storage/*`, `lib/app/paywall/jablab_paywall.dart`, `lib/app/entitlements/jablab_entitlement.dart`,
`integration_test/subscription_lifecycle_test.dart`, `assets/content/disciplines/`,
`docs/content/{rights-ledger,expert-approvals}.json`, `test/full_vision_inventory_test.dart`,
`lib/app/shell/` — hiçbiri erken/sızıntılı biçimde oluşturulmamış. Evidence ledger
(§8 protokol) bu depoda henüz **bootstrap edilmedi** — `docs/evidence/production-line/`
dizini yok; JAB-P0-002 slotu açıldığında ilk iş bunu kuracak.

## 5. Roadmap ifadesiyle gerçek durum arasındaki NİTELİKSEL sapma (dosya varlığı değil, ANLAM sapması)

Roadmap §1: *"`lib/shell_candidate/` shipped shell değildir; iki shell paralel
yaşamamalı."* — Bu ifade **eksik/basitleştirilmiş**. Ayrıntı PREP (b) raporunda
(`SHELL-ENVANTERI-ANALIZI-2026-08-19.md`): `shell_candidate/`'in 6 dosyasından
4'ü (+`WhyNotPage`) zaten **shipped app'in aktif bağımlılığı**; yalnız
sayfa-seviyesi 6 bileşen (`ShellScaffold`/`ProgressPage`/`PaywallStub`/
`LibraryPage`/`ItemPage`/candidate-`CoursePage`) gerçekten "donmuş/kullanılmayan
aday" durumda. JAB-P0-001'i alacak writer bu ayrımı bilmeden "iki shell'i
birleştir" gibi okursa yanlış kapsamda çalışır.

## 6. Küçük/düşük öncelikli gözlem (sapma değil, bilgi notu)

- `docs/DEFTER.md` (164 satır, son kaydı ~2026-07-29 "stance referansı" konusu)
  `workspace/DEFTER.md`'den (560KB, J-290'a kadar) **AYRI ve TERK EDİLMİŞ** bir
  defter — kurumsal dönüşümden (2026-07-25) önceki bir kalıntı olabilir.
  Aktif olarak kullanılmıyor, karışıklık riski düşük ama temizlik adayı.
- `build` / `build 2` iCloud-çiftleme dizinleri mevcut ama `.gitignore`
  (`build [0-9]*` deseni) bunları **zaten kapsıyor** — bilinen risk, önlemi
  hazır.

## 7. Sonuç

Roadmap'in JAB-P0/P1 dosya envanteri **%90+ doğru**; kapılar (analyze/app/motor)
**tam yeşil ve DEFTER'in son beyanıyla birebir tutarlı**. Gerçek sapma yalnız
JAB-P1-003/004'ün henüz başlamamış kısımlarında (beklenen) ve shell_candidate'in
"iki shell" çerçevesinin fazla basitleştirilmiş olmasında. Evidence ledger
(`docs/evidence/production-line/`) henüz yok — protokol §8 gereği JAB-P0-002
slotu açıldığında bootstrap edilecek.
