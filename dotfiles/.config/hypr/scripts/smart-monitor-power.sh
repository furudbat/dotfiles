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
DDC_DISPLAYS["HDMI-A-1"]=2  # LG IPS QHD (Primary Focus Fallback)
DDC_DISPLAYS["DP-2"]=3      # Acer EK271 H
DDC_DISPLAYS["DP-3"]=4      # Optional fourth monitor

TARGET_MONITORS=("HDMI-A-1" "DP-2" "DP-3")
PRIMARY_FALLBACK_MONITOR="DP-1"

set_refresh_saver() {
    hyprctl keyword monitor "DP-1,2560x1440@60,2560x169,1"
    hyprctl keyword monitor "HDMI-A-1,2560x1440@60,0x169,1"
    hyprctl keyword monitor "DP-2,1920x1080@60,5120x0,1"
}

set_refresh_normal() {
    hyprctl keyword monitor "DP-1,2560x1440@170,2560x169,1"
    hyprctl keyword monitor "HDMI-A-1,2560x1440@100,0x169,1"
    hyprctl keyword monitor "DP-2,1920x1080@100,5120x0,1"
}

set_brightness_if_needed() {
    local mon="$1"
    local target="$2"

    [[ "${CURRENT_STAGE[$mon]}" == "$target" ]] && return

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
            log_msg "Applying Eco Strategy: Rapid multi-screen blanking enabled."
            for mon in "${TARGET_MONITORS[@]}"; do
                WAKE_DELAY_REQ["$mon"]=3   
                DIM_75_TIME["$mon"]=100      
                DIM_50_TIME["$mon"]=250     
                DIM_25_TIME["$mon"]=360     
                OFF_TIME["$mon"]=600        
            done
            ;;
        "performance"|"balanced"|*)
            log_msg "Applying Balanced Strategy: Normalized timeline profiles enabled."
            
            # --- HDMI-A-1 ---
            WAKE_DELAY_REQ["HDMI-A-1"]=2
            DIM_75_TIME["HDMI-A-1"]=360
            DIM_50_TIME["HDMI-A-1"]=400
            DIM_25_TIME["HDMI-A-1"]=500
            OFF_TIME["HDMI-A-1"]=3600

            # --- DP-2 ---
            WAKE_DELAY_REQ["DP-2"]=2
            DIM_75_TIME["DP-2"]=260
            DIM_50_TIME["DP-2"]=360
            DIM_25_TIME["DP-2"]=460
            OFF_TIME["DP-2"]=3600

            # --- DP-3 ---
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

    # Re-fetch active monitors list on cleanup to avoid crashing if one was pulled out
    local active_monitors_list=$(hyprctl monitors -j 2>/dev/null)

    for mon in "${TARGET_MONITORS[@]}"; do
        # Verification check: skip if the monitor was completely disconnected during runtime
        if ! echo "$active_monitors_list" | jq -e --arg name "$mon" '.[] | select(.name == $name)' &>/dev/null; then
            continue
        fi

        DISP="${DDC_DISPLAYS[$mon]}"
        curr_stage=${CURRENT_STAGE[$mon]:-100}
        
        DPMS_STATUS=$(echo "$active_monitors_list" | jq -r ".[] | select(.name == \"$mon\") | .dpmsStatus" 2>/dev/null)
        
        stagger_bus_call
        if [ "$DPMS_STATUS" = "false" ]; then
            log_msg "$mon is suspended (OFF). Activating display connection and resetting baseline..."
            hyprctl dispatch dpms on "$mon" &>/dev/null
            ddcutil setvcp 10 100 --display "$DISP" --async &>/dev/null
            
        elif [ "$curr_stage" != "100" ] && [ "$curr_stage" != "OFF" ]; then
            log_msg "$mon is active but dimmed at ${curr_stage}%. Elevating back to 100% brightness..."
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
log_msg "Initializing monitors to 100% brightness..."
INIT_MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)
for mon in "${TARGET_MONITORS[@]}"; do
    IDLE_COUNTERS[$mon]=0
    HOVER_COUNTERS[$mon]=0
    CURRENT_STAGE[$mon]="100"
    
    # Initialize only if physically present
    if echo "$INIT_MONITORS_JSON" | jq -e --arg name "$mon" '.[] | select(.name == $name)' &>/dev/null; then
        stagger_bus_call
        ddcutil setvcp 10 100 --display "${DDC_DISPLAYS[$mon]}" --async &>/dev/null
    fi
