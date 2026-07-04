#!/bin/bash

trap "pkill -P $$" EXIT

ICONS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

cava -p ~/.config/cava/config | while IFS=';' read -ra bars; do
    # Ensure a complete frame of 8 bars
    (( ${#bars[@]} < 8 )) && continue

    left=""
    right=""

    # Loop through the 8 stereo bars
    for ((i=0; i<8; i++)); do
        b="${bars[i]}"
        
        (( b > 7 )) && b=7
        (( b < 0 )) && b=0
        icon="${ICONS[$b]}"

        if (( i % 2 == 0 )); then
            # Left channel
            left="$left$icon"
        else
            # Right channel
            right="$icon$right"
        fi
    done

    output="$left$right"

    echo "{\"text\":\"$output\",\"class\":\"cava\"}"
done