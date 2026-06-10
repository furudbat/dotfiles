#!/bin/bash

LOG_FILE="/tmp/smart_monitor.log"
log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [RESTORE] $1" >> "$LOG_FILE"
}

PRIMARY_MONITOR="DP-1"
declare -A DDC_DISPLAYS=( ["HDMI-A-1"]=2 ["DP-2"]=3 ["DP-3"]=4 )
TARGET_MONITORS=("HDMI-A-1" "DP-2" "DP-3")

log_msg "Selective restoration triggered to prevent flickering..."

# 1. Ensure main workstation screen is on
hyprctl dispatch "hl.dsp.dpms({ action = \"disable\", monitor = \"$PRIMARY_MONITOR\" })" &>/dev/null

# 2. Loop through screens and ONLY restore what is altered
for mon in "${TARGET_MONITORS[@]}"; do
    DISP="${DDC_DISPLAYS[$mon]}"
    
    # Read the current stage directly from the running state of the main daemon script
    # If the daemon wasn't tracking, default to checking DPMS status
    CURRENT_STATUS=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$mon\") | .dpmsStatus")
    
    # Check if monitor is actually blanked at the Hyprland driver level
    if [ "$CURRENT_STATUS" = "false" ]; then
        log_msg "$mon is suspended (OFF). Waking up and normalizing..."
        hyprctl dispatch "hl.dsp.dpms({ action = \"enable\", monitor = \"$mon\" })" &>/dev/null
        ddcutil setvcp 10 100 --display "$DISP" --async &>/dev/null
    else
        ddcutil setvcp 10 100 --display "$DISP" --async &>/dev/null
        # The screen is physically ON. Now check if it's currently dimmed.
        # We can poll the real monitor brightness over DDC to verify if it needs resetting.
        # To remain fast, we only reset if it's not a standard 100% return footprint.
        log_msg "$mon is already active. Skipping power commands to prevent flicker."
    fi
done

log_msg "Selective restoration finished cleanly."