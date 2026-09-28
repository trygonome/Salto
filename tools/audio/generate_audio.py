#!/usr/bin/env python3
"""Génère les bruitages du jeu, entièrement synthétisés (pas de licence tierce).

Depuis la version 4.0, la musique est jouée par de vrais instruments (`make_music.py`, qui reprend
d'ici le tempo, la boucle de 8 mesures et quelques sons) et les ambiances sont de vraies prises de
forêt (`fetch_sounds.py`).

Usage : python3 tools/audio/generate_audio.py   (demande numpy)
"""
import math
import pathlib
import wave

import numpy as np

RATE = 44100
BPM = 104
BEATS_PER_BAR = 4
BARS = 8
BEAT = 60.0 / BPM
LOOP_SAMPLES = round(BARS * BEATS_PER_BAR * BEAT * RATE)
ROOT = pathlib.Path(__file__).resolve().parents[2]
RNG = np.random.default_rng(104)

# Ré majeur pentatonique : ré, mi, fa#, la, si.
D3 = 146.83


def note(semitones_from_d3):
    return D3 * 2 ** (semitones_from_d3 / 12)


PENTA = [0, 2, 4, 7, 9]


def degree(d, octave=0):
    """Degré de la gamme pentatonique (0 = ré), avec octaves."""
    o, i = divmod(d, len(PENTA))
    return note(PENTA[i] + 12 * (o + octave))


def env(length, attack, decay):
    t = np.arange(length) / RATE
    a = np.minimum(t / max(attack, 1e-4), 1.0)
    return a * np.exp(-t / decay)


def add(buf, start_beat, signal, gain):
    start = round(start_beat * BEAT * RATE)
    idx = (start + np.arange(len(signal))) % len(buf)
    np.add.at(buf, idx, signal * gain)


def kick(length=0.35):
    n = int(length * RATE)
    t = np.arange(n) / RATE
    freq = 45 + 75 * np.exp(-t / 0.04)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    return np.sin(phase) * env(n, 0.002, 0.12)


def tom(pitch, length=0.4):
    n = int(length * RATE)
    t = np.arange(n) / RATE
    freq = pitch * (1 + 0.6 * np.exp(-t / 0.03))
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    body = np.sin(phase) * env(n, 0.001, 0.14)
    slap = RNG.standard_normal(n) * env(n, 0.0005, 0.012)
    return body + 0.35 * slap


def marimba(freq, length=0.6):
    n = int(length * RATE)
    t = np.arange(n) / RATE
    fundamental = np.sin(2 * np.pi * freq * t) * env(n, 0.002, 0.32)
    overtone = np.sin(2 * np.pi * freq * 4 * t) * env(n, 0.001, 0.03)
    return fundamental + 0.3 * overtone


def voice(freq, length):
    """Voix d'un Muet qui chante « aah » : deux formants sur une note tenue, un peu de vibrato."""
    n = int(length * RATE)
    t = np.arange(n) / RATE
    vibrato = 1 + 0.01 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(t / 0.3, 1)
    phase = 2 * np.pi * np.cumsum(freq * vibrato) / RATE
    tone = np.zeros(n)
    for k in range(1, 9):
        # Formants d'un « a » (vers 700 Hz et 1200 Hz).
        f = freq * k
        weight = np.exp(-((f - 700) / 260) ** 2) + 0.6 * np.exp(-((f - 1200) / 300) ** 2) + 0.35 / k
        tone += weight * np.sin(k * phase)
    shape = np.minimum(t / 0.12, 1.0) * np.minimum((length - t) / 0.25, 1.0).clip(0, 1)
    return tone * shape


def sfx_hit():
    n = int(0.25 * RATE)
    body = kick(0.25)[:n] * 0.9
    snap = RNG.standard_normal(n) * env(n, 0.0005, 0.02)
    return np.tanh(1.4 * (body + 0.6 * snap))


def sfx_chime():
    n = int(0.9 * RATE)
    t = np.arange(n) / RATE
    f = degree(5, 1)  # ré aigu ; le jeu le transpose sur la gamme
    tone = sum(a * np.sin(2 * np.pi * f * m * t) for m, a in [(1, 1.0), (2.01, 0.35), (3.02, 0.15)])
    return tone * env(n, 0.002, 0.22)


