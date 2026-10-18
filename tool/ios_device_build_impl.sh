#!/bin/bash
# Implementation called by ios_device_build.sh while its shared lease is held.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

HEDEF_CIHAZ="${1:-}"
XCCONFIG="ios/Flutter/Generated.xcconfig"
# The public wrapper holds the shared machine lease throughout this process.
python3 - <<'FD'
import os
os.fstat(int(os.environ['JABLAB_NATIVE_LEASE_FD']))
FD
DEFINES="${JABLAB_PUBLIC_DEFINES_FILE:?Set the path to the existing approved public config JSON}"
BUILD_NUMBER="${JABLAB_BUILD_NUMBER:-3}"
[[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]] || { echo "Invalid build number"; exit 2; }
CIKTI="$(mktemp -d "${TMPDIR:-/tmp}/jablab-ios-dd.XXXXXX")"
python3 "$ROOT/tool/prepare_store_packet.py" --validate-config "$DEFINES" > "$CIKTI/public-config-receipt.json"
echo "owned output: $CIKTI"
# Always restore the production entry point and approved config. Merely seeing
# lib/main.dart in an older generated file does not validate its defines.
flutter build ios --config-only --release --no-pub --no-codesign \
  --target lib/main.dart --build-name 1.0.0 --build-number "$BUILD_NUMBER" \
  --dart-define-from-file="$DEFINES" > "$CIKTI/config-only.log" 2>&1

# ── KAPI 1/3 — FLUTTER_TARGET zehirlenmesi ────────────────────────────────
# Bu dosya .gitignore'da: taze klonda YOKTUR. "Yok" bir kusur değil, ama
# SESSİZ geçilmemeli — hangi dalda olduğumuz HER koşumda basılır (vakumun
# panzehiri: susmak değil, saymak).
echo "kapı 1/3: FLUTTER_TARGET zehirlenmesi…"
if [ ! -f "$XCCONFIG" ]; then
  echo "  dal: xcconfig YOK (taze ağaç) — üretiliyor"
  echo "Generated config missing after explicit config step"; exit 1
else
  ONCE="$(grep '^FLUTTER_TARGET=' "$XCCONFIG" || true)"
  echo "  dal: xcconfig VAR → ${ONCE:-<FLUTTER_TARGET satırı yok>}"
  if [ "$ONCE" != "FLUTTER_TARGET=lib/main.dart" ]; then
    echo "  🔴 ZEHİRLİ ya da beklenmedik hedef — yeniden üretiliyor"
    echo "Explicit production target was not retained"; exit 1
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
test -d "$CIKTI" # Fresh owned output; no deletion of shared paths.
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath "$CIKTI" \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=T5HZGYBWK8 build > "$CIKTI.log" 2>&1
echo "  ✅ xcodebuild exit 0"

APP="$CIKTI/Build/Products/Release-iphoneos/Runner.app"
# Build success is not signature, version or source-asset acceptance.
codesign --verify --deep --strict "$APP" > "$CIKTI/signature-verify.log" 2>&1
python3 - "$APP/Info.plist" "$BUILD_NUMBER" <<'VERSION'
import plistlib,sys
with open(sys.argv[1],'rb') as f:p=plistlib.load(f)
if p.get('CFBundleIdentifier')!='com.yulalab.jablab' or p.get('CFBundleShortVersionString')!='1.0.0' or p.get('CFBundleVersion')!=sys.argv[2]:
    raise SystemExit('Artifact identity/version/build mismatch')
VERSION


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
for f in content/library.json content/curriculum.json content/solo_boxing_course.v1.json motion_content/manifest.json rulesets/boxing@1.0.0.json models/pose_landmarker_full.v1.task; do
  if [ ! -f "$VARLIK/$f" ]; then
    echo "🔴 KAPI 2/3 DÜŞTÜ: JabLab'e özgü varlık eksik: $f"; exit 1
  fi
done
python3 - "$ROOT" "$VARLIK" <<'ASSETS'
from pathlib import Path
import hashlib,sys
root,assets=map(Path,sys.argv[1:])
for relative in ['content/library.json','content/solo_boxing_course.v1.json','motion_content/manifest.json','rulesets/boxing@1.0.0.json','models/pose_landmarker_full.v1.task']:
    if hashlib.sha256((root/'assets'/relative).read_bytes()).digest()!=hashlib.sha256((assets/relative).read_bytes()).digest():
        raise SystemExit('Artifact asset/source mismatch: '+relative)
ASSETS
echo "  ✅ bundle=$BUNDLE · Dart anlık görüntüsü=$BOYUT bayt · JabLab varlıkları yerinde"

# ── KAPI 3/3 — KURULABİLİRLİK (derlenebilirlikten AYRI eksen) ─────────────
# H-6 dersi: kapsama İKİ EKSENLİDİR. Bundle-ID ekseni imzada bağlar,
# CİHAZ ekseni yalnız KURULUMDA bağlar. Yeşil bir derleme, kurulamayan bir
# profille tamamen tutarlıdır — 08-14'te tam olarak bu ölçüldü.
echo "kapı 3/3: gömülü profilin cihaz ekseni…"
PROF="$CIKTI/embedded-profile.plist"
security cms -D -i "$APP/embedded.mobileprovision" > "$PROF"
PROF_AD="$(plutil -extract Name raw -o - "$PROF")"
echo "  profil: $PROF_AD"

if [ -n "$HEDEF_CIHAZ" ]; then
  if python3 - "$PROF" "$HEDEF_CIHAZ" <<'DEVICE'
import plistlib,sys
with open(sys.argv[1],'rb') as f:p=plistlib.load(f)
raise SystemExit(0 if sys.argv[2] in p.get('ProvisionedDevices',[]) else 1)
DEVICE
  then
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
echo "⚠️ Device and simulator native-asset builds are separate acceptance paths."
echo "    A later simulator check needs an approved fresh rebuild under the shared lease."
echo "    Do not delete existing simulator devices or another job's build/cache paths."
