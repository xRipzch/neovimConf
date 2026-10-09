-- [[ Treesitter: syntax highlighting + indentation ]]
-- Treesitter parses code into a syntax tree, which gives much more precise
-- highlighting than regex-based Vim syntax. LSP "semantic tokens" are layered
-- on top automatically when a language server supports them (gopls,
-- basedpyright, lua_ls do), so functions/variables/types/keywords/strings/
-- comments each get distinct colors in every theme.
--
-- nvim-treesitter (main branch) installs and updates parsers; Neovim itself
-- does the highlighting. Installing parsers needs the `tree-sitter` CLI
-- (pacman: tree-sitter-cli) and a C compiler.
-- Opening a file of a language not listed below auto-installs its parser.
-- See `:help nvim-treesitter` and `:help treesitter`.

local pack = require 'config.pack'
pack.add { { src = pack.gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

local treesitter = require 'nvim-treesitter'

local PARSERS = {
  'go',
  'gomod',
  'gosum',
  'gowork',
  'python',
  'lua',
  'luadoc',
  'bash',
  'fish',
  'markdown',
  'markdown_inline',
  'json',
  'yaml',
  'toml',
  'html',
  'vim',
  'vimdoc',
  'query',
  'regex', -- used by help pages and the cmdline popup
}

local can_install = vim.fn.executable 'tree-sitter' == 1
if can_install then
  treesitter.install(PARSERS)
else
  vim.notify('treesitter: `tree-sitter` CLI not found, so parsers cannot be installed.\nInstall it with: sudo pacman -S tree-sitter-cli', vim.log.levels.WARN)
end

--- Turn on treesitter highlighting + indentation for a buffer, if a parser exists.
---@param buf integer
---@param language string
local function attach(buf, language)
  if not vim.api.nvim_buf_is_valid(buf) then return end -- buffer closed while installing
  local ok, err = vim.treesitter.language.add(language)
  if not ok then
    -- No parser at all is normal (plain text, ...). A parser file that exists
    -- but fails to load (corrupt, or built for another Neovim) is worth a warning.
    local has_parser_file = #vim.api.nvim_get_runtime_file(('parser/%s.*'):format(language), false) > 0
    if has_parser_file then vim.notify(('treesitter: parser "%s" failed to load: %s (try :TSUpdate)'):format(language, err), vim.log.levels.WARN) end
    return
  end

  vim.treesitter.start(buf, language)

  -- Treesitter-based indentation, when the language has indent rules.
  if vim.treesitter.query.get(language, 'indents') ~= nil then vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end

local available = can_install and treesitter.get_available() or {}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user-treesitter', { clear = true }),
  desc = 'Start treesitter (installing the parser if needed)',
  callback = function(args)
    local buf = args.buf
    local language = vim.treesitter.language.get_lang(args.match)
    if not language then return end

    local installed = treesitter.get_installed 'parsers'
    if vim.tbl_contains(installed, language) or not vim.tbl_contains(available, language) then
      -- Installed, or not managed by nvim-treesitter (e.g. bundled with Neovim).
      attach(buf, language)
    else
      treesitter.install(language):await(function() attach(buf, language) end)
    end
  end,
})
