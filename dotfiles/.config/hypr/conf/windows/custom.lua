hl.config({
    general = {
        gaps_in  = 0,
        gaps_out = 0,
        border_size = 2,
        col = {
            active_border   = { colors = {"rgba(fed07cff)" "rgba(b18121ff)"}, angle = 90 },
            inactive_border = on_primary,
            nogroup_border = $on_primary_fixed
            nogroup_border_active = "rgba(b18121ff)"
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
        gaps_workspaces = 0,
    }
})