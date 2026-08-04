#!/usr/bin/env python3
"""Generate App Store marketing screenshots for Pupdoku at 6.9" (1320x2868).

Renders faithful mockups of the real app screens (same palette, layout, and the
same Pillow-drawn breed faces used by the icon) with a caption headline on each.
Supersampled 2x for clean antialiased edges.

Output: store/screenshots/6.9/<n>_<name>.png
"""
import os
from PIL import Image, ImageDraw, ImageFont

K = 2                      # supersample
W, H = 1320, 2868          # 6.9" portrait
OUT = os.path.join(os.path.dirname(__file__), "..", "store", "screenshots", "6.9")

FONT_BOLD  = "C:/Windows/Fonts/segoeuib.ttf"
FONT_BLACK = "C:/Windows/Fonts/seguibl.ttf"
FONT_REG   = "C:/Windows/Fonts/segoeui.ttf"
FONT_EMOJI = "C:/Windows/Fonts/seguiemj.ttf"

def Hx(s):
    s = s.lstrip("#"); return (int(s[0:2],16), int(s[2:4],16), int(s[4:6],16))
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

# Palette (mirrors UI/Theme.swift)
BG_TOP, BG_BOT = Hx("FFF7EC"), Hx("FBE7CE")
CARD = Hx("FFFFFF"); INK = Hx("3D3328"); INK_SOFT = Hx("8A7C6B")
LINE = Hx("D9C7AE"); LINE_BOLD = Hx("9E8A6E")
CELL_GIVEN = Hx("FDF3E4"); SELECTED = Hx("FBD9A6"); PEER = Hx("FBEFDC"); SAME = Hx("F7E3C0")
ACCENT = Hx("F2A65A"); ACCENT_DEEP = Hx("E8933F"); SUCCESS = Hx("5FA463")

def font(path, size):
    try: return ImageFont.truetype(path, size*K)
    except Exception: return ImageFont.truetype(FONT_REG, size*K)

# Breed params for Pillow face drawing (values 1..9 as in Breed.swift)
BREEDS = {
 1: dict(fur="F2A65A", ear="E8933F", inner="F6C79A", muzzle="FBEAD2", ears="up"),
 2: dict(fur="B8C6D4", ear="5C6B7A", inner="D9DFE6", muzzle="F3F5F7", ears="up", blue=True, cap="5C6B7A"),
 3: dict(fur="D9B98A", ear="5A4632", inner="7A6248", muzzle="4A3A2A", ears="floppy", nose="1F1F1F"),
 4: dict(fur="F1F2F4", ear="2C2C2C", inner="6E6E6E", muzzle="FFFFFF", ears="floppy", spots=True),
 5: dict(fur="F4C542", ear="E0A93C", inner="F4D488", muzzle="FBE7B0", ears="floppy"),
 6: dict(fur="E06B4A", ear="C8573A", inner="F3C9B4", muzzle="FBEEE4", ears="up"),
 7: dict(fur="B98A5E", ear="5A3A26", inner="8A6244", muzzle="F5EAD9", ears="floppy", cap="6E4B34"),
 8: dict(fur="EFC7DC", ear="E7B4CE", inner="F4D6E6", muzzle="FBECF4", ears="floppy", pom=True, nose="7A4A63"),
 9: dict(fur="6E4B3A", ear="4A2F22", inner="6E4B3A", muzzle="B98A5E", ears="floppy", nose="1F1F1F"),
}

