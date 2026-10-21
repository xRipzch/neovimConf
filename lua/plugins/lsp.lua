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
-- We add `grd` (go to definition), which Neovim doesn't map by default, and
-- <leader>ch to toggle inlay hints (parameter names / types shown inline).
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
        hints = { -- inlay hints, see the toggle at the bottom of this file
          parameterNames = true,
          assignVariableTypes = true,
          compositeLiteralFields = true,
          rangeVariableTypes = true,
        },
      },
    },
  },

  basedpyright = {
    settings = {
      basedpyright = {
        disableOrganizeImports = true, -- ruff organizes imports
        -- 'standard' = pyright's normal checks; basedpyright's default
        -- ('recommended') is very strict for everyday scripts.
        analysis = {
          typeCheckingMode = 'standard',
          inlayHints = { callArgumentNames = true, variableTypes = true, functionReturnTypes = true },
        },
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
        hint = { enable = true, setType = true }, -- inlay hints
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

-- [[ Inlay hints ]]
-- Shown in normal mode only: they are hidden while typing (InsertEnter) and
-- come back on InsertLeave. <leader>ch switches them on/off for good.
local inlay_hints_wanted = true

--- Show or hide inlay hints in every buffer that has a server supporting them.
---@param visible boolean
local function set_inlay_hints(visible) vim.lsp.inlay_hint.enable(visible) end

local function toggle_inlay_hints()
  inlay_hints_wanted = not inlay_hints_wanted
  set_inlay_hints(inlay_hints_wanted)
  vim.notify('Inlay hints ' .. (inlay_hints_wanted and 'on' or 'off'))
end

set_inlay_hints(inlay_hints_wanted)

local inlay_group = vim.api.nvim_create_augroup('user-inlay-hints', { clear = true })
vim.api.nvim_create_autocmd('InsertEnter', {
  group = inlay_group,
  desc = 'Hide inlay hints while typing',
  callback = function() set_inlay_hints(false) end,
})
vim.api.nvim_create_autocmd('InsertLeave', {
  group = inlay_group,
  desc = 'Restore inlay hints in normal mode',
  callback = function() set_inlay_hints(inlay_hints_wanted) end,
})

vim.keymap.set('n', '<leader>ch', toggle_inlay_hints, { desc = 'Toggle inlay hints' })
