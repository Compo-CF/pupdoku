#!/usr/bin/env python3
"""Generate the nine puppy-breed SVG tokens + their asset-catalog Contents.json.

All faces share one parametric template (head, eyes, nose, smile) so the set
reads as one illustrated family, while ear shape, fur/marking colors and a few
per-breed flourishes (Dalmatian spots, Pug mask, Poodle pom, Husky mask, tan
points) keep every breed instantly distinct — including for colorblind players,
who also get 2-letter codes in-app.

Output: Pupdoku/Resources/Assets.xcassets/Breeds/breed_<name>.imageset/
        containing breed_<name>.svg and Contents.json (vector-preserving).
"""
import os, json, math

ROOT = os.path.join(os.path.dirname(__file__), "..",
                    "Pupdoku", "Resources", "Assets.xcassets", "Breeds")

# --- shared geometry ---------------------------------------------------------
CX, CY = 120, 134          # head center
HRX, HRY = 80, 74          # head radii
EYE_Y = 122
EYE_DX = 30
EYE_R = 13

def upright_ears(ear, inner):
    return f'''
  <path d="M60 106 Q40 34 84 74 Z" fill="{ear}" stroke="#00000018" stroke-width="2" stroke-linejoin="round"/>
  <path d="M180 106 Q200 34 156 74 Z" fill="{ear}" stroke="#00000018" stroke-width="2" stroke-linejoin="round"/>
  <path d="M67 92 Q55 56 82 78 Z" fill="{inner}"/>
  <path d="M173 92 Q185 56 158 78 Z" fill="{inner}"/>'''

def floppy_ears(ear, inner):
    return f'''
  <ellipse cx="48" cy="150" rx="27" ry="52" transform="rotate(-14 48 150)" fill="{ear}" stroke="#00000018" stroke-width="2"/>
  <ellipse cx="192" cy="150" rx="27" ry="52" transform="rotate(14 192 150)" fill="{ear}" stroke="#00000018" stroke-width="2"/>
  <ellipse cx="52" cy="150" rx="13" ry="30" transform="rotate(-14 52 150)" fill="{inner}"/>
  <ellipse cx="188" cy="150" rx="13" ry="30" transform="rotate(14 188 150)" fill="{inner}"/>'''

def poodle_ears(ear):
    puffs = []
    for (x, y, r) in [(44,132,30),(56,168,26),(196,132,30),(184,168,26)]:
        puffs.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{ear}"/>')
    return "\n  " + "\n  ".join(puffs)

def head(fur):
    return f'<ellipse cx="{CX}" cy="{CY}" rx="{HRX}" ry="{HRY}" fill="{fur}" stroke="#00000018" stroke-width="2"/>'

def eyes(blue=False, mask=False):
    pupil = "#25303B" if blue else "#2B2B2B"
    iris = f'<circle cx="{CX-EYE_DX}" cy="{EYE_Y}" r="{EYE_R}" fill="{pupil}"/><circle cx="{CX+EYE_DX}" cy="{EYE_Y}" r="{EYE_R}" fill="{pupil}"/>'
    if blue:
        iris = (f'<circle cx="{CX-EYE_DX}" cy="{EYE_Y}" r="{EYE_R}" fill="#5AA9E6"/>'
                f'<circle cx="{CX+EYE_DX}" cy="{EYE_Y}" r="{EYE_R}" fill="#5AA9E6"/>'
                f'<circle cx="{CX-EYE_DX}" cy="{EYE_Y}" r="6.5" fill="#20313F"/>'
                f'<circle cx="{CX+EYE_DX}" cy="{EYE_Y}" r="6.5" fill="#20313F"/>')
    hi = (f'<circle cx="{CX-EYE_DX+4}" cy="{EYE_Y-4}" r="3.4" fill="#FFFFFF"/>'
          f'<circle cx="{CX+EYE_DX+4}" cy="{EYE_Y-4}" r="3.4" fill="#FFFFFF"/>')
    return iris + hi

def muzzle(color):
    return f'<ellipse cx="{CX}" cy="172" rx="42" ry="32" fill="{color}"/>'

def nose_and_smile(nose="#2B2B2B"):
    return f'''
  <path d="M108 158 Q120 170 132 158 Q120 150 108 158 Z" fill="{nose}"/>
  <path d="M120 168 V180" stroke="{nose}" stroke-width="3.2" stroke-linecap="round"/>
  <path d="M120 180 Q106 194 92 184" stroke="{nose}" stroke-width="3.2" fill="none" stroke-linecap="round"/>
  <path d="M120 180 Q134 194 148 184" stroke="{nose}" stroke-width="3.2" fill="none" stroke-linecap="round"/>
  <path d="M112 188 Q120 196 128 188 Q120 192 112 188 Z" fill="#E8879B"/>'''

def cheeks():
    return (f'<circle cx="{CX-52}" cy="158" r="10" fill="#FF9E9E" opacity="0.28"/>'
            f'<circle cx="{CX+52}" cy="158" r="10" fill="#FF9E9E" opacity="0.28"/>')

def wrap(inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" '
            f'width="240" height="240">\n{inner}\n</svg>\n')

