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

echo "core.hooksPath -> tool/hooks (bu klondaki commit kapısı artık AKTİF)."
