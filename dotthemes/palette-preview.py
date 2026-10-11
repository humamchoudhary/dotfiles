#!/usr/bin/env python3
# palette-preview.py <theme-name> — render a palette as PNG on stdout.
# Used as the fsel --preview renderer for the theme picker (fsel renders
# stdout image bytes natively via the kitty graphics protocol).
import json
import os
import sys

from PIL import Image, ImageDraw

ORDER = [
    "true_black", "vanta_ui", "surface", "elevated", "border",
    "muted_text", "body_text", "bright_text", "accent", "accent_dim",
]


def main():
    if len(sys.argv) < 2:
        return
    name = sys.argv[1].strip()
    src = os.path.join(os.path.dirname(os.path.abspath(__file__)), "colors.json")
    palettes = json.load(open(src))
    pal = next((p for p in palettes if p["palette"].strip().lower() == name.lower()), None)
    if pal is None:
        return

    colors = []
    for key in ORDER:
        hexv = pal["colors"][key]["hex"].lstrip("#")
        colors.append(tuple(int(hexv[i:i + 2], 16) for i in (0, 2, 4)))

    w, h = 360, 200
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    band = h // len(colors)
    for i, color in enumerate(colors):
        y0 = i * band
        y1 = (i + 1) * band - 1 if i < len(colors) - 1 else h - 1
        draw.rectangle([0, y0, w, y1], fill=color)

    sys.stdout.buffer.write(b"")
    img.save(sys.stdout.buffer, "PNG")


if __name__ == "__main__":
    main()
