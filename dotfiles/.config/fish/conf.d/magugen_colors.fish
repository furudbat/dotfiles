# ~/.config/fish/conf.d/magugen_colors.fish
# Magugen theme - Fish 4.x ready
# All colors are set globally (--global) to replace universal scope

# -------------------------
# Basic Colors
# -------------------------
set --global fish_color_autosuggestion 8c9198
set --global fish_color_cancel -r
set --global fish_color_command 98ccf9
set --global fish_color_comment 8c9198
set --global fish_color_cwd green
set --global fish_color_cwd_root red
set --global fish_color_end d1bfe7
set --global fish_color_error ffb4ab
set --global fish_color_escape 8c9198
set --global fish_color_history_current --bold
set --global fish_color_host normal
set --global fish_color_host_remote yellow
set --global fish_color_keyword 98ccf9
set --global fish_color_match d1bfe7
set --global fish_color_normal normal
set --global fish_color_operator d1bfe7
set --global fish_color_option 2a638b
set --global fish_color_param 2a638b
set --global fish_color_quote b8c8d9
set --global fish_color_redirection 2a638b

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
