# YULAlab — yerel Codex girişi

Önce [ortak bağlam girişini](../../../AGENTS.md), ardından [bu reponun tek yerel ürün/güvenlik kaynağını](CLAUDE.md) oku. CLAUDE.md içindeki yerel bilgiler Codex ve Claude için aynıdır; teknik yöntemi model seçer, dosya işlem yetkisi üretmez.

Bu bölümler Codex ve diğer kod ajanları içindir; kısa tutulur. `CLAUDE.md` ile çelişirse CLAUDE.md doğrudur.

## Yığın
- Flutter 3.47.5 (CI'da sabit) · Dart ^3.9.0 · durum yönetimi: yok; `ChangeNotifier`/`ValueNotifier` (Riverpod/bloc yok).
- Ortak altyapı pinli Motion Core'dan (`motion_*` git bağımlılıkları); yerel paket `packages/jablab_engine`.
- Kurulum: `flutter pub get` (+ `cd packages/jablab_engine && dart pub get`) · Analiz: `flutter analyze` · Test: `flutter test` ve `cd packages/jablab_engine && flutter test`.
- CI (`.github/workflows/checks.yml`, `gates` işi) ayrıca koşar: `dart run tool/build_solo_boxing_integrity_manifest.dart --check`, `python3 tool/check_media_source_projection.py --check`, `python3 tool/build_boxing_editorial_closed_qa.py --check`, `python3 tool/test_frozen_source_release_gate.py`.

## Kurallar
- **Minimal diff:** yalnız istenen dosyalara dokun; biçimlendirme/yeniden adlandırma turu yapma.
- **Yerelleştirme ARB/`gen-l10n` değildir.** 14 dil; kaynak `l10n/source_catalog.json` (id = `s_` + SHA256(en + U+0000 + tr)), çeviriler `l10n/translations/<dil>.json` (tr kaynaktır, dosyası yok), uygulamaya giren paket `assets/i18n/<dil>.json`. Araç: `python3 tool/l10n/catalog.py` (`--refresh`, `--write`, `--allow-partial`). Boşluğu ve anatomik yönleri normalize etme; yeni metni tüm dillere ekle.
- Testler: uygulama için `test/*_test.dart`, motor için `packages/jablab_engine/test/`, araçlar için `tool/test_*.py`; yeni davranışa test ekle; mevcut testi silme ya da atlatma.
- Gerçek-zamanlı LLM yasağı ve "ham video cihazda kalır" sınırı korunur; tıbbi iddia yazma.
- Bitirmeden: analiz ve test temiz olmalı; çıktının son 5 satırını ve gerçek çıkış kodunu rapora koy (başarı satırı kanıt değildir).

## Dokunulmaz
- Sır dosyaları (`.env*`, anahtarlar, `~/.secrets`), imzalama yapılandırması (`android/app/build.gradle.kts`, `tool/app_store_signing.xcconfig`), fiyat/abonelik kimlikleri, Supabase göçleri ve şeması — yalnız açık talimatla.
- Mağaza meta verisi ve sürüm numarası (`pubspec.yaml` `version`) — yalnız açık talimatla.
- Motion Core pini (`pubspec.yaml` içindeki `motion_*` `ref`i; hepsi aynı commit olmalı, `test/dependency_pin_test.dart` zorlar) — yalnız açık talimatla.
- Kamera özelliği bayrağı kapalı kalır: `jablabCameraCoachingAvailable` (`lib/main.dart`, Core kamera bayrağını izler) açılmaz.
- Burun Farkı ve Iron Bank'a dokunulmaz.
