# -----------------------------------------------------
# CUSTOMIZATION
# -----------------------------------------------------

# -----------------------------------------------------
# Prompt
# -----------------------------------------------------
#eval "$($HOME/.local/bin/oh-my-posh init fish --config $HOME/.config/ohmyposh/zen.toml)"
# eval "$($HOME/.local/bin/oh-my-posh init fish --config $HOME/.config/ohmyposh/EDM115-newline.omp.json)"

eval "$(oh-my-posh init fish --config $HOME/.config/ohmyposh/blueish.omp.json)"

if type -q mise
    mise activate fish | source
end

if type -q zoxide
    zoxide init fish | source
end

if type -q fzf
    if test -f /usr/share/fzf/completion.fish
        source /usr/share/fzf/completion.fish
    end

    if test -f /usr/share/fzf/key-bindings.fish
        source /usr/share/fzf/key-bindings.fish
    end
end