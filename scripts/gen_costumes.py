#!/usr/bin/env python3
"""Generate event-pass costume overlays (SVG) that sit on top of any breed token.

Each costume is a full 240x240 viewBox with a transparent background and the
accessory positioned over the top of the puppy head, so it aligns when drawn as
an overlay Image at the same scaledToFit size as the breed art.
Output: Assets.xcassets/Costumes/costume_<id>.imageset/ (+ Contents.json).
"""
import os, json

ROOT = os.path.join(os.path.dirname(__file__), "..",
                    "Pupdoku", "Resources", "Assets.xcassets", "Costumes")

def wrap(inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" '
            f'width="240" height="240">\n{inner}\n</svg>\n')

def witch_hat():
    # Spooky: dark bent cone + brim + purple band + star.
    return f'''
  <ellipse cx="120" cy="100" rx="82" ry="17" fill="#2A2340"/>
  <path d="M78 100 Q92 44 150 16 Q150 60 164 100 Z" fill="#3B2F5C" stroke="#241C3A" stroke-width="2" stroke-linejoin="round"/>
  <path d="M84 92 Q104 66 150 44 Q140 74 150 92 Z" fill="#4A3C74"/>
  <rect x="80" y="86" width="86" height="14" rx="7" fill="#8C5CE0"/>
  <path d="M120 84 l4 8 9 1 -6 6 2 9 -9 -5 -9 5 2 -9 -6 -6 9 -1 Z" fill="#F4C542"/>'''

def santa_hat():
    # Winter: red floppy hat + white fur trim + pom.
    return f'''
  <path d="M70 98 Q104 34 182 40 Q150 66 158 98 Z" fill="#D64F4F" stroke="#B03E3E" stroke-width="2" stroke-linejoin="round"/>
  <path d="M78 92 Q108 52 168 50 Q140 70 150 92 Z" fill="#E86A6A"/>
  <rect x="62" y="90" width="120" height="20" rx="10" fill="#FFFFFF"/>
  <circle cx="184" cy="42" r="14" fill="#FFFFFF"/>'''

def party_hat():
    # New Year: striped party cone + polka dots + gold pom + confetti bits.
    return f'''
  <path d="M86 102 L124 14 L162 102 Z" fill="#B79CF2" stroke="#7E5CC8" stroke-width="2" stroke-linejoin="round"/>
  <path d="M100 70 L148 70 L156 88 L92 88 Z" fill="#F7C948"/>
  <path d="M112 42 L136 42 L141 54 L107 54 Z" fill="#F49AC1"/>
  <circle cx="122" cy="96" r="4" fill="#FFFFFF"/>
  <circle cx="140" cy="62" r="3.5" fill="#FFFFFF"/>
  <circle cx="108" cy="62" r="3.5" fill="#FFFFFF"/>
  <rect x="80" y="96" width="88" height="12" rx="6" fill="#F27B7B"/>
  <circle cx="124" cy="14" r="11" fill="#F7C948" stroke="#D9A21E" stroke-width="2"/>
  <rect x="64" y="40" width="9" height="5" rx="2" fill="#7FB8F0" transform="rotate(-25 68 42)"/>
  <rect x="172" y="30" width="9" height="5" rx="2" fill="#8EDB9E" transform="rotate(30 176 32)"/>
  <circle cx="178" cy="70" r="3.5" fill="#F49AC1"/>
  <circle cx="60" cy="74" r="3.5" fill="#F7C948"/>'''

def heart_headband():
    # Valentine: red headband with two springy heart boppers.
    return f'''
  <path d="M62 104 Q120 58 178 104" fill="none" stroke="#C7466A" stroke-width="12" stroke-linecap="round"/>
  <path d="M96 78 Q88 52 80 34" fill="none" stroke="#C7466A" stroke-width="4" stroke-linecap="round"/>
  <path d="M144 78 Q152 52 160 34" fill="none" stroke="#C7466A" stroke-width="4" stroke-linecap="round"/>
  <path d="M80 44 C62 30 56 12 70 6 C78 3 80 10 80 14 C80 10 82 3 90 6 C104 12 98 30 80 44 Z" fill="#E8586E" stroke="#B03A55" stroke-width="2"/>
  <path d="M160 44 C142 30 136 12 150 6 C158 3 160 10 160 14 C160 10 162 3 170 6 C184 12 178 30 160 44 Z" fill="#F7A8B8" stroke="#B03A55" stroke-width="2"/>
  <circle cx="70" cy="14" r="3" fill="#FFFFFF" opacity="0.8"/>
  <circle cx="150" cy="14" r="3" fill="#FFFFFF" opacity="0.8"/>'''

COSTUMES = {"spooky": witch_hat, "winter": santa_hat, "newyear": party_hat, "valentine": heart_headband}

def contents(fn):
    return json.dumps({
        "images": [{"filename": fn, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": True,
                       "template-rendering-intent": "original"},
    }, indent=2)

def main():
    os.makedirs(ROOT, exist_ok=True)
    with open(os.path.join(ROOT, "Contents.json"), "w", encoding="utf-8") as f:
        f.write(json.dumps({"info": {"author": "xcode", "version": 1},
                            "properties": {"provides-namespace": False}}, indent=2))
    for name, fn in COSTUMES.items():
        d = os.path.join(ROOT, f"costume_{name}.imageset")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, f"costume_{name}.svg"), "w", encoding="utf-8") as f:
            f.write(wrap(fn()))
        with open(os.path.join(d, "Contents.json"), "w", encoding="utf-8") as f:
            f.write(contents(f"costume_{name}.svg"))
        print("wrote", d)

if __name__ == "__main__":
    main()
