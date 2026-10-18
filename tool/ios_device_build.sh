#!/bin/bash
# 📱 iOS CİHAZ DERLEMESİ — KAPILI SARMALAYICI (J-246, 2026-08-14 gece vardiyası)
#
# NEDEN VAR — bedelle öğrenildi:
#   2026-08-13 12:11'de bir `integration_test` denemesi
#   `ios/Flutter/Generated.xcconfig` içindeki FLUTTER_TARGET'ı geçici bir
#   `flutter_test_listener/listener.dart` yoluna yazdı. Temp dizin OS
#   tarafından silindi. Sonraki HER iOS derlemesi `lib/main.dart` yerine
#   SİLİNMİŞ bir stub'ı derlemeye çalıştı. Bir gün önceki oturumun
#   "84,1 saniyede GEÇEN ama debug bağlantısı kurulamayan" derlemesi ve
#   "yalnız durum çubuğu görünen siyah render"ı bununla tutarlı.
#   ⇒ ***BİR DERLEMENİN YEŞİL OLMASI, DERLEDİĞİ ŞEYİN SENİN ÜRÜNÜN
#      OLDUĞUNUN KANITI DEĞİLDİR.***
#
# ⛔ NEDEN COMMIT KAPISI DEĞİL: `flutter test` bu değeri meşru olarak
#   değiştirir. Commit kapısına konsaydı her test koşumundan sonra commit'i
#   reddederdi — J-245'in dersi: *bir kapı kendi ürününün ilerlemesini
#   cezalandırıyorsa, ürünün düşmanıdır.* Yeri DERLEME yolu.
#
# ⛔ BORU HATTI YOK: çıkış kodu her adımda doğrudan taşınır.
#
# KULLANIM:
#   tool/ios_device_build.sh                      # derle + artefaktı doğrula
#   tool/ios_device_build.sh <CIHAZ_UDID>         # ayrıca KURULABİLİRLİK ölç
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
LOCK="${JABLAB_NATIVE_LOCK_FILE:-$ROOT/../../../scratch/2026-10-02-autonomous-e2e/shared-locks/machine-runtime.lock}"
exec python3 "$ROOT/tool/with_native_lease.py" --lock-file "$LOCK" -- bash "$ROOT/tool/ios_device_build_impl.sh" "$@"
