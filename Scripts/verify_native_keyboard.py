#!/usr/bin/env python3
"""Validate that Cortex uses Apple's native keyboard path only."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "CortexApp" / "CortexApp.swift"
POLICY = ROOT / "CortexApp" / "Core" / "Utilities" / "NativeKeyboardPolicy.swift"
THEME = ROOT / "CortexApp" / "Theme" / "CortexTheme.swift"
FEATURES = ROOT / "CortexApp" / "Features"


def fail(message: str) -> None:
    print(f"native keyboard verification failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    app_text = APP.read_text(encoding="utf-8")
    policy_text = POLICY.read_text(encoding="utf-8")
    theme_text = THEME.read_text(encoding="utf-8")
    feature_text = "\n".join(
        path.read_text(encoding="utf-8") for path in FEATURES.rglob("*.swift")
    )

    if "@UIApplicationDelegateAdaptor(CortexAppDelegate.self)" not in app_text:
        fail("CortexAppDelegate is not attached to the SwiftUI app")

    required_policy_tokens = (
        "shouldAllowExtensionPointIdentifier",
        "extensionPointIdentifier != .keyboard",
    )
    for token in required_policy_tokens:
        if token not in policy_text:
            fail(f"missing keyboard extension policy token: {token}")

    forbidden_tokens = (
        "UIInputViewController",
        "inputView =",
        "inputAccessoryView =",
        "keyboardAppearance =",
    )
    combined = "\n".join((policy_text, theme_text, feature_text))
    for token in forbidden_tokens:
        if token in combined:
            fail(f"custom or forced keyboard implementation remains: {token}")

    text_fields = len(re.findall(r"\bTextField\(", feature_text))
    text_editors = len(re.findall(r"\bTextEditor\(", feature_text))
    native_text = feature_text.count(".cortexNativeKeyboard(")
    native_number = feature_text.count(".cortexNativeNumberPad(")

    expected_inputs = text_fields + text_editors
    configured_inputs = native_text + native_number
    if expected_inputs != configured_inputs:
        fail(
            f"{expected_inputs} native text inputs found but only "
            f"{configured_inputs} have an explicit Apple keyboard modifier"
        )

    print(
        "Verified Apple keyboard policy: third-party keyboard extensions are "
        f"blocked and all {expected_inputs} text inputs use native modifiers."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
