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
cd "$ROOT"

HEDEF_CIHAZ="${1:-}"
XCCONFIG="ios/Flutter/Generated.xcconfig"
CIKTI="${TMPDIR:-/tmp}/jablab_ios_dd"

# ── KAPI 1/3 — FLUTTER_TARGET zehirlenmesi ────────────────────────────────
# Bu dosya .gitignore'da: taze klonda YOKTUR. "Yok" bir kusur değil, ama
# SESSİZ geçilmemeli — hangi dalda olduğumuz HER koşumda basılır (vakumun
# panzehiri: susmak değil, saymak).
echo "kapı 1/3: FLUTTER_TARGET zehirlenmesi…"
if [ ! -f "$XCCONFIG" ]; then
  echo "  dal: xcconfig YOK (taze ağaç) — üretiliyor"
  flutter build ios --config-only --release
else
  ONCE="$(grep '^FLUTTER_TARGET=' "$XCCONFIG" || true)"
  echo "  dal: xcconfig VAR → ${ONCE:-<FLUTTER_TARGET satırı yok>}"
  if [ "$ONCE" != "FLUTTER_TARGET=lib/main.dart" ]; then
    echo "  🔴 ZEHİRLİ ya da beklenmedik hedef — yeniden üretiliyor"
    flutter build ios --config-only --release
  fi
fi

SONRA="$(grep '^FLUTTER_TARGET=' "$XCCONFIG" || true)"
if [ "$SONRA" != "FLUTTER_TARGET=lib/main.dart" ]; then
  echo "🔴 KAPI 1/3 DÜŞTÜ: FLUTTER_TARGET onarılamadı."
  echo "   beklenen: FLUTTER_TARGET=lib/main.dart"
  echo "   bulunan : ${SONRA:-<yok>}"
  exit 1
fi
echo "  ✅ FLUTTER_TARGET=lib/main.dart"

# ── DERLEME ───────────────────────────────────────────────────────────────
# `-allowProvisioningUpdates` BİLEREK YOK: o bayrak kurucunun geliştirici
# hesabında yapılandırma değiştirir (profile cihaz ekler). Hat dokunmaz.
echo "derleme: xcodebuild (generic/platform=iOS, Release)…"
rm -rf "$CIKTI"
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath "$CIKTI" \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=T5HZGYBWK8 build > "$CIKTI.log" 2>&1
echo "  ✅ xcodebuild exit 0"

APP="$CIKTI/Build/Products/Release-iphoneos/Runner.app"

# ── KAPI 2/3 — ÜRETİLEN ŞEY GERÇEKTEN JABLAB MI ───────────────────────────
# Kapı 1 girdiyi korur; bu kapı ÇIKTIYI ölçer. İkisi aynı varsayıma
# dayanmaz (J-244 ②: iki kontrolün aynı varsayıma dayanması, iki kontrol
# değil BİRDİR).
echo "kapı 2/3: artefakt gerçekten JabLab mı…"
BUNDLE="$(plutil -extract CFBundleIdentifier raw -o - "$APP/Info.plist")"
if [ "$BUNDLE" != "com.yulalab.jablab" ]; then
  echo "🔴 KAPI 2/3 DÜŞTÜ: bundle kimliği '$BUNDLE', beklenen 'com.yulalab.jablab'"; exit 1
fi

SNAP="$APP/Frameworks/App.framework/App"
BOYUT=$(stat -f%z "$SNAP")
if [ "$BOYUT" -lt 1000000 ]; then
  echo "🔴 KAPI 2/3 DÜŞTÜ: Dart anlık görüntüsü $BOYUT bayt (<1 MB) — stub şüphesi"; exit 1
fi

VARLIK="$APP/Frameworks/App.framework/flutter_assets/assets"
for f in content/library.json content/curriculum.json rulesets/boxing.v3.json; do
  if [ ! -f "$VARLIK/$f" ]; then
    echo "🔴 KAPI 2/3 DÜŞTÜ: JabLab'e özgü varlık eksik: $f"; exit 1
  fi
done
echo "  ✅ bundle=$BUNDLE · Dart anlık görüntüsü=$BOYUT bayt · JabLab varlıkları yerinde"

