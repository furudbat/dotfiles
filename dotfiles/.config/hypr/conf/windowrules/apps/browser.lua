-- Browser tags and styling.
hl.window_rule({ match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)" } }, { tag = "+chromium-based-browser" })
hl.window_rule({ match = { class = "([fF]irefox|zen|librewolf)" } }, { tag = "+firefox-based-browser" })
hl.window_rule({ match = { tag = "chromium-based-browser" } }, { tag = "-default-opacity", tile = true, opacity = "1.0 0.97" })
hl.window_rule({ match = { tag = "firefox-based-browser" } }, { tag = "-default-opacity", opacity = "1.0 0.97" })

-- Video apps: remove chromium browser tag so they don't get opacity applied.
hl.window_rule({ match = { class = "(chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)" } }, { tag = "-chromium-based-browser" })
hl.window_rule({ match = { class = "(chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)" } }, { tag = "-default-opacity" })

-- Hide screen sharing notification windows.
hl.window_rule({ match = { title = ".*is sharing.*" } }, { workspace = "special silent" })