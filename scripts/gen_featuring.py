#!/usr/bin/env python3
"""Generate Pupdoku App Store *featuring* creative art (the editorial "Header" and
"Search Result" placements from Apple's Creative Assets Templates).

Apple overlays its own title/subtitle text and crops per placement, so this art is
full-bleed, text-free, logo-free, and keeps the hero subjects inside a centered
safe area with the lower-left kept calm for Apple's text. Matches the v3.1 refresh
(gradient-shaded pups, warm cream world, colored board tiles).

Outputs to store/featuring/: header.svg + search.svg and (if a headless Chrome or
Edge is found) header.png (3840x1646) + search.png (3840x2560).
"""
import os, subprocess, math

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "store", "featuring")

# Artboard sizes from the template (name: (w, h))
ARTBOARDS = {"header": (3840, 1646), "search": (3840, 2560), "universal": (5244, 2950)}

PAL = ["#8FD08A", "#F2A65A", "#7FB3E0", "#EC87A6", "#F2CE5E", "#A78BD0", "#8FD9C4"]

# --- puppy (gradient version; rendered by real Chrome so gradients are safe) -----
def defs():
    return '''<defs>
  <radialGradient id="corgi" cx="42%" cy="34%" r="75%"><stop offset="0" stop-color="#F9C07E"/><stop offset="1" stop-color="#E8912F"/></radialGradient>
  <linearGradient id="corgiEar" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E8912F"/><stop offset="1" stop-color="#CF7A22"/></linearGradient>
  <radialGradient id="husky" cx="42%" cy="32%" r="78%"><stop offset="0" stop-color="#CBD7E2"/><stop offset="1" stop-color="#9DB1C4"/></radialGradient>
  <radialGradient id="poodle" cx="42%" cy="32%" r="78%"><stop offset="0" stop-color="#F6D3E6"/><stop offset="1" stop-color="#E6A7CC"/></radialGradient>
  <radialGradient id="golden" cx="42%" cy="32%" r="78%"><stop offset="0" stop-color="#FAD86A"/><stop offset="1" stop-color="#ECB62E"/></radialGradient>
  <radialGradient id="shiba" cx="42%" cy="32%" r="78%"><stop offset="0" stop-color="#F0A074"/><stop offset="1" stop-color="#D96E43"/></radialGradient>
  <radialGradient id="eye" cx="38%" cy="34%" r="70%"><stop offset="0" stop-color="#4a4a4a"/><stop offset="1" stop-color="#1d1d1d"/></radialGradient>
  <radialGradient id="sky" cx="50%" cy="38%" r="75%"><stop offset="0" stop-color="#FFFBF4"/><stop offset="1" stop-color="#FBE6CC"/></radialGradient>
</defs>'''

def pup(kind):
    fur = f"url(#{kind})"
    if kind == "corgi":
        ears = ('<path d="M60 108 Q40 36 86 76 Z" fill="url(#corgiEar)"/>'
                '<path d="M180 108 Q200 36 154 76 Z" fill="url(#corgiEar)"/>')
    elif kind in ("husky", "shiba"):
        ec = "#5C6B7A" if kind == "husky" else "#C8573A"
        ears = (f'<path d="M60 108 Q40 36 86 76 Z" fill="{ec}"/>'
                f'<path d="M180 108 Q200 36 154 76 Z" fill="{ec}"/>')
    else:
        ec = {"poodle": "#E7B4CE", "golden": "#E0A93C"}[kind]
        ears = (f'<ellipse cx="48" cy="150" rx="27" ry="50" transform="rotate(-14 48 150)" fill="{ec}"/>'
                f'<ellipse cx="192" cy="150" rx="27" ry="50" transform="rotate(14 192 150)" fill="{ec}"/>')
    muzzle = {"corgi": "#FCEBD2", "husky": "#F3F5F7", "poodle": "#FBECF4",
              "golden": "#FBE7B0", "shiba": "#FBEEE4"}[kind]
    blue = kind == "husky"
    pom = ('<circle cx="120" cy="60" r="30" fill="#F2C3DC"/><circle cx="98" cy="74" r="20" fill="#F2C3DC"/>'
           '<circle cx="142" cy="74" r="20" fill="#F2C3DC"/>') if kind == "poodle" else ""
    cap = ('<path d="M120 60 Q54 68 60 150 Q90 120 120 120 Q150 120 180 150 Q186 68 120 60 Z" fill="#5C6B7A"/>'
           ) if kind == "husky" else ""
    eye = "#5AA9E6" if blue else "url(#eye)"
    bluep = ('<circle cx="90" cy="120" r="7" fill="#1d2b36"/><circle cx="150" cy="120" r="7" fill="#1d2b36"/>'
             ) if blue else ""
    return (f'<g>'
            f'<ellipse cx="120" cy="212" rx="70" ry="14" fill="rgba(0,0,0,.12)"/>{pom}{ears}'
            f'<ellipse cx="120" cy="130" rx="86" ry="80" fill="{fur}"/>{cap}'
            f'<ellipse cx="120" cy="168" rx="46" ry="34" fill="{muzzle}"/>'
            f'<ellipse cx="78" cy="150" rx="12" ry="9" fill="#FF9E9E" opacity=".4"/>'
            f'<ellipse cx="162" cy="150" rx="12" ry="9" fill="#FF9E9E" opacity=".4"/>'
            f'<circle cx="90" cy="120" r="15" fill="{eye}"/><circle cx="150" cy="120" r="15" fill="{eye}"/>{bluep}'
            f'<circle cx="95" cy="114" r="4.5" fill="#fff"/><circle cx="155" cy="114" r="4.5" fill="#fff"/>'
            f'<path d="M108 156 Q120 170 132 156 Q120 150 108 156 Z" fill="#2B2B2B"/>'
            f'<path d="M120 166 V180" stroke="#2B2B2B" stroke-width="3.2" stroke-linecap="round"/>'
            f'<path d="M120 180 Q107 193 94 184 M120 180 Q133 193 146 184" stroke="#2B2B2B" stroke-width="3.2" fill="none" stroke-linecap="round"/>'
            f'</g>')

