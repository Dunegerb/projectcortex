#!/usr/bin/env python3
"""Validate the native, WebKit-free startup animation and launch bridge."""

from __future__ import annotations

import hashlib
import json
import re
import struct
import sys
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[1]
VIDEO = ROOT / "CortexApp" / "Resources" / "Launch" / "CortexSplashIntro.mp4"
SWIFT = ROOT / "CortexApp" / "Features" / "Launch" / "SplashAnimationView.swift"
APP_ROOT = ROOT / "CortexApp" / "AppRootView.swift"
PROJECT = ROOT / "project.yml"
ASSETS = ROOT / "CortexApp" / "Resources" / "Assets.xcassets"
LAUNCH_MARK = ASSETS / "LaunchMark.imageset"
EXPECTED_VIDEO_SHA256 = "a34b17c4f76faadae9a7030994a7b140e4af20ccd4c39e9bc7e14a3a84f5d3ae"
EXPECTED_FRAME_HASHES = {
    "SplashFirstFrame.png": "9f56a1ec8d15b8b87a6095761608351ba06fe9f9cb2dca590cf6c5d38f44bb95",
    "SplashFirstFrame@2x.png": "041f2c5bbc8af5c4f71e909da13a0907edf49e41d483648b066974649b0ac23d",
    "SplashFirstFrame@3x.png": "7f003bea85a5f7064c7a230f58c8ff50fb40460d1301ca17fcec1776347b2a30",
    "SplashFinalFrame.png": "b75696f78a668845ede22111bfe85e33609a53872d17746154945f079f744d77",
    "SplashFinalFrame@2x.png": "e771ce6550bd7f026dc3277fb808fe34e2fea923fddadc84f62c2b2440e28253",
    "SplashFinalFrame@3x.png": "d96c7c45e38ff3d92afe82498cbdfc78e58c47d1ef330b57367973cf5f0107ff",
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
        fail(f"{path.name} must be RGBA")


def iter_boxes(data: bytes, start: int = 0, end: Optional[int] = None):
    end = len(data) if end is None else end
    offset = start
    while offset + 8 <= end:
        size = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4 : offset + 8]
        header = 8
        if size == 1:
            if offset + 16 > end:
                return
            size = struct.unpack_from(">Q", data, offset + 8)[0]
            header = 16
        elif size == 0:
            size = end - offset
        if size < header or offset + size > end:
            return
        yield kind, offset + header, offset + size
        offset += size


def verify_mp4(path: Path) -> None:
    raw = path.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    if digest != EXPECTED_VIDEO_SHA256:
        fail("CortexSplashIntro.mp4 differs from the approved native render")
    if not 50_000 <= len(raw) <= 500_000:
        fail(f"unexpected splash movie size: {len(raw)} bytes")

    top = list(iter_boxes(raw))
    top_types = {kind for kind, _, _ in top}
    for required in (b"ftyp", b"moov", b"mdat"):
        if required not in top_types:
            fail(f"MP4 box {required.decode()} is missing")
    if b"avc1" not in raw:
        fail("splash movie is not H.264/AVC")

    duration_seconds = None
    dimensions = None
    for kind, payload_start, box_end in top:
        if kind != b"moov":
            continue
        for child_kind, child_start, child_end in iter_boxes(raw, payload_start, box_end):
            if child_kind == b"mvhd":
                payload = raw[child_start:child_end]
                version = payload[0]
                if version == 0 and len(payload) >= 20:
                    timescale = struct.unpack_from(">I", payload, 12)[0]
                    duration = struct.unpack_from(">I", payload, 16)[0]
                elif version == 1 and len(payload) >= 32:
                    timescale = struct.unpack_from(">I", payload, 20)[0]
                    duration = struct.unpack_from(">Q", payload, 24)[0]
                else:
                    continue
                if timescale:
                    duration_seconds = duration / timescale
            elif child_kind == b"trak":
                for track_kind, track_start, track_end in iter_boxes(raw, child_start, child_end):
                    if track_kind != b"tkhd":
                        continue
                    payload = raw[track_start:track_end]
                    version = payload[0]
                    width_offset = 76 if version == 0 else 88
                    if len(payload) < width_offset + 8:
                        continue
                    width = struct.unpack_from(">I", payload, width_offset)[0] / 65536
                    height = struct.unpack_from(">I", payload, width_offset + 4)[0] / 65536
                    if width > 0 and height > 0:
                        dimensions = (round(width), round(height))

    if dimensions != (750, 1624):
        fail(f"unexpected splash movie dimensions: {dimensions}")
    if duration_seconds is None or abs(duration_seconds - 1.75) > 0.002:
        fail(f"unexpected splash movie duration: {duration_seconds}")


