#!/usr/bin/env fish

set runtime_dir /tmp
if set -q XDG_RUNTIME_DIR
    set runtime_dir $XDG_RUNTIME_DIR
end

jq --slurpfile palette ~/.config/ohmyposh/colors.json \
   '. + $palette[0]' \
   ~/.config/ohmyposh/blueish.omp.json \
   > "$runtime_dir/new_theme.json"

mv "$runtime_dir/new_theme.json" ~/.config/ohmyposh/blueish.omp.json