# --- per-breed definitions ---------------------------------------------------
def corgi():
    return (upright_ears("#E8933F", "#F6C79A") + "\n  " + head("#F2A65A") + "\n  "
            + muzzle("#FBEAD2") + "\n  " + eyes() + nose_and_smile() + cheeks())

def husky():
    body = head("#B8C6D4")
    # dark head cap + white face mask
    mask = f'''
  <path d="M120 62 Q52 70 60 150 Q86 120 120 120 Q154 120 180 150 Q188 70 120 62 Z" fill="#5C6B7A"/>
  <path d="M120 96 Q92 112 96 176 Q120 168 120 168 Q120 168 144 176 Q148 112 120 96 Z" fill="#F3F5F7"/>'''
    return (upright_ears("#5C6B7A", "#D9DFE6") + "\n  " + body + mask + "\n  "
            + muzzle("#F3F5F7") + "\n  " + eyes(blue=True) + nose_and_smile() )

def pug():
    body = head("#D9B98A")
    mask = f'<ellipse cx="{CX}" cy="150" rx="58" ry="46" fill="#4A3A2A"/>'
    wrinkle = '<path d="M120 96 Q108 104 120 112 Q132 104 120 96" fill="none" stroke="#00000022" stroke-width="3"/>'
    return (floppy_ears("#5A4632", "#7A6248") + "\n  " + body + "\n  " + mask + wrinkle + "\n  "
            + eyes() + nose_and_smile(nose="#1F1F1F"))

def dalmatian():
    body = head("#F1F2F4")
    spots = "".join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#2C2C2C"/>'
                    for (x,y,r) in [(78,104,11),(160,150,9),(150,96,7),(92,168,7),(176,120,6)])
    return (floppy_ears("#2C2C2C", "#6E6E6E") + "\n  " + body + "\n  " + spots + "\n  "
            + muzzle("#FFFFFF") + "\n  " + eyes() + nose_and_smile())

def golden():
    return (floppy_ears("#E0A93C", "#F4D488") + "\n  " + head("#F4C542") + "\n  "
            + muzzle("#FBE7B0") + "\n  " + eyes() + nose_and_smile())

def shiba():
    body = head("#E06B4A")
    points = f'''
  <path d="M120 108 Q94 120 98 178 Q120 168 120 168 Q120 168 142 178 Q146 120 120 108 Z" fill="#FBEEE4"/>'''
    return (upright_ears("#C8573A", "#F3C9B4") + "\n  " + body + points + "\n  "
            + eyes() + nose_and_smile())

def beagle():
    body = head("#B98A5E")
    cap = f'<path d="M120 62 Q60 70 66 132 Q92 108 120 108 Q148 108 174 132 Q180 70 120 62 Z" fill="#6E4B34"/>'
    return (floppy_ears("#5A3A26", "#8A6244") + "\n  " + body + "\n  " + cap + "\n  "
            + muzzle("#F5EAD9") + "\n  " + eyes() + nose_and_smile())

def poodle():
    body = head("#EFC7DC")
    pom = '<circle cx="120" cy="66" r="30" fill="#F4D6E6"/><circle cx="100" cy="78" r="20" fill="#F4D6E6"/><circle cx="140" cy="78" r="20" fill="#F4D6E6"/>'
    return (poodle_ears("#E7B4CE") + "\n  " + body + "\n  " + pom + "\n  "
            + muzzle("#FBECF4") + "\n  " + eyes() + nose_and_smile(nose="#7A4A63"))

def dachshund():
    body = head("#6E4B3A")
    tan = f'<ellipse cx="{CX}" cy="176" rx="40" ry="26" fill="#B98A5E"/>'
    brows = f'<ellipse cx="{CX-EYE_DX}" cy="{EYE_Y-20}" rx="11" ry="6" fill="#B98A5E"/><ellipse cx="{CX+EYE_DX}" cy="{EYE_Y-20}" rx="11" ry="6" fill="#B98A5E"/>'
    return (floppy_ears("#4A2F22", "#6E4B3A") + "\n  " + body + "\n  " + tan + brows + "\n  "
            + eyes() + nose_and_smile(nose="#1F1F1F"))

BREEDS = {
    "corgi": corgi, "husky": husky, "pug": pug, "dalmatian": dalmatian,
    "golden": golden, "shiba": shiba, "beagle": beagle, "poodle": poodle,
    "dachshund": dachshund,
}

def contents(filename):
    return json.dumps({
        "images": [{"filename": filename, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": True,
                       "template-rendering-intent": "original"},
    }, indent=2)

def main():
    for name, fn in BREEDS.items():
        set_dir = os.path.join(ROOT, f"breed_{name}.imageset")
        os.makedirs(set_dir, exist_ok=True)
        svg = wrap(fn())
        with open(os.path.join(set_dir, f"breed_{name}.svg"), "w", encoding="utf-8") as f:
            f.write(svg)
        with open(os.path.join(set_dir, "Contents.json"), "w", encoding="utf-8") as f:
            f.write(contents(f"breed_{name}.svg"))
        print("wrote", set_dir)

if __name__ == "__main__":
    main()
