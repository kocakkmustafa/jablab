# 🏗️ SHELL ENVANTERİ ANALİZİ — shipped `lib/app/` vs `lib/shell_candidate/`, 2026-08-19

> PREP lane salt-okuma analiz. Kod YAZILMADI. Amaç: JAB-P0-001'in (Canonical
> shell ve claim truth) Step 1'ini ("Shipped ve candidate route/capability
> farkını makine-okur envantere çıkar") önceden hazırlamak — writer slotu
> geldiğinde sıfırdan keşfe gerek kalmasın.

## 1. Roadmap'in ifadesi eksik — gerçek durum üç katmanlı

21-JABLAB-MASTER-ROADMAP.md §1: *"`lib/shell_candidate/` shipped shell
değildir; iki shell paralel yaşamamalı."* Bu, `lib/shell_candidate/README.md`
(depoda zaten mevcut, kanonik kaynak) ile karşılaştırıldığında **basitleştirilmiş**:
gerçekte üç ayrı katman var, ikisi değil.

### Katman A — zaten shipped, "aday" değil (aile-terfi bekleyen altyapı)

| Dosya | Sembol | Kullanan shipped dosyalar |
|---|---|---|
| `shell_models.dart` | `ShellLibrary/ShellItem/ShellCourse/ShellLesson/ShellExclusion` | `content_repository.dart`, `course_page.dart`, `select_page.dart`, `session_screen.dart`, `onboarding_page.dart`, `jablab_app.dart` (6 dosya) |
| `live_surface.dart` | `LiveState`, `SessionSummaryView` vb. | `session_screen.dart`, `skeleton_overlay.dart`, `live_jab_controller.dart` |
| `session_flow.dart` | `SessionStage`, `IntervalTimer` | `session_screen.dart` |
| `honesty_box.dart` | `HonestyBox` | `select_page.dart` |
| `library_pages.dart` (yalnız `WhyNotPage`) | `WhyNotPage` | `jablab_app.dart` (`show WhyNotPage` ile kısıtlı import) |

Bu katman **motion_shell'e (M-F-25) terfi beklerken JabLab'ın kendi üretim
kodunun omurgası** durumunda — "shell_candidate" adı yanıltıcı, bunlar aday
değil, çalışan bağımlılık.

### Katman B — donmuş, JabLab'ın kendi app akışı ARTIK çağırmıyor (gerçek "dead candidate")

