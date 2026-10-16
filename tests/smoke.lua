-- Smoke tests for this config. Run from the config directory:
--   nvim --headless -c 'luafile tests/smoke.lua'
-- Exit code = number of failed checks (0 = all passed).

-- `-c` runs before VimEnter, but some plugins (noice) finish setting up on
-- VimEnter. Re-run this file once startup is complete.
if vim.v.vim_did_enter == 0 then
  local script = debug.getinfo(1, 'S').source:sub(2)
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      vim.schedule(function() dofile(script) end)
    end,
  })
  return
end

local LSP_ATTACH_TIMEOUT_MS = 20000
local POLL_INTERVAL_MS = 100
local MAX_CUSTOM_KEYMAPS = 30

local failures = 0
local function check(name, ok, detail)
  if ok then
    io.stdout:write('ok   ' .. name .. '\n')
  else
    failures = failures + 1
    io.stdout:write('FAIL ' .. name .. (detail and (' -- ' .. tostring(detail)) or '') .. '\n')
  end
end

--- Run `fn` and record an error as a failure instead of aborting the suite.
local function section(name, fn)
  local ok, err = pcall(fn)
  if not ok then check(name .. ' (raised error)', false, err) end
end

-- [[ Options ]] -----------------------------------------------------------------
section('options', function()
  local expected = {
    number = true,
    relativenumber = false,
    swapfile = false,
    undofile = true,
    ignorecase = true,
    smartcase = true,
    termguicolors = true,
    cursorline = true,
    signcolumn = 'yes',
    splitright = true,
    splitbelow = true,
    laststatus = 3,
  }
  for name, value in pairs(expected) do
    check('option ' .. name, vim.o[name] == value, ('got %s'):format(vim.inspect(vim.o[name])))
  end
  check('scrolloff > 0', vim.o.scrolloff > 0)
  check('updatetime is fast', vim.o.updatetime <= 300, vim.o.updatetime)
  check('leader is space', vim.g.mapleader == ' ')
end)