def verify_imageset(name: str) -> None:
    directory = ASSETS / f"{name}.imageset"
    manifest = json.loads((directory / "Contents.json").read_text(encoding="utf-8"))
    expected = {
        f"{name}.png": (375, 812),
        f"{name}@2x.png": (750, 1624),
        f"{name}@3x.png": (1125, 2436),
    }
    referenced = {item.get("filename") for item in manifest.get("images", [])}
    if referenced != set(expected):
        fail(f"unexpected {name} manifest entries: {sorted(referenced)}")
    for filename, size in expected.items():
        path = directory / filename
        verify_png(path, size)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != EXPECTED_FRAME_HASHES[filename]:
            fail(f"{filename} differs from the approved reference frame")


def main() -> int:
    if not VIDEO.is_file():
        fail("CortexSplashIntro.mp4 is missing")
    if (ROOT / "CortexApp" / "Resources" / "SplashIntro.html").exists():
        fail("SplashIntro.html must not be bundled or kept as a runtime resource")

    verify_mp4(VIDEO)
    verify_imageset("SplashFirstFrame")
    verify_imageset("SplashFinalFrame")

    swift = SWIFT.read_text(encoding="utf-8")
    app_root = APP_ROOT.read_text(encoding="utf-8")
    project = PROJECT.read_text(encoding="utf-8")

    for token in (
        "import AVFoundation",
        "AVPlayerItem(asset: asset)",
        "AVPlayerLayer.self",
        'forResource: "CortexSplashIntro"',
        'withExtension: "mp4"',
        "automaticallyWaitsToMinimizeStalling = true",
        "playImmediately(atRate: 1)",
        ".AVPlayerItemDidPlayToEndTime",
        'Image("SplashFirstFrame")',
        'Image("SplashFinalFrame")',
        "finishOnlyAfterRealMovieEnd",
        "currentSeconds + 0.025 < durationSeconds",
        "onPlaybackFailure: beginFallback",
        ".now() + 0.9",
        ".now() + 1.75",
        ".timingCurve(1, 0.01, 0, 0.99, duration: 0.8)",
        ".resizeAspect",
        "isMuted = true",
    ):
        require(swift, token, "SplashAnimationView.swift")

    for forbidden in (
        "import WebKit",
        "WKWebView",
        "WKWebViewConfiguration",
        "loadFileURL",
        "evaluateJavaScript",
        "SplashIntro.html",
        "transitionend",
        "accessibilityReduceMotion",
        ".now() + 0.08",
        ".now() + 0.12",
        "finishAfterFallbackDelay",
    ):
        if forbidden in swift:
            fail(f"WebKit/HTML splash code still present: {forbidden}")

    for token in (
        "@State private var isShowingSplash = true",
        "SplashAnimationView",
        "isShowingSplash = false",
        ".zIndex(100)",
    ):
        require(app_root, token, "AppRootView.swift")

    require(project, "CortexApp/Resources/Launch/CortexSplashIntro.mp4", "project.yml")
    if "CortexApp/Resources/SplashIntro.html" in project:
        fail("project.yml still copies SplashIntro.html")
    if not re.search(r"CURRENT_PROJECT_VERSION:\s*24", project):
        fail("CURRENT_PROJECT_VERSION must be 24")
    if not re.search(r"MARKETING_VERSION:\s*1\.2\.10", project):
        fail("MARKETING_VERSION must be 1.2.10")

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
        "Verified native AVFoundation splash: full 1.75 s playback gated by the real movie end, "
        "duration-safe fallback, no HTML, and no WebKit."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
