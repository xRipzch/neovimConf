-- [[ gitsigns: git changes in the sign column ]]
-- Shows added/changed/deleted lines next to the line numbers, and feeds the
-- branch + diff counts to the statusline.
-- See `:help gitsigns`. To remove: delete this file + its require in init.lua.

local pack = require 'config.pack'
pack.add { pack.gh 'lewis6991/gitsigns.nvim' }

local gitsigns = require 'gitsigns'

gitsigns.setup {
  -- Keymaps are buffer-local: they only exist in files tracked by git.
  on_attach = function(bufnr)
    local function map(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc }) end

    -- ]c / [c is Vim's own "next/previous change" in diff mode; outside diff
    -- mode it jumps between git hunks instead.
    map(']c', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        gitsigns.nav_hunk 'next'
      end
    end, 'Next git change')
    map('[c', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        gitsigns.nav_hunk 'prev'
      end
    end, 'Previous git change')

    map('<leader>gp', gitsigns.preview_hunk, 'Preview change')
    map('<leader>gb', function() gitsigns.blame_line { full = true } end, 'Blame line')
    map('<leader>gr', gitsigns.reset_hunk, 'Reset change')
  end,
}
