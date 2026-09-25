#!/usr/bin/env bash
# Exporte la version web (moteur Compatibility, sans threads : s'héberge n'importe où, sans
# en-têtes spéciaux) dans build/web/. Pour l'essayer : tools/serve_web.sh puis ouvrir
# http://localhost:8060 dans un navigateur.
source "$(dirname "$0")/env.sh"

ensure_godot
ensure_templates

mkdir -p "$ROOT/build/web"
import_project
"$GODOT" --headless --path "$ROOT" --export-release "Web" "$ROOT/build/web/index.html"
echo "Web : $ROOT/build/web/index.html"
