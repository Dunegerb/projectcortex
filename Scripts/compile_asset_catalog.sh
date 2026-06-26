#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 /caminho/Cortex.app" >&2
  exit 64
fi

APP_PATH="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CATALOG="$ROOT/CortexApp/Resources/Assets.xcassets"
PARTIAL_PLIST="$(mktemp -t cortex-actool.XXXXXX).plist"
trap 'rm -f "$PARTIAL_PLIST"' EXIT

if [[ ! -d "$APP_PATH" ]]; then
  echo "Erro: bundle do app não encontrado: $APP_PATH" >&2
  exit 1
fi
if [[ ! -d "$CATALOG/AppIcon.appiconset" ]]; then
  echo "Erro: catálogo AppIcon ausente: $CATALOG" >&2
  exit 1
fi
if ! command -v xcrun >/dev/null 2>&1; then
  echo "Erro: xcrun não está disponível para compilar o catálogo de assets." >&2
  exit 1
fi

# Normalmente o Xcode cria Assets.car. Esta etapa é uma proteção para builds
# unsigned em que a fase de recursos tenha sido omitida por uma geração antiga.
if [[ -s "$APP_PATH/Assets.car" ]]; then
  echo "Assets.car já foi compilado pelo Xcode: $APP_PATH/Assets.car"
  exit 0
fi

echo "Compilando Assets.xcassets com actool..."
xcrun actool "$CATALOG" \
  --compile "$APP_PATH" \
  --output-format human-readable-text \
  --notices \
  --warnings \
  --platform iphoneos \
  --minimum-deployment-target 17.0 \
  --target-device iphone \
  --app-icon AppIcon \
  --accent-color AccentColor \
  --compress-pngs \
  --enable-on-demand-resources NO \
  --development-region pt_BR \
  --output-partial-info-plist "$PARTIAL_PLIST"

if [[ ! -s "$APP_PATH/Assets.car" ]]; then
  echo "Erro: actool terminou sem produzir Assets.car." >&2
  exit 1
fi

# Mescla as chaves produzidas pelo actool sem apagar os metadados existentes.
python3 - "$APP_PATH/Info.plist" "$PARTIAL_PLIST" <<'PY'
import plistlib
import sys
from pathlib import Path

app_plist = Path(sys.argv[1])
partial_plist = Path(sys.argv[2])

with app_plist.open('rb') as f:
    app = plistlib.load(f)
with partial_plist.open('rb') as f:
    partial = plistlib.load(f)

for key, value in partial.items():
    app[key] = value

with app_plist.open('wb') as f:
    plistlib.dump(app, f, fmt=plistlib.FMT_BINARY, sort_keys=False)
PY

echo "Catálogo compilado manualmente em: $APP_PATH"
