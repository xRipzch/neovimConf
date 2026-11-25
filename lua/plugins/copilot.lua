-- [[ Copilot: inline suggestions (grey "ghost text", like VS Code) ]]
-- Uses Neovim's built-in inline completion (`:help lsp-inline_completion`)
-- with GitHub's Copilot language server (installed by Mason, see lsp.lua).
-- No plugin needed: nvim-lspconfig ships the 'copilot' server config.
--
-- Keys (insert mode, only while a suggestion is shown; otherwise they
-- behave as usual):
--   <Tab>        accept the whole suggestion (set up in completion.lua, so
--                it falls back to blink's snippet jump / a normal Tab)
--   <C-Right>    accept the next word only
--   <Down>/<Up>  next / previous suggestion (completion.lua; the completion
--                menu goes first when it is open, else the cursor moves)
--
-- First time: open any file, run `:LspCopilotSignIn` and follow the browser
-- steps. Works with the free Copilot plan (https://github.com/settings/copilot).
-- Check status: `:checkhealth vim.lsp`. Sign out: `:LspCopilotSignOut`.

local M = {}

local SERVER = 'copilot'
local INLINE_NAMESPACE = 'nvim.lsp.inline_completion' -- where Neovim draws the ghost text

-- Files Copilot never sees (secrets). Lua patterns matched against the file name.
local PRIVATE_FILE_PATTERNS = {
  '^%.env$',
  '^%.env%.', -- .env.local, .env.production, ...
  '%.pem$',
  '%.key$',
  '^id_rsa',
  '^id_ed25519',
}

--- Whether Copilot may read this file.
---@param path string
---@return boolean
function M.is_allowed(path)
  local name = vim.fs.basename(path)
  for _, pattern in ipairs(PRIVATE_FILE_PATTERNS) do
    if name:find(pattern) then return false end
  end
  return true
end

--- The next piece of `text` to accept with "accept word": a line break plus
--- the next line's indent, or a word (with the spaces before it), or a run
--- of punctuation, or else whatever whitespace is left.
---@param text string
---@return string
function M.next_word(text) return text:match '^\r?\n[ \t]*' or text:match '^[ \t]*[%w_]+' or text:match '^[ \t]*[^%w_%s]+' or text:match '^%s+' or text end

--- Shrink a suggestion so accepting it inserts only its next word.
--- Copilot's items replace a range that starts before the cursor (the part
--- already typed) and may run past it; the new item replaces only up to the
--- cursor, so text after the cursor is kept.
---@param item vim.lsp.inline_completion.Item
---@param bufnr integer
---@param cursor [integer, integer] 0-based row and byte column
---@return vim.lsp.inline_completion.Item
function M.trim_to_next_word(item, bufnr, cursor)
  local text = item.insert_text
  if type(text) ~= 'string' then return item end -- a snippet: accept it whole

  if not item.range then return vim.tbl_extend('force', item, { insert_text = M.next_word(text) }) end

  local start_row, start_col = item.range.start_row, item.range.start_col
  local row, col = cursor[1], cursor[2]
  if row < start_row or (row == start_row and col < start_col) then return item end

  local typed = table.concat(vim.api.nvim_buf_get_text(bufnr, start_row, start_col, row, col, {}), '\n')
  if not vim.startswith(text, typed) then return item end

  return vim.tbl_extend('force', item, {
    insert_text = typed .. M.next_word(text:sub(#typed + 1)),
    range = vim.range(bufnr, start_row, start_col, row, col),
  })
end

--- Whether a suggestion is shown in the current buffer (Neovim draws it as
--- an extmark in this namespace).
---@return boolean
function M.is_visible()
  local ns = vim.api.nvim_get_namespaces()[INLINE_NAMESPACE]
  if not ns then return false end
  return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { limit = 1 }) > 0
end

--- Show another suggestion, `step` places away (wraps around); the hint
--- " (2/3)" after the ghost text tells which one is shown.
---@param step integer
---@return boolean cycled false when no suggestion is shown
local function cycle(step)
  if not M.is_visible() then return false end
  vim.lsp.inline_completion.select { count = step }
  return true
end

---@return boolean cycled
function M.next() return cycle(1) end

---@return boolean cycled
function M.previous() return cycle(-1) end

--- Accept the whole suggestion.
---@return boolean accepted false when no suggestion is shown
function M.accept() return vim.lsp.inline_completion.get() end

--- Accept only the next word of the suggestion.
---@return boolean accepted false when no suggestion is shown
function M.accept_word()
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.lsp.inline_completion.get {
    on_accept = function(item)
      local pos = vim.api.nvim_win_get_cursor(0)
      return M.trim_to_next_word(item, bufnr, { pos[1] - 1, pos[2] })
    end,
  }
end

--- Attach in git projects (root = repo) and to loose files (root = their
--- folder), but never to the private files above.
---@param bufnr integer
---@param on_dir fun(root: string)
local function root_dir(bufnr, on_dir)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' or not M.is_allowed(path) then return end
  on_dir(vim.fs.root(bufnr, '.git') or vim.fs.dirname(path))
end

vim.lsp.config(SERVER, {
  root_dir = root_dir,
  settings = { telemetry = { telemetryLevel = 'off' } },
})
vim.lsp.enable(SERVER)
vim.lsp.inline_completion.enable()

vim.keymap.set('i', '<C-Right>', function()
  if not M.accept_word() then return '<C-Right>' end
end, { expr = true, desc = 'Accept next word of suggestion' })

return M
