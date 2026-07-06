#!/usr/bin/env python3
"""Fail fast when the SF Pro scale or OLED elevation palette drifts."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / "Shared" / "CortexDesignSystem.swift"
THEME = ROOT / "CortexApp" / "Theme" / "CortexTheme.swift"
APP_SOURCES = list((ROOT / "CortexApp").rglob("*.swift"))
WIDGET_SOURCES = list((ROOT / "CortexWidget").rglob("*.swift"))

EXPECTED_SIZES = {
    "largeTitle": "34",
    "title1": "28",
    "title2": "22",
    "title3": "20",
    "headline, .body": "17",
    "callout": "16",
    "subhead": "15",
    "footnote": "13",
    "caption1": "12",
    "caption2": "11",
}

EXPECTED_DARK_COLORS = (
    "28.0 / 255.0, green: 28.0 / 255.0, blue: 30.0 / 255.0",
    "44.0 / 255.0, green: 44.0 / 255.0, blue: 46.0 / 255.0",
    "58.0 / 255.0, green: 58.0 / 255.0, blue: 60.0 / 255.0",
)

EXPECTED_LIGHT_HEX = (
    "0xF1F1F1",
    "0xFFFFFF",
    "0xF5F5F5",
    "0x191817",
    "0x555555",
    "0xE9E9E9",
    "0xC2C2C2",
    "0x9E9E9E",
)


def fail(message: str) -> None:
    print(f"design verification failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    text = DESIGN.read_text(encoding="utf-8")
    theme = THEME.read_text(encoding="utf-8")

    if "Font.system" not in text and ".font(.system" not in text:
        fail("system/SF Pro font is not configured")

    for case_name, size in EXPECTED_SIZES.items():
        pattern = rf"case \.{re.escape(case_name)}:\s*{re.escape(size)}"
        if not re.search(pattern, text):
            fail(f"missing typography mapping {case_name} = {size} pt")

    if "case .headline: .semibold" not in text:
        fail("Headline must remain Semi-Bold")

    for color in EXPECTED_DARK_COLORS:
        if color not in text:
            fail(f"missing dark elevation color {color}")

    app_source_text = "\n".join(
        path.read_text(encoding="utf-8") for path in APP_SOURCES
    )

    for color in EXPECTED_LIGHT_HEX:
        if color not in theme and color not in app_source_text:
            fail(f"missing supplied light-mode color {color}")

    for token in ("AppAppearanceMode", "adaptiveUIColor", "preferredColorScheme"):
        source = theme if token != "preferredColorScheme" else app_source_text
        if token not in source:
            fail(f"missing adaptive appearance implementation: {token}")

    source_text = "\n".join(path.read_text(encoding="utf-8") for path in APP_SOURCES + WIDGET_SOURCES)
    forbidden = {
        "design: .serif": "legacy serif display font",
        "design: .rounded": "legacy rounded display font",
    }
    for token, description in forbidden.items():
        if token in source_text:
            fail(f"{description} remains in UI source")

    # Large positive tracking was part of the previous visual language.
    positive_tracking = re.search(r"\.tracking\(\s*(?:[1-9]|0\.[1-9])", source_text)
    if positive_tracking:
        fail("positive ad-hoc tracking remains in UI source")

    print("Verified SF Pro typography and adaptive dark/light palette.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
