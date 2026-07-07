#!/usr/bin/env python3
from pathlib import Path
import json
import struct

root = Path(__file__).resolve().parents[1]
iconset = root / 'CortexApp/Resources/Assets.xcassets/AppIcon.appiconset'
manifest = iconset / 'Contents.json'
if not manifest.is_file():
    raise SystemExit('app icon verification failed: Contents.json is missing')

data = json.loads(manifest.read_text(encoding='utf-8'))
expected = {
    'AppIcon-20@2x.png': (40, 40),
    'AppIcon-20@3x.png': (60, 60),
    'AppIcon-29@2x.png': (58, 58),
    'AppIcon-29@3x.png': (87, 87),
    'AppIcon-40@2x.png': (80, 80),
    'AppIcon-40@3x.png': (120, 120),
    'AppIcon-60@2x.png': (120, 120),
    'AppIcon-60@3x.png': (180, 180),
    'AppIcon-1024.png': (1024, 1024),
}
listed = {item.get('filename') for item in data.get('images', []) if item.get('filename')}
missing_manifest = sorted(set(expected) - listed)
if missing_manifest:
    raise SystemExit(f'app icon verification failed: files absent from Contents.json: {missing_manifest}')

for name, expected_size in expected.items():
    path = iconset / name
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit(f'app icon verification failed: missing or empty {name}')
    raw = path.read_bytes()
    if raw[:8] != b'\x89PNG\r\n\x1a\n' or raw[12:16] != b'IHDR':
        raise SystemExit(f'app icon verification failed: {name} is not a valid PNG')
    width, height, bit_depth, color_type = struct.unpack('>IIBB', raw[16:26])
    if (width, height) != expected_size:
        raise SystemExit(f'app icon verification failed: {name} is {(width, height)}, expected {expected_size}')
    if bit_depth != 8 or color_type != 2:
        raise SystemExit(
            f'app icon verification failed: {name} must be 8-bit RGB without alpha '
            f'(bit_depth={bit_depth}, color_type={color_type})'
        )


fallback = root / 'CortexApp/Resources/AppIconFallback'
fallback_pairs = {
    'AppIcon20x20@2x.png': 'AppIcon-20@2x.png',
    'AppIcon20x20@3x.png': 'AppIcon-20@3x.png',
    'AppIcon29x29@2x.png': 'AppIcon-29@2x.png',
    'AppIcon29x29@3x.png': 'AppIcon-29@3x.png',
    'AppIcon40x40@2x.png': 'AppIcon-40@2x.png',
    'AppIcon40x40@3x.png': 'AppIcon-40@3x.png',
    'AppIcon60x60@2x.png': 'AppIcon-60@2x.png',
    'AppIcon60x60@3x.png': 'AppIcon-60@3x.png',
}
for fallback_name, source_name in fallback_pairs.items():
    fallback_path = fallback / fallback_name
    source_path = iconset / source_name
    if not fallback_path.is_file() or fallback_path.stat().st_size == 0:
        raise SystemExit(f'app icon verification failed: missing or empty fallback {fallback_name}')
    if fallback_path.read_bytes() != source_path.read_bytes():
        raise SystemExit(
            f'app icon verification failed: fallback {fallback_name} does not exactly match {source_name}'
        )

print('Verified embedded iPhone AppIcon set and exact Sideloadly fallback copies: dimensions, RGB format and pixel identity are correct.')
