#!/usr/bin/env bash
# Runs the game's client UI code with Lune, then draws its ScreenGuis to PNGs.
#
#   EARNESP_SRC=/path/to/EarnEsp/src MODELS_SRC=src tools/preview/gui.sh <screens.luau> <outDir> [nameFilter]
#
# MODELS_SRC lists folders laid over the game's src (split by ":"; later ones
# win), so a folder with client/HackMenu.luau replaces the game's. JSON goes to
# <outDir>/json and pictures to <outDir>/png. Needs lune, and node with
# Playwright's Chromium.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
screens="$1"
out="$2"
filter="${3:-}"
mkdir -p "$out/json" "$out/png"
if [ -n "$filter" ]; then
	rm -f "$out/json/"*"$filter"*.json
else
	rm -f "$out/json/"*.json
fi
status=0
lune run "$here/gui.luau" "$screens" "$out/json" ${filter:+"$filter"} || status=$?
node "$here/gui_render.mjs" "$out/json" "$out/png" ${filter:+"$filter"} || status=$?
exit $status
