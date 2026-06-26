#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="${1:-}"

if [[ -z "$DESTINATION" ]]; then
  echo "Uso: $0 <diretorio-de-recursos-do-app>" >&2
  exit 64
fi

mkdir -p "$DESTINATION"

for resource in ChakraExperience.html personkundalini.svg; do
  source_path="$ROOT/CortexApp/Resources/$resource"
  destination_path="$DESTINATION/$resource"

  if [[ ! -s "$source_path" ]]; then
    echo "Erro: recurso Kundalini ausente ou vazio: $source_path" >&2
    exit 1
  fi

  /usr/bin/install -m 0644 "$source_path" "$destination_path"

  if [[ ! -s "$destination_path" ]]; then
    echo "Erro: não foi possível instalar o recurso: $destination_path" >&2
    exit 1
  fi

done

printf 'Kundalini resources installed in: %s\n' "$DESTINATION"
