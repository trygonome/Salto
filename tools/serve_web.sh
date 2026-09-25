#!/usr/bin/env bash
# Sert build/web/ en local sur http://localhost:8060 (Ctrl+C pour arrêter).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/build/web" && exec python3 -m http.server "${1:-8060}"
