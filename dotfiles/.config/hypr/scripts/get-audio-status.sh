#!/usr/bin/env bash

# Get default sink (*)
sink_line=$(wpctl status 2>/dev/null | sed 's/[├─│└]//g' |
awk '/Audio$/ {in_audio=1} in_audio && /Sinks:/ {in_sinks=1; next} in_sinks && /^[[:space:]]*$/ {exit} in_sinks && /^[[:space:]]*\*/ {print; exit}')

# Fallback if empty
[[ -z "$sink_line" ]] && sink_line="* 0. Unknown Sink [vol: 0]"

# Extract sink name
sink_name=$(echo "$sink_line" | sed 's/^[[:space:]]*\*//; s/^[[:space:]]*//' \
            | sed -E 's/^[0-9]+\.\s*([^[]+).*/\1/' \
            | sed 's/[[:space:]]*$//')
[[ -z "$sink_name" ]] && sink_name="Unknown Sink"

# Extract volume
volume=$(echo "$sink_line" | grep -oP '\[vol: \K[0-9.]+' | awk '{printf "%d", $1*100}')
[[ -z "$volume" ]] && volume="0"

# Mute detection (0 = unmuted, 1 = muted)
sink_id=$(echo "$sink_line" | sed -E 's/^[[:space:]]*\*([0-9]+)\..*/\1/')
muted=$(wpctl get-volume "$sink_id" 2>/dev/null | grep -q "muted" && echo 1 || echo 0)

# Determine icon
if [[ "$muted" -eq 1 ]]; then
    icon=""
else
    case "$sink_name" in
        *Headphone*|*headset*|*Hands-Free*|*Wireless*|*JBL* )
            icon=""
            ;;
        *USB* )
            icon=""
            ;;
        *HDMI* )
            icon="🖥️"
            ;;
        *Speaker*|*Analog*|*Speakers* )
            icon=""
            ;;
        *)
            icon=""
            ;;
    esac
fi

# Output JSON for Waybar
jq -c -n --arg icon "$icon" --arg vol "$volume" --arg sink "$sink_name" \
   '{text: ($icon + "  " + $vol + "%"), icon: $icon, tooltip: ($sink + " | " + $vol + "%"), class: "audio", percentage: $vol}'
