#!/usr/bin/env bash
# Headless smoke test for the COLD READ skeleton.
# Imports resources, then drives all of Act 1 through the runner with no UI
# and asserts the data + state + Mirror code paths are clean.
#
# Requires a Godot 4.x binary on PATH as `godot` (validated on 4.7.2-stable).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
godot --headless --path "$HERE" --import >/dev/null 2>&1 || true
godot --headless --path "$HERE" -- --selftest