def face(d, cx, cy, r, p):
    """Draw a breed face centered at (cx,cy) radius r, all in raw (scaled) px."""
    def E(x0,y0,x1,y1,c): d.ellipse([x0,y0,x1,y1], fill=Hx(c) if isinstance(c,str) else c)
    ear, inner, fur = p["ear"], p["inner"], p["fur"]
    muzzle = p["muzzle"]; nose = p.get("nose","2B2B2B"); ears = p.get("ears","up")
    if ears == "up":
        d.polygon([(cx-r*0.7,cy-r*0.2),(cx-r*0.85,cy-r*1.15),(cx-r*0.15,cy-r*0.55)], fill=Hx(ear))
        d.polygon([(cx+r*0.7,cy-r*0.2),(cx+r*0.85,cy-r*1.15),(cx+r*0.15,cy-r*0.55)], fill=Hx(ear))
        d.polygon([(cx-r*0.62,cy-r*0.3),(cx-r*0.7,cy-r*0.9),(cx-r*0.28,cy-r*0.5)], fill=Hx(inner))
        d.polygon([(cx+r*0.62,cy-r*0.3),(cx+r*0.7,cy-r*0.9),(cx+r*0.28,cy-r*0.5)], fill=Hx(inner))
    else:
        E(cx-r*1.05,cy-r*0.35,cx-r*0.35,cy+r*0.95, ear)
        E(cx+r*0.35,cy-r*0.35,cx+r*1.05,cy+r*0.95, ear)
    if p.get("pom"):
        for dx,dy,rr in [(0,-0.95,0.5),(-0.5,-0.7,0.4),(0.5,-0.7,0.4)]:
            E(cx+dx*r-rr*r,cy+dy*r-rr*r,cx+dx*r+rr*r,cy+dy*r+rr*r, ear)
    E(cx-r,cy-r*0.92,cx+r,cy+r*0.92, fur)                       # head
    if p.get("cap"): d.pieslice([cx-r,cy-r*0.92,cx+r,cy+r*0.92], 180,360, fill=Hx(p["cap"]))
    E(cx-r*0.62,cy+r*0.1,cx+r*0.62,cy+r*0.85, muzzle)          # muzzle
    if p.get("spots"):
        for sx,sy,sr in [(-0.5,-0.4,0.16),(0.55,0.2,0.12),(0.4,-0.55,0.1)]:
            E(cx+sx*r-sr*r,cy+sy*r-sr*r,cx+sx*r+sr*r,cy+sy*r+sr*r,"2C2C2C")
    ex,ey,er = r*0.42, r*0.15, r*0.17
    if p.get("blue"):
        E(cx-ex-er,cy-ey-er,cx-ex+er,cy-ey+er,"5AA9E6"); E(cx+ex-er,cy-ey-er,cx+ex+er,cy-ey+er,"5AA9E6")
        e2=r*0.09
        E(cx-ex-e2,cy-ey-e2,cx-ex+e2,cy-ey+e2,"20313F"); E(cx+ex-e2,cy-ey-e2,cx+ex+e2,cy-ey+e2,"20313F")
    else:
        E(cx-ex-er,cy-ey-er,cx-ex+er,cy-ey+er,"2B2B2B"); E(cx+ex-er,cy-ey-er,cx+ex+er,cy-ey+er,"2B2B2B")
    hr=r*0.055
    E(cx-ex-hr+r*0.06,cy-ey-hr-r*0.06,cx-ex+hr+r*0.06,cy-ey+hr-r*0.06,"FFFFFF")
    E(cx+ex-hr+r*0.06,cy-ey-hr-r*0.06,cx+ex+hr+r*0.06,cy-ey+hr-r*0.06,"FFFFFF")
    d.polygon([(cx-r*0.16,cy+r*0.34),(cx+r*0.16,cy+r*0.34),(cx,cy+r*0.52)], fill=Hx(nose))
    lwid=max(1,int(r*0.05))
    d.line([(cx,cy+r*0.5),(cx,cy+r*0.66)], fill=Hx(nose), width=lwid)
    d.arc([cx-r*0.3,cy+r*0.5,cx,cy+r*0.82], 20,160, fill=Hx(nose), width=lwid)
    d.arc([cx,cy+r*0.5,cx+r*0.3,cy+r*0.82], 20,160, fill=Hx(nose), width=lwid)

