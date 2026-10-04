#!/usr/bin/env python3
"""Generates the background music loops in assets/music/.

One original, seamless loop per environment (file name = environment id).
Everything is synthesized from scratch, so there are no licensing questions.
Re-run after editing to regenerate:

    pip install numpy scipy
    python3 tools/generate_music.py            # all tracks
    python3 tools/generate_music.py city camp  # only some

The loops are seamless because every sound that rings past the end of the loop
wraps around to its start, and all filters / reverbs are circular.
The tracks are written as mono 16-bit WAV at 22.05 kHz: WAV loops without the
tiny gap MP3/AAC encoders add, and the music is soft and dark enough that the
lower sample rate is not audible. Convert to another format if size matters.
"""
import os
import sys
import wave

import numpy as np
from scipy import signal

SR = 22050
OUT_DIR = os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'music'))

TARGET_RMS = 0.10  # about -20 dBFS: background level, the player lowers it more


# --------------------------------------------------------------------------
# Basics
# --------------------------------------------------------------------------

def midi(n):
    return 440.0 * 2.0 ** ((np.asarray(n, dtype=float) - 69.0) / 12.0)


def tt(dur):
    return np.arange(int(round(dur * SR))) / SR


def _filt(x, kind, cutoff, order, circular):
    sos = signal.butter(order, cutoff, kind, fs=SR, output='sos')
    if not circular:
        return signal.sosfilt(sos, x)
    n = len(x)
    return signal.sosfilt(sos, np.concatenate([x, x, x]))[n:2 * n]


def lp(x, cutoff, order=2, circular=False):
    return _filt(x, 'low', cutoff, order, circular)


def hp(x, cutoff, order=2, circular=False):
    return _filt(x, 'high', cutoff, order, circular)


def bp(x, lo, hi, order=2, circular=False):
    sos = signal.butter(order, [lo, hi], 'band', fs=SR, output='sos')
    if not circular:
        return signal.sosfilt(sos, x)
    n = len(x)
    return signal.sosfilt(sos, np.concatenate([x, x, x]))[n:2 * n]


