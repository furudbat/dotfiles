-- Set the cursor size for xcursor
hl.env("XCURSOR_THEME", "ModernXP2")
hl.env("XCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_SIZE", "32")

hl.on("hyprland.start", function () 
    hl.exec_cmd("sleep 5 && otd-daemon")
    hl.exec_cmd("sleep 10 && ~/.config/bongocat/launch.sh")

    hl.exec_cmd("sleep 5 && ~/.config/hypr/scripts/power-daemon.sh")
    hl.exec_cmd("sleep 10 && ~/.config/hypr/scripts/smart-monitor-power.sh")

    -- Workaround for Dolphin
    hl.exec_cmd("sleep 5 && XDG_MENU_PREFIX=plasma- kbuildsycoca6 --noincremental")
end)