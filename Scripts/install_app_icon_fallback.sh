#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 /caminho/Cortex.app" >&2
  exit 64
fi

APP_PATH="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/CortexApp/Resources/AppIconFallback"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Erro: bundle do app não encontrado: $APP_PATH" >&2
  exit 1
fi

required=(
  CortexIcon20x20@2x.png CortexIcon20x20@3x.png
  CortexIcon29x29@2x.png CortexIcon29x29@3x.png
  CortexIcon40x40@2x.png CortexIcon40x40@3x.png
  CortexIcon60x60@2x.png CortexIcon60x60@3x.png
)

for name in "${required[@]}"; do
  if [[ ! -s "$SOURCE/$name" ]]; then
    echo "Erro: ícone fallback ausente ou vazio: $SOURCE/$name" >&2
    exit 1
  fi
  /usr/bin/ditto "$SOURCE/$name" "$APP_PATH/$name"
done

printf 'Ícones fallback instalados em: %s\n' "$APP_PATH"
