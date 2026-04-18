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
        notify-send -u low -t 800 "Audio Switch" "$msg"
    fi
}

get_sinks() {
    local skip_whitelist="$1" # If "true", ignore the WHITELIST array
    
    wpctl status | \
        sed 's/[├─│└]//g' | \
        awk '/Sinks:/ {flag=1; next} /^$/ {flag=0} flag' | \
        while read -r line; do
            [[ -z "$line" ]] && continue

            if [[ "$line" == \** ]]; then
                is_default=1
                line="${line#\*}"
            else
                is_default=0
            fi

            line="${line#"${line%%[![:space:]]*}"}" 

            if [[ "$line" =~ ^([0-9]+)\.\ ([^\[]+) ]]; then
                sink_id="${BASH_REMATCH[1]}"
                sink_name="${BASH_REMATCH[2]}"
                sink_name="${sink_name%"${sink_name##*[![:space:]]}"}"

                if [[ "$skip_whitelist" == "true" ]]; then
                    echo "$sink_id|$sink_name|$is_default"
                else
                    for allowed in "${WHITELIST[@]}"; do
                        if [[ "$sink_name" == "$allowed" ]]; then
                            echo "$sink_id|$sink_name|$is_default"
                        fi
                    done
                fi
            fi
        done
}

switch_audio() {
    local target_name="$1"
    local sinks
    
    # Logic: If argument exists, fetch ALL sinks. If not, fetch WHITELISTED sinks.
    if [[ -n "$target_name" ]]; then
        mapfile -t sinks < <(get_sinks "true")
    else
        mapfile -t sinks < <(get_sinks "false")
    fi

    if (( ${#sinks[@]} == 0 )); then
        notify "No sinks found!"
        exit 1
    fi

    local target_id=""
    local target_found_name=""

    # 1. Search for the specific argument in the full list
    if [[ -n "$target_name" ]]; then
        for entry in "${sinks[@]}"; do
            IFS="|" read -r id name is_default <<< "$entry"
            if [[ "${name,,}" == *"${target_name,,}"* ]]; then
                target_id="$id"
                target_found_name="$name"
                break
            fi
        done
    fi

    # 2. If no target found or no argument provided, toggle within the whitelist
    if [[ -z "$target_id" ]]; then
        # If we reached here with an argument, it means the target wasn't found.
        # We should re-fetch the whitelisted sinks for the toggle.
        if [[ -n "$target_name" ]]; then
             mapfile -t sinks < <(get_sinks "false")
        fi

        local current_index=-1
        local i=0
        for entry in "${sinks[@]}"; do
            IFS="|" read -r id name is_default <<< "$entry"
            [[ "$is_default" == "1" ]] && current_index=$i
            ((i++))
        done

        [[ $current_index -eq -1 ]] && current_index=0
        
        local next_index=$(( (current_index + 1) % ${#sinks[@]} ))
        IFS="|" read -r target_id target_found_name next_def <<< "${sinks[$next_index]}"
    fi

    # 3. Execution
    wpctl set-default "$target_id"
    notify "Switched to $target_found_name"
}

# ------------ MAIN ------------ #

switch_audio "$1"