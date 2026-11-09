#!/usr/bin/env python3
"""Generate Pupdoku App Store *In-App Event* art for the Winter Pass holiday event.

Apple overlays the event name / badge / short description on the lower-left of the
event card, so this art is text-free and keeps the lower-left calm. Festive winter
reskin of the v3.1 look: snowy icy-blue world, winter board tiles, Santa-hat pups.

Outputs to store/events/:
  card.svg   + card.png    1920 x 1080  (Event Card, landscape)
  detail.svg + detail.png  1080 x 1920  (Event Details page, portrait)

Uses an ISOLATED Chrome --user-data-dir so headless never contends with a Chrome
the user already has open (that profile lock hangs the launch).
"""
import os, subprocess, math

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "store", "events")

ARTBOARDS = {"card": (1920, 1080), "detail": (1080, 1920)}

# Winter board palette (from BoardTheme.swift "winter"): icy blues/whites + festive red
WINTER = ["#BFE3F5", "#9FC8E8", "#D64F4F", "#8FB8D8", "#5FA0C8"]


def defs():
    return '''<defs>
  <radialGradient id="corgi" cx="42%" cy="34%" r="75%"><stop offset="0" stop-color="#F9C07E"/><stop offset="1" stop-color="#E8912F"/></radialGradient>
  <linearGradient id="corgiEar" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E8912F"/><stop offset="1" stop-color="#CF7A22"/></linearGradient>
  <radialGradient id="husky" cx="42%" cy="32%" r="78%"><stop offset="0" stop-color="#CBD7E2"/><stop offset="1" stop-color="#9DB1C4"/></radialGradient>
  <radialGradient id="poodle" cx="42%" cy="32%" r="78%"><stop offset="0" stop-color="#F6D3E6"/><stop offset="1" stop-color="#E6A7CC"/></radialGradient>
  <radialGradient id="golden" cx="42%" cy="32%" r="78%"><stop offset="0" stop-color="#FAD86A"/><stop offset="1" stop-color="#ECB62E"/></radialGradient>
  <radialGradient id="shiba" cx="42%" cy="32%" r="78%"><stop offset="0" stop-color="#F0A074"/><stop offset="1" stop-color="#D96E43"/></radialGradient>
  <radialGradient id="eye" cx="38%" cy="34%" r="70%"><stop offset="0" stop-color="#4a4a4a"/><stop offset="1" stop-color="#1d1d1d"/></radialGradient>
  <radialGradient id="snow" cx="50%" cy="30%" r="85%"><stop offset="0" stop-color="#FBFEFF"/><stop offset="1" stop-color="#CFE6F2"/></radialGradient>
</defs>'''


def santa_hat():
    """A tilted Santa hat sitting on the top of a 240-unit pup's head."""
    return ('<g>'
            # red cone, drooping to the right
            '<path d="M58 80 Q64 24 150 30 Q150 58 160 76 Q110 62 58 80 Z" fill="#D64F4F"/>'
            '<path d="M58 80 Q64 24 150 30 Q120 44 100 72 Q80 72 58 80 Z" fill="#E86A6A" opacity="0.5"/>'
            # white fluffy brim
            '<rect x="46" y="70" width="116" height="22" rx="11" fill="#FBFEFF"/>'
            '<rect x="46" y="70" width="116" height="10" rx="5" fill="#E7F1FA" opacity="0.7"/>'
            # pom
            '<circle cx="156" cy="28" r="14" fill="#FBFEFF"/>'
            '</g>')


def pup(kind, hat=False):
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
    eye = "#5AA9E6" if blue else "url(#eye)"
    bluep = ('<circle cx="90" cy="120" r="7" fill="#1d2b36"/><circle cx="150" cy="120" r="7" fill="#1d2b36"/>'
             ) if blue else ""
    hatsvg = santa_hat() if hat else ""
    return (f'<g>'
            f'<ellipse cx="120" cy="212" rx="70" ry="14" fill="rgba(0,0,0,.12)"/>{ears}'
            f'<ellipse cx="120" cy="130" rx="86" ry="80" fill="{fur}"/>'
            f'<ellipse cx="120" cy="168" rx="46" ry="34" fill="{muzzle}"/>'
            f'<ellipse cx="78" cy="150" rx="12" ry="9" fill="#FF9E9E" opacity=".4"/>'
            f'<ellipse cx="162" cy="150" rx="12" ry="9" fill="#FF9E9E" opacity=".4"/>'
            f'<circle cx="90" cy="120" r="15" fill="{eye}"/><circle cx="150" cy="120" r="15" fill="{eye}"/>{bluep}'
            f'<circle cx="95" cy="114" r="4.5" fill="#fff"/><circle cx="155" cy="114" r="4.5" fill="#fff"/>'
            f'<path d="M108 156 Q120 170 132 156 Q120 150 108 156 Z" fill="#2B2B2B"/>'
            f'<path d="M120 166 V180" stroke="#2B2B2B" stroke-width="3.2" stroke-linecap="round"/>'
            f'<path d="M120 180 Q107 193 94 184 M120 180 Q133 193 146 184" stroke="#2B2B2B" stroke-width="3.2" fill="none" stroke-linecap="round"/>'
            f'{hatsvg}'
            f'</g>')


def place(kind, cx, cy, scale, rot=0, hat=False):
    s = scale / 240.0
    return f'<g transform="translate({cx},{cy}) rotate({rot}) scale({s}) translate(-120,-120)">{pup(kind, hat)}</g>'


