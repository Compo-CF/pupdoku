#!/usr/bin/env python3
"""Generate App Store marketing screenshots for Pupdoku in the v3.1 look.

These depict the REAL game — "Find the Puppies" (a Queens-style logic puzzle:
one puppy per row, column, and colored region, none touching) — not the old
sudoku build. Each screen is a full-bleed marketing mockup (warm cream world,
white board card with a brown region frame + drop shadow, gradient-shaded pups,
purple Parade Pass accents) with a caption headline, matching UI/Theme.swift,
BoardView, CellView, DifficultySelectView and the v3.1 refresh.

Rendered as SVG -> headless Chrome/Edge so gradients, shadows and real fonts are
faithful. Output: store/screenshots/<6.9|6.5>/<n>_<name>.png

  6.9" = 1320x2868   (required)
  6.5" = 1242x2688   (optional, widely used)
"""
import os, subprocess

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUTBASE = os.path.join(ROOT, "store", "screenshots")

SIZES = {"6.9": (1320, 2868), "6.5": (1242, 2688)}

# --- palette (mirrors UI/Theme.swift) ---------------------------------------
BG_TOP, BG_BOT = "FFF8EF", "FBE9D2"
INK, INK_SOFT = "37302A", "9A8C7B"
ACCENT_BRIGHT, BRAND_SHADOW = "F6A542", "CF7A22"
LINE_BOLD = "6E5B44"
SUCCESS = "5FA463"
BONES = "E8933F"
PARADE1, PARADE2, PARADE_INK = "7C5CE0", "B56BE0", "6B46C1"
DAILY1, DAILY2 = "5AA9E6", "4F86D6"
REGIONS = ["F6C9A8", "A8D8EA", "C7E9B0", "F7B7C6", "F9E1A8",
           "C9B8E8", "A8E6CF", "FFD3B6", "D6C3A5"]

FONT = "'Segoe UI',system-ui,-apple-system,sans-serif"

# --- a genuinely valid 6x6 Queens solution ----------------------------------
# Region map: 6 contiguous regions, each containing exactly one puppy.
REGION_MAP = [
    [0, 0, 1, 1, 2, 2],
    [0, 0, 1, 1, 2, 2],
    [0, 3, 1, 4, 2, 2],
    [3, 3, 3, 4, 4, 5],
    [3, 3, 4, 4, 5, 5],
    [3, 3, 4, 5, 5, 5],
]
# One puppy per row, column AND region; no two adjacent (incl. diagonally).
PUPPIES = {(0, 1), (1, 3), (2, 5), (3, 0), (4, 2), (5, 4)}
# Breed per region index (mapped to the gradient pups we can render).
REGION_PUP = {0: "corgi", 1: "husky", 2: "shiba", 3: "poodle", 4: "golden", 5: "husky"}

