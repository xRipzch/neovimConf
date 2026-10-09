-- [[ LSP: language servers ]]
-- Neovim has a built-in LSP client. Three pieces make it easy to use:
--   nvim-lspconfig       -> ready-made server settings (cmd, filetypes, root markers)
--   mason.nvim           -> downloads servers/formatters/linters into Neovim's data dir
--   mason-tool-installer -> makes sure everything in MASON_PACKAGES is installed
--
-- Built-in keys (no config needed, available when a server is attached):
--   K hover docs        grn rename           gra code action
--   grr references      gri implementation   grt type definition
--   gO document symbols [d / ]d prev/next diagnostic   <C-w>d diagnostic popup
--   <C-s> (insert mode) signature help
-- We add only `grd` (go to definition), which Neovim doesn't map by default.
--
-- Add a server: add it to SERVERS (lspconfig name) and its Mason package to
-- MASON_PACKAGES, then restart. Server names: `:help lspconfig-all`.
-- Check status: `:checkhealth vim.lsp`, `:Mason`.

local pack = require 'config.pack'
local gh = pack.gh

pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}

-- Mason package names (shown in `:Mason`). Includes formatters/linters used
-- by plugins/format.lua and plugins/lint.lua.
local MASON_PACKAGES = {
  -- language servers
  'gopls',
  'basedpyright',
  'ruff', -- Python linter + formatter, also runs as a language server
  'lua-language-server',
  -- formatters
  'gofumpt',
  'goimports',
  'stylua',
  -- linters
  'golangci-lint',
}

-- Per-server settings, merged on top of nvim-lspconfig's defaults.
-- See `:help vim.lsp.config()`.
---@type table<string, vim.lsp.Config>
local SERVERS = {
  gopls = {
    -- lspconfig also lists 'gotmpl', which Neovim has no filetype for.
    filetypes = { 'go', 'gomod', 'gowork' },
    settings = {
      gopls = {
        semanticTokens = true, -- richer highlighting (types, params, ...)
        gofumpt = true, -- gopls' own formatting/fixes follow gofumpt style
      },
    },
  },

  basedpyright = {
    settings = {
      basedpyright = {
        disableOrganizeImports = true, -- ruff organizes imports
        -- 'standard' = pyright's normal checks; basedpyright's default
        -- ('recommended') is very strict for everyday scripts.
        analysis = { typeCheckingMode = 'standard' },
      },
    },
  },

  ruff = {
    -- basedpyright gives better hover docs; avoid two hover popups.
    on_attach = function(client) client.server_capabilities.hoverProvider = false end,
  },

  -- Lua, tuned for editing this config.
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME }, -- know about the `vim.*` API
        },
        format = { enable = false }, -- stylua formats Lua (plugins/format.lua)
      },
    },
  },
}

require('mason').setup() -- also puts Mason's bin dir on $PATH for conform/nvim-lint
require('mason-tool-installer').setup { ensure_installed = MASON_PACKAGES }

for name, config in pairs(SERVERS) do
  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

-- Diagnostics display. See `:help vim.diagnostic.Opts`.
vim.diagnostic.config {
  severity_sort = true,
  update_in_insert = false,
  virtual_text = true, -- message at the end of the line
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  float = { source = 'if_many' },
  -- Show the full message in a popup after jumping with [d / ]d.
  jump = {
    on_jump = function(_, bufnr) vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false } end,
  },
}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  desc = 'LSP keymaps',
  callback = function(event) vim.keymap.set('n', 'grd', vim.lsp.buf.definition, { buffer = event.buf, desc = 'Go to definition' }) end,
})
