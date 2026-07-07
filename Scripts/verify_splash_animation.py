#!/usr/bin/env python3
"""Validate the supplied two-frame startup animation and launch-screen bridge."""

from __future__ import annotations

import hashlib
import json
import re
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SWIFT = ROOT / "CortexApp" / "Features" / "Launch" / "SplashAnimationView.swift"
APP_ROOT = ROOT / "CortexApp" / "AppRootView.swift"
ASSETS = ROOT / "CortexApp" / "Resources" / "Assets.xcassets"
DESIGN = ROOT / "CortexApp" / "Resources" / "DesignSource" / "LaunchAnimation"
LAUNCH_MARK = ASSETS / "LaunchMark.imageset"
PROJECT = ROOT / "project.yml"

SVG_NS = {"svg": "http://www.w3.org/2000/svg"}
EXPECTED_SOURCE_HASHES = {
    "Frame1/glasslogo.svg": "5a6bcaf728666771f8eaa131ec59289d549d7dd1bd48cca6830e2ca0441815ce",
    "Frame1/iconlogo.svg": "8148bb73ba70118810544a158175b78684d0bb2b0c08ced4c53e65a2ba9080db",
    "Frame1/lightsbackground.svg": "b95d40f1420368a78a1dd3c3eccea3d2f7ec2223638fc7267164093b70fa5a1b",
    "Frame1/textlogo.svg": "eb136ebb6a2ad6b26082e6118868f1342558c07e31526013d7e8ef35573c658c",
    "Frame2/glasslogo.svg": "5a6bcaf728666771f8eaa131ec59289d549d7dd1bd48cca6830e2ca0441815ce",
    "Frame2/iconlogo.svg": "47cecf5debd3fe0c7e423ea855aef7e6fbf6106afd43eb37611ff750f7e11e08",
    "Frame2/lightsbackground.svg": "a5ae23ff93c75c999e853a2da751f82a7d152ef7b649f7ef4ec82ed47091ce2e",
    "Frame2/textlogo.svg": "19ac3dc5c2026c25031b9bea4e2535b961aafe41186482485a72a54380a78e60",
    "frame-1-reference.svg": "ad37131ffdfb00e22868dd78229e8dfffcbb3bce0b45260e866183f9ac42bc89",
    "frame-2-reference.svg": "4e335dd95d8ece2a91d9468815c4b5b6e516c822883c82077a90d6996281e3c4",
}