def sfx_telegraph():
    """Annonce d'une attaque : deux coups de cor graves, comme un tambour qui prévient."""
    out = np.zeros(int(0.5 * RATE))
    for k, start in enumerate((0.0, 0.2)):
        n = int(0.22 * RATE)
        t = np.arange(n) / RATE
        f = note(-12 + (0 if k == 0 else -2))
        tone = np.sign(np.sin(2 * np.pi * f * t)) * 0.4 + np.sin(2 * np.pi * f * t)
        seg = np.tanh(tone * env(n, 0.01, 0.09))
        i = int(start * RATE)
        out[i:i + n] += seg
    return out


def sfx_freed():
    """Muet libéré : le premier son qu'il fait est toujours un rire (arpège qui monte)."""
    out = np.zeros(int(0.7 * RATE))
    for k, d in enumerate([5, 7, 8, 10, 12]):
        n = int(0.16 * RATE)
        t = np.arange(n) / RATE
        f = degree(d, 0)
        wobble = 1 + 0.03 * np.sin(2 * np.pi * 18 * t)
        seg = np.sin(2 * np.pi * np.cumsum(f * wobble) / RATE) * env(n, 0.004, 0.06)
        i = int(k * 0.09 * RATE)
        out[i:i + n] += seg
    return out


def sfx_boss_freed():
    """Grand Muet libéré : sa voix revient, un long arpège qui s'ouvre."""
    out = np.zeros(int(2.2 * RATE))
    for k, d in enumerate([0, 2, 4, 5, 7, 9, 10, 12]):
        seg = marimba(degree(d, -1), 0.9)
        i = int(k * 0.14 * RATE)
        out[i:i + len(seg)] += seg
    return out


def sfx_answer():
    """Bonne réponse à un Muet : sa voix revient un instant, deux notes de marimba qui montent."""
    out = np.zeros(int(0.6 * RATE))
    for k, d in enumerate([7, 12]):
        seg = marimba(degree(d, 0), 0.45)
        i = int(k * 0.07 * RATE)
        out[i:i + len(seg)] += seg
    return out


def sfx_hurt():
    """Héros touché : un choc sourd et une note qui descend."""
    n = int(0.3 * RATE)
    t = np.arange(n) / RATE
    f = 330 * np.exp(-t / 0.15)
    tone = np.sin(2 * np.pi * np.cumsum(f) / RATE) * env(n, 0.002, 0.12)
    thud = kick(0.3)[:n]
    return np.tanh(1.2 * (tone + thud))


def sfx_dodge():
    """Esquive parfaite : un souffle qui passe."""
    n = int(0.35 * RATE)
    t = np.arange(n) / RATE
    noise = RNG.standard_normal(n)
    smooth = np.convolve(noise, np.ones(8) / 8, mode="same")
    shape = np.sin(np.pi * t / t[-1]) ** 2
    return (noise - smooth) * shape


def sfx_gong():
    """Gong des anciens : partiels inharmoniques, longue résonance (ré ; le jeu le transpose)."""
    n = int(2.4 * RATE)
    t = np.arange(n) / RATE
    f = degree(0, 0)
    partials = [(1.0, 1.0, 1.4), (2.76, 0.5, 0.9), (5.4, 0.25, 0.5), (8.9, 0.12, 0.25)]
    tone = sum(a * np.sin(2 * np.pi * f * m * t) * np.exp(-t / d) for m, a, d in partials)
    strike = RNG.standard_normal(n) * env(n, 0.0005, 0.01)
    return tone * np.minimum(t / 0.004, 1.0) + 0.3 * strike


def sfx_chest():
    """Coffre qui s'ouvre : un grincement court puis une pluie de notes."""
    out = np.zeros(int(1.0 * RATE))
    n = int(0.25 * RATE)
    t = np.arange(n) / RATE
    creak = np.sin(2 * np.pi * np.cumsum(90 + 40 * np.sin(2 * np.pi * 7 * t)) / RATE) * env(n, 0.02, 0.1)
    out[:n] += 0.6 * creak
    for k, d in enumerate([7, 9, 10, 12, 14]):
        seg = marimba(degree(d, 0), 0.5)
        i = int((0.2 + 0.07 * k) * RATE)
        out[i:i + len(seg)] += 0.5 * seg[: len(out) - i]
    return out


def sfx_pickup():
    """Objet ramassé : deux notes brillantes."""
    out = np.zeros(int(0.5 * RATE))
    for k, d in enumerate([10, 12]):
        seg = marimba(degree(d, 0), 0.4)
        i = int(0.08 * k * RATE)
        out[i:i + len(seg)] += seg
    return out


