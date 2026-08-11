# ADR-005 — $cameraBasis politikası: kamera-gereksinimi beyanı, cihaz-kanıtından AYRI

**Tarih:** 2026-08-11 · **Statü:** KABUL · **Bağlam:** J-194/J-197 (`curriculum.json` `$gateReachability`), motion-core `docs/70-KAMERA-KOPRUSU-SOZLESMESI.md` §1/§7, koordinatör hükmü (2026-08-11 22:44)

## Karar

Bir dersin `usesCamera: true` taşıyıp taşımadığı — yani `$cameraBasis` — şu tek soruya bağlıdır:

> **Bu dersin `curriculum.json`'daki ilerleme kapısı, tespit-türevi bir sinyale mi dayanıyor?**

Tespit-türevi sinyal: `event` sayımı (`jab`, `setupCheckPassed`…), `combination` sıra takibi, `withValidAnalysisRatio` (geçerli-analiz oranı). Bunların hepsi kamera+poz-çıkarım hattının çıktısıdır; kamera kapalıyken hiçbiri üretilemez.

Bu soru **cihazda kanıtlanmış olmaya bağlı DEĞİL.** İki eksen ayrı:

| Eksen | Ne kanıtlar | Kanıtlayan |
|---|---|---|
| **Cihaz turu** (§7.3-7.7) | Köprü **ÇALIŞIYOR** — gerçek `judgedRatio`, gerçek `meanInferenceUs`, gerçek cihazda oturum | kurucu-manuel, henüz açık |
| **`$cameraBasis`** | Ders **GEREKTİRİYOR** — bu dersin kapısı tespitsiz asla geçilemez | içerik beyanı, bugün karara bağlanabilir |

Bir dersin kamera gerektirdiğini söylemek, kameranın bugün kanıtlanmış olmasını beklemez — tıpkı `boxing.foundations.jab`'ın `usesCamera:true`sinin köprü §7 kapanmadan ÖNCE de doğru olması gibi (J-096, 2026-07-30). Sözleşme §1 katman sorumluluklarını da cihazdan bağımsız tanımlıyor; §7 yalnız köprünün "yazılı" değil "canlı" sayılması için gereken kanıt listesi.

Bu karar `motion-core` `M-F-77`'nin beş kurucu-kapılı kaleminden (harcama · store · fiyat · lisans · tasarım yönü) hiçbirine girmiyor — kapsam bir **içerik doğruluğu** sorusu, `$gateReachability`'nin kendi mantığının bir uzantısı.

## Uygulama — 12 ders (J-197 listesi)

`$gateReachabilityUnreachable`'daki 12 dersin hepsinin kapısı tespit istiyor; hepsine `usesCamera:true` + gerekçeli `$cameraBasis` eklendi:

