#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LEGACY_BRAIN="$ROOT/CortexApp/Features/Dashboard/BrainSceneView.swift"

# Some users replace the project files without cloning the repository first.
# In that workflow, Git can leave an old tracked source behind on GitHub.
# Remove it before XcodeGen scans CortexApp, so the deprecated SceneKit brain
# can never be included in the generated project or unsigned IPA.
if [[ -e "$LEGACY_BRAIN" ]]; then
  rm -f "$LEGACY_BRAIN"
  printf 'Removed legacy dashboard source: %s\n' "$LEGACY_BRAIN"
else
  printf 'Legacy 3D brain source is already absent.\n'
fi
