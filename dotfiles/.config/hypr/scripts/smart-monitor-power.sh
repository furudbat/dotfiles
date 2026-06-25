#!/bin/bash

# Log helper function
log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Ensure required dependencies are present
for cmd in jq ddcutil hyprctl powerprofilesctl; do
    if ! command -v $cmd &> /dev/null; then
        echo "Missing dependency: $cmd" && exit 1
    fi
done

# ==========================================
# 1. MONITOR MAP CONFIGURATION
# ==========================================
declare -A DDC_DISPLAYS
DDC_DISPLAYS["HDMI-A-1"]=2
DDC_DISPLAYS["DP-2"]=3
DDC_DISPLAYS["DP-3"]=4

TARGET_MONITORS=("HDMI-A-1" "DP-2" "DP-3")
PRIMARY_FALLBACK_MONITOR="DP-1"

# ==========================================
# REFRESH RATE CONTROL
# ==========================================
# Track current refresh state globally to avoid redundant hyprctl calls
CURRENT_REFRESH_MODE="normal"

set_refresh_saver() {
    [[ "$CURRENT_REFRESH_MODE" == "saver" ]] && return
    log_msg "REFRESH: Dropping all monitors to 60Hz (power-saver)"
    hyprctl keyword monitor "DP-1,2560x1440@60,2560x169,1"
    hyprctl keyword monitor "HDMI-A-1,2560x1440@60,0x169,1"
    hyprctl keyword monitor "DP-2,1920x1080@60,5120x0,1"
    CURRENT_REFRESH_MODE="saver"
    # Invalidate monitor cache after a mode change
    MONITORS_CACHE=""
    MONITORS_CACHE_TIME=0
}

set_refresh_normal() {
    [[ "$CURRENT_REFRESH_MODE" == "normal" ]] && return
    log_msg "REFRESH: Restoring monitors to max Hz"
    hyprctl keyword monitor "DP-1,2560x1440@170,2560x169,1"
    hyprctl keyword monitor "HDMI-A-1,2560x1440@100,0x169,1"
    hyprctl keyword monitor "DP-2,1920x1080@100,5120x0,1"
    CURRENT_REFRESH_MODE="normal"
    MONITORS_CACHE=""
    MONITORS_CACHE_TIME=0
}

# ==========================================
# CACHE LAYER
# ==========================================
# All three caches refresh on independent intervals (seconds).
# Monitors change rarely; clients change more often; power profile rarely.
MONITORS_CACHE=""
MONITORS_CACHE_TIME=0
MONITORS_CACHE_TTL=5      # seconds — monitors almost never change mid-session

CLIENTS_CACHE=""
CLIENTS_CACHE_TIME=0
CLIENTS_CACHE_TTL=3       # seconds — media windows open/close occasionally

PP_CACHE=""
PP_CACHE_TIME=0
PP_CACHE_TTL=10           # seconds — power profile changes are user-driven

get_monitors_json() {
    local now
    now=$(date +%s)
    if (( now - MONITORS_CACHE_TIME >= MONITORS_CACHE_TTL )) || [[ -z "$MONITORS_CACHE" ]]; then
        MONITORS_CACHE=$(hyprctl monitors -j 2>/dev/null)
        MONITORS_CACHE_TIME=$now
    fi
    echo "$MONITORS_CACHE"
}

get_clients_json() {
    local now
    now=$(date +%s)
    if (( now - CLIENTS_CACHE_TIME >= CLIENTS_CACHE_TTL )) || [[ -z "$CLIENTS_CACHE" ]]; then
        CLIENTS_CACHE=$(hyprctl clients -j 2>/dev/null)
        CLIENTS_CACHE_TIME=$now
    fi
    echo "$CLIENTS_CACHE"
}

get_power_profile() {
    local now
    now=$(date +%s)
    if (( now - PP_CACHE_TIME >= PP_CACHE_TTL )) || [[ -z "$PP_CACHE" ]]; then
        PP_CACHE=$(powerprofilesctl get 2>/dev/null)
        PP_CACHE_TIME=$now
    fi
    echo "$PP_CACHE"
}

# ==========================================
# DDC TRANSITION-GATED BRIGHTNESS SETTER
# ==========================================
# Replaces all raw `ddcutil setvcp 10 ...` calls in the loop.
# Only fires ddcutil when the stage actually changes.
set_brightness_if_needed() {
    local mon="$1"
    local target="$2"   # numeric value: 100, 75, 50, 25

    [[ "${CURRENT_STAGE[$mon]}" == "$target" ]] && return

    log_msg "DDC: $mon brightness → ${target}%"
    stagger_bus_call
    ddcutil setvcp 10 "$target" \
        --display "${DDC_DISPLAYS[$mon]}" \
        --async >/dev/null 2>&1

    CURRENT_STAGE[$mon]="$target"
}