def place(kind, cx, cy, scale, rot=0):
    """Drop a 240-unit pup centered at (cx,cy), scaled, optionally rotated."""
    s = scale / 240.0
    return (f'<g transform="translate({cx},{cy}) rotate({rot}) scale({s}) translate(-120,-120)">{pup(kind)}</g>')

def tile(cx, cy, size, color, rot, kind):
    """A rounded board tile (depth + brown frame) holding a pup."""
    h = size / 2
    r = size * 0.16
    inset = size * 0.14
    return (f'<g transform="translate({cx},{cy}) rotate({rot})">'
            f'<rect x="{-h}" y="{-h}" width="{size}" height="{size}" rx="{r}" fill="{color}" stroke="#6E5B44" stroke-width="{size*0.045}"/>'
            f'<rect x="{-h}" y="{-h}" width="{size}" height="{size*0.5}" rx="{r}" fill="#ffffff" opacity="0.18"/>'
            f'<g transform="translate(0,{size*0.03}) scale({(size-inset*2)/240.0}) translate(-120,-120)">{pup(kind)}</g>'
            f'</g>')

def paw(cx, cy, s, color, op=0.5, rot=0):
    return (f'<g transform="translate({cx},{cy}) rotate({rot}) scale({s})" fill="{color}" opacity="{op}">'
            f'<ellipse cx="0" cy="6" rx="12" ry="10"/>'
            f'<circle cx="-11" cy="-9" r="5"/><circle cx="-3" cy="-14" r="5"/>'
            f'<circle cx="6" cy="-14" r="5"/><circle cx="14" cy="-9" r="5"/></g>')

def bone(cx, cy, s, color, op=0.5, rot=0):
    return (f'<g transform="translate({cx},{cy}) rotate({rot}) scale({s})" fill="{color}" opacity="{op}">'
            f'<rect x="-14" y="-5" width="28" height="10" rx="5"/>'
            f'<circle cx="-14" cy="-6" r="7"/><circle cx="-14" cy="6" r="7"/>'
            f'<circle cx="14" cy="-6" r="7"/><circle cx="14" cy="6" r="7"/></g>')

