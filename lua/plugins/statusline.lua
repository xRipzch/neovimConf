-- [[ Statusline: mini.statusline ]]
-- One global bar (see 'laststatus' = 3 in options.lua), left to right:
--   MODE | git branch, diff, diagnostics | relative/path/file.go [+] ... filetype | HH:MM  line:col
-- mini.statusline gives us ready-made sections and per-mode colors; we add
-- the relative filename, filetype and a clock ourselves.
-- See `:help mini.statusline`. To remove: delete this file + its require in init.lua.

local CLOCK_FORMAT = '%H:%M'
local MS_PER_SECOND = 1000
local SECONDS_PER_MINUTE = 60
-- Sections hide themselves when the window is narrower than these widths.
local TRUNC_GIT = 40
local TRUNC_DETAILS = 75

local pack = require 'config.pack'
pack.add { pack.gh 'nvim-mini/mini.statusline' }

local statusline = require 'mini.statusline'

--- Path relative to the current directory (e.g. work/Scripts/example.go),
--- or ~/... when outside it, followed by [+] when modified.
local function section_filename()
  if vim.bo.buftype ~= '' then return '%t' end -- help, terminal, explorer, ...
  local name = vim.fn.expand '%:~:.'
  if name == '' then name = '[No Name]' end
  -- '%' is special in statuslines, so escape it in file names.
  return name:gsub('%%', '%%%%') .. '%m%r'
end

--- Filetype with its icon, e.g. " go".
local function section_filetype()
  local filetype = vim.bo.filetype
  if filetype == '' then return '' end
  local icon = MiniIcons.get('filetype', filetype)
  return icon .. ' ' .. filetype
end

local function section_clock() return os.date(CLOCK_FORMAT) end

local function active_content()
  local mode, mode_hl = statusline.section_mode {} -- no trunc_width: always the full name
  local git = statusline.section_git { trunc_width = TRUNC_GIT }
  local diff = statusline.section_diff { trunc_width = TRUNC_DETAILS }
  local diagnostics = statusline.section_diagnostics { trunc_width = TRUNC_DETAILS }

  return statusline.combine_groups {
    { hl = mode_hl, strings = { mode:upper() } },
    { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics } },
    '%<', -- truncate from here when the window is too narrow
    { hl = 'MiniStatuslineFilename', strings = { section_filename() } },
    '%=', -- everything after this is right-aligned
    { hl = 'MiniStatuslineFileinfo', strings = { section_filetype() } },
    { hl = mode_hl, strings = { section_clock(), '%l:%v' } },
  }
end

statusline.setup {
  content = { active = active_content },
  use_icons = true,
}

-- The statusline only redraws when something happens, so a timer redraws it
-- at the start of every minute. It's re-armed each time (instead of a fixed
-- 60 s repeat) so it re-aligns to the real clock, e.g. after a laptop suspend.
local timer = vim.uv.new_timer()
if not timer then
  vim.notify('statusline: could not create clock timer; time will only update on redraw', vim.log.levels.WARN)
  return
end

local function ms_until_next_minute()
  local seconds_into_minute = tonumber(os.date '%S') or 0
  return (SECONDS_PER_MINUTE - seconds_into_minute) * MS_PER_SECOND
end

local function tick()
  vim.cmd.redrawstatus()
  timer:start(ms_until_next_minute(), 0, vim.schedule_wrap(tick))
end
timer:start(ms_until_next_minute(), 0, vim.schedule_wrap(tick))
