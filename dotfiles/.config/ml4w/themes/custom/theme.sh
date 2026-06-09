#!/usr/bin/env bash
# Custom Theme

# Set waybar
echo "/custom;/custom" > $HOME/.config/ml4w/settings/waybar-theme.sh
$HOME/.config/waybar/launch.sh &

# Set nwg-dock-hyprland
echo "custom" > $HOME/.config/ml4w/settings/dock-theme
$HOME/.config/nwg-dock-hyprland/launch.sh &

# Set swaync
echo '@import "themes/custom/style.css";' > $HOME/.config/swaync/style.css
swaync-client -rs

# Set launcher
echo 'rofi' > $HOME/.config/ml4w/settings/launcher

# Set walker theme
echo 'custom' > $HOME/.config/ml4w/settings/walker-theme

# Set Window Border
echo -e 'local name = "custom.lua"\nload_variant(name,"windows")' > $HOME/.config/hypr/conf/custom.lua

# Set rofi
echo '* { border-width: 2px; }' > $HOME/.config/ml4w/settings/rofi-border.rasi

echo ":: Theme set to custom"