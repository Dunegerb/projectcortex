#!/usr/bin/env python3
"""Validate the source-built unsigned IPA and native full-screen metadata."""

from __future__ import annotations

import argparse
import plistlib
import stat
import sys
import zipfile
from pathlib import Path, PurePosixPath


def is_signing_artifact(name: str) -> bool:
    path = PurePosixPath(name)
    return (
        "_CodeSignature" in path.parts
        or "SC_Info" in path.parts
        or path.name in {"CodeResources", "embedded.mobileprovision"}
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("ipa", type=Path)
    args = parser.parse_args()

    try:
        if not args.ipa.is_file():
            raise FileNotFoundError(args.ipa)

        with zipfile.ZipFile(args.ipa, "r") as archive:
            infos = archive.infolist()
            names = {item.filename for item in infos}

            main_plists = [
                item
                for item in infos
                if len(PurePosixPath(item.filename).parts) == 3
                and item.filename.startswith("Payload/")
                and PurePosixPath(item.filename).parts[1].endswith(".app")
                and PurePosixPath(item.filename).name == "Info.plist"
            ]
            if len(main_plists) != 1:
                raise ValueError(f"Expected one main Info.plist, found {len(main_plists)}")

            info = plistlib.loads(archive.read(main_plists[0]))
            launch = info.get("UILaunchScreen")
            if not isinstance(launch, dict):
                raise ValueError("UILaunchScreen is missing or invalid")
            if launch.get("UIColorName") != "LaunchBackground":
                raise ValueError("UILaunchScreen UIColorName is not LaunchBackground")
            if launch.get("UIImageName") != "LaunchMark":
                raise ValueError("UILaunchScreen UIImageName is not LaunchMark")
            if info.get("UIRequiresFullScreen") is not True:
                raise ValueError("UIRequiresFullScreen is not enabled")

            primary_icon = info.get("CFBundleIcons", {}).get("CFBundlePrimaryIcon", {})
            if primary_icon.get("CFBundleIconName") != "CortexAppIcon":
                raise ValueError("CFBundleIconName is missing or does not point to CortexAppIcon")
            icon_files = primary_icon.get("CFBundleIconFiles")
            expected_icon_basenames = {
                "CortexIcon20x20",
                "CortexIcon29x29",
                "CortexIcon40x40",
                "CortexIcon60x60",
            }
            if not isinstance(icon_files, list) or not expected_icon_basenames.issubset(icon_files):
                raise ValueError(
                    "CFBundlePrimaryIcon does not contain all CortexIcon fallback metadata"
                )

            signing_files = [item.filename for item in infos if is_signing_artifact(item.filename)]
            if signing_files:
                raise ValueError(f"Signing artifacts remain: {signing_files}")

            executable_name = info.get("CFBundleExecutable")
            if not isinstance(executable_name, str) or not executable_name:
                raise ValueError("CFBundleExecutable is missing")
            app_dir = PurePosixPath(main_plists[0].filename).parent
            executable_path = str(app_dir / executable_name)
            executable_info = next((item for item in infos if item.filename == executable_path), None)
            if executable_info is None:
                raise ValueError(f"Main executable is missing: {executable_path}")
            if not (stat.S_IMODE(executable_info.external_attr >> 16) & stat.S_IXUSR):
                raise ValueError("Main executable lost executable permissions")

            if not any(name.startswith(f"{app_dir}/PlugIns/") and name.endswith(".appex/Info.plist") for name in names):
                raise ValueError("Embedded widget extension is missing")

            assets_path = str(app_dir / "Assets.car")
            assets_info = next((item for item in infos if item.filename == assets_path), None)
            if assets_info is None or assets_info.file_size <= 0:
                raise ValueError("Compiled Assets.car is missing or empty")

            required_icons = (
                "CortexIcon20x20@2x.png",
                "CortexIcon20x20@3x.png",
                "CortexIcon29x29@2x.png",
                "CortexIcon29x29@3x.png",
                "CortexIcon40x40@2x.png",
                "CortexIcon40x40@3x.png",
                "CortexIcon60x60@2x.png",
                "CortexIcon60x60@3x.png",
            )
            for icon in required_icons:
                icon_path = str(app_dir / icon)
                icon_info = next((item for item in infos if item.filename == icon_path), None)
                if icon_info is None or icon_info.file_size <= 0:
                    raise ValueError(f"Fallback app icon is missing or empty: {icon_path}")

            required_resources = (
                "ChakraExperience.html",
                "personkundalini.svg",
            )
            forbidden_splash_resources = (
                str(app_dir / "SplashIntro.html"),
                str(app_dir / "CortexSplashIntro.mp4"),
            )
            for forbidden_path in forbidden_splash_resources:
                if forbidden_path in names:
                    raise ValueError(
                        f"Legacy splash runtime resource must not be present in the IPA: {forbidden_path}"
                    )
            for resource in required_resources:
                resource_path = str(app_dir / resource)
                resource_info = next(
                    (item for item in infos if item.filename == resource_path),
                    None,
                )
                if resource_info is None:
                    raise ValueError(
                        f"Required runtime resource is missing from the main app bundle: {resource_path}"
                    )
                if resource_info.file_size <= 0:
                    raise ValueError(f"Required runtime resource is empty: {resource_path}")

        print(f"Verified: {args.ipa}")
        return 0
    except Exception as exc:
        print(f"verification failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