def ar_env(n, attack, release):
    """Raised-cosine attack and release around a flat sustain."""
    e = np.ones(n)
    a = min(int(attack * SR), n // 2)
    r = min(int(release * SR), n // 2)
    if a > 0:
        e[:a] = 0.5 - 0.5 * np.cos(np.pi * np.arange(a) / a)
    if r > 0:
        e[n - r:] = 0.5 + 0.5 * np.cos(np.pi * np.arange(r) / r)
    return e


def finish(sig, attack=0.003, tail=0.015):
    """Removes clicks at the start and end of a one-shot sound."""
    a = min(int(attack * SR), len(sig) // 2)
    r = min(int(tail * SR), len(sig) // 2)
    if a > 0:
        sig[:a] *= np.linspace(0, 1, a)
    if r > 0:
        sig[-r:] *= np.linspace(1, 0, r)
    return sig


class Loop:
    def __init__(self, seconds, seed):
        self.L = int(round(seconds * SR))
        self.seconds = self.L / SR
        self.rng = np.random.default_rng(seed)
        self.buses = {}

    def add(self, bus, start, sig, gain=1.0):
        """Mixes [sig] in at [start] seconds; whatever passes the end wraps."""
        b = self.buses.setdefault(bus, np.zeros(self.L))
        sig = np.asarray(sig) * gain
        n = len(sig)
        i0 = int(round(start * SR)) % self.L
        k = min(n, self.L - i0)
        b[i0:i0 + k] += sig[:k]
        done = k
        while done < n:
            m = min(n - done, self.L)
            b[:m] += sig[done:done + m]
            done += m

    def lfo_freq(self, hz):
        """Closest frequency that fits a whole number of cycles in the loop."""
        return max(1, round(hz * self.seconds)) / self.seconds

    def time(self):
        return np.arange(self.L) / SR

    def noise(self):
        return self.rng.standard_normal(self.L)


# --------------------------------------------------------------------------
# Instruments (one-shot sounds)
# --------------------------------------------------------------------------

def partials(f, dur, parts, attack=0.003):
    t = tt(dur)
    sig = np.zeros_like(t)
    for ratio, amp, decay in parts:
        fr = f * ratio
        if fr > 9500:
            continue
        sig += amp * np.exp(-decay * t) * np.sin(2 * np.pi * fr * t)
    return finish(sig, attack=attack)


MARIMBA = [(1, 1.0, 3.2), (3.97, 0.30, 10.0), (9.2, 0.06, 22.0)]
BELL = [(1, 1.0, 0.9), (2.0, 0.55, 1.3), (2.76, 0.40, 1.8),
        (5.4, 0.22, 2.6), (8.93, 0.12, 3.5)]
BLIP = [(1, 1.0, 9.0), (3, 0.12, 12.0), (5, 0.05, 14.0)]


def guitar(f, dur, bright=0.82, decay=1.5):
    parts = []
    for k in range(1, 15):
        ratio = k * (1 + 0.00005 * k * k)
        amp = bright ** (k - 1) / k ** 0.6
        parts.append((ratio, amp, decay + 0.6 * (k - 1)))
    return partials(f, dur, parts)


def pad_note(f, dur, attack, release, rng, detune=(-6, 6), harmonics=6):
    t = tt(dur + release)
    sig = np.zeros_like(t)
    for cents in detune:
        ff = f * 2 ** (cents / 1200)
        phase = rng.uniform(0, 2 * np.pi)
        for k in range(1, harmonics + 1):
            if k * ff > 8000:
                break
            sig += np.sin(2 * np.pi * k * ff * t + phase * k) / k ** 1.6
    return sig * ar_env(len(t), attack, release) / len(detune)


def epiano(f, dur, vel=1.0):
    t = tt(dur)
    index = 1.5 * vel * np.exp(-t * 3.2) + 0.15
    mod = np.sin(2 * np.pi * f * t)
    sig = np.sin(2 * np.pi * f * t + index * mod)
    if f * 7 < 9500:
        sig += 0.12 * np.sin(2 * np.pi * f * 7 * t) * np.exp(-t * 14)
    sig *= np.exp(-t * (1.0 + f / 900.0))
    return finish(sig * vel, attack=0.004, tail=0.05)


def bass_note(f, dur):
    t = tt(dur)
    sig = (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t)
           + 0.08 * np.sin(6 * np.pi * f * t))
    return finish(sig * np.exp(-t * 1.6), attack=0.01, tail=0.08)


def kick():
    t = tt(0.35)
    phase = 2 * np.pi * np.cumsum(45 + 95 * np.exp(-t * 30)) / SR
    return finish(np.sin(phase) * np.exp(-t * 9), attack=0.001)


def snare(rng):
    t = tt(0.25)
    noise = bp(rng.standard_normal(len(t)), 1200, 5000)
    tone = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 24)
    return finish((0.9 * noise * np.exp(-t * 18) + 0.5 * tone), attack=0.001)


def hat(rng, decay=55):
    t = tt(0.07)
    return finish(hp(rng.standard_normal(len(t)), 5000) * np.exp(-t * decay),
                  attack=0.0005, tail=0.01)


def bubble(f0, rng):
    t = tt(0.14)
    freq = f0 * (1 + 1.6 * t / 0.14)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    return finish(np.sin(phase) * np.sin(np.pi * t / 0.14) ** 2 * np.exp(-t * 9),
                  attack=0.002)


def cricket_chirp():
    pulse = tt(0.025)
    shape = np.sin(np.pi * pulse / 0.025) ** 2
    one = shape * np.sin(2 * np.pi * 4300 * pulse)
    gap = np.zeros(int(0.018 * SR))
    return np.concatenate([one, gap, one, gap, one])


# --------------------------------------------------------------------------
# Effects and master
# --------------------------------------------------------------------------

def reverb_ir(rt60, seed=3, damp=3500, predelay=0.02):
    rng = np.random.default_rng(seed)
    n = int(rt60 * 1.1 * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-6.91 * t / rt60)
    ir = lp(ir, damp, order=1)
    ir = np.concatenate([np.zeros(int(predelay * SR)), ir])
    return ir / np.sqrt(np.sum(ir ** 2))


def echo_ir(delay, feedback, taps):
    n = int(round(delay * SR * taps)) + 2
    ir = np.zeros(n)
    for k in range(1, taps + 1):
        ir[int(round(k * delay * SR))] = feedback ** (k - 1)
    return lp(ir, 2800, order=1)


def conv_circ(x, ir):
    n = len(x)
    assert len(ir) < n, 'effect tail longer than the loop'
    return np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir, n=n), n=n)


