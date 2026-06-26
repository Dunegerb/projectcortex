#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/Scripts/remove_legacy_brain.sh"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

export CORTEX_TEAM_ID="${CORTEX_TEAM_ID:-}"
export CORTEX_APP_BUNDLE_ID="${CORTEX_APP_BUNDLE_ID:-com.seudominio.cortex}"
export CORTEX_WIDGET_BUNDLE_ID="${CORTEX_WIDGET_BUNDLE_ID:-com.seudominio.cortex.widget}"
export CORTEX_APP_GROUP="${CORTEX_APP_GROUP:-group.com.seudominio.cortex}"
export CORTEX_APP_PROFILE="${CORTEX_APP_PROFILE:-}"
export CORTEX_WIDGET_PROFILE="${CORTEX_WIDGET_PROFILE:-}"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen não encontrado. Instale com: brew install xcodegen" >&2
  exit 1
fi

xcodegen generate
printf '\nProjeto gerado: %s/Cortex.xcodeproj\n' "$ROOT"
printf 'Abra com: open Cortex.xcodeproj\n'