# Operational States Tracking Arrays
declare -A IDLE_COUNTERS HOVER_COUNTERS CURRENT_STAGE LAST_PROFILE
declare -A DIM_75_TIME DIM_50_TIME DIM_25_TIME OFF_TIME WAKE_DELAY_REQ

# ==========================================
# 2. DYNAMIC PROFILE SCALING ENGINE
# ==========================================
update_timeout_profiles() {
    local active_profile=$1

    if [ "$active_profile" = "${LAST_PROFILE["GLOBAL"]}" ]; then
        return
    fi

    log_msg "WAYBAR EVENT: Power Profile shifted to [$active_profile]. Re-indexing timer matrices..."
    LAST_PROFILE["GLOBAL"]="$active_profile"

    case "$active_profile" in
        "power-saver")
            log_msg "Applying Eco Strategy: Rapid multi-screen blanking + 60Hz enabled."
            set_refresh_saver
            for mon in "${TARGET_MONITORS[@]}"; do
                WAKE_DELAY_REQ["$mon"]=3
                DIM_75_TIME["$mon"]=100
                DIM_50_TIME["$mon"]=250
                DIM_25_TIME["$mon"]=360
                OFF_TIME["$mon"]=600
            done
            ;;
        "performance"|"balanced"|*)
            log_msg "Applying Balanced Strategy: Normalized timeline profiles + max Hz enabled."
            set_refresh_normal

            WAKE_DELAY_REQ["HDMI-A-1"]=2
            DIM_75_TIME["HDMI-A-1"]=360
            DIM_50_TIME["HDMI-A-1"]=400
            DIM_25_TIME["HDMI-A-1"]=500
            OFF_TIME["HDMI-A-1"]=3600

            WAKE_DELAY_REQ["DP-2"]=2
            DIM_75_TIME["DP-2"]=260
            DIM_50_TIME["DP-2"]=360
            DIM_25_TIME["DP-2"]=460
            OFF_TIME["DP-2"]=3600

            WAKE_DELAY_REQ["DP-3"]=2
            DIM_75_TIME["DP-3"]=200
            DIM_50_TIME["DP-3"]=360
            DIM_25_TIME["DP-3"]=400
            OFF_TIME["DP-3"]=3600
            ;;
    esac
}

# ==========================================
# ANTI-FLICKER BUS STAGGERING TOOL
# ==========================================
stagger_bus_call() {
    local jitter=$(awk 'BEGIN{srand(); print 0.1 + rand()*0.3}')
    sleep "$jitter"
}

# ==========================================
# SELECTIVE CLEANUP & RESTORE ROUTINE
# ==========================================
cleanup_and_restore() {
    log_msg "EXIT TRAP TRIGGERED: Restoring modified monitor states..."

    # Always restore refresh rate to normal on exit
    set_refresh_normal

    local active_monitors_list
    active_monitors_list=$(hyprctl monitors -j 2>/dev/null)

    for mon in "${TARGET_MONITORS[@]}"; do
        if ! echo "$active_monitors_list" | jq -e --arg name "$mon" '.[] | select(.name == $name)' &>/dev/null; then
            continue
        fi

        DISP="${DDC_DISPLAYS[$mon]}"
        curr_stage=${CURRENT_STAGE[$mon]:-100}

        DPMS_STATUS=$(echo "$active_monitors_list" | jq -r ".[] | select(.name == \"$mon\") | .dpmsStatus" 2>/dev/null)

        stagger_bus_call
        if [ "$DPMS_STATUS" = "false" ]; then
            log_msg "$mon is suspended (OFF). Activating display and resetting baseline..."
            hyprctl dispatch dpms on "$mon" &>/dev/null
            ddcutil setvcp 10 100 --display "$DISP" --async &>/dev/null
        elif [ "$curr_stage" != "100" ] && [ "$curr_stage" != "OFF" ]; then
            log_msg "$mon dimmed at ${curr_stage}%. Elevating back to 100%..."
            ddcutil setvcp 10 100 --display "$DISP" --async &>/dev/null
        fi
    done

    log_msg "Smart Power Manager Daemon terminated safely."
    exit 0
}

