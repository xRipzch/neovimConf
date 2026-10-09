-- [[ Options ]]
-- Plain Neovim settings. Look any of them up with `:help 'optionname'`,
-- e.g. `:help 'scrolloff'`.

local SCROLLOFF_LINES = 8 -- keep this many lines visible above/below the cursor
local UPDATE_TIME_MS = 250 -- idle time before CursorHold fires and swap/undo is written
local KEY_TIMEOUT_MS = 350 -- how long to wait for the next key of a mapping (also when which-key pops up)
local INDENT_WIDTH = 4 -- default indent; Go's ftplugin switches to real tabs automatically

local opt = vim.o

-- Line numbers: absolute (1, 2, 3 ... from the top of the file), not relative.
opt.number = true
opt.relativenumber = false

-- Mouse works for clicking/resizing splits/scrolling.
opt.mouse = 'a'

-- Mode is shown in the statusline, so don't repeat it in the command line.
opt.showmode = false

-- Use the system clipboard (needs `wl-clipboard` on Wayland).
-- Scheduled because detecting the clipboard provider can slow startup.
vim.schedule(function() opt.clipboard = 'unnamedplus' end)

-- Files: no swap files, but keep undo history across restarts.
opt.swapfile = false
opt.undofile = true

-- Search: case-insensitive unless the search contains a capital letter.
opt.ignorecase = true
opt.smartcase = true

-- Show substitutions live as you type `:s/foo/bar`.
opt.inccommand = 'split'

-- Indentation defaults (filetype plugins and formatters may override).
opt.expandtab = true
opt.shiftwidth = INDENT_WIDTH
opt.tabstop = INDENT_WIDTH
opt.breakindent = true -- wrapped lines keep their indent

-- UI
opt.termguicolors = true -- 24-bit colors (foot supports them)
opt.signcolumn = 'yes' -- always reserve the sign column, so text doesn't jump
opt.cursorline = true -- highlight the line the cursor is on
opt.scrolloff = SCROLLOFF_LINES
opt.laststatus = 3 -- ONE global statusline, even with many splits
opt.winborder = 'rounded' -- rounded borders on floating windows (hover, diagnostics, ...)
opt.confirm = true -- ask "save changes?" instead of failing on :q with unsaved edits

-- Show tabs and trailing spaces subtly.
opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Timing
opt.updatetime = UPDATE_TIME_MS
opt.timeoutlen = KEY_TIMEOUT_MS

-- New splits open to the right / below (like most editors).
opt.splitright = true
opt.splitbelow = true

-- Disable "remote plugin" providers. They're only for old plugins written in
-- Python/Node/Ruby/Perl (none are used here); this skips their startup checks
-- and their :checkhealth warnings.
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
