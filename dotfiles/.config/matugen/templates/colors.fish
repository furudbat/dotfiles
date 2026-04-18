# ~/.config/fish/conf.d/magugen_colors.fish
# Magugen theme - Fish 4.x ready
# All colors are set globally (--global) to replace universal scope

# -------------------------
# Basic Colors
# -------------------------
set --global fish_color_autosuggestion {{colors.outline.default.hex_stripped}}
set --global fish_color_cancel -r
set --global fish_color_command {{colors.primary.default.hex_stripped}}
set --global fish_color_comment {{colors.outline.default.hex_stripped}}
set --global fish_color_cwd green
set --global fish_color_cwd_root red
set --global fish_color_end {{colors.tertiary_fixed_dim.default.hex_stripped}}
set --global fish_color_error {{colors.error.default.hex_stripped}}
set --global fish_color_escape {{colors.outline.default.hex_stripped}}
set --global fish_color_history_current --bold
set --global fish_color_host normal
set --global fish_color_host_remote yellow
set --global fish_color_keyword {{colors.primary.default.hex_stripped}}
set --global fish_color_match {{colors.tertiary.default.hex_stripped}}
set --global fish_color_normal normal
set --global fish_color_operator {{colors.tertiary.default.hex_stripped}}
set --global fish_color_option {{colors.inverse_primary.default.hex_stripped}}
set --global fish_color_param {{colors.inverse_primary.default.hex_stripped}}
set --global fish_color_quote {{colors.secondary.default.hex_stripped}}
set --global fish_color_redirection {{colors.inverse_primary.default.hex_stripped}}

# -------------------------
# Search and Selection
# -------------------------
set --global fish_color_search_match 'bryellow' '--background=brblack'
set --global fish_color_selection 'white' '--bold' '--background=brblack'
set --global fish_color_status red
set --global fish_color_user brgreen
set --global fish_color_valid_path --underline

# -------------------------
# Pager Colors
# -------------------------
# Background and secondary colors can be left empty if unused
set --global fish_pager_color_background
set --global fish_pager_color_completion normal
set --global fish_pager_color_description 'B3A06D' 'yellow'
set --global fish_pager_color_prefix normal '--bold' '--underline'
set --global fish_pager_color_progress brwhite '--background=cyan'
set --global fish_pager_color_secondary_background
set --global fish_pager_color_secondary_completion
set --global fish_pager_color_secondary_description
set --global fish_pager_color_secondary_prefix
set --global fish_pager_color_selected_background --background=brblack
set --global fish_pager_color_selected_completion
set --global fish_pager_color_selected_description
set --global fish_pager_color_selected_prefix
