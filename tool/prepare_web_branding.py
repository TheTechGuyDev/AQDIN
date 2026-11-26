from pathlib import Path
import json
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
svg = root / "assets/branding/aqdin_mark.svg"
web = root / "web"
icons = web / "icons"
icons.mkdir(parents=True, exist_ok=True)

try:
    import cairosvg
    from PIL import Image, ImageDraw
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "cairosvg", "Pillow"])
    import cairosvg
    from PIL import Image, ImageDraw

# Render the existing AQDIN mark onto a branded deep-green rounded tile.
mark_bytes = cairosvg.svg2png(url=str(svg), output_width=420, output_height=420)
import io
mark = Image.open(io.BytesIO(mark_bytes)).convert("RGBA")

for size in (192, 512):
    for maskable in (False, True):
        canvas = Image.new("RGBA", (size, size), "#07362A")
        draw = ImageDraw.Draw(canvas)
        inset = int(size * (0.00 if maskable else 0.06))
        draw.rounded_rectangle(
            (inset, inset, size - inset - 1, size - inset - 1),
            radius=int(size * 0.22),
            fill="#07362A",
        )
        margin = int(size * (0.20 if maskable else 0.15))
        mark_size = size - margin * 2
        rendered = mark.resize((mark_size, mark_size), Image.Resampling.LANCZOS)
        canvas.alpha_composite(rendered, ((size - mark_size) // 2, (size - mark_size) // 2))
        suffix = "-maskable" if maskable else ""
        canvas.convert("RGB").save(icons / f"Icon-{size}{suffix}.png", optimize=True)

# A small square favicon uses the same logo artwork.
favicon = Image.new("RGBA", (64, 64), "#07362A")
small = mark.resize((54, 54), Image.Resampling.LANCZOS)
favicon.alpha_composite(small, (5, 5))
favicon.save(web / "favicon.png", optimize=True)

manifest = {
    "name": "AQDIN — Muslim Matrimonial",
    "short_name": "AQDIN",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#07362A",
    "theme_color": "#07362A",
    "description": "A thoughtful space for Muslims seeking marriage.",
    "icons": [
        {"src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png"},
        {"src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png"},
        {"src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable"},
        {"src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"}
    ]
}
(web / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\\n")

index = web / "index.html"
if index.exists():
    html = index.read_text()
    html = html.replace('href="favicon.png"', 'href="favicon.png"')
    html = html.replace('<meta name="theme-color" content="#000000">', '<meta name="theme-color" content="#07362A">')
    index.write_text(html)
print("AQDIN web icons and PWA manifest generated.")
