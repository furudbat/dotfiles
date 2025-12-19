# -----------------------------------------------------
# AUTOSTART
# -----------------------------------------------------

# -----------------------------------------------------
# Fastfetch
# -----------------------------------------------------
if status is-interactive
    switch $TERM
        case '*kitty*'
            pokemon-colorscripts --no-title -s -r | \
                fastfetch \
                    -c $HOME/.config/fastfetch/pkmn.config.jsonc \
                    --logo-type file-raw \
                    --logo-height 10 \
                    --logo-width 5 \
                    --logo -

        case '*ghost*'
            fastfetch -c $HOME/.config/fastfetch/config.jsonc

        case '*'
            fastfetch -c $HOME/.config/fastfetch/config.jsonc
    end
end