-- [[ Core keymaps ]]
-- Keymaps that need no plugin. Plugin keymaps live next to their plugin
-- (e.g. find keys in plugins/telescope.lua) so removing a plugin removes its keys.
--
-- Every mapping has a `desc`: which-key shows it, and `<leader>?` searches it.
-- See `:help vim.keymap.set()`.

local map = vim.keymap.set

local RESIZE_STEP = 2 -- columns/rows per resize key press

-- Clear search highlighting.
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- Create a new file (asks for the path; missing folders are created).
map('n', '<leader>fn', function() require('config.files').prompt() end, { desc = 'New file' })

-- [[ Splits ]] ------------------------------------------------------------------
-- The letters match stock Vim's <C-w> commands (<C-w>v, <C-w>s, <C-w>q, <C-w>o),
-- so learning these teaches you the built-in keys too.
map('n', '<leader>wv', '<cmd>vsplit<CR>', { desc = 'Vertical split (right)' })
map('n', '<leader>ws', '<cmd>split<CR>', { desc = 'Horizontal split (below)' })
map('n', '<leader>wq', '<cmd>close<CR>', { desc = 'Close this split' })
map('n', '<leader>wo', '<cmd>only<CR>', { desc = 'Close all other splits' })

-- Move between splits with Ctrl + h/j/k/l (works from the file explorer too).
map('n', '<C-h>', '<C-w>h', { desc = 'Focus split left' })
map('n', '<C-j>', '<C-w>j', { desc = 'Focus split below' })
map('n', '<C-k>', '<C-w>k', { desc = 'Focus split above' })
map('n', '<C-l>', '<C-w>l', { desc = 'Focus split right' })

-- Resize the current split with Ctrl + arrow keys.
map('n', '<C-Left>', ('<cmd>vertical resize -%d<CR>'):format(RESIZE_STEP), { desc = 'Split narrower' })
map('n', '<C-Right>', ('<cmd>vertical resize +%d<CR>'):format(RESIZE_STEP), { desc = 'Split wider' })
map('n', '<C-Up>', ('<cmd>resize +%d<CR>'):format(RESIZE_STEP), { desc = 'Split taller' })
map('n', '<C-Down>', ('<cmd>resize -%d<CR>'):format(RESIZE_STEP), { desc = 'Split shorter' })