# ---------------------------------------------------------------------------
def defs():
    return '''<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient>
  <linearGradient id="brand" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient>
  <linearGradient id="parade" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient>
  <linearGradient id="daily" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient>
  <linearGradient id="celltop" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#ffffff" stop-opacity="0.28"/>
    <stop offset="0.5" stop-color="#ffffff" stop-opacity="0"/>
    <stop offset="1" stop-color="#000000" stop-opacity="0.07"/></linearGradient>
  <radialGradient id="corgi" cx="42%%" cy="34%%" r="75%%"><stop offset="0" stop-color="#F9C07E"/><stop offset="1" stop-color="#E8912F"/></radialGradient>
  <linearGradient id="corgiEar" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E8912F"/><stop offset="1" stop-color="#CF7A22"/></linearGradient>
  <radialGradient id="husky" cx="42%%" cy="32%%" r="78%%"><stop offset="0" stop-color="#CBD7E2"/><stop offset="1" stop-color="#9DB1C4"/></radialGradient>
  <radialGradient id="poodle" cx="42%%" cy="32%%" r="78%%"><stop offset="0" stop-color="#F6D3E6"/><stop offset="1" stop-color="#E6A7CC"/></radialGradient>
  <radialGradient id="golden" cx="42%%" cy="32%%" r="78%%"><stop offset="0" stop-color="#FAD86A"/><stop offset="1" stop-color="#ECB62E"/></radialGradient>
  <radialGradient id="shiba" cx="42%%" cy="32%%" r="78%%"><stop offset="0" stop-color="#F0A074"/><stop offset="1" stop-color="#D96E43"/></radialGradient>
  <radialGradient id="eye" cx="38%%" cy="34%%" r="70%%"><stop offset="0" stop-color="#4a4a4a"/><stop offset="1" stop-color="#1d1d1d"/></radialGradient>
  <filter id="cardshadow" x="-20%%" y="-20%%" width="140%%" height="140%%">
    <feDropShadow dx="0" dy="8" stdDeviation="14" flood-color="#000000" flood-opacity="0.12"/></filter>
  <filter id="btnshadow" x="-40%%" y="-40%%" width="180%%" height="180%%">
    <feDropShadow dx="0" dy="6" stdDeviation="10" flood-color="#%s" flood-opacity="0.40"/></filter>
</defs>''' % (BG_TOP, BG_BOT, ACCENT_BRIGHT, BRAND_SHADOW, PARADE1, PARADE2,
              DAILY1, DAILY2, BRAND_SHADOW)

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
    s = scale / 240.0
    return f'<g transform="translate({cx},{cy}) rotate({rot}) scale({s}) translate(-120,-120)">{pup(kind)}</g>'

def xmark(cx, cy, s):
    c = f"#{INK}"
    return (f'<g stroke="{c}" stroke-opacity="0.45" stroke-width="{s*0.14}" stroke-linecap="round">'
            f'<line x1="{cx-s/2}" y1="{cy-s/2}" x2="{cx+s/2}" y2="{cy+s/2}"/>'
            f'<line x1="{cx-s/2}" y1="{cy+s/2}" x2="{cx+s/2}" y2="{cy-s/2}"/></g>')

def board(ox, oy, side, states):
    """Render the 6x6 Queens board (white card, brown region frame, gradient pups).
    `states`: dict (r,c)->'p'|'x'|'' overriding the solved placement."""
    n = 6
    cell = side / n
    pad = cell * 0.16
    el = []
    el.append(f'<rect x="{ox-pad}" y="{oy-pad}" width="{side+2*pad}" height="{side+2*pad}" '
              f'rx="{side*0.035}" fill="#ffffff" filter="url(#cardshadow)"/>')
    for r in range(n):
        for c in range(n):
            reg = REGION_MAP[r][c]
            x, y = ox + c * cell, oy + r * cell
            el.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="#{REGIONS[reg]}"/>')
            el.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="url(#celltop)"/>')
            st = states.get((r, c), 'p' if (r, c) in PUPPIES else '')
            if st == 'p':
                el.append(place(REGION_PUP[reg], x + cell / 2, y + cell / 2, cell * 0.74))
            elif st == 'x':
                el.append(xmark(x + cell / 2, y + cell / 2, cell * 0.34))
    tw, thin = cell * 0.05, cell * 0.014
    for r in range(n):
        for c in range(n):
            x, y = ox + c * cell, oy + r * cell
            if c < n - 1:
                bold = REGION_MAP[r][c] != REGION_MAP[r][c + 1]
                el.append(f'<line x1="{x+cell}" y1="{y}" x2="{x+cell}" y2="{y+cell}" '
                          f'stroke="#{LINE_BOLD}" stroke-opacity="{1 if bold else 0.18}" '
                          f'stroke-width="{tw if bold else thin}"/>')
            if r < n - 1:
                bold = REGION_MAP[r][c] != REGION_MAP[r + 1][c]
                el.append(f'<line x1="{x}" y1="{y+cell}" x2="{x+cell}" y2="{y+cell}" '
                          f'stroke="#{LINE_BOLD}" stroke-opacity="{1 if bold else 0.18}" '
                          f'stroke-width="{tw if bold else thin}"/>')
    el.append(f'<rect x="{ox}" y="{oy}" width="{side}" height="{side}" fill="none" '
              f'stroke="#{LINE_BOLD}" stroke-width="{cell*0.06}" rx="{cell*0.08}"/>')
    return "".join(el)

