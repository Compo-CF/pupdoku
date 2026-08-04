#!/usr/bin/env python3
"""Draw the Pupdoku app icon (1024x1024 PNG) with Pillow.

Concept: a big friendly corgi hero on a cool contrasting background (so the warm
orange pup pops), peeking over a small colorful sudoku-grid strip at the bottom —
one strong character PLUS a clear "puzzle" cue. Rendered at 2x then downscaled.
"""
import os
from PIL import Image, ImageDraw

K = 2
OUT = os.path.join(os.path.dirname(__file__), "..", "Pupdoku", "Resources",
                   "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")

def lerp(a, b, t): return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(3))
def Hx(s):
    s = s.lstrip("#"); return (int(s[0:2],16), int(s[2:4],16), int(s[4:6],16))

def main():
    S = 1024 * K
    img = Image.new("RGB", (S, S), Hx("BFE0F2"))
    d = ImageDraw.Draw(img, "RGBA")

    # Cool sky-blue gradient — contrast for the warm corgi.
    top, bot = Hx("CBE8F7"), Hx("8FBFE8")
    for y in range(S):
        d.line([(0, y), (S, y)], fill=lerp(top, bot, y / S))

    def R(*v): return tuple(int(x * K) for x in v)
    def px(x): return int(x * K)

    def face(cx, cy, r, fur, ear, inner_ear, muzzle, ears="up",
             blue=False, cap=None, pom=False, nose="2B2B2B", outline=None):
        def E(x0, y0, x1, y1, fill):
            d.ellipse(R(x0, y0, x1, y1), fill=Hx(fill) if isinstance(fill, str) else fill)
        ow = px(r*0.03)
        # ears (behind head)
        if ears == "up":
            d.polygon([R(cx-r*0.7, cy-r*0.2)[:2], R(cx-r*0.85, cy-r*1.15)[:2], R(cx-r*0.15, cy-r*0.55)[:2]], fill=Hx(ear))
            d.polygon([R(cx+r*0.7, cy-r*0.2)[:2], R(cx+r*0.85, cy-r*1.15)[:2], R(cx+r*0.15, cy-r*0.55)[:2]], fill=Hx(ear))
            d.polygon([R(cx-r*0.62, cy-r*0.3)[:2], R(cx-r*0.7, cy-r*0.9)[:2], R(cx-r*0.28, cy-r*0.5)[:2]], fill=Hx(inner_ear))
            d.polygon([R(cx+r*0.62, cy-r*0.3)[:2], R(cx+r*0.7, cy-r*0.9)[:2], R(cx+r*0.28, cy-r*0.5)[:2]], fill=Hx(inner_ear))
        elif ears == "floppy":
            E(cx-r*1.05, cy-r*0.35, cx-r*0.35, cy+r*0.95, ear)
            E(cx+r*0.35, cy-r*0.35, cx+r*1.05, cy+r*0.95, ear)
        if pom:
            for (dx, dy, rr) in [(0,-0.95,0.5),(-0.5,-0.7,0.4),(0.5,-0.7,0.4)]:
                E(cx+dx*r-rr*r, cy+dy*r-rr*r, cx+dx*r+rr*r, cy+dy*r+rr*r, ear)
        # head
        d.ellipse(R(cx-r, cy-r*0.92, cx+r, cy+r*0.92), fill=Hx(fur),
                  outline=Hx(outline) if outline else None, width=ow if outline else 0)
        if cap:
            d.pieslice(R(cx-r, cy-r*0.92, cx+r, cy+r*0.92), 180, 360, fill=Hx(cap))
        # muzzle
        E(cx-r*0.62, cy+r*0.1, cx+r*0.62, cy+r*0.85, muzzle)
        # cheeks (corgi warmth)
        if fur == "F2A65A":
            d.ellipse(R(cx-r*0.9, cy+r*0.25, cx-r*0.55, cy+r*0.6), fill=(255,158,158,70))
            d.ellipse(R(cx+r*0.55, cy+r*0.25, cx+r*0.9, cy+r*0.6), fill=(255,158,158,70))
        # eyes
        ex, ey, er = r*0.42, r*0.15, r*0.17
        if blue:
            E(cx-ex-er, cy-ey-er, cx-ex+er, cy-ey+er, "5AA9E6")
            E(cx+ex-er, cy-ey-er, cx+ex+er, cy-ey+er, "5AA9E6")
            e2 = r*0.09
            E(cx-ex-e2, cy-ey-e2, cx-ex+e2, cy-ey+e2, "20313F")
            E(cx+ex-e2, cy-ey-e2, cx+ex+e2, cy-ey+e2, "20313F")
        else:
            E(cx-ex-er, cy-ey-er, cx-ex+er, cy-ey+er, "2B2B2B")
            E(cx+ex-er, cy-ey-er, cx+ex+er, cy-ey+er, "2B2B2B")
        hr = r*0.055
        E(cx-ex-hr+r*0.06, cy-ey-hr-r*0.06, cx-ex+hr+r*0.06, cy-ey+hr-r*0.06, "FFFFFF")
        E(cx+ex-hr+r*0.06, cy-ey-hr-r*0.06, cx+ex+hr+r*0.06, cy-ey+hr-r*0.06, "FFFFFF")
        # nose + smile
        d.polygon([R(cx-r*0.16, cy+r*0.34)[:2], R(cx+r*0.16, cy+r*0.34)[:2], R(cx, cy+r*0.52)[:2]], fill=Hx(nose))
        d.line([R(cx, cy+r*0.5)[:2], R(cx, cy+r*0.66)[:2]], fill=Hx(nose), width=px(r*0.05))
        d.arc(R(cx-r*0.3, cy+r*0.5, cx, cy+r*0.82), 20, 160, fill=Hx(nose), width=px(r*0.05))
        d.arc(R(cx, cy+r*0.5, cx+r*0.3, cy+r*0.82), 20, 160, fill=Hx(nose), width=px(r*0.05))

    # ---- hero corgi ----
    face(512, 356, 290, fur="F2A65A", ear="E8933F", inner_ear="F6C79A",
         muzzle="FBEAD2", ears="up")

    # ---- sudoku-grid strip (the puzzle cue) ----
    gx0, gy0, gx1, gy1 = 128, 672, 896, 916
    line = Hx("E8933F")
    d.rounded_rectangle(R(gx0, gy0, gx1, gy1), radius=px(40), fill=Hx("FFFFFF"),
                        outline=line, width=px(12))
    w = gx1 - gx0
    for i in (1, 2):
        x = gx0 + w * i / 3
        d.line([R(x, gy0+14)[:2], R(x, gy1-14)[:2]], fill=line, width=px(14))
    cy = (gy0 + gy1) / 2
    sr = 78
    centers = [gx0 + w*(1/6), gx0 + w*(3/6), gx0 + w*(5/6)]
    # Husky (blue), Golden (yellow), Poodle (pink) — color variety
    face(centers[0], cy, sr, fur="B8C6D4", ear="5C6B7A", inner_ear="D9DFE6",
         muzzle="F3F5F7", ears="up", blue=True, cap="5C6B7A")
    face(centers[1], cy, sr, fur="F4C542", ear="E0A93C", inner_ear="F4D488",
         muzzle="FBE7B0", ears="floppy")
    face(centers[2], cy, sr, fur="EFC7DC", ear="E7B4CE", inner_ear="F4D6E6",
         muzzle="FBECF4", ears="floppy", pom=True, nose="7A4A63")

    img = img.resize((1024, 1024), Image.LANCZOS)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, "PNG")
    print("wrote", OUT)

if __name__ == "__main__":
    main()
