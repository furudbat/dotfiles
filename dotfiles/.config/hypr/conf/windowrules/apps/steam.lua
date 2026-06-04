hl.window_rule({ match = { class = "steam" } }, { float = true, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { class = "steam", title = "Steam" } }, { center = true, size = { 1100, 700 } })
hl.window_rule({ match = { class = "steam.*" } }, { tag = "-default-opacity", opacity = "1 1" })
hl.window_rule({ match = { class = "steam", title = "Friends List" } }, { size = { 460, 800 } })