def scene(w, h):
    cx = w / 2
    el = [f'<rect width="{w}" height="{h}" fill="url(#sky)"/>']
    # soft sun rays behind the cluster
    rays = []
    rcx, rcy = cx + w * 0.06, h * 0.40
    for a in range(0, 360, 30):
        x2 = rcx + math.cos(math.radians(a)) * w
        y2 = rcy + math.sin(math.radians(a)) * w
        rays.append(f'<polygon points="{rcx},{rcy} {x2-60},{y2} {x2+60},{y2}" fill="#F6B86A" opacity="0.05"/>')
    el.append('<g>' + "".join(rays) + '</g>')

    # scattered confetti (kept lighter on the lower-left for Apple's text overlay)
    el += [
        bone(w*0.74, h*0.16, 2.4, "#E8B07A", 0.5, -18),
        paw(w*0.84, h*0.30, 2.2, "#E8B07A", 0.45, 12),
        paw(w*0.68, h*0.10, 1.8, "#EAC08E", 0.4, -8),
        bone(w*0.90, h*0.55, 2.0, "#E8B07A", 0.4, 24),
        paw(w*0.30, h*0.12, 1.6, "#EAC08E", 0.35, -16),
    ]

    r = w / h
    if r >= 2.0:      # ---- Header: wide parade arc ----
        base = h * 0.60
        tiles = [("#7FB3E0","husky"),("#F2CE5E","golden"),("#EC87A6","poodle"),("#8FD08A","shiba")]
        n = len(tiles)
        for i,(c,k) in enumerate(tiles):
            t = (i-(n-1)/2)
            x = cx + w*0.14 + t*w*0.135
            y = base - abs(t)*h*0.05 - h*0.02
            el.append(tile(x, y, h*0.34, c, t*5, k))
        # two hero pups up front
        el.append(place("corgi", cx - w*0.30, base + h*0.06, h*0.62))
        el.append(place("golden", cx - w*0.12, base + h*0.12, h*0.46, 4))
    elif r >= 1.65:   # ---- 16x9 Universal: wide hero, tiles arced upper-right ----
        base = h * 0.64
        tiles = [("#7FB3E0","husky"),("#F2CE5E","golden"),("#EC87A6","poodle"),("#8FD08A","shiba"),("#A78BD0","corgi")]
        n = len(tiles)
        for i,(c,k) in enumerate(tiles):
            t = (i-(n-1)/2)
            x = cx + w*0.14 + t*w*0.125
            y = h*0.33 - abs(t)*h*0.045
            el.append(tile(x, y, h*0.24, c, t*5, k))
        # hero trio lower-left of center
        el.append(place("corgi",  cx - w*0.34, base + h*0.05, h*0.52, -3))
        el.append(place("golden", cx - w*0.17, base + h*0.11, h*0.40, 3))
        el.append(place("shiba",  cx - w*0.02, base + h*0.04, h*0.34, 6))
    else:             # ---- Search Result: taller cluster ----
        base = h * 0.54
        # fanned tile row
        tiles = [("#7FB3E0","husky"),("#F2CE5E","golden"),("#EC87A6","poodle"),("#8FD08A","shiba"),("#A78BD0","corgi")]
        n = len(tiles)
        for i,(c,k) in enumerate(tiles):
            t = (i-(n-1)/2)
            x = cx + t*w*0.165
            y = base - h*0.20 - abs(t)*h*0.015
            el.append(tile(x, y, h*0.215, c, t*5, k))
        # hero trio in front
        el.append(place("corgi",  cx - w*0.22, base + h*0.16, h*0.40, -3))
        el.append(place("golden", cx + w*0.02, base + h*0.22, h*0.46, 2))
        el.append(place("husky",  cx + w*0.26, base + h*0.15, h*0.38, 5))

    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">{defs()}' + "".join(el) + '</svg>')

def html_wrap(svg):
    return f'<!doctype html><html><head><meta charset="utf-8"><style>*{{margin:0;padding:0}}html,body{{overflow:hidden}}</style></head><body>{svg}</body></html>'

def find_browser():
    for p in [r"C:\Program Files\Google\Chrome\Application\chrome.exe",
              r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"]:
        if os.path.exists(p):
            return p
    return None

def main():
    os.makedirs(OUT, exist_ok=True)
    browser = find_browser()
    for name, (w, h) in ARTBOARDS.items():
        svg = scene(w, h)
        with open(os.path.join(OUT, f"{name}.svg"), "w", encoding="utf-8") as f:
            f.write(svg)
        html_path = os.path.join(OUT, f"{name}.html")
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(html_wrap(svg))
        print("wrote", name + ".svg")
        if browser:
            png = os.path.join(OUT, f"{name}.png")
            subprocess.run([browser, "--headless", "--disable-gpu", "--hide-scrollbars",
                            "--force-device-scale-factor=1", f"--window-size={w},{h}",
                            f"--screenshot={png}", "file:///" + html_path.replace("\\", "/")],
                           check=False, capture_output=True)
            ok = os.path.exists(png)
            print(("rendered " if ok else "FAILED  ") + name + ".png")

if __name__ == "__main__":
    main()