def sfx_drum_return():
    """Tambour rapporté : un roulement de tambours qui monte, et un grand coup."""
    out = np.zeros(int(1.6 * RATE))
    for k in range(10):
        seg = tom(150 + 12 * k, 0.3)
        i = int(0.07 * k * RATE)
        out[i:i + len(seg)] += (0.4 + 0.05 * k) * seg
    big = tom(110, 0.9) + kick(0.9)
    i = int(0.75 * RATE)
    out[i:i + len(big)] += big[: len(out) - i]
    return out


def sfx_bounce():
    """Champignon-trampoline : un « boïng » qui monte."""
    n = int(0.35 * RATE)
    t = np.arange(n) / RATE
    f = 180 * np.exp(t / 0.18)
    wobble = 1 + 0.08 * np.sin(2 * np.pi * 22 * t)
    return np.sin(2 * np.pi * np.cumsum(f * wobble) / RATE) * env(n, 0.003, 0.14)


def band_noise(length, f_start, f_end, q=1.2, rng=None):
    """Bruit passé dans un filtre passe-bande dont la fréquence glisse de f_start à f_end
    (`rng` : tirage propre, pour ne pas changer les autres sons)."""
    n = int(length * RATE)
    noise = (rng if rng is not None else RNG).standard_normal(n)
    freqs = np.geomspace(f_start, f_end, n)
    out = np.zeros(n)
    low = band = 0.0
    damping = 1.0 / q
    for i in range(n):
        f = 2 * math.sin(math.pi * freqs[i] / RATE)
        low += f * band
        high = noise[i] - low - damping * band
        band += f * high
        out[i] = band
    return out


def whoosh(length, f_start, f_end, q=1.2, rng=None):
    """Souffle : bruit filtré qui glisse, qui enfle puis retombe."""
    n = int(length * RATE)
    t = np.arange(n) / RATE
    shape = np.sin(np.pi * t / t[-1]) ** 1.5
    return band_noise(length, f_start, f_end, q, rng) * shape


def sfx_jump():
    """Saut : un petit souffle qui monte."""
    return whoosh(0.18, 350, 1300, 1.5)


def sfx_salto():
    """Salto : un souffle plus long qui tourne, et un reflet de carillon."""
    n = int(0.42 * RATE)
    t = np.arange(n) / RATE
    air = whoosh(0.42, 500, 2600, 2.0)
    shine = np.sin(2 * np.pi * degree(12, 0) * t) * env(n, 0.05, 0.12) * 0.15
    return air + shine * np.max(np.abs(air))


def sfx_land():
    """Atterrissage : un petit choc sourd dans l'herbe."""
    n = int(0.16 * RATE)
    t = np.arange(n) / RATE
    f = 55 + 60 * np.exp(-t / 0.02)
    thump = np.sin(2 * np.pi * np.cumsum(f) / RATE) * env(n, 0.001, 0.05)
    grass = band_noise(0.16, 1800, 900, 1.0) * env(n, 0.001, 0.03)
    return thump + 0.25 * grass / max(np.max(np.abs(grass)), 1e-9)


def sfx_roll():
    """Roulade : un froissement qui roule."""
    n = int(0.32 * RATE)
    t = np.arange(n) / RATE
    rustle = band_noise(0.32, 700, 400, 0.9)
    tumble = 0.6 + 0.4 * np.sin(2 * np.pi * 14 * t)
    return rustle * tumble * np.sin(np.pi * t / t[-1])


def sfx_swing():
    """Coup de pied dans le vide : un souffle bref qui descend."""
    return whoosh(0.14, 1600, 500, 1.4)


def sfx_slam():
    """Frappe au sol du Grand Muet : un grondement profond."""
    n = int(0.9 * RATE)
    t = np.arange(n) / RATE
    f = 38 + 50 * np.exp(-t / 0.05)
    boom = np.sin(2 * np.pi * np.cumsum(f) / RATE) * env(n, 0.002, 0.3)
    rumble = band_noise(0.9, 180, 60, 0.8) * env(n, 0.002, 0.25)
    return np.tanh(1.5 * (boom + 0.5 * rumble / max(np.max(np.abs(rumble)), 1e-9)))


def sfx_ui_click():
    """Bouton de l'interface : un petit tic de bois."""
    return marimba(degree(10, 0), 0.12)


