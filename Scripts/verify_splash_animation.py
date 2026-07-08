#!/usr/bin/env python3
"""Verify the native SwiftUI Cortex launch animation and positioning fix."""

from __future__ import annotations

import hashlib
import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SWIFT = ROOT / "CortexApp" / "Features" / "Launch" / "SplashAnimationView.swift"
METAL = ROOT / "CortexApp" / "Features" / "Launch" / "CortexSplashShaders.metal"
APP_ROOT = ROOT / "CortexApp" / "AppRootView.swift"
PROJECT = ROOT / "project.yml"
ASSETS = ROOT / "CortexApp" / "Resources" / "Assets.xcassets"
RESOURCES = ROOT / "CortexApp" / "Resources"
LAUNCH_MARK = ASSETS / "LaunchMark.imageset"

EXPECTED_PNG_SETS = {
    "SplashGlassMask": {
        "size": (442, 298),
        "hashes": {
            1: "d810a69b54d43333f4b06b855d55b0a3463613749b0c91b57d33b969fadb3302",
            2: "76c1b7bd25d4133ddeb77b0dfd538bcdaaf0a914e993177308d4debcc1e37bbb",
            3: "df5eb275412fef5d35b0bab3bab5abe50ced74fa951d11a4b5f734f8a19d56ce",
        },
    },
    "SplashGlassOverlay": {
        "size": (442, 298),
        "hashes": {
            1: "247fb3794fb4369fcbc813194dfc6147d2582dae3f6a732ff216115621288acd",
            2: "385d572619e5889af0fd779d7bdfd8d8b998925122e8080e07953b644a5aaf7d",
            3: "995d135c6e62e5c55b276235f508a253ca3ba7dd92181b8e88d5c2a5c5271ed9",
        },
    },
    "SplashIconLogoStart": {
        "size": (66, 53),
        "hashes": {
            1: "9455852d2526c97271eb848aa82f4181d7eb65572ca25503f4f961eca7c306a7",
            2: "d2ead098c70b7d8ae5ce2c94e4b11009f8ad72bc8692e3b376af9444659923ee",
            3: "29f3c0606841b1c55c3203e65b49ab6a196c6421cb0e7a19df31985bb809d62b",
        },
    },
    "SplashIconLogoEnd": {
        "size": (164, 131),
        "hashes": {
            1: "bccb7248e80e67b90553b61c32e5227b5bf0cfff422128012b9668c2fa8f0d82",
            2: "a5d6050fab4b7b56b40e665835f42cd9765a5d5dc7f582f52506d95579d25428",
            3: "e60690b70ff2bc1642f860fd99b3340851c7fe400a6506ad06ff1a9322e96925",
        },
    },
    "SplashTextLogoStart": {
        "size": (131, 88),
        "hashes": {
            1: "f1c7e8cd1b350ca9266b5261cb2d3333dc57e3300078080ea338e1e57ddb73c2",
            2: "eb73432f5c38bed2ea231e4033c9a7d7015443013fea3ab520d1b7c42b64f69d",
            3: "598055c2339a1abd47cb68565ebf2abc30abcc64518f3d2bb0c57f178bb56ef0",
        },
    },
    "SplashTextLogoEnd": {
        "size": (29, 19),
        "hashes": {
            1: "928fa3d608f081d72d87bfe868083791e6c0c1013aed78df36b7c450be614317",
            2: "3b84f1fe775453d7d37e888d18bb65358966337a1267c279b1b584f044805645",
            3: "d1529a6d69372671b996c79e3698016ad166f65898993d79ad03cd99fea1edcb",
        },
    },
}


