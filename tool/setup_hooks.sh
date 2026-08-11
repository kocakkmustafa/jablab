#!/bin/bash
# Bir kerelik kurulum: bu klonda commit kapısını AKTİF eder.
#
# NEDEN GEREKLİ: `core.hooksPath` bir git AYARIDIR, dosya değil — hiçbir
# repo içeriği onu otomatik ayarlayamaz (git bunu güvenlik gereği
# yapmaz). `tool/hooks/pre-commit` İZLENİYOR ama koşması için bu komutun
# BİR KEZ çalıştırılması gerekiyor. Ölçüldü (2026-08-11, koordinatör):
# taze klonda bu adım atlanırsa 44 kapının koruması SIFIR olur.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

chmod +x tool/hooks/pre-commit
git config core.hooksPath tool/hooks

# ⚠️ ÖLÇÜLDÜ (taze klon sınaması, 2026-08-11): pose modeli (.task, 9,4 MB)
# aile kuralıyla git DIŞINDA tutuluyor (motion-core/.gitignore) — taze
# klonda `assets/models/` dizini yok ve `flutter analyze` bunu HATA sayıp
# çıkış kodunu 1 yapıyor. Fetch edilmeden kapı kendi ilk koşumunda
# ÇALIŞMADAN kırmızı dönerdi — kurulmuş olmak yetmiyordu, öttüğünü
# GÖRMEDEN bu boşluk saklı kalırdı. Testler modelin yokluğuna zaten
# toleranslı (`model_pin_test` isimli sebeple atlar); `flutter analyze`
# değil.
bash tool/fetch_pose_model.sh

# ⚠️ P0 ÖLÇÜLDÜ (koordinatör, 2026-08-11): `build` iCloud/codesign
# panzehiri (KAMERA-KOPRUSU-CANLILIK.md) gereği bir sembolik linke
# çevrilmişti VE makineye özel mutlak yoluyla git'e COMMIT'LENMİŞTİ
# (`.gitignore`daki `build/` sondaki `/` yüzünden yalnız GERÇEK dizinleri
# kapsıyordu, sembolik linki kaçırdı). Başka makinede taze klon =
# sarkan symlink = `flutter test` tool-crash — ürün kusuru SANILABİLECEK
# bir kapı kırmızısı. Sembolik link artık İZLENMİYOR (`git rm --cached`,
# `/build` eklendi); yerel kolaylık olarak BURADA üretilir, hiçbir mutlak
# yol repoya girmez.
#
# SIRA ÖNEMLİ (2026-08-04'te bir kez yanlış sırayla ölçüldü, J-092):
# `flutter clean` `build`i bir dizin sanıp kaldırır — SEMBOLİK LİNK DAHİL.
# Önce hedef dizin, SONRA temizlik, EN SON symlink.
BUILDOUT="$HOME/jablab_buildout"
mkdir -p "$BUILDOUT"
rm -rf build
flutter clean > /dev/null 2>&1 || true
ln -sf "$BUILDOUT" build

echo "core.hooksPath -> tool/hooks (bu klondaki commit kapısı artık AKTİF)."