- **8 ders** (`first_round`, `r3`, `r5`, `r10`, `r20`, `tempo`, `hiit`, `technique_round`) — kapı `sessionMinutes` + `withValidAnalysisRatio: 0.7`. Bu ikisi zaten modellenmiş `jab`/`cross` tekniğiyle çalışan round/interval dersleri; `withValidAnalysisRatio` doğrudan köprünün ölçtüğü `judgedRatio`nun karşılığı (`KAMERA-KOPRUSU-CANLILIK.md` — emülatörde 0,810 ölçüldü). En sağlam 8.
- **`boxing.intermediate.fatigue`** — aynı sınıf (`sessionMinutes` + `withValidAnalysisRatio`), 20 dk'lık en uzun tur.
- **`boxing.foundations.one_two`** — kapı `combination:"1-2", minCorrectSequences:20`. Sıra-takibi A bandında (`$gateableWhy`), ama ⚠️ **J-162/163'te `COMBINATION_END`'in motorda hiç geçmediği ölçülmüştü ve bu ölçüm bu turda YENİDEN sınanmadı** (başlangıç promptunun ayrı, kapanışta bilerek bırakılmış 2. işi). `usesCamera:true` doğru — kombinasyon sırası kavramsal olarak tespit gerektiriyor — ama kapının somut olayının bugün ateşlendiği YENİDEN doğrulanmadı; bu ayrı ve açık kalan bir bulgu, burada ÇÖZÜLMEDİ.
- **`boxing.foundations.stance`** — kapı `event:"stanceHold", minSeconds:60`. Duruş genişliği/ayak çaprazlaması/denge tespiti gerçek ve A bandında (M-F-06 geometrik dedektör, `drill.stance_reset`/`drill.balance`/`drill.footwork_basics` `gateable:true`) — `usesCamera:true` bu yüzden doğru. Ama ⚠️ **`stanceHold` adlı bir olay motor kodunda HİÇBİR YERDE üretilmiyor** (repo geneli arama, sıfır eşleşme) — bu spesifik kapı-olayı bugün var olmayan bir üretici bekliyor. Tespit yeteneği gerçek, bu tek gate-primitifi değil.
- **`boxing.foundations.camera`** — kapı `event:"setupCheckPassed"`. En çarpıcı vaka (J-197'nin kendi örneği): bu ders kamerayı KURMAYI öğretiyor, `usesCamera:true` olması apaçık. Ama ⚠️ **`setupCheckPassed` de motor kodunda hiçbir yerde üretilmiyor** — aynı sınıf boşluk.

**Son iki madde bilerek YARIM bırakılmadı — NAMED bırakıldı.** `usesCamera` bayrağı (gerçekten tüketilen, canlı mekanizma — `content_repository.dart`/`jablab_app.dart`) ile `curriculum.json`'daki gate-olayının bir üreticisi olması (bugün HİÇBİR gate'in tüketicisi yok, J-179) iki ayrı katman. Bu ADR yalnız BİRİNCİSİNİ düzeltiyor — ki görev buydu. `stanceHold`/`setupCheckPassed` üreticilerini yazmak yeni motor yüzeyi açar (kapsam dışı: "eşik icadı yok", tek turda 12 ders sınırı, motion_camera pin'e dokunmama).

## Pil / ısı / izin politikası

`usesCamera:true` bayrağı, dersin canlı seans ekranı açıldığında `LiveJabController.start()`ı tetikler (`lib/app/jablab_app.dart:542`) — **kurulumda değil, seans açılışında**, ve izin isteği de aynı anda, bağlamsal olarak (`live_jab_controller.dart:149`, "İZİN ÖNCE, kamera SONRA"). 12 dersin eklenmesi bu akışa yeni bir desen SOKMUYOR — var olan `jab`/`guard`/`range` deseninin aynısı, yalnız kapsamı genişliyor.

**Gerçek fark — süre.** `jab`/`guard`/`range` birer teknik-drill dersi (10-12 dk, sabit ders süresi). Eklenen 12'nin **8'i round/interval dersi** ve ikisi 20 dakikaya kadar çıkıyor (`r20`, `fatigue`) — kamera+poz-çıkarımının SÜREKLİ ve UZUN çalıştığı ilk vaka bunlar. Bu, ADR-001'in "2× dual-pass maliyeti" varsayımının ve §7.4'ün (dual-pass ölçümü) asıl sınama zemini olacak — bugüne kadar hiçbir ölçüm 20 dakikalık sürekli çıkarımı kapsamadı (emülatör smoke'u 40 sn).

**Politika, icat değil, sınır beyanı:**
1. Pil/ısı maliyeti bu ADR'de **tahmin edilmiyor** — `KAMERA-KOPRUSU-CANLILIK.md` §7.3/§7.4 zaten bunu kurucu-manuel cihaz turunun kalemleri olarak isimlendirmiş; bu ADR o listeyi DEĞİŞTİRMİYOR, yalnız hangi derslerin o ölçümün kapsamına gireceğini genişletiyor (3 dersten 15'e).
2. İzin UX'i **değişmiyor** — her ders kendi `start()`ında ister, `already-running` kilidi (C-195) tek-kamera varsayımını zaten koruyor.
3. `withValidAnalysisRatio: 0.7` eşiği **icat edilmedi** — zaten `curriculum.json`da yazılıydı (J-197'den önce de); bu ADR onu değiştirmedi, yalnız hangi derslerin ona tabi olacağını (kamera açıklığı üzerinden) netleştirdi.
4. **motion_camera pin'ine dokunulmadı** — bu karar tamamen içerik katmanında (`library.json`), köprünün kendisi (native/Dart) bu turda değişmedi.

## Sonuçlar

- `$gateReachabilityUnreachable` 12 → **0** (tüm kapılar artık `usesCamera:true` temelinde camera-basis şartını sağlıyor). `$gateReachability` metni ve test bunu yansıtacak şekilde güncellendi.
- İki NAMED açık kalem devam ediyor (`stanceHold`, `setupCheckPassed` üreticisi yok) — kapatılmadı, gizlenmedi.
- `one_two`'nun `COMBINATION_END` sorusu (J-162/163) hâlâ açık, ayrı iş.
- Cihaz turu (§7.3-7.7) hâlâ kurucu-manuel — bu ADR onu ne yerine geçiriyor ne erteliyor, yalnız kapsamını (3→15 ders) büyütüyor.