def new_canvas():
    img = Image.new("RGB", (W*K, H*K), BG_TOP)
    d = ImageDraw.Draw(img, "RGBA")
    for y in range(H*K):
        d.line([(0,y),(W*K,y)], fill=lerp(BG_TOP,BG_BOT,y/(H*K)))
    return img, d

def s(v): return int(v*K)

def caption(d, headline, sub=None):
    f = font(FONT_BLACK, 78)
    d.text((W*K/2, s(180)), headline, font=f, fill=INK, anchor="mm", align="center")
    if sub:
        d.text((W*K/2, s(268)), sub, font=font(FONT_BOLD,40), fill=INK_SOFT, anchor="mm", align="center")

def rrect(d, box, radius, fill=None, outline=None, width=1):
    b=[s(box[0]),s(box[1]),s(box[2]),s(box[3])]
    d.rounded_rectangle(b, radius=s(radius), fill=fill, outline=outline, width=s(width) if outline else 0)

def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.resize((W,H), Image.LANCZOS).save(os.path.join(OUT,name), "PNG")
    print("wrote", name)

# A valid 9x9 solution to display believable boards.
SOLUTION = [
 [5,3,4,6,7,8,9,1,2],[6,7,2,1,9,5,3,4,8],[1,9,8,3,4,2,5,6,7],
 [8,5,9,7,6,1,4,2,3],[4,2,6,8,5,3,7,9,1],[7,1,3,9,2,4,8,5,6],
 [9,6,1,5,3,7,2,8,4],[2,8,7,4,1,9,6,3,5],[3,4,5,2,8,6,1,7,9]]
BLANKS = {(0,3),(0,6),(1,1),(1,5),(2,2),(2,7),(3,0),(3,4),(3,8),
          (4,2),(4,6),(5,1),(5,5),(6,3),(6,7),(7,0),(7,4),(8,2),(8,6),(1,8),(7,8)}