done

update_timeout_profiles "$(powerprofilesctl get)"

# ==========================================
# 3. CORE PROCESSING LOOP
# ==========================================
while true; do
    CLIENTS_JSON=$(hyprctl clients -j 2>/dev/null)
    MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)
    
    ACTIVE_MONITOR=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null)
    CURRENT_PP_PROFILE=$(powerprofilesctl get 2>/dev/null)
    
    update_timeout_profiles "$CURRENT_PP_PROFILE"

    IS_LOCKED=false
    if pidof hyprlock &>/dev/null; then
        IS_LOCKED=true
    fi

    HYPRIDLE_RUNNING=true
    if ! pidof hypridle &>/dev/null; then
        HYPRIDLE_RUNNING=false
    fi

    # --- CRITICAL PROTECTION CONTEXT ---
    ACTIVE_SCREENS_COUNT=0
    for m in "${TARGET_MONITORS[@]}"; do
        # Check if it is physically active in the JSON environment AND not software disabled
        if echo "$MONITORS_JSON" | jq -e --arg name "$m" '.[] | select(.name == $name)' &>/dev/null; then
            if [ "${CURRENT_STAGE[$m]}" != "OFF" ]; then
                ((ACTIVE_SCREENS_COUNT++))
            fi
        fi
    done

    for mon in "${TARGET_MONITORS[@]}"; do
        # --------------------------------------
        # HARDWARE CONNECTION SANITY CHECK
        # --------------------------------------
        # Skip this monitor completely if it's not connected or turned on in Hyprland settings
        if ! echo "$MONITORS_JSON" | jq -e --arg name "$mon" '.[] | select(.name == $name)' &>/dev/null; then
            # Reset counters silently so it starts fresh if reconnected
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

        # If it was previously disconnected and just got plugged back in, reset state to 100
        if [ "$curr_stage" = "DISCONNECTED" ]; then
            curr_stage="100"
            CURRENT_STAGE[$mon]="100"
        fi

        # --------------------------------------
        # BULLETPROOF IDLE INHIBITION DETECTOR
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
                    log_msg "LOCK SCREEN SAFETY: Preventing total black out. Holding primary monitor ($mon) active at 25%."
                    stagger_bus_call
                    ddcutil setvcp 10 25 --display "$DISP" --async &>/dev/null
                    CURRENT_STAGE[$mon]="25"
                fi
            elif [ "$curr_stage" != "OFF" ]; then
                log_msg "SYSTEM LOCKED: Fast-tracking auxiliary screen $mon completely OFF"
                stagger_bus_call
                # @FIXME: remove "pidof hyprlock || " -- https://github.com/hyprwm/hyprlock/issues/953
                if ! pidof hyprlock >/dev/null; then
                    hyprctl dispatch "hl.dsp.dpms({ action = \"disable\", monitor = \"$mon\" })" &>/dev/null
                    CURRENT_STAGE[$mon]="OFF"
                fi
                ((ACTIVE_SCREENS_COUNT--))
            fi
            continue
        fi

        # --------------------------------------
        # MONITOR IS PROTECTED (FOCUS OR RUNNING MEDIA)
        # --------------------------------------
        if [ "$mon" = "$ACTIVE_MONITOR" ] || [ "$HAS_ACTIVE_MEDIA_WINDOW" = "true" ]; then
            if [ "$id_count" -ne 0 ]; then
                if [ "$curr_stage" != "100" ]; then
                    if [ "$HAS_ACTIVE_MEDIA_WINDOW" = "true" ]; then
                        log_msg "Active Media / Idle-Inhibition window detected on $mon. Resetting timers."
                    else
                        log_msg "Cursor focus returned to $mon. Restoring display state..."
                    fi
                fi
                IDLE_COUNTERS[$mon]=0
            fi
            
            if [ "$curr_stage" = "OFF" ]; then
                ((HOVER_COUNTERS[$mon]++))
                log_msg "$mon is OFF. Hover validation counter: ${HOVER_COUNTERS[$mon]}/$t_wake"
                
                if [[ ${HOVER_COUNTERS[$mon]} -ge $t_wake ]]; then
                    log_msg "Hover threshold met! Waking up $mon."
                    stagger_bus_call
                    hyprctl dispatch dpms on "$mon" &>/dev/null
                    ddcutil setvcp 10 100 --display "$DISP" --async &>/dev/null
                    CURRENT_STAGE[$mon]="100"
                    HOVER_COUNTERS[$mon]=0
                fi
            elif [ "$curr_stage" != "100" ]; then
                log_msg "$mon was dimmed ($curr_stage%). Restoring to 100% instantly."
                stagger_bus_call
                ddcutil setvcp 10 100 --display "$DISP" --async &>/dev/null
                CURRENT_STAGE[$mon]="100"
                HOVER_COUNTERS[$mon]=0
            fi
        else
            # --------------------------------------
            # MONITOR IS FULLY IDLE (NO MOUSE, NO INHIBITORS)
            # --------------------------------------
            ((IDLE_COUNTERS[$mon]++))
            HOVER_COUNTERS[$mon]=0 

            if [[ $id_count -ge $t_off ]]; then
                if [ "$curr_stage" != "OFF" ]; then
                    if [ "$mon" = "$PRIMARY_FALLBACK_MONITOR" ] || [ $ACTIVE_SCREENS_COUNT -le 1 ]; then
                        if [ "$curr_stage" != "25" ]; then
                            log_msg "TOTAL BLACKOUT SAFETY OVERRIDE: Holding last standing monitor ($mon) active at 25%."
                            stagger_bus_call
                            ddcutil setvcp 10 25 --display "$DISP" --async &>/dev/null
                            CURRENT_STAGE[$mon]="25"
                        fi
                    elif [ "$HYPRIDLE_RUNNING" = "false" ]; then
                        if [ "$curr_stage" != "25" ] ; then
                            log_msg "HYPRIDLE NOT RUNNING: Overriding deep sleep. Holding $mon at 25% brightness fallback."
                            stagger_bus_call
                            ddcutil setvcp 10 25 --display "$DISP" --async &>/dev/null
                            CURRENT_STAGE[$mon]="25"
                        fi
                    else
                        log_msg "TIMEOUT REACHED ($id_count s >= $t_off s): Turning $mon completely OFF"
                        stagger_bus_call
                        # @FIXME: remove "pidof hyprlock || " -- https://github.com/hyprwm/hyprlock/issues/953
                        if ! pidof hyprlock >/dev/null; then
                            hyprctl dispatch "hl.dsp.dpms({ action = \"disable\", monitor = \"$mon\" })" &>/dev/null
                            CURRENT_STAGE[$mon]="OFF"
                        fi
                        ((ACTIVE_SCREENS_COUNT--))
                    fi
                fi
            elif [[ $id_count -ge $t_25 ]]; then
                if [ "$curr_stage" != "25" ] && [ "$curr_stage" != "OFF" ]; then
                    log_msg "TIMEOUT REACHED ($id_count s >= $t_25 s): Dimming $mon to 25%"
                    stagger_bus_call
                    ddcutil setvcp 10 25 --display "$DISP" --async &>/dev/null
                    CURRENT_STAGE[$mon]="25"
                fi
            elif [[ $id_count -ge $t_50 ]]; then
                if [ "$curr_stage" != "50" ] && [ "$curr_stage" != "25" ] && [ "$curr_stage" != "OFF" ]; then
                    log_msg "TIMEOUT REACHED ($id_count s >= $t_50 s): Dimming $mon to 50%"
                    stagger_bus_call
                    ddcutil setvcp 10 50 --display "$DISP" --async &>/dev/null
                    CURRENT_STAGE[$mon]="50"
                fi
            elif [[ $id_count -ge $t_75 ]]; then
                if [ "$curr_stage" != "75" ] && [ "$curr_stage" != "50" ] && [ "$curr_stage" != "25" ] && [ "$curr_stage" != "OFF" ]; then
                    log_msg "TIMEOUT REACHED ($id_count s >= $t_75 s): Dimming $mon to 75%"
                    stagger_bus_call
                    ddcutil setvcp 10 75 --display "$DISP" --async &>/dev/null
                    CURRENT_STAGE[$mon]="75"
                fi
            fi
        fi
    done

    sleep 1
done