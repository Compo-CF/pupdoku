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

COSTUMES = {"spooky": witch_hat, "winter": santa_hat}

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
