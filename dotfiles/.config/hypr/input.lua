-- -----------------------------------------------------
-- Input
-- -----------------------------------------------------

hl.config({
    input = {
        kb_layout  = "de",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        numlock_by_default = true,

        follow_mouse = 1,

        sensitivity  = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad     = {
            natural_scroll = true,
        },
    },
})

-- Keyboard 1
hl.device({
    name = "corsair-corsair-gaming-k55-rgb-keyboard",
    kb_layout = "de",
    kb_options = "caps:escape",
})

-- Keyboard 2
hl.device({
    name = "semico---dierya-61se-",
    kb_layout = "us",
    kb_options = "caps:escape",
})
hl.device({
    name = "semico---dierya-61se--consumer-control",
    kb_layout = "us",
    kb_options = "caps:escape",
})
hl.device({
    name = "semico---dierya-61se--system-control",
    kb_layout = "us",
    kb_options = "caps:escape",
})
hl.device({
    name = "semico---dierya-61se--keyboard",
    kb_layout = "us",
    kb_options = "caps:escape",
})

-- Foot pedal
hl.device({
    name = "pcsensor-footswitch-keyboard",
    kb_layout = "de",
    kb_options = "fkeys:basic_13-24",
})

-- Misc
hl.device({
    name = "eee-pc-wmi-hotkeys",
    kb_layout = "de",
})

-- hl.device({
--    name = "hid-0581:011c",
--    kb_layout = "de",
-- })

-- Tablet
hl.device({
    name = "ugtablet-21.5-inch-pendisplay-stylus",
    output = "DP-2",
    transform = -1,
    region_position = "0 0",
    region_size = "1920 1080",
    relative_input = false,
    left_handed = false,
})
hl.device({
    name = "ugtablet-21.5-inch-pendisplay-mouse",
    output = "DP-2",
    transform = -1,
    region_position = "0 0",
    region_size = "1920 1080",
    relative_input = false,
    left_handed = false,
})