| Dosya | Sembol | Durum (README'nin kendi kaydı, 2026-08-06/07) |
|---|---|---|
| `shell_scaffold.dart` | `ShellScaffold` | 4-sekme kabuk — JabLab 3-sayfa+köşeye geçti, terk edildi |
| `shell_scaffold.dart` | `ProgressPage` | JabLab kendi K8-bant bloğunu `course_page.dart` içine **yeniden yazdı** (aynı metin/key, ayrı kod) |
| `shell_scaffold.dart` | `PaywallStub` | **0 atıf** (J-135, 2026-08-07 ölçüldü) — "yakında kullanılacak" sanılırsa yanlış izlenim |
| `library_pages.dart` | `LibraryPage`, `ItemPage`, `CoursePage` (candidate'teki, `lib/app/course_page.dart`'takinden AYRI) | JabLab kendi `course_page.dart`'ını "donmuş dosya bozulmasın diye" bilerek ayrı yazdı |

Bu katman roadmap'in "dead candidate" kastettiği gerçek karşılık — **terfi
kaderi aile kararı, koordinatörde** (README'nin kendi notu).

### Katman C — Katman B'ye DOĞRUDAN pompalayan, ama JabLab'ın gerçek navigasyon
kökünden GEÇMEYEN testler ("bayat yeşil")

`progress_recorded_test.dart` ve `shell_test.dart`, `ProgressPage`/`ShellScaffold`'u
widget ağacına doğrudan enjekte ediyor — JabLab'ın `MaterialApp` → `SelectPage`
kökünden değil. README'nin kendi uyarısı: *"Bayat yeşil kırmızıdan tehlikelidir:
bunu ölçmeden okuyan biri 'JabLab hâlâ bunu kullanıyor' sanabilir."* Bu testler
**Katman B'nin kod bütünlüğünü** kanıtlıyor, **kullanıcı erişilebilirliğini DEĞİL**.

## 2. `test/shell_promotion_test.dart` — roadmap'in beklediğinden FARKLI bir şeyi test ediyor

JAB-P0-001 Step 2: *"Tek canonical shell kabul testini önce kırmızı yaz;
duplicate route ve dead candidate FAIL üretir."*

Gerçekte var olan `shell_promotion_test.dart` (368 içinde, yeşil) bunu
**test etmiyor**. Test ettiği şey: `lib/shell_candidate/`'in
**`motion_shell` aile-paketine terfi ön-koşulları** —
1. Alan sözlüğü sızıntısı yok (regex: punch/jab/round/boxing/vb. geçmiyor)
2. `jablab_engine`/`lib/app/` bağımlılığı yok
3. Dürüstlük değişmezleri (`assert`, `numericUnlocked`) kabukta kodlu

Bu, roadmap'in istediği "duplicate route/dead candidate FAIL" kabul testinden
**kavramsal olarak ayrı** (biri AİLE-TERFİ kapısı, diğeri JABLAB'IN KENDİ
canonical-shell netliği). İsim çakışması (`shell_promotion_test.dart`) kafa
karıştırıcı: aynı ada iki farklı niyet yüklenmiş durumda.

**Writer'a not:** JAB-P0-001 Step 2'yi uygularken mevcut testin kapsamını
DEĞİŞTİRMEDEN (aile-terfi kapısı hâlâ geçerli bir sözleşme) AYRI bir test
eklenmeli — örn. `test/canonical_shell_reachability_test.dart` — Katman B'nin
hiçbir üyesinin gerçek navigasyon ağacından (Katman C testleri hariç)
erişilemez olduğunu ve `lib/app/shell/`e taşınacak üyelerin tekilliğini
doğrulayan.

## 3. JAB-P0-001 Step 3 için aile-kararı çelişkisi riski — orkestratöre soru

Roadmap Step 3: *"Onaylanan component'leri `lib/app/shell/` altına taşı."*
Katman A zaten aile-çapında `motion_shell`'e (M-F-25) terfi planında. Bu
bileşenleri JabLab'a özel `lib/app/shell/`'e taşımak, ileride aile-terfisi
geldiğinde **ikinci bir taşıma turu** doğurur (çifte iş) ve M-F-25 kararıyla
potansiyel çakışır. **Öneri:** JAB-P0-001 writer'ı işe başlamadan Motion
Orchestration'a şunu sorsun — "Katman A (zaten kullanılan 4+1 bileşen)
`lib/app/shell/`e mi taşınsın, yoksa `motion_shell` aile-terfisini bekleyip
yalnız Katman B (gerçek dead candidate, 6 bileşen) için mi canonical-shell
kapısı kurulsun?" Bu, roadmap'te YOK — protokol §13 madde 1 gereği sapma
olarak flag ediliyor, körlemesine karar verilmiyor.

## 4. Özet tablo (writer'a hazır envanter)

| Kategori | Dosya sayısı | Sembol sayısı | Aksiyon |
|---|---:|---:|---|
| A — shipped altyapı (aday değil) | 4 (+1 kısmi) | 5+ sınıf ailesi | Dokunma / aile-terfi kararını bekle |
| B — donmuş, gerçek dead candidate | 2 dosya içinde | 6 (`ShellScaffold`,`ProgressPage`,`PaywallStub`,`LibraryPage`,`ItemPage`,candidate-`CoursePage`) | JAB-P0-001'in asıl hedefi — sil/taşı/bağla kararı koordinatörden |
| C — donmuş bileşene pompalayan testler | 2 dosya | — | Kapsam etiketini düzelt (ne ölçtüğünü netleştir) veya Katman B kararına bağla |

**Kaynak:** `lib/shell_candidate/README.md` (depoda zaten mevcut, en güncel
ve kanonik envanter — bu rapor onu doğruladı ve roadmap diliyle köprüledi,
yeniden icat etmedi).
