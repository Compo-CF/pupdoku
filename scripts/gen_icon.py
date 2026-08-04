#!/usr/bin/env python3
"""Draw the Pupdoku app icon (1024x1024 PNG) with Pillow.

A friendly corgi face on a warm gradient, with a faint 3x3 sudoku grid behind it
to tie the puppy theme to the puzzle. Rendered at 2x then downscaled for smooth
antialiased edges. Output goes straight into the AppIcon.appiconset.
"""
import os, math
from PIL import Image, ImageDraw

S = 2048  # supersample
OUT = os.path.join(os.path.dirname(__file__), "..", "Pupdoku", "Resources",
                   "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")

def lerp(a, b, t): return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(3))

def main():
    img = Image.new("RGB", (S, S), (242, 166, 90))
    d = ImageDraw.Draw(img, "RGBA")

    # Vertical gradient background.
    top, bot = (255, 201, 138), (232, 138, 63)
    for y in range(S):
        d.line([(0, y), (S, y)], fill=lerp(top, bot, y / S))

    # Faint 3x3 grid to hint "sudoku".
    grid = (255, 255, 255, 40)
    for i in range(1, 3):
        x = S * i / 3
        d.line([(x, 0), (x, S)], fill=grid, width=6)
        y = S * i / 3
        d.line([(0, y), (S, y)], fill=grid, width=6)

    sc = S / 240.0  # reuse the 240-unit face coordinate system
    def P(x, y): return (x * sc, y * sc)
    def ell(cx, cy, rx, ry, fill):
        d.ellipse([P(cx-rx, cy-ry), P(cx+rx, cy+ry)], fill=fill)

    # Face is shifted down a touch and enlarged for icon presence.
    CX, CY = 120, 128
    # Ears (upright corgi).
    d.polygon([P(60,110), P(58,44), P(92,80)], fill=(232,147,63))
    d.polygon([P(180,110), P(182,44), P(148,80)], fill=(232,147,63))
    d.polygon([P(68,96), P(64,58), P(88,82)], fill=(246,199,154))
    d.polygon([P(172,96), P(176,58), P(152,82)], fill=(246,199,154))
    # Head.
    ell(CX, CY, 84, 78, (242, 166, 90))
    # Muzzle.
    ell(CX, 168, 46, 34, (251, 234, 210))
    # Eyes.
    ell(120-32, 118, 14, 14, (43, 43, 43))
    ell(120+32, 118, 14, 14, (43, 43, 43))
    ell(120-32+5, 118-5, 4, 4, (255, 255, 255))
    ell(120+32+5, 118-5, 4, 4, (255, 255, 255))
    # Cheeks.
    d.ellipse([P(58,150),P(82,174)], fill=(255,158,158,90))
    d.ellipse([P(158,150),P(182,174)], fill=(255,158,158,90))
    # Nose + smile.
    d.polygon([P(108,156), P(132,156), P(120,170)], fill=(43,43,43))
    d.line([P(120,168), P(120,182)], fill=(43,43,43), width=int(3.4*sc))
    d.arc([P(96,168),P(120,192)], 20, 160, fill=(43,43,43), width=int(3.4*sc))
    d.arc([P(120,168),P(144,192)], 20, 160, fill=(43,43,43), width=int(3.4*sc))

    img = img.resize((1024, 1024), Image.LANCZOS)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, "PNG")
    print("wrote", OUT)

if __name__ == "__main__":
    main()
