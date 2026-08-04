#!/usr/bin/env python3
"""Synthesize Pupdoku's original sound effects + a cozy looping music bed.

All audio is generated from scratch with numpy (sine/triangle partials + ADSR),
so it's 100% original and royalty-free. Output: 16-bit mono WAV at 44.1kHz into
Pupdoku/Resources/Audio/. Short SFX + one seamless ~12s music loop.
"""
import os, wave, struct
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "Pupdoku", "Resources", "Audio")

def write_wav(name, sig):
    sig = np.clip(sig, -1.0, 1.0)
    data = (sig * 32767).astype("<i2").tobytes()
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data)
    print("wrote", name, f"{len(sig)/SR:.2f}s")

def t(dur): return np.linspace(0, dur, int(SR*dur), endpoint=False)

def expenv(dur, k=6.0):
    x = t(dur); return np.exp(-k * x / dur)

def adsr(dur, a=0.01, d=0.1, s=0.6, r=0.2):
    n = int(SR*dur); env = np.ones(n)
    na, nd, nr = int(SR*a), int(SR*d), int(SR*r)
    na = max(1, min(na, n));
    env[:na] = np.linspace(0, 1, na)
    if nd > 0 and na+nd <= n: env[na:na+nd] = np.linspace(1, s, nd)
    env[na+nd:n-nr] = s
    if nr > 0: env[n-nr:] = np.linspace(env[n-nr-1] if n-nr-1>0 else s, 0, nr)
    return env

def tone(freq, dur, env, partials=(1.0,)):
    x = t(dur); sig = np.zeros_like(x)
    for i, amp in enumerate(partials, start=1):
        sig += amp * np.sin(2*np.pi*freq*i*x)
    return sig * env

def tri(freq, dur, env):
    x = t(dur)
    return (2*np.abs(2*(freq*x - np.floor(freq*x+0.5)))-1) * env

def pad(volume=0.9):
    n = int(SR*0.005); s = np.copy(volume)
    return s

# Note frequencies
def nf(name):
    names = {"C3":130.81,"E3":164.81,"G3":196.00,"A3":220.00,"F3":174.61,
             "C4":261.63,"D4":293.66,"E4":329.63,"F4":349.23,"G4":392.00,"A4":440.00,"B4":493.88,
             "C5":523.25,"D5":587.33,"E5":659.25,"F5":698.46,"G5":783.99,"A5":880.00,"C6":1046.50}
    return names[name]

# ---------------- SFX ----------------
def sfx_select():
    return 0.5*tone(760, 0.05, expenv(0.05, 9))

def sfx_place():
    # warm marimba-ish confirm
    s = tone(nf("C5"), 0.20, expenv(0.20, 6), partials=(1.0,0.35,0.12))
    s += 0.5*tone(nf("G5"), 0.20, expenv(0.20, 7))
    return 0.6*s

def sfx_note():
    return 0.4*tone(1180, 0.04, expenv(0.04, 10))

def sfx_erase():
    return 0.4*tone(320, 0.10, expenv(0.10, 8), partials=(1.0,0.3))

def sfx_mistake():
    # gentle descending "uh-oh", soft triangle — not harsh
    a = tri(392, 0.12, expenv(0.12, 5))
    b = tri(294, 0.16, expenv(0.16, 5))
    sig = np.concatenate([a, b])
    return 0.5*sig

def sfx_hint():
    # sparkle: quick rising tones
    seq = [700, 950, 1300]
    parts = [tone(f, 0.06, expenv(0.06, 9)) for f in seq]
    return 0.4*np.concatenate(parts)

def sfx_unlock():
    a = tone(nf("C5"), 0.14, adsr(0.14, 0.005, 0.05, 0.6, 0.06), partials=(1.0,0.4,0.15))
    b = tone(nf("G5"), 0.22, expenv(0.22, 5), partials=(1.0,0.4,0.15))
    return 0.5*np.concatenate([a, b])

def sfx_win():
    # happy major arpeggio with bell timbre
    seq = [("C5",0.12),("E5",0.12),("G5",0.12),("C6",0.42)]
    parts = []
    for name, dur in seq:
        parts.append(tone(nf(name), dur, expenv(dur, 4), partials=(1.0,0.5,0.25,0.1)))
    sig = np.concatenate(parts)
    # add a soft shimmer octave under the last note
    return 0.55*sig

# ---------------- Music loop ----------------
def chord_pad(freqs, dur, vol=0.16):
    x = t(dur); s = np.zeros_like(x)
    env = adsr(dur, a=0.25, d=0.3, s=0.85, r=0.35)
    for f in freqs:
        s += np.sin(2*np.pi*f*x) + 0.25*np.sin(2*np.pi*2*f*x)
        s += 0.15*np.sin(2*np.pi*f*1.003*x)  # slight detune for warmth
    return vol * s/len(freqs) * env

def arp(freqs, dur, step=0.357, vol=0.10):
    n = int(SR*dur); out = np.zeros(n)
    i = 0; k = 0
    while i < n:
        f = freqs[k % len(freqs)]
        note = tri(f, min(step, (n-i)/SR), expenv(min(step,(n-i)/SR), 7))
        out[i:i+len(note)] += vol*note
        i += int(SR*step); k += 1
    return out

def bass(freq, dur, vol=0.14):
    x = t(dur)
    return vol*np.sin(2*np.pi*freq*x)*adsr(dur, 0.02, 0.2, 0.7, 0.2)

def music():
    # I - vi - IV - V in C, cozy and slow
    prog = [
        (["C4","E4","G4","B4"], "C3", ["C5","E5","G5","E5"]),
        (["A3","C4","E4","G4"], "A3", ["A4","C5","E5","C5"]),
        (["F3","A3","C4","E4"], "F3", ["F4","A4","C5","A4"]),
        (["G3","B4","D5","F5"], "G3", ["G4","B4","D5","B4"]),
    ]
    bar = 2.85
    chunks = []
    for chord, root, arpn in prog:
        cf = [nf(n) for n in chord]
        af = [nf(n) for n in arpn]
        seg = chord_pad(cf, bar) + arp(af, bar) + bass(nf(root), bar)
        chunks.append(seg)
    sig = np.concatenate(chunks)
    # normalize gently (background level)
    sig = sig / (np.max(np.abs(sig)) + 1e-9) * 0.5
    # seamless loop: crossfade tail into head
    L = int(SR*0.4)
    fade = np.linspace(0, 1, L)
    head = sig[:L].copy()
    sig[:L] = sig[:L]*fade + sig[-L:]*(1-fade)
    sig = sig[:-L]
    return sig

def main():
    write_wav("select.wav", sfx_select())
    write_wav("place.wav",  sfx_place())
    write_wav("note.wav",   sfx_note())
    write_wav("erase.wav",  sfx_erase())
    write_wav("mistake.wav",sfx_mistake())
    write_wav("hint.wav",   sfx_hint())
    write_wav("unlock.wav", sfx_unlock())
    write_wav("win.wav",    sfx_win())
    write_wav("music.wav",  music())

if __name__ == "__main__":
    main()
