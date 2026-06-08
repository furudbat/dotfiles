#!/usr/bin/env bash

PIDFILE="/tmp/hypr-power-daemon.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    exit 0
fi

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

PERF_APPS="code-oss|code|android-studio|clion|intellij|jetbrains|neovim|ghostty|alacritty|kitty|wine|steam"

STATE="balanced"
BAL_TIMER_PID=""

set_profile() {
    local profile="$1"

    if [ "$STATE" != "$profile" ]; then
        STATE="$profile"
        echo "$(date): switching to $profile" >> /tmp/power-daemon.log
        powerprofilesctl set "$profile"
    fi
}

cancel_bal_timer() {
    [ -n "$BAL_TIMER_PID" ] && kill "$BAL_TIMER_PID" 2>/dev/null
    BAL_TIMER_PID=""
}

visible_workspaces() {
    hyprctl monitors -j | jq -r '.[].activeWorkspace.id'
}

any_perf_visible_ws() {
    local ws_list
    ws_list="$(visible_workspaces | paste -sd'|' -)"

    hyprctl clients -j |
        jq -r --arg ws "$ws_list" --arg perf "$PERF_APPS" '
            .[] |
            select(.mapped == true) |
            select(.class | ascii_downcase | test($perf)) |
            .workspace.id |
            tostring
        ' | grep -E "^($ws_list)$" -q
}

start_bal_timer() {
    cancel_bal_timer

    (
        sleep 30
        if ! any_perf_visible_ws; then
            set_profile balanced
        fi
    ) &
    BAL_TIMER_PID=$!
}

handle_event() {
    local line="$1"

    if [[ "$line" == activewindow\>\>* ]]; then
        local payload="${line#activewindow>>}"
        local active_class="${payload%%,*}"
        active_class="$(echo "$active_class" | tr '[:upper:]' '[:lower:]')"

        #echo "$(date): focus=$active_class"

        if any_perf_visible_ws; then
            cancel_bal_timer
            set_profile performance
            return
        fi

        if [[ "$active_class" =~ $PERF_APPS ]]; then
            (
                sleep 10
                if any_perf_visible_ws; then
                    set_profile performance
                fi
            ) &
        else
            start_bal_timer
        fi
    fi
}

socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" |
while read -r line; do
    handle_event "$line"
done