#!/usr/bin/env bash
# Exporte l'APK de test dans build/android/ :
#   tools/export_android.sh            → salto-debug.apk   (moteur de débogage)
#   tools/export_android.sh --release  → salto-release.apk (moteur optimisé : plus léger et plus
#                                        rapide, pour juger les performances et l'envoyer au téléphone)
# Les deux sont signées avec tools/android/debug.keystore : toutes les versions de test ont la même
# signature, on peut donc installer une nouvelle APK par-dessus l'ancienne sans désinstaller.
source "$(dirname "$0")/env.sh"

MODE="debug"
if [[ "${1:-}" == "--release" ]]; then
	MODE="release"
fi

ensure_godot
ensure_templates
ensure_android_sdk

KEYSTORE="$ROOT/tools/android/debug.keystore"
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="android"

APK="$ROOT/build/android/salto-$MODE.apk"
mkdir -p "$ROOT/build/android"
import_project
set_editor_setting "export/android/android_sdk_path" "$ANDROID_HOME"
"$GODOT" --headless --path "$ROOT" "--export-$MODE" "Android" "$APK"
echo "APK : $APK"