# ── KAPI 3/3 — KURULABİLİRLİK (derlenebilirlikten AYRI eksen) ─────────────
# H-6 dersi: kapsama İKİ EKSENLİDİR. Bundle-ID ekseni imzada bağlar,
# CİHAZ ekseni yalnız KURULUMDA bağlar. Yeşil bir derleme, kurulamayan bir
# profille tamamen tutarlıdır — 08-14'te tam olarak bu ölçüldü.
echo "kapı 3/3: gömülü profilin cihaz ekseni…"
PROF="${TMPDIR:-/tmp}/jablab_embedded.plist"
security cms -D -i "$APP/embedded.mobileprovision" > "$PROF"
PROF_AD="$(plutil -extract Name raw -o - "$PROF")"
echo "  profil: $PROF_AD"
echo "  profildeki cihazlar:"
plutil -extract ProvisionedDevices xml1 -o - "$PROF" 2>/dev/null \
  | grep -o '000[0-9A-Fa-f]*-[0-9A-Fa-f]*' | sed 's/^/    /' || echo "    (yok — store profili)"

if [ -n "$HEDEF_CIHAZ" ]; then
  if plutil -extract ProvisionedDevices xml1 -o - "$PROF" 2>/dev/null | grep -q "$HEDEF_CIHAZ"; then
    echo "  ✅ hedef cihaz $HEDEF_CIHAZ profilde VAR — kurulabilir"
  else
    echo "🔴 KAPI 3/3 DÜŞTÜ: hedef cihaz $HEDEF_CIHAZ profilde YOK."
    echo "   Derleme yeşil ama bu artefakt O CİHAZA KURULAMAZ."
    echo "   Gereken: profil TAZELEME (kurucu — workspace/A12-CIHAZ-RECETESI.md)."
    exit 1
  fi
else
  echo "  ⚠️ hedef cihaz verilmedi ⇒ kurulabilirlik ÖLÇÜLMEDİ (derlenebilirlik ≠ kurulabilirlik)"
fi

echo
echo "✅ TAMAM — artefakt: $APP"
echo
# ⚠️ YAN ETKİ — ÖLÇÜLDÜ, TAHMİN DEĞİL (J-253).
#
# Bu betik bir CİHAZ derlemesidir ve cihaz derlemesi, paylaşılan native-asset
# artefaktının üzerine yazıyor: `objective_c.framework` simülatör paketine
# **platform 2 (cihaz)** olarak giriyor, dyld reddediyor, `package:objective_c`
# başlatılamıyor ve ona bağımlı `path_provider` HER çağrıda patlıyor ⇒
# simülatörde kalıcılık (onboarding bayrağı, seans geçmişi) SESSİZCE ölür.
#
# Tek değişkenli olarak üretildi: önce platform 7 → bu betik → artımlı
# `flutter run` → platform 2 + `DOBJC_initializeApi` istisnası.
#
# ⭐ J-245'in dersi yeni bir kılıkta: BİR KAPININ YAN ETKİSİ, KORUDUĞU ŞEYİ
#    BOZUYORSA, KAPI BUNU KENDİSİ SÖYLEMELİDİR. Sessiz kalsaydı bir sonraki
#    oturum "kaydetmiyor" diye var olmayan bir ÜRÜN kusuru kovalardı — bu gece
#    tam olarak bu oldu ve bir turu yedi.
echo "⚠️  SİMÜLATÖR DOĞRULAMASI ARTIK ZEHİRLİ (yan etki, ölçüldü — J-253)."
echo "    Cihaz derlemesi, simülatörün native-asset artefaktını platform 2'ye"
echo "    düşürür ⇒ path_provider ölür ⇒ 'kaydetmiyor' gibi görünen SAHTE bir"
echo "    ürün kusuru üretir. Simülatörde ölçüm yapacaksan ÖNCE:"
echo "      # ⛔ flutter clean TEK BAŞINA YETMEZ (H-14, Ostinato O-137 ölçtü):"
echo "      #   build/ bir SYMLINK (iCloud panzehiri) ⇒ clean yalnız BAĞLANTIYI siler,"
echo "      #   hedefteki zehirli artefakta HİÇ DOKUNMAZ. İki panzehir birbirini kesiyor."
echo "      rm -rf \"\$(readlink build)/native_assets/ios\"   # ← ASIL TEMİZLİK: symlink HEDEFİ"
echo "      flutter clean && ln -s <hedef> build && flutter run -d <sim>"
echo "    Ve güvenmeden ÖNCE doğrula (beyan değil, ölçüm):"
echo "      vtool -show-build \"\$(xcrun simctl get_app_container <UDID> $BUNDLE app)/Frameworks/objective_c.framework/objective_c\" | grep platform"
echo "    platform IOSSIMULATOR görmeden zehri gitmiş SAYMA — o koşumdaki hiçbir"
echo "    kalıcılık gözlemi geçerli değildir."