trap cleanup_and_restore EXIT SIGINT SIGTERM

# ==========================================
# INITIALIZATION BLOCK
# ==========================================
log_msg "Initializing monitors to 100% brightness and max refresh..."

# Force a live fetch at init (bypass cache)
INIT_MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)
MONITORS_CACHE="$INIT_MONITORS_JSON"
MONITORS_CACHE_TIME=$(date +%s)

for mon in "${TARGET_MONITORS[@]}"; do
    IDLE_COUNTERS[$mon]=0
    HOVER_COUNTERS[$mon]=0
    CURRENT_STAGE[$mon]="100"

    if echo "$INIT_MONITORS_JSON" | jq -e --arg name "$mon" '.[] | select(.name == $name)' &>/dev/null; then
        stagger_bus_call
        ddcutil setvcp 10 100 --display "${DDC_DISPLAYS[$mon]}" --async &>/dev/null
    fi
done

update_timeout_profiles "$(get_power_profile)"

# ==========================================
# 3. CORE PROCESSING LOOP
# ==========================================
while true; do
    CLIENTS_JSON=$(get_clients_json)
    MONITORS_JSON=$(get_monitors_json)

    ACTIVE_MONITOR=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null)
    CURRENT_PP_PROFILE=$(get_power_profile)

    update_timeout_profiles "$CURRENT_PP_PROFILE"

    IS_LOCKED=false
    if pidof hyprlock &>/dev/null; then
        IS_LOCKED=true
    fi

    HYPRIDLE_RUNNING=true
    if ! pidof hypridle &>/dev/null; then
        HYPRIDLE_RUNNING=false
    fi

    ACTIVE_SCREENS_COUNT=0
    for m in "${TARGET_MONITORS[@]}"; do
        if echo "$MONITORS_JSON" | jq -e --arg name "$m" '.[] | select(.name == $name)' &>/dev/null; then
            if [ "${CURRENT_STAGE[$m]}" != "OFF" ]; then
                ((ACTIVE_SCREENS_COUNT++))
            fi
        fi
    done

    for mon in "${TARGET_MONITORS[@]}"; do
        if ! echo "$MONITORS_JSON" | jq -e --arg name "$mon" '.[] | select(.name == $name)' &>/dev/null; then
            IDLE_COUNTERS[$mon]=0
            HOVER_COUNTERS[$mon]=0
            CURRENT_STAGE[$mon]="DISCONNECTED"
            continue
        fi

        DISP="${DDC_DISPLAYS[$mon]}"

        id_count=${IDLE_COUNTERS[$mon]:-0}
        hov_count=${HOVER_COUNTERS[$mon]:-0}
        curr_stage=${CURRENT_STAGE[$mon]:-100}

        t_75=${DIM_75_TIME[$mon]}
        t_50=${DIM_50_TIME[$mon]}
        t_25=${DIM_25_TIME[$mon]}
        t_off=${OFF_TIME[$mon]}
        t_wake=${WAKE_DELAY_REQ[$mon]}

        if [ "$curr_stage" = "DISCONNECTED" ]; then
            curr_stage="100"
            CURRENT_STAGE[$mon]="100"
        fi

        # --------------------------------------
        # IDLE INHIBITION DETECTOR
        # --------------------------------------
        HAS_ACTIVE_MEDIA_WINDOW=false
        if [ -n "$CLIENTS_JSON" ]; then
            MON_ID=$(echo "$MONITORS_JSON" | jq -r --arg name "$mon" '.[] | select(.name == $name) | .id' 2>/dev/null)
            if [ -n "$MON_ID" ]; then
                INHIBIT_CHECK=$(echo "$CLIENTS_JSON" | jq -r --argjson mid "$MON_ID" '.[] | select(.monitor == $mid) | select(.inhibitingIdle == true or (.title | test("YouTube|Netflix|Twitch|vlc|mpv"; "i"))) | .title' 2>/dev/null)
                if [ -n "$INHIBIT_CHECK" ]; then
                    HAS_ACTIVE_MEDIA_WINDOW=true
                fi
            fi
        fi

        # --------------------------------------
        # SYSTEM LOCKED OVERRIDE
        # --------------------------------------
        if [ "$IS_LOCKED" = "true" ] && [ "$mon" != "$ACTIVE_MONITOR" ]; then
            if [ "$mon" = "$PRIMARY_FALLBACK_MONITOR" ] && [ $ACTIVE_SCREENS_COUNT -le 1 ]; then
                if [ "$curr_stage" != "25" ]; then
                    log_msg "LOCK SCREEN SAFETY: Holding primary monitor ($mon) active at 25%."
                    set_brightness_if_needed "$mon" 25
                fi
            elif [ "$curr_stage" != "OFF" ]; then
                log_msg "SYSTEM LOCKED: Fast-tracking auxiliary screen $mon completely OFF"
                stagger_bus_call
                if ! pidof hyprlock >/dev/null; then
                    hyprctl dispatch "hl.dsp.dpms({ action = \"disable\", monitor = \"$mon\" })" &>/dev/null
                    CURRENT_STAGE[$mon]="OFF"
                fi
                ((ACTIVE_SCREENS_COUNT--))
            fi
            continue
        fi

        # --------------------------------------
        # MONITOR IS PROTECTED (FOCUS OR MEDIA)
        # --------------------------------------
        if [ "$mon" = "$ACTIVE_MONITOR" ] || [ "$HAS_ACTIVE_MEDIA_WINDOW" = "true" ]; then
            if [ "$id_count" -ne 0 ]; then
                if [ "$curr_stage" != "100" ]; then
                    if [ "$HAS_ACTIVE_MEDIA_WINDOW" = "true" ]; then
                        log_msg "Active Media on $mon. Resetting timers."
                    else
                        log_msg "Cursor focus returned to $mon. Restoring display state..."
                    fi
                fi
                IDLE_COUNTERS[$mon]=0
            fi

            if [ "$curr_stage" = "OFF" ]; then
                ((HOVER_COUNTERS[$mon]++))
                log_msg "$mon is OFF. Hover validation: ${HOVER_COUNTERS[$mon]}/$t_wake"

                if [[ ${HOVER_COUNTERS[$mon]} -ge $t_wake ]]; then
                    log_msg "Hover threshold met! Waking up $mon."
                    stagger_bus_call
                    hyprctl dispatch dpms on "$mon" &>/dev/null
                    set_brightness_if_needed "$mon" 100
                    HOVER_COUNTERS[$mon]=0
                fi
            elif [ "$curr_stage" != "100" ]; then
                log_msg "$mon was dimmed ($curr_stage%). Restoring to 100%."
                set_brightness_if_needed "$mon" 100
                HOVER_COUNTERS[$mon]=0
            fi
        else
            # --------------------------------------
            # MONITOR IS IDLE
            # --------------------------------------
            ((IDLE_COUNTERS[$mon]++))
            HOVER_COUNTERS[$mon]=0

            if [[ $id_count -ge $t_off ]]; then
                if [ "$curr_stage" != "OFF" ]; then
                    if [ "$mon" = "$PRIMARY_FALLBACK_MONITOR" ] || [ $ACTIVE_SCREENS_COUNT -le 1 ]; then
                        if [ "$curr_stage" != "25" ]; then
                            log_msg "BLACKOUT SAFETY: Holding last monitor ($mon) at 25%."
                            set_brightness_if_needed "$mon" 25
                        fi
                    elif [ "$HYPRIDLE_RUNNING" = "false" ]; then
                        if [ "$curr_stage" != "25" ]; then
                            log_msg "HYPRIDLE NOT RUNNING: Holding $mon at 25% fallback."
                            set_brightness_if_needed "$mon" 25
                        fi
                    else
                        log_msg "TIMEOUT REACHED ($id_count s >= $t_off s): Turning $mon OFF"
                        stagger_bus_call
                        if ! pidof hyprlock >/dev/null; then
                            hyprctl dispatch "hl.dsp.dpms({ action = \"disable\", monitor = \"$mon\" })" &>/dev/null
                            CURRENT_STAGE[$mon]="OFF"
                        fi
                        ((ACTIVE_SCREENS_COUNT--))
                    fi
                fi
            elif [[ $id_count -ge $t_25 ]]; then
                set_brightness_if_needed "$mon" 25
            elif [[ $id_count -ge $t_50 ]]; then
                # Only step down to 50 if not already at a lower stage
                if [ "$curr_stage" != "25" ] && [ "$curr_stage" != "OFF" ]; then
                    set_brightness_if_needed "$mon" 50
                fi
            elif [[ $id_count -ge $t_75 ]]; then
                if [ "$curr_stage" != "50" ] && [ "$curr_stage" != "25" ] && [ "$curr_stage" != "OFF" ]; then
                    set_brightness_if_needed "$mon" 75
                fi
            fi
        fi
    done

    sleep 1
done