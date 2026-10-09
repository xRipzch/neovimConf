-- [[ Autocommands ]]
-- Small automatic behaviours. See `:help lua-guide-autocommands`.

local group = vim.api.nvim_create_augroup('user-core', { clear = true })

-- Briefly highlight yanked (copied) text. Try `yap` in normal mode.
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = group,
  callback = function() vim.hl.on_yank() end,
})
