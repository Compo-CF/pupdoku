#!/usr/bin/env python3
"""Generate 512x512 Game Center achievement badge images.

App Store Connect requires an image per achievement. Each badge is a warm
gradient with a soft white disc and the achievement's emoji centered (rendered
in color via Segoe UI Emoji on Windows). Output: art/achievements/<id>.png
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "art", "achievements")
EMOJI_FONT = "C:/Windows/Fonts/seguiemj.ttf"

# id, emoji, accent hex
BADGES = [
    ("first_win",   "🐶", "F2A65A"),
    ("unlock_six",  "🐕", "6C8EBF"),
    ("unlock_nine", "🐺", "7A6B98"),
    ("wins_10",     "🌳", "5FA463"),
    ("perfect_5",   "🎾", "E06B4A"),
    ("nine_hard",   "🏆", "F4C542"),
    ("zoomies",     "💨", "8AB6D6"),
    ("daily_7",     "🦴", "C9A36B"),
    ("daily_30",    "❤️", "E39AC0"),
    ("wins_50",     "👑", "9B6BD1"),
]

def Hx(s):
    s = s.lstrip("#"); return (int(s[0:2],16), int(s[2:4],16), int(s[4:6],16))
def lerp(a, b, t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))
def lighten(c, t=0.55): return lerp(c, (255,255,255), t)
def darken(c, t=0.20): return lerp(c, (0,0,0), t)

def main():
    os.makedirs(OUT, exist_ok=True)
    S = 512
    font = ImageFont.truetype(EMOJI_FONT, 250)
    for (aid, emoji, hexcol) in BADGES:
        accent = Hx(hexcol)
        img = Image.new("RGB", (S, S), accent)
        d = ImageDraw.Draw(img)
        top, bot = lighten(accent, 0.30), darken(accent, 0.15)
        for y in range(S):
            d.line([(0, y), (S, y)], fill=lerp(top, bot, y / S))
        # soft white disc
        m = 70
        d.ellipse([m, m, S-m, S-m], fill=(255, 255, 255))
        d.ellipse([m, m, S-m, S-m], outline=lighten(accent, 0.1), width=6)
        # emoji centered
        d.text((S/2, S/2 + 6), emoji, font=font, embedded_color=True, anchor="mm")
        img.save(os.path.join(OUT, f"{aid}.png"), "PNG")
        print("wrote", aid)

if __name__ == "__main__":
    main()
