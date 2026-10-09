-- [[ which-key: key hints, docked on the right ]]
-- Press <leader> (Space) and pause: a narrow column on the right lists the
-- next keys. Groups (f, w, c, ...) open a second level. <BS> goes back, <Esc> closes.
-- See `:help which-key.nvim-which-key-configuration` (or the README on GitHub).

local PANEL_WIDTH = 38 -- columns, including the border
local PANEL_HEIGHT = -3 -- negative = "screen height minus 3": stays clear of the statusline + command line
local POPUP_DELAY_MS = 350 -- same as 'timeoutlen' in options.lua

local pack = require 'config.pack'
pack.add { pack.gh 'folke/which-key.nvim' }

local wk = require 'which-key'

wk.setup {
  preset = false, -- start from plain defaults; layout is set explicitly below
  delay = POPUP_DELAY_MS,

  -- Hide noise: only show mappings that have a description (all of ours do),
  -- and turn off the built-in help for marks, registers, motions, etc.
  filter = function(mapping) return mapping.desc ~= nil and mapping.desc ~= '' end,
  plugins = {
    marks = false,
    registers = false,
    spelling = { enabled = false },
    presets = {
      operators = false,
      motions = false,
      text_objects = false,
      windows = false,
      nav = false,
      z = false,
      g = false,
    },
  },

  win = {
    -- Dock on the right edge, from the top down. In which-key, a negative
    -- col/row counts from the right/bottom; numbers < 1 are fractions.
    col = -1,
    row = 0,
    width = PANEL_WIDTH,
    height = PANEL_HEIGHT,
    no_overlap = false, -- keep the panel docked even if the cursor is under it
    border = 'rounded',
    padding = { 1, 1 },
    title = true,
    title_pos = 'center',
  },
  -- Minimum column width ~ the panel width, so entries form ONE vertical
  -- column (one per row) instead of being spread over several columns.
  layout = { width = { min = PANEL_WIDTH - 8 }, spacing = 1 },

  -- Nerd Font icons next to entries (your font has them).
  icons = { mappings = true },

  -- Group names. Each group's keys are defined in the matching plugin file.
  spec = {
    { '<leader>f', group = 'find' },
    { '<leader>w', group = 'window' },
    { '<leader>c', group = 'code', mode = { 'n', 'x' } },
    { '<leader>d', group = 'diagnostics' },
    { '<leader>g', group = 'git' },
    { '<leader>t', group = 'theme' },
    { 'gr', group = 'LSP' },
  },
}
