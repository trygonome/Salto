#!/usr/bin/env python3
"""Va chercher les vrais sons du jeu (version 4.0) sur Freesound, tous sous licence CC0.

Pour chaque son, la page Freesound est lue d'abord : on vérifie que sa licence est bien CC0 1.0,
sinon il est refusé. Puis :
- les instruments (tambours, udu, marimba, kalimba, flûte de bambou, hochets, claquements de mains,
  voix) sont découpés en coups isolés dans `tools/audio/samples/` (le générateur de musique
  `make_music.py` les joue en couches) ;
- les prises de forêt tropicale (oiseaux, insectes, grenouilles, fleuve) deviennent des boucles
  d'ambiance sans couture dans `assets/audio/ambience/` (OGG, stéréo).

Les sons téléchargés sont gardés dans ~/.cache/salto-tools/freesound (dossier réglable par
SALTO_TOOLS_DIR). Chaque son est noté dans assets/LICENCES.md.

Usage : python3 tools/audio/fetch_sounds.py   (demande numpy, curl et ffmpeg, et le réseau)
"""
import os
import pathlib
import re
import subprocess
import wave

import numpy as np

RATE = 44100
ROOT = pathlib.Path(__file__).resolve().parents[2]
SAMPLES = ROOT / "tools/audio/samples"
AMBIENCE = ROOT / "assets/audio/ambience"
CACHE = pathlib.Path(os.environ.get("SALTO_TOOLS_DIR", pathlib.Path.home() / ".cache/salto-tools")) / "freesound"
CC0 = "creativecommons.org/publicdomain/zero/1.0/"

# Instruments : nom du coup -> (auteur, numéro Freesound, longueur gardée en secondes).
INSTRUMENTS = {
    "djembe_bass": ("PanPiper5", 659911, 0.9),
    "djembe_slap": ("PanPiper5", 659910, 0.5),
    "djembe_tone": ("reflecs", 21906, 0.6),
    "bata_tone": ("Sassaby", 687122, 1.2),
    "clave": ("PanPiper5", 659912, 0.13),
    "shaker": ("PanPiper5", 659914, 0.35),
    "seeds": ("PanPiper5", 542752, 0.25),
    "triangle": ("PanPiper5", 659913, 2.0),
    "kalimba": ("PanPiper5", 659909, 2.2),
    "flute": ("PanPiper5", 659915, 3.2),
    "zanka": ("PanPiper5", 427080, 1.4),
    "marimba": ("Sassaby", 528065, 1.6),
    "udu_low": ("iyankc", 479245, 0.9),
    "udu_high": ("iyankc", 479249, 0.5),
    "clap": ("bastianpusch", 493717, 0.4),
    "voice": ("Sadiquecat", 802522, 1.1),
}

# Ambiances : nom de la boucle -> liste de prises (auteur, numéro, début en s, gain relatif).
AMBIENCES = {
    # Sous-bois : après-midi en Amazonie péruvienne (grenouilles de pluie, tinamou, insectes).
    "undergrowth": [("nonamethefish", 653743, 2.0, 1.0)],
    # Ruines englouties : un fleuve qui court sur les pierres, des grenouilles et des grillons.
    "sunken": [("Tom_Kaszuba", 660260, 5.0, 1.0), ("mycompasstv", 462889, 10.0, 0.9)],
    # Canopée : oiseaux et insectes, et le cri du piaha hurleur de la forêt de Gran Sabana.
    "canopy": [("myrinvp", 423711, 3.0, 1.0), ("felix.blume", 376827, 4.0, 0.35)],
    # Village : la forêt de nuages la nuit (grillons, grenouilles, feuilles).
    "village": [("sethlind", 332722, 38.0, 1.0)],
}
LOOP_LENGTH = 30.0
CROSSFADE = 3.0
AMBIENCE_RMS = 0.06
AMBIENCE_PEAK = 0.8


