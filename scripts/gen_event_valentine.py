#!/usr/bin/env python3
"""App Store In-App Event art for the Puppy Love Challenge (Feb 1-28 2027).

Same layout as gen_event_newyear.py: pups/tiles from gen_event_card.py, wearing the
in-game heart headband (gen_costumes.py "valentine") on the Puppy Love palette
(BoardTheme.swift "puppylove"), floating hearts instead of confetti. Text-free.
Renders with Edge headless (Chrome headless hangs on this machine).
Outputs store/events/puppylove/card_1920x1080.png + details_1080x1920.png.
"""
import os, random, subprocess
import gen_event_card as base

OUT = os.path.join(base.ROOT, "store", "events", "puppylove")
PINKS = ["#F7A8B8", "#E8586E", "#D98FC0", "#C7466A", "#F4B6C9", "#FBD3DC"]
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"


def heart_headband():
    return ('<g>'
            '<path d="M62 104 Q120 58 178 104" fill="none" stroke="#C7466A" stroke-width="12" stroke-linecap="round"/>'
            '<path d="M96 78 Q88 52 80 34" fill="none" stroke="#C7466A" stroke-width="4" stroke-linecap="round"/>'
            '<path d="M144 78 Q152 52 160 34" fill="none" stroke="#C7466A" stroke-width="4" stroke-linecap="round"/>'
            '<path d="M80 44 C62 30 56 12 70 6 C78 3 80 10 80 14 C80 10 82 3 90 6 C104 12 98 30 80 44 Z" fill="#E8586E" stroke="#B03A55" stroke-width="2"/>'
            '<path d="M160 44 C142 30 136 12 150 6 C158 3 160 10 160 14 C160 10 162 3 170 6 C184 12 178 30 160 44 Z" fill="#F7A8B8" stroke="#B03A55" stroke-width="2"/>'
            '</g>')


base.santa_hat = heart_headband


def defs():
    return base.defs().replace(
        '<radialGradient id="snow" cx="50%" cy="30%" r="85%"><stop offset="0" stop-color="#FBFEFF"/><stop offset="1" stop-color="#CFE6F2"/></radialGradient>',
        '<radialGradient id="snow" cx="50%" cy="28%" r="90%"><stop offset="0" stop-color="#FFF4F6"/><stop offset="0.6" stop-color="#FCDDE4"/><stop offset="1" stop-color="#F6C2CF"/></radialGradient>')


def heart(x, y, s, c, rot, op):
    return (f'<g transform="translate({x:.0f},{y:.0f}) rotate({rot:.0f}) scale({s:.2f})" opacity="{op:.2f}">'
            f'<path d="M0 12 C-14 2 -18 -10 -9 -14 C-4 -16 0 -12 0 -8 C0 -12 4 -16 9 -14 C18 -10 14 2 0 12 Z" fill="{c}"/></g>')


def hearts(w, h, n, rng):
    out = []
    for _ in range(n):
        x, y = rng.uniform(0, w), rng.uniform(0, h * 0.78)
        if x < w * 0.45 and y > h * 0.55:
            continue
        out.append(heart(x, y, rng.uniform(0.8, 2.6), rng.choice(PINKS), rng.uniform(-25, 25), rng.uniform(0.45, 0.9)))
    return out


def scene(w, h):
    rng = random.Random(214)
    cx = w / 2
    el = [f'<rect width="{w}" height="{h}" fill="url(#snow)"/>',
          f'<path d="M0 {h} L0 {h*0.86} Q {w*0.25} {h*0.80} {w*0.5} {h*0.85} Q {w*0.78} {h*0.90} {w} {h*0.83} L {w} {h} Z" fill="#FFFFFF" opacity="0.45"/>']
    el += hearts(w, h, 70, rng)
    if w > h:
        el += [heart(w*0.86, h*0.18, 6.5, "#E8586E", 10, 0.9), heart(w*0.66, h*0.10, 4.0, "#F7A8B8", -12, 0.9)]
        b = h * 0.64
        tiles = [("#F7A8B8", "husky"), ("#E8586E", "golden"), ("#FBD3DC", "poodle"), ("#D98FC0", "shiba")]
        n = len(tiles)
        for i, (c, k) in enumerate(tiles):
            t = i - (n - 1) / 2
            el.append(base.tile(cx + w*0.16 + t*w*0.13, h*0.38 - abs(t)*h*0.05, h*0.30, c, t*5, k, hat=(k == "golden")))
        el.append(base.place("corgi", cx - w*0.30, b + h*0.06, h*0.60, -3, hat=True))
        el.append(base.place("husky", cx - w*0.12, b + h*0.12, h*0.44, 4, hat=True))
    else:
        el += [heart(w*0.78, h*0.10, 7.0, "#E8586E", 10, 0.9), heart(w*0.24, h*0.08, 4.5, "#F7A8B8", -12, 0.9)]
        b = h * 0.46
        tiles = [("#F7A8B8", "husky"), ("#E8586E", "golden"), ("#FBD3DC", "poodle"), ("#D98FC0", "shiba"), ("#F4B6C9", "corgi")]
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
    udd = os.path.join(os.environ.get("TEMP", "."), "pupdoku_event_edge")
    for name, (w, h) in {"card_1920x1080": (1920, 1080), "details_1080x1920": (1080, 1920)}.items():
        html = os.path.join(OUT, name + ".html")
        open(html, "w", encoding="utf-8").write(base.html_wrap(scene(w, h)))
        png = os.path.join(OUT, name + ".png")
        try:
            subprocess.run([EDGE, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
                            f"--user-data-dir={udd}_{name}", "--force-device-scale-factor=1",
                            f"--window-size={w},{h}", f"--screenshot={png}", "file:///" + html.replace("\\", "/")],
                           check=False, capture_output=True, timeout=90)
        except subprocess.TimeoutExpired:
            pass
        os.remove(html)
        print(("rendered " if os.path.exists(png) else "FAILED ") + png)


if __name__ == "__main__":
    main()
