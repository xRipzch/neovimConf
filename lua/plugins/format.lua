-- [[ conform.nvim: formatting ]]
-- Formats on every save, and on demand with <leader>cf.
--   Go     -> goimports (add/remove imports), then gofumpt (stricter gofmt)
--   Python -> ruff: sort imports, then format
--   Lua    -> stylua (settings in .stylua.toml)
-- Other filetypes fall back to the language server's formatter, if any.
-- Check what applies to the current file: `:ConformInfo`.
-- Skip formatting once: `:noautocmd write`.

local FORMAT_TIMEOUT_MS = 1000

local pack = require 'config.pack'
pack.add { pack.gh 'stevearc/conform.nvim' }

local conform = require 'conform'

conform.setup {
  formatters_by_ft = {
    go = { 'goimports', 'gofumpt' },
    python = { 'ruff_organize_imports', 'ruff_format' },
    lua = { 'stylua' },
  },
  default_format_opts = { lsp_format = 'fallback' },
  format_on_save = { timeout_ms = FORMAT_TIMEOUT_MS },
}

vim.keymap.set({ 'n', 'x' }, '<leader>cf', function() conform.format { async = true } end, { desc = 'Format buffer' })
