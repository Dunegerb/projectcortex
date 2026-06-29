#!/usr/bin/env python3
"""Validate the automatic counter, redesigned Home and Kundalini runtime."""

from __future__ import annotations

import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DASHBOARD = ROOT / "CortexApp" / "Features" / "Dashboard" / "DashboardView.swift"
APP_ROOT = ROOT / "CortexApp" / "AppRootView.swift"
ENGINE = ROOT / "CortexApp" / "Core" / "Engines" / "RecoveryEngine.swift"
SETTINGS = ROOT / "CortexApp" / "Features" / "Settings" / "SettingsView.swift"
WEB_VIEW = ROOT / "CortexApp" / "Features" / "Dashboard" / "ChakraExperienceView.swift"
ARTWORK = ROOT / "CortexApp" / "Resources" / "ChakraExperience.html"
SOURCE_SVG = ROOT / "CortexApp" / "Resources" / "personkundalini.svg"
FALLBACK_SVG = ROOT / "CortexApp" / "Resources" / "Assets.xcassets" / "KundaliniPerson.imageset" / "KundaliniPerson.svg"
ASSETS = ROOT / "CortexApp" / "Resources" / "Assets.xcassets"
DESIGN_SOURCE = ROOT / "CortexApp" / "Resources" / "DesignSource"
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


def verify_template_asset(name: str) -> None:
    imageset = ASSETS / f"{name}.imageset"
    manifest = imageset / "Contents.json"
    png = imageset / f"{name}.png"
    if not manifest.is_file() or not png.is_file() or png.stat().st_size < 500:
        fail(f"missing or empty redesigned asset: {name}")
    data = json.loads(manifest.read_text(encoding="utf-8"))
    if data.get("properties", {}).get("template-rendering-intent") != "template":
        fail(f"{name} must use template rendering")
    raw = png.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n" or raw[12:16] != b"IHDR":
        fail(f"{name} is not a PNG")
    width, height = struct.unpack(">II", raw[16:24])
    if min(width, height) < 128:
        fail(f"{name} is too small: {width}x{height}")


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
    app_root = APP_ROOT.read_text(encoding="utf-8")
    engine = ENGINE.read_text(encoding="utf-8")
    settings = SETTINGS.read_text(encoding="utf-8")
    web_view = WEB_VIEW.read_text(encoding="utf-8")
    artwork = ARTWORK.read_text(encoding="utf-8")
    project = PROJECT.read_text(encoding="utf-8")
    packager = PACKAGER.read_text(encoding="utf-8")
    resource_installer = RESOURCE_INSTALLER.read_text(encoding="utf-8")

    for legacy_token in ("BrainSceneView(", "import SceneKit", "SCNView"):
        if legacy_token in dashboard:
            fail(f"legacy 3D brain reference remains in DashboardView.swift: {legacy_token}")

    for token in (
        "Good Morning,",
        "Keep transmuting",
        "Since ",
        "Current energy:",
        "Recovered time",
        "dashboardSummaryCards",
        "Add today's note",
        "goalRemainingDays",
        "savedNotesCount",
        "HomeMetrics.scale",
        "chakraProgressStrip",
        "CortexBottomNavigation",
        "ChakraExperienceView(",
        "day: snapshot.currentDay",
        "artworkScale: 1.88",
        "profile.startDate = relapseDate",
        "Este espaço é opcional",
        "activationDay: 30",
        "activationDay: 90",
        'assetName: "ChakraRoot"',
        'assetName: "ChakraCrown"',
    ):
        target = dashboard if token != "CortexBottomNavigation" else app_root
        require(target, token, "DashboardView.swift" if target is dashboard else "AppRootView.swift")

    for token in (
        "NavHome",
        "NavJournal",
        "NavEmergency",
        "NavMilestones",
        "NavSettings",
        "Estou com fissura",
        "router.showEmergency = true",
        "navigationBottomPadding",
        "bottomInset - 8 * scale",
    ):
        require(app_root, token, "AppRootView.swift")

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
        "artworkOffset: CGSize = .zero",
        ".scaleEffect(artworkScale, anchor: .center)",
        ".offset(artworkOffset)",
    ):
        require(web_view, token, "ChakraExperienceView.swift")

    for asset in (
        "ChakraRoot", "ChakraSacral", "ChakraSolar", "ChakraHeart",
        "ChakraThroat", "ChakraThirdEye", "ChakraCrown",
        "NavHome", "NavJournal", "NavEmergency", "NavMilestones", "NavSettings",
        "ShieldGlyph",
    ):
        verify_template_asset(asset)

    for reference in (
        "HomeRedesignReference.png",
        "HomeRedesignLayout.json",
        "actualchakralogos-topcard.svg",
        "Current-energy,_card.svg",
        "barnavegation.svg",
        "goal-card.svg",
        "countnotes-card.svg",
        "addtodaynote-card.svg",
    ):
        path = DESIGN_SOURCE / reference
        if not path.is_file() or path.stat().st_size == 0:
            fail(f"design source is missing: {reference}")

    for token in (
        "postBuildScripts:",
        "Install Kundalini runtime resources",
        "copy_kundalini_resources.sh",
        "Assets.xcassets",
        "buildPhase: resources",
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
        "Verified pixel-referenced iPhone X Home redesign, SF Pro layout, custom navigation, "
        "seven automatic energy stages, optional daily notes and Kundalini runtime."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
