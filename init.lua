--[[
  Personal Neovim config, built from kickstart.nvim (vim.pack edition).

  Load order matters, so everything is required explicitly from here:
    1. config.*   -> plain Neovim settings (no plugins needed)
    2. plugins.*  -> one file per feature; each file installs its plugins with
                     `vim.pack.add` and then configures them.

  To disable a feature: comment out its `require` line below and restart.
  To remove it for good: also delete the file, then run
    :lua vim.pack.del({ 'plugin-name' })
  (see `:help vim.pack`).
--]]

-- Cache compiled Lua modules -> faster startup.
vim.loader.enable()

-- Leader must be set before any keymap that uses <leader> is created.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- 1. Core editor settings -----------------------------------------------------
require 'config.options'
require 'config.keymaps'
require 'config.autocmds'
require 'config.pack' -- plugin-manager helpers + build hooks (before any vim.pack.add)

-- 2. Plugins --------------------------------------------------------------------
require 'plugins.mini' -- icons + autopairs (icons first: other UI plugins use them)
require 'plugins.themes' -- colorschemes + restore your saved theme
require 'plugins.statusline'
require 'plugins.which-key'
require 'plugins.cmdline' -- noice: command-line popup only
require 'plugins.git'
require 'plugins.telescope'
require 'plugins.explorer'
require 'plugins.treesitter'
require 'plugins.lsp'
require 'plugins.completion'
require 'plugins.format'
require 'plugins.lint'
require 'plugins.indent'

-- vim: ts=2 sts=2 sw=2 et