def mini_board(ox, oy, size, n):
    """Small n x n colored difficulty preview with a brown frame."""
    cell = size / n
    el = [f'<rect x="{ox}" y="{oy}" width="{size}" height="{size}" rx="{size*0.12}" fill="#ffffff"/>']
    for r in range(n):
        for c in range(n):
            col = REGIONS[(r + c) % len(REGIONS)]
            el.append(f'<rect x="{ox+c*cell+1}" y="{oy+r*cell+1}" width="{cell-2}" height="{cell-2}" '
                      f'rx="{cell*0.18}" fill="#{col}"/>')
    el.append(f'<rect x="{ox}" y="{oy}" width="{size}" height="{size}" rx="{size*0.12}" '
              f'fill="none" stroke="#{LINE_BOLD}" stroke-width="{size*0.03}"/>')
    return "".join(el)

def text(x, y, s, size, color, weight=900, anchor="middle"):
    return (f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" font-weight="{weight}" '
            f'fill="#{color}" text-anchor="{anchor}">{s}</text>')

def caption(W, head, sub, y=150):
    return (text(W/2, y, head, W*0.062, INK, 900)
            + text(W/2, y + W*0.052, sub, W*0.034, INK_SOFT, 700))

def rrect(x, y, w, h, r, fill, stroke=None, sw=0, filt=None):
    s = f' stroke="#{stroke}" stroke-width="{sw}"' if stroke else ''
    f = f' filter="url(#{filt})"' if filt else ''
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"{s}{f}/>'

# --- screens ----------------------------------------------------------------
def screen_board(W, H):
    el = [f'<rect width="{W}" height="{H}" fill="url(#bg)"/>',
          caption(W, "Find the hidden puppies", "One per row, column &amp; color")]
    el.append(rrect(W*0.08, H*0.115, W*0.30, W*0.085, W*0.042, "#ffffff"))
    el.append(text(W*0.14, H*0.115 + W*0.058, "🦴", W*0.045, INK, 400, "middle"))
    el.append(text(W*0.20, H*0.115 + W*0.057, "128", W*0.040, INK, 900, "start"))
    el.append(rrect(W*0.58, H*0.115, W*0.34, W*0.085, W*0.042, "#ffffff"))
    el.append(text(W*0.75, H*0.115 + W*0.057, "6 × 6  ·  Easy", W*0.030, INK_SOFT, 800, "middle"))
    side = W * 0.84
    board_y = H * 0.25
    el.append(board((W - side) / 2, board_y, side, {}))
    by = board_y + side + H*0.055
    for i, (emo, lab) in enumerate([("💡", "Hint"), ("↩", "Undo"), ("✓", "Check")]):
        bw = W * 0.26; bx = W*0.08 + i * (bw + W*0.03)
        el.append(rrect(bx, by, bw, W*0.11, W*0.05, "#ffffff"))
        el.append(text(bx + bw/2, by + W*0.068, f"{emo}  {lab}", W*0.034, INK, 800, "middle"))
    return wrap(W, H, el)

def screen_deduce(W, H):
    st = {}
    keep = {(0, 1), (3, 0), (5, 4)}
    for (r, c) in PUPPIES:
        if (r, c) not in keep:
            st[(r, c)] = ''
    for (dr, dc) in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]:
        r, c = 3 + dr, 0 + dc
        if 0 <= r < 6 and 0 <= c < 6 and (r, c) not in PUPPIES:
            st[(r, c)] = 'x'
    st[(2, 2)] = 'x'; st[(4, 4)] = 'x'; st[(1, 5)] = 'x'
    el = [f'<rect width="{W}" height="{H}" fill="url(#bg)"/>',
          caption(W, "Deduce, don't guess", "No two puppies may touch — even diagonally")]
    side = W * 0.84
    board_y = H * 0.27
    el.append(board((W - side) / 2, board_y, side, st))
    cy = board_y + side + H*0.05
    el.append(rrect(W*0.10, cy, W*0.80, W*0.17, W*0.05, "#ffffff"))
    el.append(text(W/2, cy + W*0.065, "Mark ✕ to rule a square out,", W*0.034, INK, 800))
    el.append(text(W/2, cy + W*0.120, "then place the puppy that must go there.", W*0.032, INK_SOFT, 700))
    return wrap(W, H, el)

