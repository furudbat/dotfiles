-- Define terminal tag to style them uniformly.
o.window("(Alacritty|kitty|com.mitchellh.ghostty|foot)", { tag = "+terminal" })
o.window({ tag = "terminal" }, { tag = "-default-opacity", opacity = "0.97 0.9" })

-- Scroll nicely in the terminal.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })
