-- =====================================================
-- Workspace definitions
-- =====================================================

local ws_browser_1 = "6"
local ws_coding_1  = "7"
local ws_gaming_1  = "8"
local ws_music_1   = "9"
local ws_art_1     = "10"

local ws_browser_2 = "1"
local ws_coding_2  = "2"
local ws_gaming_2  = "3"
local ws_music_2   = "4"
local ws_art_2     = "5"

local ws_browser_3 = "11"
local ws_coding_3  = "12"
local ws_gaming_3  = "13"
local ws_music_3   = "14"
local ws_art_3     = "15"

local ws_browser_4 = "16"
local ws_coding_4  = "17"
local ws_gaming_4  = "18"
local ws_music_4   = "19"
local ws_art_4     = "20"

-- =====================================================
-- Hyprsplit
-- =====================================================

local ok_hs, hs = pcall(require, "hyprsplit")
if ok_hs then
    hs.monitor_priority({"HDMI-A-1", "DP-1", "DP-2", "DP-3"})
    hs.config({ num_workspaces = 5 })
end

-- =====================================================
-- Workspace rules
-- =====================================================

-- hl.workspace_rule({
--     workspace = "r[1-20]",
--     gaps_out = 0,
--     gaps_in = 0,
-- })

-- Smart gaps / no gaps when only one tiled or fullscreen window
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, rounding = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, rounding = 0 })

-- =====================================================
-- Gamemode workspace
-- =====================================================

hl.window_rule({
    name = "gamemode",
    match = {
        workspace = ws_gaming_2,
    },

    no_anim   = true,
    no_shadow = true,
    no_blur   = true,
    rounding  = 0,
    opacity   = 1.0,
})

hl.workspace_rule({
    workspace = ws_gaming_2,
    gaps_out = 0,
    gaps_in = 0,
})

-- =====================================================
-- Monitor 3 (DP-2)
-- =====================================================

local monitor_3_gaps_in  = 5
local monitor_3_gaps_out = 10
local monitor_3_rounding = 10

for _, ws in ipairs({
    ws_browser_3,
    ws_coding_3,
    ws_gaming_3,
    ws_music_3,
    ws_art_3,
}) do
    hl.workspace_rule({
        workspace = ws,
        monitor = "DP-2",
        persistent = true,
        gaps_out = monitor_3_gaps_out,
        gaps_in = monitor_3_gaps_in,
    })

    hl.window_rule({
        name = "rounding-" .. ws,
        match = {
            workspace = ws,
        },

        rounding = monitor_3_rounding,
    })
end

hl.workspace_rule({
    workspace = ws_browser_3,
    monitor = "DP-2",
    persistent = true,
    default = true,
    gaps_out = monitor_3_gaps_out,
    gaps_in = monitor_3_gaps_in,
})


-- =====================================================
-- Default workspaces
-- =====================================================

hl.workspace_rule({
    workspace = ws_browser_1,
    default = true,
})

hl.workspace_rule({
    workspace = ws_browser_2,
    default = true,
})

hl.workspace_rule({
    workspace = ws_browser_3,
    default = true,
})

hl.workspace_rule({
    workspace = ws_art_4,
    default = true,
})