#!/usr/bin/env python3
"""App Store In-App Event art for the New Year Pup Challenge (Jan 4-31 2027).

Reuses the pups/tiles from gen_event_card.py (Winter Pass art) with the in-game
party hat (gen_costumes.py "newyear") and the New Year Confetti board palette
(BoardTheme.swift "confetti"). Text-free; lower-left kept calm for Apple's overlay.

Outputs store/events/newyear/card_1920x1080.png + details_1080x1920.png.
"""
import os, random, subprocess
import gen_event_card as base

OUT = os.path.join(base.ROOT, "store", "events", "newyear")
CONFETTI = ["#F7C948", "#7FB8F0", "#F49AC1", "#8EDB9E", "#B79CF2", "#FFB36B", "#6FD3D1", "#F27B7B"]


def party_hat():
    # Same shape as the in-game costume (240-unit pup head space).
    return ('<g>'
            '<path d="M86 102 L124 14 L162 102 Z" fill="#B79CF2" stroke="#7E5CC8" stroke-width="2" stroke-linejoin="round"/>'
            '<path d="M100 70 L148 70 L156 88 L92 88 Z" fill="#F7C948"/>'
            '<path d="M112 42 L136 42 L141 54 L107 54 Z" fill="#F49AC1"/>'
            '<circle cx="122" cy="96" r="4" fill="#FFFFFF"/><circle cx="140" cy="62" r="3.5" fill="#FFFFFF"/>'
            '<circle cx="108" cy="62" r="3.5" fill="#FFFFFF"/>'
            '<rect x="80" y="96" width="88" height="12" rx="6" fill="#F27B7B"/>'
            '<circle cx="124" cy="14" r="11" fill="#F7C948" stroke="#D9A21E" stroke-width="2"/>'
            '</g>')


base.santa_hat = party_hat  # pup(..., hat=True) now wears the party hat


def defs():
    return base.defs().replace(
        '<radialGradient id="snow" cx="50%" cy="30%" r="85%"><stop offset="0" stop-color="#FBFEFF"/><stop offset="1" stop-color="#CFE6F2"/></radialGradient>',
        '<radialGradient id="snow" cx="50%" cy="28%" r="90%"><stop offset="0" stop-color="#FFF7E6"/><stop offset="0.6" stop-color="#FCE3C4"/><stop offset="1" stop-color="#F5C9A6"/></radialGradient>')


def confetti(w, h, n, rng, avoid_lower_left=True):
    out = []
    for _ in range(n):
        x, y = rng.uniform(0, w), rng.uniform(0, h * 0.75)
        if avoid_lower_left and x < w * 0.45 and y > h * 0.55:
            continue
        c = rng.choice(CONFETTI)
        rot = rng.uniform(0, 180)
        if rng.random() < 0.6:
            s = rng.uniform(10, 22)
            out.append(f'<rect x="{x:.0f}" y="{y:.0f}" width="{s:.0f}" height="{s*0.45:.0f}" rx="3" fill="{c}" '
                       f'transform="rotate({rot:.0f} {x:.0f} {y:.0f})" opacity="0.9"/>')
        else:
            out.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rng.uniform(4, 8):.1f}" fill="{c}" opacity="0.85"/>')
    return out


def burst(cx, cy, r, color):
    rays = "".join(f'<line x1="0" y1="{-r*0.35:.0f}" x2="0" y2="{-r:.0f}" transform="rotate({a})" stroke="{color}" '
                   f'stroke-width="{r*0.06:.1f}" stroke-linecap="round"/>' for a in range(0, 360, 30))
    return f'<g transform="translate({cx:.0f},{cy:.0f})" opacity="0.85">{rays}<circle r="{r*0.08:.1f}" fill="{color}"/></g>'


def scene(w, h):
    rng = random.Random(2027)
    cx = w / 2
    el = [f'<rect width="{w}" height="{h}" fill="url(#snow)"/>']
    el.append(f'<path d="M0 {h} L0 {h*0.86} Q {w*0.25} {h*0.80} {w*0.5} {h*0.85} '
              f'Q {w*0.78} {h*0.90} {w} {h*0.83} L {w} {h} Z" fill="#FFFFFF" opacity="0.45"/>')
    if w > h:
        el += [burst(w*0.86, h*0.16, h*0.13, "#F7C948"), burst(w*0.64, h*0.09, h*0.08, "#F49AC1"),
               burst(w*0.95, h*0.52, h*0.07, "#7FB8F0")]
    else:
        el += [burst(w*0.80, h*0.10, w*0.13, "#F7C948"), burst(w*0.22, h*0.08, w*0.09, "#F49AC1"),
               burst(w*0.55, h*0.05, w*0.06, "#7FB8F0")]
    el += confetti(w, h, 90, rng)

    if w / h >= 1.3:
        b = h * 0.64
        tiles = [("#7FB8F0", "husky"), ("#F7C948", "golden"), ("#F49AC1", "poodle"), ("#8EDB9E", "shiba")]
        n = len(tiles)
        for i, (c, k) in enumerate(tiles):
            t = i - (n - 1) / 2
            el.append(base.tile(cx + w*0.16 + t*w*0.13, h*0.36 - abs(t)*h*0.05, h*0.30, c, t*5, k, hat=(k == "golden")))
        el.append(base.place("corgi", cx - w*0.30, b + h*0.06, h*0.60, -3, hat=True))
        el.append(base.place("husky", cx - w*0.12, b + h*0.12, h*0.44, 4, hat=True))
    else:
        b = h * 0.46
        tiles = [("#7FB8F0", "husky"), ("#F7C948", "golden"), ("#F49AC1", "poodle"), ("#8EDB9E", "shiba"), ("#B79CF2", "corgi")]
        n = len(tiles)
        for i, (c, k) in enumerate(tiles):
            t = i - (n - 1) / 2
            el.append(base.tile(cx + t*w*0.17, b - h*0.12 - abs(t)*h*0.012, h*0.135, c, t*5, k, hat=(k == "golden")))
        el.append(base.place("corgi", cx - w*0.24, b + h*0.14, h*0.26, -3, hat=True))
        el.append(base.place("golden", cx + w*0.02, b + h*0.19, h*0.30, 2, hat=True))
        el.append(base.place("husky", cx + w*0.26, b + h*0.13, h*0.25, 5, hat=True))
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{defs()}'
            + "".join(el) + '</svg>')


def main():
    os.makedirs(OUT, exist_ok=True)
    browser = base.find_browser()
    udd = os.path.join(os.environ.get("TEMP", "."), "pupdoku_event_profile")
    for name, (w, h) in {"card_1920x1080": (1920, 1080), "details_1080x1920": (1080, 1920)}.items():
        html = os.path.join(OUT, name + ".html")
        open(html, "w", encoding="utf-8").write(base.html_wrap(scene(w, h)))
        png = os.path.join(OUT, name + ".png")
        try:
          subprocess.run([browser, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
                        "--no-default-browser-check", f"--user-data-dir={udd}_{name}", "--force-device-scale-factor=1",
                        f"--window-size={w},{h}", f"--screenshot={png}", "file:///" + html.replace("\\", "/")],
                       check=False, capture_output=True, timeout=90)
        except subprocess.TimeoutExpired:
            pass  # headless Chrome sometimes lingers after writing the PNG
        os.remove(html)
        print(("rendered " if os.path.exists(png) else "FAILED ") + png)


if __name__ == "__main__":
    main()
