# CLAUDE.md — JabLab

## 🔒 KOD BAŞLATMA KİLİDİ
Kurucu "JabLab'a başlayalım" demeden üretim kodu YAZILMAZ. Başlangıç sırası:
1. `../VENTURE.md` + `../workspace/` dörtlüsünü OKU.
2. Aile sözleşmesi OKU (bağlayıcı): motion-core `docs/00-AILE-MIMARISI.md` — lokal: `ventures/motion-core/lib/docs/00-AILE-MIMARISI.md` (kapsam direktifi §1.1: sesli antrenör-vaadi çekirdek; V1 = sıra, tavan DEĞİL).
3. `docs/jablab-plan.md` OKU.
4. **V0 kapısı:** D2 — HIZ ÖRNEKLEME ÖLÇÜMÜ: hedef cihazlarda gerçek yumruk fps/blur profili; hız metriklerinin faz-süresi tasarımının fixture'la doğrulanması.
5. Kapı sonucu kurucuya → sonra plan/kod.

## 🚪 Commit kapısı — HER TAZE KLONDA BİR KEZ
`bash tool/setup_hooks.sh` — koşulmazsa `flutter analyze` + app süiti + motor
süiti commit anında ÇALIŞMAZ (`core.hooksPath` git ayarıdır, dosya değil;
hiçbir repo içeriği onu otomatik ayarlayamaz). Kapı betiği `tool/hooks/
pre-commit` İZLENİYOR, ama tetikleyicisi izlenmiyor — bu adım o boşluğu
kapatır (ölçüldü 2026-08-11, koordinatör: taze klonda önceden koruma
SIFIRDI). Boru hattı KULLANMAZ (`flutter test | tail -1` sınıfı çıkış-kodu
yutma J-197 kapanışında ölçülmüştü); her adımın çıkış kodu doğrudan taşınır.

## Sert kurallar
- Ortak altyapı motion-core'dan PİNLİ sürümle gelir; çekirdek kodu buraya KOPYALANMAZ, app mantığı çekirdeğe SIZMAZ.
- Gerçek-zamanlı LLM yok · ham video cihazda · düşük güvende hüküm yok · kural = versiyonlu config · replay-fixture'sız teknik eklenmez · tıbbi dil yasak (wellness).
- Danışmanlar: `motion-cv-engineer` + `movement-science-advisor`; submit öncesi `privacy-data-guardian` + `store-policy-officer`.
- Bundle ID: `com.yulalab.jablab` (rezerve, 2026-07-25).
