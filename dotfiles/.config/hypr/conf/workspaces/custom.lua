-- =====================================================
-- Workspace definitions (Using raw absolute numbers)
-- =====================================================

NUM_WORKSPACES_PER_MONITOR = 5

-- Monitor 1 (e.g., HDMI-A-1)
local ws_browser_1 = "6"
local ws_coding_1  = "7"
local ws_gaming_1  = "8"
local ws_music_1   = "9"
local ws_art_1     = "10"

-- Monitor 2 (e.g., DP-1)
local ws_browser_2 = "1"
local ws_coding_2  = "2"
local ws_gaming_2  = "3"
local ws_music_2   = "4"
local ws_art_2     = "5"

-- Monitor 3 (DP-2)
local ws_browser_3 = "11"
local ws_coding_3  = "12"
local ws_gaming_3  = "13"
local ws_music_3   = "14"
local ws_art_3     = "15"

-- Monitor 4 (e.g., DP-3)
local ws_browser_4 = "16"
local ws_coding_4  = "17"
local ws_gaming_4  = "18"
local ws_music_4   = "19"
local ws_art_4     = "20"

-- =====================================================
-- Native Monitor Bindings & Defaults
-- =====================================================

-- Map lists of workspaces to their respective physical outputs
local m1_workspaces = { ws_browser_1, ws_coding_1, ws_gaming_1, ws_music_1, ws_art_1 }
local m2_workspaces = { ws_browser_2, ws_coding_2, ws_gaming_2, ws_music_2, ws_art_2 }
local m4_workspaces = { ws_browser_4, ws_coding_4, ws_gaming_4, ws_music_4, ws_art_4 }

-- Monitor 1 assignments
for _, ws in ipairs(m1_workspaces) do
    hl.workspace_rule({ workspace = ws, monitor = "HDMI-A-1", persistent = true,
        gaps_out = 0,
        gaps_in = 0, 
    })
end
hl.workspace_rule({ workspace = ws_browser_1, monitor = "HDMI-A-1", default = true })

-- Monitor 2 assignments
for _, ws in ipairs(m2_workspaces) do
    hl.workspace_rule({ workspace = ws, monitor = "DP-1", persistent = true,
        gaps_out = 0,
        gaps_in = 0, 
    })
end
hl.workspace_rule({ workspace = ws_browser_2, monitor = "DP-1", default = true })

-- Monitor 4 assignments
for _, ws in ipairs(m4_workspaces) do
    hl.workspace_rule({ workspace = ws, monitor = "DP-3", persistent = true,
        gaps_out = 0,
        gaps_in = 0, 
    })
end
hl.workspace_rule({ workspace = ws_art_4, monitor = "DP-3", default = true })


-- =====================================================
-- Monitor 3 (DP-2) Configuration with Custom Gaps
-- =====================================================

local monitor_3_gaps_in  = 5
local monitor_3_gaps_out = 10
local monitor_3_rounding = 10

local m3_workspaces = { ws_browser_3, ws_coding_3, ws_gaming_3, ws_music_3, ws_art_3 }

for _, ws in ipairs(m3_workspaces) do
    hl.workspace_rule({
        workspace = ws,
        monitor = "DP-2",
        persistent = true,
        gaps_out = monitor_3_gaps_out,
        gaps_in = monitor_3_gaps_in,
    })

    hl.window_rule({
        match = { workspace = ws },
        rounding = monitor_3_rounding,
    })
end

-- Force browser to be the default landing workspace on DP-2
hl.workspace_rule({ workspace = ws_browser_3, monitor = "DP-2", default = true })


-- =====================================================
-- Workspace rules (Smart Gaps)
-- =====================================================

-- No gaps when only one tiled window or fullscreen window is open
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0 })

hl.window_rule({ match = { workspace = "w[tv1]s[false]", float = false }, border_size = 0, rounding = 0 })
hl.window_rule({ match = { workspace = "f[1]s[false]", float = false }, border_size = 0, rounding = 0 })


-- =====================================================
-- Gamemode workspace
-- =====================================================

hl.workspace_rule({
    workspace = ws_gaming_2,
    gaps_out = 0,
    gaps_in = 0,
})

hl.window_rule({
    match = { workspace = ws_gaming_2 },
    no_anim   = true,
    no_shadow = true,
    no_blur   = true,
    rounding  = 0,
    opacity   = 1.0,
})

-- =====================================================
-- Hyprsplit
-- =====================================================

local ok_hs, hs = pcall(require, "hyprsplit")
if ok_hs then
    -- hs.monitor_priority({"HDMI-A-1", "DP-1", "DP-2", "DP-3"})
    hs.config({ num_workspaces = NUM_WORKSPACES_PER_MONITOR })
end