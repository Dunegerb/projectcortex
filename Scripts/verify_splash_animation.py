#!/usr/bin/env python3
"""Verify the fully native SwiftUI Cortex launch animation."""

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

EXPECTED_SVGS = {
    "SplashGlassMask": {
        "file": "SplashGlassMask.svg",
        "size": (442, 298),
        "sha256": "c84e493dddfc18f94d318ab20dd1b07dc7ee67c5e53235c052e7058833b5728b",
    },
    "SplashGlassOverlay": {
        "file": "SplashGlassOverlay.svg",
        "size": (442, 298),
        "sha256": "a1ab72dcc19f1c1cfb4d34318e4ef757012ccd16edf27528f40efb24ef2293ed",
    },
    "SplashIconLogoStart": {
        "file": "SplashIconLogoStart.svg",
        "size": (66, 53),
        "sha256": "8148bb73ba70118810544a158175b78684d0bb2b0c08ced4c53e65a2ba9080db",
    },
    "SplashIconLogoEnd": {
        "file": "SplashIconLogoEnd.svg",
        "size": (164, 131),
        "sha256": "47cecf5debd3fe0c7e423ea855aef7e6fbf6106afd43eb37611ff750f7e11e08",
    },
    "SplashTextLogoStart": {
        "file": "SplashTextLogoStart.svg",
        "size": (131, 88),
        "sha256": "eb136ebb6a2ad6b26082e6118868f1342558c07e31526013d7e8ef35573c658c",
    },
    "SplashTextLogoEnd": {
        "file": "SplashTextLogoEnd.svg",
        "size": (29, 19),
        "sha256": "19ac3dc5c2026c25031b9bea4e2535b961aafe41186482485a72a54380a78e60",
    },
}


def fail(message: str) -> None:
    print(f"splash animation verification failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, token: str, location: str) -> None:
    if token not in text:
        fail(f"missing {token!r} in {location}")


def verify_png(path: Path, expected_size: tuple[int, int], require_alpha: bool = False) -> None:
    raw = path.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n" or raw[12:16] != b"IHDR":
        fail(f"{path.relative_to(ROOT)} is not a PNG")
    width, height = struct.unpack(">II", raw[16:24])
    if (width, height) != expected_size:
        fail(f"unexpected dimensions for {path.name}: {width}x{height}")
    if require_alpha and raw[25] not in (4, 6):
        fail(f"{path.name} must contain alpha")


def verify_svg_asset(name: str, metadata: dict[str, object]) -> None:
    directory = ASSETS / f"{name}.imageset"
    manifest_path = directory / "Contents.json"
    svg_path = directory / str(metadata["file"])
    if not manifest_path.is_file() or not svg_path.is_file():
        fail(f"{name}.imageset is incomplete")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    filenames = [item.get("filename") for item in manifest.get("images", [])]
    if filenames != [metadata["file"]]:
        fail(f"unexpected manifest for {name}: {filenames}")
    if manifest.get("properties", {}).get("preserves-vector-representation") is not True:
        fail(f"{name} must preserve its vector representation")

    raw = svg_path.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    if digest != metadata["sha256"]:
        fail(f"{svg_path.name} differs from the approved vector asset")

    text = raw.decode("utf-8")
    width, height = metadata["size"]
    if f'width="{width}"' not in text or f'height="{height}"' not in text:
        fail(f"unexpected SVG dimensions for {svg_path.name}")
    if f'viewBox="0 0 {width} {height}"' not in text:
        fail(f"unexpected SVG viewBox for {svg_path.name}")


def main() -> int:
    forbidden_runtime_files = [
        RESOURCES / "SplashIntro.html",
        RESOURCES / "Launch" / "CortexSplashIntro.mp4",
    ]
    for path in forbidden_runtime_files:
        if path.exists():
            fail(f"legacy splash runtime file still exists: {path.relative_to(ROOT)}")

    movie_files = sorted(
        path.relative_to(ROOT)
        for suffix in ("*.mp4", "*.mov", "*.m4v")
        for path in RESOURCES.rglob(suffix)
    )
    if movie_files:
        fail(f"movie assets are forbidden in the splash implementation: {movie_files}")

    for name, metadata in EXPECTED_SVGS.items():
        verify_svg_asset(name, metadata)

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
        "SplashDesignSpace(isFrame2: isFrame2)",
        "x: 0.5074424899 * viewportScale",
        "y: 0.5075 * viewportScale",
        "SplashRect(x: 173, y: 680, width: 33, height: 59.627)",
        "SplashRect(x: 479, y: 696, width: 82, height: 62)",
        "SplashRect(x: 173, y: 821.373, width: 33, height: 59.627)",
        "SplashRect(x: 479, y: 843, width: 82, height: 62)",
        "SplashRect(x: 337, y: 774, width: 66, height: 53)",
        "SplashRect(x: 288, y: 735, width: 164, height: 131)",
        "SplashRect(x: 304, y: 756, width: 131, height: 88)",
        "SplashRect(x: 355, y: 790, width: 29, height: 19)",
        ".blur(radius: 23.4, opaque: false)",
        ".distortionEffect(",
        "ShaderLibrary.cortexLiquidWarp()",
        "maxSampleOffset: CGSize(width: 9, height: 9)",
        'Image("SplashGlassMask")',
        'Image("SplashGlassOverlay")',
        'startAsset: "SplashIconLogoStart"',
        'endAsset: "SplashIconLogoEnd"',
        'startAsset: "SplashTextLogoStart"',
        'endAsset: "SplashTextLogoEnd"',
        "try? await Task.sleep(nanoseconds: Timing.initialHoldNanoseconds)",
        "withAnimation(Timing.transition)",
        "finishOnce()",
    ):
        require(swift, token, "SplashAnimationView.swift")


    if hashlib.sha256(METAL.read_bytes()).hexdigest() != "b06a6f87d05a795440b747e785f89e090c100a231f2beefde58f02c3e35730dc":
        fail("CortexSplashShaders.metal differs from the approved native refraction shader")
    for token in (
        "[[ stitchable ]] float2 cortexLiquidWarp(float2 position)",
        "float2 frequency = float2(0.008, 0.024)",
        "cortexSmoothNoise(samplePoint, 17.0)",
        "* 17.0",
    ):
        require(metal, token, "CortexSplashShaders.metal")

    for forbidden in (
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
            fail(f"non-native splash dependency still present: {forbidden}")

    for token in (
        "@State private var isShowingSplash = true",
        "SplashAnimationView",
        "isShowingSplash = false",
        ".zIndex(100)",
    ):
        require(app_root, token, "AppRootView.swift")

    if "CortexSplashIntro.mp4" in project or "SplashIntro.html" in project:
        fail("project.yml still includes a legacy splash runtime resource")
    if not re.search(r"CURRENT_PROJECT_VERSION:\s*25", project):
        fail("CURRENT_PROJECT_VERSION must be 25")
    if not re.search(r"MARKETING_VERSION:\s*1\.2\.11", project):
        fail("MARKETING_VERSION must be 1.2.11")

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
        verify_png(LAUNCH_MARK / filename, size, require_alpha=True)

    print(
        "Verified fully native SwiftUI splash: exact frame geometry and timing, "
        "vector assets, no movie, no HTML, no WebKit, and no AVFoundation."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
