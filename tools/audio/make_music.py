#!/usr/bin/env python3
"""Musique en couches de l'expédition (version 4.0), jouée par de vrais instruments.

Les coups d'instruments (djembé, bata, udu, marimba du Ghana, kalimba, flûte de bambou, zanka,
hochets, clave, triangle, claquements de mains, voix) sont des prises CC0 préparées par
`fetch_sounds.py` dans `tools/audio/samples/`. Ce script les accorde (rééchantillonnage) sur la
gamme du jeu — ré majeur pentatonique — et les place au temps près, à 104 BPM.

Chaque couche est une boucle de 8 mesures rendue dans un tampon circulaire (les queues de notes
reviennent au début) : la reprise est sans couture, et toutes les couches restent synchrones.
Les couches s'additionnent : la base joue toujours, chaque tambour rapporté en ajoute une ; la
troupe du village et les régions ont chacune la leur.

Il fait aussi les sons des danses de l'Onde (version 4.1), avec les mêmes instruments.

Usage : python3 tools/audio/make_music.py   (demande numpy)
"""
import pathlib
import wave

import numpy as np

from generate_audio import BARS, BEAT, BEATS_PER_BAR, LOOP_SAMPLES, RATE, ROOT, add, drop, whistle

SAMPLES = ROOT / "tools/audio/samples"
MUSIC = ROOT / "assets/audio/music"
PENTA = [0, 2, 4, 7, 9]
D3_MIDI = 50
# Accords de la boucle (degrés), deux mesures chacun.
BAR_CHORDS = [[0, 4, 7], [2, 5, 9], [-3, 2, 4], [0, 4, 7]]
# Note de chaque coup accordé (MIDI, mesurée sur la prise).
SAMPLE_MIDI = {
    "flute": 55.16,
    "zanka": 50.3,
    "kalimba": 57.1,
    "marimba": 43.45,
    "udu_low": 43.16,
    "udu_high": 52.62,
    "bata_tone": 49.2,
    "voice": 66.2,
}
RNG = np.random.default_rng(400)
_cache = {}


def sample(name):
    if name not in _cache:
        with wave.open(str(SAMPLES / f"{name}.wav")) as src:
            _cache[name] = np.frombuffer(src.readframes(src.getnframes()), "<i2").astype(float) / 32767
    return _cache[name]


def degree_midi(d, octave=0):
    """Degré de la gamme pentatonique (0 = ré 3), en note MIDI."""
    o, i = divmod(d, len(PENTA))
    return D3_MIDI + PENTA[i] + 12 * (o + octave)


def pitched(x, semitones):
    """Rééchantillonne : monte ou descend de `semitones` demi-tons (et raccourcit ou allonge)."""
    ratio = 2 ** (semitones / 12)
    if abs(ratio - 1.0) < 1e-4:
        return x.copy()
    if ratio > 1.0:
        # Filtre les aigus qui dépasseraient la moitié de la fréquence d'échantillonnage.
        spectrum = np.fft.rfft(x)
        spectrum[int(len(spectrum) / ratio):] = 0.0
        x = np.fft.irfft(spectrum, len(x))
    positions = np.arange(0.0, len(x) - 1, ratio)
    return np.interp(positions, np.arange(len(x)), x)


