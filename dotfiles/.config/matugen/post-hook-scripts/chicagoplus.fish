#!/usr/bin/env fish

# dont forget to set CHICAGO_PLUS_DIR in config.fish
set -q CHICAGO_PLUS_DIR; or set CHICAGO_PLUS_DIR "$HOME/Chicago95/Plus"

set THEME "$HOME/.config/Chicago95/themes/Matugen.theme"

# optional: silently skip
if not test -d "$CHICAGO_PLUS_DIR"
    exit 1
end

if not test -f "$THEME"
    exit 2
end

if not test -f "$CHICAGO_PLUS_DIR/.venv/bin/activate.fish"
    exit 3
end

cd "$CHICAGO_PLUS_DIR"

source .venv/bin/activate.fish

python ChicagoPlus.py \
    "$THEME" \
    --nofonts \
    --nocursors \
    --noicons \
    --nosounds \
    --nowallpaper

deactivate