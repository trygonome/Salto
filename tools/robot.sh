#!/usr/bin/env bash
# Robot joueur : enchaîne des expéditions en accéléré (sans fenêtre, aussi vite que le processeur le
# permet) et écrit un rapport dans build/robot/rapport.md, avec le journal de jeu dans build/robot/journal/.
#   tools/robot.sh                         → 10 expéditions, adresse moyenne, au-delà d'un gardien
#   tools/robot.sh --runs 30 --skill fort --beyond 3 --seed 42
# Options : --runs N, --skill faible|moyen|fort, --beyond N (gardiens avant de rentrer), --seed N,
#           --out DOSSIER.
source "$(dirname "$0")/env.sh"

ensure_godot
import_project
rm -rf "$ROOT/build/robot/journal"
"$GODOT" --headless --fixed-fps 60 --path "$ROOT" -s res://tests/bot/robot_main.gd -- "$@"
