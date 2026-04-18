# -----------------------------------------------------
# AUTOSTART
# -----------------------------------------------------

# -----------------------------------------------------
# Fastfetch
# -----------------------------------------------------
if status is-interactive
    if not test -f $HOME/.config/ml4w/settings/hide-fastfetch
        if string match -q '*pts*' (tty)

            # Detect IDE shells -> minimal fastfetch
            set -l is_ide_shell 0
            if test "$TERM_PROGRAM" = "vscode"
                set is_ide_shell 1
            end
            if set -q JETBRAINS_IDE; or set -q NVIM; or set -q INSIDE_EMACS
                set is_ide_shell 1
            end

            # Parent process fallback
            set -l parent (ps -o comm= -p (ps -o ppid= -p $fish_pid) 2>/dev/null | string trim)
            if string match -q '*code*' $parent \
            or string match -q '*idea*' $parent \
            or string match -q '*jetbrains-*' $parent \
            or string match -qi '*pycharm*' $parent \
            or string match -qi '*webstorm*' $parent
                set is_ide_shell 1
            end

            if test $is_ide_shell -eq 1
                fastfetch -c "$HOME/.config/fastfetch/minimal.jsonc"
            else
                switch $TERM
                    case '*kitty*'
                        if type -q pokemon-colorscripts
                            # Kitty -> Pokémon fastfetch
                            pokemon-colorscripts --no-title -s -r | \
                                fastfetch \
                                    -c "$HOME/.config/fastfetch/pkmn.config.jsonc" \
                                    --logo-type file-raw \
                                    --logo-height 10 \
                                    --logo-width 5 \
                                    --logo -
                        else
                            fastfetch -c "$HOME/.config/fastfetch/config.jsonc"
                        end
                    case '*ghost*'
                        # Ghostty -> normal fastfetch
                        fastfetch -c "$HOME/.config/fastfetch/config.jsonc"
                    case '*'
                        # All other terminals -> normal fastfetch
                        fastfetch -c "$HOME/.config/fastfetch/config.jsonc"
                end
            end
        end
    end
end