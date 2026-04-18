return {
  "nvim-treesitter/nvim-treesitter-context",
  event = "VeryLazy",
  config = function()
    require("treesitter-context").setup({
      enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
      max_lines = 0,            -- How many lines the window should span. Values <= 0 mean no limit.
      trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      mode = 'cursor',          -- Line used to calculate context. Choices: 'cursor', 'topline'
      separator = nil,          -- Separator between context and content. Can be a string or `nil`.
    })
  end,
}