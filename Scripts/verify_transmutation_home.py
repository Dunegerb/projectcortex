#!/usr/bin/env python3
"""Validate the automatic day counter and Kundalini Home assets."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DASHBOARD = ROOT / "CortexApp" / "Features" / "Dashboard" / "DashboardView.swift"
ENGINE = ROOT / "CortexApp" / "Core" / "Engines" / "RecoveryEngine.swift"
SETTINGS = ROOT / "CortexApp" / "Features" / "Settings" / "SettingsView.swift"
WEB_VIEW = ROOT / "CortexApp" / "Features" / "Dashboard" / "ChakraExperienceView.swift"
ARTWORK = ROOT / "CortexApp" / "Resources" / "ChakraExperience.html"
SOURCE_SVG = ROOT / "CortexApp" / "Resources" / "personkundalini.svg"
FALLBACK_SVG = (
    ROOT
    / "CortexApp"
    / "Resources"
    / "Assets.xcassets"
    / "KundaliniPerson.imageset"
    / "KundaliniPerson.svg"
)
BRAIN = ROOT / "CortexApp" / "Features" / "Dashboard" / "BrainSceneView.swift"
PROJECT = ROOT / "project.yml"
PACKAGER = ROOT / "Scripts" / "package_unsigned_ipa.sh"
RESOURCE_INSTALLER = ROOT / "Scripts" / "copy_kundalini_resources.sh"


def fail(message: str) -> None:
    print(f"transmutation verification failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, token: str, location: str) -> None:
    if token not in text:
        fail(f"missing {token!r} in {location}")


def main() -> int:
    if BRAIN.exists():
        fail("legacy BrainSceneView.swift still exists; run Scripts/remove_legacy_brain.sh")

    for path, minimum_size in (
        (ARTWORK, 50_000),
        (SOURCE_SVG, 50_000),
        (FALLBACK_SVG, 50_000),
    ):
        if not path.is_file() or path.stat().st_size < minimum_size:
            fail(f"required Kundalini resource is missing or incomplete: {path}")

    dashboard = DASHBOARD.read_text(encoding="utf-8")
    for legacy_token in ("BrainSceneView(", "import SceneKit", "SCNView"):
        if legacy_token in dashboard:
            fail(f"legacy 3D brain reference remains in DashboardView.swift: {legacy_token}")
    engine = ENGINE.read_text(encoding="utf-8")
    settings = SETTINGS.read_text(encoding="utf-8")
    web_view = WEB_VIEW.read_text(encoding="utf-8")
    artwork = ARTWORK.read_text(encoding="utf-8")
    project = PROJECT.read_text(encoding="utf-8")
    packager = PACKAGER.read_text(encoding="utf-8")
    resource_installer = RESOURCE_INSTALLER.read_text(encoding="utf-8")

    for token in (
        "ChakraExperienceView(",
        "day: snapshot.currentDay",
        "TransmutationStage.activeCount",
        "Opcional · não altera sua contagem",
        "profile.startDate = relapseDate",
        "TEMPO RECUPERADO",
        "activationDay: 30",
        "activationDay: 90",
    ):
        require(dashboard, token, "DashboardView.swift")

    for token in (
        "Check-ins are journal",
        "currentStreak: currentDay",
        "now.timeIntervalSince(cycleStart)",
        "profile.dailyUsageMinutes",
    ):
        require(engine, token, "RecoveryEngine.swift")

    require(settings, "Tempo gasto no ato da autosatisfação", "SettingsView.swift")

    for token in (
        "loadHTMLString",
        "KundaliniPerson",
        "cortexReady",
        "window.setCortexDay",
        "ChakraExperience.html",
        "artworkScale: CGFloat = 0.80",
        ".scaleEffect(artworkScale, anchor: .center)",
    ):
        require(web_view, token, "ChakraExperienceView.swift")

    scale_match = re.search(r"artworkScale:\s*CGFloat\s*=\s*([0-9.]+)", web_view)
    if not scale_match or not 0.65 <= float(scale_match.group(1)) <= 0.85:
        fail("Kundalini artwork scale must stay between 0.65 and 0.85")

    for token in (
        "postBuildScripts:",
        "Install Kundalini runtime resources",
        "copy_kundalini_resources.sh",
        "ChakraExperience.html",
        "personkundalini.svg",
    ):
        require(project, token, "project.yml")

    for token in (
        "copy_kundalini_resources.sh",
        '"$APP_PATH"',
        "ChakraExperience.html",
        "personkundalini.svg",
    ):
        require(packager, token, "package_unsigned_ipa.sh")

    for token in (
        "ChakraExperience.html",
        "personkundalini.svg",
        "/usr/bin/install -m 0644",
    ):
        require(resource_installer, token, "copy_kundalini_resources.sh")

    for token in (
        'id="revealRect"',
        "window.setCortexDay",
        "{ name: 'third-eye', day: 30, y: 188 }",
        "{ name: 'crown', day: 90, y: 46 }",
        'data-chakra="root"',
        'data-chakra="third-eye"',
        'data-chakra="crown"',
    ):
        require(artwork, token, "ChakraExperience.html")

    if len(re.findall(r'data-chakra="[^"]+"', artwork)) < 7:
        fail("fewer than seven chakra elements were found")

    print(
        "Verified compact Kundalini artwork, WebKit fallback, day 30 third-eye, "
        "day 90 crown, automatic counting and optional notes."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
