# JabLab — LOOP

## Oturum protokolü
1. `../VENTURE.md` + PROGRESS son mühür + DEFTER açık maddeler OKU.
2. 🔓 **Kod kilidi 2026-07-26'da AÇILDI** (kurucu tetiği verildi). Artık üretim kodu yazılabilir.
3. Her iterasyon: kuyruktan iş al → yap → **KANITLA doğrula** → PROGRESS'e mühürle → DEFTER'i güncelle.
4. Kapanışta `/oturum-kapanisi`.

## ⛔ Kuyruk başındaki blokaj
**M-017 (motion-core çakışması) kurucu kararı bekliyor.** `packages/motion_core/` başka bir oturumun commit'siz işi; JabLab motoru onun üstüne kurulacak. Karar gelmeden çekirdeğe bağımlı kod yazılmaz — çekirdekten BAĞIMSIZ işler öne çekilir (aşağıda ⭐).

## İş kuyruğu (öncelik sırasıyla)

### ⭐ Çekirdekten bağımsız (M-017 beklemeden yapılabilir)
1. **`boxing@1.0.0` kural config'i yaz** — ADR-004 şeması; teknik tanımları + 10 hata kodu + drill eşlemesi. Eşikler D2 başlangıç değerleriyle, `calibrationPending: true` bayrağıyla.
2. **Müfredat config'i** (G6 erken başlangıcı) — Başlangıç hattı: kamera→stance→guard→jab→cross→1-2→footwork→ilk tur. Ölçülebilir beceri kriterleriyle (PRD §9).
3. **Sesli koç replik seti (EN)** — tur içi tek-hata disiplinine uygun kısa cue'lar; ~60 replik çekirdek + sayaç/tebrik/tur yönetimi. `feedbackKey` → metin eşlemesi.
4. **`movement-science-advisor` turu** — hata taksonomisinin fizyolojik ilk-geçiş denetimi (gerçek antrenör doğrulaması öncesi).
5. **G0 kalanı:** rakip elle-doğrulama (M-015) — PunchLab/Boxx/FightCamp store fiyat+özellik ekran görüntüsü; dataset lisans yazışma listesi (J-005).

### Çekirdek kararından sonra
6. **Standing Striking Engine** — `motion_core.PhaseStateMachine` üzerine jab/cross faz tanımları + stance değerlendirici + kombinasyon sıra motoru + hata üretici.
7. **Replay testleri** — bu gecenin 6 gerçek fixture'ı (`scratch/2026-07-26-jablab-d2/fixtures/`) üzerinde motor doğrulaması; sonra kurucu çekimleriyle gerçek fixture seti.
8. **Native köprü (T1)** — Kotlin/Swift port + altın-fixture çapraz doğrulama (ADR-002).

### Kurucu çekimi geldikten sonra (D2-D)
9. **Eşik kalibrasyonu** (J-007) → `ELBOW_FLARED` / `OVERREACH` bandını B'den A'ya taşı.
10. **Kamera açısı kesin kanıtı** (J-006, çekim #13) → ADR-003 onayı veya revizyonu.
11. **G3 fixture kütüphanesi** — 8 hata sınıfı × doğru/yanlış; CI kapısı.

## Kurucu-kapılı (gece yapılamaz)
- remote push / main merge · M-017 uzlaştırma · D2-C cihaz ölçümü · voice-pack harcaması · nihai fiyat · submission · domain (`jablab.app`)