def sfx_title():
    """Grand titre : un accord de marimba qui s'ouvre, en arpège rapide."""
    out = np.zeros(int(1.6 * RATE))
    for k, d in enumerate([0, 4, 7, 10]):
        seg = marimba(degree(d, 0), 1.2)
        i = int(0.06 * k * RATE)
        out[i:i + len(seg)] += seg[: len(out) - i]
    return out


def sweep(length, f_start, f_end, shape):
    """Son qui glisse de f_start à f_end (Hz) : sinus, triangle ou carré."""
    n = int(length * RATE)
    t = np.arange(n) / RATE
    freq = f_start * (max(f_end, 1.0) / f_start) ** (t / length)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    if shape == "square":
        return np.sign(np.sin(phase))
    if shape == "triangle":
        return 2 / np.pi * np.arcsin(np.sin(phase))
    return np.sin(phase)


def sfx_clink():
    """Coup arrêté par un bouclier : un tintement métallique bref."""
    n = int(0.22 * RATE)
    a = sweep(0.22, 1800, 1200, "square") * env(n, 0.001, 0.05) * 0.5
    b = sweep(0.22, 2600, 2600, "sine") * env(n, 0.001, 0.08)
    return a + b


def sfx_spit():
    """Crachat d'une bulle de silence : un « ploup » qui descend."""
    n = int(0.18 * RATE)
    return sweep(0.18, 420, 160, "triangle") * env(n, 0.003, 0.06)


def sfx_ui_card():
    """Carte de don qui surgit : un petit tambour de bois accordé (son propre tirage : il ne change
    pas les autres sons)."""
    rng = np.random.default_rng(22)
    n = int(0.22 * RATE)
    t = np.arange(n) / RATE
    freq = degree(0, 1) * (1 + 0.35 * np.exp(-t / 0.02))
    body = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * env(n, 0.001, 0.06)
    slap = rng.standard_normal(n) * env(n, 0.0005, 0.006)
    return body + 0.25 * slap + 0.4 * marimba(degree(0, 2), 0.22)


def normalized(signal):
    return signal / max(np.max(np.abs(signal)), 1e-9)


def sfx_break():
    """Équilibre brisé : un craquement sec et un tambour qui s'effondre (tirage propre)."""
    rng = np.random.default_rng(231)
    n = int(0.55 * RATE)
    t = np.arange(n) / RATE
    crack = normalized(band_noise(0.55, 3200, 700, 1.6, rng)) * env(n, 0.0005, 0.04)
    f = 70 + 140 * np.exp(-t / 0.08)
    drop = np.sin(2 * np.pi * np.cumsum(f) / RATE) * env(n, 0.002, 0.2)
    clicks = np.zeros(n)
    for k, at in enumerate((0.0, 0.035, 0.07)):
        i = int(at * RATE)
        m = int(0.02 * RATE)
        clicks[i:i + m] += rng.standard_normal(m) * env(m, 0.0002, 0.004) * (1.0 - 0.25 * k)
    return np.tanh(1.3 * (0.8 * crack + drop + 0.6 * clicks))


def sfx_impact():
    """Muet projeté contre un obstacle : un choc sourd et du bois qui craque (tirage propre)."""
    rng = np.random.default_rng(232)
    n = int(0.4 * RATE)
    t = np.arange(n) / RATE
    f = 42 + 90 * np.exp(-t / 0.03)
    thud = np.sin(2 * np.pi * np.cumsum(f) / RATE) * env(n, 0.001, 0.12)
    wood = normalized(band_noise(0.4, 900, 300, 1.2, rng)) * env(n, 0.001, 0.05)
    return np.tanh(1.6 * (thud + 0.5 * wood))


def sfx_charge():
    """Coup chargé : une note qui monte et vibre de plus en plus, puis tient en scintillant
    (tirage propre)."""
    rng = np.random.default_rng(233)
    rise, hold = 0.8, 1.4
    n = int((rise + hold) * RATE)
    t = np.arange(n) / RATE
    f = np.where(t < rise, degree(0, 0) * (2.0 ** (2.0 * t / rise)), degree(0, 2))
    tremolo = 1.0 + 0.35 * np.sin(2 * np.pi * (6 + 10 * np.minimum(t / rise, 1.0)) * t)
    tone = np.sin(2 * np.pi * np.cumsum(f) / RATE) * tremolo * np.minimum(t / 0.05, 1.0)
    air = normalized(band_noise(rise + hold, 400, 3000, 1.0, rng)) * np.minimum(t / rise, 1.0) * 0.25
    shimmer = np.sin(2 * np.pi * degree(0, 3) * t) * (t > rise) * 0.2
    fade = np.minimum((t[-1] - t) / 0.1, 1.0)
    return (tone * 0.6 + air + shimmer) * fade


