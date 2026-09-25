#!/usr/bin/env bash
# Lance tous les tests (GUT) sans fenêtre. Code de sortie non nul si un test échoue.
source "$(dirname "$0")/env.sh"

ensure_godot
import_project
# En temps réel, sans --fixed-fps : les pas physiques enchaînés sans pause déclenchent au hasard
# un avertissement de Jolt (« job system exceeded the maximum number of jobs ») que GUT compte
# comme une erreur. Les tests restent reproductibles : ils avancent image physique par image physique.
"$GODOT" --headless --path "$ROOT" -s addons/gut/gut_cmdln.gd "$@"
