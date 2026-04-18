#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for volume controls for audio and mic - wpctl version

iDIR="$HOME/.config/swaync/icons"
# Sound-Datei (Standard in vielen Themes, sonst Pfad anpassen)
SOUND_FILE="/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"

# Get Volume (Converted to integer percentage)
get_volume() {
    volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}')
    is_muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -i "MUTED")
    
    if [[ -n "$is_muted" ]]; then
        echo "Muted"
    else
        echo "$(echo "$volume * 100" | bc | cut -d. -f1) %"
    fi
}

# Get icons
get_icon() {
    current=$(get_volume)
    if [[ "$current" == "Muted" ]]; then
        echo "$iDIR/volume-mute.png"
    else
        vol_num=$(echo "$current" | tr -d ' %')
        if [[ "$vol_num" -le 30 ]]; then
            echo "$iDIR/volume-low.png"
        elif [[ "$vol_num" -le 60 ]]; then
            echo "$iDIR/volume-mid.png"
        else
            echo "$iDIR/volume-high.png"
        fi
    fi
}

# Play Sound (Ersatz für Sounds.sh)
play_sound() {
    if [ -f "$SOUND_FILE" ]; then
        pw-play "$SOUND_FILE" &
    fi
}

# Notify
notify_user() {
    vol_text=$(get_volume)
    if [[ "$vol_text" == "Muted" ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$(get_icon)" " Volume:" " Muted"
    else
        vol_num=$(echo "$vol_text" | tr -d ' %')
        notify-send -e -h int:value:"$vol_num" -h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$(get_icon)" " Volume Level:" " $vol_text"
        play_sound
    fi
}

# Increase Volume
inc_volume() {
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ && notify_user
}

# Decrease Volume
dec_volume() {
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify_user
}

# Toggle Mute
toggle_mute() {
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    if [[ "$(get_volume)" == "Muted" ]]; then
        notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/volume-mute.png" " Mute"
    else
        notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$(get_icon)" " Volume:" " Switched ON"
    fi
}

# Restliche Funktionen (Mic etc.) bleiben gleich wie zuvor...
# [Hier können die Mic-Funktionen aus der vorherigen Antwort eingefügt werden]

# Execute accordingly
case "$1" in
    "--inc") inc_volume ;;
    "--dec") dec_volume ;;
    "--toggle") toggle_mute ;;
    *) get_volume ;;
esac