def fail(message: str) -> None:
    print(f"splash animation verification failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, token: str, location: str) -> None:
    if token not in text:
        fail(f"missing {token!r} in {location}")


def png_info(path: Path) -> tuple[int, int, int]:
    raw = path.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n" or raw[12:16] != b"IHDR":
        fail(f"{path.relative_to(ROOT)} is not a PNG")
    width, height = struct.unpack(">II", raw[16:24])
    color_type = raw[25]
    return width, height, color_type


def verify_png_set(name: str, metadata: dict[str, object]) -> None:
    directory = ASSETS / f"{name}.imageset"
    manifest_path = directory / "Contents.json"
    if not manifest_path.is_file():
        fail(f"{name}.imageset is missing Contents.json")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    images = manifest.get("images", [])
    expected_names = [f"{name}@{scale}x.png" for scale in (1, 2, 3)]
    actual_names = [item.get("filename") for item in images]
    actual_scales = [item.get("scale") for item in images]
    if actual_names != expected_names or actual_scales != ["1x", "2x", "3x"]:
        fail(f"unexpected Retina manifest for {name}: {images}")

    if list(directory.glob("*.svg")):
        fail(f"runtime SVG remains in {name}.imageset")

    base_width, base_height = metadata["size"]
    hashes = metadata["hashes"]
    for scale in (1, 2, 3):
        path = directory / f"{name}@{scale}x.png"
        if not path.is_file():
            fail(f"missing {path.relative_to(ROOT)}")
        width, height, color_type = png_info(path)
        expected_size = (base_width * scale, base_height * scale)
        if (width, height) != expected_size:
            fail(f"unexpected dimensions for {path.name}: {width}x{height}")
        if color_type not in (4, 6):
            fail(f"{path.name} must preserve transparency")
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != hashes[scale]:
            fail(f"{path.name} differs from the approved rasterized asset")


def verify_launch_mark(path: Path, expected_size: tuple[int, int]) -> None:
    width, height, color_type = png_info(path)
    if (width, height) != expected_size:
        fail(f"unexpected dimensions for {path.name}: {width}x{height}")
    if color_type not in (4, 6):
        fail(f"{path.name} must contain alpha")


def main() -> int:
    for path in (
        RESOURCES / "SplashIntro.html",
        RESOURCES / "Launch" / "CortexSplashIntro.mp4",
    ):
        if path.exists():
            fail(f"legacy splash runtime file still exists: {path.relative_to(ROOT)}")

    movie_files = sorted(
        path.relative_to(ROOT)
        for suffix in ("*.mp4", "*.mov", "*.m4v")
        for path in RESOURCES.rglob(suffix)
    )
    if movie_files:
        fail(f"movie assets are forbidden in the splash implementation: {movie_files}")

    for name, metadata in EXPECTED_PNG_SETS.items():
        verify_png_set(name, metadata)

    swift = SWIFT.read_text(encoding="utf-8")
    metal = METAL.read_text(encoding="utf-8")
    app_root = APP_ROOT.read_text(encoding="utf-8")
    project = PROJECT.read_text(encoding="utf-8")

    for token in (
        "import SwiftUI",
        "static let initialHoldNanoseconds: UInt64 = 900_000_000",
        "static let transitionNanoseconds: UInt64 = 800_000_000",
        "static let finalHoldNanoseconds: UInt64 = 50_000_000",
        "Animation.timingCurve(1, 0.01, 0, 0.99, duration: 0.8)",
        "let viewport = SplashViewport(containerSize: proxy.size)",
        "Self.referenceViewport.width / Self.designSpace.width",
        "Self.referenceViewport.height / Self.designSpace.height",
        "func screenRect(_ rect: SplashRect) -> CGRect",
        "func localRect(_ rect: SplashRect) -> CGRect",
        "func splashFrame(_ rect: CGRect) -> some View",
        ".offset(x: rect.minX, y: rect.minY)",
        "SplashRect(x: 149, y: 651, width: 442, height: 298)",
        "SplashRect(x: 173, y: 680, width: 33, height: 59.627)",
        "SplashRect(x: 479, y: 696, width: 82, height: 62)",
        "SplashRect(x: 173, y: 821.373, width: 33, height: 59.627)",
        "SplashRect(x: 479, y: 843, width: 82, height: 62)",
        "SplashRect(x: 337, y: 774, width: 66, height: 53)",
        "SplashRect(x: 288, y: 735, width: 164, height: 131)",
        "SplashRect(x: 304, y: 756, width: 131, height: 88)",
        "SplashRect(x: 355, y: 790, width: 29, height: 19)",
        ".distortionEffect(",
        "ShaderLibrary.cortexLiquidWarp(",
        ".float(Float(viewport.scaleX))",
        ".float(Float(viewport.scaleY))",
        'Image("SplashGlassMask")',
        'Image("SplashGlassOverlay")',
        'startAsset: "SplashIconLogoStart"',
        'endAsset: "SplashIconLogoEnd"',
        'startAsset: "SplashTextLogoStart"',
        'endAsset: "SplashTextLogoEnd"',
        "withAnimation(Timing.transition)",
        "finishOnce()",
    ):
        require(swift, token, "SplashAnimationView.swift")

    for forbidden in (
        ".compositingGroup()",
        ".drawingGroup()",
        ".position(",
        ".scaleEffect(",
        "import AVFoundation",
        "AVPlayer",
        "AVPlayerLayer",
        "CortexSplashIntro",
        "import WebKit",
        "WKWebView",
        "evaluateJavaScript",
        "SplashIntro.html",
        "VideoPlayer",
    ):
        if forbidden in swift:
            fail(f"forbidden splash implementation token remains: {forbidden}")

    if hashlib.sha256(METAL.read_bytes()).hexdigest() != "25890143ea4eba8b97f907e4ad5378a768087babfc9aa2a9c82f2a40a4acea81":
        fail("CortexSplashShaders.metal differs from the approved scale-aware shader")
    for token in (
        "[[ stitchable ]] float2 cortexLiquidWarp(",
        "float scaleX",
        "float scaleY",
        "float2 designPosition = position / designScale",
        "float2 frequency = float2(0.008, 0.024)",
        "cortexSmoothNoise(samplePoint, 17.0)",
        "designDisplacement * designScale",
    ):
        require(metal, token, "CortexSplashShaders.metal")

    for token in (
        "@State private var isShowingSplash = true",
        "SplashAnimationView",
        "isShowingSplash = false",
        ".zIndex(100)",
    ):
        require(app_root, token, "AppRootView.swift")

    if "CortexSplashIntro.mp4" in project or "SplashIntro.html" in project:
        fail("project.yml still includes a legacy splash runtime resource")
    if not re.search(r"CURRENT_PROJECT_VERSION:\s*26", project):
        fail("CURRENT_PROJECT_VERSION must be 26")
    if not re.search(r"MARKETING_VERSION:\s*1\.2\.12", project):
        fail("MARKETING_VERSION must be 1.2.12")

    launch_manifest = json.loads((LAUNCH_MARK / "Contents.json").read_text(encoding="utf-8"))
    launch_expected = {
        "LaunchMark@1x.png": (256, 256),
        "LaunchMark@2x.png": (512, 512),
        "LaunchMark@3x.png": (768, 768),
    }
    launch_referenced = {item.get("filename") for item in launch_manifest.get("images", [])}
    if launch_referenced != set(launch_expected):
        fail(f"unexpected LaunchMark manifest entries: {sorted(launch_referenced)}")
    for filename, size in launch_expected.items():
        verify_launch_mark(LAUNCH_MARK / filename, size)

    print(
        "Verified native splash positioning: direct screen-space frames and offsets, "
        "Retina raster layers, scale-aware Metal refraction, exact timing, and no "
        "group scaling, offscreen compositing, movie, HTML, WebKit, or AVFoundation."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
