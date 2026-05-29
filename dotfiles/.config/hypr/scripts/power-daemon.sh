#!/usr/bin/env bash

# Clean up any existing instances of this script
PIDFILE="/tmp/hypr-power-daemon.pid"
if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    exit 0
fi
echo $$ > "$PIDFILE"

# List of window classes/titles that trigger Performance mode
# Use 'hyprctl clients' to find your specific app class names
PERF_APPS="code-odd|code|android-studio|clion|intellij|jetbrains|neovim|ghostty|alacritty|kitty|wine|steam"

handle_event() {
    local line="$1"
    
    # Listen to 'activewindowv2' event (fires when window focus shifts)
    if [[ "$line" =~ ^activewindowv2\:\: ]]; then
        # Query Hyprland for the currently focused window class
        local active_class=$(hyprctl activewindow -j | jq -r '.class' | tr '[:upper:]' '[:lower:]')
        
        if [ -f ~/.cache/gamemode ]; then
            powerprofilesctl set performance
        else
            # If the active window matches our development stack, kick up the governor
            if [[ "$active_class" =~ $PERF_APPS ]]; then
                # Avoid redundant calls if already set
                if [ "$(powerprofilesctl get)" != "performance" ]; then
                    powerprofilesctl set performance
                fi
            else
                # Default back to balanced when browsing or chatting
                if [ "$(powerprofilesctl get)" != "balanced" ]; then
                    powerprofilesctl set balanced
                fi
            fi
        fi
    fi
}

# Connect to Hyprland's event broadcast socket
# Requires 'socat' and 'jq' installed on your system
socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    handle_event "$line"
done