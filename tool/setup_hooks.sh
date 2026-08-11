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

echo "core.hooksPath -> tool/hooks (bu klondaki commit kapısı artık AKTİF)."
