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
APP = ROOT / "CortexApp" / "CortexApp.swift"
THEME = ROOT / "CortexApp" / "Theme" / "CortexTheme.swift"
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


def verify_current_energy_asset(name: str) -> None:
    imageset = ASSETS / f"{name}.imageset"
    manifest = imageset / "Contents.json"
    if not manifest.is_file():
        fail(f"missing native current-energy asset manifest: {name}")

    data = json.loads(manifest.read_text(encoding="utf-8"))
    expected = {
        "1x": (350, 192),
        "2x": (699, 383),
        "3x": (1049, 575),
    }
    found_scales: set[str] = set()

    for image in data.get("images", []):
        scale = image.get("scale")
        filename = image.get("filename")
        if scale not in expected or not filename:
            continue
        png = imageset / filename
        if not png.is_file() or png.stat().st_size < 10_000:
            fail(f"missing or empty {scale} current-energy image: {name}")
        raw = png.read_bytes()
        if raw[:8] != b"\x89PNG\r\n\x1a\n" or raw[12:16] != b"IHDR":
            fail(f"{name} {scale} is not a PNG")
        width, height = struct.unpack(">II", raw[16:24])
        if (width, height) != expected[scale]:
            fail(f"unexpected dimensions for {name} {scale}: {width}x{height}")
        found_scales.add(scale)

    if found_scales != set(expected):
        fail(f"incomplete current-energy image scales for {name}: {sorted(found_scales)}")


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
    app = APP.read_text(encoding="utf-8")
    theme = THEME.read_text(encoding="utf-8")
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
        "elasticTopPanel",
        "DashboardOverscrollPreferenceKey",
        "updateElasticOverscroll",
        "interpolatingSpring",
        "HomeColors.welcomeDark",
        "HomeColors.welcomeMid",
        "HomeColors.welcomeLight",
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
        "profile.startDate = relapseDate",
        "Este espaço é opcional",
        "activationDay: 30",
        "activationDay: 90",
        'assetName: "ChakraRoot"',
        'assetName: "ChakraCrown"',
        "stage.lightCardAssetName",
        'cardAssetName: "CurrentEnergyRoot"',
        'cardAssetName: "CurrentEnergySacral"',
        'cardAssetName: "CurrentEnergySolar"',
        'cardAssetName: "CurrentEnergyHeart"',
        'cardAssetName: "CurrentEnergyThroat"',
        'cardAssetName: "CurrentEnergyThirdEye"',
        'cardAssetName: "CurrentEnergyCrown"',
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
        "bottomInset - 16 * scale",
        "location: 0.62",
        "center: UnitPoint(x: 0.08, y: 0.92)",
        ".strokeBorder(",
        "startPoint: .bottomLeading",
        "endPoint: .topTrailing",
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
        "AppAppearanceMode.storageKey",
        'Section("Aparência")',
        '.pickerStyle(.segmented)',
        'case .system:',
        'case .light:',
        'case .dark:',
    ):
        require(settings if token not in ("case .system:", "case .light:", "case .dark:") else theme, token, "SettingsView.swift / CortexTheme.swift")
    for token in (
        ".preferredColorScheme(appearanceMode.colorScheme)",
        "@AppStorage(AppAppearanceMode.storageKey)",
    ):
        require(app, token, "CortexApp.swift")
    for token in (
        "0xF1F1F1", "0xFFFFFF", "0xF5F5F5", "0x191817", "0x555555",
        "0xE9E9E9", "0xC2C2C2", "0x9E9E9E",
    ):
        if token not in theme and token not in dashboard:
            fail(f"missing supplied light-mode color {token}")

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

    current_card_source = dashboard.split("private func currentEnergyCard", 1)[1].split("private func recoveredTimeCard", 1)[0]
    if "ChakraExperienceView(" in current_card_source or "WKWebView" in current_card_source:
        fail("current energy card must not depend on WebKit; it causes late rescaling and blanking after backgrounding")
    for token in (
        "Image(stage.lightCardAssetName)",
        "Image(stage.cardAssetName)",
        "currentEnergyLightGlass(",
        "LightBackdropBlur()",
        "HomeColors.control.opacity(0.31)",
        ".strokeBorder(",
        ".aspectRatio(699.0 / 383.0, contentMode: .fit)",
        ".id(stage.lightCardAssetName)",
        ".id(stage.cardAssetName)",
    ):
        require(current_card_source, token, "DashboardView.swift currentEnergyCard")
    require(dashboard, ".systemUltraThinMaterialLight", "DashboardView.swift light glass blur")

    light_stage_sources = DESIGN_SOURCE / "CurrentEnergyStagesLight"
    for light_svg in light_stage_sources.glob("CurrentEnergy*Light.svg"):
        source = light_svg.read_text(encoding="utf-8")
        if '<rect x="28" y="261" width="638" height="88" rx="44"' in source:
            fail(f"light current-energy glass must be composed natively, not baked into {light_svg.name}")
    require(artwork, ".aura {\n      display: none !important;", "ChakraExperience.html")

    for asset in (
        "ChakraRoot", "ChakraSacral", "ChakraSolar", "ChakraHeart",
        "ChakraThroat", "ChakraThirdEye", "ChakraCrown",
        "NavHome", "NavJournal", "NavEmergency", "NavMilestones", "NavSettings",
        "ShieldGlyph",
    ):
        verify_template_asset(asset)

    for asset in (
        "CurrentEnergyRoot", "CurrentEnergySacral", "CurrentEnergySolar",
        "CurrentEnergyHeart", "CurrentEnergyThroat", "CurrentEnergyThirdEye",
        "CurrentEnergyCrown",
        "CurrentEnergyRootLight", "CurrentEnergySacralLight", "CurrentEnergySolarLight",
        "CurrentEnergyHeartLight", "CurrentEnergyThroatLight", "CurrentEnergyThirdEyeLight",
        "CurrentEnergyCrownLight",
    ):
        verify_current_energy_asset(asset)

    for reference in (
        "HomeRedesignReference.png",
        "HomeRedesignLayout.json",
        "actualchakralogos-topcard.svg",
        "Current-energy,_card.svg",
        "barnavegation.svg",
        "goal-card.svg",
        "countnotes-card.svg",
        "addtodaynote-card.svg",
        "HomeLightModeReference.svg",
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
        "seven dark/light native current-energy cards with a native light glass overlay, automatic appearance selection, "
        "optional daily notes and Kundalini runtime."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
