-- [[ Theme persistence + transparency ]]
-- Remembers the last colorscheme (however it was chosen: <leader>tt, or
-- `:colorscheme name`) and whether the background is transparent, and restores
-- both on startup. State is a tiny JSON file in Neovim's state directory.

local M = {}

local STATE_FILE = vim.fn.stdpath 'state' .. '/theme.json'
local DEFAULT_THEME = 'tokyonight-night'
local BUILTIN_FALLBACK_THEME = 'habamax' -- ships with Neovim, always available

-- Groups whose background is removed in transparent mode, so foot's own
-- (translucent) background shows through. Floating windows (popups, pickers)
-- keep their background on purpose: transparent popups are hard to read.
local TRANSPARENT_GROUPS = {
  'Normal',
  'NormalNC',
  'SignColumn',
  'LineNr',
  'FoldColumn',
  'EndOfBuffer',
  'MsgArea',
  'NeoTreeNormal',
  'NeoTreeNormalNC',
  'NeoTreeEndOfBuffer',
}

---@class ThemeState
---@field name string colorscheme name
---@field transparent boolean

---@type ThemeState
local DEFAULT_STATE = { name = DEFAULT_THEME, transparent = false }

---@type ThemeState
local state = DEFAULT_STATE

-- True while a fallback theme loads because the saved one failed, so the
-- fallback doesn't overwrite your real choice on disk.
local is_loading_fallback = false

local function warn(msg) vim.notify('theme: ' .. msg, vim.log.levels.WARN) end

---@return ThemeState
local function read_state()
  local file = io.open(STATE_FILE, 'r')
  if not file then return DEFAULT_STATE end -- first run: nothing saved yet

  local content = file:read '*a'
  file:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= 'table' then
    warn(('could not parse %s (%s); using defaults'):format(STATE_FILE, tostring(decoded)))
    return DEFAULT_STATE
  end

  return {
    name = type(decoded.name) == 'string' and decoded.name or DEFAULT_THEME,
    transparent = decoded.transparent == true,
  }
end

---@param new_state ThemeState
local function write_state(new_state)
  local file, open_err = io.open(STATE_FILE, 'w')
  if not file then
    warn(('could not save %s: %s'):format(STATE_FILE, open_err))
    return
  end
  local ok, write_err = file:write(vim.json.encode(new_state))
  file:close()
  if not ok then warn(('could not write %s: %s'):format(STATE_FILE, write_err)) end
end

--- Remove the background color from the groups in TRANSPARENT_GROUPS.
local function apply_transparency()
  for _, group in ipairs(TRANSPARENT_GROUPS) do
    local current = vim.api.nvim_get_hl(0, { name = group, link = false })
    -- Only touch groups the theme defines; creating empty ones would hide
    -- the plugin's own default links.
    if next(current) ~= nil then vim.api.nvim_set_hl(0, group, vim.tbl_extend('force', current, { bg = 'NONE', ctermbg = 'NONE' })) end
  end
end

--- Load a colorscheme, returning false (with a warning) instead of erroring.
---@param name string
---@return boolean
local function try_colorscheme(name)
  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then warn(('could not load "%s": %s'):format(name, err)) end
  return ok
end

--- Toggle transparent background and remember the choice.
function M.toggle_transparency()
  state = vim.tbl_extend('force', state, { transparent = not state.transparent })
  write_state(state)
  -- Reload the theme so turning transparency OFF restores its backgrounds.
  -- Use our saved name, not vim.g.colors_name: some themes report only their
  -- family name there (kanagawa-dragon sets it to "kanagawa").
  try_colorscheme(state.name)
end

---@return ThemeState
function M.get_state() return state end

--- Make `:colorscheme` (no argument) report the exact saved variant.
--- Some themes set g:colors_name to their family name only (kanagawa-dragon
--- -> "kanagawa"); the theme picker restores that name when cancelled, which
--- would silently switch you to the default variant.
function M.sync_colors_name() vim.g.colors_name = state.name end

function M.setup()
  state = read_state()

  -- Runs after ANY colorscheme is loaded: re-apply transparency and save the
  -- name. While previewing in the picker this fires per theme; cancelling the
  -- picker restores (and therefore saves) the original theme again; see
  -- M.sync_colors_name for why the exact variant survives that.
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('user-theme', { clear = true }),
    desc = 'Persist colorscheme and apply transparency',
    callback = function(ev)
      if state.transparent then apply_transparency() end
      if is_loading_fallback then return end
      state = vim.tbl_extend('force', state, { name = ev.match })
      write_state(state)
    end,
  })

  if try_colorscheme(state.name) then return end
  is_loading_fallback = true
  if state.name == DEFAULT_THEME or not try_colorscheme(DEFAULT_THEME) then try_colorscheme(BUILTIN_FALLBACK_THEME) end
  is_loading_fallback = false
end

return M
