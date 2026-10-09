-- [[ indent-blankline: subtle indent guides ]]
-- A thin, dim line at each indent level. No scope highlighting, no animation.
-- See `:help ibl.config`. To remove: delete this file + its require in init.lua.

local pack = require 'config.pack'
pack.add { pack.gh 'lukas-reineke/indent-blankline.nvim' }

require('ibl').setup {
  indent = { char = '│' }, -- uses the dim 'IblIndent' highlight (linked to Whitespace)
  scope = { enabled = false },
}
