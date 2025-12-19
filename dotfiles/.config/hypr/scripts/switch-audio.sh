#!/usr/bin/env bash

# --- CONFIGURATION ---
WHITELIST=(
    "USB Audio Speakers"
    "JBL Quantum350 Wireless Analoges Stereo"
)

ENABLE_NOTIFICATIONS=true

# ------------ FUNCTIONS ------------ #

notify() {
    local msg="$1"
    if [[ "$ENABLE_NOTIFICATIONS" == true ]]; then
        dbus-launch notify-send -u low -t 800 "Audio Switch" "$msg"
    fi
}

get_sinks() {
    # Output: lines in the following format:
    # sink_id|sink_name|is_default
    wpctl status | \
        sed 's/[├─│└]//g' | \
        awk '/Sinks:/ {flag=1; next} /^$/ {flag=0} flag' | \
        while read -r line; do
            [[ -z "$line" ]] && continue

            # Detect default (*) marker
            if [[ "$line" == \** ]]; then
                is_default=1
                line="${line#\*}"
            else
                is_default=0
            fi

            line="${line#"${line%%[![:space:]]*}"}" # trim left

            # Extract ID and name: "52. USB Audio Speakers [vol: ...]"
            if [[ "$line" =~ ^([0-9]+)\.\ ([^\[]+) ]]; then
                sink_id="${BASH_REMATCH[1]}"
                sink_name="${BASH_REMATCH[2]}"
                sink_name="${sink_name%"${sink_name##*[![:space:]]}"}" # trim right

                # Check whitelist
                for allowed in "${WHITELIST[@]}"; do
                    if [[ "$sink_name" == "$allowed" ]]; then
                        echo "$sink_id|$sink_name|$is_default"
                    fi
                done
            fi
        done
}

toggle_sink() {
    mapfile -t sinks < <(get_sinks)

    if (( ${#sinks[@]} == 0 )); then
        notify "No whitelisted sinks found!"
        exit 1
    fi

    local current_index=-1
    local i=0

    for entry in "${sinks[@]}"; do
        IFS="|" read -r id name is_default <<< "$entry"
        if [[ "$is_default" == "1" ]]; then
            current_index=$i
        fi
        ((i++))
    done

    # No default marked? Default to first entry
    if (( current_index == -1 )); then
        current_index=0
    fi

    next_index=$(( (current_index + 1) % ${#sinks[@]} ))
    IFS="|" read -r next_id next_name next_def <<< "${sinks[$next_index]}"

    # Apply new default sink
    wpctl set-default "$next_id"

    notify "Switched to $next_name"
}

# ------------ MAIN ------------ #

toggle_sink
