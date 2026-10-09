-- [[ neo-tree: file explorer sidebar ]]
-- <leader>e toggles it and jumps to the current file. Hidden until asked for;
-- `nvim .` (opening a directory) shows it, like `code .` in VS Code.
-- Inside the tree: <CR> open, a add, d delete, r rename, c copy, m move,
-- H toggle hidden files, / filter, ? show all keys.
-- See `:help neo-tree`. To remove: delete this file + its require in init.lua.

local SIDEBAR_WIDTH = 32

local pack = require 'config.pack'
local gh = pack.gh

pack.add {
  { src = gh 'nvim-neo-tree/neo-tree.nvim', version = vim.version.range '3' },
  gh 'nvim-lua/plenary.nvim',
  gh 'MunifTanjim/nui.nvim',
}

require('neo-tree').setup {
  close_if_last_window = true, -- quit the tree when it's the only window left
  popup_border_style = 'rounded',
  window = {
    position = 'left',
    width = SIDEBAR_WIDTH,
    mappings = {
      -- neo-tree maps <Space> by default; free it so <leader> keys work in the tree.
      ['<space>'] = 'none',
    },
  },
  filesystem = {
    follow_current_file = { enabled = true }, -- highlight the file you're editing
    use_libuv_file_watcher = true, -- refresh automatically when files change on disk
    hijack_netrw_behavior = 'open_default', -- `nvim somedir` opens the sidebar
    filtered_items = {
      hide_dotfiles = false, -- show .env, .gitignore, ... (dimmed)
      hide_gitignored = true,
    },
  },
}

vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle reveal<CR>', { desc = 'Explorer (toggle)' })