-- [[ Global keymaps ]] ------------------------------------------------------------
-- { mode, lhs } for every custom global mapping; each must exist with a desc.
local GLOBAL_KEYMAPS = {
  { 'n', '<Esc>' },
  { 'n', '<C-H>' },
  { 'n', '<C-J>' },
  { 'n', '<C-K>' },
  { 'n', '<C-L>' },
  { 'n', '<C-Left>' },
  { 'n', '<C-Right>' },
  { 'n', '<C-Up>' },
  { 'n', '<C-Down>' },
  { 'n', ' wv' },
  { 'n', ' ws' },
  { 'n', ' wq' },
  { 'n', ' wo' },
  { 'n', ' e' },
  { 'n', ' ff' },
  { 'n', ' fg' },
  { 'n', ' fb' },
  { 'n', ' fr' },
  { 'n', ' fh' },
  { 'n', ' ft' },
  { 'n', ' ?' },
  { 'n', ' cf' },
  { 'n', ' dd' },
  { 'n', ' tt' },
}
-- Buffer-local ones, checked later: grd (LSP), ]c [c <leader>gp gb gr (git).
local BUFFER_KEYMAP_COUNT = 6

section('keymaps', function()
  for _, km in ipairs(GLOBAL_KEYMAPS) do
    local info = vim.fn.maparg(km[2], km[1], false, true)
    local has_desc = type(info) == 'table' and info.desc ~= nil and info.desc ~= ''
    check(('keymap %s %s has desc'):format(km[1], km[2]), has_desc, vim.inspect(info.desc))
  end
  local total = #GLOBAL_KEYMAPS + BUFFER_KEYMAP_COUNT
  check(('custom keymaps <= %d'):format(MAX_CUSTOM_KEYMAPS), total <= MAX_CUSTOM_KEYMAPS, total)
end)

-- [[ Plugin configuration ]] -------------------------------------------------------
section('which-key', function()
  local opts = require('which-key.config').options
  check('which-key docked right', opts.win.col == -1 and opts.win.row == 0, vim.inspect { opts.win.col, opts.win.row })
  check('which-key narrow width', opts.win.width >= 35 and opts.win.width <= 40, opts.win.width)
  check('which-key no overlap shifting', opts.win.no_overlap == false)
  check('which-key delay 300-400ms', opts.delay >= 300 and opts.delay <= 400, opts.delay)
end)

section('noice', function()
  local opts = require('noice.config').options
  check('noice cmdline on', opts.cmdline.enabled and opts.cmdline.view == 'cmdline_popup')
  check('noice messages off', opts.messages.enabled == false)
  check('noice notify off', opts.notify.enabled == false)
  check('noice popupmenu off', opts.popupmenu.enabled == false)
  check('noice lsp off', not (opts.lsp.hover.enabled or opts.lsp.signature.enabled or opts.lsp.progress.enabled or opts.lsp.message.enabled))
  check('vim.notify not replaced', not tostring(debug.getinfo(vim.notify, 'S').source):find 'noice')
  check('no nvim-notify installed', not pcall(require, 'notify'))
end)

section('blink.cmp', function()
  local config = require 'blink.cmp.config'
  check('signature help on', config.signature.enabled == true)
  check('docs auto-show', config.completion.documentation.auto_show == true)
  check('<C-s> mapped in blink', config.keymap['<C-s>'] ~= nil)
end)

section('conform', function()
  local conform = require 'conform'
  check('go formatters', vim.deep_equal(conform.formatters_by_ft.go, { 'goimports', 'gofumpt' }), vim.inspect(conform.formatters_by_ft.go))
  check('python formatters', vim.deep_equal(conform.formatters_by_ft.python, { 'ruff_organize_imports', 'ruff_format' }))
end)

section('lsp', function()
  for _, name in ipairs { 'gopls', 'basedpyright', 'ruff', 'lua_ls' } do
    check('lsp enabled: ' .. name, vim.lsp.is_enabled(name))
  end
end)

section('no unwanted UI', function()
  check('no tabline', vim.o.showtabline <= 1)
  check('no winbar', vim.o.winbar == '')
  check('single window at startup (no explorer)', #vim.api.nvim_tabpage_list_wins(0) == 1, #vim.api.nvim_tabpage_list_wins(0))
end)

-- [[ Theme persistence + transparency ]] ------------------------------------------------
section('theme', function()
  local theme = require 'config.theme'
  local state_file = vim.fn.stdpath 'state' .. '/theme.json'
  local backup = vim.fn.filereadable(state_file) == 1 and vim.fn.readfile(state_file) or nil
  local original = vim.deepcopy(theme.get_state())

  vim.cmd.colorscheme 'kanagawa'
  local saved = vim.json.decode(table.concat(vim.fn.readfile(state_file), '\n'))
  check('theme persisted', saved.name == 'kanagawa', vim.inspect(saved))

  if not theme.get_state().transparent then theme.toggle_transparency() end
  check('transparent: Normal has no bg', vim.api.nvim_get_hl(0, { name = 'Normal' }).bg == nil)
  theme.toggle_transparency()
  check('opaque: Normal has bg', vim.api.nvim_get_hl(0, { name = 'Normal' }).bg ~= nil)

  -- Restore whatever the user had before the test.
  if original.transparent ~= theme.get_state().transparent then theme.toggle_transparency() end
  vim.cmd.colorscheme(original.name)
  if backup then
    vim.fn.writefile(backup, state_file)
  else
    vim.fn.delete(state_file)
  end

  local colors = vim.fn.getcompletion('', 'color')
  for _, name in ipairs { 'catppuccin', 'tokyonight', 'kanagawa', 'rose-pine', 'gruvbox', 'nord' } do
    check('theme available: ' .. name, vim.tbl_contains(colors, name))
  end
end)

-- [[ Real buffers: treesitter, statusline, LSP, git ]] ------------------------------------
section('go buffer', function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. '/work/Scripts', 'p')
  vim.fn.writefile({ 'module example', '', 'go 1.22' }, dir .. '/go.mod')
  vim.fn.writefile({ 'package main', '', 'func main() {', '\tprintln("hi")', '}' }, dir .. '/work/Scripts/example.go')
  vim.system({ 'git', 'init', '-q' }, { cwd = dir }):wait()
  vim.system({ 'git', 'add', '.' }, { cwd = dir }):wait()

  vim.cmd.cd(dir)
  vim.cmd.edit 'work/Scripts/example.go'
  local buf = vim.api.nvim_get_current_buf()

  check('treesitter active for go', vim.treesitter.highlighter.active[buf] ~= nil)

  local line = MiniStatusline.active()
  check('statusline: mode', line:find('NORMAL', 1, true) ~= nil, line)
  check('statusline: relative path', line:find('work/Scripts/example.go', 1, true) ~= nil, line)
  check('statusline: not absolute path', line:find(dir, 1, true) == nil, line)
  check('statusline: filetype', line:find(' go', 1, true) ~= nil, line)
  check('statusline: clock', line:find '%d%d:%d%d' ~= nil, line)

  local attached = vim.wait(LSP_ATTACH_TIMEOUT_MS, function() return #vim.lsp.get_clients { bufnr = buf, name = 'gopls' } > 0 end, POLL_INTERVAL_MS)
  check('gopls attached', attached)
  if attached then
    vim.wait(POLL_INTERVAL_MS * 5)
    check('grd mapped', vim.fn.maparg('grd', 'n', false, true).buffer == 1)
  end

  local git_ready = vim.wait(LSP_ATTACH_TIMEOUT_MS, function() return vim.b[buf].gitsigns_head ~= nil end, POLL_INTERVAL_MS)
  check('gitsigns attached', git_ready)
  if git_ready then
    for _, lhs in ipairs { ']c', '[c', ' gp', ' gb', ' gr' } do
      check('git keymap ' .. lhs, vim.fn.maparg(lhs, 'n', false, true).buffer == 1)
    end
  end

end)

section('telescope (lazy)', function()
  check('telescope not loaded at startup', package.loaded['telescope.builtin'] == nil)
  vim.ui.select({ 'one', 'two' }, { prompt = 'test' }, function() end)
  vim.wait(POLL_INTERVAL_MS * 5)
  check('vim.ui.select opens Telescope', vim.bo.filetype == 'TelescopePrompt', vim.bo.filetype)
  vim.api.nvim_feedkeys(vim.keycode '<Esc><Esc>', 'x', false)
  vim.cmd 'stopinsert'
  vim.wait(POLL_INTERVAL_MS * 3)
  check('ui-select replaced the lazy wrapper', debug.getinfo(vim.ui.select, 'S').source:find('ui-select', 1, true) ~= nil)

  -- Cancelling the theme picker must keep the exact variant (kanagawa-dragon
  -- reports itself as plain "kanagawa" in g:colors_name).
  local theme = require 'config.theme'
  local state_file = vim.fn.stdpath 'state' .. '/theme.json'
  local backup = vim.fn.filereadable(state_file) == 1 and vim.fn.readfile(state_file) or nil
  local original = theme.get_state().name
  vim.cmd.colorscheme 'kanagawa-dragon'
  vim.fn.maparg(' ft', 'n', false, true).callback()
  vim.wait(POLL_INTERVAL_MS * 5)
  vim.api.nvim_feedkeys(vim.keycode '<Esc><Esc>', 'x', false)
  vim.cmd 'stopinsert'
  vim.wait(POLL_INTERVAL_MS * 3)
  check('theme picker cancel keeps variant', theme.get_state().name == 'kanagawa-dragon', theme.get_state().name)
  vim.cmd.colorscheme(original)
  if backup then
    vim.fn.writefile(backup, state_file)
  else
    vim.fn.delete(state_file)
  end
end)

--- Filetype of every window in the current tab.
local function window_filetypes()
  return vim.tbl_map(function(win) return vim.bo[vim.api.nvim_win_get_buf(win)].filetype end, vim.api.nvim_tabpage_list_wins(0))
end

section('explorer', function()
  local explorer = vim.fn.maparg(' e', 'n', false, true).callback
  local wait = function() vim.wait(POLL_INTERVAL_MS * 5) end

  explorer() -- closed -> open + focus
  wait()
  check('<leader>e opens and focuses the tree', vim.bo.filetype == 'neo-tree', vim.bo.filetype)
  vim.cmd.wincmd 'l'
  check('<C-l> leaves the tree', vim.bo.filetype ~= 'neo-tree', vim.bo.filetype)
  explorer() -- open but in a file -> focus the tree again
  wait()
  check('<leader>e from a file focuses the open tree', vim.bo.filetype == 'neo-tree', vim.bo.filetype)
  check('...without opening a second tree', #vim.tbl_filter(function(ft) return ft == 'neo-tree' end, window_filetypes()) == 1)
  explorer() -- in the tree -> close
  wait()
  check('<leader>e in the tree closes it', not vim.tbl_contains(window_filetypes(), 'neo-tree'), vim.inspect(window_filetypes()))
  -- Let neo-tree's scheduled callbacks finish; quitting in the same tick as
  -- `close` makes Neovim exit non-zero (a race, not reachable by hand).
  wait()
end)

io.stdout:write(('\n%d failure(s)\n'):format(failures))
vim.cmd(('cquit %d'):format(failures))
