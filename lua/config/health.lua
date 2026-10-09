-- [[ :checkhealth config ]]
-- Checks the external programs this config relies on. Run with `:checkhealth config`.

local M = {}

local MIN_NVIM_VERSION = '0.12'

-- { executable, why it's needed, Arch package }
local REQUIRED_TOOLS = {
  { 'git', 'installing plugins (vim.pack)', 'git' },
  { 'rg', 'live grep (<leader>fg)', 'ripgrep' },
  { 'fd', 'fast file finding (<leader>ff)', 'fd' },
  { 'make', 'building telescope-fzf-native', 'make' },
  { 'cc', 'compiling treesitter parsers', 'gcc' },
  { 'tree-sitter', 'installing treesitter parsers', 'tree-sitter-cli' },
  { 'curl', 'Mason downloads', 'curl' },
  { 'unzip', 'Mason downloads', 'unzip' },
  { 'wl-copy', 'system clipboard on Wayland', 'wl-clipboard' },
}

local LANGUAGE_TOOLS = {
  { 'go', 'Go toolchain (gopls, goimports, golangci-lint need it)', 'go' },
  { 'python3', 'Python', 'python' },
  { 'npm', 'Mason installs basedpyright via npm', 'npm' },
}

---@param tools string[][]
---@param report_missing fun(msg: string, advice: string)
local function check_tools(tools, report_missing)
  for _, tool in ipairs(tools) do
    local exe, purpose, package = tool[1], tool[2], tool[3]
    if vim.fn.executable(exe) == 1 then
      vim.health.ok(('`%s` found (%s)'):format(exe, purpose))
    else
      report_missing(('`%s` not found: needed for %s'):format(exe, purpose), ('sudo pacman -S %s'):format(package))
    end
  end
end

function M.check()
  vim.health.start 'Neovim version'
  if vim.fn.has('nvim-' .. MIN_NVIM_VERSION) == 1 then
    vim.health.ok(('Neovim %s'):format(tostring(vim.version())))
  else
    vim.health.error(('Neovim %s+ required, found %s'):format(MIN_NVIM_VERSION, tostring(vim.version())))
  end

  vim.health.start 'Required tools'
  check_tools(REQUIRED_TOOLS, function(msg, advice) vim.health.error(msg, advice) end)

  vim.health.start 'Language tools'
  check_tools(LANGUAGE_TOOLS, function(msg, advice) vim.health.warn(msg, advice) end)
end

return M
