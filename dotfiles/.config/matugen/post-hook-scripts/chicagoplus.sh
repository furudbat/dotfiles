#!/usr/bin/env bash

set -e

# dont forget to set CHICAGO_PLUS_DIR in .bashrc_custom
CHICAGO_PLUS_DIR="${CHICAGO_PLUS_DIR:-~/Projects/Chicago95/Plus}"
THEME="$HOME/.config/Chicago95/themes/Matugen.theme"

# Do nothing if ChicagoPlus is missing
[ -d "$CHICAGO_PLUS_DIR" ] || exit 1
[ -f "$THEME" ] || exit 2
[ -f "$CHICAGO_PLUS_DIR/.venv/bin/activate" ] || exit 3

cd "$CHICAGO_PLUS_DIR"

source .venv/bin/activate

python ChicagoPlus.py \
    "$THEME" \
    --nofonts \
    --nocursors \
    --noicons \
    --nosounds \
    --nowallpaper

deactivate

~/.config/matugen/post-hook-scripts/gtk-themes-reload.sh

exit 0