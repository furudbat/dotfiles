-- Float LocalSend and fzf file picker.
hl.window_rule({ match = { class = "(Share|localsend)" } }, { float = true, center = true })
hl.window_rule({ match = { class = "localsend" } }, { size = { 1100, 700 } })