def fail(message: str) -> None:
    print(f"splash animation verification failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, token: str, location: str) -> None:
    if token not in text:
        fail(f"missing {token!r} in {location}")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def svg_metadata(path: Path) -> tuple[int, int, int, ET.Element]:
    if not path.is_file() or path.stat().st_size < 200:
        fail(f"missing or empty SVG: {path.relative_to(ROOT)}")
    root = ET.parse(path).getroot()
    try:
        width = int(float(root.attrib["width"]))
        height = int(float(root.attrib["height"]))
    except (KeyError, ValueError) as error:
        fail(f"invalid SVG dimensions in {path.relative_to(ROOT)}: {error}")
    paths = root.findall(".//svg:path", SVG_NS)
    return width, height, len(paths), root


def verify_vector_asset(name: str, expected_size: tuple[int, int], expected_paths: int) -> ET.Element:
    imageset = ASSETS / f"{name}.imageset"
    manifest = imageset / "Contents.json"
    svg = imageset / f"{name}.svg"
    if not manifest.is_file():
        fail(f"missing asset manifest for {name}")
    data = json.loads(manifest.read_text(encoding="utf-8"))
    if data.get("properties", {}).get("preserves-vector-representation") is not True:
        fail(f"{name} must preserve its vector representation")
    images = data.get("images", [])
    if not any(image.get("filename") == svg.name for image in images):
        fail(f"{name} manifest does not reference {svg.name}")
    width, height, paths, root = svg_metadata(svg)
    if (width, height) != expected_size:
        fail(f"unexpected {name} dimensions: {width}x{height}")
    if paths != expected_paths:
        fail(f"unexpected {name} path count: {paths}")
    return root


def verify_png(path: Path, expected_size: tuple[int, int]) -> None:
    raw = path.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n" or raw[12:16] != b"IHDR":
        fail(f"{path.relative_to(ROOT)} is not a PNG")
    width, height = struct.unpack(">II", raw[16:24])
    if (width, height) != expected_size:
        fail(f"unexpected dimensions for {path.name}: {width}x{height}")
    color_type = raw[25]
    if color_type not in (4, 6):
        fail(f"{path.name} must retain transparency to bridge into the animated frame")


def main() -> int:
    for relative, expected_hash in EXPECTED_SOURCE_HASHES.items():
        source = DESIGN / relative
        if not source.is_file():
            fail(f"missing supplied design source: {relative}")
        if sha256(source) != expected_hash:
            fail(f"supplied design source changed unexpectedly: {relative}")

    frame1_size = svg_metadata(DESIGN / "frame-1-reference.svg")[:2]
    frame2_size = svg_metadata(DESIGN / "frame-2-reference.svg")[:2]
    if frame1_size != (739, 1600) or frame2_size != (739, 1600):
        fail(f"reference frames must remain 739x1600, got {frame1_size} and {frame2_size}")

    glass = verify_vector_asset("SplashGlassLogoMask", (442, 298), 6)
    text = verify_vector_asset("SplashTextLogo", (131, 88), 6)
    icon = verify_vector_asset("SplashIconLogo", (164, 131), 26)

    for path in glass.findall(".//svg:path", SVG_NS):
        if path.attrib.get("fill-opacity") is not None:
            fail("glass mask must be fully opaque; visual opacity belongs in SwiftUI")
        if path.attrib.get("fill") != "#FFFFFF":
            fail("glass mask paths must be white")
    if any(path.attrib.get("fill") != "#F1F1F1" for path in text.findall(".//svg:path", SVG_NS)):
        fail("text logo asset no longer matches frame 1")
    if any(path.attrib.get("fill") != "#F1F1F1" for path in icon.findall(".//svg:path", SVG_NS)):
        fail("icon logo asset no longer matches frame 2")

    launch_manifest = json.loads((LAUNCH_MARK / "Contents.json").read_text(encoding="utf-8"))
    expected_launch = {
        "LaunchMark@1x.png": (256, 256),
        "LaunchMark@2x.png": (512, 512),
        "LaunchMark@3x.png": (768, 768),
    }
    referenced = {item.get("filename") for item in launch_manifest.get("images", [])}
    if referenced != set(expected_launch):
        fail(f"unexpected LaunchMark manifest entries: {sorted(referenced)}")
    for filename, size in expected_launch.items():
        verify_png(LAUNCH_MARK / filename, size)

    swift = SWIFT.read_text(encoding="utf-8")
    app_root = APP_ROOT.read_text(encoding="utf-8")
    project = PROJECT.read_text(encoding="utf-8")

    for token in (
        "static let canvasWidth: CGFloat = 739",
        "static let canvasHeight: CGFloat = 1600",
        "CGSize(width: 131, height: 88)",
        "CGSize(width: 29, height: 19)",
        "CGSize(width: 66, height: 53)",
        "CGSize(width: 164, height: 131)",
        "static let transitionNanoseconds: UInt64 = 800_000_000",
        ".timingCurve(",
        "1,\n                    0.01,\n                    0,\n                    0.99,",
        'Image("SplashTextLogo")',
        'Image("SplashIconLogo")',
        'Image("SplashGlassLogoMask")',
        ".fill(.ultraThinMaterial)",
        "@Environment(\\.accessibilityReduceMotion)",
        "screenOpacity = 0",
    ):
        require(swift, token, "SplashAnimationView.swift")

    for token in (
        "@State private var isShowingSplash = true",
        "if isShowingSplash",
        "SplashAnimationView",
        "isShowingSplash = false",
        ".zIndex(100)",
    ):
        require(app_root, token, "AppRootView.swift")

    if not re.search(r"CURRENT_PROJECT_VERSION:\s*21", project):
        fail("CURRENT_PROJECT_VERSION must be 21")
    if not re.search(r"MARKETING_VERSION:\s*1\.2\.7", project):
        fail("MARKETING_VERSION must be 1.2.7")

    print("Verified the 800 ms two-frame glass startup animation and launch-screen bridge.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
