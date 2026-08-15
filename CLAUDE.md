# CLAUDE.md — JabLab

## 🔒 KOD BAŞLATMA KİLİDİ

> 🔓 **AÇILDI — 2026-08-16, H-28/M-F-636 (YAYIN YOLU rejimi, orkestratör görev-dağıtımı
> başladı).** Kilit 2026-07-26'da JabLab tetiklendiğinde geçerliydi; bugün depo **252+
> commit** derinliğinde ve üretim kodu zaten yazılı. Kilit cümlesi SİLİNMEDİ (o günün
> doğrusuydu, `M-F-634 ⑤`) — bugünden itibaren geçersiz sayılır. (H-31)

Kurucu "JabLab'a başlayalım" demeden üretim kodu YAZILMAZ. Başlangıç sırası:
1. `../VENTURE.md` + `../workspace/` dörtlüsünü OKU.
2. Aile sözleşmesi OKU (bağlayıcı): motion-core `docs/00-AILE-MIMARISI.md` — lokal: `ventures/motion-core/lib/docs/00-AILE-MIMARISI.md` (kapsam direktifi §1.1: sesli antrenör-vaadi çekirdek; V1 = sıra, tavan DEĞİL).
3. `docs/jablab-plan.md` OKU.
4. **V0 kapısı:** D2 — HIZ ÖRNEKLEME ÖLÇÜMÜ: hedef cihazlarda gerçek yumruk fps/blur profili; hız metriklerinin faz-süresi tasarımının fixture'la doğrulanması.

   > 🔓 **KANITLA KAPALI (2026-08-16 doğrulandı) — TAM DEĞİL, ŞARTLI.** 2026-07-26'da
   > ölçüldü: 6 klip / 2.662 kare / 128 yumruk, medyan `t_ext`=128,2 ms → 3,8 kare@30fps ·
   > 7,7 kare@60fps (ön-kayıtlı eşik ≥2/≥4 ✅). Faz-süresi metriği 2× seyreltmede **6/6
   > klipte** piksel-hızından kararlı. Kanıt: `docs/gates/D2-KAPI-RAPORU.md` + DEFTER
   > `J-001` (şartlı kapalı) + `J-018` (kurucu onayı `M-F-01`, 2026-07-26 retrospektif,
   > gece modu §2.6). **Açık kalan iki şart** (J-018'de adıyla, silinmedi): `J-007`
   > (blur↔kapanma-mesafesi ayrışmadı, H2 sonuçsuz) · `J-011` (cihaz-üstü sürdürülebilir
   > fps + termal profil ölçülmedi — fiziksel cihaz gerektirir, kurucu-kapılı, bkz. A12).
   > Kanıtı bulamasaydım "karşılandı" yazmayacaktım (H-31); buldum, ama tamamı değil —
   > bir kapıyı yarım kanıtla tam kapalı yazmak, kanıtsız yazmaktan farksızdır. (H-31)
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
