-- [[ Colorschemes ]]
-- Six themes to pick from with <leader>tt (live preview, choice is remembered).
--
-- Why this doesn't slow startup: during startup `vim.pack.add` only puts the
-- themes on the 'runtimepath' (like `:packadd!`). None of their Lua code runs
-- until a theme is actually chosen with `:colorscheme`, so effectively they
-- are lazy-loaded. Only your saved theme is loaded at startup.
--
-- Add a theme: add its repo below and restart. Remove one: delete its line.
-- Transparent background (<leader>tb) works for all of them, see config/theme.lua.

local pack = require 'config.pack'
local gh = pack.gh

pack.add {
  { src = gh 'catppuccin/nvim', name = 'catppuccin' },
  gh 'folke/tokyonight.nvim',
  gh 'rebelot/kanagawa.nvim',
  { src = gh 'rose-pine/neovim', name = 'rose-pine' },
  gh 'ellisonleao/gruvbox.nvim',
  gh 'gbprod/nord.nvim',
}

local theme = require 'config.theme'
theme.setup()

vim.keymap.set('n', '<leader>tb', theme.toggle_transparency, { desc = 'Toggle transparent background' })
