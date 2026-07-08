#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT/build/unsigned"
PAYLOAD_DIR="$ROOT/build/Payload"
IPA_PATH="$ROOT/build/Cortex-unsigned-fullscreen.ipa"
CHECKSUM_PATH="$IPA_PATH.sha256"

cd "$ROOT"
"$ROOT/Scripts/remove_legacy_brain.sh"
"$ROOT/Scripts/bootstrap.sh"
python3 "$ROOT/Scripts/verify_design_system.py"
python3 "$ROOT/Scripts/verify_native_keyboard.py"
python3 "$ROOT/Scripts/verify_transmutation_home.py"
python3 "$ROOT/Scripts/verify_splash_animation.py"
python3 "$ROOT/Scripts/verify_app_icon.py"
python3 "$ROOT/Scripts/verify_xcode_project_resources.py"

python3 - "$ROOT/Config/Cortex-Info.plist" <<'PY'
import plistlib
import sys
from pathlib import Path

plist_path = Path(sys.argv[1])
with plist_path.open("rb") as handle:
    info = plistlib.load(handle)
launch = info.get("UILaunchScreen")
if not isinstance(launch, dict):
    raise SystemExit("Erro: UILaunchScreen ausente em Config/Cortex-Info.plist após o XcodeGen")
if launch.get("UIColorName") != "LaunchBackground" or launch.get("UIImageName") != "LaunchMark":
    raise SystemExit("Erro: configuração UILaunchScreen inválida no plist-fonte")
icons = info.get("CFBundleIcons", {}).get("CFBundlePrimaryIcon", {})
if icons.get("CFBundleIconName") != "CortexAppIcon":
    raise SystemExit("Erro: CFBundleIconName não aponta para CortexAppIcon no plist-fonte")
print(f"Source launch and app-icon metadata confirmed in: {plist_path}")
PY

rm -rf "$DERIVED_DATA" "$PAYLOAD_DIR" "$IPA_PATH" "$CHECKSUM_PATH"
mkdir -p "$ROOT/build"

xcodebuild \
  -project Cortex.xcodeproj \
  -scheme Cortex \
  -configuration Unsigned \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  EXPANDED_CODE_SIGN_IDENTITY='' \
  DEVELOPMENT_TEAM='' \
  PROVISIONING_PROFILE_SPECIFIER='' \
  ASSETCATALOG_COMPILER_APPICON_NAME=CortexAppIcon \
  ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS=YES \
  ONLY_ACTIVE_ARCH=NO \
  build

PRODUCTS_DIR="$DERIVED_DATA/Build/Products/Unsigned-iphoneos"
APP_PATH="$PRODUCTS_DIR/Cortex.app"
if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH="$(find "$DERIVED_DATA/Build/Products" -type d -name 'Cortex.app' -print -quit)"
fi
if [[ -z "${APP_PATH:-}" || ! -d "$APP_PATH" ]]; then
  echo "Erro: Cortex.app não encontrado após o build." >&2
  exit 1
fi

"$ROOT/Scripts/copy_kundalini_resources.sh" "$APP_PATH"
"$ROOT/Scripts/install_app_icon_fallback.sh" "$APP_PATH"
"$ROOT/Scripts/compile_asset_catalog.sh" "$APP_PATH"

for resource in ChakraExperience.html personkundalini.svg CortexSplashIntro.mp4; do
  if [[ ! -s "$APP_PATH/$resource" ]]; then
    echo "Erro: recurso de runtime ausente no bundle final: $resource" >&2
    exit 1
  fi
done

if [[ ! -s "$APP_PATH/Assets.car" ]]; then
  echo "Erro: Assets.car não foi gerado; o catálogo CortexAppIcon não foi compilado." >&2
  exit 1
fi

python3 - "$APP_PATH/Info.plist" <<'PY'
import plistlib
import sys
from pathlib import Path

plist_path = Path(sys.argv[1])
with plist_path.open("rb") as handle:
    info = plistlib.load(handle)

info["UILaunchScreen"] = {
    "UIColorName": "LaunchBackground",
    "UIImageName": "LaunchMark",
    "UIImageRespectsSafeAreaInsets": True,
}
info["UIRequiresFullScreen"] = True
primary = info.setdefault("CFBundleIcons", {}).setdefault("CFBundlePrimaryIcon", {})
primary["CFBundleIconName"] = "CortexAppIcon"
primary["CFBundleIconFiles"] = ["CortexIcon20x20", "CortexIcon29x29", "CortexIcon40x40", "CortexIcon60x60"]
info["CFBundleIconName"] = "CortexAppIcon"
info["CFBundleIconFiles"] = ["CortexIcon20x20", "CortexIcon29x29", "CortexIcon40x40", "CortexIcon60x60"]

with plist_path.open("wb") as handle:
    plistlib.dump(info, handle, fmt=plistlib.FMT_BINARY, sort_keys=False)

print(f"Launch and app-icon metadata confirmed in: {plist_path}")
PY

find "$APP_PATH" -type d -name '_CodeSignature' -prune -exec rm -rf {} +
find "$APP_PATH" -type f \( -name 'CodeResources' -o -name 'embedded.mobileprovision' \) -delete

mkdir -p "$PAYLOAD_DIR"
ditto "$APP_PATH" "$PAYLOAD_DIR/Cortex.app"
(
  cd "$ROOT/build"
  /usr/bin/zip -qry -y "$(basename "$IPA_PATH")" Payload
)

python3 "$ROOT/Scripts/verify_unsigned_ipa.py" "$IPA_PATH"
shasum -a 256 "$IPA_PATH" > "$CHECKSUM_PATH"
printf 'Gerado automaticamente: %s\n' "$IPA_PATH"
printf 'SHA-256: %s\n' "$CHECKSUM_PATH"
