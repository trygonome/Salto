#!/usr/bin/env bash
# Exporte l'APK de test (debug) dans build/android/salto-debug.apk.
# Signée avec tools/android/debug.keystore : toutes les versions de test ont la même signature,
# on peut donc installer une nouvelle APK par-dessus l'ancienne sans désinstaller.
source "$(dirname "$0")/env.sh"

ensure_godot
ensure_templates
ensure_android_sdk

export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$ROOT/tools/android/debug.keystore"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"

mkdir -p "$ROOT/build/android"
import_project
set_editor_setting "export/android/android_sdk_path" "$ANDROID_HOME"
"$GODOT" --headless --path "$ROOT" --export-debug "Android" "$ROOT/build/android/salto-debug.apk"
echo "APK : $ROOT/build/android/salto-debug.apk"
