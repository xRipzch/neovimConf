-- [[ neo-tree: file explorer sidebar ]]
-- <leader>e opens it at the current file, jumps back into it when it's open
-- but you're in a file, and closes it when you're in it. <C-h>/<C-l> also
-- move between the tree and your file. Hidden until asked for; `nvim .`
-- (opening a directory) shows it, like `code .` in VS Code.
-- Inside the tree: <CR> open, a new file/folder (opens new files), d delete,
-- r rename, c copy, m move, H toggle hidden files, / filter, ? show all keys.
-- See `:help neo-tree`. To remove: delete this file + its require in init.lua.

local SIDEBAR_WIDTH = 32

local pack = require 'config.pack'
local gh = pack.gh

pack.add {
  { src = gh 'nvim-neo-tree/neo-tree.nvim', version = vim.version.range '3' },
  gh 'nvim-lua/plenary.nvim',
  gh 'MunifTanjim/nui.nvim',
}

--- Open `path` in the first normal (non-tree, non-floating) window.
---@param path string
local function open_in_editor_window(path)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local is_float = vim.api.nvim_win_get_config(win).relative ~= ''
    if not is_float and vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'neo-tree' then
      vim.api.nvim_set_current_win(win)
      vim.cmd.edit(vim.fn.fnameescape(path))
      return
    end
  end
  vim.cmd.vsplit(vim.fn.fnameescape(path)) -- only the tree is open
end

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
    commands = {
      -- Replace neo-tree's `add` (key `a`): same prompt, but a new FILE is
      -- also opened, like in VS Code. New folders just appear in the tree.
      add = function(state)
        local common = require 'neo-tree.sources.common.commands'
        local filesystem = require 'neo-tree.sources.filesystem'
        common.add(state, function(path)
          filesystem.show_new_children(state, path)
          if vim.fn.isdirectory(path) == 0 then open_in_editor_window(path) end
        end)
      end,
    },
    follow_current_file = { enabled = true }, -- highlight the file you're editing
    use_libuv_file_watcher = true, -- refresh automatically when files change on disk
    hijack_netrw_behavior = 'open_default', -- `nvim somedir` opens the sidebar
    filtered_items = {
      hide_dotfiles = false, -- show .env, .gitignore, ... (dimmed)
      hide_gitignored = true,
    },
  },
}

--- In the tree: close it. Anywhere else: open it (or jump into it if it's
--- already open) with the current file selected.
local function explorer()
  if vim.bo.filetype == 'neo-tree' then
    vim.cmd 'Neotree close'
  else
    vim.cmd 'Neotree reveal'
  end
end

vim.keymap.set('n', '<leader>e', explorer, { desc = 'Explorer (open / focus / close)' })
