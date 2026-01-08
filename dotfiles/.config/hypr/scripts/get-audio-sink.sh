#!/usr/bin/env bash

# Get the Audio → Sinks block only
sinks_block=$(
    wpctl status | sed 's/[├─│└]//g' |
    awk '
        /Audio$/ { in_audio=1 }
        in_audio && /Sinks:/ { in_sinks=1; next }
        in_sinks && /^$/ { exit }
        in_sinks
    '
)

# Find the default sink (line starting with spaces + *)
default_line=$(echo "$sinks_block" | grep -E "^[[:space:]]*\*")

if [[ -z "$default_line" ]]; then
    echo "No default sink found."
    exit 1
fi

# Clean up the default-line
clean_line=$(echo "$default_line" | sed 's/^[[:space:]]*\*//; s/^[[:space:]]*//')

# Extract sink name (strip ID and everything after the first '[')
current_sink_name=$(echo "$clean_line" | sed -E 's/^[0-9]+\.\s*([^[]+).*/\1/' | sed 's/[[:space:]]*$//')


# --- icon function ---
print_icon() {
    case "$current_sink_name" in
        *Headphones*|*headphones*|*Headset*|*Wireless*|*Bluetooth*)
            echo ""
            ;;
        *Speaker*|*speaker*|*Speakers*|*Analog*)
            echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

current_icon=$(print_icon)

# Example usage:
echo "$current_sink_name"