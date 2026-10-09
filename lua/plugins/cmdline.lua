-- [[ noice.nvim: command-line popup ONLY ]]
-- Typing `:` (or / and ?) opens a small rounded popup near the bottom of the
-- screen instead of the classic bottom line. Everything else noice can do
-- (messages, notifications, LSP hover/signature/progress, completion menu)
-- is switched OFF, so Neovim's own messages, blink.cmp and signature help
-- behave exactly as without noice.
-- To remove: delete this file + its require in init.lua (and nui.nvim if unused).

local POPUP_ROW = '90%' -- vertical position: 0% = top, 100% = bottom of the screen
local POPUP_COL = '50%' -- horizontally centered
local POPUP_WIDTH = 60

local pack = require 'config.pack'
pack.add {
  pack.gh 'MunifTanjim/nui.nvim', -- UI component library noice is built on
  pack.gh 'folke/noice.nvim',
}

require('noice').setup {
  cmdline = {
    enabled = true,
    view = 'cmdline_popup',
  },

  -- Everything below is turned off on purpose.
  messages = { enabled = false }, -- keep Neovim's normal message area
  popupmenu = { enabled = false }, -- keep the native completion menu for : commands
  notify = { enabled = false }, -- no notification popups
  lsp = {
    progress = { enabled = false },
    hover = { enabled = false }, -- K stays the built-in hover
    signature = { enabled = false }, -- signature help comes from blink.cmp
    message = { enabled = false },
    override = {
      ['vim.lsp.util.convert_input_to_markdown_lines'] = false,
      ['vim.lsp.util.stylize_markdown'] = false,
      ['cmp.entry.get_documentation'] = false,
    },
  },

  views = {
    cmdline_popup = {
      position = { row = POPUP_ROW, col = POPUP_COL },
      size = { width = POPUP_WIDTH, height = 'auto' },
      border = { style = 'rounded' },
    },
  },
}
