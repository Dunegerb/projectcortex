#!/usr/bin/env python3
"""Fail early when XcodeGen omitted the asset catalog from Copy Bundle Resources."""
from pathlib import Path
import sys

project = Path('Cortex.xcodeproj/project.pbxproj')
if not project.is_file():
    raise SystemExit('project verification failed: Cortex.xcodeproj was not generated')
text = project.read_text(encoding='utf-8', errors='replace')

if 'Assets.xcassets' not in text:
    raise SystemExit('project verification failed: Assets.xcassets is absent from the generated project')
if 'Assets.xcassets in Resources' not in text:
    raise SystemExit('project verification failed: Assets.xcassets is not in Copy Bundle Resources')
if 'ASSETCATALOG_COMPILER_APPICON_NAME = CortexAppIcon' not in text and 'ASSETCATALOG_COMPILER_APPICON_NAME = "CortexAppIcon"' not in text:
    raise SystemExit('project verification failed: CortexAppIcon build setting is absent')

print('Verified generated Xcode project: Assets.xcassets is in Copy Bundle Resources.')