def sfx_grace():
    """Coup de grâce : un grand tambour et un arpège de marimba qui monte jusqu'en haut."""
    out = np.zeros(int(1.3 * RATE))
    boom = tom(degree(0, -1) * 0.9, 0.6)
    out[: len(boom)] += 1.2 * boom
    for k, d in enumerate([0, 2, 4, 5, 7, 9, 10]):
        seg = marimba(degree(d, 1), 0.7)
        i = int((0.04 + 0.045 * k) * RATE)
        out[i:i + len(seg)] += 0.7 * seg[: len(out) - i]
    return np.tanh(1.2 * out)


def sfx_riposte():
    """Riposte : un souffle vif, un coup net et un reflet aigu (tirage propre)."""
    rng = np.random.default_rng(234)
    n = int(0.45 * RATE)
    t = np.arange(n) / RATE
    air = np.zeros(n)
    w = whoosh(0.16, 2200, 600, 1.6, rng)
    air[: len(w)] += normalized(w)
    hit = np.zeros(n)
    k = kick(0.25)
    start = int(0.12 * RATE)
    hit[start:start + len(k)] += k[: n - start]
    shine = np.sin(2 * np.pi * degree(7, 2) * t) * env(n, 0.13, 0.08) * (t > 0.12) * 0.4
    return np.tanh(1.3 * (0.6 * air + hit + shine))


def sfx_sing():
    """Totem chanteur : un accord de voix « aah » qui monte d'un coup, et un reflet aigu."""
    out = np.zeros(int(1.1 * RATE))
    for k, d in enumerate([0, 4, 7]):
        v = voice(degree(d, 1), 0.9)
        i = int(0.03 * k * RATE)
        out[i:i + len(v)] += v[: len(out) - i]
    t = np.arange(len(out)) / RATE
    out += np.sin(2 * np.pi * degree(0, 3) * t) * env(len(out), 0.05, 0.3) * 0.4
    return out


def drop(freq, length=0.25):
    """Goutte d'eau : une note qui monte très vite, courte et ronde."""
    n = int(length * RATE)
    t = np.arange(n) / RATE
    f = freq * (1 + 0.8 * (1 - np.exp(-t / 0.012)))
    phase = 2 * np.pi * np.cumsum(f) / RATE
    return np.sin(phase) * env(n, 0.001, 0.05)


def whistle(freq, length):
    """Oiseau des cimes : un sifflet qui glisse vers le haut puis retombe."""
    n = int(length * RATE)
    t = np.arange(n) / RATE
    f = freq * (1 + 0.12 * np.sin(np.pi * t / length))
    phase = 2 * np.pi * np.cumsum(f) / RATE
    shape = np.minimum(t / 0.02, 1.0) * np.minimum((length - t) / 0.04, 1.0).clip(0, 1)
    return np.sin(phase) * shape


def sfx_trap():
    """Piège (version 3.0) : un « tok » de bois sourd et un frottement d'épines, très court."""
    rng = np.random.default_rng(300)
    n = int(0.22 * RATE)
    t = np.arange(n) / RATE
    tok = np.sin(2 * np.pi * 220 * t * (1 + 0.3 * np.exp(-t / 0.01))) * env(n, 0.001, 0.035)
    scrape = rng.standard_normal(n) * env(n, 0.004, 0.05)
    scrape = np.convolve(scrape, np.ones(6) / 6, mode="same")
    return 0.8 * tok + 0.25 * scrape


def sfx_passage():
    """Passage rituel (version 3.5) : un roulement de toms qui monte, un bruissement, un carillon."""
    rng = np.random.default_rng(350)
    length = 1.3
    buf = np.zeros(int(length * RATE))
    hits = [0.0, 0.12, 0.22, 0.31, 0.39, 0.46, 0.52]
    for i, at in enumerate(hits):
        sig = tom(95 + i * 18, 0.35) * (0.5 + 0.08 * i)
        start = int(at * RATE)
        buf[start:start + len(sig)] += sig[: len(buf) - start]
    n = int(0.7 * RATE)
    rustle = rng.standard_normal(n)
    rustle = np.convolve(rustle, np.ones(4) / 4, mode="same") * np.linspace(0.0, 1.0, n) ** 2 * env(n, 0.5, 0.15)
    start = int(0.05 * RATE)
    buf[start:start + n] += 0.25 * rustle
    ring = sfx_chime()
    start = int(0.58 * RATE)
    end = min(len(buf), start + len(ring))
    buf[start:end] += 0.7 * ring[: end - start]
    return buf


