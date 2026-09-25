#!/usr/bin/env bash
# Outils partagés par les scripts : trouve (ou télécharge) Godot, ses modèles d'export et le SDK Android.
# Dossier des outils téléchargés : $SALTO_TOOLS_DIR (par défaut ~/.cache/salto-tools).

set -euo pipefail

GODOT_VERSION="4.7.2"
ANDROID_BUILD_TOOLS="36.1.0"
ANDROID_CMDLINE_TOOLS="16111833"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${SALTO_TOOLS_DIR:-$HOME/.cache/salto-tools}"
GODOT_DOWNLOAD="https://downloads.godotengine.org/?version=${GODOT_VERSION}&flavor=stable"

# Godot : $GODOT, puis `godot` dans le PATH s'il est à la bonne version, sinon téléchargement.
ensure_godot() {
	if [[ -n "${GODOT:-}" ]]; then
		return
	fi
	if command -v godot >/dev/null && godot --version | grep -q "^${GODOT_VERSION}\.stable"; then
		GODOT="godot"
		return
	fi
	local dir="$TOOLS_DIR/godot-$GODOT_VERSION"
	GODOT="$dir/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
	if [[ ! -x "$GODOT" ]]; then
		echo "Téléchargement de Godot $GODOT_VERSION…"
		mkdir -p "$dir"
		curl -fsSL -o "$dir/godot.zip" "${GODOT_DOWNLOAD}&slug=linux.x86_64.zip&platform=linux.64"
		unzip -q -o "$dir/godot.zip" -d "$dir"
		rm "$dir/godot.zip"
	fi
}

# Modèles d'export, à l'endroit où Godot les cherche.
ensure_templates() {
	local dir="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}.stable"
	if [[ -f "$dir/android_debug.apk" ]]; then
		return
	fi
	echo "Téléchargement des modèles d'export Godot $GODOT_VERSION (≈ 1 Go)…"
	local tmp
	tmp="$(mktemp -d)"
	curl -fsSL -o "$tmp/templates.tpz" "${GODOT_DOWNLOAD}&slug=export_templates.tpz&platform=templates"
	unzip -q -o "$tmp/templates.tpz" -d "$tmp"
	mkdir -p "$dir"
	mv "$tmp"/templates/* "$dir/"
	rm -rf "$tmp"
}

# SDK Android minimal (outils de signature) : $ANDROID_HOME s'il existe, sinon téléchargement.
ensure_android_sdk() {
	if [[ -z "${ANDROID_HOME:-}" ]]; then
		ANDROID_HOME="$TOOLS_DIR/android-sdk"
	fi
	export ANDROID_HOME
	if [[ -x "$ANDROID_HOME/build-tools/$ANDROID_BUILD_TOOLS/apksigner" ]]; then
		return
	fi
	local sdkmanager="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
	if [[ ! -x "$sdkmanager" ]]; then
		echo "Téléchargement des outils Android…"
		local tmp
		tmp="$(mktemp -d)"
		curl -fsSL -o "$tmp/clt.zip" \
			"https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip"
		unzip -q -o "$tmp/clt.zip" -d "$tmp"
		mkdir -p "$ANDROID_HOME/cmdline-tools"
		mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
		rm -rf "$tmp"
	fi
	yes | "$sdkmanager" --sdk_root="$ANDROID_HOME" --licenses >/dev/null || true
	"$sdkmanager" --sdk_root="$ANDROID_HOME" "platform-tools" "build-tools;$ANDROID_BUILD_TOOLS" >/dev/null
}

# Écrit un réglage de l'éditeur Godot (Linux). Le fichier existe après un premier lancement de l'éditeur.
set_editor_setting() {
	local key="$1" value="$2"
	local file="${XDG_CONFIG_HOME:-$HOME/.config}/godot/editor_settings-${GODOT_VERSION%.*}.tres"
	if grep -q "^$key = " "$file"; then
		sed -i "s|^$key = .*|$key = \"$value\"|" "$file"
	else
		echo "$key = \"$value\"" >>"$file"
	fi
}

# Importe les ressources (nécessaire après un clone : cache des classes, textures…).
import_project() {
	# Les exports (build/) ne doivent pas être importés ni repris dans l'export suivant.
	mkdir -p "$ROOT/build"
	touch "$ROOT/build/.gdignore"
	"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
}
