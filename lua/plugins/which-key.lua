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

-- which-key only pops up after a prefix key (like <leader>), so keys such as
-- <C-h> or ]c can never show up on their own. To keep ALL custom keys in one
-- place, each group also lists the related keys that don't use <leader>.
-- Picking such a row presses the real key, so the key itself stays defined in
-- one place only (and only keys that exist right now are listed: grd needs a
-- language server, ]c/[c a git file).
local MIRRORED_KEYS = {
  window = { '<C-h>', '<C-j>', '<C-k>', '<C-l>', '<C-Left>', '<C-Right>', '<C-Up>', '<C-Down>' },
  find = { '<Esc>' },
  code = { 'grd' },
  git = { ']c', '[c' },
}

--- First key of a key sequence: ']c' -> ']', 'grd' -> 'g', '<C-h>' -> '<C-h>'.
---@param lhs string
---@return string
local function first_key(lhs) return lhs:match '^<[^>]+>' or lhs:sub(1, 1) end

--- Run the real normal-mode mapping for `lhs` (looked up when pressed).
---@param lhs string
local function run_mapping(lhs)
  local keymap = vim.fn.maparg(lhs, 'n', false, true)
  if keymap.callback then
    keymap.callback()
  elseif keymap.rhs then
    vim.api.nvim_feedkeys(vim.keycode(keymap.rhs), keymap.noremap == 1 and 'n' or 'm', false)
  end
end

--- Build the which-key rows for a group's mirrored keys. Multi-key sequences
--- show their first key, with the real key sequence in the description.
---@param keys string[]
---@return fun(): wk.Spec[]
local function mirror(keys)
  return function()
    local rows = {}
    for _, lhs in ipairs(keys) do
      local keymap = vim.fn.maparg(lhs, 'n', false, true)
      if keymap.desc then
        local key = first_key(lhs)
        local desc = key == lhs and keymap.desc or ('%s  (%s)'):format(keymap.desc, lhs)
        table.insert(rows, { key, function() run_mapping(lhs) end, desc = desc })
      end
    end
    return rows
  end
end

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

  -- Group names. Each group's keys are defined in the matching plugin file;
  -- `expand` adds the mirrored keys from MIRRORED_KEYS above.
  spec = {
    { '<leader>f', group = 'find', expand = mirror(MIRRORED_KEYS.find) },
    { '<leader>w', group = 'window', expand = mirror(MIRRORED_KEYS.window) },
    { '<leader>c', group = 'code', mode = { 'n', 'x' }, expand = mirror(MIRRORED_KEYS.code) },
    { '<leader>d', group = 'diagnostics' },
    { '<leader>g', group = 'git', expand = mirror(MIRRORED_KEYS.git) },
    { '<leader>t', group = 'theme' },
    { 'gr', group = 'LSP' },
  },
}
