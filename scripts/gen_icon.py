#!/usr/bin/env python3
"""Draw the Pupdoku app icon (1024x1024 PNG) with Pillow.

Concept: a mini sudoku board (2x2) with four DIFFERENT, colorful breeds in the
cells — so the icon reads instantly as "a puzzle, with puppies" and brings real
color contrast (orange / blue / yellow / pink) rather than a single hue.
Rendered at 2x then downscaled for smooth antialiasing.
"""
import os
from PIL import Image, ImageDraw

K = 2                     # supersample factor
OUT = os.path.join(os.path.dirname(__file__), "..", "Pupdoku", "Resources",
                   "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")

def lerp(a, b, t): return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(3))
def H(s):
    s = s.lstrip("#"); return (int(s[0:2],16), int(s[2:4],16), int(s[4:6],16))

def main():
    S = 1024 * K
    img = Image.new("RGB", (S, S), H("FFF3E4"))
    d = ImageDraw.Draw(img, "RGBA")

    # Warm cream background gradient.
    top, bot = H("FFF1DC"), H("F8D9AE")
    for y in range(S):
        d.line([(0, y), (S, y)], fill=lerp(top, bot, y / S))

    def R(*v): return tuple(int(x * K) for x in v)   # scale a tuple of coords
    def px(x): return int(x * K)

    # ---- board ----
    m = 96
    lw = 30                          # grid line width
    inner = 1024 - 2 * m
    cell = (inner - lw) // 2         # 419
    line = H("E8933F")

    # outer rounded board with soft shadow + orange frame
    d.rounded_rectangle(R(m-8, m-8, 1024-m+8, 1024-m+8), radius=px(70),
                        fill=H("FFFFFF"), outline=line, width=px(10))

    # cell rectangles (white) — draw the cross grid lines by leaving a gap
    cells = [
        (m,               m,               m+cell,          m+cell),           # TL
        (m+cell+lw,       m,               1024-m,          m+cell),           # TR
        (m,               m+cell+lw,       m+cell,          1024-m),           # BL
        (m+cell+lw,       m+cell+lw,       1024-m,          1024-m),           # BR
    ]
    for (x0, y0, x1, y1) in cells:
        d.rounded_rectangle(R(x0, y0, x1, y1), radius=px(26), fill=H("FFFFFF"))

    # bold cross grid lines
    cx_mid = m + cell + lw // 2
    d.line([R(cx_mid, m)[:2], R(cx_mid, 1024-m)[:2]], fill=line, width=px(lw))
    d.line([R(m, cx_mid)[:2], R(1024-m, cx_mid)[:2]], fill=line, width=px(lw))

    # ---- puppy faces, one per cell ----
    def face(cx, cy, r, fur, ear, inner_ear, muzzle, ears="up",
             blue=False, cap=None, pom=False, nose="2B2B2B"):
        cx, cy, r = cx, cy, r
        def E(x0, y0, x1, y1, fill): d.ellipse(R(x0, y0, x1, y1), fill=H(fill) if isinstance(fill,str) else fill)
        # ears (behind head)
        if ears == "up":
            d.polygon([R(cx-r*0.7, cy-r*0.2)[:2], R(cx-r*0.85, cy-r*1.15)[:2], R(cx-r*0.15, cy-r*0.55)[:2]], fill=H(ear))
            d.polygon([R(cx+r*0.7, cy-r*0.2)[:2], R(cx+r*0.85, cy-r*1.15)[:2], R(cx+r*0.15, cy-r*0.55)[:2]], fill=H(ear))
            d.polygon([R(cx-r*0.62, cy-r*0.3)[:2], R(cx-r*0.7, cy-r*0.9)[:2], R(cx-r*0.28, cy-r*0.5)[:2]], fill=H(inner_ear))
            d.polygon([R(cx+r*0.62, cy-r*0.3)[:2], R(cx+r*0.7, cy-r*0.9)[:2], R(cx+r*0.28, cy-r*0.5)[:2]], fill=H(inner_ear))
        elif ears == "floppy":
            E(cx-r*1.05, cy-r*0.35, cx-r*0.35, cy+r*0.95, ear)
            E(cx+r*0.35, cy-r*0.35, cx+r*1.05, cy+r*0.95, ear)
        # pom (poodle) — fluffy top
        if pom:
            for (dx, dy, rr) in [(0,-0.95,0.5),(-0.5,-0.7,0.4),(0.5,-0.7,0.4)]:
                E(cx+dx*r-rr*r, cy+dy*r-rr*r, cx+dx*r+rr*r, cy+dy*r+rr*r, ear)
        # head
        E(cx-r, cy-r*0.92, cx+r, cy+r*0.92, fur)
        # cap/mask (husky)
        if cap:
            d.pieslice(R(cx-r, cy-r*0.92, cx+r, cy+r*0.92), 180, 360, fill=H(cap))
        # muzzle
        E(cx-r*0.62, cy+r*0.1, cx+r*0.62, cy+r*0.85, muzzle)
        # eyes
        ex, ey, er = r*0.42, r*0.15, r*0.17
        if blue:
            E(cx-ex-er, cy-ey-er, cx-ex+er, cy-ey+er, "5AA9E6")
            E(cx+ex-er, cy-ey-er, cx+ex+er, cy-ey+er, "5AA9E6")
            er2 = r*0.09
            E(cx-ex-er2, cy-ey-er2, cx-ex+er2, cy-ey+er2, "20313F")
            E(cx+ex-er2, cy-ey-er2, cx+ex+er2, cy-ey+er2, "20313F")
        else:
            E(cx-ex-er, cy-ey-er, cx-ex+er, cy-ey+er, "2B2B2B")
            E(cx+ex-er, cy-ey-er, cx+ex+er, cy-ey+er, "2B2B2B")
        # eye highlights
        hr = r*0.05
        E(cx-ex-hr+r*0.05, cy-ey-hr-r*0.05, cx-ex+hr+r*0.05, cy-ey+hr-r*0.05, "FFFFFF")
        E(cx+ex-hr+r*0.05, cy-ey-hr-r*0.05, cx+ex+hr+r*0.05, cy-ey+hr-r*0.05, "FFFFFF")
        # nose + smile
        d.polygon([R(cx-r*0.16, cy+r*0.34)[:2], R(cx+r*0.16, cy+r*0.34)[:2], R(cx, cy+r*0.52)[:2]], fill=H(nose))
        d.line([R(cx, cy+r*0.5)[:2], R(cx, cy+r*0.66)[:2]], fill=H(nose), width=px(r*0.045))
        d.arc(R(cx-r*0.3, cy+r*0.5, cx, cy+r*0.82), 20, 160, fill=H(nose), width=px(r*0.045))
        d.arc(R(cx, cy+r*0.5, cx+r*0.3, cy+r*0.82), 20, 160, fill=H(nose), width=px(r*0.045))

    # cell centers
    ctl = (m + cell//2,          m + cell//2)
    ctr = (m + cell + lw + cell//2, m + cell//2)
    cbl = (m + cell//2,          m + cell + lw + cell//2)
    cbr = (m + cell + lw + cell//2, m + cell + lw + cell//2)
    fr = cell * 0.30   # face radius

    # Corgi (orange), Husky (blue), Golden (yellow), Poodle (pink)
    face(*ctl, fr, fur="F2A65A", ear="E8933F", inner_ear="F6C79A", muzzle="FBEAD2", ears="up")
    face(*ctr, fr, fur="B8C6D4", ear="5C6B7A", inner_ear="D9DFE6", muzzle="F3F5F7", ears="up",
         blue=True, cap="5C6B7A")
    face(*cbl, fr, fur="F4C542", ear="E0A93C", inner_ear="F4D488", muzzle="FBE7B0", ears="floppy")
    face(*cbr, fr, fur="EFC7DC", ear="E7B4CE", inner_ear="F4D6E6", muzzle="FBECF4", ears="floppy",
         pom=True, nose="7A4A63")

    img = img.resize((1024, 1024), Image.LANCZOS)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, "PNG")
    print("wrote", OUT)

if __name__ == "__main__":
    main()
