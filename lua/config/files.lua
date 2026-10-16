-- [[ New file ]]
-- <leader>fn asks for a path (pre-filled with the current file's folder),
-- creates any missing folders, creates the file and opens it.
-- Plain-Vim alternatives: `:e path/to/new.go` then `:w`, or `:w name` to save
-- an unnamed buffer. In the explorer: `a`.

local M = {}

local function notify_error(msg) vim.notify('new file: ' .. msg, vim.log.levels.ERROR) end

--- Create `path` (and missing parent folders) if needed, then open it.
---@param path string absolute or relative to the current directory
---@return boolean ok
---@return string? err
function M.create(path)
  if path == nil or vim.trim(path) == '' then return false, 'no file name given' end

  local full = vim.fn.fnamemodify(vim.fn.expand(vim.trim(path)), ':p')
  if vim.fn.isdirectory(full) == 1 or vim.endswith(full, '/') then return false, ('"%s" is a folder, not a file'):format(full) end

  local parent = vim.fn.fnamemodify(full, ':h')
  if vim.fn.isdirectory(parent) == 0 and vim.fn.mkdir(parent, 'p') == 0 then return false, ('could not create folder "%s"'):format(parent) end

  local existed = vim.fn.filereadable(full) == 1
  if not existed and vim.fn.writefile({}, full) ~= 0 then return false, ('could not create "%s"'):format(full) end

  local ok, err = pcall(vim.cmd.edit, vim.fn.fnameescape(full))
  if not ok then return false, ('could not open "%s": %s'):format(full, err) end
  return true
end

--- Folder to pre-fill in the prompt: the current file's folder (relative to
--- the working directory), or nothing when not editing a real file.
---@return string
local function default_folder()
  if vim.bo.buftype ~= '' or vim.api.nvim_buf_get_name(0) == '' then return '' end
  local folder = vim.fn.expand '%:p:h'
  if folder == vim.fn.getcwd() then return '' end -- file is in the working directory
  return vim.fn.fnamemodify(folder, ':~:.') .. '/'
end

--- Prompt for a path and create it. Cancelling (<Esc>) does nothing.
function M.prompt()
  vim.ui.input({ prompt = 'New file: ', default = default_folder(), completion = 'file' }, function(path)
    if path == nil then return end -- cancelled
    local ok, err = M.create(path)
    if not ok then notify_error(err) end
  end)
end

return M
