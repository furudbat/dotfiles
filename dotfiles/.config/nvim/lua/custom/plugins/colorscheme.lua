return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha", -- Options: latte, frappe, macchiato, mocha
                transparent_background = false,
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    nvimtree = true,
                    treesitter = true,
                    telescope = true,
                    mason = true,
                    which_key = true,
                },
            })
        end,
    },
    {
        'flazz/vim-colorschemes',
        priority = 1000,
        config = function()
          if vim.g.vscode then
	        return
          end
        end,
    },
    {
        'uloco/bluloco.nvim',
        priority = 1000,
        dependencies = { 'rktjmp/lush.nvim' },
        config = function()
            if vim.g.vscode then
                return
            end
        end,
    },
    {
      'projekt0n/github-nvim-theme',
      name = 'github-theme',
      lazy = false, -- make sure we load this during startup if it is your main colorscheme
      priority = 1000, -- make sure to load this before all the other start plugins
      config = function()
        if vim.g.vscode then
            return
        end
        require('github-theme').setup({
          -- ...
        })
      end,
    },
    { 
        'folke/tokyonight.nvim',
        priority = 1000, -- Make sure to load this before all the other start plugins.
        config = function()
            -- don't let LazyVim load a colorscheme, refer https://github.com/LazyVim/LazyVim/discussions/648#discussioncomment-5682446
            if vim.g.vscode then
                return
            end

            ---@diagnostic disable-next-line: missing-fields
            require('tokyonight').setup {
                styles = {
                    comments = { italic = false }, -- Disable italics in comments
                },
            }
        end,
    }
}