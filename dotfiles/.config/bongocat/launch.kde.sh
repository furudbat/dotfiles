#!/usr/bin/env bash
exec 200>$XDG_RUNTIME_DIR/bongocat-launch.lock
flock -n 200 || exit 0

killall wpets || true
pkill wpets || true
killall wpets-all || true
pkill wpets-all || true
killall wpets-dm || true
pkill wpets-dm || true
killall wpets-pkmn || true
pkill wpets-pkmn || true
sleep 1

# Check if waybar-disabled file exists
if [ ! -f $HOME/.config/ml4w/settings/waybar-disabled ]; then
    # NOTE: add more wpets here
    wpets-dm --watch-config --config ~/.config/bongocat/screen1.bongocat.kde.conf --strict --nr 1      2>&1 > ~/.cache/bongocat/1.screen1.log &
    wpets-pkmn --watch-config --config ~/.config/bongocat/audio.screen1.bongocat.kde.conf --strict --nr 2     2>&1 > ~/.cache/bongocat/2.screen1.log &
    wpets-all --watch-config --config ~/.config/bongocat/screen2.bongocat.kde.conf --strict --nr 3      2>&1 > ~/.cache/bongocat/3.screen2.log &
    wpets-dm --watch-config --config ~/.config/bongocat/cpu.screen2.bongocat.kde.conf --strict --nr 4  2>&1 > ~/.cache/bongocat/4.cpu.screen2.log &
    wpets-all --watch-config --config ~/.config/bongocat/screen3.bongocat.kde.conf --strict --nr 5      2>&1 > ~/.cache/bongocat/5.screen3.log &
    wpets-pkmn --watch-config --config ~/.config/bongocat/screen4.bongocat.kde.conf --strict --nr 6     2>&1 > ~/.cache/bongocat/6.screen4.log &
else
    echo ":: Waybar disabled"
fi

# Explicitly release the lock (optional) -> flock releases on exit
flock -u 200
exec 200>&-