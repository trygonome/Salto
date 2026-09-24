#!/usr/bin/env bash
# Lance tous les tests (GUT) sans fenêtre. Code de sortie non nul si un test échoue.
source "$(dirname "$0")/env.sh"

ensure_godot
import_project
"$GODOT" --headless --path "$ROOT" -s addons/gut/gut_cmdln.gd "$@"
