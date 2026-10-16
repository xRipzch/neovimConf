-- [[ Telescope: fuzzy finder ]]
-- All finders live under <leader>f. Inside a picker: type to filter,
-- <C-n>/<C-p> or arrows to move, <CR> to open, <C-v>/<C-x> to open in a
-- vertical/horizontal split, <Esc> to close, <C-/> for all picker keys.
-- See `:help telescope`. To remove: delete this file + its require in init.lua.

local pack = require 'config.pack'
local gh = pack.gh

local specs = {
  gh 'nvim-lua/plenary.nvim', -- Lua helper library (also used by neo-tree)
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim', -- code-action menus etc. use Telescope too
}
-- Native C sorter = much faster filtering. Needs `make` + a C compiler.
if vim.fn.executable 'make' == 1 then table.insert(specs, gh 'nvim-telescope/telescope-fzf-native.nvim') end
pack.add(specs)

-- Telescope's Lua code is only loaded the first time you open a picker (or a
-- menu like code actions), which keeps ~20 ms off every startup.
local is_set_up = false

--- Load an extension, warning (not crashing) when it isn't available.
---@param name string
local function load_extension(name)
  local ok, err = pcall(require('telescope').load_extension, name)
  if not ok then vim.notify(('telescope: extension "%s" not loaded: %s'):format(name, err), vim.log.levels.WARN) end
end

local function setup_telescope()
  if is_set_up then return end
  is_set_up = true

  require('telescope').setup {
    pickers = {
      -- The theme picker previews each theme live as you move through the list.
      colorscheme = { enable_preview = true, ignore_builtins = true },
    },
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }
  if vim.fn.executable 'make' == 1 then load_extension 'fzf' end
  load_extension 'ui-select' -- replaces vim.ui.select with a Telescope menu
end

--- A keymap callback that opens Telescope's builtin picker `name`.
---@param name string see `:help telescope.builtin`
local function picker(name)
  return function()
    setup_telescope()
    require('telescope.builtin')[name]()
  end
end

-- Menus via vim.ui.select (e.g. `gra` code actions) set Telescope up on first
-- use; ui-select then takes over. If it failed to load, use Neovim's own menu.
local native_ui_select = vim.ui.select
local function lazy_ui_select(...)
  setup_telescope()
  if vim.ui.select == lazy_ui_select then vim.ui.select = native_ui_select end
  return vim.ui.select(...)
end
vim.ui.select = lazy_ui_select

local map = vim.keymap.set

map('n', '<leader>ff', picker 'find_files', { desc = 'Find files' })
map('n', '<leader>fg', picker 'live_grep', { desc = 'Find by grep (text in files)' })
map('n', '<leader>fb', picker 'buffers', { desc = 'Find open buffers' })
map('n', '<leader>fr', picker 'oldfiles', { desc = 'Find recent files' })
map('n', '<leader>fh', picker 'help_tags', { desc = 'Find help' })
map('n', '<leader>tt', function()
  require('config.theme').sync_colors_name() -- so cancelling restores the exact variant
  picker 'colorscheme'()
end, { desc = 'Pick theme (live preview)' })
map('n', '<leader>?', picker 'keymaps', { desc = 'Search all keymaps' })
map('n', '<leader>dd', picker 'diagnostics', { desc = 'Diagnostics list' })
