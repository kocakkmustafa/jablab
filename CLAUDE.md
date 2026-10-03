# CLAUDE.md — JabLab

Ortak şirket/ürün/servis/durum bağlamı için önce [YULAlab ortak girişini](../../../AGENTS.md) oku. Teknik yöntemi model seçer; bu dosya işlem yetkisi üretmez. Yerel ürün ve güvenlik bilgileri aşağıdadır.

Solo boks becerisi.

## Yerel ürün ve güvenlik bağlamı

- Ortak altyapı pinli Motion Core'dan gelir; app'e özgü içerik/kural/progresyon app reposundadır. Mevcut çekirdek/app sınırı korunur.
- Ham video cihazda kalır; düşük güvende hüküm verilmez; tıbbi iddia yoktur (wellness).
- Mevcut gerçek-zamanlı LLM yasağı güvenlik/ürün sınırı olarak korunur; kaldırılması bu belge düzenlemesinin kapsamı değildir.
- Beş ayrı beceri alanında tam kurs hedefi ve güncel kabul/yayın durumu ortak PROJECTS'tedir; ilk kurs ve tarihsel kapı sonucu tam ürün kabulü değildir.
- [D2 raporu](docs/gates/D2-KAPI-RAPORU.md) ve mevcut defter tarihsel hız/blur değerlendirmesini korur. Kayıtlı sonuç şartlıdır: 6 klip/2.662 kare/128 yumruk; J-007 blur/kapanma ayrımı ve J-011 cihaz-üstü sürdürülebilir fps/termal profil kapsamı tam kabul sayılmaz.
- Mevcut `tool/setup_hooks.sh`/`tool/hooks/pre-commit` dosyaları yerinde; doküman otomatik Git config/hook kurulumu emretmez. Doğrulama sonucunun gerçek çıkış kodu saklanır; başarı satırı tek başına kanıt değildir.
- Bundle ID: `com.yulalab.jablab`.