def screen_difficulty(W, H):
    el = [f'<rect width="{W}" height="{H}" fill="url(#bg)"/>',
          caption(W, "Grow your pack", "From a tiny 5×5 up to a full 9×9")]
    rows = [("🐾", "Puppy", "5 × 5", "Puppy Pals", 5),
            ("🦴", "Easy", "6 × 6", "Little Litter", 6),
            ("🎾", "Medium", "7 × 7", "Growing Pack", 7),
            ("🏆", "Hard", "8 × 8", "Big Pack", 8),
            ("👑", "Expert", "9 × 9", "Full Kennel", 9)]
    y = H * 0.24
    rh = H * 0.135
    for emo, name, size, sub, n in rows:
        el.append(rrect(W*0.08, y, W*0.84, rh*0.88, W*0.05, "#ffffff", filt="cardshadow"))
        ms = rh * 0.64
        el.append(mini_board(W*0.12, y + (rh*0.88 - ms)/2, ms, n))
        tx = W*0.12 + ms + W*0.05
        el.append(text(tx, y + rh*0.37, f"{emo}  {name}", W*0.044, INK, 900, "start"))
        el.append(text(tx, y + rh*0.60, f"{size}  ·  {sub}", W*0.030, INK_SOFT, 700, "start"))
        y += rh
    return wrap(W, H, el)

def screen_win(W, H):
    el = [f'<rect width="{W}" height="{H}" fill="url(#bg)"/>']
    el.append(text(W/2, H*0.20, "🏆", W*0.20, INK, 400))
    el.append(text(W/2, H*0.29, "Good Dog!", W*0.10, INK, 900))
    cx, cy, cw, ch = W*0.14, H*0.34, W*0.72, H*0.11
    el.append(rrect(cx, cy, cw, ch, W*0.05, "#ffffff", filt="cardshadow"))
    el.append(text(cx + W*0.05, cy + ch*0.42, "Time", W*0.036, INK_SOFT, 700, "start"))
    el.append(text(cx + cw - W*0.05, cy + ch*0.46, "3:48", W*0.05, INK, 900, "end"))
    el.append(rrect(cx + W*0.05, cy + ch*0.60, W*0.26, ch*0.28, ch*0.14, f"#{SUCCESS}"))
    el.append(text(cx + W*0.18, cy + ch*0.60 + ch*0.20, "New best!", W*0.026, "FFFFFF", 800))
    el.append(text(cx + cw - W*0.05, cy + ch*0.60 + ch*0.20, "No mistakes · no hints", W*0.026, SUCCESS, 700, "end"))
    bw, bh = W*0.52, W*0.14
    bx, by = (W - bw)/2, H*0.49
    el.append(rrect(bx, by, bw, bh, bh/2, "url(#brand)", filt="btnshadow"))
    el.append(text(W/2, by + bh*0.64, "🦴  +40 Bones", W*0.052, "FFFFFF", 900))
    pr_y = H*0.62
    for i, k in enumerate(["corgi", "golden", "poodle", "husky", "shiba"]):
        el.append(place(k, W*0.18 + i*W*0.16, pr_y, W*0.14, (-6 + i*3)))
    pw, ph = W*0.76, W*0.14
    el.append(rrect((W-pw)/2, H*0.70, pw, ph, ph/2, "url(#brand)", filt="btnshadow"))
    el.append(text(W/2, H*0.70 + ph*0.63, "Play Again", W*0.05, "FFFFFF", 900))
    el.append(caption(W, "Earn Bones with every win", "Spend them on themes, hints &amp; more", y=H*0.84))
    return wrap(W, H, el)

