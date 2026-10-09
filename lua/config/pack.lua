-- [[ Plugin manager: vim.pack ]]
-- `vim.pack` is Neovim's built-in plugin manager (0.12+); kickstart uses it too.
--   Install:  add a spec to a `pack.add { ... }` call and restart (`:restart`)
--   Update:   :lua vim.pack.update()      (review, then `:write` to apply)
--   Inspect:  :lua vim.pack.update(nil, { offline = true })
--   Remove:   delete the spec, restart, then :lua vim.pack.del({ 'name' })
-- Exact plugin versions are pinned in `nvim-pack-lock.json` next to init.lua.
-- See `:help vim.pack`.

local M = {}

local BUILD_TIMEOUT_MS = 120000 -- give up on a hung build step after 2 minutes
local TIMEOUT_EXIT_CODE = 124 -- what vim.system reports when it kills a timed-out process

--- Turn 'owner/repo' into a full GitHub URL.
---@param repo string
---@return string
function M.gh(repo) return 'https://github.com/' .. repo end

--- Install (if missing) and load plugins.
--- `confirm = false` skips the "install these plugins?" prompt, which would
--- otherwise appear once per file on the very first start.
---@param specs (string|vim.pack.Spec)[]
---@param opts? vim.pack.keyset.add
function M.add(specs, opts) vim.pack.add(specs, vim.tbl_extend('force', { confirm = false }, opts or {})) end

--- Run a build command synchronously and report failures loudly.
---@param name string plugin name (for the error message)
---@param cmd string[]
---@param cwd string
local function run_build(name, cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd, text = true }):wait(BUILD_TIMEOUT_MS)
  if result.code == 0 then return end
  if result.code == TIMEOUT_EXIT_CODE then
    vim.notify(('Build for %s timed out after %d s'):format(name, BUILD_TIMEOUT_MS / 1000), vim.log.levels.ERROR)
    return
  end
  local output = (result.stderr ~= '' and result.stderr) or result.stdout or ''
  if output == '' then output = 'no output from build command' end
  vim.notify(('Build failed for %s (exit %d):\n%s'):format(name, result.code, output), vim.log.levels.ERROR)
end

-- Build steps some plugins need after install/update. Must be registered
-- before the first `vim.pack.add`, which is why init.lua requires this early.
-- See `:help vim.pack-events`.
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('user-pack-build', { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= 'install' and kind ~= 'update' then return end

    if name == 'telescope-fzf-native.nvim' then
      if vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
      else
        vim.notify('telescope-fzf-native: `make` not found, skipping build', vim.log.levels.WARN)
      end
    elseif name == 'nvim-treesitter' and kind == 'update' then
      -- Parsers must match the plugin version, so update them together.
      if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
      vim.cmd 'TSUpdate'
    end
  end,
})

return M