def rms(x):
    return float(np.sqrt(np.mean(x ** 2)) + 1e-12)


def master(loop, mix, rt60, echo=None, master_lp=None):
    """Mixes the buses.

    Each bus is normalized to RMS 1 first, so the numbers in [mix] are relative
    loudness: 'dry' direct level, 'rev' reverb send, 'echo' echo send,
    'lp' / 'hp' optional circular filters applied to the bus first.
    """
    n = loop.L
    dry = np.zeros(n)
    send = np.zeros(n)
    echo_send = np.zeros(n)
    for name, buf in loop.buses.items():
        cfg = mix[name]
        x = buf
        if cfg.get('lp'):
            x = lp(x, cfg['lp'], circular=True)
        if cfg.get('hp'):
            x = hp(x, cfg['hp'], circular=True)
        x = x / rms(x)
        dry += x * cfg.get('dry', 1.0)
        send += x * cfg.get('rev', 0.0)
        echo_send += x * cfg.get('echo', 0.0)
    out = dry
    if echo:
        e = conv_circ(echo_send, echo_ir(*echo))
        out = out + e
        send = send + 0.6 * e
    out = out + conv_circ(send, reverb_ir(rt60))
    if master_lp:
        out = lp(out, master_lp, circular=True)
    out = hp(out, 35, circular=True)
    out = out - np.mean(out)
    out = out * (TARGET_RMS / rms(out))
    # Soft limiter so a stray peak never clips.
    return np.tanh(out * 1.1) / 1.1


