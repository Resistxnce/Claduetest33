#!/usr/bin/env bash
# Builds scenes with Lune, then renders them to PNG contact sheets.
#
#   EARNESP_SRC=/path/to/EarnEsp/src tools/preview/preview.sh <scenes.luau> <outDir> [nameFilter]
#
# JSON goes to <outDir>/json and pictures to <outDir>/png. Needs lune, node
# with Playwright's Chromium, and `npm install` run once in tools/preview.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
scenes="$1"
out="$2"
filter="${3:-}"
mkdir -p "$out/json" "$out/png"
if [ -n "$filter" ]; then
	rm -f "$out/json/"*"$filter"*.json
else
	rm -f "$out/json/"*.json
fi
status=0
lune run "$here/scene.luau" "$scenes" "$out/json" ${filter:+"$filter"} || status=$?
node "$here/render.mjs" "$out/json" "$out/png" ${filter:+"$filter"} || status=$?
exit $status
