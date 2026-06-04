-- =====================================================
-- Window rules
-- =====================================================

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Apply default opacity after apps have had a chance to opt out.
hl.window_rule({ tag = "default-opacity" }, { opacity = "1 1" })

-- Fix some dragging issues with XWayland.
hl.window_rule({
  match = {
    class = "^$",
    title = "^$",
    
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

-- XWayland highlighting
hl.window_rule({
    name = "xwayland",

    match = {
        xwayland = true,
    },

    border_size = 3,
    border_color = { colors = { on_error, on_tertiary }, angle = 90 },
})

-- =====================================================
-- Misc
-- =====================================================

-- hl.misc({
--     focus_on_activate = true,
-- })

-- =====================================================
-- App-specific rules
-- =====================================================

require("conf.windowrules.apps._rules")
require("conf.windowrules.apps.browser")
require("conf.windowrules.apps.hyprshot")
require("conf.windowrules.apps.jetbrains")
require("conf.windowrules.apps.keepass")
require("conf.windowrules.apps.localsend")
require("conf.windowrules.apps.moonlight")
require("conf.windowrules.apps.qemu")
require("conf.windowrules.apps.retroarch")
require("conf.windowrules.apps.steam")
require("conf.windowrules.apps.telegram")
require("conf.windowrules.apps.terminals")