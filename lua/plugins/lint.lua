-- [[ nvim-lint: extra linters ]]
-- Runs golangci-lint (many Go linters in one tool) after each save of a Go file.
-- Python linting comes from the ruff language server (plugins/lsp.lua), so it
-- is NOT added here; running ruff twice would show every warning twice.
-- Add a linter: put its name in LINTERS_BY_FT (names: `:help nvim-lint`,
-- or the files in nvim-lint's lua/lint/linters/ directory).

local pack = require 'config.pack'
pack.add { pack.gh 'mfussenegger/nvim-lint' }

local lint = require 'lint'

local LINTERS_BY_FT = {
  go = { 'golangcilint' },
}
lint.linters_by_ft = LINTERS_BY_FT

local GOLANGCI_LINT_MODULE = 'lint.linters.golangcilint'
-- golangci-lint repeats compile errors as "typecheck" issues, which gopls
-- already reports; drop them so every error shows up once.
local DUPLICATE_GO_SOURCE = 'typecheck'
local is_golangcilint_ready = false

--- Prepare golangci-lint on the first Go save (not at startup): loading its
--- definition runs `golangci-lint version` to pick the right arguments.
---@return boolean ready
local function prepare_golangcilint()
  if is_golangcilint_ready then return true end

  local linter = lint.linters.golangcilint
  if linter.args == nil then
    -- Loaded before golangci-lint was installed, so arguments are missing.
    -- Forget the cached definition and load it again now that it exists.
    package.loaded[GOLANGCI_LINT_MODULE] = nil
    linter = lint.linters.golangcilint
  end
  if linter.args == nil then
    vim.notify('lint: could not detect golangci-lint version; Go linting disabled for now', vim.log.levels.WARN)
    return false
  end

  local parse = linter.parser
  linter.parser = function(output, bufnr, cwd)
    return vim.tbl_filter(function(d) return d.source ~= DUPLICATE_GO_SOURCE end, parse(output, bufnr, cwd))
  end
  is_golangcilint_ready = true
  return true
end

-- Linters already warned about this session, so the warning shows once.
local warned_missing = {}

--- Names of this filetype's linters whose executable is installed.
--- Missing ones (e.g. Mason still installing) are reported once, not every save.
---@param filetype string
---@return string[]
local function available_linters(filetype)
  local result = {}
  for _, name in ipairs(LINTERS_BY_FT[filetype] or {}) do
    local linter = lint.linters[name]
    if type(linter) == 'function' then linter = linter() end -- some linters are built lazily
    local cmd = type(linter) == 'table' and linter.cmd or nil
    if type(cmd) == 'function' then cmd = cmd() end
    if cmd and vim.fn.executable(cmd) == 1 then
      table.insert(result, name)
    elseif not warned_missing[name] then
      warned_missing[name] = true
      vim.notify(('lint: "%s" is not installed (check :Mason)'):format(name), vim.log.levels.WARN)
    end
  end
  return result
end

vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('user-lint', { clear = true }),
  desc = 'Run linters after saving',
  callback = function(args)
    if not vim.bo[args.buf].modifiable then return end
    local names = available_linters(vim.bo[args.buf].filetype)
    if vim.tbl_contains(names, 'golangcilint') and not prepare_golangcilint() then
      names = vim.tbl_filter(function(name) return name ~= 'golangcilint' end, names)
    end
    if #names == 0 then return end
    -- try_lint works on the current buffer; after `:wa` that may be another one.
    vim.api.nvim_buf_call(args.buf, function() lint.try_lint(names) end)
  end,
})
