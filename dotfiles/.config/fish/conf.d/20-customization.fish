# -----------------------------------------------------
# CUSTOMIZATION
# -----------------------------------------------------

# -----------------------------------------------------
# Prompt
# -----------------------------------------------------
#eval "$($HOME/.local/bin/oh-my-posh init fish --config $HOME/.config/ohmyposh/zen.toml)"
# eval "$($HOME/.local/bin/oh-my-posh init fish --config $HOME/.config/ohmyposh/EDM115-newline.omp.json)"

# oh-my-posh
oh-my-posh init fish --config $HOME/.config/ohmyposh/blueish.omp.json | source

# mise
if type -q mise
    mise activate fish | source
end

# zoxide
if type -q zoxide
    zoxide init fish | source
end

# fzf
if type -q fzf
    if test -f /usr/share/fzf/shell/completion.fish
        source /usr/share/fzf/shell/completion.fish
    end

    if test -f /usr/share/fzf/shell/key-bindings.fish
        source /usr/share/fzf/shell/key-bindings.fish
    end
end