def fetch(user, sound_id):
    """Vérifie la licence sur la page du son, puis télécharge son aperçu de qualité (MP3 128 kbit/s)."""
    CACHE.mkdir(parents=True, exist_ok=True)
    target = CACHE / f"{sound_id}.mp3"
    if target.exists():
        return target
    url = f"https://freesound.org/people/{user}/sounds/{sound_id}/"
    page = subprocess.run(["curl", "-s", "-L", "-m", "60", url], capture_output=True, text=True, check=True).stdout
    licences = set(re.findall(r"creativecommons\.org/[a-z/.0-9]*", page))
    if licences != {CC0}:
        raise SystemExit(f"{url} : licence {sorted(licences)}, pas CC0 — refusé")
    preview = re.search(r"https://cdn\.freesound\.org/previews/[^\"]*-hq\.mp3", page)
    if preview is None:
        raise SystemExit(f"{url} : aperçu introuvable")
    subprocess.run(["curl", "-s", "-L", "-m", "300", "-o", str(target), preview.group(0)], check=True)
    print(f"{url} : CC0, téléchargé")
    return target


def decode(path, channels):
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-f", "f32le", "-ac", str(channels),
                          "-ar", str(RATE), "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, "<f4").astype(float).reshape(-1, channels)


def write_wav(path, signal):
    data = (np.clip(signal, -1.0, 1.0) * 32767).astype("<i2")
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1 if signal.ndim == 1 else signal.shape[1])
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(data.tobytes())


def prepare_instrument(name, user, sound_id, length):
    """Un coup isolé : commence à l'attaque, crête à 1, fin adoucie."""
    x = decode(fetch(user, sound_id), 1)[:, 0]
    x = x - np.mean(x)
    peak = np.max(np.abs(x))
    onset = max(int(np.argmax(np.abs(x) > peak * 0.05)) - int(0.002 * RATE), 0)
    x = x[onset:onset + int(length * RATE)] / peak
    fade = min(int(0.06 * RATE), len(x) // 3)
    x[-fade:] *= np.linspace(1.0, 0.0, fade) ** 2
    write_wav(SAMPLES / f"{name}.wav", x)
    print(f"tools/audio/samples/{name}.wav : {len(x) / RATE:.2f} s")


def seamless(x, length, fade):
    """Boucle sans couture : la fin de la prise se fond dans son début (fondu à puissance égale)."""
    n, f = int(length * RATE), int(fade * RATE)
    theta = np.linspace(0.0, np.pi / 2, f)[:, None]
    out = x[:n].copy()
    out[:f] = x[:f] * np.sin(theta) + x[n:n + f] * np.cos(theta)
    return out


def make_ambience(name, takes):
    mix = None
    for user, sound_id, start, gain in takes:
        x = decode(fetch(user, sound_id), 2)
        x = x[int(start * RATE):int((start + LOOP_LENGTH + CROSSFADE) * RATE)]
        x = x - np.mean(x, axis=0)
        x = x / np.sqrt(np.mean(x ** 2)) * gain
        mix = x if mix is None else mix + x
    loop = seamless(mix, LOOP_LENGTH, CROSSFADE)
    loop *= AMBIENCE_RMS / np.sqrt(np.mean(loop ** 2))
    peak = np.max(np.abs(loop))
    if peak > AMBIENCE_PEAK:
        # Les cris trop forts sont adoucis (compression douce au-dessus du seuil).
        over = np.abs(loop) > AMBIENCE_PEAK * 0.7
        knee = AMBIENCE_PEAK * 0.7
        loop[over] = np.sign(loop[over]) * (knee + (AMBIENCE_PEAK - knee) * np.tanh((np.abs(loop[over]) - knee) / (AMBIENCE_PEAK - knee)))
    tmp = CACHE / f"{name}.wav"
    write_wav(tmp, loop)
    target = AMBIENCE / f"{name}.ogg"
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(tmp), "-c:a", "libvorbis", "-q:a", "3", str(target)], check=True)
    print(f"{target.relative_to(ROOT)} : {LOOP_LENGTH:.0f} s, {target.stat().st_size // 1024} Kio")


def main():
    for name, (user, sound_id, length) in INSTRUMENTS.items():
        prepare_instrument(name, user, sound_id, length)
    for name, takes in AMBIENCES.items():
        make_ambience(name, takes)


if __name__ == "__main__":
    main()