def tuned(name, midi, length=None, release=0.08):
    """Le coup `name` accordé sur la note `midi` ; coupé à `length` secondes avec un relâché."""
    x = pitched(sample(name), midi - SAMPLE_MIDI[name])
    if length is not None and length * RATE < len(x):
        n = int(length * RATE)
        r = min(int(release * RATE), n // 2)
        x = x[:n + r].copy()
        x[n:n + r] *= np.linspace(1.0, 0.0, len(x[n:n + r])) ** 2
    return x


def hit(name, gain_jitter=0.0, semitones=0.0):
    """Un coup non accordé, légèrement varié (chaque main frappe un peu différemment)."""
    x = sample(name) if semitones == 0.0 else pitched(sample(name), semitones)
    return x * (1.0 + gain_jitter * RNG.uniform(-1.0, 1.0))


def layer_base():
    """Le cœur : la basse du djembé sur les temps forts, les hochets en croches, la kalimba qui
    égrène les accords."""
    buf = np.zeros(LOOP_SAMPLES)
    for bar in range(BARS):
        b0 = bar * BEATS_PER_BAR
        add(buf, b0, hit("djembe_bass", 0.05), 0.9)
        add(buf, b0 + 2, hit("djembe_bass", 0.05), 0.65)
        for eighth in range(8):
            accent = 0.75 if eighth % 2 == 0 else 0.45
            add(buf, b0 + eighth / 2, hit("shaker", 0.15), 0.2 * accent)
        add(buf, b0 + 3.75, hit("seeds", 0.1), 0.1)
        chord = BAR_CHORDS[bar // 2]
        for k, d in enumerate([chord[0], chord[1], chord[2], chord[1]]):
            add(buf, b0 + k, tuned("kalimba", degree_midi(d)), 0.3 if k == 0 else 0.22)
    return buf


def layer_drums():
    """Le djembé qui parle : tons et claqués, la clave en 3-2, le bata qui répond."""
    buf = np.zeros(LOOP_SAMPLES)
    pattern = [(0.75, "djembe_tone"), (1.5, "djembe_slap"), (2.0, "djembe_tone"), (2.5, "djembe_slap"),
               (3.25, "djembe_slap"), (3.5, "djembe_tone")]
    for bar in range(BARS):
        b0 = bar * BEATS_PER_BAR
        for beat_offset, name in pattern:
            add(buf, b0 + beat_offset, hit(name, 0.12), 0.5 if name == "djembe_slap" else 0.75)
        clave = [0.0, 1.5, 3.0] if bar % 2 == 0 else [1.0, 2.0]
        for beat_offset in clave:
            add(buf, b0 + beat_offset, hit("clave", 0.05), 0.22)
        if bar % 2 == 1:
            add(buf, b0 + 3.75, tuned("bata_tone", degree_midi(0, -1) + 12), 0.5)
    return buf


def layer_bass():
    """La marimba du Ghana tient la basse ; l'udu double la fondamentale."""
    buf = np.zeros(LOOP_SAMPLES)
    roots = [0, 0, 2, 2, -3, -3, 0, 4]
    for bar, root in enumerate(roots):
        b0 = bar * BEATS_PER_BAR
        for beat_offset, step in [(0, 0), (1.5, 0), (2, 2), (3, 1)]:
            midi = degree_midi(root + step, -1)
            while midi < 38:
                midi += 12
            add(buf, b0 + beat_offset, tuned("marimba", midi, 0.8), 1.2)
        udu = degree_midi(root, -1)
        add(buf, b0, tuned("udu_low", udu if udu >= 38 else udu + 12), 0.6)
    return buf


def flute_note(midi, length):
    """Flûte de bambou (grave) ou zanka (plus grave encore), selon la note."""
    name = "zanka" if midi < 54 else "flute"
    return tuned(name, midi, length, release=0.12)


def layer_melody():
    """La flûte de bambou chante le thème ; la kalimba répond en contretemps."""
    buf = np.zeros(LOOP_SAMPLES)
    phrase = [  # (temps, degré, durée en temps)
        (0, 5, 1), (1, 7, 0.5), (1.5, 6, 0.5), (2, 5, 1.5), (4, 7, 1), (5, 9, 1), (6, 8, 1.5),
        (8, 7, 0.5), (8.5, 8, 0.5), (9, 9, 1), (10, 10, 2), (12, 9, 1), (13, 7, 1), (14, 5, 2),
    ]
    for repeat in range(2):
        for beat_pos, d, length in phrase:
            add(buf, repeat * 16 + beat_pos, flute_note(degree_midi(d, -1), length * BEAT), 0.42)
    for bar in range(BARS):
        for k, d in enumerate([5, 7, 9, 7]):
            add(buf, bar * BEATS_PER_BAR + k + 0.5, tuned("kalimba", degree_midi(d + (bar % 2), -1)), 0.14)
    return buf


def layer_band():
    """La troupe du village : les Sourdines rendues à la vie tapent dans leurs mains (temps 2 et
    4) et lancent des « ouh ! » sur les accords, en appel et réponse."""
    buf = np.zeros(LOOP_SAMPLES)
    for bar in range(BARS):
        b0 = bar * BEATS_PER_BAR
        for beat_offset in (1, 3):
            add(buf, b0 + beat_offset, hit("clap", 0.1), 0.8)
        if bar % 2 == 1:
            add(buf, b0 + 3.5, hit("clap", 0.1), 0.45)
        chord = BAR_CHORDS[bar // 2]
        if bar % 2 == 0:
            for j, d in enumerate(chord[:2]):
                add(buf, b0 + j * 0.03, tuned("voice", degree_midi(d, 1)), 0.35)
        else:
            add(buf, b0 + 2.5, tuned("voice", degree_midi(chord[2], 0) + 12, 0.5), 0.25)
    return buf


def layer_sunken():
    """Ruines englouties : udus graves et aigus, gouttes d'eau sur la gamme, un bourdon d'eau."""
    rng = np.random.default_rng(260)
    buf = np.zeros(LOOP_SAMPLES)
    for bar in range(BARS):
        b0 = bar * BEATS_PER_BAR
        for beat_offset, d in [(0.0, 0), (1.5, 2), (2.5, 0), (3.0, 4)]:
            midi = degree_midi(d, -1)
            name = "udu_low" if midi < 48 else "udu_high"
            add(buf, b0 + beat_offset, tuned(name, midi), 1.0)
        for k in range(3):
            pos = b0 + rng.integers(0, 8) / 2
            add(buf, pos, drop(2 ** ((degree_midi(int(rng.integers(5, 12))) - 69) / 12) * 440), 0.12)
    t = np.arange(LOOP_SAMPLES) / RATE
    swell = 0.5 + 0.5 * np.sin(2 * np.pi * t / (LOOP_SAMPLES / RATE / 2))
    buf += np.sin(2 * np.pi * 73.42 * t) * (0.04 + 0.04 * swell)
    return buf


def layer_canopy():
    """Canopée : la clave en doubles croches comme des bambous, le triangle, des appels d'oiseaux."""
    rng = np.random.default_rng(261)
    buf = np.zeros(LOOP_SAMPLES)
    for bar in range(BARS):
        b0 = bar * BEATS_PER_BAR
        for sixteenth in range(16):
            if sixteenth % 4 == 0 or rng.random() < 0.35:
                accent = 0.6 if sixteenth % 4 == 0 else 0.3
                add(buf, b0 + sixteenth / 4, hit("clave", 0.1, semitones=float(sixteenth % 3) * 2.0), 0.3 * accent)
        if bar % 4 == 0:
            add(buf, b0, hit("triangle"), 0.12)
        if bar % 2 == 0:
            for k, d in enumerate([9, 11, 10]):
                add(buf, b0 + 1 + k * 0.5, whistle(2 ** ((degree_midi(d) - 69) / 12) * 440, 0.22), 0.1)
        else:
            add(buf, b0 + 2.5, whistle(2 ** ((degree_midi(int(rng.integers(8, 13))) - 69) / 12) * 440, 0.5), 0.08)
    return buf


def place(buf, at, signal, gain):
    """Pose `signal` à `at` secondes dans `buf` (coupé à la fin)."""
    i = int(at * RATE)
    n = min(len(signal), len(buf) - i)
    buf[i:i + n] += signal[:n] * gain


def sfx_dance_palm():
    """Onde de paume : un claqué de djembé, la kalimba qui sonne haut, les graines qui frémissent."""
    buf = np.zeros(int(0.9 * RATE))
    place(buf, 0.0, hit("seeds"), 0.35)
    place(buf, 0.05, sample("djembe_slap"), 0.8)
    place(buf, 0.06, tuned("kalimba", degree_midi(7)), 0.5)
    return buf


def sfx_dance_spiral():
    """Spirale : trois coups de hochet et la kalimba qui monte en arpège."""
    buf = np.zeros(int(1.1 * RATE))
    for k, d in enumerate([5, 7, 9]):
        place(buf, k * 0.09, hit("shaker"), 0.4)
        place(buf, k * 0.09 + 0.02, tuned("kalimba", degree_midi(d)), 0.45)
    return buf


def sfx_dance_rain():
    """Pluie de pas : les graines qui roulent, puis le pied frappe (djembé grave et udu)."""
    buf = np.zeros(int(1.2 * RATE))
    for k in range(4):
        place(buf, k * 0.05, hit("seeds", 0.2), 0.2 + 0.08 * k)
    place(buf, 0.22, sample("djembe_bass"), 0.9)
    place(buf, 0.23, tuned("udu_low", degree_midi(0, -1)), 0.6)
    return buf


def sfx_dance_thread(length=2.4):
    """Fil d'écho : une flûte tenue qui tremble, en boucle sans couture (deux souffles qui se relaient)."""
    n = int(length * RATE)
    buf = np.zeros(n)
    note = tuned("flute", degree_midi(4), length * 0.75, release=0.3)
    t = np.arange(len(note)) / RATE
    note = note * (1.0 + 0.25 * np.sin(2 * np.pi * 7.0 * t))
    for k in range(2):
        idx = (int(k * n / 2) + np.arange(len(note))) % n
        np.add.at(buf, idx, note * 0.5)
    for k in range(8):
        idx = (int(k * n / 8) + np.arange(len(sample("shaker")))) % n
        np.add.at(buf, idx, sample("shaker") * 0.08)
    return buf


def sfx_dance_fizzle():
    """Pas manqué : un ton de djembé étouffé, plus grave, qui retombe tout de suite."""
    x = pitched(sample("djembe_tone"), -5.0)[: int(0.25 * RATE)].copy()
    x *= np.linspace(1.0, 0.0, len(x)) ** 2
    return x * 0.6


def write(path, signal):
    data = (np.clip(signal, -1.0, 1.0) * 32767).astype("<i2")
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(data.tobytes())
    print(f"{path.relative_to(ROOT)} : {len(signal) / RATE:.3f} s, crête {np.max(np.abs(signal)):.2f}")


def main():
    layers = {
        "night_0_base": layer_base(),
        "night_1_drums": layer_drums(),
        "night_2_bass": layer_bass(),
        "night_3_melody": layer_melody(),
    }
    # Même gain pour toutes les couches : leur somme ne sature pas, même avec la troupe et une région.
    extra = {"night_band": layer_band(), "region_sunken": layer_sunken(), "region_canopy": layer_canopy()}
    loudest = max(np.max(np.abs(sum(layers.values()) + extra["night_band"] + region)) for region in (extra["region_sunken"], extra["region_canopy"]))
    gain = 0.9 / loudest
    for name, buf in {**layers, **extra}.items():
        write(MUSIC / f"{name}.wav", buf * gain)
    sfx = ROOT / "assets/audio/sfx"
    for name, buf in (("dance_palm", sfx_dance_palm()), ("dance_spiral", sfx_dance_spiral()), ("dance_rain", sfx_dance_rain()),
                      ("dance_thread", sfx_dance_thread()), ("dance_fizzle", sfx_dance_fizzle())):
        write(sfx / f"{name}.wav", buf / max(np.max(np.abs(buf)), 1e-9) * 0.7)


if __name__ == "__main__":
    main()
