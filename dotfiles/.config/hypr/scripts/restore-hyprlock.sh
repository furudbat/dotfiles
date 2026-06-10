#!/usr/bin/env bash

pkill hyprlock || killall -9 hyprlock || true
hyprctl --instance 0 eval 'hl.config{misc={allow_session_lock_restore=true}}'
hyprctl --instance 0 eval 'hl.exec_cmd("hyprlock")'

sleep 5

# Start Quickshell
killall qs
sleep 0.5
hyprctl --instance 0 eval 'hl.exec_cmd("qs")'
sleep 0.5

# Start ML4W Settings App
hyprctl --instance 0 eval 'hl.exec_cmd("PROFILE=\"com.ml4w.dotfiles\" qs -p \"$HOME/.local/share/ml4w-dotfiles-settings/quickshell\"")'

# Start Quickshell Overview
hyprctl --instance 0 eval 'hl.exec_cmd("qs -p \"$HOME/.config/quickshell/overview\"")'
sleep 1

hyprctl --instance 0 eval 'hl.exec_cmd("~/.config/ml4w/scripts/ml4w-wallpaper-app --restore")'