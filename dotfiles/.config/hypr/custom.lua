-- hl.env("XDG_MENU_PREFIX", "plasma-")
hl.on("hyprland.start", function () 
    hl.exec_cmd("sh -lc 'sleep 2 && kbuildsycoca6 --noincremental'")
end)

hl.on("hyprland.start", function () 
    hl.exec_cmd("sleep 5 && otd-daemon")
    hl.exec_cmd("sleep 10 && ~/.config/bongocat/launch.sh")

    hl.exec_cmd("sleep 5 && ~/.config/hypr/scripts/power-daemon.sh")
    hl.exec_cmd("sleep 10 && ~/.config/hypr/scripts/smart-monitor-power.sh")
end)