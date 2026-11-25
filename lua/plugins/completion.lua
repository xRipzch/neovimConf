-- [[ blink.cmp: autocompletion + signature help ]]
-- Completion menu keys ('default' preset, same idea as Vim's built-in completion):
--   <C-n>/<C-p> or arrows  move      <C-y> accept ("yes")    <C-e> close
--                          (<C-y> also accepts a Copilot suggestion when no menu is open)
--   <C-space>              open menu / toggle docs
--   <Tab>/<S-Tab>          jump between snippet placeholders (else a normal Tab)
--   <C-s> or <C-k>         toggle function signature help
-- See `:help blink-cmp-config` (or https://cmp.saghen.dev).

local DOCS_DELAY_MS = 300 -- show docs for the selected item after this long

local pack = require 'config.pack'
-- Follow the stable 1.x releases.
pack.add { { src = pack.gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }

require('blink.cmp').setup {
  keymap = {
    preset = 'default',
    -- Neovim's built-in insert-mode <C-s> is signature help; point it at
    -- blink's signature window so both look the same.
    ['<C-s>'] = { 'show_signature', 'hide_signature', 'fallback' },
    -- "Yes": accept the menu item when the menu is open, else a Copilot
    -- suggestion when one is shown (plugins/copilot.lua). Tab stays free
    -- for indenting, since a suggestion is shown most of the time.
    ['<C-y>'] = { 'select_and_accept', function() return require('plugins.copilot').accept() end, 'fallback' },
    -- Arrows move in the menu when it is open, else cycle Copilot
    -- suggestions when one is shown, else move the cursor.
    ['<Up>'] = { 'select_prev', function() return require('plugins.copilot').previous() end, 'fallback' },
    ['<Down>'] = { 'select_next', function() return require('plugins.copilot').next() end, 'fallback' },
  },

  appearance = { nerd_font_variant = 'mono' },

  completion = {
    -- Docs (e.g. a function's description) next to the selected item.
    documentation = { auto_show = true, auto_show_delay_ms = DOCS_DELAY_MS },
  },

  -- Signature popup while typing a function call's arguments; the active
  -- parameter is highlighted.
  signature = { enabled = true },

  -- Where completions come from. Snippets offered by language servers
  -- (e.g. Go's `for` loops) arrive via 'lsp' and use Neovim's built-in
  -- `vim.snippet`, so no snippet plugin is needed.
  sources = { default = { 'lsp', 'path', 'buffer' } },

  -- Fast, typo-tolerant Rust matcher. blink.cmp downloads a prebuilt binary
  -- for its release tag on first start; until then (or if the download
  -- fails) it falls back to a pure-Lua matcher and warns once.
  fuzzy = { implementation = 'prefer_rust_with_warning' },
}
