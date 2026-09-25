#!/usr/bin/env python3
"""Génère la musique en couches de la nuit (104 BPM) et les bruitages de base.

Tout est synthétisé ici : pas de licence tierce. Chaque couche est une boucle de 8 mesures
rendue dans un tampon circulaire (les queues de notes reviennent au début) : la reprise
est sans couture. Les couches s'additionnent ; la base joue toujours, chaque tambour
rapporté en ajoute une.

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


def shaker(length=0.09):
    n = int(length * RATE)
    noise = RNG.standard_normal(n)
    noise = np.diff(noise, prepend=0.0)  # passe-haut grossier
    return noise * env(n, 0.004, 0.025)


def marimba(freq, length=0.6):
    n = int(length * RATE)
    t = np.arange(n) / RATE
    fundamental = np.sin(2 * np.pi * freq * t) * env(n, 0.002, 0.32)
    overtone = np.sin(2 * np.pi * freq * 4 * t) * env(n, 0.001, 0.03)
    return fundamental + 0.3 * overtone


def bass(freq, length=0.5):
    n = int(length * RATE)
    t = np.arange(n) / RATE
    tone = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * freq * 2 * t)
    return np.tanh(1.6 * tone * env(n, 0.004, 0.28))


def flute(freq, length):
    n = int(length * RATE)
    t = np.arange(n) / RATE
    vibrato = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(t / 0.25, 1)
    phase = 2 * np.pi * np.cumsum(freq * vibrato) / RATE
    tone = np.sin(phase) + 0.12 * np.sin(2 * phase)
    breath = RNG.standard_normal(n) * 0.04
    shape = np.minimum(t / 0.05, 1.0) * np.minimum((length - t) / 0.08, 1.0).clip(0, 1)
    return (tone + breath) * shape


def pad(freqs, length):
    n = int(length * RATE)
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for f in freqs:
        for detune in (-0.004, 0.0, 0.004):
            saw = 2 * ((f * (1 + detune) * t) % 1.0) - 1
            out += saw
    # Passe-bas simple (moyenne glissante) puis fondu d'entrée et de sortie.
    kernel = np.ones(24) / 24
    out = np.convolve(out, kernel, mode="same")
    shape = np.minimum(t / 0.6, 1.0) * np.minimum((length - t) / 0.6, 1.0).clip(0, 1)
    return out * shape / (len(freqs) * 3)


def layer_base():
    buf = np.zeros(LOOP_SAMPLES)
    for bar in range(BARS):
        b0 = bar * BEATS_PER_BAR
        add(buf, b0, kick(), 0.9)
        add(buf, b0 + 2, kick(), 0.7)
        for eighth in range(8):
            accent = 0.5 if eighth % 2 else 0.8
            add(buf, b0 + eighth / 2, shaker(), 0.25 * accent)
    chords = [[0, 4, 7], [2, 5, 9], [-3, 2, 4], [0, 4, 7]]  # degrés, deux mesures chacun
    for i, chord in enumerate(chords):
        freqs = [degree(d, -1) for d in chord]
        add(buf, i * 2 * BEATS_PER_BAR, pad(freqs, 2 * BEATS_PER_BAR * BEAT), 0.5)
    return buf


def layer_drums():
    buf = np.zeros(LOOP_SAMPLES)
    pattern = [(0.0, 1), (0.75, 0), (1.5, 0), (2.0, 1), (2.5, 0), (3.25, 2), (3.5, 0)]
    pitches = [190.0, 130.0, 260.0]
    for bar in range(BARS):
        for beat_offset, which in pattern:
            add(buf, bar * BEATS_PER_BAR + beat_offset, tom(pitches[which]), 0.55)
        if bar % 2 == 1:
            add(buf, bar * BEATS_PER_BAR + 3.75, tom(pitches[2]), 0.4)
    return buf


def layer_bass():
    buf = np.zeros(LOOP_SAMPLES)
    roots = [0, 0, 2, 2, -3, -3, 0, 4]
    for bar, root in enumerate(roots):
        b0 = bar * BEATS_PER_BAR
        for beat_offset, step in [(0, 0), (1.5, 0), (2, 2), (3, 1)]:
            add(buf, b0 + beat_offset, bass(degree(root + step, -2)), 0.45)
    return buf


def layer_melody():
    buf = np.zeros(LOOP_SAMPLES)
    phrase = [  # (temps, degré, durée en temps)
        (0, 5, 1), (1, 7, 0.5), (1.5, 6, 0.5), (2, 5, 1.5), (4, 7, 1), (5, 9, 1), (6, 8, 1.5),
        (8, 7, 0.5), (8.5, 8, 0.5), (9, 9, 1), (10, 10, 2), (12, 9, 1), (13, 7, 1), (14, 5, 2),
    ]
    for repeat in range(2):
        for beat_pos, d, length in phrase:
            add(buf, repeat * 16 + beat_pos, flute(degree(d), length * BEAT), 0.28)
    # Marimba en contrechant, sur les contretemps.
    for bar in range(BARS):
        for k, d in enumerate([5, 7, 9, 7]):
            add(buf, bar * BEATS_PER_BAR + k + 0.5, marimba(degree(d + (bar % 2), 0)), 0.18)
    return buf


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


def band_noise(length, f_start, f_end, q=1.2):
    """Bruit passé dans un filtre passe-bande dont la fréquence glisse de f_start à f_end."""
    n = int(length * RATE)
    noise = RNG.standard_normal(n)
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


def whoosh(length, f_start, f_end, q=1.2):
    """Souffle : bruit filtré qui glisse, qui enfle puis retombe."""
    n = int(length * RATE)
    t = np.arange(n) / RATE
    shape = np.sin(np.pi * t / t[-1]) ** 1.5
    return band_noise(length, f_start, f_end, q) * shape


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


def ambience_night(length=16.0):
    """Ambiance de la jungle la nuit, en boucle sans couture : grillons, grenouilles, vent."""
    n = int(length * RATE)
    buf = np.zeros(n)

    def place(start, signal, gain):
        idx = (int(start * RATE) + np.arange(len(signal))) % n
        np.add.at(buf, idx, signal * gain)

    # Vent : bruit mis en forme dans le domaine fréquentiel (donc périodique sur la boucle).
    spectrum = np.fft.rfft(RNG.standard_normal(n))
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    spectrum *= 1 / np.maximum(freqs, 40) * (freqs < 900)
    wind = np.fft.irfft(spectrum, n)
    wind /= np.max(np.abs(wind))
    t = np.arange(n) / RATE
    wind *= 0.6 + 0.4 * np.sin(2 * np.pi * t / length)
    buf += 0.35 * wind
    # Grillons : groupes de trilles aigus, chacun à son rythme.
    for cricket in range(5):
        carrier = RNG.uniform(3900, 5200)
        period = RNG.uniform(0.55, 1.3)
        pulses = int(RNG.integers(3, 6))
        start = RNG.uniform(0, period)
        gain = RNG.uniform(0.05, 0.12)
        chirp_n = int(0.028 * RATE)
        tc = np.arange(chirp_n) / RATE
        chirp = np.sin(2 * np.pi * carrier * tc) * np.sin(np.pi * tc / tc[-1]) ** 2
        time = start
        while time < length:
            for k in range(pulses):
                place(time + k * 0.042, chirp, gain * RNG.uniform(0.7, 1.0))
            time += period * RNG.uniform(0.85, 1.15)
    # Grenouilles : quelques coassements graves.
    for croak in range(4):
        n_c = int(0.28 * RATE)
        tc = np.arange(n_c) / RATE
        f = RNG.uniform(260, 420)
        ribbit = np.sin(2 * np.pi * f * tc) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 32 * tc)))
        ribbit *= env(n_c, 0.01, 0.1)
        ribbit = np.convolve(ribbit, np.ones(20) / 20, mode="same")
        place(RNG.uniform(0, length), ribbit, 0.35)
    return buf


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
    layers = {
        "night_0_base": layer_base(),
        "night_1_drums": layer_drums(),
        "night_2_bass": layer_bass(),
        "night_3_melody": layer_melody(),
    }
    # Même gain pour toutes les couches : leur somme ne sature pas.
    total_peak = np.max(np.abs(sum(layers.values())))
    for name, buf in layers.items():
        write(ROOT / "assets/audio/music" / f"{name}.wav", buf / total_peak * 0.9, peak=np.max(np.abs(buf)) / total_peak * 0.9)
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
    write(ROOT / "assets/audio/ambience/night_ambience.wav", ambience_night(), peak=0.5)
    write(ROOT / "assets/audio/sfx/clink.wav", sfx_clink(), peak=0.45)
    write(ROOT / "assets/audio/sfx/spit.wav", sfx_spit(), peak=0.5)


if __name__ == "__main__":
    main()
