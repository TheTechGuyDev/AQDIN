from pathlib import Path
import json
import math
import struct
import zlib

root = Path(__file__).resolve().parents[1]
web = root / "web"
icons = web / "icons"
icons.mkdir(parents=True, exist_ok=True)

GREEN = (23, 107, 85)
MINT = (228, 241, 235)
WHITE = (255, 255, 255)

def inside_polygon(x, y, points):
    inside = False
    j = len(points) - 1
    for i, (xi, yi) in enumerate(points):
        xj, yj = points[j]
        if (yi > y) != (yj > y):
            cross = (xj - xi) * (y - yi) / ((yj - yi) or 1e-12) + xi
            if x < cross:
                inside = not inside
        j = i
    return inside

def png_chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)

def save_icon(path, size, maskable=False):
    inset = 0 if maskable else int(size * 0.06)
    radius = int(size * 0.23)
    circle = size * 0.28
    cx = cy = (size - 1) / 2
    heart_scale = size * (0.014 if maskable else 0.015)
    heart = []
    for step in range(181):
        t = 2 * math.pi * step / 180
        hx = 16 * math.sin(t) ** 3
        hy = 13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)
        heart.append((cx + hx * heart_scale, cy - hy * heart_scale - size * 0.012))

    rows = []
    for y in range(size):
        row = bytearray([0])
        for x in range(size):
            # Rounded-square mint tile on a deep green background.
            left, top = inset, inset
            right, bottom = size - 1 - inset, size - 1 - inset
            qx = max(left + radius - x, 0, x - (right - radius))
            qy = max(top + radius - y, 0, y - (bottom - radius))
            tile = (left <= x <= right and top <= y <= bottom and
                    qx*qx + qy*qy <= radius*radius)
            color = MINT if tile else GREEN
            if (x-cx)**2 + (y-cy)**2 <= circle*circle:
                color = GREEN
            if inside_polygon(x + 0.5, y + 0.5, heart):
                color = WHITE
            row.extend((*color, 255))
        rows.append(bytes(row))
    raw = b"".join(rows)
    header = struct.pack(">2I5B", size, size, 8, 6, 0, 0, 0)
    data = b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", header)
    data += png_chunk(b"IDAT", zlib.compress(raw, 9)) + png_chunk(b"IEND", b"")
    path.write_bytes(data)

for size in (192, 512):
    for maskable in (False, True):
        suffix = "-maskable" if maskable else ""
        save_icon(icons / f"Icon-{size}{suffix}.png", size, maskable)

save_icon(web / "favicon.png", 64)

manifest = {
    "name": "AQDIN — Muslim Matrimonial",
    "short_name": "AQDIN",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#176B55",
    "theme_color": "#176B55",
    "description": "A thoughtful space for Muslims seeking marriage.",
    "icons": [
        {"src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png"},
        {"src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png"},
        {"src": "icons/Icon-192-maskable.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable"},
        {"src": "icons/Icon-512-maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"}
    ]
}
(web / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

index = web / "index.html"
if index.exists():
    html = index.read_text(encoding="utf-8")
    html = html.replace('<meta name="theme-color" content="#000000">',
                        '<meta name="theme-color" content="#176B55">')
    index.write_text(html, encoding="utf-8")

print("AQDIN web icons and PWA manifest generated with Python standard library only.")