def write(path, signal, peak=0.9):
    signal = signal / max(np.max(np.abs(signal)), 1e-9) * peak
    data = (signal * 32767).astype("<i2")
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(data.tobytes())
    print(f"{path.relative_to(ROOT)} : {len(signal) / RATE:.3f} s")


def main():
    write(ROOT / "assets/audio/sfx/hit.wav", sfx_hit())
    write(ROOT / "assets/audio/sfx/chime.wav", sfx_chime(), peak=0.7)
    write(ROOT / "assets/audio/sfx/telegraph.wav", sfx_telegraph(), peak=0.7)
    write(ROOT / "assets/audio/sfx/freed.wav", sfx_freed(), peak=0.6)
    write(ROOT / "assets/audio/sfx/boss_freed.wav", sfx_boss_freed(), peak=0.7)
    write(ROOT / "assets/audio/sfx/hurt.wav", sfx_hurt(), peak=0.8)
    write(ROOT / "assets/audio/sfx/dodge.wav", sfx_dodge(), peak=0.5)
    write(ROOT / "assets/audio/sfx/gong.wav", sfx_gong(), peak=0.7)
    write(ROOT / "assets/audio/sfx/chest.wav", sfx_chest(), peak=0.6)
    write(ROOT / "assets/audio/sfx/pickup.wav", sfx_pickup(), peak=0.6)
    write(ROOT / "assets/audio/sfx/drum_return.wav", sfx_drum_return(), peak=0.85)
    write(ROOT / "assets/audio/sfx/bounce.wav", sfx_bounce(), peak=0.6)
    write(ROOT / "assets/audio/sfx/jump.wav", sfx_jump(), peak=0.35)
    write(ROOT / "assets/audio/sfx/salto.wav", sfx_salto(), peak=0.45)
    write(ROOT / "assets/audio/sfx/land.wav", sfx_land(), peak=0.5)
    write(ROOT / "assets/audio/sfx/roll.wav", sfx_roll(), peak=0.4)
    write(ROOT / "assets/audio/sfx/swing.wav", sfx_swing(), peak=0.35)
    write(ROOT / "assets/audio/sfx/slam.wav", sfx_slam(), peak=0.85)
    write(ROOT / "assets/audio/sfx/ui_click.wav", sfx_ui_click(), peak=0.4)
    write(ROOT / "assets/audio/sfx/title.wav", sfx_title(), peak=0.5)
    write(ROOT / "assets/audio/sfx/clink.wav", sfx_clink(), peak=0.45)
    write(ROOT / "assets/audio/sfx/spit.wav", sfx_spit(), peak=0.5)
    write(ROOT / "assets/audio/sfx/answer.wav", sfx_answer(), peak=0.6)
    write(ROOT / "assets/audio/sfx/ui_card.wav", sfx_ui_card(), peak=0.5)
    # Combat 2.3 (chacun son tirage).
    write(ROOT / "assets/audio/sfx/break.wav", sfx_break(), peak=0.8)
    write(ROOT / "assets/audio/sfx/impact.wav", sfx_impact(), peak=0.85)
    write(ROOT / "assets/audio/sfx/charge.wav", sfx_charge(), peak=0.45)
    write(ROOT / "assets/audio/sfx/grace.wav", sfx_grace(), peak=0.75)
    write(ROOT / "assets/audio/sfx/riposte.wav", sfx_riposte(), peak=0.7)
    # Bestiaire 2.4.
    write(ROOT / "assets/audio/sfx/sing.wav", sfx_sing(), peak=0.55)
    # Refonte 3.0.
    write(ROOT / "assets/audio/sfx/trap.wav", sfx_trap(), peak=0.4)
    # Passage rituel (version 3.5), tiré en dernier : les autres sons ne changent pas.
    write(ROOT / "assets/audio/sfx/passage.wav", sfx_passage(), peak=0.6)


if __name__ == "__main__":
    main()
