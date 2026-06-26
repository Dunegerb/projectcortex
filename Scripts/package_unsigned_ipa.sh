python3 Scripts/verify_app_icon.py
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

# Ensure project generation did not overwrite the static source Info.plist.
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
print(f"Source launch metadata confirmed in: {plist_path}")
PY

rm -rf "$DERIVED_DATA" "$PAYLOAD_DIR" "$IPA_PATH" "$CHECKSUM_PATH"
mkdir -p "$ROOT/build"

# Build the real source project for physical iPhone (arm64), with signing fully
# disabled. The dedicated Unsigned configuration also prevents provisioning
# settings from leaking in from the signed Release configuration.
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

# Xcode should install these through the target build phase. Copy them again
# here as a deterministic packaging safeguard, because the unsigned IPA is
# assembled after the build and has not been code-signed.
"$ROOT/Scripts/copy_kundalini_resources.sh" "$APP_PATH"

for resource in ChakraExperience.html personkundalini.svg; do
  if [[ ! -s "$APP_PATH/$resource" ]]; then
    echo "Erro: recurso Kundalini ausente no bundle final: $resource" >&2
    exit 1
  fi
done

# XcodeGen must use the repository plist as-is. As a final packaging safeguard,
# enforce the native launch-screen metadata in the processed app plist too.
# This is safe here because the output is intentionally unsigned.
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

with plist_path.open("wb") as handle:
    plistlib.dump(info, handle, fmt=plistlib.FMT_BINARY, sort_keys=False)

print(f"Launch metadata confirmed in: {plist_path}")
PY

# A build without signing normally has no signature, but remove any accidental
# leftovers before packaging so the output is unambiguously unsigned.
find "$APP_PATH" -type d -name '_CodeSignature' -prune -exec rm -rf {} +
find "$APP_PATH" -type f \( -name 'CodeResources' -o -name 'embedded.mobileprovision' \) -delete

mkdir -p "$PAYLOAD_DIR"
ditto "$APP_PATH" "$PAYLOAD_DIR/Cortex.app"

(
  cd "$ROOT/build"
  /usr/bin/zip -qry -y "$(basename "$IPA_PATH")" Payload
)

shasum -a 256 "$IPA_PATH" > "$CHECKSUM_PATH"
printf 'Gerado automaticamente: %s\n' "$IPA_PATH"
printf 'SHA-256: %s\n' "$CHECKSUM_PATH"
