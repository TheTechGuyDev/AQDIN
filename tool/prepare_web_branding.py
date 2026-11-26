from pathlib import Path
import json
import math
import subprocess
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
web = root / "web"
icons = web / "icons"
icons.mkdir(parents=True, exist_ok=True)

GREEN = "#176B55"
MINT = "#E4F1EB"
WHITE = "#FFFFFF"

def draw_aqdin_icon(size: int, maskable: bool = False) -> Image.Image:
    image = Image.new("RGBA", (size, size), GREEN)
    draw = ImageDraw.Draw(image)
    inset = int(size * (0.00 if maskable else 0.06))
    radius = int(size * 0.23)
    draw.rounded_rectangle(
        (inset, inset, size - inset - 1, size - inset - 1),
        radius=radius,
        fill=MINT,
    )

    circle_size = int(size * 0.56)
    left = (size - circle_size) // 2
    top = (size - circle_size) // 2
    draw.ellipse((left, top, left + circle_size, top + circle_size), fill=GREEN)

    # Draw a clean, symmetrical heart using a sampled parametric curve.
    points = []
    scale = size * (0.014 if maskable else 0.015)
    cx, cy = size / 2, size / 2 - size * 0.012
    for step in range(181):
        t = 2 * math.pi * step / 180
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)
        points.append((cx + x * scale, cy - y * scale))
    draw.polygon(points, fill=WHITE)
    return image

for size in (192, 512):
    for maskable in (False, True):
        icon = draw_aqdin_icon(size, maskable)
        suffix = "-maskable" if maskable else ""
        icon.convert("RGB").save(icons / f"Icon-{size}{suffix}.png", optimize=True)

draw_aqdin_icon(64).convert("RGB").save(web / "favicon.png", optimize=True)

manifest = {
    "name": "AQDIN — Muslim Matrimonial",
    "short_name": "AQDIN",
    "start_url": ".",
    "display": "standalone",
    "background_color": GREEN,
    "theme_color": GREEN,
    "description": "A thoughtful space for Muslims seeking marriage.",
    "icons": [
        {"src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png"},
        {"src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png"},
        {"src": "icons/Icon-192-maskable.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable"},
        {"src": "icons/Icon-512-maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"},
    ],
}
(web / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

index = web / "index.html"
if index.exists():
    html = index.read_text(encoding="utf-8")
    html = html.replace('<meta name="theme-color" content="#000000">', f'<meta name="theme-color" content="{GREEN}">')
    index.write_text(html, encoding="utf-8")

print("AQDIN web icons and PWA manifest generated.")
