#!/usr/bin/env fish

# dont forget to set CHICAGO_PLUS_DIR in config.fish
if not set -q CHICAGO_PLUS_DIR
    set -q XDG_PROJECTS_DIR
    or set XDG_PROJECTS_DIR "$HOME/Projects"

    set CHICAGO_PLUS_DIR "$XDG_PROJECTS_DIR/Chicago95/Plus"
end
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