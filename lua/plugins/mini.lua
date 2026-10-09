-- [[ mini.icons + mini.pairs ]]
-- Two small modules from the mini.nvim family, installed as standalone repos
-- (the all-in-one mini.nvim repo also ships 7 colorschemes that would clutter
-- the theme picker). mini.statusline lives in plugins/statusline.lua.
--   mini.icons -> file-type icons (needs a Nerd Font, which you have)
--   mini.pairs -> auto-close brackets and quotes
-- More modules: https://github.com/nvim-mini/mini.nvim

local pack = require 'config.pack'

pack.add {
  pack.gh 'nvim-mini/mini.icons',
  pack.gh 'nvim-mini/mini.pairs',
}

require('mini.icons').setup()
-- Plugins written for `nvim-web-devicons` (telescope, neo-tree) get their
-- icons from mini.icons instead, so we don't need that extra plugin.
MiniIcons.mock_nvim_web_devicons()

-- Typing ( [ { " ' ` inserts the closing pair; typing the closer skips over it.
require('mini.pairs').setup()
