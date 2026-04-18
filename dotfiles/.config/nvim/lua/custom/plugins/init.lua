-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

return {
  -- Godot (GDScript)
  {
    "habamax/vim-godot",
    ft = "gdscript",
  },

  -- Hyprland syntax
  {
		"theRealCarneiro/hyprland-vim-syntax",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = "hypr",
	},

  -- Mermaid and markdown enhancements
  {
    "jakewvincent/mkdnflow.nvim",
    ft = "markdown",
    opts = {},
  },

  -- Optional: better markdown headers and code block UI
  {
    "lukas-reineke/headlines.nvim",
    dependencies = "nvim-treesitter/nvim-treesitter",
    ft = "markdown",
    opts = {},
  },

  -- Vim plugin for Ledger (https://www.ledger-cli.org/)
  {
    "ledger/vim-ledger",
    ft = "ledger",
  }
}