def screen_board():
    img,d = new_canvas()
    caption(d, "Fill every row,", "column & box with one of each breed")
    # board
    side=1180; x0=(W-side)//2; y0=430; cell=side/9
    rrect(d,(x0-10,y0-10,x0+side+10,y0+side+10),34,fill=CARD)
    sel=(0,3)
    for r in range(9):
        for c in range(9):
            X=x0+c*cell; Y=y0+r*cell
            bg=CARD
            if (r,c)==sel: bg=SELECTED
            elif r==sel[0] or c==sel[1] or (r//3==sel[0]//3 and c//3==sel[1]//3): bg=PEER
            elif (r,c) not in BLANKS and SOLUTION[r][c]==SOLUTION[sel[0]][sel[1]]: bg=SAME
            d.rectangle([s(X),s(Y),s(X+cell),s(Y+cell)], fill=bg)
            if (r,c) not in BLANKS:
                face(d, s(X+cell/2), s(Y+cell/2), s(cell*0.36), BREEDS[SOLUTION[r][c]])
    # thin grid
    for i in range(1,9):
        d.line([(s(x0+i*cell),s(y0)),(s(x0+i*cell),s(y0+side))], fill=LINE, width=s(1))
        d.line([(s(x0),s(y0+i*cell)),(s(x0+side),s(y0+i*cell))], fill=LINE, width=s(1))
    for i in range(0,10,3):
        d.line([(s(x0+i*cell),s(y0)),(s(x0+i*cell),s(y0+side))], fill=LINE_BOLD, width=s(3))
        d.line([(s(x0),s(y0+i*cell)),(s(x0+side),s(y0+i*cell))], fill=LINE_BOLD, width=s(3))
    rrect(d,(x0-10,y0-10,x0+side+10,y0+side+10),34,outline=LINE_BOLD,width=3)
    # palette row (9 tokens)
    py=y0+side+70; pw=1180; px0=(W-pw)//2; bw=pw/9
    for v in range(1,10):
        bx=px0+(v-1)*bw
        rrect(d,(bx+6,py,bx+bw-6,py+150),22,fill=CARD,outline=LINE,width=1)
        face(d, s(bx+bw/2), s(py+75), s(bw*0.32), BREEDS[v])
    save(img,"1_board.png")

def button(d, box, text, filled=True, sub=None):
    rrect(d, box, 30, fill=ACCENT if filled else CARD)
    col = Hx("FFFFFF") if filled else INK
    cy = (box[1]+box[3])/2 - (14 if sub else 0)
    d.text((s((box[0]+box[2])/2), s(cy)), text, font=font(FONT_BLACK,54), fill=col, anchor="mm")
    if sub:
        subcol = Hx("FFFFFF") if filled else INK_SOFT
        d.text((s((box[0]+box[2])/2), s(cy+58)), sub, font=font(FONT_BOLD,30), fill=subcol, anchor="mm")

def screen_home():
    img,d = new_canvas()
    face(d, s(W/2), s(560), s(150), BREEDS[1])
    d.text((s(W/2), s(800)), "Pupdoku", font=font(FONT_BLACK,140), fill=INK, anchor="mm")
    d.text((s(W/2), s(910)), "Sudoku, but make it puppies", font=font(FONT_BOLD,44), fill=INK_SOFT, anchor="mm")
    button(d,(140,1120,1180,1300),"Play", sub="Pick a size & difficulty")
    rrect(d,(140,1340,1180,1520),30,fill=CARD,outline=Hx("F2A65A"),width=2)
    d.text((s(220), s(1408)), "🦴", font=font(FONT_EMOJI,64), fill=INK, anchor="mm", embedded_color=True)
    d.text((s(300), s(1392)), "Daily Puzzle", font=font(FONT_BLACK,50), fill=INK, anchor="lm")
    d.text((s(300), s(1452)), "Daily · Hard", font=font(FONT_BOLD,32), fill=INK_SOFT, anchor="lm")
    # utility row
    labels=[("📊","Stats"),("🏅","Awards"),("🛒","Shop"),("⚙️","Settings")]
    uw=1040/4; ux0=140
    for i,(emo,lab) in enumerate(labels):
        bx=ux0+i*uw
        rrect(d,(bx+10,1580,bx+uw-10,1760),24,fill=CARD)
        d.text((s(bx+uw/2), s(1650)), emo, font=font(FONT_EMOJI,52), fill=INK, anchor="mm", embedded_color=True)
        d.text((s(bx+uw/2), s(1720)), lab, font=font(FONT_BOLD,30), fill=INK, anchor="mm")
    caption(d, "A cozy daily habit", "for the whole family")
    save(img,"2_home.png")

def screen_difficulty():
    img,d = new_canvas()
    caption(d, "From 4×4 to a full 9×9", "unlock bigger boards as you win")
    sizes=[("4 × 4","Puppy Pals"),("6 × 6","Little Litter"),("9 × 9","Full Pack")]
    cw=1040/3; cx0=140
    for i,(t,su) in enumerate(sizes):
        bx=cx0+i*cw; filled=(i==2)
        rrect(d,(bx+12,440,bx+cw-12,650),24, fill=ACCENT if filled else CARD, outline=None if filled else LINE, width=1)
        col=Hx("FFFFFF") if filled else INK
        d.text((s(bx+cw/2), s(520)), t, font=font(FONT_BLACK,54), fill=col, anchor="mm")
        d.text((s(bx+cw/2), s(585)), su, font=font(FONT_BOLD,28), fill=(Hx("FFFFFF") if filled else INK_SOFT), anchor="mm")
    diffs=[("🐾","Puppy","62 clues · relaxed, no fail"),("🦴","Easy","clues aplenty · 5 mistakes"),
           ("🎾","Medium","fewer clues · 4 mistakes"),("🏆","Hard","sparse clues · 3 mistakes")]
    y=730
    for emo,name,sub in diffs:
        rrect(d,(140,y,1180,y+190),26,fill=CARD)
        d.text((s(230), s(y+95)), emo, font=font(FONT_EMOJI,66), fill=INK, anchor="mm", embedded_color=True)
        d.text((s(320), s(y+72)), name, font=font(FONT_BLACK,52), fill=INK, anchor="lm")
        d.text((s(320), s(y+130)), sub, font=font(FONT_BOLD,32), fill=INK_SOFT, anchor="lm")
        d.text((s(1120), s(y+95)), "›", font=font(FONT_BOLD,60), fill=INK_SOFT, anchor="mm")
        y+=220
    save(img,"3_difficulty.png")

def screen_win():
    img,d = new_canvas()
    d.text((s(W/2), s(560)), "🏆", font=font(FONT_EMOJI,220), fill=INK, anchor="mm", embedded_color=True)
    d.text((s(W/2), s(820)), "Good Dog!", font=font(FONT_BLACK,120), fill=INK, anchor="mm")
    rrect(d,(180,960,1140,1270),28,fill=CARD)
    d.text((s(240), s(1050)), "Time", font=font(FONT_BOLD,44), fill=INK_SOFT, anchor="lm")
    d.text((s(1080), s(1050)), "4:12", font=font(FONT_BLACK,56), fill=INK, anchor="rm")
    rrect(d,(240,1120,470,1180),18,fill=SUCCESS)
    d.text((s(355), s(1150)), "New best!", font=font(FONT_BOLD,30), fill=Hx("FFFFFF"), anchor="mm")
    d.text((s(1080), s(1150)), "Perfect clear — no mistakes, no hints",
           font=font(FONT_BOLD,30), fill=SUCCESS, anchor="rm")
    # a happy row of breeds
    for i,v in enumerate([1,5,6,8,2]):
        face(d, s(320+i*170), s(1470), s(78), BREEDS[v])
    button(d,(220,1650,1100,1830),"Play Again")
    caption(d, "Win with a happy pack", "beat your best time")
    save(img,"4_win.png")

def screen_achievements():
    img,d = new_canvas()
    caption(d, "Earn awards", "& climb Game Center leaderboards")
    items=[("🐶","First Best Friend","Complete your first puzzle.",True),
           ("🎾","Flawless Fetch","Win 5 with no mistakes or hints.",True),
           ("🏆","Top Dog","Beat a 9×9 on Hard.",False),
           ("🦴","Week of Walkies","Keep a 7-day streak.",True),
           ("💨","Zoomies","Finish a 9×9 under 5 minutes.",False),
           ("👑","Pack Leader","Win 50 puzzles.",False)]
    y=430
    for emo,name,desc,earned in items:
        rrect(d,(140,y,1180,y+200),26,fill=CARD)
        e = emo if earned else "🔒"
        d.text((s(240), s(y+100)), e, font=font(FONT_EMOJI,70), fill=INK, anchor="mm", embedded_color=True)
        d.text((s(340), s(y+72)), name, font=font(FONT_BLACK,50), fill=INK, anchor="lm")
        d.text((s(340), s(y+135)), desc, font=font(FONT_BOLD,32), fill=INK_SOFT, anchor="lm")
        if earned:
            cx, cy, rr = s(1100), s(y+100), s(34)
            d.ellipse([cx-rr,cy-rr,cx+rr,cy+rr], fill=SUCCESS)
            lw = s(7)
            d.line([(cx-s(15),cy),(cx-s(3),cy+s(14)),(cx+s(17),cy-s(15))],
                   fill=Hx("FFFFFF"), width=lw, joint="curve")
        y+=230
    save(img,"5_achievements.png")

def main():
    screen_board(); screen_home(); screen_difficulty(); screen_win(); screen_achievements()

if __name__ == "__main__":
    main()