def screen_themes(W, H):
    el = [f'<rect width="{W}" height="{H}" fill="url(#bg)"/>',
          caption(W, "Make it yours — ad-free", "Board themes, costumes &amp; Parade Pass")]
    themes = [("Classic", REGIONS[:4]),
              ("Midnight", ["5B6BA8", "4E8FA6", "5AA574", "B0668A"]),
              ("Pastel Dream", ["F7C8DD", "C9E4F5", "D8F0C8", "F6E2B3"]),
              ("Neon Pups", ["FF7AB6", "5BE0E6", "8CFF6B", "FFE24A"])]
    y = H*0.235
    cw, ch = W*0.40, W*0.34
    gap = W*0.04
    for i, (name, cols) in enumerate(themes):
        col = i % 2
        row = i // 2
        x = W*0.08 + col * (cw + gap)
        yy = y + row * (ch + gap)
        el.append(rrect(x, yy, cw, ch, W*0.05, "#ffffff", filt="cardshadow"))
        sw = (cw - W*0.09) / 2
        for j, c in enumerate(cols):
            sx = x + W*0.03 + (j % 2) * (sw + W*0.02)
            sy = yy + W*0.03 + (j // 2) * (sw + W*0.02)
            el.append(rrect(sx, sy, sw, sw, sw*0.22, f"#{c}"))
        el.append(text(x + cw/2, yy + ch - W*0.03, name, W*0.030, INK, 800))
    py = y + 2 * (ch + gap) + H*0.01
    pw, ph = W*0.84, H*0.185
    el.append(rrect(W*0.08, py, pw, ph, W*0.055, "url(#parade)", filt="cardshadow"))
    el.append(text(W*0.14, py + ph*0.26, "🎉  Parade Pass", W*0.052, "FFFFFF", 900, "start"))
    el.append(text(W*0.14, py + ph*0.46, "No ads · unlimited hints · every theme", W*0.030, "FFFFFF", 700, "start"))
    chw, chh = W*0.30, W*0.11
    el.append(rrect(W*0.08 + pw - chw - W*0.05, py + ph*0.60, chw, chh, chh/2, "#ffffff"))
    el.append(text(W*0.08 + pw - chw/2 - W*0.05, py + ph*0.60 + chh*0.64, "Try it", W*0.036, PARADE_INK, 900))
    return wrap(W, H, el)

def wrap(W, H, el):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
            f'viewBox="0 0 {W} {H}">{defs()}' + "".join(el) + '</svg>')

SCREENS = [("1_board", screen_board), ("2_deduce", screen_deduce),
           ("3_difficulty", screen_difficulty), ("4_win", screen_win),
           ("5_themes", screen_themes)]

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
    browser = find_browser()
    for label, (W, H) in SIZES.items():
        out = os.path.join(OUTBASE, label)
        os.makedirs(out, exist_ok=True)
        for name, fn in SCREENS:
            svg = fn(W, H)
            with open(os.path.join(out, f"{name}.svg"), "w", encoding="utf-8") as f:
                f.write(svg)
            html_path = os.path.join(out, f"{name}.html")
            with open(html_path, "w", encoding="utf-8") as f:
                f.write(html_wrap(svg))
            if browser:
                png = os.path.join(out, f"{name}.png")
                subprocess.run([browser, "--headless", "--disable-gpu", "--hide-scrollbars",
                                "--force-device-scale-factor=1", f"--window-size={W},{H}",
                                f"--screenshot={png}", "file:///" + html_path.replace("\\", "/")],
                               check=False, capture_output=True)
                print(("rendered " if os.path.exists(png) else "FAILED  ") + f"{label}/{name}.png")
            else:
                print("wrote", f"{label}/{name}.svg (no browser for PNG)")

if __name__ == "__main__":
    main()