def tile(cx, cy, size, color, rot, kind, hat=False):
    h = size / 2
    r = size * 0.16
    inset = size * 0.14
    return (f'<g transform="translate({cx},{cy}) rotate({rot})">'
            f'<rect x="{-h}" y="{-h}" width="{size}" height="{size}" rx="{r}" fill="{color}" stroke="#4A6B82" stroke-width="{size*0.045}"/>'
            f'<rect x="{-h}" y="{-h}" width="{size}" height="{size*0.5}" rx="{r}" fill="#ffffff" opacity="0.22"/>'
            f'<g transform="translate(0,{size*0.03}) scale({(size-inset*2)/240.0}) translate(-120,-120)">{pup(kind, hat)}</g>'
            f'</g>')


def flake(cx, cy, s, op=0.9):
    spokes = []
    for a in range(0, 180, 60):
        spokes.append(f'<line x1="{-10}" y1="0" x2="{10}" y2="0" transform="rotate({a})" '
                      f'stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round"/>')
    return (f'<g transform="translate({cx},{cy}) scale({s})" opacity="{op}">'
            + "".join(spokes) + '<circle r="2.2" fill="#FFFFFF"/></g>')


def dot(cx, cy, r, op):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#FFFFFF" opacity="{op}"/>'


def scene(w, h):
    cx = w / 2
    el = [f'<rect width="{w}" height="{h}" fill="url(#snow)"/>']

    # soft snow drift along the bottom
    el.append(f'<path d="M0 {h} L0 {h*0.86} Q {w*0.25} {h*0.80} {w*0.5} {h*0.85} '
              f'Q {w*0.78} {h*0.90} {w} {h*0.83} L {w} {h} Z" fill="#FFFFFF" opacity="0.55"/>')

    # falling snow + a few crisp flakes (kept lighter lower-left for Apple's text)
    snow_pts = [(0.72, 0.12, 4), (0.82, 0.22, 3), (0.64, 0.08, 3), (0.90, 0.40, 5),
                (0.30, 0.10, 3), (0.50, 0.14, 4), (0.86, 0.60, 4), (0.42, 0.06, 2.5),
                (0.94, 0.14, 3), (0.58, 0.26, 3), (0.76, 0.46, 2.5)]
    for fx, fy, r in snow_pts:
        el.append(dot(w*fx, h*fy, r, 0.8))
    el.append(flake(w*0.80, h*0.14, 1.6, 0.9))
    el.append(flake(w*0.68, h*0.30, 1.2, 0.8))
    el.append(flake(w*0.92, h*0.26, 1.0, 0.75))

    r = w / h
    if r >= 1.3:      # ---- Event Card: wide hero + arced tiles upper-right ----
        base = h * 0.64
        tiles = [("#9FC8E8", "husky"), ("#D64F4F", "golden"), ("#BFE3F5", "poodle"), ("#8FB8D8", "shiba")]
        n = len(tiles)
        for i, (c, k) in enumerate(tiles):
            t = (i - (n - 1) / 2)
            x = cx + w * 0.16 + t * w * 0.13
            y = h * 0.34 - abs(t) * h * 0.05
            el.append(tile(x, y, h * 0.30, c, t * 5, k, hat=(k == "golden")))
        # hero pups up front, lower-left of center, in Santa hats
        el.append(place("corgi",  cx - w * 0.30, base + h * 0.06, h * 0.60, -3, hat=True))
        el.append(place("husky",  cx - w * 0.12, base + h * 0.12, h * 0.44, 4, hat=True))
    else:             # ---- Event Details: tall cluster ----
        base = h * 0.46
        tiles = [("#9FC8E8", "husky"), ("#D64F4F", "golden"), ("#BFE3F5", "poodle"),
                 ("#8FB8D8", "shiba"), ("#5FA0C8", "corgi")]
        n = len(tiles)
        for i, (c, k) in enumerate(tiles):
            t = (i - (n - 1) / 2)
            x = cx + t * w * 0.17
            y = base - h * 0.12 - abs(t) * h * 0.012
            el.append(tile(x, y, h * 0.135, c, t * 5, k, hat=(k == "golden")))
        # hero trio in front, in Santa hats
        el.append(place("corgi",  cx - w * 0.24, base + h * 0.14, h * 0.26, -3, hat=True))
        el.append(place("golden", cx + w * 0.02, base + h * 0.19, h * 0.30, 2, hat=True))
        el.append(place("husky",  cx + w * 0.26, base + h * 0.13, h * 0.25, 5, hat=True))

    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">{defs()}' + "".join(el) + '</svg>')


def html_wrap(svg):
    return (f'<!doctype html><html><head><meta charset="utf-8">'
            f'<style>*{{margin:0;padding:0}}html,body{{overflow:hidden}}</style></head>'
            f'<body>{svg}</body></html>')


def find_browser():
    for p in [r"C:\Program Files\Google\Chrome\Application\chrome.exe",
              r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"]:
        if os.path.exists(p):
            return p
    return None


def main():
    os.makedirs(OUT, exist_ok=True)
    browser = find_browser()
    udd = os.path.join(os.environ.get("TEMP", "."), "pupdoku_event_profile")
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
            subprocess.run([browser, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                            "--no-first-run", "--no-default-browser-check",
                            f"--user-data-dir={udd}",
                            "--force-device-scale-factor=1", f"--window-size={w},{h}",
                            f"--screenshot={png}", "file:///" + html_path.replace("\\", "/")],
                           check=False, capture_output=True, timeout=60)
            ok = os.path.exists(png)
            print(("rendered " if ok else "FAILED  ") + name + ".png")


if __name__ == "__main__":
    main()