def write_wav(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# --------------------------------------------------------------------------
# Tracks
# --------------------------------------------------------------------------

def space_station():
    """Slow drifting pads, sparse bells with long echoes. D major / lydian."""
    lo = Loop(40.0, seed=11)
    rng = lo.rng
    seg = 10.0
    chords = [
        [38, 50, 57, 61, 64, 66],      # Dmaj9
        [43, 50, 59, 66, 73],          # Gmaj7#11
        [47, 54, 62, 66, 69, 73],      # Bm9
        [45, 52, 59, 64, 66],          # A6sus2
    ]
    for i, chord in enumerate(chords):
        for j, note in enumerate(chord):
            lo.add('pad', i * seg + j * 0.35,
                   pad_note(midi(note), seg - 0.5, 3.0, 4.0, rng), 1.0)
    scale = [74, 76, 78, 81, 83, 86, 88]
    t = 1.5
    while t < 38.0:
        lo.add('bell', t, partials(midi(rng.choice(scale)), 5.0, BELL),
               rng.uniform(0.5, 1.0))
        t += rng.uniform(2.4, 5.2)
    tm = lo.time()
    drone = np.sin(2 * np.pi * lo.lfo_freq(73.4) * tm)
    drone *= 0.85 + 0.15 * np.sin(2 * np.pi * lo.lfo_freq(0.1) * tm)
    lo.buses['drone'] = drone
    mix = {
        'pad': dict(dry=1.0, rev=0.5, lp=1800),
        'bell': dict(dry=0.35, rev=0.8, echo=0.6, lp=3500),
        'drone': dict(dry=0.30),
    }
    return master(lo, mix, rt60=5.5, echo=(0.9, 0.5, 5))


def island():
    """Marimba arpeggios, soft bass, ocean swell. C major, 80 bpm."""
    lo = Loop(36.0, seed=21)
    rng = lo.rng
    bar, step = 3.0, 0.375
    chords = [
        dict(root=48, arp=[60, 64, 67, 72], pad=[60, 64, 67]),   # C
        dict(root=45, arp=[57, 60, 64, 69], pad=[57, 60, 64]),   # Am
        dict(root=41, arp=[57, 60, 65, 69], pad=[57, 60, 65]),   # F
        dict(root=43, arp=[59, 62, 67, 71], pad=[59, 62, 67]),   # G
    ]
    pattern = [0, 2, 1, 3, 2, 1, 3, 2]
    for ci, ch in enumerate(chords):
        lo.add('pad', ci * 3 * bar,
               sum_notes(ch['pad'], 3 * bar - 1.0, 1.5, 2.5, rng), 1.0)
        for b in range(3):
            t0 = (ci * 3 + b) * bar
            lo.add('bass', t0, bass_note(midi(ch['root']), 1.4), 1.0)
            lo.add('bass', t0 + 1.5, bass_note(midi(ch['root']), 1.2), 0.6)
            for s in range(8):
                if s != 0 and rng.random() < 0.2:
                    continue
                note = ch['arp'][pattern[s]]
                if s in (4, 7) and rng.random() < 0.35:
                    note = ch['arp'][rng.integers(0, 4)] + 12
                vel = (0.95 if s == 0 else 0.7) * rng.uniform(0.85, 1.0)
                lo.add('mallet', t0 + s * step, partials(midi(note), 1.6, MARIMBA), vel)
    tm = lo.time()
    n1, n2 = lo.noise(), lo.noise()
    low = lp(n1, 600, circular=True)
    hiss = hp(lp(n2, 3500, circular=True), 1200, circular=True)
    sw1 = 0.5 + 0.5 * np.sin(2 * np.pi * lo.lfo_freq(1 / 9.0) * tm)
    sw2 = 0.5 + 0.5 * np.sin(2 * np.pi * lo.lfo_freq(1 / 12.0) * tm + 1.3)
    lo.buses['waves'] = (low / rms(low)) * (0.3 + 0.7 * (0.6 * sw1 + 0.4 * sw2) ** 2) \
        + 0.35 * (hiss / rms(hiss)) * (sw1 ** 3)
    mix = {
        'pad': dict(dry=0.35, rev=0.2, lp=2500),
        'bass': dict(dry=0.55, lp=900),
        'mallet': dict(dry=1.0, rev=0.35),
        'waves': dict(dry=0.28, rev=0.1),
    }
    return master(lo, mix, rt60=1.6)


def laboratory():
    """Minimal electronic: soft arpeggio, hats, bubbles. E minor, 100 bpm."""
    lo = Loop(38.4, seed=31)
    rng = lo.rng
    bar, step = 2.4, 0.15
    chords = [
        dict(root=40, arp=[64, 67, 71, 74, 78], pad=[52, 59, 62, 66, 67]),  # Em9
        dict(root=48, arp=[60, 64, 67, 71, 74], pad=[48, 55, 59, 62, 64]),  # Cmaj9
        dict(root=45, arp=[57, 60, 64, 67, 71], pad=[45, 52, 55, 59, 60]),  # Am9
        dict(root=47, arp=[59, 62, 66, 69, 74], pad=[47, 54, 57, 62, 66]),  # Bm7
    ]
    seq = [0, 1, 2, 3, 4, 3, 2, 1]
    accents = [1.0, 0.45, 0.6, 0.45]
    for ci, ch in enumerate(chords):
        lo.add('pad', ci * 4 * bar,
               sum_notes(ch['pad'], 4 * bar - 1.0, 1.5, 2.0, rng), 1.0)
        for b in range(4):
            t0 = (ci * 4 + b) * bar
            lo.add('bass', t0, bass_note(midi(ch['root']), 0.9), 1.0)
            lo.add('bass', t0 + 6 * step, bass_note(midi(ch['root']), 0.35), 0.7)
            for s in range(16):
                if s % 4 != 0 and rng.random() < 0.12:
                    continue
                note = ch['arp'][seq[s % 8]]
                lo.add('arp', t0 + s * step, partials(midi(note), 0.3, BLIP, attack=0.006),
                       accents[s % 4] * rng.uniform(0.85, 1.0))
            for s in (2, 6, 10, 14):
                lo.add('hat', t0 + s * step, hat(rng), rng.uniform(0.6, 1.0))
    t = 2.0
    while t < lo.seconds - 1.0:
        lo.add('bubble', t, bubble(rng.uniform(500, 1100), rng), rng.uniform(0.6, 1.0))
        t += rng.uniform(1.6, 4.2)
    # Filter sweep on the arpeggio: mix a dark and a bright version.
    tm = lo.time()
    sweep = 0.5 + 0.5 * np.sin(2 * np.pi * lo.lfo_freq(1 / 19.2) * tm)
    a = lo.buses['arp']
    lo.buses['arp'] = lp(a, 900, circular=True) * (1 - sweep) \
        + lp(a, 4500, circular=True) * sweep
    mix = {
        'pad': dict(dry=0.5, rev=0.2, lp=1600),
        'bass': dict(dry=0.5, lp=700),
        'arp': dict(dry=0.9, rev=0.25, echo=0.5),
        'hat': dict(dry=0.18),
        'bubble': dict(dry=0.22, rev=0.4),
    }
    return master(lo, mix, rt60=1.3, echo=(0.45, 0.38, 5))


def city():
    """Lo-fi night drive: electric piano, soft beat, vinyl. C major, 80 bpm."""
    lo = Loop(48.0, seed=41)
    rng = lo.rng
    beat, bar = 0.75, 3.0
    chords = [  # rootless piano voicings, bass root
        ([53, 57, 60, 64], 38),   # Dm9
        ([53, 59, 64, 69], 43),   # G13
        ([52, 55, 59, 62], 48),   # Cmaj9
        ([55, 59, 60, 64], 45),   # Am9
        ([57, 60, 64, 67], 41),   # Fmaj9
        ([55, 59, 62, 64], 40),   # Em7
        ([53, 57, 60, 64], 38),   # Dm9
        ([53, 59, 64, 69], 43),   # G13
    ]

    def hit(t, notes, dur, vel):
        for i, n in enumerate(notes):
            lo.add('keys', t + i * 0.018, epiano(midi(n), dur, vel * rng.uniform(0.9, 1.0)))

    for ci, (notes, root) in enumerate(chords):
        for b in range(2):
            t0 = (ci * 2 + b) * bar
            if b == 0:
                hit(t0, notes, 2.4, 0.9)
                hit(t0 + 2.5 * beat, notes, 1.0, 0.65)
            else:
                hit(t0 + 1.5 * beat, notes, 1.4, 0.75)
                hit(t0 + 3.0 * beat, notes, 1.0, 0.6)
                if rng.random() < 0.7:
                    pos = rng.choice([0.0, 1.0, 2.0, 2.5])
                    lo.add('keys', t0 + pos * beat,
                           epiano(midi(rng.choice(notes) + 12), 1.5, 0.7), 0.7)
            lo.add('bass', t0, bass_note(midi(root), 1.4), 1.0)
            lo.add('bass', t0 + 2.5 * beat, bass_note(midi(root), 0.6), 0.65)
            for kb in ([0.0, 2.5] + ([1.5] if b == 1 else [])):
                lo.add('drums', t0 + kb * beat, kick(), 1.0)
            for sb in (1.0, 3.0):
                lo.add('drums', t0 + sb * beat, snare(rng), 0.55 * rng.uniform(0.9, 1.0))
            for e in range(8):
                swing = 0.12 * beat if e % 2 else 0.0
                lo.add('drums', t0 + e * 0.5 * beat + swing, hat(rng),
                       (0.5 if e % 2 == 0 else 0.3) * rng.uniform(0.7, 1.0))
    # Vinyl crackle.
    n = np.zeros(lo.L)
    pos = rng.integers(0, lo.L, size=int(6 * lo.seconds))
    n[pos] = rng.random(len(pos)) ** 3
    lo.buses['vinyl'] = hp(n, 2500, circular=True)
    mix = {
        'keys': dict(dry=1.0, rev=0.3, lp=4500),
        'bass': dict(dry=0.6, lp=800),
        'drums': dict(dry=0.40, lp=5000),
        'vinyl': dict(dry=0.07),
    }
    return master(lo, mix, rt60=1.4, master_lp=7000)


def camp():
    """Fingerpicked acoustic guitar, crickets, fire. G major, 72 bpm."""
    lo = Loop(40.0, seed=51)
    rng = lo.rng
    bar = 40.0 / 12
    step = bar / 8
    chords = [
        dict(bass=[43, 50], up=[59, 62, 67], pad=[43, 50, 55]),   # G
        dict(bass=[40, 47], up=[55, 59, 64], pad=[40, 47, 52]),   # Em
        dict(bass=[48, 43], up=[60, 64, 67], pad=[48, 55, 52]),   # C
        dict(bass=[50, 45], up=[57, 62, 66], pad=[50, 57, 54]),   # D
    ]
    for ci, ch in enumerate(chords):
        lo.add('pad', ci * 3 * bar,
               sum_notes(ch['pad'], 3 * bar - 1.0, 1.8, 2.5, rng, harmonics=3), 1.0)
        order = [('b', 0), ('u', 1), ('u', 0), ('u', 2),
                 ('b', 1), ('u', 1), ('u', 0), ('u', 2)]
        for b in range(3):
            t0 = (ci * 3 + b) * bar
            for s, (kind, idx) in enumerate(order):
                note = ch['bass'][idx] if kind == 'b' else ch['up'][idx]
                vel = (1.0 if kind == 'b' else 0.7) * rng.uniform(0.85, 1.0)
                jitter = rng.uniform(-0.008, 0.008) if s else 0.0
                lo.add('guitar', t0 + s * step + jitter,
                       guitar(midi(note), 3.0), vel)
    # Crickets: short windows of chirps.
    t = rng.uniform(0.5, 2.0)
    while t < lo.seconds - 4:
        length = rng.uniform(3.0, 7.0)
        c = t
        while c < t + length:
            lo.add('crickets', c, cricket_chirp(), rng.uniform(0.7, 1.0))
            c += rng.uniform(0.42, 0.55)
        t += length + rng.uniform(4.0, 9.0)
    # Fire: crackles over a faint low rumble.
    pops = np.zeros(lo.L)
    pos = rng.integers(0, lo.L, size=int(12 * lo.seconds))
    pops[pos] = rng.random(len(pos)) ** 3
    fire = bp(pops, 700, 5000, circular=True)
    rumble = lp(lo.noise(), 300, circular=True)
    lo.buses['fire'] = fire / rms(fire) + 0.5 * rumble / rms(rumble)
    mix = {
        'guitar': dict(dry=1.0, rev=0.2, lp=6500),
        'pad': dict(dry=0.18, lp=1500),
        'crickets': dict(dry=0.035, rev=0.05),
        'fire': dict(dry=0.14),
    }
    return master(lo, mix, rt60=1.0)


def sum_notes(notes, dur, attack, release, rng, harmonics=6):
    """A whole chord as one sound, so it can be placed with Loop.add."""
    parts = [pad_note(midi(n), dur, attack, release, rng, harmonics=harmonics)
             for n in notes]
    out = np.zeros(max(len(p) for p in parts))
    for p in parts:
        out[:len(p)] += p
    return out


TRACKS = {
    'space_station': space_station,
    'island': island,
    'laboratory': laboratory,
    'city': city,
    'camp': camp,
}


def main(names):
    os.makedirs(OUT_DIR, exist_ok=True)
    for name in names:
        x = TRACKS[name]()
        path = os.path.join(OUT_DIR, f'{name}.wav')
        write_wav(path, x)
        jump = abs(x[0] - x[-1])
        typical = float(np.percentile(np.abs(np.diff(x)), 99))
        print(f'{name:14s} {len(x) / SR:5.1f}s  peak {np.max(np.abs(x)):.2f}  '
              f'rms {rms(x):.3f}  loop jump {jump:.4f} (99% step {typical:.4f})')


if __name__ == '__main__':
    selected = sys.argv[1:] or list(TRACKS)
    unknown = [n for n in selected if n not in TRACKS]
    if unknown:
        sys.exit(f'unknown track(s): {unknown}; choose from {list(TRACKS)}')
    main(selected)
