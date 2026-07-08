#!/usr/bin/env python3
"""Validate the exact HTML/WebKit startup animation and launch-screen bridge."""

from __future__ import annotations

import hashlib
import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "CortexApp" / "Resources" / "SplashIntro.html"
SWIFT = ROOT / "CortexApp" / "Features" / "Launch" / "SplashAnimationView.swift"
APP_ROOT = ROOT / "CortexApp" / "AppRootView.swift"
PROJECT = ROOT / "project.yml"
LAUNCH_MARK = ROOT / "CortexApp" / "Resources" / "Assets.xcassets" / "LaunchMark.imageset"

EXPECTED_HTML_SHA256 = "221d39b7e4231996d054f513fc79ab09d7e94e72c95f7305971dc96a78279292"


def fail(message: str) -> None:
    print(f"splash animation verification failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, token: str, location: str) -> None:
    if token not in text:
        fail(f"missing {token!r} in {location}")


def verify_png(path: Path, expected_size: tuple[int, int]) -> None:
    raw = path.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n" or raw[12:16] != b"IHDR":
        fail(f"{path.relative_to(ROOT)} is not a PNG")
    width, height = struct.unpack(">II", raw[16:24])
    if (width, height) != expected_size:
        fail(f"unexpected dimensions for {path.name}: {width}x{height}")
    if raw[25] not in (4, 6):
        fail(f"{path.name} must be RGBA so the launch bridge is deterministic")


def main() -> int:
    if not HTML.is_file():
        fail("SplashIntro.html is missing")
    if hashlib.sha256(HTML.read_bytes()).hexdigest() != EXPECTED_HTML_SHA256:
        fail("SplashIntro.html differs from the exact user-supplied reference")

    html = HTML.read_text(encoding="utf-8")
    swift = SWIFT.read_text(encoding="utf-8")
    app_root = APP_ROOT.read_text(encoding="utf-8")
    project = PROJECT.read_text(encoding="utf-8")

    for token in (
        '--screen-w: 375px;',
        '--screen-h: 812px;',
        '--duration: 800ms;',
        '--ease: cubic-bezier(1, .01, 0, .99);',
        'width:739px; height:1600px;',
        'transform:scale(.5074424899,.5075);',
        'filter:blur(23.4px);',
        'filter:url(#liquid-warp);',
        'backdrop-filter:brightness(1.035) contrast(1.10);',
        '.text-logo { left:304px; top:756px; width:131px; height:88px; }',
        '.icon-logo { left:337px; top:774px; width:66px; height:53px; }',
        '.is-frame-2 .text-logo { left:355px; top:790px; width:29px; height:19px; }',
        '.is-frame-2 .icon-logo { left:288px; top:735px; width:164px; height:131px; }',
        'const INITIAL_HOLD_MS = 900;',
        'setTimeout(() => nextPaint(frame2), INITIAL_HOLD_MS);',
    ):
        require(html, token, "SplashIntro.html")

    for token in (
        "import WebKit",
        "WKWebViewConfiguration()",
        'forResource: "SplashIntro"',
        'withExtension: "html"',
        "loadFileURL(",
        "contentInsetAdjustmentBehavior = .never",
        "isUserInteractionEnabled = false",
        "transitionend",
        "event.propertyName === 'width'",
        "requestAnimationFrame(() => requestAnimationFrame",
        "setTimeout(postFinished, 3500)",
    ):
        require(swift, token, "SplashAnimationView.swift")

    for forbidden in (
        'Image("SplashTextLogo")',
        'Image("SplashIconLogo")',
        'Image("SplashGlassLogoMask")',
        '.timingCurve(',
    ):
        if forbidden in swift:
            fail(f"legacy native approximation still present: {forbidden}")

    for token in (
        "@State private var isShowingSplash = true",
        "SplashAnimationView",
        "isShowingSplash = false",
        ".zIndex(100)",
    ):
        require(app_root, token, "AppRootView.swift")

    require(project, "CortexApp/Resources/SplashIntro.html", "project.yml")
    if not re.search(r"CURRENT_PROJECT_VERSION:\s*22", project):
        fail("CURRENT_PROJECT_VERSION must be 22")
    if not re.search(r"MARKETING_VERSION:\s*1\.2\.8", project):
        fail("MARKETING_VERSION must be 1.2.8")

    manifest = json.loads((LAUNCH_MARK / "Contents.json").read_text(encoding="utf-8"))
    expected = {
        "LaunchMark@1x.png": (256, 256),
        "LaunchMark@2x.png": (512, 512),
        "LaunchMark@3x.png": (768, 768),
    }
    referenced = {item.get("filename") for item in manifest.get("images", [])}
    if referenced != set(expected):
        fail(f"unexpected LaunchMark manifest entries: {sorted(referenced)}")
    for filename, size in expected.items():
        verify_png(LAUNCH_MARK / filename, size)

    print("Verified exact HTML/CSS splash, WebKit transition bridge, and launch frame assets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
